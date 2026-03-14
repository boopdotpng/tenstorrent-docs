# Matmul fast-path gap analysis (2026-02-05)

## Context

Goal: produce a single-file TT-Metal C++ matmul reference that matches TTNN fast-path performance (170+ TFLOPS on 4096x4096 bf16) and is easy to port into blackhole-py.

## What we measured

- TTNN benchmark path (`ttnn.matmul`) reaches near peak:
  - auto mode: ~171.21 TFLOPS
  - explicit 2D mode: ~170.93 TFLOPS
- New explicit C++ single-file host (`matmul_peak_fast_dispatch.cpp`) runs but tops out around ~86.5 TFLOPS.
- Experimental TTNN-kernel wiring attempt (`matmul_peak_fast_dispatch_v3.cpp`) currently hangs (deadlock/handshake mismatch).

## New information learned

1. Fast dispatch is necessary but not sufficient.
   - We already have fast dispatch in the C++ single-file driver.
   - Throughput still stays ~86 TFLOPS without TTNN-equivalent kernel topology/args.

2. The 170+ path is not one "magic kernel".
   - It is a coordinated stack: role-specific dataflow kernels + specific compile-time args + specific runtime arg ordering + semaphore protocol + split-NoC placement.

3. The biggest gap is exact topology/ABI parity with TTNN 2D mcast factory.
   - When this mapping is off by even a little, cores block in semaphore waits and hang.

## What is still missing vs fastest TTNN path

### 1) Exact per-core kernel role partition

Need literal parity with `matmul_multicore_reuse_mcast_2d_program_factory.cpp` core-grouping:

- in0 sender set
- in0 receiver set (including "other noc setup" split)
- in1 sender+writer set
- in1 receiver+writer set (including "other noc setup" split)

Current single-file v3 still has mismatches in this partitioning logic.

### 2) Exact compile-time arg vectors per kernel

TTNN kernels are sensitive to compile-time arg order/meaning. We need 1:1 ordering for:

- in0 sender
- in0 receiver
- in1 sender/writer
- in1 receiver/writer
- compute kernel (`bmm_large_block_zm_fused_bias_activation.cpp`)

Any index mismatch can cause incorrect semaphore IDs, tensor strides, block geometry, or writer behavior.

### 3) Exact runtime arg packing per core

Per-core runtime args must match TTNN factory ordering exactly, including:

- physical NoC source/destination coordinates
- start tile offsets
- edge padding values (last block/subblock args)
- writer block counts and skip values

Current v3 likely still diverges here.

### 4) Split-NoC behavior parity

TTNN uses preferred NoCs and split-NoC variants for parts of receiver grids. We need exact same conditions and kernel assignment.

### 5) Optional perf defines/tuning parity

Once functional parity is stable, re-check these TTNN-side defines:

- `PACKER_L1_ACC`
- stagger/throttle defines from compute_throttle utils
- fidelity/accumulator flags used by benchmarked fast path

These are second-order compared to getting topology/arg parity correct.

## How complicated is the fast path really?

Short answer: moderately high complexity, mostly in orchestration.

- Kernel count: ~5 core kernels (4 dataflow + 1 compute), plus split-NoC variants.
- Synchronization: 4 semaphores with directional handshakes.
- Host orchestration: substantial per-core runtime arg construction and special handling for edge tiles.
- Complexity source: not math itself; correctness depends on exact ABI and role mapping.

Practical estimate:

- Functional parity implementation effort: medium/high (careful transplant of TTNN factory logic).
- Performance closure from ~86 -> ~170: likely straightforward after parity is correct.

## Recommended next step

Build a `v4` that is a literal, reduced-scope transplant of TTNN 2D mcast factory for one fixed case:

- shape: 4096x4096x4096
- dtype: bf16
- no bias
- no sharding
- no fused collectives
- one batch

Then only remove generic branches after it runs and matches throughput.
