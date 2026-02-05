# Fast dispatch architecture and ABI (Blackhole)

This consolidates fast-dispatch overview, CQ layout/alignments, and compile-time defines.

## Overview: slow vs fast dispatch

**Slow dispatch:**
- Host writes directly to worker L1 via TLB windows
- Each write is a separate PCIe transaction

**Fast dispatch:**
- Host writes commands to system memory (hugepage or IOMMU-mapped)
- Device reads commands via PCIe DMA
- On-device prefetch/dispatch cores process commands and write to workers via NoC

## Two write destinations

### 1) System memory (issue queue)
```
Host Memory (Hugepage or IOMMU mmap)
├── Issue Queue (commands)
├── Completion Queue (device writes completion events here)
└── Control pointers (read/write pointers)
```

No hugepages needed with IOMMU. tt-metal uses regular mmap.

### 2) Prefetch core L1 (TLB)
Small control writes to notify the device that new commands are ready:
- `PREFETCH_Q` entries (sizes of commands to fetch)
- `ISSUE_Q_WR` pointer update

## IOMMU vs hugepage path

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

## Dispatch core coordinates

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

## Host CQ control area layout (sysmem)

`CommandQueueHostAddrType` offsets are `type * PCIE_ALIGNMENT`:
- `ISSUE_Q_RD = 0x00`
- `ISSUE_Q_WR = 0x40`
- `COMPLETION_Q_WR = 0x80`
- `COMPLETION_Q_RD = 0xC0`
- `UNRESERVED (issue data start) = 0x100`

`PCIE_ALIGNMENT = 64` bytes on Blackhole.

## Device CQ control area layout (prefetch core L1)

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

## Prefetcher + dispatcher runtime args

Prefetch and dispatch firmware kernels take only **3 runtime args**, all `0` for single-chip MMIO:
```
rt_args[0] = my_dev_id        = 0
rt_args[1] = to_dev_id        = 0
rt_args[2] = router_direction  = 0
```

`dispatch_s` takes **zero** runtime args.

## All real config is compile-time defines

Every meaningful configuration value — buffer addresses, NOC coordinates, queue sizes, semaphore IDs — is passed as `#define` macros at kernel compile time. Pre-compiled ELFs are device-configuration-specific.

Defines are set in:
- `tt_metal/impl/dispatch/kernel_config/prefetch.cpp`
- `tt_metal/impl/dispatch/kernel_config/dispatch.cpp`
- `tt_metal/impl/dispatch/kernel_config/fd_kernel.cpp`

## Prefetch kernel defines (PREFETCH_HD, single-chip)

### Base defines (all FD kernels)
- `DISPATCH_KERNEL = 1`
- `FD_CORE_TYPE = 0`
- `FORCE_DPRINT_OFF = 1` (unless dprint reads dispatch cores)
- `FORCE_WATCHER_OFF = 1` (if watcher dispatch disabled)

### NOC coordinates
- `MY_NOC_X`, `MY_NOC_Y`
- `UPSTREAM_NOC_INDEX`
- `UPSTREAM_NOC_X`, `UPSTREAM_NOC_Y`
- `DOWNSTREAM_NOC_X`, `DOWNSTREAM_NOC_Y`
- `DOWNSTREAM_SUBORDINATE_NOC_X`, `DOWNSTREAM_SUBORDINATE_NOC_Y`

### Buffer addresses and sizes
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

### Downstream (dispatch) buffer config
- `DOWNSTREAM_CB_BASE`
- `DOWNSTREAM_CB_LOG_PAGE_SIZE`
- `DOWNSTREAM_CB_PAGES`
- `MY_DOWNSTREAM_CB_SEM_ID`
- `DOWNSTREAM_CB_SEM_ID`
- `DOWNSTREAM_SYNC_SEM_ID`

### Dispatch_S buffer config
- `DISPATCH_S_BUFFER_BASE`
- `DISPATCH_S_BUFFER_SIZE`
- `DISPATCH_S_CB_LOG_PAGE_SIZE`
- `MY_DISPATCH_S_CB_SEM_ID`
- `DOWNSTREAM_DISPATCH_S_CB_SEM_ID`

### Fabric (all 0 for single-chip HD)
- `FABRIC_HEADER_RB_BASE`
- `FABRIC_HEADER_RB_ENTRIES`
- `MY_FABRIC_SYNC_STATUS_ADDR`
- `FABRIC_MUX_*` (11 fields)
- `FABRIC_WORKER_*_SEM` (3 fields)
- `NUM_HOPS`
- `EW_DIM`
- `TO_MESH_ID`

### Variant flags
- `IS_D_VARIANT = 1`
- `IS_H_VARIANT = 1`
- `FABRIC_RELAY` not defined (only set for split variants)

## Dispatch kernel defines (DISPATCH_HD, single-chip)

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

## How NoC write bytes are packed (conceptual)

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
