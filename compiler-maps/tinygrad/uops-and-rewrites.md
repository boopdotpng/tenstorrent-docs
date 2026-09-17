# tinygrad UOps and rewrites and exercises

Production source map and worked exercises for the pinned September 2026 tinygrad checkout. Historical lowering investigations remain in Archives.

<a id="uops-and-rewrites"></a>
## Tinygrad UOps and rewrites: contracts, motivations, and failure modes
<a id="uops-and-rewrites--tinygrad-uops-and-rewrites-contracts-motivations-and-failure-modes"></a>

Audited against clean `master` **`107adc31701df0247dfa45e175984df906a68b53`**, dated 2026-09-17; audit 2026-09-17. The user requested master without the local Blackhole changes. This document therefore does **not** describe the local Tensix `renderer.program_matcher` extension. Relative source links point into the sibling checkout and line numbers are snapshot-specific. “Rationale” below is an inference from the implementation unless a source comment explicitly states it. Reading source demonstrates behavior, not that every transformation is correct for every input.

For the substantial end-to-end example, read [RMSNorm lowering and fusion between kernels](rmsnorm-kernel-fusion.md). The [worked exercises](uops-and-rewrites.md#rewrites-exercises) explain the small mechanisms needed to interpret that trace. The [mechanical matcher census](matcher-inventory.md) indexes 180 direct construction sites and 103 graph/list driver calls in production Python sources. The older [UOps reference](../../archive/tinygrad/uops-reference.md) and [matcher reference](../../archive/tinygrad/pattern-matchers-reference.md) remain useful historical material, but describe July 10, not this snapshot. In particular, **do not copy their UOp constructor/type assumptions into current code**.

For individual rules, use the [rule-by-rule reference](rules/README.md). This
page remains the overview: its family table is not an explanation of every
rule. The rule reference supplies matches, guards, results, examples, and
rationale, including validators and text emitters.

<a id="uops-and-rewrites--1-one-node-representation-several-languages"></a>
### 1. One node representation, several languages

Start with `t = x + 1; y = t * t`. Instead of immediately calculating `t`, tinygrad can record an `ADD` node whose inputs are `x` and `1`, then a `MUL` node whose two inputs both refer to that `ADD`. This is an **intermediate representation (IR)**: a program represented as data so other code can inspect and transform it. Each tinygrad node is a **UOp**. Their dependencies form a **directed acyclic graph (DAG)**: sharing is allowed, dependency cycles are not.

A compiler **phase** is one stage of transforming that description. A phase's **contract** says which forms it accepts and produces. For example, an early phase may say “sum an axis”; a later one must explain the iteration and running accumulator that implement the sum. **Lowering** adds those implementation details. Tinygrad reuses UOps across phases, so the node class alone cannot tell you how much has been decided. The optional [first-principles primer](../first-principles.md) gives the broader context.

In the constructor below, `op` names the operation, `src` holds its input nodes, `arg` holds operation-specific information, and `tag` can distinguish otherwise identical constructions. **Dtype** means numeric data type. A weak integer or float has not yet committed to a machine storage width; `CAST` expresses conversion to a specified type.

[UOp](../../../tinygrad/tinygrad/uop/ops.py#L230) is `UOp(op, src=(), arg=None, tag=None)`. There is no `dtype=` constructor field. Its `dtype` is derived recursively from the operation, sources, and argument. Its shape is also derived. To construct a typed constant, use `UOp.const(3, dtypes.int32)`, which currently produces `CAST(int32, CONST(3))`. Bare Python integer constants have `weakint` dtype; bare Python floats have `weakfloat`. This makes the old description “every UOp explicitly carries its dtype” misleading.

The [metaclass](../../../tinygrad/tinygrad/uop/ops.py#L192) interns nodes—reuses an existing object for an identical construction—using `(op, src, arg, tag, type(arg))`, with weak references. Weak references let unused nodes be garbage-collected; they are unrelated to weak numeric types. Equal live constructions share identity. `type(arg)` prevents Python's `True == 1` dictionary behavior from conflating constants. Metadata is stored separately. Although the dataclass is technically mutable for speed, treat it as immutable: use `replace`, which reconstructs/interns a node. Mutating a node's fields can invalidate interning, cached properties, and every other graph sharing it.

**Rationale:** sharing makes common subexpressions cheap and enables identity-based pattern constraints and rewrite memoization. The cost is that changes must rebuild the affected path while preserving unchanged nodes. An effectful operation, such as writing memory, also needs explicit dependencies to say when it happens. A `SINK` retains roots; it does not by itself promise execution order between siblings. `AFTER(value, effect, ...)` carries ordering while exposing the value. `STORE` is an effect, not the updated tensor value.

The [Ops enum and GroupOp sets](../../../tinygrad/tinygrad/uop/__init__.py#L13) classify syntax. They do not define phase legality. The executable [spec matchers](../../../tinygrad/tinygrad/uop/spec.py#L42) supply those contracts:

In the table, **materialization** means storing a computed value, a **range** represents iteration over positions, and **lanes** are element positions grouped for execution. Unrolling expands loop iterations; upcasting here exposes several element lanes within a thread's work, not numeric dtype promotion. `WMMA` represents matrix multiply-accumulate work mapped to matrix hardware. A **parameter interface** lists the values a kernel receives from its caller.

| Representation | Typical nodes | What the next stage must resolve |
|---|---|---|
| Tensor/function graph | movement ops, reductions, copies, calls, shaped values | materialization, movement index formulas, fusion boundaries |
| Rangeified kernel graph | `RANGE`, indexed expressions, `STAGE`, `END`, kernel `CALL`s | concrete buffers and parameter interfaces, iteration schedule |
| Optimized kernel graph | local/upcast/unroll/reduction axes, `WMMA`, shaped lanes | explicit loads, accumulators, hardware coordinates, scalar/lane lowering |
| Program graph | committed arithmetic types, explicit memory/control dependencies | ordering, instruction selection where applicable |
| Program container | `PROGRAM(SINK, LINEAR, SOURCE, BINARY)` progressively | rendering/assembly and compilation |

An op name alone cannot tell you its meaning. `INDEX` can select tensor elements, address storage, or manipulate late shaped lanes. `LINEAR` can hold scheduled calls or instructions. `RESHAPE` reappears during codegen lane expansion even after initial Tensor movement has been rangeified. Ask **which producer made this node, and which consumer is meant to eliminate it?**

Current [spec_program](../../../tinygrad/tinygrad/uop/spec.py#L189) rejects weak non-constant nodes, bare constant edges except underneath `CAST`, ordinary movement ops, and `Invalid`. It permits a special buffer `SHRINK`. These contracts identify what each phase must establish.

<a id="uops-and-rewrites--2-upat-is-a-structural-query-not-an-algebra-theorem"></a>
### 2. UPat is a structural query, not an algebra theorem

A **pattern** describes the shape of a subgraph, such as “an ADD whose right input is constant zero.” `UPat` describes that query; a **PatternMatcher (PM)** pairs queries with Python callbacks. A callback can produce a replacement or decline. Its extra checks are called **guards**: the shape may match while a dtype, bound or hardware constraint makes the replacement unsafe.

For a schematic integer rule `ADD(x, 0) -> x`, there are three separate steps: recognize the ADD and zero, bind its other input to the name `x`, then return that bound node. The pattern does not prove the arithmetic identity; the rule author must establish the conditions under which it holds. **Arity** below means the number of inputs. A wrapper such as `CAST(CONST(0))` adds a node between the operation and the literal.

Read [UPat construction and matching](../../../tinygrad/tinygrad/uop/ops.py#L1383) alongside [PatternMatcher](../../../tinygrad/tinygrad/uop/ops.py#L1522).

| Pattern feature | Exact consequence | Sharp edge |
|---|---|---|
| `op`, `dtype`, `arg`, `tag` | constrain the matched node | `arg=None` means unconstrained, not “must have None” |
| `name="x"` | passes the node as callback argument `x` | repeated `x` requires object identity, not merely equal computed values |
| tuple `src=(a,b)` | positional matching | swapping operands will fail unless explicitly accommodated |
| list `src=[a,b]` | tries source permutations | permutations can grow factorially; arbitrary lists do not prove commutativity |
| one `UPat` as `src` | repeat that pattern over children | zero children can match vacuously; constrain arity if needed |
| `allow_any_len=True` | accepts extra sources after required prefix | extra dependency/effect sources may still matter semantically |
| `UPat.any(...)` | alternative structural patterns | alternatives and permutations make match cost less predictable |
| `custom_early_reject` | required immediate child op set | an overly strict set silently prevents a valid full match |

Operator sugar uses `GroupOp.Commutative` to build permutation patterns, so `UPat.var('x') * 1` accepts either source order. Manually constructed tuple patterns do not automatically become commutative. A bare `UPat(Ops.CONST)` also does not match `CAST(CONST)`; use appropriate alternatives/`.or_casted()` or match at the intended phase.

A matcher groups candidates by root operation, then cheaply checks immediate child-op requirements before full matching. Each callback receives named bindings and optionally `ctx`. The first result that is neither `None` nor the original node wins. `a + b` concatenates rule lists: it means **priority and repeated opportunities under the driver**, not “run all of a as a completed pass, then all of b.” A callback can decline a structural match by returning `None`. Returning the same interned node also declines and permits later rules.

Callbacks may also return booleans in spec matchers or other values in specialized consumers; only pass UOp-producing matchers to `graph_rewrite`. Callbacks cannot close over Python closure cells: [deconstruct_function](../../../tinygrad/tinygrad/uop/ops.py#L1494) asserts this because functions are reconstructed for serialization/compilation. Put evolving state in `ctx`.

<a id="uops-and-rewrites--3-graph-driver-semantics-are-part-of-the-algorithm"></a>
### 3. Graph driver semantics are part of the algorithm

Matching one node does not specify how to transform an entire graph. The **driver** chooses when to visit inputs, whether to revisit replacements, and where to stop. A **fixed point** is a graph on which another application makes no change. **Memoization** records an already computed replacement so a shared input need not be transformed again. A call body has its own parameter scope: parameter slot 0 inside it is not automatically slot 0 in the caller.

[RewriteContext](../../../tinygrad/tinygrad/uop/ops.py#L1699) is worth reading in full. Tinygrad's naming is easy to misread:

| Invocation | Actual order |
|---|---|
| default `graph_rewrite(root, pm)` | visit sources, rebuild node, attempt `pm`, recursively process replacements until stable |
| `bottom_up=True` | attempt `pm` on the original node **before descending**; reach a local fixed point, then process its sources |
| `bpm=other` | additionally use `other` before descent while normal `pm` handles rebuilt nodes |
| `walk=True` | single traversal: accepted replacements are used as-is, with no traversal into their newly created subgraphs |
| `enter_calls=False` (default) | preserve `CALL.src[0]` body; call arguments can still be visited |

Thus `bottom_up` is not the usual tree-traversal mnemonic “children first.” Reason from the code and an example, not the parameter name. The fixed-point driver memoizes replacements for shared nodes, uses a work stack/waitlist, and checks repeated nodes in the early rewrite loop. It also has a stack limit. Neither mechanism proves termination of your rule set: rules can continually mint larger new graphs, or interact in a cycle.

`walk=True` is useful when replacements should not be rewritten under the same stateful transformation. Current [parameter numbering](../../../tinygrad/tinygrad/codegen/__init__.py#L391) uses it. The default `CALL` boundary matters for lexical parameter scopes and separately compiled bodies; `enter_calls=True` must be a deliberate choice, not an attempt to make every missing rewrite disappear.

<a id="uops-and-rewrites--concrete-trace-replacement-processing-versus-a-walk"></a>
#### Concrete trace: replacement processing versus a walk

Let `x` be an integer variable, and define only two rules:

```text
ADD(a, 0) -> MUL(a, 1)
MUL(a, 1) -> a
```

For `ADD(x,0)`, the default driver returns `x`: the first replacement is revisited and the second rule fires. `walk=True` returns `MUL(x,1)`: the replacement is not revisited. These outputs were asserted in the CPU-only probes below. `pm.rewrite(root)` alone performs only a node-level attempt and should not be mistaken for a graph pass.

<a id="uops-and-rewrites--4-why-these-concrete-matchers-exist"></a>
### 4. Why these concrete matchers exist

Read the families as successive questions: Can views become index formulas? Where must results be stored? Which iterations run together? Where do reads and writes occur? Can the target express the chosen operations? **Canonicalization** chooses a consistent equivalent spelling to help later rules recognize it. **Scalarization/devectorization** splits grouped values into individual element work. **Decomposition** replaces an unsupported operation with supported smaller operations. **Poison/Invalid** marks a position that has no valid value; a **gate** is the condition controlling where it is valid.

For example, representing a padded array creates both an index formula and a validity condition. Simplifying the formula, transferring the condition to a load, and finally removing the marker are different jobs. That is why the table contains several small matchers touching the same expression at different times.

This is a semantic map of the important families, not a count of all runtime matcher instances. Factory-created patterns, compositions, instruction renderers, specs, and experimental queues all contribute additional matchers.

| Matcher / source | Observable job | Rationale and boundary |
|---|---|---|
| [`mop_cleanup`](../../../tinygrad/tinygrad/uop/movement.py#L5) | simplify movement compositions | remove representational noise while retaining movement semantics |
| [`pm_mops`](../../../tinygrad/tinygrad/schedule/prepare.py#L47) | push indexing through movement; preserve/rearrange `AFTER` dependencies | convert views into coordinate transforms instead of allocating copies |
| [`earliest_rewrites`](../../../tinygrad/tinygrad/schedule/prepare.py#L151) | prepare materialization/reductions and tensor graph forms | expose useful scheduling structure before committing kernels; its hazard helper materializes unsafe overlapping updates |
| [`pm_add_buffers`, `split_kernels`](../../../tinygrad/tinygrad/schedule/rangeify.py#L261) | turn stages into storage and kernel calls | represent producer/consumer interfaces explicitly; algebraic equivalence alone cannot decide storage lifetime |
| [`symbolic_simple`](../../../tinygrad/tinygrad/uop/symbolic.py#L115) | identities, constants, basic folding, invalid handling | cheap normalization reused in lowering passes |
| [`symbolic`, `sym`](../../../tinygrad/tinygrad/uop/symbolic.py#L240) | broader canonicalization, range/div-mod/validity reasoning | simplify index arithmetic enough to reveal coalescing and redundant work; not safe to append indiscriminately to every matcher |
| [`pm_data_invalid`](../../../tinygrad/tinygrad/uop/symbolic.py#L79) | propagate poison/gates through computations | preserve invalid-lane meaning before ordinary zero/identity folds erase it |
| [`pm_reduce_identity`](../../../tinygrad/tinygrad/codegen/__init__.py#L223) | replace invalid reduction inputs with their reduction identity | a reduction must ignore masked lanes using its operation's identity, not blindly treat all padding as zero |
| [`expander`](../../../tinygrad/tinygrad/codegen/__init__.py#L78) | turn chosen unroll/upcast ranges into shaped constants; expand reduction/WMMA forms | expose compile-time lanes only after scheduling chose them |
| [`pm_wmma_add`](../../../tinygrad/tinygrad/codegen/__init__.py#L102) | move a surrounding add into WMMA's accumulator, through supported movement wrappers | preserve opportunities for matrix accumulation rather than separate elementwise addition |
| [`pm_reduce_local`](../../../tinygrad/tinygrad/codegen/__init__.py#L228) | grouped reductions, range accumulators, horizontal reductions, merged ends | turn mathematical reductions into concrete sequential/local-memory work |
| [`pm_add_local_buffers`](../../../tinygrad/tinygrad/codegen/__init__.py#L249) | resolve remaining local/register stages into placeholders and stores | reduction lowering creates storage that must acquire concrete identity |
| [`pm_add_gpudims`](../../../tinygrad/tinygrad/codegen/gpudims.py) | map scheduled axes and synchronization to target launch structure | hardware coordinates and workgroup behavior depend on renderer capabilities |
| [`pm_expand_broadcast`, `devectorizer2`](../../../tinygrad/tinygrad/codegen/__init__.py#L112) | make broadcast shapes explicit, scalarize shaped operations/memory | scalarization assumes aligned source shapes; applying it too early misses or misinterprets lanes |
| [`pm_add_loads`](../../../tinygrad/tinygrad/codegen/__init__.py#L239) | add reads when memory-addressable values feed computation | separate location from loaded value; store destinations must remain locations |
| [`indexing_simplify`, memory coalescing](../../../tinygrad/tinygrad/codegen/late/coalesce.py) | normalize/group memory access forms | scheduling and scalarization must expose accesses before target-supported memory widths can be selected |
| [`pm_commit_weak`](../../../tinygrad/tinygrad/uop/weak.py#L35) | propagate required concrete widths into weak expressions and stores | settle width obligations without prematurely defaulting everything |
| [`pm_lower_weak`](../../../tinygrad/tinygrad/uop/weak.py#L67) | resolve remaining weak computations, absorb conversion wrappers | explicit boundary between mathematical index expressions and target integer/float operations |
| [`pm_uncast_const`](../../../tinygrad/tinygrad/uop/weak.py#L89) | remove a constant cast only if consumer still derives identical types | keep bare-constant patterns useful without changing operand/result type inference |
| [`pm_cast_const`](../../../tinygrad/tinygrad/uop/weak.py#L98) | state remaining constant widths at consumer edges, including bool | final program forbids uncommitted constant operands |
| [`pm_dtype_decomps`](../../../tinygrad/tinygrad/codegen/decomp/dtype.py) | emulate unsupported data types | target dtype support is a legality issue, not merely an optimization |
| [op/transcendental factories](../../../tinygrad/tinygrad/codegen/decomp/op.py) | select replacements according to renderer-supported ops and options | lower unsupported semantics late enough to retain high-level optimization opportunities |
| [`pm_move_gates_from_index`](../../../tinygrad/tinygrad/codegen/late/gater.py) | move invalid index gating to executable load/store forms | a symbolic invalid address cannot be emitted as ordinary address arithmetic |
| [`pm_remove_invalid`](../../../tinygrad/tinygrad/uop/symbolic.py#L104) | erase residual Invalid with renderable values | legal only after required gates/identities have carried its semantic information elsewhere |
| [`pm_implicit_barriers`](../../../tinygrad/tinygrad/codegen/__init__.py#L281) | add workgroup barriers for local-memory dependencies | graph ordering between values is insufficient for inter-thread visibility |
| [`pm_add_control_flow`, `pm_split_ends`](../../../tinygrad/tinygrad/codegen/late/linearizer.py) | build/split loop control structure | a DAG must become legal nested execution order |
| [`pm_linearize_cleanups`](../../../tinygrad/tinygrad/codegen/__init__.py#L408) | gated stores become IF/STORE/ENDIF in ordered lists | line expansion has different contracts from a UOp-to-UOp graph rewrite |
| [`pm_to_program`](../../../tinygrad/tinygrad/codegen/__init__.py#L462) | append linearized, rendered/assembled, compiled artifacts | a progressive IR container acts as a compilation state machine |
| [`pm_proc`, `pm_renderer`](../../../tinygrad/tinygrad/uop/upat.py#L108) | simplify and emit the matcher's own predicate IR | spend compilation effort once to reduce repeated Python matching overhead |
| [`spec_tensor`, `spec_program`, `spec_full`](../../../tinygrad/tinygrad/uop/spec.py#L132) | return validity judgments | reuse structural queries to express phase contracts; these are validators, not optimization passes |

<a id="uops-and-rewrites--5-ordering-has-concrete-semantic-consequences"></a>
### 5. Ordering has concrete semantic consequences

Consider a four-lane implementation of a three-element maximum: the valid data is `[-5, -2, -7]`, and the fourth lane is padding. Replacing padding with zero gives `max(-5,-2,-7,0)=0`, which is wrong. Replacing it with negative infinity gives `-2`. This schematic example explains why information about invalid positions must survive until the compiler knows which reduction or memory operation uses them; it is not a new execution result.

The authoritative sequence is [full_rewrite_to_sink](../../../tinygrad/tinygrad/codegen/__init__.py#L286). Simplified:

```text
movement/range simplification -> scheduling options
 -> postopt symbolic + reduction identities -> expansion
 -> explicit reductions -> local storage -> hardware dimensions
 -> broadcast + loads -> devectorization -> memory coalescing
 -> symbolic + commit weak -> lower weak -> final symbolic
 -> float operands -> early ops -> dtype emulation -> late ops/math
 -> move gates -> renderer rules + remove Invalid -> cast constants
 -> barriers -> control flow -> number params -> verify
```

**Invalid before arithmetic simplification.** The source explicitly says `pm_data_invalid` must precede symbolic folds so `0 * maybe_invalid` does not become an unconditional zero. For `WHERE(c,x,Invalid) * 0`, its rewrite is `WHERE(c,x*0,Invalid)`. Even if the inner multiply later becomes zero, invalidity survives outside the valid region. The probe checked this exact structure. This is about compiler lane/address validity, not IEEE NaN arithmetic.

**Reduction identity before scalar lowering.** Add uses zero, multiply uses one, max uses the dtype's identity. `pm_reduce_identity` handles this before `expander`/accumulator construction. Removing invalidity with a generic zero too soon can change a product or all-negative maximum.

**Weak width commitment before defaulting.** `pm_commit_weak` must reach a fixed point before `pm_lower_weak` picks defaults. A concrete cast on a weak ALU states a width floor, and the helper includes both node and source bounds to avoid narrowing. Constants may remain bare where their consumers still derive a concrete type. “Bare” is a property of the edge, not a prohibition on all `CONST` nodes.

**One explicitly prohibited composition.** [The comment immediately before weak lowering](../../../tinygrad/tinygrad/codegen/__init__.py#L350) says not to compose `symbolic` there: `pm_data_invalid` pushes a weak-result cast into a gated `WHERE`, recreating a weak node and cycling with lowering. This is a concrete answer to “why another tiny PM instead of one giant optimizer?” Different phases require different normal forms, and locally sensible inverses cannot share an unrestricted fixed point.

**Committed constants after decompositions.** Dtype/transcendental decomposition creates new nodes. Width cleanup must accompany or follow these expansions; doing it once before them does not establish the final program invariant. `pm_cast_float_alu` similarly exists because the decomposition's polynomial implementation requires explicitly float operands.

**Control flow after memory semantics.** Barriers and gate placement must see the memory dependency structure. Ordered IF/ENDIF emission happens in `line_rewrite`; introducing IF nodes arbitrarily in the graph fails `pm_linearize_cleanups`' explicit check.

<a id="uops-and-rewrites--changes-checked-in-the-latest-master-refresh"></a>
#### Changes checked in the latest-master refresh

The Sept 13 → Sept 17 source diff matters even for this small map: `pm_reduce_identity` no longer contains the two WMMA input rules; tensor-core formation handles a reduction gate by zeroing its multiplicands in [postrange scheduling](../../../tinygrad/tinygrad/codegen/opt/postrange.py#L231). WMMA metadata now has four entries, with the device removed, and expansion reads upcast axes from `arg[3]`. `pm_cast_const` now forces every remaining non-Invalid bare constant edge to a committed width, not just bool edges. CALL gained a checked `.body` property for its first source. The broader `sym` composition also lost its general cast-through-WHERE rule. None of those changes justify removing the still-present warning about Invalid-driven cycles at weak lowering.

<a id="uops-and-rewrites--6-the-matcher-compiles-itself"></a>
### 6. The matcher compiles itself

A general pattern interpreter repeatedly asks questions like “is this an ADD?” and “does its second input equal zero?” A compiled matcher turns that fixed query into specialized Python code once, then reuses it. This saves work on repeated matches but introduces a first-use compilation cost. A **predicate** is a true/false test; conjunction and alternative mean AND and OR.

[upat.py](../../../tinygrad/tinygrad/uop/upat.py#L10) translates a UPat into a small UOp-based predicate graph: `CUSTOM`/`CUSTOMI` hold predicate fragments, `STORE` binds names, `PYLITERAL` holds Python objects, `AND`/`OR` compose tests. This is host compiler infrastructure, not instructions for the accelerator.

`pm_proc` flattens conjunctions, redistributes alternatives, and turns repeated name bindings into identity checks. It refuses some overly large combinations (`UPatCompileError`). `pm_renderer` converts fragments into Python source; `upat_compile` executes that source to make a specialized matcher. Compilation is lazy at the first attempted match, and unsupported compilation falls back to interpretation. `UPAT_COMPILE=0` provides a useful comparison path. These infrastructure matchers explicitly use `compiled=False`, avoiding a dependency on compiling the compiler before it can run.

**Sharp edge:** a source-level `PatternMatcher(...)` census is not a runtime matcher count or a proof that each rule executes. Compositions and factories create more objects; many rules are target- or phase-specific. To understand importance, combine call-site placement, rewrite traces, and tests that reach the pattern.

<a id="uops-and-rewrites--7-a-practical-readingdebugging-loop"></a>
### 7. A practical reading/debugging loop

1. Find the producing `graph_rewrite(..., name=...)` in codegen/schedule. Record which phase's graph you have.
2. Check exact shape, dtype, `src` ordering/arity, and wrappers (`CAST`, `AFTER`, movement) before changing a pattern.
3. Read the callback's guards as part of the rule. A structural match can correctly decline.
4. Check earlier competing rules and early-reject filters. Trace with and without UPat compilation if matcher behavior is suspect.
5. Check phase specs, then final numerical behavior. Structural tests catch missed forms; execution catches incorrect equivalences; neither replaces the other.
6. For a new rule, write down a decreasing measure or phase boundary. Adding its inverse to the same fixed-point matcher is a termination risk.

[The VIZ README](../../../tinygrad/tinygrad/viz/README.md) documents `VIZ=1`, `python -m tinygrad.viz.cli`, pass listings via `--ls`, and `DEBUG=7` rewrite details. Use exact pass names from your run; old tutorial names and kernel labels need not match this commit.

<a id="uops-and-rewrites--8-validation-actually-performed"></a>
### 8. Validation actually performed

On the clean master snapshot, using its existing virtual environment and no accelerator:

```bash
cd tinygrad
.venv/bin/python -m pytest test/null/test_pattern_matcher.py \
  test/null/test_graph_rewrite.py test/null/test_rewrite_bottom_up_gate.py -x -q -n12
```

Result: **53 passed, 1 skipped in 1.49s**. The example probe passed both with default compiled matching and with `UPAT_COMPILE=0`. Small additional Python assertions verified interning, bool/int constant separation, concrete constant representation, `(x+0)*1` simplification, fixed-point versus walk behavior, repeated-name identity matching, and Invalid gate propagation. The reproducible probe is in [the exercises](uops-and-rewrites.md#rewrites-exercises--reproducible-probe). This validates examples and the tested rewrite machinery; it is not a hardware/compiler correctness certification. Initial attempts with `python` and system `python3 -n12` failed due to environment/tool availability; the repository virtual environment provided the required interpreter and xdist.

<a id="uops-and-rewrites--9-gpu-amd-and-image-rules"></a>
### 9. GPU, AMD, and IMAGE rules

Target-specific rules adapt the lowered computation to a device or its programming interface. A **chip guard** enables a rule only for selected hardware generations. An **IMAGE** is a GPU image resource with coordinate/channel access rules, not a claim that the user's tensor contains pictures. A **matrix fragment** is the portion of a matrix tile assigned to one participating lane. Hardware intrinsics expose specialized instructions through a compiler interface.

Read the [AMD matcher guide](amd-pattern-matchers.md) for HIP versus LLVM,
chip-specific matrix fragments, dtype workarounds, and concrete probes. Read
the [IMAGE guide](image-pattern-matchers.md) for image promotion, four-channel
accesses, pitch/layout constraints, validity masks, and the runtime binding.
The individual rules are indexed in the [rule reference](rules/README.md).

Three different places make code target-specific:

| Place | What changes | Why looking only for an AMD-named PM misses it |
| --- | --- | --- |
| Generic codegen driven by renderer capabilities | Launch dimensions, dtype emulation, supported-op decomposition, vector memory widths | The same factory builds different rule sets from the target's capabilities. |
| `ren.extra_matcher` in the final graph rewrite | Target legality and hardware/compiler-specific forms | These rules run after generic decompositions and gate movement, with width cleanup still present. |
| Rendering and explicit instruction assembly | Target syntax, intrinsics, register/storage conventions | A string-emitting matcher or handwritten `INS` assembler is not another general UOp optimization pass. |

The ordering is visible in [full_rewrite_to_sink](../../../tinygrad/tinygrad/codegen/__init__.py#L330):
memory coalescing precedes image promotion; width commitment and decompositions
precede final renderer rules; constant commitment and implicit barriers follow.
Moving a rule to a seemingly more general matcher can violate those assumptions.

Examples outside AMD help distinguish chip guards from general GPU behavior:

- [PTX](../../../tinygrad/tinygrad/renderer/ptx.py#L40) rewrites boolean
  comparisons into predicate operations, accesses non-register bool storage
  through bytes, and coerces shift counts to unsigned integers. Its
  [architecture constructor](../../../tinygrad/tinygrad/renderer/ptx.py#L143)
  additionally promotes half `MAX` and `EXP2` through float32 for `sm < 80`.
  The first group is a PTX representation requirement; the second has an
  explicit architecture guard.
- [Metal](../../../tinygrad/tinygrad/renderer/cstyle.py#L369) promotes selected
  bfloat16 transcendental operations and uses manual bfloat16 cast rules.
  Apple generation checks select tensor-core and dtype capabilities elsewhere
  in the renderer; not every chip distinction is a separate matcher.
- [WGSL](../../../tinygrad/tinygrad/renderer/wgsl.py#L43) rewrites packed
  subword storage, boolean operations, shifts, and NaN checks. Its text rules
  recognize the resulting read/modify/write shape and emit atomic operations.
  These are backend language/storage constraints, not evidence of one GPU
  chip's erratum.

For a reduction such as RMSNorm, first establish which scheduled kernels and
buffers exist using [the executed boundary study](rmsnorm-kernel-fusion.md).
Then inspect which target rules lower each kernel. A WMMA fragment repair,
image coordinate rewrite, or predicate conversion does not by itself remove
the boundary between the reduction kernel and its consumer.

<a id="rewrites-exercises"></a>
## Tinygrad rewrite exercises and worked solutions
<a id="rewrites-exercises--tinygrad-rewrite-exercises-and-worked-solutions"></a>

A **UOp** is a node describing an operation and its inputs. The nodes form an **IR** (intermediate representation) that the compiler can inspect as data. `ADD(x,0) -> x` means replace an addition node with its existing input `x`; it is schematic graph notation, not Python code. A **pattern matcher (PM)** recognizes graph shapes, and a **driver** decides which nodes to visit and whether to revisit replacements. A **guard** is an additional condition required before a replacement is safe. The optional [first-principles primer](../first-principles.md) provides background; the explanations here introduce the local details.

Snapshot: clean master `107adc31701df0247dfa45e175984df906a68b53` (2026-09-17). Companion: [UOps and rewrites](uops-and-rewrites.md#uops-and-rewrites). Exercises 1–8 build toward reading a real codegen pass; 9–12 are patch/research assignments. The solutions are explanations, not claims that the open-ended patches have been implemented. CPU-only probes and existing test results are recorded at the end. For a substantial lowering and cross-kernel fusion exercise, use the measured [RMSNorm case study](rmsnorm-kernel-fusion.md); the early exercises here isolate its underlying mechanisms.

<a id="rewrites-exercises--1-reconstruct-the-current-node-model-15-minutes"></a>
### 1. Reconstruct the current node model (15 minutes)

**Interning** reuses the same object for an identical live node construction. Object identity means Python's `is`, which is stronger than two expressions eventually producing equal numbers. A **weak dtype** postpones a machine-width choice; `CAST` makes a conversion/type choice explicit.

**Task.** Predict `op`, dtype, and identity relationships for `UOp.const(1)`, another `UOp.const(1)`, `UOp.const(True)`, and `UOp.const(1, dtypes.int32)`. Explain why changing `x.arg` in place is unsafe. Find the source defining these behaviors.

**Solution.** The first two are the same live interned `CONST` with weak integer dtype. The boolean is a distinct `CONST` with bool dtype; `type(arg)` is part of the interning key precisely because Python dictionary equality otherwise conflates `True` and `1`. The explicitly int32 constant is a `CAST` whose argument states int32, wrapping a constant value. In-place mutation invalidates the assumptions behind the interning cache and cached derived properties and changes all sharing graphs. Use `replace`.

Evidence: [UOp metaclass](../../../tinygrad/tinygrad/uop/ops.py#L192), [const](../../../tinygrad/tinygrad/uop/ops.py#L607). **Acceptance:** assert all four predictions without initializing a device.

<a id="rewrites-exercises--2-make-a-match-precise-20-minutes"></a>
### 2. Make a match precise (20 minutes)

**Task.** Match `ADD(x,x)` but reject `ADD(x,y)` when x and y are distinct. Then match addition with zero on either side. Explain the difference between tuple and list sources and why `UPat(Ops.CONST)` can miss a typed literal.

**Solution.** Use `UPat(Ops.ADD, src=(UPat(name='x'), UPat(name='x')))`. Repeated names assert identity, not semantic equivalence. For either zero order, use `src=[UPat(name='x'), UPat.const(0)]`, or `UPat.var('x') + 0`; the latter knows ADD is commutative. A tuple preserves order. To see the wrapper issue, compare `ADD(x, CONST(0))` with `ADD(x, CAST(int32, CONST(0)))`. The second input has root operation CONST in the first graph and CAST in the second. A concrete typed literal may be `CAST(CONST)` at this phase, so a bare CONST pattern misses its outer node. A phase-appropriate `.or_casted()` can accept both spellings.

Evidence: [UPat](../../../tinygrad/tinygrad/uop/ops.py#L1383). **Acceptance:** include distinct same-valued expressions as a negative case unless they intern to the same node. Report graph identity separately from numerical equality.

<a id="rewrites-exercises--3-distinguish-matcher-composition-from-pass-sequencing-20-minutes"></a>
### 3. Distinguish matcher composition from pass sequencing (20 minutes)

**Task.** Given `A: ADD(x,0) -> MUL(x,1)` and `B: MUL(x,1) -> x`, predict default graph rewriting, a single `pm.rewrite`, and `walk=True`. Explain what happens if two ADD rules both succeed.

**Solution.** Starting at `ADD(x,0)`, A produces `MUL(x,1)`. Default graph rewriting with `A+B` then revisits that replacement, B produces `x`, and neither rule matches `x`. The result is stable: this is a **fixed point**. A single node rewrite returns `MUL(x,1)`. A walk also returns `MUL(x,1)` here, because it does not descend into the new replacement. With two successful ADD rules, the earlier rule's non-identical, non-None result wins. Composition concatenates priorities; separate graph passes establish a phase boundary and may produce a different result.

Evidence: [PatternMatcher.rewrite](../../../tinygrad/tinygrad/uop/ops.py#L1540), [RewriteContext](../../../tinygrad/tinygrad/uop/ops.py#L1699). **Acceptance:** execute the probe below and add a competing ADD rule to demonstrate priority.

<a id="rewrites-exercises--4-explain-a-missing-rewrite-inside-a-call-15-minutes"></a>
### 4. Explain a “missing” rewrite inside a call (15 minutes)

**Task.** A pattern simplifies `x+0` directly but appears to do nothing when that expression is inside a CALL body. Diagnose it before widening the pattern.

**Solution.** `graph_rewrite` defaults to `enter_calls=False`, preserving `CALL.src[0]`. Its arguments can still be rewritten. If this pass truly owns the body's phase and scope, use `enter_calls=True`; otherwise invoke the pass where that body is independently lowered. A parameter substitution intended for outer call arguments must not blindly substitute inner lexical parameters with the same slot numbers. This is the same scope issue as two Python functions each naming their first argument `x`: matching the name or position does not make them the same variable.

Evidence: [driver call-body boundary](../../../tinygrad/tinygrad/uop/ops.py#L1765), [lexical resolution](../../../tinygrad/tinygrad/schedule/__init__.py#L119). **Acceptance:** identify the exact call-site ownership before proposing a code change.

<a id="rewrites-exercises--5-preserve-invalid-lanes-25-minutes"></a>
### 5. Preserve invalid lanes (25 minutes)

A **lane** is one element position in grouped computation. `WHERE(c,a,b)` selects `a` when condition `c` is true and `b` otherwise. `Invalid` marks a position that has no valid value; it may tell later stages that a memory access must not occur. A **gate** is the condition controlling that access.

**Task.** Why is `WHERE(c,x,Invalid)*0 -> 0` dangerous? Give the first rewrite tinygrad makes and explain when a renderable zero becomes legal.

**Solution.** The multiplication cannot erase the invalidity of the false branch: that invalidity can still determine whether a memory access exists. `pm_data_invalid` first produces `WHERE(c,x*0,Invalid)`. An inner zero fold still leaves the outside gate. Later lowering transfers required validity to memory gates or reduction identities; only after that can residual invalid sentinels be removed. Invalid is not a normal number and is not IEEE NaN.

Evidence: [source's ordering comment and rules](../../../tinygrad/tinygrad/uop/symbolic.py#L61), [gate lowering](../../../tinygrad/tinygrad/codegen/late/gater.py), [final sequence](../../../tinygrad/tinygrad/codegen/__init__.py#L373). **Acceptance:** assert the first structural rewrite, then explain why that alone does not prove final memory safety.

<a id="rewrites-exercises--6-choose-the-padding-identity-20-minutes"></a>
### 6. Choose the padding identity (20 minutes)

**Task.** A masked reduction adds padded lanes. What values should replace invalid inputs for ADD, MUL, and MAX? Explain why MAX over negative inputs catches a zero-padding bug that an all-positive example misses.

**Solution.** ADD needs zero; MUL needs one; MAX needs the appropriate dtype identity (negative infinity for a supported floating maximum, or the integer dtype's minimum for an integer maximum). For valid values `[-5,-2,-7]` and one padded lane, zero gives `max(-5,-2,-7,0)=0`; negative infinity gives the correct `-2`. For a product of `[2,3]`, padding with one preserves `6`, whereas padding with zero produces `0`. These are arithmetic illustrations; they do not themselves execute masked code generation. Tinygrad computes the identity using `identity_element`; do not hardcode one identity for every dtype or reduction. Tensor-core formation separately gates WMMA multiplicands with zero because their products must contribute zero to addition; current `pm_reduce_identity` itself only handles REDUCE.

Evidence: [pm_reduce_identity](../../../tinygrad/tinygrad/codegen/__init__.py#L223). **Acceptance:** construct positive and negative max examples and an integer case, and state whether your test exercises masked codegen or merely Python arithmetic.

<a id="rewrites-exercises--7-explain-the-four-weak-type-matchers-30-minutes"></a>
### 7. Explain the four weak-type matchers (30 minutes)

The underlying problem is timing: early index algebra benefits from postponing numeric widths, but emitted machine arithmetic and stored values need definite types. Committing a width propagates a requirement; lowering replaces unresolved operations with concrete ones. Removing and later restoring constant wrappers serves different consumers at those different stages.

**Task.** Why are `pm_commit_weak`, `pm_lower_weak`, `pm_uncast_const`, and `pm_cast_const` separate? Find one real composition that the source explicitly prohibits.

**Solution.** Commitment propagates concrete width requirements while graph reasoning can still use weak types. Lowering settles residual weak computations and conversions. Uncasting removes redundant constant wrappers only when consumer operand/result type derivation stays unchanged; this preserves simple constant patterns. Final constant casting satisfies renderer/program contracts, including boolean constants. `symbolic` must not be composed into the weak-lowering fixed point: its Invalid rules can push casts into gated WHERE and recreate weak nodes that lowering tries to remove. The implementation explicitly documents the cycle.

Schematically, one transformation replaces a weak result with a concrete cast around it; another moves that cast inside a gated selection and exposes a weak result again. If both keep undoing the other's required form, “repeat until stable” never reaches stability. Separate phases stop the two transformations from competing indefinitely. This description explains the cycle, rather than asserting a literal two-node source trace.

Evidence: [weak.py](../../../tinygrad/tinygrad/uop/weak.py#L1), [prohibited composition](../../../tinygrad/tinygrad/codegen/__init__.py#L350), [program spec](../../../tinygrad/tinygrad/uop/spec.py#L189). **Acceptance:** draw the cast/gate movement cycle and explain which phase boundary breaks it. Do not run an intentionally nonterminating full compiler process.

<a id="rewrites-exercises--8-trace-one-elementwise-expression-through-phase-contracts-45-minutes"></a>
### 8. Trace one elementwise expression through phase contracts (45 minutes)

Use this conceptual path before inspecting a real trace: reshape a six-element input to `(2,3)`, add scalar 1, and store six results. Position `(row,col)` refers to flat input position `3*row+col`; broadcasting supplies 1 at each position; a load reads the input value; addition computes the result; a store writes it. The actual UOp graph also has to encode types and dependencies. **Devectorization** splits grouped element work into scalar pieces; it needs corresponding source lanes to agree.

**Task.** Start with a reshaped input, add a scalar, and store the result. Annotate what each of movement rewriting, broadcast expansion, load insertion, devectorization, weak lowering, and final constant casting must accomplish. Which matcher's prerequisites would fail if you moved devectorization first?

**Solution.** Movement rewriting expresses the view through index coordinates. Broadcast expansion makes source shapes agree. Load insertion distinguishes storage locations from computed values while leaving the store destination addressable. Devectored operations can then index corresponding lanes; the implementation declines if source shapes disagree (except Invalid). Weak lowering settles machine types after algebra/index simplification. Final constant casting states literal operand widths after newly generated decomposition nodes are present. Moving devectorization before broadcast alignment violates its explicit shape precondition and can leave shaped expressions unresolved.

Evidence: [expand_broadcast and do_devectorize](../../../tinygrad/tinygrad/codegen/__init__.py#L90), [pm_add_loads](../../../tinygrad/tinygrad/codegen/__init__.py#L239). **Acceptance:** produce a phase table from an actual VIZ run; keep concrete observed graphs separate from this expected outline. This document does not claim that end-to-end VIZ trace was run.

<a id="rewrites-exercises--9-implement-a-rule-with-a-termination-argument-6090-minutes"></a>
### 9. Implement a rule with a termination argument (60–90 minutes)

A **decreasing measure** is a quantity that goes down on every accepted rewrite and cannot decrease forever, such as the count of a particular redundant wrapper. It explains why repeated application stops only if interacting rules cannot increase that quantity again. **NaN** is a floating-point “not a number” value; familiar real-number algebra may fail for it.

**Task.** In a disposable branch, add or isolate a small integer rewrite that is missing at the chosen revision. First prove that it is actually missing. Supply a counterexample to an overly broad formulation, phase placement, and a decreasing measure. Avoid submitting an identity already covered by symbolic.py.

**Worked solution strategy.** Search the existing rules and tests, then construct the minimal failing graph. Restrict to a dtype/domain where the identity holds; arithmetic involving overflow, signed division, zero divisors, or floating NaNs needs separate reasoning. A rule that removes a redundant wrapper can use wrapper count as a local measure, but inspect surrounding rules for wrapper recreation. Test numerical equivalence over a small exhaustive domain plus the structural expected form. Run a second rewrite and require stability. Compare compiled and interpreted matching. A correct solution may conclude that the proposed rule already exists or belongs only in a later phase.

**Rubric:** 2 points for existing-rule audit, 2 for domain/counterexample, 2 for phase and termination, 2 for numerical and structural tests, 2 for evidence of a useful real graph. This is a project recipe, not an implemented patch.

<a id="rewrites-exercises--10-build-a-matcher-performance-experiment-60-minutes"></a>
### 10. Build a matcher performance experiment (60 minutes)

A shared **DAG** is a directed graph without dependency cycles in which several users can point to the same input node. **Cold time** includes first-use setup; **warm time** measures subsequent reuse. A source-permutation pattern tries alternative orders of children, so a concise pattern can still require many comparisons.

**Task.** Compare compiled and interpreted matching on a shared DAG. Account for first-use compilation, repeated matches, and rules that never reach their callbacks. Explain why fewer Python source lines do not necessarily mean a faster matcher.

**Worked solution strategy.** Use separate processes with `UPAT_COMPILE=0` and the default. Report graph size, sharing, rule candidates, cold time, warm time, and sample variance. Include a high-permutation pattern and a precise-op alternative with the same accepted cases. Root dispatch and child-op early rejection can avoid most deep matching; list-source permutation and nested alternatives can dominate others. The matcher compiler sometimes falls back to interpretation, so confirm which path was used before attributing a speedup. Never infer a whole-model speedup from a microbenchmark alone.

Evidence: [upat compiler](../../../tinygrad/tinygrad/uop/upat.py#L157). **Rubric:** correctness parity and honest cold/warm separation are required; no fixed speedup is expected or reported here.

<a id="rewrites-exercises--11-explain-a-reduction-rewrite-from-an-actual-trace-90-minutes"></a>
### 11. Explain a reduction rewrite from an actual trace (90 minutes)

A grouped reduction splits the input among cooperating threads. Each thread first computes a partial answer; another step combines the partial answers. **Local storage** is memory shared within a workgroup (a cooperating group of threads), and a **barrier** coordinates those threads. A producer's graph dependency does not by itself make another thread's write visible. This is why the exercise asks for both the store/read pair and its synchronization.

**Task.** Capture a grouped reduction and annotate `pm_reduce_identity`, `expander`, `pm_reduce_local`, local buffer insertion, and barriers. Identify the store/read pair requiring cross-thread synchronization.

**Worked solution strategy.** Use a supported backend or compile-only renderer and record its configuration. Follow grouped reduction axes into `fix_group_for_reduce`: partial results go through LOCAL storage, then a second reduction reads them. Separate sequential accumulator dependencies from workgroup synchronization. Track the exact `AFTER` links and compare with implicit barrier insertion. Hardware execution is necessary to establish the behavior of an actual device; compiling a graph demonstrates only the emitted structure.

Evidence: [group reduction helper](../../../tinygrad/tinygrad/codegen/__init__.py#L163), [barrier insertion](../../../tinygrad/tinygrad/codegen/__init__.py#L281). **Rubric:** identify producer/consumer, address space, participating lanes, loop scope, and the resulting barrier placement. This trace was not run for this document.

<a id="rewrites-exercises--12-maintain-this-map-across-a-compiler-change-45-minutes"></a>
### 12. Maintain this map across a compiler change (45 minutes)

**Task.** Choose two commits and produce a semantic diff, not a renamed-file list: constructor changes, type/shape derivation, one removed abstraction, pass order, and tests covering the change.

**Worked solution.** July documentation's index dtype and explicit-typing descriptions cannot be transplanted into this September snapshot. Current UOps derive dtype, weakint/weakfloat carry unresolved values, concrete constants are CAST/CONST pairs, and weak.py implements the boundary. A good update links the actual introducing changes if history is available; a shallow clone may lack them. State that limitation rather than guessing motivation. Meeting comments can explain intent, but current source and tests establish shipped behavior.

**Rubric:** exact two revisions, source-backed before/after, one runnable migrated example, and a clear distinction between stated intent and inferred rationale.

<a id="rewrites-exercises--reproducible-probe"></a>
### Reproducible probe

Run from the `tinygrad` checkout with the existing environment. This is the same behavior checked during the audit; it constructs/re-writes graphs without allocating accelerator buffers.

```python
from tinygrad.uop.ops import UOp, UPat, Ops, PatternMatcher, graph_rewrite
from tinygrad.uop.symbolic import symbolic_simple, pm_data_invalid
from tinygrad.dtype import dtypes, Invalid

x = UOp.variable('x', 0, 10)
assert UOp.const(1) is UOp.const(1)
assert UOp.const(True) is not UOp.const(1)
assert UOp.const(1, dtypes.int32).op is Ops.CAST
assert graph_rewrite((x + 0) * 1, symbolic_simple) is x

pm = PatternMatcher([
  (UPat(Ops.ADD, src=(UPat(name='a'), UPat.const(0))), lambda a: a * 1),
  (UPat(Ops.MUL, src=(UPat(name='a'), UPat.const(1))), lambda a: a),
])
assert graph_rewrite(x + 0, pm) is x
assert graph_rewrite(x + 0, pm, walk=True).op is Ops.MUL
same = UPat(Ops.ADD, src=(UPat(name='a'), UPat(name='a')))
assert same.match(x + x, {})
assert not same.match(x + 1, {})
out = graph_rewrite((x < 5).where(x, UOp.const(Invalid)) * 0, pm_data_invalid)
assert out.op is Ops.WHERE and out.src[2].is_invalid
print('probe passed')
```

Actual additional suite: `.venv/bin/python -m pytest test/null/test_pattern_matcher.py test/null/test_graph_rewrite.py test/null/test_rewrite_bottom_up_gate.py -x -q -n12`: **53 passed, 1 skipped in 1.49s**. The displayed probe also passed with `UPAT_COMPILE=0` and with the default compiled matcher. Exercises 8–11 specify further work; their expected approaches are not fabricated run results.
