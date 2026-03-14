# Multi-Host and Remote Card Architecture

How tt-metal handles clusters larger than one server, how non-PCIe-attached (remote) cards work, and how data actually moves between chips. Includes a complete walkthrough of data-parallel training across 16 cards, comparison with GPU clusters, and the blackhole-py extension path.

See also: `fabric-and-topology-internals.md` for topology/routing details, `dispatch-kernel-pipeline-internals.md` for the dispatch kernel catalog.

## Can You Aim One CQ at Everything?

**No.** Each host can only dispatch to its own local PCIe-attached cards. There is no CQ tunneling across hosts. The `FDMeshCommandQueue` explicitly skips non-local devices:

```cpp
if (!mesh_device_->is_local(address.device_coord)) {
    return;  // silently no-op for remote devices
}
```

Instead, tt-metal uses an **SPMD (Single Program Multiple Data)** model: every host runs the same program, each dispatches only to its local slice of the mesh. MPI coordinates between hosts, but all inter-chip data movement goes over the **TT-Fabric ethernet links** directly.

## The Multi-Host Architecture

```
Host 0 (MPI rank 0)                    Host 1 (MPI rank 1)
┌────────────────────────┐              ┌────────────────────────┐
│ Same program running   │              │ Same program running   │
│ MeshDevice (global     │              │ MeshDevice (global     │
│   shape 8x8, but only  │              │   shape 8x8, but only  │
│   local slice 8x4)     │              │   local slice 8x4)     │
│                        │              │                        │
│ CQ → local 32 chips    │              │ CQ → local 32 chips    │
│   via PCIe             │              │   via PCIe             │
│                        │              │                        │
│ Chips [0,0]-[7,3]      │              │ Chips [0,4]-[7,7]      │
└────────┬───────────────┘              └───────────┬────────────┘
         │ QSFP ethernet (chip-to-chip)             │
         └──────────────────────────────────────────┘
              ↑ data plane: TT-Fabric (autonomous)
              ↑ control plane: MPI (barriers, metadata)
```

Each host:
1. Opens only its local chips via PCIe.
2. Writes dispatch commands only to those chips.
3. The chips themselves handle cross-host data movement via ethernet, autonomously.

### The host network carries only control, not data

| | GPU cluster | TT cluster |
|---|---|---|
| **Inter-device transport** | NCCL over NVLink/InfiniBand, host-initiated | TT-Fabric over ethernet, device-initiated |
| **Dispatch model** | N separate `cudaLaunchKernel` calls | One `EnqueueMeshWorkload` per host |
| **Who moves data** | GPU via NCCL (host kicks it off) | Tensix/ERISC cores autonomously |
| **Addressing** | Separate GPU memory spaces, explicit transfers | Unified addressing (same buffer address on every chip) |
| **Multi-host coordination** | NCCL + RDMA (data AND control over network) | MPI for control only, data goes chip-to-chip |
| **Trace/replay** | CUDA graphs (per-device) | `MeshTrace` spans entire multi-device mesh |

## Remote (Non-PCIe) Cards

You do NOT need a host attached to every card. Wormhole already does this:

- **T3000**: 1 PCIe card (MMIO), 7 remote cards reachable only via ethernet.
- **WH Galaxy**: 1 MMIO card, up to 8 remote cards per tunnel.

The host has no PCIe path to remote cards at all. Everything goes through the MMIO card as a gateway:

```
Host CPU
  │ PCIe (only connection to the cluster)
  ▼
MMIO Card [0]
  ├── PREFETCH_HD + DISPATCH_HD + DISPATCH_S  (local work)
  ├── PREFETCH_H × N  ──┐
  ├── DISPATCH_H × N  ──┤
  ├── FABRIC_MUX ────────┘──→ ethernet ──→ Remote Card [1]
  │                                         ├── PREFETCH_D
  │                                         ├── DISPATCH_D + DISPATCH_S
  │                                         └── RETURN_FABRIC_MUX
  │                          ethernet ──→ Remote Card [2] (same structure)
  │                          ...
  │                          ethernet ──→ Remote Card [8]
  └── (MMIO card is the gateway for all remote dispatch)
```

### The multiplexing problem

With 8 remote cards, you'd naively need 8 PREFETCH_H + 8 DISPATCH_H = 16 Tensix cores consumed on the gateway. FABRIC_MUX solves this by multiplexing multiple streams into a single ethernet link. In Galaxy: 2 FABRIC_MUX instances (one per tunnel), each handling 4 remote chips.

The gateway card has finite cores and bandwidth. When you exceed what one gateway can handle, add another host with its own MMIO card.

### Blackhole Galaxy is different

BH Galaxy has **every chip PCIe-attached** (all are MMIO devices). No remote cards, no PREFETCH_H/D split needed. Each chip gets its own independent PREFETCH_HD + DISPATCH_HD dispatched directly from the host. The fabric still runs for inter-chip data movement, but dispatch bypasses it entirely.

## The "NoC of Cards" Concept

The chips ARE tiles in a larger NoC. The TT-Fabric is literally an inter-chip NoC:

| Single chip | Multi-chip fabric |
|---|---|
| Tensix cores connected by on-chip NOC | Chips connected by ethernet fabric |
| NOC unicast/mcast writes to any core | Fabric unicast/mcast writes to any chip |
| Routing via NOC coordinates (x,y) | Routing via mesh coordinates (row, col, mesh_id) |
| ~1 cycle latency per hop | ~100ns+ per ethernet hop |

The device-side API (`tt_fabric_api.h`) lets any Tensix kernel on any chip do:

```cpp
fabric_unicast_send(dst_mesh_id, dst_chip_id, dst_noc_addr, payload, size);
fabric_async_write(noc_addr, payload, size);  // using pre-set route
```

A write to any address on any chip in the cluster, routed through ERISC routers using L1 routing tables. Host CPUs are uninvolved.

## Cross-Host Discovery Protocol

### Phase 1: Local ethernet probing

Each MPI rank probes its local chips' ethernet PHY:

```
for each chip on this host:
    for each ethernet channel:
        if link is up AND peer chip is NOT in local PCIe tree:
            record as ExitNodeConnection(src_exit_node, dst_exit_node, is_local=false)
```

### Phase 2: Global merge via MPI

1. All non-controller ranks serialize their `PhysicalSystemDescriptor` to protobuf, send to rank 0.
2. Rank 0 merges, calls `generate_cross_host_connections()` — cross-references all hosts' exit node tables to match cable endpoints using symmetric hashing.
3. Rank 0 broadcasts merged global descriptor to all ranks.
4. Every host generates routing tables from the global topology and writes them to every chip's L1.

### Phase 3: Logical port pairing

1. Each host generates `PortDescriptorTable` for its exit nodes (assigns logical port IDs).
2. All hosts send tables to rank 0 via MPI.
3. Rank 0 pairs ports using symmetric `connection_hash` (same hash on both ends of a cable).
4. Rank 0 broadcasts `AnnotatedIntermeshConnections` — final `((src_mesh, src_port), (dst_mesh, dst_port))` pairs.
5. Routing tables regenerated with inter-mesh paths and written to all chips.

## Intra-Host vs Cross-Host Ethernet

| Property | Intra-host (`is_local=true`) | Cross-host (`is_local=false`) |
|---|---|---|
| `EthConnection::is_local` | `true` | `false` |
| UMD source | `get_ethernet_connections()` | `get_ethernet_connections_to_remote_devices()` |
| Both ASICs accessible by same host | Yes | No |
| EDM builder flag | `is_inter_mesh = false` | `is_inter_mesh = true` |
| Router firmware CT arg | `is_intermesh_router_on_edge = false` | `is_intermesh_router_on_edge = true` |
| Virtual channel | VC0 only | VC0 for unicast, VC1 for intermesh (prevents head-of-line blocking) |
| Routing table | `intra_mesh_table_` | `inter_mesh_table_` + `exit_node_lut_` |
| At mesh boundary | Never triggered | Triggers `recompute_path()` from new mesh's L1 table |

At the firmware level, a cross-host hop is identical to an intra-host hop — just another ethernet link. The ERISC router doesn't know which server the far end is on.

## Data-Parallel Training Walkthrough

### Setup: 16 BH Cards, 2 Hosts

```
Host 0 (PCIe to 8 cards)              Host 1 (PCIe to 8 cards)
┌─────────────────────────┐            ┌─────────────────────────┐
│ [0,0] [0,1] [0,2] [0,3]│            │ [0,4] [0,5] [0,6] [0,7]│
│ [1,0] [1,1] [1,2] [1,3]│── QSFP ──→│ [1,4] [1,5] [1,6] [1,7]│
└─────────────────────────┘            └─────────────────────────┘
```

Logical shape: `2x8`. Host topology: `1x2`. Each host owns a `2x4` slice.

Each card runs the same model. Batch of 16 samples sharded 1 per card.

### Step 1: Model loading (replicate weights)

```python
# Each host writes to its own 8 cards via PCIe. No cross-host comm.
for chip in my_local_chips:
    write_to_dram(chip, weights_addr, model_weights)
```

Key convention: every chip allocates buffers at **the same DRAM address**. This enables symmetric addressing in collective kernels.

### Step 2: Data sharding

```python
# Host 0 has samples 0-7, Host 1 has samples 8-15
for i, chip in enumerate(my_local_chips):
    write_to_dram(chip, input_addr, my_batch[i])
```

Pure PCIe. No fabric involved.

### Step 3: Forward + backward pass (pure local compute)

```python
for chip in my_local_chips:
    dispatch(chip, forward_backward_program)
```

Each chip runs independently on its own sample. No inter-chip communication. After this, each chip has its own unique gradient tensor in DRAM.

### Step 4: All-reduce gradients (fabric data movement)

This is where inter-chip communication happens. Decomposed into **reduce-scatter + all-gather** on a ring of 16 chips.

**Memory layout on each chip before all-reduce:**
```
Chip k DRAM:
  GRAD_ADDR + 0*CHUNK:     gradient_chunk_0
  GRAD_ADDR + 1*CHUNK:     gradient_chunk_1
  ...
  GRAD_ADDR + 15*CHUNK:    gradient_chunk_15
  RECV_ADDR:               scratch buffer for incoming data
```

**Reduce-scatter (15 steps):** Each step, every chip simultaneously sends one chunk to its ring neighbor and receives one chunk:

```
Step 1 (all chips in parallel):
  Chip 0:  fabric_write(dst=chip_1, addr=RECV_ADDR, data=grad_chunk[0])
  Chip 1:  fabric_write(dst=chip_2, addr=RECV_ADDR, data=grad_chunk[1])
  ...
  Chip 15: fabric_write(dst=chip_0, addr=RECV_ADDR, data=grad_chunk[15])

  Each chip receives a chunk, adds it to its own:
    grad_chunk[k] += received_chunk
```

When chip [0,3] sends to chip [0,4] (crossing the host boundary):
1. ERISC on chip [0,3] forwards the packet EAST over the QSFP cable.
2. ERISC on chip [0,4] (Host 1) receives it, routing table says destination is local.
3. ERISC delivers via NOC write to the target DRAM address.
4. **Host CPUs are completely uninvolved.**

After 15 steps: each chip owns one fully-reduced chunk (sum of all 16 chips' contributions).

**All-gather (15 more steps):** Each chip broadcasts its fully-reduced chunk around the ring.

After all-gather: every chip has the complete averaged gradient. **No single card ever held all the data.** The reduction was fully distributed.

### Step 5: Weight update (pure local)

```python
for chip in my_local_chips:
    dispatch(chip, weight_update_program)  # SGD/Adam step
```

Each chip applies the identical averaged gradient to its weights. Back to step 3 for the next iteration.

### Step 6: Host synchronization

```python
MPI_Barrier()  # ensure all hosts finished the iteration
if rank == 0:
    log_metrics()
```

MPI is only used for this kind of coordination, never for tensor data.

## Same-Address Allocation Convention

When chip 0 does `fabric_write(dst=chip_1, addr=0x30000, data=chunk)`, chip 1's ERISC delivers to address `0x30000` in chip 1's local DRAM. If every chip allocated its gradient buffer at `0x30000`, the sender doesn't need to know anything about the receiver's memory layout. The addresses are symmetric.

This is a convention, not a hardware requirement, but it massively simplifies collective kernels. In tt-metal: `ReplicateTensorToMesh` + `MeshBuffer` with `ReplicatedBufferConfig` ensures every chip uses the same address.

## Collectives: The NCCL Equivalent

tt-metal has its own CCL as first-class TTNN ops running entirely on-device:

| Op | Description |
|----|-------------|
| `ttnn.all_gather(tensor, cluster_axis)` | Ring or linear topology gather |
| `ttnn.reduce_scatter(tensor, cluster_axis)` | Ring or linear reduce-scatter |
| `ttnn.all_reduce` | Composite of the above |
| `all_gather_matmul_async` | Fused: overlap all-gather with matmul |
| `matmul_reduce_scatter_async` | Fused: overlap matmul with reduce-scatter |

These run on Tensix + ERISC cores directly. No host involvement during execution.

## Parallelism Strategies

| Strategy | How it works on TT | Example |
|----------|-------------------|---------|
| **Tensor Parallel (TP)** | Weights sharded across chips. Column-parallel matmul → AllGather → row-parallel matmul → ReduceScatter. | Llama-70B: 4 TP replicas on 4x2 submeshes of an 8x4 Galaxy |
| **Data Parallel (DP)** | Each submesh runs independent model replica. Batch sharded across submeshes. | `mesh_device.create_submeshes(MeshShape(2,4))` |
| **Pipeline Parallel** | Different MPI ranks own different meshes (pipeline stages). `FabricSocket` for point-to-point tensor streaming. | Multi-mesh via `tt-run` |
| **Hybrid TP+DP** | TP within submesh, DP across submeshes. | Galaxy 8x4: 4 × (2x4 TP submesh) with DP across them |

## Extending blackhole-py to Multi-Card

### The data movement hierarchy

1. **Host → chip**: PCIe writes (existing `TLBWindow.write()` / CQ dispatch)
2. **Chip → chip (same host)**: Ethernet via EDM fabric (ERISC routes autonomously)
3. **Chip → chip (cross host)**: Same ethernet fabric — ERISC doesn't know or care about server boundaries

The host CPU never touches inter-chip data. It only:
- Writes routing tables at startup
- Starts EDM firmware on ERISC cores
- Dispatches compute kernels via PCIe CQ
- Synchronizes with other hosts via MPI

### What to implement, in layers

#### Layer 1: Topology discovery and routing (one-time setup)

```python
# Discover local chips
local_chips = discover_pcie_devices()  # existing single-card code, x8

# Discover ethernet topology
for chip in local_chips:
    for eth_core in chip.ethernet_cores:  # 14 per BH chip
        link_state = read_eth_phy_status(chip, eth_core)
        if link_state.connected:
            peer = read_eth_peer_id(chip, eth_core)

# Build dimension-ordered routing tables
for src in all_chips:
    for dst in all_chips:
        if src.row != dst.row:
            table[src][dst] = NORTH if dst.row < src.row else SOUTH
        elif src.col != dst.col:
            table[src][dst] = WEST if dst.col < src.col else EAST
        else:
            table[src][dst] = LOCAL

# Write to every chip's L1
for chip in local_chips:
    for core in chip.all_cores:
        write_l1(chip, core, ROUTING_TABLE_ADDR, table[chip])
```

#### Layer 2: Start fabric EDM firmware

```python
edm_kernel = compile_kernel("fabric_erisc_router.cpp", defines={"FABRIC_2D": 1})
for chip in local_chips:
    for eth_core in chip.active_ethernet_cores:
        load_kernel(chip, eth_core, edm_kernel)
        start_kernel(chip, eth_core)
# Fabric is now live — ERISC cores spinning, ready for packets
```

#### Layer 3: Dispatch compute (existing code, looped)

```python
for chip in local_chips:
    write_dram(chip, weights_addr, model_weights)
    write_dram(chip, input_addr, my_data_shard[i])
    dispatch_program(chip, forward_backward_kernel)
```

#### Layer 4: Remote (non-PCIe) card dispatch

Two options:

**Option A: Full dispatch pipeline (2-4 reserved cores per remote card)**

Run PREFETCH_D + DISPATCH_D + DISPATCH_S + RETURN_FABRIC_MUX on each remote card. Same firmware as tt-metal's CQ pipeline, just compiled with different `#define` flags.

**Option B: Direct fabric writes from gateway (0 reserved cores on remote)**

```python
class RemoteDevice:
    def __init__(self, gateway_chip, eth_route):
        self.gateway = gateway_chip
        self.route = eth_route

    def write_dram(self, addr, data):
        # Write data to gateway's L1 via PCIe
        self.gateway.write_l1(relay_core, RELAY_BUF, data)
        # Relay kernel on gateway does:
        #   fabric_unicast_write(dst, addr, RELAY_BUF, size)
        # ERISC delivers directly to remote chip's DRAM via NOC
```

Option B uses ERISC's direct NOC write to poke kernel binaries, args, and GO signals into remote worker L1. No PREFETCH_D/DISPATCH_D needed. The tradeoff: no command batching, no dispatch overlap (DISPATCH_S), no pipelined async completion. Fine for a simpler runtime that dispatches one program at a time.

#### Layer 5: Collective communication (all-reduce kernel)

```python
GRAD_ADDR = 0x30000000
RECV_ADDR = 0x30100000
CHUNK_SIZE = total_grad_size // num_chips

allreduce_kernel = compile_kernel("my_allreduce.cpp")

for i, chip in enumerate(all_chips):
    write_l1(chip, core, ARGS_ADDR, {
        "ring_index": i,
        "ring_next": (i + 1) % num_chips,
        "grad_addr": GRAD_ADDR,
        "recv_addr": RECV_ADDR,
        "chunk_size": CHUNK_SIZE,
    })
    dispatch(chip, allreduce_kernel)
```

The kernel on each chip uses `fabric_unicast_write()` to send/receive chunks around the ring. Cross-host hops are transparent — the ERISC routing table handles it.

#### Layer 6: Multi-host coordination (MPI)

```python
import mpi4py.MPI as MPI
comm = MPI.COMM_WORLD
rank = comm.Get_rank()

# Exchange exit node info
my_exits = find_cross_host_eth_links(local_chips)
all_exits = comm.allgather(my_exits)
global_routing = build_routing_tables(all_exits)

# Training loop
for epoch in range(epochs):
    for i, chip in enumerate(local_chips):
        write_dram(chip, input_addr, my_batch[i])
        dispatch(chip, forward_backward_kernel)
    for chip in local_chips:
        dispatch(chip, allreduce_kernel)
    wait_for_completion(local_chips)
    for chip in local_chips:
        dispatch(chip, weight_update_kernel)
    comm.Barrier()

## TT-Metal Distributed API Reference

The distributed execution model is centered on four C++ primitives:

| Primitive | Header | Purpose |
|---|---|---|
| `MeshDevice` | `tt-metalium/mesh_device.hpp` | Logical 2D view of physical chips |
| `MeshWorkload` | `tt-metalium/mesh_workload.hpp` | Maps programs to mesh coordinate ranges |
| `MeshBuffer` | `tt-metalium/mesh_buffer.hpp` | Distributed memory (replicated or sharded global layout) |
| `MeshCommandQueue` | `tt-metalium/distributed.hpp` | Enqueue workload, reads/writes, synchronize/events/trace |

### Tensor distribution

- `MeshMapperConfig::Replicate` and `MeshMapperConfig::Shard{dim}` define placement along mesh dimensions.
- `MeshComposerConfig` defines how shards are concatenated back.
- `ShardedBufferConfig` sets global size/shape + shard shape + orientation.

Headers: `ttnn/distributed/distributed_tensor.hpp`, `ttnn/distributed/distributed_configs.hpp`

### Collective ops (TTNN CCL)

Bindings in:
- `ttnn/operations/ccl/all_reduce/all_reduce_nanobind.cpp`
- `ttnn/operations/ccl/all_gather/all_gather_nanobind.cpp`
- `ttnn/operations/experimental/ccl/all_reduce_async/all_reduce_async_nanobind.cpp`

### Multi-process and multi-host scoping

- **Single process, one mesh**: open one `MeshDevice` spanning all visible devices.
- **Multi-process partitioning**: use `TT_VISIBLE_DEVICES` to give each process a subset of PCIe devices.
- **Multi-host / bound ranks**: use `TT_MESH_ID` and `TT_MESH_HOST_RANK` to bind rank-local view into a larger mesh graph.

### Programming examples

| Example | Path |
|---|---|
| SPMD dispatch | `tt_metal/programming_examples/distributed/1_distributed_program_dispatch/` |
| Mesh buffer IO | `tt_metal/programming_examples/distributed/2_distributed_buffer_rw/` |
| Trace + events | `tt_metal/programming_examples/distributed/4_distributed_trace_and_events/` |

### Blackhole-py API sketch (minimal surface)

```python
open_mesh_device(shape, device_ids=None)
create_mesh_buffer(mesh, layout="replicated"|"sharded", global_shape=..., shard_shape=...)
enqueue_mesh_workload(mesh, workload, blocking=True)
all_reduce(tensor, mode="host"|"fabric")
all_gather(tensor, mode="host"|"fabric")
```
```
