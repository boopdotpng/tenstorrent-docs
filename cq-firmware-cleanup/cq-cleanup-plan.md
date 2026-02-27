# CQ Firmware Cleanup Plan

## Goal

Reduce bloat and verbosity in the CQ (Command Queue) firmware. The firmware kernels
and CQ kernels will **never** be compiled with profiling on, so all profiling
instrumentation is dead weight in the source. Additionally, the fixed topology config
(`cq_fixed_config.hpp`) makes many code paths permanently dead -- they should be removed
to simplify the codebase.

## Instructions

- Refer to `AGENTS.md` for repo conventions (2-space indents, max 150 chars/line, zen of python)
- After big changes, run examples to verify correctness (short timeout, kernels finish in <10s)
- Use `flock /tmp/tt-device.lock` for any device-accessing commands
- Clear `~/.cache/tt-metal-cache` if results look inconsistent after firmware/dispatch changes
- **Definition of done:** pass both:
  1. `flock /tmp/tt-device.lock python3 examples/matmul_peak.py`
  2. `flock /tmp/tt-device.lock env TT_USB=1 python3 examples/matmul_peak.py`

## Key Constraint

**Profiling will never be enabled for CQ firmware.** This means all profiling
instrumentation (DeviceZoneScopedN, DeviceTimestampedData, TRACE_WRITE_BARRIERS,
kernel_profiler.hpp includes) can be **deleted outright** -- not just left for the
preprocessor to eliminate.

---

## Discoveries

### Fixed Config (`cq_fixed_config.hpp`)

The fixed config always sets:
- `IS_H_VARIANT=1`
- `IS_D_VARIANT=1`
- `SPLIT_PREFETCH=0`
- `DISTRIBUTED_DISPATCHER=0`
- `VIRTUALIZE_UNICAST_CORES=0`
- `DOWNSTREAM_CB_BASE=0` / `DOWNSTREAM_CB_SIZE=0` (for dispatch)

These are all `constexpr` values, so the compiler eliminates dead branches at
compile time. But the source code is still bloated with hundreds of lines of
unreachable code.

### Profiling Flags in `compiler.py`

- `PROFILER` flag comes from `helpers.py` line 6: `PROFILER = os.environ.get("TT_PROFILER") == "1"`
- `_PROFILE_DEFINES` (compiler.py lines 120-123): `["-DPROFILE_KERNEL=1", "-DPROFILER_FULL_HOST_BUFFER_SIZE_PER_RISC=65536"]`
- These defines are conditionally added to firmware (line 200-201), dataflow kernels (line 270-271), and trisc kernels (line 286-287)
- The `_run()` function (compiler.py lines 129-151) parses `#pragma message` for `KERNEL_PROFILER` zone map data from compiler stderr when profiling is on

### Instrumentation Inventory (130+ matches across files)

#### Always compiled in (not gated by PROFILE_KERNEL):

**WAYPOINT() calls** (~40+ occurrences across all files):
- Defined in `waypoint.h` -- compiles to `#define WAYPOINT(x)` (no-op) when watcher is disabled (line 46), but writes to L1 mailbox when enabled (line 42)
- These should be **kept** -- they're cheap debug hooks, not profiling

**DPRINT statements** (active, not commented out):
- `cq_dispatch.cpp`: "dispatch_11: start" (line 1162), error dumps in `process_invalid_cmd` (lines 957-964), "cmd_sink"/"cmd_debug"/"cmd_delay" (lines 1078, 1081, 1087)
- `cq_dispatch_subordinate.cpp`: "dispatch_s : start" (line 329), "dispatch_s : done" (line 367), "dispatcher_s invalid command" (line 352)
- `cq_prefetch.cpp`: "prefetcher_11: start" (line 1891), "prefetcher_11: out" (line 1909)
- DPRINT is defined as `DebugPrinter()` when debug printing is enabled, or a discarding no-op otherwise (dprint.h lines 42-44)
- **Decision:** Keep DPRINTs in error paths (process_invalid_cmd). The startup/shutdown DPRINTs are debatable.

**Commented-out DPRINT statements** (~30+ occurrences):
- Scattered throughout all files. Pure source bloat -- remove them.

#### Gated by PROFILE_KERNEL (profiler-only) -- ALL REMOVABLE:

**DeviceZoneScopedN():**
- `cq_dispatch.cpp` line 1196: `DeviceZoneScopedN("CQ-DISPATCH")`
- `cq_dispatch_subordinate.cpp` line 341: `DeviceZoneScopedN("CQ-DISPATCH-SUBORDINATE")`
- `cq_prefetch.cpp` line 1875: `DeviceZoneScopedN("CQ-PREFETCH")`
- Expands to nothing when PROFILE_KERNEL not defined (kernel_profiler.hpp line 714/774)

**DeviceTimestampedData():**
- `cq_dispatch.cpp` lines 1006, 1022, 1053, 1069, 1132: various profiling data points
- `cq_dispatch_subordinate.cpp` line 345: `DeviceTimestampedData("process_cmd_d_dispatch_subordinate", ...)`
- Expands to nothing without PROFILE_KERNEL (kernel_profiler.hpp line 716/784)

**TRACE_WRITE_BARRIERS ifdef blocks:**
- `cq_dispatch.cpp` lines 549-551, 675-677, 789-791, 923-925: contain `DeviceZoneScopedN("noc_async_write_barrier")`
- `TRACE_WRITE_BARRIERS` is **never defined** anywhere in this project -- pure dead code

### Dead Code Paths

#### In `cq_dispatch.cpp` (1219 lines)

| Dead Code | Why Dead | Lines |
|-----------|----------|-------|
| `process_cmd_h()` | Only used when `!is_d_variant` (never true) | 1127-1158 |
| `process_write_host_d()` | Only called when `!is_h_variant` | 385-392 |
| `relay_write_h()` | Only called when `!is_h_variant` | 394-400 |
| `process_exec_buf_end_d()` | Only called when `!is_h_variant` | 402 |
| `relay_to_next_cb()` | Used by D-only and H-only variants; dead in HD mode | 297-383 |
| `process_write_linear_h_by_variant()` | Always takes `is_h_variant` branch -> inlines to `process_write()` | 970-976 |
| `process_write_linear_h_host_by_variant()` | Always takes `is_h_variant` branch -> inlines to `process_write_host_h()` | 978-984 |
| `process_exec_buf_end_by_variant()` | Always takes `is_h_variant` branch -> inlines to `process_exec_buf_end_h()` | 994-1000 |
| `RemoteReleasePolicy` struct | Only used when `is_h_variant && !is_d_variant` | 114-119 |
| `split_prefetch` branch in `process_exec_buf_end_h()` | `SPLIT_PREFETCH=0`, body never runs | 280-287 |
| `distributed_dispatcher` branches | `DISTRIBUTED_DISPATCHER=0`, branch never taken | 933-937 |
| `virtualize_unicast_cores` branches | `VIRTUALIZE_UNICAST_CORES=0`, branch never taken | 888-904 |
| `downstream_cb_*` variables | `DOWNSTREAM_CB_BASE=0`, `DOWNSTREAM_CB_SIZE=0`, used only by dead relay code | 37-39, 97-98 |
| `dispatch_h_cb_writer` | Used only by dead relay code | 292 |
| Terminate relay branch | `is_d_variant && !is_h_variant` is never true | 1114-1116 |
| `relay_client.init` in kernel_main | Guarded by `!(is_h_variant && is_d_variant)` -- never runs | 1188-1190 |
| `relay_client.teardown` | Guarded by `is_h_variant && !is_d_variant` -- never runs | 1214-1216 |

**Estimated removable:** ~200-300 lines

#### In `cq_prefetch.cpp` (1911 lines)

| Dead Code | Why Dead | Lines |
|-----------|----------|-------|
| `kernel_main_h()` | Only used when `is_h_variant && !is_d_variant` | 1780-1812 |
| `kernel_main_d()` | Only used when `!is_h_variant && is_d_variant` | 1814-1858 |
| `relay_cb_get_cmds()` | Only used by `kernel_main_d()` | 1740-1778 |
| `relay_raw_data_to_downstream()` | Only used by `relay_cb_get_cmds()` | 1682-1731 |
| `h_cmddat_q_reader` | Only used by D-variant functions | 1669-1676 |
| `process_relay_linear_h_cmd()` | Only used by `kernel_main_h()` | 1603-1636 |
| `process_relay_inline_all()` | Only used by `kernel_main_h()` | 1640-1664 |
| `relay_payload_to_downstream()` | Only used by H-only functions | 1565-1600 |
| D-variant `cmddat_q_*` defines | Used only by D-variant and some exec_buf paths | 68-72 |

**Note:** `DispatchSRelayInlineState` IS used in `kernel_main_hd()` through
`process_relay_inline_cmd_select` when `dispatcher_type == DISPATCH_SUBORDINATE`.
Do NOT remove it.

**Estimated removable:** ~300-500 lines

#### In `cq_dispatch_subordinate.cpp` (369 lines)

| Dead Code | Why Dead | Lines |
|-----------|----------|-------|
| `distributed_dispatcher` branches | Always 0 | 162-183, 333-335 |
| `virtualize_unicast_cores` branches | Always 0 | 262-279 |
| `worker_count_update_for_dispatch_d[]` | Only used when `distributed_dispatcher=1` | 71 |
| `update_worker_completion_count_on_dispatch_d()` | No-op when `distributed_dispatcher=0` | 160-183 |

**Estimated removable:** ~30-50 lines

#### In `cq_commands.hpp` (418 lines)

| Dead Code | Why Dead |
|-----------|----------|
| `CQDispatchSetUnicastOnlyCoresCmd` (lines 346-350) | No handler in dispatch code, never used |
| `CQ_DISPATCH_CMD_SINK` / `CQ_DISPATCH_CMD_DEBUG` / `CQ_DISPATCH_CMD_DELAY` | Testing-only commands; handlers exist in dispatch but only used in test harnesses |

**Decision:** The testing commands are debatable. The unused struct can go.

#### In `cq_common.hpp` (611 lines)

| Dead Code | Why Dead |
|-----------|----------|
| `CQReadInterface` struct (lines 20-25) | Never used anywhere in the CQ firmware |

#### In `cq_relay.hpp` (94 lines)

`CQRelayClient` IS used by `cq_prefetch.cpp` in `kernel_main_hd()` for
`init_write_state_only` and `write_atomic_inc_any_len` (and some relay paths).
However, the `init()` method wrapping `init_write_state_only` with WAYPOINTs, the
`teardown()` method, and the `write_inline()` method may all be dead. Check before removing.

#### In `compiler.py`

- Should ensure `_PROFILE_DEFINES` are **not** passed to CQ firmware compilation
  (they currently are when `PROFILER=True`, but since profiling is never used for CQ,
  this code path is arguably dead too)

---

## Cleanup Plan (Ordered)

### Phase 1: Remove Profiling Instrumentation
1. Delete all `DeviceZoneScopedN()` calls from CQ firmware
2. Delete all `DeviceTimestampedData()` calls from CQ firmware
3. Delete all `#ifdef TRACE_WRITE_BARRIERS` ... `#endif` blocks
4. Remove `#include "tools/profiler/kernel_profiler.hpp"` if present (check if any file includes it)
5. Remove commented-out DPRINT statements (source bloat)

### Phase 2: Remove Dead Code from `cq_dispatch.cpp`
1. Delete `process_cmd_h()`, `process_write_host_d()`, `relay_write_h()`, `process_exec_buf_end_d()`
2. Delete `relay_to_next_cb()` and associated `dispatch_h_cb_writer`
3. Simplify variant dispatchers: inline the always-taken branches
   - `process_write_linear_h_by_variant()` -> just call `process_write()`
   - `process_write_linear_h_host_by_variant()` -> just call `process_write_host_h()`
   - `process_exec_buf_end_by_variant()` -> just call `process_exec_buf_end_h()`
4. Delete `RemoteReleasePolicy` struct
5. Remove dead `split_prefetch` branch in `process_exec_buf_end_h()`
6. Remove dead `distributed_dispatcher` branch in `process_notify_dispatch_s_go_signal_cmd()`
7. Remove dead `virtualize_unicast_cores` branch in `process_go_signal_mcast_cmd()`
8. Remove dead downstream_cb variables and relay_client usage
9. Simplify `kernel_main()`: remove `!is_d_variant` branch, relay_client init/teardown
10. Simplify `process_cmd_d` terminate case: remove `is_d_variant && !is_h_variant` relay branch

### Phase 3: Remove Dead Code from `cq_prefetch.cpp`
1. Delete `kernel_main_h()` and `kernel_main_d()`
2. Delete helper functions only used by them: `relay_cb_get_cmds()`, `relay_raw_data_to_downstream()`, `process_relay_linear_h_cmd()`, `process_relay_inline_all()`, `relay_payload_to_downstream()`
3. Delete `h_cmddat_q_reader`
4. Simplify `kernel_main()`: remove the h-only and d-only branches, just call `kernel_main_hd()` directly
5. Check if any D-variant-only cmddat_q defines can be removed

### Phase 4: Remove Dead Code from `cq_dispatch_subordinate.cpp`
1. Remove `distributed_dispatcher` branches
2. Remove `virtualize_unicast_cores` branches
3. Remove `worker_count_update_for_dispatch_d[]` array
4. Simplify `update_worker_completion_count_on_dispatch_d()` to a no-op or remove entirely

### Phase 5: Header Cleanup
1. `cq_commands.hpp`: Remove `CQDispatchSetUnicastOnlyCoresCmd`
2. `cq_common.hpp`: Remove `CQReadInterface` struct
3. `cq_relay.hpp`: Audit which methods are still used after Phase 2/3 removals; remove dead ones
4. `compiler.py`: Consider removing profiling define pass-through for CQ firmware

### Phase 6: Test
1. Clear cache: `rm -rf ~/.cache/tt-metal-cache`
2. Run: `flock /tmp/tt-device.lock python3 examples/matmul_peak.py`
3. Run: `flock /tmp/tt-device.lock env TT_USB=1 python3 examples/matmul_peak.py`

---

## Accomplished So Far

- Read all 7 CQ firmware files and compiler.py in full
- Identified all profiling flags in compiler.py
- Grepped all instrumentation across firmware (130+ matches)
- Verified how profiling macros compile (checked tt-metal-deps headers)
- Identified all dead code paths from fixed config analysis
- Created this cleanup plan
- **Not started**: Actually making any changes

## Relevant Files

### CQ Firmware (all in `firmware/cq/`)
- `cq_dispatch.cpp` (1219 lines) -- dispatch kernel, most bloated
- `cq_prefetch.cpp` (1911 lines) -- prefetch kernel, most bloated
- `cq_dispatch_subordinate.cpp` (369 lines) -- subordinate dispatch
- `cq_commands.hpp` (418 lines) -- shared command definitions
- `cq_common.hpp` (611 lines) -- shared utilities, CB reader/writer classes
- `cq_fixed_config.hpp` (154 lines) -- fixed topology config
- `cq_relay.hpp` (94 lines) -- relay client class

### Build System
- `compiler.py` (447 lines) -- compiler with profiling flags
- `helpers.py` -- defines `PROFILER` env var flag
- `defs.py` -- defines `TensixL1` profiler addresses

### tt-metal-deps Headers (read-only reference)
- `tt-metal-deps/include/tools/profiler/kernel_profiler.hpp` -- profiler macro definitions
- `tt-metal-deps/include/tt_metal/hw/inc/api/debug/waypoint.h` -- WAYPOINT macro
- `tt-metal-deps/include/tt_metal/hw/inc/api/debug/dprint.h` -- DPRINT macro

### Repo Conventions
- `AGENTS.md` -- repo conventions and testing instructions
