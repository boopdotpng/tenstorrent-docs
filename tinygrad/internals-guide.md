# tinygrad internals: from `Tensor` expressions to a linear program

This is a source-guided map of tinygrad's compiler as of tinygrad commit
`4234a9d727e52a6bb033c387d2c869cea4caf641` (2026-07-10). tinygrad changes
quickly: names in an older article or trace may describe a genuinely different
compiler. The revision is part of the documentation, not trivia.

For the complete op catalog, see [UOps reference](uops-reference.md). For the
rewrite inventory, see [PatternMatcher reference](pattern-matchers-reference.md).
The concrete `arange(100)[45:55].sum()` snapshots are in
[the historical May 2026 stage trace](tinygrad-uop-arange-slice-sum-stages.md).
That trace predates the July shape-based codegen rewrite; use it to compare
compiler generations, not as the current pass order.

## The useful mental model

A `Tensor` is a small Python wrapper around one `UOp`. Tensor methods do not
normally execute a kernel. They add nodes to a lazily built, immutable DAG:

```text
Tensor methods
    │ build
    ▼
tensor UOp DAG
    │ callify: choose buffers and make calls explicit
    ▼
call/function DAG
    │ rangeify: turn shapes and movement into iteration/index expressions
    ▼
kernel SINK DAGs
    │ dependency scheduling and temporary-memory planning
    ▼
schedule LINEAR(CALL, CALL, ...)
    │ per-kernel optimization and target lowering
    ▼
program SINK with RANGE/LOAD/ALU/STORE/control-flow edges
    │ priority topological sort
    ▼
program LINEAR(uop, uop, ...)
    │ render/assemble and compile
    ▼
PROGRAM(SINK, LINEAR, SOURCE, BINARY)
```

This is called a "single UOp dialect", but it is more accurate to imagine one
Python node type carrying several short-lived dialects. `RESHAPE` belongs to the
tensor graph; `STAGE` marks a scheduler materialization boundary; `RANGE` and
`REDUCE` describe a kernel; `LOAD`, `SPECIAL`, and `WMMA` are codegen-level;
`INS` is selected machine code. The enum is shared, while the legal subset and
meaning of a graph depend on the phase.

That phase dependence explains many apparent contradictions in the source.
Current codegen reuses `RESHAPE`, `PERMUTE`, `EXPAND`, `STACK`, and `INDEX` to
make lane expansion explicit even after the Tensor-level movement has already
been rangeified. A `LINEAR` under the outer schedule does not mean the same
thing as the `LINEAR` under a compiled `PROGRAM`.

## What a UOp actually is

The current object is effectively:

```python
UOp(op, dtype=None, src=(), arg=None, tag=None)
```

- `op` is one of the 82 values in `tinygrad.uop.Ops`.
- `dtype` is stored. The constructor can now infer it with `dtype_from_uop`
  when the caller passes `None`, and `SPEC=2` checks an explicit dtype against
  that production rule.
- `src` contains this node's dependencies. Edges therefore point from a
  consumer toward its inputs.
- `arg` carries op-specific immutable data: a constant, axes, buffer metadata,
  kernel metadata, and so on.
- `tag` is transient compiler metadata and also participates in identity.

`UOpMetaClass` hash-conses nodes in a global weak cache keyed by
`(op, dtype, src, arg, tag)`. Constructing the same structural UOp while the old
one is live returns the same Python object. This makes identity comparisons and
rewrite caches useful, and it makes the graph a DAG rather than an accidental
tree. The nodes are treated as immutable; `replace(...)` constructs or reuses a
new node.

Properties such as `shape`, `device`, value bounds, axes, buffer identity, and
range membership are computed from the graph. Recursive properties use an
iterative topological walk and cache results on nodes. There is no separate
ShapeTracker object attached to every Tensor anymore.

The sibling `tinyspec` paper is a good conceptual overview, especially its
Callify → Rangeify → Optimize → Expand → instruction selection → Linearize
sequence. It is not an exact schema for this checkout. The local standalone
paper contains stale ops such as `BufferView`, `Vconst`, `Replicated`, and
`AtomicAdd`; lacks current infrastructure such as `PYLITERAL` and several
scheduler ops; and describes a four-field UOp while current code still stores
`dtype`. Use the paper for the model and current
`tinygrad/uop/__init__.py`, `tinygrad/uop/spec.py`, and the source for facts.

Here is the useful translation from the paper to this revision:

| `tinyspec` term | Current source boundary |
|---|---|
| Callify | `callify.py::transform_to_call` |
| Rangeify | `schedule/indexing.py::run_rangeify`, orchestrated by `schedule/rangeify.py::get_kernel_graph` |
| Optimize | range simplification plus `codegen/opt/postrange.py::apply_opts` inside `full_rewrite_to_sink` |
| Expand | `codegen/__init__.py::expander2`, `unbroadcast`, and `devectorizer2`; this now uses shapes/`STACK`, so do not look for the older `dtype.vec` implementation the paper alludes to |
| Instruction selection | renderer decomposition/`extra_matcher`; explicit `INS` selection only for `ISARenderer` targets such as x86 |
| Linearize | `pm_add_control_flow` followed by `codegen/late/linearizer.py::linearize` |
| Command buffers | outer schedule `LINEAR` plus runtime dispatch; `extra/hcq2` is a separate experimental lowering, not the ordinary compiler path |

## How Tensor methods become the raw graph

`Tensor._apply_uop` is the common bridge from Tensor code to UOp construction.
The method calls a UOp-producing function over the input tensors' `.uop`s and
wraps the result in a new `Tensor`. The Tensor mixins implement math, movement,
reduction, creation, random, and gradient behavior.

A Python method call is not guaranteed to correspond to exactly one UOp:

- broadcasting can insert `RESHAPE` and `EXPAND`;
- a convenience operation can decompose to primitive ALU nodes;
- `arange` is itself a lazy expression rather than an eager allocation;
- movement stays explicit as `RESHAPE`, `PERMUTE`, `EXPAND`, `PAD`, `SHRINK`,
  and `FLIP` until rangeify;
- identical subexpressions can be the same hash-consed node.

So "raw graph" means the Tensor-level UOp DAG after the Tensor API has expressed
its semantics, not an audit log with one node per chained method. `Tensor.uop`
is the root to inspect. `UOp.sink(*roots)` gives multiple requested results one
root without implying evaluation order.

## The complete lowering path

### 1. Realization starts at a Tensor root

`Tensor.realize()` filters out values that have no device or already have a
buffer identity. For the remaining roots it calls:

```text
Tensor.linear_with_vars(...)
  -> transform_to_call(SINK(tensor roots))
  -> create_linear_with_vars(callified graph)
  -> run_linear(schedule LINEAR, variable values)
```

Realization mutates the Python Tensor wrappers to point at their realized buffer
identities, but transformations of the UOp DAG itself remain functional.

### 2. Callify chooses materialization and call boundaries

`tinygrad/callify.py::transform_to_call` turns an open Tensor expression
into a function-like graph with explicit arguments and effects. In order, its
main matchers do the following:

1. `add_tags` finds realization/allocation boundaries and tracks
   `COPY`, `AFTER`, and forced-contiguous values.
2. `pm_early_transform_tensor_graph` handles already compiled `FUNCTION`s,
   tuple extraction, zero-copy contiguous views, and the lowering of a forced
   `CONTIGUOUS` value to storage. It removes frontend-only detach/backward
   markers when their job is finished.
3. `pm_finalize_call` records stores, assignments, and other side effects.
4. `pm_replace_buf` replaces concrete `BUFFER`, `SLICE`, and `BIND` values with
   `PARAM`s so the function body has a reusable structural cache key.

The result is conceptually:

```text
CALL(
  SINK(function body with STORE/AFTER and PARAMs),
  concrete buffer argument 0,
  concrete buffer argument 1,
  ...)
```

Callify also returns a map used to update in-scope Tensors to their new buffer
identities. At this point movement and reduction intent are still visible.

### 3. Rangeify changes shapes into loops and indexes

`create_linear_with_vars` enters call bodies with `pm_schedule` and invokes
`schedule/rangeify.py::get_kernel_graph`. This is the largest semantic change in
the pipeline.

The scheduler first normalizes multi-device operations and early movement
syntax. `run_rangeify` then:

- computes which values must be materialized;
- builds a consumer map;
- creates `RANGE` nodes for output and reduction axes;
- propagates a consumer's ranges backward through the graph;
- replaces each movement operation with a mapping from output coordinates to
  input coordinates;
- represents padding validity with predicates/`WHERE` values;
- gives reductions reduction-typed ranges;
- inserts `STAGE` nodes at bufferization boundaries.

An elementwise tensor operation has no intrinsic loop before this pass. Its
shape tells rangeify which ranges to supply. Likewise, a reshape is not copied:
rangeify flattens the output coordinate in row-major order and unflattens it
against the input shape. After the coordinate transform is in the index
expression, the movement UOp can disappear.

Subsequent scheduler rewrites simplify symbolic expressions and reductions,
fold constant buffers, remove redundant staging, cap/split kernels with too many
buffers, and turn surviving global `STAGE`s into allocated buffers plus
`STORE`/`AFTER` effects. Finally `split_kernels` extracts independent stores and
ends into calls shaped like:

```text
CALL(SINK(..., arg=KernelInfo(...)), buffer arguments...)
```

This kernel `SINK` is an especially useful compiler boundary: it has explicit
iteration and buffer semantics, but still retains operations such as `REDUCE`.

### 4. Kernel calls become a dependency-ordered schedule

`schedule/__init__.py::create_schedule` builds dependencies among kernel calls.
It derives read-after-write edges from buffer states carried through `AFTER` and
adds write-after-read edges so a later assignment cannot clobber a state still
being read. A topological queue produces:

```text
LINEAR(CALL(kernel 0, ...), CALL(kernel 1, ...), ...)
```

This is the **schedule-level `LINEAR`**. Its children are executable calls, not
scalar instructions.

`pm_resolve_linear_call` substitutes cached `PARAM`s with concrete buffers and
flattens nested linears. `memory_plan_rewrite` computes temporary lifetimes and
uses TLSF suballocation to replace compatible global temporaries with `SLICE`s
of larger arenas. JIT capture can stop here and retain the schedule.

### 5. Each kernel is compiled

For normal execution, `engine/realize.py::compile_linear` rewrites every kernel
call. Optional CPU validation and BEAM annotations happen first. `pm_compile`
is the generic device seam:

```python
CALL(SINK(kernel), buffers...)
  -> CALL(to_program(kernel, Device[...].renderer), buffers...)
```

The matcher also accepts a call whose first source is an already constructed
`PROGRAM`, allowing progressive/custom compilation paths to re-enter here.

`to_program` calls `full_rewrite_to_sink`, whose current order matters:

1. normalize early movement-on-index forms;
2. collapse indexed loads and split/flatten ranges;
3. run symbolic simplification and range simplification;
4. apply hand-coded or BEAM-selected kernel opts;
5. build a map for upcast/unroll ranges, expand them into shaped constants and
   `RESHAPE`/`PERMUTE`/`STACK` forms, and expand shaped `WMMA` results;
6. lower `REDUCE` into register accumulators or horizontal trees and merge its
   range ends;
7. turn local `STAGE`s into local buffers, stores, and barriers;
8. add GPU dimensions as `SPECIAL` nodes;
9. make broadcasting explicit and insert `LOAD`s;
10. devectorize shaped elementwise/memory/`WMMA` work using `STACK` and shaped
    `INDEX` operations;
11. simplify indexes, rerun symbolic folding, coalesce memory, and select image
    accesses;
12. run another symbolic cleanup after coalescing;
13. lower index dtypes and decompose unsupported ALU/dtype/transcendental ops;
14. run the renderer's target-specific `extra_matcher` with final legalization;
15. add loop/control-flow dependency edges;
16. assign slots to still-unnumbered scalar `PARAM`s.

The result is a target-legal program `SINK`, but it is still a DAG.

This shape-based expansion is new in the July 2026 codegen rewrite. Older
traces show `GEP`, vector dtypes, `UNROLL`, `CONTRACT`, and `SHAPED_WMMA`; none
of those ops exist in this revision.

For an `ISARenderer` (currently the x86 path), pre-instruction-selection and
instruction-selection matchers turn target-independent nodes into `INS` before
the `PROGRAM` is built. Source renderers retain target-independent program UOps
for their string renderer.

### 6. The current linearizer is a priority topological sort

`codegen/late/linearizer.py::linearize` assigns each node a preferred position
based on loop run count and op class, then makes the closest legal topological
order. Important preferences include definitions first, loads early, stores
late, and range placement that forms sensible loop nests.

`do_linearize` then line-rewrites gated stores into `IF` / `STORE` / `ENDIF` if
necessary. ISA renderers additionally perform pre-register-allocation rewrites,
linear-scan register allocation, and post-allocation rewrites. The result is
attached to the program as:

```text
PROGRAM(
  SINK(...),
  LINEAR(PARAM, RANGE, LOAD, ALU, STORE, END, ...)
)
```

This is the **program-level `LINEAR`**, an ordered low-level UOp list.

Finally, an ISA renderer assembles `INS` nodes directly. A source renderer emits
text, and its compiler turns the `SOURCE` into `BINARY`. A complete program is
normally `PROGRAM(SINK, LINEAR, SOURCE, BINARY)`. `pm_exec` allocates unresolved
buffers, resolves the runtime program, computes launch dimensions, and invokes
the device runtime.

## Three naming traps

1. **There are two `LINEAR`s.** The schedule one contains calls. The program one
   contains low-level operations for a single kernel.
2. **There are two schedulers.** `tinygrad/schedule/` separates kernels and
   orders effects. `codegen/opt/postrange.py::Scheduler` chooses per-kernel
   range/global/local/upcast/tensor-core optimizations.
3. **There is no current `Linearizer` class.** Older tinygrad discussions refer
   to one. Today `pm_add_control_flow` has the comment "this was the linearizer",
   and the remaining `linearize()` function orders an already lowered DAG.

## Pattern matching is the compiler

`UPat` describes a local UOp pattern: root op/dtype, source patterns, arguments,
names to bind, and optional early rejection. A `PatternMatcher` indexes ordered
rules by possible root op. The first matching rule that returns a non-`None`,
non-identity replacement wins. `a + b` concatenates matchers, so order is part
of compiler semantics.

`graph_rewrite` repeatedly reconstructs nodes using rewritten sources and asks
the matcher for replacements. Its modes matter:

- ordinary mode reaches a fixed point and caches rewritten nodes;
- `bottom_up=True` drives local replacement before reconstructing consumers;
- `walk=True` is a single walking pass used where replacements should not be
  recursively re-entered in the same way;
- `ctx` carries pass-local mutable state such as range maps, renderer features,
  counters, or allocation context;
- `enter_calls=True` allows a rewrite to cross otherwise opaque call bodies.

Patterns are lazily compiled for speed, with an interpreter fallback. Rewrite
tracking and visualization wrap this machinery rather than defining another
pass framework. See [PatternMatcher reference](pattern-matchers-reference.md)
for every production matcher and factory in this revision.

## How ShapeTracker was removed

### What it used to do

The old `ShapeTracker` held a tuple of `View` objects. Each view carried a shape,
strides, offset, optional validity mask, and contiguity information. Movement
operations composed views; late lowering asked the tracker for a flat memory
index and a validity expression.

It worked, but it was a second, parallel IR. Tensor semantics lived partly in
UOps and partly inside opaque `ShapeTracker`/`View` arguments. View merging had
its own algebra and edge cases, and compiler patterns could not inspect the
coordinate transformation as ordinary UOps.

### What replaced it

ShapeTracker was not replaced by one new class. Its responsibilities were split:

- tensor movement remains explicit in the graph;
- `UOp._shape` derives shapes directly from UOps;
- `run_rangeify` gives consumers explicit ranges and propagates them backward;
- `apply_movement_op` translates coordinates through each movement op;
- reshape uses symbolic row-major flatten/unflatten arithmetic;
- pad produces an explicit validity predicate;
- symbolic matchers simplify the resulting index DAG;
- movement nodes are deleted once their mapping is encoded in those indexes.

The telling comment in `_apply_reshape` calls symbolic simplification the
replacement for reshape view-merging code. Complexity did not vanish: it moved
from a hidden view stack into a common, inspectable graph and the general rewrite
system.

### The migration, not just the final deletion

Useful landmarks in git history are:

| Date | Commit | Change |
|---|---|---|
| 2024-05-17 | `07b350a8f` | "new uops is an actual graph" |
| 2024-07-12 | `870dc8c35` | renamed `Linearizer` to `Lowerer` |
| 2024-10-04 | `f4ec39fe5` | symbolic math moved to UOps |
| 2024-12-28 | `90ce2c602` | UOp shape spec / TIP 4 work |
| 2025-06-08 | `32e994905` | `lazydata` renamed to `uop` |
| 2025-08-20 | `963559214` | "rangeify try 3" landed |
| 2025-10-08 | `1e567a5cf` | rangeify became the default |
| 2025-10-08 | `b6835f413` | `Ops.VIEW` removed |
| 2025-10-08 | `077457544` | old rangeify path deleted |
| 2025-10-15 | `a59439d01` | `UOp.shape` replaced `UOp.st` use |
| 2025-10-16 | `592e86f6f` | `UOp.st` removed |
| 2025-10-16 | `1d1e1d9d8` | ShapeTracker and old tests deleted |
| 2025-10-30 | `e64d4b3b4` | programs represented as UOps |
| 2025-11-06 | `42b34cf83` | bottom-up linearizer work |
| 2026-01-30 | `7a9dee4e5` | `CALL`/`PARAM` architecture |
| 2026-03-16 | `b3378e702`, `e1fab4d2a` | assignment became `STORE` + `AFTER`; `STORE` became void |
| 2026-07-04 | `c7e7687bd` | new shape-based codegen landed |
| 2026-07-04 | `3fd6f3d28` | `GEP` removed |
| 2026-07-05 | `dd6aa77fd` | `UNROLL` and `CONTRACT` removed |
| 2026-07-06 | `d94ad4444` | `SHAPED_WMMA` removed |
| 2026-07-07 | `2fc7e5341` | `PtrDType` removed |
| 2026-07-09 | `93338df75` | dedicated `dtypes.index` introduced |
| 2026-07-09 | `1df49a7bf` | most UOp dtypes became inferable at construction |

Read the deletion commit only after the earlier rangeify commits. The deletion
is small conceptually because the replacement had already become authoritative.

## Current costs and rough edges

These are not all runtime-performance bugs. Most are compile-time scaling,
maintainability, validation, or backend-fit issues. The evidence column points
to a concrete current-code signal rather than guessing from aesthetics.

| Area | Why it costs | Current evidence / qualification |
|---|---|---|
| Repeated whole-DAG rewrites | Codegen reconstructs and scans the graph many times, sometimes with overlapping symbolic matchers. Hash-consing and caches help, but large index DAGs still pay traversal and matching costs. | The ordered calls in `full_rewrite_to_sink`; benchmark before combining passes because fixed-point/order semantics differ. |
| Buffer limiting | The pass repeatedly discovers relationships between buffers and ranges. | `schedule/rangeify.py::limit_bufs` has an explicit "add cache to fix n^2" TODO. |
| Expensive validity optimization is disabled | Padding/gating can create repeated `WHERE`s. A useful closure fold is commented out because its naive implementation compares each `WHERE` with many graph nodes. | `uop/symbolic.py` labels the disabled fold `O(number of WHERE * number of node)`. This is missed simplification, not active quadratic work. |
| Shape expansion can multiply nodes | Current expansion/devectorization enumerates Cartesian products of shaped axes and constructs scalar indexed copies before stacking them. This is clearer than the removed vector/GEP bridge, but large upcasts/broadcasts can still create many Python UOps. | `codegen/__init__.py::do_devectorize` and `broadcast_and_devec_wmma`; measure compile time and node count before changing it. |
| One enum, many dialects | A small core is attractive, but phase-overloaded ops require implicit invariants and special cases in shape/spec code. New contributors can construct a locally valid UOp that is illegal at that phase. | `spec_tensor`, `spec_program`, and `spec_full` differ; shape derivation has special cases/hacks for `NOOP`, `STACK`, `SLICE`, `STAGE`, and movement reused during codegen. |
| Semantic information is deliberately erased | By renderer time a reduction is a register accumulator/tree and attention is unrelated matmul/softmax graphs. This is correct for scalar GPU codegen but a poor late hook for a tile/dataflow architecture. | `pm_reduce_local` precedes renderer matchers; there is no generic attention UOp. |
| Matcher construction/caching | Matcher addition creates composites, factories specialize for target capabilities, and root-index/compiled-pattern caches live for long periods. This trades memory and startup work for fast local rewrites. | `PatternMatcher.__add__`, lazy UPat compilation, and the lifetime warning around matcher keys. Measure rather than assuming it dominates. |
| Autotuning compile latency | BEAM compiles/runs candidate schedules; local-size selection can try launches. This can dwarf ordinary rewrite time. | Optional behavior, normally controlled by `BEAM` and local-size optimization; it may improve kernel runtime. |
| Validation holes | Some complex shaped index structures are deliberately skipped by out-of-bounds validation, and the strongest spec modes are not routine. | `validate_index` skips non-final shaped indexes and indexes containing `BITCAST` or `STACK`, and notes overflow is unchecked; rangeify temporarily caps `SPEC` at 2 because `SPEC=3` shape checking is broken there. |
| Transitional dtype/shape rules | The constructor now infers dtype, while the object still stores it and `PARAM`/`BUFFER` metadata also carries dtype. This improves call sites but leaves production rules and phase specs to keep synchronized. | `dtype_from_uop` says it may eventually become a recursive UOp property; `SLICE` and `CONST` retain dtype TODOs. |
| ShapeTracker complexity moved into expressions | Rangeify made indexing uniform and visible, but symbolic flatten/unflatten and validity DAGs can grow before simplification. | This is the intended trade: fewer parallel abstractions, potentially larger UOp graphs. Profile representative movement-heavy graphs. |

The best first optimization patch is the explicit `limit_bufs` cache TODO. The
disabled validity fold is a good follow-up only with an indexed algorithm and
fuzz tests. Shape expansion is a deeper architectural/performance area with a
larger regression surface.

## A practical way to read and debug this compiler

Follow one small graph and record op counts at boundaries instead of trying to
read every matcher first:

1. inspect `tensor.uop` before realization;
2. inspect `transform_to_call(UOp.sink(...))`;
3. inspect `get_kernel_graph(function_sink)`;
4. inspect the schedule `LINEAR` from `create_linear_with_vars`;
5. inspect `full_rewrite_to_sink` with `VIZ=1` or rewrite tracking;
6. inspect the program `LINEAR` and emitted source.

Change one property at a time: contiguous versus transposed, divisible versus
edge-masked size, one reduction axis versus two, scalar versus broadcast input.
Diffing two small graphs teaches more than staring at a large model DAG.

Useful test neighborhoods are:

- `test/null/test_pattern_matcher.py` and `test/null/test_graph_rewrite.py`;
- `test/null/test_uop_graph.py` and `test/null/test_uop_symbolic.py`;
- `test/backend/test_rangeify.py` and `test/backend/test_schedule.py`;
- `test/backend/test_uops.py`;
- `test/backend/test_linearizer*.py`;
- `test/external/external_benchmark_schedule.py` and the schedule-scaling test.

The [UOp probe corpus](uop-probes/README.md) already applies this method to
movement, elementwise, reduction, matmul, convolution, effects, and attention.

## Source map for this revision

| Question | First file to open |
|---|---|
| UOp enum and op groups | `tinygrad/uop/__init__.py` |
| UOp identity, properties, rewrite engine | `tinygrad/uop/ops.py` |
| Pattern syntax/compiler | `tinygrad/uop/upat.py` |
| Phase validity | `tinygrad/uop/spec.py` |
| Tensor-to-UOp bridge | `tinygrad/tensor.py`, `tinygrad/mixin/` |
| Call/buffer boundary | `tinygrad/callify.py` |
| Range propagation / movement indexing | `tinygrad/schedule/indexing.py` |
| Kernel extraction | `tinygrad/schedule/rangeify.py` |
| Kernel dependency schedule | `tinygrad/schedule/__init__.py` |
| Temporary allocation | `tinygrad/schedule/memory.py` |
| Per-kernel lowering pipeline | `tinygrad/codegen/__init__.py` |
| Range optimization | `tinygrad/codegen/opt/postrange.py` |
| Final ordering | `tinygrad/codegen/late/linearizer.py` |
| Compile and execute dispatch | `tinygrad/engine/realize.py` |
