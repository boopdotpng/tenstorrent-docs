# Tinygrad rewrite exercises and worked solutions

A **UOp** is a node describing an operation and its inputs. The nodes form an **IR** (intermediate representation) that the compiler can inspect as data. `ADD(x,0) -> x` means replace an addition node with its existing input `x`; it is schematic graph notation, not Python code. A **pattern matcher (PM)** recognizes graph shapes, and a **driver** decides which nodes to visit and whether to revisit replacements. A **guard** is an additional condition required before a replacement is safe. The optional [first-principles primer](../first-principles.md) provides background; the explanations here introduce the local details.

Snapshot: clean master `107adc31701df0247dfa45e175984df906a68b53` (2026-09-17). Companion: [UOps and rewrites](uops-and-rewrites.md). Exercises 1–8 build toward reading a real codegen pass; 9–12 are patch/research assignments. The solutions are explanations, not claims that the open-ended patches have been implemented. CPU-only probes and existing test results are recorded at the end. For a substantial lowering and cross-kernel fusion exercise, use the measured [RMSNorm case study](rmsnorm-kernel-fusion.md); the early exercises here isolate its underlying mechanisms.

## 1. Reconstruct the current node model (15 minutes)

**Interning** reuses the same object for an identical live node construction. Object identity means Python's `is`, which is stronger than two expressions eventually producing equal numbers. A **weak dtype** postpones a machine-width choice; `CAST` makes a conversion/type choice explicit.

**Task.** Predict `op`, dtype, and identity relationships for `UOp.const(1)`, another `UOp.const(1)`, `UOp.const(True)`, and `UOp.const(1, dtypes.int32)`. Explain why changing `x.arg` in place is unsafe. Find the source defining these behaviors.

**Solution.** The first two are the same live interned `CONST` with weak integer dtype. The boolean is a distinct `CONST` with bool dtype; `type(arg)` is part of the interning key precisely because Python dictionary equality otherwise conflates `True` and `1`. The explicitly int32 constant is a `CAST` whose argument states int32, wrapping a constant value. In-place mutation invalidates the assumptions behind the interning cache and cached derived properties and changes all sharing graphs. Use `replace`.

Evidence: [UOp metaclass](../../../tinygrad/tinygrad/uop/ops.py#L192), [const](../../../tinygrad/tinygrad/uop/ops.py#L607). **Acceptance:** assert all four predictions without initializing a device.

## 2. Make a match precise (20 minutes)

**Task.** Match `ADD(x,x)` but reject `ADD(x,y)` when x and y are distinct. Then match addition with zero on either side. Explain the difference between tuple and list sources and why `UPat(Ops.CONST)` can miss a typed literal.

**Solution.** Use `UPat(Ops.ADD, src=(UPat(name='x'), UPat(name='x')))`. Repeated names assert identity, not semantic equivalence. For either zero order, use `src=[UPat(name='x'), UPat.const(0)]`, or `UPat.var('x') + 0`; the latter knows ADD is commutative. A tuple preserves order. To see the wrapper issue, compare `ADD(x, CONST(0))` with `ADD(x, CAST(int32, CONST(0)))`. The second input has root operation CONST in the first graph and CAST in the second. A concrete typed literal may be `CAST(CONST)` at this phase, so a bare CONST pattern misses its outer node. A phase-appropriate `.or_casted()` can accept both spellings.

Evidence: [UPat](../../../tinygrad/tinygrad/uop/ops.py#L1383). **Acceptance:** include distinct same-valued expressions as a negative case unless they intern to the same node. Report graph identity separately from numerical equality.

## 3. Distinguish matcher composition from pass sequencing (20 minutes)

**Task.** Given `A: ADD(x,0) -> MUL(x,1)` and `B: MUL(x,1) -> x`, predict default graph rewriting, a single `pm.rewrite`, and `walk=True`. Explain what happens if two ADD rules both succeed.

**Solution.** Starting at `ADD(x,0)`, A produces `MUL(x,1)`. Default graph rewriting with `A+B` then revisits that replacement, B produces `x`, and neither rule matches `x`. The result is stable: this is a **fixed point**. A single node rewrite returns `MUL(x,1)`. A walk also returns `MUL(x,1)` here, because it does not descend into the new replacement. With two successful ADD rules, the earlier rule's non-identical, non-None result wins. Composition concatenates priorities; separate graph passes establish a phase boundary and may produce a different result.

Evidence: [PatternMatcher.rewrite](../../../tinygrad/tinygrad/uop/ops.py#L1540), [RewriteContext](../../../tinygrad/tinygrad/uop/ops.py#L1699). **Acceptance:** execute the probe below and add a competing ADD rule to demonstrate priority.

## 4. Explain a “missing” rewrite inside a call (15 minutes)

**Task.** A pattern simplifies `x+0` directly but appears to do nothing when that expression is inside a CALL body. Diagnose it before widening the pattern.

**Solution.** `graph_rewrite` defaults to `enter_calls=False`, preserving `CALL.src[0]`. Its arguments can still be rewritten. If this pass truly owns the body's phase and scope, use `enter_calls=True`; otherwise invoke the pass where that body is independently lowered. A parameter substitution intended for outer call arguments must not blindly substitute inner lexical parameters with the same slot numbers. This is the same scope issue as two Python functions each naming their first argument `x`: matching the name or position does not make them the same variable.

Evidence: [driver call-body boundary](../../../tinygrad/tinygrad/uop/ops.py#L1765), [lexical resolution](../../../tinygrad/tinygrad/schedule/__init__.py#L119). **Acceptance:** identify the exact call-site ownership before proposing a code change.

## 5. Preserve invalid lanes (25 minutes)

A **lane** is one element position in grouped computation. `WHERE(c,a,b)` selects `a` when condition `c` is true and `b` otherwise. `Invalid` marks a position that has no valid value; it may tell later stages that a memory access must not occur. A **gate** is the condition controlling that access.

**Task.** Why is `WHERE(c,x,Invalid)*0 -> 0` dangerous? Give the first rewrite tinygrad makes and explain when a renderable zero becomes legal.

**Solution.** The multiplication cannot erase the invalidity of the false branch: that invalidity can still determine whether a memory access exists. `pm_data_invalid` first produces `WHERE(c,x*0,Invalid)`. An inner zero fold still leaves the outside gate. Later lowering transfers required validity to memory gates or reduction identities; only after that can residual invalid sentinels be removed. Invalid is not a normal number and is not IEEE NaN.

Evidence: [source's ordering comment and rules](../../../tinygrad/tinygrad/uop/symbolic.py#L61), [gate lowering](../../../tinygrad/tinygrad/codegen/late/gater.py), [final sequence](../../../tinygrad/tinygrad/codegen/__init__.py#L373). **Acceptance:** assert the first structural rewrite, then explain why that alone does not prove final memory safety.

## 6. Choose the padding identity (20 minutes)

**Task.** A masked reduction adds padded lanes. What values should replace invalid inputs for ADD, MUL, and MAX? Explain why MAX over negative inputs catches a zero-padding bug that an all-positive example misses.

**Solution.** ADD needs zero; MUL needs one; MAX needs the appropriate dtype identity (negative infinity for a supported floating maximum, or the integer dtype's minimum for an integer maximum). For valid values `[-5,-2,-7]` and one padded lane, zero gives `max(-5,-2,-7,0)=0`; negative infinity gives the correct `-2`. For a product of `[2,3]`, padding with one preserves `6`, whereas padding with zero produces `0`. These are arithmetic illustrations; they do not themselves execute masked code generation. Tinygrad computes the identity using `identity_element`; do not hardcode one identity for every dtype or reduction. Tensor-core formation separately gates WMMA multiplicands with zero because their products must contribute zero to addition; current `pm_reduce_identity` itself only handles REDUCE.

Evidence: [pm_reduce_identity](../../../tinygrad/tinygrad/codegen/__init__.py#L223). **Acceptance:** construct positive and negative max examples and an integer case, and state whether your test exercises masked codegen or merely Python arithmetic.

## 7. Explain the four weak-type matchers (30 minutes)

The underlying problem is timing: early index algebra benefits from postponing numeric widths, but emitted machine arithmetic and stored values need definite types. Committing a width propagates a requirement; lowering replaces unresolved operations with concrete ones. Removing and later restoring constant wrappers serves different consumers at those different stages.

**Task.** Why are `pm_commit_weak`, `pm_lower_weak`, `pm_uncast_const`, and `pm_cast_const` separate? Find one real composition that the source explicitly prohibits.

**Solution.** Commitment propagates concrete width requirements while graph reasoning can still use weak types. Lowering settles residual weak computations and conversions. Uncasting removes redundant constant wrappers only when consumer operand/result type derivation stays unchanged; this preserves simple constant patterns. Final constant casting satisfies renderer/program contracts, including boolean constants. `symbolic` must not be composed into the weak-lowering fixed point: its Invalid rules can push casts into gated WHERE and recreate weak nodes that lowering tries to remove. The implementation explicitly documents the cycle.

Schematically, one transformation replaces a weak result with a concrete cast around it; another moves that cast inside a gated selection and exposes a weak result again. If both keep undoing the other's required form, “repeat until stable” never reaches stability. Separate phases stop the two transformations from competing indefinitely. This description explains the cycle, rather than asserting a literal two-node source trace.

Evidence: [weak.py](../../../tinygrad/tinygrad/uop/weak.py#L1), [prohibited composition](../../../tinygrad/tinygrad/codegen/__init__.py#L350), [program spec](../../../tinygrad/tinygrad/uop/spec.py#L189). **Acceptance:** draw the cast/gate movement cycle and explain which phase boundary breaks it. Do not run an intentionally nonterminating full compiler process.

## 8. Trace one elementwise expression through phase contracts (45 minutes)

Use this conceptual path before inspecting a real trace: reshape a six-element input to `(2,3)`, add scalar 1, and store six results. Position `(row,col)` refers to flat input position `3*row+col`; broadcasting supplies 1 at each position; a load reads the input value; addition computes the result; a store writes it. The actual UOp graph also has to encode types and dependencies. **Devectorization** splits grouped element work into scalar pieces; it needs corresponding source lanes to agree.

**Task.** Start with a reshaped input, add a scalar, and store the result. Annotate what each of movement rewriting, broadcast expansion, load insertion, devectorization, weak lowering, and final constant casting must accomplish. Which matcher's prerequisites would fail if you moved devectorization first?

**Solution.** Movement rewriting expresses the view through index coordinates. Broadcast expansion makes source shapes agree. Load insertion distinguishes storage locations from computed values while leaving the store destination addressable. Devectored operations can then index corresponding lanes; the implementation declines if source shapes disagree (except Invalid). Weak lowering settles machine types after algebra/index simplification. Final constant casting states literal operand widths after newly generated decomposition nodes are present. Moving devectorization before broadcast alignment violates its explicit shape precondition and can leave shaped expressions unresolved.

Evidence: [expand_broadcast and do_devectorize](../../../tinygrad/tinygrad/codegen/__init__.py#L90), [pm_add_loads](../../../tinygrad/tinygrad/codegen/__init__.py#L239). **Acceptance:** produce a phase table from an actual VIZ run; keep concrete observed graphs separate from this expected outline. This document does not claim that end-to-end VIZ trace was run.

## 9. Implement a rule with a termination argument (60–90 minutes)

A **decreasing measure** is a quantity that goes down on every accepted rewrite and cannot decrease forever, such as the count of a particular redundant wrapper. It explains why repeated application stops only if interacting rules cannot increase that quantity again. **NaN** is a floating-point “not a number” value; familiar real-number algebra may fail for it.

**Task.** In a disposable branch, add or isolate a small integer rewrite that is missing at the chosen revision. First prove that it is actually missing. Supply a counterexample to an overly broad formulation, phase placement, and a decreasing measure. Avoid submitting an identity already covered by symbolic.py.

**Worked solution strategy.** Search the existing rules and tests, then construct the minimal failing graph. Restrict to a dtype/domain where the identity holds; arithmetic involving overflow, signed division, zero divisors, or floating NaNs needs separate reasoning. A rule that removes a redundant wrapper can use wrapper count as a local measure, but inspect surrounding rules for wrapper recreation. Test numerical equivalence over a small exhaustive domain plus the structural expected form. Run a second rewrite and require stability. Compare compiled and interpreted matching. A correct solution may conclude that the proposed rule already exists or belongs only in a later phase.

**Rubric:** 2 points for existing-rule audit, 2 for domain/counterexample, 2 for phase and termination, 2 for numerical and structural tests, 2 for evidence of a useful real graph. This is a project recipe, not an implemented patch.

## 10. Build a matcher performance experiment (60 minutes)

A shared **DAG** is a directed graph without dependency cycles in which several users can point to the same input node. **Cold time** includes first-use setup; **warm time** measures subsequent reuse. A source-permutation pattern tries alternative orders of children, so a concise pattern can still require many comparisons.

**Task.** Compare compiled and interpreted matching on a shared DAG. Account for first-use compilation, repeated matches, and rules that never reach their callbacks. Explain why fewer Python source lines do not necessarily mean a faster matcher.

**Worked solution strategy.** Use separate processes with `UPAT_COMPILE=0` and the default. Report graph size, sharing, rule candidates, cold time, warm time, and sample variance. Include a high-permutation pattern and a precise-op alternative with the same accepted cases. Root dispatch and child-op early rejection can avoid most deep matching; list-source permutation and nested alternatives can dominate others. The matcher compiler sometimes falls back to interpretation, so confirm which path was used before attributing a speedup. Never infer a whole-model speedup from a microbenchmark alone.

Evidence: [upat compiler](../../../tinygrad/tinygrad/uop/upat.py#L157). **Rubric:** correctness parity and honest cold/warm separation are required; no fixed speedup is expected or reported here.

## 11. Explain a reduction rewrite from an actual trace (90 minutes)

A grouped reduction splits the input among cooperating threads. Each thread first computes a partial answer; another step combines the partial answers. **Local storage** is memory shared within a workgroup (a cooperating group of threads), and a **barrier** coordinates those threads. A producer's graph dependency does not by itself make another thread's write visible. This is why the exercise asks for both the store/read pair and its synchronization.

**Task.** Capture a grouped reduction and annotate `pm_reduce_identity`, `expander`, `pm_reduce_local`, local buffer insertion, and barriers. Identify the store/read pair requiring cross-thread synchronization.

**Worked solution strategy.** Use a supported backend or compile-only renderer and record its configuration. Follow grouped reduction axes into `fix_group_for_reduce`: partial results go through LOCAL storage, then a second reduction reads them. Separate sequential accumulator dependencies from workgroup synchronization. Track the exact `AFTER` links and compare with implicit barrier insertion. Hardware execution is necessary to establish the behavior of an actual device; compiling a graph demonstrates only the emitted structure.

Evidence: [group reduction helper](../../../tinygrad/tinygrad/codegen/__init__.py#L163), [barrier insertion](../../../tinygrad/tinygrad/codegen/__init__.py#L281). **Rubric:** identify producer/consumer, address space, participating lanes, loop scope, and the resulting barrier placement. This trace was not run for this document.

## 12. Maintain this map across a compiler change (45 minutes)

**Task.** Choose two commits and produce a semantic diff, not a renamed-file list: constructor changes, type/shape derivation, one removed abstraction, pass order, and tests covering the change.

**Worked solution.** July documentation's index dtype and explicit-typing descriptions cannot be transplanted into this September snapshot. Current UOps derive dtype, weakint/weakfloat carry unresolved values, concrete constants are CAST/CONST pairs, and weak.py implements the boundary. A good update links the actual introducing changes if history is available; a shallow clone may lack them. State that limitation rather than guessing motivation. Meeting comments can explain intent, but current source and tests establish shipped behavior.

**Rubric:** exact two revisions, source-backed before/after, one runnable migrated example, and a clear distinction between stated intent and inferred rationale.

## Reproducible probe

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
