# Matmul Peak Performance Sweep — Blackhole P100A

Device: Blackhole P100A, 118 dispatchable cores, 1350 MHz AICLK
Config: bf16 I/O, mixed-precision accumulation, HiFi2 math fidelity
Driver: blackhole-py (fast dispatch)

## Square Dimensions (M=K=N)

| Size | Grid | per_core MxN | block_w | blocks | Min us | TFLOPS |
|-----:|-----:|:------------:|--------:|-------:|-------:|-------:|
|  256 | 10x10 |     —      |    —    |    —   |   14.0 |   2.40 |
|  512 | 10x10 |     —      |    —    |    —   |   24.3 |  11.05 |
| 1024 | 10x10 |    4x4     |   32    |    1   |   51.7 |  41.54 |
| 1536 | 10x10 |     —      |    —    |    —   |   84.2 |  86.08 |
| 2048 | 10x10 |     —      |    —    |    —   |  137.5 | 124.94 |
| 2560 | 10x10 |     —      |    —    |    —   |  215.0 | 156.07 |
| 3072 | 10x10 |     —      |    —    |    —   |  305.6 | 189.73 |
| 3584 | 10x10 |     —      |    —    |    —   |  491.6 | 187.29 |
| 4096 | 10x10 |     —      |    —    |    —   |  643.2 | 213.68 |
| 4608 |   —   |     —      |    —    |    —   |   FAIL | **grid gap bug** |
| 5120 |   —   |     —      |    —    |    —   | 1184.0 | 226.72 |

Peak square: **226.72 TFLOPS** at 5120x5120x5120.

## Rectangular Dimensions

| M | K | N | Min us | TFLOPS |
|----:|-----:|-----:|-------:|-------:|
|  256 | 1024 |  256 |   33.4 |   4.02 |
|  256 | 4096 |  256 |   87.1 |   6.16 |
|  256 | 5120 |  256 |   FAIL | **precision bug** |
|  512 | 2048 |  512 |   60.0 |  17.90 |
| 1024 |  256 | 1024 |   23.4 |  22.94 |
| 1024 | 4096 | 1024 |  139.7 |  61.49 |
| 1024 | 5120 | 1024 |  173.3 |  61.96 |
| 2048 | 1024 | 2048 |   90.9 |  94.50 |
| 2048 | 4096 | 2048 |  236.3 | 145.41 |
| 3072 | 1024 | 3072 |  154.5 | 125.10 |
| 4096 | 1024 | 4096 |  256.2 | 134.11 |
| 4096 | 2048 | 4096 |  385.0 | 178.49 |
| 4096 | 5120 | 4096 |  767.0 | 223.99 |
| 5120 |  256 | 5120 |  243.2 |  55.19 |
| 5120 | 1024 | 5120 |  394.8 | 135.99 |
| 5120 | 4096 | 5120 |  992.1 | 216.46 |

Peak rectangular: **223.99 TFLOPS** at 4096x5120x4096.

## Performance Analysis

### Scaling Behavior

Performance follows a clear S-curve as dimensions grow:

- **256-512**: 2-11 TFLOPS. Overhead-dominated — the 100 cores have almost nothing to compute
  per core (a few tiles each). Multicast setup, semaphore handshakes, and DRAM read latency
  dwarf the actual FMA work. The kernel launch cost is amortized across too little compute.
- **1024-2048**: 42-125 TFLOPS. Rapid scaling as per-core work grows enough to hide
  communication latency. Each core processes enough tiles that the compute pipeline stays
  mostly busy.
- **2560-3072**: 156-190 TFLOPS. Approaching peak utilization. Compute is now dominant but
  DRAM bandwidth for loading A/B tiles and writing C still matters.
- **4096-5120**: 214-227 TFLOPS. Near peak. The compute-to-communication ratio is high
  enough that NOC and DRAM latency are almost fully hidden.

### Bottleneck Breakdown

**Small M and N (tall-skinny or short-wide):**
When M or N is small (e.g. 256), each core gets very few output tiles. The multicast fanout
for in0 (row-wise) and in1 (column-wise) still incurs full semaphore round-trips per K-block,
but each core only produces a 2x2 or similar tiny output tile. Overhead per useful FLOP is
enormous. This is visible in 256x4096x256 = 6.16 TFLOPS — the 100 cores are mostly idle
waiting for multicast synchronization.

**Small K:**
When K is small (e.g. 256), there are very few K-blocks to iterate over, so the compute
pipeline drains quickly. The inner loop `matmul_block` runs for only a few iterations per
output subblock. The ratio of DRAM reads (loading A/B blocks) to compute is unfavorable.
See 5120x256x5120 = 55 TFLOPS — large output but insufficient K to amortize input reads.

**Large K with small output:**
When K is large but M*N is small, the accumulator precision limit kicks in. Large `block_w`
values mean many tiles are accumulated in bf16 destination registers before being flushed,
which loses precision. See the 256x5120x256 failure below.

**3584 regression:**
3584x3584x3584 (187 TFLOPS) is slightly *slower* than 3072x3072x3072 (190 TFLOPS). This is
a tiling artifact: the grid planner pads 3584/32=112 tiles across 10 rows/cols, which gives
per_core_M/N values that don't tile as efficiently (poor subblock factorization or wasted
padding), leading to more idle cycles in the compute kernel.

### Theoretical Peak

Blackhole P100A has 120 Tensix cores, each capable of 8x16 FMA per cycle at 1350 MHz.
A single FMA = 2 FLOPs (multiply + add):

```
120 cores * 8 * 16 * 2 * 1350 MHz = 497.66 TFLOPS (bf16 theoretical)
```

With fast dispatch reserving 2 cores, 118 cores gives ~489 TFLOPS theoretical.
Our measured peak of ~227 TFLOPS is **~46% of theoretical** — reasonable for a real matmul
with DRAM traffic, multicast synchronization, and L1 accumulator management.

The gap comes from:
1. **DRAM bandwidth** — reading A and B tiles from DRAM through NOC
2. **Multicast synchronization** — semaphore round-trips between sender and receiver cores
3. **L1 accumulator spills** — intermediate results written to CB24 and reloaded
4. **Output writeback** — writing C tiles back to DRAM through NOC
5. **Subblock overhead** — tile_regs_acquire/commit/wait/release per subblock

## Failure Analysis

### 4608x4608x4608 — Grid Gap Bug

**Error:** `AssertionError: core (14,2) not in dispatchable_cores`

The P100A's 118 dispatchable cores span:
- X coords: `[1,2,3,4,5,6,7, 10,11,12,13,14]` (12 columns; gap at 8-9 for dispatch/ethernet)
- Y coords: `[2,3,4,5,6,7,8,9,10,11]` (10 rows)

But this is **not a full 12x10 rectangle**. Column x=14 is missing rows y=2 and y=3 — it
only has 8 cores (y=4..11). The total is 12*10 - 2 = 118, not 120.

`_solve_grid` is told `max_cols=12, max_rows=10` (from `len(avail_xs)` and `len(avail_ys)`).
For 4608: Mt=Nt=144 tiles. The solver picks `rows=9, cols=12` (108 cores) as optimal. Then
`_build_grid` tries to construct a 12x9 rectangle using `xs[:12]` and `ys[:9]`, and asserts
every (x,y) pair exists. But (14,2) and (14,3) are not dispatchable cores — assertion fails.

**Fix options:**
1. Cap `max_cols` to 11 (exclude x=14) so the planner never tries 12 columns with y=2 or y=3
2. Make `_build_grid` aware of holes and skip missing cores
3. Have `_solve_grid` validate candidates against the actual core set

### 256x5120x256 — Numerical Precision Failure

**Error:** `Validation failed: rel_l2=0.082229` (threshold is 0.08)

With Mt=8, Kt=160, Nt=8, the solver picks `bw=80` (largest divisor of 160 fitting in L1),
giving only `num_blocks = 160/80 = 2`. Each K-block accumulates 80 bf16 tiles in the
destination register — that's 2560 multiply-accumulate operations per output element before
any flush, all in bf16 precision. The accumulated rounding error exceeds the validation
threshold.

Smaller `bw` values (e.g. 16, 20, 32) would give more blocks (10, 8, 5) and flush the
accumulator more frequently via the L1 accumulator path (CB24), keeping precision in check.
But the scoring function in `_solve_grid` aggressively rewards larger `bw`:

```python
score = (active * max_bw * per_core_work_bias**2, ...)
```

This is correct for throughput (fewer blocks = less overhead) but ignores precision.

**Fix options:**
1. Cap `bw` to a maximum (e.g. 32 or 64) to bound accumulation depth
2. Add a precision-aware penalty to the scoring function for large `bw * tile_size`
3. Switch to FP32 accumulation (`F32_ACC=1`) for large-K cases

## Notes on Dimension Sweep Methodology

The current approach of running individual `matmul_peak.py` invocations per dimension is
slow (~15-30 seconds per point including compilation and device setup). For a comprehensive
sweep across hundreds of dimensions, better approaches:

1. **Batch mode in matmul_peak.py** — accept a file of (M,K,N) triples, compile all unique
   kernel variants once, and run them back-to-back without re-initializing the device. Most
   dimension changes only affect runtime args, not the compiled kernels (the compute kernel
   has all blocking parameters as constexpr, so different blocking = different binary).

2. **Separate planning from execution** — run `_solve_grid` offline for all dimensions to
   identify which share the same compute kernel (same subblock/block parameters), then group
   them. Many dimensions map to the same compiled kernel with different runtime args.

3. **Template caching** — the compiler already caches binaries. But the device
   open/close cycle per run is the real cost. A persistent device handle with a queue of
   programs would let you sweep hundreds of dimensions in seconds.

4. **Grid planner unit tests** — run `_solve_grid` in isolation (no device needed) across
   all target dimensions to catch failures like the grid gap bug and precision issue before
   touching hardware.
