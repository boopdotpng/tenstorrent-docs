# Eager execution exercises with worked solutions

Use alongside [the source map](eager-execution.md), pinned to PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. These are source-derived worked solutions, not recorded experiment results. Runnable snippets are optional probes; first record the installed version and commit, because the installed wheel can differ from this checkout. GPU kernel-count predictions below require the stated assumptions and should be checked with device profiling, not a count of `aten::` events.

Work through these after [eager execution](eager-execution.md), which introduces dispatch keys, storage, and gradients. Shapes use `[rows, columns]`; FP32/FP16 mean 32-/16-bit floating point. A **materialization** writes a computed tensor into storage for later use. A **kernel launch** submits device code; an operator call may submit zero, one, or several launches.

For each problem, write down (1) the required values and storage effects, (2) the selected implementation, and (3) the evidence needed to count actual device work. This prevents a plausible numerical answer from turning into an unsupported performance claim.

## 1. An operator named “fused” on CPU

**Question.** For contiguous CPU FP32 `x:[32,4096]`, explain `F.rms_norm(x, (4096,), w, eps=1e-5)` without assuming an optimized CPU RMSNorm primitive.

**Solution.** Begin with the equation: each row is multiplied by `1/sqrt(mean(x*x)+eps)` and then by `w`. Nothing in that equation requires one machine kernel.

The Python function calls `torch.rms_norm`. Its `CompositeImplicitAutograd` registration enters `rms_norm_symint`, which generally calls `_fused_rms_norm` after validation/eligibility checks. The private op has CUDA, MPS and XPU registrations but no dedicated CPU registration in this snapshot; CPU falls through to `rms_norm_composite`.

Follow the fallback to see what actually computes the answer. That routine uses other ATen operations: power, mean, epsilon addition, reciprocal square root, multiplication by input and weight, and layout/type handling. A name is not an execution guarantee. See [the schemas](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/native_functions.yaml#L3297) and [composite implementation](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/layer_norm.cpp#L265).

**Extension.** Predict which operations can be no-ops for FP32 contiguous input: conversion to FP32, the final conversion to input dtype, and a contiguous request when layout already satisfies it. “Called in C++” need not imply new data movement.

## 2. Same CUDA op, different kernel boundary

**Question.** Compare RMSNorm on contiguous aligned FP32 `[32,4096]` and `[32,4097]`, with matching contiguous weight. Why can kernel count change without changing the operator?

**Solution.** The equation works for either width. The special implementation, however, processes groups of adjacent values: **vectorization**. A row width of 4096 can fit its groups; 4097 leaves a remainder that this path does not handle.

The vectorized path checks normalized width divisibility as well as alignment, dtype and size. The first width is a fast-path candidate; the second fails vector-width divisibility. Fast-path normalization computes statistics and output together; fallback first computes row statistics, then launches the normalization/output kernel. This excludes layout copies and assumes ordinary grid sizes. Inspect [`LayerNormKernelImplInternal`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1151).

**What to measure.** Collect actual device kernel events for warmed-up executions of both shapes. A profiler event for `_fused_rms_norm` alone cannot prove a one-kernel implementation.

## 3. Residual + RMSNorm + GEMM: identify materializations

**Question.** Trace `u=x+r; y=F.rms_norm(u,(H,),w,eps); z=y@W` in eager inference. Which buffers could a graph compiler try to eliminate?

**Solution.** Track the edges between the three computations:

```text
x,r -> residual addition -> stored u -> RMSNorm -> stored y -> GEMM -> stored z
```

`u` materializes when the residual addition executes. `y` materializes as normalization output and is read by GEMM. RMSNorm can additionally materialize row statistics and contiguous copies. A graph compiler might fuse residual addition into normalization, avoiding standalone storage for `u` when no other consumer needs it.

Next consider the second boundary. Folding normalization into GEMM is harder: normalization requires a reduction across each input row, whereas GEMM tiles its reduction and output dimensions. A compiler could use a separate statistics kernel and a GEMM template that applies the scale while loading, or recompute statistics in some schedule; either choice needs concrete support and a cost argument. Ordinary eager does not synthesize either transformation across these calls.

**Check against tinygrad.** Compare [tinygrad's RMSNorm/kernel-fusion example](../tinygrad/rmsnorm-kernel-fusion.md). Explain the actual scheduled kernels and surviving buffers, rather than declaring fusion merely because an expression has one graph node or one API call.

## 4. Why the dispatcher does not go straight to CUDA

**Question.** A CUDA tensor requires gradients. Why can the first selected implementation be an autograd wrapper rather than the CUDA arithmetic kernel? Why does the wrapper not recurse forever?

**Solution.** The call has two obligations: compute values on the GPU and remember how to differentiate them. An autograd wrapper handles the second obligation, then asks the dispatcher to continue to the arithmetic implementation.

Effective dispatch keys combine tensor key sets and thread-local (TLS) inclusions/exclusions, then apply operator masks. Priority can select an autograd behavior before the backend. That wrapper establishes backward history and redispatches below its own key. Redispatch deliberately changes the key set, preventing selection of the same wrapper again. The relevant contract is [effective key extraction](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/dispatch/DispatchKeyExtractor.h#L24) and [redispatch semantics](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/dispatch/Dispatcher.h#L194).

**Trap.** Turning `requires_grad` off does not imply the tensor has no autograd-related dispatch key. Wrapper selection and the decision to record a node are separate.

## 5. `no_grad` does not repair invalid saved values

**Question.** Predict the failure point:

```python
x = torch.tensor([2.0, 3.0], requires_grad=True)
y = x.square().sum()
with torch.no_grad():
    x.add_(1)
y.backward()
```

**Solution.** Before the update, the forward loss is `2² + 3² = 13`. Differentiating that forward computation gives `[2*2, 2*3] = [4, 6]`. The update changes `x` to `[3, 4]`, but cannot retroactively change which forward computation we are differentiating.

The update is permitted under `no_grad`, but increments the version of storage-backed tensor state used by the saved forward value. Square backward requires the original `x`; when that value is unpacked, the version mismatch triggers an error. Without that check, using the new values would return `[6,8]` instead of the correct forward-program gradient `[4,6]`. `no_grad` suppresses graph recording for the update, not correctness checks on older graphs. See [`SavedVariable::unpack`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/saved_variable.cpp#L128).

**Repair.** Do not mutate data required by an outstanding backward. If a separate mutable tensor is needed, clone it at the appropriate point rather than merely disabling grad mode.

## 6. A detached alias still changes storage

**Question.** Replace the mutation above by `x.detach().add_(1)`. Why is this not a safe snapshot? What changes with `x.detach().clone().add_(1)`?

**Solution.** Ask two questions independently: is there a gradient connection, and are the numeric bytes shared?

Detach removes gradient connectivity but shares storage with `x`; the in-place update still changes the forward-required data and version accounting can catch it. Clone allocates separate storage, so mutating the detached clone does not overwrite `x`. This illustrates three distinct relations: Python identity, gradient connectivity and storage aliasing. Consult [view/alias autograd rationale](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/variable.h#L518).

## 7. A view is not necessarily a kernel

**Question.** For contiguous `x:[B,H]`, compare `x.view(B,H//2,2)`, `x.t()`, and `x.t().contiguous()`. Which computations move tensor elements?

**Solution.** Use a concrete `[2, 4]` matrix. Its ordinary row-major strides are `(4, 1)`: move four elements to reach the next row, one to reach the next column. Transposing produces shape `[4, 2]` with strides `(1, 4)`. The numeric bytes have not moved; indexing interprets them differently. Copying that transpose into ordinary contiguous layout does move values.

With valid dimensions, the first view changes metadata and shares storage. Transpose changes strides and shares storage. For a nontrivial matrix, making that transposed tensor contiguous generally allocates and copies/reorders elements. Thus three Tensor-returning APIs can have zero, zero and nonzero data-processing work, respectively. If used in differentiable code, metadata-only operations can still create backward relationships. Empty/size-one dimensions can make contiguous behavior less intuitive, so state the shape when testing.

## 8. Why broadcasting is not just shape arithmetic

**Question.** Let `a:[B,H]` and `b:[H]`. Explain eager `a*b`, then explain why using a broadcasted view of `b` as an arbitrary in-place output is problematic.

**Solution.** For `B=2, H=3`, both output rows multiply by the same three entries of `b`. No repeated copy of `b` is necessary: the address for `b[j]` can ignore the row index.

TensorIterator computes a common iteration shape and represents the broadcasted dimension with zero stride for `b`, so all rows read the same weight values. It also determines dtype/output handling and checks overlap. Writing distinct results into a zero-stride expanded output would make multiple logical elements target the same memory: the result is not a well-defined independent elementwise write. [`TensorIteratorBase::build`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/TensorIterator.cpp#L1467) shows why iteration construction includes overlap checks before computation.

## 9. Derive RMSNorm backward, then find its implementation boundary

**Question.** For one real row of width `H`, define `r=(mean(x*x)+eps)^(-1/2)`, `y_i=x_i*r*w_i`, and incoming gradient `g_i`. Derive `dx` and `dw`. Why save `r`?

**Solution.** Let `L` be the scalar loss and `g_i = dL/dy_i`. Each `x_i` affects the loss in two ways: directly through `y_i = x_i*r*w_i`, and indirectly by changing `r`, which affects every output in the row.

1. Write `m = sum(x_j*x_j)/H + eps`, so `r = m^(-1/2)`.
2. Differentiate the reduction: `dm/dx_i = 2*x_i/H`.
3. Apply the chain rule: `dr/dx_i = (-1/2)*m^(-3/2)*(2*x_i/H) = -x_i*r^3/H`.
4. The direct loss contribution is `g_i*w_i*r`. The shared-scale contribution is `sum_j(g_j*x_j*w_j) * dr/dx_i`.
5. Define `a_i=g_i*w_i` and `c=mean(a*x)` to collect those terms:


```text
dx_i = r*a_i - x_i*r^3*c
dw_i = g_i*x_i*r                  # then sum over all rows sharing weight
```

For `dw_i`, changing `w_i` scales only `y_i` within one row, giving `g_i*x_i*r`. If many rows use that weight, their contributions add.

Saving `r` avoids recomputing the mean-square reduction. Weight gradients need reduction over rows, unlike input gradients' row-local reduction, which helps explain why backward is not simply “run forward in reverse with one kernel.” The [derivative declaration](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/tools/autograd/derivatives.yaml#L1301) can choose a differentiable backward implementation for higher-order gradients instead of the ordinary fused backward primitive.

**Boundary condition.** This derivation assumes real input and fixed epsilon/weight broadcasting as stated; it is not the complex derivative formula or an exact floating-point equivalence proof.

## 10. Two kernels can beat one

**Question.** Why would the RMSNorm/layer-norm weight-gradient implementation deliberately split into partial sums and a later reduction for very large row count `M` and small width `N`?

**Solution.** Think of each GPU block as an independent task. If a schedule assigns tasks only to a few columns, adding millions of rows makes those tasks longer without giving the GPU enough independent tasks to keep its processors busy.

Parallelizing only by columns supplies too few blocks to occupy the device when `N` is small. Partitioning rows introduces many independent blocks, producing temporary partial sums. A second reduction combines them. Extra traffic/launch cost can be outweighed by vastly improved parallelism. The source's [`ShouldUseHugeMGammaBetaBackwardKernel`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L992) checks large `M` and column-block count against device multiprocessor count. This is a cost-model example: kernel count alone is a poor optimization objective.

## 11. Find an AMD workaround without an AMD directory

**Question.** Search the shared normalization source for `USE_ROCM`. Why cap grid size and launch again for remaining rows?

**Solution.** `gridDim.x` is the number of blocks along the launch's x dimension; `blockDim.x` is the threads per block along that dimension. Their product can exceed a runtime limit even though every individual tensor value is valid.

The code documents a ROCm launch restriction involving `gridDim.x * blockDim.x` exceeding the 32-bit bound. The vectorized launcher caps the first grid and advances input/output pointers for subsequent chunks; the fallback launch bounds its grid and lets blocks stride over rows. The work is semantically the same, but a hardware/runtime constraint changes launch organization. Read [the launcher](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1090). Contrast this with a tinygrad chip-specific rewrite: the fix here is native host launch logic, not a PM over compiler UOps.

## 12. Eager timing versus completion timing

**Question.** A CPU wall-clock timer around `z=F.rms_norm(x,... )@W` on CUDA reports an implausibly short duration. Does that prove eager deferred optimization like tinygrad?

**Solution.** Imagine timing the act of placing two jobs in a queue. That measures submission, not how long the workers spend finishing them. GPU dispatch has the same distinction.

No. Python can dispatch the operations immediately while the device executes asynchronously. The timer may mainly measure submission. Use properly synchronized end-to-end timing or device events on the appropriate stream, warm up lazy initialization/library state, and separate one-time setup from steady-state work. This measures a different question from whether arithmetic kernels fuse. CUDA graph replay can reduce submission overhead without eliminating a single intermediate buffer.

## 13. Native and decomposed RMSNorm disagree numerically

**Question.** A hand-written FP16 implementation uses `x.square().mean(...)` without an explicit cast, and differs from `F.rms_norm`. Why is “both implement the same equation” insufficient?

**Solution.** Floating-point arithmetic rounds intermediate values. Squaring a large FP16 value in FP16 can overflow before the mean is computed; casting to FP32 before the square can avoid that particular overflow. Casting only after the square cannot recover the lost value. Likewise, a different reduction order can round differently even without overflow.

The [composite implementation](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/layer_norm.cpp#L265) upcasts low-precision input to opmath dtype. The [CUDA implementation](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1996) chooses an accumulation type and an epsilon default from that type. Explicitly specify the same epsilon and accumulation/cast placement when comparing. Reduction trees and fused arithmetic can still change rounding. Inspect dtype mismatch guards on weight too: they can switch the entire path.

## 14. Where should a new backend plug in?

**Question.** A backend implements a matrix multiply entry point. Why is that insufficient to support this whole residual/RMSNorm/GEMM program with gradients?

**Solution.** Walk the program in execution order. Before matrix multiplication, the backend must create device tensors, add the residual, and normalize rows. For training, it must then execute the derivative computations and accumulate gradients. A matrix-multiply entry point covers only one part of that route.

The program also needs allocation/storage/device support, addition, shape/stride operations, normalization or its composite prerequisites, appropriate dispatch registrations, and backward support for the operators reached. Composite implementations can reduce how many dedicated kernels a backend must write, but only if their constituent operators work. Mutation/view semantics, streams and dtype/layout behavior must match the contract. A compiler backend can instead lower a captured supported region, but graph breaks/fallback still require a plan. Compare tinygrad's device/runtime plus renderer/codegen integration: its shared UOp lowering can cover many tensor operations through a smaller low-level target surface, while specialized operations and hardware constraints still need implementation.
