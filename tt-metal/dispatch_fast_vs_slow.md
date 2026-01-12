# Fast vs slow dispatch in TT-Metal

This doc summarizes how TT-Metal dispatch works at a high level, and how the fast (command-queue) path differs from the slow (host-driven) path.

## High-level architecture
TT-Metal has two mutually exclusive dispatch modes:
- **Fast dispatch**: host enqueues commands to a device command queue. Firmware/dispatcher handles execution on device.
- **Slow dispatch**: host writes runtime args and launch messages directly to cores and waits for completion.

The mode is latched per process. Mixing is prohibited and will trigger a fatal check.

## Fast dispatch path (default)
**Primary entry points**
- `distributed::MeshDevice::create_unit_mesh()`
- `MeshCommandQueue` + `distributed::EnqueueMeshWorkload()`
- `distributed::Finish()`

**Execution flow (conceptual)**
1) Host builds a `Program` with kernels and circular buffers.
2) Host wraps it in a `MeshWorkload` and enqueues the workload on a `MeshCommandQueue`.
3) The command queue schedules dispatch and data movement asynchronously.
4) `Finish()` blocks until the queue is drained (if requested).

**Key characteristics**
- Supports multi-device/mesh workflows.
- Enables overlap of IO and compute and better throughput for many launches.
- Used by most programming examples and intended as the production path.

**Relevant implementation points**
- Command queue APIs and mesh workload logic live under `tt_metal/api/tt-metalium/distributed.hpp` and
  `tt_metal/api/tt-metalium/mesh_*`.
- Dispatch command processing is in `tt_metal/impl/dispatch/host_runtime_commands.cpp`.

## Slow dispatch path
**Primary entry points**
- `CreateDevice()` (single MMIO device)
- `detail::WriteToBuffer()` / `detail::ReadFromBuffer()`
- `detail::LaunchProgram()`

**Execution flow (conceptual)**
1) Host builds a `Program` with kernels and circular buffers.
2) `detail::LaunchProgram()` compiles the program, writes runtime args, configures the device, and writes launch
   messages directly to the cores.
3) Host optionally waits for all cores to finish before returning.

**Key characteristics**
- Synchronous and simpler control flow.
- Primarily single-device oriented.
- Lower throughput for many small launches (no command queue overlap).

**Relevant implementation points**
- Slow dispatch is implemented in `tt_metal/tt_metal.cpp` (`detail::LaunchProgram`).
- Runtime args + device configuration are done via `detail::WriteRuntimeArgsToDevice()` and
  `detail::ConfigureDeviceWithProgram()` inside `LaunchProgram`.

## Why mixing is forbidden
A global dispatch state is latched on first use via `detail::DispatchStateCheck()` (see
`tt_metal/impl/dispatch/host_runtime_commands.cpp`). If you call a fast-dispatch API after slow dispatch (or vice versa),
TT-Metal throws:

```
TT_FATAL: Mixing fast and slow dispatch is prohibited!
```

## How to select a mode
- **Fast dispatch** is the default. Use the distributed/mesh APIs.
- **Slow dispatch** requires setting `TT_METAL_SLOW_DISPATCH_MODE=1` before device initialization, or calling
  `setenv("TT_METAL_SLOW_DISPATCH_MODE", "1", 1)` before any TT-Metal API usage.

## Guidance for a minimal C ABI
- If you want the smallest surface for a Python CFFI prototype: use slow dispatch.
- If you want scalability and production-like behavior: wrap fast dispatch (command queues + mesh workload).

## Example references in this repo
- Slow dispatch, single device: `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`
- Fast dispatch, mesh: `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file_distributed.cpp`
