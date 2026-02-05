# blackhole-py Fast Dispatch: Bug Analysis

The fast dispatch path in blackhole-py hangs. HEAD commit (`201ecf3`) is titled "non-working fast dispatch". Here are the identified bugs, in order of severity.

## Bug 1: Race condition — firmware overwritten while BRISC is running

`fast_device.py:374-438`

`Device.__init__()` (the parent class) uploads generic firmware to **all** Tensix tiles and releases BRISC from reset. Then `_start_dispatch_cores()` overwrites L1 on the prefetch and dispatch cores with the dispatch ELFs while BRISC is already executing the generic firmware from that same L1.

**Fix**: Hold the dispatch cores in reset before writing the dispatch firmware. Write the ELF segments, then release BRISC. The reset can be done via the soft-reset register at `TensixMMIO` addresses (write to `RISCV_DEBUG_REG_SOFT_RESET_0`).

## Bug 2: `run()` polls via wrong TLB target

`fast_device.py:467-478`

```python
cfg = TLBConfig(addr=0, start=core, end=core, ...)  # <-- never applied to win
mmio_cfg = TLBConfig(addr=mmio_base, ...)
with TLBWindow(self.fd, TLBSize.MiB_2) as win:
  self._set_tile_noc_translation_enabled(win, mmio_cfg, core, ...)  # reconfigures win to MMIO space
  while win.uc[TensixL1.GO_MSG + 3] != DevMsgs.RUN_MSG_DONE:  # reads MMIO, not L1
```

The TLB window is configured for MMIO register space, but the poll loop reads `GO_MSG + 3` (L1 offset ~0x373) through it. This reads garbage from MMIO space, not the worker's L1.

**Fix**: After `_set_tile_noc_translation_enabled`, reconfigure the TLB window to point at the worker core's L1 using `cfg` before polling.

## Bug 3: Dispatch subordinate (NCRISC) never loaded

`fast_device.py:383-384`

`cq_dispatch_subordinate_ncrisc.elf` exists in the firmware directory but is never loaded onto the dispatch core's NCRISC. The dispatch BRISC expects its subordinate to handle `NOTIFY_SUBORDINATE_GO_SIGNAL` and `SEND_GO_SIGNAL` commands.

For the minimal `WRITE_LINEAR`-only path, this may not cause an immediate hang — but the firmware may still expect the subordinate's semaphores to be properly initialized.

**Fix**: Load the subordinate ELF onto the dispatch core's NCRISC and release NCRISC from reset.

## Bug 4 (NOT a bug): rt_args=[0,0,0]

`fast_device.py:400,419`

Originally suspected as the root cause, but **this is actually correct**. The prefetch and dispatch firmware only take 3 runtime args (fabric routing IDs), all of which are 0 for single-chip MMIO. All real configuration (buffer addresses, NOC coords, queue sizes) is baked into the ELFs as compile-time `#define` macros.

See `blackhole/fast-dispatch-abi.md` for full analysis.

## Bug 5: Potential semaphore mismatch

The pre-compiled ELFs have specific semaphore IDs baked in (e.g., `MY_DOWNSTREAM_CB_SEM_ID`, `DOWNSTREAM_CB_SEM_ID`). The host code initializes `sem_values=[dispatch_cb_pages, 0]` for prefetch and `sem_values=[0, 0]` for dispatch, but the semaphore slot indices assumed by the firmware depend on what `CreateSemaphore()` allocated during the tt-metal build that produced these ELFs.

**Fix**: Extract the baked-in semaphore IDs from the ELF (via disassembly) and ensure the host initializes the correct L1 semaphore slots with the right values.

## Bug 6: No issue queue read pointer synchronization

`fast_device.py:237-252`

The `_issue_write()` method writes records to the issue queue and advances the write pointer, but never checks if the prefetch firmware has consumed previous records (no read pointer check). On a fast host, this could overwrite unread commands.

For initial bring-up with few commands this is unlikely to trigger, but it's a latent bug.

## Summary: Likely hang sequence

1. `Device.__init__()` boots all tiles with generic firmware, including the dispatch cores
2. `_start_dispatch_cores()` overwrites dispatch core L1 while BRISC is running → **corrupted state / crash on dispatch cores**
3. Even if the firmware survives the race, the dispatch subordinate is missing
4. `run()` sends commands via CQ, then polls `GO_MSG` through a wrongly-configured TLB → **reads garbage, times out**

The minimum fix path:
1. Hold dispatch cores in reset before writing dispatch firmware
2. Load all required ELFs (including subordinate NCRISC)
3. Release from reset
4. Fix the TLB configuration in `run()` before polling
