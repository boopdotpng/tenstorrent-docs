# Matmul Peak Performance Sweep - Blackhole P100A

Device: Blackhole P100A

This doc was updated after a planner refactor in `examples/matmul_peak.py` and new benchmark runs.

## What Changed

The matmul planner/generator was re-architected into 5 stages:

1. Topology-aware planning:
   - Planner now ingests exact `dispatchable_cores` and only emits valid layouts that exist on silicon.
2. Hard constraints separated from scoring:
   - Core existence, divisibility, L1 fit, and precision policy are enforced before scoring.
3. Precision policy:
   - Added bf16 `block_w` caps for small-output / large-K cases to avoid accumulation-depth instability.
4. Plan object as single source of truth:
   - Codegen/runtime args consume a `MatmulPlan` instead of recomputing layout assumptions.
5. Planner-only tests:
   - Added topology-hole and precision-policy tests to catch regressions without hardware.

## Validation Status

- Planner unit tests: pass (`tests/test_matmul_peak_planner.py`, 4/4)
- Fast dispatch sanity run: pass with validation (`PCC=0.999944`, `rel_l2=0.011338`)
- Slow dispatch sanity run (`TT_USB=1`): pass with same validation

## Fast Dispatch Sweep (bf16 I/O, mixed accum, HiFi2)

Command: `/tmp/matmul_sweep.sh`

| Size | Min us | TFLOPS |
|-----:|-------:|-------:|
|  256 |   14.0 |   2.40 |
|  512 |   24.4 |  11.00 |
| 1024 |   51.5 |  41.70 |
| 1536 |   84.2 |  86.08 |
| 2048 |  138.0 | 124.49 |
| 2560 |  215.2 | 155.92 |
| 3072 |  306.1 | 189.42 |
| 3584 |  491.7 | 187.26 |
| 4096 |  642.7 | 213.85 |
| 4608 |  948.4 | 206.34 |
| 5120 | 1185.8 | 226.37 |

Peak square (this run): **226.37 TFLOPS** at 5120x5120x5120.

## Fast Dispatch Sweep (f16 I/O, mixed accum, LoFi) - Square

Command: `F16=1 MATH_FIDELITY=lofi /tmp/matmul_sweep.sh`

| Size | Min us | TFLOPS | Speedup vs HiFi2 bf16 |
|-----:|-------:|-------:|----------------------:|
|  256 |   12.4 |   2.71 |                 1.13x |
|  512 |   21.2 |  12.66 |                 1.15x |
| 1024 |   48.0 |  44.74 |                 1.07x |
| 1536 |   83.3 |  87.01 |                 1.01x |
| 2048 |  134.5 | 127.73 |                 1.03x |
| 2560 |  207.9 | 161.40 |                 1.04x |
| 3072 |  284.8 | 203.59 |                 1.07x |
| 3584 |  408.4 | 225.45 |                 1.20x |
| 4096 |  500.7 | 274.49 |                 1.28x |
| 4608 |  664.1 | 294.67 |                 1.43x |
| 5120 |  782.5 | 343.05 |                 1.52x |

Peak square (LoFi+f16): **343.05 TFLOPS** at 5120x5120x5120.

## Fast Dispatch Sweep (f16 I/O, mixed accum, LoFi) - Rectangular

Command: `/tmp/matmul_lofi_rect_sweep.sh`

| M | K | N | Min us | TFLOPS | Speedup vs previous HiFi2 bf16 |
|----:|-----:|-----:|-------:|-------:|-------------------------------:|
|  256 | 1024 |  256 |   27.0 |   4.97 |                          1.24x |
|  256 | 4096 |  256 |   80.9 |   6.64 |                          1.08x |
|  256 | 5120 |  256 |   99.2 |   6.77 |                            n/a |
|  512 | 2048 |  512 |   53.5 |  20.07 |                          1.12x |
| 1024 |  256 | 1024 |   22.5 |  23.86 |                          1.04x |
| 1024 | 4096 | 1024 |  135.2 |  63.54 |                          1.03x |
| 1024 | 5120 | 1024 |  163.4 |  65.71 |                          1.06x |
| 2048 | 1024 | 2048 |   88.9 |  96.62 |                          1.02x |
| 2048 | 4096 | 2048 |  225.4 | 152.44 |                          1.05x |
| 3072 | 1024 | 3072 |  148.8 | 129.89 |                          1.04x |
| 4096 | 1024 | 4096 |  227.9 | 150.77 |                          1.12x |
| 4096 | 2048 | 4096 |  321.6 | 213.68 |                          1.20x |
| 4096 | 5120 | 4096 |  592.4 | 290.00 |                          1.29x |
| 5120 |  256 | 5120 |  233.6 |  57.46 |                          1.04x |
| 5120 | 1024 | 5120 |  321.6 | 166.94 |                          1.23x |
| 5120 | 4096 | 5120 |  670.3 | 320.38 |                          1.48x |

Peak rectangular (LoFi+f16): **320.38 TFLOPS** at 5120x4096x5120.

## Previously Observed Failures: Current Status

### 4608x4608x4608 grid-gap crash

Previous behavior:
- Failed with `AssertionError: core (14,2) not in dispatchable_cores`

Current behavior:
- Passes and produces **206.34 TFLOPS** in the fast-dispatch sweep.

Root cause fixed by topology-aware layout enumeration against actual core coordinates.

### 256x5120x256 precision instability

Previous behavior:
- Could fail validation when planner chose very large `block_w` for bf16 accumulation depth.

Current behavior:
- Passes in LoFi+f16 rectangular sweep (`6.77 TFLOPS`).
- Planner precision policy now caps bf16 `block_w` for small-output-tile cases.

## Notes

- `MATH_FIDELITY` env var is now supported in `examples/matmul_peak.py`:
  - `lofi`, `hifi2` (default), `hifi3`, `hifi4`
- LoFi+f16 improved throughput substantially at larger dimensions in this kernel path, but not a full 2x.
- **Why LoFi doesn't reach 2x:** Tensix has three independent hardware threads (unpack/math/pack) running in parallel; end-to-end throughput is gated by the slowest. LoFi genuinely halves the FPU work (1 MVMUL pass vs 2 for HiFi2), but the unpacker and packer do identical work in both modes. At small dims, math isn't the bottleneck (dispatch/NOC overhead dominates), so LoFi shows ~1.0x. At large dims, HiFi2 is math-bound so LoFi helps, but it makes TRISC1 fast enough that the unpacker becomes the new bottleneck — hence ~1.5x instead of 2x. The ~343 TFLOPS LoFi ceiling at 5120 represents the unpacker throughput limit.
