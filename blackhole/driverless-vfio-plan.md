# Removing tt-kmd: Driverless blackhole-py via VFIO

## Current Kernel Driver Dependency

blackhole-py uses 5 ioctls from tt-kmd, plus its mmap handler for BAR access:

| IOCTL | Kernel action |
|-------|---------------|
| `PIN_PAGES` | `pin_user_pages()` + IOMMU DMA map + configure outbound iATU region |
| `UNPIN_PAGES` | Reverse of above |
| `ALLOCATE_TLB` | Bitmap allocator, returns mmap offsets into BAR0/BAR4 |
| `CONFIGURE_TLB` | Writes 64-bit register at BAR4 + 0x1FC00000 + tlb_id*8 |
| `FREE_TLB` | Clears bitmap bit |

The mmap handler maps PCIe BARs (0, 2, 4) into userspace with UC or WC caching policies.

## What's Easy vs Hard to Replace

| Task | Difficulty | Notes |
|------|-----------|-------|
| BAR mmap (UC/WC) | Easy | sysfs `resourceN` files or VFIO |
| TLB allocation | Trivial | Kernel impl is just a bitmap + `find_next_zero_bit` |
| TLB configuration | Easy | One 64-bit register write to BAR4 |
| iATU programming | Easy | Seven 32-bit writes to BAR2 + 0x1200 + region*0x100 |
| DMA / page pinning | Hard | Requires *some* kernel involvement |
| Device reset | Medium | PCIe hot reset via sysfs remove/rescan or VFIO |

DMA is the only fundamentally kernel-requiring operation. Everything else is register writes to mapped BARs.

## Recommended Approach: VFIO

VFIO is the Linux framework for giving userspace full control of a PCIe device with IOMMU safety.

### What VFIO provides

- **BAR mapping** — `mmap()` the VFIO device fd for BAR0/BAR2/BAR4, with WC/UC control
- **DMA mapping** — `VFIO_IOMMU_MAP_DMA` replaces `PIN_PAGES` entirely (pins pages, programs IOMMU, returns IOVA)
- **IOMMU isolation** — safe multi-device operation, no kernel trust needed
- **Device reset** — `VFIO_DEVICE_RESET` ioctl

### What to implement in userspace Python

1. **TLB register programming** — BAR4 mapped via VFIO, write 64-bit config register directly:
   - Register address: `BAR4 + 0x1FC00000 + tlb_id * 8`
   - Format: 64-bit value encoding NOC address, coordinates, ordering mode
   - Just `struct.pack()` + mmap write

2. **TLB window allocation** — Pure Python bitmap, replaces the kernel's `find_next_zero_bit` allocator

3. **iATU configuration** — For NOC DMA (device reading from host memory):
   - Base: `BAR2 + 0x1200 + region * 0x100`
   - Seven 32-bit register writes: lower/upper base, lower/upper target, limit, ctrl1, ctrl2
   - 16 regions available

### Setup steps

1. Unbind Blackhole from `tenstorrent` driver
2. Bind to `vfio-pci` (or use `vfio-pci` as default)
3. Open `/dev/vfio/<group>`, get device fd
4. mmap BARs from VFIO device fd
5. Use `VFIO_IOMMU_MAP_DMA` instead of `PIN_PAGES`
6. Program TLB/iATU registers directly from Python

### Estimated scope

~200-300 lines of Python wrapping VFIO, replacing all 5 ioctls + the mmap handler. The TLB and iATU register formats are already well-defined in blackhole-py's `defs.py` and `tlb.py`.

## Alternative Approaches

### UIO
Simpler than VFIO — maps BARs via `/sys/class/uio/`. But no IOMMU protection; a Python bug could DMA-corrupt arbitrary host memory. Fine for dev, dangerous for production.

### Raw sysfs + hugepages
Map BARs via `/sys/bus/pci/devices/.../resourceN`. For DMA, allocate hugepages and read `/proc/self/pagemap` for physical addresses. Only works with IOMMU off/passthrough. Fragile.

### Minimal kernel module
A ~50-line driver that only does `pin_user_pages` + `dma_map_page` and returns the address. Minimal kernel surface area if VFIO is too heavyweight.
