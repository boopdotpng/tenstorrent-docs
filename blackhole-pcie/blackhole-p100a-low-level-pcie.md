# Blackhole P100A low-level PCIe + tt-kmd API spec (host-side)

Scope
- Target: Blackhole P100A, single device, single process, compute workloads.
- Keep tt-kmd; replace everything above it with a minimal userspace runtime.
- No firmware reverse engineering; firmware interaction is via documented ARC/mailbox paths.

This document is grounded in local repo evidence. Each key claim cites the file path and symbol (or struct) that shows it.

---

## A) Blackhole P100A Low-level PCIe + tt-kmd API spec

### A1) Device discovery and open
- Device node: `/dev/tenstorrent/<N>` is opened with `open(O_RDWR|O_CLOEXEC)` in `tt_device_open()` (file: `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c`, symbol: `tt_device_open`).
- Device identity and PCI location come from `TENSTORRENT_IOCTL_GET_DEVICE_INFO` (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_get_device_info`, fields: `vendor_id`, `device_id`, `bus_dev_fn`, `pci_domain`).
- UMD uses `TENSTORRENT_IOCTL_GET_DRIVER_INFO` to check driver API/semver (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_get_driver_info`; file: `tt-umd/device/pcie/pci_device.cpp`, calls `TENSTORRENT_IOCTL_GET_DRIVER_INFO`).

### A2) BAR mapping (mmap through tt-kmd)
- BARs are exposed via `TENSTORRENT_IOCTL_QUERY_MAPPINGS` returning mapping IDs and mmap offsets (file: `tt-kmd/ioctl.h`, structs: `tenstorrent_query_mappings`, `tenstorrent_mapping`; file: `tt-kmd/memory.c`, function: `ioctl_query_mappings`).
- Mapping IDs are static:
  - `TENSTORRENT_MAPPING_RESOURCE0_*` → PCI BAR0
  - `TENSTORRENT_MAPPING_RESOURCE1_*` → PCI BAR2
  - `TENSTORRENT_MAPPING_RESOURCE2_*` → PCI BAR4
  (file: `tt-kmd/ioctl.h`, defines).
- mmap offsets are synthetic, not raw BAR addresses. KMD uses a 64-bit offset scheme:
  - `MMAP_OFFSET_RESOURCE{0,1,2}_{UC,WC}` for UC/WC mappings
  - `MMAP_OFFSET_TLB_{UC,WC}` for TLB windows
  - `MMAP_OFFSET_DMA_BUF` for driver-allocated DMA buffers
  (file: `tt-kmd/memory.c`, defines).
- BAR mapping is selected by choosing a vma offset in those ranges, then calling `mmap()` on `/dev/tenstorrent/N` (file: `tt-kmd/memory.c`, function: `tenstorrent_mmap`).
- UMD maps BAR0 + BAR2 for Blackhole (BAR2 UC used for registers) based on `TENSTORRENT_IOCTL_QUERY_MAPPINGS` (file: `tt-umd/device/pcie/pci_device.cpp`, function: `PCIDevice::PCIDevice`).

### A3) TLB windows (inbound: host → device NOC)
- TLBs are allocated via `TENSTORRENT_IOCTL_ALLOCATE_TLB` and configured via `TENSTORRENT_IOCTL_CONFIGURE_TLB` (file: `tt-kmd/ioctl.h`, structs: `tenstorrent_allocate_tlb`, `tenstorrent_configure_tlb`).
- For Blackhole, TLB windows exist in BAR0 and BAR4. BAR4’s 4G windows are mmap’ed with offsets starting at `BAR0_SIZE` (file: `tt-kmd/memory.c`, function: `ioctl_allocate_tlb`).
- `tenstorrent_noc_tlb_config` specifies NOC target + address + ordering + multicast range (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_noc_tlb_config`).
- UMD wraps this as `tt_tlb_alloc()` + `tt_tlb_map()` + `tt_tlb_get_mmio()` (file: `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c`, symbols: `tt_tlb_alloc`, `tt_tlb_map`, `tt_tlb_get_mmio`).
- NOC ordering modes are defined as `TT_NOC_ORDERING_*` (file: `tt-umd/device/api/umd/device/tt_kmd_lib/tt_kmd_lib.h`, enum: `tt_noc_ordering`).
- TLB windows are the primary mechanism for host-side MMIO into device L1/DRAM and device register space (file: `tt-umd/device/tt_device/tt_device.cpp`, method: `TTDevice::read_from_device` / `TTDevice::write_to_device`, uses `TlbWindow::read_block_reconfigure` / `write_block_reconfigure`).

### A4) DMA / pinned host memory (host → device access)
- `TENSTORRENT_IOCTL_PIN_PAGES` pins user pages and returns a device DMA address (IOVA if IOMMU, PA otherwise). It requires page-aligned VA/size (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_pin_pages`; file: `tt-kmd/memory.c`, function: `ioctl_pin_pages`).
- With IOMMU enabled, KMD maps an SG table to produce a contiguous IOVA; without IOMMU, KMD requires physical contiguity and checks PFNs for contiguity (file: `tt-kmd/memory.c`, function: `ioctl_pin_pages`).
- `TENSTORRENT_PIN_PAGES_NOC_DMA` and `TENSTORRENT_PIN_PAGES_NOC_TOP_DOWN` request an address in the device’s NOC-to-host aperture (file: `tt-kmd/ioctl.h`, flags for `tenstorrent_pin_pages_in`; file: `tt-kmd/memory.c`, `setup_noc_dma` path).
- Userspace helpers:
  - `tt_dma_map()` pins memory and can return both DMA addr and NOC addr (file: `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c`, symbol: `tt_dma_map`; file: `tt-umd/device/api/umd/device/tt_kmd_lib/tt_kmd_lib.h`, `tt_dma_get_dma_addr`, `tt_dma_get_noc_addr`).
  - `PCIDevice::map_for_dma()` and `PCIDevice::map_buffer_to_noc()` call `TENSTORRENT_IOCTL_PIN_PAGES` (file: `tt-umd/device/pcie/pci_device.cpp`).
- KMD’s `TENSTORRENT_IOCTL_ALLOCATE_DMA_BUF` allocates a coherent DMA buffer and exposes an mmap offset. UMD only uses this for Wormhole (Blackhole DMA buffers are not used) (file: `tt-kmd/memory.c`, `ioctl_allocate_dma_buf`; file: `tt-umd/device/pcie/pci_device.cpp`, `allocate_pcie_dma_buffer`).
- Blackhole DMA engines are not supported in UMD (`dma_h2d`/`dma_d2h` throw) (file: `tt-umd/device/tt_device/blackhole_tt_device.cpp`, methods: `dma_h2d`, `dma_d2h`).

### A5) Locks, reset, power, cleanup
- Optional lock resource via `TENSTORRENT_IOCTL_LOCK_CTL` (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_lock_ctl`; file: `tt-kmd/chardev.c`, function: `ioctl_lock_ctl`).
- Reset via `TENSTORRENT_IOCTL_RESET_DEVICE` (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_reset_device`; file: `tt-kmd/chardev.c`, function: `ioctl_reset_device`).
- Auto cleanup via `TENSTORRENT_IOCTL_SET_NOC_CLEANUP`, which issues a device-side NOC write when the fd closes (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_set_noc_cleanup`).
- Power control via `TENSTORRENT_IOCTL_SET_POWER_STATE` (file: `tt-kmd/ioctl.h`, struct: `tenstorrent_power_state`; file: `tt-kmd/chardev.c`, `ioctl_set_power_state`).

---

## A) BAR map (as visible from host)

### A6) BAR map and mmap offsets
- KMD’s mmap address space is a multiplexed range with fixed 64-bit offsets (file: `tt-kmd/memory.c`, defines: `MMAP_OFFSET_RESOURCE*`, `MMAP_OFFSET_TLB_*`, `MMAP_OFFSET_DMA_BUF`).
- Example mapping IDs (used by UMD):
  - BAR0 UC: `TENSTORRENT_MAPPING_RESOURCE0_UC`
  - BAR0 WC: `TENSTORRENT_MAPPING_RESOURCE0_WC`
  - BAR2 UC: `TENSTORRENT_MAPPING_RESOURCE1_UC`
  - BAR2 WC: `TENSTORRENT_MAPPING_RESOURCE1_WC`
  - BAR4 UC: `TENSTORRENT_MAPPING_RESOURCE2_UC`
  - BAR4 WC: `TENSTORRENT_MAPPING_RESOURCE2_WC`
  (file: `tt-kmd/ioctl.h`, mapping IDs; file: `tt-umd/device/pcie/pci_device.cpp`, mapping selection).
- Blackhole uses BAR2 UC for register access (file: `tt-umd/device/pcie/pci_device.cpp`, Blackhole branch mapping `bar2_uc`).

---

## A) Command queues, doorbells, and queue formats

### A7) Host command queue memory layout (fast dispatch)
- Fast dispatch uses a command queue (CQ) in host memory, split into issue and completion regions (file: `tt-metal/tt_metal/impl/dispatch/system_memory_cq_interface.hpp`, struct: `SystemMemoryCQInterface`).
- CQ base addresses on host are computed from channel + CQ ID with fixed offsets (file: `tt-metal/tt_metal/impl/dispatch/command_queue_common.cpp`, function: `get_absolute_cq_offset`).
- Issue/completion pointers are stored in host sysmem and are read via `Cluster::read_sysmem` (file: `tt-metal/tt_metal/impl/dispatch/command_queue_common.cpp`, functions: `get_cq_issue_rd_ptr`, `get_cq_completion_wr_ptr`).
- Host issue queue pointers are in 16B units (pointer values stored as `addr >> 4`), with wrap/toggle logic in `SystemMemoryManager` (file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, functions: `issue_queue_push_back`, `completion_queue_pop_front`).

### A8) Prefetch queue (device-side “doorbell”)
- Host triggers device-side prefetcher by writing the command size (in 16B units) to a prefetch queue entry in device L1 via a static TLB mapping (`umd::Writer`) (file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, function: `fetch_queue_write`; file: `tt-umd/device/api/umd/device/tt_io.hpp`, class: `Writer`).
- `DispatchSettings::prefetch_q_entry_type` is `uint16_t`, and size units are 16B (file: `tt-metal/tt_metal/impl/dispatch/dispatch_settings.hpp`, `prefetch_q_entry_type`, `PREFETCH_Q_LOG_MINSIZE`).
- Prefetch queue base address (device) is provided by `DispatchMemMap::get_device_command_queue_addr(PREFETCH_Q_RD)` and `UNRESERVED` offset (file: `tt-metal/tt_metal/impl/dispatch/dispatch_mem_map.hpp`, methods; file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, usage).

### A9) Completion queue protocol
- Device writes completion data to host memory and updates the completion write pointer via NOC write (device kernel) (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_dispatch.cpp`, functions: `notify_host_of_completion_queue_write_pointer`, `completion_queue_push_back`).
- Host reads completion queue entries and updates completion read pointer back to device via `Writer` (file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, functions: `completion_queue_wait_front`, `send_completion_queue_read_ptr`).

### A10) Queue command formats (prefetch + dispatch)
- Prefetcher command IDs and packed structs are defined in `cq_commands.hpp` (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_commands.hpp`, enums: `CQPrefetchCmdId`, structs: `CQPrefetchCmd`, `CQPrefetchCmdLarge`, `CQPrefetchRelayPagedCmd`, `CQPrefetchRelayInlineCmd`, etc).
- Dispatcher command IDs and packed structs are defined in the same file (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_commands.hpp`, enums: `CQDispatchCmdId`, structs: `CQDispatchWriteCmd`, `CQDispatchWritePagedCmd`, `CQDispatchWritePackedCmd`, `CQDispatchWaitCmd`, etc).
- Commands are assembled in `program_dispatch::assemble_device_commands` and emitted to the CQ (file: `tt-metal/tt_metal/impl/program/dispatch.cpp`, symbols: `assemble_device_commands`, `add_dispatch_write_packed`, `add_prefetch_relay_*`).

---

## A) Kernel binary format + launch ABI (host view)

### A11) Kernel binary packaging
- Kernel binaries are represented as `ll_api::memory` spans, each span has a target destination address and length (file: `tt-metal/tt_metal/impl/program/program.cpp`, in `ProgramImpl::populate_program_transfer_info`, uses `kernel_bin.process_spans`).
- All kernel binaries are packed into a single `binary_data` vector (uint32 words) with page-size padding (`HostMemDeviceCommand::PROGRAM_PAGE_SIZE`) (file: `tt-metal/tt_metal/impl/program/program.cpp`, `ProgramImpl::populate_program_transfer_info`).
- Transfer metadata per kernel is captured in `kernel_bins_transfer_info` (dst base addrs, page offsets, lengths, processor ids) (file: `tt-metal/tt_metal/impl/program/program_device_map.hpp`, struct: `kernel_bins_transfer_info`).
- That transfer metadata is used to generate dispatch write commands (multicast or unicast) in fast dispatch (file: `tt-metal/tt_metal/impl/program/dispatch.cpp`, functions that build `kernel_bins_cmds` and `kernel_bins_unicast_cmds`).

### A12) Launch message ABI (slow dispatch path)
- Launch configuration is written into the L1 mailbox `launch_msg_t` (file: `tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h`, structs: `launch_msg_t`, `kernel_config_msg_t`).
- Runtime argument locations are encoded via `kernel_config_msg_t::rta_offset` (per processor index) (file: `tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h`, struct: `kernel_config_msg_t`).
- `WriteRuntimeArgsToDevice()` computes `kernel_config_base + rta_offset` and writes unique/common args into L1 (file: `tt-metal/tt_metal/tt_metal.cpp`, function: `WriteRuntimeArgsToDevice`).
- `launch_msg_t` and `go_msg_t` live in the L1 mailbox region; their base addresses are derived from `MEM_MAILBOX_BASE` (file: `tt-metal/tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp`, macro `GET_MAILBOX_ADDRESS_HOST`, entries: `HalL1MemAddrType::LAUNCH`, `GO_MSG`, `GO_MSG_INDEX`).

### A13) Runtime argument ABI (kernel-side)
- Runtime args are read using `get_arg_val<T>(idx)` from L1 (file: `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`, template `get_arg_val`).
- Common (shared) runtime args use `get_common_arg_val<T>(idx)` (same file).
- This implies runtime args are 4-byte values and are laid out contiguously in L1 based on `rta_offset` (file: `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`, docstring and `static_assert`).

---

## B) Tracing add1_sfpu_single_file.cpp

### B1) Common high-level structure
- Three kernels (copyin, compute, copyout) are constructed from string sources in the example:
  - Reader: `DataMovementProcessor::RISCV_1` (`kReaderKernel`)
  - Compute: `ComputeConfig` (`kComputeKernel`)
  - Writer: `DataMovementProcessor::RISCV_0` (`kWriterKernel`)
  (file: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`, calls to `CreateKernelFromString`).
- Copyin/copyout use TensorAccessor-based DRAM tiles and NOC DMA primitives (`noc_async_read_tile` / `noc_async_write_tile`) (file: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`, kernels; file: `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`, `noc_async_*` APIs).
- Compute kernel reads from CB0, does SFPU add, writes to CB16 (file: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`, `kComputeKernel`).

### B2) Slow dispatch (“1-device”) path
Entry point: `add1_sfpu_single_file.cpp` with `TT_METAL_SLOW_DISPATCH_MODE=1` (file: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`).

1) Program creation + buffer allocation
- `CreateDevice` creates a local device (file: `tt-metal/tt_metal/tt_metal.cpp`, function: `CreateDevice`).
- DRAM buffers are allocated via `CreateBuffer` with `BufferType::DRAM` (file: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`).

2) Kernel compilation
- `detail::CompileProgram()` invokes `ProgramImpl::compile`, which JIT-compiles kernels and reads binaries (file: `tt-metal/tt_metal/tt_metal.cpp`, `CompileProgram`; file: `tt-metal/tt_metal/impl/program/program.cpp`, `ProgramImpl::compile`).
- `ProgramImpl::compile` calls `kernel->generate_binaries()` and `kernel->read_binaries()` (file: `tt-metal/tt_metal/impl/program/program.cpp`).

3) Runtime args and config
- `SetRuntimeArgs` stores args in kernel objects (file: `tt-metal/tt_metal/tt_metal.cpp`, `SetRuntimeArgsImpl`).
- `detail::WriteRuntimeArgsToDevice` writes runtime args to L1 at offsets from the kernel config base (file: `tt-metal/tt_metal/tt_metal.cpp`, `WriteRuntimeArgsToDevice`).

4) Launch
- `LaunchProgram` writes `launch_msg_t` and `go_msg_t` directly to each core’s mailbox and optionally asserts a reset/go signal (file: `tt-metal/tt_metal/tt_metal.cpp`, `LaunchProgram`; file: `tt-metal/tt_metal/llrt/llrt.cpp`, `write_launch_msg_to_core`, `send_reset_go_signal`).
- The mailbox addresses for `launch` and `go_messages` are defined in the Blackhole HAL memory map (`MEM_MAILBOX_BASE` + struct offsets) (file: `tt-metal/tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp`).

5) Sync + readback
- Completion is polled by reading device state (`wait_until_cores_done`) (file: `tt-metal/tt_metal/llrt/llrt.cpp`, `wait_until_cores_done`).
- `ReadFromBuffer` reads DRAM back via `Cluster::read_dram_vec` (file: `tt-metal/tt_metal/tt_metal.cpp`, `ReadFromDeviceDRAMChannel`; file: `tt-metal/tt_metal/llrt/tt_cluster.cpp`, `Cluster::read_dram_vec`).

Lowest-level PCIe behavior (slow dispatch):
- Host writes to device L1/DRAM via TLB windows (`TTDevice::write_to_device` → `TlbWindow::write_block_reconfigure`) (file: `tt-umd/device/tt_device/tt_device.cpp`).
- All host accesses to device memory (L1/DRAM/registers) are MMIO via TLB windows allocated/configured with tt-kmd (file: `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c`, `tt_tlb_alloc`, `tt_tlb_map`).

### B3) Distributed / fast-dispatch path (single device)
Entry point: `add1_sfpu_single_file_distributed.cpp` (file: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file_distributed.cpp`).

1) MeshDevice creation
- `MeshDevice::create_unit_mesh()` chooses fast dispatch if enabled in runtime options (file: `tt-metal/tt_metal/distributed/mesh_device.cpp`, `MeshDevice::initialize`).
- Fast dispatch creates `FDMeshCommandQueue` instances (file: `tt-metal/tt_metal/distributed/mesh_device.cpp`, `FDMeshCommandQueue` path).

2) Kernel compilation + binary packaging
- `EnqueueMeshWorkload` calls `MeshWorkloadImpl::compile`, `load_binaries`, `generate_dispatch_commands` (file: `tt-metal/tt_metal/distributed/distributed.cpp`).
- `MeshWorkloadImpl::load_binaries` creates a replicated DRAM `MeshBuffer` and writes kernel binaries into DRAM (file: `tt-metal/tt_metal/distributed/mesh_workload.cpp`, `load_binaries`).
- Binary packaging uses `ProgramImpl::populate_program_transfer_info` (same structures as slow dispatch) (file: `tt-metal/tt_metal/impl/program/program.cpp`).

3) Dispatch command generation
- `ProgramImpl::generate_dispatch_commands` assembles prefetch/dispatch CQ commands for kernels + runtime/config (file: `tt-metal/tt_metal/impl/program/program.cpp`, `ProgramImpl::generate_dispatch_commands`; file: `tt-metal/tt_metal/impl/program/dispatch.cpp`, `assemble_device_commands`).

4) CQ submission + doorbell
- `FDMeshCommandQueue` enqueues the generated command sequences into the host issue queue and rings the prefetch queue (file: `tt-metal/tt_metal/distributed/fd_mesh_command_queue.cpp`, `enqueue_mesh_workload`; file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, `issue_queue_reserve` / `fetch_queue_write`).
- The prefetch queue “doorbell” is a device L1 write through a static TLB `Writer` (file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, `prefetch_q_writers`; file: `tt-umd/device/api/umd/device/tt_io.hpp`, `Writer::write`).

5) Completion + readback
- Completion is signaled by device writes into the completion queue and `COMPLETION_Q_WR` pointer (device kernel) (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_dispatch.cpp`).
- Host reads completion queue and updates read pointer (file: `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`, `completion_queue_wait_front`, `send_completion_queue_read_ptr`).

Lowest-level PCIe behavior (fast dispatch):
- Host CQ region is in pinned host memory (hugepage or IOMMU-mapped sysmem). UMD maps this via `TENSTORRENT_IOCTL_PIN_PAGES` (file: `tt-umd/device/pcie/pci_device.cpp`, `map_for_dma`; file: `tt-kmd/ioctl.h`, `TENSTORRENT_IOCTL_PIN_PAGES`).
- Device accesses host sysmem via NOC-to-host aperture (if NOC-mapped) or via PCIe DMA for Wormhole; on Blackhole, CQ traffic is driven by prefetch/dispatch kernels issuing NOC writes/reads (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_dispatch.cpp`, `noc_async_write` to host completion queue).

Why the distributed path is faster even on a single device:
- It batches command sequences in host memory and lets the device prefetch/dispatch pipeline overlap kernel uploads and execution (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_prefetch.cpp`, `cq_dispatch.cpp`; command generation in `tt-metal/tt_metal/impl/program/dispatch.cpp`).
- It avoids per-core host roundtrips for each kernel by using multicast/unicast dispatch commands (file: `tt-metal/tt_metal/impl/program/dispatch.cpp`, `kernel_bins_cmds`, `kernel_bins_unicast_cmds`).

---

## C) Minimal standalone runtime plan

### C1) Minimal module breakdown (single device)
1) `device_open`
  - Open `/dev/tenstorrent/N`.
  - Query device and driver info via ioctls.
  - Query BAR mappings via `TENSTORRENT_IOCTL_QUERY_MAPPINGS`.
2) `bar_map`
  - `mmap()` BAR0 UC and BAR2 UC using mapping offsets.
  - Optional: TLB windows via `TENSTORRENT_IOCTL_ALLOCATE_TLB` + `mmap()` (UC for registers, WC for bulk).
3) `dma_map`
  - Pin host buffers with `TENSTORRENT_IOCTL_PIN_PAGES` (or use `tt_dma_map` wrapper).
  - Optionally request NOC aperture addresses for device-side accesses.
4) `kernel_build`
  - Offline or build-time JIT for `kReaderKernel`, `kComputeKernel`, `kWriterKernel`.
  - Produce packed binary spans (dst addr + length) similar to `ProgramImpl::populate_program_transfer_info`.
5) `kernel_upload`
  - For slow dispatch: write binaries to per-core L1 destinations directly (TLB window + `write_block`).
  - For fast dispatch: allocate a DRAM buffer, copy binaries into it, and emit CQ commands.
6) `launch`
  - Slow dispatch: fill `launch_msg_t` + `go_msg_t` in mailbox and write to cores.
  - Fast dispatch: enqueue commands into issue queue + ring prefetch queue.
7) `sync`
  - Slow dispatch: poll `go_msg_t.signal` or `wait_until_cores_done` equivalent.
  - Fast dispatch: poll completion queue write pointer and consume entries.
8) `readback`
  - Read DRAM via TLB `read_block` on NOC addresses, or via host CQ completion reads.

### C2) Minimal “hello world” sequence (slow dispatch) — C-ish pseudocode
```c
// Minimal, single-process, single-device flow.
// Uses tt-kmd ioctls + BAR/TLB mmap only. No tt-metal at runtime.

int fd = open("/dev/tenstorrent/0", O_RDWR | O_CLOEXEC);

// Query device info
struct tenstorrent_get_device_info info = {0};
info.in.output_size_bytes = sizeof(info.out);
ioctl(fd, TENSTORRENT_IOCTL_GET_DEVICE_INFO, &info);

// Query BAR mmap offsets
struct {
  struct tenstorrent_query_mappings query;
  struct tenstorrent_mapping mapping_array[8];
} mappings = {0};
mappings.query.in.output_mapping_count = 8;
ioctl(fd, TENSTORRENT_IOCTL_QUERY_MAPPINGS, &mappings.query);

// Map BAR0 + BAR2 UC (Blackhole registers in BAR2 UC)
void* bar0 = mmap(NULL, bar0_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, bar0_uc_offset);
void* bar2 = mmap(NULL, bar2_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, bar2_uc_offset);

// Allocate a 2MiB TLB window (UC for register, WC for bulk)
struct tenstorrent_allocate_tlb tlb_alloc = {0};
tlb_alloc.in.size = (1ULL << 21);
ioctl(fd, TENSTORRENT_IOCTL_ALLOCATE_TLB, &tlb_alloc);

// mmap the TLB
void* tlb = mmap(NULL, 1 << 21, PROT_READ | PROT_WRITE, MAP_SHARED, fd, tlb_alloc.out.mmap_offset_wc);

// Configure TLB to point at a core + L1 addr (example: core (x,y), addr aligned to 2MiB)
struct tenstorrent_configure_tlb cfg = {0};
cfg.in.id = tlb_alloc.out.id;
cfg.in.config.addr = aligned_l1_addr;
cfg.in.config.x_end = core_x;
cfg.in.config.y_end = core_y;
cfg.in.config.noc = 0;
cfg.in.config.mcast = 0;
cfg.in.config.ordering = TT_NOC_ORDERING_STRICT;
ioctl(fd, TENSTORRENT_IOCTL_CONFIGURE_TLB, &cfg);

// Write kernel binaries into L1 via tlb + offset
memcpy((uint8_t*)tlb + (kernel_l1_addr & ((1<<21)-1)), kernel_bin, kernel_bin_size);

// Build launch_msg_t (kernel_config_msg_t includes rta_offset, kernel_text_offset, etc)
// Addresses are from dev_mem_map: mailboxes_t in MEM_MAILBOX_BASE.
write_launch_msg_to_mailbox(tlb, launch_msg);
write_go_msg_to_mailbox(tlb, go_msg);

// Poll for completion (go_msg_t.signal == RUN_MSG_DONE), then read back DRAM via TLB.
```

### C3) Minimal “hello world” sequence (fast dispatch) — high-level notes
- Allocate a host sysmem buffer and pin it via `TENSTORRENT_IOCTL_PIN_PAGES`.
- Build issue queue entries using the `CQPrefetchCmd` and `CQDispatchCmd` formats.
- Write command sequences into the issue queue region.
- Ring the prefetch queue by writing the size entry into `PREFETCH_Q_RD` (device L1).
- Poll completion queue pointer and read completion entries back from host sysmem.

---

## D) Practical boundary: tt-kmd vs tt-umd vs tt-metal

### D1) What tt-kmd does (keep)
- Device discovery, BAR mapping, and user-managed `mmap()` access (file: `tt-kmd/memory.c`, `tenstorrent_mmap`).
- Pin/unpin user pages for DMA/IOVA and optional NOC aperture addresses (file: `tt-kmd/memory.c`, `ioctl_pin_pages`).
- Allocate/configure inbound TLB windows (file: `tt-kmd/memory.c`, `ioctl_allocate_tlb`, `ioctl_configure_tlb`).
- Power/reset/cleanup policy (file: `tt-kmd/chardev.c`).

### D2) What tt-umd provides (replace, but re-implement minimally)
- PCIe device open, BAR mmap, TLB window management (file: `tt-umd/device/pcie/pci_device.cpp`, `tt_kmd_lib.c`).
- TLB-based MMIO read/write to device cores (file: `tt-umd/device/tt_device/tt_device.cpp`).
- ARC access + telemetry (optional) (file: `tt-umd/device/arc/blackhole_arc_telemetry_reader.cpp`).

### D3) What tt-metal does (replace)
- Kernel compilation + binary packaging (file: `tt-metal/tt_metal/impl/program/program.cpp`).
- Runtime args placement and launch messaging (file: `tt-metal/tt_metal/tt_metal.cpp`, `WriteRuntimeArgsToDevice`, `LaunchProgram`).
- Fast-dispatch CQ command generation and queue management (file: `tt-metal/tt_metal/impl/dispatch/*`).

---

## E) Optional: minimal telemetry / “device alive” checks

### E1) ARC boot/telemetry
- ARC boot status is checked at `SCRATCH_RAM_2` via ARC APB (file: `tt-umd/device/tt_device/blackhole_tt_device.cpp`, `wait_arc_core_start`; file: `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp`, `SCRATCH_RAM_2`).
- Telemetry table/value addresses are read from `SCRATCH_RAM_12` / `SCRATCH_RAM_13` (file: `tt-umd/device/arc/blackhole_arc_telemetry_reader.cpp`, `get_telemetry_address`).
- ARC message queue descriptor is read from `SCRATCH_RAM_11` (file: `tt-umd/device/arc/blackhole_arc_message_queue.cpp`, `get_blackhole_arc_message_queue`).

Safe polling guidance
- `SCRATCH_RAM_2` (ARC boot status) is safe for frequent polling during bring-up (file: `tt-umd/device/tt_device/blackhole_tt_device.cpp`, loop in `wait_arc_core_start`).
- ARC telemetry table/value reads are safe but higher overhead than direct register reads (file: `tt-umd/device/arc/arc_telemetry_reader.cpp`).

---

## F) Gaps / ambiguities + validation ideas (no firmware RE)

1) NOC-to-host aperture address ranges
  - `TENSTORRENT_IOCTL_PIN_PAGES` returns `noc_address`, but exact aperture constraints aren’t hard-coded in host code (file: `tt-kmd/ioctl.h`, `tenstorrent_pin_pages_out_extended`; file: `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c`, `tt_dma_get_noc_addr`).
  - Validate with a small host buffer, pass `TT_DMA_FLAG_NOC_TOP_DOWN`, log returned address range and attempt a device-side NOC read.

2) Dispatch command stream semantics
  - CQ command formats are defined, but runtime ordering requirements depend on dispatch kernel implementation (file: `tt-metal/tt_metal/impl/dispatch/kernels/cq_dispatch.cpp`).
  - Validate by capturing a minimal CQ stream (single write + go signal) and observing completion queue contents.

3) Kernel binary format details
  - `ll_api::memory` spans define dst addr + length, but actual ELF packing is handled by kernel generators (file: `tt-metal/tt_metal/impl/program/program.cpp`, `kernel_bin.process_spans`; file: `tt-metal/tt_metal/impl/kernels/kernel.cpp`, `generate_binaries`).
  - Validate by printing span count/addresses from the JIT output and confirming those addresses are valid for the target processor (BRISC/NCRISC/TRISC).

---

## References (files + symbols)

Key KMD API
- `tt-kmd/ioctl.h`: ioctl IDs and structs (`TENSTORRENT_IOCTL_*`, `tenstorrent_*` structs).
- `tt-kmd/memory.c`: mmap offsets (`MMAP_OFFSET_*`), BAR/TTLB mapping, pin/unpin logic.

UMD wrappers
- `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c`: `tt_device_open`, `tt_dma_map`, `tt_tlb_alloc`, `tt_tlb_map`.
- `tt-umd/device/pcie/pci_device.cpp`: BAR mapping, `map_for_dma`, `map_buffer_to_noc`.
- `tt-umd/device/tt_device/tt_device.cpp`: TLB-based `read_from_device` / `write_to_device`.

Launch ABI
- `tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h`: `launch_msg_t`, `kernel_config_msg_t`, `go_msg_t`.
- `tt-metal/tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp`: mailbox offsets (`HalL1MemAddrType::LAUNCH`, `GO_MSG`).

Dispatch queues
- `tt-metal/tt_metal/impl/dispatch/system_memory_manager.cpp`: issue/completion queue logic, prefetch “doorbell”.
- `tt-metal/tt_metal/impl/dispatch/kernels/cq_commands.hpp`: command formats.
- `tt-metal/tt_metal/impl/dispatch/kernels/cq_dispatch.cpp`: completion queue updates.

Program + kernel packaging
- `tt-metal/tt_metal/impl/program/program.cpp`: `ProgramImpl::compile`, `populate_program_transfer_info`.
- `tt-metal/tt_metal/impl/program/program_device_map.hpp`: `kernel_bins_transfer_info`.
