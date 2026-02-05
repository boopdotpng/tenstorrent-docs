# TT-Metal debugging and profiling env vars

This is a quick reference for common runtime debugging/profiling controls.

## Logging (host + UMD)

- `TT_LOGGER_LEVEL=Debug|Info|Error|Fatal|Trace`
  - Controls verbosity for TT logger (host runtime and UMD if built with logging).
- `TT_LOGGER_TYPES=...`
  - Filter log categories (e.g. `Op`).

## Kernel debug print (DPRINT)

Enable device-side print buffers and pick cores/RISCs to read:

- `TT_METAL_DPRINT_CORES=0,0` (required; logical cores or `all`, `worker`, `dispatch`)
- `TT_METAL_DPRINT_ETH_CORES=0,0` (optional)
- `TT_METAL_DPRINT_CHIPS=0` (optional, or `all`)
- `TT_METAL_DPRINT_RISCVS=BR|NC|TR0|TR1|TR2|TR*|ER0|ER1|ER*` (optional)
- `TT_METAL_DPRINT_FILE=log.txt` (optional)
- `TT_METAL_DPRINT_PREPEND_DEVICE_CORE_RISC=0` (optional)
- `TT_METAL_DPRINT_ONE_FILE_PER_RISC=1` (optional)

## Watcher (hang detection + waypoints)

- `TT_METAL_WATCHER=120` (poll interval in seconds; enables watcher)
- `TT_METAL_WATCHER_APPEND=1` (append logs)
- `TT_METAL_WATCHER_DUMP_ALL=1` (dump extra state; can be invasive)

Feature toggles:

- `TT_METAL_WATCHER_DISABLE_ASSERT=1`
- `TT_METAL_WATCHER_DISABLE_PAUSE=1`
- `TT_METAL_WATCHER_DISABLE_RING_BUFFER=1`
- `TT_METAL_WATCHER_DISABLE_NOC_SANITIZE=1`
- `TT_METAL_WATCHER_DISABLE_WAYPOINT=1`
- `TT_METAL_WATCHER_DISABLE_STACK_USAGE=1`
- `TT_METAL_WATCHER_DISABLE_ETH_LINK_STATUS=1`
- `TT_METAL_WATCHER_ENABLE_NOC_SANITIZE_LINKED_TRANSACTION=1`
- `TT_METAL_WATCHER_NOINLINE=1`
- `TT_METAL_WATCHER_DISABLE_DISPATCH=1`
- `TT_METAL_WATCHER_PHYS_COORDS=1`

Debug delays (requires watcher enabled):

- `TT_METAL_WATCHER_DEBUG_DELAY=10`
- `TT_METAL_READ_DEBUG_DELAY_CORES=0,0`
- `TT_METAL_WRITE_DEBUG_DELAY_CORES=0,0`
- `TT_METAL_READ_DEBUG_DELAY_RISCVS=BR|NC|TR0|TR1|TR2`
- `TT_METAL_WRITE_DEBUG_DELAY_RISCVS=BR|NC|TR0|TR1|TR2`

## Device program profiler

- `TT_METAL_DEVICE_PROFILER=1` (enable device profiling)
- `TT_METAL_DEVICE_PROFILER_DISPATCH=1`
- `TT_METAL_DEVICE_PROFILER_NOC_EVENTS=1`
- `TT_METAL_DEVICE_PROFILER_NOC_EVENTS_RPT_PATH=/path`
- `TT_METAL_PROFILE_PERF_COUNTERS=<bitfield>`
- `TT_METAL_PROFILER_SYNC=1`
- `TT_METAL_PROFILER_MID_RUN_DUMP=1`
- `TT_METAL_PROFILER_CPP_POST_PROCESS=1`
- `TT_METAL_PROFILER_SUM=1`
- `TT_METAL_PROFILER_PROGRAM_SUPPORT_COUNT=<n>`
- `TT_METAL_PROFILER_DISABLE_DUMP_TO_FILES=1`
- `TT_METAL_TRACE_PROFILER=1`
- `TT_METAL_PROFILER_TRACE_TRACKING=1`
- `TT_METAL_MEM_PROFILER=1`

## Inspector (host runtime RPC + logs)

- `TT_METAL_INSPECTOR=1`
- `TT_METAL_INSPECTOR_INITIALIZATION_IS_IMPORTANT=1`
- `TT_METAL_INSPECTOR_WARN_ON_WRITE_EXCEPTIONS=0`
- `TT_METAL_INSPECTOR_RPC=1`
- `TT_METAL_INSPECTOR_RPC_SERVER_ADDRESS=localhost:50051`

## Runtime paths and debug info

- `TT_METAL_HOME=/path/to/tt-metal`
- `TT_METAL_RUNTIME_ROOT=/path/to/runtime/artifacts`
- `TT_METAL_LOGS_PATH=/path/for/logs`
- `TT_METAL_RISCV_DEBUG_INFO=1` (emit DWARF info for kernel ELFs)

## Conflicts

- Do not enable `TT_METAL_DEVICE_PROFILER`, `TT_METAL_DPRINT_CORES`, and `TT_METAL_WATCHER` at the same time. They share SRAM resources and conflict.
