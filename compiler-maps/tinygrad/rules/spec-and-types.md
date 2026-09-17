# Every rule: specification, bounds proofs, and weak types

Source snapshot: tinygrad `107adc31701df0247dfa45e175984df906a68b53`.
This chapter covers **100 rule entries**: 82 in `uop/spec.py`, nine in
`uop/validate.py`, and nine in `uop/weak.py`. These files have no rule-generating
comprehensions or runtime rule factories. An opcode set in a pattern applies the
same callback to each listed member; relevant variants are explained below.

All arrow examples below are **schematic, not executed**, unless explicitly
listed in the CPU probe at the end. `f32(x)`, `i32(x)`, and `CAST_i32(x)` denote
typed values/conversions, not Python constructor signatures. Some malformed
examples cannot be constructed through normal UOp APIs: dtype derivation rejects
them before a spec sees them. “Declines” means this rule returns `None` or does not
match, allowing a later rule; **`False` is terminal**, just like `True`.
`type_verify` requires the final matcher result to be exactly `True`.

Why these rules exist is often recoverable from the invariant they enforce, but
that does not establish the original author's historical motivation. “Source”
means a local comment explicitly explains the purpose. “Inference” means the
explanation follows from current code, without claiming a PR or hardware bug
was the original cause.

## Start with the question each matcher answers

A UOp is a node in a computation graph: its opcode says what it does, `src`
holds its input nodes, and `arg` holds metadata such as an axis number. Its
`dtype` describes the kind and width of its values. See the shared
[first-principles guide](../../first-principles.md) for the larger compiler path.

This chapter contains three different jobs. The `spec_*` matchers answer
“is this node allowed at this stage?” and return acceptance or rejection. They
**do not repair the graph**. The Z3 matcher translates index arithmetic into a
mathematical question about possible out-of-bounds accesses. The weak-type
matchers actually replace graph nodes so that numbers acquire concrete machine
types. A successful bounds proof, a successful format check, and a successful
rewrite therefore mean different things.

Read each specification entry as a small part of a validator, not a complete
contract for the operation. For example, `RESHAPE` acceptance checks that two
inputs exist; it does not itself prove that the old and new shapes have the same
number of elements. `type_verify` checks nodes individually, so accepting a root
also does not automatically accept its children.

### Types, widths, and addresses in the examples

`f32` means 32-bit floating point; `f16` means 16-bit floating point. `i32` is a
32-bit signed integer, while `u32` is unsigned and cannot represent negative
values. `bool` holds a true/false decision. A bool result can still require
wide inputs: comparing two i64 indices produces one bool without making the
indices themselves bools. `void` means no data value, as for a store effect.

A **weak** type records integer or floating-point kind while deferring the width
choice. The literal `1` can participate in an i32 index calculation or be
converted for an f16 tensor operation. A **strong** type has committed to a
concrete representation. `CAST` converts a number, potentially rounding it;
`BITCAST` reinterprets the same bits. For example, an 8-bit all-ones pattern is
255 as unsigned u8 and -1 as signed i8. That is the distinction used in the Z3
bitcast rule below.

`BUFFER` identifies storage; `PARAM` is a placeholder supplied by a caller.
GLOBAL storage survives between kernel launches. LOCAL storage is shared by a
GPU workgroup, and REG denotes register storage within kernel execution.
ALU-space scalar parameters carry values such as a symbolic dimension. Here
ALU means arithmetic/logic operation, not a separately allocated tensor buffer.
An `INDEX` forms an address; `LOAD` and `STORE` use that address. A **gate** is a
bool deciding whether that memory access happens. `Invalid` is an internal marker
for “no valid element here,” not the value false or the address zero.

## How to read the specifications

`spec_tensor`, `spec_program`, and `spec_hcq` prepend their rules to
`spec_shared`. `spec_full` puts permissive intermediate rules first, then tensor,
program, and HCQ rules. It is therefore **not the conjunction of their checks**:
a tensor rule that accepts a node can prevent a program rejection from running.
`spec_kernel_graph` is an independent whitelist, not `spec_shared` plus additions.

`matches_dtype(value, wanted)` accepts an exact dtype or an `Invalid` base;
`Invalid` is a sentinel, not a boolean data value, even though its derived dtype
is bool. Weak integer/float values carry an unresolved width. New `CONST`s
normally derive weak types; a concrete typed constant is `CAST(CONST(value))`.
`UPat(..., src=())` means zero sources; a source tuple means exact arity unless
`allow_any_len=True`; a single repeated `UPat` applies to **every** source.
`or_casted`, `or_bitcasted`, and `or_after` add one optional wrapper, not arbitrary
recursive peeling. `arg=None` in a UPat means no argument restriction.

**Arity** means the number of sources; a **leaf** has none. A check over “all
sources” succeeds for an empty source list unless another condition requires a
source to exist. That is what **vacuously** means in the entries below. A matcher
**whitelist** accepts only the listed forms. Rules run in order, stopping at the
first non-None result, so a permissive acceptance placed early can bypass a
stricter check later. The stage-specific rule sets make that ordering part of
the contract.

The memory helper [`validate_index`](../../../../tinygrad/tinygrad/uop/spec.py#L10)
accepts nonfinal addresses with source count other than two, an entirely invalid
index, disabled `CHECK_OOB`, and **IMAGE-shaped buffers** without a bounds proof.
Otherwise it first tries `0 <= idx.vmin <= idx.vmax < buffer.max_numel()`; if that
cannot prove safety, it asks Z3 whether an active out-of-bounds access exists.
A gate can prove an otherwise dangerous index safe. Integer overflow is explicitly
not checked. Thus “accepted” below means this implementation's check passed,
not that memory safety was comprehensively proved. The IMAGE bypass is relevant
to the GPU/IMAGE chapter: it is a validation gap, not evidence that arbitrary
texture coordinates are safe.

## `spec_shared`: forms shared across graph stages

### uop/spec.py:L44 — SINK is a permissive root

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L44). **Match/result:** Any void `SINK` returns `True`.

**Example:** `SINK(STORE(...))` and even `SINK(ADD(...))` are accepted by this rule; an `ADD` root is not accepted by this rule.

SINK gathers outputs/effects into one root for traversal. A permissive container lets tests examine unusual graphs while leaving each contained node responsible for passing its own check.

**Why:** Source: tests are allowed to put anything in sinks. A root container should not impose a particular number of outputs.

**Sharp edge:** Its children still need their own successful checks in `type_verify`; accepting a sink does not bless its subgraph.

### uop/spec.py:L47 — NOOP is temporarily legal

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L47). **Match/result:** Any `NOOP` returns `True`, with no source or argument restrictions.

**Example:** `NOOP()` is accepted; `REWRITE_ERROR("bad")` does not match.

**Why:** Source: a TODO says to remove this rule; it accommodates a currently used placeholder.

**Sharp edge:** There is no useful structural validation here, and NOOP can survive a spec check without doing work.

### uop/spec.py:L50 — Constants carry a canonical Python value

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L50). **Match/result:** A source-free `CONST` returns `True` for `Invalid`, or when its value has exactly the Python type produced by `dtype.const(value)`.

**Example:** `CONST(3)`, `CONST(3.0)`, `CONST(True)`, and `CONST(Invalid)` are accepted; `CONST(3, src=(x,))` is not.

**Why:** Inference: Python bool is an int subclass, so exact type equality prevents silently conflating scalar kinds.

**Sharp edge:** This checks Python type, not every numeric range property; dtype inference may reject malformed constants earlier.

### uop/spec.py:L53 — Empty STACK is void

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L53). **Match/result:** A void `STACK` with zero sources returns `True`.

**Example:** `STACK()` is accepted; a nonempty float stack uses the next rule instead.

**Why:** Inference: the empty shape/vector needs an identity representation without inventing an element dtype.

**Sharp edge:** This is a distinct zero-element case, not an arbitrary void vector.

### uop/spec.py:L54 — Nonempty STACK has uniform shape and compatible elements

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L54). **Match/result:** A `STACK` with at least one source returns whether every source has the same shape and matches the stack dtype or is weak.

**Example:** `STACK(f32(a), f32(b))` for equally shaped a/b passes; stacking shape `(2,)` and shape `(3,)` fails.

If a and b each have shape `(2,)`, stacking them creates two rows with matching lengths. Shape `(2,)` beside `(3,)` would create a ragged object instead of a regular tensor, which this operation does not represent.

**Why:** Inference: stacking creates one regular higher-dimensional value; inconsistent element shapes cannot define it.

**Sharp edge:** A weak operand or Invalid can pass before widths are settled; this is not a check that final machine lanes already agree.

### uop/spec.py:L59 — WHERE selects values of one type

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L59). **Match/result:** Three-source `WHERE` with bool condition returns whether both branches match its result dtype, allowing weak branches.

**Example:** `WHERE(bool(c), f32(x), 0.0_weak)` passes; `WHERE(bool(c), i32(x), f32(y))` fails when promotion makes the result f32 but x remains strong i32.

A WHERE result must have one representation regardless of which branch wins. A weak zero can adopt the other branch’s representation; two conflicting concrete types require an explicit conversion somewhere in the graph.

**Why:** Inference: selection chooses existing representations; implicit conversion must be expressed or deferred only for weak values.

**Sharp edge:** The gate is not checked for shape compatibility here; invalid gate dtypes can fail during UOp construction first.

### uop/spec.py:L61 — Comparisons produce bool but compare compatible operands

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L61). **Match/result:** `CMPLT`, `CMPNE`, or `CMPEQ` with bool result and exactly two operands returns whether their types agree, either base is Invalid, or either dtype is weak.

**Example:** `CMPLT(i32(x), i32(y))` passes; `CMPEQ(i32(x), f32(y))` fails; `CMPNE(i32(x), 0_weak)` passes.

**Why:** Inference: the result bool cannot be used as the required operand dtype, unlike ordinary ALUs.

**Sharp edge:** Acceptance with one weak side does not decide the eventual comparison width.

### uop/spec.py:L63 — Reject floating bitwise operations before generic ALU acceptance

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L63). **Match/result:** For `AND`, `OR`, `XOR`, `SHL`, or `SHR`, returns `False` if any source is floating; otherwise `None`.

**Example:** `AND(f32(x), f32(y))` is rejected; `XOR(i32(x), i32(y))` falls through to normal typing. The same rejection applies to float shift data/counts.

**Why:** Inference: matching float operand/result types alone would incorrectly admit bitwise arithmetic.

**Sharp edge:** Integer inputs are not accepted by this rule; another rule must validate them. Float shifts can already fail dtype derivation.

### uop/spec.py:L64 — Allow renderer-specific unsigned shift counts

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L64). **Match/result:** Two-source `SHL`/`SHR` returns whether the count matches the result dtype, is uint32 or weakint, or the left operand has an Invalid base.

**Example:** `SHL(i64(x), u32(3))` passes; `SHR(i64(x), i16(c))` fails.

For `x << 3`, x determines the bit pattern being shifted and the result width; 3 only counts positions. Some backends require this count to be u32 even when x is i64, which is why exact source-type equality would be too strict.

**Why:** Source: renderer-lowered shifts may use uint32 counts. Shift result width follows the left input, not count width.

**Sharp edge:** This says nothing about a negative or oversized count; type validity is not shift-domain validity.

### uop/spec.py:L66 — Integer division and remainders reject float results

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L66). **Match/result:** For `CDIV`, `CMOD`, `FLOORDIV`, `FLOORMOD`, returns `None` when the result is integer or any input is Invalid, otherwise `False`.

**Example:** `CDIV(f32(x), f32(y))` fails; `FLOORMOD(i32(x), i32(y))` proceeds to generic ALU typing.

The difference appears with negative numbers: `CDIV(-7,3)=-2` truncates toward zero, while `FLOORDIV(-7,3)=-3` rounds downward. Their remainders must follow the matching division convention.

**Why:** Inference: truncating/floor integer operations must not masquerade as floating arithmetic.

**Sharp edge:** No nonzero-divisor proof; CDIV/CMOD and FLOORDIV/FLOORMOD have different signed semantics despite sharing this typing rule.

### uop/spec.py:L68 — Generic ALUs require compatible operand types

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L68). **Match/result:** For every ALU opcode, returns whether each source matches the result type or is weak; earlier special cases handle comparisons, WHERE, shifts, and prohibited domains.

**Example:** `ADD(f32(x), f32(y))` passes; `MUL(f32(x), i32(y))` fails without an explicit cast. `NEG(f32(x))` passes.

**Why:** Inference: a backend should receive explicit conversions instead of accidentally depending on C or ISA promotion.

**Sharp edge:** This does not validate operation arity or mathematical domains. ALU includes unary SIN/EXP2/LOG2/SQRT/RECIPROCAL/NEG/TRUNC, binary arithmetic/comparisons/bitwise/THREEFRY, and WHERE/MULACC.

### uop/spec.py:L71 — CAST and BITCAST state a DType

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L71). **Match/result:** Unary `CAST`/`BITCAST` returns whether `arg` is a `DType`.

**Example:** `CAST_i32(f32(x))` and `BITCAST_u32(f32(x))` pass; either with two sources does not match.

Casting float 1.0 to an integer asks for the number 1. Bitcasting its float32 bits to u32 asks for the integer encoded by that same bit pattern. Both need a destination DType, but that shared metadata requirement does not make their meanings interchangeable.

**Why:** Inference: the target type is metadata, not a graph input; the conversion cannot be rendered without it.

**Sharp edge:** This rule does not prove equal byte sizes for BITCAST; malformed dtype arguments may fail construction first.

### uop/spec.py:L74 — RANGE identifies axes and axis kind

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L74). **Match/result:** A RANGE with at least one source requires tuple arg of length at least two, integer entries except for a final `AxisType`.

**Example:** `RANGE(bound, arg=(0, AxisType.REDUCE))` passes; `arg=("row", AxisType.REDUCE)` or `(0, "reduce")` fails.

An axis identifier names which loop/index dimension this RANGE represents. Its AxisType describes the role, such as a reduction loop. Names and roles are bookkeeping separate from the numeric upper bound supplied as an input.

**Why:** Source: RANGE also exists in the big graph; a void RANGE can serve as a boundless loop header.

**Sharp edge:** This checks identifier structure, not bound dtype/positivity or uniqueness; extra integer axis identifiers are allowed.

### uop/spec.py:L76 — INDEX coordinates must be integer-like

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L76). **Match/result:** An INDEX returns `True` when it has at least one source and every coordinate after the base has integer dtype or Invalid base; otherwise `None`.

**Example:** `INDEX(buf, i32(7))` passes; `INDEX(buf, f32(1.5))` is declined.

**Why:** Inference: memory coordinates cannot depend on floating pointer arithmetic without explicit conversion.

**Sharp edge:** A base-only INDEX passes vacuously; this rule does not run bounds checking—LOAD/STORE rules do that.

### uop/spec.py:L78 — END closes a list of ranges

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L78). **Match/result:** An END with at least one source returns `True` if all trailing sources are RANGE nodes, otherwise `None`.

**Example:** `END(value, r0, r1)` passes; `END(value, ADD(i,j))` is declined.

**Why:** Source: END closes RANGEs, recording which loop scopes finish after a value/effect.

**Sharp edge:** `END(value)` passes vacuously; the intermediate full spec accepts more forms, and the next rule handles conditional loops.

### uop/spec.py:L80 — END of a boundless loop carries a backedge condition

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L80). **Match/result:** Exactly `END(value, void_RANGE, bool_condition)` returns `True`.

**Example:** `END(store, RANGE(NOOP), bool(again))` passes; the same END with i32 condition does not match.

**Why:** Source: the trailing bool says to loop again while true.

**Sharp edge:** This must follow the normal END rule because a bool is not a RANGE; it validates structure, not loop termination.

### uop/spec.py:L83 — PARAM declares its metadata without shape inputs

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L83). **Match/result:** A source-free PARAM returns whether `arg` is `ParamArg`.

**Example:** `PARAM(ParamArg(...))` passes; a PARAM with a shape UOp as source does not match.

**Why:** Source: PARAM/BUFFER sizes live in the argument, not a shape input.

**Sharp edge:** It does not constrain PARAM address space here; ParamArg constructor and dtype derivation supply additional invariants.

### uop/spec.py:L84 — Shared BUFFER admits registers and local storage

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L84). **Match/result:** A source-free BUFFER requires ParamArg and REG or LOCAL address space.

**Example:** A local scratch allocation and a register accumulator buffer pass; a GLOBAL BUFFER returns `False` in this shared rule.

A kernel may declare scratch storage it uses internally. Long-lived global arrays are allocated outside that kernel and passed in; they are represented differently at this stage.

**Why:** Inference: the shared program-level graph can allocate kernel-local storage but cannot allocate host/device-global storage inside a kernel.

**Sharp edge:** Tensor spec prepends a global-buffer rule; checking a tensor buffer against only spec_shared gives a different answer.

### uop/spec.py:L87 — GROUP contains effect-like nodes

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L87). **Match/result:** A void GROUP returns `True` when every source is GROUP, STORE, NOOP, INS, or END.

**Example:** `GROUP(STORE(...), END(...))` passes; `GROUP(ADD(x,y))` does not match.

**Why:** Source: GROUP groups stores; INS and END extend this to instructions and completed control scopes.

**Sharp edge:** A zero-source GROUP is allowed by the repeated-source pattern; ordering still comes from graph dependencies.

### uop/spec.py:L90 — AFTER forwards an address/view plus dependencies

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L90). **Match/result:** An AFTER with first source a movement op, PARAM, BUFFER, COPY, INDEX, AFTER, UNSHARD, BITCAST, or INS and any trailing sources returns `True`.

**Example:** `AFTER(PARAM, STORE(...))` passes; `AFTER(ADD(x,y), STORE(...))` is declined here.

The first source supplies the value/address seen by users; trailing sources keep effects alive and ordered. They are dependencies, not additional numeric operands to combine with the value.

**Why:** Inference: AFTER is an ordering wrapper around a value/storage identity, not ordinary arithmetic sequencing.

**Sharp edge:** Trailing dependencies are unrestricted by this rule. The comment lists some stale op names; the actual set in the pattern is authoritative.

### uop/spec.py:L95 — CUSTOM and CUSTOMI carry code plus result type

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L95). **Match/result:** CUSTOM/CUSTOMI require a two-element tuple `(str, DType)` and return the corresponding bool.

**Example:** `CUSTOMI(("f($0)", f32), x)` passes; `(17, f32)` fails.

**Why:** Source: inline/non-inline source text states the dtype it produces; void means a bare statement.

**Sharp edge:** No source-language parsing, placeholder/arity validation, or safety check occurs here.

### uop/spec.py:L99 — External function body names are strings

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L99). **Match/result:** Any CUSTOM_FUNCTION requires string arg, regardless of its source count.

**Example:** `CUSTOM_FUNCTION("external_fn", fn_pointer)` passes; integer arg fails.

**Why:** Source: sources may hold a callee/function pointer for an external-call body.

**Sharp edge:** It does not check pointer type or external ABI; a string is enough for this rule.

### uop/spec.py:L101 — CALL pairs an opaque body with CallInfo

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L101). **Match/result:** CALL must start with an opcode from OPAQUE_CALL_BODIES, have any additional arguments, and carry CallInfo whose dtype is identical to x.dtype.

**Example:** `CALL(PROGRAM(...), args..., arg=CallInfo(...))` passes; `CALL(ADD(x,y), ...)` does not match.

“Opaque” means this caller treats the body as a unit rather than ordinary arithmetic to traverse and fuse freely. CallInfo describes the call, but this particular rule does not establish that each argument agrees with the function’s expected inputs.

**Why:** Source: CALL bodies are opaque and the CallInfo states the possibly void result type.

**Sharp edge:** Does not compare actual arguments with callee parameters. The body set is SINK, PROGRAM, LINEAR, COPY, and CUSTOM_FUNCTION; none of these implies argument ABI verification.

### uop/spec.py:L105 — PYLITERAL is accepted for the pattern compiler

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L105). **Match/result:** Every PYLITERAL returns `True`.

**Example:** `PYLITERAL(arg="field")` passes; an ordinary CONST is handled elsewhere.

**Why:** Source: this is pattern-compiler IR, not intended as a tensor/program node, but is spec-compliant.

**Sharp edge:** Its placement in shared means a spec alone does not enforce that intended phase restriction.

### uop/spec.py:L108 — BARRIER accepts arbitrary dependency sources

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L108). **Match/result:** Any void BARRIER returns `True`.

**Example:** `BARRIER(store0, store1)` passes; it imposes no condition that the sources are local stores.

**Why:** Source: it is accepted at any length, with a TODO to move it to spec_program.

**Sharp edge:** Tensor-stage acceptance does not imply a device supports the requested synchronization semantics.

### uop/spec.py:L111 — INS states instruction payload and result type

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L111). **Match/result:** INS requires a two-element tuple whose second element is DType.

**Example:** `INS((instruction, f32), inputs...)` passes; a three-element arg tuple fails.

**Why:** Source: this represents an assembly instruction; explicit result typing lets instruction IR compose with UOps.

**Sharp edge:** The instruction object itself is unchecked, so this is not ISA operand verification.

### uop/spec.py:L114 — Ungated indexed LOAD checks bounds

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L114). **Match/result:** LOAD of an INDEX or SHRINK, optionally under one CAST, calls validate_index and returns its bool.

**Example:** Loading `buf16[7]` passes; loading `buf16[16]` fails when CHECK_OOB is enabled and the helper reaches a proof.

An address expression can be formed without reading memory. Checking at LOAD ties the proof to the point where an actual read is requested, including any gate on that read.

**Why:** Inference: attaching the check to the memory effect avoids rejecting addresses which are constructed but never dereferenced.

**Sharp edge:** A SHRINK normally has three sources and is skipped by the helper; IMAGE and disabled checking also bypass proof.

### uop/spec.py:L115 — Gated LOAD validates the fallback and active address

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L115). **Match/result:** Three-source LOAD(address, alternate, bool_gate), with INDEX/SHRINK optionally casted, returns False for incompatible alternate dtype; otherwise validate_index(address, gate).

**Example:** For i in `[0,31]`, `LOAD(buf16[i], f32(0), i<16)` can pass; a strong i32 fallback for an f32 load fails.

Lanes 16 through 31 calculate indices too, but their gate is false. They must return the fallback 0 rather than read beyond the buffer; both the gate and the fallback type are therefore part of validating the load.

**Why:** Inference: an inactive load must produce a representable fallback while only active lanes require in-bounds addresses.

**Sharp edge:** matches_dtype permits Invalid fallback bases; this helper does not independently establish a valid eventual machine fallback.

### uop/spec.py:L117 — Ungated indexed STORE checks bounds

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L117). **Match/result:** STORE(address, value) of INDEX/SHRINK optionally casted returns validate_index(address).

**Example:** `STORE(buf16[15], x)` passes; `STORE(buf16[16], x)` fails under active bounds checking.

**Why:** Inference: writes need the same address safety check as reads.

**Sharp edge:** The stored value dtype is unrestricted by this rule; do not mistake bounds validation for full store type validation.

### uop/spec.py:L118 — Gated STORE checks only active lanes

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L118). **Match/result:** STORE(address, value, bool_gate) of INDEX/SHRINK optionally casted returns validate_index(address, gate).

**Example:** `STORE(buf16[i], x, i<16)` with i in `[0,31]` passes; changing the gate to `i<=16` exposes an out-of-bounds witness at 16.

At i=16, the proposed `i<=16` gate is true while the index is outside `[0,15]`. That concrete assignment is the witness explaining rejection. A false gate means no write occurs at that index.

**Why:** Inference: masked writes may compute invalid inactive coordinates without performing those writes.

**Sharp edge:** An always-false gate makes the proof vacuous; IMAGE and nonfinal-address bypasses still apply.

### uop/spec.py:L122 — Whole-target STORE requires storage identity

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L122). **Match/result:** A two-source void STORE looks through target.storage_base: BUFFER/PARAM/COPY yields True, INDEX yields None, anything else False.

**Example:** `STORE(PARAM, value)` passes; `STORE(ADD(x,y), value)` fails; an indexed target is reserved for indexed-memory validation.

**Why:** Source: target must denote writable storage, including supported wrappers/views, rather than an arbitrary computed value.

**Sharp edge:** The adjacent comment still mentions CONTIGUOUS, absent as an opcode in this snapshot. This predicate does not check value shape or dtype.

### uop/spec.py:L126 — WMMA has operands and four metadata fields

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L126). **Match/result:** Exactly WMMA(a,b,acc) requires a tuple arg of length four.

**Example:** A tensor-core operation with three operands and four metadata fields passes; missing accumulator or three metadata fields does not.

WMMA represents a matrix multiply-accumulate tile operation: the result combines `a*b` with acc. Counting three inputs checks the outer form; validating that their distributed hardware layouts fit together requires more information.

**Why:** Source: WMMA has a, b, and accumulator inputs. Inference: layout/device-specific details are validated outside this generic shape check.

**Sharp edge:** No matrix tile compatibility, supported chip instruction, or operand precision check is performed.

## `spec_tensor`: tensor and compilation-container rules

### uop/spec.py:L133 — Floating transcendental domain

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L133). **Match/result:** Unary SIN/LOG2/EXP2/SQRT/RECIPROCAL returns whether the derived result is float or the input base is Invalid.

**Example:** `SQRT(f32(x))` and `EXP2(i32(x))` pass because EXP2 derives a floating result; `SIN(Invalid)` also passes. A two-source SQRT does not match.

**Why:** Inference: these operations have floating semantics, even when an integer input is promoted to a float result.

**Sharp edge:** This validates the result type, not that the argument is positive for LOG2/SQRT. Tensor ordering gives this rule priority over shared generic ALU typing.

### uop/spec.py:L137 — Tensor BUFFER may own global storage or declare it

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L137). **Match/result:** Source-free BUFFER returns True immediately when is_unbound; otherwise a GLOBAL ParamArg requires DType, integer size, and a device string or tuple of strings; other address spaces decline.

**Example:** An unbound GLOBAL temporary passes; a realized GLOBAL buffer with device `"CPU"` passes; a realized one with device 12 fails.

**Why:** Inference: tensors name external allocations and scheduler output declarations, unlike local program buffers.

**Sharp edge:** The is_unbound early accept bypasses the later device/size checks; it means GLOBAL storage with arg.buffer=None, not a symbolic variable.

### uop/spec.py:L142 — A symbolic scalar variable has no device

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L142). **Match/result:** A source-free BUFFER that is_variable returns whether arg.device is None; other buffers decline.

**Example:** An ALU-space scalar BUFFER carrying bounds `[1,128]` and device=None passes; giving the variable a device string fails.

A symbolic dimension such as n is a scalar whose eventual value is supplied later. It needs bounds for reasoning but no tensor allocation on a device, hence the ALU address space and absent device.

**Why:** Source: a Variable is a zero-dimensional ALU BUFFER with value bounds and no device.

**Sharp edge:** is_variable requires BUFFER, ParamArg, vmin_vmax, ALU space, and scalar shape. An ALU PARAM is not is_variable here.

### uop/spec.py:L145 — Tensor CUSTOM_FUNCTION names remain strings

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L145). **Match/result:** CUSTOM_FUNCTION returns isinstance(arg, str).

**Example:** `CUSTOM_FUNCTION("rmsnorm_external")` passes; a bytes name fails.

**Why:** Inference: tensor graphs can carry custom external-call bodies before lowering.

**Sharp edge:** This repeats the shared validator; the tensor-specific copy does not add signature checking.

### uop/spec.py:L148 — Pre-lowering SPECIAL has a weak bound

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L148). **Match/result:** SPECIAL with exactly one weakint source requires a string arg.

**Example:** `SPECIAL(CONST(128), arg="lidx0")` passes; an integer-valued name fails; a concrete i32 bound does not match this tensor rule.

**Why:** Source: SPECIAL is an index before index lowering, currently used by custom_kernel.

**Sharp edge:** The name is not parsed to prove it names a supported launch dimension.

### uop/spec.py:L151 — RESHAPE and EXPAND carry shape as an input

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L151). **Match/result:** Exactly RESHAPE(value, shape) or EXPAND(value, shape) returns True.

**Example:** `RESHAPE(x, STACK(2,8))` and `EXPAND(x, STACK(4,8))` match; a missing shape source does not.

A shape can contain a symbolic dimension n, so representing it as graph inputs lets the compiler track that dependency. The existence of the shape input alone says nothing about whether the requested reshape is mathematically valid.

**Why:** Inference: shape expressions now live in the UOp graph and can be symbolic.

**Sharp edge:** The rule does not check element-count preservation for reshape or broadcasting legality for expand.

### uop/spec.py:L152 — PAD and SHRINK have equally shaped bounds

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L152). **Match/result:** Three-source PAD/SHRINK returns whether the second and third source shapes agree.

**Example:** For a rank-two value, two length-two bound stacks pass; a length-two lower stack and length-one upper stack fail.

**Why:** Inference: paired beginning/end or padding values need corresponding axis entries.

**Sharp edge:** Equal bound-vector shape does not guarantee legal numeric bounds or even agreement with the value rank.

### uop/spec.py:L153 — PERMUTE and FLIP use tuple metadata

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L153). **Match/result:** Unary PERMUTE/FLIP returns whether arg is tuple.

**Example:** `PERMUTE(x, arg=(1,0))` or `FLIP(x, arg=(True,False))` passes; list metadata fails.

**Why:** Inference: immutable axis metadata can be hashed and shared with the UOp.

**Sharp edge:** Does not verify permutation uniqueness, axis count, or that FLIP tuple elements are bool.

### uop/spec.py:L156 — REDUCE names an associative reduction and axes

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L156). **Match/result:** REDUCE with at least one source requires arg `(op, num_axes)`, op ADD/MUL/MAX, integer axis count, and trailing sources weakint or int32.

**Example:** `REDUCE(x, r_i32, arg=(ADD,1))` passes; `(SUB,1)` or an i64 range fails.

ADD, MUL, and MAX combine a sequence using the same repeated operation; this is the structure meant by a reduction monoid. Floating-point implementations still have rounding-sensitive order, so accepting ADD here does not promise bitwise equality for arbitrary reassociation.

**Why:** Source: after lowering, trailing inputs are reduction ranges. Inference: only supported reduction monoids are admitted.

**Sharp edge:** No check that num_axes is nonnegative or equals the number of range sources; trailing integers need not literally be RANGE nodes.

### uop/spec.py:L161 — COPY destination is a device descriptor

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L161). **Match/result:** Unary COPY requires a device string or tuple of strings.

**Example:** `COPY(x, arg="AMD:0")` and destination `("AMD:0","AMD:1")` pass; arg 0 fails.

**Why:** Inference: a transfer target is device metadata, not arithmetic.

**Sharp edge:** is_device accepts empty tuples and arbitrary strings, without checking device existence.

### uop/spec.py:L162 — ALLREDUCE specifies reduction plus participating devices

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L162). **Match/result:** Unary ALLREDUCE requires a two-element tuple, ADD/MUL/MAX first, and device descriptor second.

**Example:** `ALLREDUCE(x, (ADD,("AMD:0","AMD:1")))` passes; `(SUB,(...))` fails.

**Why:** Inference: communication must know both how to combine values and where it operates.

**Sharp edge:** This does not validate distributed shapes, communicator construction, or hardware collective support.

### uop/spec.py:L167 — UNSHARD carries one range per sharded axis

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L167). **Match/result:** UNSHARD requires source count `1+len(arg)`, integer axis metadata, and weak-typed trailing range expressions.

**Example:** `UNSHARD(x, r_weakint, arg=(0,))` passes; the same with no range or an i32 range fails.

Sharding splits a tensor across devices. The extra expressions say which per-device piece belongs along each sharded axis, so there must be one such expression per axis named in arg.

**Why:** Source: each sharded axis has a sharding range, usually a DEVICE RANGE but potentially a derived expression.

**Sharp edge:** Both weakint and weakfloat satisfy the actual dtype test; do not read this as an integer-only range verifier.

### uop/spec.py:L169 — MSELECT selects one device from a multi-device value

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L169). **Match/result:** Returns whether the first source device is tuple and arg is less than its length.

**Example:** Selecting index 1 from devices `(AMD:0, AMD:1)` passes; index 2 fails.

**Why:** Inference: a device selection must name an available shard.

**Sharp edge:** The predicate does not check `arg>=0`, source arity, or integer arg type; malformed inputs may throw rather than return False.

### uop/spec.py:L170 — MSTACK combines per-device or repeated device-free values

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L170). **Match/result:** Returns True when each source has string device, or all sources are identical and their device is None.

**Example:** Stacking an AMD:0 value and AMD:1 value passes; stacking the identical symbolic scalar twice also passes; distinct device-free scalar sources fail.

**Why:** Inference: distributed values usually combine concrete device-local pieces, with a scalar broadcast exception.

**Sharp edge:** No uniqueness check on devices. An empty source list passes the first all() vacuously.

### uop/spec.py:L173 — DETACH and CONTIGUOUS_BACKWARD are unary markers

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L173). **Match/result:** Unary DETACH/CONTIGUOUS_BACKWARD returns True.

**Example:** `DETACH(x)` and `CONTIGUOUS_BACKWARD(x)` pass; either with two inputs does not match.

**Why:** Inference: these mark gradient/scheduling behavior while forwarding a value.

**Sharp edge:** Although the pattern spells arg=None, that means unrestricted arg in UPat, not an explicit None check.

### uop/spec.py:L176 — STAGE is accepted before buffer realization

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L176). **Match/result:** STAGE with at least one input returns True.

**Example:** `STAGE(value)` or `STAGE(value, extra_dependency)` passes; zero inputs do not match.

**Why:** Source: a TODO says this should not be here; STAGE transforms into BUFFER later.

**Sharp edge:** Acceptance is a transitional allowance, not proof that a backend can emit STAGE.

### uop/spec.py:L179 — LINEAR contains the emitted instruction order

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L179). **Match/result:** Any void LINEAR returns True.

**Example:** `LINEAR(load, add, store)` passes; no source order checks are performed.

**Why:** Source: PROGRAM progressively accumulates lowered representations. Inference: LINEAR packages a schedule for rendering.

**Sharp edge:** This rule does not prove dependency order, balanced loops, or instruction legality.

### uop/spec.py:L180 — SOURCE is a leaf compilation artifact

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L180). **Match/result:** A source-free void SOURCE returns True.

**Example:** `SOURCE(arg="kernel source text")` passes; SOURCE with a source UOp does not match.

**Why:** Inference: generated source is an artifact, not a tensor dependency expression.

**Sharp edge:** No string type check despite the name; the UOp comment describes a string but this rule only checks structure.

### uop/spec.py:L181 — BINARY contains bytes

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L181). **Match/result:** A source-free uint8 BINARY returns isinstance(arg, bytes).

**Example:** `BINARY(arg=b"compiled object")` passes; a str or bytearray fails.

Generated code progresses from a graph to text and then to compiled bytes. Requiring immutable bytes gives the loader a binary payload; it cannot establish that the payload is executable on the chosen chip.

**Why:** Inference: compiled code must be an immutable binary payload usable by program loading and caching.

**Sharp edge:** It does not validate an ELF header, instruction set, or device compatibility.

### uop/spec.py:L182 — PROGRAM before linearization

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L182). **Match/result:** Exactly PROGRAM(SINK) returns True.

**Example:** `PROGRAM(SINK(...))` passes; PROGRAM(SOURCE) does not.

**Why:** Source: the first progressive program representation is its kernel SINK.

**Sharp edge:** A SINK child still needs validation; PROGRAM acceptance does not validate a complete compilable kernel.

### uop/spec.py:L183 — PROGRAM after linearization

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L183). **Match/result:** Exactly PROGRAM(SINK, LINEAR) returns True.

**Example:** `PROGRAM(sink, linear)` passes; swapping the sources does not.

**Why:** Source: compilation appends LINEAR while retaining SINK. Inference: retained stages support metadata/debugging.

**Sharp edge:** Does not prove LINEAR was derived from this particular SINK.

### uop/spec.py:L184 — PROGRAM after rendering

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L184). **Match/result:** Exactly PROGRAM(SINK, LINEAR, SOURCE) returns True.

**Example:** `PROGRAM(sink, linear, source)` passes; BINARY in the third position does not.

**Why:** Source: rendered source is the next appended compilation stage.

**Sharp edge:** This checks artifact order, not equivalence between source text and UOps.

### uop/spec.py:L185 — PROGRAM after compilation

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L185). **Match/result:** Exactly PROGRAM(SINK, LINEAR, SOURCE, BINARY) returns True.

**Example:** `PROGRAM(sink, linear, source, binary)` passes; a fifth artifact does not match.

**Why:** Source: BINARY is the final listed progressive stage.

**Sharp edge:** It does not establish that the bytes were compiled from the accompanying source.

## `spec_program`: final typed program boundaries

### uop/spec.py:L191 — Bare constants may appear only under CAST

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L191). **Match/result:** Every opcode is inspected: returns False if a non-CAST has any direct CONST source, otherwise None.

**Example:** `ADD(i32(x), CONST(1))` is rejected; `ADD(i32(x), CAST_i32(CONST(1)))` proceeds to later rules.

The underlying literal answers “which number?” and its CAST edge answers “in which machine representation?” This rule forces that second answer to be visible before code emission.

**Why:** Source: every width in a program must be stated; the CONST/CAST pair makes scalar bit width explicit.

**Sharp edge:** Even boolean constants need an explicit CAST edge here. This rule must run before permissive shared validators.

### uop/spec.py:L192 — Unresolved weak nodes cannot survive in programs

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L192). **Match/result:** Any weakint/weakfloat node except CONST returns False.

**Example:** A weakint RANGE or ADD is rejected; a weak CONST itself is exempt, provided each consumer satisfies the preceding CAST-edge rule.

**Why:** Source: CONST is the only remaining weak node in final programs.

**Sharp edge:** This rejects CAST-to-weak too; choosing a concrete machine width is a required lowering step.

### uop/spec.py:L195 — SHRINK has a special final-program address form

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L195). **Match/result:** Exactly SHRINK(base, offset, constant_length), where base is PARAM/BUFFER/AFTER optionally BITCASTed and length is CONST optionally CASTed, returns True.

**Example:** `SHRINK(PARAM, i32(offset), CAST_i32(CONST(4)))` passes; a dynamic ADD as length does not match.

At this stage SHRINK denotes a narrow address/slice form, not a general tensor slice. Its special acceptance must precede the broad movement rejection so that the final program can retain this useful address representation.

**Why:** Source: special SHRINK of buffer or bitcast is allowed. Inference: this retains a static address/vector slice without retaining general tensor movement.

**Sharp edge:** Runs before general movement rejection, but after bare-constant rejection; a bare length CONST fails in the composed spec despite matching this pattern in isolation.

### uop/spec.py:L198 — Reject tensor movement that escaped lowering

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L198). **Match/result:** Any RESHAPE/EXPAND/PERMUTE/PAD/SHRINK/FLIP returns False.

**Example:** `PERMUTE(x, (1,0))` is rejected in a program; the narrowly allowed SHRINK above can already have returned True.

For a transposed tensor, a final load must calculate the transposed address. It should no longer ask the backend to interpret a high-level PERMUTE node; lowering has to turn that indexing meaning into address arithmetic first.

**Why:** Source: movement operations are not allowed in programs. Inference: indexing must embody their effect by code emission time.

**Sharp edge:** Rule order is the only reason static address SHRINK survives; moving this rule earlier would break it.

### uop/spec.py:L201 — A program BUFFER allocates only REG or LOCAL

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L201). **Match/result:** Any BUFFER requires ParamArg and REG or LOCAL address space.

**Example:** A LOCAL reduction scratch buffer passes; a GLOBAL buffer fails.

**Why:** Inference: a final kernel accesses externally allocated global storage through PARAM and only declares internal allocations itself.

**Sharp edge:** Unlike the shared BUFFER pattern, this pattern does not require zero sources; it only checks metadata/address space.

### uop/spec.py:L204 — Invalid sentinel must have become control flow

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L204). **Match/result:** CONST with arg Invalid returns False.

**Example:** `CONST(Invalid)` is rejected; a normal CONST(0) goes on to the shared constant rule.

Invalid says an element should not be accessed. A device program needs an executable decision—skip the access or choose a fallback—rather than this compiler-only marker.

**Why:** Source: Invalid is not allowed in program. Inference: masked access semantics must have been lowered to gates/IFs/fallbacks.

**Sharp edge:** CONST(False) is ordinary bool data, not Invalid; the two are not interchangeable.

### uop/spec.py:L207 — IF carries gate and address identity

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L207). **Match/result:** Exactly void IF(bool_gate, CAST-or-INDEX-or-SHRINK) returns True.

**Example:** `IF(i<16, INDEX(buf,i))` passes; IF with only its gate does not.

**Why:** Source: the second source is index_for_dedup. Inference: address identity controls whether memory guards can share an IF region.

**Sharp edge:** No assertion that the address corresponds to every effect enclosed by this IF; topology/control-flow assembly matters too.

### uop/spec.py:L208 — ENDIF refers to its IF

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L208). **Match/result:** Exactly void ENDIF(IF_node) returns True.

**Example:** `ENDIF(the_if)` passes; `ENDIF(bool_gate)` does not match.

**Why:** Inference: an explicit reference identifies which control-flow region ends, rather than treating ENDIF as an unpaired punctuation token.

**Sharp edge:** Does not verify nesting or placement in LINEAR; a structurally paired ENDIF can still be badly scheduled.

### uop/spec.py:L211 — Final SPECIAL has a concrete int32 bound

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L211). **Match/result:** SPECIAL with one int32 source requires string arg.

**Example:** `SPECIAL(CAST_i32(CONST(128)), "lidx0")` passes; a weak bound is rejected by the earlier weak-node rule.

**Why:** Source: SPECIAL is int32 after index lowering. Inference: GPU launch coordinates need an actual backend integer width.

**Sharp edge:** The name and launch limit are not checked against hardware constraints.

## HCQ and permissive intermediate rules

### uop/spec.py:L215 — GETADDR extracts an HCQ address

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L215). **Match/result:** uint64 GETADDR of BUFFER/PARAM/SHRINK/BITCAST/MSTACK/MSELECT/LINEAR, optionally AFTER-wrapped, returns whether arg is a device descriptor.

**Example:** `GETADDR(AFTER(PARAM, dependency), arg="AMD:0")` passes; ADD as its base does not match.

HCQ means hardware command queue: the host/runtime builds commands telling a device what to run. Such a command needs a numeric address of storage or executable code; that address is different from the tensor value held there.

**Why:** Inference: queue commands need an address in a selected device address space, including addresses of loaded code/linear artifacts.

**Sharp edge:** No residency or alignment proof; uint64 is an address representation, not a promise of valid memory.

### uop/spec.py:L218 — HCQ PROGRAM can point at a buffer

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L218). **Match/result:** Exactly void PROGRAM of BUFFER/PARAM optionally AFTER-wrapped returns True.

**Example:** `PROGRAM(AFTER(BUFFER, upload))` passes; PROGRAM(ADD(...)) does not.

**Why:** Inference: a queue-level executable may be represented by its uploaded storage instead of the compiler-stage artifact chain.

**Sharp edge:** This is a different PROGRAM shape from spec_tensor, reflecting a different stage, not an alternative four-artifact layout.

### uop/spec.py:L223 — Intermediate REWRITE_ERROR carries a diagnostic

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L223). **Match/result:** Void REWRITE_ERROR returns whether arg is str.

**Example:** `REWRITE_ERROR("unsupported layout")` passes this spec; integer arg fails.

**Why:** Inference: an error marker must survive long enough to report a useful diagnostic through a rewrite pipeline.

**Sharp edge:** Passing the spec does not mean compilation succeeded; it only means the error representation is well-formed.

### uop/spec.py:L226 — Intermediate END tolerates replaced ranges

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L226). **Match/result:** END with at least two arbitrary sources returns True.

**Example:** `END(store, SPECIAL(...))` passes full spec; END(store) does not match this entry (but may match shared END).

A GPU mapping pass can replace an abstract loop index with a hardware lane/group index (SPECIAL). During that transition, an END may still refer to the replacement until control-flow cleanup finishes.

**Why:** Source: gpudims may have replaced RANGE with SPECIAL before codegen ends ranges.

**Sharp edge:** This deliberately weakens END validation; use the appropriate later-stage spec to catch leaked intermediate forms.

### uop/spec.py:L229 — Intermediate AFTER can wrap any value

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L229). **Match/result:** AFTER with at least one arbitrary source returns True.

**Example:** `AFTER(ADD(x,y), dependency)` passes full spec even though shared AFTER declines it.

**Why:** Source: allow any AFTER. Inference: transitional graph ordering temporarily needs wrappers beyond final storage identities.

**Sharp edge:** A one-source AFTER with no ordering dependencies is accepted too.

### uop/spec.py:L232 — Intermediate LOAD and STORE are unconditional allowances

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L232). **Match/result:** Any LOAD or STORE returns True.

**Example:** `STORE(arithmetic_value, x)` passes this particular full-spec rule; the strict shared storage-target rule would reject it.

A transitional graph can have memory nodes that are not yet in their final address form. This permissive rule lets that intermediate graph exist; it also explains why passing spec_full cannot substitute for final memory checks.

**Why:** Source: allow all loads/stores as intermediate ops. Inference: address formation and gate lowering are not complete yet.

**Sharp edge:** This bypasses shared memory shape and bounds checks in spec_full; full is broader, not stricter.

## `spec_kernel_graph`: host-side calls and buffer wiring

### uop/spec.py:L239 — Kernel graph SINK roots invocations

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L239). **Match/result:** Any void SINK returns True.

**Example:** `SINK(CALL(...), CALL(...))` passes; no minimum call count is required.

**Why:** Inference: the outer graph roots executable work and dependencies without becoming a device kernel itself.

**Sharp edge:** Children are separately verified; accepting SINK alone does not accept arbitrary arithmetic children.

### uop/spec.py:L241 — STORE binds a scalar variable

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L241). **Match/result:** Exactly void STORE(BUFFER, CONST) returns whether the BUFFER is_variable.

**Example:** `STORE(variable_n, CONST(64))` passes; storing a CONST into an ordinary GLOBAL BUFFER fails here.

**Why:** Source: AFTER(BUFFER, STORE(BUFFER, CONST)) binds a Variable in call arguments.

**Sharp edge:** This is scalar binding, not a blanket approval of tensor memory writes; it does not check that 64 lies within the declared bounds.

### uop/spec.py:L243 — Kernel graph accepts source-free constants

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L243). **Match/result:** Any source-free CONST returns True.

**Example:** `CONST(8)` passes; CONST with a source does not.

**Why:** Source: constants and stacks form vector constants and shape arguments.

**Sharp edge:** Less strict than shared constant validation; this rule does not exclude Invalid explicitly.

### uop/spec.py:L244 — Kernel graph preserves a casted constant

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L244). **Match/result:** CAST of a source-free CONST returns True.

**Example:** `CAST_f32(CONST(0.0))` passes; CAST of ADD does not match.

**Why:** Source: a zero-size or bound reduction keeps its constant casted. Inference: empty reductions can produce typed scalar results without launching arithmetic.

**Sharp edge:** This is not a general host-side cast operation; its source must be the leaf CONST.

### uop/spec.py:L245 — STACK collects scalar launch/shape arguments

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L245). **Match/result:** STACK returns True if every source is CONST, PARAM, a variable BUFFER, or a bound variable; otherwise None.

**Example:** `STACK(CONST(32), variable_n)` passes; `STACK(ADD(x,y))` is declined.

**Why:** Source: stacks make vector constants and shape arguments. Inference: launch metadata should be constants/parameters, not unlowered computation.

**Sharp edge:** A bound variable is specifically AFTER(var, STORE(var, CONST)); arbitrary AFTER is not a scalar binding. Empty STACK passes vacuously.

### uop/spec.py:L249 — Kernel graph PARAM declares outside storage

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L249). **Match/result:** Source-free PARAM requires ParamArg.

**Example:** A PARAM identifying an external input passes; PARAM with a shape source does not match.

**Why:** Source: PARAM is an outside buffer and stores size in metadata.

**Sharp edge:** Address space and argument aliasing are not checked here.

### uop/spec.py:L250 — Kernel graph BUFFER is GLOBAL storage or an ALU scalar

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L250). **Match/result:** BUFFER requires ParamArg and GLOBAL or ALU address space.

**Example:** A GLOBAL temporary and an ALU variable pass; a LOCAL scratch buffer fails.

The host graph connects whole kernel launches. A temporary array passed from one launch to another must outlive an individual workgroup, whereas LOCAL scratch belongs inside a launch.

**Why:** Inference: kernel graph nodes represent resources that exist between launches, not a kernel internal shared-memory allocation.

**Sharp edge:** This is the opposite stage boundary from spec_program BUFFER; passing one spec tells little about the other.

### uop/spec.py:L251 — Kernel graph permits BITCAST views

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L251). **Match/result:** Any BITCAST returns True.

**Example:** A BITCAST of an input buffer passes; no equal-size check is done here. A CAST of a non-CONST has no corresponding allowance.

**Why:** Inference: storage reinterpretation can be carried across calls without executing a numeric conversion kernel.

**Sharp edge:** Pattern does not constrain arity or source kind; constructor invariants and consumers provide additional checks.

### uop/spec.py:L253 — Kernel graph MSTACK assembles distributed arguments

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L253). **Match/result:** Requires all sources to have string devices, or identical sources with device None.

**Example:** Combining AMD:0 and AMD:1 buffers passes; two distinct device-free variables fail.

**Why:** Inference: multi-device call arguments preserve shard storage plus a repeated-scalar broadcast case.

**Sharp edge:** Same predicate as tensor MSTACK, including no check that devices are distinct and vacuous empty-list acceptance.

### uop/spec.py:L254 — Kernel graph MSELECT chooses a shard

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L254). **Match/result:** Requires tuple device on first source and arg smaller than the device count.

**Example:** Index 0 from a two-device MSTACK passes; index 2 fails.

**Why:** Inference: individual launches need a per-device argument extracted from distributed storage.

**Sharp edge:** As in the tensor rule, negative indices are not explicitly rejected and malformed structure may raise.

### uop/spec.py:L256 — Kernel graph CALL requires an opaque body

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L256). **Match/result:** CALL whose first source is in OPAQUE_CALL_BODIES returns True with arbitrary remaining arguments.

**Example:** CALL of a PROGRAM body passes; CALL of ADD does not match.

**Why:** Source: all calls are on opaque bodies. Inference: the host graph schedules calls instead of reinterpreting their implementation as host arithmetic.

**Sharp edge:** Unlike shared CALL validation, this entry does not check CallInfo explicitly; check surrounding constructors and call verification too.

### uop/spec.py:L258 — Kernel graph AFTER carries storage ordering

[Source](../../../../tinygrad/tinygrad/uop/spec.py#L258). **Match/result:** AFTER whose first source is a movement op, PARAM, AFTER, BUFFER, MSTACK, MSELECT, BITCAST, or RESHAPE returns True; remaining sources unrestricted.

**Example:** `AFTER(MSELECT(shards,0), CALL(...))` passes; `AFTER(ADD(x,y), CALL(...))` does not match.

**Why:** Inference: call outputs and views are usable only after producing effects complete.

**Sharp edge:** RESHAPE appears redundantly because it is already in Movement. This verifies permitted value families, not actual happens-before correctness.

## `z3_renderer`: translate an index into a proof problem

These callbacks return **Z3 expressions, not bool validators or replacement
UOps**. `uops_to_z3` visits eligible integer/bool nodes, recording expressions in
`ctx[1]`, and carries a solver in `ctx[0]`. `validate_index_with_z3` adds the load/store
gate and asks whether `index < 0 or index >= size` is satisfiable: `unsat` means
accepted, `sat` prints a witness and rejects, and `unknown` also rejects. Missing
translations raise `NotImplementedError`; this is not an optimistic acceptance.
Names for RANGE/SPECIAL must denote the intended shared variables. Bounds are
mathematical integers, **not a full machine-overflow model**.

A concrete proof question helps decode these rules. Launch 32 lanes with indices
`i=0..31` against a 16-element buffer. Without a gate, lane 16 is a counterexample
to safety. With gate `i<16`, ask whether both `i<16` and `i>=16` can hold; they
cannot. Z3 reports **unsatisfiable** (`unsat`), meaning no active bad access exists
in this mathematical model. **Satisfiable** (`sat`) means it found an assignment
such as `i=16`. The gate does not shrink the launch; it disables the extra lanes'
accesses. These translations build that proof question rather than executing it.

### uop/validate.py:L46 — A validity WHERE becomes a solver assumption

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L46). **Match/result:** `WHERE(cond,x,Invalid)` adds the already translated cond to the solver and returns translated x.

**Example:** `WHERE(i<16,i,Invalid)` → expression i plus constraint `i<16`; with `0<=i<32`, size 16 is accepted, while unguarded i can be rejected.

The Invalid arm says there is no access when cond is false. Adding cond to the solver restricts attention to accesses that actually happen; it is not claiming cond holds for every launched lane.

**Why:** Source: the valid condition is a constraint. Inference: Invalid branches represent inactive addresses, not a scalar numeric value to reason about.

**Sharp edge:** This is stronger than translating a general conditional value: it restricts the domain of the entire proof. It is appropriate for address validity semantics, not arbitrary select expressions.

### uop/validate.py:L48 — RANGE and SPECIAL become bounded integer variables

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L48). **Match/result:** Creates integer RANGE/SPECIAL symbol with constraints `0<=symbol<=translated_bound-1`; SPECIAL uses arg name, RANGE uses `r` plus range_str.

**Example:** `RANGE(16)` → r with `0<=r<=15`; index r into size16 passes, index r+1 fails at r=15.

**Why:** Inference: enumerating loop iterations is unnecessary when inequalities describe every possible lane/iteration.

**Sharp edge:** Does not model step sizes or hardware register wraparound; a void boundless loop is not handled as an ordinary bounded range by this translator.

### uop/validate.py:L51 — Unknown integer values become bounded symbols

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L51). **Match/result:** PARAM/BUFFER/LOAD/INDEX calls create_var: bool becomes a free Bool; other values an Int bounded by x.vmin/x.vmax. PARAM/BUFFER use arg.name, others generated names.

**Example:** An integer LOAD known only in `[0,255]` → symbolic load in that interval; indexing buf16 with it fails, while gating it `<16` can pass.

The solver does not read the actual buffer. Replacing a loaded integer by any value in `[0,255]` covers all possibilities known to this analysis; a counterexample may therefore reflect missing information rather than an access that occurs for the present data.

**Why:** Source: unknown values, including non-pointer INDEX-as-load, are bounded variables. Inference: data-dependent indexing cannot be proved from its address expression alone.

**Sharp edge:** No relation to memory contents is retained. Bounds can be conservative enough to reject a safe program; symbol naming also matters.

### uop/validate.py:L52 — Float-derived casts and comparisons become unknowns

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L52). **Match/result:** CAST/BITCAST or CMPLT/CMPNE/CMPEQ with every source of floating dtype calls create_var.

**Example:** `CAST_i32(float_load)` → bounded unknown integer; `CMPLT(f32(x),f32(y))` → free Bool. A free float comparison does not prove `i<16`.

**Why:** Source: anything coming from floats is treated as unknown. Inference: this integer proof engine does not model floating-point rounding/NaNs.

**Sharp edge:** The repeated-source pattern requires all sources floating; it does not mean merely one float source. No link between float operands and result survives.

### uop/validate.py:L54 — Integer BITCAST wraps to the target range

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L54). **Match/result:** Integer-to-integer BITCAST maps to `(x - target.min) % 2**(8*itemsize) + target.min`.

**Example:** `BITCAST_i8(u8(255))` → -1, so as an index it fails a nonnegative bounds test; bitcast to u8 maps -1 to 255.

For i8, the target minimum is -128 and the modulus is 256. With input 255 the formula becomes `(255+128)%256-128 = 127-128 = -1`, matching the signed interpretation of the same eight bits.

**Why:** Source: Z3 integers are unbounded; bitcasts must wrap into the target integer range.

**Sharp edge:** Uses scalar dtype itemsize and mathematical modular arithmetic; this rule is not the same as CAST below and does not validate legal bitcast shapes.

### uop/validate.py:L57 — Invalid outside a validity WHERE is symbolic

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L57). **Match/result:** CONST(Invalid) becomes a named Z3 Int `Invalid`.

**Example:** A direct symbolic Invalid index has no bounds proof and can produce an out-of-range witness; `WHERE(g,i,Invalid)` instead uses L46.

**Why:** Inference: a sentinel has no legitimate numeric value, so assigning it zero would hide bad accesses.

**Sharp edge:** spec.validate_index short-circuits an entirely invalid index before invoking Z3; this entry matters inside translated expressions, not that bypassed case.

### uop/validate.py:L58 — Ordinary constants become Z3 literals

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L58). **Match/result:** CONST maps to BoolVal for bool dtype, otherwise IntVal(value).

**Example:** CONST(True) → BoolVal(True); CONST(7) → IntVal(7): size8 accepts index7 and rejects index8.

**Why:** Inference: exact integer literals make arithmetic bounds reasoning decidable in common cases.

**Sharp edge:** Floating subgraphs are normally excluded or abstracted earlier; do not assume this IntVal path is a float semantics implementation.

### uop/validate.py:L59 — CAST only changes bool versus integer interpretation

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L59). **Match/result:** CAST calls z3_cast: same boolness returns the expression unchanged; integer→bool yields `x!=0`, bool→integer yields `If(x,1,0)`.

**Example:** `CAST_bool(i)` → `i!=0`; `CAST_i32(b)` → `If(b,1,0)`; CAST_i8(256) still translates to 256.

Boolness means whether the value is a boolean decision or an integer number. The translator distinguishes those two kinds, but an i32-to-i8 cast stays the same mathematical integer here. This simplification is why the proof has an explicit overflow limitation.

**Why:** Source: Z3 does not model widths, so CAST only converts between bool and int.

**Sharp edge:** The last example is deliberately unlike actual narrowing machine semantics; this proof must not be cited as integer-overflow verification.

### uop/validate.py:L60 — ALU dispatch translates integer semantics with explicit exceptions

[Source](../../../../tinygrad/tinygrad/uop/validate.py#L60). **Match/result:** Any ALU calls z3_alu[op] on translated sources, returning a Z3 expression or raising for unsupported operand/op combinations.

**Example:** For a=-7,b=3: CDIV→-2, CMOD→-1, FLOORDIV→-3, FLOORMOD→2. WHERE(c,2,3) → If(c,2,3); MAX(a,b) → If(a<b,b,a).

**Why:** Source: Z3 division differs from truncation-toward-zero, so custom CDIV/CMOD formulas repair it. Inference: using raw `/` would prove the wrong address for negative intermediate indices.

**Sharp edge:** AND only supports Bool or an integer constant mask `2**k-1` / `-2**k`; XOR only Bool or integer XOR -1. Shifts require a numeral count. See the individual operator variants below.

The L60 dispatch variants deserve spelling out because the one PM entry hides the
non-obvious arithmetic:

| Variant | Translation example | Reason and limitation |
|---|---|---|
| CDIV | `-7 / 3 -> -2`; `-7 / -3 -> 2` | `z3_cdiv` adjusts a negative dividend before Z3's Euclidean division, preserving C-style truncation. No divide-by-zero precondition is added. |
| CMOD | `-7 %c 3 -> -1` | Uses `a - cdiv(a,b)*b`, keeping remainder consistent with truncation. |
| FLOORDIV | `7 // -3 -> -3` | For a negative divisor use `(-a)/(-b)` to obtain mathematical floor. |
| FLOORMOD | `7 %floor -3 -> -2` | Uses `a - floordiv(a,b)*b`, rather than Z3's standalone modulus. |
| SHL | `3 << 2 -> 12` | Multiply by `2**count`; count must support `.as_long()`, and no finite-width wrap occurs. |
| SHR | `-7 >> 1 -> -4` | Divide by positive power of two in Z3 integer arithmetic. Symbolic counts are unsupported. |
| AND, bool | `True & c -> c` | Z3 boolean conjunction. |
| AND, low-bit mask | `x & 7 -> x % 8`; at x=-3, result 5 | Two's-complement masking expressed without bitvectors. A single constant mask may occur on either side. |
| AND, alignment mask | `x & -8 -> x - x%8`; at x=13, result 8 | Removes low bits. An arbitrary mask such as 5 raises RuntimeError. |
| XOR, bool | `True ^ c -> not c` | Boolean exclusive-or. |
| XOR, integer NOT | `13 ^ -1 -> -(13+1) -> -14` | Infinite two's-complement identity. `13 ^ 3` is unsupported, not approximated. |
| WHERE | `WHERE(c,4,8) -> If(c,4,8)` | A normal select retains both branches; unlike the Invalid-arm rule, it does not add c as an assumption. |
| MAX | `MAX(3,8) -> If(3<8,8,3)` | Piecewise arithmetic rather than Python's eager ordering of symbolic expressions. |
| Inherited python_alu | `ADD(i,4) -> i+4`, `MUL(i,4) -> i*4`, comparisons → Z3 comparisons | The mapping inherits Python ALU callables, but not every callable works on Z3 objects; e.g. arbitrary integer bitwise OR and floating transcendental expressions are not a supported integer proof path. |

The integer AND helper swaps operands whenever its first operand is a numeral.
Consequently, feeding it **two unfurled numeral operands** can make it try the
wrong one as the mask: `z3_and(IntVal(-3), IntVal(7))` raises because it tests -3 as
the mask. The symbolic-x cases in the table are the intended translation path;
constant folding normally handles pure constant arithmetic before this stage.
This is a source-observed sharp edge, not a claim that all callers guarantee
prior folding.

## Weak type commitment and elimination

These are actual **UOp rewrites**. Their job is not GPU instruction selection:
it is to postpone width decisions until a consumer supplies enough information,
then make every width explicit before the final program spec. The consumer edge
matters: the same weak literal can become f16 in one computation and f32 in another.
`commit_dtype(int32)` chooses an integer type sufficient for a weakint node's
bounds, with int32 as the default; weakfloat becomes its strong float kind.
`derived_dtypes` only succeeds for Broadcastable operators when both promoted
operand type and derived result type are concrete. Unary operators do not use
that helper's derivation shortcut.

`commit_srcs_at` has a subtle exception: if the consumer already derives a strong
type, a bare weak CONST is numerically converted but can remain a bare weak
CONST, relying on the consumer to state its width. Otherwise it uses `ccast`.
Returning an identical UOp becomes None, preventing a pointless rewrite loop.

### uop/weak.py:L36 — Commit weak broadcast operands from strong neighbors

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L36). **Match/result:** For any Binary/WHERE/MULACC, commit_weak_srcs declines unless there is a weak source and least_upper_dtype of all source dtypes is concrete; otherwise commits weak sources at that type.

**Example:** `ADD(f32(x), weakfloat_expr)` → `ADD(f32(x), CAST_f32(weakfloat_expr))`; `ADD(weakint_x, weakint_y)` stays unresolved. A bare 1.0 may remain a bare literal if the consumer derives f32.

The strong neighbor supplies context: adding a weak float to f32 data usually resolves that weak operand as f32. With two weak operands no concrete neighbor settles the choice, so another stage must decide from bounds/defaults.

**Why:** Source: decomposition/float emulation can mint weak constants; commitment must reach a fixpoint (another pass makes no further change) before default lowering. Inference: contextual type information should beat a global default.

**Sharp edge:** The width is a promotion of all sources, not blindly the first source. Invalid and WHERE conditions interact with the promotion lattice (the rules choosing a common dtype), rather than being ad hoc dtype guesses.

### uop/weak.py:L37 — STORE commits its weak value to storage dtype

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L37). **Match/result:** STORE with weak-typed second source and optional trailing sources replaces that value with `.ccast(target.dtype)`.

**Example:** `STORE(f16_buffer, CONST(1.25), gate)` → `STORE(f16_buffer, CAST_f16(CONST(1.25)), gate)`.

**Why:** Inference: storage is an authoritative width boundary; otherwise a weak literal could be emitted at default f32 into f16 memory.

**Sharp edge:** The destination controls width, including rounding/narrowing; trailing gates/dependencies are preserved unchanged.

### uop/weak.py:L40 — A concrete CAST can resolve a weak ALU underneath

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L40). **Match/result:** CAST over weak ALU calls cast_weak_srcs. It declines if outer type is weak or its weak kind differs from the inner result; otherwise chooses a type at least as wide as outer type, inner bounds, and every weak source bound.

**Example:** `CAST_i16(ADD(weak_var[0,100000],1))` → compute the ADD at a sufficiently wide integer type (at least int32), then CAST_i16. `CAST_i32(weakfloat_add)` is declined.

The outer cast describes the final stored result, not necessarily the precision of the calculation producing it. Keeping the inner sum wide preserves its value until that final conversion; narrowing intermediate operands could lose information earlier.

**Why:** Source: a concrete cast states a width floor, never a narrowing of intermediate computation; crossing int/float kinds is a value conversion, not width annotation.

**Sharp edge:** Do not push the i16 cast into every input: early truncation changes arithmetic. No CONST arm exists because CAST(CONST) already means a committed constant.

### uop/weak.py:L69 — Narrow a masked long index for a small buffer

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L69). **Match/result:** INDEX/SHRINK with second input `WHERE(gate, int64_idx, Invalid)` becomes the same node using gated CAST_int32(idx), if `buf.max_numel()-1 <= int32.max`.

**Example:** For a buffer of 1024 elements, `INDEX(buf, WHERE(i<1024, i64(i), Invalid))` → `INDEX(buf, WHERE(i<1024, CAST_i32(i), Invalid))`. A buffer needing index 2**31 declines.

Every valid element of a 1024-element buffer has index 0 through 1023, which fits i32. Values outside the active gate need not preserve a usable address, but the compiler must already be entitled to assume active accesses are valid.

**Why:** Source: a gated long index into a small buffer narrows because out-of-gate values are discarded. Inference: active in-bounds indices need only int32, reducing index arithmetic cost.

**Sharp edge:** The rule does not independently prove the gate implies in-bounds indexing; it relies on valid address semantics. Casting before masking is safe only for the accessed values. INDEX and SHRINK preserve additional sources.

### uop/weak.py:L73 — Two weak CASTs preserve two kind conversions

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L73). **Match/result:** Nested weak CASTs whose original x is strong are replaced by concrete casts at the inner and outer commitment types, followed by the outer weak wrapper.

**Example:** `CAST_weakfloat(CAST_weakint(f32(3.75)))` → `CAST_weakfloat(CAST_f32(CAST_i32(f32(3.75))))`, preserving truncation to 3 before returning to float.

The inner conversion changes kind from floating point to integer and discards the fractional part. The outer conversion turns that integer back into floating point. Deferring widths must not erase either of these numerical steps.

**Why:** Source: two stacked weak casts are two kind conversions; each resolves at its own kind default.

**Sharp edge:** If x is still weak this declines. Simply dropping both wrappers would incorrectly turn the example back into 3.75.

### uop/weak.py:L75 — Give symbolic ALU parameters a physical integer width

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L75). **Match/result:** Weakint PARAM/BUFFER in ALU address space gets ParamArg.dtype replaced with commit_dtype(int32), then a CAST back to weakint; other address spaces decline.

**Example:** `BUFFER(variable n, weakint, bounds=[0,1024], ALU)` → `CAST_weakint(BUFFER(n, int32, same bounds))`. Bounds larger than int32 can select a wider integer.

A launch argument must occupy a fixed number of bytes so the caller and callee agree on how to pass it. The temporary weak wrapper lets surrounding symbolic arithmetic finish choosing its own widths after that physical argument representation is settled.

**Why:** Inference: scalar launch arguments need ABI widths while surrounding symbolic expressions may still use weak typing.

**Sharp edge:** The weak wrapper is intentional and is absorbed by later consumers; this is not the final emitted form. This does not convert storage-buffer element types.

### uop/weak.py:L77 — Lower weak consumers and preserve numerical conversions

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L77). **Match/result:** All opcodes run lower_weak_node: skip CAST(CONST); absorb weak CAST sources, default underivable weak constants, and when ready unify concrete source widths before restoring original result dtype with CAST.

**Example:** `ADD(CAST_weakint(i32(x)), CAST_weakint(i32(y)))` → int32 ADD, temporarily wrapped back to weakint. For an i32 input cast through weakint, the weak wrapper disappears at the consumer; for a float input cast to weakint, it becomes a real integer conversion.

Weak wrappers describe deferred decisions, so the consumer examines all its inputs together before choosing actual widths. It must still preserve a float-to-integer change of kind, because that changes the number rather than merely annotating its width.

**Why:** Source: consumers absorb weak CASTs; weakfloat unary operations resolve before transcendental decomposition. Inference: one coordinated width choice prevents premature narrowing in compound index arithmetic.

**Sharp edge:** WHERE excludes the bool condition from operand width casting. If unresolved nonconstant weak operands remain, only source updates happen this round. Binary result bounds participate in widening; Invalid bases are never cast during unification.

### uop/weak.py:L89 — Remove redundant constant commitment only when derivation is unchanged

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L89). **Match/result:** For Broadcastable nodes, uncast_const removes strong CAST around a weak CONST only if the new operand promotion and derived result dtype exactly equal the old ones; otherwise declines.

**Example:** `ADD(f32(x), CAST_f32(CONST(2.0)))` → `ADD(f32(x), CONST(2.0))`. `ADD(CAST_i64(CONST(2)), CAST_i64(CONST(3)))` stays typed because stripping both would leave only weak operands.

Many algebraic patterns recognize a literal directly. Removing an unnecessary cast makes those patterns work again, but only when the same operand computation and result types can still be derived. The final constant pass restores explicit widths later.

**Why:** Source: bare-CONST patterns must keep matching; both the promoted operand type and result dtype must be preserved. Inference: this reconciles easy constant algebra with contextual typing.

**Sharp edge:** Checking only the result dtype would be insufficient for comparisons, whose result stays bool even if operand precision changes. Weak CASTs are not commitments and are not stripped here.

### uop/weak.py:L98 — Finally state the type on every remaining constant edge

[Source](../../../../tinygrad/tinygrad/uop/weak.py#L98). **Match/result:** Any node with a direct CONST child is eligible via custom_early_reject; cast_consts skips CAST(CONST), commits derivable weak constants using operand type, then wraps remaining non-Invalid CONST children with forced cconst at their committed dtype.

**Example:** `ADD(f32(x), CONST(2.0))` → `ADD(f32(x), CAST_f32(CONST(2.0)))`; `WHERE(CONST(True), f32(x), f32(y))` gets an explicit bool CAST on the condition.

This is the final counterpart to exposing bare literals for simplification. The same literal node can have different consumers, so each consumer edge gets the representation that its own calculation requires.

**Why:** Source: bare is a property of the consumer edge; `.cast(bool)` can fold away so `cconst` forces even a bool width annotation. This makes spec_program L191 pass.

**Sharp edge:** Invalid is intentionally not committed and must be removed elsewhere. A CONST already beneath CAST is its value payload, not another unresolved consumer edge; wrapping repeatedly would never terminate.

## What these rules imply for RMSNorm and IMAGE

For RMSNorm, `sum(x*x) / N` contains weak literals (zero, epsilon, N) alongside
f16/f32 data and integer reduction indices. The weak passes determine whether a
literal is converted at a data operand's precision, a store's precision, or an
index's bound-derived width. A comparison's bool result must not erase the width
of its integer operands. `pm_uncast_const` can expose epsilon/N again to algebraic
patterns, and `pm_cast_const` eventually makes their emitted width explicit.
These passes **do not decide whether the reduction and normalization occupy one
kernel or two**; that decision is in scheduling and reduction lowering.

For IMAGE, the shared LOAD/STORE validator deliberately does not prove texture
bounds. At this snapshot, `dtype_from_uop` also makes INDEX of an image-shaped
PARAM return float regardless of storage dtype. Together these facts explain why
naively applying scalar-buffer assumptions to image accesses is misleading.
Neither fact by itself documents why a particular vendor workaround was added;
see the GPU/IMAGE rule chapter for address conversion and packing rules.

## CPU probe actually executed

[`probes/spec_and_types.py`](probes/spec_and_types.py) executes 20 assertions
using Python and Z3 4.15.3, with no GPU/device initialization. From the workspace
root, run:

```sh
tinygrad/.venv/bin/python boop-docs/compiler-maps/tinygrad/rules/probes/spec_and_types.py
```

Observed: **20 assertions passed**. The probe covers typed→bare→typed constant
round-tripping, the final program's rejection of a bare constant, rejection of
float AND, tensor EXP2 of an integer source, explicit bool constant commitment,
f16 STORE commitment, preserving int32 arithmetic under an int16 result cast,
nested float→integer→float conversions, ALU variable width selection, weak
consumer absorption, a gated bounds proof, four signed division cases, and three
symbolic bit-mask/XOR cases evaluated at concrete inputs. These are selected
examples, not exhaustive validation of all 100 rules. All other examples remain
source-reviewed schematics.
