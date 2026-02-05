# Blackhole P100A low-level PCIe + tt-kmd API spec (host-side)

Scope
- Target: Blackhole P100A, single device, single process, compute workloads.
- Keep tt-kmd; replace everything above it with a minimal userspace runtime.
- No firmware reverse engineering; firmware interaction is via documented ARC/mailbox paths.

This document is grounded in local repo evidence. Each key claim cites the file path and symbol (or struct) that shows it.

---

## A) Blackhole P100A Low-level PCIe + tt-kmd API spec

### A1) Device discovery and open
- Device node: `/dev/tenstorrent/<N>` is opened with `open(O_RDWR|O_CLOEXEC)` in `tt_device_open()` (file: `tt_device_open`).
- Device identity and PCI location come from `TENSTORRENT_IOCTL_GET_DEVICE_INFO` (struct: `tenstorrent_get_device_info`).
- UMD uses `TENSTORRENT_IOCTL_GET_DRIVER_INFO` to check driver API/semver.

### A2) BAR mapping (mmap through tt-kmd)
- BARs are exposed via `TENSTORRENT_IOCTL_QUERY_MAPPINGS` returning mapping IDs and mmap offsets.
- Mapping IDs are static:
  - `TENSTORRENT_MAPPING_RESOURCE0_*` → PCI BAR0
  - `TENSTORRENT_MAPPING_RESOURCE1_*` → PCI BAR2
  - `TENSTORRENT_MAPPING_RESOURCE2_*` → PCI BAR4
- mmap offsets are synthetic, not raw BAR addresses. KMD uses a 64-bit offset scheme:
  - `MMAP_OFFSET_RESOURCE{0,1,2}_{UC,WC}` for UC/WC mappings
  - `MMAP_OFFSET_TLB_{UC,WC}` for TLB windows
  - `MMAP_OFFSET_DMA_BUF` for driver-allocated DMA buffers
- BAR mapping is selected by choosing a vma offset in those ranges, then calling `mmap()` on `/dev/tenstorrent/N`.
- UMD maps BAR0 + BAR2 for Blackhole (BAR2 UC used for registers).

### A3) TLB windows (inbound: host → device NOC)
- TLBs are allocated via `TENSTORRENT_IOCTL_ALLOCATE_TLB` and configured via `TENSTORRENT_IOCTL_CONFIGURE_TLB`.
- For Blackhole, TLB windows exist in BAR0 and BAR4. BAR4’s 4G windows are mmap’ed with offsets starting at `BAR0_SIZE`.
- `tenstorrent_noc_tlb_config` specifies NOC target + address + ordering + multicast range.
- UMD wraps this as `tt_tlb_alloc()` + `tt_tlb_map()` + `tt_tlb_get_mmio()`.
- NOC ordering modes are defined as `TT_NOC_ORDERING_*` in UMD.
- TLB windows are the primary mechanism for host-side MMIO into device L1/DRAM and device register space.

### A4) DMA / pinned host memory (host → device access)
- `TENSTORRENT_IOCTL_PIN_PAGES` pins user pages and returns a device DMA address (IOVA if IOMMU, PA otherwise). It requires page-aligned VA/size.
- With IOMMU enabled, KMD maps an SG table to produce a contiguous IOVA; without IOMMU, KMD requires physical contiguity and checks PFNs for contiguity.
- `TENSTORRENT_PIN_PAGES_NOC_DMA` and `TENSTORRENT_PIN_PAGES_NOC_TOP_DOWN` request an address in the device’s NOC-to-host aperture.
- Userspace helpers:
  - `tt_dma_map()` pins memory and can return both DMA addr and NOC addr.
  - `PCIDevice::map_for_dma()` and `PCIDevice::map_buffer_to_noc()` call `TENSTORRENT_IOCTL_PIN_PAGES`.
- KMD’s `TENSTORRENT_IOCTL_ALLOCATE_DMA_BUF` allocates a coherent DMA buffer and exposes an mmap offset. UMD only uses this for Wormhole (Blackhole DMA buffers are not used).
- Blackhole DMA engines are not supported in UMD (`dma_h2d`/`dma_d2h` throw).

### A5) Locks, reset, power, cleanup
- Optional lock resource via `TENSTORRENT_IOCTL_LOCK_CTL`.
- Reset via `TENSTORRENT_IOCTL_RESET_DEVICE`.
- Auto cleanup via `TENSTORRENT_IOCTL_SET_NOC_CLEANUP`, which issues a device-side NOC write when the fd closes.
- Power control via `TENSTORRENT_IOCTL_SET_POWER_STATE`.

---

## B) BAR map (as visible from host)

### B1) BAR map and mmap offsets
- KMD’s mmap address space is a multiplexed range with fixed 64-bit offsets (`MMAP_OFFSET_RESOURCE*`, `MMAP_OFFSET_TLB_*`, `MMAP_OFFSET_DMA_BUF`).
- Example mapping IDs (used by UMD):
  - BAR0 UC: `TENSTORRENT_MAPPING_RESOURCE0_UC`
  - BAR0 WC: `TENSTORRENT_MAPPING_RESOURCE0_WC`
  - BAR2 UC: `TENSTORRENT_MAPPING_RESOURCE1_UC`
  - BAR2 WC: `TENSTORRENT_MAPPING_RESOURCE1_WC`
  - BAR4 UC: `TENSTORRENT_MAPPING_RESOURCE2_UC`
  - BAR4 WC: `TENSTORRENT_MAPPING_RESOURCE2_WC`
- Blackhole uses BAR2 UC for register access.

---

## C) Command queues, doorbells, and queue formats

### C1) Host command queue memory layout (fast dispatch)
- Fast dispatch uses a command queue (CQ) in host memory, split into issue and completion regions.
- CQ base addresses on host are computed from channel + CQ ID with fixed offsets.
- Issue/completion pointers are stored in host sysmem and are read via `Cluster::read_sysmem`.
- Host issue queue pointers are in 16B units (pointer values stored as `addr >> 4`), with wrap/toggle logic in `SystemMemoryManager`.

### C2) Prefetch queue (device-side “doorbell”)
- Host triggers device-side prefetcher by writing the command size (in 16B units) to a prefetch queue entry in device L1 via a static TLB mapping (`umd::Writer`).
- `DispatchSettings::prefetch_q_entry_type` is `uint16_t`, and size units are 16B.
- Prefetch queue base address (device) is provided by `DispatchMemMap::get_device_command_queue_addr(PREFETCH_Q_RD)` and `UNRESERVED` offset.

### C3) Completion queue protocol
- Device writes completion data to host memory and updates the completion write pointer via NOC write.
- Host reads completion queue entries and updates completion read pointer back to device via `Writer`.

### C4) Queue command formats (prefetch + dispatch)
- Prefetcher command IDs and packed structs are defined in `cq_commands.hpp`.
- Dispatcher command IDs and packed structs are defined in the same file.
- Commands are assembled in `program_dispatch::assemble_device_commands` and emitted to the CQ.

---

## D) Kernel binary format + launch ABI (host view)

### D1) Kernel binary packaging
- Kernel binaries are represented as `ll_api::memory` spans, each span has a target destination address and length.
- All kernel binaries are packed into a single `binary_data` vector (uint32 words) with page-size padding.
- Transfer metadata per kernel is captured in `kernel_bins_transfer_info` (dst base addrs, page offsets, lengths, processor ids).
- That transfer metadata is used to generate dispatch write commands in fast dispatch.

### D2) Launch message ABI (slow dispatch path)
- Launch configuration is written into the L1 mailbox `launch_msg_t`.
- Runtime argument locations are encoded via `kernel_config_msg_t::rta_offset` (per processor index).
- `WriteRuntimeArgsToDevice()` computes `kernel_config_base + rta_offset` and writes unique/common args into L1.
- `launch_msg_t` and `go_msg_t` live in the L1 mailbox region; their base addresses are derived from `MEM_MAILBOX_BASE`.

### D3) Runtime argument ABI (kernel-side)
- Runtime args are read using `get_arg_val<T>(idx)` from L1.
- Common runtime args use `get_common_arg_val<T>(idx)`.
- Runtime args are 4-byte values and are laid out contiguously in L1 based on `rta_offset`.

---

## E) PCIe bandwidth benchmarking (tt-umd)

### TLB Window Sizes
- Wormhole: 1MB, 2MB, 16MB
- Blackhole: 2MB, 4GB only

### Transfer mechanisms

**MMIO via TLB**
```
Host CPU → PCIe Posted Writes → TLB Window → NoC → Device Memory (L1/DRAM)
```
- CPU writes to mapped TLB region
- Reads are synchronous and very slow (~44 MB/s)
- Limited by PCIe transaction overhead

**PCIe DMA**
```
Host Memory → DMA Engine → PCIe → Device MMIO Region → NoC → Device Memory
```
- Hardware DMA engine copies data
- Requires IOMMU for buffer mapping
- Higher bandwidth potential (30-50 GB/s on Gen5 x16)

### Can DMA write to L1?
Yes, but it still traverses the NoC. Observed L1 bandwidth is lower than DRAM because NoC is the limiter.

### Benchmark results (Blackhole, PCIe Gen5 x16)

Dynamic TLB (MMIO):
- DRAM writes plateau ~7.6 GB/s
- L1 writes plateau ~5.2 GB/s
- Reads ~44 MB/s

Static TLB improves small transfers by reducing TLB setup overhead.

### Common pitfall: 16MB TLB on Blackhole
Blackhole only supports 2MB and 4GB windows. 16MB allocations fail with EINVAL.

