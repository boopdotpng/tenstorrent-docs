# Fast dispatch host bring-up notes (what docs usually miss)

This is a practical checklist for implementing a minimal host-side fast-dispatch path (single chip, MMIO worker cores), based on `tt-metal` kernel sources.

## 1) Prefetch queue entries are ownership markers

The prefetch queue (`PREFETCH_Q`) is an array of `uint16_t` entries in prefetch core L1.

- `0` means slot is free.
- nonzero means slot owned by prefetcher and contains command size in 16B units.
- prefetch kernel clears consumed entries back to `0`.

Host-side implication: do not blindly advance write index; wait for target slot to become `0` before writing to avoid overwriting unread commands.

Relevant code: `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` (`read_from_pcie`, queue poll loop).

## 2) Issue queue wrap rules are device-driven

Prefetcher wraps PCIe read pointer when `pcie_read_ptr + size > pcie_base + pcie_size`.

Host-side implication:
- Keep issue records 64B aligned (`PCIE_ALIGNMENT`).
- Mirror the same wrap model in host writer.
- Queue correctness comes from: prefetch slot ownership + in-order consumption.

## 3) Dispatch subordinate (NCRISC) is not optional for real GO overlap

`cq_dispatch_subordinate.cpp` handles:
- `CQ_DISPATCH_CMD_SEND_GO_SIGNAL`
- `CQ_DISPATCH_CMD_WAIT`
- `CQ_DISPATCH_SET_NUM_WORKER_SEMS`
- `CQ_DISPATCH_SET_GO_SIGNAL_NOC_DATA`

Without subordinate NCRISC firmware, command streams that rely on async GO signaling or worker semaphore tracking can stall.

Relevant code: `tt_metal/impl/dispatch/kernels/cq_dispatch_subordinate.cpp`.

## 4) Runtime args are tiny; config is compile-time

Prefetch and dispatch BRISC kernels only need 3 runtime args (`my_dev_id`, `to_dev_id`, `router_direction`), usually `0,0,0` on single-chip paths.

Most behavior is from compile-time defines (`PREFETCH_Q_BASE`, `DISPATCH_CB_BASE`, semaphore IDs, NOC coordinates, etc.) generated in:
- `tt_metal/impl/dispatch/kernel_config/prefetch.cpp`
- `tt_metal/impl/dispatch/kernel_config/dispatch.cpp`

Host-side implication: precompiled ELFs are tightly coupled to build-time dispatch settings.

## 5) Semaphore IDs are host/kernel contract, not hardcoded constants

IDs like `MY_DOWNSTREAM_CB_SEM_ID`, `DOWNSTREAM_CB_SEM_ID`, `MY_DISPATCH_CB_SEM_ID` come from `CreateSemaphore()` during kernel setup.

Host-side implication: if you boot standalone precompiled dispatch ELFs, host semaphore initialization must match the IDs baked into those ELFs.

## 6) Minimal stable bring-up sequence

For dispatch cores:
1. Assert soft reset before overwriting dispatch-core L1 firmware.
2. Write dispatch firmware images.
3. Initialize CQ control blocks (`PREFETCH_Q_*`, completion ptrs, sync sems).
4. Write launch/go mailbox state.
5. Deassert required RISCVs (prefetch BRISC; dispatch BRISC+NCRISC if subordinate used).

This avoids races where BRISC executes while its L1 image is being replaced.
