# Regular PyTorch eager execution: dispatch a program, then execute its gradient program

Source snapshot: PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df` (main). All links below pin that commit. This is a source-reviewed architecture walkthrough, not a claim that this checkout was built or these GPU paths were profiled. Worked predictions are explicitly conditional. See [the exercise bank](eager-exercises.md).

Start with this small program. These are expected values for explanation, not recorded test results:

```python
x = torch.tensor([2.0, 3.0], requires_grad=True)
z = x * x                 # forward values: [4, 9]
loss = z.sum()            # forward value: 13
loss.backward()           # accumulates x.grad: [4, 6]
```

When Python reaches `x * x`, eager PyTorch chooses an implementation and asks it to compute multiplication. On GPU this usually queues work instead of waiting for completion. An **operator** is a named tensor operation; a **kernel** is concrete device code doing some work. One operator can require several kernels.

`backward()` is a later computation. Since the derivative of `x_i*x_i` is `2*x_i`, it needs the original values `[2, 3]` and a record of how `loss` depended on them. This **autograd graph** computes derivatives; its existence does not mean forward multiplication waited for `backward()`.

For shared compiler vocabulary, see the [first-principles guide](../first-principles.md). Here we start with eager calls, then follow residual addition → RMSNorm → matrix multiplication.

The useful difference from tinygrad is **where the system commits to execution**. Ordinary PyTorch eager dispatches each operator as Python reaches it. A backend implementation can immediately execute CPU work, enqueue GPU work, or call other operators. Tinygrad normally retains a tensor computation as UOps until realization and schedules kernels from that graph. PyTorch eager's autograd graph records how to compute derivatives of already-dispatched forward work; it does not ordinarily postpone that forward work for graph-wide fusion.

That difference explains much of the apparent machinery. PyTorch must preserve the behavior of an enormous operator surface across devices, tensor subclasses, views, mutation, autocast, differentiation and extension libraries. An operator schema plus a layered dispatcher is the stable meeting point. Tinygrad puts more of the equivalent reasoning into transformations of a shared compiler IR. Neither distinction means that PyTorch lacks graph compilers or that tinygrad lacks runtime dispatch: `torch.compile` changes the execution strategy for captured regions, and tinygrad also selects devices, kernels and libraries.

## The forward path and why each boundary exists

For `x * x`, the runtime must validate arguments, determine output properties, decide whether to record derivatives, and select code for the device holding the values. Separating these jobs avoids reimplementing all of them inside every arithmetic kernel.

**ATen** is PyTorch's tensor operator library. A **schema** describes an operator's arguments, results, and storage-sharing/mutation behavior. A **registration** associates an operator and dispatch category with an implementation. The **dispatcher** chooses the next behavior for this call. A **wrapper** performs bookkeeping or changes policy before calling onward. A **composite implementation** computes its result by calling other operators.

```text
Python function / Tensor method / nn.Module.forward
  -> generated Python argument parsing and Tensor unwrapping
  -> ATen operator API and schema
  -> c10 dispatcher: tensor keys + thread-local modes + operator table
  -> optional wrappers: subclass, transforms, autograd, autocast, ...
  -> backend implementation OR composite implementation calling more operators
  -> TensorIterator loop / specialized kernel / BLAS or other library
  -> CPU execution or device-stream enqueue
```

The arrows are a representative route, not a fixed list of wrappers every call traverses. Registration, active modes and fallthrough determine the actual route.

| Module / source entry | What it owns | Why it exists / sharp edge |
|---|---|---|
| [`torch/_tensor.py:102`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_tensor.py#L102) | Python `Tensor` conveniences and protocols above `_C.TensorBase` | Python usability without implementing numeric loops in Python. Reading this file alone misses generated methods and native execution. |
| [`torch/nn/functional.py:2998`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/nn/functional.py#L2998) | Functional API validation/protocol handling and native calls | `F.rms_norm` handles `__torch_function__` before calling `torch.rms_norm`. A tensor subclass can change the route before ordinary backend execution. |
| [`tools/autograd/gen_python_functions.py:408`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/tools/autograd/gen_python_functions.py#L408) | Generated Python bindings | Shares schemas across large families of overloads rather than hand-maintaining every binding. A missing generated `.cpp` in a source checkout is not a missing implementation. |
| [`torch/csrc/autograd/python_variable.cpp:408`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/python_variable.cpp#L408) | Python object wrapping of native tensors | Python object lifetime and C++ tensor lifetime must cooperate; wrapper identity is distinct from storage aliasing. |
| [`aten/src/ATen/core/TensorBase.h:93`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/TensorBase.h#L93), [`c10/core/TensorImpl.h:510`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/c10/core/TensorImpl.h#L510) | Tensor handle and implementation metadata | Sizes, strides, dtype, device, storage offset and dispatch identity must survive calls independently of Python. A view can have a different TensorImpl while sharing storage. |
| [`native_functions.yaml:3297`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/native_functions.yaml#L3297) | Operator schemas and dispatch declarations | Defines the semantic/operator boundary, not a promise about kernel count. Alias annotations and out/in-place variants matter for transformation correctness. |
| [`torchgen/model.py:507`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torchgen/model.py#L507), [`torchgen/gen.py:2336`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torchgen/gen.py#L2336) | Parsed schema model and generated registrations/wrappers | Keeps schemas, C++ interfaces and backend registrations consistent. Generated wrappers can allocate outputs or perform structured checks before the implementation body you found. |
| [`Dispatcher.h:71`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/dispatch/Dispatcher.h#L71) | Operator registry, boxed/unboxed calling, dispatch and redispatch | Runtime extensibility for backends and transforms. A dispatch key is a layer of behavior, not merely a device enum. |
| [`DispatchKeyExtractor.h:24`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/dispatch/DispatchKeyExtractor.h#L24), [`DispatchKeySet.h:430`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/c10/core/DispatchKeySet.h#L430) | Effective key set and priority | Tensor state and scoped thread-local modes must compose. “CUDA wins because the tensor is CUDA” overlooks higher-level wrappers. |
| [`TensorIterator.cpp:1467`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/TensorIterator.cpp#L1467) | Reusable iteration planning | Implements broadcasting, overlap checks, dtype rules, output setup and stride iteration across many operators. This is local loop planning, not a whole-program fusion IR. |
| [`native/cpu/BinaryOpsKernel.cpp:126`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cpu/BinaryOpsKernel.cpp#L126) | A concrete multiply loop using the iterator | CPU vectorization and parallel loops are shared infrastructure; an eager expression can be fast inside each operator while still paying materialization between operators. |
| [`native/LinearAlgebra.cpp:1601`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/LinearAlgebra.cpp#L1601), [`native/cuda/Blas.cpp`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/Blas.cpp) | Matrix-operation preparation and library routing | GEMM needs layout/leading-dimension handling and specialized algorithms, not TensorIterator. One BLAS call can itself perform multiple device launches. |
| [`c10/cuda/CUDACachingAllocator.h:142`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/c10/cuda/CUDACachingAllocator.h#L142) | Allocation lifetime and stream-use accounting | Reuse memory without globally synchronizing after each operation. Storage lifetime and stream dependencies are part of correctness, not graph-fusion policy. |

## Dispatcher: unpack the “magic” instead of memorizing key names

For `x*x` on a GPU with gradient recording enabled, choosing only the GPU arithmetic would omit the record needed by backward. A **dispatch key** names a category of behavior, such as a backend or gradient bookkeeping. A **key set** contains the categories relevant to the call, and priority determines which runs next.

Some categories come from tensors; scoped modes come from the host thread. **TLS** means thread-local state. A wrapper can temporarily exclude its own category while calling onward. In the formula, `|` means set union, `-` removes keys, and `&` retains only keys in both sets.

For an ordinary tensor-input operator, conceptual effective keys are:

```text
effective = ((keys_from_arguments | TLS.included) - TLS.excluded) & operator_key_mask
```

This is the expression in [`computeDispatchKeySet`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/dispatch/DispatchKeyExtractor.h#L24). Operator masks remove fallthrough entries; backend/functionality representation and dispatch-table indexing make the real implementation more nuanced than a flat “device switch.” Priority chooses the next registered behavior. A wrapper then **redispatches below itself** so the next layer can run. Redispatch receives an explicit key set; [`Dispatcher.h:194`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/core/dispatch/Dispatcher.h#L194) warns that the supplied set is used as-is rather than applying TLS masking again.

For example, a floating CUDA tensor requiring gradients can reach an autograd wrapper before the CUDA implementation. The wrapper determines whether a backward node is needed, saves the required inputs/results, calls onward with autograd excluded and attaches history. `requires_grad` is not simply an extra dispatch key inserted only when true: tensors can carry autograd-related dispatch identity even when no graph is recorded. `no_grad` affects the graph-recording decision; it is not a universal instruction to remove every autograd-related dispatch layer.

The underlying reason for redispatch is recursion control. If an autocast or autograd wrapper called the same operator with unchanged active keys, it could select itself forever. It also gives composition a defined order. Tinygrad PM ordering solves a different problem: it determines which graph transformations fire. A PyTorch dispatch wrapper usually implements the current call's semantics rather than searching the surrounding computation for a rewrite opportunity.

Translate the source registration names into three questions: does forward call other differentiable operators, does it supply its own derivative, or does it only predict output metadata?

Three distinctions prevent common misreadings:

- **CompositeImplicitAutograd:** an implementation expressed in other operators can inherit differentiation through those operators. This is not synonymous with slow Python or with one kernel. The RMSNorm public entry is a C++ composite implementation that can call a fused backend op.
- **CompositeExplicitAutograd:** a composite forward is paired with explicitly managed differentiation; do not assume “composite” always means tracing backward through every internal call.
- **Meta/Fake behavior:** metadata-only execution helps shape inference and compilation. It does not show which real hardware kernel would launch. FakeTensor also has its own higher-level machinery; it is not adequately described as changing `device='cuda'` to `device='meta'`.

## Autograd is another execution system, with different nodes

For `loss = (x*x).sum()`, backward starts with a derivative of 1 for scalar `loss`. Sum passes 1 to each input element; multiplication produces `2*x`. An **incoming gradient** tells a node how the final loss changes with its output. The node applies a derivative formula to compute contributions for its inputs. Contributions from multiple consumers must be added.

This requires formulas, saved forward values, and an engine that runs nodes when their incoming gradients are ready. The table locates those responsibilities. **Higher-order gradients** differentiate the derivative computation again, which requires that computation to support differentiation too.

| Module | Responsibility and reason |
|---|---|
| [`tools/autograd/derivatives.yaml:1301`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/tools/autograd/derivatives.yaml#L1301) | Declares derivative formulas. Forward operator contracts do not determine the most efficient or higher-order-correct backward implementation automatically. |
| [`tools/autograd/gen_variable_type.py:615`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/tools/autograd/gen_variable_type.py#L615) | Generates wrappers that decide whether gradients are needed and establish history. Repetition is generated rather than maintained for every ATen op. |
| [`torch/csrc/autograd/function.h`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/function.h), [`graph_task.h:18`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/graph_task.h#L18) | Nodes, gradient edges and per-backward task state. These nodes describe backward dependencies, not a retained UOp forward program awaiting realization. |
| [`engine.cpp:1168`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/engine.cpp#L1168), [`engine.cpp:1428`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/engine.cpp#L1428) | Evaluates ready backward functions and manages dependencies/task completion. Gradient contributions from multiple consumers must be accumulated before a predecessor is ready. |
| [`saved_variable.cpp:15`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/saved_variable.cpp#L15), [`saved_variable.cpp:128`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/saved_variable.cpp#L128) | Stores backward-required values/metadata and checks versions when unpacking. Saving a tensor is not automatically a deep copy immune to later mutation. |
| [`TensorImpl.h:328`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/c10/core/TensorImpl.h#L328), [`gen_inplace_or_view_type.py:534`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/tools/autograd/gen_inplace_or_view_type.py#L534) | Version counters and generated in-place/view wrappers. Silent reuse of mutated forward data would produce wrong gradients. |
| [`variable.h:518`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/autograd/variable.h#L518) | Differentiable-view history, base/view relationships and mutation handling. Sharing storage requires more than copying a `grad_fn` pointer. |

Here is why saving values requires more than keeping a Python reference:

```python
x = torch.tensor([2.0, 3.0], requires_grad=True)
v = x.view(2)              # different Tensor, same numeric storage
loss = x.square().sum()    # backward needs the original x
with torch.no_grad():
    v.add_(1)              # changes both v and x to [3, 4]
loss.backward()            # expected error: saved data was modified
```

A **view** has its own shape/stride metadata but shares existing storage. The trailing `_` marks an in-place update. `no_grad()` suppresses gradient recording for that update; it does not copy the old data. A **version counter** records mutations so backward can detect invalid saved values. Otherwise this example could silently return `[6, 8]` instead of `[4, 6]`.

Concrete case: `x.requires_grad_(); y = x.square().sum()`. Backward needs the original `x` to form `2*x`. Modifying `x` under `no_grad` after forward still changes its version. Backward generally detects the mismatch when unpacking the saved value. `no_grad` prevents recording the modification as new gradient history; it does not promise that overwriting backward-required storage is safe. Leaf-mutation checks can reject other cases earlier.

A view adds a second hazard: `v = x.view(...)` can alias `x`, so changing `v` changes the values seen through `x`. Autograd's view metadata and shared versioning account for this. `detach()` removes the gradient relationship but ordinarily still shares storage: it is not a protective copy. Custom operators must declare mutation/alias semantics and implement autograd/transform support correctly; being callable through the dispatcher alone does not establish those properties.

The RMSNorm derivative entry is particularly instructive. For the fused primitive, the formula chooses a differentiable backward path when grad mode is enabled or the auxiliary reciprocal-RMS output has a gradient; otherwise it can use `_fused_rms_norm_backward`. Higher-order gradients therefore need not use the same kernels as ordinary first-order training. A backward node is also not a single device kernel.

## Worked trace: residual + RMSNorm + matrix multiplication

RMSNorm rescales each row by its root-mean-square magnitude. For width `H`, compute `r = 1/sqrt(sum(u_i*u_i)/H + eps)`, then `y_i = u_i*r*weight_i`. Computing `r` combines all elements of a row: this is a **reduction**. The residual add produces `u`; matrix multiplication consumes the normalized `y`.

`B` is the row count, `H` is row width, and `K` is the output width after matrix multiplication. **FP32** means 32-bit floating point. **Contiguous** means the tensor follows the expected dense memory layout. **Inference** here means considering forward work without gradient recording. Assume real FP32 contiguous tensors, no subclasses/autocast, inference unless stated:

```python
# x, residual: [B, H]; weight: [H]; W: [H, K]
u = x + residual
y = torch.nn.functional.rms_norm(u, (H,), weight, eps=1e-5)
out = y @ W
```

### Step 1: residual addition commits its output

Eager reaches `x + residual` and dispatches addition. CPU executes a loop; GPU enqueues an addition implementation on the current stream. `u` is a real output tensor with storage, even if GPU work has not completed when Python receives it. The next operator depends on `u` through stream ordering. Ordinary eager does not inspect the following RMSNorm call and retroactively fuse this producer into its kernel.

### Step 2: follow the public and private RMSNorm operators separately

[`F.rms_norm`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/nn/functional.py#L2998) calls `torch.rms_norm`. Its schema registers [`rms_norm_symint`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/layer_norm.cpp#L325) as `CompositeImplicitAutograd`. This routine checks shapes and chooses a path:

| Condition at this snapshot | Route / implication |
|---|---|
| Channels-last suggested memory format | Composite fallback; a tensor can be contiguous in a channels-last format yet miss this fused path. |
| Complex input | Composite fallback; do not assume the real-valued CUDA fused formula applies to complex inputs. |
| Defined weight with different dtype from input | Warn once, then composite fallback. Changing only weight dtype can change execution structure. |
| MPS | Additional inference/weight eligibility check and fallback; not equivalent to CUDA selection. |
| Other eligible input | Calls `_fused_rms_norm`; its dispatch registrations choose CUDA/MPS/XPU implementations or a composite fallback. |

“Opmath upcasting” means using a wider arithmetic type for low-precision inputs, for example FP32 arithmetic on FP16 values. This limits intermediate rounding error.

There is **no dedicated CPU registration** for `_fused_rms_norm` in this schema snapshot: ordinary CPU uses [`rms_norm_composite`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/layer_norm.cpp#L265). That routine performs opmath upcasting, square/power, mean over normalized dimensions, epsilon addition, reciprocal square root, multiplication by input, optional multiplication by weight, layout handling and a cast back to the input dtype. Each internal ATen operation can execute separately. For FP16/BF16, explicit Python code that omits the upcast is not the same numerical program.

The CUDA registration points to [`_fused_rms_norm_cuda`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1996). It validates normalized dimensions, obtains contiguous input/weight as necessary, allocates `Y` and the auxiliary `rstd`, and calls `RmsNormKernelImpl`. A noncontiguous input can therefore add a materialization before the arithmetic kernels. The auxiliary result is useful for backward even though the public function returns only `Y`.

### Step 3: a “fused” native RMSNorm can launch one or two arithmetic kernels

A workgroup can compute a row's reduction, share its scale locally, and write normalized output in one kernel. The vectorized implementation also loads groups of adjacent values. That needs a suitably divisible width and **aligned** addresses: addresses that are multiples of the required byte boundary. The fallback separates statistics from output when the combined implementation cannot handle the input.

[`RmsNormKernelImpl:1234`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1234) reuses layer-normalization infrastructure with the template parameter `rms_norm=true`; subtracting a mean is omitted. [`LayerNormKernelImplInternal:1151`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1151) checks dtype, row width, vector-width divisibility and pointer alignment.

- Eligible float/half/bfloat16, aligned rows and sufficiently small divisible `H`: vectorized path computes row statistics and normalized output in one arithmetic launch for ordinary sizes.
- Ineligible vectorization, for example an odd `H` not divisible by the vector width: a row-moments kernel produces `rstd`, then an output kernel reads input and `rstd` and applies the weight.
- Empty row count: the enclosing function skips arithmetic launches.
- Layout copies and special huge-grid ROCm handling can add launches beyond these simple cases.

For example, compare contiguous FP32 `[32, 4096]` with `[32, 4097]`, with suitably aligned weight and allocations. The first is a fast-path candidate; the second fails vector-width divisibility. **The same public operator and even the same private “fused” operator can have different kernel boundaries.** This is a stronger explanation than counting profiler `aten::` entries.

The implementation visibly documents why one gate exists: the element count within each row (normalized width `N`) uses a floating representation, so the normalized width is bounded using the precision of `float`. Alignment and divisibility gates protect vector memory accesses. Those are local native-kernel eligibility tests, whereas a tinygrad lowering may express comparable constraints through scheduling, vectorization and rewrite legality across UOps.

### Step 4: matrix multiplication is its own backend decision

**GEMM** is the conventional name for general matrix multiplication. **BLAS** libraries provide optimized linear algebra routines. An **epilogue** performs extra work, such as adding bias, while producing the matrix-multiply result.

`y @ W` with two matrices routes to matrix multiplication; the ATen linear-algebra implementation prepares layouts and delegates to an appropriate backend kernel/library. The already-computed `y` crosses this boundary in memory. An ordinary eager matmul call does not pull the preceding RMSNorm reduction into its library GEMM. Shapes, strides, dtype, architecture and build/library configuration influence the chosen algorithm and launch count.

Calling a purpose-built combined operator can change the boundary. An `addmm`/linear implementation can use a library bias epilogue where eligible. That is explicitly implemented fusion within an operator/library API, not evidence that arbitrary neighboring eager calls are fused automatically. Likewise CUDA graph capture/replay can reduce launch overhead while retaining multiple kernels and intermediates; graph capture alone is not arithmetic kernel fusion.

For the example, a sensible source prediction is **one residual-add implementation, one or two RMSNorm arithmetic kernels on eligible CUDA paths, then the GEMM implementation**, plus any copies/auxiliary work. It is deliberately not a universal exact kernel total: BLAS internals, empty shapes, layouts and build choices matter. Record device kernel events to establish an actual total.

### Explicit decomposed RMSNorm is a different eager dispatch sequence

```python
u = x + residual
q = u.float()                         # identity when already FP32
s = q.square().mean(dim=-1, keepdim=True)
r = torch.rsqrt(s + 1e-5)
y = (q * r * weight).to(u.dtype)
out = y @ W
```

For the stated FP32 case this expresses the same real-valued formula as native RMSNorm, subject to reduction/rounding differences. It exposes square, reduction, epsilon addition, rsqrt and two multiplies as separate eager operators. This is neither six guaranteed GPU launches nor automatic fusion: some operations may be no-ops, some may launch multiple kernels, and the reduction chooses its own implementation. In `torch.compile`, the captured pointwise/reduction program becomes material for compiler scheduling and fusion. In tinygrad, retaining such expressions for graph transformations is the ordinary starting model.

## AMD/ROCm: where eager hardware specificity lives

**ROCm** is AMD's GPU software platform; **HIP** is its programming/runtime interface used here. A GPU launch specifies a grid of blocks, each containing threads. `grid.x * block.x` counts threads along that launch dimension. These details matter even when the equation is unchanged.

Do not search only for `native/hip` and conclude there are no AMD kernels. Much of PyTorch's CUDA-named source is shared or translated for ROCm, and `USE_ROCM` branches remain in those sources. [`aten/src/ATen/cuda/CUDABlas.cpp:17`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/cuda/CUDABlas.cpp#L17) includes ROCm-specific BLAS support; [`native/cuda/Blas.cpp:123`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/Blas.cpp#L123) contains architecture and hipBLASLt eligibility logic. `torch.cuda` API naming also persists on ROCm builds.

A concrete RMSNorm-adjacent workaround appears in [`launch_vectorized_layer_norm_kernel:1090`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L1090). Under `USE_ROCM`, the launch is capped to keep `grid.x * block.x` within a 32-bit bound, and remaining rows are processed in additional launches. The source comments cite invalid launch configurations as the reason. The fallback path also bounds its launch and strides over remaining rows. This is a backend launch workaround with an explicit source explanation, not an inferred algebraic simplification.

Backward contains another useful exception to “fewer kernels means faster”: [`ShouldUseHugeMGammaBetaBackwardKernel:992`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/aten/src/ATen/native/cuda/layer_norm_kernel.cu#L992) identifies very many rows and too little column parallelism. The implementation computes partial weight/bias gradients then reduces them. Its comment explains why two kernels can outperform a single insufficiently parallel kernel. This is source rationale, not a benchmark reproduced here.

Compared with tinygrad's AMD matcher guide, eager hardware-specific decisions are dispersed among C++ eligibility branches, templates, launch configuration, translated sources, backend registration and vendor libraries. `torch.compile` adds another location: compiler lowering and generated kernel/template selection. A complete AMD account needs both maps.

## Eager does not mean synchronous

The **host** is the CPU running Python. A device **stream** is an ordered queue of GPU work. Queuing B after A on one stream orders their execution without making Python wait for A to finish. An **event** marks progress; synchronization waits for relevant completion.

On CPU an ordinary numeric call usually completes its CPU computation before returning. On GPU the host typically enqueues work and returns before the device finishes. Same-stream dependencies order the residual add, normalization and GEMM without a CPU wait after each call. Reading a GPU value on the host, explicit synchronization, or certain runtime paths can introduce waits.

Thus three independent questions must be kept separate:

1. **When is the computation represented/optimized?** Eager per-call dispatch versus a captured/retained graph.
2. **When does the host submit work?** Individual launches versus graph replay or another batching mechanism.
3. **When is the result complete and observable?** Stream/event ordering and synchronization.

A host timer around a CUDA expression can measure submission rather than completion. CUDA graphs can improve submission without fusing kernels. A fused kernel can run asynchronously. None of these facts changes eager's default absence of cross-call graph optimization.

## Sharp edges to carry into source reading

- Count Python calls, ATen dispatcher calls, backend implementations and GPU launches separately. They are four different levels.
- Inspect registration before reading a plausibly named native function: the active backend may route elsewhere or use a composite implementation.
- A source checkout contains generators/templates; generated binding/registration files often live in build outputs. Search the schema, generator and template rather than concluding an operator is missing.
- `contiguous()` can be free or can copy. `view` is normally metadata/aliasing; `reshape` can copy when the requested view is impossible. Storage movement is often more important than operator count.
- Overlap, broadcasting and dtype semantics are not implementation trivia. A broadcasted zero-stride output cannot generally be mutated as though every logical element were independent.
- `no_grad`, `detach` and inference mode have different metadata/lifetime implications. Neither `no_grad` nor `detach` makes shared storage immutable.
- Do not use the installed wheel to prove exact behavior of this newer source snapshot. Record `torch.__version__`, `torch.version.git_version`, backend availability and device when running an exercise.

The practical reading loop is: **schema → generated wrapper contract → dispatch registration → implementation → actual launch/library call → derivative rule**. For a discrepancy, inspect dtype/layout/grad/mode guards at each boundary before assuming the compiler is involved.
