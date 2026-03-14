# PCIe DMA and Sysmem on Blackhole

## The Problem: BAR Reads Are Slow

Reading device memory from the host via MMIO (BAR TLB windows) is fundamentally slow. Every read is a non-posted PCIe transaction -- the CPU sends a read request, waits for the device to respond, one cacheline (64 bytes) at a time. This gives ~0.03 GB/s regardless of mapping type (WC or UC) or access method (Python mmap, libc memcpy, etc.).

BAR writes are much faster (~2.5 GB/s) because PCIe writes are posted (fire-and-forget).

## Blackhole Has No PCIe DMA Engine

Unlike Wormhole, Blackhole does **not** support PCIe DMA transfers. tt-metal explicitly throws on `dma_d2h` / `dma_h2d` for Blackhole:

```cpp
// blackhole_tt_device.cpp
void BlackholeTTDevice::dma_d2h(void *dst, uint32_t src, size_t size) {
    throw std::runtime_error("D2H DMA is not supported on Blackhole.");
}
```

The `dma_address_bits` kernel module parameter exists but is set to 0 (disabled).

## The Fast Path: Sysmem (Device Writes to Host Memory)

Instead of the host reading from the device, the device writes to host memory. This uses PCIe posted writes at full link bandwidth.

### How It Works

1. **Hugepages**: Host allocates 1 GB hugepages from `/dev/hugepages-1G/`, mmap'd with `MAP_SHARED | MAP_POPULATE`
2. **Pin Pages**: Pages are pinned to the device via `IOCTL_PIN_PAGES` (ioctl 7) with `TENSTORRENT_PIN_PAGES_NOC_DMA` flag, which returns the physical/IOVA address
3. **iATU Programming**: The inbound Address Translation Unit (iATU) is programmed through BAR2 UC registers to map a PCIe address range to the hugepage's physical address
4. **Device NoC Writes**: Device-side software writes to NOC address `4ULL << 58` + offset. The PCIe controller translates this to a posted write targeting the hugepage
5. **Host Reads**: Host reads from the hugepage mmap -- this is just local RAM, full DDR bandwidth

### iATU (inbound Address Translation Unit)

The iATU is PCIe IP that translates incoming PCIe addresses to host physical addresses. It's essentially a page table for PCIe. When the device does a NoC write to `4ULL << 58`, the PCIe controller sends a posted write to the host. The iATU maps that PCIe address to the physical address of the hugepage.

Blackhole programs the iATU directly through BAR2 UC registers (unlike Wormhole which uses ARC messages).

### Performance

| Method | Bandwidth | Mechanism |
|--------|-----------|-----------|
| Host reads device (BAR MMIO) | ~0.03 GB/s | Non-posted PCIe reads, one cacheline at a time |
| Host writes device (BAR MMIO) | ~2.5 GB/s | Posted PCIe writes |
| Device writes to sysmem | ~10-15 GB/s | Posted PCIe writes at near-link bandwidth |
| Host reads sysmem | DDR bandwidth | Local memory access |

PCIe Gen4 x16 theoretical max is ~25 GB/s. Sysmem gets ~10-15 GB/s in practice.

### Capacity

tt-metal uses up to 4 channels of 1 GB hugepages (4 GB total sysmem). For data larger than what's mapped, you chunk it -- device writes 1 GB, host copies it out, device writes the next 1 GB. In practice 1 GB is plenty; a 2048x2048 fp16 matmul output is only 8 MB.

Sysmem is shared between reads and writes (tt-metal uses it for fast host-to-device too).

## tt-metal Read Path Summary

```
Host wants data from Device DRAM:

Option A: Host-initiated read (slow, ~0.03 GB/s)
  Cluster::read_from_device()
    -> LocalChip::read_from_device()
      -> Static TLB mapped? -> memcpy() from BAR mmap
      -> No static TLB?     -> reconfigure TLB (ioctl) + memcpy per 2MB chunk

Option B: Device writes to host sysmem (fast, ~10+ GB/s)
  Device NoC writes to (4ULL << 58) + offset
    -> Data lands in hugepage mmap
    -> Host reads via local memcpy()
```

## tt-kmd Ioctls for Sysmem

- `IOCTL_PIN_PAGES` (7): Pin userspace pages, get physical/IOVA + NOC address. Flags: `TENSTORRENT_PIN_PAGES_NOC_DMA` (2)
- `IOCTL_ALLOCATE_DMA_BUF` (3): Allocate kernel DMA buffer. Flag: `TENSTORRENT_ALLOCATE_DMA_BUF_NOC_DMA` (2). Returns physical address + mmap offset + NOC address

## Blackhole-Specific Notes

- TLB windows: 202x 2 MiB + 8x 4 GiB (the 4 GiB TLBs are unique to Blackhole)
- Blackhole uses plain `memcpy()` for BAR reads (Wormhole uses word-by-word volatile reads due to GDDR5 controller bugs)
- Blackhole disables `static_vc` in TLB configuration
- PCIe base for sysmem in NOC address space: `4ULL << 58` = `0x4000000000000000`
- NUMA awareness matters: hugepage should be on the same NUMA node as the device
