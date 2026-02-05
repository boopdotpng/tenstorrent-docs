# Dispatch microbenchmark (fast vs slow)

This note captures how to run the tt-metal dispatch microbenchmark and how it computes the reported timings.

## What this benchmark is

Binary:
- `tt-metal/build_metal_only/test/tt_metal/perf_microbenchmark/dispatch/test_pgm_dispatch`

Source:
- `tt-metal/tests/tt_metal/tt_metal/perf_microbenchmark/dispatch/test_pgm_dispatch.cpp`

This benchmark repeatedly enqueues programs with an optional pattern of “slow” kernels separated by `nfast_kernels` “fast” kernels. It is meant to stress dispatch overhead (especially with short kernels and large `-nf`).

## How to build (C++ only, no Python)

```
./build_metal.sh --build-metal-tests --without-distributed --without-python-bindings --build-dir build_metal_only
```

## How to run (fast vs slow dispatch)

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

## How the timing is computed

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

## Notes

- With `-nf` large, the benchmark spends much more time in dispatch and command queue handling, which is where fast dispatch shines.
- For fair comparisons, run fast and slow with identical flags and a cold device (reset if needed).
