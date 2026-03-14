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


## Notes on Python FFI

TT-Metal host APIs are C++ (`std::vector`, `std::variant`, `std::shared_ptr`), so Python bindings need a C ABI wrapper or nanobind. Kernels are compiled by TT-Metal's JIT build system at runtime. Kernel code can be file-based or passed as strings with `CreateKernelFromString`.

## Single-file kernel examples

It is feasible to embed all three kernels (reader/compute/writer) as strings in one host file and call `CreateKernelFromString`. The runtime JIT handles compilation and caching. `SetRootDir()` or `TT_METAL_HOME` must be set so kernel includes resolve.

- **Slow dispatch:** `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`
- **Fast dispatch (mesh):** `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file_distributed.cpp`

Fast and slow dispatch must not be mixed within the same process (global dispatch state is latched on first use).
