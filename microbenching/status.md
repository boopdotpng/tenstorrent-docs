# Microbenching Status

Concise state of the archived `microbenching/` tree. Raw reports live under
`docs/`; this file is the distilled answer.

## Criteria

- **RUNS** means hardware execution completed and the host validated returned
  data where validation exists.
- **Compute-proof** means the kernel emits real TRISC math/SFPU work and the
  output matches a numpy/reference check.
- Timings are issue-side RISC wall-clock cycles unless the row says launch time
  or bandwidth.
- Job IDs refer to historical `tt-device-queue` hardware runs.

## Current Runnable Set

| area | state | evidence | result |
|---|---|---|---|
| Smoke/copy | RUNS | `examples/add1.py` | one-tile copy/add scaffold passes |
| SFPU unary | RUNS, compute-proof | `microbench_sfpu_transcendental.py` | recip 16 cyc/op, exp 40, rsqrt 58, sigmoid 59, SiLU 62 |
| SFPU reductions | RUNS, compute-proof | `microbench_sfpu_reduce.py` | sum/max 51 cyc/op; rowmax 293 cyc/tile |
| Argmax | PARTIAL | `microbench_sfpu_argmax.py` | value works; N-stage index works; single 32-lane index XFAIL |
| Binary tile ops | RUNS, compute-proof | `microbench_eltwise_binary.py` | add/sub/mul ~676-682 cyc/tile |
| Broadcast tile ops | RUNS, compute-proof | `microbench_eltwise_bcast.py` | row ~678, scalar ~720, col ~835 cyc/tile |
| Softmax row | RUNS, compute-proof | `microbench_softmax.py` | 2746 cyc/tile |
| RMSNorm inverse | RUNS | `microbench_rmsnorm_inv.py` | 3 launches, ~22 us, rel ~= 0.000303 |
| RoPE + K scatter | RUNS | `microbench_rope_k_scatter.py` | ~14.8 us |
| GEMV M=1 | RUNS, compute-proof | `microbench_skinny_gemv.py` | 92.7 GB/s blended, PCC ~= 0.9999 |
| Backend probes | RUNS | math/unpack/pack/sem-CB/instr benches | useful as isolated subsystem probes, not public primitives |
| NoC/DRAM/multicast | ARCHIVED | `docs/noc/` | many historical calibration reports; see `docs/README.md` |

## Missing Or Broken

| area | state | notes |
|---|---|---|
| Movement/layout | BROKEN/MISSING | tilize times out; untilize is host-only; no generic reshape/permute/expand/pad/shrink/flip |
| Generic indexing | MISSING | no reusable index/range/gather-scatter primitive; embedding/KV paths are custom NCRISC proofs |
| Unary tile-map | PARTIAL | exp/recip/near-unit rsqrt/sigmoid/SiLU run; neg, sqrt, log, sin, abs, cast/bitcast/trunc, GELU missing |
| Binary tile-map | PARTIAL | add/sub/mul and broadcast run; max, compares, bitwise, div/mod missing |
| Compare/select | MISSING | no cmplt/cmpne/cmpeq/where primitive; blocks generic masks and causal masking |
| Reductions | PARTIAL | sum/max/rowmax run; product, shape-aware multi-tile, hidden-dim, and cross-core reductions missing |
| Full matmul | UNSTABLE | `examples/matmul_peak.py 64 64 64` timed out in the refresh sweep; GEMV is the stable matmul-like path |
| Attention bridge | UNSTABLE | `microbench_attention_scores_softmax.py` hit a CQ timeout |
| Report defaults | BROKEN for old report appenders | use `--no-report` for old math/instr/sem-CB report-writing paths |

## Quarantine

Do not run these casually without re-auditing: `microbench_tilize.py`,
`microbench_xmov.py`, `microbench_dest_readback.py`, `microbench_sfpu.py`
debug-readback validation, `microbench_pack_backend.py --validate`, full
`examples/matmul_peak.py`, and attention bridge paths.

## Hardware Job Snapshot

| area | command | job | result |
|---|---|---|---|
| smoke | `examples/add1.py --tiles-per-core 1 --cores one` | `4a44dcb0` | PASS |
| SFPU unary | `microbench_sfpu_transcendental.py --iters 4096` | `e7a9b047` | PASS exp/recip/rsqrt/sigmoid/SiLU |
| SFPU reduce | `microbench_sfpu_reduce.py --iters 4096` | `4d7ab968` | PASS sum/max/rowmax |
| binary bcast | `microbench_eltwise_bcast.py --iters 8` | `e755b8b5` | PASS |
| binary | `microbench_eltwise_binary.py --iters 8` | `edf34159` | PASS |
| softmax | `microbench_softmax.py --iters 8` | `3d11d4d7` | PASS |
| RMSNorm | `microbench_rmsnorm_inv.py` | `49e259bf` | PASS |
| RoPE | `microbench_rope_k_scatter.py` | `1fcd42f4` | PASS |
| math backend | `microbench_math_backend.py --iters 100 --no-report` | `6859cc30` | PASS |
| unpack backend | `microbench_unpack_backend.py --no-report` | `d06e74ff` | PASS |
| pack backend | `microbench_pack_backend.py --no-report` | `763d7409` | PASS empty-only smoke |
| sem/CB | `microbench_sem_cb.py --no-report` | `58cfdba0` | PASS |
| instr issue | `tensix_instr_bench.py --no-report` | `72386724` | PASS |
| argmax | `microbench_sfpu_argmax.py --n 1024 --cores 4` | `434f6c99` | VALUE PASS; index single XFAIL, N-stage PASS |
| GEMV | `microbench_skinny_gemv.py` | `d7b20adf` | PASS 92.7 GB/s |
| old report path | `microbench_math_backend.py --iters 100` | `dbe57150` | FAIL: missing report path; use `--no-report` |
| old report path | `tensix_instr_bench.py` | `3d2cc804` | FAIL: missing report path; use `--no-report` |
| old report path | `microbench_sem_cb.py` | `8b3bbdf8` | FAIL: missing report path; use `--no-report` |
| XMOV | `microbench_xmov.py --no-report` | `406ff105` | FAIL: timeout |
| XMOV subset | `microbench_xmov.py --no-report --no-readback-probe --tests <dma_reg_only>` | `c1f8eb64` | FAIL: timeout |
| tilize | `microbench_tilize.py` | `34440c2b` | FAIL: timeout waiting for core `(1,2)` |
| full matmul | `examples/matmul_peak.py 64 64 64` | `5863905f` | FAIL: timeout waiting for core `(1,2)` |
| attention bridge | `microbench_attention_scores_softmax.py` | `c733292f` | FAIL: CQ timeout |

## Tinygrad-Relevant Bottom Line

The runnable set is enough for elementwise add/sub/mul, simple broadcasts,
softmax/RMSNorm/RoPE pieces, reductions, and M=1 GEMV experiments. The main
missing pieces for a reusable lowering target are movement/indexing,
compare/select, wider unary math, multi-tile reductions, full matmul, and
attention programs.
