# TT-Metal dispatch: modes, queues, and ABI

These chapters describe the recorded TT-Metal command protocol and launch path. They are not the current blackhole-py CQ ABI. Hardware coordinates, service counts, addresses, and compile-time defines below belong to their stated configuration. See [blackhole-py runtime](blackhole-py-runtime.md) for the current Python implementation.

<a id="dispatch-modes"></a>
## Dispatch modes (fast vs slow) and architecture mapping
<a id="dispatch-modes--dispatch-modes-fast-vs-slow-and-architecture-mapping"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

TT-Metal has two mutually exclusive dispatch modes:
- **Fast dispatch**: host enqueues commands to a device command queue; firmware dispatches on-device.
- **Slow dispatch**: host writes runtime args and launch messages directly to cores and waits for completion.

Mixing is prohibited; the dispatch state is latched on first use.

<a id="dispatch-modes--fast-dispatch-path"></a>
### Fast dispatch path

Primary entry points:
- `distributed::MeshDevice::create_unit_mesh()`
- `MeshCommandQueue` + `distributed::EnqueueMeshWorkload()`
- `distributed::Finish()`

Characteristics:
- Supports multi-device/mesh workflows
- Overlap of IO + compute
- Production path

<a id="dispatch-modes--slow-dispatch-path"></a>
### Slow dispatch path

Primary entry points:
- `CreateDevice()`
- `detail::WriteToBuffer()` / `detail::ReadFromBuffer()`
- `detail::LaunchProgram()`

Characteristics:
- Synchronous, single-device oriented
- Simpler control flow

<a id="dispatch-modes--architecture-mapping-blackhole"></a>
### Architecture mapping (Blackhole)

From `blackhole/architecture.md`:
- Host orchestrates device setup and dispatch
- Brisc/Ncrisc do NoC/DMA orchestration
- Trisc threads push Tensix instruction streams

<a id="dispatch-modes--slow-dispatch--architecture"></a>
#### Slow dispatch ↔ architecture
- Host directly programs per-core state and triggers execution
- Brisc/Ncrisc handle NoC DMA for reader/writer kernels
- Trisc threads push Tensix instructions

<a id="dispatch-modes--fast-dispatch--architecture"></a>
#### Fast dispatch ↔ architecture
- Host enqueues CQ commands
- Device-side dispatch firmware programs the same Brisc/Trisc/Tensix pipeline
- CQ scheduling overlaps DMA and compute

<a id="dispatch-modes--harvesting--slow-dispatch-behavior"></a>
### Harvesting + slow dispatch behavior

- Harvesting fuses off columns/tiles/banks
- Coordinate translation provides a stable logical view
- In slow dispatch, tt-metal writes **per core** (unicast), even when bytes are identical
- This avoids multicast rectangles that might include harvested/invalid endpoints

If you do your own multicast rectangles:
- avoid harvested columns
- avoid non-Tensix columns
- or use per-core unicast (slow-dispatch style)

<a id="dispatch-modes--choosing-a-path-for-a-c-abi"></a>
### Choosing a path for a C ABI
- Minimal C wrapper: slow dispatch
- Production-like path: fast dispatch

<a id="dispatch-kernel-pipeline-internals"></a>
## Dispatch Kernel Pipeline Internals
<a id="dispatch-kernel-pipeline-internals--dispatch-kernel-pipeline-internals"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

Complete catalog of every dispatch kernel in tt-metal, how they connect, the CQ command protocol, and the multi-chip dispatch flow. This covers the firmware that turns host command queue entries into kernel launches on Tensix workers.

See also: `dispatch-modes.md` for fast vs slow dispatch overview, `fabric-and-topology-internals.md` for the ethernet fabric layer underneath.

<a id="dispatch-kernel-pipeline-internals--dispatch-kernel-types"></a>
### Dispatch Kernel Types

All dispatch kernels are compiled from three source files with different `#define` flags:

| Source | Variants |
|--------|----------|
| `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` | PREFETCH_HD, PREFETCH_H, PREFETCH_D |
| `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` | DISPATCH_HD, DISPATCH_H, DISPATCH_D |
| `tt_metal/impl/dispatch/kernels/cq_dispatch_subordinate.cpp` | DISPATCH_S |
| `tt_metal/fabric/impl/kernels/tt_fabric_mux.cpp` | FABRIC_MUX, RETURN_FABRIC_MUX |

The variant is selected by compile-time flags:

| Type | IS_H_VARIANT | IS_D_VARIANT |
|------|:---:|:---:|
| PREFETCH_HD | 1 | 1 |
| PREFETCH_H | 1 | 0 |
| PREFETCH_D | 0 | 1 |
| DISPATCH_HD | 1 | 1 |
| DISPATCH_H | 1 | 0 |
| DISPATCH_D | 0 | 1 |

<a id="dispatch-kernel-pipeline-internals--core-type-assignment"></a>
#### Core type assignment

All dispatch kernels run on **Tensix** (WORKER) or **idle ETH** cores, selected by `DispatchCoreConfig`:

```cpp
enum class DispatchCoreType : uint32_t { WORKER, ETH, COUNT };
```

When `ETH` is selected, dispatch kernels run on idle (non-routing) ethernet cores compiled with `Eth::IDLE`. This is used on N300/T3000 where idle ETH cores are plentiful.

**Active ERISC cores** (running the fabric router `fabric_erisc_router.cpp`) are never used for dispatch. They are `CoreType::ACTIVE_ETH` with `Eth::SENDER` mode, completely separate from the dispatch pipeline.

<a id="dispatch-kernel-pipeline-internals--per-kernel-reference"></a>
### Per-Kernel Reference

<a id="dispatch-kernel-pipeline-internals--prefetch_hd--single-chip-combined-prefetcher"></a>
#### PREFETCH_HD — Single-chip combined prefetcher

**Runs on:** MMIO card only. Tensix or idle ETH.

**What it does:** Reads CQ commands from the host via PCIe. The host writes commands into a pinned sysmem ring buffer (hugepage), then pokes 16-bit size tokens into the prefetch core's L1 queue (`PREFETCH_Q_BASE`). PREFETCH_HD reads the size, DMA-reads that many bytes from sysmem, and feeds them into the downstream dispatch ring buffer.

**Data sources:**
- Host PrefetchQ (16-bit size tokens at `CQ_PREFETCH_Q_BASE`)
- Host issue ring buffer (actual command bytes, read via PCIe DMA)
- Local DRAM (for `RELAY_LINEAR`, `RELAY_PAGED` commands that fetch from device DRAM)

**Outputs:**
- Dispatch CB ring buffer → DISPATCH_HD
- `dispatch_s_buffer` → DISPATCH_S (go-signal-related commands, routed by `dispatcher_type` field)

**Semaphore protocol:** Two semaphores with DISPATCH: `page_ready` (prefetcher increments) and `page_done` (dispatcher increments when consumed).

---

<a id="dispatch-kernel-pipeline-internals--prefetch_h--mmio-side-prefetcher-for-remote-chips"></a>
#### PREFETCH_H — MMIO-side prefetcher for remote chips

**Runs on:** MMIO card. Tensix or idle ETH. One instance per remote card.

**What it does:** Same command reading as PREFETCH_HD, but instead of feeding a local dispatcher, forwards command pages over the TT-Fabric to the remote card's PREFETCH_D. Uses `CQRelayClient` / `WorkerToFabricMuxSender` to write into FABRIC_MUX.

**Inputs:** Host PrefetchQ + issue ring buffer (same as HD). Local DRAM for DRAM-backed commands.

**Outputs:** Via FABRIC_MUX → ethernet → remote chip's PREFETCH_D cmddat queue.

**Special command:** `CQ_PREFETCH_CMD_RELAY_LINEAR_H` must be the only command in a fetchq entry. Reads from an MMIO-chip NOC address and relays directly to remote.

---

<a id="dispatch-kernel-pipeline-internals--prefetch_d--remote-chip-receiver"></a>
#### PREFETCH_D — Remote-chip receiver

**Runs on:** Remote (non-MMIO) card. Tensix or idle ETH.

**What it does:** Receives command pages from PREFETCH_H via the fabric. The ERISC router on the local chip writes directly into PREFETCH_D's L1 cmddat buffer via NOC 1 (zero-copy). PREFETCH_D polls its upstream semaphore, reads commands, and feeds local DISPATCH_D and DISPATCH_S.

**Inputs:** L1 cmddat buffer, filled by ERISC. Remote chip's DRAM for paged reads.

**Outputs:**
- Dispatch CB → DISPATCH_D (all worker-write commands)
- `dispatch_s_buffer` → DISPATCH_S (go-signal commands, routed by `dispatcher_type` field in `CQPrefetchRelayInlineCmd`)

---

<a id="dispatch-kernel-pipeline-internals--dispatch_hd--single-chip-combined-dispatcher"></a>
#### DISPATCH_HD — Single-chip combined dispatcher

**Runs on:** MMIO card only. Tensix or idle ETH.

**What it does:** The main command interpreter. Reads command pages from PREFETCH_HD's ring buffer. For each command, issues the appropriate NOC writes: kernel binaries to worker L1, runtime args, semaphore configs, CB configs. Writes completions back to host sysmem via PCIe.

**NOC assignment:** NOC1 for upstream (receiving from prefetcher), NOC0 for downstream (worker writes, host completion writes). This split is mandatory because DISPATCH_D and DISPATCH_S can co-locate on the same core with conflicting NOC usage.

**Inputs:** Dispatch CB ring buffer from PREFETCH_HD.

**Outputs:**
- NOC writes to worker Tensix/ETH L1 (binaries, kernel configs, RTAs, semaphores)
- PCIe writes to host completion queue (events, readback data)
- GO signal multicast/unicast to workers (when not using distributed DISPATCH_S)

---

<a id="dispatch-kernel-pipeline-internals--dispatch_h--mmio-side-return-handler"></a>
#### DISPATCH_H — MMIO-side return handler

**Runs on:** MMIO card. Tensix or idle ETH.

**What it does:** Receives completion data back from the remote chip's DISPATCH_D (via RETURN_FABRIC_MUX → ethernet → local ERISC). Writes it to the host completion queue via PCIe. Also signals PREFETCH_H when the remote card is ready for more commands (exec-buf-end notification).

**Inputs:** Data pages from RETURN_FABRIC_MUX via `CQRelayClient`.

**Outputs:** PCIe writes to host completion queue. NOC semaphore increment to PREFETCH_H.

**Key point:** DISPATCH_H does NOT do any worker writes. All worker writes happen on the remote chip by DISPATCH_D.

---

<a id="dispatch-kernel-pipeline-internals--dispatch_d--remote-chip-dispatcher"></a>
#### DISPATCH_D — Remote-chip dispatcher

**Runs on:** Remote card. Tensix or idle ETH.

**What it does:** Same command interpreter as DISPATCH_HD. Receives pages from PREFETCH_D. Issues all worker-targeted writes locally on the remote chip. For host-bound data (completion events, readback), relays through RETURN_FABRIC_MUX → ethernet → DISPATCH_H → host PCIe.

**NOC assignment:** NOC1 upstream, NOC0 downstream (same split as HD).

**Inputs:** Dispatch CB from PREFETCH_D.

**Outputs:**
- NOC writes to remote chip's worker L1
- GO signal multicast/unicast (when not using distributed DISPATCH_S)
- Host-return data via RETURN_FABRIC_MUX

---

<a id="dispatch-kernel-pipeline-internals--dispatch_s--subordinate-dispatcher-go-signal-specialist"></a>
#### DISPATCH_S — Subordinate dispatcher (GO signal specialist)

**Runs on:** Same chip as its paired DISPATCH_D (or DISPATCH_HD). Can share the same physical Tensix core (DISPATCH_D on NCRISC, DISPATCH_S on BRISC) or run on a separate core (`distributed_dispatcher=1`).

**What it does:** One job: send GO signals to workers and wait for them to finish. This decouples go-signal latency from command processing, allowing DISPATCH_D to start queuing the next program while DISPATCH_S waits for the current one to complete. This is the key dispatch latency overlap optimization.

**Command set (only 5 commands):**

| Command | Purpose |
|---------|---------|
| `CQ_DISPATCH_CMD_SEND_GO_SIGNAL` | Multicast + unicast GO to all workers. Wait for completion count. |
| `CQ_DISPATCH_CMD_WAIT` | Wait for workers to complete and reset stream counter (distributed mode only). |
| `CQ_DISPATCH_SET_NUM_WORKER_SEMS` | Set number of worker semaphores in use. |
| `CQ_DISPATCH_SET_GO_SIGNAL_NOC_DATA` | Populate NOC XY table for unicast go signals. |
| `CQ_DISPATCH_CMD_TERMINATE` | Shutdown. |

**Worker completion mechanism:** Workers atomically increment `STREAM_REMOTE_DEST_BUF_SPACE_AVAILABLE_REG_INDEX` on DISPATCH_S (or DISPATCH_D in non-distributed mode) via NOC. DISPATCH_S polls this stream register. In distributed mode, it mirrors the count to DISPATCH_D's stream register.

**NOC allocation (when co-located with DISPATCH_D):**
- Cmd Buf 0: regular writes (DISPATCH_S)
- Cmd Buf 1: small inline writes (DISPATCH_S)
- Cmd Buf 2: atomics (DISPATCH_S)
- Cmd Buf 3: reserved for DISPATCH_D

**Inputs:** `dispatch_s_buffer` ring filled by PREFETCH_D (or PREFETCH_HD).

**Outputs:** NOC multicast to `mcast_go_signal_addr` on all worker cores. NOC unicast to active ETH cores. Stream register updates to DISPATCH_D.

---

<a id="dispatch-kernel-pipeline-internals--fabric_mux--host-to-device-multiplexer"></a>
#### FABRIC_MUX — Host-to-device multiplexer

**Runs on:** MMIO card. Tensix or idle ETH.

**What it does:** Aggregates command traffic from multiple PREFETCH_H instances and forwards to the ERISC fabric router sender channels. Bridges the dispatch pipeline's "worker interface" to the persistent TT-Fabric ethernet infrastructure.

**Channel types:**
- **Full-size channels**: one per upstream PREFETCH_H. Carries complete command+data payloads.
- **Header-only channels**: one per downstream DISPATCH_H. Carries flow control signals.

**Inputs:** NOC writes from PREFETCH_H workers via `WorkerToFabricMuxSender`.

**Outputs:** Feeds the ERISC sender channel L1 buffer on the MMIO chip.

---

<a id="dispatch-kernel-pipeline-internals--return_fabric_mux--device-to-host-return-multiplexer"></a>
#### RETURN_FABRIC_MUX — Device-to-host return multiplexer

**Runs on:** Remote card. Tensix or idle ETH. Same source (`tt_fabric_mux.cpp`), instantiated with `d2h_=true`.

**What it does:** Reverse-direction mux. Aggregates completion data from DISPATCH_D (full-size channels) and coordination headers from PREFETCH_D (header-only), sends over ethernet back to DISPATCH_H on the MMIO card.

**Inputs:** DISPATCH_D relay writes (full-size). PREFETCH_D exec-buf-end headers.

**Outputs:** Feeds ERISC sender channel for return-path ethernet transmission.

<a id="dispatch-kernel-pipeline-internals--topology-graphs"></a>
### Topology Graphs

Static dispatch topology tables live in `tt_metal/impl/dispatch/topology.cpp`. Node format: `{id, device_id, servicing_device_id, cq_id, kernel_type, [upstream_ids], [downstream_ids], noc_selection}`.

<a id="dispatch-kernel-pipeline-internals--single-chip-1-cq"></a>
#### Single chip, 1 CQ

```
PREFETCH_HD(0) ──dispatch_cb──→ DISPATCH_HD(1)
PREFETCH_HD(0) ──dispatch_s_buf──→ DISPATCH_S(2)
DISPATCH_S(2) ──sync_sem──→ DISPATCH_HD(1)
```

3 cores consumed.

<a id="dispatch-kernel-pipeline-internals--two-chip-1-cq-n300t3000-with-fabric"></a>
#### Two-chip, 1 CQ (N300/T3000 with fabric)

```
MMIO chip (device 0):
  PREFETCH_HD(0) → DISPATCH_HD(1) ← DISPATCH_S(2)     [local CQ]
  PREFETCH_H(3) → FABRIC_MUX(5)                         [to remote]
  DISPATCH_H(4) ← FABRIC_MUX(5)                         [from remote]

         ↕ ethernet (fabric EDM) ↕

Remote chip (device 1):
  PREFETCH_D(6) → DISPATCH_D(7) ← DISPATCH_S(8)        [remote CQ]
  PREFETCH_D(6) → RETURN_FABRIC_MUX(9)                  [to host]
  DISPATCH_D(7) → RETURN_FABRIC_MUX(9)                  [to host]
```

MMIO card: 3 (local) + 2 (PREFETCH_H + DISPATCH_H) + 1 (FABRIC_MUX) = 6 cores.
Remote card: 3 (PREFETCH_D + DISPATCH_D + DISPATCH_S) + 1 (RETURN_FABRIC_MUX) = 4 cores.

<a id="dispatch-kernel-pipeline-internals--galaxy-9-chip-1-cq"></a>
#### Galaxy (9-chip, 1 CQ)

MMIO chip has up to 2 FABRIC_MUX instances (one per ethernet tunnel), each serving 4 remote chips. Each FABRIC_MUX has 4 full-size channels (one per PREFETCH_H) and 4 header-only channels (one per DISPATCH_H). Each remote chip has the standard 4-kernel quad.

MMIO card: 3 (local) + 8 (PREFETCH_H) + 8 (DISPATCH_H) + 2 (FABRIC_MUX) = ~21 cores.
Each remote card: 4 cores.

<a id="dispatch-kernel-pipeline-internals--cq-command-protocol"></a>
### CQ Command Protocol

<a id="dispatch-kernel-pipeline-internals--prefetch-commands-processed-by-prefetch_"></a>
#### Prefetch commands (processed by PREFETCH_*)

| Opcode | ID | Description |
|--------|----|-------------|
| `RELAY_LINEAR` | 1 | Read linear data from NOC address, relay to downstream CB |
| `RELAY_LINEAR_H` | 2 | H-variant relay; must be sole command in fetchq entry |
| `RELAY_PAGED` | 3 | Read banked/paged data from DRAM or L1, relay to downstream |
| `RELAY_PAGED_PACKED` | 4 | Multiple paged reads from different banks |
| `RELAY_INLINE` | 5 | Copy data from CmdDatQ directly to downstream (+ optional dispatch_s channel) |
| `RELAY_INLINE_NOFLUSH` | 6 | Like RELAY_INLINE but don't flush the page yet |
| `EXEC_BUF` | 7 | Execute commands from a DRAM-backed exec buffer (trace replay) |
| `EXEC_BUF_END` | 8 | Finish exec_buf, signal completion |
| `STALL` | 9 | Drain the pipe through dispatcher (barrier) |
| `DEBUG` | 10 | Watcher/checksum logging |
| `TERMINATE` | 11 | Shutdown |
| `PAGED_TO_RINGBUFFER` | 12 | Copy paged DRAM data into local ringbuffer (trace) |
| `SET_RINGBUFFER_OFFSET` | 13 | Set read/write offset in ringbuffer |
| `RELAY_RINGBUFFER` | 14 | Relay data from ringbuffer to downstream (trace replay) |

`RELAY_INLINE` has a `dispatcher_type` field: `DISPATCH_MASTER=0` routes to DISPATCH_D's CB, `DISPATCH_SUBORDINATE=1` routes to DISPATCH_S's buffer.

<a id="dispatch-kernel-pipeline-internals--dispatch-commands-processed-by-dispatch_d--dispatch_hd"></a>
#### Dispatch commands (processed by DISPATCH_D / DISPATCH_HD)

| Opcode | ID | Description |
|--------|----|-------------|
| `WRITE_LINEAR` | 1 | NOC unicast/multicast write to worker L1 |
| `WRITE_LINEAR_H` | 2 | Linear write targeted at H-variant (passthrough) |
| `WRITE_LINEAR_H_HOST` | 3 | Write to host completion queue; D-variant relays through return fabric |
| `WRITE_PAGED` | 4 | Banked/paged write to DRAM or L1 |
| `WRITE_PACKED` | 5 | Write same data to multiple unicast/multicast NOC addresses |
| `WRITE_PACKED_LARGE` | 6 | Variable-size payloads per sub-command |
| `WAIT` | 7 | Barrier + optional wait on L1 or stream register |
| `SINK` | 8 | Data sink (testing only) |
| `DEBUG` | 9 | Watcher/checksum logging |
| `DELAY` | 10 | Spin delay (testing only) |
| `EXEC_BUF_END` | 11 | Notify PREFETCH_H of exec_buf completion |
| `SET_WRITE_OFFSET` | 12 | Set relocation offsets (up to 4) for all non-host writes |
| `TERMINATE` | 13 | Shutdown |
| `SEND_GO_SIGNAL` | 14 | Multicast + unicast GO to workers |
| `NOTIFY_SUBORDINATE_GO_SIGNAL` | 15 | D → S: "safe to send GO now" (increment sync counter) |
| `SET_NUM_WORKER_SEMS` | 16 | Set number of active worker semaphores |
| `SET_GO_SIGNAL_NOC_DATA` | 17 | Populate NOC XY table for unicast GO signals |
| `TIMESTAMP` | 18 | Write 64-bit cycle counter to DRAM |

<a id="dispatch-kernel-pipeline-internals--go-signal-and-launch-message-protocol"></a>
### GO Signal and Launch Message Protocol

The launch/GO mechanism is how programs start executing on worker cores.

<a id="dispatch-kernel-pipeline-internals--launch-message"></a>
#### Launch message

`launch_msg_t` is written to each worker core's mailbox ring buffer (8 entries at `dev_msgs.mailboxes.launch[]`) via `CQ_DISPATCH_CMD_WRITE_PACKED` with type `PACKED_WRITE_FLAG_TYPE_LAUNCH`. Contains:

- Kernel text offsets within L1 (per-RISC: BRISC, NCRISC, TRISC0/1/2)
- Semaphore offsets
- CB layout configuration
- RTA (runtime args) offsets
- Enables bitmask (which RISCs participate)
- NOC ID
- Dispatch mode flag
- Host-assigned program ID

<a id="dispatch-kernel-pipeline-internals--go-signal"></a>
#### GO signal

A single 32-bit `go_msg_t` containing `{dispatch_message_offset, master_x, master_y, signal}`. Signal values:

| Value | Name | Meaning |
|-------|------|---------|
| `0x00` | `RUN_MSG_DONE` | Worker completed, back to idle |
| `0x80` | `RUN_MSG_GO` | Start executing the program in the launch message |
| `0xE0` | `RUN_MSG_RESET_READ_PTR_FROM_HOST` | Reset mailbox read pointer |

<a id="dispatch-kernel-pipeline-internals--go-signal-flow"></a>
#### GO signal flow

1. DISPATCH writes `RESET_READ_PTR_FROM_HOST` to all worker `GO_MSG` addresses.
2. DISPATCH writes `GO_MSG_INDEX` (which slot in the 8-entry ring to read).
3. DISPATCH writes `launch_msg_t` to the correct ring slot on each worker.
4. DISPATCH writes kernel binary + CB config into worker L1.
5. DISPATCH issues `CQ_DISPATCH_CMD_SEND_GO_SIGNAL` → multicasts `RUN_MSG_GO` to all workers.
6. BRISC firmware on each worker sees `RUN_MSG_GO`, reads `launch_msg_t`, deasserts NCRISC/TRISCs from reset, loads kernel text, jumps in.
7. On completion, BRISC writes `RUN_MSG_DONE` back and atomically increments DISPATCH_S's stream register.

<a id="dispatch-kernel-pipeline-internals--distributed-dispatch_s-flow"></a>
#### Distributed DISPATCH_S flow

When DISPATCH_S is on a separate core from DISPATCH_D:

1. DISPATCH_D processes `NOTIFY_SUBORDINATE_GO_SIGNAL` → increments sync semaphore on DISPATCH_S.
2. DISPATCH_D continues immediately (can start queuing next program).
3. DISPATCH_S waits for sync semaphore, then multicasts GO.
4. DISPATCH_S waits for worker completion count on stream register.
5. DISPATCH_S mirrors completion count to DISPATCH_D's stream register via `noc_inline_dw_write`.


<a id="dispatch-kernel-pipeline-internals--multi-chip-dispatch-flow-end-to-end"></a>
### Multi-Chip Dispatch Flow (End-to-End)

Complete path for launching a kernel on a remote (non-PCIe) card:

```
 1. Host CPU writes CQ commands into pinned sysmem (hugepage)
 2. Host pokes 16-bit size token into PREFETCH_H's L1 queue
 3. PREFETCH_H DMA-reads commands from sysmem via PCIe
 4. PREFETCH_H NOC-writes command pages into FABRIC_MUX's L1 buffer
 5. FABRIC_MUX NOC-writes pages into ERISC sender channel's L1 buffer
 6. ERISC transmits over ethernet PHY
 7. Remote ERISC receives, NOC-writes directly into PREFETCH_D's L1 cmddat buffer
 8. Remote ERISC increments PREFETCH_D's upstream semaphore
 9. PREFETCH_D reads from cmddat, feeds DISPATCH_D and DISPATCH_S
10. DISPATCH_D interprets commands → NOC-writes kernel binary + args to worker L1
11. DISPATCH_S multicasts GO signal to all workers
12. Workers execute kernel
13. Workers atomically increment DISPATCH_S's stream register when done
14. DISPATCH_D relays completion through RETURN_FABRIC_MUX → ethernet → DISPATCH_H
15. DISPATCH_H writes completion event to host sysmem via PCIe
```

Step 7 is zero-copy: the ERISC writes directly to PREFETCH_D's known L1 address via NOC 1. No bounce buffer or Tensix intermediary.

<a id="dispatch-kernel-pipeline-internals--two-paths-command-dispatch-vs-data-movement"></a>
### Two Paths: Command Dispatch vs Data Movement

| Property | Command dispatch (host → chip) | Data movement (chip → chip) |
|----------|-------------------------------|----------------------------|
| Goes through PREFETCH/DISPATCH? | Yes, always | No |
| Tensix cores consumed on remote | 3-4 (PREFETCH_D + DISPATCH_D + DISPATCH_S + RETURN_MUX) | 0 |
| Who initiates? | Host CPU via CQ | Tensix kernel via `fabric_async_write()` |
| ERISC's role | Deliver into PREFETCH_D's L1 buffer | Deliver directly to target NOC address |
| Host involvement at runtime | Writes to sysmem, reads completions | None |

For fabric data movement (all-reduce, tensor sharding, etc.), the ERISC writes directly to the destination NOC address specified in the packet header. No dispatch pipeline involvement. See `multi-host-and-remote-card-architecture.md` for worked examples.

<a id="fast-dispatch-abi"></a>
## Fast dispatch ABI: memory layout and compile-time defines (Blackhole)
<a id="fast-dispatch-abi--fast-dispatch-abi-memory-layout-and-compile-time-defines-blackhole"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

CQ control area layouts, compile-time defines for prefetch/dispatch kernels, and IOMMU/hugepage details. This is the low-level ABI reference.

For the dispatch pipeline architecture, kernel catalog, and command protocol, see `dispatch-kernel-pipeline-internals.md`. For blackhole-py implementation notes and bugs, see `fast-dispatch-implementation-notes.md`.

<a id="fast-dispatch-abi--iommu-vs-hugepage-path"></a>
### IOMMU vs hugepage path

`TENSTORRENT_IOCTL_PIN_PAGES` inputs:
```
class tenstorrent_pin_pages_in:
  output_size_bytes: u32
  flags: u32
  virtual_address: u64
  size: u64
```

Flags:
- `TENSTORRENT_PIN_PAGES_CONTIGUOUS` (requires hugepages)
- `TENSTORRENT_PIN_PAGES_NOC_DMA` (map to NOC address space)

With IOMMU:
- use `TENSTORRENT_PIN_PAGES_NOC_DMA` only

Without IOMMU:
- use `TENSTORRENT_PIN_PAGES_CONTIGUOUS | TENSTORRENT_PIN_PAGES_NOC_DMA`

NOC address base for PCIe/sysmem:
```
PCIE_NOC_BASE = 4ULL << 58 = 0x0400_0000_0000_0000
```

<a id="fast-dispatch-abi--dispatch-core-coordinates"></a>
### Dispatch core coordinates

From `blackhole_140_arch.yaml`:
```
dispatch_cores:
  [[-1, 0], [-1, 1], [-1, 2], [-1, 3], [-1, 4], [-1, 5], [-1, 6], [-1, 7], [-1, 8], [-1, 9]]
```

- `[-1, y]` means last logical column, row y
- For unharvested 14x10 grid: logical `(13, y)`
- Physical NOC0: `(16, 2..11)`

Core allocation order:
1. Prefetcher
2. Dispatcher
3. Optional Dispatch_S

<a id="fast-dispatch-abi--host-cq-control-area-layout-sysmem"></a>
### Host CQ control area layout (sysmem)

`CommandQueueHostAddrType` offsets are `type * PCIE_ALIGNMENT`:
- `ISSUE_Q_RD = 0x00`
- `ISSUE_Q_WR = 0x40`
- `COMPLETION_Q_WR = 0x80`
- `COMPLETION_Q_RD = 0xC0`
- `UNRESERVED (issue data start) = 0x100`

`PCIE_ALIGNMENT = 64` bytes on Blackhole.

<a id="fast-dispatch-abi--device-cq-control-area-layout-prefetch-core-l1"></a>
### Device CQ control area layout (prefetch core L1)

Relative to `DEFAULT_UNRESERVED`:
- `PREFETCH_Q_RD_PTR_OFF = 0x00` (4B)
- `PREFETCH_Q_PCIE_RD_PTR_OFF = 0x04`
- `COMPLETION_Q_WR_PTR_OFF = 0x10`
- `COMPLETION_Q_RD_PTR_OFF = 0x20`
- `COMPLETION_Q0_LAST_EVENT_PTR_OFF = 0x30`
- `COMPLETION_Q1_LAST_EVENT_PTR_OFF = 0x40`
- `DISPATCH_S_SYNC_SEM_OFF = 0x50`
- `FABRIC_HEADER_RB_OFF = 0xD0`
- `FABRIC_SYNC_STATUS_OFF = 0x150`
- `UNRESERVED_OFF = 0x180` (aligned to 64B)

`UNRESERVED` is where `PREFETCH_Q` (ring of `uint16_t` sizes) starts.

<a id="fast-dispatch-abi--prefetcher--dispatcher-runtime-args"></a>
### Prefetcher + dispatcher runtime args

Prefetch and dispatch firmware kernels take only **3 runtime args**, all `0` for single-chip MMIO:
```
rt_args[0] = my_dev_id        = 0
rt_args[1] = to_dev_id        = 0
rt_args[2] = router_direction  = 0
```

`dispatch_s` takes **zero** runtime args.

<a id="fast-dispatch-abi--all-real-config-is-compile-time-defines"></a>
### All real config is compile-time defines

Every meaningful configuration value — buffer addresses, NOC coordinates, queue sizes, semaphore IDs — is passed as `#define` macros at kernel compile time. Pre-compiled ELFs are device-configuration-specific.

Defines are set in:
- `tt_metal/impl/dispatch/kernel_config/prefetch.cpp`
- `tt_metal/impl/dispatch/kernel_config/dispatch.cpp`
- `tt_metal/impl/dispatch/kernel_config/fd_kernel.cpp`

<a id="fast-dispatch-abi--prefetch-kernel-defines-prefetch_hd-single-chip"></a>
### Prefetch kernel defines (PREFETCH_HD, single-chip)

<a id="fast-dispatch-abi--base-defines-all-fd-kernels"></a>
#### Base defines (all FD kernels)
- `DISPATCH_KERNEL = 1`
- `FD_CORE_TYPE = 0`
- `FORCE_DPRINT_OFF = 1` (unless dprint reads dispatch cores)
- `FORCE_WATCHER_OFF = 1` (if watcher dispatch disabled)

<a id="fast-dispatch-abi--noc-coordinates"></a>
#### NOC coordinates
- `MY_NOC_X`, `MY_NOC_Y`
- `UPSTREAM_NOC_INDEX`
- `UPSTREAM_NOC_X`, `UPSTREAM_NOC_Y`
- `DOWNSTREAM_NOC_X`, `DOWNSTREAM_NOC_Y`
- `DOWNSTREAM_SUBORDINATE_NOC_X`, `DOWNSTREAM_SUBORDINATE_NOC_Y`

<a id="fast-dispatch-abi--buffer-addresses-and-sizes"></a>
#### Buffer addresses and sizes
- `PREFETCH_Q_BASE`
- `PREFETCH_Q_SIZE`
- `PREFETCH_Q_RD_PTR_ADDR`
- `PREFETCH_Q_PCIE_RD_PTR_ADDR`
- `CMDDAT_Q_BASE`
- `CMDDAT_Q_SIZE`
- `CMDDAT_Q_LOG_PAGE_SIZE`
- `CMDDAT_Q_PAGES`
- `CMDDAT_Q_BLOCKS`
- `SCRATCH_DB_BASE`
- `SCRATCH_DB_SIZE`
- `PCIE_BASE`
- `PCIE_SIZE`
- `RINGBUFFER_SIZE`

<a id="fast-dispatch-abi--downstream-dispatch-buffer-config"></a>
#### Downstream (dispatch) buffer config
- `DOWNSTREAM_CB_BASE`
- `DOWNSTREAM_CB_LOG_PAGE_SIZE`
- `DOWNSTREAM_CB_PAGES`
- `MY_DOWNSTREAM_CB_SEM_ID`
- `DOWNSTREAM_CB_SEM_ID`
- `DOWNSTREAM_SYNC_SEM_ID`

<a id="fast-dispatch-abi--dispatch_s-buffer-config"></a>
#### Dispatch_S buffer config
- `DISPATCH_S_BUFFER_BASE`
- `DISPATCH_S_BUFFER_SIZE`
- `DISPATCH_S_CB_LOG_PAGE_SIZE`
- `MY_DISPATCH_S_CB_SEM_ID`
- `DOWNSTREAM_DISPATCH_S_CB_SEM_ID`

<a id="fast-dispatch-abi--fabric-all-0-for-single-chip-hd"></a>
#### Fabric (all 0 for single-chip HD)
- `FABRIC_HEADER_RB_BASE`
- `FABRIC_HEADER_RB_ENTRIES`
- `MY_FABRIC_SYNC_STATUS_ADDR`
- `FABRIC_MUX_*` (11 fields)
- `FABRIC_WORKER_*_SEM` (3 fields)
- `NUM_HOPS`
- `EW_DIM`
- `TO_MESH_ID`

<a id="fast-dispatch-abi--variant-flags"></a>
#### Variant flags
- `IS_D_VARIANT = 1`
- `IS_H_VARIANT = 1`
- `FABRIC_RELAY` not defined (only set for split variants)

<a id="fast-dispatch-abi--dispatch-kernel-defines-dispatch_hd-single-chip"></a>
### Dispatch kernel defines (DISPATCH_HD, single-chip)

Additional dispatch-specific defines:
- `DISPATCH_CB_BASE`
- `DISPATCH_CB_LOG_PAGE_SIZE`
- `DISPATCH_CB_PAGES`
- `DISPATCH_CB_BLOCKS`
- `MY_DISPATCH_CB_SEM_ID`
- `UPSTREAM_DISPATCH_CB_SEM_ID`
- `UPSTREAM_SYNC_SEM`
- `COMMAND_QUEUE_BASE_ADDR`
- `COMPLETION_QUEUE_BASE_ADDR`
- `COMPLETION_QUEUE_SIZE`
- `HOST_COMPLETION_Q_WR_PTR`
- `DEV_COMPLETION_Q_WR_PTR`
- `DEV_COMPLETION_Q_RD_PTR`
- `DISPATCH_S_SYNC_SEM_BASE_ADDR`
- `MAX_NUM_WORKER_SEMS`
- `MAX_NUM_GO_SIGNAL_NOC_DATA_ENTRIES`
- `MCAST_GO_SIGNAL_ADDR`
- `UNICAST_GO_SIGNAL_ADDR`
- `PACKED_WRITE_MAX_UNICAST_SUB_CMDS`
- `WORKER_MCAST_GRID`
- `NUM_WORKER_CORES_TO_MCAST`
- `DISTRIBUTED_DISPATCHER`
- `FIRST_STREAM_USED`
- `SPLIT_PREFETCH`

<a id="fast-dispatch-abi--how-noc-write-bytes-are-packed-conceptual"></a>
### How NoC write bytes are packed (conceptual)

Single unicast write (inline payload):
1. Prefetch command `CQ_PREFETCH_CMD_RELAY_INLINE`
2. Payload begins with a dispatch write command, followed by raw bytes
3. Padding up to 64B boundary

Stream layout:
```
[CQPrefetchCmd 16B: RELAY_INLINE, length=32+N, stride=align(16+(32+N),64)]
[CQDispatchCmdLarge 32B: WRITE_LINEAR, noc_xy_addr=(y<<6)|x, addr=dst, length=N]
[data bytes N]
[pad to 64B]
```

Relevant defs:
- `tt_metal/impl/dispatch/kernels/cq_commands.hpp`
- `tt_metal/impl/dispatch/device_command.cpp`

<a id="slow-dispatch-tlb-writes"></a>
## Slow Dispatch: What TLB Writes Actually Happen
<a id="slow-dispatch-tlb-writes--slow-dispatch-what-tlb-writes-actually-happen"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

When `TT_USB=1` (or the CQ firmware isn't available), blackhole-py falls back to **slow dispatch** — the host directly MMIO-writes everything into each worker core's L1 through TLB windows. No prefetch core, no dispatch core, no command queue. Just the host CPU driving the NOC through the PCIe BAR.

<a id="slow-dispatch-tlb-writes--tlb-mechanics"></a>
### TLB mechanics

A **TLB window** is a 2 MB MMIO region mapped into the host's virtual address space via the `tenstorrent` kernel driver. The driver's `CONFIGURE_TLB` ioctl sets up the NOC routing:

```
NocTlbConfig {
  addr:    u64    # L1 base address (aligned to TLB size)
  x_start: u16    # NOC X start (for mcast: left edge)
  y_start: u16    # NOC Y start (for mcast: top edge)
  x_end:   u16    # NOC X end (for mcast: right edge)
  y_end:   u16    # NOC Y end (for mcast: bottom edge)
  noc:     u8     # NOC 0 or 1
  mcast:   u8     # 0=unicast, 1=multicast
  ordering: u8    # STRICT(2) or RELAXED(0)
}
```

When `mcast=1`, any write to the TLB window hits **every core** in the bounding box `(x_start, y_start)` to `(x_end, y_end)`. This is how one MMIO write can program 60+ cores at once.

Writes use the **uncached (UC) mapping** (`mmap_offset_uc`) to guarantee write ordering. The driver exposes both a write-combining (WC) mapping for bulk data and a UC mapping for ordered control writes.

<a id="slow-dispatch-tlb-writes--the-full-sequence-for-one-program"></a>
### The full sequence for one program

Here's what `SlowDevice._run_single()` does for add1, step by step. All writes go through mcast TLB windows configured for the worker core grid.

<a id="slow-dispatch-tlb-writes--step-1-reset-worker-state"></a>
#### Step 1: Reset worker state

```
TLB mcast write -> L1 0x000370 (GO_MSG)
  Rectangle: (1,2)-(7,11)  = 60 cores
  Rectangle: (10,2)-(13,11) = 40 cores
  ... additional rects for remaining workers
  Data: GoMsg { signal = 0xE0 (RESET_READ_PTR_FROM_HOST), master_x=0, master_y=0 }
        + 4 bytes zero padding
  Total: 8 bytes per mcast group
```

This tells each worker's BRISC firmware to reset its internal read pointers. The firmware sees `signal=0xE0` in the GO_MSG mailbox and resets without starting any kernel.

<a id="slow-dispatch-tlb-writes--step-2-upload-per-core-runtime-args-rta"></a>
#### Step 2: Upload per-core runtime args (RTA)

```
TLB mcast write -> L1 0x0082B0 (KERNEL_CONFIG_BASE)
  Per unique RTA group — cores with identical args are grouped into mcast rectangles.

  For add1: each core gets unique args (different tile offsets), so this typically
  degrades to one mcast write per column, or one per core in the worst case.

  Data per core (24 bytes):
    writer_args:  [dst_buf_addr: u32, tile_offset: u32, n_tiles: u32]
    reader_args:  [src_buf_addr: u32, tile_offset: u32, n_tiles: u32]
    compute_args: [n_tiles: u32]
    (packed contiguously as little-endian u32s)
```

The RTA sits at the base of `KERNEL_CONFIG_BASE`. Each RISC-V core reads its arguments with `get_arg_val<uint32_t>(N)` which indexes into this region.

<a id="slow-dispatch-tlb-writes--step-3-upload-per-core-launchmsg"></a>
#### Step 3: Upload per-core LaunchMsg

```
TLB mcast write -> L1 0x000070 (LAUNCH = MAILBOX_BASE + 0x10)
  Per unique LaunchMsg group.

  Data: LaunchMsg / KernelConfigMsg (88 bytes):
    kernel_config_base = [0x82B0, 0x82B0, 0x82B0]  (one per ProgrammableCoreType)
    sem_offset = [24, 24, 24]
    local_cb_offset = offset to CB config within KERNEL_CONFIG_BASE region
    local_cb_mask = 0x10001  (bits set for CB 0 and CB 16)
    enables = 0x1F  (all 5 RISCs: BRISC + NCRISC + TRISC0 + TRISC1 + TRISC2)
    mode = DISPATCH_MODE_HOST (1)  <-- NOTE: host mode, not dev mode
    brisc_noc_id = 1
    kernel_text_offset = [brisc_off, ncrisc_off, trisc0_off, trisc1_off, trisc2_off]
```

Key difference from fast dispatch: `mode = DISPATCH_MODE_HOST (1)` tells the firmware that the host will poll for completion (no dispatch core to signal).

<a id="slow-dispatch-tlb-writes--step-4-upload-shared-kernel-image"></a>
#### Step 4: Upload shared kernel image

```
TLB mcast write -> L1 0x0082B0 + shared_off (KERNEL_CONFIG_BASE + offset)
  Per unique kernel image group. For add1, all cores run the same kernels,
  so this is one mcast write per rectangle.

  Rectangle: (1,2)-(7,11) = 60 cores
  Rectangle: (10,2)-(13,11) = 40 cores
  ...

  Data (~6 KB):
    [LocalCBConfig[0]:  addr=0x37000, size=4096, pages=2, page_size=2048]
    [LocalCBConfig[16]: addr=0x37800, size=4096, pages=2, page_size=2048]
    [padding to 17 CB slots * 16 bytes]
    [BRISC XIP binary  - writer kernel, ~800 bytes]
    [NCRISC XIP binary - reader kernel, ~900 bytes]
    [TRISC0 XIP binary - unpack, ~600 bytes]
    [TRISC1 XIP binary - math (SFPI add1), ~1200 bytes]
    [TRISC2 XIP binary - pack, ~500 bytes]
```

The kernel binaries are compiled as **XIP (execute-in-place)** — position-independent code relocated to run directly from their L1 address. No loader needed on-device; the firmware just jumps to `kernel_text_offset[proc]`.

<a id="slow-dispatch-tlb-writes--step-5-send-go"></a>
#### Step 5: Send GO

```
TLB mcast write -> L1 0x000370 (GO_MSG)
  Rectangle: (1,2)-(7,11) = 60 cores
  Rectangle: (10,2)-(13,11) = 40 cores
  ...
  Data: GoMsg { signal = 0x80 (RUN_MSG_GO) }
  Total: 4 bytes per mcast group
```

This is the launch. Every worker's BRISC firmware is spinning on `GO_MSG+3` (the signal byte). When it sees `0x80`:
1. BRISC reads the `LaunchMsg` from L1 0x70
2. BRISC sets up CB pointers from the `local_cb_offset` region
3. BRISC releases NCRISC and TRISCs from reset (they were held since firmware upload)
4. All 5 RISCs jump to their respective `kernel_text_offset` and start executing

<a id="slow-dispatch-tlb-writes--step-6-poll-for-completion"></a>
#### Step 6: Poll for completion

```
For each worker core (x, y):
  TLB unicast read -> L1 0x000373 (GO_MSG + 3, the signal byte)
  Spin until value == 0x00 (RUN_MSG_DONE)
```

When each kernel finishes, the firmware writes `signal = 0x00` back to `GO_MSG+3`. The host polls each core individually. This is the main latency cost of slow dispatch — 118 sequential TLB reads, each a PCIe round-trip.

<a id="slow-dispatch-tlb-writes--total-mmio-traffic"></a>
### Total MMIO traffic

For add1 on 118 cores:

| Step | Write target | Mcast groups | Bytes per group | Total bytes |
|------|-------------|--------------|-----------------|-------------|
| Reset GO_MSG | 0x000370 | ~4 rects | 8 | ~32 |
| RTA | 0x0082B0 | 118 (per-core) | ~28 | ~3.3 KB |
| LaunchMsg | 0x000070 | 1 (uniform) | 88 | ~350 |
| Shared image | 0x0082D0+ | ~4 rects | ~6000 | ~24 KB |
| GO | 0x000370 | ~4 rects | 4 | ~16 |
| **Poll** | 0x000373 | 118 reads | 1 | 118 PCIe reads |

Total write traffic: ~28 KB. Total TLB reconfigurations: ~130 `CONFIGURE_TLB` ioctls.

The bottleneck isn't bandwidth — it's the **latency of TLB reconfigurations** and the **sequential polling loop**. Each `CONFIGURE_TLB` ioctl is a kernel round-trip. The polling loop makes 118 PCIe BAR reads. This is why fast dispatch exists.
