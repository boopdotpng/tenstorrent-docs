# RMSNorm lowering and fusion across kernel boundaries

At tinygrad master `107adc31701df0247dfa45e175984df906a68b53`, the measured CPU schedule for RMSNorm is **two kernels**. Leaving a following matmul lazy also takes two kernels; materializing the normalized tensor first takes three. That is a concrete eliminated kernel boundary and intermediate tensor, beyond simply combining arithmetic inside an existing kernel. The experiment compares kernel partitioning during scheduling of lazy versus explicitly materialized graphs; it does **not** demonstrate late merging of already compiled kernels or the proposed CALL-level fusion discussed in September meetings.

These are executed results, not proposed schedules. The [probe](probe-rmsnorm.py) and [summary](rmsnorm-artifacts/summary.json) record float32 inputs, `DEV=CPU`, `ClangRenderer`, `BEAM=0`, normal heuristics (`NOOPT=0`), and disabled schedule caching (`SCACHE=0`). This is a CPU source/compiler study, not a Blackhole/GPU performance result or a universal fusion guarantee. “Kernel” here means a scheduled compiled `PROGRAM` invocation, including CPU functions.

## The computation, before the compiler

RMSNorm rescales each row by its **root mean square**. Square each element, average those squares, take a square root, then divide each original element by that common denominator. A learned weight multiplies each output position. A small positive `eps` inside the square root prevents division by zero on an all-zero row.

For a paper example, let `x=[3,4]`, `w=[1,2]`, and temporarily use `eps=0`. The squared values are `[9,16]`, their mean is `12.5`, and the denominator is approximately `3.5355`. The output is approximately `[0.8485,2.2627]`. The real probe uses `eps=1e-5` and the larger shapes below; these hand calculations are only an explanation of the formula.

The mean is a **reduction**: many input elements produce one value. Applying that value to every element is a **broadcast**. These two steps need different loops. A compiler might first finish a row's reduction and then loop over its outputs inside one kernel. Or it might store denominators and run a second kernel. The interesting fusion question is which arrays must actually be stored between those loops.

Tinygrad initially records requested operations without executing each Python line. That is **lazy execution**. **Materializing** or **realizing** a tensor executes enough work to put its values in a buffer. A **kernel** is one compiled unit invoked by the runtime; here it can be a CPU function. Combining calculations inside that unit is operation fusion. Eliminating a producer's stored array and separate invocation is the kernel-boundary change measured in this chapter.

## Reproduce and audit

From `/home/boop/tenstorrent`:

```sh
tinygrad/.venv/bin/python boop-docs/compiler-maps/tinygrad/probe-rmsnorm.py \
  --tinygrad tinygrad --out /tmp/rmsnorm-recheck
```

The Python environment needs NumPy and a working tinygrad CPU compiler. Recorded environment: Python 3.13.11, NumPy 2.4.2, x86-64 Linux. The script imports from the explicitly supplied checkout and records its actual HEAD. Current tinygrad uses `DEV=CPU`; the older `CPU=1` and `CPU_CC=clang` environment spellings are rejected.

A **DAG** is a directed acyclic graph: operations refer to their inputs, and shared inputs need not be copied into every use. An **AST** here is the saved graph describing the work inside one chosen kernel.

For every phase, `*.tensor.txt` is the requested tensor DAG before scheduling, `*.kN.ast.txt` is the scheduled kernel AST before codegen, `*.kN.c` is actual rendered source, and `schedule.json` identifies input/output buffer edges and operation histograms. Node numbers are local to each DAG; `PARAM` slots are local to each kernel. Buffer identities such as `temp2` connect kernels **within a case**, not across independent cases. `ProgramInfo.ins`/`outs` supply read/write classification; filenames and kernel names alone do not establish fusion.

The probe executes the exact `LINEAR` returned by `schedule_linear()`. That matters: scheduling rewrites Tensor graphs to storage; scheduling once for inspection and then independently calling `realize()` is not a safe substitute for executing that saved schedule. Intermediate phases in the materialized cases actually execute before the next expression is built, enforcing the same storage boundary as `.realize()` while preserving inspectable schedules.

Input creation/realization and output `.numpy()` reads are outside the counted phases. Every recorded phase has zero non-compute calls. No timing measurements are made. All twelve checked outputs across eleven cases passed a float64 NumPy reference with `rtol=2e-5, atol=2e-5`. Inputs are deterministic (`seed=20260917`) and include a near-zero first row to exercise epsilon. The largest absolute error was `7.67e-6` for the lazy matmul consumer; standalone RMSNorm was `3.68e-7`. This does not test fp16/bfloat16, symbolic shapes, multi-device behavior, or exceptional floating-point values. The expression is explicitly float32; do not extrapolate its cast placement to the stock `nn.RMSNorm` layer on lower-precision inputs.

## Measured boundary changes

Unless stated otherwise, `x`, residual `r`: `(4,128)` float32; weight `w`: `(128,)`; epsilon `1e-5`; matmul matrix `A`: `(128,32)`.

| Case | Compute kernels | What is materialized between kernels? |
|---|---:|---|
| RMSNorm, lazy | 2 | Four row denominators |
| RMSNorm, five explicitly executed stages | 5 | Square tensor, means, inverse scales, normalized tensor |
| `(x+r)` → RMSNorm, lazy | 2 | Four row denominators; no residual sum tensor |
| Execute `x+r`, then RMSNorm | 3 | Residual sum plus row denominators |
| RMSNorm → matmul, lazy | 2 | Four row denominators; no normalized tensor |
| Execute RMSNorm output, then matmul | 3 | Row denominators plus normalized tensor |
| RMSNorm → row sum, lazy | 2 | Four row denominators; no normalized tensor |
| Execute RMSNorm output, then row sum | 3 | Row denominators plus normalized tensor |
| Request RMSNorm output **and** row sum together | 3 | Row denominators plus requested normalized output |
| RMSNorm at `(4,127)` | 2 | Four row denominators |
| RMSNorm at `(1,4096)` | 2 | One row denominator |

The last two cases are negative controls: these shape changes did **not** change the kernel count. Fanout/output demand provides the observed splitting case; there is no invented width threshold.

## Follow one RMSNorm through the compiler

Define

```python
s = (x*x).mean(-1, keepdim=True)
y = x * (s + 1e-5).rsqrt() * w
```

Mathematically, `y[b,j] = x[b,j] * w[j] / sqrt(sum_k x[b,k]^2 / 128 + eps)`.

The first important translation is in the tensor API. [`mean`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/mixin/op.py#L493) constructs a sum with its accumulation dtype, divides by the reduction extent, and casts to the output dtype. [`rsqrt`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/mixin/elementwise.py#L821) is literally `self.sqrt().reciprocal()`. An API method is not an opaque kernel or necessarily a dedicated primitive UOp.

The [input DAG](rmsnorm-artifacts/rms_lazy/output.tensor.txt) therefore contains ordinary multiply, reduce, square-root, reciprocal, and movement/shape nodes. Shape-bearing UOps express broadcasting without first creating a repeated `(4,128)` denominator array.

[`Tensor.linear_with_vars`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/tensor.py#L394) turns requested results into storage-backed calls. [`lower_sink_to_linear`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/schedule/__init__.py#L120) then invokes:

```python
linear = create_schedule(get_kernel_graph(prepare_rangeify(function)))
```

The kernel boundary question principally lives inside that `get_kernel_graph` step, before per-kernel rendering:

In the following steps, a **range** describes a loop coordinate and its extent: for this input, row `b` runs from 0 to 3 and column `j` from 0 to 127. Propagating a consumer’s ranges backward asks, “which input value is needed for this output iteration?”

1. [`run_rangeify`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/schedule/indexing.py#L188) propagates consumer iteration ranges backward. Reductions introduce reduction ranges. A broadcast reuses the same reduced value across an output range; the compiler must track where the reduction range ends. Multiple consumers can require different output ranges and partial/full realization.
2. `STAGE` marks candidate storage boundaries. [`pm_remove_bufferize`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/schedule/rangeify.py#L127) may substitute a staged producer into a consumer's indexing. This is where eliminating a prospective producer/consumer buffer can remove a kernel boundary. It refuses non-removable stages, has an input-buffer-count heuristic, and retains stages when reductions access buffers. These are concrete conservative choices, not a universal optimal cost model.
3. [`get_kernel_graph`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/schedule/rangeify.py#L367) runs symbolic/reduction/debufferization cleanup, buffer-limit enforcement, conversion of stages to stores, then `split_kernels`. `split_store` extracts completed range regions into kernel calls.
4. `create_schedule` orders the resulting calls using buffer-state dependencies, including read-after-write and write-after-read hazards. A reader must wait for its producer to finish writing, and a later overwrite must wait for earlier readers to finish. It does not turn two already-rendered C functions into a fused function.

In the measured result, the reduction-to-broadcast boundary survives. A four-element buffer `d` holds **the square root denominator**, not the inverse scale. The subsequent kernel divides by it. Read the actual [first source](rmsnorm-artifacts/rms_lazy/output.k0.c) and [second source](rmsnorm-artifacts/rms_lazy/output.k1.c):

```c
// Exact first-kernel store; buf0 accumulated the row's squared elements.
*(data0_4+Lidx1) = __builtin_sqrtf((((*(buf0+0))*0.0078125f)+9.999999747378752e-06f));
```

Its schedule is:

```text
K0: read x[4,128]                     -> write d[4]
K1: read x[4,128], d[4], w[128]        -> write y[4,128]
```

`0.0078125` is `1/128`. The emitted epsilon spelling reflects float32 rounding. K0 unrolls the reduction by four, putting four iterations’ work together. K1 upcasts by four, grouping four output elements, and uses `float4` loads/stores. Here “upcast” is a loop-layout choice, not an increase in floating-point precision. These loop/vector decisions happen **inside** the two kernel regions; their presence is not evidence of a removed kernel boundary.

The [five-stage baseline](rmsnorm-artifacts/rms_staged/schedule.json) explicitly executes `x*x`, its mean, `(mean+eps).rsqrt()`, `x*scale`, then multiplication by weight. It produces five kernels because the intermediate tensors must exist before later expressions are constructed. Leaving the graph lazy eliminates three of those boundaries, but does not eliminate the row-statistic boundary. This makes “RMSNorm is fused” too imprecise: name the actual surviving buffers.

## Residual producer: fewer kernels, duplicated work

Compare `rms(x+r,w)` with `z=(x+r).realize(); rms(z,w)`.

```text
lazy:
  K0: x,r       -> d
  K1: x,r,d,w   -> y

materialized:
  K0: x,r       -> z
  K1: z         -> d
  K2: z,d,w     -> y
```

The lazy graph absorbs the residual-add producer into **both** consumers of that producer. Actual [K0 source](rmsnorm-artifacts/residual_lazy/output.k0.c) contains `float alu2 = (val0[0]+val1[0]);` before squaring. Actual [K1 source](rmsnorm-artifacts/residual_lazy/output.k1.c) contains `(((val1[0]+val2[0])/val0)*val3[0])` in the output store.

Consequently the residual addition is computed twice per element across the surviving kernels. Saving an intermediate buffer and dispatch can be worthwhile, but “fusion means each arithmetic operation runs once” is false. At this shape, the eliminated `z` buffer is 2,048 bytes. The lazy schedule reads both `x` and `r` in both kernels; the materialized schedule reads them once and reads `z` twice. Traffic and cache behavior therefore require a fuller comparison than the removed tensor size. The probe makes no speed claim.

This is also why the scheduler's reindexing/cost logic matters more than simply having a matcher for `ADD` followed by `MUL`.

## Consumer fusion: RMSNorm → matmul

Let `z = rms(x,w) @ A`. The materialized baseline is:

```text
K0: x         -> d[4]
K1: x,d,w     -> y[4,128]
K2: y,A       -> z[4,32]
```

The lazy [schedule](rmsnorm-artifacts/matmul_lazy/schedule.json) instead is:

```text
K0: x         -> d[4]
K1: x,d,w,A   -> z[4,32]
```

K1's [scheduled AST](rmsnorm-artifacts/matmul_lazy/consumer.k1.ast.txt) proves more than counting two calls: it indexes the original `x`, row denominator, weight, and matrix parameters, multiplies those values, and reduces. There is no 512-element normalized input buffer. This is fusion of the normalization-output producer with the matmul consumer region.

Now compare the AST with its [generated source](rmsnorm-artifacts/matmul_lazy/consumer.k1.c). In the AST, multiplication by the reciprocal denominator is inside the reduction expression. In generated C, the dot-product accumulation contains `x*w*A`, followed by:

```c
*(data0_128+((Lidx1<<5)+Lidx2)) = ((*(buf0+0))/val0);
```

`val0` was loaded from the row denominator buffer outside the output-column loop. Algebraically the code computes:

```text
z[b,n] = (sum_j x[b,j] * w[j] * A[j,n]) / d[b]
```

This second observation is a **within-kernel** rewrite, distinct from eliminating `y`. [`symbolic.reduce_mul_chain`](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/uop/symbolic.py#L396) partitions multiplicative factors by dependence on reduction ranges and moves independent factors outside an additive reduction; the matcher is registered at line 475. The captured AST/source show the resulting change, but the probe does not capture a per-rule firing trace, so they do not establish the precise first invocation of that rule.

There is a real numerical tradeoff: `sum((x/d)*w*A)` and `sum(x*w*A)/d` can round differently in finite precision. The float64 reference check tolerates ordinary float32 differences; it is not a proof for overflow, underflow, NaNs, or strict reproducibility. The CPU source also multiplies `x*w` across output columns rather than loading a precomputed `y`; eliminated storage can trade against recomputation. Whether this wins on a tensor-core GPU or Blackhole needs a backend-specific experiment.

## Second reduction and fanout: output demand changes fusion

**Fanout** means one computed value has multiple consumers. It becomes important when a consumer needs an array in a different loop order, or when the array must also be returned to the caller.

The same effect occurs without matmul. `rms(x,w).sum(-1)` is two kernels: the row denominator and a reduction of `x*w` followed by division by that denominator. See [actual consumer source](rmsnorm-artifacts/row_sum_lazy/consumer.k1.c). Forcing `y` to storage first takes three.

Now request both `y` and `y.sum(-1)` in one scheduling call:

```python
y = rms(x,w)
s = y.sum(-1)
linear = y.schedule_linear(s)
```

The measured [fanout schedule](rmsnorm-artifacts/fanout/schedule.json) has three kernels:

```text
K0: x       -> d[4]
K1: x,d,w   -> y[4,128]   # demanded output
K2: y       -> s[4]       # reads that same output buffer
```

The tensor `y` must remain available as an output, and its consumers have different iteration requirements. `run_rangeify` explicitly considers consumer range agreement and realization. This run retains `y` and consumes it; it does not produce one multi-output reduction kernel. Merely storing `y` in a Python variable is not the same thing as demanding it as a realized output. Conversely, this example does not prove that all fanout forces materialization: compatible consumer ranges and other shapes can behave differently.

## Which abstraction answers which question?

| Question | Inspect | Why this abstraction exists |
|---|---|---|
| What computation and broadcasting were requested? | Tensor DAG, shape-bearing UOps | Preserve semantics independently of storage/loops |
| Why did producer and consumer separate? | `indexing.run_rangeify`, `STAGE`, removable stages | Decide which loops can share work and which results must be stored |
| Did a boundary actually disappear? | Scheduled calls and buffer identities | Distinguish eliminated storage from pretty arithmetic |
| Why did the denominator move outside the dot product? | Per-kernel AST versus generated source, symbolic rewrites | Simplify arithmetic after a kernel region has been chosen |
| Why vector width four? | Kernel `applied_opts`, generated C | Select a loop/layout implementation for this backend |
| Why must this kernel run first? | `AFTER` states and `create_schedule` dependencies | Keep reads, writes, and mutation ordering valid |

The main diagnostic mistake is editing a late arithmetic PM to solve an earlier storage-boundary problem. Conversely, changing rangeify to fix a missed invariant-factor simplification changes more than necessary. For example, an invariant factor is one that stays constant throughout a particular loop: `d[b]` stays fixed as the column index changes. Start by locating the first representation where the behavior diverges from the intended result.

## Advanced exercises with worked solutions

**1. Prove kernel fusion, without using the kernel names.** Compare lazy and materialized matmul. Identify the disappeared producer buffer and verify its consumer replacement.

**Solution.** Materialized RMSNorm phase writes `temp4` (512 float32 elements); its matmul phase reads that buffer plus `matrix`. Lazy matmul instead takes `x`, `temp3` (four denominators), `weight`, and `matrix`, and writes 128 outputs. Its AST contains a reduction of the indexed factors. Total scheduled compute calls fall from three to two. Those buffer edges plus the AST establish removal of `y`, independently of function-name formatting.

**2. A proposed optimization removes every stage before a multiply. Explain why that is not a valid general fusion policy.**

**Solution.** The RMSNorm denominator depends on a reduction over all 128 elements of its row, whereas its broadcast consumer produces 128 values. Substitution can repeat that reduction per consumer element, or create incompatible range nesting. Fanout can require separate ranges or a demanded output, and explicit/custom-kernel storage constraints must remain. Current `remove_bufferize` rejects non-removable stages and buffered reductions and includes an input-count heuristic. An improvement needs a legal range mapping and cost argument, not just an adjacent-op pattern.

**3. Count the extra residual additions introduced by lazy fusion for `(4,128)`. Does the deleted 2,048-byte temporary imply lower total traffic?**

**Solution.** Lazy K0 and K1 each add 512 pairs: 1,024 additions versus 512 in the explicit residual producer, hence 512 extra additions. Counting full logical array traversals and ignoring cache, lazy residual inputs consume four 512-element reads; materialization uses two input reads, one `z` write, and two `z` reads, or five traversals. That simplified model favors lazy traffic, but physical traffic depends on cache/reuse, vectorization, allocator placement, and backend. It does not give a measured speedup.

**4. Why can denominator division leave the matmul reduction while weight multiplication cannot? What changes if `w` is a scalar?**

**Solution.** `d[b]` has no dependence on reduction index `j`, so `1/d[b]` is a reduction-invariant factor. `w[j]` depends on `j`, so it remains inside the sum. A scalar weight is also invariant and becomes a candidate for moving outside; the exact emitted schedule/source must be checked because simplification order and floating-point policy matter. The evidence here supports the denominator case, not an unexecuted scalar-weight claim.

**5. Predict and then verify the effect of requesting `y` as an additional output of the row-sum case. Would a Python local variable alone have the same effect?**

**Solution.** This probe changes from two kernels to three when `schedule_linear` requests both outputs. The last kernel reads the stored 512-element `y`. A local variable alone does not demand materialization; the lazy row-sum case already uses `y` as a Python variable and remains two kernels. Add output demand, not variable naming, to the experiment.

**6. Design a credible “fuse the whole RMSNorm” experiment on CPU or Blackhole. What would count as success?**

**Solution.** Define a row-oriented implementation that accumulates the sum, computes its denominator, then produces the row's elements, with an explicit strategy for retaining or rereading `x`. Capture a single scheduled compute region, demonstrate absence of a global denominator intermediate, and verify randomized/near-zero inputs against a reference. On Blackhole also specify tile ownership, reduction completion, synchronization, local storage and spill limits, and output layout. Compare execution time and actual resource behavior against the two-kernel baseline. A reduction in PM count, an inlined reciprocal, or fewer C statements is insufficient. This is an exercise proposal, not a measured backend result.
