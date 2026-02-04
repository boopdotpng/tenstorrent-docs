# Fast Dispatch: Runtime Args vs Compile-Time Defines

## The rt_args Misconception

The prefetch and dispatch firmware kernels take only **3 runtime args**, and for single-chip MMIO (P100A over PCIe), they are all **0**:

```
rt_args[0] = my_dev_id        = 0  (fabric node chip ID, unused single-chip)
rt_args[1] = to_dev_id        = 0  (destination chip ID, unused single-chip)
rt_args[2] = router_direction  = 0  (fabric routing direction, unused single-chip)
```

These are set in `tt_metal/impl/dispatch/kernel_config/prefetch.cpp` `InitializeRuntimeArgsValues()` and `dispatch.cpp` `InitializeRuntimeArgsValues()`. Both are identical — 3 sequential offsets for fabric routing, all defaulting to 0 via `.value_or(0)`.

`dispatch_s` has **zero** runtime args (inherits empty default from `FDKernel`).

## All Real Config is Compile-Time #defines

Every meaningful configuration value — buffer addresses, NOC coordinates, queue sizes, semaphore IDs — is passed as a `#define` macro at kernel compile time, baked into the ELF as immediate values in RISC-V instructions. This means **pre-compiled ELFs are device-configuration-specific**.

The defines are set in `CreateKernel()` methods in:
- `tt_metal/impl/dispatch/kernel_config/prefetch.cpp` (lines ~438-541)
- `tt_metal/impl/dispatch/kernel_config/dispatch.cpp` (lines ~443-541)
- `tt_metal/impl/dispatch/kernel_config/fd_kernel.cpp` `configure_kernel_variant()` (base defines)

## Prefetch Kernel Defines (PREFETCH_HD, single-chip)

### Base defines (all FD kernels)

| Define | Value | Notes |
|--------|-------|-------|
| `DISPATCH_KERNEL` | `1` | Always |
| `FD_CORE_TYPE` | `0` | Tensix core type index |
| `FORCE_DPRINT_OFF` | `1` | Unless dprint reads dispatch cores |
| `FORCE_WATCHER_OFF` | `1` | If watcher dispatch disabled |

### NOC coordinates

| Define | Meaning |
|--------|---------|
| `MY_NOC_X`, `MY_NOC_Y` | Prefetch core's virtual NOC0 coords on `non_dispatch_noc` |
| `UPSTREAM_NOC_INDEX` | 0 or 1, upstream NOC selection |
| `UPSTREAM_NOC_X`, `UPSTREAM_NOC_Y` | Upstream core (self for HD) virtual NOC0 coords on `upstream_noc` |
| `DOWNSTREAM_NOC_X`, `DOWNSTREAM_NOC_Y` | Dispatch core's virtual NOC0 coords on `downstream_noc` |
| `DOWNSTREAM_SUBORDINATE_NOC_X`, `DOWNSTREAM_SUBORDINATE_NOC_Y` | Dispatch_S core's coords on `downstream_noc` |

For a typical unharvested BH (dispatch cores at physical (16,2) and (16,3)):
- Prefetch = (16, 2), Dispatch = (16, 3)
- With NOC translation, virtual coords may differ from physical

### Buffer addresses and sizes

| Define | Typical Value | How Computed |
|--------|---------------|--------------|
| `PREFETCH_Q_BASE` | `UNRESERVED_base` | `device_cq_addrs_[UNRESERVED]` ≈ `l1_base + 0x180` |
| `PREFETCH_Q_SIZE` | `3068` | `1534 entries * 2 bytes` |
| `PREFETCH_Q_RD_PTR_ADDR` | `l1_base` | `device_cq_addrs_[PREFETCH_Q_RD]` |
| `PREFETCH_Q_PCIE_RD_PTR_ADDR` | `l1_base + 4` | `device_cq_addrs_[PREFETCH_Q_PCIE_RD]` |
| `CMDDAT_Q_BASE` | `align(PREFETCH_Q_BASE + 3068, 64)` | After prefetch_q ring |
| `CMDDAT_Q_SIZE` | `262144` (256 KB) | `prefetch_cmddat_q_size_` |
| `CMDDAT_Q_LOG_PAGE_SIZE` | `12` | 4 KB pages |
| `CMDDAT_Q_PAGES` | `64` | `262144 / 4096` |
| `CMDDAT_Q_BLOCKS` | `4` | `PREFETCH_D_BUFFER_BLOCKS` |
| `SCRATCH_DB_BASE` | `align(CMDDAT_Q_BASE + 262144, 64)` | After cmddat_q |
| `SCRATCH_DB_SIZE` | `131072` (128 KB) | |
| `PCIE_BASE` | `cq_offset + 256` | Host issue queue start in NOC sysmem space |
| `PCIE_SIZE` | (issue queue size) | From sysmem manager |
| `RINGBUFFER_SIZE` | `1048576` (1 MB) | |

### Downstream (dispatch) buffer config

| Define | Typical Value | Notes |
|--------|---------------|-------|
| `DOWNSTREAM_CB_BASE` | `align(UNRESERVED_base, 4096)` | Dispatch core's circular buffer base |
| `DOWNSTREAM_CB_LOG_PAGE_SIZE` | `12` | 4 KB pages |
| `DOWNSTREAM_CB_PAGES` | `128` | `524288 / 4096` |
| `MY_DOWNSTREAM_CB_SEM_ID` | 0 | Semaphore on prefetch core tracking dispatch credits |
| `DOWNSTREAM_CB_SEM_ID` | (sem_id) | Semaphore on dispatch core |
| `DOWNSTREAM_SYNC_SEM_ID` | (sem_id) | Sync semaphore |

### Dispatch_S buffer config

| Define | Value | Notes |
|--------|-------|-------|
| `DISPATCH_S_BUFFER_BASE` | `dispatch_buffer_base + 524288` | After dispatch CB, if dispatch_s enabled on WORKER cores |
| `DISPATCH_S_BUFFER_SIZE` | `32768` (32 KB) | |
| `DISPATCH_S_CB_LOG_PAGE_SIZE` | `8` | 256-byte pages |
| `MY_DISPATCH_S_CB_SEM_ID` | (sem_id) | |
| `DOWNSTREAM_DISPATCH_S_CB_SEM_ID` | (sem_id) | `UNUSED_SEM_ID=0` if no dispatch_s |

### Fabric (all 0 for single-chip HD)

| Define | Value |
|--------|-------|
| `FABRIC_HEADER_RB_BASE` | (non-zero, allocated in L1) |
| `FABRIC_HEADER_RB_ENTRIES` | `1` |
| `MY_FABRIC_SYNC_STATUS_ADDR` | (non-zero, allocated in L1) |
| `FABRIC_MUX_*` (11 fields) | all `0` |
| `FABRIC_WORKER_*_SEM` (3 fields) | all `0` |
| `NUM_HOPS` | `0` |
| `EW_DIM` | `0` |
| `TO_MESH_ID` | `0` |

### Variant flags

| Define | Value |
|--------|-------|
| `IS_D_VARIANT` | `1` |
| `IS_H_VARIANT` | `1` |
| `FABRIC_RELAY` | **not defined** (only set for split variants) |

## Dispatch Kernel Defines (DISPATCH_HD, single-chip)

Shares the base defines, NOC coords, and fabric defines with prefetch. Additional dispatch-specific:

| Define | Typical Value | Notes |
|--------|---------------|-------|
| `DISPATCH_CB_BASE` | `align(UNRESERVED_base, 4096)` | Same as prefetch's `DOWNSTREAM_CB_BASE` |
| `DISPATCH_CB_LOG_PAGE_SIZE` | `12` | |
| `DISPATCH_CB_PAGES` | `128` | |
| `DISPATCH_CB_BLOCKS` | `4` | |
| `MY_DISPATCH_CB_SEM_ID` | (sem_id) | Semaphore on dispatch core |
| `UPSTREAM_DISPATCH_CB_SEM_ID` | (sem_id) | From prefetch's `my_downstream_cb_sem_id` |
| `UPSTREAM_SYNC_SEM` | (sem_id) | From prefetch's `downstream_sync_sem_id` |
| `COMMAND_QUEUE_BASE_ADDR` | `cq_offset` | Absolute offset into sysmem for this CQ |
| `COMPLETION_QUEUE_BASE_ADDR` | `issue_start + issue_size` | Completion queue start in sysmem |
| `COMPLETION_QUEUE_SIZE` | (completion queue size) | |
| `HOST_COMPLETION_Q_WR_PTR` | `128` | `COMPLETION_Q_WR(2) * 64` |
| `DEV_COMPLETION_Q_WR_PTR` | `l1_base + 64` | On dispatch core's L1 |
| `DEV_COMPLETION_Q_RD_PTR` | `l1_base + 80` | On dispatch core's L1 |
| `DISPATCH_S_SYNC_SEM_BASE_ADDR` | `l1_base + 128` | |
| `MAX_NUM_WORKER_SEMS` | `8` | `DISPATCH_MESSAGE_ENTRIES` |
| `MAX_NUM_GO_SIGNAL_NOC_DATA_ENTRIES` | `64` | |
| `MCAST_GO_SIGNAL_ADDR` | (arch-specific) | `hal.get_dev_addr(TENSIX, GO_MSG)` |
| `UNICAST_GO_SIGNAL_ADDR` | (arch-specific) | For active ethernet cores, 0 if none |
| `PACKED_WRITE_MAX_UNICAST_SUB_CMDS` | `X*Y` | Compute grid size product |
| `WORKER_MCAST_GRID` | (encoded) | NOC multicast encoding of compute grid |
| `NUM_WORKER_CORES_TO_MCAST` | `X*Y` | |
| `DISTRIBUTED_DISPATCHER` | `0` | For WORKER core type |
| `FIRST_STREAM_USED` | `48` | For WORKER cores |
| `SPLIT_PREFETCH` | `0` | Not split for HD |

## Implication for blackhole-py

The pre-compiled dispatch ELFs in `blackhole-py/riscv-firmware/p100a/` have all these values baked in as immediate values in RISC-V instructions. This means:

1. **rt_args=[0,0,0] is correct** for single-chip — that's not the bug
2. **The ELFs are tied to a specific device configuration** — NOC coords, buffer addresses, sysmem layout are all hardcoded
3. **To use different dispatch core locations or buffer sizes**, you must recompile the firmware with different defines
4. **The ELFs expect specific semaphore IDs** — the host must initialize those exact semaphore slots

The `l1_base` (`DEFAULT_UNRESERVED`) for Blackhole Tensix is approximately `0x19700` (computed from `MEM_MAP_END=0x82B0 + 69KB`, aligned to 64). All buffer addresses chain from this base.

## Source files

| File | What |
|------|------|
| `tt_metal/impl/dispatch/kernel_config/prefetch.cpp` | Prefetch `CreateKernel()` — sets all defines |
| `tt_metal/impl/dispatch/kernel_config/dispatch.cpp` | Dispatch `CreateKernel()` — sets all defines |
| `tt_metal/impl/dispatch/kernel_config/fd_kernel.cpp` | Base `configure_kernel_variant()` — common defines |
| `tt_metal/impl/dispatch/kernel_config/prefetch.hpp` | `StaticConfig` struct with all field names |
| `tt_metal/impl/dispatch/kernel_config/dispatch.hpp` | `StaticConfig` struct |
| `tt_metal/impl/dispatch/dispatch_settings.hpp` | Default buffer sizes |
| `tt_metal/impl/dispatch/dispatch_mem_map.cpp` | L1 address layout computation |
| `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` | Firmware source — consumes defines |
| `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` | Firmware source — consumes defines |
