# torch.compile: recovering a compiler program from eager Python

Source snapshot: PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`.
This is a source-derived map, not a claim that this checkout was built. Examples
below are schematic unless linked to executed probes. The installed PyTorch
2.11 runtime is a different revision. Continue with [Inductor and kernel
fusion](inductor-and-fusion.md) and [worked exercises](compile-exercises.md).

## Start with one ordinary array function

```python
def scaled_sine(x, scale=2.0):
    return x.sin() * scale
```

In ordinary eager execution, Python calls the sine operation, gets a tensor,
then calls multiplication. A compiler would like to see both operations before
choosing how to execute them. It might calculate `sin(x[i]) * scale` for each
element and avoid writing a whole intermediate sine array to memory.

**Capture** means recovering a record of those operations from the Python
execution. The record is a **graph**: each operation is a node and each value
passed to another operation is a connecting edge. PyTorch calls its graph
container **FX**. A **backend** is the compiler or executor asked to turn that
record into a callable implementation. Inductor is the usual compiler backend.
The name of the container does not say whether the graph is fast yet.

There is a catch: the first call only shows one situation. Suppose the compiler
assumes the input is a contiguous float32 array and `scale` is `2.0`. Code built
under those assumptions is a **specialization**. A **guard** is a check that the
assumptions still hold on a later call. A failed guard can cause compilation of
another specialization, called **recompilation**. Exactly which properties get
specialized depends on the configuration and program.

Now put unsupported Python work between the sine and multiplication. With the
usual policy, capture may stop, run that Python work, and start another graph.
That interruption is a **graph break**. It differs from a guard failure: a break
splits the program being captured; a failed guard rejects reuse of an existing
version. The rest of this guide explains why each layer needs to exist even
for programs built from familiar array operations. For general terminology,
see [compiler first principles](../first-principles.md).

The central difference from tinygrad is where the compiler starts. Tinygrad's
Tensor construction already produces a lazy UOp program. PyTorch's ordinary
Tensor operations execute eagerly, and a large Python ecosystem depends on that
behavior. `torch.compile` must discover useful regions of an existing eager
program while preserving Python state, aliasing, autograd, dispatch, and shape
semantics. Much of the apparent complexity pays for that compatibility boundary.
This is an architectural interpretation of the code, not a claim about every
maintainer's historical intent.

## The boundaries to keep separate

```text
Python callable + real inputs
  → Dynamo: guarded Python specialization and FX graph regions
  → AOTAutograd: functional ATen graph, optionally joint forward/backward
  → partition: forward outputs + saved values / backward inputs + gradients
  → Inductor: loop/buffer IR, scheduling, generated kernels and library calls
  → runtime callable + wrappers preserving the original observable behavior
```

A **kernel** is a unit of generated device computation. **GEMM** means matrix
multiplication; an external GEMM call invokes an existing implementation.
A Dynamo graph is not a kernel. A forward/backward partition is not a GPU
partition. A graph break is not an ordinary kernel boundary. A single captured
FX graph can have many generated kernels and external GEMM calls. Conversely,
one eager operation can call a composite implementation or several kernels.

## Entry, Python capture, and resumption: module map

Python itself executes small instructions called **bytecode**, such as loading
an argument or calling a method. Dynamo follows those instructions using
representations of values rather than treating the whole function as opaque.
It can record tensor work while keeping track of Python lists, attributes,
and branches. When the map below says **abstract value**, it means this
compiler-side description of a value, not the tensor's numerical contents.

A **frame** holds one Python function invocation's local variables and current
execution position. **Resumption** means restoring enough of that state to
continue Python after running a captured region. These definitions explain why
capture needs more than a list of tensor operations.

All source links below are pinned to the snapshot.

### [`torch/__init__.py:compile`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/__init__.py#L3076)

**Why it exists.** Public wrapper selecting capture/backend policies. Compilation is generally triggered on invocation, when input properties are known.

**Example and boundary.** Decorating `rmsnorm` does not itself establish its eventual kernel count. This revision also has `recompile_limit`, `isolate_recompiles`, and `dynamic_shapes`; older installed wheels may not expose them.

### [`_dynamo/eval_frame.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/eval_frame.py) and [`csrc/dynamo/eval_frame.c`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/dynamo/eval_frame.c)

**Why it exists.** Install the frame-evaluation machinery and wrap callables/modules. This lets existing Python code opt into capture without a new Tensor API.

**Example and boundary.** Calling the same function can reuse a guarded specialization. The code-object cache is not simply a dictionary from Tensor shapes to kernels.

### [`_dynamo/convert_frame.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/convert_frame.py)

**Why it exists.** Coordinate tracing a frame, compiling its graph, transformed bytecode, guards, and failure policy.

**Example and boundary.** A guard miss can enter compilation again; unsupported tracing and backend compilation failures are different failure classes.

### [`_dynamo/symbolic_convert.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/symbolic_convert.py)

**Why it exists.** Interpret Python bytecode using abstract values, emitting tensor graph operations while following or specializing Python behavior.

**Example and boundary.** `if x.shape[0] > 8` can select a branch and require a shape guard. `if x.sum() > 0` depends on tensor data and cannot generally be resolved by shape specialization.

### [`_dynamo/variables/base.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/variables/base.py), [`builder.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/variables/builder.py), [`tensor.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/variables/tensor.py)

**Why it exists.** `VariableTracker` represents Python values, their provenance, supported behavior, and mutation properties; `TensorVariable` carries a graph proxy. These are interpreter values, not an arithmetic optimization IR.

**Example and boundary.** A Python list of tensors must retain list semantics while each tensor contributes FX nodes. Treating all values as tensors loses identity, specialization, and Python method behavior.

### [`_dynamo/source.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/source.py)

**Why it exists.** Describe how to retrieve a value from runtime locals, globals, attributes, or containers. Needed to build guards and reconstruct execution.

**Example and boundary.** The source of `self.weight` differs from an anonymous intermediate: the former can be retrieved/guarded at the next call.

### [`_dynamo/output_graph.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/output_graph.py)

**Why it exists.** Own graph construction and the boundary between tensor graph outputs and the Python stack/locals that must survive.

**Example and boundary.** A graph prefix may return an intermediate needed by resumed Python, even when that value is not a user-visible function result.

### [`_dynamo/guards.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/guards.py) and [`csrc/dynamo/guards.cpp`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/dynamo/guards.cpp)

**Why it exists.** Check the assumptions that made a specialization valid. A guard is a correctness condition, not just an annoying cache key.

**Example and boundary.** Shape, stride, dtype, device, Python constants, object relationships, and ambient state can matter. `dynamic=True` does not remove all of these checks.

### [`_dynamo/side_effects.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/side_effects.py)

**Why it exists.** Record supported Python mutations and generate replay code preserving their observable behavior.

**Example and boundary.** Appending a tensor to a list cannot disappear because only the returned tensor is in FX. Unsupported effects can force a break/error; supported effects do not all require graph breaks.

### [`_dynamo/resume_execution.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/resume_execution.py) and [`bytecode_transformation.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/bytecode_transformation.py)

**Why it exists.** Build continuation bytecode so a graph prefix can run, unsupported Python can execute, and tracing/execution can resume.

**Example and boundary.** Splitting before logging a tensor is more work than cutting an FX edge: stack state, locals, and active context managers must remain meaningful.

`fullgraph=True` requires capture without graph breaks; it does **not** mean a
single GPU kernel, static shapes, or no guards. A notable snapshot detail:
its public docstring says fullgraph enables unbacked semantics, including scalar
output and dynamic-output-shape capture defaults. Therefore the old blanket
claim “`.item()` always graph-breaks” is wrong here. Capturing a scalar and using
that scalar to choose arbitrary Python control flow are still different tasks.

## Fake execution, symbolic shapes, and FX

To plan `x @ w`, the compiler needs the output shape and dtype. It usually does
not need to multiply the actual array values. A **FakeTensor** lets operations
work with descriptions such as “float32 on this device, shape `(B,H)`, these
strides” while avoiding the normal data computation. **Metadata** means those
descriptive properties. A **stride** says how far to move through storage when
one index increases; equal shapes can have different strides.

If the compiler writes the batch size as a variable `B` instead of the constant
`8`, it is using a **symbolic shape**. It must still prove relationships: the
inner dimensions of a matrix multiplication must agree, for example.
`ShapeEnv` is where many of these expressions and assumptions are tracked.
A fake tensor answers “what sort of result?”, a symbolic expression answers
“how does that property depend on sizes?”, and FX records “which operation
produces it?”. These are related but different jobs.

### [`_subclasses/fake_tensor.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_subclasses/fake_tensor.py)

**Why it exists.** `FakeTensorMode` propagates metadata and device semantics without performing the normal real-data computation. Tensor storage identity and alias relationships also matter during tracing.

**Example and boundary.** `x @ w` can infer output shape/dtype without reading GPU values. An operator lacking appropriate fake/meta behavior cannot be made traceable merely by writing a fast CUDA implementation.

### [`fx/experimental/symbolic_shapes.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/experimental/symbolic_shapes.py)

**Why it exists.** `ShapeEnv` manages symbolic expressions, assumptions, ranges, guards, and deferred assertions. Shapes influence correctness of indexing and specialization.

**Example and boundary.** Broadcasting `(B, H)` with `(H,)` needs dimension relationships. A reshape can need divisibility constraints. `B` can be symbolic while `H` remains specialized.

### [`fx/experimental/sym_node.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/experimental/sym_node.py)

**Why it exists.** Back symbolic integer/boolean operations with expressions and a shape environment.

**Example and boundary.** `x.shape[0] * x.shape[1]` need not become an ordinary constant, but converting a symbolic condition into a Python boolean can introduce a guard or fail.

### [`fx/graph.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/graph.py), [`node.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/node.py), [`graph_module.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/graph_module.py)

**Why it exists.** Provide a graph representation with Python-callable code generation and metadata. Different stages can use FX with different operator vocabularies.

**Example and boundary.** A Dynamo FX graph and a decomposed ATen FX graph are not necessarily the same program representation merely because both are `GraphModule`s.

### [`fx/experimental/proxy_tensor.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/experimental/proxy_tensor.py)

**Why it exists.** `make_fx` and dispatch-level proxy tracing capture tensor operations, including decompositions, under tensor modes.

**Example and boundary.** AOT tracing can record the ATen operations executed by autograd without independently interpreting all user Python again. Do not equate this with Dynamo's bytecode interpreter.

A **backed** shape symbol has a value from the example inputs that can guide
specialization. An **unbacked** symbol can represent a data-dependent quantity,
such as a count determined by tensor contents, without an ordinary input-shape
hint. Neither grants permission to guess data-dependent control flow. Runtime
assertions, explicit structured control flow, specialization, and unsupported
cases are distinct ways a compiler handles the constraints.

## AOTAutograd: why so much machinery sits before the kernel compiler

Training adds another program to compile: the calculation of gradients.
**Autograd** constructs that derivative computation. **AOTAutograd** records
forward work and the corresponding derivative work early enough that compiler
passes can inspect them together. Their combined record is the **joint graph**.
Splitting it into forward and backward graphs is **partitioning**. A value
needed in backward can be saved during forward or calculated again later;
that choice affects memory traffic as well as arithmetic.

Another difficulty is `x.add_(r)`: Python expects it to change `x`. Many compiler
transformations are easier when an operation produces a new value rather than
silently changing an old one. **Functionalization** expresses such changes as
explicit value flow. Conceptually, `x.add_(r)` becomes `new_x = x + r`, with a
record that the caller must still observe the update to `x`. A **runtime
wrapper** is surrounding code that repairs that external contract when calling
the compiled function. It may copy back updates or recreate views. A **view**
shares storage with another tensor; that shared-storage relationship is called
**aliasing**. Equal numbers alone are not enough to preserve it.

The normalized graphs commonly use **ATen**, PyTorch's tensor-operator
vocabulary. **Decomposition** replaces an operator with a sequence of simpler
operators, for example exposing arithmetic and reductions inside a compound
operation. Simpler compiler input can help, but losing a useful compound
operation can also hide an efficient implementation.

AOT here means differentiation is traced before executing the corresponding
compiled computation. It does not imply that `torch.compile` has become an
offline deployable binary, nor that every backward has already been machine-code
compiled when the first forward returns. Lazy backward compilation exists.

### [`_functorch/aot_autograd.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/aot_autograd.py)

**Why it exists.** Flatten function/module inputs, configure tracing and compiler callbacks, expose `aot_function` / `aot_module_simplified`.

**Example and boundary.** Module parameters and buffers become explicit computational inputs; user-level module calls are not the final kernel ABI. These private interfaces are experimental.

### [`_aot_autograd/graph_compile.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/graph_compile.py)

**Why it exists.** Separate `aot_stage1_graph_capture` from stage-two compilation/export, dispatch training versus inference paths, and invoke partitioners/compiler callbacks.

**Example and boundary.** Inference needs functionalization but no generated gradient graph when no autograd is needed. This snapshot uses these filenames; older guides referring to `jit_compile_runtime_wrappers.py` describe a different organization.

### [`_aot_autograd/collect_metadata_analysis.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/collect_metadata_analysis.py) and [`schemas.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/schemas.py)

**Why it exists.** Record input mutations, output aliases, subclass information, and calling-convention metadata. The graph alone cannot explain how to reconstruct all eager semantics.

**Example and boundary.** Returning a view of a mutated input differs from returning an independent equal-valued tensor. `ViewAndMutationMeta` retains that distinction.

### [`_aot_autograd/graph_capture_wrappers.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/graph_capture_wrappers.py)

**Why it exists.** `create_functionalized_fn` and `create_joint` normalize mutation and arrange forward plus gradients for tracing. Functionalization makes dependencies explicit.

**Example and boundary.** `x.add_(r)` can be represented by a new value, with the externally visible mutation restored through the surrounding contract. It is not legal simply to delete the mutation.

### [`_aot_autograd/graph_capture.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/graph_capture.py)

**Why it exists.** Dispatch-level capture of inference or joint autograd graphs, under established tracing invariants.

**Example and boundary.** Joint inputs include forward primals and output cotangents (called tangents in the implementation); outputs include forward results and gradients.

### [`_decomp/__init__.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_decomp/__init__.py), [`decompositions.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_decomp/decompositions.py)

**Why it exists.** Replace selected higher-level ATen operations with simpler ones supported/optimized downstream. This controls the compiler's operator surface.

**Example and boundary.** A norm may expose reductions and pointwise math after decomposition. Not every operator is always decomposed; preserving a recognizable operation can benefit a backend. Floating-point casts and promotion are part of correctness.

### [`_functorch/partitioners.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/partitioners.py)

**Why it exists.** Split joint graphs into forward/backward and choose which values cross the boundary. `min_cut_rematerialization_partition` trades saved activations against recomputation.

**Example and boundary.** Saving `(B, 1)` inverse RMS can be much cheaper than saving another `(B, H)` intermediate. A value needed in backward need not always be stored by forward.

### [`_aot_autograd/runtime_wrappers.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/runtime_wrappers.py)

**Why it exists.** Reconcile functional graph calling conventions with real eager inputs/outputs and autograd. Includes deduplication, synthetic bases, subclasses, mutation/alias epilogues, saved state, and lazy backward compilation.

**Example and boundary.** Two inputs can alias one storage. Treating them as independent buffers can miscompile an update; synthetic-base handling reconstructs the views where needed.

### [`_aot_autograd/autograd_cache.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/autograd_cache.py)

**Why it exists.** Cache reusable AOT work and preserve the metadata needed to recreate valid runtime behavior.

**Example and boundary.** A Dynamo cache hit and an AOT cache hit describe different layers; compile latency should be attributed accordingly.

Inductor wires its partitioning and compiler callbacks through
[`compile_fx.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/compile_fx.py).
Do not infer Inductor's partition policy from `aot_function`'s default alone:
the backend supplies its own callback, including joint-graph passes.

## Worked training trace: residual RMSNorm

```python
def residual_rmsnorm(x, residual, weight, eps=1e-6):
    z = x.float() + residual.float()
    inv = torch.rsqrt(z.square().mean(dim=-1, keepdim=True) + eps)
    return (z * inv * weight.float()).to(x.dtype)
```

Read one row as one example with `H` features. RMSNorm squares its feature
values, averages those squares, adds a small epsilon, and takes the reciprocal
square root. Multiplying the row by that scalar normalizes its magnitude;
`weight` then scales each feature. The residual is added before these steps.
A **reduction** combines many elements into fewer elements, as `mean` does.
**Broadcasting** reuses a smaller array or scalar across a larger array's
indices without necessarily storing repeated copies.

Take `x, residual: (B, H)` and `weight: (H,)`, all requiring gradients. This
expression is deliberately explicit: it does not depend on whether a particular
native RMSNorm operator is preserved or decomposed. Accumulation is explicitly
FP32; output conversion is part of the contract.

1. Dynamo records casts, add, square, mean, epsilon add, rsqrt, multiplies, and
   output conversion. It specializes or symbolically tracks dimensions and
   guards relevant dtype/device/layout/Python assumptions. The Python default
   `eps` can be a specialization assumption.
2. Fake execution supplies metadata. `mean(..., keepdim=True)` gives `(B, 1)`;
   multiplying by `z` and `weight` introduces broadcast/index relationships.
3. AOTAutograd traces the differentiated computation. Ignoring cast rounding
   for the analytic FP32 explanation, write `r = (mean(z²)+eps)^(-1/2)` and
   `q = grad_output * weight`. Then
   `grad_z = r*q - z*r³*mean(q*z)` along each row. Both `grad_x` and
   `grad_residual` receive this gradient through their casts, while
   `grad_weight = sum_rows(grad_output*z*r)`.
4. The partitioner chooses saved values/recomputation. Candidates include
   original inputs, `z`, and rowwise `r`. The chosen set is a compiler-policy
   result, not fixed by the derivative above. Inspect forward auxiliary outputs
   and backward placeholders to find what actually crosses the boundary.
5. Inductor separately schedules the resulting forward and backward graphs.
   The rowwise RMS reduction and the cross-row weight-gradient reduction have
   different reduction axes. They are not automatically one kernel simply
   because the joint graph describes both.

In step 3, `grad_output` means the derivative supplied by the later part of the
model: how changing each output affects the final loss. The derivative has a
direct term through `z` and an indirect term through the row's normalization
scalar. Both must be present. Step 4 exists because the indirect term needs
information from the forward calculation after the forward has finished.

Returning `(output, z)` changes the user-visible materialization requirements.
Adding `return output @ projection` introduces a GEMM consumer whose layout,
implementation, and fusion opportunities differ from another pointwise
consumer. The [fusion guide](inductor-and-fusion.md) follows that next boundary.

## Three failures that look similar but have different causes

**A recompilation:** `f(x, scale=0.5)` computes `x * scale`; another call changes
the Python scalar or input stride. A previously installed assumption may fail,
causing a new specialization. Tensorizing the scalar can change the capture
contract; it is not a universal cure for shape or layout guards. With
`dynamic=None`, shape changes can prompt a more dynamic recompile. With
`dynamic=True`, many dimensions start symbolic, but dtype, device, layout,
branch constraints, and specialization still matter.

**A graph break:** place `torch._dynamo.graph_break()` between RMSNorm and its
GEMM consumer for a controlled experiment. The compiler must finish the first
region and resume Python before another region. This forbids ordinary
same-region optimization across that boundary. Removing the break makes fusion
possible to consider; it does not force the GEMM implementation to accept it.
`fullgraph=True` turns this explicit break into a capture failure.

**A mutation contract:** `x.add_(residual); return x[:, :H//2]` changes `x` and
returns a view. In an inference experiment, use fresh non-grad inputs and check
both input contents and output aliasing against eager. A functional graph may
return an updated input value plus metadata-driven outputs. Runtime copyback
and view reconstruction restore the contract. In training, eager autograd's
leaf/in-place restrictions still apply: compilation is not permission to mutate
a leaf requiring gradients.

## Export and Compiled Autograd are separate extensions

The normal compile workflow can check assumptions and return to Python when
needed. Deployment may instead need a program handed to another tool with a
clear list of allowed inputs. **Export** makes that handoff explicit. Its
**signature** describes the meaning and order of inputs and outputs; its
constraints describe which shapes the program supports.

[`torch.export.export`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/export/__init__.py#L59)
produces an `ExportedProgram` with a graph, signature/state, and shape
constraints for a declared input domain. It is intended to outlive the
interactive guarded Python execution strategy. It does not preserve arbitrary
Python fallback as a deployment mechanism. `strict=False` at this revision is
not permission to export unsound arbitrary behavior. Export is also not itself
GPU code generation; a downstream compiler/runtime is still needed.

[`_dynamo/compiled_autograd.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/compiled_autograd.py)
captures backward execution at a different boundary and can encompass work
that otherwise remains split between autograd regions. Ordinary AOTAutograd
inside `torch.compile` should not be described as automatically compiling the
entire application-wide backward engine, hooks, and every eager region.

## Comparison with tinygrad's compiler philosophy

| Question | tinygrad starting point | PyTorch compile starting point |
| --- | --- | --- |
| Where is the tensor program? | Tensor construction already builds a lazy UOp graph. | Discover tensor regions in a Python program whose normal contract is eager execution. |
| Why all the Python machinery? | Tensor semantics are designed around the lazy representation; TinyJit captures reusable execution with its own constraints. | Existing Python control flow, object identity, modules, side effects, and eager behavior need compatibility. |
| Why multiple representations? | UOps serve many phases; phase invariants and matcher ordering carry much of the contract. | Python abstract values, FX graphs with stage-dependent vocabularies, functional ATen, and backend loop/buffer IR solve different boundary problems. |
| Where does training fit? | Autograd contributes computation to the lazy tensor program. | AOTAutograd obtains joint graphs and supplies compiled forward/backward callables integrated with the eager autograd runtime. |
| What does reuse mean? | Reuse/capture depends on tinygrad's JIT and execution contracts. | Guarded specializations plus multiple compilation caches; reuse must validate assumptions about surrounding Python and tensor state. |
| How to read a “weird rule”? | Start with the UOp phase and matcher ordering. | First identify which layer owns the behavior: bytecode modeling, shape proof, decomposition, alias wrapper, FX rewrite, or kernel scheduling. |

Neither system guarantees fusion from algebra alone. The useful comparison is
how each represents the constraints that make fusion legal, and where each
chooses a materialization or launch boundary.
