# Distributed Training in TT-Metal: Low-Level Mechanics and Blackhole-Py Integration Plan

## Executive summary

TT-Metal distributed is not a hidden runtime that auto-magically does NCCL-style behavior. It is a mesh-native execution model with explicit placement and explicit communication.

- **Yes, you can control all N cards** via one logical `MeshDevice`.
- **All-reduce equivalent** exists (`ttnn.all_reduce`), but you decide when to invoke it.
- **Model/tensor sharding equivalent** exists via mesh mappers/composers and sharded mesh buffers.
- **Under the hood**, this is built from mesh command queues, mesh workload dispatch, mesh buffer layouts, and fabric-aware collectives.
- **For blackhole-py**, you can stage integration in layers: first host-orchestrated SPMD multi-card, then real inter-card collectives.

## 1) What "distributed" means in TT-Metal at low level

At C++ runtime level, distributed is centered on four primitives:

1. **`MeshDevice`**: logical 2D view of physical chips.
2. **`MeshWorkload`**: maps one or more programs to mesh coordinate ranges.
3. **`MeshBuffer`**: distributed memory object (replicated or sharded global layout).
4. **`MeshCommandQueue` APIs**: enqueue workload, enqueue mesh reads/writes, synchronize/events/trace.

This is direct in:

- `tt-metal/tt_metal/api/tt-metalium/mesh_device.hpp`
- `tt-metal/tt_metal/api/tt-metalium/mesh_workload.hpp`
- `tt-metal/tt_metal/api/tt-metalium/mesh_buffer.hpp`
- `tt-metal/tt_metal/api/tt-metalium/distributed.hpp`

### 1.1 Control plane vs data plane

- **Control plane**: device discovery, mesh shape, rank/host bindings, scope (global/local).
- **Data plane**: actual kernel launch and memory movement on all mesh members.

You see this split in:

- mesh/rank env bindings and local/global scope tests: `tt-metal/tests/tt_metal/distributed/test_control_plane_local_mesh_binding.cpp`
- workload + IO + CQ synchronization + tracing examples: `tt-metal/tt_metal/programming_examples/distributed/4_distributed_trace_and_events/distributed_trace_and_events.cpp`

## 2) Equivalent of all-reduce / all-gather / collectives

The most practical entry points are TT-NN ops backed by TT-Metal CCL:

- `ttnn.all_reduce(...)`
- `ttnn.all_gather(...)`
- `ttnn.experimental.all_reduce_async(...)`

Bindings and operation signatures are in:

- `tt-metal/ttnn/cpp/ttnn/operations/ccl/all_reduce/all_reduce_nanobind.cpp`
- `tt-metal/ttnn/cpp/ttnn/operations/ccl/all_gather/all_gather_nanobind.cpp`
- `tt-metal/ttnn/cpp/ttnn/operations/experimental/ccl/all_reduce_async/all_reduce_async_nanobind.cpp`

Low-level implication: collective ops are explicit graph nodes in your program, not implicit side effects of optimizer calls.

## 3) Equivalent of model sharding

There are two levels:

1. **Tensor distribution API** (logical): map/compose tensors across mesh.
2. **MeshBuffer layout API** (physical-ish): define global memory as sharded or replicated.

Key files:

- `tt-metal/ttnn/api/ttnn/distributed/distributed_tensor.hpp`
- `tt-metal/ttnn/api/ttnn/distributed/distributed_configs.hpp`
- `tt-metal/tt_metal/api/tt-metalium/mesh_buffer.hpp`

Important config details:

- `MeshMapperConfig::Replicate` and `MeshMapperConfig::Shard{dim}` define placement along mesh dimensions.
- `MeshComposerConfig` defines how shards are concatenated back.
- `ShardedBufferConfig` sets global size/shape + shard shape + orientation.

## 4) Do we control all N cards, and how is that scoped?

Yes. There are multiple modes of control:

- **Single process, one mesh**: open one `MeshDevice` spanning all visible devices.
- **Multi-process partitioning**: use `TT_VISIBLE_DEVICES` to give each process a subset of PCIe devices.
- **Multi-host / bound ranks**: use `TT_MESH_ID` and `TT_MESH_HOST_RANK` to bind rank-local view into a larger mesh graph.

References:

- `tt-metal/tech_reports/Programming_Mesh_of_Devices/Programming_Mesh_of_Devices_with_TT-NN.md`
- `tt-metal/tests/tt_metal/distributed/multiprocess/README.md`
- `tt-metal/tests/tt_metal/distributed/test_control_plane_local_mesh_binding.cpp`

## 5) Low-level execution flow (what actually happens)

Ignoring front-end sugar, the distributed loop is:

1. Open mesh and CQ(s).
2. Allocate mesh buffers with explicit layout.
3. Build programs and assign them to mesh ranges (`MeshWorkload.add_program`).
4. Enqueue data movement across mesh buffers.
5. Enqueue workload dispatch.
6. Synchronize with events or `Finish`.
7. Optional: capture/replay mesh traces for steady-state loops.

Concrete implementation examples:

- SPMD dispatch skeleton: `tt-metal/tt_metal/programming_examples/distributed/1_distributed_program_dispatch/distributed_program_dispatch.cpp`
- mesh buffer IO: `tt-metal/tt_metal/programming_examples/distributed/2_distributed_buffer_rw/distributed_buffer_rw.cpp`
- mixed homogeneous/heterogeneous mesh workloads + events + trace: `tt-metal/tt_metal/programming_examples/distributed/4_distributed_trace_and_events/distributed_trace_and_events.cpp`

## 6) Mapping TT-Metal concepts to blackhole-py today

Current blackhole-py has strong single-device low-level building blocks:

- device abstraction with slow/fast dispatch switch: `blackhole-py/device.py`
- firmware load, launch message packing, per-core multicast/unicast launch: `blackhole-py/device_runtime.py`, `blackhole-py/device_dispatch.py`
- DRAM allocator + tilize/untilize + fast drain path: `blackhole-py/dram.py`
- low-level constants/ABI structs for launch/runtime messages: `blackhole-py/defs.py`

### 6.1 Direct concept mapping

- `MeshDevice` (TT-Metal) -> **new** `MeshDevicePy` (list/grid of `Device` instances).
- `MeshWorkload` -> **new** `MeshWorkloadPy` (program + coordinate-range mapping).
- `MeshBuffer` replicated/sharded -> **new** `MeshBufferPy` with per-device `DramBuffer` handles.
- `EnqueueMeshWorkload` -> host loop dispatch to each device with deterministic order + barrier semantics.
- mesh events/trace -> later phase; start with host synchronization, then add queue/event objects.

## 7) Integration plan for blackhole-py (incremental)

### Phase 0: multi-card SPMD without inter-card collectives

Goal: run same program on N cards with explicit host-level sharding/replication.

Implement:

1. `open_mesh_device(paths_or_ids, shape)` creating `MeshDevicePy`.
2. `MeshBufferPy`:
   - replicated: same payload written to all device buffers
   - sharded: host splits payload and writes shard per device
3. `enqueue_mesh_workload(mesh, workload)`:
   - compile once if binaries reusable
   - launch per device
   - optional blocking finish across all devices

This already enables data-parallel style execution where gradients are reduced on host as a first functional baseline.

### Phase 1: host-mediated collectives (functional, slower)

Goal: API parity first, performance second.

Implement collectives by explicit readback + host reduction/scatter:

- `all_reduce_host`: read shards from each card, sum on host, write result to all cards.
- `all_gather_host`: read shards and concatenate on host, then broadcast/reshard.

This gives a correctness path for training loops before on-device/fabric CCL kernels exist in blackhole-py.

### Phase 2: device/fabric collectives (performance path)

Goal: avoid host bounce for inter-card reduction/gather.

Requirements:

- multi-device routing/topology model in blackhole-py (ring/line/mesh over available links)
- runtime support for inter-device transfer kernels and synchronization
- launch protocol additions mirroring TT-Metal CCL sequencing and semaphore/event behavior

At this phase, blackhole-py API can remain stable while backend switches from host-mediated to fabric-mediated collectives.

## 8) Practical API sketch for blackhole-py

Suggested minimal surface:

- `open_mesh_device(shape, device_ids=None)`
- `create_mesh_buffer(mesh, layout="replicated"|"sharded", global_shape=..., shard_shape=...)`
- `enqueue_mesh_workload(mesh, workload, blocking=True)`
- `all_reduce(tensor, mode="host"|"fabric")`
- `all_gather(tensor, mode="host"|"fabric")`

This keeps user-facing mental model close to TT-NN while implementation starts simple.

## 9) Risks and gotchas for blackhole-py integration

- **Compilation/cache consistency**: multi-process runs need isolated cache paths (same lesson as `TT_METAL_CACHE`).
- **Synchronization semantics**: host barriers are easier but can hide race bugs that appear with true async CQ/event execution.
- **Topology assumptions**: shape validity must reflect actual physical connectivity if/when fabric collectives are added.
- **Performance cliffs**: host-mediated collectives are much slower; use only as bootstrap for correctness.

## 10) Where to read next for implementation details

If your end goal is "add distributed to blackhole-py", study these in order:

1. `tt-metal/tt_metal/programming_examples/distributed/1_distributed_program_dispatch/distributed_program_dispatch.cpp`
2. `tt-metal/tt_metal/api/tt-metalium/mesh_workload.hpp`
3. `tt-metal/tt_metal/api/tt-metalium/mesh_buffer.hpp`
4. `tt-metal/tt_metal/programming_examples/distributed/4_distributed_trace_and_events/distributed_trace_and_events.cpp`
5. `tt-metal/ttnn/cpp/ttnn/operations/ccl/all_reduce/all_reduce_nanobind.cpp`
6. `blackhole-py/device_dispatch.py`
7. `blackhole-py/dram.py`

## References

- `tt-metal/tech_reports/Programming_Mesh_of_Devices/Programming_Mesh_of_Devices_with_TT-NN.md`
- `tt-metal/tt_metal/api/tt-metalium/mesh_device.hpp`
- `tt-metal/tt_metal/api/tt-metalium/distributed.hpp`
- `tt-metal/tt_metal/api/tt-metalium/mesh_workload.hpp`
- `tt-metal/tt_metal/api/tt-metalium/mesh_buffer.hpp`
- `tt-metal/tt_metal/programming_examples/distributed/1_distributed_program_dispatch/distributed_program_dispatch.cpp`
- `tt-metal/tt_metal/programming_examples/distributed/2_distributed_buffer_rw/distributed_buffer_rw.cpp`
- `tt-metal/tt_metal/programming_examples/distributed/4_distributed_trace_and_events/distributed_trace_and_events.cpp`
- `tt-metal/ttnn/api/ttnn/distributed/api.hpp`
- `tt-metal/ttnn/api/ttnn/distributed/distributed_configs.hpp`
- `tt-metal/ttnn/api/ttnn/distributed/distributed_tensor.hpp`
- `tt-metal/ttnn/ttnn/distributed/distributed.py`
- `tt-metal/ttnn/cpp/ttnn/operations/ccl/all_reduce/all_reduce_nanobind.cpp`
- `tt-metal/ttnn/cpp/ttnn/operations/ccl/all_gather/all_gather_nanobind.cpp`
- `tt-metal/ttnn/cpp/ttnn/operations/experimental/ccl/all_reduce_async/all_reduce_async_nanobind.cpp`
- `tt-metal/tests/ttnn/distributed/test_data_parallel_example_TG.py`
- `tt-metal/tests/ttnn/distributed/test_tensor_parallel_example_T3000.py`
- `tt-metal/tests/tt_metal/distributed/multiprocess/README.md`
- `tt-metal/tests/tt_metal/distributed/test_control_plane_local_mesh_binding.cpp`
- `blackhole-py/README.md`
- `blackhole-py/device.py`
- `blackhole-py/device_runtime.py`
- `blackhole-py/device_dispatch.py`
- `blackhole-py/dram.py`
- `blackhole-py/defs.py`
