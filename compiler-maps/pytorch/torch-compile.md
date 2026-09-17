# torch.compile capture and exercises

The source explanation and its worked exercises share one reference. They describe the recorded PyTorch checkout; runnable validation is identified explicitly below.

<a id="torch-compile"></a>
## torch.compile: recovering a compiler program from eager Python
<a id="torch-compile--torchcompile-recovering-a-compiler-program-from-eager-python"></a>

Source snapshot: PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`.
This is a source-derived map, not a claim that this checkout was built. Examples
below are schematic unless linked to executed probes. The installed PyTorch
2.11 runtime is a different revision. Continue with [Inductor and kernel
fusion](inductor-and-fusion.md#inductor-and-fusion) and [worked exercises](torch-compile.md#compile-exercises).

<a id="torch-compile--start-with-one-ordinary-array-function"></a>
### Start with one ordinary array function

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

<a id="torch-compile--the-boundaries-to-keep-separate"></a>
### The boundaries to keep separate

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

<a id="torch-compile--entry-python-capture-and-resumption-module-map"></a>
### Entry, Python capture, and resumption: module map

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

<a id="torch-compile--torch__init__pycompilehttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch__init__pyl3076"></a>
#### [`torch/__init__.py:compile`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/__init__.py#L3076)

**Why it exists.** Public wrapper selecting capture/backend policies. Compilation is generally triggered on invocation, when input properties are known.

**Example and boundary.** Decorating `rmsnorm` does not itself establish its eventual kernel count. This revision also has `recompile_limit`, `isolate_recompiles`, and `dynamic_shapes`; older installed wheels may not expose them.

<a id="torch-compile--_dynamoeval_framepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamoeval_framepy-and-csrcdynamoeval_framechttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchcsrcdynamoeval_framec"></a>
#### [`_dynamo/eval_frame.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/eval_frame.py) and [`csrc/dynamo/eval_frame.c`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/dynamo/eval_frame.c)

**Why it exists.** Install the frame-evaluation machinery and wrap callables/modules. This lets existing Python code opt into capture without a new Tensor API.

**Example and boundary.** Calling the same function can reuse a guarded specialization. The code-object cache is not simply a dictionary from Tensor shapes to kernels.

<a id="torch-compile--_dynamoconvert_framepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamoconvert_framepy"></a>
#### [`_dynamo/convert_frame.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/convert_frame.py)

**Why it exists.** Coordinate tracing a frame, compiling its graph, transformed bytecode, guards, and failure policy.

**Example and boundary.** A guard miss can enter compilation again; unsupported tracing and backend compilation failures are different failure classes.

<a id="torch-compile--_dynamosymbolic_convertpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamosymbolic_convertpy"></a>
#### [`_dynamo/symbolic_convert.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/symbolic_convert.py)

**Why it exists.** Interpret Python bytecode using abstract values, emitting tensor graph operations while following or specializing Python behavior.

**Example and boundary.** `if x.shape[0] > 8` can select a branch and require a shape guard. `if x.sum() > 0` depends on tensor data and cannot generally be resolved by shape specialization.

<a id="torch-compile--_dynamovariablesbasepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamovariablesbasepy-builderpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamovariablesbuilderpy-tensorpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamovariablestensorpy"></a>
#### [`_dynamo/variables/base.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/variables/base.py), [`builder.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/variables/builder.py), [`tensor.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/variables/tensor.py)

**Why it exists.** `VariableTracker` represents Python values, their provenance, supported behavior, and mutation properties; `TensorVariable` carries a graph proxy. These are interpreter values, not an arithmetic optimization IR.

**Example and boundary.** A Python list of tensors must retain list semantics while each tensor contributes FX nodes. Treating all values as tensors loses identity, specialization, and Python method behavior.

<a id="torch-compile--_dynamosourcepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamosourcepy"></a>
#### [`_dynamo/source.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/source.py)

**Why it exists.** Describe how to retrieve a value from runtime locals, globals, attributes, or containers. Needed to build guards and reconstruct execution.

**Example and boundary.** The source of `self.weight` differs from an anonymous intermediate: the former can be retrieved/guarded at the next call.

<a id="torch-compile--_dynamooutput_graphpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamooutput_graphpy"></a>
#### [`_dynamo/output_graph.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/output_graph.py)

**Why it exists.** Own graph construction and the boundary between tensor graph outputs and the Python stack/locals that must survive.

**Example and boundary.** A graph prefix may return an intermediate needed by resumed Python, even when that value is not a user-visible function result.

<a id="torch-compile--_dynamoguardspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamoguardspy-and-csrcdynamoguardscpphttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchcsrcdynamoguardscpp"></a>
#### [`_dynamo/guards.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/guards.py) and [`csrc/dynamo/guards.cpp`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/csrc/dynamo/guards.cpp)

**Why it exists.** Check the assumptions that made a specialization valid. A guard is a correctness condition, not just an annoying cache key.

**Example and boundary.** Shape, stride, dtype, device, Python constants, object relationships, and ambient state can matter. `dynamic=True` does not remove all of these checks.

<a id="torch-compile--_dynamoside_effectspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamoside_effectspy"></a>
#### [`_dynamo/side_effects.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/side_effects.py)

**Why it exists.** Record supported Python mutations and generate replay code preserving their observable behavior.

**Example and boundary.** Appending a tensor to a list cannot disappear because only the returned tensor is in FX. Unsupported effects can force a break/error; supported effects do not all require graph breaks.

<a id="torch-compile--_dynamoresume_executionpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamoresume_executionpy-and-bytecode_transformationpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_dynamobytecode_transformationpy"></a>
#### [`_dynamo/resume_execution.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/resume_execution.py) and [`bytecode_transformation.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_dynamo/bytecode_transformation.py)

**Why it exists.** Build continuation bytecode so a graph prefix can run, unsupported Python can execute, and tracing/execution can resume.

**Example and boundary.** Splitting before logging a tensor is more work than cutting an FX edge: stack state, locals, and active context managers must remain meaningful.

`fullgraph=True` requires capture without graph breaks; it does **not** mean a
single GPU kernel, static shapes, or no guards. A notable snapshot detail:
its public docstring says fullgraph enables unbacked semantics, including scalar
output and dynamic-output-shape capture defaults. Therefore the old blanket
claim “`.item()` always graph-breaks” is wrong here. Capturing a scalar and using
that scalar to choose arbitrary Python control flow are still different tasks.

<a id="torch-compile--fake-execution-symbolic-shapes-and-fx"></a>
### Fake execution, symbolic shapes, and FX

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

<a id="torch-compile--_subclassesfake_tensorpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_subclassesfake_tensorpy"></a>
#### [`_subclasses/fake_tensor.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_subclasses/fake_tensor.py)

**Why it exists.** `FakeTensorMode` propagates metadata and device semantics without performing the normal real-data computation. Tensor storage identity and alias relationships also matter during tracing.

**Example and boundary.** `x @ w` can infer output shape/dtype without reading GPU values. An operator lacking appropriate fake/meta behavior cannot be made traceable merely by writing a fast CUDA implementation.

<a id="torch-compile--fxexperimentalsymbolic_shapespyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchfxexperimentalsymbolic_shapespy"></a>
#### [`fx/experimental/symbolic_shapes.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/experimental/symbolic_shapes.py)

**Why it exists.** `ShapeEnv` manages symbolic expressions, assumptions, ranges, guards, and deferred assertions. Shapes influence correctness of indexing and specialization.

**Example and boundary.** Broadcasting `(B, H)` with `(H,)` needs dimension relationships. A reshape can need divisibility constraints. `B` can be symbolic while `H` remains specialized.

<a id="torch-compile--fxexperimentalsym_nodepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchfxexperimentalsym_nodepy"></a>
#### [`fx/experimental/sym_node.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/experimental/sym_node.py)

**Why it exists.** Back symbolic integer/boolean operations with expressions and a shape environment.

**Example and boundary.** `x.shape[0] * x.shape[1]` need not become an ordinary constant, but converting a symbolic condition into a Python boolean can introduce a guard or fail.

<a id="torch-compile--fxgraphpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchfxgraphpy-nodepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchfxnodepy-graph_modulepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchfxgraph_modulepy"></a>
#### [`fx/graph.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/graph.py), [`node.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/node.py), [`graph_module.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/graph_module.py)

**Why it exists.** Provide a graph representation with Python-callable code generation and metadata. Different stages can use FX with different operator vocabularies.

**Example and boundary.** A Dynamo FX graph and a decomposed ATen FX graph are not necessarily the same program representation merely because both are `GraphModule`s.

<a id="torch-compile--fxexperimentalproxy_tensorpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorchfxexperimentalproxy_tensorpy"></a>
#### [`fx/experimental/proxy_tensor.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/fx/experimental/proxy_tensor.py)

**Why it exists.** `make_fx` and dispatch-level proxy tracing capture tensor operations, including decompositions, under tensor modes.

**Example and boundary.** AOT tracing can record the ATen operations executed by autograd without independently interpreting all user Python again. Do not equate this with Dynamo's bytecode interpreter.

A **backed** shape symbol has a value from the example inputs that can guide
specialization. An **unbacked** symbol can represent a data-dependent quantity,
such as a count determined by tensor contents, without an ordinary input-shape
hint. Neither grants permission to guess data-dependent control flow. Runtime
assertions, explicit structured control flow, specialization, and unsupported
cases are distinct ways a compiler handles the constraints.

<a id="torch-compile--aotautograd-why-so-much-machinery-sits-before-the-kernel-compiler"></a>
### AOTAutograd: why so much machinery sits before the kernel compiler

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

<a id="torch-compile--_functorchaot_autogradpyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorchaot_autogradpy"></a>
#### [`_functorch/aot_autograd.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/aot_autograd.py)

**Why it exists.** Flatten function/module inputs, configure tracing and compiler callbacks, expose `aot_function` / `aot_module_simplified`.

**Example and boundary.** Module parameters and buffers become explicit computational inputs; user-level module calls are not the final kernel ABI. These private interfaces are experimental.

<a id="torch-compile--_aot_autogradgraph_compilepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradgraph_compilepy"></a>
#### [`_aot_autograd/graph_compile.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/graph_compile.py)

**Why it exists.** Separate `aot_stage1_graph_capture` from stage-two compilation/export, dispatch training versus inference paths, and invoke partitioners/compiler callbacks.

**Example and boundary.** Inference needs functionalization but no generated gradient graph when no autograd is needed. This snapshot uses these filenames; older guides referring to `jit_compile_runtime_wrappers.py` describe a different organization.

<a id="torch-compile--_aot_autogradcollect_metadata_analysispyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradcollect_metadata_analysispy-and-schemaspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradschemaspy"></a>
#### [`_aot_autograd/collect_metadata_analysis.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/collect_metadata_analysis.py) and [`schemas.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/schemas.py)

**Why it exists.** Record input mutations, output aliases, subclass information, and calling-convention metadata. The graph alone cannot explain how to reconstruct all eager semantics.

**Example and boundary.** Returning a view of a mutated input differs from returning an independent equal-valued tensor. `ViewAndMutationMeta` retains that distinction.

<a id="torch-compile--_aot_autogradgraph_capture_wrapperspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradgraph_capture_wrapperspy"></a>
#### [`_aot_autograd/graph_capture_wrappers.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/graph_capture_wrappers.py)

**Why it exists.** `create_functionalized_fn` and `create_joint` normalize mutation and arrange forward plus gradients for tracing. Functionalization makes dependencies explicit.

**Example and boundary.** `x.add_(r)` can be represented by a new value, with the externally visible mutation restored through the surrounding contract. It is not legal simply to delete the mutation.

<a id="torch-compile--_aot_autogradgraph_capturepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradgraph_capturepy"></a>
#### [`_aot_autograd/graph_capture.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/graph_capture.py)

**Why it exists.** Dispatch-level capture of inference or joint autograd graphs, under established tracing invariants.

**Example and boundary.** Joint inputs include forward primals and output cotangents (called tangents in the implementation); outputs include forward results and gradients.

<a id="torch-compile--_decomp__init__pyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_decomp__init__py-decompositionspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_decompdecompositionspy"></a>
#### [`_decomp/__init__.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_decomp/__init__.py), [`decompositions.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_decomp/decompositions.py)

**Why it exists.** Replace selected higher-level ATen operations with simpler ones supported/optimized downstream. This controls the compiler's operator surface.

**Example and boundary.** A norm may expose reductions and pointwise math after decomposition. Not every operator is always decomposed; preserving a recognizable operation can benefit a backend. Floating-point casts and promotion are part of correctness.

<a id="torch-compile--_functorchpartitionerspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorchpartitionerspy"></a>
#### [`_functorch/partitioners.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/partitioners.py)

**Why it exists.** Split joint graphs into forward/backward and choose which values cross the boundary. `min_cut_rematerialization_partition` trades saved activations against recomputation.

**Example and boundary.** Saving `(B, 1)` inverse RMS can be much cheaper than saving another `(B, H)` intermediate. A value needed in backward need not always be stored by forward.

<a id="torch-compile--_aot_autogradruntime_wrapperspyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradruntime_wrapperspy"></a>
#### [`_aot_autograd/runtime_wrappers.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/runtime_wrappers.py)

**Why it exists.** Reconcile functional graph calling conventions with real eager inputs/outputs and autograd. Includes deduplication, synthetic bases, subclasses, mutation/alias epilogues, saved state, and lazy backward compilation.

**Example and boundary.** Two inputs can alias one storage. Treating them as independent buffers can miscompile an update; synthetic-base handling reconstructs the views where needed.

<a id="torch-compile--_aot_autogradautograd_cachepyhttpsgithubcompytorchpytorchblobe52fd8ff9759e1c4bea7adcf63ca22717fe5e8dftorch_functorch_aot_autogradautograd_cachepy"></a>
#### [`_aot_autograd/autograd_cache.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_functorch/_aot_autograd/autograd_cache.py)

**Why it exists.** Cache reusable AOT work and preserve the metadata needed to recreate valid runtime behavior.

**Example and boundary.** A Dynamo cache hit and an AOT cache hit describe different layers; compile latency should be attributed accordingly.

Inductor wires its partitioning and compiler callbacks through
[`compile_fx.py`](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/compile_fx.py).
Do not infer Inductor's partition policy from `aot_function`'s default alone:
the backend supplies its own callback, including joint-graph passes.

<a id="torch-compile--worked-training-trace-residual-rmsnorm"></a>
### Worked training trace: residual RMSNorm

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
consumer. The [fusion guide](inductor-and-fusion.md#inductor-and-fusion) follows that next boundary.

<a id="torch-compile--three-failures-that-look-similar-but-have-different-causes"></a>
### Three failures that look similar but have different causes

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

<a id="torch-compile--export-and-compiled-autograd-are-separate-extensions"></a>
### Export and Compiled Autograd are separate extensions

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

<a id="torch-compile--comparison-with-tinygrads-compiler-philosophy"></a>
### Comparison with tinygrad's compiler philosophy

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

<a id="compile-exercises"></a>
## Capture and training exercises, with worked answers
<a id="compile-exercises--capture-and-training-exercises-with-worked-answers"></a>

Companion to [the compile source map](torch-compile.md#torch-compile). Source-derived answers
use PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. These exercises are
investigation recipes, not invented execution transcripts. Any measured results
must identify runtime version, device, dtype, shapes, and configuration.

These exercises follow one sequence: first recover a record of array operations,
then preserve its Python behavior, then plan training, then ask how it executes.
A graph is that operation record; a kernel is a unit of generated device work.
A guard checks an assumption used to compile a particular version. If these
are new terms, read [the opening example](torch-compile.md#torch-compile--start-with-one-ordinary-array-function)
first. Each “Work through it” section gives intermediate steps before the answer.

<a id="compile-exercises--1-separate-capture-count-from-kernel-count"></a>
### 1. Separate capture count from kernel count

Use `residual_rmsnorm` from [the source map](torch-compile.md#torch-compile--worked-training-trace-residual-rmsnorm)
and prepare tensors `x`, `residual`, and `weight` with matching shapes. The code
below is a snippet, not a standalone script. A backend receives the captured
graph as `gm`; `gm.code` displays its generated Python and `gm.forward` runs it.
Use this deliberately diagnostic backend:

```python
import torch

submissions = []
def inspect_backend(gm, example_inputs):
    submissions.append(gm)
    print(gm.code)
    return gm.forward

compiled = torch.compile(residual_rmsnorm, backend=inspect_backend)
y = compiled(x, residual, weight)
```

**Task:** Does one backend submission establish that RMSNorm executes as one
kernel? What does it establish, and what information is missing?

**Work through it:** Find the line that appends to `submissions`. It runs when the backend receives a graph, not whenever a device kernel launches. Next find what callable the backend returns. Ask which compiler stages that callable actually uses.

**Answer:** It establishes that this backend received one captured FX region
for this invocation/specialization. Returning `gm.forward` executes its graph
through regular PyTorch operations; it does not invoke Inductor's kernel
scheduler. The example is useful for capture debugging, not fusion claims.
Use the Inductor backend, generated code, and a runtime trace to count executed
kernels/library calls. Record compilation separately from warm execution.

<a id="compile-exercises--2-rmsnorm-backward-as-a-graph-boundary-problem"></a>
### 2. RMSNorm backward as a graph-boundary problem

**Task:** For `z=x+residual`, `r=rsqrt(mean(z*z)+eps)`, and `y=z*r*weight`,
find the two different reduction directions in backward. Decide which values
might be saved, then verify against actual AOT forward/backward graphs.

**Work through it:** Draw a row of H values and its one normalization scalar. Changing one value affects its own output directly and every output in that row through the scalar. Separately, one weight value is reused across B rows, so its gradient gathers contributions from those rows.

**Worked answer:** The upstream gradient `g` says how each output affects the
loss. Let `s=mean(z*z)+eps` and `r=s^(-1/2)`. The local derivative of `r`
with respect to feature `z[h]` is `-z[h]*r^3/H`: differentiating the mean of
squares gives `2*z[h]/H`, and differentiating the inverse square root gives
`-0.5*s^(-3/2)`. Multiplying cancels the factors of two.

The direct route through `y=z*r*weight` contributes `r*g*weight`. The route
through `r` collects the whole row's contributions, producing the second term
below. For upstream gradient `g`, set `q=g*weight`.
Along the hidden dimension,

```text
a[b] = mean_h(q[b,h] * z[b,h])
grad_z[b,h] = r[b] * q[b,h] - z[b,h] * r[b]^3 * a[b]
```

The weight gradient instead reduces rows:

```text
grad_weight[h] = sum_b(g[b,h] * z[b,h] * r[b])
```

`grad_x` and `grad_residual` are both `grad_z` before the respective cast
backward conversions. Additional leading dimensions are also reduced for the
weight gradient. The row reduction and column reduction want different work
partitioning. Mathematical adjacency therefore does not prove kernel fusion.

Saving `r` costs `B` FP32 elements; saving `z` costs `B*H`. Reconstructing `z`
requires rereading both input tensors and an add. Reconstructing `r` also needs
a reduction. A partitioner weighs such choices, with implementation constraints;
it does not solve this example by a universal “save everything” rule.

For a concrete capture experiment, create your own `rmsnorm_probe.py` that calls
the function with grad-enabled inputs and calls backward on a scalar loss.
The following command is a recipe for that script, not a claim that a file with
this name has been executed here. Run the function and its backward under:

```bash
TORCH_LOGS="aot_graphs,aot_joint_graph,graph_breaks,recompiles" python rmsnorm_probe.py
```

Inspect forward outputs beyond the user's result and the matching backward
placeholders. Distinguish saved tensors from saved symbolic sizes. Then inspect
Inductor output code to see which saved values actually require memory traffic.
The logging interface and graph formatting are version-sensitive; check the
installed runtime when replaying the recipe.

<a id="compile-exercises--3-add-a-gemm-and-force-a-real-capture-boundary"></a>
### 3. Add a GEMM and force a real capture boundary

```python
def block(x, residual, weight, projection):
    y = residual_rmsnorm(x, residual, weight)
    return y @ projection

def split_block(x, residual, weight, projection):
    y = residual_rmsnorm(x, residual, weight)
    torch._dynamo.graph_break()
    return y @ projection
```

**Task:** Compare graph regions, generated kernels, external calls, and
intermediate allocations for both. Repeat with `fullgraph=True`. Why might the
unsplit case still materialize `y`?

**Work through it:** Label three kinds of boundary separately: leaving a captured graph, writing an intermediate array, and launching a kernel or library operation. Then compare which of those are forced by the explicit break and which remain backend choices.

**Answer:** The explicit break demands a first compiled region and resumed
Python before the later region; fullgraph rejects this break. In the unsplit
version, capture can expose both operations to a backend, but the chosen GEMM
may be an external library call requiring a materialized input. A template
may support only particular producer/epilogue fusion forms. RMSNorm's reduction
also requires more than substituting a scalar multiply into GEMM indexing.
Therefore removing the graph break can leave the same number of kernel/library
launches. Demonstrate a change using code and traces, not FX node counts.

A useful extension is to return both `y` and `y @ projection`: now `y` is
observable even if a fused consumer could otherwise avoid storing it. Compare
with the tinygrad materialized-versus-lazy RMSNorm exercise, keeping the API
semantics of the two systems explicit.

<a id="compile-exercises--4-recompilation-is-an-assumption-failure"></a>
### 4. Recompilation is an assumption failure

**Task:** Compile a pointwise function and call it with batch sizes 8, 8, 12,
12, 8. Change a Python scale parameter on the fourth call. Repeat with
`dynamic=False` and `dynamic=True`. Then change dtype and use a noncontiguous
input with the same shape. Predict categories of guards, not an invariant
number of recompilations.

**Work through it:** Make a five-row record of call number, batch size, scale, and cumulative backend submissions. A count increase means a new graph was submitted; an unchanged count means no new submission. Keep the dtype/layout experiments separate so one changed property explains each observation.

**Answer:** Static dimension specialization can make 12 violate the first
shape guard. Reusing 8 may find an existing valid entry. A Python scalar may
be specialized or symbolically represented depending on its type, dynamic
policy, and runtime version; do not universally predict a recompile. Changing
layout or dtype can invalidate a specialization even if batch size is symbolic.
`TORCH_LOGS="guards,recompiles,dynamic"` identifies the actual assumptions.

A concrete executed counting-backend probe in the installed **2.11.0+cu130**
wheel used integer scale values `2, 2, 2, 3, 2` with these batch sizes. Cumulative
backend submissions were `1, 1, 2, 3, 3` for `dynamic=False` and
`1, 1, 1, 1, 1` for `dynamic=True`. In that latter run the scalar was symbolic
as well. These are capture observations for that wheel, not kernel counts or a
promise about the source snapshot. Raw evidence:
[`artifacts/rmsnorm/results.json`](artifacts/rmsnorm/results.json).

<a id="compile-exercises--5-mutation-plus-output-aliasing"></a>
### 5. Mutation plus output aliasing

```python
def mutate_and_view(x, residual):
    x.add_(residual)
    return x[:, :x.shape[1] // 2]
```

**Task:** In inference with non-grad inputs, compare eager and compiled behavior
for (a) independent input storages and (b) carefully chosen overlapping views.
What must your oracle check besides numerical output equality?

**Work through it:** First check that the same case is legal in eager execution. Then check both what the function returns and what happened to the original inputs. Finally change one element through the returned view and see which input element changes.

**Answer:** Check the mutated input contents, unaffected storage regions,
output sizes/strides, and observable alias behavior: modifying the returned
view should change the corresponding region of `x` in the same way as eager.
For each run, recreate the same alias relationships on fresh storage. Simply
cloning each argument independently destroys the test case. Some overlap
patterns are already illegal in eager; matching eager's legal domain matters.

Read `ViewAndMutationMeta`, `AOTSyntheticBaseWrapper`, and runtime epilogues.
The compiler may represent mutations as output values and reconstruct original
views. An apparently redundant copy or alias operation can be part of the
correct calling convention. In training, do not mutate a leaf requiring grad
and then blame a compiler for preserving eager's error.

<a id="compile-exercises--6-python-state-is-not-tensor-state"></a>
### 6. Python state is not tensor state

```python
def record(x, history):
    y = x.sin()
    history.append(y)
    return y.cos()
```

**Task:** Why is eliminating `y` because only `cos(y)` is returned unsound?
Where would you investigate if the list receives the wrong value or wrong
number of entries?

**Work through it:** Call the function twice with the same list. Even if nobody assigns its return value, the caller can inspect the list afterward. Count the expected appended entries and trace where each appended tensor comes from.

**Answer:** `history` is externally observable and must gain the correct tensor
on each supported execution. Dynamo's `SideEffects`, source tracking, generated
bytecode, and resumption are the first places to investigate. AOT tensor
functionalization handles a different layer. Some Python effects are modeled
and replayed; others require breaks or errors. Do not assume every list append
is untraceable or that a graph visualization displays all observable effects.

<a id="compile-exercises--7-shape-dependent-and-data-dependent-branches"></a>
### 7. Shape-dependent and data-dependent branches

```python
def shape_branch(x):
    return x.sin() if x.shape[0] > 8 else x.cos()

def value_branch(x):
    return x.sin() if x.sum() > 0 else x.cos()
```

**Task:** Why can a symbolic batch still require multiple specializations in the
first function? Why doesn't `dynamic=True` solve the second in general?

**Work through it:** For the first function, determine the branch from the array shape without reading any elements. For the second, make two equal-shaped arrays with opposite-sign sums. Their metadata is identical but the chosen branches differ.

**Answer:** The first branch creates a predicate on the symbolic batch. One
specialization can be valid only for a range such as `B>8`; symbolic does not
mean all branch paths are present. The second predicate depends on data, not
input-shape metadata. Capturing a scalar or an unbacked symbolic value is not
the same as resolving an arbitrary Python branch. Explore explicit structured
control flow when suitable, while respecting branch signature and mutation
constraints. Record whether the runtime breaks, errors, or captures a
supported representation rather than guessing from the flag alone.

<a id="compile-exercises--8-export-the-contract-not-the-cache"></a>
### 8. Export the contract, not the cache

**Task:** Wrap residual RMSNorm in a module and export with a dynamic batch and
fixed hidden size. What must travel with the graph? What is absent compared
with normal `torch.compile` execution?

**Work through it:** List what another process would need to run the model without your original Python session: tensor inputs, parameters, input/output structure, and rules for allowed dimensions. Then distinguish that package from machine code for a specific device.

**Answer:** The graph signature, parameter/buffer state, input/output structure,
and shape constraints are part of the program contract. An exported program
is valid within those constraints. The deployment artifact cannot depend on
arbitrary Python fallback to repair an unsupported path. Export alone does
not choose the final GPU kernels or supply every target runtime component.
AOTInductor or another consumer provides further lowering/deployment machinery.
This is closer to MLIR/IREE's explicit program handoff than to Dynamo's ongoing
specialize/check/recompile loop, although the representations differ.

<a id="compile-exercises--9-diagnose-at-the-narrowest-failing-boundary"></a>
### 9. Diagnose at the narrowest failing boundary

**Task:** RMSNorm is correct eager, but wrong compiled. In what order would you
isolate the failure without claiming every debugging backend runs the same
pipeline?

**Work through it:** Use exactly the same fresh input values for each comparison. Start with the earliest stage that can reproduce the mismatch, and add one compiler layer at a time. Keep a separate record of forward outputs, changed inputs, and gradients.

**Answer:** First fix seeds, inputs, dtype, tolerances, and alias relationships.
A tolerance is the numerical error you accept when comparing floating-point
results; changing addition order can change rounding without indicating an
incorrect transformation.

Compare eager with a capture backend that returns `gm.forward`; that tests
Dynamo's recovered regions and associated Python behavior without Inductor.

Then use an available AOT eager diagnostic backend to exercise functionalization
and differentiation while leaving machine-code generation out of scope.

Finally compare Inductor and inspect the smallest differing forward/backward result.
A passing simpler backend narrows the search but does not prove all common
passes are identical: backend configurations and decomposition tables can
differ. Separate an incorrect result from expected floating-point reassociation
and reduction-order differences using a stated tolerance and high-precision
reference where appropriate.
