# Blackhole tinygrad backend: hardcoded dataflow kernel patterns

Date: 2026-02-11

## Context

Goal: build a tinygrad backend for Blackhole (`blackhole-py`) where dataflow kernels are mostly static templates, and real op codegen happens in TRISC compute kernels.

Key question: how many dataflow templates are needed, and do we need very high-input (`N`-ary) compute/dataflow kernels.

## What was checked

1. `tt-metal` dataflow kernel inventory and naming patterns (unary/binary/ternary/matmul/mcast/concat/etc).
2. `blackhole-py` examples:
   - `examples/add1.py` (unary pattern)
   - `examples/matmul_naive.py`
   - `examples/matmul_peak.py` (2D mcast matmul pattern)
3. tinygrad runtime behavior on AMD (actual scheduled kernels, buffer arity).
4. `boop-docs/tinygrad/amdgpu_uops_report.md` linearized kernel corpus.

## Hard constraints to respect

- There are 32 CB indices total (`c_0..c_31`): `tt-metal/tt_metal/hostdevcommon/api/hostdevcommon/kernel_structs.h`.
- Historically grouped as:
  - input-like: `c_0..c_7`
  - param/dataflow: `c_8..c_15`
  - output-like: `c_16..c_23`
  - intermed: `c_24..c_31`
- `NUM_CIRCULAR_BUFFERS = 32`: `tt-metal/tt_metal/api/tt-metalium/circular_buffer_constants.h`.

Important practical point: although CB count is 32, compute kernels are not naturally designed for unbounded input streams. Very high fan-in compute should be split above backend level.

## Observed tinygrad kernel arity (AMD runs)

Model-like workloads (max kernel arg buffers seen):
- unary chain: 3
- binary add: 3
- ternary where: 4
- reductions: 3
- layernorm/softmax: 4
- matmul/bmm: 3
- attention core (`qk^T -> softmax -> @v`): 5

Stress/fan-in workloads:
- chained add with `n` inputs can produce a single kernel with `n+1` buffers (output + all inputs).
- examples observed:
  - `n=16` -> 17 buffers
  - `n=20` -> 21 buffers
- `cat`/`stack` with many tensors also scales similarly (`n=16` -> 17 buffers in final concat/stack kernel).

From `amdgpu_uops_report.md` sample:
- 47 kernels total
- max `DEFINE_GLOBAL` count = 5 (typically 4 inputs + 1 output)
- this corpus is not a hard upper bound; synthetic and concat cases exceed it.

## `tt-metal` pattern coverage relevant to backend design

Stable core families:
- unary reader + unary writer
- binary reader + unary writer
- ternary reader + unary writer
- matmul readers/writer (including sender/receiver multicast variants)

Special/multi-input families:
- `reader_nary.cpp` exists in tests (generic concept works).
- concat has dedicated multi-input kernels and explicit splitting strategy.
  - See `ttnn/.../concat_device_operation.cpp`: large input lists are chunked recursively.
  - Also documents effective runtime-arg limit behavior (`256` args) and split-by-batches strategy.

## Recommendation: hardcode this kernel set

Minimum production set:
1. `fill` (0-input -> 1-output)
2. `unary` (1-input -> 1-output)
3. `binary` (2-input -> 1-output)
4. `ternary` (3-input -> 1-output, mainly `where`/fused ternary)
5. `matmul` (2-input -> 1-output)
6. `matmul_mcast` (sender/receiver flavor for scale-up)
7. `concat_copy_n` (data-movement-only N-input copy/pack kernel family)

Optional later:
- dedicated reduction dataflow variants
- tilize/untilize/relayout templates if device-side layout conversion is required.

## Recommendation: TT-specific tinygrad rewrites (required)

Do not let arbitrary fused fan-in map 1:1 into a single TT compute launch.

Add backend-specific rewrite rules before final kernel selection:

1. Associative fan-in split
- For associative ops (`add`, `mul`, bitwise reductions, etc.), if input count exceeds threshold, rewrite to a balanced binary tree.
- Example threshold:
  - conservative: max 3 compute inputs (unary/binary/ternary only)
  - moderate: max 4 compute inputs if you add a quaternary template

2. Concat/stack chunking
- If input tensor count exceeds per-kernel limit, chunk into batches and recursively concat outputs.
- Mirror TTNN strategy conceptually.

3. Keep compute templates simple
- Prefer many small predictable kernels over one giant fused kernel with huge argument/CB pressure.

## Practical policy to start with

- `MAX_COMPUTE_INPUTS = 3`
- `MAX_CONCAT_INPUTS_PER_KERNEL = 8` (safe initial value; tune upward after stability)
- Always split above these limits.

This gives:
- predictable CB usage,
- lower runtime-arg pressure,
- straightforward static dataflow kernels,
- compute specialization remaining in TRISC kernels as intended.

## Representative `blackhole-py` example suite (10-15 files)

Use this as the target coverage set for tinygrad kernel shapes and op classes:

1. `fill_const.py`
- shape: `0 in -> 1 out`
- covers: constant/fill kernels.

2. `copy_identity.py`
- shape: `1 in -> 1 out`
- covers: pure data movement copy.

3. `unary_chain.py`
- shape: `1 in -> 1 out`
- covers: fused unary math (`relu/exp/log/sqrt`).

4. `unary_scalar.py`
- shape: `1 in + scalar -> 1 out`
- covers: scalar-broadcast pointwise ops.

5. `binary_elementwise.py`
- shape: `2 in -> 1 out`
- covers: add/sub/mul/div binary dataflow template.

6. `binary_broadcast.py`
- shape: `2 in -> 1 out`
- covers: row/col/scalar broadcast readers.

7. `ternary_where.py`
- shape: `3 in -> 1 out`
- covers: ternary `where` class.

8. `reduce_sum.py`
- shape: reduction (`1 in -> 1 out`)
- covers: sum reduction + padding-neutral behavior (`0`).

9. `reduce_max.py`
- shape: reduction (`1 in -> 1 out`)
- covers: max reduction + padding masking (`-inf` neutral).

10. `softmax_rowwise.py`
- shape: reduction + pointwise pipeline
- covers: exp/sum/div path.

11. `layernorm.py` (or `rmsnorm.py`)
- shape: multi-stage reduction + pointwise
- covers: norm class kernels.

12. `bmm.py`
- shape: matmul family
- covers: batched matmul schedule and strides.

13. `attention_core.py`
- shape: matmul + softmax + matmul
- covers: transformer-critical chain.

14. `concat_nary.py`
- shape: `N in -> 1 out` data movement
- covers: high-arity inputs, split/chunk policy.

15. `transpose_slice_pad_unpad.py`
- shape: relayout/data movement
- covers: nontrivial indexing and odd-shape boundaries.

### Current `blackhole-py` status vs this suite

Already present:
- `examples/add1.py` (unary baseline)
- `examples/matmul_naive.py` (basic matmul)
- `examples/matmul_peak.py` and `examples/matmul_peak_f16f16_f32acc.py` (optimized matmul + mcast)

Left to add (major gaps):
- binary, ternary, reductions, softmax/norm
- concat/stack high-arity behavior with split rewrites
- relayout ops (transpose/slice/pad/unpad)
- explicit odd (non-32-multiple) shape cases across all categories

## Bottom line

You do not need a general “10+ input compute kernel” to make tinygrad viable on Blackhole.

You do need:
- a small hardcoded dataflow kernel library,
- and TT-specific graph rewrites that cap per-kernel fan-in and split large ops into multiple launches.

That matches both tinygrad behavior and existing TTNN/tt-metal practice.
