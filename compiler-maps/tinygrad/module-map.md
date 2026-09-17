# tinygrad: the module map

Snapshot: clean local `master`, `107adc31701df0247dfa45e175984df906a68b53` (commit date 2026-09-17), inspected 2026-09-17. This describes upstream master; local Blackhole work was stashed before the final audit and is excluded. The neighboring [older internals guide](../../archive/tinygrad/internals-guide.md) is pinned to July and should not be used as an exact API/pass-order reference for this snapshot.

This is a reading map, not a claim that every branch of every backend has been executed. Every production Python module is accounted for in the inventory below, including grouped generated bindings and empty package initializers. The audited package contains 216 tracked Python files: 127 outside `runtime/autogen/` and 89 within it, including the three handwritten generation registries. Generated bindings are grouped by API/architecture; every non-generated module is explicitly routed below. Compiler entrypoints, lifetime rules, dtype behavior, and JIT contracts received deeper source inspection. Device-specific files received structural/interface inspection; generated register tables were inventoried, not manually verified against silicon. Tests/examples/tools are mapped by area rather than narrated file by file.

Motivations below explain the responsibility visible in the source; they are architectural interpretations, not claims about an author's private intent. For UOp definitions, precise matcher contracts, and why individual PMs exist, continue with [UOps and rewrites](uops-and-rewrites.md). The [RMSNorm and inter-kernel fusion case study](rmsnorm-kernel-fusion.md) follows a larger computation. The [worked exercises](module-exercises.md) turn this map into curriculum material.

## Read the boundaries first

Suppose you write `y = (x + 1).sum()`. The Python expression states which answer you want, but leaves several questions open: must the array `x+1` be stored, which processor computes each element, and when is the answer ready to read? The compiler answers these questions in stages. **Lowering** means replacing a convenient description with a more explicit one that the next stage can implement.

Tinygrad records the computation as an **intermediate representation (IR)**: data describing a program. Its basic node is a **UOp**, with an operation and references to its inputs. The nodes form a **directed acyclic graph (DAG)**: arrows connect operations to their dependencies, shared inputs can have multiple users, and following dependencies cannot lead back to the same node. A **pass** transforms this graph. A **phase invariant** is a condition a pass promises the next pass, such as “all memory reads are explicit.” A **PatternMatcher (PM)** is a collection of rules used by many of these passes.

In the pipeline below, `CALL` represents invoking a body with arguments, `PARAM` a body input, and `SINK` a root collecting work that must be retained. A **buffer** is storage for values. **Materializing** a value means producing its stored contents; **realization** requests that pending computation become available. A **kernel** is a unit of device computation; **fusion** lets work share a kernel and may avoid storing and rereading an intermediate. A memory **arena** is one larger allocation divided among temporary buffers. The CPU running Python is the **host**; the selected execution target is the **device**, which can also be a CPU.

The optional [first-principles primer](../first-principles.md) introduces the same vocabulary across projects. Here, read the narrative before each table for the problem being solved, then use the table to locate its implementation.

The shortest useful walk is [`Tensor.realize`](../../../tinygrad/tinygrad/tensor.py#L412) → [`create_linear_with_vars`](../../../tinygrad/tinygrad/schedule/__init__.py#L185) → [`run_linear`](../../../tinygrad/tinygrad/engine/realize.py#L299) → [`to_program`](../../../tinygrad/tinygrad/codegen/__init__.py#L507) → [`Renderer`](../../../tinygrad/tinygrad/renderer/__init__.py#L63) and [`Compiled`](../../../tinygrad/tinygrad/device.py#L404). Read each function's caller and returned UOp shape before reading its helpers.

```text
Tensor + shared operation mixins
  → immutable value/effect UOp DAG
  → explicit CALL/PARAM/buffer identities
  → prepare, index/rangeify, choose kernel boundaries
  → schedule LINEAR(CALL, ...) and memory arenas
  → optimize/lower each kernel SINK
  → PROGRAM(SINK, LINEAR, SOURCE, BINARY)
  → compile/link command submission and resolve runtime addresses
  → execute, synchronize, expose host data
```

`LINEAR` has two important uses: a schedule of calls and an ordered instruction stream inside a program. Likewise, a `UOp` being well-formed at the tensor level does not mean a renderer accepts it. The shared node representation reduces adapters while putting more responsibility on phase invariants.

For CAIR, use the frontend to explain semantics; scheduling to explain materialization and dependencies; codegen to explain legality versus profitability; runtime to explain why valid machine code is insufficient without memory ownership and submission ordering. For a future Blackhole study, these are useful comparative seams, but this snapshot contains no TT backend and this document makes no claim about the stashed work.

## Frontend, shared semantics, and basic services

The frontend decides what the expression means before choosing how to execute it. For `x+1`, **broadcasting** applies the scalar to each element, and **type promotion** chooses a compatible numeric type. A **weak scalar type** records “integer” or “float” without immediately forcing a machine width such as int32; a concrete array dtype can guide that choice. The promotion lattice is the set of permitted common-type choices, not an execution schedule.

A **view** changes how an array is indexed without necessarily copying its storage. Two views that share storage **alias**: writing through one may change what the other reads. A reduction, such as `sum`, combines an axis into fewer values; its **accumulator** holds the running result. Python mixins below share groups of tensor methods. JIT means just-in-time compilation; tinygrad's `TinyJit` also captures and replays executable work, as discussed under runtime.

| Module / source entry | Why it exists and what to read | Contract / sharp edge |
|---|---|---|
| [`__init__.py`](../../../tinygrad/tinygrad/__init__.py#L1) | Small public export surface (`Tensor`, dtypes, JIT, context, function). | An exported convenience API does not stabilize compiler internals. |
| [`tensor.py`](../../../tinygrad/tinygrad/tensor.py#L265) | Owns Python-facing tensor identity, host data conversion, realization, assignment, differentiation entrypoints, and conversion of graphs into calls. Start with `__slots__`, `_apply_uop`, `linear_with_vars`, `assign`, `_buffer`. | Tensor wrappers are mutable; UOp graphs are structurally shared. Assignment to pending values, realized storage, and views has different handling. Scheduling can update live tensors to refer to buffers. |
| [`function.py`](../../../tinygrad/tinygrad/function.py#L34) | Builds reusable graph-level function boundaries with explicit parameters, optional precompilation, and custom gradients. | Device usage is restricted inside the wrapped function. Implicit buffer capture defaults to rejection; unsupported Python return structures fail. This is different from replaying a TinyJit capture. |
| [`dtype.py`](../../../tinygrad/tinygrad/dtype.py#L57) | Type identities, promotion lattice, weak scalar types, address spaces, numeric encodings, and reduction accumulator types. | Weak types describe scalar intent and must become concrete at storage. Casting is numerical conversion; bitcasting reinterprets storage. FP8 variants are not interchangeable. |
| [`helpers.py`](../../../tinygrad/tinygrad/helpers.py#L169) | Shared configuration (`Context`/`ContextVar`, `Target`), caches, profiling, fetching, formatting, scalar helpers. | Settings can change compiler semantics and cache identity. Read `to_program_config` before adding a lowering-affecting switch. Disk and process caches are different layers. |
| [`mixin/creation.py`](../../../tinygrad/tinygrad/mixin/creation.py#L10) | Constructs values/shapes using shared graph operations. | Shape and dtype choices are made before hardware exists. Constant creation need not allocate storage. |
| [`mixin/dtype.py`](../../../tinygrad/tinygrad/mixin/dtype.py#L8) | Shared dtype conversion conveniences. | Storage requirements and weak-type commitment are not equivalent to Python's scalar coercion rules. |
| [`mixin/elementwise.py`](../../../tinygrad/tinygrad/mixin/elementwise.py#L15) | Broadcasting, promotion, arithmetic and comparisons on a minimal UOp-like interface. | Equal shapes alone do not settle dtype/device compatibility. Division and comparison semantics matter to later rewrites. |
| [`mixin/movement.py`](../../../tinygrad/tinygrad/mixin/movement.py#L12) | Reshape, expand, permute, padding, shrinking and related movement semantics. | These are logical index transformations; they do not all imply copies or ordinary contiguous pointer views. |
| [`mixin/reduce.py`](../../../tinygrad/tinygrad/mixin/reduce.py#L9) | Reductions and accumulator/axis normalization. | Empty dimensions, identities and accumulator dtype are semantic obligations of every backend. |
| [`mixin/op.py`](../../../tinygrad/tinygrad/mixin/op.py#L19) | Larger tensor operations composed from smaller ones: indexing, contractions, convolution and neural-network math. | A single API method may become many UOps or kernels; a high-level name does not imply a dedicated runtime operator. |
| [`mixin/rand.py`](../../../tinygrad/tinygrad/mixin/rand.py#L10) | Random construction and state handling built on the shared operation layer. | Reproducibility includes seed/counter evolution and device behavior, not just the distribution formula. |
| [`mixin/gradient.py`](../../../tinygrad/tinygrad/mixin/gradient.py#L132) | Reverse traversal and derivative rules, including calls and partial stores. | Differentiation is a graph transformation. Broadcasts need gradient reductions; writes and custom calls require explicit treatment. |

## UOp representation and proof machinery

For `t=x+1; y=t*t`, both multiply inputs can point to the same node for `t`. **Interning** reuses a node when its construction matches an existing live node; it avoids building duplicate graph objects. A tree-shaped syntax representation (an AST) need not preserve that sharing. A rewrite recognizes a subgraph and replaces it while preserving its meaning.

The proof machinery supplies limited facts that make rewrites safe. A **range bound** might establish `0 <= i < 8`; a **validity predicate** is a true/false condition such as `i < length`. A **gated load** performs a read only where the condition allows it. Z3 is an external logic solver used for supported validation questions. Passing a structural specification establishes that the graph has an allowed form, not that two programs calculate the same answers.

| Module / source entry | Responsibility | Sharp edge |
|---|---|---|
| [`uop/__init__.py`](../../../tinygrad/tinygrad/uop/__init__.py#L13) | `Ops`, grouped operation categories, enum machinery. | Enum membership is broader than any one legal compiler phase. |
| [`uop/ops.py`](../../../tinygrad/tinygrad/uop/ops.py#L230) | UOp construction/interning, shape and dtype properties, calls, buffers, symbolic values; `UPat`, `PatternMatcher`, graph rewriting and tracing. | This is the semantic center, not merely an AST dataclass. Rewrite traversal and source order affect correctness and performance. |
| [`uop/upat.py`](../../../tinygrad/tinygrad/uop/upat.py#L166) | Compiles patterns into efficient matching code. | The pattern language and Python callback semantics both constrain a rewrite. |
| [`uop/spec.py`](../../../tinygrad/tinygrad/uop/spec.py#L28) | Structural/type specifications and verification for graph phases. | Passing a spec is a local legality check, not proof that a transformation preserves values. |
| [`uop/validate.py`](../../../tinygrad/tinygrad/uop/validate.py#L74) | Z3 translation and index validation. | Solver support has a defined operation subset and integer/cast semantics; do not infer an unrestricted theorem prover. |
| [`uop/symbolic.py`](../../../tinygrad/tinygrad/uop/symbolic.py#L29) | Algebraic simplification, ranges, validity predicates and gated loads. | Floating-point identities, invalid values, division convention and bounds prevent naive school algebra. |
| [`uop/divandmod.py`](../../../tinygrad/tinygrad/uop/divandmod.py#L8) | Specialized div/mod folding. | Sign and bounds are part of the proof. |
| [`uop/movement.py`](../../../tinygrad/tinygrad/uop/movement.py#L1) | Shared movement rewrite rules. | Legal movement across another op depends on axes, shape and operation semantics. |
| [`uop/weak.py`](../../../tinygrad/tinygrad/uop/weak.py#L53) | Resolves weak scalar expressions and casts into concrete types. | Resolving too early can change promotion; too late leaves unstorable values. |
| [`uop/render.py`](../../../tinygrad/tinygrad/uop/render.py#L137) | Human-readable graph dumps and Python reconstruction. | This is debugging serialization, distinct from target code rendering. |

## Scheduling: choose what must exist in memory

Return to `(x+1).sum()`. One possible implementation reads each `x[i]`, adds one, and immediately adds that result to an accumulator. Another writes every `x[i]+1` into a temporary array and runs a second kernel to sum it. Scheduling decides which intermediate values must be stored and how the dependent calls are ordered; the exact choice depends on shape and target constraints.

**Rangeification** makes iteration explicit: “operate on an array” becomes expressions parameterized by positions such as `i` from `0` through `N-1`. This lets the compiler reason about which iterations depend on which values. **Liveness** means a stored value is still needed by a future call; only after its last use can its space be reused. Memory-planner **lanes** separate classes of allocations and are distinct from GPU execution lanes. **Sharding** splits an array across devices; an **allreduce** combines their partial results and makes the combined result available to participants.

| Module / source entry | Why the abstraction exists | Contract / sharp edge |
|---|---|---|
| [`schedule/__init__.py`](../../../tinygrad/tinygrad/schedule/__init__.py#L28) | Orders dependencies, resolves linear calls/buffers, extracts copy operations, binds variables and invokes memory planning. | It produces a call schedule, not target instructions. A schedule may be captured by JIT instead of executed. Conflicting bindings for one symbolic variable fail. |
| [`schedule/prepare.py`](../../../tinygrad/tinygrad/schedule/prepare.py#L218) | Normalizes calls, copy boundaries, reduction splitting, bitcasts and store hazards before rangeification. | In-place stores can invalidate values still needed by another consumer. `fix_store_hazard` exists to preserve read/write meaning, not merely optimize. |
| [`schedule/indexing.py`](../../../tinygrad/tinygrad/schedule/indexing.py#L188) | Turns logical tensor movement and reduction axes into index/range expressions; tracks which sources must be realized. | Padding becomes local validity/value behavior. Indexing and materialization decisions interact; incorrect fusion can duplicate work or change effects. |
| [`schedule/rangeify.py`](../../../tinygrad/tinygrad/schedule/rangeify.py#L367) | Removes temporary bufferization constructs, splits stores and forms kernel graphs. | Range dependence, buffer limits, effect dependencies and local intermediates decide boundaries. Every tensor op is not a kernel. |
| [`schedule/memory.py`](../../../tinygrad/tinygrad/schedule/memory.py#L20) | Reuses temporary storage with per-device/lane arenas from call lifetimes. | Held buffers are excluded. Copy buffers use separate lanes and extended holds to avoid accidental serialization/dependency hazards. DISK/CL/WEBGPU are excluded by `_can_plan`. |
| [`schedule/multi.py`](../../../tinygrad/tinygrad/schedule/multi.py#L107) | Distributes arithmetic/movement/reductions over sharded values and expands cross-device effects. | A reduction over a sharded axis requires communication. This snapshot rejects partially reducing multi-axis sharding when sharded axes remain. |
| [`schedule/allreduce.py`](../../../tinygrad/tinygrad/schedule/allreduce.py#L6) | Builds naive, ring, or all-to-all collective algorithms as graph operations. | Concrete sizes, thresholds and number of devices choose algorithms; ring is not universally cheaper. Cross-device transport capability still belongs to runtime. |

## Code generation: choose a legal, profitable implementation

Once a kernel boundary is chosen, code generation decides how that kernel does its work. **Legality** means an implementation preserves the required behavior and is supported by the target; **profitability** means it is expected to run faster. They are different questions.

A **lane** here is an element position within grouped execution or a vector value. Vectorization groups several element operations; unrolling spells out iterations instead of keeping a loop. **Coalescing** groups suitable memory accesses. An **address space** distinguishes kinds of storage, such as per-thread registers, workgroup-shared local memory, and device-wide global memory. A **barrier** coordinates participating threads so producers finish writes before consumers read them. **Register pressure** is how much fast per-thread storage is simultaneously needed. Arithmetic/logic operations are abbreviated **ALU**; pseudo-random number generation is abbreviated **PRNG**.

| Module / source entry | Responsibility | Contract / sharp edge |
|---|---|---|
| [`codegen/__init__.py`](../../../tinygrad/tinygrad/codegen/__init__.py#L286) | Authoritative per-kernel pass order; expands lanes/reductions, introduces local storage and barriers, lowers dtypes/ops, linearizes, renders/assembles and compiles programs. | Ordering is semantic: the source explicitly requires symbolic simplification before range simplification. Inspect `do_to_program`, not an old blog's pipeline. |
| [`codegen/simplify.py`](../../../tinygrad/tinygrad/codegen/simplify.py#L23) | Range merging, reduction and load collapse. | Removing a range needs a dependence argument; a folded constant reduction still needs its multiplicity/identity preserved. |
| [`codegen/gpudims.py`](../../../tinygrad/tinygrad/codegen/gpudims.py#L41) | Maps parallel ranges into bounded target launch dimensions. | Renderer launch limits constrain legal grouping/splitting; dimensions are not arbitrary labels. |
| [`codegen/opt/__init__.py`](../../../tinygrad/tinygrad/codegen/opt/__init__.py#L6) | Named optimization actions and errors. | These actions express schedules/layout choices with legality checks. |
| [`codegen/opt/postrange.py`](../../../tinygrad/tinygrad/codegen/opt/postrange.py#L17) | `Scheduler` applies transformations after ranges exist. | Axis identities and divisibility evolve as transformations run; an option sequence is order-dependent. |
| [`codegen/opt/heuristic.py`](../../../tinygrad/tinygrad/codegen/opt/heuristic.py#L8) | Cheap hand-coded schedule selection. | Heuristics use target capabilities and shapes; they are not proofs of fastest execution. |
| [`codegen/opt/search.py`](../../../tinygrad/tinygrad/codegen/opt/search.py#L105) | Beam search compiles/times candidate schedules. | Needs device access; measurement size, cache state, timeout and noise affect results. `engine.realize` keeps beam compilation in the parent process. |
| [`codegen/decomp/op.py`](../../../tinygrad/tinygrad/codegen/decomp/op.py#L83) | Replaces operations with lower-level equivalents, including division and PRNG arithmetic. | Fast division needs correct integer-width/sign semantics. |
| [`codegen/decomp/dtype.py`](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L205) | Implements unsupported types/conversions using supported storage and arithmetic. | Rounding, saturation, packing and memory access granularity matter; supporting arithmetic alone is insufficient. |
| [`codegen/decomp/transcendental.py`](../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L268) | Software sin/exp/log/pow approximations and argument reduction. | Accuracy domains and exceptional values constrain replacements; native operations and decompositions need comparison. |
| [`codegen/late/coalesce.py`](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L104) | Groups memory operations, including image accesses and validity treatment. | Neighboring logical elements may not form an aligned, valid physical vector load. |
| [`codegen/late/gater.py`](../../../tinygrad/tinygrad/codegen/late/gater.py#L5) | Moves suitable WHERE conditions onto loads. | A result mask alone cannot protect an invalid memory access. |
| [`codegen/late/linearizer.py`](../../../tinygrad/tinygrad/codegen/late/linearizer.py#L8) | Produces a legal sequential order from a dependency/control-flow graph. | Topological legality includes scope/end and control-flow constraints, not only ALU operands. |
| [`codegen/late/regalloc.py`](../../../tinygrad/tinygrad/codegen/late/regalloc.py#L9) | Linear-scan register allocation for selected instructions. | Physical register pressure and live ranges appear only after lower-level choices; semantic equivalence need not preserve register cost. |

## Renderers: describe the target and emit its program

A renderer translates the lowered program into a target language or instruction representation. Its capability declarations also tell earlier stages which choices are legal. An **intrinsic** names a target-specific operation supplied by a compiler. An **ISA** is a processor's instruction set; direct ISA generation must handle details otherwise delegated to a compiler. An **ABI** is the agreement about arguments, memory layout and calling conventions between separately implemented components. ELF is a binary container format used by several loading paths.

For matrix hardware, a **fragment** is the subset of a matrix tile owned by a participating lane. Correct arithmetic on the wrong fragment layout still produces the wrong matrix. LLVM IR, PTX, NIR and WGSL below are alternative target representations, not successive steps that every tinygrad program traverses.

| Module / source entry | Why it exists | Sharp edge |
|---|---|---|
| [`renderer/__init__.py`](../../../tinygrad/tinygrad/renderer/__init__.py#L63) | Target capabilities, compiler object, supported dtypes, optional final rewrites; `Estimates` counts symbolic work/traffic. | Incorrect capability declarations admit illegal schedules. Estimates are model counts, not measured bandwidth/FLOP rates. |
| [`renderer/cstyle.py`](../../../tinygrad/tinygrad/renderer/cstyle.py#L119) | Shared C-like emitter with Clang/OpenCL/Metal/CUDA/HIP/QCOM variants. | Similar syntax hides different intrinsic, pointer/address-space and vector conventions. |
| [`renderer/llvmir.py`](../../../tinygrad/tinygrad/renderer/llvmir.py#L146) | LLVM IR generation, with CPU/AMD specializations. | LLVM types, volatile accesses and target intrinsics must preserve UOp semantics. |
| [`renderer/ptx.py`](../../../tinygrad/tinygrad/renderer/ptx.py#L137) | NVIDIA PTX emission. | PTX is an intermediate target language; assembly/loading remain downstream responsibilities. |
| [`renderer/nir.py`](../../../tinygrad/tinygrad/renderer/nir.py#L115) | Mesa NIR construction and NAK/LVP/IR3 target variants. | Depends on Mesa IR/compiler ABI and target-specific lowerings. |
| [`renderer/wgsl.py`](../../../tinygrad/tinygrad/renderer/wgsl.py#L55) | WebGPU shader emission and packed-value handling. | Shader storage support may force packing and read/modify/write behavior absent from logical dtype semantics. |
| [`renderer/tc.py`](../../../tinygrad/tinygrad/renderer/tc.py#L7) | Tensor-core instruction shapes and lane/fragment layout metadata. | Matrix shape support does not specify which lane owns each element; layout is part of correctness. |
| [`renderer/isa/__init__.py`](../../../tinygrad/tinygrad/renderer/isa/__init__.py#L37) | Direct instruction selection interface, virtual registers and linearization context. | Direct ISA generation assumes responsibilities an external compiler would otherwise own. |
| [`renderer/isa/x86.py`](../../../tinygrad/tinygrad/renderer/isa/x86.py#L697) | x86 instruction selection, ABI lowering, register handling and encoding. | Flags, integer division, operand constraints and ABI clobbers are first-class concerns. |
| [`renderer/amd/__init__.py`](../../../tinygrad/tinygrad/renderer/amd/__init__.py#L73), [`dsl.py`](../../../tinygrad/tinygrad/renderer/amd/dsl.py#L270), [`elf.py`](../../../tinygrad/tinygrad/renderer/amd/elf.py#L15) | AMD instruction decoding/format detection, bitfield/register DSL, and assembly into ELF. | Encoding family, literal operands, relocation and binary container metadata must agree. |
| [`renderer/amd/generate.py`](../../../tinygrad/tinygrad/renderer/amd/generate.py#L73) | Generates AMD instruction metadata from external descriptions. | Generator provenance and input architecture versions matter; generated output is not independent validation. |
| [`renderer/amd/sqtt.py`](../../../tinygrad/tinygrad/renderer/amd/sqtt.py#L590) | Decodes hardware trace packets and maps them to instructions. | Packet formats and timing interpretation vary by GPU generation. |

## Execution and runtime backends

Generated instructions do not allocate their own inputs or arrange their own launch. The runtime creates storage, loads code, supplies addresses and arguments, and submits commands. **Synchronization** establishes when work is complete or visible to another participant. **Capture** records reusable execution work; **replay** invokes it again with compatible inputs. Reusing a program is different from reusing an old input address.

[`device.py`](../../../tinygrad/tinygrad/device.py#L108) separates logical `Buffer` ownership/views from `Allocator` storage operations, `Compiler` source-to-binary work, callable `Program` instances, and `Compiled` device state. `Buffer.get_storage` can map one allocation into another device; `is_allocated` checks view/base storage identity. This is where a new backend must preserve byte offsets, alignment, lifetime, mapping, and synchronization, even if its generated kernel is numerically correct.

[`engine/realize.py`](../../../tinygrad/tinygrad/engine/realize.py#L289) orchestrates lowering/compilation, HCQ compilation, linking and execution dispatch. [`engine/worker.py`](../../../tinygrad/tinygrad/engine/worker.py#L37) supplies compile workers and context transfer. [`engine/jit.py`](../../../tinygrad/tinygrad/engine/jit.py#L214) first runs the function normally, then captures, then replays compiled work with compatible input metadata. It plans capture memory, splits graph-compatible work and checks input identities/shapes/contracts. Host data access during capture is rejected in `Tensor._buffer` because it would bake values into Python execution.

| Runtime module | Role and reason for separation | Sharp edge / source entry |
|---|---|---|
| [`ops_cpu.py`](../../../tinygrad/tinygrad/runtime/ops_cpu.py#L18) | Native CPU program execution and renderer selection. | Host executable memory, ABI and CPU ISA availability. |
| [`ops_python.py`](../../../tinygrad/tinygrad/runtime/ops_python.py#L46) | Interpreter/reference execution of low-level operations. | Useful for semantics, not a GPU memory-model or performance simulator. |
| [`ops_null.py`](../../../tinygrad/tinygrad/runtime/ops_null.py#L53) | No-work backend for compiler/capture plumbing. | Success is not numerical execution evidence. |
| [`ops_npy.py`](../../../tinygrad/tinygrad/runtime/ops_npy.py#L3) | Host/NumPy-backed storage bridge. | This tiny storage device is not a NumPy implementation of every kernel. |
| [`ops_disk.py`](../../../tinygrad/tinygrad/runtime/ops_disk.py#L9) | File-backed buffers and allocation/copy access. | Persistence, offsets and file mapping differ from compute-device storage. |
| [`ops_cuda.py`](../../../tinygrad/tinygrad/runtime/ops_cuda.py#L98) | CUDA driver API programs, buffers and graphs. | Argument packing, stream lifetimes and synchronization. |
| [`ops_hip.py`](../../../tinygrad/tinygrad/runtime/ops_hip.py#L12) | HIP API-backed execution. | Do not conflate it with the lower-level AMD backend. |
| [`ops_amd.py`](../../../tinygrad/tinygrad/runtime/ops_amd.py#L836) | AMD packet queues, program metadata, allocation, KFD/PCI/USB interfaces and profiling. | GPU architecture, firmware/driver interface, queue dependencies and address visibility. |
| [`ops_nv.py`](../../../tinygrad/tinygrad/runtime/ops_nv.py#L557) | NVIDIA QMD/queues, binary loading, allocation and kernel/PCI/mock interfaces. | Not the same route as `CUDA`; packet and launch metadata are architecture-specific. |
| [`ops_rdma.py`](../../../tinygrad/tinygrad/runtime/ops_rdma.py#L60) | RDMA device, NIC memory registration and UOp send/receive submission used for cross-node copies. | Peer-group ownership, registered pages, queue-pair sequence/completion state and transfer chunking. |
| [`ops_metal.py`](../../../tinygrad/tinygrad/runtime/ops_metal.py#L31) | Metal compile/load/command buffers and storage. | Objective-C ownership and completion errors. |
| [`ops_cl.py`](../../../tinygrad/tinygrad/runtime/ops_cl.py#L91) | OpenCL API compilation/program/allocation. | Device/compiler dialect and buffer view limits. |
| [`ops_webgpu.py`](../../../tinygrad/tinygrad/runtime/ops_webgpu.py#L165) | WebGPU adapter/device, shader pipelines and transfers. | Asynchronous API completion is bridged explicitly; limits differ from native GPU runtimes. |
| [`ops_qcom.py`](../../../tinygrad/tinygrad/runtime/ops_qcom.py#L304) | Adreno queues/program metadata/allocations. | Command packet fields and cache maintenance are essential behavior. |
| [`ops_dsp.py`](../../../tinygrad/tinygrad/runtime/ops_dsp.py#L128) | Qualcomm DSP code generation, RPC transport and allocation, with mock support. | RPC ABI, alignment and host/remote sharing remain separate from arithmetic. |
| [`graph/cuda.py`](../../../tinygrad/tinygrad/runtime/graph/cuda.py#L10), [`graph/metal.py`](../../../tinygrad/tinygrad/runtime/graph/metal.py#L10) | Native graph capture/replay adapters reduce repeated host launch work. | Capturable calls and mutable arguments must fit graph API restrictions. |

## Runtime support: the details the abstraction must not erase

These modules implement the machinery behind launch and memory operations. A **hardware command queue (HCQ)** holds commands for a device. **Linking/relocation** fills in references whose final addresses were unknown when code or commands were built. **MMIO** exposes device registers through memory addresses; page tables translate virtual addresses to underlying memory. PCI and USB are transports to hardware. **RDMA** transfers data through registered network-accessible memory. Generated bindings turn external C declarations and constants into Python-accessible definitions; their correctness depends on matching the external interface version.

For a first reading, follow `hcq2.py` and one compiler adapter, then return to the device-specific tables only when tracing that device. The filenames and library acronyms below are lookup targets, not concepts that must all be learned before understanding a kernel launch.

| Module(s) | Responsibility and sharp edge |
|---|---|
| [`support/hcq2.py`](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L507) | Hardware command queue compilation: dependencies, staging, cross-node RDMA splitting, batches, encoding, symbolic addresses, patching and linking. `hcq_compile` and `hcq_link` separate reusable submission structure from actual allocated addresses. An address valid during capture need not be valid during replay. |
| [`support/hcq.py`](../../../tinygrad/tinygrad/runtime/support/hcq.py#L9) | Remaining file I/O/interface helpers and visible-device filtering. At this snapshot the bulk of queue compilation lives in `hcq2.py`; do not assume the older filename is still the main runtime. |
| [`support/memory.py`](../../../tinygrad/tinygrad/runtime/support/memory.py#L23) | MMIO views, bump/TLSF allocators, virtual mappings and page-table management. Logical byte allocation, CPU MMIO and GPU address translation are distinct layers. |
| [`support/system.py`](../../../tinygrad/tinygrad/runtime/support/system.py#L166) | Local/USB/remote PCI access and common interface allocation. Remote addressing and peer topology can change the transport without changing tensor semantics. |
| [`support/c.py`](../../../tinygrad/tinygrad/runtime/support/c.py#L40) | C ABI records, fields, pointers, DLLs and ioctl helpers. Size/layout errors become memory corruption, not ordinary Python type errors. |
| [`support/elf.py`](../../../tinygrad/tinygrad/runtime/support/elf.py#L15) | ELF loading, linking and JIT relocation. Code bytes without correct relocation/sections are not an executable program. |
| [`support/objc.py`](../../../tinygrad/tinygrad/runtime/support/objc.py#L30) | Objective-C message/ownership bridge used by Apple runtime paths. Return ownership and method signatures matter. |
| [`support/autogen.py`](../../../tinygrad/tinygrad/runtime/support/autogen.py#L102) | Binding generation via libclang. The generator is handwritten; generated bindings below are ABI descriptions. |
| [`support/compiler_cpu.py`](../../../tinygrad/tinygrad/runtime/support/compiler_cpu.py#L5), [`compiler_llvm.py`](../../../tinygrad/tinygrad/runtime/support/compiler_llvm.py#L12) | Clang/direct-x86 and LLVM compiler adapters. Target flags and emitted object conventions must match loaders. |
| [`support/compiler_cuda.py`](../../../tinygrad/tinygrad/runtime/support/compiler_cuda.py#L46), [`compiler_amd.py`](../../../tinygrad/tinygrad/runtime/support/compiler_amd.py#L80) | NVRTC/NVCC/PTX/NVPTX and HIP/COMGR compilation adapters. Renderer and compiler are separate selections; a backend can have multiple routes. |
| [`support/compiler_mesa.py`](../../../tinygrad/tinygrad/runtime/support/compiler_mesa.py#L19), [`compiler_qcom.py`](../../../tinygrad/tinygrad/runtime/support/compiler_qcom.py#L10) | Mesa LVP/NAK/IR3 and Qualcomm compiler integration. Native library version/layout assumptions matter. |
| [`support/compileserver.py`](../../../tinygrad/tinygrad/runtime/support/compileserver.py#L1) | Compiler service entrypoint. Remote compilation changes where code is built, not the target execution contract. |
| [`support/amd.py`](../../../tinygrad/tinygrad/runtime/support/amd.py#L17) | AMD register/IP wrappers and architecture-specific metadata imports. Register addresses differ by hardware generation. |
| [`support/am/amdev.py`](../../../tinygrad/tinygrad/runtime/support/am/amdev.py#L144), [`am/ip.py`](../../../tinygrad/tinygrad/runtime/support/am/ip.py#L8) | AMD userspace device bringup, firmware, page tables and hardware IP blocks. Read only when studying the direct PCI path; register programming has effects beyond one kernel. |
| [`support/nv/nvdev.py`](../../../tinygrad/tinygrad/runtime/support/nv/nvdev.py#L74), [`nv/ip.py`](../../../tinygrad/tinygrad/runtime/support/nv/ip.py#L13) | NVIDIA direct device/memory management and Falcon/GSP firmware interfaces. Firmware protocols and memory mappings are their own state machines. |
| [`support/rdma/bnxtdev.py`](../../../tinygrad/tinygrad/runtime/support/rdma/bnxtdev.py#L52) | Broadcom RDMA device/queue-pair setup and work queues. Completion ordering and pinned address ownership constrain transfers. |
| [`support/usb.py`](../../../tinygrad/tinygrad/runtime/support/usb.py#L303) | USB transport/controller, chunking, staging, dependency and load/store rewrites. Transfer granularity and backpressure cannot be inferred from ordinary PCI behavior. |
| [`runtime/autogen/__init__.py`](../../../tinygrad/tinygrad/runtime/autogen/__init__.py#L1) | Handwritten lazy binding-generation/loader registry: source URLs, headers, compiler flags and library choices. Unlike empty package markers, this initializer is executable tooling and defines binding provenance. |
| [`runtime/autogen/am/__init__.py`](../../../tinygrad/tinygrad/runtime/autogen/am/__init__.py#L1), [`runtime/autogen/nv_regs/__init__.py`](../../../tinygrad/tinygrad/runtime/autogen/nv_regs/__init__.py#L1) | Handwritten architecture-specific generation registries: AMD header/firmware/register sources and NVIDIA register extraction/offset rules. Their initializers execute generation logic; they are not empty package markers. |
| [`runtime/autogen/`](../../../tinygrad/tinygrad/runtime/autogen/) | Generated external ABI/constant tables: GPU APIs (`cuda`, `hip`, `hsa`, `kfd`, `amdgpu_drm`, `nv*`, `kgsl`, `opencl`, `webgpu`), compiler/media/system APIs (`llvm*`, `libclang`, `comgr`, `nvrtc`, `nvjitlink`, `mesa`, `avcodec`, `ggml_common`, `libc`, `pci`, `vfio`, `io_uring`, `libusb`, `corefoundation`, `iokit`, `metal`), networking/profiling (`bnxt`, `mlx5`, `rocprof`, `sqtt`, `qcom_dsp`, `amd_gpu`, `amdgpu_kd`), AMD IP tables under `am/`, AMD ISA enums/instructions/operands/pseudocode under `amd/{cdna,rdna3,rdna4}/` plus `common.py`, and NVIDIA register families under `nv_regs/`. These are grouped intentionally: audit generator input/version and consuming code instead of reading thousands of constants linearly. |

## Neural networks, applications and observation

These modules use the compiler rather than adding another universal lowering stage. Optimizers update model parameters using gradients and persistent state. Model loaders translate stored formats into tensors; quantization represents weights with fewer bits plus decoding rules. The language-model **KV cache** retains attention keys and values from previous tokens, so its updates exercise the same aliasing and ordering rules as other in-place writes. Profiling and visualization expose the resulting work, but estimated operation counts and measured elapsed times answer different questions.

| Module(s) | Why it exists / where it bites |
|---|---|
| [`nn/__init__.py`](../../../tinygrad/tinygrad/nn/__init__.py#L8) | Tensor-composed layers, normalization, embedding and LSTM. Training mode, state and custom embedding derivatives are worth tracing. |
| [`nn/optim.py`](../../../tinygrad/tinygrad/nn/optim.py#L7) | Optimizer state and parameter updates (SGD, Muon, LARS, Adam-family/LAMB). Correct arithmetic also needs correct ordering of old/new parameter and state values. |
| [`nn/state.py`](../../../tinygrad/tinygrad/nn/state.py#L89) | State traversal, parameter collection, safetensors and PyTorch checkpoint loading, archive helpers, Tensor I/O. Object traversal and format loading are outside compiler semantics but determine real model inputs. |
| [`nn/onnx.py`](../../../tinygrad/tinygrad/nn/onnx.py#L369) | Protobuf parsing and ONNX execution/operator mapping. Opset, attributes, constants and shape semantics must survive import. |
| [`nn/datasets.py`](../../../tinygrad/tinygrad/nn/datasets.py#L4) | MNIST/CIFAR download/load helpers. Dataset/network access is not needed to study the core compiler. |
| [`nn/torch.py`](../../../tinygrad/tinygrad/nn/torch.py#L1) | Imports the experimental PyTorch backend from `extra/torch_backend`. Requires a source checkout; it explicitly rejects a missing extra frontend. |
| [`llm/model.py`](../../../tinygrad/tinygrad/llm/model.py#L354) | Configurable transformer/attention/MoE/SSM components and inference state. KV/state mutation and dynamic lengths pressure function/JIT boundaries. |
| [`llm/gguf.py`](../../../tinygrad/tinygrad/llm/gguf.py#L222) | GGUF parsing, split files and quantized weight decoding. Quantization layout is a storage contract as well as numerical approximation. |
| [`llm/cli.py`](../../../tinygrad/tinygrad/llm/cli.py#L141), [`llm/__main__.py`](../../../tinygrad/tinygrad/llm/__main__.py#L1) | Tokenizer/template handling and CLI entrypoint. Keep text protocol behavior separate from tensor math. |
| [`llm/serve.py`](../../../tinygrad/tinygrad/llm/serve.py#L165), [`chat.html`](../../../tinygrad/tinygrad/llm/chat.html#L1) | HTTP/streaming chat application and browser UI. Stream/tool-call parsing is application logic, not compiler lowering. |
| [`llm/kernels/amd.py`](../../../tinygrad/tinygrad/llm/kernels/amd.py#L29) | Specialized quantized linear, GEMV, attention and gated-delta kernels with AMD capability checks. Useful to study escape hatches/custom UOps; these are not portable tensor-level guarantees. |
| [`viz/cli.py`](../../../tinygrad/tinygrad/viz/cli.py#L79), [`viz/serve.py`](../../../tinygrad/tinygrad/viz/serve.py#L77) | Decode rewrite/profile records, inspect IR transitions, render timelines and architecture traces. Distinguish simulated estimates, host timings and device timestamps. |
| [`viz/README.md`](../../../tinygrad/tinygrad/viz/README.md#L1), `viz/index.html`, `viz/js/{index,worker}.js`, `viz/fetch_assets.sh`, `viz/assets/` | Usage, browser visualization, worker layout and vendored JS/CSS assets. The vendored UI libraries are delivery dependencies, not compiler modules. |

Empty initializer modules (`engine`, `mixin`, `runtime`, `runtime/graph`, `runtime/support`, `support/am`, `support/nv`, `support/rdma`, `codegen/decomp`, `codegen/late`, `viz`, `llm`, and empty generated subpackages; the three `runtime/autogen/{,am/,nv_regs/}__init__.py` registries are executable exceptions) establish package structure. `py.typed` marks typing support. They introduce no additional lowering pass.

## The rest of the repository

| Area | Reading purpose / coverage |
|---|---|
| [`test/README`](../../../tinygrad/test/README#L1), [`test/backend/`](../../../tinygrad/test/backend/), [`test/null/`](../../../tinygrad/test/null/), [`test/unit/`](../../../tinygrad/test/unit/) | Main semantic specification in executable form. Backend tests run across devices; null tests need no backend; unit tests run on one backend in CI. Start with `test_schedule`, `test_rangeify`, `test_assign`, `test_jit`, `test_function`, `test_dtype_weak`, `test_after`, `test_buffer`, `test_uop_symbolic`. |
| [`test/amd/`](../../../tinygrad/test/amd/), [`test/device/`](../../../tinygrad/test/device/), [`test/mockgpu/`](../../../tinygrad/test/mockgpu/), [`test/opt/`](../../../tinygrad/test/opt/) | Architecture-specific tests, device checks, mock command paths and scheduling optimization checks. Mock execution cannot prove real hardware visibility/ordering. |
| [`test/models/`](../../../tinygrad/test/models/), [`test/external/`](../../../tinygrad/test/external/), [`test/speed/`](../../../tinygrad/test/speed/), [`test/testextra/`](../../../tinygrad/test/testextra/), [`test/web/`](../../../tinygrad/test/web/), `test/test_tiny.py`, `test/helpers.py` | Integration, external-framework/model dependencies, performance, extras, browser coverage, smoke coverage and shared harnesses. Expensive model tests are not required for every compiler exercise. |
| [`examples/`](../../../tinygrad/examples/) | End-to-end workloads: MNIST/CIFAR/training, transformer/LLM families, diffusion, vision, speech, RL, ONNX; `mlperf/`, `openpilot/`, `tinychat/`, `webgpu/`, `tools/`, `other_mnist/`, `vgg7_helpers/`, conversation assets. Use one small model before large benchmark suites. This is folder/workload coverage, not a correctness audit of every application. |
| [`extra/models/`](../../../tinygrad/extra/models/), `extra/datasets/`, `extra/training.py`, `extra/lr_scheduler.py`, `extra/gradcheck.py`, `extra/onnx_helpers.py`, `extra/huggingface_onnx/`, `extra/export_model.py` | Model/data/training and import/export experiments used by examples and external tests. Their location signals a different surface from the core package. |
| [`extra/optimization/`](../../../tinygrad/extra/optimization/), `extra/gemm/`, `gemm_fragment.py`, `mmapeak/`, `fp8/`, `llama_kernels/`, `gptoss_kernels/`, `benchmark_llm.py`, `archprobe.py`, `bench_log.py`, `introspection.py`, `multitensor.py`, `f16_decompress.py` | Kernel experiments, optimization and inspection. A fast specialized kernel suggests an optimization opportunity, not a universal schedule rule. |
| [`extra/hcq/`](../../../tinygrad/extra/hcq/), `hcq1/`, `hcqfuzz/`, `amdpci/`, `amdflash/`, `nv_gpu_driver/`, `hip_gpu_driver/`, `qcom_gpu_driver/`, `bnxt_driver/`, `mlx_driver/`, `usbgpu/`, `remote/`, `dsp/`, `mesa/`, `hiprtc/`, `nv_pma/`, `sqtt/`, `perfetto/` | Driver bringup, queue fuzzing, firmware and instrumentation experiments. These may be invasive hardware tools; read them for implementation evidence before choosing one to run. |
| [`extra/torch_backend/`](../../../tinygrad/extra/torch_backend/), `torch_hook/`, `hook_cuda.py`, `thunder/`, `thneed.py`, `webgpu/`, `viz/`, `hevc/`, `testsig/` | Alternate frontends/interception, recording/export, browser/visualization/media experiments and test infrastructure. They are not additional core IR stages. Remaining top-level setup scripts, headers, runbooks, benchmark shell scripts and weekly-commit reporting support these experiments. |
| [`docs/`](../../../tinygrad/docs/), [`mkdocs.yml`](../../../tinygrad/mkdocs.yml#L1), `serve_docs.sh` | Public API/docs, developer explanations, runtime/dtype/env-variable references; `abstractions3.py` and `abstractions4.py` are explanatory artifacts. Check source revision when prose and code differ. |
| [`spec/tinyspec.tex`](../../../tinygrad/spec/tinyspec.tex#L1), [`spec/README.md`](../../../tinygrad/spec/README.md#L1), `spec/render.sh`, `spec/tinyspec.pdf` | Human-readable formalization/source and rendered artifact. The README requires regeneration after TeX edits. Separate written intent, executable `uop/spec.py`, and actual backend behavior. |
| [`pyproject.toml`](../../../tinygrad/pyproject.toml#L1), `conftest.py`, `.github/`, `README.md`, `AGENTS.md`, `LICENSE`, `sz.py`, `opencode.json` | Packaging, test setup, CI policy, onboarding, contribution instructions, licensing, size tooling and tool configuration. Local `site/`, `__pycache__/`, egg metadata are generated/environment artifacts, not new architecture modules. |

## A personal route through the code

1. **Semantics day:** build a broadcasted add/reduction; inspect `Tensor.uop`, weak vs concrete dtype, and view assignment. Read `tensor`, mixins, `dtype`, and the corresponding tests. Deliverable: explain output shape/dtype and when a copy is necessary.
2. **IR day:** read `Ops`, `UOp`, `UPat`, graph rewrite and phase specs. Work the UOp companion exercises. Deliverable: a rewrite with a precondition and a counterexample when that precondition is removed.
3. **Scheduling day:** follow one graph through prepare/indexing/rangeify/schedule. Deliverable: a kernel-boundary diagram identifying stores, retained values, and communication.
4. **Lowering day:** inspect `full_rewrite_to_sink`, postrange options and one renderer. Deliverable: connect a vectorized load or reduction to a target capability and a legality check.
5. **Runtime day:** read Buffer/Allocator/Compiled, realize, HCQ2, CPU/PYTHON first; then one hardware runtime. Deliverable: explain allocation identity, a synchronization edge, and replay-time address patching.
6. **Curriculum capstone:** take one tiny model through an optimizer step and JIT replay, then a sharded reduction. Deliverable: evidence distinguishing semantic correctness, allocation reduction, compile latency, launch overhead and kernel speed.

The recurring sharp edge is a boundary crossing: logical value → storage, weak → concrete dtype, shape → index, graph → ordered effects, source → binary, captured address → replay address, local reduction → collective. These boundaries make better exercises than memorizing filenames.
