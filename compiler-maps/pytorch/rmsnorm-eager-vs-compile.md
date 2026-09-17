# RMSNorm: eager execution, compiler fusion, and the boundaries that survive

This is an **executed CPU experiment using the installed wheel**, not an execution of the new source checkout. The wheel is `torch 2.11.0+cu130`, git `70d99e998b4955e0049d13a98d77ae1b14db1f45`; the mapped checkout is `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. No source build or package installation was performed. The CUDA suffix describes the wheel distribution; all tensors and generated kernels here are CPU. GPU behavior, timings, and cross-version numerical equivalence are not validated.

The question is concrete: when several array operations implement normalization, which intermediate arrays and separate calls survive compilation? **Fusion** combines work that could execute separately. Here we inspect CPU generated functions and stored buffers; the experiment does not measure speedup. For background, see [eager execution](eager-execution.md), [Inductor](inductor-and-fusion.md), or the shared [first-principles guide](../first-principles.md).

Reproduce from `/home/boop/tenstorrent`:

```bash
.venv/bin/python boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py
```

The [probe](probes/rmsnorm_cpu.py) fixes the RNG seed, uses two CPU threads and float32 inputs of shape `[8,128]`, disables compiler caches, and saves [results](artifacts/rmsnorm/results.json), Dynamo graphs, pre/post-fusion scheduler IR, lowered FX, and generated C++ embedded in Python wrappers. It uses private compiler/debug APIs: rerunning another wheel may require adapting the probe. Generated artifact imports and wrapper ABI also belong to this wheel.

**How to read the artifacts.** Dynamo captures supported Python execution as an FX graph: calls and their dependencies. Inductor lowers that graph into work on loops and buffers. A **scheduler IR** is its intermediate representation for organizing that work. The generated **wrapper** allocates storage and invokes the resulting C++ functions or external libraries. Its **ABI** is the calling agreement, including which arguments/results those functions expect. Follow these representations to see where each boundary changes.

## The expression and its mathematical contract

RMSNorm scales a row by its overall magnitude, then applies a per-feature weight. **RMS** means root mean square: square the values, average the squares, and take a square root. Taking its reciprocal gives the normalization scale. `eps = 1e-5` is added before the square root so a zero row does not divide by zero. A **reduction** combines many elements into one value; broadcasting then applies that row's scale to every element of the row.

```python
def rms(x, w):
    return x * torch.rsqrt(x.square().mean(-1, keepdim=True) + 1e-5) * w
```

For a two-element illustration with values `[3, 4]` and weights `[1, 1]`, the mean square is `(9+16)/2 = 12.5`. The scale is `1/sqrt(12.5+1e-5)`, approximately `0.282843`, and the output is approximately `[0.848528, 1.131370]`. The actual experiment uses 128 elements per row, so its divisor is 128 rather than 2.

For row `r`, `s[r] = 1/sqrt(sum_j(x[r,j]^2)/128 + 1e-5)` and `y[r,j] = x[r,j]*s[r]*w[j]`. The keepdim matters: the row statistic has shape `[8,1]`, so its broadcast indexes the row, while `w[128]` indexes the feature. Every variant passes the same explicit epsilon, including `F.rms_norm`; otherwise comparing API defaults can silently compare different math.

There are two distinct comparisons. **Eager versus compiled** checks whether compilation preserves the program's values within a tolerance. A separately written **float64 reference** uses wider arithmetic to provide another check on selected cases. Agreement within tolerance is not a claim of identical bit patterns: changing the order of floating-point additions can change rounding.

Numerical checks compare compiled outputs with eager execution; the decomposed, native and strided cases also use a separately written float64 sum/divide/sqrt formula. The backward case compares input and weight gradients against eager autograd. The mutation case checks the input after execution as well as the returned tensor. This is eight bounded execution cases, plus static/dynamic guard and graph-break experiments; it is not a proof for all shapes, dtypes, or exceptional floating values.

## What actually executed

Read each row as a specific invocation of the stated experiment. **Pointwise** work computes one output element from the corresponding inputs; normalization's mean is a reduction. An **external matmul** calls an existing matrix-multiply implementation instead of expressing it inside the generated normalization function. A **stride** describes the address step for moving along a tensor dimension.

“Generated C++ calls” below means invocations visible in captured wrappers for one execution. It does **not** mean GPU launches, number of ATen operations, or number of loop nests. The backward row includes forward and backward wrappers.

| Case | Generated C++ calls | External matmul calls | What the case establishes |
|---|---:|---:|---|
| Decomposed RMSNorm | 1 | 0 | Reduction and broadcast consumer share a generated callable |
| Native `F.rms_norm` | 1 | 0 | A different captured operator can lower to the same generated schedule |
| Residual `rms(x+r,w)` | 1 | 0 | The producer add fuses into the normalization computation |
| `rms(x,w) @ m`, `m[128,64]` | 1 | 1 | Normalization fuses internally; matrix multiply remains an external call |
| RMSNorm forward + backward | 2 | 0 | Autograd creates a separate backward computation and saved-value contract |
| View + input `add_(0.25)` + RMSNorm | 1 | 0 | Observable input mutation survives functionalization/lowering |
| Noncontiguous `x` with stride `(1,8)` | 1 | 0 | The same formula gets a different indexing/vectorization schedule |
| Three separately compiled RMSNorm stages | 3 | 0 | Explicit compilation boundaries retain separate generated calls |

For example, the matmul row means “call one generated normalization function, then one external matrix-multiply routine.” It does not say how many internal loops or lower-level tasks the external routine uses. The backward row counts two generated functions across two phases, not two functions for inference alone.

The raw `metrics.generated_kernel_count` is **3** for contiguous inference RMSNorm even though its wrapper invokes one C++ function; it is **10** for the backward experiment despite two wrapper calls. The metric measures compiler bookkeeping, not this execution's callable count. Inspect `generated_*.py` and scheduler dumps before interpreting it. Likewise the eager profiler's ATen events include nested calls, scalar conversions and allocation; adding their counts does not produce a kernel count.

## Following one row through the compiler

Start with [Dynamo's captured expression](artifacts/rmsnorm/decomposed/dynamo_1.py), then the [lowered FX](artifacts/rmsnorm/decomposed/schedule_0_fx_graph_readable.py), [pre-fusion IR](artifacts/rmsnorm/decomposed/schedule_0_ir_pre_fusion.txt), [post-fusion IR](artifacts/rmsnorm/decomposed/schedule_0_ir_post_fusion.txt), and [actual generated code](artifacts/rmsnorm/decomposed/generated_0.py).

Follow the data dependency first: the output for a row cannot be normalized until its mean-square statistic is available. One possible schedule computes statistics for all rows, then computes outputs for all rows. Another finishes the statistic and output for one row before moving to the next. CPU outer-loop fusion chooses the latter organization here.

The pre-fusion scheduler has two computed-buffer nodes: a row reduction producing `buf0[8,1]`, and a pointwise consumer producing `buf1[8,128]`. The post-fusion node is explicitly `OuterLoopFusedSchedulerNode(SchedulerNode,SchedulerNode)`. This is a scheduling change across producer/consumer work, not merely replacing `square` with `mul` in an expression tree.

The C++ function runs an outer loop over the eight rows. Within each row it first accumulates the squared values using vector loads, writes the row sum to `buf0`, then traverses that row again to normalize and multiply by the weight. Both traversals live in one generated callable, inside an OpenMP region. OpenMP supplies CPU parallel execution; putting both traversals in that region does not turn them into one traversal. The input is loaded twice; the small intermediate still exists; fusion has not made the reduction dependence disappear.

This is an instructive difference from treating “fused kernel” as “one pass over every byte.” CPU outer-loop fusion can combine two ordered inner loops while keeping a scratch buffer. Compare tinygrad's [RMSNorm schedules](../tinygrad/rmsnorm-kernel-fusion.md), where the particular captured backend schedules split the reduction and consumer into separate kernels. The tinygrad walkthrough used `[4,128]`, while this probe uses `[8,128]`; these are not matched benchmark workloads. These are observations of chosen backends, shapes, and revisions, not an inherent two-kernel limit in tinygrad or a universal one-kernel guarantee in PyTorch.

In eager execution, Python calls immediately reach the dispatcher and native implementations. The profiler records `square/pow`, `mean/sum/div_`, `add`, `rsqrt` and two `mul` events, together with bookkeeping. There is no surrounding Dynamo/Inductor graph here to fuse the whole Python expression. A native operator may itself be composite or internally fused: this wheel's native RMSNorm profiler records `aten::rms_norm`, `aten::_fused_rms_norm` **and** nested reduction/pointwise events. The operator name alone cannot establish physical fusion.

## Kernel boundaries: residual producers, explicit staging, and GEMM

A **producer** computes a value that a later **consumer** reads. The important question is whether the producer writes a full intermediate array, or whether its work can happen where the consumer needs it. **Materialization** means creating that stored intermediate. **GEMM** is the conventional name for general matrix multiplication.

In [residual generated code](artifacts/rmsnorm/residual/generated_0.py), `x+r` is calculated in the reduction and again in the output traversal. There is no separate full residual tensor allocation in the wrapper. This trades recomputation of an inexpensive add for avoiding that materialization and a separate callable. Algebraic identity alone would not explain why duplicating the add is useful; storage lifetime and scheduling do.

The staged control compiles three functions independently:

```python
mean_part = torch.compile(lambda a: a.square().mean(-1, keepdim=True))
scale_part = torch.compile(lambda a: torch.rsqrt(a + 1e-5))
out_part = torch.compile(lambda a, b, c: a * b * c)
y = out_part(x, scale_part(mean_part(x)), w)
```

The Python caller is intentionally outside a surrounding compile region. Its three generated wrappers materialize each boundary's output. Compare [staged artifacts](artifacts/rmsnorm/staged/) with the single full-expression callable: this is a concrete **three versus one generated-call** contrast caused by compilation scope. It does not claim that an outer compiled caller could never capture and optimize the composition.

The matrix multiplication has shape `[8,128] @ [128,64] -> [8,64]`. Each output combines a normalized row with a column of `m`, so normalization must be accounted for before or within those multiply-and-sum computations.

For [RMSNorm → matmul](artifacts/rmsnorm/matmul/generated_0.py), the wrapper allocates the complete normalized `buf1`, calls the fused RMSNorm C++ function, then calls `extern_kernels.mm(buf1, arg2_1, out=buf2)`. The external GEMM is opaque (its internal computation is not available for this scheduler to rewrite) to the normalization loop schedule in this captured result. “They are in one FX graph” does not imply they become one generated kernel. Fusing normalization into a GEMM consumer would require a suitable implementation/template and legal treatment of the row reduction and GEMM tiling, plus a profitable schedule. This CPU result does not answer whether another backend or configuration selects one.

## Why training changes the schedule

Training asks how a scalar loss changes when inputs or weights change. **Forward** computes normalized values; **backward** uses the derivative rule to compute those sensitivities. A saved-value interface specifies which forward quantities backward will receive, avoiding their recomputation.

The [training forward wrapper](artifacts/rmsnorm/backward/generated_0.py) returns the visible output **and** saves the original input, weight and reciprocal RMS for backward. Its loops calculate and retain the reciprocal statistic, rather than just treating it as an ephemeral scalar inside the inference row consumer. The [backward wrapper](artifacts/rmsnorm/backward/generated_1.py) consumes those saved values and the output gradient.

An **incoming gradient** `g[r,j]` is the derivative of the eventual loss with respect to output `y[r,j]`. In this probe the loss sums all outputs, so that incoming gradient consists of ones. The formula below is more general and allows any incoming gradient.

For incoming gradient `g`, writing `s=rsqrt(mean(x²)+eps)`:

```text
dw[j]   = sum_r g[r,j] * x[r,j] * s[r]
dx[r,j] = g[r,j] * w[j] * s[r]
          - x[r,j] * s[r]^3 * mean_k(g[r,k] * w[k] * x[r,k])
```

Read `dx` as two effects added together: changing `x[r,j]` directly changes that output element, and also changes the shared normalization scale for the entire row. The second term accounts for that shared-scale effect. For `dw`, the same feature weight is used in every row, so those row contributions add. See [the stepwise derivative exercise](eager-exercises.md#9-derive-rmsnorm-backward-then-find-its-implementation-boundary) for the chain rule.

There is a reduction across features for `dx` and across rows for `dw`. These are different iteration spaces; “backward is a reversed forward graph” is insufficient to derive its scheduling. AOTAutograd chooses a forward/backward boundary and saved-value interface; Inductor optimizes each resulting graph. The probe invokes `.sum().backward()` outside the compiled forward, so the eager loss reduction is not counted among the two generated wrapper calls. Both `x.grad` and `w.grad` are checked.

## Mutation and views are semantics, not optimization hints

A **view** is another tensor object interpreting shared storage; an in-place operation changes the contents of that storage. For example, if `v` views `x`, then `v.add_(0.25)` also changes values read through `x`. Returning a new normalized tensor does not undo this side effect.

The mutation case creates a view, adds `0.25` in place, and returns RMSNorm of that view. The [generated wrapper](artifacts/rmsnorm/view_mutation/generated_0.py) passes the original input both as an input and an output pointer to `cpp_fused_add_copy__mean_mul_pow_rsqrt_0`. The input's changed contents are observable after the function returns. Removing that write merely because only the normalized tensor is returned would be incorrect.

Functionalization lets the compiler reason about a functional graph while arranging the required mutation effects. The [transformed FX](artifacts/rmsnorm/view_mutation/schedule_0_fx_graph_transformed.py) and scheduler record this obligation; the final wrapper/code discharges it. This probe checks one contiguous view alias, not arbitrary overlapping views, returned alias identity, tensor subclasses, or mutation of autograd leaves. Such cases need their own semantic checks.

For an ordinary contiguous `[8,128]` tensor, strides are `(128,1)`: moving to the next row advances 128 elements, while moving to the next column advances one. With stride `(1,8)`, the address of element `[r,j]` instead advances by `r + 8*j` elements from the base. The shape and equation can stay the same while the efficient memory-access direction changes.

The [strided case](artifacts/rmsnorm/strided/generated_0.py) starts with a transposed allocation: shape `[8,128]`, stride `(1,8)`. Mathematical dimensions match contiguous RMSNorm, but contiguous vector loads are along a different physical direction. Inspect the index formulas and the wrapper's `assert_size_stride`: changing a view is often a scheduling and guard question even when it moves no data in eager execution.

## Guards, graph breaks, and the meaning of `fullgraph`

A **guard** checks an assumption on which a captured program depends, such as a fixed shape or Python value. If assumptions no longer hold, capture may produce another variant. A **graph break** ends capture for one region and resumes Python before another region can be captured. Neither concept directly counts machine kernels.

A second experiment uses a counting backend returning `gm.forward`, with **no Inductor kernel generation**. For `sin(x)*scale`, calls use `(row_count, scale)` values `(8,2), (8,2), (12,2), (12,3), (8,2)`.

| Setting | Cumulative backend graph submissions |
|---|---|
| `dynamic=False` | `1, 1, 2, 3, 3` |
| `dynamic=True` | `1, 1, 1, 1, 1` |

The entries are running totals after the five calls, not a new-graph count for each call. With `dynamic=False`, the first call submits a graph; the identical second call adds none; changing rows to 12 adds one; changing scale to 3 adds another; returning to `(8,2)` reuses the first. With `dynamic=True`, all five tested calls reuse a single graph. The counting backend returns `gm.forward`, which executes the captured graph directly, so this isolates capture/reuse from Inductor's optimization decisions.

Under static specialization, the changed tensor shape and then changed Python integer require additional compiled variants; revisiting the first input reuses its variant. In this wheel's dynamic setting, the graph accepts both the changing dimension and integer parameter. Do not generalize to “all Python values become dynamic”: other argument types and control flow can still specialize or break capture.

An explicit `torch._dynamo.graph_break()` between `sin` and `cos` produces **two graph submissions** with the ordinary counting backend; [`fullgraph=True` rejects it](artifacts/rmsnorm/fullgraph_error.txt) with `Unsupported`. Graph fragments are execution/compiler boundaries, while scheduled kernels are the backend's implementation of each fragment. Fullgraph enforces capture without graph breaks; the earlier RMSNorm→GEMM example demonstrates that it does not promise a single kernel.

## Exercises with worked answers

1. **Does one RMSNorm generated call imply no intermediate storage?** No. Find `empty_strided_cpu((8,1), ...)` and the row sum stores in the contiguous wrapper. Outer-loop fusion places ordered loops in one callable; it does not eliminate their data dependency.
2. **Where should you intervene to reduce the three staged calls to one?** First enlarge capture scope to include the whole expression and inspect the new graph and generated wrapper. Adding an algebraic rewrite inside an already separate stage cannot by itself remove Python-level compilation boundaries.
3. **Why is residual recomputation potentially profitable?** The two row traversals need the residual value at different times. Repeating an add costs arithmetic and input reads but can remove an entire residual write/read pair and a separate callable. Profitability depends on memory bandwidth, cache, dtype and backend; the artifact establishes the selected plan, not its measured speedup.
4. **Why didn't the matrix multiply fuse merely because `fullgraph=True` succeeded?** Fullgraph is a frontend capture condition. The scheduler selected a generated normalization computation plus an external GEMM call, and the latter consumes a materialized buffer. Prove the boundary from the wrapper, not the number of Dynamo graphs.
5. **Can training reuse the inference wrapper unchanged?** Not with the captured saved-value ABI. Backward needs input, weight and reciprocal RMS, and its reductions have different axes. An alternative could recompute saved values, but that changes the partition/memory/computation tradeoff.
6. **How would an output-only mutation test miss a compiler bug?** A compiler could produce the correct normalized result while omitting the caller-visible in-place add. Check the original input, and in broader cases also aliases and version-sensitive autograd behavior.
7. **Why is `metrics.generated_kernel_count == 3` not evidence against the single-call claim?** Count invocations in `Runner.call`; the raw counter records code-generation bookkeeping at another abstraction level. CPU subkernels/loop code generation and grouping do not have a one-to-one relationship with wrapper calls.
8. **Does the dynamic probe prove zero future recompilations?** No. It only establishes reuse for its five calls, dtype, layout, function body and wheel. Introduce a noncontiguous layout, a different dtype, a Python branch, or a noninteger parameter and inspect guards again.

## Limitations and reading the evidence

A numerical check asks whether the difference is small enough under the script's stated tolerances. It does not ask whether every bit matches. Output checks cover returned values; gradient checks cover derivative values; input-content checks cover caller-visible effects on the original inputs. Passing one of these does not automatically establish the others.

All eight output checks passed; gradients passed for the backward case, and input-content comparisons passed for every case. Largest eager/compiled output difference was about `1.34e-5` for RMSNorm→matmul. Float64 references passed for the three specified cases. Tolerances are recorded in the script; bitwise equivalence is not expected after changing reduction/vectorization order.

The CPU profiler emitted a `gpuGetDeviceCount` diagnostic from the CUDA-enabled wheel even with CPU-only activities and CUDA visibility disabled; no GPU computation was performed. The preserved [run log](artifacts/rmsnorm/run.log) retains that diagnostic and debug warnings. These runs are validation and compiler inspection, not performance measurements. Current source guides explain the architecture; these installed-wheel artifacts supply a concrete, separately versioned observation of it.
