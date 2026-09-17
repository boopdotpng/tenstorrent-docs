# Frontend, differentiation, and UOp tooling: every matcher rule

Source snapshot: `107adc31701df0247dfa45e175984df906a68b53`. This chapter covers every active rule tuple in `tensor.py`, `function.py`, `mixin/gradient.py`, and `uop/{ops,render,upat}.py`. A group-valued pattern is one rule template; its operation-specific behavior is spelled out where useful. Empty visualization matchers have no rules. Shared matchers composed with `+` retain the rules documented at their definitions.

Examples below are **schematic, source-reviewed, not executed**. `g` means the incoming cotangent; `None` means no gradient edge or, for ordinary rewrites, decline this rule and try the next. Those are distinct uses. “Why (inferred)” describes the present implementation's purpose, not a claim about the author's historical motivation. “Why (explicit)” is supported by a source comment. Source links point at the checked-out snapshot.

These are not GPU instruction selectors. The frontend rules establish storage and call scope, gradient rules construct a backward graph, and render rules return strings. Understanding them prevents mistaking a textual renderer or storage rewrite for kernel fusion.

## Read this chapter as four different uses of graph matching

Start with the [first-principles guide](../../first-principles.md) if UOps,
materialization, or compiler stages are new. A UOp's `src` tuple holds its inputs;
its `arg` holds metadata. These rules use the same matching mechanism but have
different outputs:

- Tensor/function rules make storage and function inputs explicit. A Python
  Tensor may initially represent a calculation such as `x+y`; **materializing**
  it means allocating a buffer and writing the calculated values there.
- Gradient rules build another graph that computes sensitivities of a loss to
  inputs. Their output tuple has one position per input of the forward node.
- UOp analysis rules substitute nodes or inspect storage views. Some produce an
  analysis result that must never be treated as replacement executable code.
- Pattern and graph renderers produce Python predicates or diagnostic strings.
  Printing `a*b+c` is not evidence that a device fused a multiply and an add.

Storage identity matters throughout the first group. Two arrays can have the
same shape and values yet own different memory; two different views can share
one allocation. `AFTER(value, effect)` means “use this value after the effect has
happened.” `AFTER(b, STORE(b,x))` therefore represents b's new contents after
writing x. A **tag** keeps track of which original Tensor needs that storage
while the graph is being replaced. This ownership bookkeeping is separate from
Python's ownership of the UOp object.

A `PARAM(slot=k)` is a placeholder for function argument k. A `CALL` contains a
body and arguments. Each body's parameter slots belong to that body, like local
parameter names in nested Python functions. An **unbound** output buffer is a
storage declaration awaiting an allocation, not an input with an unknown
numerical value. Canonicalizing its slot means choosing a repeatable identifier
so equivalent graphs can share a cache entry.

In the entry descriptions, `ctx` is the context object supplied by the current
rewrite pass: it may hold captured arguments, known views, or rendered strings.
It is not a tensor input. **Arity** means the number of sources. **Identity**
means the exact graph node or underlying allocation, rather than equal numerical
values. A matcher that **declines** has made no replacement; later rules may
still handle the node. “Bottom-up” traversal visits a node's inputs before the
node itself. **Interning** means reusing one node object for identical immutable
node descriptions, which can make identity-based graph sharing possible.

### tensor.py:L45 — add_tags: creation-device COPY

[Source](../../../../tinygrad/tinygrad/tensor.py#L45). **Match/result:** Any COPY; tag it with its original UOp only if its source device starts with DISK, NPY, or PYTHON. Already tagged nodes decline.

**Example:** `COPY(NPY_buffer → CPU)` acquires `(original_copy,)`, allowing its eventual storage to update the held Tensor.

The tag is a link back to the original request: after rewriting the copy, the frontend still knows which held Tensor should refer to its resulting buffer.

**Why (explicit):** Copies from creation devices must become real buffers; the comment explicitly names disk/numpy.

**Sharp edge:** The predicate also includes PYTHON. Ordinary device-to-device copies do not match this callback guard.

### tensor.py:L48 — add_tags: merge full-store COPY identity

[Source](../../../../tinygrad/tinygrad/tensor.py#L48). **Match/result:** AFTER(dest, STORE(dest, COPY(...))) with both AFTER and COPY carrying nonempty tags: merge the COPY tag into AFTER and replace the inner tag with `()`.

**Example:** `AFTER[d_tag](b, STORE(b, COPY[c_tag](numpy)))` becomes one owner tagged `(d_tag,c_tag)`; COPY has an empty tag.

There is already a place to put the copied data: dest. Moving the tag to the outer AFTER lets both original identities refer to that one completed destination, instead of requiring an extra copy buffer.

**Why (explicit):** The full destination already supplies the COPY storage; avoid a second allocation.

**Sharp edge:** Repeated `dest` requires identity, not equal shapes. Partial stores deliberately retain independent COPY storage. Empty tags mean handled, not untagged.

### tensor.py:L51 — add_tags: AFTER identity

[Source](../../../../tinygrad/tinygrad/tensor.py#L51). **Match/result:** Any AFTER without a tag receives `(original_after,)`.

**Example:** `b.after(store)` gets a tag that survives bufferization and maps the user-held result back to storage.

**Why (inferred):** Keep the identity of stateful values while their implementation graph changes.

**Sharp edge:** Existing tags are preserved; blindly replacing them would lose earlier aliases.

### tensor.py:L52 — add_tags: requested storage bases

[Source](../../../../tinygrad/tinygrad/tensor.py#L52). **Match/result:** Any operation in `ctx.bases` is tagged if not already tagged.

**Example:** A held computed base `x+y` selected for realization gets tagged even though it is not an AFTER.

**Why (inferred):** The realization request identifies which computed values need persistent storage.

**Sharp edge:** It does not tag every intermediate; doing that would force unnecessary materialization.

### tensor.py:L139 — early transform: precompiled CALL outputs

[Source](../../../../tinygrad/tinygrad/tensor.py#L139). **Match/result:** CALL with `arg.precompile` and unbound outputs: replace returned placeholders by real output buffers, place values into target PARAMs, and return a SINK of stores to the placeholders.

**Example:** `CALL(f, RETURNED, x)` becomes an opaque call with real `out`; the old placeholder is associated with `out.after(new_call)`.

Think of changing a Python-style `out = f(x)` into a lower-level `f(out_buffer, x)`. The call now writes through an explicit output argument; the following AFTER records when that output becomes usable. ABI means this agreement about how a caller supplies inputs and outputs.

**Why (explicit):** Transform value-producing precompiled calls into opaque calls with explicit output storage.

**Sharp edge:** Requires a SINK body of output stores. Shared outputs are placed once; symbolic output shapes shrink maximum allocations. This is an ABI/storage conversion, not inlining.

### tensor.py:L142 — early transform: returned AFTER extraction

[Source](../../../../tinygrad/tinygrad/tensor.py#L142). **Match/result:** AFTER(r, SINK(stores), ...) resolves to the unique stored value whose target shares r’s unbound base.

**Example:** `RETURNED.after(SINK(STORE(RETURNED, out.after(call)))) → out.after(call)`.

**Why (explicit):** Recover the value yielded by the precompiled-call conversion.

**Sharp edge:** Declines for bound storage, zero matching stores, or multiple matches. Matching is by unsharded base identity.

### tensor.py:L145 — early transform: contiguous COPY view

[Source](../../../../tinygrad/tinygrad/tensor.py#L145). **Match/result:** COPY of movement/BITCAST: `contiguous_mops_to_view` requires a buffer/unshard base, concrete shape, and a provably contiguous view; replace self-copy by a buffer slice/view, or preserve cross-device COPY around that view.

**Example:** `COPY_self(RESHAPE(SHRINK(b, [8:16]), (2,4))) → b[8:16].reshape(2,4)`.

A contiguous slice occupies consecutive bytes, so its address and length can describe it. A transpose usually changes the order in which bytes are visited; merely pointing at a subrange would not reproduce that order.

**Why (explicit):** A contiguous subrange can alias existing storage instead of being materialized.

**Sharp edge:** Noncontiguous transposes and symbolic shapes decline. Multi-device cases must resolve per-shard movement first; the constructed view is recorded in ctx.views.

### tensor.py:L146 — early transform: bitcast STORE target view

[Source](../../../../tinygrad/tinygrad/tensor.py#L146). **Match/result:** STORE whose target is BITCAST uses the same contiguous-view callback, replacing the destination with a canonical buffer view while retaining the other STORE sources.

**Example:** `STORE(BITCAST_u8(b_u32), bytes)` targets the equivalent byte slice of b.

**Why (inferred):** Expose contiguous target storage and byte offsets without a compute kernel.

**Sharp edge:** The callback requires a concrete shape and a valid contiguous buffer view; interpreting the dtype conversion as numeric CAST would be wrong.

### tensor.py:L149 — early transform: remove disk self-copy before transfer

[Source](../../../../tinygrad/tinygrad/tensor.py#L149). **Match/result:** Movement except SHRINK/RESHAPE, then a self-COPY, then COPY: if the movement lives on DISK, drop the intermediate self-COPY and clear the outer tag.

**Example:** `COPY_CPU(COPY_self(PERMUTE(disk))) → COPY_CPU(PERMUTE(disk))`.

A self-copy is a request for distinct/contiguous storage on the same device. Here an imminent disk-to-compute-device transfer already creates destination storage, so retaining the intermediate disk materialization would add an unnecessary step.

**Why (explicit):** Remove contiguous on movement operations before a disk copy.

**Sharp edge:** The inner COPY must be a self-copy. This rule feeds the next rule; alone it does not make arbitrary disk movement executable.

### tensor.py:L152 — early transform: transfer before disk movement

[Source](../../../../tinygrad/tinygrad/tensor.py#L152). **Match/result:** COPY of a DISK movement except SHRINK/RESHAPE: move the COPY below that movement, clear its tag, preserve movement parameters.

**Example:** `COPY_CPU(PERMUTE(disk)) → PERMUTE(COPY_CPU(disk))`.

**Why (explicit):** Push the transfer past movement so the movement is handled after reading disk data.

**Sharp edge:** It can read the underlying buffer rather than only a transformed selection; SHRINK/RESHAPE are intentionally excluded.

### tensor.py:L156 — early transform: erase autograd-only markers

[Source](../../../../tinygrad/tinygrad/tensor.py#L156). **Match/result:** DETACH or CONTIGUOUS_BACKWARD becomes its source; if the wrapper has tags, merge them with source tags.

**Example:** `DETACH[tag_d](x[tag_x]) → x[tag_x+tag_d]`.

**Why (explicit):** These markers matter during differentiation, but must be stripped before storage minting.

**Sharp edge:** Erasing DETACH before differentiation would incorrectly allow gradients through it. Phase ordering is essential.

### tensor.py:L159 — early transform: already materialized contiguous

[Source](../../../../tinygrad/tinygrad/tensor.py#L159). **Match/result:** Self-COPY of AFTER whose first source has buffer identity becomes that AFTER, combining tags.

**Example:** `contiguous(b.after(STORE(b,x))) → b.after(STORE(b,x))`.

**Why (explicit):** Contiguous of already materialized storage is a no-op.

**Sharp edge:** Cross-device copies and AFTER values without buffer identity must remain.

### tensor.py:L162 — early transform: mint tagged storage

[Source](../../../../tinygrad/tinygrad/tensor.py#L162). **Match/result:** Any op except AFTER/STORE: untagged declines; empty tag is stripped; nonempty tag normally becomes `buf.after(buf.store(value))` with that tag. Self-copy stores its source.

**Example:** `tagged(x+y) → b.after(STORE(b,x+y))`; a tagged self-copy avoids copying the COPY node itself.

Read the replacement in two steps: allocate b, then write the expression into b. The AFTER returns b while keeping the write as a required dependency. This is how a value expression gains persistent storage.

**Why (explicit):** Tags encode which held values need actual buffers; the mint resolves that obligation.

**Sharp edge:** Virtual values/DISK retain an annotation without a real allocation; zero-size shapes also skip allocation. An untagged contiguous is left for the scheduler.

### tensor.py:L166 — drop_after: storage projection

[Source](../../../../tinygrad/tinygrad/tensor.py#L166). **Match/result:** Any AFTER becomes its first source.

**Example:** `AFTER(b, STORE(b,x)) → b` when extracting storage.

**Why (explicit):** A store’s storage retains views but drops sequencing nodes.

**Sharp edge:** This is valid only in the storage-projection use site; applying it to an execution graph would discard dependencies.

### tensor.py:L183 — canonicalize_unbound: CALL body recursion

[Source](../../../../tinygrad/tinygrad/tensor.py#L183). **Match/result:** CALL body is rewritten bottom-up with the same canonicalizer; replace the CALL only if its body changes.

**Example:** `CALL(body_with_RETURNED_slot_812, args) → CALL(body_with_RETURNED_slot_-1, args)`.

**Why (inferred):** Canonicalize placeholders inside lexical call bodies for stable cache keys.

**Sharp edge:** Only the body is explicitly replaced by this callback; it is not argument substitution or call evaluation.

### tensor.py:L184 — canonicalize_unbound: local negative IDs

[Source](../../../../tinygrad/tinygrad/tensor.py#L184). **Match/result:** Source-free unbound BUFFER with nonnegative slot gets a context-stable negative slot `-1-len(ctx.unbound)`.

**Example:** `RETURNED(slot=812), RETURNED(slot=913) → slots -1,-2` in one context.

The slot is part of the graph identity used as a cache key. If two otherwise identical calls use freshly numbered output slots 812 and 913, their raw keys differ. Renumbering by local encounter order removes that accidental difference.

**Why (explicit):** Fresh global slots must not make structurally identical calls miss the schedule cache.

**Sharp edge:** Already-negative slots are already canonical. Bound BUFFER identity must not be canonicalized this way.

### tensor.py:L189 — replace_buf: global input PARAM

[Source](../../../../tinygrad/tinygrad/tensor.py#L189). **Match/result:** Source-free global-address-space BUFFER that is not unbound is appended to ctx.replacements and replaced by its corresponding PARAM.

**Example:** `BUFFER(CPU,slot=99) → PARAM(slot=0)` plus external argument 0 retaining the buffer.

**Why (explicit):** Normalize buffer identity out of the schedule cache key.

**Sharp edge:** ALU-address-space Variables and unbound outputs remain; this does not turn every BUFFER into an input.

### tensor.py:L192 — replace_buf: captured contiguous views

[Source](../../../../tinygrad/tinygrad/tensor.py#L192). **Match/result:** SHRINK/BITCAST explicitly recorded in ctx.views becomes an input PARAM through the same replacement list.

**Example:** `b[8:16] → PARAM(1)` with that view captured as argument 1.

**Why (explicit):** Cache the canonical contiguous view as input storage, including its offset.

**Sharp edge:** Arbitrary SHRINK/BITCAST nodes are not captured; membership in ctx.views is the guard.

### tensor.py:L194 — replace_buf: bound Variable parameterization

[Source](../../../../tinygrad/tinygrad/tensor.py#L194). **Match/result:** AFTER recognized as a bound Variable becomes an input PARAM.

**Example:** `n.bind(64) → PARAM(k)`; a later `n.bind(128)` can share the normalized graph.

**Why (explicit):** Strip the stored value from bound Variables for schedule-cache reuse.

**Sharp edge:** Runtime bounds/values are still passed separately; this is not replacing every symbolic value by an unconstrained number.

### function.py:L17 — pm_ctx: implicit buffer capture

[Source](../../../../tinygrad/tinygrad/function.py#L17). **Match/result:** BUFFER unless unbound: `add_to_ctx` skips buffers in ctx[1], otherwise appends x and returns `x.param_like(next_slot)`.

**Example:** A function closing over weight buffer w converts w to PARAM(0) and captures w as an implicit argument.

**Why (explicit):** Closed-over storage needs an explicit call argument; unbound outputs stay in their own CALL scope.

**Sharp edge:** The skip set prevents fresh write-only scratch from becoming an implicit input.

### function.py:L18 — pm_ctx: capture materialized state

[Source](../../../../tinygrad/tinygrad/function.py#L18). **Match/result:** AFTER or self-COPY with a non-unbound base, no PARAM in its backward slice, and at least one BUFFER: capture the entire value via add_to_ctx.

**Example:** `w.after(update)` used by a closure becomes PARAM(k) with the updated state as argument.

The backward slice means all nodes reachable by following a value’s input edges. If that slice contains a PARAM, the value already depends on the current function’s arguments; capturing it as an external constant-like input would lose that dependence.

**Why (inferred):** Capture the materialized value, including its sequencing, rather than recapturing internal buffer plumbing.

**Sharp edge:** Cross-device COPY, expressions already depending on PARAM, and unbound returned values decline.

## What the gradient rules compute

Suppose a forward node computes `y=f(x)` and a final scalar loss is `L`. The
incoming `g` is `dL/dy`: how much the loss changes for a small change in y. The
rule constructs `dL/dx = g * f'(x)`, the **chain rule**. This incoming sensitivity
is also called a **cotangent**. No knowledge of that terminology is needed beyond
“one sensitivity for each output element.” For a tensor y, g has one entry per
element; for a scalar loss L itself, the initial sensitivity is 1.

For example, let `y=x*x` and `L=3*y`. At `x=2`, the incoming sensitivity at y is
3. Each input edge of multiply contributes `3*2=6`. Both edges refer to x, so the
gradient walker adds them to obtain `dL/dx=12`. The local rule supplies the two
contributions; the walker combines shared uses and sums broadcast dimensions.

In entries below, `dx` is shorthand for `dL/dx`, and `y` denotes a saved forward
result when the formula reuses it. A tuple such as `(None,g)` is aligned with the
forward node's inputs: no differentiable contribution to input 0, sensitivity g
to input 1. `None` is different from a zero tensor: it omits a gradient edge
entirely. Shape metadata, pointers, and branch decisions commonly have no edge.

### mixin/gradient.py:L85 — pm_gradient: CAST

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L85). **Match/result:** CAST returns `(g.cast(input.dtype),)`

**Example:** float16→float32 forward; float32 cotangent 2 becomes float16 cotangent 2.

The backward graph must supply a gradient with the input’s representation. This rule converts the incoming sensitivity back to that dtype; it does not attempt to differentiate every rounding threshold of float16.

**Why (inferred):** Propagate the linear numeric conversion back into the input dtype.

**Sharp edge:** This is the chosen autograd convention, not differentiation of discrete rounding.

### mixin/gradient.py:L86 — pm_gradient: RECIPROCAL

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L86). **Match/result:** RECIPROCAL returns `(-g*y*y,)`, reusing forward result y.

**Example:** x=2, g=1 → dx=-1/4.

Since `y=1/x`, the local derivative is `-1/x²=-y²`. Multiplying by the incoming g gives `-g*y*y`; reusing y avoids constructing another reciprocal.

**Why (inferred):** Use derivative of 1/x and reuse its output.

**Sharp edge:** At zero the reciprocal and derivative are singular.

### mixin/gradient.py:L87 — pm_gradient: SIN

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L87). **Match/result:** SIN returns `(sin(pi/2-x)*g,)`.

**Example:** x=0, g=3 → dx=3.

The slope of sin(x) is cos(x). The identity `cos(x)=sin(pi/2-x)` expresses that slope using an opcode the graph already has, then g accounts for uses of the result farther downstream.

**Why (inferred):** Compute cosine with the available SIN operation.

**Sharp edge:** Argument reduction and floating-point error mean this identity need not be bitwise equal to a native cosine.

### mixin/gradient.py:L88 — pm_gradient: LOG2

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L88). **Match/result:** LOG2 returns `(g/(x*ln(2)),)`.

**Example:** x=2, g=1 → dx=1/(2 ln 2).

Write `log2(x)=ln(x)/ln(2)`. Its slope is therefore `1/(x*ln(2))`; omitting the `ln(2)` factor would give the natural-log derivative instead.

**Why (inferred):** Account for the base-2 logarithm.

**Sharp edge:** Zero/negative inputs are outside the ordinary real differentiable domain.

### mixin/gradient.py:L89 — pm_gradient: EXP2

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L89). **Match/result:** EXP2 returns `(y*g*ln(2),)`.

**Example:** x=3, g=1 → dx=8 ln 2.

Write `2**x=exp(x*ln(2))`. Differentiation supplies one `ln(2)` factor, so the forward value y is multiplied by both g and `ln(2)`.

**Why (inferred):** Differentiate base-2 exponentiation and reuse y.

**Sharp edge:** Forward overflow carries into the derivative.

### mixin/gradient.py:L90 — pm_gradient: SQRT

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L90). **Match/result:** SQRT returns `(g/(2*y),)`.

**Example:** x=4, g=1 → dx=1/4.

From `y*y=x`, small changes satisfy `2*y*dy=dx`, giving slope `dy/dx=1/(2*y)`. The rule multiplies that slope by g.

**Why (inferred):** Reuse the forward square root in its derivative.

**Sharp edge:** Derivative is singular at zero; this rule adds no epsilon.

### mixin/gradient.py:L91 — pm_gradient: TRUNC

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L91). **Match/result:** TRUNC returns a zero cotangent shaped/dtyped like g.

**Example:** x=1.7, g=5 → dx=0.

Near 1.7, a sufficiently small input change still truncates to 1, so the output change is zero. At an integer boundary the function jumps; the rule still chooses zero there by convention.

**Why (inferred):** Truncation is locally constant away from integer discontinuities.

**Sharp edge:** Zero is also returned at discontinuities; this is a convention, not a classical derivative there.

### mixin/gradient.py:L92 — pm_gradient: CMPLT and CMPNE

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L92). **Match/result:** Comparisons return `(None,None)`.

**Example:** `x<y` feeding WHERE sends no cotangent to the predicate operands.

**Why (inferred):** Boolean decisions have no ordinary differentiable edge.

**Sharp edge:** None means stop propagation, not manufacture an explicit zero tensor.

### mixin/gradient.py:L93 — pm_gradient: ADD

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L93). **Match/result:** ADD returns `(g,g)`.

**Example:** `z=x+y`, g=2 → `(dx,dy)=(2,2)`.

**Why (inferred):** Both local derivatives are one.

**Sharp edge:** Broadcasted input gradients are reduced by compute_gradient afterward.

### mixin/gradient.py:L94 — pm_gradient: POW

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L94). **Match/result:** For y=b**e: base cotangent is `g*where(e==0,e,e*b**(e-1))`; exponent cotangent uses `g*y*ln(b)` except b=0 gets 0 or -infinity according to e.

**Example:** b=2,e=3,g=1 → db=12,de=8 ln 2; e=0 yields db=0 without relying on `0*b**-1`.

For a positive base, holding e fixed gives slope `e*b**(e-1)`; holding b fixed gives slope `b**e*ln(b)`. The special branches are needed because writing those formulas literally at zero can create undefined intermediate products even when the chosen gradient is zero.

**Why (inferred):** Avoid obvious zero-base/zero-exponent indeterminate products while implementing both derivatives.

**Sharp edge:** Negative bases still have no general real exponent derivative. The explicit b=0,e<0 exponent branch is -infinity.

### mixin/gradient.py:L96 — pm_gradient: MAX pairwise

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L96). **Match/result:** MAX returns g to the greater operand, zero to the smaller; equal operands each receive g/2.

**Example:** max(3,3), g=2 → `(1,1)`; max(4,3) → `(2,0)`.

If x is strictly larger than y, changing only y a little cannot change max(x,y), so y gets zero sensitivity. At equality there is no unique ordinary derivative. Splitting g equally is the implementation’s symmetric choice of subgradient, a generalized slope at the corner.

**Why (inferred):** Choose a symmetric subgradient at ties.

**Sharp edge:** This tie policy differs from winner-takes-all and from NaN comparisons.

### mixin/gradient.py:L98 — pm_gradient: MUL

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L98). **Match/result:** MUL returns `(other_operand*g, first_operand*g)`.

**Example:** x=2,y=3,g=4 → dx=12,dy=8.

Holding y fixed, changing x by a little changes x*y by y times as much. That gives `dx=y*g`; holding x fixed similarly gives `dy=x*g`. Shared inputs accumulate both contributions.

**Why (inferred):** Apply the product rule locally.

**Sharp edge:** Aliased inputs, as in x*x, produce two edges whose contributions must later be summed.

### mixin/gradient.py:L99 — pm_gradient: WHERE

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L99). **Match/result:** WHERE(c,a,b) returns `(None,where(c,g,0),where(c,0,g))`.

**Example:** c=[true,false], g=[2,3] → da=[2,0],db=[0,3].

**Why (inferred):** Route gradient to the selected value branch.

**Sharp edge:** Predicate receives no gradient; the rule is not a smooth approximation to branch selection.

### mixin/gradient.py:L100 — pm_gradient: REDUCE: sum, maximum, product

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L100). **Match/result:** Dispatch by reduction op: ADD broadcasts g; MAX divides g equally among matching maxima using accumulator-width tie counts; MUL handles zero counts explicitly.

**Example:** sum([2,3]),g=1 → [1,1]; max([3,3,1]) → [.5,.5,0]; prod([0,2,3]) → [6,0,0], prod([0,0,3]) → [0,0,0].

For a sum, every input contributes with slope 1. For a maximum, only winning entries contribute, and a tie shares the sensitivity. For a product, an input’s derivative multiplies every other input: removing the sole zero from `[0,2,3]` leaves 6, whereas removing one zero from `[0,0,3]` still leaves a zero.

**Why (explicit):** Sum broadcasts; MAX needs tie counting without gradient-dtype overflow; product derivative at zero is the product of the other factors.

**Sharp edge:** Reduction axes are the leading `ret.arg[1]` axes, where `ret` is the forward result node. MAX counts use sum_acc_dtype; product must not naively compute y/x at zero.

### mixin/gradient.py:L101 — pm_gradient: CONTIGUOUS_BACKWARD

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L101). **Match/result:** Return `(g.contiguous(),)`.

**Example:** Forward marker around a view causes its backward cotangent to be materialized contiguously.

**Why (inferred):** This marker explicitly requests a backward storage boundary.

**Sharp edge:** It does not force forward materialization.

### mixin/gradient.py:L102 — pm_gradient: RESHAPE

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L102). **Match/result:** Return `(g.reshape(input.shape),None)`.

**Example:** Forward (2,3)→(6,); backward [g0..g5]→(2,3).

**Why (inferred):** Reshape changes indexing, so reverse it; shape metadata has no cotangent.

**Sharp edge:** Source arity includes a shape source; the None is not an optional extra.

### mixin/gradient.py:L103 — pm_gradient: EXPAND

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L103). **Match/result:** Return `(g,None)` and let the common gradient accumulator reduce broadcast axes.

**Example:** Forward (1,3)→(4,3), g=ones: rule returns (4,3) ones; edge normalization sums to (1,3) fours.

Each of the four output rows uses the same input row. Changing one input entry therefore affects four outputs, so their four sensitivities must be added. Returning g locally postpones that addition to the common broadcast-handling code.

**Why (inferred):** Centralize broadcast-gradient reduction instead of implementing it in every local rule.

**Sharp edge:** Reading the tuple alone makes this look wrong; compute_gradient performs the sum after the matcher.

### mixin/gradient.py:L104 — pm_gradient: PAD

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L104). **Match/result:** Return g shrunk to the original region, then two None metadata gradients.

**Example:** Pad [a,b] with one zero each side; g=[1,2,3,4] → dx=[2,3].

**Why (inferred):** Padded constants do not depend on the input.

**Sharp edge:** The crop starts at each left padding amount and ends at left+original size.

### mixin/gradient.py:L105 — pm_gradient: SHRINK

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L105). **Match/result:** Return g padded by `(start, original_size-start-length)` on each axis, plus two Nones.

**Example:** Slice x[1:3] from length 4; g=[7,8] → dx=[0,7,8,0].

**Why (inferred):** Unselected entries contribute zero.

**Sharp edge:** `ret.marg` uses start and length here; treating the second item as an absolute endpoint gives the wrong right padding.

### mixin/gradient.py:L106 — pm_gradient: PERMUTE

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L106). **Match/result:** Return g permuted by argsort(forward permutation).

**Example:** Forward order (2,0,1); backward permutation (1,2,0).

Forward axes `(2,0,1)` put original axis 0 in position 1, axis 1 in position 2, and axis 2 in position 0. Selecting backward axes `(1,2,0)` restores that original order.

**Why (inferred):** A permutation is inverted by its inverse permutation.

**Sharp edge:** Reusing the forward permutation only works for self-inverse permutations.

### mixin/gradient.py:L107 — pm_gradient: FLIP

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L107). **Match/result:** Return g flipped on every axis whose forward flag is true.

**Example:** Forward [a,b,c]→[c,b,a]; g=[1,2,3] → dx=[3,2,1].

**Why (inferred):** A reversal is its own inverse.

**Sharp edge:** The stored movement argument (`marg`) is a tuple of flags; the method takes axis indices.

### mixin/gradient.py:L108 — pm_gradient: STACK

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L108). **Match/result:** Return one slice `g[i]` per source.

**Example:** stack(a,b), g=[[1,2],[3,4]] → da=[1,2],db=[3,4].

**Why (inferred):** Separate the stacked cotangent back into the contributing values.

**Sharp edge:** The count follows source arity, not an arbitrary runtime axis.

### mixin/gradient.py:L109 — pm_gradient: COPY

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L109). **Match/result:** Self-copy returns g unchanged; cross-device COPY returns g copied back to the source device.

**Example:** CPU→AMD forward; AMD cotangent → CPU backward.

**Why (inferred):** The derivative is identity in value space but must honor device placement.

**Sharp edge:** A self-copy does not force another backward copy.

### mixin/gradient.py:L110 — pm_gradient: UNSHARD

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L110). **Match/result:** Shard g with the forward device tuple/axis and return the resulting shard sources.

**Example:** Two shards forming a length-8 value receive the corresponding halves of the length-8 cotangent.

**Why (inferred):** Reverse assembly of distributed storage.

**Sharp edge:** Replicated versus axis-sharded layouts follow `ret.axis`; do not assume every case is a simple split.

### mixin/gradient.py:L111 — pm_gradient: SINK

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L111). **Match/result:** Return ctx.src as the per-source gradient tuple.

**Example:** SINK(a,b), incoming SINK(ga,gb) → `(ga,gb)`.

**Why (inferred):** SINK is a structural tuple of outputs.

**Sharp edge:** The incoming gradient must have the same structural arity.

### mixin/gradient.py:L112 — pm_gradient: AFTER a CALL

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L112). **Match/result:** AFTER(d,CALL(...,d,...)) returns g for d and a SINK cotangent for CALL, with g at d’s argument position and NOOP elsewhere.

**Example:** CALL(body,input,out), result out.after(call) → call cotangent SINK(NOOP,g).

NOOP here marks a call-argument position with no output sensitivity. The SINK preserves positional correspondence so the later call-gradient machinery can connect g to the output buffer that actually produced the value.

**Why (inferred):** Route an output’s gradient back to the correct slot of a multi-output call.

**Sharp edge:** d must actually occur among the call sources; later call_gradient handles custom gradients or differentiates output stores.

### mixin/gradient.py:L115 — pm_gradient: AFTER unrelated STORE

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L115). **Match/result:** AFTER(dest,STORE(t,v)) returns `(g,None)` if t and dest have different buf_uop identities, otherwise declines.

**Example:** Return a after writing unrelated b: cotangent remains on a and does not differentiate b’s write.

**Why (explicit):** This AFTER is ordering-only; the returned value was not changed.

**Sharp edge:** Identity check must use underlying buffers because views can alias.

### mixin/gradient.py:L118 — pm_gradient: AFTER full assignment

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L118). **Match/result:** AFTER(dest,STORE(dest,v)) returns `(None,g)`.

**Example:** Overwrite a with v, then use a: gradient goes to v through STORE, not to old a.

**Why (explicit):** Clone/assign gradient passes through the assigned value.

**Sharp edge:** Repeated dest binding requires identical UOps; a partial view write falls through.

### mixin/gradient.py:L119 — pm_gradient: AFTER partial assignment

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L119). **Match/result:** For a STORE view reached from dest through only RESHAPE/SHRINK/PERMUTE/FLIP, apply that view path to g and zero the written region of dest’s old-state cotangent.

**Example:** Write v into a[1:3], incoming g=[1,2,3,4] → old a=[1,0,0,4], STORE cotangent=[2,3].

The loss can still depend on old a outside the slice, but the overwritten old entries no longer affect the result. Conversely, each newly written v entry receives the sensitivity of the destination position it replaced.

**Why (explicit):** A nonoverlapping view write replaces only its region of returned state.

**Sharp edge:** Unsupported paths or a view not rooted at dest decline; arbitrary overlapping EXPAND writes are not accepted.

### mixin/gradient.py:L120 — pm_gradient: STORE

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L120). **Match/result:** Two-source STORE returns `(None,g)`.

**Example:** STORE(pointer,v) with cotangent 3 → dv=3, no pointer gradient.

**Why (inferred):** Stored value determines new contents; the destination is storage.

**Sharp edge:** This specifically matches two sources, not every low-level store form.

### mixin/gradient.py:L122 — pm_gradient: BITCAST

[Source](../../../../tinygrad/tinygrad/mixin/gradient.py#L122). **Match/result:** Return `(None,)`.

**Example:** float bits reinterpreted as integer do not propagate a numeric cotangent.

**Why (explicit):** There is no gradient for bitcast.

**Sharp edge:** Do not confuse it with CAST, whose rule propagates a converted gradient.

## Substitution and view analysis

The following matchers operate on the graph as a data structure. A
**substitution** replaces selected node identities. A **contiguous view** names
one consecutive span of an existing allocation; discovering its starting offset
can avoid making a second buffer. Keep offsets' units visible: an offset of two
u32 elements is eight bytes, but an offset of two u8 elements is two bytes.
These analyses are useful precisely because they can describe storage without
running a tensor calculation.

### uop/ops.py:L1816 — _substitute: dictionary-driven rule factory

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1816). **Match/result:** Any Ops member looks up its exact UOp in ctx and returns the replacement or None. `UOp.substitute` filters identity substitutions and composes `extra_pm` before this rule.

**Example:** With `{x:y}`, `ADD(x,2) → ADD(y,2)`; an equal-looking but distinct key is not selected unless UOp interning gives the same key.

“Lexical” means the parameter belongs to its enclosing function body. PARAM(0) inside an inner CALL can refer to a different input from PARAM(0) in the outer body, just as two Python functions can both name a parameter x.

**Why (inferred):** Use one generic matcher for dynamically supplied substitutions: call argument binding, forward-output reuse in backward graphs, scratch renumbering, and many other callers.

**Sharp edge:** Bottom-up traversal, walk, and enter_calls options determine scope. Nested CALL PARAMs are lexical; entering them accidentally can substitute the wrong parameters.

### uop/ops.py:L1817 — _pm_resolve_params: positional call substitution

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1817). **Match/result:** PARAM returns `ctx[p.arg.slot]`.

**Example:** Call body `PARAM(1)*2` with arguments (a,b) becomes `b*2`.

**Why (inferred):** Resolve a lexical parameter against the caller’s argument tuple.

**Sharp edge:** No bounds check or missing-value fallback is supplied; a wrong slot or wrong call scope is a caller error.

### uop/ops.py:L1825 — remove_all_tags: erase storage annotations

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1825). **Match/result:** Any operation with non-None tag gets a copy with tag=None.

**Example:** `ADD[tag=(old,)](x,y) → ADD(x,y)`.

**Why (inferred):** Remove frontend identity annotations once a graph no longer needs them.

**Sharp edge:** An empty tag is also erased; this changes annotation identity, not mathematical computation.

### uop/ops.py:L1836 — pm_unbind: split symbolic value from binding

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1836). **Match/result:** AFTER recognized as a bound Variable calls unbind(), records `ctx[variable]=integer`, and returns the variable.

**Example:** `n.bind(64) → n`, recording `{n:64}`.

**Why (inferred):** Separate runtime scalar values from symbolic graph structure for reuse.

**Sharp edge:** An arbitrary AFTER is not a binding. The context stores one current integer per variable.

### uop/ops.py:L1841 — contiguous_view_offset: flatten BITCAST

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1841). **Match/result:** BITCAST whose result is not rank one becomes flatten(input).bitcast(dtype).reshape(original_shape).

**Example:** `BITCAST_u8(b_u32[2,2]) → RESHAPE(BITCAST_u8(FLATTEN(b)), original_byte_shape)`.

**Why (explicit):** Normalize bitcasts to one dimension before finding a contiguous byte offset.

**Sharp edge:** This is a view analysis normalization; rank-one casts decline to avoid a rewrite loop.

### uop/ops.py:L1842 — contiguous_view_offset: convert bitcast offset units

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1842). **Match/result:** INDEX(BITCAST(b),constant c), only with a tagged bitcast: convert count and offset by output/input element sizes, indexing flattened b with a new range.

**Example:** Tagged u32→u8 view at byte offset 8 covering 8 bytes becomes a range of 2 u32 elements starting at element 2.

The same starting byte is `8 / 4 = 2` elements into the original u32 buffer. The view’s eight-byte span covers `8 / 4 = 2` original elements. Both offset and span must change units together.

**Why (inferred):** Track contiguous storage in the underlying buffer’s element units across dtype reinterpretation.

**Sharp edge:** Uses integer division: byte alignment and proof of contiguity are obligations of surrounding analysis, not a generic permission to alias misaligned casts.

### uop/ops.py:L1844 — contiguous_view_offset: scalar base index

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1844). **Match/result:** INDEX with only a base becomes `base.rtag().index(0)`.

**Example:** A scalar view INDEX(b) normalizes to INDEX(b,0).

**Why (inferred):** Represent a scalar storage view with an explicit zero starting offset.

**Sharp edge:** Only the no-index source shape matches; rtag changes analysis tags.

### uop/ops.py:L1845 — contiguous_view_offset: zero-origin range

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1845). **Match/result:** INDEX(base,RANGE) becomes tagged base indexed at zero.

**Example:** `b[r]` for r=0..15 yields starting offset 0.

The range describes many positions, but this analysis asks only where that span starts. Replacing r by zero answers that question; it would be incorrect if the replacement were executed as the original computation.

**Why (inferred):** Contiguous range analysis needs the starting address, not each element’s address.

**Sharp edge:** The replacement is not an executable vector-load optimization; interpreting it as one would lose all but the first element.

### uop/ops.py:L1846 — contiguous_view_offset: shifted range

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1846). **Match/result:** INDEX(base,RANGE+constant c) becomes tagged base indexed at c.

**Example:** `b[r+12]` yields starting offset 12.

**Why (inferred):** A unit-stride range shifted by a constant describes one contiguous span.

**Sharp edge:** `2*r+12` is not this pattern; a strided span cannot use the same proof.

### uop/ops.py:L1847 — contiguous_view_offset: singleton constant index

[Source](../../../../tinygrad/tinygrad/uop/ops.py#L1847). **Match/result:** INDEX(base,constant c) is accepted only if ctx.numel()==1 resolves true; tag base and retain index c.

**Example:** A one-element view b[7:8] yields offset 7.

**Why (inferred):** A constant index is contiguous for one element.

**Sharp edge:** For a larger view, a constant index denotes repeated/aliased elements, so the guard prevents a false contiguous proof.

## Compiling the pattern matcher itself

Here the program being compiled is “does this graph node match this pattern?”
Tinygrad expresses that decision as a small predicate graph and renders Python
code to evaluate it. Consequently `AND` combines conditions, a `STORE` can bind
a Python pattern name, and `INDEX` can mean selecting a child from `uop.src`.
Their meaning in this context is not a GPU arithmetic instruction or memory
write. `CUSTOMI` below holds a source-code fragment used to assemble that Python
predicate.

### uop/upat.py:L109 — pm_proc: normalize compiled match predicates

[Source](../../../../tinygrad/tinygrad/uop/upat.py#L109). **Match/result:** AND invokes do_process_and: flatten nested ANDs; combine multiple OR clauses by Cartesian product; push STORE bindings into OR branches; replace repeated-name bindings by identity tests; deduplicate terms.

**Example:** `AND(bind x=a,bind x=b,p)` becomes `AND(a is b,p,bind x=a)`; `AND(OR(p,q),OR(r,s))` expands to four branch conjunctions.

A repeated name in a pattern means the very same node must fill both positions. The generated `a is b` checks that identity. Expanding alternatives gives each successful branch a definite set of captured names before the callback runs.

**Why (explicit):** The file explicitly compiles a predicate IR into Python. Normalization makes binding scope and branch returns representable.

**Sharp edge:** Four or more OR children raise UPatCompileError and trigger interpreter fallback. These STOREs are name bindings, not device memory writes.

### uop/upat.py:L117 — pm_renderer: capture Python literal

[Source](../../../../tinygrad/tinygrad/uop/upat.py#L117). **Match/result:** PYLITERAL allocates a name `a{len(ctx)}` in a Python lookup dictionary and returns a CUSTOMI fragment with that name.

**Example:** A dtype object literal becomes fragment a0, with ctx[a0]=dtypes.float32.

**Why (inferred):** Keep arbitrary Python objects available to generated predicate code without trying to serialize them as source.

**Sharp edge:** Names refer to generated-function globals; they are not kernel constants.

### uop/upat.py:L120 — pm_renderer: conjunction inside repeated match

[Source](../../../../tinygrad/tinygrad/uop/upat.py#L120). **Match/result:** CUSTOM with exactly three sources, first an AND entirely of CUSTOMI, joins that conjunction into one parenthesized CUSTOMI.

**Example:** `CUSTOM(all([{0} for {1} in {2}.src]), AND(p,q),it,uop)` becomes the same template with first fragment `(p and q)`.

**Why (explicit):** The source comment identifies the AND-of-fragments conversion; it enables repeated-source pattern predicates.

**Sharp edge:** All children must already be string fragments. Parentheses retain conjunction grouping inside the comprehension.

### uop/upat.py:L123 — pm_renderer: interpolate predicate template

[Source](../../../../tinygrad/tinygrad/uop/upat.py#L123). **Match/result:** CUSTOM whose every source is CUSTOMI formats its arg template with their strings and becomes CUSTOMI.

**Example:** Template `{0}.dtype == {1}` with fragments uop,a0 emits `uop.dtype == a0`.

**Why (inferred):** Finish lowering predicate IR operations into Python expressions.

**Sharp edge:** Python format placeholders and source order must agree; this is not arbitrary UOp arithmetic.

### uop/upat.py:L124 — pm_renderer: child access

[Source](../../../../tinygrad/tinygrad/uop/upat.py#L124). **Match/result:** INDEX(CUSTOMI x,CONST c) becomes x’s fragment followed by `.src[c]`.

**Example:** `INDEX(fragment uop,1) → fragment uop.src[1]`.

**Why (inferred):** Compiled structural matching needs direct access to a candidate’s children.

**Sharp edge:** The preceding generated length checks must protect out-of-range accesses; this rule itself inserts none.

## Three kinds of text output

The ordinary `renderer` makes graphs readable in diagnostics, often omitting
information. `renderer_infer` produces expressions for scalar inference, with
helpers supplied by the caller. `pyrender` produces Python expressions intended
to reconstruct supported UOp graphs. These purposes explain apparently fussy
rules: a pretty label can omit a dtype, whereas reconstruction must retain it;
a convenient Python operator can insert broadcasting or casts, so reconstruction
sometimes uses an explicit `.alu(...)` constructor instead. None of these is
the device kernel source renderer.

### uop/render.py:L35 — renderer: PARAM

[Source](../../../../tinygrad/tinygrad/uop/render.py#L35). **Match/result:** PARAM emits its explicit name or `p{slot}`.

**Example:** Unnamed slot 2 → `p2`; named weight → `weight`.

**Why (inferred):** Give graph parameters concise stable labels.

**Sharp edge:** Names are diagnostic labels, not proof of parameter identity.

### uop/render.py:L36 — renderer: BUFFER

[Source](../../../../tinygrad/tinygrad/uop/render.py#L36). **Match/result:** BUFFER emits a ParamArg name when available, else `b{slot}`.

**Example:** Buffer slot 7 → `b7`.

**Why (inferred):** Distinguish storage from parameter placeholders visually.

**Sharp edge:** A name can hide the device/dtype; inspect the UOp for those details.

### uop/render.py:L37 — renderer: AFTER

[Source](../../../../tinygrad/tinygrad/uop/render.py#L37). **Match/result:** AFTER emits the already-rendered first source.

**Example:** `AFTER(b7,STORE(...)) → b7`.

**Why (inferred):** Display its value without expanding sequencing dependencies.

**Sharp edge:** This output deliberately hides side effects; never use it alone to audit execution ordering.

### uop/render.py:L38 — renderer: SPECIAL

[Source](../../../../tinygrad/tinygrad/uop/render.py#L38). **Match/result:** SPECIAL emits x.arg directly.

**Example:** Hardware index SPECIAL arg `gidx0` → `gidx0`.

**Why (inferred):** Use the descriptive special-index name.

**Sharp edge:** It omits the bound stored in the source.

### uop/render.py:L39 — renderer: void RANGE

[Source](../../../../tinygrad/tinygrad/uop/render.py#L39). **Match/result:** A void-typed RANGE emits `loop{arg[0]}`.

**Example:** Void range with identifier 3 → `loop3`.

**Why (inferred):** Distinguish a control-flow loop from a numeric index value.

**Sharp edge:** This more specific rule must precede the general RANGE rule.

### uop/render.py:L40 — renderer: numeric RANGE

[Source](../../../../tinygrad/tinygrad/uop/render.py#L40). **Match/result:** Other RANGE nodes emit `r` plus range_str(x).

**Example:** RANGE with arg `(3, AxisType.LOOP)` → `r3`; arg `(2,-1,AxisType.REDUCE)` → `r2_m1`.

**Why (inferred):** Expose the range’s role without dumping its subgraph.

**Sharp edge:** The uncolored string omits the axis-type enum; it encodes range IDs, not the numerical extent.

### uop/render.py:L41 — renderer: CONST

[Source](../../../../tinygrad/tinygrad/uop/render.py#L41). **Match/result:** CONST emits str(x.val).

**Example:** CONST(7) → `7`.

**Why (inferred):** Show a literal’s value directly.

**Sharp edge:** Width and dtype are not present in this rendering.

### uop/render.py:L43 — renderer: cast constant

[Source](../../../../tinygrad/tinygrad/uop/render.py#L43). **Match/result:** CAST(CONST c) emits str(c.val), overriding the generic CAST rendering.

**Example:** CAST_float32(CONST(2.0)) → `2.0`.

**Why (explicit):** The source explains that CAST states the width while the weak CONST carries the value.

**Sharp edge:** Diagnostic rendering suppresses the width; do not infer dtype from this text.

### uop/render.py:L44 — renderer: CAST

[Source](../../../../tinygrad/tinygrad/uop/render.py#L44). **Match/result:** CAST emits `(dtype_without_dtypes_prefix)(rendered_source)`.

**Example:** CAST_float32(x) → `(float32)(x)`.

**Why (inferred):** Retain visible conversion when the source is not the constant special case.

**Sharp edge:** This is debugging syntax, not necessarily executable Python.

### uop/render.py:L45 — renderer: NEG

[Source](../../../../tinygrad/tinygrad/uop/render.py#L45). **Match/result:** NEG emits `(-x)`.

**Example:** NEG(a) → `(-a)`.

**Why (inferred):** Use familiar unary arithmetic.

**Sharp edge:** It does not simplify a double negation.

### uop/render.py:L46 — renderer: RECIPROCAL

[Source](../../../../tinygrad/tinygrad/uop/render.py#L46). **Match/result:** RECIPROCAL emits `(1/x)`.

**Example:** RECIPROCAL(a) → `(1/a)`.

**Why (inferred):** Make the operation readable without its enum name.

**Sharp edge:** Text alone does not specify hardware approximate-reciprocal semantics.

### uop/render.py:L47 — renderer: MAX

[Source](../../../../tinygrad/tinygrad/uop/render.py#L47). **Match/result:** MAX emits `max(x, y)`.

**Example:** MAX(a,b) → `max(a, b)`.

**Why (inferred):** Make pairwise maximum recognizable.

**Sharp edge:** This is not a reduction and says nothing about NaN behavior.

### uop/render.py:L48 — renderer: MULACC

[Source](../../../../tinygrad/tinygrad/uop/render.py#L48). **Match/result:** MULACC emits `(x*y+z)`.

**Example:** MULACC(a,b,c) → `(a*b+c)`.

A fused multiply-add rounds once after computing the full expression; separate multiply and add can round twice. Both print as `a*b+c` here, so the diagnostic string deliberately cannot answer that numerical question.

**Why (inferred):** Show the multiply-add formula.

**Sharp edge:** The text hides whether arithmetic is fused and how rounding occurs.

### uop/render.py:L49 — renderer: WHERE

[Source](../../../../tinygrad/tinygrad/uop/render.py#L49). **Match/result:** WHERE emits Python-style conditional text.

**Example:** WHERE(c,a,b) → `(a if c else b)`.

**Why (inferred):** Make branch selection intuitive in a graph display.

**Sharp edge:** This text is not a lazy-control-flow guarantee; graph branches may already be computed.

### uop/render.py:L50 — renderer: CDIV

[Source](../../../../tinygrad/tinygrad/uop/render.py#L50). **Match/result:** CDIV emits `cdiv(x, y)`.

**Example:** CDIV(-7,3) → `cdiv(-7, 3)` (value -2).

**Why (inferred):** Distinguish truncating division from Python floor division.

**Sharp edge:** For negatives, replacing it with // changes the value.

### uop/render.py:L51 — renderer: CMOD

[Source](../../../../tinygrad/tinygrad/uop/render.py#L51). **Match/result:** CMOD emits `cmod(x, y)`.

**Example:** CMOD(-7,3) → `cmod(-7, 3)` (value -1).

**Why (inferred):** Distinguish the remainder paired with truncating division.

**Sharp edge:** Python % would yield 2 in this example.

### uop/render.py:L52 — renderer: movement template

[Source](../../../../tinygrad/tinygrad/uop/render.py#L52). **Match/result:** All movement ops render `source.op(render_marg(...))`; movement-argument rendering distinguishes permutation, flip-axis list, shapes, and pad/shrink pairs.

**Example:** RESHAPE(a,(2,3)) → `a.reshape((2,3))`; FLIP flags (false,true) → `a.flip((1,))`.

**Why (inferred):** Present tensor indexing transforms in their familiar method forms.

**Sharp edge:** Simplified symbolic movement-argument expressions may not occur in ctx, so marg_str falls back to their own render().

### uop/render.py:L53 — renderer: infix arithmetic template

[Source](../../../../tinygrad/tinygrad/uop/render.py#L53). **Match/result:** ADD/SUB/FLOORDIV/FLOORMOD/SHL/SHR/MUL/CMPLT/CMPNE/AND/OR/XOR emit their symbols using precedence-aware parentheses.

**Example:** ADD(MUL(a,b),c) → `(a*b+c)`; SUB(a,SUB(b,c)) retains parentheses around the right subtraction.

Parentheses preserve the expression tree: `a-(b-c)` differs from `(a-b)-c`. Removing only redundant parentheses improves legibility without changing which operands belong to which operation.

**Why (inferred):** Reduce display noise while preserving grouping.

**Sharp edge:** Comparison ops are deliberately outside the precedence table because Python comparison chaining is different.

### uop/render.py:L54 — renderer: INDEX and STAGE

[Source](../../../../tinygrad/tinygrad/uop/render.py#L54). **Match/result:** Emit concatenated brackets for sources after the base, stripping outer parentheses on indices.

**Example:** INDEX(b,i,j) → `[i][j]`, not `b[i][j]`.

**Why (inferred):** Display just an indexing suffix for graph diagnostics.

**Sharp edge:** The base is deliberately absent: this is neither a complete address nor a reconstruction expression.

### uop/render.py:L55 — renderer: STACK

[Source](../../../../tinygrad/tinygrad/uop/render.py#L55). **Match/result:** STACK emits brace-enclosed comma-separated source strings.

**Example:** STACK(a,b) → `{a,b}`.

**Why (inferred):** Compactly show packed lanes or a stack of values.

**Sharp edge:** Braces are display notation, not a Python set-valued interpretation.

### uop/render.py:L56 — renderer: fallback

[Source](../../../../tinygrad/tinygrad/uop/render.py#L56). **Match/result:** Any remaining operation emits str(x), the UOp’s structural representation.

**Example:** An unsupported display shorthand such as CALL falls back to its UOp representation.

**Why (inferred):** Ensure diagnostics still cover newly introduced operation kinds.

**Sharp edge:** Fallback output can be large and is not an executable reconstruction guarantee.

### uop/render.py:L60 — renderer_infer: FLOORMOD

[Source](../../../../tinygrad/tinygrad/uop/render.py#L60). **Match/result:** FLOORMOD emits `floormod(x,y)` before generic rendering.

**Example:** FLOORMOD(-7,3) → `floormod(-7, 3)` (2).

**Why (inferred):** Route inference to the supplied floor-remainder helper.

**Sharp edge:** Keep distinct from CMOD, especially for negative operands.

### uop/render.py:L61 — renderer_infer: FLOORDIV

[Source](../../../../tinygrad/tinygrad/uop/render.py#L61). **Match/result:** FLOORDIV emits `floordiv(x,y)`.

**Example:** FLOORDIV(-7,3) → `floordiv(-7, 3)` (-3).

**Why (inferred):** Use an explicit inference helper for floor semantics.

**Sharp edge:** CDIV’s truncation would return -2 instead.

### uop/render.py:L62 — renderer_infer: CAST

[Source](../../../../tinygrad/tinygrad/uop/render.py#L62). **Match/result:** CAST chooses Python float, bool, or int according to destination dtype.

**Example:** CAST_float32(x) → `float(x)`; CAST_bool(x) → `bool(x)`.

**Why (inferred):** Produce evaluable scalar inference expressions.

**Sharp edge:** Python conversion does not itself reproduce every finite-width GPU overflow or rounding behavior.

### uop/render.py:L64 — renderer_infer: BITCAST

[Source](../../../../tinygrad/tinygrad/uop/render.py#L64). **Match/result:** BITCAST emits a helper call including repr of source and destination dtype.

**Example:** BITCAST_i32(float32 x) → `bitcast(x,dtypes.float32,dtypes.int32)`.

**Why (inferred):** Bit reinterpretation needs widths and kinds, unlike a numeric Python conversion.

**Sharp edge:** The helper must be present in the evaluation environment.

### uop/render.py:L84 — pyrender: CONST

[Source](../../../../tinygrad/tinygrad/uop/render.py#L84). **Match/result:** Source-free CONST emits `UOp.const(value)`.

**Example:** CONST(7) → `UOp.const(7)`.

**Why (inferred):** Reconstruct the weak literal node through the canonical constructor.

**Sharp edge:** Typed values normally include a separate CAST node; this rule is not a typed-constant serializer.

### uop/render.py:L85 — pyrender: CAST and BITCAST

[Source](../../../../tinygrad/tinygrad/uop/render.py#L85). **Match/result:** Emit `src.cast(dtype)` / `src.bitcast(dtype)` only when source and target dtype differ.

**Example:** CAST_float32(weak 2) → `UOp.const(2).cast(dtypes.float32)`.

**Why (inferred):** Use concise explicit conversion constructors.

**Sharp edge:** A same-dtype conversion declines so the structural fallback can preserve the actual node.

### uop/render.py:L86 — pyrender: SPECIAL

[Source](../../../../tinygrad/tinygrad/uop/render.py#L86). **Match/result:** SPECIAL with exactly one CONST source emits `UOp.special(bound, repr(name))`.

**Example:** SPECIAL(CONST(256),arg=gidx0) → `UOp.special(256, 'gidx0')`.

**Why (inferred):** Preserve both index name and bound in reconstruction.

**Sharp edge:** Nonconstant or differently shaped sources fall through.

### uop/render.py:L87 — pyrender: BUFFER

[Source](../../../../tinygrad/tinygrad/uop/render.py#L87). **Match/result:** Source-free BUFFER with ParamArg and GLOBAL address space emits `UOp.new_buffer(device,max_numel,dtype,slot)`.

**Example:** A CPU float32 buffer of 16 elements, slot 3 → `UOp.new_buffer('CPU', 16, dtypes.float32, 3)`.

**Why (inferred):** Reconstruct global storage declarations compactly.

**Sharp edge:** pyrender separately rejects BUFFERs carrying live device Buffer objects: their runtime allocation cannot be serialized this way.

### uop/render.py:L90 — pyrender: COPY

[Source](../../../../tinygrad/tinygrad/uop/render.py#L90). **Match/result:** One-source COPY emits `source.copy_to_device(repr(copy.arg))`.

**Example:** COPY_CPU(x) → `x.copy_to_device('CPU')`.

**Why (inferred):** Express transfer/self-copy using its construction API.

**Sharp edge:** The destination is stored in arg; this does not embed buffer contents.

### uop/render.py:L91 — pyrender: CUSTOM_FUNCTION

[Source](../../../../tinygrad/tinygrad/uop/render.py#L91). **Match/result:** Emit an explicit UOp constructor with CUSTOM_FUNCTION, source tuple, and arg repr.

**Example:** A custom function with source x emits `UOp(Ops.CUSTOM_FUNCTION, src=(x,), arg=...)`.

**Why (inferred):** Retain the custom function payload while serializing graph structure.

**Sharp edge:** The payload repr may require names in the reconstruction environment.

### uop/render.py:L92 — pyrender: shaped REDUCE

[Source](../../../../tinygrad/tinygrad/uop/render.py#L92). **Match/result:** REDUCE with nonzero `arg[1]` emits `src._rop(reduction_op,tuple(range(arg[1])))`.

**Example:** A sum over two leading axes → `x._rop(Ops.ADD, (0, 1))`.

**Why (inferred):** Reconstruct high-level leading-axis reduction using the canonical helper.

**Sharp edge:** Zero-leading-axis reductions decline; other representations use the generic sugar/fallback.

### uop/render.py:L94 — pyrender: RANGE

[Source](../../../../tinygrad/tinygrad/uop/render.py#L94). **Match/result:** RANGE whose first source is CONST emits UOp.range with that extent and all arg entries, preserving additional sources in `src=`.

**Example:** A range of 16 with an extra control dependency emits `UOp.range(16, ..., src=(dep,))`.

**Why (explicit):** The source notes that ranges acquire extra sources after control-flow processing; reconstruction must retain them.

**Sharp edge:** Dropping extra sources would silently change ordering.

### uop/render.py:L101 — pyrender: truncating CDIV

[Source](../../../../tinygrad/tinygrad/uop/render.py#L101). **Match/result:** CDIV emits `lhs.alu(Ops.CDIV,rhs)`.

**Example:** `a.alu(Ops.CDIV,b)` preserves truncation for -7/3 → -2.

**Why (explicit):** The source explicitly warns that // parses as FLOORDIV.

**Sharp edge:** Operator sugar here would reconstruct a different operation.

### uop/render.py:L102 — pyrender: truncating CMOD

[Source](../../../../tinygrad/tinygrad/uop/render.py#L102). **Match/result:** CMOD emits `lhs.alu(Ops.CMOD,rhs)`.

**Example:** `a.alu(Ops.CMOD,b)` preserves -7 rem 3 → -1.

**Why (explicit):** The source explicitly warns that % parses as FLOORMOD.

**Sharp edge:** Positive-only examples would conceal the bug.

### uop/render.py:L104 — pyrender: WHERE without repromotion

[Source](../../../../tinygrad/tinygrad/uop/render.py#L104). **Match/result:** WHERE emits `condition.alu(Ops.WHERE,a,b)`.

**Example:** Rebuild a WHERE containing a weak literal with `.alu(...)`, retaining the source tuple.

The public `.where(...)` helper prepares user expressions by reconciling operand types. A serializer already has the desired exact source nodes, so repeating that preparation could produce a different graph on reload.

**Why (explicit):** The source notes that `.where` re-promotes operands and can add casts.

**Sharp edge:** The safe representation is structural; convenient frontend methods can change the graph.

### uop/render.py:L106 — pyrender: safe infix template

[Source](../../../../tinygrad/tinygrad/uop/render.py#L106). **Match/result:** For the infix-op set except SUB/CDIV/CMOD, use infix text only if `_broadcasted(lhs,rhs)==original_sources`; otherwise emit `.alu(op,rhs)`.

**Example:** Same-dtype a+b → `(a+b)`; a weak/strong pair whose operator would add CAST becomes `a.alu(Ops.ADD,b)`.

The `_broadcasted` check asks what the convenient operator would do to its operands. If it would expand a shape or insert a cast, the renderer uses `.alu` to preserve the graph that already exists.

**Why (explicit):** The source explicitly avoids type promotion while reconstructing exact UOps.

**Sharp edge:** SUB is excluded from this template. A separate source comment also flags missing reflected inequality behavior; do not assume every pretty expression round-trips identically.

### uop/render.py:L109 — pyrender: source-free method sugar

[Source](../../../../tinygrad/tinygrad/uop/render.py#L109). **Match/result:** For the sugar set, zero-source nodes emit `UOp.opname(arg=... if present)`.

**Example:** Empty SINK → `UOp.sink()`; source-free BARRIER → `UOp.barrier()`.

**Why (inferred):** Use constructor-like methods for nullary members of the supported sugar set.

**Sharp edge:** Only ops in sugar participate; adding an enum does not automatically add method support.

### uop/render.py:L110 — pyrender: sourceful method sugar

[Source](../../../../tinygrad/tinygrad/uop/render.py#L110). **Match/result:** For sugar-set nodes with sources, emit a method on source 0, passing remaining sources and arg if present.

**Example:** SQRT(x) → `x.sqrt()`; STORE(p,v) → `p.store(v)`.

**Why (inferred):** Use short canonical UOp construction APIs for common graph operations.

**Sharp edge:** Sugar includes SINK/END/STORE/LOAD/SQRT/INDEX/REDUCE/AFTER/THREEFRY/RECIPROCAL/EXP2/LOG2/SIN/BARRIER/DETACH. Earlier specialized rules win.

### uop/render.py:L116 — pyrender: structural fallback

[Source](../../../../tinygrad/tinygrad/uop/render.py#L116). **Match/result:** Any remaining op emits `UOp(op, source_tuple[, arg])`.

**Example:** An operation without sugar emits e.g. `UOp(Ops.NEG, (x,))`.

**Why (explicit):** The source explicitly says pm_pyrender_extra can be removed and structural rendering still works.

**Sharp edge:** The surrounding renderer splits deep/shared expressions and appends tags. It explicitly rejects certain opaque calls/live buffers; “fallback” does not mean every runtime graph is serializable.

## Context that explains otherwise surprising rules

The gradient walker, not `pm_gradient`, handles CALL differentiation, DETACH traversal stopping, summing gradients from shared edges, and reducing broadcast gradients back to each source shape. Consequently there is no missing DETACH or CALL tuple in the list above. `call_gradient` can invoke an explicit custom derivative or differentiate a SINK of output stores, compact the needed PARAMs, and build one backward CALL. Precompiled calls substitute saved forward outputs to avoid recomputing them; this is a call-level concern, not a scalar derivative rule.

The two `PatternMatcher([])` instances in `tensor.py` (L199 and L233) are visualization hooks. They deliberately apply zero rewrites. Dynamic substitutions made by `_compact_params`, `renumber_invalid_outputs`, precompiled-call placement, and many other callers are instances of the `_substitute` rule template above, not additional hidden matcher tuples.

The commented-out movement pyrender rule at `uop/render.py:L98` is **inactive**. Its adjacent TODO says movement helpers simplify expressions and can break SPEC=2. That is a useful example of why the “uglier” structural constructor fallback exists: reconstruction should preserve the graph rather than opportunistically simplify it.

A useful exercise is to trace RMSNorm backward with x shaped (B,N): reciprocal/sqrt/multiply local rules are short, but the reduction and broadcast-gradient machinery create whole backward reductions. A second exercise is to overwrite a slice of the RMSNorm output before computing loss: the three AFTER/STORE rules distinguish unrelated sequencing, full overwrite, and partial overwrite. These graph-level effects are much easier to miss than the derivative formulas.
