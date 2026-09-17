# Decomposition rules, individually

Snapshot: tinygrad `107adc31701df0247dfa45e175984df906a68b53`. This chapter covers every rule template in `codegen/decomp/op.py`, `dtype.py`, and `transcendental.py`, including rules constructed conditionally by factories. **All before/after examples below are schematic, source-reviewed, and unexecuted.** They illustrate the rule, not a claim that constant folding leaves this exact graph intact. `CDIV`/`CMOD` mean C-style truncating division/remainder; `//`/`%` mean floor division/modulo. These differ for negative inputs.

“Why” below states the current mechanical necessity. When a source comment supplies the reason, it is labeled **explicit**; otherwise it is **inferred**, not a claim about the author's original motivation. Rules select operations according to a renderer's supported-operation tuple; chip names are not hard-coded here. See the AMD and IMAGE chapters for the backend-specific selection and subsequent rewrites.

## What decomposition does

A compiler graph can ask for an operation that a target device cannot execute directly. **Decomposition** replaces that request with smaller operations the device understands. For example, floor division of a negative integer might need a truncating divide plus a correction, and a 64-bit integer might need two 32-bit words. The program's intended operation stays recognizable, but its implementation becomes more explicit. See [the first-principles guide](../../first-principles.md) for where this fits in compilation.

A **renderer** is the backend component that turns the final operation graph into source or instructions. Its supported-operation and supported-dtype lists tell these factories which replacements to create. A **factory** builds a matcher for that capability set; a **rule template** can therefore create multiple concrete patterns. A **guard** says when a replacement is applicable. Some guards protect arithmetic correctness, some prevent unsupported output, and some avoid an unnecessarily expensive expansion.

Read the compact operation names as follows: ALU means ordinary arithmetic/logic operations; SHL/SHR shift bits left/right; CMPLT/CMPNE/CMPEQ compare less-than/not-equal/equal; NEG changes sign; RECIP computes 1/x; FDIV is floating division; MULACC computes a*b+c. WHERE selects one of two values using a boolean condition. A graph selection is not automatically a Python-style branch that skips evaluating all inputs.

### The division convention is part of the operation

For positive 7 divided by 3, floor and truncating division both produce quotient 2, remainder 1. Negative inputs expose the difference:

| Calculation | Quotient | Remainder | Reconstruction |
|---|---:|---:|---|
| Floor: `-7//3`, `-7%3` | -3 | 2 | `-3*3+2=-7` |
| Truncate toward zero: `CDIV(-7,3)`, `CMOD(-7,3)` | -2 | -1 | `-2*3-1=-7` |
| Floor with negative divisor: `7//-3`, `7%-3` | -3 | -2 | `-3*(-3)-2=7` |

The pair must always satisfy `a=q*b+r`. Floor remainder has the divisor's sign (unless zero); truncating remainder has the dividend's sign. A rewrite must preserve the requested pair of conventions, not merely choose a fast divide instruction.

In mathematical examples `2^v` means `2**v` in Python. In XOR expressions, `^` instead means bitwise exclusive-or; the operation name tells you which. `0x` introduces hexadecimal, with each digit representing four bits. A **word** below is 32 bits. Unsigned words hold 0 through `2**32-1`; signed two's-complement words use the top bit for negative values. Arithmetic right shift repeats that sign bit, while logical right shift fills with zeros. `vmin`/`vmax` are proven lower/upper bounds, not observed sample values.

## Integer and operation decomposition

Two factories run at different times. `get_simplifying_rewrite_patterns` removes semantic operations such as floor division. `get_late_rewrite_patterns` chooses instructions after symbolic reasoning; changing comparison shapes too early would interfere with the symbolic helper that reasons about nonnegative sums and their constraints (called simplex in this code). Within a matcher, ordering matters: the cheap power-of-two rule comes before the general division expansion.

### codegen/decomp/op.py:L70 — Floor division by a positive power of two

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L70).

**Match/guard:** integer `x // c`, renderer supports SHR, `c=2^v` with `1<=v<=63`. The dictionary lookup's falsey zero excludes `c=1`.

**How to read this rule:** In signed binary, shifting -9 right three places repeats its sign bit and drops the three low bits. That rounds downward to -2, exactly the requested floor quotient. It would not match a divide that rounds toward zero.

**Result/example:** `-9 // 8 → -9 >> 3 → -2`.

**Why (explicit):** arithmetic right shift already implements floor division, avoiding a truncation correction.

**Sharp edge:** logical shifting signed `-9` gives a huge positive result; and truncating `CDIV(-9,8)` is `-1`, so the same uncorrected rewrite cannot serve signed CDIV.

### codegen/decomp/op.py:L72 — General floor division becomes corrected truncation

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L72).

**Match/guard:** any `a // b` that reaches this rule.

**How to read this rule:** Begin with the machine-friendly quotient q=-2 and remainder r=-1 for -7/3. Because the result is negative and not exact, rounding down requires one more negative step: q-1=-3. If r=0 there is no fractional part to correct, which explains both tests in the correction.

**Result:** if bounds prove both operands nonnegative/positive or nonpositive/negative, use CDIV directly; otherwise `CDIV(a,b) - ((CMOD(a,b)!=0) & ((a<0)!=(b<0)))`. **Example:** `-7 // 3 → -2 - (true & true) = -3`; `-6 // 3 → -2 - 0`.

**Why (inferred):** target integer division commonly truncates, whereas indexing algebra needs floor semantics.

**Sharp edge:** subtracting merely on opposite signs makes exact divisions wrong (`-6/3` must stay `-2`); division by zero is not repaired here.

### codegen/decomp/op.py:L74 — Floor modulo by a power of two

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L74).

**Match/guard:** integer `x % c`, AND supported, `c` in `{1,2,...,2^63}` restricted to powers of two.

**How to read this rule:** The mask 7 is binary 111, so it keeps the three low bits. In two's complement, -9 ends in 111: these bits encode its offset 7 above the previous multiple of eight (-16). That offset is the floor remainder.

**Result/example:** `-9 % 8 → -9 & 7 → 7`; `%1 → &0`.

**Why (explicit):** the low bits of two's-complement encode the positive floor remainder.

**Sharp edge:** `CMOD(-9,8)=-1`, not `7`; negative divisors are intentionally absent.

### codegen/decomp/op.py:L75 — General floor modulo becomes corrected C remainder

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L75).

**Match/guard:** any remaining `a % b`.

**How to read this rule:** Changing truncating quotient -2 to floor quotient -3 consumes one extra group of 3. To keep `a=q*b+r` unchanged, the remainder must increase by 3: -1 becomes 2. WHERE expresses “add b only when correction is needed” without introducing a multiply-accumulate the later word-pair implementation cannot handle.

**Result:** same-sign bounds permit CMOD; otherwise `r=CMOD(a,b); r + ((r!=0)&((a<0)!=(b<0))).where(b,0)`. **Example:** `-7 % 3 → -1+3=2`; `7 % -3 → 1-3=-2`.

**Why (explicit):** WHERE rather than multiplication prevents later integer MULACC fusion, which long decomposition does not implement.

**Sharp edge:** a seemingly equivalent `r + bool*b` can therefore break an emulated int64 backend even when its arithmetic is right.

### codegen/decomp/op.py:L77 — Threefry as explicit word arithmetic

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L77).

**Match/guard:** THREEFRY(counter,key) when THREEFRY is unsupported.

**How to read this rule:** A counter-based random generator deterministically maps a counter and key to output bits. Each round mixes the two words: addition creates carries, rotation moves bits around the word with the falling bits wrapped to the other end, and XOR combines them. Exact word widths and round order define the sequence, so a superficially similar random source is not a valid replacement.

**Result:** split both uint64 inputs into low/high uint32 words; inject keys; execute 20 add/rotate/XOR rounds in five groups of four; inject another key after each group; repack `(high<<32)|low`. Rotations alternate `[13,15,26,6]` and `[17,29,16,24]`; the third key word is `key0 ^ key1 ^ 0x1BD11BDA`.

**Example:** counter=0/key=0 starts `(0,0)`; the first rotation leaves `(0,0)`, and the first four-round group's key injection produces `(0,0x1BD11BDB)`. The rewrite includes the remaining four groups; that intermediate is **not** the random output.

**Why (explicit):** real hardware has no THREEFRY instruction, although NullRenderer can retain it.

**Sharp edge:** additions must wrap at 32 bits; implementing a rotate with signed right shift corrupts any round with the top bit set. This is deterministic PRNG lowering, not interchangeable with a native random-number instruction.

### codegen/decomp/op.py:L79 — MAX through compare/select

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L79).

**Match/guard:** MAX unsupported and CMPLT supported.

**How to read this rule:** If the first value is smaller, choose the second; otherwise choose the first. This truth-table definition supplies a MAX implementation using only two primitives the renderer accepts. Special floating values are why that operand order is documented.

**Result/example:** `MAX(3,5) → (3<5).where(5,3) → 5`.

**Why (explicit):** max spelling/availability is awkward across C-style backends.

**Sharp edge:** NaN and signed-zero tie behavior depends on operand order: `(NaN<5)` is false, selecting the first NaN; `(5<NaN)` is false, selecting 5. Do not substitute an unrelated library `fmax` contract without checking it.

### codegen/decomp/op.py:L85 — De Morgan for boolean masks

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L85).

**Match/guard:** boolean `!x & !y`, OR supported.

**How to read this rule:** “Neither x nor y is true” is the same statement as “it is false that either is true.” This is De Morgan's law, and turns two negations plus AND into one OR plus one negation.

**Result/example:** `!true & !false → !(true|false) → false`.

**Why (inferred):** one NOT can replace two NOTs when OR exists.

**Sharp edge:** this is restricted to bool: integer logical negation and bitwise complementation are different (`!2=0`, `~2=-3`).

### codegen/decomp/op.py:L88 — Integer multiply by a power of two

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L88).

**Match/guard:** integer `x*c`, SHL supported, `c=2^v`, `v!=0`.

**How to read this rule:** Each left shift doubles an integer's positional value when representable; three shifts multiply it by eight. The dtype and constant guards ensure this is a bit operation on an integer, not an attempt to shift a floating representation.

**Result/example:** `7*8 → 7<<3 → 56`.

**Why (explicit):** replace multiply with a shift.

**Sharp edge:** negative constants and `*1` do not match the callback; float `0.5*8` must not become an integer shift. Backend overflow/shift semantics still matter for signed values.

### codegen/decomp/op.py:L91 — Unsigned truncating division by a power of two

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L91).

**Match/guard:** unsigned CDIV(x,c), SHR supported, positive power-of-two `c>1`.

**How to read this rule:** For nonnegative integers, discarding the three fractional binary places of division by eight has only one rounding direction: toward zero is also down. Signed negative values do not have that property.

**Result/example:** `CDIV(uint32(19),8) → 19>>3 → 2`.

**Why (explicit):** unsigned floor and truncation coincide.

**Sharp edge:** the next rule handles signed values; applying this one to `-9` loses the truncation correction.

### codegen/decomp/op.py:L94 — Signed truncating division needs a bias

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L94).

**Match/guard:** integer CDIV(x,c), SHR supported, `c=2^v>1`; unsigned instances normally matched the preceding rule.

**How to read this rule:** A raw shift gives floor division. Adding c-1 only for negative x raises its position within the group enough to implement truncation: for c=8, -9 becomes -2 before shifting, and floor(-2/8)=-1. The conditional bias fixes the rounding direction without changing positive inputs.

**Result:** `(x + (x<0).where(c-1,0)) >> v`; if bounds prove the sign, the predicate is made constant immediately. **Example:** `CDIV(-9,8) → (-9+7)>>3 → -1`.

**Why (inferred):** a positive bias makes arithmetic shift round a negative dividend toward zero.

**Sharp edge:** `(-8+7)>>3=-1` also handles exact multiples correctly; adding the bias for positive `9` would wrongly produce `2`.

### codegen/decomp/op.py:L99 — Replace constant division with multiply/shift

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L99).

**Match/guard:** integer CDIV(x,d), SHR supported, fast-idiv enabled; helper refuses `d<=0` or `x.vmin<0`.

**How to read this rule:** The multiplier 43 with shift 7 approximates division by 3 because 43/128≈1/3. Approximation alone is not sufficient: the helper proves that rounding down gives the exact integer quotient throughout the stated input interval. The product needs enough bits to hold x*m before the shift removes low bits.

**Result:** `magicgu(vmax,d)` finds `m,s` satisfying `floor(x/d)=(x*m)>>s` over the proven interval. Return zero if `vmax<d`; otherwise prefer an in-width product, then factor powers of two out of `d`, then try one supported wider integer dtype.

**Example:** for `0<=x<=100`, `x/3 → (x*43)>>7`; at `x=100`, `4300>>7=33`. For full uint32 range the multiplier/intermediate choice must be reconsidered.

**Why (explicit):** widening may be slow, so shrink the numerator first when possible.

**Sharp edge:** the interval is part of the proof: extending a multiplier beyond its proven interval can fail, and computing a correct multiplier in a too-small dtype overflows. `dont_cast=True` prevents recursive attempts to widen after factoring.

### codegen/decomp/op.py:L102 — Constant remainder via the same proven quotient

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L102).

**Match/guard:** integer CMOD(x,d), SHR supported, fast-idiv enabled, and `fast_idiv` actually returns a quotient.

**How to read this rule:** Once q is known, the defining identity gives r=x-d*q. For x=100,d=3 the proven q is 33, so the remainder is 100-99=1. Reusing that proof avoids needing a separate remainder algorithm.

**Result/example:** bounded `CMOD(100,3) → 100-3*((100*43)>>7) → 1`.

**Why (explicit):** avoid perturbing general floor-mod's negative-input CMOD implementation detail.

**Sharp edge:** for `x=-7`, fast_idiv refuses; blindly using a floor quotient would make the C remainder `2` instead of `-1`.

### codegen/decomp/op.py:L105 — Explicit negation instruction

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L105).

**Match/guard:** `x*-1`, NEG supported.

**How to read this rule:** NEG is one-input sign change. The earlier graph may have represented that intention using multiplication by -1; this rule selects the direct instruction only after the target advertises it.

**Result/example:** `5*-1 → NEG(5) → -5`.

**Why (inferred):** use the backend's unary operation.

**Sharp edge:** signed minimum negation still overflows; this is not a widening operation. Floating `-0`/NaN behavior should follow the backend's ALU contract.

### codegen/decomp/op.py:L106 — Add a negation becomes subtraction

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L106).

**Match/guard:** `x+NEG(y)`, both NEG and SUB supported.

**How to read this rule:** Adding the negative of y is subtraction of y. The order of rewrites matters because the pattern sees operation names and inputs, not an unrestricted algebraic expression: it needs NEG(y) to exist first.

**Result/example:** `10+NEG(3) → SUB(10,3) → 7`.

**Why (inferred):** avoid a separate negation instruction.

**Sharp edge:** the matcher requires an actual NEG node, often created by the preceding rule; `x+(-1*y)` is not literally the same input graph until rewritten.

### codegen/decomp/op.py:L110 — Negated signed less-than, constant on right

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L110).

**Match/guard:** `!(signed_x<c)`, CMPLT supported.

**How to read this rule:** For integer x, “not below 5” means x>=5, which is exactly x>4 because no integer lies between 4 and 5. The target can therefore use its less-than primitive with operands reversed.

**Result/example:** `!(x<5) → 4<x`; x=5 gives true.

**Why (explicit):** run late because simplex expects the earlier equality/inequality representation.

**Sharp edge:** the discrete predecessor is invalid for floats: x=4.5 satisfies `4<x` but not `!(x<5)`. Integer minimum constants require care because `c-1` lies outside the dtype's ordinary range.

### codegen/decomp/op.py:L111 — Negated signed less-than, constant on left

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L111).

**Match/guard:** `!(c<signed_x)`, CMPLT supported.

**How to read this rule:** For integer x, “not above 5” means x<=5, which is x<6. The successor 6 converts an inclusive bound into the strict comparison available here.

**Result/example:** `!(5<x) → x<6`; x=5 gives true.

**Why (explicit):** late canonicalization for the same simplex reason.

**Sharp edge:** x=5.5 would expose the invalid float extension; `c=max_int` also makes the successor a boundary to inspect.

### codegen/decomp/op.py:L112 — Move a negative sign across a comparison

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L112).

**Match/guard:** `signed_x*-1 < signed_y*c`, CMPLT supported.

**How to read this rule:** Start with -x<c*y. Multiply both sides by -1, reversing the comparison, to get x>-(c*y), then exchange the sides to get y*(-c)<x. This explains both the operand swap and the negated constant.

**Result/example:** `-3 < 2*4 → 2*(-4) < 3 → true`.

**Why (inferred):** expose a simpler comparison orientation without an explicit negated left operand.

**Sharp edge:** the identity is mathematical signed arithmetic, not an unconditional wraparound identity: negating the minimum signed integer does not produce its mathematical positive counterpart.

### codegen/decomp/op.py:L113 — Move negation when the other side is constant

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L113).

**Match/guard:** `signed_x*-1 < c`, CMPLT supported.

**How to read this rule:** The same two steps apply when the right side is already constant: -x<c becomes x>-c, then -c<x. The compiler can compute -c in advance.

**Result/example:** `-3<5 → -5<3`.

**Why (inferred):** fold negation into a constant.

**Sharp edge:** the minimum-integer caveat remains; this is not a proof that all machine-overflow comparisons commute with negation.

### codegen/decomp/op.py:L114 — A one-integer open interval is equality

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L114).

**Match/guard:** `(c1<x)&(x<c2)` for the same signed integer x, CMPLT supported, and `c1+1==c2-1`.

**How to read this rule:** The strict bounds exclude 4 and 6 themselves. For an integer, only 5 remains between them, so equality fully describes the allowed set. The exact one-integer gap guard supplies that proof.

**Result/example:** `(4<x)&(x<6) → x==5`.

**Why (inferred):** replace two bounds and an AND with one equality.

**Sharp edge:** `(4<x)&(x<7)` admits 5 and 6, so the callback refuses; floats would admit infinitely many points even in `(4,6)`.

### codegen/decomp/op.py:L117 — Invert inequality to native equality

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L117).

**Match/guard:** `!(x!=y)`, CMPEQ supported.

**How to read this rule:** This is instruction selection: a boolean equality already exists semantically as NOT(not-equal). The rule exposes it as CMPEQ when the backend has that operation, preserving the comparison rather than proving the operands equal.

**Result/example:** `!(3!=3) → CMPEQ(3,3) → true`.

**Why (inferred):** equality is often represented initially using available inequality/NOT machinery; use the target primitive late.

**Sharp edge:** NaN comparison must remain false for equality: `!(NaN!=NaN)=false`, not an identity-based “same UOp means equal” fold.

### codegen/decomp/op.py:L119 — Multiply-add instruction selection

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L119).

**Match/guard:** `a*b+c`, MULACC supported.

**How to read this rule:** A fused floating multiply-add can keep the full product internally, add c, then round once. Separate multiply and add round twice. That difference explains why selecting one native instruction can change low-order result bits even though real-number algebra is unchanged.

**Result/example:** `2*3+4 → MULACC(2,3,4) → 10`.

**Why (inferred):** enable a native multiply-accumulate instruction.

**Sharp edge:** floating fused rounding can differ from separate MUL then ADD; for float32 `(1+2^-23)*(1-2^-23)-1`, separate rounding can give 0 while fused evaluation retains `-2^-46`. This is operation fusion **inside** a kernel, not scheduler kernel fusion.

### codegen/decomp/op.py:L121 — Recover multiply-add after multiply became shift

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L121).

**Match/guard:** `(x<<n)+c`, MULACC and SHL supported, n constant.

**How to read this rule:** The earlier power-of-two optimization changed x*8 into x<<3. This later rule recovers the multiplication coefficient 8 because the whole multiply-plus-add may have a better single-instruction implementation.

**Result/example:** `(7<<3)+5 → MULACC(7,8,5) → 61`.

**Why (explicit):** MUL→SHL may already have fired, hiding a multiply-accumulate opportunity.

**Sharp edge:** instruction-selection order creates this rule's need; it does not eliminate a kernel boundary. Out-of-width shift counts cannot be justified by ordinary integer algebra.

### codegen/decomp/op.py:L124 — Reciprocal through division

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L124).

**Match/guard:** RECIP(x), FDIV supported.

**How to read this rule:** A reciprocal is division with numerator 1. Supplying a floating 1 lets a renderer that implements FDIV express the operation without inventing a separate reciprocal instruction.

**Result/example:** `RECIP(4.0) → FDIV(1.0,4.0) → 0.25`.

**Why (explicit):** some backends render reciprocal using division anyway.

**Sharp edge:** preserve floating semantics: `1/0.0` is an infinity case, not integer division; the untyped literal's dtype is resolved by UOp typing.

### codegen/decomp/op.py:L125 — Absorb reciprocal division into numerator

[Source](../../../../tinygrad/tinygrad/codegen/decomp/op.py#L125).

**Match/guard:** `a * FDIV(1,b)` with floating FDIV, renderer supports FDIV.

**How to read this rule:** With direct division available, make a the numerator instead of first computing 1/b and then multiplying. This saves a graph operation, but a separately rounded intermediate reciprocal and a single division need not return identical floating bits.

**Result/example:** `6*(1/4) → FDIV(6,4) → 1.5`.

**Why (explicit):** avoid materializing a reciprocal when the backend is dividing anyway.

**Sharp edge:** rounding and overflow need not match two separately rounded operations; a tiny reciprocal can underflow before multiplication, while direct a/b may remain representable.

## Emulated integer dtypes: word pairs and tags

A long value becomes `(lo32,hi32)`, with `tag=(word_number,word_dtype)` indicating which half a consumer requests. `split_l2i` memoizes by `(op,dtype,inputs)` and recursively rewrites operands bottom-up before calling `l2i`; otherwise both halves would independently construct the same large division circuit. Memory layout doubles the element count and maps element i to words `2*i,2*i+1`. This is a representation change, not a numeric cast to a smaller integer.

For an unsigned pair `(lo,hi)`, the represented value is `lo + hi*2**32`. Thus `(3,2)` represents 8589934595, not the tuple's sum 5. A signed pair uses a signed high word and an unsigned low word; `(0xFFFFFFFF,-1)` represents -1 because `(2**32-1)-2**32=-1`.

The **tag** is compiler metadata requesting one half, not data added to the tensor. A consumer needing the high half asks for word 1; the recursive rewrite constructs it from the input halves. **Memoization** stores a previously built result so asking for both halves does not duplicate an expensive graph. A buffer **definition** describes storage; INDEX describes its addressed element; LOAD reads it; STORE writes it. After splitting storage, the index unit changes from an eight-byte value to a four-byte word.

### codegen/decomp/dtype.py:L147 — Commit weak constants before splitting

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L147).

**Match/guard:** every GroupOp.All node; helper uses the first long/ulong source's dtype when present and only returns a change when needed.

**How to read this rule:** The literal 2**40 needs bits in the high half: its pair is `(0,256)`. Choosing int32 before decomposition would throw those bits away, so the helper first commits the literal to the long operand's type.

**Result/example:** `ADD(long_x, weak(2^40)) → ADD(long_x, CONST_long(2^40))` before word selection.

**Why (explicit):** decomposition itself creates bare constants mid-rewrite; they need the long sibling's dtype.

**Sharp edge:** committing that literal to int32 first loses the high word, turning `2^40` into zero modulo 32 bits.

### codegen/decomp/dtype.py:L148 — Redefine long storage as twice as many words

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L148).

**Match/guard:** a definition with long/ulong dtype.

**How to read this rule:** Ten 64-bit elements occupy 80 bytes. Twenty 32-bit words also occupy 80 bytes; doubling the count preserves capacity while changing the addressing unit. ALU-local variables follow a different representation path, so the helper explicitly refuses that case.

**Result/example:** a 10-element long buffer becomes a 20-element int buffer; ulong maps to uint. Preserve tag and other definition metadata.

**Why (inferred):** storage must have an addressable slot for each half.

**Sharp edge (explicit):** AddrSpace.ALU variables raise rather than decompose; unknown size stays unknown. Replacing dtype without doubling size would underallocate by half.

### codegen/decomp/dtype.py:L149 — Address the requested half

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L149).

**Match/guard:** long/ulong INDEX with a word tag.

**How to read this rule:** Element 3 begins at word 2*3=6. Word tag 0 selects 6 and tag 1 selects 7. The tag disappears once this choice has been encoded in the actual address.

**Result/example:** `INDEX(long_buffer,3, tag=(1,int)) → INDEX(word_buffer,7)` and clear the tag.

**Why (inferred):** word consumers must address their physical half.

**Sharp edge:** untagged INDEX is left alone; low and high halves must be 6 and 7, not 3 and 4. `reindex` preserves additional index sources such as masks.

### codegen/decomp/dtype.py:L151 — One long store becomes two stores

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L151).

**Match/guard:** STORE(long/ulong index,val), val has no word tag.

**How to read this rule:** The example value is `2*2**32+1`, so its low word is 1 and high word is 2. GROUP collects the two writes as one compiler graph result; it does not make the device perform them indivisibly.

**Result/example:** `store(buf[3],0x0000000200000001) → group(store(words[6],1),store(words[7],2))` via tags on both address and value.

**Why (inferred):** neither half alone represents the value.

**Sharp edge:** this is not an atomic 64-bit write; observing only one half would expose a torn value. The tag guard avoids splitting the same store repeatedly.

### codegen/decomp/dtype.py:L154 — Compare complete word pairs

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L154).

**Match/guard:** comparison whose operands include long/ulong a (the list source pattern admits comparison operand permutations).

**How to read this rule:** Compare the most significant part first, as when comparing decimal numbers by their leading digits. Only tied high words need a low-word comparison. Low words describe a nonnegative offset within that high-word block even for an overall signed value.

**Result/example:** `(0x0000000100000000 < 0x00000000FFFFFFFF) → (1<0) | ((1==0)&(uint(0)<uint(0xFFFFFFFF))) → false`.

**Why (inferred):** comparisons produce one bool, not a low/high bool pair.

**Sharp edge:** compare high words with the original signedness and low words unsigned when high words tie. Signed-low comparison would make `0xFFFFFFFF < 1` look true incorrectly. Equality is `lo_eq & hi_eq`; inequality is `lo_ne | hi_ne`.

### codegen/decomp/dtype.py:L156 — Signed/unsigned long casts preserve both halves

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L156).

**Match/guard:** CAST between long/ulong; the caller supplies a requested word tag.

**How to read this rule:** A same-width signedness cast changes how the top bit is interpreted, not which 64 bits are present. Both halves must be preserved; reconstructing the high word from only the low word would discard original information.

**Result/example:** `CAST_ulong(long(-1)) → (uint(0xFFFFFFFF),uint(0xFFFFFFFF))` by bitcasting each half, selecting the requested half.

**Why (inferred):** same-width signedness conversion preserves bits.

**Sharp edge:** treating it as an ordinary narrow-source cast would regenerate a high half from only the low half; `0x0000000200000001` would become 1.

### codegen/decomp/dtype.py:L159 — Split cast constants by their complete value

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L159).

**Match/guard:** CAST(CONST c) with tag `(0|1,int|uint)`.

**How to read this rule:** Masking to 32 bits selects the low eight hexadecimal digits. Shifting the original constant by 32 selects the high eight digits. Doing that shift after narrowing would mean the high digits were already gone.

**Result/example:** tagged constant `0x123456789ABCDEF0 → low=0x9ABCDEF0, high=0x12345678`, each truncated to requested word dtype.

**Why (explicit):** the general CAST path would drop the high word.

**Sharp edge:** shifting happens before truncation; truncating c first makes the high result zero (or a spurious sign extension).

### codegen/decomp/dtype.py:L161 — Widen an ordinary value to a long pair

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L161).

**Match/guard:** CAST to long/ulong, tagged output, previous special cast cases did not handle it.

**How to read this rule:** For signed -3, the pair reconstructs `(2**32-3) + (-1)*2**32 = -3`. For the floating example, `lo=2**32-1` requires hi=-2 to reconstruct `-2**32-1`; using hi=-1 would reconstruct only -1. That is the reason for the negative-value correction.

**Result/example:** int32(-3)→long gives `(0xFFFFFFFD,0xFFFFFFFF)`; uint32(0xFFFFFFFF)→long gives `(0xFFFFFFFF,0)`. Integer/bool sources use sign or zero extension. Float sources compute low by cast and high as `cast(x/2^32) - ((x<0)&(lo!=0))`; e.g. a representable `-4294967297.0` in float64 needs high=-2 and low=0xFFFFFFFF.

**Why (inferred):** sign extension and carrying across words are representation requirements.

**Sharp edge:** float→integer range/NaN behavior remains backend-dependent; this is not an arbitrary-precision conversion.

### codegen/decomp/dtype.py:L163 — Convert a long pair to a non-long dtype

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L163).

**Match/guard:** CAST from untagged long/ulong to a dtype outside the long pair.

**How to read this rule:** Converting to a float reconstructs the numeric value `hi*2**32+unsigned(lo)` before rounding to the destination. Converting to a smaller integer instead keeps the destination's low bits. Those are two distinct conversion jobs, not a universal “keep the low word” operation.

**Result/example:** long `2^32+3`→float32 becomes `float(1)*2^32+float(uint(3))` (rounded to float32); →int16 keeps the low bits, yielding 3. Float conversion uses a “fits in signed/unsigned low word” fast select; otherwise combines high and unsigned low in float32 or float64 before final cast.

**Why (inferred):** interpreting lo as signed would corrupt values whose low top bit is set.

**Sharp edge:** float32 cannot represent `2^32+3` exactly; the result is `2^32`, an expected precision loss, not evidence the high word vanished.

### codegen/decomp/dtype.py:L165 — Shift a pair with one count

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L165).

**Match/guard:** tagged long/ulong SHL/SHR; only the low word of the shift count is needed.

**How to read this rule:** A shift moves bits across the boundary between words. At count 32, the previous high word becomes the new low word. For smaller counts, each destination word can contain pieces from both original words; independent shifts would lose the crossing bits.

**Result/example:** `0x0000000100000000 >> 32 → (lo=1,hi=0)`; signed `-1>>32 → (0xFFFFFFFF,0xFFFFFFFF)`. The helper masks count with 31, transfers crossing bits, and selects a different arrangement at count>=32.

**Why (inferred):** words must exchange bits rather than shift independently.

**Sharp edge:** split transfer expressions use `>>1>>(31-n)` or `<<1<<(31-n)` to avoid a width-32 shift at n=0; counts >=64 are not a license to infer mathematical arbitrary-width shifts.

### codegen/decomp/dtype.py:L167 — Select both halves using the same predicate

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L167).

**Match/guard:** tagged long/ulong WHERE(c,a,b).

**How to read this rule:** The same choice must select both halves. Choosing low from a and high from b would invent a third 64-bit value, so the predicate remains shared and unsplit.

**Result/example:** `where(true,(1,2),(3,4)) → (where(true,1,3),where(true,2,4)) → (1,2)`.

**Why (inferred):** a boolean predicate is a single value; the data operands are pairs.

**Sharp edge:** flattening all inputs as pairs would wrongly split c or mismatch high/low lanes, potentially producing `(1,4)` which was never either input.

### codegen/decomp/dtype.py:L170 — Arithmetic and bitcasts through the word ALU

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L170).

**Match/guard:** tagged long/ulong ALU other than comparisons/shifts/WHERE, or BITCAST.

**How to read this rule:** Addition and subtraction resemble schoolbook arithmetic in base 2**32: overflowing the low digit carries one into the high digit, and borrowing subtracts one from it. Bitwise operations have no carry, so they can act independently on the two words. Division requires the longer bring-down/compare/subtract procedure shown in the table.

**Result:** recursively request both halves of every source and dispatch to `l2i`, returning the requested output half.

**Why (inferred):** this is the shared entry point; its individual op cases have different arithmetic obligations, detailed below.

**Sharp edge:** the broad match is not blanket support: unsupported cases raise `NotImplementedError`; notably MULACC is absent. This explains the WHERE workaround in floor modulo.

Each helper arm is a distinct executable expansion, even though there is one outer PM rule:

| `l2i` arm | Before → after example | Necessity / sharp edge |
|---|---|---|
| NEG | `(lo=1,hi=0)` → `0-(1,0)` → `(0xFFFFFFFF,0xFFFFFFFF)` | Borrow makes high=-1; independent per-word negation gives high=0, wrong. |
| ADD | `(0xFFFFFFFF,0)+(1,0)` → `(0,1)` | Carry is unsigned `sum_lo<a_lo`; signed comparison cannot detect it reliably. |
| SUB | `(0,1)-(1,0)` → `(0xFFFFFFFF,0)` | Borrow is unsigned `a_lo<b_lo`; high must lose one. |
| MUL | `(0x00010000,0)^2` → `(0,1)` | Split low words into 16-bit halves; combine low×low, cross products and carries, plus `a0*b1+a1*b0` into high. High×high is beyond bit63 and discarded; ordinary low-word multiplication alone loses bit32. |
| CDIV | signed `-7/3` → unsigned magnitudes `7/3=(2,1 remainder)` → quotient `-2` | 64 rounds of binary restoring division: shift remainder, bring down dividend bit, compare/subtract divisor, set quotient bit. Restore quotient sign with XOR of input signs. This can produce a very large UOp graph. |
| CMOD | signed `-7%3` in C semantics → unsigned remainder 1 → `-1` | Same 64-round circuit; restore remainder with dividend sign, not divisor sign. Floor modulo is a separate earlier correction. |
| XOR | `(0xFF,2)^(0x0F,3)` → `(0xF0,1)` | Independent words, unlike addition. |
| OR | `(0xF0,2)\|(0x0F,1)` → `(0xFF,3)` | Independent words; no carry. |
| AND | `(0xFF,3)&(0x0F,1)` → `(0x0F,1)` | Independent words; no carry. |
| BITCAST | signed `(-1,-1)` → unsigned `(0xFFFFFFFF,0xFFFFFFFF)` | Preserve each word's bits; do not numerically clamp. |
| MAX | `max((0,1),(0xFFFFFFFF,0))` → pair comparison + pair WHERE → `(0,1)` | Comparing low words only would choose the smaller 64-bit number. |

No explicit zero-divisor or minimum-signed/-1 overflow repair appears in the division helper; do not infer such guarantees from its ordinary examples.

### codegen/decomp/dtype.py:L173 — Load the requested physical word

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L173).

**Match/guard:** tagged long/ulong LOAD with its single index source.

**How to read this rule:** A consumer asking only for the high word needs the read at 2*i+1. The low-word consumer requests 2*i separately. Neither request is a whole 64-bit memory transaction after this representation change.

**Result/example:** requested high word of `load(buf[3]) → load(words[7])`; address is itself rewritten before reindexing and tag removal.

**Why (inferred):** dataflow consumers should load their chosen physical half.

**Sharp edge:** this pattern is specifically a one-source LOAD; do not assume it handles every hypothetical masked/default-valued LOAD shape. Like stores, separate word loads are not an atomic long load.

## Emulated floating dtypes: storage bits versus compute values

For context `(fr,to)`, e.g. `(fp8e4m3,float16)` or `(bfloat16,float32)`, **storage remains the original bit width** as an unsigned integer dtype, while arithmetic uses `to`. Tags on definitions/indices remember the original format. Unlike long storage, element count does not double.

### A small floating-point format primer

Ordinary normalized binary floats encode `(-1)**sign * 2**(exponent-bias) * (1+fraction)`. The sign is one bit; the stored exponent describes the scale; the fraction (often called mantissa bits here) supplies precision within that scale. **Bias** is the fixed offset that lets an unsigned exponent field describe both negative and positive powers. Conversion must change fields according to their meaning, not copy a float's numerical value into an integer.

For half precision, the exponent bias is 15 and the fraction has 10 bits. The number 1.5 is `1.5*2**0`: sign=0, stored exponent=15, fraction=0.5. Its bits are `0x3E00`. Float32 has bias 127 and 23 fraction bits, so the same number becomes `0x3FC00000`. **Rebiasing** changes stored exponent 15 to 127; it does not multiply the represented value by 2**112.

A **subnormal** (also called denormal) encodes very small magnitudes using a special zero-exponent representation. **Flushing to zero** discards these small nonzero values. NaN is a special “not a number” encoding, and a **payload** is the additional information in its bits. NaNs and infinities are not ordinary exponents with ordinary fractions. FP8 format names such as e4m3 describe exponent/fraction widths (4 and 3 bits); FNUZ means finite values, NaN, and unsigned zero, so the usual negative-zero bit pattern has another meaning.

Narrowing loses precision. **Round to nearest, ties to even** chooses the nearest representable value; exactly halfway, it chooses the value whose retained low bit is zero. **Clamping** instead limits magnitude, such as replacing 1000 by the maximum finite 448. Clamping alone does not round all smaller values onto the destination format's grid. Keeping those two jobs separate is essential for understanding L195.

The shared conversion helper [f2f](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L99) is essential to understanding these rules:

- **Widening:** extract sign, exponent and mantissa; widen mantissa bits and rebias exponent; install destination infinity/NaN exponent as appropriate. For half 1.5, `0x3E00 → float32 0x3FC00000`. Input denormals flush to zero (explicit source comment), rather than being renormalized. Half `0x0001` therefore does **not** widen to `2^-24` in this emulation path.
- **FNUZ widening:** the `0x80` byte is NaN, not negative zero. Its bias can also exceed the target bias, so a normal source exponent can fall below the target's normal range and flush. A sign-bit-only test must handle NaN before ordinary zero.
- **Narrowing:** clamp overflow, isolate sign/magnitude, round mantissa to nearest-even using `rne`, subtract bias difference, cast storage width, and select underflow/NaN encodings. `rne(v,s)` rounds up only when the dropped top bit is set **and** either lower dropped bits are nonzero or the retained low bit is odd. Thus integer significand `v=5,s=1` rounds 2.5→2 while `v=7,s=1` rounds 3.5→4.
- **Finite-only formats:** e4m3 reserves only its final magnitude code for NaN. FNUZ uses the sign-only code for NaN and has no signed zero. The helper's predicates and maximum finite calculations differ accordingly; “all exponent bits set means infinity” is wrong for these formats.
- **Clamp:** [f2f_clamp](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L126) computes the destination's largest finite magnitude from its exponent/mantissa. FP8 defaults to saturation (e4m3 1000→448); ordinary narrow floats overflow to infinity (float32 100000→half +inf). NaN is selected through `val!=val`; the source explicitly flags NaN CMPLT semantics as a FIXME.

### codegen/decomp/dtype.py:L179 — Retype emulated-float storage to unsigned bits

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L179).

**Match/guard:** any definition with dtype==fr.

**How to read this rule:** The buffer still has the same two bytes per bfloat16 element. Only its compiler-visible storage dtype becomes uint16, letting ordinary integer memory operations transport the bits while later rules interpret them as floating data.

**Result/example:** a bfloat16 buffer definition becomes uint16 with tag=bfloat16.

**Why (inferred):** hardware may store those bits without supporting arithmetic in that float format.

**Sharp edge:** it is not a numeric `float→uint` cast: bfloat16 1.0 must remain bits `0x3F80`, not integer 1.

### codegen/decomp/dtype.py:L182 — Carry storage-format identity through addressing

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L182).

**Match/guard:** INDEX/SHRINK of dtype fr whose first source is not LOAD or STACK; allow extra sources.

**How to read this rule:** An address into a buffer still points to compact storage and needs the format tag. Selecting a lane from a value already loaded and converted is different: it indexes the wider compute value, so reapplying storage conversion would be wrong.

**Result/example:** `INDEX(bfloat_buffer,3) → INDEX(uint16_buffer,3,tag=bfloat16)` after recursively rewriting the base.

**Why (explicit):** INDEX into LOAD/STACK selects a lane of an already converted compute value; load rules own those cases.

**Sharp edge:** reinterpreting `INDEX(STACK(float32_values),lane)` as uint16 storage would read the wrong representation and apply conversion twice.

### codegen/decomp/dtype.py:L185 — Convert emulated-float loads to compute values

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L185).

**Match/guard:** floating LOAD of dtype fr.

**How to read this rule:** A load retrieves encoded bits, not yet a float32 numeric value. Decoding exponent and fraction turns the bfloat16 pattern 0x3FC0 into float32 1.5. Arithmetic can now use a dtype the renderer implements.

**Result/example:** `load_bfloat16(buf[i]) → f2f(load_uint16(storage[i]),bfloat16,float32)`; stored `0x3FC0` becomes float32 1.5. A multi-element load becomes STACK of individually reindexed/converting loads.

**Why (inferred):** widening bits into a supported arithmetic dtype makes later ALU legal.

**Sharp edge:** this helper flushes denormals as described above; vector conversion is lane-by-lane rather than one giant integer bitcast.

### codegen/decomp/dtype.py:L187 — Bitcasted loads bypass numeric conversion

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L187).

**Match/guard:** BITCAST(LOAD), original load dtype==fr.

**How to read this rule:** This expression asks “what bits were stored?”, not “what number do these bits represent?” The direct-load path answers that question before a numeric conversion can change the encoding, especially for NaN and subnormal values.

**Result/example:** `bitcast_uint16(load_bfloat16(buf[i])) → bitcast_uint16(load_uint16(storage[i]))`; 1.5 yields `0x3FC0`.

**Why (explicit):** replace the load directly, retaining storage bits.

**Sharp edge:** widening to float32 first yields `0x3FC00000`; narrowing or selecting some 16 bits of that is not the requested source representation.

### codegen/decomp/dtype.py:L190 — Repack emulated values before bitcasting out

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L190).

**Match/guard:** BITCAST from floating x; x now has compute dtype to, and destination bit width equals fr's bit width.

**How to read this rule:** After promotion, a computed 1.5 has the float32 representation. A bitcast to 16 bits is supposed to observe bfloat16's representation, so the helper first encodes the result back into that format, then exposes those bits.

**Result/example:** original `bfloat16(1.5).bitcast(uint16)` after promotion → `f2f(float32_bits(1.5),float32,bfloat16).bitcast(uint16) → 0x3FC0`.

**Why (inferred):** a bitcast observes the original representation, not the promoted compute format.

**Sharp edge:** NaN payloads/denormals may already have changed during emulation; this does not promise a raw load's bitwise roundtrip (that is why L187 exists).

### codegen/decomp/dtype.py:L193 — Bitcast into an emulated format must decode its bits

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L193).

**Match/guard:** BITCAST to fr.

**How to read this rule:** Integer 0x3FC0 is decimal 16320, but those bits encode bfloat16 1.5. BITCAST requests the second interpretation. The decode step produces a supported compute value with that interpretation.

**Result/example:** `uint16(0x3FC0).bitcast(bfloat16) → decode_bfloat16(0x3FC0) as float32 → 1.5`.

**Why (inferred):** downstream consumers require a to-typed compute value.

**Sharp edge:** numeric cast of integer 16320 would yield 16320.0, not 1.5; this operation is representation decoding.

### codegen/decomp/dtype.py:L195 — Explicit cast to unsupported float computes wider, then clamps

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L195).

**Match/guard:** floating CAST with output dtype fr.

**How to read this rule:** Clamping 1000 to 448 enforces the FP8 magnitude limit, but clamping 1.001 leaves it unchanged because it is within range. A later storage encoding rounds onto the narrow format's representable values. This distinction explains why the emulation can keep extra intermediate precision.

**Result/example:** `CAST_fp8e4m3(float32(1000)) → f2f_clamp(CAST_half(1000),fp8e4m3) → half(448)` when to=half.

**Why (inferred):** retain a supported compute dtype while respecting destination overflow bounds.

**Sharp edge:** clamp is not full mantissa quantization: float32 `1.001` cast through this path to emulated bfloat16 can remain `1.001` in compute, whereas store conversion later rounds to bfloat16 1.0. Emulation does not insert original-format rounding after every arithmetic node.

### codegen/decomp/dtype.py:L197 — Promote arithmetic on unsupported floats

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L197).

**Match/guard:** fr-typed node except definitions/CAST/BITCAST/CONST, after more specific rules get their chance.

**How to read this rule:** The graph still says “add these two values,” but it now asks the backend for float32 addition instead of unsupported bfloat16 addition. Keeping more fraction bits until storage can preserve small terms that native narrow arithmetic would have rounded away.

**Result/example:** `ADD_bfloat16(a,b) → ADD(CAST_float32(a),CAST_float32(b))`, preserving op argument/tag; inference derives the supported result dtype.

**Why (inferred):** execute the arithmetic using backend-supported types.

**Sharp edge:** predicate/index sources retain their own types, and wider intermediate rounding can differ from native bfloat16. For instance a tiny increment lost by immediate bfloat16 rounding may survive to a later addition in float32.

### codegen/decomp/dtype.py:L199 — Store a bitcast's raw bits directly

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L199).

**Match/guard:** STORE(idx,BITCAST(...)) where val dtype==fr and idx.tag==fr.

**How to read this rule:** If a value was formed by reinterpreting uint16 bits as bfloat16, writing it back to bfloat16 storage can write those very bits. Decoding to a number and encoding again adds work and may alter special bit patterns unnecessarily.

**Result/example:** store `bitcast_bfloat16(uint16(0x3FC0))` → store uint16 `0x3FC0` directly.

**Why (inferred):** numeric encode/decode would be redundant and could alter special encodings.

**Sharp edge:** format tag proves this is storage for fr; applying the shortcut to ordinary float32 storage could write a 16-bit encoding into a 32-bit value slot.

### codegen/decomp/dtype.py:L201 — Encode wider compute values on store

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L201).

**Match/guard:** STORE of floating val dtype==to through an index (optionally casted) tagged fr.

**How to read this rule:** The compute result 1.5 must be represented in the destination's two-byte format before writing. The encoder supplies 0x3FC0; an ordinary integer conversion would supply 1, which the next bfloat16 reader would interpret as a completely different value.

**Result/example:** storing float32 1.5 to bfloat16 memory → encode `0x3FC0` then uint16 store. A vector becomes a group of stores at offsets i, each independently rounded/encoded.

**Why (inferred):** preserve the original tensor's compact memory layout.

**Sharp edge:** unlike a numeric cast to uint16, rounding, exponent rebiasing and special-value encoding must all happen; storing 1 instead of `0x3FC0` is representation corruption.

### codegen/decomp/dtype.py:L217 — Collect potentially emulated types

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L217).

**Match/guard:** any node of fp8/bfloat16/half/long/ulong.

**How to read this rule:** This rule is a bookkeeping visitor: it records encountered types in the context set and returns no replacement. The later root rule then has enough information to choose a coherent conversion for the whole graph.

**Result/example:** encountering ulong adds long to `ctx[0]`; seeing half adds half. This callback mutates the set and returns no graph replacement.

**Why (inferred):** one whole-graph dtype pass can handle all relevant nodes consistently; long and ulong share one pass.

**Sharp edge:** collected does not mean emulated: supported dtypes are filtered later unless `EMULATED_DTYPES` forces them. Calling this matcher without its `(set,renderer)` context is invalid.

### codegen/decomp/dtype.py:L220 — At SINK, run requested emulation passes

[Source](../../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L220).

**Match/guard:** SINK; selected collected dtype is forced by EMULATED_DTYPES or absent from renderer.supported_dtypes().

**How to read this rule:** SINK is the graph root collecting the kernel's requested results/effects. Reaching it lets the factory apply each needed dtype conversion to the whole computation, including both arithmetic and memory boundaries, using one agreed compute format.

**Result/example:** graph uses unsupported bfloat16 and supported float32 → rewrite whole sink with `(bfloat16,float32)`; clear collected set afterward. FP8 chooses half if half is supported/not forced for emulation, otherwise float32. Long chooses the pair matcher with a memo dict; float chooses the float matcher.

**Why (inferred):** legality is a property of the renderer and entire graph, not an isolated node.

**Sharp edge:** forcing half emulation changes FP8's intermediate choice; read support predicates together rather than assuming FP8 always computes in half.

## Transcendental factory rules and their actual algorithms

### codegen/decomp/transcendental.py:L272 — Expand supported-format EXP2, LOG2, or SIN

[Source](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L272).

**Match/guard:** this loop creates **three** rule instances, one each for EXP2/LOG2/SIN on float16/32/64. The instance exists only if that op is absent from renderer's supported tuple or `force_transcendental` is true.

**How to read this rule:** These are functions that cannot generally be expressed as a finite exact polynomial. Software implementations first reduce the input to a small interval where a polynomial is accurate, evaluate it, then reconstruct the answer's scale or sign. ULP means one spacing between adjacent representable floating values near the answer; “approximately 1 ULP” is an accuracy claim, not exact equality or a measured guarantee here.

**Result:** call xexp2/xlog2/xsin respectively.

**Why (inferred):** replace unavailable or deliberately bypassed native math with ordinary ALU and bit manipulation. The helpers' docstrings claim approximately 1 ULP; this chapter has not verified that bound on any device or the full input domain.

**EXP2 example and expansion:** `EXP2(3.25)` chooses rounded integer q=3 and s=0.25; evaluate a polynomial approximating `2^s`, then scale by `2^q`, yielding about 9.5136566. [xexp2](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L193) first substitutes zero for infinities/NaN so integer casts are not fed those values. `rintk` adds signed 0.5 then casts, rounding ties away from zero. The polynomial is evaluated in Horner form: for example, `a+b*s+c*s*s` becomes `a+s*(b+s*c)`, avoiding separately computing every power. Its coefficients differ for float64 versus float16/32. `ldexp2k` splits exponent into floor(q/2) and the remainder and multiplies by two separately constructed powers of two. It then handles upper/lower thresholds and NaN explicitly.

**Sharp edge:** the input residual is s in roughly [-0.5,0.5], despite a coefficient comment describing a log-scaled interval. Naively applying a polynomial to d=100 would be catastrophically wrong; and removing output guards would expose exponent-bit construction outside its normal range. Thresholds are dtype-specific, not universally [-150,128].

**LOG2 example and expansion:** `LOG2(8)` computes an exponent e=3 and normalized m=1; x=(m-1)/(m+1)=0, so the polynomial corrections vanish and output is 3. [xlog2](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L219) scales small inputs by `2^64` (half: `2^10`), extracts the exponent from the bitcast of `a/0.75`, normalizes by adjusting exponent bits, subtracts scaling from e, then approximates log using an odd series in x with a polynomial in x². Float32 has an extra low correction `x*3.2734474483568488616e-08`; half omits it because it underflows. **Why these details (explicit):** half cannot represent `2^64`; its special scaling and omitted correction avoid overflow/underflow.

**Sharp edge:** `LOG2(0)=-inf`, negative input gives NaN, +inf gives +inf, and final `RECIP(d)==-inf` catches negative zero; the comment specifically mentions PTX signed-zero behavior. Removing the final correction is not justified merely because ordinary positive examples pass. Small-input scaling also relies on backend handling of subnormal input arithmetic.

**SIN example and expansion:** `SIN(1)` takes the small path, reduces around a multiple of π, then evaluates an odd sine polynomial and restores parity/sign; expected value is about 0.841471. `SIN(100)` selects the large path because default switch_over=30, even though the reduction helper docstrings discuss much larger theoretical ranges. [xsin](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L170) masks exceptional inputs, records sign, works on magnitude, and restores NaN for ±inf/NaN at the end.

The [Cody–Waite helper](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L115) actually computes a multiple of π (`q≈round(d/π)`), subtracting a split π constant in several pieces to reduce loss of significant digits when two nearby large numbers are subtracted (cancellation). This differs from the helper docstring's blanket π/2 description. Float64 splits off a large quotient component `qdh`; half performs subtraction in float32 before narrowing. The small polynomial uses q's odd/even parity for the sign. `sin(π+0.1)` therefore reduces to about 0.1 and flips sign, rather than evaluating its polynomial at 3.24.

The [Payne–Hanek helper](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L66) extracts mantissa/exponent; uses the exponent to select 96 relevant bits from a fixed 190-bit 2/π table; performs uint64 products; obtains the quadrant (which of four quarter-turn regions contains the angle) from the high product and the within-region angle from the fractional product; and reconstructs the position within the sine cycle with q's low two bits. This integer work is why software sine can trigger long decomposition and expand far beyond one math instruction.

**Sharp edge:** do not repeat the docstring as a verified unlimited-range guarantee: the table is finite, and the implementation's final rounding select tests `f<0.5` (the frexp mantissa), whereas its comment says “fraction >=0.5.” This discrepancy deserves a targeted accuracy probe before modifying the algorithm. `fast=True` discards the large path and assumes the stated small-input domain; this factory calls the default `fast=False`.

### codegen/decomp/transcendental.py:L273 — Promote other float formats around transcendental ops

[Source](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L273).

**Match/guard:** for each of EXP2/LOG2/SIN under the same unsupported-or-forced condition, match any float dtype outside float16/32/64 (FP8 and bfloat16).

**How to read this rule:** The float32 intermediate gives the software algorithm the exponent and fraction layout it expects. Casting the answer back respects the requested output format, but cannot recover precision the original narrow input never had.

**Result/example:** `SIN_bfloat16(x) → CAST_bfloat16(SIN_float32(CAST_float32(x)))`; bfloat16 x=1 gets a float32 approximation then conversion to the original format.

**Why (inferred):** the bit-manipulation algorithms are written for three IEEE formats; direct bfloat16 exponent/mantissa assumptions would be wrong.

**Sharp edge:** promotion does not recover information already rounded in x; the inner float32 op must itself be processed by the preceding rule. This is three fallback instances, not one universal rule enabled for all supported native ops.

### codegen/decomp/transcendental.py:L276 — SQRT through power, then log/exp

[Source](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L276).

**Match/guard:** SQRT when unsupported or forced.

**How to read this rule:** For positive x, `sqrt(x)=x**0.5=2**(0.5*log2(x))`. That lets the compiler reuse two existing software functions, but also inherits their approximation and edge-case behavior; it is not the same algorithm as a device's dedicated square-root instruction.

**Result/example:** `SQRT(9) → xpow(9,0.5) → EXP2(0.5*LOG2(9))`, approximately 3. [xpow](../../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L257) computes the positive-magnitude result and handles negative-base exponent rules with selects: noninteger exponent gives NaN except its special -inf behavior; odd integer exponent negates; exponent zero returns 1 including zero/infinity bases.

**Why (inferred):** reuse existing primitive decompositions instead of a separate square-root iteration.

**Sharp edge:** this is approximate and not necessarily correctly rounded like a native sqrt. Moreover the helper's explicit `-inf` exception means `SQRT(-inf)` follows magnitude power to +inf rather than the usual NaN sqrt contract; do not advertise unconditional IEEE equivalence. The helper tests exponent integrality/parity through int32 casts, so general xpow with huge exponents has additional limitations even though this rule uses fixed 0.5.

## Exercises that test the reason, not just the pattern spelling

1. **Why does RMSNorm's reciprocal square root become expensive on an emulated backend?** Trace `SQRT(mean(x²)+eps)` through L276, then L272 LOG2 and EXP2; identify polynomial ALU, casts and bit manipulation. **Solution:** unsupported/forced SQRT uses exp2(log2(v)*0.5), so one source operation expands into two range reductions and polynomial evaluations. Its consumer RECIP may become FDIV. This affects per-kernel instruction count; it says nothing by itself about whether the scheduler fuses the reduction kernel with normalization.
2. **Why can replacing WHERE with multiply break int64 floor modulo?** **Solution:** L75 deliberately emits WHERE. Multiplication can combine with surrounding addition under op.py L119 into MULACC; dtype.py L170 matches that ALU but `l2i` has no MULACC arm and raises. Equivalent scalar algebra is insufficient for backend legality.
3. **Why is bfloat16 emulation not “cast everything to float32”?** **Solution:** storage remains uint16; L185 decodes loads, L201 encodes stores, L187/L190/L193 preserve the distinction between bitcast and numeric conversion, and arithmetic promotion changes intermediate rounding. Raw bits 0x3F80 mean 1.0, not integer 16256 converted to float.
4. **Find a case where one unguarded shift rewrite fails.** **Solution:** CDIV(-9,8) must be -1; plain arithmetic SHR gives -2. L94 adds 7 before the shift, while L70 intentionally does not because floor division wants -2.
