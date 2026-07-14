# PatternMatcher reference

This is a static, source-level inventory for tinygrad commit
`4234a9d727e52a6bb033c387d2c869cea4caf641` (2026-07-10). It answers two
different questions:

- how tinygrad's rewrite engine works; and
- what every `PatternMatcher(...)` construction site in this checkout is for.

It does not pretend that the number of runtime matcher objects is fixed.
Composition, cached factories, renderer selection, and architecture-specific
mutation all create or extend matchers at runtime.

## Exact census

An AST count finds **232 direct `PatternMatcher(...)` calls in 44 Python
files**:

| Scope | Direct sites | Files | Breakdown |
|---|---:|---:|---|
| `tinygrad/` | 141 | 34 | 130 non-empty semantic/dynamic sites, 10 empty sites, and the constructor inside `PatternMatcher.__add__` |
| `extra/hcq2/` | 30 | 2 | Experimental host-command-queue compilation and AMD queue encoding |
| `test/` | 61 | 8 | Rewrite-engine, visualization, serialization, and graph tests |
| **Total** | **232** | **44** | No direct construction sites elsewhere in this checkout |

The 34 production files reconcile as follows:

| File | Sites | File | Sites |
|---|---:|---|---:|
| `tinygrad/callify.py` | 6 | `tinygrad/codegen/__init__.py` | 16 |
| `tinygrad/codegen/decomp/dtype.py` | 3 | `tinygrad/codegen/decomp/op.py` | 2 |
| `tinygrad/codegen/decomp/transcendental.py` | 1 | `tinygrad/codegen/gpudims.py` | 1 |
| `tinygrad/codegen/late/coalese.py` | 2 | `tinygrad/codegen/late/gater.py` | 1 |
| `tinygrad/codegen/late/linearizer.py` | 2 | `tinygrad/codegen/late/regalloc.py` | 1 |
| `tinygrad/codegen/simplify.py` | 8 | `tinygrad/engine/jit.py` | 2 |
| `tinygrad/engine/realize.py` | 6 | `tinygrad/function.py` | 1 |
| `tinygrad/mixin/gradient.py` | 1 | `tinygrad/renderer/cstyle.py` | 12 |
| `tinygrad/renderer/isa/x86.py` | 5 | `tinygrad/renderer/llvmir.py` | 7 |
| `tinygrad/renderer/nir.py` | 3 | `tinygrad/renderer/ptx.py` | 2 |
| `tinygrad/renderer/wgsl.py` | 2 | `tinygrad/runtime/ops_dsp.py` | 2 |
| `tinygrad/schedule/__init__.py` | 3 | `tinygrad/schedule/indexing.py` | 3 |
| `tinygrad/schedule/multi.py` | 3 | `tinygrad/schedule/rangeify.py` | 16 |
| `tinygrad/uop/divandmod.py` | 1 | `tinygrad/uop/movement.py` | 1 |
| `tinygrad/uop/ops.py` | 6 | `tinygrad/uop/render.py` | 4 |
| `tinygrad/uop/spec.py` | 4 | `tinygrad/uop/symbolic.py` | 11 |
| `tinygrad/uop/upat.py` | 2 | `tinygrad/uop/validate.py` | 1 |

### Why `rg 'PatternMatcher\('` says 240

That regular expression is a substring search, not a constructor parser. Its
240 lines are:

- the 232 direct calls above;
- six explicit `TrackedPatternMatcher(...)` calls in
  `test/null/test_viz.py`;
- `class TrackedPatternMatcher(PatternMatcher):`; and
- `class TestPatternMatcher(unittest.TestCase):`.

The last class name also contains the searched substring. The six tracked
calls are real constructor calls, but deliberately are not direct
`PatternMatcher(...)` calls and therefore are outside the 61-column AST
census. Also, when match tracking or profiling is enabled, production code
rebinds the name `PatternMatcher` to `TrackedPatternMatcher`; the source count
does not change.

## How a matcher works

A rule is a pair `(UPat(...), callback)`. Think of `UPat` as a small query over
one UOp and its sources:

- `op` selects one operation or a set such as `GroupOp.ALU`;
- `dtype`, `arg`, and `tag` constrain metadata;
- `src` describes ordered child patterns and may contain alternatives;
- `allow_any_len=True` permits additional children;
- `name="x"` binds the matched UOp for the callback, and reusing a name means
  the occurrences must be the same interned UOp; and
- `custom_early_reject` can provide an additional cheap child-op filter.

Every root pattern must identify at least one possible op. Construction builds
`PatternMatcher.pdict`, an ordered rule list indexed by root `Ops`. Before a
full match, `rewrite` checks the pattern's `early_reject` set against the
root's child-op set. This avoids walking source patterns that cannot possibly
match.

Callbacks receive named UOps and optionally `ctx`. Returning `None` or the
original UOp means "no rewrite". The first callback that returns a different
object wins, so source order is part of compiler semantics. Callback closures
are forbidden because matcher lambdas must be reconstructable for pickling.

Rules are lazily compiled to specialized Python by `tinygrad/uop/upat.py`.
If compilation is disabled or unsupported, tinygrad uses the interpreter.
`compiled=False` is explicit at three sites (`pm_proc`, `pm_renderer`, and
`pm_gate_substitute`) where interpreted behavior is needed. `a + b`
concatenates the two ordered rule lists and caches the
resulting matcher.

`graph_rewrite` supplies the graph-level behavior. In normal mode it rewrites
shared DAG nodes once, rebuilds parents after child changes, and processes
replacement graphs until stable. Important switches are:

- `bottom_up=True` applies the matcher as the early/fixed-point matcher;
- `walk=True` selects a single MLIR-style walk and does not recurse into a
  replacement;
- `enter_calls=True` crosses the normally opaque `CALL`/`FUNCTION` body
  boundary;
- `bpm=` adds a separate early matcher; and
- `BottomUpGate` lets a rule prune a subtree, as rangeify substitution does.

Rewrite tracking swaps in `TrackedPatternMatcher`, records attempts, matches,
times, before/after UOps, pass names, and locations, and feeds the visualization
tools. It preserves first-success semantics.

## The July 2026 representation change

Older tinygrad matcher maps are misleading for this revision. The July
codegen rewrite deleted `Ops.GEP`, `Ops.UNROLL`, `Ops.CONTRACT`, and
`Ops.SHAPED_WMMA`, and removed vector dtype as the generic lane/shape carrier.
Generic codegen now represents lanes with shaped UOps, movement ops, `STACK`,
and scalar `INDEX`; `expander2`, `unbroadcast`, and `devectorizer2` perform the
shape-to-scalar transition in `codegen/__init__.py`.

Two qualifications matter:

- `AxisType.UNROLL` and `OptOps.UNROLL` still exist. A `RANGE` may be classified
  as unrolled, but there is no longer an `Ops.UNROLL` node.
- Late ISA selection can still use packed `DType.count > 1` values (x86 does).
  They are a target representation, not the generic graph's old vector bridge.

Consequently, there is no current `codegen/late/expander.py`, no
`codegen/late/devectorizer.py`, no `pm_remove_vec_dtypes`, no `gep_pushing`,
and no renderer `pre_matcher` stage.

## Core UOp, symbolic, and specification matchers

### `tinygrad/uop/ops.py` — 6 sites

| Site | Purpose |
|---|---|
| `PatternMatcher.__add__` | Constructs and caches the ordered composite for `a + b`. This is infrastructure, not a compiler pass. |
| `pm_lower_index_dtype` | Chooses concrete `int`/`long` widths for `dtypes.index`, pushes widths through arithmetic/ranges/stacks/params/binds, and removes wrapper casts from final indexes and structural nodes. |
| `_substitute` | Generic context-dictionary replacement used by `UOp.substitute`. |
| `_pm_resolve_params` | Replaces a `PARAM` by the call argument at its slot. |
| `remove_all_tags` | Clears transient UOp tags across a graph. |
| `pm_unbind` | Replaces `BIND(variable, constant)` with the variable and records the concrete value in context. |

### `tinygrad/uop/movement.py` — 1 site

| Site | Purpose |
|---|---|
| `mop_cleanup` | Canonicalizes movement IR: merges/removes reshapes and permutes and simplifies `STACK`/constant-`INDEX` inverse pairs. |

### `tinygrad/uop/divandmod.py` — 1 site

| Site | Purpose |
|---|---|
| `div_and_mod_symbolic` | Canonicalizes and folds index `FLOORDIV`/`FLOORMOD`, including congruence, GCD, nested division, quotient/remainder recombination, and variable-denominator cases. |

### `tinygrad/uop/symbolic.py` — 11 sites

| Site | Purpose |
|---|---|
| `pm_index_invalid` | Drops an `Invalid` gate where an index result is only cast or compared; the consuming index still carries validity. |
| `pm_data_invalid` | Propagates `Invalid` through data ALU/casts/`WHERE` and folds invalid loads and stores. |
| `pm_remove_invalid` | Converts any non-index `Invalid` constant left at final rendering to zero. |
| `symbolic_simple` | Fast identities, constant folding, cast/bitcast cleanup, elementary boolean/where/pow rules, movement cleanup, and invalid propagation. |
| `commutative` | Gives commutative `dtypes.index` expressions a deterministic operand order. |
| `symbolic` | Deeper bounds-aware algebra, term combining, range/div/mod/cast simplification, and `AFTER` dependency cleanup, layered on `symbolic_simple`. |
| `pm_drop_and_clauses` | Removes validity conjunction clauses whose ranges cannot affect the gated expression. |
| `pm_move_where_on_load` | Moves eligible outer `WHERE` conditions into an index's validity and removes duplicate clauses already on the load. |
| `pm_simplify_valid` | Simplifies conjunctions and index expressions under facts known true inside a validity region. |
| `pm_clean_up_group_sink` | Removes one-child `GROUP`s and flattens nested/no-op `GROUP`/`SINK` structure. |
| `sym` | Broad high-level composite: shaped elementwise cleanup, cast/where/pow/load/store/reduction algebra, then group/sink cleanup. |

`propagate_invalid = pm_index_invalid + pm_data_invalid` is a composite, not
another constructor site. Likewise `symbolic_simple`, `symbolic`, and `sym` are
successively broader layers, not synonyms.

### `tinygrad/uop/render.py` — 4 sites

| Site | Purpose |
|---|---|
| `renderer` | Renders a UOp expression as a short human-readable string. |
| `renderer_infer` | Adds explicit inference/debug forms for division, modulo, and bitcasts. |
| `pm_pyrender_extra` | Emits compact, reconstructable Python for common UOps. |
| `pm_pyrender` | Adds the generic `UOp(...)` Python fallback to `pm_pyrender_extra`. |

### `tinygrad/uop/spec.py` — 4 sites

These callbacks return `True` for valid local forms; `type_verify` uses them as
an executable grammar.

| Site | Purpose |
|---|---|
| `spec_shared` | Arity, dtype, ALU, memory, control-flow, and structural invariants shared by tensor graphs and programs. |
| `spec_tensor` | Tensor/function/scheduler forms: movement, multi-device, calls, staging, and progressive kernel state. |
| `spec_program` | Final-program restrictions, including the absence of movement ops, index dtype, and `Invalid`. |
| `spec_full` | Permissive transitional union used when constructing intermediate UOps. |

### `tinygrad/uop/upat.py` — 2 sites

| Site | Purpose |
|---|---|
| `pm_proc` (`compiled=False`) | Simplifies the boolean UOp program produced while compiling a `UPat`. |
| `pm_renderer` (`compiled=False`) | Renders that program as specialized Python. This is the matcher compiler implemented with matchers. |

### `tinygrad/uop/validate.py` — 1 site

| Site | Purpose |
|---|---|
| `z3_renderer` | Translates supported integer/boolean UOps and constraints to Z3 for out-of-bounds validation. |

## Tensor graph construction, callify, and autograd

### `tinygrad/callify.py` — 6 sites

| Site | Purpose |
|---|---|
| `add_tags` | Finds allocation/realization boundaries, records original graph nodes, and tags `CONTIGUOUS`/`AFTER`/disk-copy storage for call construction. |
| `pm_early_transform_tensor_graph` | Rewrites precompiled functions, tuples, contiguous buffer views, disk copies, realization tags, `DETACH`, and `CONTIGUOUS_BACKWARD` into call-ready storage operations. |
| `pm_finalize_call` | Resolves tagged `AFTER`s into the original-to-storage map and collects assignment or disk effects for the call body. |
| `pm_replace_buf` | Replaces global `BUFFER`, `SLICE`, and concrete `BIND` inputs with normalized `PARAM`s for reusable call/cache keys. |
| `PatternMatcher([])` — `View Tensor Graph` | No-op visualization snapshot before callification. |
| `PatternMatcher([])` — `View Call` | No-op visualization snapshot after callification. |

### `tinygrad/function.py` — 1 site

| Site | Purpose |
|---|---|
| `pm_ctx` | Makes buffers, bindings, and realized dependencies captured by a function explicit parameters in its function context. |

### `tinygrad/mixin/gradient.py` — 1 site

| Site | Purpose |
|---|---|
| `pm_gradient` | Reverse-mode derivative rules for ALU, reductions, movement, multi-device nodes, stores, calls, and tuple results. |

## Rangeification and scheduling

### `tinygrad/schedule/indexing.py` — 3 sites

| Site | Purpose |
|---|---|
| `pm_generate_realize_map` | Marks mandatory realization points and store/self-access hazards before ranges are propagated. |
| `pm_apply_rangeify` | Inserts explicit ranges, `INDEX`, and `STAGE`; turns padding into validity; gives reductions their ranges; and removes high-level movement nodes. |
| `pm_fix_deviceless` | Supplies a missing device on a global `STAGE`. |

### `tinygrad/schedule/multi.py` — 3 sites

| Site | Purpose |
|---|---|
| `replace_allreduce` | Normalizes copies to/from multi-device values, `MSELECT(MSTACK)`, shard shrinking, and movement around shard selection. |
| `_early_allreduce` | Optional eager `ALLREDUCE` implementation, composed into `replace_allreduce` when `LATE_ALLREDUCE=0`. |
| `multi_pm` | Distributes parameters, ALU, reductions, movement, stores, calls, functions, and tuples over shards, then removes `MULTI` wrappers where appropriate. |

The effective `replace_allreduce` rule list therefore depends on the
environment at import time.

### `tinygrad/schedule/rangeify.py` — 16 sites

| Site | Purpose |
|---|---|
| `pm_fold_moved_after` | OpenPilot-specific recovery of `AFTER` dependencies hidden behind movement/cast/padded expressions. |
| `pm_mops` | Applies movement to explicit indexes and moves movement/index nodes through `AFTER` and `END`. It no longer lowers `SHAPED_WMMA`. |
| `pm_gather_params` | Collects nonnegative-slot params while inlining a function. |
| `earliest_rewrites` | Inlines ordinary functions, resolves tuples/allreduce, splits large reductions, expands shape-changing bitcasts, normalizes sinks/copies/stores, and handles zero-size graphs before rangeify. |
| `pm_gate_substitute` (`compiled=False`) | Raises `BottomUpGate` so substitutions do not walk subgraphs that cannot contain relevant ranges. |
| `pm_const_buffer_folding` | Removes dead axes/stages and folds constants, invalid indexes, copies, no-ops, and multi-stacks around staging. |
| `pm_remove_bufferize` | Uses a cost decision to remove unnecessary `STAGE`/`INDEX`, and removes self-store/no-op ends. |
| `pm_limit_bufs` | Inserts staging into large elementwise expressions when a target's per-kernel buffer limit would be exceeded. |
| `pm_flatten_bufferize` | Turns multi-axis staging into one flat index, then restores the logical shape. |
| `pm_add_buffers` | Converts global `STAGE` to real buffer stores/ends and cleans multi-device reshapes, call inputs, invalid stores, and no-op dependencies. |
| `to_define_global` | Converts buffers to kernel params, named scalar params to variables, removes binds/afters, checks indexing cycles, strips local-stage devices, and renumbers ranges. |
| `rangeify_codegen` | Removes `CONTIGUOUS`/empty `NOOP` at kernel split time while preserving applied optimization metadata. |
| `pm_add_param_range_tags` | Temporarily tags `PARAM` and `RANGE` so kernel-local renumbering and parameter assignment can distinguish them. |
| `split_kernels` | Extracts closed store/end regions as kernel, copy, or slice `CALL`s. |
| `PatternMatcher([])` — `View Rangeify` | No-op visualization snapshot after rangeification and buffer decisions. |
| `PatternMatcher([])` — `View Kernel Graph` | No-op visualization snapshot after kernel splitting. |

`mop_cleanup` now lives in `uop/movement.py` and is composed into rangeify
matchers; it is not another rangeify constructor. Older names
`pm_store_ranges`, `pm_syntactic_sugar`, `to_bufferview`, and
`pm_add_buffers_local` are gone.

### `tinygrad/schedule/__init__.py` — 3 sites

| Site | Purpose |
|---|---|
| `pm_post_sched_cache` | Resolves cached schedule params to actual call inputs and creates fresh concrete global buffers. |
| `pm_resolve_linear_call` | Substitutes arguments into a cached schedule `LINEAR` and flattens nested schedule linears. |
| `pm_schedule` | Replaces a non-kernel function `SINK` with its dependency-ordered schedule `LINEAR`. |

## Generic code generation

### `tinygrad/codegen/__init__.py` — 16 sites

This file now owns expansion, reduction lowering, and shape scalarization that
used to be split across the deleted late expander/devectorizer modules.

| Site | Purpose |
|---|---|
| `pm_number_params` | Assigns slots to scalar params whose slot is `-1`. |
| `pm_no_index` | Converts final `dtypes.index` ALU/constants/casts to concrete `int` after index-width lowering. |
| `expander2` | Materializes `UPCAST`/`UNROLL` ranges as shaped constants, expands horizontal reduction axes, reshapes tagged WMMA input/output lanes, and composes range/movement cleanup. |
| `pm_wmma_add` | Folds an addend into the WMMA accumulator and moves reshape/permute through a WMMA-add expression. |
| `unbroadcast` | Makes binary/ternary/store broadcasting explicit; broadcasts WMMA batches and expands them into independent WMMA values. |
| `ew_devectorizer` | Scalarizes shaped elementwise operations after memory coalescing, especially around image conversion. |
| `devectorizer2` | Scalarizes shaped elementwise/load/store graphs, lowers shaped indexes, prepares WMMA stacks, flattens nested indexes, and cleans scalar reshape/expand cases. |
| `pm_reduce_local` | Handles grouped local reductions, replaces range reductions with explicit register accumulators/store/end dependencies, expands horizontal reductions, folds WMMA adds, and merges compatible ends. |
| `pm_add_loads` | Inserts explicit `LOAD` when an elementwise/reduce/WMMA/stack/store operand is an address-space-backed value. |
| `pm_add_local_buffers` | Lowers local `STAGE` to a placeholder local buffer, store/end, and barrier. |
| `PatternMatcher([])` — `View Base AST` | No-op visualization snapshot entering `full_rewrite_to_sink`. |
| fallback `PatternMatcher([])` | Identity `extra_matcher` when the selected renderer has no target-specific final rules. This is the one empty non-visualization site. |
| `PatternMatcher([])` — `View Output AST` | No-op visualization snapshot after final graph lowering. |
| `pm_linearize_cleanups` | Rejects graph-level `IF`/`ENDIF` and expands a gated store into line-level `IF`, `STORE`, `ENDIF`. |
| `pm_to_program` | Progressively adds `LINEAR`, estimates, `INS` or source, and compiled binary to a `PROGRAM`. |
| `PatternMatcher([])` — `View Program` | No-op visualization snapshot of the progressively built program. |

In actual `full_rewrite_to_sink` order, the important current chain is:
`pm_mops` → range/reduction simplifiers → `expander2` → `pm_reduce_local` →
`pm_add_local_buffers` → GPU dimensions → `unbroadcast + pm_add_loads` →
`devectorizer2` → index/image/coalescing passes → index-width lowering →
decompositions → gates → renderer `extra_matcher + pm_split_ends + pm_no_index
+ pm_remove_invalid` → control-flow dependencies → parameter numbering.

### `tinygrad/codegen/decomp/dtype.py` — 3 sites

| Site | Purpose |
|---|---|
| `pm_long_decomp` | Emulates unsupported 64-bit integer values as paired 32-bit values. |
| `pm_float_decomp` | Emulates unsupported low-precision float storage/compute using integer storage and a supported compute float. |
| `pm_dtype_decomps` | Detects unsupported/emulated dtypes at the sink and dispatches the appropriate decomposition. |

### `tinygrad/codegen/decomp/op.py` — 2 sites

| Factory site | Purpose |
|---|---|
| `get_simplifying_rewrite_patterns(...)` | Builds a matcher specialized to the renderer's supported ops for early floor/trunc division, modulo, Threefry, and max legalization. |
| `get_late_rewrite_patterns(...)` | Builds target-dependent late rules for shifts, magic division, neg/sub, comparisons, FMA, reciprocal/division, and other unsupported ops. |

### `tinygrad/codegen/decomp/transcendental.py` — 1 site

| Factory site | Purpose |
|---|---|
| `get_transcendental_patterns(...)` | Builds software `EXP2`, `LOG2`, `SIN`, and `SQRT` lowering according to target support and the transcendental mode. |

These three functions are cached factories. One source call site can create
several runtime matcher instances for different supported-op tuples.

### `tinygrad/codegen/gpudims.py` — 1 site

| Site | Purpose |
|---|---|
| `pm_add_gpudims` | Replaces global/local/warp/group ranges with target-limited `SPECIAL` launch coordinates and adds missing local validity to global stores. |

### `tinygrad/codegen/simplify.py` — 8 sites

| Site | Purpose |
|---|---|
| `pm_flatten_range` | Rebuilds the explicit range dependencies of reductions and ends in canonical nesting order. |
| `pm_simplify_ranges` | Merges compatible ranges and shrinks ranges using index validity, while protecting reduction ranges. |
| `pm_split_ranges` | Splits modulo-compatible ranges into outer and inner ranges. |
| `pm_reduce_unparented` | Removes reduction ranges unused by the reduced expression, applying the operation's closed form. |
| `pm_reduce_collapse` | Pulls range-independent factors/terms out of reductions and analytically collapses supported range predicates. |
| `pm_reduce_load_collapse` | Adds collapse rules for reductions involving indexed loads and equality-like selection. |
| `pm_reduce_simplify` | Eliminates add reductions whose range dependence can be symbolically collapsed without loads. |
| `pm_load_collapse` | Collapses reductions produced by tensor indexing while retaining overflow-safe index algebra. |

### `tinygrad/codegen/late/coalese.py` — 2 sites

| Site | Purpose |
|---|---|
| `indexing_simplify` | Simplifies gated scalar/image indexes using the validity constraints and drops image validity clauses already guaranteed by out-of-bounds coordinates. |
| `pm_simplify_add_image` | Chooses image layouts/indexes, normalizes image load/store float dtype, and removes redundant half/float round trips. |

`memory_coalesing` in this file is a whole-graph function, not a
`PatternMatcher` construction site.

### `tinygrad/codegen/late/gater.py` — 1 site

| Site | Purpose |
|---|---|
| `pm_move_gates_from_index` | Converts `Invalid`-encoded scalar/image indexes into explicit load alternatives and load/store gates late enough for renderers. |

### `tinygrad/codegen/late/linearizer.py` — 2 sites

| Site | Purpose |
|---|---|
| `pm_add_control_flow` | Adds dependencies between sibling ranges so the later priority topological sort preserves loop nesting/order. The source calls this step "what was the linearizer." |
| `pm_split_ends` | Converts a multi-range `END` into nested one-range `END`s. |

### `tinygrad/codegen/late/regalloc.py` — 1 site

| Site | Purpose |
|---|---|
| `pm_regalloc_rewrite` | Performs line-level linear-scan register allocation: definitions, live intervals, physical assignments, spills/reloads, and pseudo-op cleanup. |

## Renderers and target legalization

There is no generic renderer `pre_matcher` in this revision. A target's
`extra_matcher` participates in the final graph rewrite; string/definition
matchers then turn final UOps into source or target IR. ISA renderers instead
continue into instruction selection and register allocation.

### `tinygrad/renderer/cstyle.py` — 12 sites

| Site | Purpose |
|---|---|
| `base_rewrite` | Shared C-family rendering for buffers, control flow, constants, casts, indexes, memory, stacks, WMMA, ALU, and custom text. |
| `create_non_native_float_pats`: base site | Upcasts unsupported float `WHERE`, ALU, and comparisons to float32. |
| `create_non_native_float_pats`: conditional cast site | Adds float32 intermediary casts when direct casts to/from the emulated dtype are unavailable. |
| `pm_manual_bf16_cast` | Implements bf16 ↔ float32 conversion with integer bit operations. |
| `ClangRenderer.extra_matcher` local site | Avoids unsupported f64/f16/bf16 direct casts before composing bf16 emulation. |
| `OpenCLRenderer.string_rewrite` local site | Emits OpenCL bitcasts, bf16 constants, and image access, then composes `base_rewrite`. |
| `MetalRenderer.extra_matcher` | Upcasts bf16 transcendental operations unsupported by Metal. |
| `MetalRenderer.string_rewrite` local site | Emits Metal bitcast syntax before C-style rendering. |
| `CUDARenderer.extra_matcher` local site | Converts between fp8 formats through float when direct cross-format conversion is missing. |
| `CUDARenderer.string_rewrite` local site | Emits CUDA bitcast syntax before C-style rendering. |
| `HIPRenderer.__init__` string site | Adds CDNA-specific WMMA/fp8 source forms to the instance string matcher. |
| `HIPRenderer.extra_matcher` local site | Packs AMD WMMA operands and handles bf16 constants, composed with generated non-native-float rules. |

### `tinygrad/renderer/llvmir.py` — 7 sites

| Site | Purpose |
|---|---|
| `LLVMRenderer.base_rewrite` | Constructs generic LLVM IR values, memory/control flow, and instructions from final UOps. |
| `AMDLLVMRenderer.string_rewrite` local site | Emits AMD work-item, barrier, transcendental, and fp8 intrinsics on top of LLVM rendering. |
| `AMDLLVMRenderer.extra_matcher` local site | Adapts WMMA widths and decomposes unsupported double transcendental operations. |
| architecture string addition | Adds the selected AMD WMMA intrinsic spelling at instance initialization. |
| CDNA extra addition | Packs bf16/fp8 WMMA inputs for CDNA targets. |
| gfx1100/gfx1151 extra addition | Adapts accumulator width and bf16 WMMA representation. |
| gfx1200/gfx1201 extra addition | Adapts bf16 WMMA representation for those targets. |

The last four mutate an instance according to the selected architecture; all
seven are distinct constructor sites.

### `tinygrad/renderer/nir.py` — 3 sites

| Site | Purpose |
|---|---|
| `NIRRenderer.extra_matcher` | Legalizes unsigned constants, bool memory, shift widths, float-to-small-uint conversion, pointer/index widths, and image coordinates for NIR. |
| `NIRRenderer.def_rewrite` | Maps legal final UOps to Mesa NIR definitions and instructions. |
| `IR3Renderer.def_rewrite` local site | Adds Qualcomm image load/store forms before the base NIR lowering. |

### `tinygrad/renderer/ptx.py` — 2 sites

| Site | Purpose |
|---|---|
| `ptx_matcher` | Legalizes booleans, half operations, bool memory, comparisons, and shift operands for PTX. |
| `string_rewrite` | Emits PTX constants, instructions, memory, control flow, and WMMA text. |

### `tinygrad/renderer/wgsl.py` — 2 sites

| Site | Purpose |
|---|---|
| `wgsl_matcher` | Emulates packed sub-32-bit memory and legalizes bool, shift, and NaN behavior. |
| `WGSLRenderer.string_rewrite` | Emits WGSL constants, buffers, bitcasts, atomics, memory/index syntax, and shared C-style fragments. |

### `tinygrad/renderer/isa/x86.py` — 5 sites

| Site | Purpose |
|---|---|
| `extra_matcher` | Legalizes booleans, casts, fp16, unsigned/float conversion, packed comparisons, and modulo before selection. |
| `pre_isel_matcher` | Materializes target vector widths, removes representation-only casts/no-ops, and legalizes gated memory. |
| `isel_matcher` | Selects x86 `INS` UOps, folds addresses/loads/immediates, satisfies ABI constraints, and creates virtual registers. |
| `pre_regalloc_matcher` | Rematerializes flag-producing instructions when intervening instructions clobber flags. |
| `post_regalloc_matcher` | Resolves frame indexes, lowers loops, and enforces x86 two-address form after allocation. |

### `tinygrad/runtime/ops_dsp.py` — 2 sites

| Site | Purpose |
|---|---|
| `dsp_pm_late` | Wraps shaped operands for Hexagon inline expressions and initializes register buffers with the vector-zero intrinsic. |
| `dsp_string` | Emits compact int8/uint8 constants for readability. |

The older `dsp_pm` construction site is gone.

## Compile and execution dispatch

### `tinygrad/engine/realize.py` — 6 sites

| Site | Purpose |
|---|---|
| `pm_flatten_linear` | Recursively flattens nested schedule `LINEAR`s. |
| `pm_validate` | Wraps device calls with CPU shadow execution and result validation, then composes linear flattening. |
| `pm_beam` | Copies the requested BEAM width into kernel metadata. |
| `pm_compile` | Replaces a call whose body is `SINK` or `PROGRAM` with a call to the compiled `PROGRAM`; this is the ordinary backend compiler seam. |
| `pm_optimize_local_size` | Benchmarks and selects a local launch size where the runtime supports it. |
| `pm_exec` | Dispatches buffer-view, copy, program, encode/decode, graph, HCQ, and validation calls to runtime implementations. |

### `tinygrad/engine/jit.py` — 2 sites

| Site | Purpose |
|---|---|
| `PatternMatcher([])` — `View captured linear` | No-op visualization snapshot of a captured JIT schedule. |
| `PatternMatcher([])` — `View graphed linear` | No-op visualization snapshot after graphing the captured schedule. |

## The ten empty production sites

Nine empties are named visualization boundaries and one is the missing-renderer
fallback:

| Area | Empty sites |
|---|---:|
| `callify.py` visualization | 2 |
| `codegen/__init__.py` visualization | 3 |
| `engine/jit.py` visualization | 2 |
| `schedule/rangeify.py` visualization | 2 |
| `codegen/__init__.py` renderer fallback | 1 |
| **Total** | **10** |

They are real constructor calls and are necessary to reconcile 130 semantic
sites + 10 empty sites + `__add__` = 141.

## Experimental HCQ2 inventory — 30 sites

`extra/hcq2` is a separate experimental compiler for host command queues. It
does not run in the ordinary Tensor → rangeified kernel → renderer path. Its
matchers show that UOps can also model queue scheduling, packet construction,
link-time patching, and a CPU submit program.

### `extra/hcq2/hcq2.py` — 23 sites

| Site | Purpose |
|---|---|
| `pm_replace_buffers` | Normalizes buffers reachable from calls to params so HCQ compilation can cache a reusable schedule. |
| `pm_insert_copy_staging` | Inserts a CPU staging buffer for copies where the source/destination pair lacks peer-to-peer access. |
| `pm_tag_hcq_calls` | Annotates device calls with device tuple, queue, estimates, name, and order tag. |
| `pm_sched_sync` | Adds resource-dependency edges between calls using the HCQ dependency tracker. |
| `pm_merge_queues` | Groups compatible calls into per-device/per-queue command-buffer submissions while preserving submission order. |
| `pm_add_finalizer` | Appends per-device finalizer submissions that wait on active queues and advance the device timeline. |
| `pm_add_global_sync` | Adds the prior-epoch timeline wait the first time a device tuple is used in a schedule. |
| `pm_add_inner_loads` | Lowers inter-queue dependencies to queue-signal waits inside submissions. |
| `pm_add_inner_stores` | Emits queue progress signals after calls on which another queue waits. |
| `pm_encode_cmdbufs` | Dispatches each submit graph to the selected device class's `pm_lower`. |
| `pm_trim_link_patches` | Removes patches knowable at link time from an `AFTER` tree while preserving their dependencies for the linker. |
| `pm_split_patches` | Splits each HCQ call's link-time patches from runtime patches. |
| `pm_rm_rt_getaddrs` | Replaces runtime `GETADDR`s with compact input/runtime/system address-table loads and records input slots. |
| `pm_rm_rt_binaries` | Moves runtime binary blobs into template placeholder buffers with fill patches. |
| `pm_replace_params` | Builds the compact final HCQ call signature and renumbers scalar variables. |
| `pm_early_simplify` | Resolves `GETADDR(SLICE)` offsets and pushes a slice offset into `INDEX`. |
| `pm_pack_placeholders` | Coalesces repeated scratch/kernarg placeholders into aligned shared allocations plus slices. |
| `pm_callify_hcq` | Compiles a host-command `SINK` into a CPU `PROGRAM` inside the HCQ custom function. |
| module `pm_bufferize` | Replaces tagged placeholder params with device-specific concrete buffers. |
| `pm_resolve_patches` | Pushes stacked patch math, resolves addresses, and eagerly applies binary or constant stores to allocated buffers. |
| `pm_assert_no_afters` | Link invariant: raises if any unresolved `AFTER` remains. |
| `pm_link_cache` | Reuses a cached linked `AFTER` allocation/patch subtree when available. |
| `HCQ2Compiled.__init__.pm_bufferize` | Base device rules for timeline, sentinel, and generic temporary placeholder allocation. |

### `extra/hcq2/ops_amd2.py` — 7 sites

| Site | Purpose |
|---|---|
| `pm_pm4_opsel` | Lowers program calls, waits, barriers, timestamps, and stores to AMD PM4 packet `INS` UOps. |
| `pm_pm4_submit` | Serializes a PM4 command buffer, writes it to the compute ring, advances pointers, and rings the doorbell. |
| `pm_sdma_opsel` | Lowers copies, waits, timestamps, barriers, and stores to SDMA packet `INS` UOps. |
| `pm_sdma_submit` | Serializes SDMA commands, handles ring wrap, advances pointers, and rings the copy-queue doorbell. |
| `AMDDevice.pm_lower` | Builds/relocates an AMD `PROGRAM` binary and chooses PM4 versus SDMA queue encoding. |
| `AMDDevice.__init__.pm_bufferize` addition | Adds scratch-placeholder allocation to the device's bufferizer. |
| `AMDDevice.create_queue.pm_bufferize` addition | Adds queue-instance ring, pointer, doorbell, and timeline placeholder resolution. |

HCQ2 composes these matchers with ordinary symbolic and linear-flattening
matchers. Its effective device rules are therefore both device- and
queue-instance-dependent.

## Test-only inventory — 61 direct sites

These direct constructors exercise the rewrite machinery; they are not hidden
production passes.

| File | Direct sites | Coverage |
|---|---:|---|
| `test/backend/test_pickle.py` | 1 | Matcher serialization and callable reconstruction |
| `test/backend/test_rangeify.py` | 1 | Targeted rangeify rewrite behavior |
| `test/null/test_graph_rewrite.py` | 15 | Fixed points, traversal modes, replacement graphs, caching, and call boundaries |
| `test/null/test_pattern_matcher.py` | 17 | `UPat` constraints, binding, rule order, composition, compilation, and contexts |
| `test/null/test_rewrite_bottom_up_gate.py` | 2 | Bottom-up pruning with `BottomUpGate` |
| `test/null/test_tensor_uop_mixin.py` | 1 | Tensor/UOp mixin interaction |
| `test/null/test_uop_graph.py` | 5 | Graph identity, topology, and rewrite behavior |
| `test/null/test_viz.py` | 19 | Tracking, named rewrite groups, replay, errors, and visualization |
| **Total** | **61** | |

`test/null/test_viz.py` additionally has the six explicit
`TrackedPatternMatcher(...)` calls discussed in the census note. They test
tracking directly rather than through the runtime name rebinding.

## A useful reading order

The source inventory becomes much easier to retain if you follow one graph:

1. `add_tags`, `pm_early_transform_tensor_graph`, `pm_finalize_call`, and
   `pm_replace_buf`;
2. `pm_generate_realize_map`, `pm_apply_rangeify`, and movement cleanup;
3. `earliest_rewrites`, `pm_const_buffer_folding`, `pm_add_buffers`, and
   `split_kernels`;
4. `pm_schedule` and `pm_resolve_linear_call`;
5. the exact `full_rewrite_to_sink` sequence, especially `expander2`,
   `pm_reduce_local`, `unbroadcast`, `pm_add_loads`, and `devectorizer2`;
6. one target's `extra_matcher` and string/definition matcher;
7. `pm_add_control_flow`, the priority topological `linearize` function,
   `pm_linearize_cleanups`, and `pm_to_program`; and
8. `pm_compile` followed by `pm_exec`.

Then run a small graph with rewrite tracking. Most of the 130 semantic source
sites will not fire for one kernel; the trace tells you which ordered subset is
the actual lowering story for that graph.
