# PyTorch source atlas: contracts first, then kernels

Source snapshot: `/home/boop/tenstorrent/pytorch`, commit `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. This is a source-reviewed directory and subsystem map, **not an audit of every file, operator, or rewrite rule**. It covers every non-hidden root directory and every immediate `torch/` subdirectory present in this checkout, grouping related packages below. It does not claim equivalent depth to the tinygrad rule catalogue. Examples in this page are reading exercises with worked answers, not execution results. A shallow checkout contains the superproject source and submodule references; it is not a built PyTorch installation or a recursive copy of every dependency.

Read this alongside [eager execution](eager-execution.md#eager-execution), [torch.compile](torch-compile.md#torch-compile), and [Inductor and kernel fusion](inductor-and-fusion.md#inductor-and-fusion). Those pages follow execution paths; this one explains why the surrounding modules exist and where to investigate a broken contract.

## Start with one operation and three responsibilities

Suppose you write `y = x + 1`. Python provides the convenient spelling. The runtime must determine shape and numeric type, decide which device implementation to call, allocate output storage, and preserve derivative behavior if needed. The selected implementation finally adds numbers. These jobs explain the first directories to learn: `torch/` exposes the interface, `aten/` defines and implements tensor operations, and `c10/` provides shared tensor/storage/device machinery. `torchgen/` generates repetitive interfaces from declarations so those layers agree.

A **contract** is behavior that other code can rely on, including effects on existing tensors. For example, these two programs can produce the same new values for `x` while having different effects on `v`:

```python
v = x.view(-1)     # shares x's storage
x.add_(1)          # changes values visible through both x and v
# Compare, starting from the original x:
v = x.view(-1)
x = x + 1         # creates new storage; v still sees the old values
```

This is **aliasing**: different tensor objects refer to overlapping memory. A compiler must preserve what a caller can observe through either object. That requirement helps explain why PyTorch has more than arithmetic kernels and optimization rules.

Read the [first-principles guide](../first-principles.md) for shared compiler terms and [eager execution](eager-execution.md#eager-execution) for a complete call path. The tables below are a lookup atlas: read the explanation before each group, then follow rows relevant to your program. You do not need to memorize every package before proceeding.

## The architectural difference from tinygrad

A productive comparison is **where each system places its shared contract**.

In tinygrad, Tensor operations construct UOps, and successive graph/schedule/codegen transformations reuse that compact vocabulary. Start with [Tensor](../../../tinygrad/tinygrad/tensor.py), [UOp](../../../tinygrad/tinygrad/uop/ops.py), and its [compiler map](../tinygrad/module-map.md#module-map). A rule often has the job of making a common representation appropriate for its next stage. This does not mean every UOp is valid at every stage, or every backend supports every operation.

An **operator schema** declares argument/result types and whether storage is shared or mutated. The **dispatcher** selects an implementation for a call using categories called **dispatch keys**. These include device backends and behavior such as gradient bookkeeping. A **registration** connects an operator/category pair to code. An **overload** distinguishes variants, such as adding a Tensor versus a scalar.

PyTorch's shared seam is substantially the **operator schema plus dispatcher contract**: overload, argument types, aliasing/mutation, dispatch keys, backend implementations, and transform behavior. [Native operator declarations](../../../pytorch/aten/src/ATen/native/native_functions.yaml), [DispatchKey](../../../pytorch/c10/core/DispatchKey.h), [Dispatcher](../../../pytorch/aten/src/ATen/core/dispatch/Dispatcher.h), and [torch.library](../../../pytorch/torch/library.py) make that concrete. Eager can execute an operator without first building a whole-program compiler IR. Autograd records a derivative computation while forward operators run. Python control flow continues to run as Python.

A compiler **IR** (intermediate representation) is a data structure describing computation so it can be analyzed and transformed. A **guard** checks that assumptions used when compiling still hold on a later call. A **graph break** ends a captured region so execution can continue outside it. **Fake execution** predicts tensor properties without computing their numeric contents.

`torch.compile` must recover larger compilable regions from that existing programming model. It therefore has machinery for Python bytecode, guards, graph breaks, tensor subclasses, fake execution, mutation, aliasing, and an operator ecosystem. FX, ATen graphs, symbolic expressions, Inductor loop IR, and generated Triton/C++ are different representations with different responsibilities. There is no universal PyTorch counterpart of “all the PatternMatchers over UOps.” See [Dynamo](../../../pytorch/torch/_dynamo), [AOTAutograd](../../../pytorch/torch/_functorch/aot_autograd.py), and [Inductor IR](../../../pytorch/torch/_inductor/ir.py).

These are architectural observations, not proof that the maintainers chose every abstraction for this reason. The practical tradeoff is visible in the source: tinygrad makes a small shared graph vocabulary a useful place to intervene; PyTorch makes compatibility with eager semantics and independently registered operators a central constraint. PyTorch can also implement eager operators in a DSL: [torch._native](../../../pytorch/torch/_native/README.md) explicitly requires dispatcher registration. “Eager” does not imply “only hand-written C++,” and “compiled” does not imply “everything becomes a newly generated kernel.”

| Question | tinygrad reading target | PyTorch reading target |
|---|---|---|
| What does this tensor expression mean? | Tensor method and the UOp it constructs | Python API, ATen schema, dtype/layout/aliasing behavior |
| How does a backend get selected? | Device, renderer, runtime, supported ops | Dispatcher key set, registration, fallback, backend implementation |
| Why did it specialize? | Shape/schedule/codegen decisions | Dynamo guards, symbolic shape constraints, backend specialization |
| Why are there two launches? | Realization/scheduling, kernel boundary, local lowering | Captured region boundary, decomposition, Inductor scheduling, external call boundary |
| Where is gradient computation? | Tensor differentiation machinery and resulting graph | Eager autograd nodes or AOTAutograd capture/partitioning |
| Where is an optimization rule? | Relevant UOp PatternMatcher and pass ordering | Decomposition, FX pattern pass, symbolic simplification, scheduler predicate, template choice, or backend kernel |

## Root directory map

The links are local source entries at the pinned checkout. “Contract” names the obligation a caller relies on; “edge” names a common source-reading or extension mistake.

| Directory / source entry | Why it exists; contract | Sharp edge / when to read |
|---|---|---|
| [torch/](../../../pytorch/torch) | Python API plus C++ frontend/bindings and compiler infrastructure; user-visible Tensor behavior ties these together. | The Python function you find may only bind a generated C++ method; follow its schema rather than assuming its body is the implementation. |
| [aten/](../../../pytorch/aten) | Tensor operator library: schemas, metadata logic, dispatcher, native CPU/accelerator kernels, library adapters. | One ATen op can be composite or launch multiple kernels. An op boundary is not a GPU kernel boundary. |
| [c10/](../../../pytorch/c10) | Shared runtime primitives: tensor/storage representation, dispatch keys, devices, streams, allocators, intrusive ownership, symbolic integers. | `c10` is not a graph optimizer. A storage lifetime or dispatch-key error generally cannot be fixed by an FX rewrite. |
| [torchgen/](../../../pytorch/torchgen) | Parses schemas and generates consistent C++ operator APIs/registrations, functionalization and backend plumbing. | Many files searched in build output do not exist in a fresh clone. Edit the declarative input/template, not generated output. |
| [functorch/](../../../pytorch/functorch) | Compatibility package, transform-related developer material, examples, and experimental pieces. | Core implementations also live in `torch/_functorch`, ATen functorch, and C++ bindings. This root alone is not the transform stack. |
| [caffe2/](../../../pytorch/caffe2) | Retained infrastructure, notably serialization plus utility/performance/build components. | The historical name does not mean contemporary eager dispatch is a Caffe2 net executor. Follow actual call sites. |
| [android/](../../../pytorch/android) | Android packaging, JNI-facing integration, tests and build support. | Platform artifacts and referenced dependencies are separate from the Python wheel; this is not the current compiler's primary entry point. |
| [binaries/](../../../pytorch/binaries) | Standalone C++ utility entry points. | Utility availability depends on build configuration. A checked-in executable source does not imply it is installed. |
| [benchmarks/](../../../pytorch/benchmarks) | Workloads and harnesses for compiler, operator, model and other performance investigations. | A benchmark may require optional packages or hardware; a timing without warmup/compile attribution is misleading. |
| [test/](../../../pytorch/test) | Behavioral, gradient, dispatch, compiler, distributed and device regression contracts. | Test parametrization carries dtype/device/layout coverage absent from a single successful example. Some require build-generated modules. |
| [tools/](../../../pytorch/tools) | Build/developer automation, autograd/Python binding generation, linting, packaging, CI helpers. | `tools/autograd/derivatives.yaml` is runtime-relevant specification despite living under “tools.” |
| [cmake/](../../../pytorch/cmake) | Dependency discovery, platform/toolchain selection and build fragments. | A dependency appearing here does not mean it was enabled in an installed binary. |
| [scripts/](../../../pytorch/scripts) | Operational build/release/platform scripts. | Historical and platform-specific flows coexist; do not treat any arbitrary script as the supported local build procedure. |
| [docs/](../../../pytorch/docs) | API and developer documentation sources. | Documentation describes intended contracts; source and tests determine exact snapshot behavior. |
| [mypy_plugins/](../../../pytorch/mypy_plugins) | Static typing integration for patterns ordinary typing cannot express cleanly. | A type-checking rule is not runtime dispatch or tracing behavior. |
| [third_party/](../../../pytorch/third_party) | Vendored code, dependency glue, patches and Git submodule mount points. | `--depth=1` does not initialize submodules. Inspect [.gitmodules](../../../pytorch/.gitmodules) and actual populated paths before claiming to have reviewed dependencies. |

Root files also matter: [setup.py](../../../pytorch/setup.py), [CMakeLists.txt](../../../pytorch/CMakeLists.txt), and [pyproject.toml](../../../pytorch/pyproject.toml) govern packaging/build; BUCK and `.bzl` files describe another build graph. Hidden directories `.ci`, `.github`, `.devcontainer`, `.spin`, `.vscode`, `.claude`, and `.ctags.d` are CI/developer/editor support, not additional tensor execution stages; `.git` is checkout metadata. This map does not audit their individual workflows.

The submodule list includes such dependencies as Gloo, TensorPipe, Kineto, FBGEMM, XNNPACK, CUTLASS, Composable Kernel, AITER, FlashAttention, and MSLK. Their role is not interchangeable: collectives/transport, profiling, CPU/quantized kernels, and accelerator kernel libraries solve different problems. Reading PyTorch's call sites tells you the integration contract; it does **not** give you the full dependency implementation. PyTorch's Triton integration is likewise not a copy of the complete Triton compiler in this repository.

## Python API, model state, and tensor semantics

A training program needs to remember more than temporary arrays. A layer owns trainable parameters and other state; an optimizer updates selected parameters; differentiation determines those updates; saving a model must preserve its state. Those responsibilities motivate `nn`, `optim`, `autograd`, and serialization. Other packages organize operations by mathematical domain or add tensor types whose storage rules differ from ordinary dense arrays.

A **parameter** is a tensor registered as trainable model state. A **buffer** is other registered tensor state, such as running statistics. A **hook** is a callback at a defined execution point. **Autocast** chooses numeric precision per operation; **gradient scaling** rescales the loss/gradients to help avoid low-precision underflow. A **transform**, such as `vmap`, applies a change to a function's execution: `vmap` evaluates a batch of function inputs through batching rules.

| Package / entry | Why and contract | Sharp edge / useful example |
|---|---|---|
| [torch/__init__.py](../../../pytorch/torch/__init__.py), [_tensor.py](../../../pytorch/torch/_tensor.py), [functional.py](../../../pytorch/torch/functional.py) | Public exports, Tensor Python behavior and Python-level composite interfaces. | An API can be imported from `_C`, dynamically generated, or a Python composition. `rg 'def add'` does not find the entire add path. |
| [_C/](../../../pytorch/torch/_C), [_C_flatbuffer/](../../../pytorch/torch/_C_flatbuffer) | Typing surfaces for binary extension modules. | `_C` source stubs are not the executable dispatcher. Extension implementation belongs under `csrc`, ATen and c10. |
| [nn/](../../../pytorch/torch/nn), [Module](../../../pytorch/torch/nn/modules/module.py), [functional](../../../pytorch/torch/nn/functional.py) | Model hierarchy, parameters/buffers, training flags, state dictionaries, hooks; functional APIs and layers. | `module(x)` invokes hook/compiled-call machinery; directly invoking `forward` bypasses parts of that contract. A Module is not inherently a fused kernel or compiler region. |
| [optim/](../../../pytorch/torch/optim), [optimizer.py](../../../pytorch/torch/optim/optimizer.py) | Stateful parameter updates, parameter groups, hooks and serialization. | Optimizer state and parameter identity matter; replacing a Parameter after constructing the optimizer can leave the optimizer pointing at the old object. |
| [autograd/](../../../pytorch/torch/autograd), [function.py](../../../pytorch/torch/autograd/function.py) | Python interfaces to differentiation, custom backward definitions, saved tensors and gradient mode. | A mathematically correct derivative is insufficient if mutation, saved-tensor lifetime, higher derivatives, or transform support are wrong. |
| [amp/](../../../pytorch/torch/amp) | Autocast and gradient scaling policy. | Autocast is per-op execution policy, not simply changing every parameter and intermediate to one dtype. |
| [linalg/](../../../pytorch/torch/linalg), [fft/](../../../pytorch/torch/fft), [special/](../../../pytorch/torch/special), [signal/](../../../pytorch/torch/signal) | Domain-organized APIs backed by native/composite implementations. | Check dtype, device, numerical conventions and vendor-library selection before attributing behavior to a generic elementwise kernel. |
| [distributions/](../../../pytorch/torch/distributions) | Probability distributions, sampling, transforms and log probabilities built over tensor ops. | `sample` versus `rsample` encodes different differentiation contracts; equivalent output shapes do not imply equivalent gradients. |
| [sparse/](../../../pytorch/torch/sparse), [nested/](../../../pytorch/torch/nested), [masked/](../../../pytorch/torch/masked) | Non-dense/ragged/masked tensor semantics and operations. | A dense implementation cannot assume strides, storage, and supported operations transfer unchanged. Layout and dispatch keys are part of semantics. |
| [foreach/](../../../pytorch/torch/foreach) | List-of-tensors operations with accelerated multi-tensor implementations or per-tensor fallbacks. | The package docstring explicitly says a call does not guarantee a single/fused kernel. This is important for optimizer launch counts. |
| [func/](../../../pytorch/torch/func), [_functorch/](../../../pytorch/torch/_functorch) | Functional transforms such as vectorization/differentiation, functionalization and AOTAutograd internals. | Stateful mutation and randomness need transform-specific rules; “works in eager” does not imply “works under vmap.” |
| [_numpy/](../../../pytorch/torch/_numpy) | NumPy-shaped API behavior over torch tensors. | Compatibility includes promotion, scalar and indexing semantics, not just renaming operators. |
| [ao/](../../../pytorch/torch/ao), [quantization/](../../../pytorch/torch/quantization) | Quantization, associated modules/tooling, pruning and compatibility APIs. | Observer/calibration state, graph transformations and backend operator support are separate pieces. A quantized dtype alone is not an end-to-end lowering. |
| [serialization.py](../../../pytorch/torch/serialization.py), [package/](../../../pytorch/torch/package) | Tensor/object checkpoint persistence and packaged Python resources. | A state dictionary, packaged program, exported graph and compiled artifact preserve different things. Loading weights does not recreate arbitrary Python model logic. |

## Compiler and extension packages

To optimize several eager calls together, PyTorch first needs a representation of them. Dynamo captures supported Python execution into **FX**, a graph structure whose nodes describe calls and dependencies. **AOTAutograd** prepares forward/backward graphs for compilation. **Functionalization** represents mutation and views in a form a compiler can reason about while preserving their visible effects. Inductor then chooses loops, buffers, and generated code or library calls.

A **decomposition** expresses one operator using simpler ones. This can make its internals available to a compiler, at the cost of losing the original high-level boundary. A custom operator presents the opposite problem: eager may have code to execute it, while capture still needs a way to predict its output metadata and training needs its derivative. The extension packages supply those additional interfaces.

| Package / entry | Why and contract | Sharp edge / where it differs from a tinygrad PM |
|---|---|---|
| [compiler/](../../../pytorch/torch/compiler) | Public controls and introspection for compilation behavior. | The public control surface is deliberately smaller than `_dynamo` and `_inductor`; underscored APIs are implementation seams. |
| [_dynamo/](../../../pytorch/torch/_dynamo) | Captures Python execution into FX regions using bytecode interpretation and guards. | A guard protects assumptions about future calls; it is not a simplification rule. A graph break changes available optimization scope. |
| [fx/](../../../pytorch/torch/fx), [graph.py](../../../pytorch/torch/fx/graph.py) | Graph/Node/GraphModule infrastructure, tracing, graph manipulation and symbolic-shape machinery. | FX nodes can call high-level Python functions or low-level ATen overloads. “It is FX” does not specify its operator vocabulary. |
| [_subclasses/](../../../pytorch/torch/_subclasses), [fake_tensor.py](../../../pytorch/torch/_subclasses/fake_tensor.py) | Tensor subclasses and metadata-only simulation for capture/analysis. | Fake execution must model shape, stride, dtype, device and aliasing; it cannot obtain arbitrary data-dependent results from real tensor contents. |
| [_decomp/](../../../pytorch/torch/_decomp) | Operator decompositions used by particular graph consumers. | Registration in a table is not proof every compiler pass uses that table. Decomposition trades opaque semantic structure for operations a consumer handles. |
| [_refs/](../../../pytorch/torch/_refs), [_prims/](../../../pytorch/torch/_prims), [_prims_common/](../../../pytorch/torch/_prims_common) | Python reference formulations, primitive operations, and shared shape/promotion/type logic. | These are related layers, not three names for one IR. A reference can expose promotion/broadcasting that a kernel implements implicitly. |
| [_higher_order_ops/](../../../pytorch/torch/_higher_order_ops) | Operations whose arguments/semantics include subgraphs: control flow, transforms, wrapped calls. | A conditional with subgraphs is not interchangeable with Python branching specialized away during tracing. |
| [_inductor/](../../../pytorch/torch/_inductor) | Backend graph lowering, loop/buffer IR, fusion scheduling, code generation, autotuning and runtime wrappers. | An FX pattern match, an IR lowering, a scheduler fusion decision and a template selection solve different questions. Follow [the fusion map](inductor-and-fusion.md#inductor-and-fusion). |
| [export/](../../../pytorch/torch/export), [_export/](../../../pytorch/torch/_export) | Public ExportedProgram interface and capture/serialization/constraint support. | Export must preserve an explicit graph/input contract. Dynamo's ability to fall back to Python around graph breaks is not an export guarantee. |
| [onnx/](../../../pytorch/torch/onnx) | Translation/export to the ONNX ecosystem. | ONNX operator semantics and supported versions form another contract; this is not the ordinary Inductor path. |
| [jit/](../../../pytorch/torch/jit) | TorchScript scripting/tracing, serialization and associated interfaces. | TorchScript and `torch.compile` coexist in the tree; finding a JIT fusion pass does not establish that Dynamo/Inductor invokes it. |
| [_lazy/](../../../pytorch/torch/_lazy) | Lazy Tensor backend interfaces and diagnostics. | This optional subsystem is not the execution model of ordinary eager torch, nor the normal Inductor IR. |
| [_dispatch/](../../../pytorch/torch/_dispatch), [_ops.py](../../../pytorch/torch/_ops.py) | Python-side operator handles and dispatcher support/control. | Enumerating Python-created OpOverloads does not enumerate every registered C++ operator: handles are populated lazily. |
| [_library/](../../../pytorch/torch/_library), [_custom_op/](../../../pytorch/torch/_custom_op), [library.py](../../../pytorch/torch/library.py) | Operator extension machinery: schemas, implementations, fake behavior, autograd and related support. | Registering a CPU/CUDA body alone does not supply fake metadata or a backward formula. Aliasing/mutation declarations must match reality. |
| [_native/](../../../pytorch/torch/_native) | Native operators/overrides implemented in Python and DSLs, selected by predicates through dispatcher integration. | Eager override routing and compile/export decomposition integration are distinct. At this snapshot `native_decomp_table()` explicitly opts consumers into overrides; imports do not silently change every compiler's table. |
| [_awaits/](../../../pytorch/torch/_awaits) | Bindings around an awaitable object facility. | Do not infer this is a general Python async executor or the scheduler for all CUDA work. Read the concrete users before adopting it as a synchronization model. |
| [nativert/](../../../pytorch/torch/nativert) | Namespace placeholder in this checkout (the `__init__.py` is empty). | An evocative directory name is not evidence of a complete locally available runtime implementation. |

### Why `_native` deserves attention in this snapshot

Its [README](../../../pytorch/torch/_native/README.md) and [registry](../../../pytorch/torch/_native/registry.py) specify a concrete extension boundary. A registered override has a predicate and implementation; matching eager calls route to the implementation, and unmatched calls fall through to the original kernel. Registration must avoid importing DSL runtimes or initializing CUDA as a side effect of `import torch`. That constraint exists because import is part of an application lifecycle, including process creation, not just compilation.

For compile/export, a backend eager registration is insufficient: captured graphs can retain the original `aten` operator without executing the eager backend implementation. `native_decomp_table()` exposes the alternate route to consumers. A mutating override may also need its functional counterpart registered because capture functionalizes mutation. This is a particularly clear counterexample to the assumption that a single pattern rule can control eager, export and compilation everywhere.

## Devices, training infrastructure, diagnostics and support

Once arithmetic is correct, a program still needs to move inputs, coordinate work, observe performance, and keep storage alive until devices finish using it. A **stream** orders queued device work; an **event** marks progress. With several training processes, a **rank** identifies a participant, and a **collective** is a coordinated operation such as summing gradients across them. **Sharding** gives different participants different portions of a tensor or state.

These modules exist because those execution obligations cannot be solved by simplifying an arithmetic expression. For example, an accurate kernel timer must measure GPU completion, and a collective must be called by the expected participants in the expected order.

| Package / entry | Why and contract | Sharp edge |
|---|---|---|
| [accelerator/](../../../pytorch/torch/accelerator), [cpu/](../../../pytorch/torch/cpu), [cuda/](../../../pytorch/torch/cuda), [mps/](../../../pytorch/torch/mps), [mtia/](../../../pytorch/torch/mtia), [xpu/](../../../pytorch/torch/xpu) | Device discovery/control, streams/events, allocation and backend-facing APIs. | Asynchronous enqueue is not completion. ROCm builds also use much of the `torch.cuda` API; the namespace name alone does not identify NVIDIA hardware. |
| [backends/](../../../pytorch/torch/backends) | Backend capabilities and policy controls, including library choices and numerical/performance options. | Built support, runtime availability and a selected algorithm are three different facts. |
| [numa/](../../../pytorch/torch/numa) | NUMA-related host execution/placement support. | CPU affinity or memory placement policy is not an operator-level mathematical transformation. |
| [distributed/](../../../pytorch/torch/distributed) | Process groups/collectives, distributed training wrappers, distributed tensors, sharding/checkpointing and RPC-related integration. | Collectives have rank/order/process-group contracts; a locally correct rewrite can violate distributed synchronization or sharding semantics. |
| [multiprocessing/](../../../pytorch/torch/multiprocessing), [futures/](../../../pytorch/torch/futures) | Process helpers, tensor sharing and future abstractions. | Shared storage lifetime and device/process initialization matter. A Python future is not automatically a device completion event. |
| [profiler/](../../../pytorch/torch/profiler), [monitor/](../../../pytorch/torch/monitor) | Execution profiling and monitoring/event/statistics interfaces. | Python/ATen events and accelerator kernels are different levels of the trace; count launches on the device timeline. |
| [_logging/](../../../pytorch/torch/_logging), [_strobelight/](../../../pytorch/torch/_strobelight) | Structured logs and profiling integration, including compiler-time diagnostics. | A compile-time profile measures compiler work, not necessarily generated program throughput. |
| [testing/](../../../pytorch/torch/testing) | Assertions and internal dtype/device/operator test infrastructure. | Internal testing helpers are not a stable public application API. OpInfo coverage is valuable evidence but not a complete proof. |
| [utils/](../../../pytorch/torch/utils) | Data loading, extensions, benchmarking, checkpointing, pytrees, dispatch helpers and many developer utilities. | This is not a homogeneous “misc” module: DataLoader controls execution/process behavior; checkpointing changes saved/recomputed work; dispatch helpers can affect tracing semantics. |
| [contrib/](../../../pytorch/torch/contrib), [legacy/](../../../pytorch/torch/legacy) | Small compatibility/contributed remnants; `legacy/README.md` points readers to pre-0.5 versions for removed legacy code. | Do not reconstruct modern architecture from historical namespace names. |
| [_vendor/](../../../pytorch/torch/_vendor) | Python dependencies copied into the package to control availability/compatibility. | Local copies may differ from the external package release; inspect the vendored version if behavior matters. |
| [headeronly/](../../../pytorch/torch/headeronly) | C++ headers designed to be independent of LibTorch linkage. | Similar-looking helpers can intentionally differ: the README explains header-only error helpers use standard exceptions instead of full c10 error machinery. |
| [lib/](../../../pytorch/torch/lib) | Native support library sources, including shared-memory support; installed distributions also use library locations for binaries. | A source checkout directory is not evidence that runtime shared libraries have been built. |
| [csrc/](../../../pytorch/torch/csrc) | C++ Python bindings, frontend, autograd engine and integration code. | The same feature often has Python policy, C++ binding, ATen implementation and c10 primitives; none of these alone is the complete module. |

## Below Python: c10, ATen, generation and bindings

A Tensor object is not just its numeric array. It needs a shape, a numeric type, a device, a storage reference, and **strides**: the memory step for moving one position along each dimension. A transpose can change strides while sharing the same bytes. Separating tensor metadata from storage ownership makes views possible without copying all elements.

The remaining layers bridge this representation to callable operators. **Bindings** convert Python calls/objects to native C++ calls/objects. A **boxed** call packages values in a generic container; an **unboxed** call uses a typed signature. Both are ways to invoke an operator, not different tensor mathematics. **ABI** means application binary interface: the calling/layout conventions compiled components must agree on. A **symbolic integer**, such as an unknown batch size `B`, lets shape calculations retain an expression instead of forcing one concrete value too early.

Read the table in groups: representation (`c10`), operator declarations/dispatch/implementations (ATen), generation (`torchgen` and `tools/autograd`), then native bindings/support (`csrc`).

| Layer / concrete entry | Abstraction it owns | Reason it is separate; sharp edge |
|---|---|---|
| [c10/core/TensorImpl.h](../../../pytorch/c10/core/TensorImpl.h), [StorageImpl.h](../../../pytorch/c10/core/StorageImpl.h) | Tensor metadata/identity and storage ownership. | Views may share storage while differing in offsets/strides and autograd metadata. “Same bytes” does not imply “same Tensor.” |
| [c10/core/DispatchKey.h](../../../pytorch/c10/core/DispatchKey.h), [DispatchKeySet.h](../../../pytorch/c10/core/DispatchKeySet.h) | Dispatch categories and key-set algebra. | Backend, autograd, Python modes and other functionality interact through priority and redispatch; this is more than `switch(device)`. |
| [c10/core/SymInt.h](../../../pytorch/c10/core/SymInt.h) | Integer API that can retain symbolic quantities. | Converting to a concrete integer may specialize or fail; shape arithmetic is not always ordinary host integer arithmetic. |
| [c10/core](../../../pytorch/c10/core), [c10/util](../../../pytorch/c10/util), [c10/cuda](../../../pytorch/c10/cuda) | Allocators/devices/streams, ownership/errors/utilities, accelerator runtime primitives. | Thread-local state and stream/allocator lifetime are runtime correctness concerns even when the arithmetic is correct. `hip`, `xpu`, `metal`, `mobile`, and `macros` hold platform/support counterparts. |
| [ATen/core/dispatch/Dispatcher.h](../../../pytorch/aten/src/ATen/core/dispatch/Dispatcher.h) | Registration and invocation of typed/boxed operators. | A fallback can intercept many operators; reading only a direct backend registration misses transform behavior. |
| [ATen/core/TensorBase.h](../../../pytorch/aten/src/ATen/core/TensorBase.h), [ATen/core/TensorBody.h](../../../pytorch/aten/src/ATen/templates/TensorBody.h) | C++ Tensor surface and generated method template. | The actual generated TensorBody location in a build is different from the checked-in template. |
| [native/native_functions.yaml](../../../pytorch/aten/src/ATen/native/native_functions.yaml) | Schema, overloads, dispatch declarations, structured delegates and tags. | `add.Tensor`, `add_.Tensor` and `add.out` are distinct contracts with related generation, not accidental duplicate code. |
| [ATen/TensorIterator.h](../../../pytorch/aten/src/ATen/TensorIterator.h), [TensorIterator.cpp](../../../pytorch/aten/src/ATen/TensorIterator.cpp) | Iteration setup for many elementwise/reduction kernels: broadcasting, strides, dtype rules and iteration layout. | It organizes one operator implementation; it does not fuse an arbitrary eager expression across dispatcher calls. |
| [ATen/native](../../../pytorch/aten/src/ATen/native) | Native operator implementations, metadata functions, CPU/CUDA/MPS/XPU/sparse/etc. kernels and library integrations. | `native` includes wrappers and composite algorithms, not only the innermost device loop. |
| [ATen/cuda](../../../pytorch/aten/src/ATen/cuda), [ATen/hip](../../../pytorch/aten/src/ATen/hip), [ATen/cudnn](../../../pytorch/aten/src/ATen/cudnn), [ATen/miopen](../../../pytorch/aten/src/ATen/miopen) | Runtime/library adapters and backend support. | Some CUDA-oriented source is shared/translated for ROCm. Inspect build selection and library calls before claiming a chip-specific path. |
| [ATen/FunctionalTensorWrapper.h](../../../pytorch/aten/src/ATen/FunctionalTensorWrapper.h), [FunctionalizeFallbackKernel.cpp](../../../pytorch/aten/src/ATen/FunctionalizeFallbackKernel.cpp) | Mutation/view bookkeeping for functionalization. | Replacing `add_` with `add` without tracking aliases does not preserve eager semantics. |
| [ATen/functorch](../../../pytorch/aten/src/ATen/functorch) | Dispatch-level transform implementation and batching support. | Vectorizing a function changes dispatch context and dimensional interpretation; it is not always adding a leading dimension to every argument. |
| [torchgen/model.py](../../../pytorch/torchgen/model.py), [gen.py](../../../pytorch/torchgen/gen.py) | Parsed schema model and operator code generation. | The model deliberately uses semantic schema structures before translating to C++ types; this keeps generation invariants explicit. |
| [torchgen/api](../../../pytorch/torchgen/api), [dest](../../../pytorch/torchgen/dest), [gen_functionalization_type.py](../../../pytorch/torchgen/gen_functionalization_type.py) | Translate schemas into API signatures and emitted registrations/wrappers/functionalization code. | A changed alias annotation may alter generated transform plumbing as well as the declaration visible to Python. |
| [tools/autograd/derivatives.yaml](../../../pytorch/tools/autograd/derivatives.yaml), [gen_autograd.py](../../../pytorch/tools/autograd/gen_autograd.py) | Backward formulas and generation of autograd wrappers/functions. | A backend implementation and derivative specification are different extension obligations. Some operators use compositional autograd instead. |
| [tools/autograd/gen_python_functions.py](../../../pytorch/tools/autograd/gen_python_functions.py) | Generated Python operator binding machinery. | Searching for a hand-written definition of each torch function will fail because many are generated. |
| [csrc/autograd/python_variable.cpp](../../../pytorch/torch/csrc/autograd/python_variable.cpp), [engine.cpp](../../../pytorch/torch/csrc/autograd/engine.cpp) | Python Tensor binding and backward execution engine. | Backward scheduling is a graph executor for derivative work, not proof forward eager operations were lazily deferred. |
| [csrc/api](../../../pytorch/torch/csrc/api), [csrc/utils](../../../pytorch/torch/csrc/utils), [csrc/tensor](../../../pytorch/torch/csrc/tensor) | C++ frontend, Python/C++ conversion helpers and tensor-facing integration. | C++ frontend modules are related to the Python API, but their source organization and language boundary are distinct. |
| [csrc/dynamo](../../../pytorch/torch/csrc/dynamo), [csrc/inductor](../../../pytorch/torch/csrc/inductor), [csrc/functorch](../../../pytorch/torch/csrc/functorch) | Performance-sensitive/native support for capture, generated-code integration and transforms. | The compiler is not entirely Python simply because its most readable entry points are. |
| [csrc/jit](../../../pytorch/torch/csrc/jit), [csrc/lazy](../../../pytorch/torch/csrc/lazy), [csrc/export](../../../pytorch/torch/csrc/export), [csrc/onnx](../../../pytorch/torch/csrc/onnx) | Separate graph/runtime/export subsystems and integrations. | Trace the caller to determine which stack is active; multiple generations of graph infrastructure coexist. |
| [csrc/distributed](../../../pytorch/torch/csrc/distributed), [csrc/profiler](../../../pytorch/torch/csrc/profiler), [csrc/stable](../../../pytorch/torch/csrc/stable) | Native collective/runtime integration, profiler plumbing and stable interface support. | ABI, process/rank coordination and observability are real contracts outside arithmetic IR. |

Other `csrc` directories visible in this snapshot (`acc`, `cpu`, `cuda`, `mps`, `mtia`, `xpu`, `functionalization`, `fx`, `instruction_counter`, `monitor`, `multiprocessing`) contain the corresponding backend/binding/support seams. This naming map is not a claim that each directory received a file-by-file review. ATen's remaining library/platform directories likewise require demand-driven study; use the schema and actual registration to choose a path before opening a hardware-specific kernel.

## Worked reading exercises

### 1. Why is `add` declared three times?

**Task.** Read `add.Tensor`, `add_.Tensor`, and `add.out` around line 541 of [native_functions.yaml](../../../pytorch/aten/src/ATen/native/native_functions.yaml). Explain the duplication and give a case where substituting one for another is incorrect.

**Answer.** First separate numerical results from storage effects. `add.Tensor` returns a new result, `add_.Tensor` writes to `self`, and `add.out` writes the supplied destination. `(a!)` names alias set `a` and marks it mutable with `!`: the result/input relationship matters to callers holding another view of that storage. It is not a Python type hint. The functional and in-place declarations use `structured_delegate: add.out`; the out variant owns structured metadata/implementation organization.

Next ask why the declarations share a delegate. Their common implementation machinery avoids duplicating all shape/setup logic while preserving distinct APIs. For `v = x.view(-1); x.add_(1)`, `v` observes the mutation. Replacing the update with `x = x + 1` leaves `v` referencing the old storage. A compiler can functionalize this program only while preserving those observable alias effects.

**Next source.** [torchgen's functionalization generator](../../../pytorch/torchgen/gen_functionalization_type.py) and [FunctionalTensorWrapper](../../../pytorch/aten/src/ATen/FunctionalTensorWrapper.h). Do not stop at the arithmetic `+` inner loop.

### 2. A custom eager operator works; why does capture fail?

**Task.** A custom operator `study::row_scale(x, s) -> Tensor` returns `x * s[:, None]` for `x[B,H]` and `s[B]`, with no mutation or aliasing. You have a registered backend implementation. What else must be checked before expecting `torch.compile` training to work?

**Answer.** Check three separate capabilities. First, the schema must actually match non-aliasing behavior. Second, fake execution needs output shape/stride/dtype/device behavior without reading tensor data, via a suitable fake implementation where required. Third, training needs a correct registered autograd formula or supported compositional path. Here `grad_x = grad_y * s[:, None]`, and `grad_s = (grad_y * x).sum(dim=1)` under the stated real-valued, matching-dtype assumptions.

Now ask a separate performance question. A backend can retain an opaque custom-op call instead of fusing through it; fusion needs an appropriate decomposition/lowering or explicitly supported kernel integration. Thus “compile accepts the op” and “Inductor fuses through the op” are different tests.

**Next source.** [torch.library](../../../pytorch/torch/library.py), [_library/custom_ops.py](../../../pytorch/torch/_library/custom_ops.py), and [_library/fake_impl.py](../../../pytorch/torch/_library/fake_impl.py). Extend the exercise to broadcasting and complex dtypes before calling the derivative general.

### 3. Does an `nn.Module` boundary explain an RMSNorm kernel boundary?

**Task.** A module computes `r = x * rsqrt(mean(x*x, dim=-1, keepdim=True) + eps); y = r * w`, followed by another module computing `y @ W`. Determine which directory can answer “will RMSNorm and matmul become one launch?”

**Answer.** First identify what a Module promises: it organizes state and calls. `nn/modules/module.py` answers module call, state and hook behavior, not the final kernel plan. In eager, follow each functional/operator call and its backend; a dedicated RMSNorm API may choose a native implementation different from this explicit composition.

For compiled execution, determine whether Dynamo captures both modules in one region, which operators/decompositions reach Inductor, whether the normalized tensor is materialized, and whether the chosen matmul implementation permits producer integration. A common FX region only makes an optimization visible; it does not guarantee a single launch. An opaque library matmul call and a generated matmul template have different integration opportunities. Reduction synchronization and normalized-value reuse also matter.

**Next source.** [The execution and scheduling walkthrough](inductor-and-fusion.md#inductor-and-fusion). The right proof is a generated schedule/code and launch trace for a concrete shape/device/version, not a count of Python modules or FX nodes.

### 4. Can eager and compile select different `_native` implementations?

**Task.** You register an eager backend override for an ATen op using `_native`, then see the original ATen op in an exported graph. Is this necessarily a capture bug?

**Answer.** No. Eager backend dispatch and export capture are different consumers. Export can record the ATen schema without executing its backend implementation. At this snapshot the registry offers `native_decomp_table()` to make selected overrides visible to consumers that opt into that table; it deliberately avoids mutating every global compiler decomposition table. The predicate runs against FakeTensors during decomposition, so reading `.item()` or depending on backend data will not reproduce an eager predicate safely. A mutation override may also disappear into its functional counterpart before that stage. Follow [the explicit contract](../../../pytorch/torch/_native/README.md), not an assumption that every registration controls all paths.

### 5. Where would you implement a new accelerator?

**Task.** Explain why “write an Inductor renderer” does not by itself provide a complete PyTorch backend.

**Answer.** Start with a single eager call: it must allocate values on the accelerator and invoke working device code. Ordinary eager calls still need device/runtime integration and operator coverage through registrations, compositional implementations or fallbacks. Allocation, streams/events, copies and Tensor representation must behave coherently. Autograd/fake/functionalization support must fit the intended feature set.

Then consider captured regions. An Inductor codegen backend adds compilation of supported captured regions and wrapper/runtime launch integration. Conversely, registering eager kernels alone does not automatically teach Inductor to generate fused kernels. Read [DispatchKey](../../../pytorch/c10/core/DispatchKey.h), [torchgen/gen_backend_stubs.py](../../../pytorch/torchgen/gen_backend_stubs.py), [torch.library](../../../pytorch/torch/library.py), and [Inductor codegen](../../../pytorch/torch/_inductor/codegen) as separate seams. This is a contract checklist for reading, not a claim that every accelerator must implement every transform before any operator can run.

### 6. Why can `torch.foreach` make an optimizer faster without `torch.compile`?

**Task.** An optimizer updates 100 parameter tensors. Compare one Python operator call per tensor with a list-of-tensors operation. Does the latter prove there is one launch?

**Answer.** The list API gives an implementation several independent tensors at once, enabling a multi-tensor kernel and reducing overhead when the inputs satisfy its requirements. It may also take a semantically equivalent per-tensor fallback; the [package docstring](../../../pytorch/torch/foreach/__init__.py) explicitly rejects a single/fused-kernel guarantee. This is batching several operator instances inside an eager implementation, not a whole-program compiler discovering arbitrary fusion. To verify, inspect input grouping/device/dtype eligibility and the selected implementation, then a device trace. It is another reason eager-versus-compiled is not synonymous with unfused-versus-fused.

## Reading order that follows one real program

1. Pick the exact API and overload, input shapes, dtype, layout and device. Start with `nn/functional.py` or the Tensor method, then `native_functions.yaml`. Write down mutation/aliasing and output metadata before performance expectations.
2. Follow eager registration to backend implementation and library calls; read TensorIterator or the selected specialized kernel only when it is on that path. Add the autograd formula/engine if training matters.
3. Run the same conceptual program through the [capture map](torch-compile.md#torch-compile): guards, graph breaks, fake metadata and AOTAutograd/functionalization establish the backend's input contract.
4. Read [Inductor lowering and scheduling](inductor-and-fusion.md#inductor-and-fusion) to locate real materialization and launch boundaries. Keep library calls distinct from generated kernels.
5. Return to surrounding packages only for an observed contract: Module hooks/state, tensor subclasses, distributed sharding, checkpointing/recomputation, precision policy or serialization.

This ordering makes the large tree useful: every abstraction has an obligation to investigate, and every claim about fusion ends at an implementation artifact rather than a directory name.
