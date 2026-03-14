# Kernel loading, XIP packing, and ABI

This consolidates the kernel-config packing rules, XIP behavior, runtime arg ABI, and the add1_sfpu trace.

## Kernel-config buffer layout (slow dispatch)

TT-metal packs everything into the kernel-config ring buffer at `TensixL1.KERNEL_CONFIG_BASE`:
- Runtime args (RTA) at offset `0x0`
- Common runtime args (CRTA) aligned to 16B
- Local CB configs at `local_cb_offset`
- Remote CB configs at `remote_cb_offset`
- Kernel text blobs appended next, 16B-aligned

For `add1_sfpu_single_file.cpp` (observed on Blackhole):
- `kernel_config_base = 0x82b0`
- `local_cb_offset = 0x20`
- `remote_cb_offset = 0x130`
- `kernel_text_offset = [0x130, 0x3b0, 0x610, 0xa10, 0xcb0]`

### Local CB config sizing

`max_local_end_index = 32 - clz(local_cb_mask)`
- size = `max_local_end_index * 16B`

### Remote CB config sizing

`(32 - min_remote_cb_start_index) * 8B`

## XIP (Execute-In-Place)

TT-metal commonly uses `CONTIGUOUS_XIP`:
- Applies `ElfFile::MakeExecuteInPlace()` to rewrite relocations
- Packs PT_LOAD segments contiguously
- Uploads the packed blob to the kernel-config region

In pure-py, a minimal equivalent is:
1. Parse ELF PT_LOAD segments
2. 4B-pad each segment
3. Concatenate in ELF order
4. Upload the blob contiguously to L1 at `kernel_text_offset`

Note: `*.elf.xip.elf` files are post-transform debug dumps; the bytes are what gets uploaded.

## Runtime args ABI

- Runtime args are 4-byte values stored in L1 at `kernel_config_base + rta_offset`.
- `get_arg_val<T>(idx)` reads `rta_l1_base[idx]`.
- Common runtime args use `get_common_arg_val<T>(idx)`.

## Mailboxes (launch/go)

Launch/go messages live in the L1 mailbox region derived from `MEM_MAILBOX_BASE`.

Host writes:
1. `launch_msg_t` to `LAUNCH`
2. `go_msg_t` with `signal = RUN_MSG_GO` to `GO_MSG`

Polling:
- read `GO_MSG.signal` until it becomes `RUN_MSG_DONE`.

## Add1 trace (single-file example)

### B1) Common high-level structure
- Three kernels (copyin, compute, copyout) constructed from strings:
  - Reader: `DataMovementProcessor::RISCV_1`
  - Compute: `ComputeConfig`
  - Writer: `DataMovementProcessor::RISCV_0`
- Copyin/copyout use TensorAccessor-based DRAM tiles and NOC DMA primitives.
- Compute kernel reads from CB0, does SFPU add, writes to CB16.

### B2) Slow dispatch (“1-device”) path

Entry point: `add1_sfpu_single_file.cpp` with `TT_METAL_SLOW_DISPATCH_MODE=1`.

1) Program creation + buffer allocation
- `CreateDevice` creates a local device.
- DRAM buffers allocated via `CreateBuffer` with `BufferType::DRAM`.

2) Kernel compilation
- `detail::CompileProgram()` invokes `ProgramImpl::compile`.
- `ProgramImpl::compile` calls `kernel->generate_binaries()` and `kernel->read_binaries()`.

3) Runtime args and config
- `SetRuntimeArgs` stores args in kernel objects.
- `detail::WriteRuntimeArgsToDevice` writes runtime args to L1 at offsets from the kernel config base.

4) Launch
- `LaunchProgram` writes `launch_msg_t` and `go_msg_t` directly to each core’s mailbox and asserts reset/go.
- Mailbox addresses are derived from `MEM_MAILBOX_BASE`.

5) Sync + readback
- Completion is polled by reading device state (`wait_until_cores_done`).
- `ReadFromBuffer` reads DRAM back via `Cluster::read_dram_vec`.

### Lowest-level PCIe behavior (slow dispatch)
- Host writes to device L1/DRAM via TLB windows (`TTDevice::write_to_device` → `TlbWindow::write_block_reconfigure`).
- All host accesses to device memory are MMIO via TLB windows allocated/configured with tt-kmd.


## Python → C FFI kernel launch (verbatim)

# Python -> C FFI for TT-Metal kernel launch

## Goal
Provide a minimal C ABI so Python (e.g., tinygrad via clang2py) can:
- create a device/program
- set up buffers and circular buffers
- compile and launch 1+ kernels (dataflow + compute)
- read back results

This avoids pulling in TTNN and keeps the API narrow.

## Key points
- TT-Metal host APIs are C++ (std::vector, std::variant, std::shared_ptr), so Python bindings need a C ABI wrapper.
- Kernels are compiled by TT-Metal's JIT build system at runtime.
  - Host build just links `TT::Metalium`.
  - Kernel code can be file-based or passed as strings with `CreateKernelFromString`.
- Rewriting TT-Metal in C is not practical; it would duplicate kernel compilation, cache, dispatch, and device setup.

## Minimal C ABI surface
Use opaque handles and POD args only. No C++ types in headers.

Suggested handles:
- `ttm_device_t*`
- `ttm_program_t*`
- `ttm_buffer_t*`
- `ttm_kernel_t*`
- `ttm_cb_t*`

Suggested API (shape only):
- device: `ttm_set_root_dir`, `ttm_device_create`, `ttm_device_close`
- program: `ttm_program_create`, `ttm_program_destroy`
- buffers: `ttm_buffer_create_interleaved`, `ttm_buffer_write`, `ttm_buffer_read`
- circular buffers: `ttm_cb_create`
- kernels:
  - `ttm_kernel_create_dataflow`
  - `ttm_kernel_create_compute`
  - `ttm_kernel_create_from_string` (optional for embedded kernels)
- runtime args: `ttm_set_runtime_args`
- launch: `ttm_program_launch`

Vector arguments become `(const uint32_t* args, size_t count)` and are copied into `std::vector` inside the C++ wrapper.

## Single-file kernel option
It is feasible to embed all three kernels (reader/compute/writer) as strings in one host file and call `CreateKernelFromString`.
- This keeps host + kernel definitions co-located.
- The runtime JIT still handles compilation and caching.
- `SetRootDir()` or `TT_METAL_HOME` must be set so kernel includes resolve.

## Scope for tinygrad
Implement only kernel launch + buffer management in the C ABI. Leave TTNN out of the dependency graph.
TT-UMD Python bindings are driver-level and do not replace the TT-Metal kernel pipeline.

## Single-file example in this repo
There is a single-file variant of the add1 SFPU example that embeds all three kernels as raw strings and uses `CreateKernelFromString`:
- `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`

It builds a host executable that links `TT::Metalium`, JIT-compiles the embedded kernels at runtime, and launches the program.

## Fast vs slow dispatch
TT-Metal has two dispatch paths that must not be mixed within the same process.

### Fast dispatch (default)
- Uses command queues and firmware dispatch on the device.
- Supports async enqueue, overlap of IO/compute, and multi-device mesh workflows.
- APIs go through `distributed::*` and `MeshCommandQueue` + `EnqueueMeshWorkload`.
- Required for scaling beyond a single device or when you want performance via pipelined launches.

### Slow dispatch
- Direct host-driven launch without command queues.
- Simpler control flow (host writes runtime args + launch messages directly).
- Primarily single-device oriented and synchronous.
- Uses lower-level helpers in `tt::tt_metal::detail` such as `detail::LaunchProgram`,
  `detail::WriteToBuffer`, and `detail::ReadFromBuffer`.
- Enable with `TT_METAL_SLOW_DISPATCH_MODE=1` before any device initialization.

### Why mixing is forbidden
A global dispatch state is latched on first use. Calling fast-dispatch APIs after slow-dispatch (or vice-versa)
triggers a fatal check: "Mixing fast and slow dispatch is prohibited!". Pick one path per process.

### Which to target for a C ABI
- Prototype/minimal C API: slow dispatch is smaller and easier to wrap.
- Production path and multi-device: fast dispatch is the standard path in this repo.

## Single-file examples in this repo
There are two single-file variants that embed all three kernels as raw strings and use `CreateKernelFromString`.

### Slow dispatch, single device
- `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`
- Uses `CreateDevice`, `CreateBuffer`, `detail::WriteToBuffer`, `detail::LaunchProgram`, `detail::ReadFromBuffer`.
- Requires `TT_METAL_SLOW_DISPATCH_MODE=1` or the program sets it before initialization.

### Fast dispatch, distributed/mesh
- `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file_distributed.cpp`
- Uses `distributed::MeshDevice`, `MeshCommandQueue`, `EnqueueMeshWorkload`, `Finish`.
- Default path used by other programming examples; supports scaling to multi-device.

## Slow-dispatch C ABI mapping (minimal set)
Below is the exact TT-Metal API surface used by the slow-dispatch single-file example and what you must expose in a C ABI.

### Core types
- `tt::tt_metal::IDevice`
- `tt::tt_metal::Program`
- `tt::tt_metal::Buffer`
- `tt::tt_metal::KernelHandle`
- `tt::tt_metal::CoreCoord`
- `tt::tt_metal::CircularBufferConfig`
- `tt::tt_metal::InterleavedBufferConfig`
- `tt::tt_metal::DataMovementConfig`
- `tt::tt_metal::ComputeConfig`
- `tt::tt_metal::MathFidelity`
- `tt::tt_metal::DataMovementProcessor`
- `tt::tt_metal::NOC`
- `tt::tt_metal::DataFormat`
- `tt::tt_metal::CBIndex`
- `tt::bfloat16`

### Device + program
- `CreateDevice(device_id)`
- `CloseDevice(device)`
- `CreateProgram()`

### Buffers
- `InterleavedBufferConfig { device, size, page_size, buffer_type }`
- `CreateBuffer(InterleavedBufferConfig)`
- `Buffer::address()` (used for runtime args)

### Circular buffers
- `CircularBufferConfig(total_size_bytes, {{cb_index, DataFormat}})`
- `CircularBufferConfig::set_page_size(cb_index, page_size)`
- `CreateCircularBuffer(program, core, cb_config)`

### Kernels
- `CreateKernelFromString(program, kernel_source_string, core, DataMovementConfig)`
- `CreateKernelFromString(program, kernel_source_string, core, ComputeConfig)`
- `TensorAccessorArgs(*buffer).append_to(compile_args)`

### Runtime args
- `SetRuntimeArgs(program, kernel_id, core, {args...})`

### Slow-dispatch launch + IO
- `detail::WriteToBuffer(buffer, host_vector)`
- `detail::LaunchProgram(device, program, wait_until_cores_done)`
- `detail::ReadFromBuffer(buffer, host_vector)`

### Required environment
- `TT_METAL_SLOW_DISPATCH_MODE=1` before any TT-Metal initialization.

### Suggested C ABI wrappers
- `ttm_device_create`, `ttm_device_close`
- `ttm_program_create`, `ttm_program_destroy`
- `ttm_buffer_create_interleaved`
- `ttm_buffer_write`, `ttm_buffer_read`
- `ttm_cb_create`
- `ttm_kernel_create_dataflow_from_string`
- `ttm_kernel_create_compute_from_string`
- `ttm_set_runtime_args`
- `ttm_program_launch`
