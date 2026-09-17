# tinygrad: meeting direction versus checked source

This is a reading map for **master `107adc31701df0247dfa45e175984df906a68b53`**, inspected on 2026-09-17, against the local tinycorp meeting archive at `3779da62412b18e14027489990f77c3ce7122834`. The latest dated transcript present is September 15. Both repositories were refreshed from upstream before this revision of the map. The archive contains noisy transcription and editorial summaries; the links below target actual discussion, and the code determines what exists in this snapshot. “Landed” here means visible in that source, not an independently reconstructed merge history.

The recurring direction is to make shapes, storage, execution, and hardware commands legible in one UOp language, with explicit contracts at each boundary. This is not the same as having one undifferentiated graph: different phases still admit different operations and invariants. The strongest June statement is that spec accuracy matters more than deleting lines ([June 8, line 69](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-06-08/meeting-transcript.md:69)).

## The recurring problem in ordinary array terms

Suppose Python asks for `y = (x.T + 1) * 2`. Transposing changes which input element corresponds to each output; it need not copy an array. Adding and multiplying can happen in one loop. But if another consumer also needs `x.T + 1`, the compiler must choose between storing that intermediate once and calculating it twice. Much of this history is about delaying those decisions until the compiler can see the actual loops and consumers.

The vocabulary follows those decisions:

- **UOp:** a node describing a value or action. Reusing this node language across phases makes transformations inspectable.
- **ShapeTracker:** the older structure that tracked how views map logical coordinates to storage. Removing it means moving that responsibility elsewhere, not removing the need to compute addresses.
- **Rangeify:** the process that turns “produce this array” into explicit index ranges and asks which input coordinates each output needs.
- **Realization / materialization / bufferization:** making values exist in storage. A `STAGE` marks a candidate boundary while later analysis can still remove it; a `STORE` explicitly writes a value.
- **CALL and PARAM:** a function-like computation and its input placeholders. A PARAM belongs to a particular call’s scope, just as a Python function’s `x` is distinct from another function’s `x`.
- **Buffer identity and aliasing:** whether two names refer to the same allocation. If they do, updating one can affect the other. An optimization must preserve this behavior as well as numeric values.
- **Invariant / spec:** a condition that a representation must satisfy, and the rules that check it. A phase can require more than merely “this graph describes a sensible computation.”

This makes the philosophy concrete: express more of those decisions in the common graph, then use explicit phase contracts to control which transformations are allowed. The chronology below separates that ambition from what the pinned source already implements.

## A chronology that explains the current abstractions

### [2025-08-18, lines 103–115](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2025-08-18/meeting-transcript.md:103): Rangeify should replace grouper/kernelize/ShapeTracker/lower responsibilities

**Problem being addressed.** Early decisions about realization and recomputation obscure the actual index/loop problem. Move indexes through the graph and represent materialization alongside ranges.

**Checked source.** `get_kernel_graph` calls `run_rangeify`, then simplification, stage-to-store, and kernel splitting. Read [rangeify.py:367](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/rangeify.py:367) and [indexing.py:167](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:167). The 2025 promise of automatic FlashAttention is a goal, not evidence of a general synthesis capability.

### [2025-08-18, lines 682–706](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2025-08-18/meeting-transcript.md:682): strengthen symbolic rules before deleting ShapeTracker

**Problem being addressed.** View merging used to simplify index expressions; removing its data structure does not remove that work.

**Checked source.** `_apply_reshape` explicitly says its symbolic simplification replaces reshape view merging ([indexing.py:152](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:152)). Symbolic PMs are compiler infrastructure, not just constant-folding conveniences.

### [2025-09-15, lines 256 onward](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2025-09-15/meeting-transcript.md:256): explain bufferization and moving indexes through movement ops

**Problem being addressed.** A transpose can become an exchange of index coordinates instead of a separately materialized tensor.

**Checked source.** `apply_movement_op` implements SHRINK, PERMUTE, FLIP, EXPAND, PAD, and RESHAPE as transformations of ranges ([indexing.py:169](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:169)).

### [2026-06-01, line 87](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-06-01/meeting-transcript.md:87): SHRINK becomes offset/size; metadata moves into ParamArg; remove pointer/vector dtype machinery

**Problem being addressed.** A symbolic start with fixed extent is easier to express directly. Address space and storage metadata should not be confused with arithmetic dtype.

**Checked source.** `ParamArg` explicitly owns slot, dtype, size, address space, device, and backing-buffer metadata ([ops.py:23](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:23)); SHRINK indexing adds the offset ([indexing.py:171](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:171)). Old code using begin/end tuples needs careful translation.

### [2026-06-08, line 594](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-06-08/meeting-transcript.md:594): migrate renderers toward a spec-matching graph

**Problem being addressed.** Avoid a separate accidental language of GEP, DEFINE_LOCAL/REG, pointer casts, and vector dtypes.

**Checked source.** The current [Ops enum](/home/boop/tenstorrent/tinygrad/tinygrad/uop/__init__.py:13) contains BUFFER/PARAM, INDEX/SHRINK/STACK; GEP and DEFINE_LOCAL/REG are absent. This does not mean every renderer accepts every legal tensor UOp.

### [2026-07-27, lines 1313–1343](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-07-27/meeting-transcript.md:1313): generalize MULTI as top-down range propagation

**Problem being addressed.** Express device/warp distribution and identify where crossing a reduction requires communication.

**Checked source.** Current UNSHARD carries explicit sharding ranges ([ops.py:670](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:670)). The proposed complete generalization to arbitrary warps is not established by that fact.

### [2026-08-17, lines 554–584](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-17/meeting-transcript.md:554): clean-slate Rangeify, safe STAGE insertion, variables like buffers

**Problem being addressed.** Separate initially safe materialization from later choices to merge/split or duplicate compute; stop scattering special cases.

**Checked source.** STAGE and stage-removal PMs exist. But `schedule/indexing.py` still exists and supplies `run_rangeify`; the statement that Rangeify 2 deletes indexing must not be presented as completed.

### [2026-08-24, lines 206–209](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-24/meeting-transcript.md:206): parallel compilation shares BEAM infrastructure

**Problem being addressed.** Lower/compile independent kernels in child processes.

**Checked source.** Shared process pool exists in [worker.py:5](/home/boop/tenstorrent/tinygrad/tinygrad/engine/worker.py:5); [realize.py:252](/home/boop/tenstorrent/tinygrad/tinygrad/engine/realize.py:252) uses it. A hypothetical `enter_calls=subprocess` was discussion; `graph_rewrite` still exposes a boolean `enter_calls`.

### [2026-08-30, lines 536–562](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-30/meeting-transcript.md:536): PARAM for outer-scope values, BUFFER local to CALL; replace UNSHARD with END

**Problem being addressed.** Make lexical scope and ranges explain graph semantics rather than inventing more special operations.

**Checked source.** PARAM/CALL scoping is real, and RETURNED is absent from the enum. **UNSHARD remains present**, with shape and range semantics ([ops.py:422](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:422)). Spec proposals and current implementation differ.

### [2026-08-30, lines 585–588](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-30/meeting-transcript.md:585): dtype no longer a stored UOp field

**Problem being addressed.** Avoid redundant dtype information that every rewrite must keep consistent.

**Checked source.** Landed: `UOp` stores op/src/arg/tag and derives dtype via `dtype_from_uop` ([ops.py:230](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:230)). Types still exist; PARAM and custom/instruction args retain explicit type information where required.

### [2026-09-07, lines 99–119](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-07/meeting-transcript.md:99): INS should become CALL; share decompositions such as SIN

**Problem being addressed.** Reuse a common function body instead of inserting a large decomposition repeatedly; keep instruction selection late.

**Checked source.** A direction, not a completed removal: `Ops.INS` remains and has an explicit spec rule ([spec.py:109](/home/boop/tenstorrent/tinygrad/tinygrad/uop/spec.py:109)).

### [2026-09-07, lines 157–210](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-07/meeting-transcript.md:157): CALLify and buffer identity take priority over new Rangeify

**Problem being addressed.** Bound storage, unbound storage, and temporaries have different ownership and optimization rights; accidental globalization creates copies.

**Checked source.** `transform_to_call` explicitly handles allocation, tags, and unbound call results ([tensor.py:197](/home/boop/tenstorrent/tinygrad/tinygrad/tensor.py:197)). This establishes the machinery, not proof that all aliasing hazards discussed in that meeting are solved.

### [2026-09-15, lines 386–428](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-15/meeting-transcript.md:386): CONTIGUOUS removed; propose much later kernel fusion over STORE/CALL/RANGE

**Problem being addressed.** Safe early buffer insertion should remain reversible, instead of forcing CALLify/prepare to avoid copies before enough facts are available.

**Checked source.** CONTIGUOUS is absent from the enum (CONTIGUOUS_BACKWARD remains). General late fusion is explicitly a goal: the speaker says current fusion works while nodes are STAGEs. The current stage-to-store then kernel-split sequence remains in [rangeify.py:382](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/rangeify.py:382).

### [2026-09-15, lines 582–610](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-15/meeting-transcript.md:582): INS-as-CALL draft and a `.body` accessor

**Problem being addressed.** Make instruction semantics recoverable by substituting CALL bodies, and make source roles explicit.

**Checked source.** `INS` and `WMMA` remain separate operations. The small `.body` accessor **has landed**: it checks for CALL and returns `src[0]` ([ops.py:544](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:544)). The accessor is not evidence that the instruction representation migration is complete.

## September 15: fusion between kernels, and why RMSNorm is a useful test

This meeting distinguishes combining operations inside one kernel from combining already formed kernels. A kernel is one executable unit launched by the runtime; separate launches commonly communicate by storing arrays. At [lines 400–409](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-15/meeting-transcript.md:400), the proposed transformation takes consecutive CALLs with ranges, inspects their bodies, and combines compatible ranges. A temporary buffer between a producer STORE and consumer LOAD could then shrink if the accesses line up and both calls execute serially in the same loop. The speaker explicitly says current fusion is limited to the STAGE representation and wants that limitation removed.

**Source-level conclusion:** this is a concrete design direction, not evidence that master has a general pass fusing arbitrary compiled kernels. The current `get_kernel_graph` still does stage cleanup, STAGE-to-STORE conversion, and kernel splitting in that order. Also distinguish inlining a high-level value CALL before scheduling from merging two completed kernel CALLs afterward; `resolve_function` already resolves some unbound-output functions, but skips precompiled ones ([prepare.py:99](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/prepare.py:99)).

`extra/gemm/amd_call_matmul.py` is a useful worked example of scoped ranges and storage, with a naming trap. Its `@call` decorator directly evaluates the Python function and adds ENDs; it does **not** itself construct an Ops.CALL ([lines 5–15](/home/boop/tenstorrent/tinygrad/extra/gemm/amd_call_matmul.py:5)). The meeting distinguishes the committed example from another version that creates actual CALL ops ([line 416](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-15/meeting-transcript.md:416)). Use the example to learn the intended scope syntax, not to claim that late CALL fusion is demonstrated.

RMSNorm makes the constraint visible. For each row, `r = rsqrt(mean(x*x) + eps)` depends on a complete reduction; `y = x*r*w` then broadcasts that result. The ordinary implementation in [nn.RMSNorm](/home/boop/tenstorrent/tinygrad/tinygrad/nn/__init__.py:281) normalizes in float, casts back, and applies its learned per-position weight. “Affine weight” here is that multiplier. Moving that cast across multiplication is not automatically numerically equivalent. A subsequent quantizer converts values to a smaller representation and often calculates a shared scale for each group. That introduces another reduction/grouping and more output buffers. The relevant question is where storage, synchronization, rounding, and reuse permit boundaries to disappear—not merely whether the expression contains several arithmetic operations.

The repository has multiple deliberately different RMSNorm paths:

| Path | Observable source boundary | What it does and does not prove |
|---|---|---|
| [Generic RMSNorm](/home/boop/tenstorrent/tinygrad/tinygrad/nn/__init__.py:300) | Tensor reduction followed by normalization, cast, and optional affine multiplication | Suitable for inspecting the scheduler's choices. Source alone does not establish a universal kernel count across shapes, devices, or optimization settings. |
| [GPT-OSS rmsnorm_mul](/home/boop/tenstorrent/tinygrad/extra/gptoss_kernels/rmsnorm/__init__.py:12) | Tensor forward graph returns both normalized output and `rrms`; wrapper uses `call_with_outputs` | Multiple outputs expose reuse required by backward. Weight multiplication here is before the final cast, unlike the generic class; do not compare them as bitwise-identical algebra without accounting for this. |
| [Custom RMSNorm + weight + MXFP8 quantization](/home/boop/tenstorrent/tinygrad/extra/gptoss_kernels/rmsnorm/__init__.py:106) | Explicit `Tensor.custom_kernel` returns `q`, exponent bytes, and `rrms`; its factory supplies a HIP-compiled PROGRAM ([line 60](/home/boop/tenstorrent/tinygrad/extra/gptoss_kernels/rmsnorm/__init__.py:60)) | A manually fused implementation avoids a BF16 normalized round trip. It is **not** evidence that a generic optimizer fused separate RMSNorm and quantizer kernel CALLs. |
| [Custom RMSNorm backward](/home/boop/tenstorrent/tinygrad/extra/gptoss_kernels/rmsnorm/__init__.py:21) | Custom kernel computes input gradients and partial weight gradients; Tensor `sum(0)` combines the partials afterward | A useful concrete kernel-to-reduction boundary. It asks whether a different execution scheme can eliminate or change intermediate storage while preserving the cross-row reduction; arbitrary elementwise substitution cannot answer that. |

The September meeting does not specifically promise that these RMSNorm paths will be fused by the new design. Their connection to the proposed late-fusion work is this map's inference from the source. A workgroup is a set of GPU threads that can share local storage and synchronize. A single-workgroup row normalization can potentially keep its statistic locally available; a reduction spread across independently scheduled workgroups needs an appropriate synchronization/execution strategy. Matching STORE/LOAD indices is useful evidence for a candidate transformation, not a complete dependence, aliasing, synchronization, or profitability proof.

## Why this produces so many pattern matchers

The useful question for each PM is: **what invariant does the next phase require that the previous phase does not guarantee?** The meetings explain why these invariants emerged; the call sites show their current order.

1. **Movement/index simplification replaces a removed abstraction.** ShapeTracker previously bundled indexing and simplification. Now `_apply_reshape` generates flatten/unflatten arithmetic and invokes `symbolic + pm_simplify_valid + pm_drop_and_clauses`. Cancelling redundant integer division/remainder calculations (`//` and `%`), and proving when an index is valid, are what keep a harmless reshape from becoming expensive index arithmetic. The source makes this replacement explicit ([indexing.py:164](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:164)).
2. **Safe staging and stage removal solve different problems.** `pm_const_buffer_folding` and `pm_remove_bufferize` remove needless staging once index/reduction relationships are available; `pm_add_buffers` then turns remaining staging into stores. A STAGE is not proof of an unavoidable allocation. Follow the composition and order in [rangeify.py:372](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/rangeify.py:372). This is consistent with the August explanation of initially preserving compute sharing, then removing stages that prove unnecessary.
3. **Kernel extraction requires a calling contract (ABI).** Each kernel needs explicit arguments so its caller can supply the right buffers. `split_kernels` creates calls after stores exist; `pm_no_indexing_calls` and `pm_no_views` clean the resulting argument graph. These PMs are not algebraic identities applied everywhere: they establish the representation required by the next layer ([rangeify.py:382](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/rangeify.py:382)).
4. **Validation also uses patterns.** `spec_tensor`, `spec_program`, and `spec_kernel_graph` describe legal graphs for different phases ([spec.py:132](/home/boop/tenstorrent/tinygrad/tinygrad/uop/spec.py:132)). A matcher's callback can be a predicate rather than a replacement UOp. Do not infer “optimization” just from the use of `PatternMatcher`.
5. **CALLify must preserve storage and effects while translating values.** Tags, replacement maps, AFTER dependencies, and unbound-buffer handling keep Python-visible tensors tied to the intended storage across graph transformation. Read [tensor.py:137](/home/boop/tenstorrent/tinygrad/tinygrad/tensor.py:137) through `transform_to_call`. This is where a superficially redundant node can carry identity or ordering.
6. **More graph coverage costs compile time.** BEAM searches candidate kernel implementations; repeated compiler work during that search can become expensive. The August 17 discussion reports symbolic/indexing/value-analysis rewrites consuming BEAM time ([line 683](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-17/meeting-transcript.md:683)); August 30 attributes HCQ2 overhead partly to emitting many patch/packet UOps ([line 74](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-30/meeting-transcript.md:74)). Those are reports about those workloads, not a universal performance measurement. Inspect both time per match and graph growth when assessing a PM.

There is also a different proposal in the older archive: expressing a rewrite as UPat-to-UPat rather than arbitrary Python callbacks, motivated by e-graphs ([2025-07-14, line 534](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2025-07-14/meeting-transcript.md:534)). Current `PatternMatcher` still stores callable callbacks and selects the first applicable replacement in order ([ops.py:1522](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:1522)). An equality-saturation system keeps multiple equivalent expressions available before selecting an implementation. This matcher instead chooses ordered replacements, so changing rule order can change the result.

## Sharp edges for reading old notes or designing exercises

- **“dtype removed” means redundant storage removed.** `u.dtype` is still meaningful. `dtype_from_uop` gives PARAM, CONST, CALL, CUSTOM, INS, arithmetic, and comparisons their production rules. Code that constructs `UOp(op, dtype, src, arg)` from an old article is for an older API.
- **Names outlive operations in comments.** The source still mentions RETURNED placeholders in comments, while the enum no longer has RETURNED. Similarly, “bufferize” remains in helper names although STAGE is the operation. Search the enum and constructors, not only English comments.
- **contiguous is not clone.** September's discussion distinguishes layout requirements from identity. Currently [ElementwiseMixin.contiguous](/home/boop/tenstorrent/tinygrad/tinygrad/mixin/elementwise.py:59) can return the input or emit a same-device COPY; [UOp.clone](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:847) creates empty-like storage and returns an AFTER of a STORE into it. Do not expect two contiguous calls to guarantee independent buffers.
- **A legal graph can still be wrong for a particular phase.** `graph_rewrite` normally treats CALL bodies specially; `enter_calls` changes that traversal ([ops.py:1767](/home/boop/tenstorrent/tinygrad/tinygrad/uop/ops.py:1767)). A global substitution crossing PARAM scopes can change meaning.
- **A pad mask is semantic.** June discusses changing PAD and localizing fill behavior ([June 15, line 891](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-06-15/meeting-transcript.md:891)). Current indexing still explicitly constructs validity for PAD ([indexing.py:175](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:175)). Do not infer that the entire proposed invalid-padding model has landed, or discard a mask because an address expression simplified.
- **Kernel count alone is a poor grading metric.** June's stated aim is to match hand-written performance at progressively higher abstraction levels, first UOps then Tensor, fixing fusion shortcomings along the way ([June 1, line 405](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-06-01/meeting-transcript.md:405)). Fewer kernels can increase recomputation, the amount of fast register storage needed at once (“register pressure”), or expensive indexing.
- **Passing tests is not the entire storage contract.** September explicitly calls out unresolved assignment/gradient/hazard semantics ([September 7, line 244](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-09-07/meeting-transcript.md:244)). This does not prove the pinned master retains a particular bug; it tells you what counterexamples to construct rather than assume away.

## CAIR exercise bank with worked reasoning

These are source-reading and paper exercises; no runtime benchmark or hardware validation is claimed here. Use VIZ for a later implementation lab, following the checked-in [VIZ guide](/home/boop/tenstorrent/tinygrad/tinygrad/viz/README.md:1).

### 1. Recover the old ShapeTracker job from a transpose

**Prompt.** An input has shape `(2, 3)`. A transpose produces shape `(3, 2)`. Given output coordinates `(i, j)`, derive input coordinates and the flat row-major address. Identify the current function implementing this translation.

**Worked answer.** Input coordinates are `(j, i)`, so the flat address is `3*j + i`. `apply_movement_op` handles PERMUTE using the inverse permutation (`argsort(arg)`); this distinction matters beyond a self-inverse two-axis transpose. No copied tensor is implied by this calculation. Whether storage is materialized is a separate scheduling/identity decision. Source: [indexing.py:172](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/indexing.py:172).

**Extension.** Compose reshape-to-`(6,)` with reshape-back-to-`(2,3)` and show that for `0 <= i < 2`, `0 <= j < 3`, `(3*i+j)//3 == i` and `(3*i+j)%3 == j`. The bounds are part of the proof. This explains why symbolic rules and range/value analysis inherit the old view-merging responsibility.

### 2. Decide whether a meeting claim is implementation evidence

**Prompt.** Classify: “dtype was removed,” “UNSHARD became END,” “INS is CALL,” and “indexing.py was deleted.” Require a source witness for each answer.

**Worked answer.** Stored dtype removal is visible in the UOp fields and derived property. The other three cannot be stated as completed in this snapshot: the enum contains UNSHARD and INS, and the scheduler imports/uses indexing. The exercise is about identifying a spec proposal, not declaring the proposal incorrect.

### 3. Explain two PMs that seem to undo each other

**Prompt.** Why insert a STAGE and later run `pm_remove_bufferize`? Why not just avoid inserting it?

**Worked answer.** Before ranges have propagated, separate consumers may or may not need equivalent computations. A safe staging decision preserves sharing. Once indexing and simplification expose the actual accesses, the compiler can prove that some storage is unnecessary. Removing it early without those facts can duplicate expensive work or lose a necessary boundary. The August 17 ReLU/COMPARE/WHERE example illustrates this reasoning ([line 575](/home/boop/tenstorrent/tinycorp-meetings/last-week-in-tinycorp/2026-08-17/meeting-transcript.md:575)); the current removal implementation remains the authority on which cases are actually supported ([rangeify.py:131](/home/boop/tenstorrent/tinygrad/tinygrad/schedule/rangeify.py:131)).

### 4. Identify the storage promise

**Prompt.** Compare `b = a.contiguous(); c = a.contiguous()` with `b = a.clone(); c = a.clone()`. Which pair establishes distinct destinations in the current construction?

**Worked answer.** Clone creates a new empty-like destination on each call, stores into it, and attaches AFTER ordering. Contiguous can reuse the same object or produce an equivalent layout request; it does not promise two new independent destinations. A useful follow-up test would modify one result and check the other, while also inspecting the graph so optimizer behavior is not mistaken for the API contract. Read both implementation links in the sharp-edge note above.

### 5. Distinguish matching, rewriting, and scope

**Prompt.** Does adding two PMs make a commutative set of equations? Will a default `graph_rewrite` rewrite everything inside a CALL body?

**Worked answer.** No to both. `__add__` concatenates ordered pattern lists, and `rewrite` selects the first replacement that is neither `None` nor the original node. Graph traversal has explicit handling of CALL bodies and an `enter_calls` option. A safe exercise adds two competing rules in a disposable script, reverses their order, and observes the result; a separate exercise uses a PARAM inside a CALL to show why blindly crossing scopes is unsafe.

### 6. Design a performance investigation without overclaiming

**Prompt.** A change reduces kernel count but compilation becomes slower. What evidence would distinguish the likely causes discussed in the meetings?

**Worked answer.** Inspect named VIZ rewrite passes; compare graph size before/after; record rule match counts/time; separate lowering, compilation, runtime command construction, and execution. Repeated symbolic matching suggests an indexing/analysis issue; exploding command-patch graphs suggest a different layer. Then test runtime separately for recomputation and register-pressure regressions. The August reports motivate these hypotheses but are not measurements of your workload. A good solution reports both correctness and costs, with pinned revision and identical inputs.


### 7. Explain an RMSNorm kernel boundary before proposing fusion

**Prompt.** Start with three conceptual kernels: A computes row statistics; B normalizes and applies weights; C quantizes the result. Then compare the custom backward path, which writes partial weight gradients and reduces them later. Which boundaries are candidates for removal, and what evidence is missing?

**Worked answer.** A→B requires each normalized element to observe the completed statistic for its row. B→C must preserve the quantizer's grouping, scaling, and intended rounding; dropping a materialized BF16 intermediate can change numerical behavior, so the intended formula matters. A and B might share one cooperative group and local statistic, while a different row decomposition may need another synchronization strategy. The backward partial-gradient→sum boundary combines contributions across rows/workgroups: keeping only one group's partial is wrong. For each candidate, write down the producer/consumer index relation, all consumers, mutation/alias constraints, required barriers, output rounding, and storage lifetime; then inspect a real lowered graph and measure register pressure and runtime. The manually fused custom forward proves an implementation exists for its ABI, not that generic late fusion currently discovers it. No measured kernel count or performance is claimed by this paper exercise.

## Recommended reading sequence

Read the 2025-08-18 Rangeify explanation, then `apply_movement_op` and `_apply_reshape`; read the 2026-08-17 STAGE discussion, then `get_kernel_graph` and its PM composition; read the 2026-09-07 buffer-identity discussion, then `contiguous`, `clone`, and `transform_to_call`. Then read the September 15 late-fusion discussion and compare generic RMSNorm with the custom quantized and backward paths. Finish with `PatternMatcher`, CALL traversal, and the phase-specific spec PMs. This order connects each abstraction to the problem it is trying to solve without treating a meeting roadmap as the current API.
