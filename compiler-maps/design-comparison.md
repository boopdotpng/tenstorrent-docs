# How these systems differ from tinygrad

The easiest way to compare these systems is to ask what problem each starts with. **Tinygrad starts with tensor expressions waiting to run. PyTorch eager starts by running each tensor call. MLIR supplies tools for building a compiler; IREE and TT-MLIR use those tools to build particular compiler/runtime systems.** `torch.compile` adds a compiler path to an existing PyTorch program, so it must preserve behavior the eager program already exposes.

For example, consider `y = (x * x).sum()`. Tinygrad can collect the multiplication and sum before choosing executable work. PyTorch eager ordinarily executes those tensor calls as Python reaches them. `torch.compile` can capture a region containing both so a backend can optimize them together. MLIR can represent and transform the calculation, but the compiler using MLIR must choose how to turn it into executable work. IREE supplies such a compilation and runtime path; TT-MLIR supplies routes suited to Tenstorrent libraries and hardware.

This page compares those responsibilities rather than ranking the projects by size or speed. Start with the [shared first-principles guide](first-principles.md) if terms such as graph, lowering, kernel, or runtime are unfamiliar. Here **lowering** means replacing a high-level computation with a more concrete implementation; a **kernel** is an executable unit of computation (including a generated CPU function in these experiments), while a **launch** submits work for execution. A graph of tensor operations is not automatically a graph of kernel launches.

“Philosophy” below means a design tradeoff visible in source, not a claim about the authors' motives. This comparison uses the source revisions in [the snapshot index](README.md#source-snapshots-not-a-claim-about-todays-upstream), plus PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. Source links use local checkouts, so consult those pins if the checkout moves. This document is a source review, not a cross-framework benchmark or a claim that all examples have been executed.

## First distinguish the things being compared

Read “starting obligation” as the behavior each project must make work before optimization is useful. **Lazy** execution records work for later; **eager** execution performs operations as the program reaches them. **Autograd** records enough of a computation to compute derivatives later. **Capture** turns a portion of a running Python program into a graph a compiler can inspect.

The table is an overview; the following sections unpack its machinery. **UOps** are tinygrad's graph nodes. **TTNN** is the Tenstorrent operation-library route; **D2M** and **TTKernel** support more explicit device-program construction. **Inductor** is the PyTorch compiler backend discussed here. A **scheduler** decides execution order and grouping; **code generation** emits the implementation.

| System | Starting obligation | Architectural consequence visible in source |
|---|---|---|
| tinygrad | Turn lazy Tensor expressions into executable work | Reuse UOps and pattern rewriting across tensor graphs, kernel graphs, arithmetic lowering, and target preparation; meanings and valid forms change by phase |
| MLIR | Provide infrastructure for defining and transforming different IRs | Dialects define semantics; interfaces expose reusable capabilities; passes and conversions compose a compiler chosen by a downstream project |
| IREE | Compile supported program IR into an executable artifact and runtime protocol | Separate tensor/dispatch partitioning, asynchronous resource scheduling, device interfaces, target executable compilation, and host execution |
| TT-MLIR | Map supported programs onto Tenstorrent software/hardware contracts | Distinguish TTNN library operations from D2M/TTKernel device programs; represent layout, memory, movement, and dispatch obligations |
| PyTorch eager | Execute tensor operations as a Python program runs | Dispatch combines backend and transformation layers; storage aliases and mutations are observable; autograd records execution for backward |
| `torch.compile` with Inductor | Optimize capturable regions while preserving PyTorch behavior | Guards and graph breaks manage capture; functionalization/autograd tracing establish compilable semantics; scheduler/codegen select generated or external kernels |

MLIR is therefore compiler-building infrastructure. To compare its runtime behavior with tinygrad, first choose a concrete compiler built on MLIR and that compiler's runtime. IREE and TT-MLIR are concrete examples of products built using MLIR. Also, `torch.compile` accepts different backends: its Inductor path is the comparison here, not the definition of every possible compiled PyTorch execution.

Source anchors: tinygrad [Tensor realization](../../tinygrad/tinygrad/tensor.py), [UOp/matcher machinery](../../tinygrad/tinygrad/uop/ops.py), and [schedule construction](../../tinygrad/tinygrad/schedule/__init__.py); MLIR [dialect definitions](../../../builds/llvm-project/mlir/docs/DefiningDialects/Operations.md) and [interfaces](../../../builds/llvm-project/mlir/docs/Interfaces.md); IREE [pipeline composition](../../iree/compiler/src/iree/compiler/Pipelines/Pipelines.cpp); TT-MLIR [dialect routes](tt-mlir/README.md#tt-mlir); PyTorch [`compile` API](../../pytorch/torch/__init__.py) and [dispatcher](../../pytorch/aten/src/ATen/core/dispatch/Dispatcher.h).

## One representation versus explicit changes of vocabulary

A **representation** is the data structure a compiler uses to describe the program at one point. Its design determines which questions are easy to ask. An expression graph makes producer/consumer relationships obvious; a loop representation makes iteration order obvious; a launch representation makes device execution boundaries obvious. No single choice makes every question equally explicit.

Tinygrad's UOp structure gives the reader one graph representation and one matcher mechanism to learn. That makes it unusually feasible to inspect the complete path from a Tensor expression to a renderer. It does **not** mean a UOp has one phase-independent interpretation: tensor movement, buffer states, kernel calls, ranges, and low-level instructions have different contracts. A rewrite can preserve the Python node structure while breaking a later pass's assumptions. The [UOp guide](tinygrad/uops-and-rewrites.md#uops-and-rewrites) and [specifications](../../tinygrad/tinygrad/uop/spec.py) identify those contracts.

MLIR makes changes in vocabulary more explicit. Its **dialects** are named families of operations and types within a common IR (intermediate representation). **SSA**, or static single assignment, gives each value one definition; **regions** contain nested code such as function and loop bodies. An **interface** lets a transformation ask a semantic question without naming every operation class. A `tensor` describes array contents as a value; a `memref` describes mutable storage; a `vector` expresses a group of element computations; a target intrinsic exposes a compiler-recognized operation for a target. Those are different promises even when they describe parts of the same calculation. Shared SSA operations/regions provide infrastructure underneath them.

Interfaces allow, for example, a tiling transform to ask an operation how it tiles without knowing every operation class. The price is more definitions, registration, interfaces, type conversions, and phase boundaries to inspect. The benefit is that a downstream compiler can preserve the vocabulary that makes a particular analysis possible. Linalg retains structured array computations, including which indices select elements and which dimensions are summed. Lowering Linalg to scalar loads and arithmetic too early can erase the indexing/iterator structure a later tile-and-fuse transform wants. See [Linalg interfaces](../../../builds/llvm-project/mlir/include/mlir/Dialect/Linalg/IR/LinalgInterfaces.td).

IREE's Flow, Stream, HAL (hardware abstraction layer), and VM (virtual machine) add vocabularies for questions a local arithmetic graph does not answer: where a dispatch boundary is, how resources remain live while work is asynchronous, what device interface is required, and how the host program invokes it. A **dispatch** invokes device work with inputs and outputs. **Asynchronous** work may continue after the host has submitted it, so storage must remain valid until completion. Flow chooses device-work boundaries, Stream represents resource use and dependencies, HAL describes device-facing execution, and VM represents host-side program execution in the typical route. See the [IREE walkthrough](iree/README.md#iree--follow-one-program-through-the-compiler).

PyTorch deliberately has more than one representation: eager Tensor/storage/dispatcher state, Dynamo's Python execution model, FX graphs, functionalized operator graphs, and Inductor loop/buffer/scheduler representations. These representations solve different problems. **Dynamo** captures Python execution into **FX**, PyTorch's graph representation. **Functionalization** expresses mutations as value updates for compiler analysis. **Inductor** lowers the graph toward loops, buffers, and executable code. **ATen** is PyTorch's tensor-operator layer. An FX graph can say which ATen operation occurs without deciding iteration order, buffer reuse, or GPU launch geometry. See [FX graph](../../pytorch/torch/fx/graph.py), [functional tensors](../../pytorch/torch/_subclasses/functional_tensor.py), and [Inductor IR](../../pytorch/torch/_inductor/ir.py).

## A tinygrad PM is not simply an MLIR pass

A **pattern** recognizes part of a program and proposes a replacement: for example, simplifying integer `x + 0` to `x`. A **rewrite driver** decides where and when to try patterns. A **pass** is a unit of compiler work and may do much more than apply patterns. **PM** in the tinygrad docs means `PatternMatcher`; its name alone does not tell you the whole transformation stage.

In tinygrad, `PatternMatcher` stores ordered candidates per root operation and returns the first replacement that is neither `None` nor the original node. Matchers compose by concatenating their rule lists. The graph rewrite driver supplies traversal/revisiting; pipeline placement supplies the phase contract. Understanding a rule therefore requires its earlier rules, callback guards, traversal, and downstream expectations. This explains why reading a pattern literal alone often fails to explain its purpose. See [the implementation](../../tinygrad/tinygrad/uop/ops.py) and [individual rules](tinygrad/rules/README.md).

MLIR separates a **pattern**, a **rewrite driver**, and a **pass**. A pass can invoke a greedy pattern driver, an analysis, a procedural transform, or dialect conversion. **Canonicalization** seeks simpler equivalent forms. **Conversion** additionally specifies which operations and types the next stage accepts, its **legality contract**, and often translates types. For example, a backend may require every high-level matmul to become loops or a supported library call; leaving a matmul untouched is then a failure even if no simplification applies.

A full conversion succeeds only when all remaining operations meet the target's legality requirements. Partial conversion has different acceptance rules. This is a useful distinction from “keep rewriting until no pattern matches”: a **fixed point** (a state where no rule changes the program) can still contain operations the next stage cannot handle. See [PatternRewriter](../../../builds/llvm-project/mlir/docs/PatternRewriter.md), [canonicalization](../../../builds/llvm-project/mlir/docs/Canonicalization.md), and [dialect conversion](../../../builds/llvm-project/mlir/docs/DialectConversion.md).

Inductor also uses graph patterns, but its fusion decision is not exhausted by FX pattern matching. [The scheduler](../../pytorch/torch/_inductor/scheduler.py) reasons about dependencies and backend capabilities. It may tentatively change loops to test a fusion candidate; at this snapshot, `can_fuse` rolls those changes back if the candidate fails. A **stream** orders submitted device work, and a **memory pool** groups allocation resources. Fusion must respect those choices: placement checks can reject different streams or memory pools, and reduction checks can reject incompatible or strict-order reduction combinations. Those are schedule-level obligations, not just algebraic recognition. See [FX pattern machinery](../../pytorch/torch/_inductor/pattern_matcher.py) for the separate graph-rewrite layer.

## RMSNorm: the same formula asks different questions

For the comparison below, **TTIR** is TT-MLIR's tensor-level vocabulary before its library or direct-kernel routes are selected. Tinygrad **rangeification** makes tensor indexing explicit in terms of iteration ranges. Those stage names locate decisions; their existence alone says nothing about how many launches result.

Here RMSNorm rescales each row by the reciprocal square root of its mean squared value, then applies a per-channel weight. Let `x` and `residual` have shape `[B, H]`: B rows of H channels. `gamma` has H weights, and `eps` is a small positive constant. `dim=-1` reduces the H channels; `keepdim=True` retains a length-one channel dimension so the row statistic broadcasts back across the row. A **reduction** combines many input elements into fewer results; **pointwise** work computes an output element from the corresponding input positions.

Use the nontrivial residual form, optionally returning the residual array:

```python
z = x + residual
q = (z * z).mean(dim=-1, keepdim=True)
y = z * (q + eps).rsqrt() * gamma
return y, z
```

For one row, suppose `x=[1,2]`, `residual=[2,2]`, and `gamma=[1,1]`. Then `z=[3,4]`, `q=(9+16)/2=12.5`, and `y` is approximately `[0.8485,1.1314]` if epsilon is temporarily zero. The two y elements share one row statistic. Returning z as well means the program must preserve both that residual array and the normalized array.

The reduction needs every hidden element in its row before the row's scale is ready. `z` has multiple consumers and is externally observable. Removing its output or assuming different GPU workgroups can synchronize with a group-local barrier would change the program. A named RMSNorm operator and this expanded formula may also select different implementation paths, so use the same expression when studying partition decisions.

A GPU **workgroup** is a cooperating set of threads. A **barrier** waits and orders memory access only within its defined scope. A statistic split across workgroups therefore needs more than each group's local barrier. In the table, **partitioning** means deciding which operations execute together and where separate launches remain; a **dispatch site** is an invocation in the program, not merely a reusable kernel definition.

| System | Where to ask “can these otherwise separate kernels become one?” | Evidence to collect |
|---|---|---|
| tinygrad | Kernel graph formation/rangeification and later codegen; compare lazy composition with explicitly realized intermediates | Scheduled calls, each call's buffer inputs/outputs, generated code, numerical result. The existing [CPU probe](tinygrad/rmsnorm-kernel-fusion.md) actually records schedules, including 2 versus 5 kernels for its basic lazy/staged comparison; that is not a count for this new two-output variant |
| MLIR | A selected tile/fuse schedule while structured tensor information remains, followed by bufferization and GPU/CPU lowering | Transformed structured IR, storage decisions, then actual launch/loop structure. One `linalg.generic` or one tiled loop does not by itself prove one GPU launch |
| IREE | DispatchCreation producer/consumer grouping and reduction splitting before target kernels are emitted | Dispatch **sites**, interfaces, Stream resource edges, and target code. Existing [tests](iree/rmsnorm-kernel-fusion.md) show aggressive fusion can group reductions and consumers, while splitting can deliberately create two dispatches |
| TT-MLIR | Distinguish TTIR recognition→TTNN library selection from D2M generic fusion and direct-kernel scheduling | The selected runtime/library route or explicit program stages. The [four-core source example](tt-mlir/rmsnorm-kernel-fusion.md) has partial-sum, all-reduce, and scale stages; their ordering is part of its synchronization strategy |
| PyTorch eager | Ordinary eager execution does not perform a whole-Python-expression fusion pass across these calls | Operator trace and device launch trace separately. Each ATen call may be a view, a composite, one kernel, or multiple kernels; operator count is not kernel count |
| PyTorch compiled | Dynamo capture boundaries, decomposition/lowering, then Inductor scheduler and target codegen | Graph breaks and guards; captured graph; scheduled buffers; generated wrapper/kernel code; actual launches. One captured FX graph may contain several generated kernels and external library calls |

The key difference is **when a global opportunity becomes available**. Tinygrad accumulates lazy work before realization. Eager PyTorch has already performed earlier calls by the time later ones arrive. Dynamo can capture a region so Inductor sees several operations together. IREE gets an input program and chooses dispatch partitions explicitly. MLIR supplies mechanisms for a compiler author to implement such choices; it does not prescribe one partitioner.

Returning `z` prevents eliminating its observable value, but does not categorically prohibit fusion. A fused kernel can have multiple outputs. It may instead recompute `z`, store it once, or retain a boundary. First ask whether a schedule is correct (**legality**), then whether its registers and temporary storage fit the target (**resource usage**), and finally whether it is faster or otherwise preferable (**profitability**). For a large row, an extra partial-reduction kernel can improve parallelism even though it increases launch count. No universal “fewest kernels wins” ranking follows from these designs.

The TT case makes the issue especially concrete: combining partial-sum and all-reduce stages must replace the readiness guarantee formerly supplied by sequential stage execution. The **NoC** is the on-chip network used to move data between cores; a **semaphore** carries synchronization state between participants; a **tile** is a block of array elements handled together. A scalar expression rewrite does not by itself specify how partial tiles travel, when all contributors are ready, or when their storage can be reused. On Tensix, one dispatched program may still contain several cooperating compute/data-movement kernel functions. See the [TT fusion exercise](tt-mlir/rmsnorm-kernel-fusion.md#how-to-prove-useful-inter-kernel-fusion).

## Mutation: where a small algebraic rewrite becomes a semantic bug

An **alias** is another reference to the same storage. A **view** changes how that storage is indexed without necessarily copying it. **Mutation** changes the stored values, so aliases can observe the change. This is why replacing an array program with equivalent-looking algebra can be wrong.

Consider this PyTorch forward example without autograd. The trailing underscore in `add_` marks an in-place operation:

```python
def f(x):
    alias = x.view(-1)
    old_sum = x.sum()
    x.add_(1)
    new_sum = alias.sum()
    return old_sum, new_sum
```

Trace it in order for input `[2., 3.]`. `view` creates another way to index the same two elements. The first sum reads 2 and 3, producing 5. `add_` changes those elements to 3 and 4. The second sum reads them through `alias`, producing 7. The result is `(5., 7.)` and the caller's tensor becomes `[3., 4.]`. `alias` observes the same storage. Moving `old_sum` after the write or treating the view as a snapshot is wrong. This is an illustrative semantic oracle, not a claim that it was executed here. With autograd enabled, leaf/view mutation restrictions and saved-value version checks add obligations; do not infer training legality from this no-grad example.

In eager PyTorch, storage aliases and operation ordering make that behavior observable immediately. In compiled PyTorch, functionalization can express mutation using functional tensor updates, but the surrounding machinery must preserve input mutation and output aliases. “Functional graph” does not mean the user's mutation silently disappears. **AOTAutograd** prepares forward and backward computations for compilation and coordinates which intermediate values must be retained for derivatives. The compiled program must still update the caller-visible input and preserve any promised output aliases. Read [functional tensors](../../pytorch/torch/_subclasses/functional_tensor.py) and [AOT runtime wrappers](../../pytorch/torch/_functorch/_aot_autograd/runtime_wrappers.py).

Tinygrad's corresponding compiler problem is ordering reads of an old buffer state against a write that supersedes it. [Schedule construction](../../tinygrad/tinygrad/schedule/__init__.py) explicitly builds read-after-write dependencies and write-after-read dependencies using buffer states and `AFTER` nodes. A lazy graph still needs a memory-effect ordering model. This is a conceptual comparison of the obligations, not a claim that a line-for-line translation of the PyTorch program has identical API semantics.

MLIR tensor SSA makes old and new tensor values distinct: a new value does not retroactively alter an earlier value. **Bufferization** chooses physical storage to implement those value computations. Bufferizing both into the same physical memory is legal only if observations of the old value remain correct. [One-Shot analysis](../../../builds/llvm-project/mlir/lib/Dialect/Bufferization/Transforms/OneShotAnalysis.cpp) checks read-after-write interference before in-place reuse. `memref.subview`, by contrast, is an aliasing memory view; loading from it after a write observes the new memory contents. Tensor value semantics and mutable memory semantics cannot be interchanged just because their shapes match.

IREE extends the storage question into asynchronous execution: the old consumer may still be running after the host submits the write. Resource access and completion dependencies must preserve ordering, and a lifetime cannot end merely because the host has finished issuing commands. Stream represents these obligations before HAL/runtime execution. See [Stream's definition](../../iree/compiler/src/iree/compiler/Dialect/Stream/IR/StreamDialect.td) and [resource review checklist](iree/README.md#iree--contracts-versus-optimization-a-review-checklist-with-teeth).

## Numerical contracts are part of the philosophy too

Floating-point operations round to representable values. That makes the *placement* of arithmetic and casts observable. If one kernel writes a low-precision intermediate and the next reads it, fusion must preserve that rounding unless the program's numerical policy allows a change. A **numerical contract** states those requirements, including which differences are acceptable.

The RMSNorm formula is not a complete floating-point specification. Record input/output types, accumulation type, where conversion occurs, epsilon placement, reduction grouping (which terms are added together first), approximate math choices, and allowed tolerance. Combining kernels can remove an intermediate rounding; splitting a reduction changes its association; recomputation can repeat conversions or math under a different context. Those changes may be allowed by a chosen contract, but cannot be waved away as “the same algebra.”

Tinygrad's [symbolic rewrites](../../tinygrad/tinygrad/uop/symbolic.py) and renderer/codegen rules make individual arithmetic choices; the AMD/IMAGE guides show target/storage constraints that can survive into seemingly strange patterns. MLIR's operation semantics and **fast-math attributes** (explicit permissions to relax certain floating-point requirements) govern allowable arithmetic transformations; a dialect conversion still needs to preserve the source's promised semantics. IREE and TT-MLIR add backend precision/layout/library configuration. Inductor's current fusion gates explicitly include strict reduction ordering checks. Consult [the scheduler](../../pytorch/torch/_inductor/scheduler.py), [Arith operations](../../../builds/llvm-project/mlir/include/mlir/Dialect/Arith/IR/ArithOps.td), and the individual RMSNorm guides before assuming identical answers or reproducibility.

This is why a useful comparison records both the dispatch graph and numerical error. “All outputs are close” does not prove the intended fusion happened; “one launch” does not prove the numerical contract was preserved.

## What adding a backend actually commits you to

A **backend** turns supported computations into work for a target. Emitting an instruction is only one part: the system must allocate its inputs, represent arguments correctly, launch the work, wait for required completion, and expose results. The **ABI** (application binary interface) is the agreement about argument/data representation at compiled-code boundaries. A **calling convention** specifies how a call passes arguments and returns results.

Some terms used below: **DMA** transfers data between memories; a Tenstorrent **CB** (circular buffer) coordinates tile storage between producers and consumers; **serialization** writes an executable artifact into a format a runtime can load. PyTorch **fake/meta** execution computes properties such as shape and dtype without real tensor data. A **decomposition** rewrites an operation using other operations that a compiler already supports.

| System | Local entry point | Work beyond spelling target instructions |
|---|---|---|
| tinygrad | Renderer/compiler support plus device runtime, allocator and program execution; target-specific rewrites where needed | Supported operations/types, launch dimensions, buffer ABI, synchronization, transfers, allocation, caching, and runtime graph support as applicable. See [device](../../tinygrad/tinygrad/device.py), [renderers](../../tinygrad/tinygrad/renderer), and [runtimes](../../tinygrad/tinygrad/runtime) |
| MLIR | Target dialect/conversion, types and interfaces, selected pass pipeline | Binary generation/translation, calling convention, host launch path, runtime, and memory ownership are still required. A dialect alone does not execute anything |
| IREE | HAL target backend plus executable lowering/serialization and compatible runtime support | Executable ABI, bindings, command submission, resource lifetimes, completion, loaders, and compiler/runtime compatibility. See [HAL targets](../../iree/compiler/src/iree/compiler/Dialect/HAL/Target) and [HAL runtime](../../iree/runtime/src/iree/hal) |
| TT-MLIR | Extend the appropriate TTNN or direct-kernel route | TTNN library/configuration support or explicit layout/CB/DMA/compute code; artifact schema/serializer/runtime when adding executable operations. See [target serializers](../../tt-mlir/lib/Target) and [runtime](../../tt-mlir/runtime) |
| PyTorch | Eager operator/backend registrations or a `torch.compile` backend; these are separate extension points | Eager semantics, autograd, aliasing, dtype/layout behavior, and dispatch; for compile, capture compatibility, fake/meta behavior, decompositions/lowerings, generated code/runtime integration, and fallback boundaries |


A custom Dynamo backend can consume an FX graph and hand it to another compiler. That does not automatically implement a full eager device backend. Conversely, an eager custom operator can work while requiring fake implementations and/or compiler handling before it works under capture. The boundary being extended determines the contract. Read [backend registration](../../pytorch/torch/_dynamo/backends/registry.py) together with [dispatcher registration](../../pytorch/aten/src/ATen/core/dispatch/Dispatcher.h).

## Runtime and deployment implications

The **compiler** creates executable work; the **runtime** allocates resources and runs it. **Deployment** asks what must be present where the program runs: Python and the compiler, a compiled artifact and a smaller runtime, or some combination. That question is separate from whether one expression can fuse.

Tinygrad keeps expression construction, compilation, buffers, and execution close enough to follow in one Python codebase. That improves the tractability of whole-stack experiments; it also means a rewrite reader must understand runtime consequences such as realization, transfer, and assignment ordering. TinyJit/runtime graph mechanisms are additional execution features, not evidence that every Tensor expression starts in eager mode. See [execution](../../tinygrad/tinygrad/engine/realize.py) and [JIT](../../tinygrad/tinygrad/engine/jit.py).

IREE makes compilation into a deployable artifact and a runtime ABI explicit. Its typical VM/HAL route can execute without bringing the compiler into the deployment process; alternate inline/loader models also exist. The associated cost is a compiler/runtime compatibility boundary to understand. TT-MLIR likewise has artifact serialization and runtime execution paths, while also exposing JIT and source-export workflows. Neither project's broad runtime architecture can be inferred from its scalar canonicalization rules.

A **guard** checks an assumption used by compiled code, such as a relevant shape or Python value. If an assumption fails, the system may need another compiled version. A **graph break** ends a captured region and allows execution to continue outside it. These mechanisms help preserve Python behavior, but mean one Python function need not become one permanent executable.

Ordinary `torch.compile` is integrated with the Python application's execution, guards, and recompilation/cache behavior. Ahead-of-time export/package routes exist separately; do not treat an ordinary decorated function as a portable standalone deployment artifact. PyTorch eager remains an execution path in its own right and may surround compiled regions. See [`torch.compile`](../../pytorch/torch/__init__.py), [export](../../pytorch/torch/export), and [AOTInductor](../../pytorch/torch/_inductor/__init__.py).

None of these facts establishes a blanket speed ranking. Compile latency, startup, cache behavior, target libraries, shape variation, memory traffic, and deployment constraints can outweigh the local fusion difference. The right comparison holds workload, dtype, target, warmup, synchronization, and measurement scope fixed.

## Are the other maps deep enough?

The existing MLIR, IREE, and TT-MLIR maps support architectural understanding and reading selected lowerings. They are **not equivalent to tinygrad's rule-by-rule reference**. Their strongest detailed material is the RMSNorm/kernel-boundary case studies. Their main remaining gap is running those source-derived examples with matching toolchains. PyTorch adds eager execution and compilation guides, with the source-checkout versus installed-wheel distinction recorded in that map.

| Area | What the current documents establish | What they do not establish |
|---|---|---|
| tinygrad | Production module map; a census and individual explanations/examples for 926 production matcher templates; AMD/IMAGE detail; executed rewrite and CPU RMSNorm probes | Exhaustive execution of all matcher cases, every shape/backend/chip combination, or historical proof of every inferred motivation |
| [MLIR](mlir/README.md#mlir) | IR ownership/SSA/regions, dialects, interfaces, rewriting vs conversion, bufferization, structured scheduling; selected important dialects and a detailed [RMSNorm example](mlir/rmsnorm-kernel-fusion.md) | Every dialect, pattern, or pass individually; a universal MLIR pipeline; executed target lowering of the authored example |
| [IREE](iree/README.md#iree) | Compiler/runtime module atlas, Flow→Stream→HAL→VM obligations, source/test evidence for dispatch fusion and splitting in [RMSNorm](iree/rmsnorm-kernel-fusion.md) | Every target pipeline/rule; reproduction of the cited FileCheck tests; measured dispatch counts or performance for the authored RMSNorm |
| [TT-MLIR](tt-mlir/README.md#tt-mlir) | Library vs direct-kernel routes; dialect/runtime atlas; concrete source-level [three-stage multicore RMSNorm](tt-mlir/rmsnorm-kernel-fusion.md), including limitations | Every dialect/rule; device validation of these examples; proof that a TTNN call corresponds to one physical kernel |
| [PyTorch](pytorch/README.md) | Companion maps cover eager dispatch/autograd and the Dynamo→AOTAutograd→Inductor route, with worked examples and source references | Every ATen kernel, decomposition, Dynamo handler, FX rewrite, or Inductor scheduler case; a complete build of this source tree |

For the question “why do these abstractions exist and where would I change this behavior?”, the other maps are useful. For “explain every rule as thoroughly as tinygrad,” the answer is **no**. Inventory inclusion is not individual review. A useful next depth target is one complete pipeline per system, with its intermediate IR and runtime evidence, rather than attaching generic explanations to thousands of unrelated rewrite definitions.

## CAIR: a sequence of comparative exercises, with answers

These are source exercises unless a matching executable environment is explicitly supplied. The linked system-specific exercise banks add implementation tasks.

### 1. Rewriting stops with an unsupported operation

A pass reaches a rewrite fixed point but still contains an unsupported operation. Has it succeeded?

**Worked answer:** first identify what the pass promised. A canonicalizer promises best-effort simplification, so having no more applicable simplifications can be an acceptable result. A full MLIR conversion promises an output accepted by its conversion target, so the unsupported operation must be legalized or conversion must fail. In tinygrad, inspect the phase specification and consuming renderer: having no applicable rewrite does not prove that the renderer can emit the remaining node.

For a concrete negative case, leave an operation that has no target lowering in an otherwise simplified graph. A test that checks only “the rewriting loop terminated” misses the bug. Read [MLIR exercises](mlir/README.md#exercises) and [tinygrad rewrite exercises](tinygrad/uops-and-rewrites.md#rewrites-exercises).

### 2. One captured graph versus one kernel

Dynamo captures all of RMSNorm as one FX graph. Has it achieved kernel fusion?

**Worked answer:** capture establishes that a backend can see the operations together. It has not yet selected the execution schedule. Inductor may emit a reduction kernel followed by pointwise work, use an external library call, or fuse some work. Inspect scheduled buffers and the generated wrapper's calls, then collect launch evidence if executing on a device.

The same distinction applies to TT-MLIR: one TTIR RMSNorm operation or one TTNN invocation can invoke several physical kernels. Count at the layer relevant to the claim.

### 3. An intermediate becomes an output

If residual RMSNorm returns `z` as well as `y`, must every compiler retain a separate residual-add kernel?

**Worked answer:** the new requirement is that the caller receives z's values. It does not specify which kernel writes them. A fused kernel can write both z and y; another schedule can retain a boundary or recompute z. Check which users need z, how each obtains it, and whether its storage survives long enough.

The extra output can increase the number of kernel arguments, memory traffic, and live temporary values. Those costs can change whether fusion is worthwhile even when it remains correct. The answer is therefore a dependency and interface analysis, not a universal kernel count.

### 4. A boundary supplied synchronization

Remove the boundary between four-core partial sums and all-reduce, the stage that combines contributions and makes the result available to participating cores. What proof is missing?

**Worked answer:** start with the dependency: every required partial sum must be produced and visible before a consumer reads it. The source example supplied that guarantee through sequential stage ordering. A merged implementation needs a replacement communication and synchronization schedule.

Check that no core reads early, no temporary is overwritten while needed, and no participant waits forever for work that cannot be scheduled. Then validate numerical results and device execution. Merely putting both computations into one program establishes none of those facts. Read [TT-MLIR exercises](tt-mlir/README.md#exercises).

### 5. Equal shapes do not establish safe reuse

Can the compiler reuse the input buffer for RMSNorm output because their shapes agree?

**Worked answer:** shape equality proves the storage could be large enough, not that overwriting it is safe. First ask whether the reduction still needs any original elements. Next ask whether another consumer, alias, or exported residual needs them. Finally ask whether those consumers have actually completed before the write, including asynchronous device work.

A schedule can sometimes make reuse safe. The proof appears in different machinery: tinygrad buffer-state dependencies, MLIR bufferization interference, PyTorch aliases/functionalization, and IREE resource lifetimes. Each must protect the same observable reads.

### 6. More kernels can expose more parallel work

Why can two kernels beat one for a reduction?

**Worked answer:** with only a few rows, assigning one group to each row may leave much of the device idle. A first kernel can split each long row into more independent partial reductions, giving more groups useful work. A later kernel merges the partial results.

The split also adds temporary traffic and launch overhead, and changes floating-point grouping. Compare those costs with the gain in usable parallelism. Test several row counts and widths on the same target, record launches and temporary storage, and compare both runtime and numerical error. Read [IREE's split-reduction evidence](iree/rmsnorm-kernel-fusion.md#source-evidence-d-reduction-splitting-intentionally-adds-a-kernel-boundary).

### 7. Functionalization must preserve mutation

What must the mutation example return after functionalization?

**Worked answer:** repeat the observations in program order: the old sum is 5, the updated values are `[3., 4.]`, and the new sum is 7. The caller must also observe that its input changed. Functionalization changes the compiler's internal representation; it does not change this public contract.

An implementation that returns both correct sums but leaves the caller's input untouched is still wrong. Add autograd only after stating which tensors require gradients and whether that mutation is permitted.

### 8. Locate the failed contract before adding a rule

Which source would you change for a target-specific RMSNorm limitation?

**Worked answer:** follow the computation until the first unmet requirement. Is the tensor expression recognized? Can its operations be lowered? Can the scheduler form a correct partition? Are layout and storage supported? Can code generation emit the instructions? Can the runtime launch and communicate correctly?

In tinygrad, different PMs over UOps can own those requirements. In MLIR-based products, they often span dialects and conversion stages. In PyTorch, a capture or operator-support failure can precede Inductor entirely. Name the responsible stage and a negative test: for example, a row width or layout that used to be rejected or handled incorrectly. “Add a fusion pattern” is only an answer after identifying why a pattern is the missing piece.

For a practical next lab, capture the same residual RMSNorm with and without exported `z`, and with small versus large hidden dimensions. Save the representation immediately before/after partitioning, each launch's inputs/outputs, intermediate storage, and a numerical comparison. Doing that once in each concrete compiler would close a more important coverage gap than reading another directory inventory. The MLIR version must name a concrete pipeline and target before its launch counts are comparable.
