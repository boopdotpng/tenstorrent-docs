# Debugging and measuring runtime work

Choose tooling for the runtime under test. The environment variables and dispatch benchmark below describe the recorded TT-Metal checkout. They do not enable tracing in blackhole-py. For that runtime, start with its test harness, profiler, and firmware completion state.

<a id="debug-env-vars"></a>
## TT-Metal debugging and profiling env vars
<a id="debug-env-vars--tt-metal-debugging-and-profiling-env-vars"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

This is a quick reference for common runtime debugging/profiling controls.

<a id="debug-env-vars--logging-host--umd"></a>
### Logging (host + UMD)

- `TT_LOGGER_LEVEL=Debug|Info|Error|Fatal|Trace`
  - Controls verbosity for TT logger (host runtime and UMD if built with logging).
- `TT_LOGGER_TYPES=...`
  - Filter log categories (e.g. `Op`).

<a id="debug-env-vars--kernel-debug-print-dprint"></a>
### Kernel debug print (DPRINT)

Enable device-side print buffers and pick cores/RISCs to read:

- `TT_METAL_DPRINT_CORES=0,0` (required; logical cores or `all`, `worker`, `dispatch`)
- `TT_METAL_DPRINT_ETH_CORES=0,0` (optional)
- `TT_METAL_DPRINT_CHIPS=0` (optional, or `all`)
- `TT_METAL_DPRINT_RISCVS=BR|NC|TR0|TR1|TR2|TR*|ER0|ER1|ER*` (optional)
- `TT_METAL_DPRINT_FILE=log.txt` (optional)
- `TT_METAL_DPRINT_PREPEND_DEVICE_CORE_RISC=0` (optional)
- `TT_METAL_DPRINT_ONE_FILE_PER_RISC=1` (optional)

<a id="debug-env-vars--watcher-hang-detection--waypoints"></a>
### Watcher (hang detection + waypoints)

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

<a id="debug-env-vars--device-program-profiler"></a>
### Device program profiler

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

<a id="debug-env-vars--inspector-host-runtime-rpc--logs"></a>
### Inspector (host runtime RPC + logs)

- `TT_METAL_INSPECTOR=1`
- `TT_METAL_INSPECTOR_INITIALIZATION_IS_IMPORTANT=1`
- `TT_METAL_INSPECTOR_WARN_ON_WRITE_EXCEPTIONS=0`
- `TT_METAL_INSPECTOR_RPC=1`
- `TT_METAL_INSPECTOR_RPC_SERVER_ADDRESS=localhost:50051`

<a id="debug-env-vars--runtime-paths-and-debug-info"></a>
### Runtime paths and debug info

- `TT_METAL_HOME=/path/to/tt-metal`
- `TT_METAL_RUNTIME_ROOT=/path/to/runtime/artifacts`
- `TT_METAL_LOGS_PATH=/path/for/logs`
- `TT_METAL_RISCV_DEBUG_INFO=1` (emit DWARF info for kernel ELFs)

<a id="debug-env-vars--conflicts"></a>
### Conflicts

- Do not enable `TT_METAL_DEVICE_PROFILER`, `TT_METAL_DPRINT_CORES`, and `TT_METAL_WATCHER` at the same time. They share SRAM resources and conflict.

<a id="dispatch-benchmark-howto"></a>
## Dispatch microbenchmark (fast vs slow)
<a id="dispatch-benchmark-howto--dispatch-microbenchmark-fast-vs-slow"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

This note captures how to run the tt-metal dispatch microbenchmark and how it computes the reported timings.

<a id="dispatch-benchmark-howto--what-this-benchmark-is"></a>
### What this benchmark is

Binary:
- `tt-metal/build_metal_only/test/tt_metal/perf_microbenchmark/dispatch/test_pgm_dispatch`

Source:
- `tt-metal/tests/tt_metal/tt_metal/perf_microbenchmark/dispatch/test_pgm_dispatch.cpp`

This benchmark repeatedly enqueues programs with an optional pattern of “slow” kernels separated by `nfast_kernels` “fast” kernels. It is meant to stress dispatch overhead (especially with short kernels and large `-nf`).

<a id="dispatch-benchmark-howto--how-to-build-c-only-no-python"></a>
### How to build (C++ only, no Python)

```
./build_metal.sh --build-metal-tests --without-distributed --without-python-bindings --build-dir build_metal_only
```

<a id="dispatch-benchmark-howto--how-to-run-fast-vs-slow-dispatch"></a>
### How to run (fast vs slow dispatch)

Fast dispatch (default):

```
./build_metal_only/test/tt_metal/perf_microbenchmark/dispatch/test_pgm_dispatch \
  --custom -w 0 -i 100 -s 256 -n -t -rs 20000 -nf 100
```

Slow dispatch:

```
TT_METAL_SLOW_DISPATCH_MODE=1 \
  ./build_metal_only/test/tt_metal/perf_microbenchmark/dispatch/test_pgm_dispatch \
  --custom -w 0 -i 100 -s 256 -n -t -rs 20000 -nf 100
```

Key flags:
- `-w`: warmup iterations (not timed)
- `-i`: iterations (timed loop)
- `-rs`: slow kernel cycles (explicit runtime cycles for slow kernels)
- `-rf`: fast kernel cycles (optional)
- `-nf`: number of fast kernels inserted between slow kernels
- `-n`, `-t`: disable ncrisc and trisc kernels (keeps only brisc)

<a id="dispatch-benchmark-howto--how-the-timing-is-computed"></a>
### How the timing is computed

The benchmark prints:
- `Ran in <total_us>us`
- `Ran in <us_per_iter>us per iteration`

These values are computed in `run_benchmark_timing_loop`:
1) The benchmark executes `info.iterations` iterations of the chosen workload.
2) It measures elapsed wall time with a steady clock.
3) It divides elapsed time by `executor.total_program_iterations` to produce “per iteration.”

For the standard (non-prefetcher-load) path, `executor.total_program_iterations` is set to `info.iterations`, so the printed “per iteration” is simply:

```
elapsed_us / info.iterations
```

For the prefetcher cache load path (`-pfl`), `executor.total_program_iterations` becomes:

```
info.iterations * programs.size()
```

That means “per iteration” is normalized to total program iterations across all generated programs in that mode.

Relevant code:
- `pgm_dispatch` sets `executor.total_program_iterations` in `create_standard_executor` or `create_load_prefetcher_executor`.
- `run_benchmark_timing_loop` computes `elapsed_us` and divides by `executor.total_program_iterations`.

<a id="dispatch-benchmark-howto--notes"></a>
### Notes

- With `-nf` large, the benchmark spends much more time in dispatch and command queue handling, which is where fast dispatch shines.
- For fair comparisons, run fast and slow with identical flags and a cold device (reset if needed).

<a id="register-memory-tooling"></a>
## Register and memory tooling for pure-py
<a id="register-memory-tooling--register-and-memory-tooling-for-pure-py"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](blackhole-py-runtime.md) for its separate implementation.

<a id="register-memory-tooling--most-relevant-tt-exalens"></a>
### Most relevant: tt-exalens
- Low-level hardware debugger with CLI and Python library for register and memory access.
- CLI highlights: `brxy` (read L1 or DRAM), `wxy` (write L1/DRAM), `riscv rd/wr/rreg/wreg` (RISC-V memory and register access), `tensix-reg`, `noc register`, and GDB server support.
- Python lib highlights: `read_word_from_device`, `read_words_from_device`, `read_from_device`, `write_words_to_device`, `write_to_device`, `read_register`, `write_register`, `read_riscv_memory`, `write_riscv_memory`.
- Notes: Some address ranges are only accessible via the debug interface (example noted in the library tutorial). Coordinates can be provided as NOC or logical locations.

Refs:
- `tt-exalens/README.md`
- `tt-exalens/docs/ttexalens-app-tutorial.md`
- `tt-exalens/docs/ttexalens-app-docs.md`
- `tt-exalens/docs/ttexalens-lib-docs.md`
- `tt-exalens/docs/ttexalens-lib-tutorial.md`
- `tt-exalens/docs/gdb.md`

<a id="register-memory-tooling--also-relevant-luwen-pyluwen-blackhole"></a>
### Also relevant: luwen (pyluwen, Blackhole)
- Host-side abstraction layer; `pyluwen` exposes low-level access for debug tooling.
- L1 access is possible via `noc_read`/`noc_write` (you need core coords and a NOC-visible address). There is no L1 helper; you must know the address map.
- Other BH capabilities in `pyluwen`: `axi_translate` + `axi_read/axi_write` for ARC/AXI registers, `arc_msg`/`arc_msg_buf`, telemetry, TLB setup, DMA buffer allocation/transfer, SPI/bootfs tables, and power control.
- BAR/AXI (MMIO) access is only available on local mmio-capable PCIe devices. For per-core L1/DRAM and dispatch mailboxes you still need NOC reads/writes, even if you configure TLB windows.

Refs:
- `luwen/README.md`
- `luwen/bind/libluwen/README.md`
- `luwen/bind/pyluwen/src/lib.rs`
- `luwen/crates/luwen-kmd/src/tlb/blackhole.rs`

<a id="register-memory-tooling--seeing-where-buffers-land-addresses-l1dram"></a>
### Seeing where buffers land (addresses, L1/DRAM)
- `tt-mlir` `ttrt run --memory --save-artifacts` writes a memory report with per-op buffer placement and addresses for DRAM/L1. This is the closest tool in these repos for tracking where allocations end up at runtime.
- `ttnn-visualizer` consumes memory and performance reports, showing per-core allocations, buffer lifetimes, and layout detail in a UI.

Refs:
- `tt-mlir/docs/src/ttrt.md`
- `ttnn-visualizer/README.md`

<a id="register-memory-tooling--less-directly-useful-for-register-level-debugging"></a>
### Less directly useful for register-level debugging
- `tt-perf-report` focuses on performance traces and does not expose register or memory read/write tooling.
- `tt-lang` is a DSL/compiler project; it discusses memory and DST registers in docs but does not provide live register or memory inspection tools.
