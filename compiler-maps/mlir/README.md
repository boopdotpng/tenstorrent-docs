# MLIR source guide and exercises

Source map and worked exercises for the pinned September 2026 checkout. Validation scope and source revisions are retained in the chapters below.

<a id="mlir"></a>
## MLIR: an annotated source map
<a id="mlir--mlir-an-annotated-source-map"></a>

For how this design differs from tinygrad, read the [cross-project comparison and coverage assessment](../design-comparison.md).

If compiler terminology is new, start with the [shared first-principles guide](../first-principles.md). This page assumes you can read array code, but introduces MLIR concepts before asking you to inspect C++.

MLIR is a compiler construction framework: one extensible representation, multiple vocabularies (dialects), and reusable verification, analysis, and rewriting infrastructure. It does **not** prescribe a model runtime or one universal lowering pipeline. The useful starting question is: **what information must remain explicit so the next transformation can be correct?**

This map targets the updated standalone checkout `/home/boop/builds/llvm-project`, revision **`e3c4c16567e3074dcd42da664fcb91298fd8c0fb`**, commit dated **2026-09-17**. Source links below are pinned to that revision. The separate checkout `tt-lang/third-party/llvm-project` is at **`37aca9d384347f4f965fa137b0f5463156ba590f`**; do not mix generated headers or pass APIs between these snapshots. The standalone checkout was chosen because it is the user's existing general LLVM source tree. The standalone checkout was updated to official upstream `main` fetched on 2026-09-17; this map describes that pinned snapshot.

**Coverage:** every top-level `mlir/lib` subsystem is routed below; selected dialects and the main transformation contracts receive deeper treatment. This is not an audit of every operation, backend, or rewrite. Rationale is an interpretation of the linked implementation/contracts; no performance measurements or executable pipeline validation were performed. [Exercises and worked solutions](README.md#exercises) separate reading-only work from optional compiled tools.

<a id="mlir--start-with-the-problem-mlir-solves"></a>
### Start with the problem MLIR solves

Suppose your Python program computes `C = A @ B`. A compiler could immediately expand that into loops, loads and additions. But a later optimization would then have to rediscover that those loops form a matrix multiply. Keeping an explicit `linalg.matmul` operation lets later stages ask directly: which dimensions are outputs, which dimension is summed, and which input elements are needed for one output tile?

MLIR lets a compiler keep these high-level facts and replace them with implementation decisions when it is ready. Its **intermediate representation (IR)** is the compiler's editable description of a program. **Lowering** makes that description more concrete: matmul becomes loops, loops become branches, and memory accesses eventually become machine instructions. Lowering preserves the computation but often discards convenient structure.

A **dialect** is a named vocabulary of operations and types in this common representation. `linalg.matmul` belongs to Linalg; `arith.addf` belongs to Arith. They can coexist in one program, just as array operations and scalar arithmetic coexist in Python. A dialect is neither a device nor necessarily a compilation stage. MLIR supplies transformation tools; the compiler built with MLIR chooses the route through them. Unlike tinygrad, MLIR itself has no single Tensor-to-kernel pipeline.

<a id="mlir--a-reading-order-that-avoids-starting-with-c-machinery"></a>
### A reading order that avoids starting with C++ machinery

1. Read the short IR example below and [LangRef][lang].
2. Read `tensor`, `linalg`, and `memref` in the dialect table; distinguish values from storage.
3. Read rewriting, conversion, and bufferization below. These are different contracts.
4. Follow the matmul trace and then one implementation, [Linalg loop lowering][loops].
5. Read [Operation][operation], [PatternMatch][patterns], and [DialectConversion][conversion] with those examples in mind.
6. Study [RMSNorm and fusion across kernel boundaries](rmsnorm-kernel-fusion.md): reduction synchronization, producer/consumer fusion, lifetime, and launch elimination.
7. Only then inspect generated op definitions, interfaces, and custom dialect scaffolding.

<a id="mlir--the-ir-foundation-why-these-objects-exist"></a>
### The IR foundation: why these objects exist

```mlir
module {
  func.func @twice(%x: i32) -> i32 {
    %result = arith.addi %x, %x : i32
    return %result : i32
  }
}
```

Read the example as `def twice(x): return x + x`, with explicit 32-bit integer types. `%` introduces a value name, `@` a symbol name such as a function, and the text after `:` gives a type. `arith.addi` takes two **operands** (input values) and produces one **result**. The spelling `return` is the convenient printed form of `func.return`.

Each named value is defined once: this is **static single assignment (SSA)**. `%result` always means this addition's result, rather than a variable later assignments overwrite. `%x` is also a value, but comes from a function argument rather than a defining operation. A tensor update can similarly produce a new value while preserving the old one's meaning; physical memory reuse is a later decision.

`module`, `func.func`, `arith.addi`, and `func.return` are all **operations**. Operations can contain **regions** holding nested program structure. A region contains **blocks**; each block is a sequence of operations with arguments at its entry. Here the function body has one block, with `%x` as its argument. Loops and branches use the same machinery for their bodies and incoming values. A **terminator**, such as the return, ends a block and determines what happens next.

A value must be available where it is used. In ordinary control flow, a definition **dominates** a use when every path to that use passes through the definition. A value computed only in one branch cannot simply be used after either branch. MLIR also maintains **use-def lists**: bookkeeping linking values to the operations that consume them, so replacing a result can update its consumers.

The table below is a reference to return to after that example. **Uniqued** objects share a stored instance of the same type or attribute within an `MLIRContext`. **Traits** describe reusable operation properties; **interfaces** expose queryable capabilities, such as reporting memory reads. An **SSACFG** region uses ordinary control-flow graph rules; a **graph** region has a different ordering/execution contract. Its containing operation determines which applies. Generic assembly printing exposes the common representation behind the convenient syntax.

| Abstraction and source | Why it exists | Invariant / sharp edge |
|---|---|---|
| [Operation][operation], [OperationSupport][opsupport] | Common container for operands/results, regions, successors, attributes/properties, and location; dialect ops supply semantics. | An op name does not itself prove semantics. Registered verifiers and interfaces matter. Mutation must maintain use lists, dominance, types, and region contracts. |
| [Value][value], [use-def lists][uses] | Uniform handle for an op result or block argument; enables replacing uses and tracing producers. | Values do not own a computation independently of its containing IR. Replacing uses with a same-typed value can still violate dominance or semantics. |
| [Region][region], [Block][block] | Nested structure and control flow without inventing a new AST for each language. Block arguments express merge values and function/loop inputs. | Regions may have SSACFG or graph semantics; dominance rules are not identical. Terminators, number of blocks, and capture rules are operation-specific. |
| [Types][types], [Attributes][attributes], [BuiltinTypes.td][builtin-types] | Types describe value domains; attributes describe compile-time metadata/constants. Shared storage makes comparison and reuse efficient. | Types/attributes are context-owned, generally immutable uniqued objects. A shaped type is not a physical allocation. `index` does not universally mean `i64`. |
| [MLIRContext][context], [Dialect][dialect] | Own uniqued objects, register dialect definitions, provide shared infrastructure. | Registration, loading, and available extensions affect which operations and interfaces are usable. Context lifetime must cover the IR that refers to it. |
| [OpDefinition][opdefinition], [interfaces][interfaces] | Traits encode reusable structural properties; interfaces expose semantic capabilities without hard-coding all op classes. | Claiming purity, alias behavior, or loop semantics incorrectly can make generic optimization unsound. A familiar name is not an interface implementation. |
| [SymbolTable][symbols] | Name-based references across isolated regions, such as function calls. | A symbol reference is not an SSA use; SSA replacement does not rename symbol references. Visibility and nested symbol resolution matter. |
| [Verifier][verifier], [Dominance][dominance] | Enforce structural contracts and availability of values. | Verification catches encoded invariants, not arbitrary semantic equivalence of a rewrite. |

A useful tinygrad comparison: UOps and MLIR operations both let compiler stages preserve semantics while changing representation. MLIR adds explicit region/block structure, SSA ownership, dialect registration, and interface contracts. A tinygrad matcher rule is closest to a rewrite pattern, not to an entire MLIR dialect or pass manager.

<a id="mlir--module-by-module-navigation"></a>
### Module-by-module navigation

Use this inventory by question: “what is a program made of?” leads to `IR`; “what can I prove?” leads to `Analysis`; “how do I change it?” leads to `Rewrite`, `Transforms`, and `Conversion`; “how do I run it?” leads to `Target` and `ExecutionEngine`.

Some shorthand used below: an **ABI** (application binary interface) specifies argument passing and data representation at a compiled-code boundary. A **JIT** compiles during execution. **CSE** (common subexpression elimination) merges equivalent computations when safe. **Liveness** asks whether a value is still needed; **alias analysis** asks whether references can reach the same memory; **Presburger** reasoning proves facts about restricted integer arithmetic, often indices and loop bounds.

Unless noted, directory names are under `mlir/lib`; public counterparts are under `mlir/include/mlir`. The [pinned library tree][lib] and [public API tree][include] are the authoritative inventory.

| Module | Purpose / why separate | Where mistakes hide |
|---|---|---|
| `IR` | Operations, values, contexts, types, attributes, printing, verification. | Lifetime, dominance, region semantics, invalid mutation. |
| `AsmParser`, `Parser` | Assembly parsing support and complete IR parsing. | Pretty syntax conceals defaults; accepting unregistered ops weakens checking. |
| `Bytecode` | Versioned compact IR serialization. | Bytecode is not machine code; dialect evolution requires compatibility handling. |
| `Dialect` | Semantically distinct op/type families plus their transforms. | A dialect is not necessarily one compilation stage. Dialects coexist. |
| `Interfaces` | Cross-dialect capabilities: effects, calls, control flow, inference, destination style. | Missing interfaces block transforms; incorrect ones miscompile. |
| `ABI` | Map MLIR types into LLVM ABI type descriptions using data layout. | A mapped type alone does not implement a complete calling convention. |
| `Remark` | Stream/import compiler optimization remarks. | A remark explains a compiler decision, not a performance measurement. |
| `Analysis` | Alias, dataflow, liveness, Presburger and other reusable facts. | Conservative unknown results are not proof of absence. Mutation invalidates facts. |
| `Rewrite` | Pattern application and supporting infrastructure. | Rewriter notifications are part of correctness for worklists/listeners. |
| `Transforms` | Greedy rewriting, canonicalization, CSE, dialect conversion and general passes. | Different drivers give the same pattern different scheduling/completion contracts. |
| `Conversion` | Specific source-to-target lowering families. | Registering patterns does not establish that an entire input program is legal. |
| `Pass` | Pass execution, nesting, analysis management, instrumentation. | Wrong anchor or undeclared dependence can skip work or fail verification. |
| `TableGen` | Support library for reading declarative op/type/interface/pass records. | Generated APIs come from the build tree, not just checked-in headers. |
| `Target` | Translation between MLIR and external representations, especially LLVM IR/SPIR-V. | LLVM dialect and LLVM IR are separate representations. |
| `ExecutionEngine` | JIT support and runtime integration. | A valid LLVM module still needs symbols, ABI, and runtime libraries. |
| `CAPI`, `Bindings` | Stable-ish C boundary and language binding implementation. | Ownership/context and API availability differ from direct C++. |
| `Tools`, `Query`, `Reducer` | Optimizer driver infrastructure, structural queries, reducing failing IR. | Reduction requires an interestingness predicate that preserves the actual failure. |
| `Debug`, `Support` | Debug actions, diagnostics/support utilities. | Debug instrumentation is not an optimization pipeline. |

The upstream tests use **lit** to run command recipes and **FileCheck** to match expected properties in command output. These tests often check transformed IR without executing the numerical computation.

Other top-level areas: [`tools`][tools] contains binaries including `mlir-opt`, `mlir-translate`, and generators; [`test`][tests] contains executable specifications using lit/FileCheck; [`unittests`][unittests] tests APIs; [`examples`][examples] contains end-to-end teaching projects such as Toy; [`python`][python] exposes Python packages; [`docs`][docs] explains contracts; `cmake`, `utils`, and `benchmark` support building, development, and measurement. Read a transform's regression tests alongside its implementation: tests often expose a precondition much faster than a class hierarchy.

<a id="mlir--tablegen-where-an-operations-contract-lives"></a>
### TableGen: where an operation's contract lives

Defining an operation requires several consistent pieces: a name, legal input/result types, printed form, and checks. Writing each independently repeats facts and invites disagreement. **TableGen** is LLVM's code generator for declarations in `.td` files. MLIR's **ODS** (Operation Definition Specification) is its vocabulary for declaring operations. A declaration can request a hook such as a constant folder, while handwritten C++ implements that hook.

[OpBase.td][opbase] supplies the vocabulary used by dialect `.td` files. For example, [ArithOps.td][arith] declares operand/result constraints, traits, assembly formats, and hooks for arithmetic operations. TableGen generates C++ wrappers, parsing/printing, and parts of verification; handwritten implementations add semantics that the declarations cannot express. [Defining operations][ods] explains the split.

This exists to keep an operation's many surfaces consistent. It does not make all generated operations correct automatically: a reduction's algebraic assumptions, aliasing contract, or verifier can still be wrong. Search `.td` before searching a generated `*.inc`. For Linalg named operations inspect both [LinalgStructuredOps.td][linalg] (including matmul) and [LinalgNamedStructuredOps.yaml][linalg-yaml], whose specification feeds generation for other named operations. Declarative rewrites ([DRR][drr], [PDLL][pdll]) describe patterns, while ODS describes operations; these are related but distinct jobs.

<a id="mlir--pattern-rewriting-what-is-the-driver-promising"></a>
### Pattern rewriting: what is the driver promising?

Consider simplifying integer `x + 0` to `x`. A **pattern** recognizes the shape and proposes a replacement. A **driver** chooses where and in what order to try patterns, including whether to revisit changed operations. The **rewriter** performs edits while informing the driver. This separation lets a rule participate in different transformation strategies.

Start with [PatternMatch.h][patterns], [PatternRewriter guide][rewrite-guide], and [GreedyPatternRewriteDriver.cpp][greedy]. A `RewritePattern` identifies a root and implements `matchAndRewrite`; `PatternBenefit` ranks competing matches. A `PatternRewriter` provides creation/replacement/erasure APIs and notifications so the driver can maintain its state.

Why many pattern sets exist: the same arithmetic identity, structured transformation, or legalization rule belongs to a particular semantic stage and driver. Tiling a structured op needs different preconditions from canonicalizing an arithmetic expression or rewriting its types for an ABI. Combining everything into one greedy set loses control over when those facts hold.

A **side effect** changes observable state, for example a memory write or I/O. **Speculation safety** asks whether executing an operation on an additional path could change behavior, for example by triggering an error. These matter when a rewrite moves computation out of a branch or deletes an unused result.

Sharp edges:

- Complete matching before mutating; return failure without having changed the IR. Use rewriter APIs, including notified in-place modification, rather than bypassing driver bookkeeping.
- A higher benefit is an ordering preference, not a global optimizer or measured speedup.
- Greedy application needs convergence. Two valid opposite-direction rewrites can oscillate; iteration limits do not prove a normal form.
- Effects, speculation safety, and dominance matter when moving code. An unused result does not imply the operation is removable.
- Pattern match failure normally means "try something else", not "the pass failed". A required lowering must establish completion separately.

**Canonicalization** means choosing simpler or preferred equivalent forms, such as removing an integer addition of zero. A **fold** is a restricted local simplification. Canonicalization ([contract][canonical], [implementation][canonical-cpp]) greedily applies operation canonicalization patterns and folds. It is best effort, bounded, and intended to simplify subsequent work. Pipelines must not depend on canonicalization for correctness. `fold` is intentionally narrower than arbitrary rewriting: it can return existing values/constant attributes or perform supported root folding, rather than arbitrarily constructing a replacement subgraph.

<a id="mlir--dialect-conversion-a-proof-obligation-about-the-result"></a>
### Dialect conversion: a proof obligation about the result

Simplification can stop while additions remain. Required lowering has a stronger goal: for example, no `toy.add` may remain because the next stage cannot execute it. **Legality** means “accepted by this stage's target,” rather than “mathematically correct.” A valid input operation may intentionally be illegal for the output stage.

Read [DialectConversion.h][conversion], [implementation][conversion-cpp], and [conversion guide][conversion-guide]. Four pieces work together:

1. A `ConversionTarget` classifies operations as legal, dynamically legal, illegal, or unknown.
2. `ConversionPattern`s describe rewrites, often consuming remapped operands through an adaptor.
3. A `TypeConverter` specifies type changes, signature conversion, and materialization bridges.
4. A conversion driver coordinates rewrites and checks the requested legalization obligation.

For example, a pattern could replace `toy.add` with `arith.addf` while a type converter replaces a custom numeric type with `f32`. An **adaptor** supplies operands after conversion. **Materialization bridges** connect old and new representations where needed during conversion; merely connecting representations does not implement an arbitrary executable conversion.

**Partial conversion** can leave pre-existing unknown operations; explicitly illegal operations must be eliminated/legalized. **Full conversion** requires the whole relevant IR to satisfy the target's legality requirements. A legal container is not automatically recursively legal: recursive legality is an explicit, powerful declaration that can exempt nested IR from conversion.

This distinction is essential when reviewing a compiler: "the pass succeeded" means only the obligation the author requested. Marking too much legal can conceal an incomplete lowering. Reading original operands instead of converted adaptor operands can reintroduce stale types. `builtin.unrealized_conversion_cast` can connect intermediate representations; it is not executable conversion code. Reconciliation only removes compatible cast scaffolding, not arbitrary missing ABI conversions.

<a id="mlir--pass-management-choosing-order-and-scope"></a>
### Pass management: choosing order and scope

A **pass** is a unit of compiler work, such as simplifying operations or lowering loops. A **pass manager** runs passes in an order and selected scope. Its **anchor** is the operation it runs on: a function pass handles a selected function, while a module pass can coordinate changes across functions. An **analysis** computes facts about the program; cached facts must be discarded if changes make them stale.

[PassManager.h][passmanager], [PassManagement.md][pass-guide], and [Pass.cpp][pass-cpp] describe a pass manager anchored on an operation type. A pipeline such as `builtin.module(func.func(canonicalize))` schedules function-local work inside a module. Some transformations require module scope because function signatures and call sites must change together.

Passes can declare dependencies on dialects, obtain cached analyses, preserve valid analyses, and signal failure. Nested execution enables concurrency where the contracts permit it; a function pass should not casually inspect or mutate siblings. Verification and IR printing around passes help locate the first broken invariant. A production compiler's pipeline builder is therefore part of its semantics, not just a list of optional optimizations.

<a id="mlir--dialects-why-retain-each-vocabulary"></a>
### Dialects: why retain each vocabulary?

Read this table as questions about one array computation. `tensor` describes its value; `linalg` describes indexing and arithmetic; `scf` makes loops explicit; `memref` describes storage; `vector` groups element computations; `gpu` assigns device work and synchronization. A compiler may use only some of these.

An **indexing map** says which coordinates an iteration accesses: matmul iteration `(m,n,k)` reads `A[m,k]` and `B[k,n]` and updates `C[m,n]`. An **iterator role** distinguishes independent output indices (`m,n`) from a reduction index contributing repeatedly to one output (`k`). A **scalar payload** is the per-element arithmetic, here multiply then add. A **tile** is a bounded piece of iteration space handled together.

A **memory space** distinguishes storage such as device-global and workgroup-shared memory; a **stride** describes the address step between neighboring indices. An **intrinsic** exposes a compiler-recognized operation, often related to target instructions. The Transform dialect's **payload** is the program being optimized; a **handle** is a reference its transformation program uses to select payload entities.

The invariant column identifies what to check before trusting a transformation, rather than claiming every invariant is mechanically verified.

| Dialect / source entry | Why it exists | Invariant and sharp edge |
|---|---|---|
| [builtin][builtin] | Common module, types, attributes, and conversion scaffolding. | A module packages IR; it provides no automatic runtime or target. |
| [func][func] | Functions, calls, returns, symbol-level ABI before target lowering. | Call signatures and returns must agree; converting a body alone may leave incompatible callers. |
| [arith][arith] | Scalar/vector arithmetic independent of a machine ISA. | Integer signedness is often in the operation; floating reassociation needs appropriate semantics/flags. `index` width is target-dependent. |
| [tensor][tensor] | Immutable shaped values, slices, inserts, dimensions. | Tensor SSA versions must remain distinguishable even when later storage is reused. `tensor.empty` does not supply initialized elements. |
| [linalg][linalg] | Structured computation with indexing maps, iterator roles, and scalar payloads. | Reduction vs parallel dimensions and destination semantics carry information needed by tiling/fusion. A matmul output is an accumulator input, not implicitly zero. |
| [scf][scf] | Structured loops, conditionals, yields, parallel constructs. | Loop-carried values/yields must agree; parallel execution requires independence or specified reductions. |
| [affine][affine] | Restricted integer expressions and loop/access structure amenable to stronger reasoning. | Expressions such as `2*i + 3` fit this restricted arithmetic; multiplying two varying indices generally does not. Loop dimensions and symbolic parameters also have scope restrictions. |
| [memref][memref] | Mutable memory with shape, layout, strides, and memory spaces. | Aliasing, lifetime, alignment, and bounds become explicit concerns. A subview usually aliases its source. |
| [vector][vector] | Explicit vector computation and memory transfers before choosing ISA instructions. | A multidimensional vector is not guaranteed to fit one hardware register. Transfer padding/masks and contraction semantics must survive lowering. |
| [gpu][gpu] | Device launch, kernel regions/functions, execution indices, memory and synchronization. | Kernel mapping and synchronization are semantic choices. Host launch lowering also needs a runtime and binary compilation path. |
| [LLVM][llvm] | LLVM-level types, operations, and intrinsics represented inside MLIR. | Translation to LLVM IR is another step; memref descriptors and function conventions must match at boundaries. |
| [transform][transform] | A program that controls transformations on separate payload IR. | Handles refer to payload entities and can be invalidated/consumed. A schedule can fail even while the payload is valid. |
| [bufferization][bufferization] | Tensor-to-buffer boundary and associated alias/read/write contracts. | In-place reuse requires a proof about observations, not just matching shapes. Allocation and deallocation are separate concerns. |
| [async][async] | Tasks, tokens, and async values with dependencies. | A token dependency is not by itself a device-specific memory visibility proof. Lowering selects an execution/runtime model. |
| [spirv][spirv] | SPIR-V's execution, storage, and capability model. | Valid generic IR may violate the chosen target environment's capabilities or layout rules. |
| [amdgpu][amdgpu] | AMD-specific operations useful before ROCDL lowering. | Address spaces, supported instructions, and target constraints matter; inspect [AMDGPUToROCDL][amd-conv]. |
| [nvgpu][nvgpu] | NVIDIA-specific matrix/async and related higher-level device operations. | Tile shapes, address spaces and synchronization are hardware contracts; inspect [NVGPUToNVVM][nv-conv]. |

Also recognize [ControlFlow][cf] (`cf` branches after structured control flow is lowered), `math` (math operations requiring target/library decisions), `index` (index arithmetic), `DLTI` (data layout information), `NVVM`/`ROCDL` (vendor LLVM intrinsics), and `PDL`/`PDLInterp` (pattern description/execution). Remaining families in the [dialect directory][dialects] include sparse tensors, quantization, shape, TOSA, architecture-specific vector extensions, distributed/parallel models, and C emission. Their presence does not mean a compiler using MLIR supports them all.

<a id="mlir--bufferization-the-abstraction-boundary-worth-studying-carefully"></a>
### Bufferization: the abstraction boundary worth studying carefully

A tensor value describes contents, not an allocation. A `memref` describes mutable storage that code loads and stores. **Bufferization** chooses storage for tensor computations while preserving their value semantics. **Aliasing** means two references can reach the same storage; **lifetime** is how long that storage remains valid.

Imagine `old = [10, 20]` and a tensor operation producing `new = [99, 20]`. If later code needs both `old[0]` and `new[0]`, it must get `10` and `99`. Overwriting a shared buffer too early would return `99` twice. If the old value is never needed again, reuse may be safe. Equal shapes alone cannot settle that question.

[OneShotAnalysis.cpp][oneshot], [BufferizableOpInterface.td][buffer-interface], and [Bufferization.md][buffer-guide] explain why this is a dedicated analysis, not a textual `tensor` -> `memref` substitution.

For a destination-style operation, an output operand identifies a candidate buffer for the result. If overwriting that buffer would change an observation of an older tensor SSA value, in-place reuse is invalid. Analysis tracks reads, writes, aliases and equivalences; a conflict can require a fresh allocation/copy. A shape match alone says nothing about that proof.

Three common surprises:

1. `outs(%init)` can mean the operation reads the initial value. For matmul, filling the destination with zero is part of computing plain `A * B` rather than `C + A * B`.
2. Unknown/custom ops need an appropriate bufferization interface or an explicitly supported boundary policy. They do not inherit correct alias information automatically.
3. One-Shot Bufferize does not free all buffers. Ownership-based deallocation and ABI choices are additional work; see [deallocation guide][deallocation].

<a id="mlir--follow-one-matmul-without-inventing-a-universal-pipeline"></a>
### Follow one matmul without inventing a universal pipeline

Start with `A: tensor<MxKxf32>`, `B: tensor<KxNxf32>`, and an initialized destination `C: tensor<MxNxf32>`. `linalg.matmul` represents `C + A * B`, with parallel `m,n` dimensions and reduction `k`. [MatmulOp definition][linalg] preserves this structure; [Linalg interfaces][linalg-interfaces] let transformations ask about it generically.

In ordinary loop notation the operation means:

```python
C = copy(C_initial)
for m in range(M):
    for n in range(N):
        for k in range(K):
            C[m, n] += A[m, k] * B[k, n]
```

`C_initial` is the supplied accumulator; use zeros for plain matrix multiplication. For `M=2, N=4, K=3`, eight independent output elements each receive three product contributions. Tiling groups some elements; vectorization expresses several element computations together. Neither changes which contributions belong to an output. **Register allocation** later assigns temporary values to limited hardware registers; **code emission** writes the final instructions.

One possible CPU route:

| Decision / transition | Preserved information and source | What this does not decide |
|---|---|---|
| Tile/fuse while Linalg structure remains | [Tiling.cpp][tiling], indexing maps and iterator kinds. | Good tile sizes, cache policy, or profitability automatically. |
| Bufferize tensor values into memory | [One-Shot analysis][oneshot], interfaces, alias/conflict proof. | Final ownership/deallocation policy. |
| Lower buffer Linalg to loops | [Loops.cpp][loops], [regression examples][loops-test]; explicit loops, loads, arithmetic, stores. | Efficient vector instructions. This is a useful baseline. |
| Alternatively vectorize structured computation | [Vectorization.cpp][vectorization], vector transfers/contractions. | A single universally optimal route; vectorization may be performed before or after other transformations under their preconditions. |
| Lower structured control flow | [SCFToControlFlow][scf-conv]; branches and block arguments. | Memory ABI and machine instruction selection. |
| Lower arithmetic, memrefs, functions, vectors | [Conversion tree][conversions], especially `ArithToLLVM`, `MemRefToLLVM`, `FuncToLLVM`, `VectorToLLVM`, `ControlFlowToLLVM`. | External function implementations or runtime symbol availability. |
| Translate LLVM dialect | [LLVM IR export][llvm-export]. | Final target optimization, register allocation and code emission, handled by LLVM. |

A GPU route instead introduces mapping to workgroups/threads, memory spaces, synchronization, and device-specific operations, then uses a target such as NVVM, ROCDL, or SPIR-V plus a host runtime path. None of these generic paths automatically implements Blackhole's distributed memory, circular-buffer protocol, Tensix compute, or multi-processor dispatch. Those need explicit target semantics and a backend/runtime contract.

For CAIR, the highest-value sequence is SSA/regions -> rewrite contracts -> legality -> bufferization -> structured scheduling -> backend ABI. Each step teaches a different correctness obligation. The [exercise bank](README.md#exercises) follows this order and includes source-only tasks before optional builds.

<!-- Links are pinned to the inspected standalone checkout. -->
[lang]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/LangRef.md
[operation]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Operation.h#L83
[opsupport]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/OperationSupport.h
[value]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Value.h#L96
[uses]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/UseDefLists.h
[region]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Region.h#L26
[block]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Block.h#L33
[types]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Types.h
[attributes]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Attributes.h
[builtin-types]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/BuiltinTypes.td
[context]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/MLIRContext.h#L63
[dialect]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Dialect.h
[opdefinition]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/OpDefinition.h
[interfaces]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/Interfaces.md
[symbols]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/SymbolTable.h
[verifier]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/IR/Verifier.cpp
[dominance]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/Dominance.h
[lib]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib
[include]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir
[tools]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/tools
[tests]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/test
[unittests]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/unittests
[examples]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/examples
[python]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/python
[docs]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs
[opbase]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/OpBase.td
[arith]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Arith/IR/ArithOps.td#L271
[ods]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/DefiningDialects/Operations.md
[linalg-yaml]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Linalg/IR/LinalgNamedStructuredOps.yaml
[drr]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/DeclarativeRewrites.md
[pdll]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/PDLL.md
[patterns]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/PatternMatch.h#L799
[rewrite-guide]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/PatternRewriter.md
[greedy]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Transforms/Utils/GreedyPatternRewriteDriver.cpp
[canonical]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/Canonicalization.md
[canonical-cpp]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Transforms/Canonicalizer.cpp
[conversion]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Transforms/DialectConversion.h#L1078
[conversion-cpp]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Transforms/Utils/DialectConversion.cpp
[conversion-guide]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/DialectConversion.md
[passmanager]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Pass/PassManager.h
[pass-guide]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/PassManagement.md
[pass-cpp]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Pass/Pass.cpp
[builtin]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/IR/BuiltinOps.td
[func]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Func/IR/FuncOps.td
[tensor]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Tensor/IR/TensorOps.td
[linalg]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Linalg/IR/LinalgStructuredOps.td#L691
[scf]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/SCF/IR/SCFOps.td
[affine]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Affine/IR/AffineOps.td
[memref]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/MemRef/IR/MemRefOps.td
[vector]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Vector/IR/VectorOps.td
[gpu]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/GPU/IR/GPUOps.td
[llvm]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/LLVMIR/LLVMOps.td
[transform]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Transform/IR/TransformOps.td
[bufferization]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Bufferization/IR/BufferizationOps.td
[async]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Async/IR/AsyncOps.td
[spirv]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/SPIRV/IR
[amdgpu]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/AMDGPU/IR/AMDGPU.td
[amd-conv]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Conversion/AMDGPUToROCDL
[nvgpu]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/NVGPU/IR/NVGPU.td
[nv-conv]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Conversion/NVGPUToNVVM
[cf]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/ControlFlow/IR/ControlFlowOps.td
[dialects]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect
[oneshot]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Bufferization/Transforms/OneShotAnalysis.cpp
[buffer-interface]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Bufferization/IR/BufferizableOpInterface.td
[buffer-guide]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/Bufferization.md
[deallocation]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/OwnershipBasedBufferDeallocation.md
[linalg-interfaces]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Linalg/IR/LinalgInterfaces.td
[tiling]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Linalg/Transforms/Tiling.cpp
[loops]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Linalg/Transforms/Loops.cpp
[loops-test]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/test/Dialect/Linalg/loops.mlir
[vectorization]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Linalg/Transforms/Vectorization.cpp
[scf-conv]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Conversion/SCFToControlFlow
[conversions]: https://github.com/llvm/llvm-project/tree/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Conversion
[llvm-export]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Target/LLVMIR/ModuleTranslation.cpp

<a id="exercises"></a>
## MLIR exercises and worked solutions
<a id="exercises--mlir-exercises-and-worked-solutions"></a>

These exercises use the snapshot and source links in the [map](README.md#mlir). Tasks 1-8 require only the checkout and a text editor. Tasks 9-11 require `mlir-opt`; task 12 is a source investigation. None requires a GPU or Tenstorrent card.

**Validation status:** source paths and relevant contracts were inspected. `mlir-opt` was not found on PATH or among enumerated files in `/home/boop/builds`; the optional command exercises below were **not executed**. Their outputs are expectations derived from the source, not captured logs. Existing unrelated toolchain installations may provide another version; check the revision before interpreting differing output.

Read the [map's first-principles introduction](README.md#mlir--start-with-the-problem-mlir-solves) before starting. Each exercise asks for a **contract**: a condition the representation or transformation must preserve. Try answering in three steps: what result does the original program promise, what changes, and what observation could expose a mistake? Source filenames below are relative to `/home/boop/builds/llvm-project/mlir` unless explicitly prefixed with `mlir/`.

<a id="exercises--1-count-the-ir-objects-15-minutes-ssa"></a>
### 1. Count the IR objects (15 minutes; SSA)

Using `@twice` in the map, identify operation results, block arguments, blocks, and regions. Explain why `%x` has no defining operation. Inspect `mlir/include/mlir/IR/Value.h` in the standalone checkout.

**Worked solution:** start at the outermost operation. The module has a body region containing a block; that block contains the function operation. The function has its own body region and entry block, containing the addition and return. `%result` is the sole arithmetic operation result; `%x` is the entry block argument owned by the function's body block. The module and function each have a region and a block in this example. `func.return` is an operation without a result. `Value` represents both `OpResult` and `BlockArgument`, so following a defining-op link is not valid for every SSA value. An argument's meaning comes from its enclosing operation/control-flow contract.

**Assessment:** credit requires explaining ownership and why values are not all expression-tree nodes.

<a id="exercises--2-find-the-generatedhandwritten-boundary-20-minutes-ods"></a>
### 2. Find the generated/handwritten boundary (20 minutes; ODS)

Find integer addition in `include/mlir/Dialect/Arith/IR/ArithOps.td`. Follow its base class and locate its handwritten folding logic in `lib/Dialect/Arith/IR/ArithOps.cpp`. Which facts come from the declaration, and which require C++?

**Worked solution:** separate “is this operation well formed?” from “can this computation be simplified?” The TableGen declaration/base constraints describe the op name, operands/results, traits and assembly surface. The `hasFolder` hook requests generated declarations for folding; C++ implements cases such as constant evaluation and arithmetic identities. The generated `*.inc` is a build artifact connecting the two. A verifier accepting an operation does not prove a newly added fold is equivalent.

**Extension:** explain why integer `x + 0` and floating-point `x + 0.0` need different semantic care (signed zero and floating-point flags).

<a id="exercises--3-design-a-rewrite-that-terminates-20-minutes-patterns"></a>
### 3. Design a rewrite that terminates (20 minutes; patterns)

A pass has rules `x + x -> x * 2` and `x * 2 -> x + x`, each with positive benefit. Does greediness guarantee convergence? How should the pass be repaired?

**Worked solution:** apply the rules by hand: `x + x -> x * 2 -> x + x -> ...`. Neither result is permanent, so the driver can revisit the same forms indefinitely. Benefits rank matches and do not prevent a cycle. Select a preferred representation appropriate to the stage and keep one direction there, or require each rewrite to decrease a quantity that cannot decrease forever, such as a suitable nonnegative complexity score. Separating stages can be appropriate if each stage has a clear contract and is not repeatedly cycled. An iteration cap bounds time but does not establish canonicality. See `docs/Canonicalization.md` and `include/mlir/IR/PatternMatch.h`.

**Assessment:** reject solutions that simply raise benefit or increase the iteration cap.

<a id="exercises--4-partial-conversion-is-not-complete-lowering-25-minutes-legality"></a>
### 4. Partial conversion is not complete lowering (25 minutes; legality)

A target marks `toy.add` illegal and `arith.addf` legal; an unrelated `toy.print` is unknown. A pattern converts every `toy.add`. Explain possible outcomes of partial versus full conversion. Then mark the enclosing module recursively legal: what danger appears?

**Worked solution:** after the pattern runs, the program contains `arith.addf` and `toy.print`. Check each against the chosen policy. `arith.addf` is accepted; `toy.print` has no classification. Partial conversion may succeed while leaving pre-existing unknown `toy.print`; all explicitly illegal operations must be handled. Full conversion cannot simply accept the unknown operation without legalizing it or making it legal through the target policy. A recursively legal module can exempt its nested operations from legalization, defeating the intended check. Read `ConversionTarget` and `applyPartialConversion` contracts in `include/mlir/Transforms/DialectConversion.h`.

**Extension:** distinguish "dynamically legal when operand types meet a predicate" from "recursively legal". The former checks a condition on an instance; the latter changes how nested IR is treated.

<a id="exercises--5-why-a-bufferization-copy-can-be-required-30-minutes-aliasing"></a>
### 5. Why a bufferization copy can be required (30 minutes; aliasing)

Suppose `%old` is a tensor. `%new = tensor.insert %v into %old[%i]` produces a modified version. A later operation reads `%old[%i]`, and the program also needs `%new`. Is reusing `%old`'s buffer for `%new` always valid?

**Worked solution:** choose `old = [10, 20]`, `i = 0`, and `v = 99`. The required observations are `old[0] == 10` and `new[0] == 99`. In tensor semantics `%old` retains its previous element. A store into the same buffer before the later old-value read would change the result. The implementation needs a proof that the read cannot observe the write, a legal reordering, or distinct storage/copy. The example's same index deliberately prevents relying on disjointness. Inspect read-after-write discussion in `docs/Bufferization.md` and conflict analysis in `lib/Dialect/Bufferization/Transforms/OneShotAnalysis.cpp`.

**Assessment:** same shape, single result, and destination style alone are insufficient proofs. The answer must identify the observation that would change.

<a id="exercises--6-the-uninitialized-matmul-trap-20-minutes-linalg"></a>
### 6. The uninitialized matmul trap (20 minutes; Linalg)

Consider a tensor `linalg.matmul` with `outs(%empty)` where `%empty = tensor.empty()`. Does this compute `A * B`? Give a correct initialization strategy.

**Worked solution:** test the smallest case: A contains `2`, B contains `3`, and the destination contains `7`. Matmul produces `7 + 2*3 = 13`, not `6`, because it accumulates into its destination. `tensor.empty` provides a shaped value with unspecified contents, not zeros. Fill the destination with a zero constant via `linalg.fill`, then use that initialized tensor as the matmul output operand. Alternatively, pass an existing initialized accumulator when the intended computation is `C + A * B`. Follow `include/mlir/Dialect/Linalg/IR/LinalgStructuredOps.td`, the named-op definitions, and `TensorOps.td`'s `EmptyOp` description.

**Assessment:** explicitly distinguish destination storage selection from destination numerical contents.

<a id="exercises--7-preserve-enough-structure-to-schedule-30-minutes-lowering"></a>
### 7. Preserve enough structure to schedule (30 minutes; lowering)

Why might a compiler tile a `linalg.matmul` before lowering it into loads/stores and nested loops? Does keeping Linalg guarantee fast code?

**Worked solution:** consider computing only output rows 0–15 and columns 0–15. The matmul indexing maps tell us immediately which A rows and B columns this tile needs, and that their products must still sum over the full reduction dimension. Parallel/reduction iterator roles distinguish the independent output elements from contributions to each element. These facts make legality and slicing structure explicit. Generic loop analysis may recover some information later, but that requires additional proofs. Keeping the structured form makes transformations easier to express; it does not choose profitable tile sizes, data layout, or a hardware instruction. Inspect `lib/Dialect/Linalg/Transforms/Tiling.cpp`, `Vectorization.cpp`, and `Loops.cpp`.

**Extension:** identify what a Blackhole backend must add: placement/memory spaces, inter-core transfers, synchronization/resource ownership, compute instruction selection, and launch/runtime ABI. A generic GPU conversion does not supply these contracts automatically.

<a id="exercises--8-a-valid-rewrite-with-an-invalid-lifetime-20-minutes-transform"></a>
### 8. A valid rewrite with an invalid lifetime (20 minutes; Transform)

A Transform dialect operation consumes a handle while replacing its payload operation. A later transform reuses that old handle. Why is valid payload IR insufficient to guarantee that this schedule succeeds?

**Worked solution:** imagine a handle selecting one matmul operation. A transform replaces that matmul with tiled operations. The old selected object no longer identifies the new operations, even if those operations correctly compute the answer. Transform IR therefore has its own handle use and invalidation contract. Replacing/consuming payload entities can invalidate mappings represented by old handles, including affected nested handles. Later schedule operations must use valid returned/reacquired handles as specified by the transform. Payload verification alone checks a different set of invariants. Inspect `docs/Dialects/Transform.md` and `include/mlir/Dialect/Transform/Interfaces/TransformInterfaces.td`.

<a id="exercises--optional-tools-what-is-actually-required"></a>
### Optional tools: what is actually required?

Source reading requires no build. Parsing and running standard passes needs **`mlir-opt`**. Translating LLVM dialect to LLVM IR needs **`mlir-translate`**. Running arbitrary lowered programs additionally requires a compatible execution engine/runtime and correct ABI; none of that is needed for the following inspection exercises.

If no compatible tools already exist, this is an optional CPU-only build from the inspected checkout. It has **not** been run as part of this map; LLVM/MLIR compilation can consume substantial time, disk, and RAM. Use an independent build directory and choose parallelism suitable for the machine.

```bash
cmake -S /home/boop/builds/llvm-project/llvm \
  -B /home/boop/builds/mlir-map-build -G Ninja \
  -DLLVM_ENABLE_PROJECTS=mlir \
  -DLLVM_TARGETS_TO_BUILD=Native \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_BUILD_EXAMPLES=OFF
cmake --build /home/boop/builds/mlir-map-build \
  --target mlir-opt mlir-translate --parallel 2
export MLIR_OPT=/home/boop/builds/mlir-map-build/bin/mlir-opt
"$MLIR_OPT" --version
```

This requires CMake, Ninja, a supported C/C++ compiler and normal LLVM build prerequisites. `Native` targets the host CPU; no vendor GPU SDK is needed for these passes. `FileCheck` and lit are only required when running the upstream regression harness, not for manually inspecting the examples below.

<a id="exercises--9-see-the-common-operation-representation-15-minutes-tool"></a>
### 9. See the common operation representation (15 minutes; tool)

Save this as `/tmp/mlir-map-add.mlir`:

```mlir
module {
  func.func @add_zero(%x: i32) -> i32 {
    %zero = arith.constant 0 : i32
    %result = arith.addi %x, %zero : i32
    return %result : i32
  }
}
```

```bash
"$MLIR_OPT" /tmp/mlir-map-add.mlir --mlir-print-op-generic
"$MLIR_OPT" /tmp/mlir-map-add.mlir --canonicalize
```

**Worked solution / expected observations:** generic printing exposes quoted operation names such as `"arith.addi"`, operand lists, and function input/output type information. Canonicalization can replace integer addition with `%x` and remove the unused constant; the function returns its argument directly. SSA names and exact formatting are not part of the expected result. A failure to parse should be investigated before blaming the optimization.

<a id="exercises--10-lower-a-small-matmul-to-explicit-loops-25-minutes-tool"></a>
### 10. Lower a small matmul to explicit loops (25 minutes; tool)

Save this as `/tmp/mlir-map-matmul.mlir`:

```mlir
module {
  func.func @matmul(%a: memref<2x3xf32>, %b: memref<3x4xf32>,
                    %c: memref<2x4xf32>) {
    linalg.matmul ins(%a, %b : memref<2x3xf32>, memref<3x4xf32>)
                  outs(%c : memref<2x4xf32>)
    return
  }
}
```

```bash
"$MLIR_OPT" /tmp/mlir-map-matmul.mlir --convert-linalg-to-loops
"$MLIR_OPT" /tmp/mlir-map-matmul.mlir \
  --convert-linalg-to-loops --convert-scf-to-cf
```

**Worked solution / expected observations:** use the dimensions to predict the result before reading printed IR. A is 2-by-3 and B is 3-by-4, so C has two rows and four columns; each C element receives three products. The first command exposes loops with bounds 2, 4, and 3, element loads from A/B/C, multiplication/addition, and a store to C. C remains an accumulator: this example intentionally starts with memrefs and does not allocate or initialize them. The second command replaces structured loop control with control-flow blocks/branches. A structured loop packages “initialize, test, run body, advance” in one operation; the lower form expresses those transitions as branches between blocks. This still is not machine code and has not tested numerical execution. Compare the `RUN` lines and checks in `mlir/test/Dialect/Linalg/loops.mlir`.

**Assessment:** explain which semantic information becomes less explicit after each step and which work (LLVM conversions, ABI, codegen/runtime) remains.

<a id="exercises--11-ask-a-verifier-for-a-useful-failure-15-minutes-tool"></a>
### 11. Ask a verifier for a useful failure (15 minutes; tool)

Change `@add_zero`'s return type to `i64` while leaving its argument/result/return operand at `i32`. Run `mlir-opt` again.

**Worked solution / expected observation:** parsing/verification rejects the mismatch between the return operand and the function's declared result. Restore the correct type; then try returning an out-of-scope SSA name and distinguish name resolution/dominance concerns from a numerical optimization bug. Diagnostic wording may vary; the exercise grades the violated invariant, not the exact string.

<a id="exercises--12-turn-one-upstream-test-into-a-cair-assignment-60-90-minutes-source-or-tool"></a>
### 12. Turn one upstream test into a CAIR assignment (60-90 minutes; source or tool)

Choose one case in `mlir/test/Dialect/Linalg/loops.mlir` or `mlir/test/Dialect/Arith/canonicalize.mlir`. Record the input contract, transform, expected property, and one near-miss case where the transformation must behave differently. Locate the implementation. If tools exist, execute only the relevant pass command from the test's `RUN` line; do not assume `%s` or FileCheck substitutions work directly in a shell.

**Worked solution outline:** write the specification first: `C[m,n] += sum_k A[m,k] * B[k,n]`. Then connect each loop/index in the expected output to that formula. For matmul lowering, the input contract includes shaped buffer operands and an initialized accumulator at execution time. Expected properties include reduction-carried updates to C and correct indexing of A(m,k)/B(k,n). A near-miss is a different contraction indexing pattern: hard-coding those accesses would be incorrect. The implementation is `Loops.cpp`, supported by Linalg indexing-map interfaces. A useful solution includes an argument about dataflow and dimensions, rather than only counting loops.

**Suggested submission rubric:** source evidence (2), invariant stated correctly (3), counterexample or negative case (3), validation status reported honestly (2). Require source-only and executed work to be labeled separately. This produces reusable exercises without confusing inferred behavior with tested behavior.

For the next level, [RMSNorm and fusion across kernel boundaries](rmsnorm-kernel-fusion.md) adds four worked exercises on launch elimination, reduction synchronization, memory traffic, and experimental evidence.
