# Inductor exercises with worked solutions

Companion to [Inductor and kernel fusion](inductor-and-fusion.md), using PyTorch source `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. These are source-reasoning exercises, not executed GPU benchmarks. Each asks for a falsifiable prediction and distinguishes arithmetic equivalence from a compiler's supported transformation.

The central question is where one array computation becomes separately
executed work. A **materialized** value has its own addressable storage; a
**template** is a generated kernel skeleton with supported insertion points;
an **external call** invokes an existing implementation. A matrix-multiply
**epilogue** performs extra work on its output before storing it, and a
**prologue** performs extra work while reading its inputs. Read the
[worked lowering sequence](inductor-and-fusion.md#from-array-expressions-to-a-schedule)
if those distinctions are new. The steps below let you reason through each
case before reading its solution.

## 1. Read a kernel count without fooling yourself

**Task.** An RMSNorm compile reports `generated_kernel_count=3`; its generated CPU wrapper invokes a single C++ function containing several loops. How many CPU wrapper invocations did the compiled region issue? What can you conclude about GPU launch count?

**Work through it.** Locate the wrapper call site first. Then open the called function and count its loops separately. Finally ask what the compiler metric counts. These are three different observations even if a tool labels all of them “kernels”.

**Solution.** One generated C++ invocation in that wrapper. The metric counts compiler-generated kernel components and is not a universal runtime-launch count. CPU code may group reduction and pointwise loops under one compiled function.

It says nothing about GPU launch count.

Inspect the wrapper and use a profiler for runtime events, including work inside external library calls. This distinction is demonstrated by the installed-wheel [RMSNorm artifacts](artifacts/rmsnorm/), whose version differs from the reviewed checkout.

## 2. Design an RMSNorm boundary experiment

**Task.** For `z=x.float()+r.float(); q=rsqrt(mean(z*z,-1,keepdim=True)+eps); n=cast(z*q*w); y=gelu(n@W+b)`, predict plausible boundary changes when (a) GEMM uses an external implementation, (b) a template supports GELU epilogue, (c) H becomes very large. Do not give a universal kernel count.

**Work through it.** Mark the row statistic q, the normalized array n, and the matrix output. For each candidate implementation, ask which of those must already be stored before the next computation can begin. Then ask whether bias/GELU can run before the matrix output is stored.

**Solution.** (a) n must be materialized for the external GEMM; ordinary generated pointwise code cannot be inserted into its opaque implementation, so GELU may remain separate.

(b) A compatible generated template may absorb bias/GELU, eliminating that output materialization/launch.

(c) the normalization reduction can split into partial reductions plus combination, increasing intermediate storage or stages. Inspect `kernel/mm.py:tuned_mm`, `scheduler.py:_can_fuse`, and `ir.py:Reduction.create` to test these predictions. Changes in shape can also change the selected GEMM and normalization resource costs.

## 3. Why a normalization producer is not a normal matmul prologue

**Task.** Compare `n=x*scale; y=n@W` with `n=RMSNorm(x); y=n@W`. What explicit guard distinguishes them? Can a clever programmer still implement a fused algorithm for the second?

**Work through it.** To compute one element of x*scale, list the values needed: one x element and its scale. To compute one normalized element, add every element needed for the row statistic. The extra row-wide dependency is the reason to inspect the reduction guard.

**Solution.** The generic template prologue path rejects a producer if `node1.is_reduction()` or `node1.is_template()`. Elementwise multiplication may pass, provided the template allows that input and use/alias/heuristic conditions hold.

RMSNorm requires a whole-row reduction, incompatible with merely inserting elementwise instructions at a tile load.

A specialized fused kernel can recompute statistics, communicate them, or choose a different tile algorithm; that is additional algorithm/backend support rather than something the generic prologue guard proves legal.

## 4. Add observable outputs

**Task.** Change exercise 2 to return `(y,z,q,n)`. Which buffers become observable? Does this require four kernels? What fusion opportunity is directly threatened?

**Work through it.** Imagine the caller prints each returned array after the function finishes. The compiler must provide those values even if another kernel also uses them internally. Then count consumers of n: the matrix multiply and the caller.

**Solution.** z, q and n must exist as returned tensors with appropriate layout/alias semantics; y already was observable.

One kernel can store several outputs, so four outputs do not imply four kernels.

Returning n adds an external use beyond the matmul, violating the generic template-prologue single-user condition. Even if residual/normalization arithmetic remains fused, output writes cannot be eliminated. Saved training intermediates can create similar obligations without explicit Python returns.

## 5. Differentiate the entire block

**Task.** Derive the RMSNorm input and weight gradients and identify the additional matmul work for `y=n@W`, given upstream matrix gradient G. Which reductions have different domains?

**Work through it.** First pass the output gradient backward through matrix multiplication to obtain the gradient of n. Next split normalization into z, q, and w. Follow both routes from z to n: directly through the multiplication and indirectly through q.

**Solution.** The matrix multiplication produces `y[b,j]=sum_h(n[b,h]*W[h,j])`.
Each `n[b,h]` affects all output columns j, so its gradient sums over j:
`gn=G@W.T`. Each `W[h,j]` affects all rows b, so its gradient sums over b:
`dW=n.T@G`.

Let `a=gn*w` and `q=(mean(z²)+eps)^(-1/2)`. Then `dz=q*a-z*q³*mean(a*z,last_dim)`, and `dw=sum_batch(gn*z*q)`.

Residual addition routes dz to both inputs, subject to casts.

RMSNorm's statistic reduces features per row; dw reduces batch dimensions; GEMMs use their own reduction axes.

AOTAutograd may save n/z/q or recompute selected values. The final schedules depend on that partition and on dtype semantics; these equations alone do not determine kernel fusion.

## 6. Diagnose the two opposing addmm rules

**Task.** Why would a compiler both replace `A@B+b` with `addmm(b,A,B)` and replace `addmm(b,A,B)` with `A@B+b`? Give a chip-specific reason that can prevent the latter.

**Work through it.** Compare two implementation opportunities: a library operation that already handles matrix multiply plus bias, and a generated pointwise tail that handles bias plus activation. Then ask whether changing the boundary also changes where low-precision rounding occurs.

**Solution.** The first exposes a compound operation to a library/template implementation. The second exposes a pointwise bias operation that may combine with downstream pointwise work.

The guards coordinate these policies: `is_valid_addmm_fusion` returns false when `should_prefer_unfused_addmm` holds.

Half/bfloat16 preservation adds another restriction. The source explicitly records an accuracy regression in ROCm gfx950 training+AMP, so the narrowing-cast exception is XPU-only under the relevant option.

This is numerical compatibility as well as fusion cost. A source comment's PR reference is evidence of the stated cause, not a complete historical investigation.

## 7. Find the invalid cast cancellation

**Task.** Is `float32 → float16 → float32` redundant? What about `float16 → float32 → float16`? What else does the actual rule inspect?

**Work through it.** Choose a float32 value that is not exactly representable in float16. After the first narrowing cast its missing bits cannot be recovered by widening. In the reverse chain, ask whether the initial value already lies in the smaller representable set.

**Solution.** The first records rounding to half, so replacing it with float32 identity changes values; `pointless_convert` retains it because the intermediate dtype is narrower than the final dtype.

The second can drop the widening stage since every finite fp16 value is representable in fp32, with ordinary caveats about exact floating-point behavior.

The rule restricts dtypes to a listed floating set; with `emulate_precision_casts`, it checks lossless first-stage widening. “Both are casts” and “same itemsize” are not adequate legality proofs.

## 8. Eliminate cats, including a counterexample

**Task.** a has width 5 and b width 7. Simplify `t=cat([a,b],1); u=cat([t,t[:,:3]],1)`. Repeat with slice width 8. Then consider `split_with_sizes(cat([a,b],1),[5,7],1)` when the cat also feeds another consumer.

**Work through it.** Write the concatenation as positions 0–4 from a and 5–11 from b. A prefix of length 3 stops in a; a prefix of length 8 crosses into b. For the split example, list all users of the concatenated array before deleting it.

**Solution.** Width 3 fits wholly in a, so replace u with `cat([a,b,a[:,:3]],1)`.

Width 8 includes part of b, so the specific first-input-prefix rewrite declines; replacing it with `a[:,:8]` silently loses elements.

Exact cat/split inversion would return `[a,b]`, but this registered elimination requires the cat have no other users.

The additional consumer blocks that specific rule. This does not prove that no later independent optimization is possible.

## 9. Separate legality from profitability

**Task.** Producer P writes `tmp[i]`; Q reads `tmp[i+1]`. Another consumer R reads `tmp[i]`. Which candidate has the simple matching dependency? If the scheduler accepts P+R, must it benchmark them? Must accepted fusion be faster?

**Work through it.** For output index i, identify which producer index each consumer needs. After checking that ordering can be preserved, consider whether combining the work increases live values or duplicates loads. Correctness and speed are separate questions.

**Solution.** P+R has matching indexed dependencies; P+Q does not pass the analogous direct match.

Other rewrites could change indexing, but identical buffer names alone do not suffice.

`speedup_by_fusion` may accept without benchmarking when the configuration disables it; CPU C++ and several special cases also bypass generic benchmarking.

Ranking by estimated saved memory is a policy, not proof of speedup.

More live values, register pressure, reduced parallelism or duplicated loads can outweigh launch/traffic savings.

## 10. Locate and explain a reconstruction rule

**Task.** A user wrote `torch.addcdiv(inp,t1,t2,value=0.5)`, but post-AOT FX contains `inp+(t1/t2)*0.5`. Why deliberately reconstruct `aten.addcdiv`? Test the guard mentally for integer inp with floating result, floating tensors on CPU, floating tensors on ROCm, and a tensor-valued scale.

**Work through it.** Separate the arithmetic formula from its implementation. FMA means a multiply and add performed with fused rounding behavior. Then check each eligibility condition independently: input dtype, output device, and whether value is a scalar or tensor graph node.

**Solution.** CompositeImplicitAutograd decomposed the operator before Inductor saw it. Reconstruction makes the FMA-aware lowering reachable again.

Integer inp fails even if division promoted the result.

CPU fails the GPU output-device requirement.

ROCm uses the `cuda` device spelling and can pass that device gate, with all other guards still required.

Tensor-valued scale fails the scalar-value requirement.

The rewrite is about restoring an implementation opportunity and numerical behavior; it is not an unconditional algebraic reordering valid for every dtype/backend.
