# x86 ISA renderer: every pattern rule

Pinned source: `107adc31701df0247dfa45e175984df906a68b53`. This page covers every tuple in all five `PatternMatcher` tables in [renderer/isa/x86.py](../../../../tinygrad/tinygrad/renderer/isa/x86.py). There are no generated matcher comprehensions in this file; dtype alternatives and helper-generated instruction sequences are explained inside each entry. The opcode encoding dictionary is a serializer, not another matcher.

Examples below are source-derived instruction/graph walkthroughs, not captured execution traces. “Explicit” means the rationale is stated by a local source comment; “inferred” means it follows from the implementation and operand constraints, not a verified account of the author’s original motivation. Register names are illustrative allocation choices. `GPR` holds scalar integers/pointers; `XMM` holds floating scalars and 128-bit packed data. `SS`/`SD` mean scalar single/double. An `i` opcode suffix represents an immediate form and `m` an encoding direction that may write memory.

The main hazards are that x86 flags are implicit shared state, many integer instructions overwrite an input, some instructions demand specific registers, and floating comparisons produce masks rather than the integer flag conditions tinygrad wants. These are separate from kernel fusion: the rules below implement already scheduled CPU kernels.

## Before reading instruction rules

Start with the [shared first-principles guide](../../first-principles.md) for graphs and lowering. Here the input is already a scheduled CPU kernel: the remaining problem is expressing its values and loops using the CPU's **instruction set architecture (ISA)**, the operations its machine code can request.

A Python expression can create as many named temporaries as you like. A CPU has a fixed number of **registers**, small named storage locations inside the processor. A **general-purpose register (GPR)** holds an integer or a memory address; `RAX` is a 64-bit example, `EAX` names its low 32 bits, `AX` its low 16, and `AL` its low 8. `RCX`/`ECX`/`CL` name analogous pieces of another register. `XMM0` is a different, 128-bit register used here for floating values and short vectors. Its four 32-bit **lanes** can hold `[a,b,c,d]`; a scalar float32 instruction operates on the low lane `a`. Register allocation chooses which physical register stores each temporary and when it can be reused.

Instruction operands have restrictions absent from Python. An **immediate** is a literal written inside an instruction's bytes, such as the `5` in `add eax,5`; its encoding has a limited width. A **two-address** instruction overwrites one input: `add eax,ebx` means `eax = eax + ebx`. For graph expression `z=x+y` where `x` remains needed, the compiler may first copy `x` to a new register. Some instructions require a particular register, such as `CL` for a variable shift count. A legal mathematical expression therefore often needs several preparation instructions.

**Flags** are shared CPU condition bits. `cmp eax,ebx` computes the conditions of a subtraction without storing the subtraction result; the zero flag means equality. `SETcc` writes a condition as byte `0` or `1`, `CMOVcc` conditionally copies a value, and `Jcc` conditionally jumps. The `cc` stands for the chosen condition: `E` equal, `NE` unequal, `L` signed less-than, `B` unsigned below. The sign flag records a result’s top bit; overflow records when a signed result does not fit; carry/borrow describes unsigned arithmetic crossing its range. That is why signed and unsigned comparisons use different conditions. An intervening addition can overwrite flags, so a graph edge to an old comparison is insufficient unless the compiler also preserves instruction order or repeats the comparison.

A **calling convention**, part of the **application binary interface (ABI)**, agrees where arguments arrive and what state a function must restore before returning. Some registers must retain the caller’s original values across this function: these are **callee-saved** registers. The **stack** is memory available for temporary storage and saved values; `RSP` points to its current top. A **stack frame** is the portion reserved for this call. A **spill** temporarily saves a register value into this memory when registers are scarce. Function-entry setup is the **prologue**, and exit cleanup is the **epilogue**. Alignment means an address is a multiple of a required byte boundary: `0x1000` is 16-byte aligned; `0x1004` is not.

Read the five tables as a sequence: `extra_matcher` rewrites unsupported operations; `pre_isel_matcher` prepares graph shapes; `isel_matcher` selects instructions and register classes; `pre_regalloc_matcher` prepares stack storage and flags; `post_regalloc_matcher` finishes instructions once registers and frame size are known. **isel** means instruction selection. A **pseudo-instruction** is a compiler placeholder such as `LOOP_CMP`, which must eventually become real instructions. `DEFINE` describes state already present on function entry; it does not mean the CPU must execute an instruction to invent that state.

In the bitwise examples, `AND` keeps a bit only when both inputs have it, `OR` when either has it, and `XOR` when exactly one has it. In code these are `&`, `|`, and `^`. Hexadecimal (`0x...`) writes four bits per digit, so `0xff` is eight one bits. A numeric **cast** converts a value to another number format; a **bitcast** reinterprets its representation.

Mnemonic details used below: `MOV` copies bits; `LEA` computes an address without reading the memory there. `SS`/`SD` mean scalar single/double precision; `PS`/`PD` mean packed single/double. A word is 16 bits, a doubleword (`dword`) 32, and a quadword (`qword`) 64. The `V` prefix marks instructions using the VEX encoding form; some scalar forms take an extra **merge source** to supply upper bits even though only the low result matters. `undef` says those otherwise unused bits need no chosen value, not that a meaningful input may be uninitialized. `NaN` means “not a number,” such as a floating result of an invalid operation. `FMA` is fused multiply-add, which rounds `a*b+c` once. `ALU` means arithmetic/logic operation. In this catalog, `STACK` joins vector elements; it is unrelated to the call stack described above.

## `extra_matcher`

### renderer/isa/x86.py:L92 — Boolean inequality is one XOR

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L92)

Matches boolean `x != y`; emits `x ^ y`.

**Example:** GPR bytes `1 != 0` become `1 XOR 0 = 1`.

**Why (explicit):** normalized boolean bits already encode the inequality truth table, so no compare/SETcc sequence is needed.

**Edge:** this identity requires canonical booleans; arbitrary nonzero integer encodings are not equivalent.

For booleans, the complete unequal cases are `0 XOR 1 = 1` and `1 XOR 0 = 1`; the equal cases both give zero. This works on the values themselves and leaves no comparison flags to keep alive.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var('x', dtypes.bool).ne(UPat.var('y')), lambda x,y: x^y)
```

</details>

### renderer/isa/x86.py:L93 — Boolean equality complements XOR

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L93)

Matches boolean equality; emits `(x ^ y) ^ True`.

**Example:** byte values `1 == 1` become `0 XOR 1 = 1`.

**Why (explicit):** equality is the complement of boolean inequality, expressible without flags.

**Edge:** XOR with one complements the low boolean bit, not an arbitrary integer word.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var('x', dtypes.bool).alu(Ops.CMPEQ, UPat.var('y')), lambda x,y: (x^y)^True)
```

</details>

### renderer/isa/x86.py:L94 — Boolean less-than is false-and-true

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L94)

Matches boolean `x < y`; emits `(x ^ True) & y`.

**Example:** `False < True` becomes `(0 XOR 1) AND 1 = 1`; `True < True` becomes zero.

**Why (explicit):** the only ordered boolean pair is `(0,1)`.

**Edge:** signed integer comparison rules cannot replace this identity for non-boolean inputs.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var('x', dtypes.bool)<UPat.var('y'), lambda x,y: (x^True)&y)
```

</details>

### renderer/isa/x86.py:L96 — Half-to-wide conversion takes a float32 bridge

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L96)

Matches float16 cast to float64 or any integer; inserts float32 first.

**Example:** half `3.5` in XMM becomes float32 `3.5`, then GPR int32 `3`.

**Why (explicit):** this backend has half/float32 conversion instructions but no direct half/integer or half/double conversions.

**Edge:** integer rounding/truncation is performed by the second conversion; this is not a bitcast.

The three representations are separate: half means a 16-bit floating encoding, float32 a 32-bit floating encoding, and int32 a 32-bit integer encoding. Each arrow converts the number; merely copying the half bits would not produce the integer 3.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float16).cast((dtypes.float64,)+dtypes.ints, name="x"), lambda y,x: y.cast(dtypes.float32).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L97 — Wide-to-half conversion takes a float32 bridge

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L97)

Matches float64/integer to float16; inserts float32 first.

**Example:** GPR int32 `7` → XMM float32 `7.0` → half `7.0`.

**Why (explicit):** the chosen half conversion instruction consumes float32.

**Edge:** two rounding steps can differ from an ideal direct float64-to-half conversion near rounding boundaries; the rule is the implemented path, not a proof of direct-rounding equivalence.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", (dtypes.float64,)+dtypes.ints).cast(dtypes.float16, name="x"), lambda y,x: y.cast(dtypes.float32).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L99 — Float-to-small-int conversion takes an int32 bridge

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L99)

Matches floating input cast to signed/unsigned 8- or 16-bit integer.

**Example:** float32 `258.9` → int32 `258` → uint8 `2`.

**Why (explicit):** available scalar float-to-integer conversion writes a 32/64-bit GPR, so the final truncation supplies the small result.

**Edge:** out-of-range floating conversion follows the intermediate instruction semantics before narrowing.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.floats).cast(dtypes.int8s+dtypes.int16s, name="x"), lambda y,x: y.cast(dtypes.int32).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L100 — Small-int-to-float first extends to int32

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L100)

Matches bool/int8/uint8/int16/uint16 cast to any float.

**Example:** uint8 `255` is zero-extended to int32 `255`, then converted to XMM float32 `255.0`; int8 `-1` sign-extends.

**Why (explicit):** scalar conversion consumes a signed 32/64-bit GPR.

**Edge:** preserving source signedness during extension is essential; interpreting byte `0xff` as signed would change uint8 conversion.

Zero-extension fills new upper bits with zeros; sign-extension repeats the old sign bit. Thus widening `uint8(255)` must produce `0x000000ff`, while widening `int8(-1)` must produce `0xffffffff`.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", (dtypes.bool,)+dtypes.int8s+dtypes.int16s).cast(dtypes.floats, name="x"), lambda y,x: y.cast(dtypes.int32).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L102 — Uint32-to-float uses a signed 64-bit container

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L102)

Matches uint32 to any float; inserts int64.

**Example:** uint32 `0xffffffff` → int64 `4294967295` → float64 `4294967295.0`.

**Why (explicit):** the conversion instructions accept signed integers, while all uint32 values fit signed int64.

**Edge:** an int32 bitcast would produce `-1`; later uint32 widening relies on x86 zero-upper-half behavior.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.uint32).cast(dtypes.floats, name="x"), lambda y,x: y.cast(dtypes.int64).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L104 — Uint64-to-float separates the low bit

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L104)

Matches uint64 to float; computes `float(int64(y >> 1))*2 + float(int64(y & 1))`.

**Example:** `y=2^63+3`: the high part is signed-safe `2^62+1`, the low part is `1`, then they recombine in floating arithmetic.

**Why (explicit):** no positive signed int64 can represent the full uint64 domain.

**Edge:** intermediate rounding means this formula should not be assumed equivalent to a single correctly rounded unsigned conversion at all boundaries.

The integer decomposition is `y = 2*(y >> 1) + (y & 1)`: divide by two without a remainder, then remember the dropped low bit. It makes both pieces fit the signed conversion instruction; the subsequent floating additions still have finite precision.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.uint64).cast(dtypes.floats, name="x"), lambda y,x:
   (y >> 1).cast(dtypes.int64).cast(x.dtype) * 2 + (y & 1).cast(dtypes.int64).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L107 — Byte multiplication runs in int16

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L107)

Matches multiplication with an int8/uint8 first operand; widens both inputs to int16 and narrows the product.

**Example:** uint8 `200*2` → int16 `400` → uint8 `144`.

**Why (explicit):** the normal two-operand multiply form used here lacks an 8-bit variant.

**Edge:** narrowing preserves low product bits, not saturation; uint8 inputs must extend with their original signedness.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.int8s) * UPat.var("b"), lambda a,b: (a.cast(dtypes.int16) * b.cast(dtypes.int16)).cast(a.dtype))
```

</details>

### renderer/isa/x86.py:L108 — Byte conditional select runs in int16

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L108)

Matches WHERE with bool/int8/uint8 true value; casts both values to int16, selects, and narrows.

**Example:** `m ? uint8(250) : uint8(3)` selects GPR word `250` or `3`, then keeps the low byte.

**Why (explicit):** CMOV has no 8-bit result form.

**Edge:** a bool mask stays a predicate; only selected values are widened.

A conditional move is a register-to-register selection: begin with the false value, then overwrite it if flags say true. The extra widening is necessary because the instruction offers 16/32/64-bit destinations but no byte destination.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("m").where(UPat.var("a", (dtypes.bool,)+dtypes.int8s), UPat.var("b")),
   lambda m,a,b: m.where(a.cast(dtypes.int16), b.cast(dtypes.int16)).cast(a.dtype))
```

</details>

### renderer/isa/x86.py:L111 — Half arithmetic runs in float32

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L111)

Matches an ALU node whose result dtype is float16; widens non-bool inputs to float32, rebuilds the operation, then narrows.

**Example:** half `a*b` → float32 multiply in XMM → half conversion.

**Why (explicit):** the backend uses float32 scalar arithmetic rather than native half ALU instructions.

**Edge:** boolean WHERE conditions must remain boolean; rounding occurs at the replacement result, and this is not permission to fuse multiple half operations across required rounding points.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(GroupOp.ALU, dtypes.float16, name="x"), lambda x: UOp(x.op,
   src=tuple(s.cast(dtypes.float) if s.dtype != dtypes.bool else s for s in x.src)).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L113 — Half comparisons also widen their inputs

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L113)

Matches a comparison with half operands; casts both inputs to float32, performs the same comparison, and casts the result to the original result dtype.

**Example:** half `1.5 < 2.0` → float32 comparison → boolean true.

**Why (inferred):** the preceding half-result ALU rule does not catch comparisons, whose result is bool.

**Edge:** this separate rule matters for NaNs as well as ordinary values; it retains the comparison opcode.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(GroupOp.Comparison, src=[UPat(dtype=dtypes.float16), UPat()], name="x"),
   lambda x: UOp(x.op, src=tuple(s.cast(dtypes.float32) for s in x.src)).cast(x.dtype))
```

</details>

### renderer/isa/x86.py:L116 — Float selects need masks as wide as their values

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L116)

Matches boolean WHERE selecting floating values, but only rewrites when the condition source promotion dtype differs from the selected float dtype. It makes `float(m) != 0` the new condition.

**Example:** integer-derived bool selecting float64 values becomes a double-width comparison mask consumed by VBLENDVPD.

**Why (explicit):** blend reads the sign bit of each value-width lane; a one-byte `1` is not such a mask.

**Edge:** the dtype guard prevents endlessly rebuilding an already suitable comparison.

For example, float32 “true” for a blend is a lane with bits `0xffffffff`, whose top bit is 1. A byte boolean has bits `00000001`; placing that unchanged in a wider lane leaves its top bit zero, so the blend would select the false input.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("m", dtypes.bool).where(UPat.var("a", dtypes.floats+(dtypes.weakfloat,)), UPat.var("b")).named("w"),
   lambda m,a,b,w: m.cast(w.dtype).ne(0).where(a, b) if w.dtype in dtypes.floats and promo_dtype(m.src) is not w.dtype else None)
```

</details>

### renderer/isa/x86.py:L119 — Negation becomes subtraction from zero

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L119)

Matches NEG; replaces it with `0 - input` at the same dtype.

**Example:** int32 `-eax` becomes `0 - eax`; float32 negation follows the same graph rewrite.

**Why (explicit transformation, inferred motivation):** SUB already has selection rules, reducing the backend opcode surface.

**Edge:** for IEEE floating signed zero, subtraction from positive zero is not identical to toggling the sign bit; do not read this as bitwise negation.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.NEG, name="x"), lambda x: UOp(Ops.SUB, src=(x.const_like(0),) + x.src))
```

</details>

### renderer/isa/x86.py:L121 — Remainder is reconstructed from quotient

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L121)

Matches CMOD `x % y`; emits `x - y*CDIV(x,y)`.

**Example:** signed `-7 % 3` with truncating division gives `-7 - 3*(-2) = -1`.

**Why (explicit):** the backend cannot yet expose the second output of multi-result integer division, where x86 places the remainder.

**Edge:** division by zero/overflow remain division problems; this is C-style truncating remainder, not floor-modulo.

Python instead gives `-7 % 3 == 2`, because Python pairs remainder with division rounded down. Here division truncates toward zero (`-7/3 → -2`), and the matching remainder is `-1`. That convention is part of the operation being lowered.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMOD, src=(UPat.var("x"), UPat.var("y"))), lambda x,y: x - y * x.alu(Ops.CDIV, y))
```

</details>

## `pre_isel_matcher`

### renderer/isa/x86.py:L150 — Uint32 widening needs no arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L150)

Matches uint32 CAST to int64/uint64; changes the opcode to BITCAST.

**Example:** writing EAX with `0xffffffff` clears upper RAX, so viewing RAX yields `4294967295`.

**Why (explicit):** x86 32-bit writes zero the upper register half.

**Edge:** this backend-specific width-changing BITCAST runs after normal graph verification; moving it earlier would violate normal dtype expectations.

`EAX` and `RAX` are overlapping names, not independent storage. After a write to EAX, RAX already contains `0x00000000ffffffff`; there are no extra high bits left to clear.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.uint32).cast(dtypes.int64s, name="x"), lambda x: x.replace(op=Ops.BITCAST))
```

</details>

### renderer/isa/x86.py:L151 — Equal-width integer casts become bitcasts

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L151)

Matches integer/bool to integer CAST, guarded by equal itemsize.

**Example:** int32 `-1` → uint32 reuses GPR bits `0xffffffff`.

**Why (inferred):** signedness changes interpretation without changing representation.

**Edge:** the guard excludes extensions; bool-to-uint8 is covered by equal byte size, but uint8-to-int64 is not.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.ints+(dtypes.bool,)).cast(dtypes.ints, name="x"),
   lambda y,x: x.replace(op=Ops.BITCAST) if x.dtype.itemsize == y.dtype.itemsize else None)
```

</details>

### renderer/isa/x86.py:L154 — Predicated loads select a real or scratch address

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L154)

Matches gated LOAD from INDEX/SHRINK. Allocates scratch sized for the result, stores the alternate value there, selects real address or scratch address, and issues an unconditional load ordered AFTER that scratch store.

**Example:** `gate ? A[i] : 9` becomes scratch=`9`; `p=gate?&A[i]:&scratch`; `load(p)`.

**Why (explicit):** this scalar backend implements predication with address CMOV.

**Edge:** selecting loaded values instead would still dereference an invalid A[i]; the AFTER edge is essential to initialize the fallback before reading it.

“Gated” means the load is enabled only when a condition is true. With `i=100` for a four-element array and `gate=False`, the address selection sends the actual read to initialized scratch. Computing `load(A[100])` first and then selecting its result would already have made the invalid read.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat((Ops.INDEX, Ops.SHRINK), name="addr").load(UPat.var("alt"), UPat.var("gate"), name="x"), gated_load)
```

</details>

### renderer/isa/x86.py:L155 — Predicated stores redirect disabled writes to scratch

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L155)

Matches gated STORE to INDEX/SHRINK; allocates scratch, selects destination address, and issues unconditional store through AFTER.

**Example:** `if gate: A[i]=7` becomes `store(gate?&A[i]:&scratch,7)`.

**Why (explicit):** address selection supplies predication without conditional-store instructions.

**Edge:** the false path still performs a memory write, but into private scratch; replacing it with a dummy global address would be unsafe.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat((Ops.INDEX, Ops.SHRINK), name="addr").store(UPat.var("val"), UPat.var("gate")), gated_store)
```

</details>

### renderer/isa/x86.py:L157 — Backedge predicates must produce usable integer flags

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L157)

Matches END with a boolean third source; uses `flag_gate` to replace a non-integer-comparison predicate with `m != int32(0)`.

**Example:** floating `a<b` backedge first materializes a boolean, then compares it to zero before the jump.

**Why (explicit):** floating masks do not provide the integer condition flags this path consumes.

**Edge:** an existing integer comparison is left alone; float NaN flag behavior is deliberately not used.

A backedge is the jump from the end of a loop back to its start. This rule turns a boolean result into the kind of comparison state the eventual loop jump can read.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.END, src=(UPat(), UPat(), UPat.var("m", dtypes.bool)), name="x"),
   lambda m,x: x.replace(src=x.src[:2]+(g,)) if (g:=flag_gate(m)) is not None else None)
```

</details>

## `isel_matcher`

### renderer/isa/x86.py:L322 — Loop constant bounds become tagged immediates

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L322)

Matches RANGE whose first source is a cast constant; preserves other sources and changes the bound to `imm(range.dtype,c)`.

**Example:** RANGE(16) keeps bound `16` as an immediate for a later `CMPi counter,16`.

**Why (inferred):** prevents pointless constant register allocation while deferring control-flow expansion.

**Edge:** this matches a literal bound, not an arbitrary invariant expression; imm truncates to the requested dtype.

If the loop runs 16 times, the number 16 need not occupy one of the few registers throughout the loop. It can be stored directly in the bytes of the eventual compare instruction.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.RANGE, src=(UPat.cvar("c").cast(),), allow_any_len=True, name="x"), lambda c,x: x.replace(src=(imm(x.dtype, c.val),) + x.src[1:]))
```

</details>

### renderer/isa/x86.py:L324 — Conditional END preserves a delayed loop compare

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L324)

Matches END with a comparison as third source; emits LOOP_CMP carrying comparison operands, original END dependencies, and comparison opcode in its tag.

**Example:** END(body,range,i<16) becomes LOOP_CMP(i,16,body,range), tagged CMPLT.

**Why (explicit):** it is effectively a branch back to the range label, whose identity must survive register allocation.

**Edge:** LOOP_CMP is a pseudo-op; directly encoding or allocating a normal result register for it is wrong.

The compiler has not yet assigned final registers or machine-code positions. Keeping “compare these values, then jump back to this range” together postpones the address calculation while preserving which loop is meant.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.END, src=(UPat(), UPat(), UPat(GroupOp.Comparison, name="cond")), name="x"),
    lambda x,cond: cond.ins(X86Ops.LOOP_CMP, tag=cond.op, src=cond.src + x.src[:2]))
```

</details>

### renderer/isa/x86.py:L329 — RET models callee-saved register preservation

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L329)

Matches SINK unless already wrapped in RET. Adds RET depending on outputs, RSP DEFINE, and DEFINEs for callee-saved registers.

**Example:** a kernel using RBX acquires a live entry RBX value reaching RET, allowing allocator save/restore around its use.

**Why (explicit):** the ordinary allocator constructs the prologue/epilogue through these liveness constraints.

**Edge:** Windows also preserves RSI/RDI and XMM6–15; ABI register sets are platform-dependent.

Suppose the caller has an important value in RBX. The generated kernel may use RBX internally, but must put that original value back before `RET` returns. Keeping the incoming RBX value live until the return tells the allocator it must preserve it, for example by saving it to the stack.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.SINK, name="x"), lambda x:
   x.replace(src=(x.ins(X86Ops.RET, src=x.src + (stack_pointer,) + tuple(def_reg(dtypes.uint64, r) for r in CALLEE_SAVED)),))
    if not x.src or x.src[0].op is not Ops.INS or x.src[0].arg[0] is not X86Ops.RET else None)
```

</details>

### renderer/isa/x86.py:L333 — Parameters acquire ABI locations

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L333)

Matches PARAM/SPECIAL without an existing tuple tag. `abi` finds argument position, assigns ABI register or stack address, then MOVs into an unconstrained result; buffer values become uint64 pointers and shape sources are tagged non-values.

**Example:** SysV argument zero arrives in RDI, argument six at entry `[rsp+8]`; Windows uses RCX first and a different stack offset.

**Why (explicit):** runtime calling convention fixes entry locations but should not constrain all later uses.

**Edge:** FRAME_INDEX must account for the eventually allocated stack frame.

SysV is the System V calling convention used on common Unix-like x86-64 systems. For the argument cases here, `[rsp+8]` means read memory eight bytes above the entry stack pointer; the return address occupies the first eight bytes. The initial MOV frees later code to move the argument away from its required entry register.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat((Ops.PARAM, Ops.SPECIAL), name="x"), abi)
```

</details>

### renderer/isa/x86.py:L335 — Address select materializes both effective addresses

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L335)

Matches WHERE selecting two INDEX/SHRINK nodes, guarded against a vector-register first base. Emits WHERE of two LEAs.

**Example:** `m?&A[i]:&scratch[0]` becomes uint64 GPR pointers before CMOV.

**Why (inferred):** a conditional move chooses values, while address expressions contain base/index/displacement structure.

**Edge:** vector INDEX means lane extraction and must not be treated as a pointer; the guard distinguishes those representations.

For a float32 array starting at byte address `0x1000`, `&A[3]` is address `0x100c`. LEA computes that number without reading `A[3]`; the conditional move can then choose between that number and a scratch address.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("m").where(UPat((Ops.INDEX, Ops.SHRINK), name="a"), UPat((Ops.INDEX, Ops.SHRINK), name="b")), lambda m,a,b:
   m.where(lea(a), lea(b)) if not _is_vec_xmm(a.src[0]) else None)
```

</details>

### renderer/isa/x86.py:L338 — Int64 constants get full-width materialization

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L338)

Matches untagged int64/uint64 constant CAST; emits MOVABS with typed immediate.

**Example:** `0x123456789abcdef0` becomes a 64-bit immediate into RAX.

**Why (inferred):** ordinary arithmetic immediates cannot encode arbitrary 64-bit values.

**Edge:** tagged constants already serving as immediates must not be recursively materialized; this rule is also the fallback for small 64-bit constants not consumed earlier.

Materialization means creating a register value explicitly. For a large literal, a later addition may therefore become `movabs temp,0x123456789abcdef0; add dst,temp` instead of trying to fit the literal in the addition instruction.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.cvar("c").cast(dtypes.int64s, name="x"), lambda c,x: x.ins(X86Ops.MOVABS, src=(imm(x.dtype, c.val),)) if not x.tag else None)
```

</details>

### renderer/isa/x86.py:L339 — Smaller integer constants get MOV-immediate

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L339)

Matches untagged integer/bool constant CAST after the 64-bit rule; emits MOVi.

**Example:** int32 `17` → `mov eax,17`; bool true → byte-sized move.

**Why (inferred):** values not folded into a consumer need an actual GPR definition.

**Edge:** rule order keeps 64-bit constants on the MOVABS path, and the tag guard keeps instruction immediates immediate.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.cvar("c").cast(dtypes.ints+(dtypes.bool,), name="x"), lambda c,x: x.ins(X86Ops.MOVi, src=(imm(x.dtype, c.val),)) if not x.tag else None)
```

</details>

### renderer/isa/x86.py:L340 — Float constants travel as integer bit patterns

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L340)

Matches untagged floating constant CAST; packs bytes in that float format, unpacks corresponding signed integer bits, then BITCASTs back to float.

**Example:** float32 `1.0` → int32 `0x3f800000` → VMOVD into XMM.

**Why (inferred):** scalar arithmetic instructions have no floating immediate field; materializing integer bits avoids a constant-memory pool.

**Edge:** float16 and float64 use different integer widths; numerical int-to-float conversion would produce the wrong value.

The hexadecimal value `0x3f800000` is the float32 *encoding* of 1.0. Numeric conversion of that integer would yield 1065353216.0; moving its bits to the floating register instead yields the intended 1.0.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.cvar("c").cast(dtypes.floats, name="x"), lambda c,x:
   UOp.cconst(struct.unpack((dt:=to_int(x.dtype)).fmt, struct.pack(x.dtype.fmt, c.val))[0], dt).bitcast(x.dtype) if not x.tag else None)
```

</details>

### renderer/isa/x86.py:L343 — Float32 WHERE uses a full-lane comparison mask

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L343)

Matches float32 comparison used to select float32 values; emits VBLENDVPS(false,true,mask(comparison)).

**Example:** `a<b ? x : y` → VCMPSS mask plus `vblendvps xmmD,xmmY,xmmX,xmmMask`.

**Why (explicit):** VCMPSS produces all-ones/zero lane masks, and blend selects by mask sign bit.

**Edge:** mask predicates are LT=1, NE=4, EQ=0; the source explicitly avoids ordinary floating flag compares because NaNs break integer-style conditions.

For `a=1,b=2,x=10,y=20`, comparison creates a true mask with every low-lane bit set. The blend receives `(20,10,true_mask)` and produces 10. This is data selection within the existing kernel, not a conditional kernel launch.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(GroupOp.Comparison, src=(UPat(dtype=dtypes.float32), UPat()), name="m").where(UPat.var("a", dtypes.float32), UPat.var("b")), lambda m,a,b:
   a.ins(X86Ops.VBLENDVPS, src=(b, a, mask(m))))
```

</details>

### renderer/isa/x86.py:L345 — Float64 WHERE uses a double-width mask

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L345)

Matches float64 comparison selecting float64 values; emits VBLENDVPD(false,true,VCMPSD mask).

**Example:** double `a==b ? x : y` uses predicate immediate zero and a 64-bit mask lane.

**Why (explicit):** the selected lane width and mask width must agree.

**Edge:** a float32 mask has the wrong bit position for double blend; this is why legalization may rebuild the predicate at the selected dtype.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(GroupOp.Comparison, src=(UPat(dtype=dtypes.float64), UPat()), name="m").where(UPat.var("a", dtypes.float64), UPat.var("b")), lambda m,a,b:
   a.ins(X86Ops.VBLENDVPD, src=(b, a, mask(m))))
```

</details>

### renderer/isa/x86.py:L348 — A floating comparison used as a value becomes bool

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L348)

Matches remaining float32/float64 comparisons; creates the XMM mask, bitcasts to same-width integer, ANDs with one, and bitcasts to bool.

**Example:** `store(bool(a<b))` takes mask `0xffffffff` through GPR AND 1 to byte true.

**Why (explicit):** an all-ones mask is suitable for blending but users expect canonical 0/1 booleans.

**Edge:** WHERE consumers match earlier to avoid this unnecessary mask→GPR→mask conversion.

The intermediate steps are `0xffffffff & 1 = 1` for true and `0x00000000 & 1 = 0` for false. The mask and the final boolean describe the same condition but use different bit representations for different consumers.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(GroupOp.Comparison, src=(UPat.var("y", (dtypes.float32, dtypes.float64)), UPat()), name="x"), lambda y,x:
   UOp(Ops.AND, src=(mask(x).bitcast(dt:=to_int(y.dtype)), UOp.cconst(1, dt))).bitcast(dtypes.bool))
```

</details>

### renderer/isa/x86.py:L353 — Non-flag WHERE gates become integer comparisons

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L353)

Matches boolean WHERE and rewrites only if `flag_gate` says its predicate is not already an integer comparison.

**Example:** byte bool in AL selecting int32 values becomes int32(bool) != 0, then CMOVNE.

**Why (explicit):** CMOV reads flags, not a boolean register.

**Edge:** placing this before float blend rules would destroy their direct comparison-mask path; comparing to int32 zero intentionally avoids byte-compare code differences.

A register holding the number 1 is not itself a CPU flag. Comparing that number with zero establishes the flags; CMOVNE then means “copy the true value when the comparison says not equal.”

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("m", dtypes.bool).where(UPat.var("a"), UPat.var("b")), lambda m,a,b: g.where(a, b) if (g:=flag_gate(m)) is not None else None)
```

</details>

### renderer/isa/x86.py:L354 — Signed less-than select

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L354)

Matches signed-integer CMPLT used as WHERE; emits `CMOVL` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise. The source order is `(false,true,compare)` so the false value is the initial destination.

**Example:** int32 -1 < 2 chooses the true GPR value.

**Why (inferred from the emitted instruction):** signed less-than interprets sign and overflow flags together.

**Edge:** This rule must precede unsigned/general CMPLT; the sign bit alone is insufficient after subtraction overflow.

Signed integers include negative values. Comparing `-1` with `2` needs signed ordering even though the bit pattern for `-1` is a large positive number when interpreted unsigned.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPLT, src=(UPat(dtype=dtypes.sints), UPat()), name="m").where(UPat.var("a"), UPat.var("b")), lambda m,a,b:
   a.ins(X86Ops.CMOVL, src=(b, a, cmp(m))))
```

</details>

### renderer/isa/x86.py:L356 — Unsigned less-than select

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L356)

Matches remaining CMPLT used as WHERE; emits `CMOVB` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise. The source order is `(false,true,compare)` so the false value is the initial destination.

**Example:** uint32 0xffffffff < 2 chooses the false value.

**Why (inferred from the emitted instruction):** unsigned below reads carry from integer subtraction.

**Edge:** Float conditions must have been lowered to masks or integer booleans; cmp explicitly rejects float inputs.

Unsigned `0xffffffff` is 4294967295, so it is not below 2. Reusing the signed less-than rule would interpret the same bits as -1 and choose the wrong value.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPLT, name="m").where(UPat.var("a"), UPat.var("b")), lambda m,a,b: a.ins(X86Ops.CMOVB, src=(b, a, cmp(m))))
```

</details>

### renderer/isa/x86.py:L357 — Equality select

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L357)

Matches CMPEQ used as WHERE; emits `CMOVE` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise. The source order is `(false,true,compare)` so the false value is the initial destination.

**Example:** int32 7 == 7 chooses true.

**Why (inferred from the emitted instruction):** zero flag records equal integer operands.

**Edge:** Both selected GPR values exist before CMOV; this does not make their computations conditional.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPEQ, name="m").where(UPat.var("a"), UPat.var("b")), lambda m,a,b: a.ins(X86Ops.CMOVE, src=(b, a, cmp(m))))
```

</details>

### renderer/isa/x86.py:L358 — Inequality select

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L358)

Matches CMPNE used as WHERE; emits `CMOVNE` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise. The source order is `(false,true,compare)` so the false value is the initial destination.

**Example:** int32 7 != 8 chooses true.

**Why (inferred from the emitted instruction):** clear zero flag records unequal integer operands.

**Edge:** CMOV is two-address: false value must occupy the destination before conditional replacement.

For `m ? a : b`, the final sequence is conceptually `dst=b; compare; if unequal: dst=a`. This explains the otherwise surprising `(false,true,compare)` source order.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPNE, name="m").where(UPat.var("a"), UPat.var("b")), lambda m,a,b: a.ins(X86Ops.CMOVNE, src=(b, a, cmp(m))))
```

</details>

### renderer/isa/x86.py:L360 — Unsigned less-than branch

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L360)

Matches IF whose CMPLT operands are unsigned; emits `JB` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** uint32 3 < 8 branches.

**Why (inferred from the emitted instruction):** carry implements unsigned below.

**Edge:** The jump target is attached later; comparison operands must remain the ones that set the consumed flags.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.IF, src=(UPat(Ops.CMPLT, src=(UPat(dtype=dtypes.uints), UPat()), name="y"),), name="x"), lambda y,x: x.ins(X86Ops.JB, src=(cmp(y),)))
```

</details>

### renderer/isa/x86.py:L361 — Signed less-than branch

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L361)

Matches remaining IF(CMPLT); emits `JL` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** int32 -3 < 0 branches.

**Why (inferred from the emitted instruction):** signed-less flags preserve signed order.

**Edge:** Unsigned matching must occur first; this fallback is not a floating comparison implementation.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.IF, src=(UPat(Ops.CMPLT, name="y"),), name="x"), lambda y,x: x.ins(X86Ops.JL, src=(cmp(y),)))
```

</details>

### renderer/isa/x86.py:L362 — Equality branch

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L362)

Matches IF(CMPEQ); emits `JE` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** counter == 16 branches.

**Why (inferred from the emitted instruction):** zero flag supplies equality without a boolean temporary.

**Edge:** A scheduled intervening flag writer requires the later rematerialization rule.

A branch changes which instruction runs next; it does not need to store the condition in a boolean register first. The comparison flags are enough, provided nothing overwrites them before the jump.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.IF, src=(UPat(Ops.CMPEQ, name="y"),), name="x"), lambda y,x: x.ins(X86Ops.JE, src=(cmp(y),)))
```

</details>

### renderer/isa/x86.py:L363 — Inequality branch

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L363)

Matches IF(CMPNE); emits `JNE` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** counter != 16 branches.

**Why (inferred from the emitted instruction):** clear zero flag supplies inequality.

**Edge:** The branch consumes a comparison dependency, not an arbitrary boolean GPR.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.IF, src=(UPat(Ops.CMPNE, name="y"),), name="x"), lambda y,x: x.ins(X86Ops.JNE, src=(cmp(y),)))
```

</details>

### renderer/isa/x86.py:L365 — Unsigned comparison materializes a byte

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L365)

Matches unsigned CMPLT used as a value; emits `SETB` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** uint32 3 < 8 writes byte 1.

**Why (inferred from the emitted instruction):** SETcc turns transient flags into a persistent boolean value.

**Edge:** The result is byte-sized; later use as wider integer must zero-extend.

A value consumer could be a store into a boolean output array. Flags alone cannot be stored as that array element; SETB turns the condition into an ordinary byte value.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPLT, src=(UPat(dtype=dtypes.uints), UPat()), name="x"), lambda x: x.ins(X86Ops.SETB, src=(cmp(x),)))
```

</details>

### renderer/isa/x86.py:L366 — Signed comparison materializes a byte

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L366)

Matches remaining CMPLT used as a value; emits `SETL` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** int32 -3 < 0 writes byte 1.

**Why (inferred from the emitted instruction):** a boolean dataflow user needs a GPR result, not flags alone.

**Edge:** Earlier float and unsigned patterns must take their specialized paths.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPLT, name="x"), lambda x: x.ins(X86Ops.SETL, src=(cmp(x),)))
```

</details>

### renderer/isa/x86.py:L367 — Equality materializes a byte

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L367)

Matches remaining CMPEQ used as a value; emits `SETE` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** int32 4 == 4 writes byte 1.

**Why (inferred from the emitted instruction):** canonical boolean representation is 0 or 1.

**Edge:** An equality WHERE matches earlier and can consume flags directly.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPEQ, name="x"), lambda x: x.ins(X86Ops.SETE, src=(cmp(x),)))
```

</details>

### renderer/isa/x86.py:L368 — Inequality materializes a byte

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L368)

Matches remaining CMPNE used as a value; emits `SETNE` with a dependency on `cmp`, which selects CMPi for an encodable immediate and CMP otherwise.

**Example:** int32 4 != 4 writes byte 0.

**Why (inferred from the emitted instruction):** canonical boolean representation is 0 or 1.

**Edge:** Do not substitute the all-ones XMM masks used for floating blend.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.CMPNE, name="x"), lambda x: x.ins(X86Ops.SETNE, src=(cmp(x),)))
```

</details>

### renderer/isa/x86.py:L370 — float32 sqrt

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L370)

Matches float32 sqrt; emits `VSQRTSS` with the input duplicated as the VEX merge source and arithmetic source.

**Example:** sqrt(9.0) in XMM1 → 3.0 in the low destination lane.

**Why (inferred):** directly implements the scalar operation while filling the instruction’s extra merge operand.

**Edge:** SS means scalar single and SD scalar double; these rules do not compute all packed lanes. Negative arguments retain the hardware floating behavior, rather than an integer square-root interpretation.

The duplicated source does not compute two square roots. One occurrence supplies the number to square-root; the other fills an encoding operand responsible for upper register bits.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float32).sqrt().named("x"), lambda y,x: x.ins(X86Ops.VSQRTSS, src=(y, y)))
```

</details>

### renderer/isa/x86.py:L371 — float64 sqrt

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L371)

Matches float64 sqrt; emits `VSQRTSD` with the input duplicated as the VEX merge source and arithmetic source.

**Example:** sqrt(9.0) in XMM1 → 3.0 in the low destination lane.

**Why (inferred):** directly implements the scalar operation while filling the instruction’s extra merge operand.

**Edge:** SS means scalar single and SD scalar double; these rules do not compute all packed lanes. Negative arguments retain the hardware floating behavior, rather than an integer square-root interpretation.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float64).sqrt().named("x"), lambda y,x: x.ins(X86Ops.VSQRTSD, src=(y, y)))
```

</details>

### renderer/isa/x86.py:L372 — float32 trunc

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L372)

Matches float32 trunc; emits `VROUNDSS` with the input duplicated as the VEX merge source and arithmetic source and uint8 immediate 3 (round toward zero).

**Example:** trunc(-3.75) in XMM1 → -3.0 in the low destination lane.

**Why (inferred):** directly implements the scalar operation while filling the instruction’s extra merge operand.

**Edge:** SS means scalar single and SD scalar double; these rules do not compute all packed lanes. Rounding-mode immediate 3 is essential; nearest-even would produce -4.0.

Truncation removes the fractional part toward zero: `-3.75 → -3.0`. The result is still floating point; a later integer cast would be a separate operation.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float32).trunc().named("x"), lambda y,x: x.ins(X86Ops.VROUNDSS, src=(y, y, imm(dtypes.uint8, 3))))
```

</details>

### renderer/isa/x86.py:L373 — float64 trunc

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L373)

Matches float64 trunc; emits `VROUNDSD` with the input duplicated as the VEX merge source and arithmetic source and uint8 immediate 3 (round toward zero).

**Example:** trunc(-3.75) in XMM1 → -3.0 in the low destination lane.

**Why (inferred):** directly implements the scalar operation while filling the instruction’s extra merge operand.

**Edge:** SS means scalar single and SD scalar double; these rules do not compute all packed lanes. Rounding-mode immediate 3 is essential; nearest-even would produce -4.0.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float64).trunc().named("x"), lambda y,x: x.ins(X86Ops.VROUNDSD, src=(y, y, imm(dtypes.uint8, 3))))
```

</details>

### renderer/isa/x86.py:L375 — Pack half lanes through integer registers

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L375)

Matches float16 STACK; bitcasts each half to int16 and inserts successive words into an XMM with VPINSRW, starting from undef.

**Example:** stack half `[1,2]` → GPR words `0x3c00,0x4000` → XMM words 0 and 1.

**Why (explicit):** a usable packing fallback exists through GPR word insertion.

**Edge:** source calls this suboptimal when inputs already reside in XMM and suggests VPUNPCKLWD; unused lanes remain undefined.

The vector is assembled one 16-bit slot at a time. The hex values are the encodings of half 1.0 and half 2.0, so insertion copies their bits without changing their numerical meaning.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.STACK, dtypes.float16, name="x"), lambda x: vpins(x, tuple(s.bitcast(dtypes.int16) for s in x.src)))
```

</details>

### renderer/isa/x86.py:L376 — Pack float32 lanes with insertion controls

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L376)

Matches float32 STACK; folds VINSERTPS over sources. Each immediate is `(source_lane<<6)|(destination_lane<<4)`.

**Example:** output `[a[2],b[0]]` uses controls `0x80` then `0x10` to place the chosen source lanes into output lanes 0 and 1.

**Why (explicit):** generic slow fallback when no stronger shuffle matches.

**Edge:** INDEX sources are peeled to their vector base and constant lane; controls encode lane positions, not byte offsets.

An insertion control tells the instruction both where to take an element from and where to put it. Here `0x80` selects source lane 2 and destination lane 0; `0x10` selects source lane 0 and destination lane 1.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.STACK, dtypes.float32, name="x"), vinsertps)
```

</details>

### renderer/isa/x86.py:L377 — Pack int32 lanes with GPR insertion

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L377)

Matches int32/uint32 STACK; folds VPINSRD from undef, selecting output lanes by immediate.

**Example:** `[eax=10,edx=20]` → `vpinsrd xmmD,undef,eax,0` followed by lane-1 insertion of EDX.

**Why (inferred):** scalar integers live in GPRs but packed loads/stores and lane operations use XMM.

**Edge:** unfilled upper lanes are undefined, and the helper only supports element sizes two/four bytes.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.STACK, dtypes.int32s, name="x"), lambda x: vpins(x, x.src))
```

</details>

### renderer/isa/x86.py:L379 — Extract a constant int32 vector lane

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L379)

Matches int32/uint32 INDEX with constant CAST index, guarded by `_is_vec_xmm(base)`. Emits VPEXTRD with a lane-number immediate.

**Example:** XMM `[10,20,30,40]`, index 2 → GPR `30`.

**Why (explicit):** INDEX here selects a register lane rather than computing a memory address.

**Edge:** a buffer with int32 element dtype is not an XMM value; omitting the guard would mistake pointer indexing for lane extraction.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.int32s).index(UPat.cvar("c").cast(), name="x"),
   lambda y,c,x: x.ins(X86Ops.VPEXTRD, src=(y, imm(dtypes.uint8, c.val))) if _is_vec_xmm(y) else None)
```

</details>

### renderer/isa/x86.py:L381 — Extract a float lane by shifting bytes

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L381)

Matches floating INDEX with constant index on an XMM vector; emits VPSRLDQ by `lane * element_size` bytes.

**Example:** float32 lane 2 moves to the low lane after shifting right by 8 bytes; half lane 3 shifts by 6.

**Why (inferred):** scalar float consumers read the low XMM lane, so a byte shift avoids moving through a GPR.

**Edge:** unlike VPEXTRD, the immediate is bytes; the result remains XMM, with other shifted lanes still present.

Think of moving `[a,b,c,d]` right by eight bytes when each element occupies four bytes. Element `c` lands in the low position where a scalar consumer expects its input; no array memory is read.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.floats).index(UPat.cvar("c").cast(), name="x"),
   lambda y,c,x: x.ins(X86Ops.VPSRLDQ, src=(y, imm(dtypes.uint8, c.val * x.dtype.itemsize))) if _is_vec_xmm(y) else None)
```

</details>

### renderer/isa/x86.py:L384 — Division pins dividend and remainder registers

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L384)

Matches integer CDIV; helper uses DIV for unsigned or IDIV for signed. It puts dividend in RAX, zero/sign-extends into RDX for widths above byte, constrains divisor away from RAX/RDX, emits division defining fixed registers, then MOVs the quotient to a freely allocatable value.

**Example:** int32 `-7/3`: EAX=-7, EDX=-1, divisor in EBX → quotient EAX=-2, remainder EDX=-1.

**Why (explicit):** x86 division has implicit operands/results; generic three-address allocation is illegal.

**Edge:** byte division instead widens AL into AX; only quotient is exposed, motivating the separate CMOD expansion.

The high register extends the dividend to twice its usual width before division. For signed -7, filling EDX with ones makes the EDX:EAX pair still represent -7. Putting the divisor in one of those registers would overwrite part of the dividend before the divide.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.ints).alu(Ops.CDIV, UPat())).named("x"), idiv)
```

</details>

### renderer/isa/x86.py:L386 — Immediate left shift

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L386)

Matches integer shift by a constant CAST; emits `SHLi` with uint8 immediate.

**Example:** uint32 3 << 2 → 12.

**Why (inferred):** the count fits the instruction’s immediate byte, avoiding the variable-count RCX constraint.

**Edge:** hardware masks shift counts by operand width; this rule itself does not prove an out-of-range count agrees with higher-level semantics.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints) << UPat.cvar("c").cast(), lambda a,c: a.ins(X86Ops.SHLi, src=(a, imm(dtypes.uint8, c.val))))
```

</details>

### renderer/isa/x86.py:L387 — Immediate unsigned right shift

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L387)

Matches unsigned integer shift by a constant CAST; emits `SHRi` with uint8 immediate.

**Example:** uint32 0x80000000 >> 1 → 0x40000000.

**Why (inferred):** logical shift inserts zeros, avoiding the variable-count RCX constraint.

**Edge:** hardware masks shift counts by operand width; this rule itself does not prove an out-of-range count agrees with higher-level semantics.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.uints) >> UPat.cvar("c").cast(), lambda a,c: a.ins(X86Ops.SHRi, src=(a, imm(dtypes.uint8, c.val))))
```

</details>

### renderer/isa/x86.py:L388 — Immediate signed right shift

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L388)

Matches signed integer shift by a constant CAST; emits `SARi` with uint8 immediate.

**Example:** int32 -8 >> 1 → -4.

**Why (inferred):** arithmetic shift replicates the sign bit, avoiding the variable-count RCX constraint.

**Edge:** hardware masks shift counts by operand width; this rule itself does not prove an out-of-range count agrees with higher-level semantics.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.sints) >> UPat.cvar("c").cast(), lambda a,c: a.ins(X86Ops.SARi, src=(a, imm(dtypes.uint8, c.val))))
```

</details>

### renderer/isa/x86.py:L389 — Immediate integer addition

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L389)

Matches `+` on integers with a constant CAST operand; emits `ADDi` only if `to_imm` succeeds.

**Example:** `eax=7; add eax,5 → 12`.

**Why (inferred):** embedding the literal removes a constant GPR and its materializing move.

**Edge:** a 64-bit operand accepts only a signed-int32-representable immediate here; `uint64(1<<40)` falls through to register materialization. This instruction is destructive/two-address after allocation; destination must preserve the other input first.

For `z=x+5`, allocation may choose the same register for `z` and `x` if the old `x` is dead. If a later expression still needs `x`, the compiler copies it before the destructive add.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints) + UPat.cvar().cast(name="c"), lambda a,c: a.ins(X86Ops.ADDi, src=(a, i)) if (i:=to_imm(c)) is not None else None)
```

</details>

### renderer/isa/x86.py:L390 — Immediate integer multiplication

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L390)

Matches `*` on integers with a constant CAST operand; emits `IMULi` only if `to_imm` succeeds.

**Example:** `eax=7; imul edx,eax,5 → 35`.

**Why (inferred):** embedding the literal removes a constant GPR and its materializing move.

**Edge:** a 64-bit operand accepts only a signed-int32-representable immediate here; `uint64(1<<40)` falls through to register materialization. IMULi has a separate destination and is not in TwoAddress.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints) * UPat.cvar().cast(name="c"), lambda a,c: a.ins(X86Ops.IMULi, src=(a, i)) if (i:=to_imm(c)) is not None else None)
```

</details>

### renderer/isa/x86.py:L391 — Immediate bitwise AND

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L391)

Matches `&` on integers/bool with a constant CAST operand; emits `ANDi` only if `to_imm` succeeds.

**Example:** `eax=0xab; and eax,15 → 11`.

**Why (inferred):** embedding the literal removes a constant GPR and its materializing move.

**Edge:** a 64-bit operand accepts only a signed-int32-representable immediate here; `uint64(1<<40)` falls through to register materialization. This instruction is destructive/two-address after allocation; destination must preserve the other input first.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints+(dtypes.bool,)) & UPat.cvar().cast(name="c"),
   lambda a,c: a.ins(X86Ops.ANDi, src=(a, i)) if (i:=to_imm(c)) is not None else None)
```

</details>

### renderer/isa/x86.py:L393 — Immediate bitwise OR

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L393)

Matches `|` on integers/bool with a constant CAST operand; emits `ORi` only if `to_imm` succeeds.

**Example:** `eax=0x10; or eax,3 → 0x13`.

**Why (inferred):** embedding the literal removes a constant GPR and its materializing move.

**Edge:** a 64-bit operand accepts only a signed-int32-representable immediate here; `uint64(1<<40)` falls through to register materialization. This instruction is destructive/two-address after allocation; destination must preserve the other input first.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints+(dtypes.bool,)) | UPat.cvar().cast(name="c"),
   lambda a,c: a.ins(X86Ops.ORi, src=(a, i)) if (i:=to_imm(c)) is not None else None)
```

</details>

### renderer/isa/x86.py:L395 — Immediate bitwise XOR

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L395)

Matches `^` on integers/bool with a constant CAST operand; emits `XORi` only if `to_imm` succeeds.

**Example:** `eax=0x13; xor eax,3 → 0x10`.

**Why (inferred):** embedding the literal removes a constant GPR and its materializing move.

**Edge:** a 64-bit operand accepts only a signed-int32-representable immediate here; `uint64(1<<40)` falls through to register materialization. This instruction is destructive/two-address after allocation; destination must preserve the other input first.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints+(dtypes.bool,)) ^ UPat.cvar().cast(name="c"),
   lambda a,c: a.ins(X86Ops.XORi, src=(a, i)) if (i:=to_imm(c)) is not None else None)
```

</details>

### renderer/isa/x86.py:L397 — Immediate integer subtraction

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L397)

Matches `SUB` on integers with a constant CAST operand; emits `SUBi` only if `to_imm` succeeds.

**Example:** `eax=7; sub eax,5 → 2`.

**Why (inferred):** embedding the literal removes a constant GPR and its materializing move.

**Edge:** a 64-bit operand accepts only a signed-int32-representable immediate here; `uint64(1<<40)` falls through to register materialization. This instruction is destructive/two-address after allocation; destination must preserve the other input first.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.SUB, dtypes.ints, (UPat.var("a"), UPat.cvar().cast(name="c"))),
   lambda a,c: a.ins(X86Ops.SUBi, src=(a, i)) if (i:=to_imm(c)) is not None else None)
```

</details>

### renderer/isa/x86.py:L400 — Variable left shift

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L400)

Matches integer shift after immediate cases; MOVs the count into RCX, constrains the value away from RCX, then emits `SHL`.

**Example:** `eax=3, cl=2 → eax=12`.

**Why (explicit):** this variable left shift implicitly consumes CL, not an arbitrary count register.

**Edge:** the value cannot also occupy RCX or installing the count would destroy it; the MOVs communicate that interference to allocation.

If the original value were in RCX, copying the shift count into CL would change its low byte. Reserving separate storage for the value avoids corrupting the number before shifting it.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.ints) << UPat()).named("x"), lambda x: shift(x, X86Ops.SHL))
```

</details>

### renderer/isa/x86.py:L401 — Variable unsigned right shift

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L401)

Matches unsigned integer shift after immediate cases; MOVs the count into RCX, constrains the value away from RCX, then emits `SHR`.

**Example:** `eax=0x80000000, cl=1 → eax=0x40000000`.

**Why (explicit):** this variable zero-filling right shift implicitly consumes CL, not an arbitrary count register.

**Edge:** the value cannot also occupy RCX or installing the count would destroy it; the MOVs communicate that interference to allocation.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.uints) >> UPat()).named("x"), lambda x: shift(x, X86Ops.SHR))
```

</details>

### renderer/isa/x86.py:L402 — Variable signed right shift

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L402)

Matches signed integer shift after immediate cases; MOVs the count into RCX, constrains the value away from RCX, then emits `SAR`.

**Example:** `eax=-8, cl=1 → eax=-4`.

**Why (explicit):** this variable sign-preserving right shift implicitly consumes CL, not an arbitrary count register.

**Edge:** the value cannot also occupy RCX or installing the count would destroy it; the MOVs communicate that interference to allocation.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.sints) >> UPat()).named("x"), lambda x: shift(x, X86Ops.SAR))
```

</details>

### renderer/isa/x86.py:L403 — Register integer addition

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L403)

Matches `+` with integers; emits `ADD(a,b)` after immediate-specific patterns decline.

**Example:** `eax=7, ebx=5 → eax=12`.

**Why (inferred):** this is the legal scalar GPR implementation and the fallback for non-encodable literals.

**Edge:** hardware overwrites its first operand, while the graph still has a separate result; post-allocation repair inserts a copy if they cannot coalesce. The instruction also clobbers flags, which later consumers may need regenerated.

“Coalesce” means assign the input and output to the same register when that reuse is safe. A flag clobber means this addition also changes the CPU condition bits, even if the graph only asks for its numeric result.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints) + UPat.var("b"), lambda a,b: a.ins(X86Ops.ADD, src=(a, b)))
```

</details>

### renderer/isa/x86.py:L404 — Register integer multiplication

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L404)

Matches `*` with integers; emits `IMUL(a,b)` after immediate-specific patterns decline.

**Example:** `eax=7, ebx=5 → eax=35`.

**Why (inferred):** this is the legal scalar GPR implementation and the fallback for non-encodable literals.

**Edge:** hardware overwrites its first operand, while the graph still has a separate result; post-allocation repair inserts a copy if they cannot coalesce. Byte multiplication was widened earlier because this form has no byte variant.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints) * UPat.var("b"), lambda a,b: a.ins(X86Ops.IMUL, src=(a, b)))
```

</details>

### renderer/isa/x86.py:L405 — Register bitwise AND

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L405)

Matches `&` with integers/bool; emits `AND(a,b)` after immediate-specific patterns decline.

**Example:** `eax=0xab, ebx=15 → eax=11`.

**Why (inferred):** this is the legal scalar GPR implementation and the fallback for non-encodable literals.

**Edge:** hardware overwrites its first operand, while the graph still has a separate result; post-allocation repair inserts a copy if they cannot coalesce. The instruction also clobbers flags, which later consumers may need regenerated.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints+(dtypes.bool,)) & UPat.var("b"), lambda a,b: a.ins(X86Ops.AND, src=(a, b)))
```

</details>

### renderer/isa/x86.py:L406 — Register bitwise OR

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L406)

Matches `|` with integers/bool; emits `OR(a,b)` after immediate-specific patterns decline.

**Example:** `eax=0x10, ebx=3 → eax=0x13`.

**Why (inferred):** this is the legal scalar GPR implementation and the fallback for non-encodable literals.

**Edge:** hardware overwrites its first operand, while the graph still has a separate result; post-allocation repair inserts a copy if they cannot coalesce. The instruction also clobbers flags, which later consumers may need regenerated.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints+(dtypes.bool,)) | UPat.var("b"), lambda a,b: a.ins(X86Ops.OR, src=(a, b)))
```

</details>

### renderer/isa/x86.py:L407 — Register bitwise XOR

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L407)

Matches `^` with integers/bool; emits `XOR(a,b)` after immediate-specific patterns decline.

**Example:** `eax=0x13, ebx=3 → eax=0x10`.

**Why (inferred):** this is the legal scalar GPR implementation and the fallback for non-encodable literals.

**Edge:** hardware overwrites its first operand, while the graph still has a separate result; post-allocation repair inserts a copy if they cannot coalesce. The instruction also clobbers flags, which later consumers may need regenerated.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a", dtypes.ints+(dtypes.bool,)) ^ UPat.var("b"), lambda a,b: a.ins(X86Ops.XOR, src=(a, b)))
```

</details>

### renderer/isa/x86.py:L408 — Register integer subtraction

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L408)

Matches `SUB` with integers; emits `SUB(a,b)` after immediate-specific patterns decline.

**Example:** `eax=7, ebx=5 → eax=2`.

**Why (inferred):** this is the legal scalar GPR implementation and the fallback for non-encodable literals.

**Edge:** hardware overwrites its first operand, while the graph still has a separate result; post-allocation repair inserts a copy if they cannot coalesce. The instruction also clobbers flags, which later consumers may need regenerated.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.SUB, dtypes.ints, (UPat.var("a"), UPat.var("b"))), lambda a,b: a.ins(X86Ops.SUB, src=(a, b)))
```

</details>

### renderer/isa/x86.py:L410 — float32 VADDSS arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L410)

Matches the float32 binary operation; emits `VADDSS` with the original operands.

**Example:** XMM inputs for `1.5+2.0` produce low-lane `3.5` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; these rules do not themselves fuse multiply/add into FMA.

For `x=[1.5,99,99,99]` and a scalar input 2.0, only the low 1.5 participates in this operation. Packed addition would compute several sums; the `SS` suffix specifically requests one.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.float32) + UPat()).named("x"), lambda x: x.ins(X86Ops.VADDSS))
```

</details>

### renderer/isa/x86.py:L411 — float64 VADDSD arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L411)

Matches the float64 binary operation; emits `VADDSD` with the original operands.

**Example:** XMM inputs for `1.5+2.0` produce low-lane `3.5` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; these rules do not themselves fuse multiply/add into FMA.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.float64) + UPat()).named("x"), lambda x: x.ins(X86Ops.VADDSD))
```

</details>

### renderer/isa/x86.py:L412 — float32 VMULSS arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L412)

Matches the float32 binary operation; emits `VMULSS` with the original operands.

**Example:** XMM inputs for `1.5*2.0` produce low-lane `3.0` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; these rules do not themselves fuse multiply/add into FMA.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.float32) * UPat()).named("x"), lambda x: x.ins(X86Ops.VMULSS))
```

</details>

### renderer/isa/x86.py:L413 — float64 VMULSD arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L413)

Matches the float64 binary operation; emits `VMULSD` with the original operands.

**Example:** XMM inputs for `1.5*2.0` produce low-lane `3.0` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; these rules do not themselves fuse multiply/add into FMA.

<details>
<summary>Exact pattern and replacement</summary>

```python
((UPat(dtype=dtypes.float64) * UPat()).named("x"), lambda x: x.ins(X86Ops.VMULSD))
```

</details>

### renderer/isa/x86.py:L414 — float32 VSUBSS arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L414)

Matches the float32 binary operation; emits `VSUBSS` with the original operands.

**Example:** XMM inputs for `1.5-2.0` produce low-lane `-0.5` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; these rules do not themselves fuse multiply/add into FMA.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.SUB, dtypes.float32, name="x"), lambda x: x.ins(X86Ops.VSUBSS))
```

</details>

### renderer/isa/x86.py:L415 — float64 VSUBSD arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L415)

Matches the float64 binary operation; emits `VSUBSD` with the original operands.

**Example:** XMM inputs for `1.5-2.0` produce low-lane `-0.5` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; these rules do not themselves fuse multiply/add into FMA.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.SUB, dtypes.float64, name="x"), lambda x: x.ins(X86Ops.VSUBSD))
```

</details>

### renderer/isa/x86.py:L416 — float32 VDIVSS arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L416)

Matches the float32 binary operation; emits `VDIVSS` with the original operands.

**Example:** XMM inputs for `3.0/2.0` produce low-lane `1.5` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; this is a division, not an approximate reciprocal-multiply replacement.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.FDIV, dtypes.float32, name="x"), lambda x: x.ins(X86Ops.VDIVSS))
```

</details>

### renderer/isa/x86.py:L417 — float64 VDIVSD arithmetic

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L417)

Matches the float64 binary operation; emits `VDIVSD` with the original operands.

**Example:** XMM inputs for `3.0/2.0` produce low-lane `1.5` in another XMM register.

**Why (inferred):** the scalar VEX instruction implements the dtype and operation directly and permits a distinct destination.

**Edge:** SS/SD select single/double precision scalar lanes, not packed arithmetic; this is a division, not an approximate reciprocal-multiply replacement.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.FDIV, dtypes.float64, name="x"), lambda x: x.ins(X86Ops.VDIVSD))
```

</details>

### renderer/isa/x86.py:L419 — Round float32 values into half representation

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L419)

Matches float32→float16 CAST; emits VCVTPS2PH with uint8 immediate 4.

**Example:** XMM float32 `1.5` → half bits `0x3e00` in the low word.

**Why (inferred):** half conversion is a dedicated conversion instruction rather than integer bit truncation.

**Edge:** immediate bit 2 selects MXCSR rounding control, so this is not a hardcoded rounding-mode-zero immediate; ordinary half ALUs route back through float32.

MXCSR is the CPU register containing floating-point control/status, including the selected rounding mode. This instruction consults that mode because the immediate is 4; it does not interpret the number 4 as a floating value to add.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.float32).cast(dtypes.float16, name="x"), lambda x: x.ins(X86Ops.VCVTPS2PH, src=x.src + (imm(dtypes.uint8, 4),)))
```

</details>

### renderer/isa/x86.py:L420 — Expand half representation to float32

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L420)

Matches float16→float32 CAST; emits VCVTPH2PS.

**Example:** low half word `0x3e00` in XMM → float32 `1.5`.

**Why (explicit in legalization):** this is the available bridge feeding scalar arithmetic and wider conversions.

**Edge:** converting half bits numerically as an integer would produce 15872, not 1.5; the opcode understands half exponent/mantissa layout.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.float16).cast(dtypes.float32, name="x"), lambda x: x.ins(X86Ops.VCVTPH2PS))
```

</details>

### renderer/isa/x86.py:L421 — float32 to integer truncation

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L421)

Matches float32 CAST to signed/unsigned 32/64-bit integer; emits `VCVTTSS2SI` from XMM to GPR, with GPR width chosen by the result dtype.

**Example:** float32 `-3.75` → int32 EAX=`-3`.

**Why (inferred):** the `CVTT` instruction form performs truncation toward zero instead of the current floating rounding mode.

**Edge:** the machine conversion is signed even though the pattern includes unsigned result dtypes; do not infer full unsigned-range behavior solely from this pattern. Out-of-range/NaN conversions need separate semantic validation.

The output integer cannot keep the fraction, so the instruction drops it. “Current rounding mode” refers to CPU floating-point state; this truncating form deliberately requests toward-zero behavior independently of that mode.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.float32).cast(dtypes.int32s+dtypes.int64s, name="x"), lambda x: x.ins(X86Ops.VCVTTSS2SI))
```

</details>

### renderer/isa/x86.py:L422 — float64 to integer truncation

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L422)

Matches float64 CAST to signed/unsigned 32/64-bit integer; emits `VCVTTSD2SI` from XMM to GPR, with GPR width chosen by the result dtype.

**Example:** float64 `-3.75` → int32 EAX=`-3`.

**Why (inferred):** the `CVTT` instruction form performs truncation toward zero instead of the current floating rounding mode.

**Edge:** the machine conversion is signed even though the pattern includes unsigned result dtypes; do not infer full unsigned-range behavior solely from this pattern. Out-of-range/NaN conversions need separate semantic validation.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.float64).cast(dtypes.int32s+dtypes.int64s, name="x"), lambda x: x.ins(X86Ops.VCVTTSD2SI))
```

</details>

### renderer/isa/x86.py:L423 — Widen float32 to float64

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L423)

Matches float32→float64 CAST; emits VCVTSS2SD with `(y,y)` sources.

**Example:** low XMM float32 `1.5` → low double `1.5`.

**Why (inferred):** hardware conversion changes exponent/mantissa encoding; duplicate input fills the VEX merge operand.

**Edge:** this is a numeric cast, not zero-padding float32 bits to 64 bits.

Floating formats divide their bits into a sign, exponent (scale), and significand (precision). Widening a number means translating those fields, not appending zero bytes to the original encoding.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float32).cast(dtypes.float64, name="x"), lambda y,x: x.ins(X86Ops.VCVTSS2SD, src=(y, y)))
```

</details>

### renderer/isa/x86.py:L424 — Narrow float64 to float32

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L424)

Matches float64→float32 CAST; emits VCVTSD2SS with `(y,y)` sources.

**Example:** double `1.1` in XMM becomes the rounded float32 approximation.

**Why (inferred):** the scalar instruction performs the required precision reduction and fills upper bits from its merge source.

**Edge:** rounding is real and must not be erased by treating the cast as an XMM register rename.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float64).cast(dtypes.float32, name="x"), lambda y,x: x.ins(X86Ops.VCVTSD2SS, src=(y, y)))
```

</details>

### renderer/isa/x86.py:L425 — Signed integer to float32

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L425)

Matches int32/int64→float32 CAST; emits `VCVTSI2SS(undef,y)`, selecting the 32/64-bit conversion form from the GPR operand width.

**Example:** EAX=`-7` → XMM low float32 `-7.0`.

**Why (inferred):** the hardware source is a signed GPR; undef supplies the irrelevant upper-lane merge input without creating a false dependency.

**Edge:** uint32 and uint64 require earlier legalization; directly interpreting their high-bit-set representations as signed would give negative values.

Only the converted low lane is meaningful. Supplying `undef` for upper lanes avoids keeping an unrelated old XMM value alive just to fill bits that no consumer will use.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", (dtypes.int32, dtypes.int64)).cast(dtypes.float32, name="x"), lambda y,x: x.ins(X86Ops.VCVTSI2SS, src=(undef(), y)))
```

</details>

### renderer/isa/x86.py:L426 — Signed integer to float64

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L426)

Matches int32/int64→float64 CAST; emits `VCVTSI2SD(undef,y)`, selecting the 32/64-bit conversion form from the GPR operand width.

**Example:** EAX=`-7` → XMM low float64 `-7.0`.

**Why (inferred):** the hardware source is a signed GPR; undef supplies the irrelevant upper-lane merge input without creating a false dependency.

**Edge:** uint32 and uint64 require earlier legalization; directly interpreting their high-bit-set representations as signed would give negative values.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", (dtypes.int32, dtypes.int64)).cast(dtypes.float64, name="x"), lambda y,x: x.ins(X86Ops.VCVTSI2SD, src=(undef(), y)))
```

</details>

### renderer/isa/x86.py:L427 — Zero-extension of unsigned small integers

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L427)

Matches uint8/uint16/bool→integer CAST only when destination is wider; emits MOVZX.

**Example:** AL=`0xff` uint8 → EAX=`255`.

**Why (inferred):** unused upper bits must be cleared before a wider consumer reads them.

**Edge:** equal/narrowing casts return None; sign-extension would turn 255 into -1.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=(dtypes.uint8, dtypes.uint16, dtypes.bool)).cast(dtypes.ints, name="x"), lambda x:
   x.ins(X86Ops.MOVZX) if x.src[0].dtype.itemsize < x.dtype.itemsize else None)
```

</details>

### renderer/isa/x86.py:L429 — Sign-extension of int32 to 64 bits

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L429)

Matches int32→int64/uint64 CAST; emits MOVSXD.

**Example:** EAX=`0xffffffff` → RAX=`0xffffffffffffffff`.

**Why (inferred):** this width pair needs the dedicated dword sign-extend instruction.

**Edge:** uint32→64-bit is handled separately as zero-extended register reinterpretation; MOVSXD would be wrong there.

Both hex values represent -1 in their respective signed widths. Replicating the sign bit makes that identity survive widening; filling the new high half with zeros would instead produce 4294967295.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.int32).cast(dtypes.int64s, name="x"), lambda x: x.ins(X86Ops.MOVSXD))
```

</details>

### renderer/isa/x86.py:L430 — Sign-extension of smaller signed integers

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L430)

Matches signed integer→integer CAST only when widening; emits MOVSX after the int32 special case.

**Example:** int8 AL=`0x80` → int32 EAX=`0xffffff80`.

**Why (inferred):** replicating the source sign preserves its signed value before destination interpretation.

**Edge:** destination may be unsigned, but source signedness still determines extension bits; MOVSX is not used for narrowing.

For the example, both `0x80` as int8 and `0xffffff80` as int32 mean -128. The added one bits preserve the negative value rather than introducing a new positive magnitude.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.sints).cast(dtypes.ints, name="x"), lambda x: x.ins(X86Ops.MOVSX) if x.src[0].dtype.itemsize < x.dtype.itemsize else None)
```

</details>

### renderer/isa/x86.py:L431 — Remaining integer casts copy the requested width

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L431)

Matches remaining integer→integer CAST; emits MOV.

**Example:** int32 `0x1234` → uint8 reads low byte `0x34`.

**Why (inferred):** after widening cases are handled, narrowing only needs the low destination-width bits.

**Edge:** rule ordering is essential; applying this fallback to int8→int64 would leave upper bits wrong.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.ints).cast(dtypes.ints, name="x"), lambda x: x.ins(X86Ops.MOV))
```

</details>

### renderer/isa/x86.py:L433 — Half bits to a GPR word

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L433)

Matches float16 BITCAST to int16/uint16; emits VPEXTRW with lane immediate 0.

**Example:** half 1.0 → GPR low word 0x3c00.

**Why (inferred):** half values live in XMM but scalar integer bits belong in GPRs.

**Edge:** these are representation transfers; using a numeric CAST instruction would change the bits. Only the scalar low lane is the intended result.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("y", dtypes.float16).bitcast(dtypes.int16s).named("x"), lambda y,x: x.ins(X86Ops.VPEXTRW, src=(y, imm(dtypes.uint8, 0))))
```

</details>

### renderer/isa/x86.py:L434 — A GPR word becomes half bits

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L434)

Matches int16/uint16 BITCAST to float16; emits VPINSRW with undef merge input and lane 0.

**Example:** GPR word 0x3c00 → half 1.0 in XMM.

**Why (inferred):** inserting the word preserves the encoding without numeric conversion.

**Edge:** these are representation transfers; using a numeric CAST instruction would change the bits. Only the scalar low lane is the intended result.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.int16s).bitcast(dtypes.float16).named("x"), lambda x: vpins(x, x.src))
```

</details>

### renderer/isa/x86.py:L435 — A GPR dword becomes float32 bits

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L435)

Matches int32/uint32 BITCAST to float32; emits VMOVD.

**Example:** EAX=0x3f800000 → XMM float32 1.0.

**Why (inferred):** a register-file transfer preserves all 32 bits.

**Edge:** these are representation transfers; using a numeric CAST instruction would change the bits. Only the scalar low lane is the intended result.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.int32s).bitcast(dtypes.float32).named("x"), lambda x: x.ins(X86Ops.VMOVD))
```

</details>

### renderer/isa/x86.py:L436 — A GPR qword becomes float64 bits

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L436)

Matches int64/uint64 BITCAST to float64; emits VMOVQ.

**Example:** RAX=0x3ff0000000000000 → XMM double 1.0.

**Why (inferred):** a 64-bit register-file transfer preserves double representation.

**Edge:** these are representation transfers; using a numeric CAST instruction would change the bits. Only the scalar low lane is the intended result.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.int64s).bitcast(dtypes.float64).named("x"), lambda x: x.ins(X86Ops.VMOVQ))
```

</details>

### renderer/isa/x86.py:L437 — Float32 bits become a GPR dword

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L437)

Matches float32 BITCAST to int32/uint32; emits VMOVDm.

**Example:** XMM float32 1.0 → EAX=0x3f800000.

**Why (inferred):** the integer consumer requires a GPR holding the same bits.

**Edge:** these are representation transfers; using a numeric CAST instruction would change the bits. The m suffix is this backend’s destination/rm encoding variant, not a guarantee that this particular operation writes memory.

Here “register-file transfer” means moving bits between the floating/vector registers and the integer registers. The encoder’s `rm` field can describe a register or memory operand; its name does not establish which is used in this instance.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.float32).bitcast(dtypes.int32s).named("x"), lambda x: x.ins(X86Ops.VMOVDm))
```

</details>

### renderer/isa/x86.py:L438 — Float64 bits become a GPR qword

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L438)

Matches float64 BITCAST to int64/uint64; emits VMOVQm.

**Example:** XMM double 1.0 → RAX=0x3ff0000000000000.

**Why (inferred):** the integer consumer requires all 64 encoding bits.

**Edge:** these are representation transfers; using a numeric CAST instruction would change the bits. The m suffix is this backend’s destination/rm encoding variant, not a guarantee that this particular operation writes memory.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(dtype=dtypes.float64).bitcast(dtypes.int64s).named("x"), lambda x: x.ins(X86Ops.VMOVQm))
```

</details>

### renderer/isa/x86.py:L440 — Memory INDEX materializes a 64-bit effective address

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L440)

Matches INDEX/SHRINK unless the base is a vector XMM value; emits LEA with folded `(base,index,displacement,size)`.

**Example:** float32 buffer `A[i+3]` gives address `[base+i*4+12]` in a uint64 GPR.

**Why (explicit):** addresses are full-width values and x86 can combine scaling/addition in one instruction.

**Edge:** negative indices sign-extend; small nonnegative indices zero-extend. Buffer indexing is by element, while stack-pointer indexing is by byte.

The element index `i+3` is multiplied by four because a float32 occupies four bytes: `address = base + 4*i + 12`. A load or store can use that address later; LEA itself only calculates it.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat((Ops.INDEX, Ops.SHRINK), name="x"), lambda x: lea(x) if not _is_vec_xmm(x.src[0]) else None)
```

</details>

### renderer/isa/x86.py:L443 — Floating loads select memory width and XMM form

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L443)

Matches one-source floating LOAD. A total two-byte result uses VPINSRW into undef; other widths choose VMOVSS (<8 bytes), VMOVSD (8–15), or VMOVUPS (>=16).

**Example:** one half loads exactly two bytes into XMM word 0; four float32 elements use a 16-byte VMOVUPS.

**Why (inferred):** scalar half lacks a dedicated scalar half-move form here, while larger loads can use standard XMM moves.

**Edge:** width comes from total element count times itemsize; these thresholds assume earlier vector legalization produced supported transfer widths, not arbitrary 12-byte-safe loads.

Load width is a memory-safety requirement. A four-byte read from a two-byte half can read beyond the valid allocation, even if the compiler intends to ignore the extra bits. Selecting a two-byte instruction makes the access itself match the value.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.LOAD, dtypes.floats, src=(UPat(name="a"),), name="x"), lambda x,a:
   x.ins(X86Ops.VPINSRW, src=(undef(),) + fold_address(a) + (imm(dtypes.uint8, 0),)) if x.max_numel() * x.dtype.itemsize == 2 else
   x.ins(_xmm_sz(x), src=fold_address(a)))
```

</details>

### renderer/isa/x86.py:L446 — Integer loads split scalar GPR and vector XMM paths

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L446)

Matches one-source integer/bool LOAD; scalar uses MOV, multiple elements use the XMM width selector.

**Example:** one int32 at `[rdi+rcx*4]` loads into EAX; four int32 values load with VMOVUPS into XMM0.

**Why (inferred):** arithmetic scalar integers use GPRs but a packed vector occupies an XMM register regardless of element type.

**Edge:** VMOVUPS here moves raw integer bits; its floating-sounding name does not convert them.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.LOAD, dtypes.ints+(dtypes.bool,), src=(UPat(name="a"),), name="x"), lambda x,a:
   x.ins(X86Ops.MOV, src=fold_address(a)) if x.max_numel() == 1 else x.ins(_xmm_sz(x), src=fold_address(a)))
```

</details>

### renderer/isa/x86.py:L448 — Floating stores select width, including a half-word escape

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L448)

Matches STORE of floating values; total two-byte value uses VPEXTRW lane 0 directly to memory; larger values choose VMOVSSm/VMOVSDm/VMOVUPSm by total width.

**Example:** store half 1.0 writes word `0x3c00` using lane extraction; four float32 values use a 16-byte store.

**Why (inferred):** extraction provides an exact two-byte memory write from XMM without clobbering neighboring elements.

**Edge:** writing a four-byte VMOVSS for scalar half would corrupt the adjacent half; width legalization remains a prerequisite.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a").store(UPat.var("b", dtypes.floats), name="x"), lambda a,b,x:
   x.ins(X86Ops.VPEXTRW, src=fold_address(a) + (b, imm(dtypes.uint8, 0))) if b.max_numel() * b.dtype.itemsize == 2 else
   x.ins(_xmm_sz_m(b), src=fold_address(a) + (b,)))
```

</details>

### renderer/isa/x86.py:L451 — Integer stores choose vector, scalar, or immediate encoding

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L451)

Matches STORE of integer/bool value. Multiple elements use XMM moves; scalar uses MOVm unless `to_imm` accepts the value, when MOVi writes memory directly.

**Example:** storing int32 7 can become `mov dword [rdi],7`; storing EAX uses MOVm; four int32 lanes use VMOVUPSm.

**Why (inferred):** immediate-to-memory avoids materializing a constant register, and vector writes preserve packed bits.

**Edge:** full uint64 literals that cannot fit the signed 32-bit immediate must use a register.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat.var("a").store(UPat.var("b", dtypes.ints+(dtypes.bool,)), name="x"), lambda a,b,x:
   x.ins(_xmm_sz_m(b), src=fold_address(a) + (b,)) if b.max_numel() > 1 else
   x.ins(X86Ops.MOVm, src=fold_address(a) + (b,)) if (i:=to_imm(b)) is None else x.ins(X86Ops.MOVi, src=fold_address(a) + (i,)))
```

</details>

### renderer/isa/x86.py:L455 — Allocate virtual register classes after selection

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L455)

Matches INS/BUFFER/RANGE; `alloc_vregs` skips physical DEFINEs, LOOP_CMP, FRAME_INDEX, void results and already constrained vregs. Otherwise it turns fixed-register tuples into constrained vregs, assigns buffer addresses and scalar integers WGPR, and floats/vector-producing ops/vectors XMM.

**Example:** VMOVD result gets an XMM vreg, VPEXTRD gets a GPR, DIV keeps RAX/RDX constraints.

**Why (explicit):** selection chooses legal register classes before physical allocation.

**Edge:** a float BUFFER value is its address and must remain GPR; BUFFER size sources are tagged so shape metadata does not become runtime values.

A virtual register is a temporary name awaiting assignment to a real register. Its register class limits the choices: a scalar integer cannot be assigned an XMM register merely because one is free. `WGPR` is the backend’s scalar general-purpose-register choice set; existing fixed-register constraints narrow that set further.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat((Ops.INS, Ops.BUFFER, Ops.RANGE), name="x"), alloc_vregs)
```

</details>

## `pre_regalloc_matcher`

### renderer/isa/x86.py:L476 — Private buffers receive stack offsets

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L476)

Matches BUFFER in the linear pre-allocation walk; turns it into LEA of `[rsp+stack_size]` through instruction selection and increments stack_size by element count times itemsize.

**Example:** float32 scratch[4] at initial offset 0 gets address RSP; next buffer starts at offset 16.

**Why (inferred):** gated memory fallbacks and local scratch need actual storage before final frame allocation.

**Edge:** the helper itself adds no padding between buffers; spill-slot allocation has its own alignment logic. The buffer result retains its register tag.

This reserves offsets, not yet the final physical stack frame. Four float32 scratch elements require `4*4=16` bytes; later spills may increase the total before the function-entry stack adjustment is emitted.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.BUFFER, name="x"), alloc_buffer)
```

</details>

### renderer/isa/x86.py:L477 — Reissue comparisons after flags were overwritten

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L477)

Matches INS/RANGE/END. Tracks the most recent flag writer in `ctx.lock`; when a ReadFlags instruction depends on another compare, inserts that compare immediately before the reader.

**Example:** `cmp eax,ebx; add ecx,1; cmovl ...` becomes `cmp; add; cmp eax,ebx; cmovl`.

**Why (explicit):** flags are one implicit mutable resource and cannot use the ordinary spill/reload fallback.

**Edge:** even RANGE/END are treated as clobbering because later lowering inserts flag-writing code; a stale comparison dependency alone does not preserve hardware flags.

In the example, ADD changes flags to describe `ecx+1`, so CMOVL would otherwise test that addition rather than `eax<ebx`. Repeating CMP immediately before CMOVL restores the intended condition without changing the arithmetic values.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat((Ops.INS, Ops.RANGE, Ops.END), name="x"), flag_rematerialize)
```

</details>

## `post_regalloc_matcher`

### renderer/isa/x86.py:L508 — Reserve the final stack frame after defining RSP

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L508)

Matches INS only when it is physical RSP DEFINE and final stack_size is nonzero. Returns the DEFINE followed by `SUBi rsp,stack_size`.

**Example:** 48 bytes of scratch/spills → entry `sub rsp,48`.

**Why (explicit):** final frame size is known after allocation; every stack-relative scratch access needs space reserved first.

**Edge:** empty frames do nothing, and the preserved original DEFINE remains the graph replacement even though an extra instruction is emitted.

The x86 stack grows toward lower addresses: if entry RSP is `0x1000`, subtracting 48 makes it `0x0fd0` and reserves that interval for this call. Stack-relative scratch offsets are then measured from the new pointer.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.INS, name="x"), lambda ctx,x: (x, [x, x.ins(X86Ops.SUBi, src=(imm(dtypes.int32, ctx.stack_size),))])
    if ctx.stack_size and x.arg[0] is X86Ops.DEFINE and rdef(x) == RSP else None)
```

</details>

### renderer/isa/x86.py:L510 — Release the frame immediately before return

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L510)

Matches INS RET when stack_size is nonzero; inserts `ADDi rsp,stack_size` before RET.

**Example:** after a 48-byte frame, `add rsp,48; ret`.

**Why (explicit):** the caller’s stack pointer and return-address location must be restored.

**Edge:** this belongs after spill/callee-save restoration and must use the same finalized size as the prologue.

With the same example, adding 48 restores `RSP=0x1000`. RET can now find the saved return address at the location the caller and callee agreed upon.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.INS, name="x"), lambda ctx,x: (x, [stack_pointer.ins(X86Ops.ADDi, src=(imm(dtypes.int32, ctx.stack_size),)), x])
    if ctx.stack_size and x.arg[0] is X86Ops.RET else None)
```

</details>

### renderer/isa/x86.py:L513 — Resolve entry-stack arguments against the grown frame

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L513)

Matches INS with one cast-constant displacement and opcode FRAME_INDEX; replaces it with constant `stack_size + displacement`.

**Example:** SysV seventh argument originally at entry RSP+8 becomes current RSP+56 after allocating 48 bytes.

**Why (explicit):** stack arguments are outside the newly reserved local frame.

**Edge:** FRAME_INDEX is an immediate placeholder, not a GPR definition; forgetting the adjustment reads local scratch instead of the argument.

The argument’s absolute address never moved: `0x1000+8 = 0x0fd0+56`. Only RSP moved when the frame was reserved, so the displacement must grow by the same amount.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.INS, src=(UPat.cvar("disp").cast(),), name="x"), lambda ctx,disp,x:
    (nx:=UOp.cconst(ctx.stack_size + disp.val, x.dtype), [nx]) if x.arg[0] is X86Ops.FRAME_INDEX else None)
```

</details>

### renderer/isa/x86.py:L516 — Delayed backedge compare becomes compare plus branch

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L516)

Matches INS LOOP_CMP. Reconstructs comparison opcode from tag using its first two sources, selects IF(comparison), emits selected compare and jump, and copies the associated range label tag onto the jump.

**Example:** LOOP_CMP for signed i<16 → CMPi i,16; JL .LOOP_k.

**Why (explicit):** retaining the RANGE edge through allocation is how this lowering locates the correct label.

**Edge:** LOOP_CMP itself must never reach binary encoding as executable work; its condition signedness controls branch selection.

The loop label names the machine-code position to revisit. Reconstructing the comparison after allocation ensures it refers to the final counter register and still targets that particular loop.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.INS, name="x"), lambda ctx,x: lower_loop(ctx, x) if x.arg[0] is X86Ops.LOOP_CMP else None)
```

</details>

### renderer/isa/x86.py:L518 — Expand RANGE into loop entry machinery

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L518)

Matches RANGE. A void range becomes only a LABEL; a value range becomes MOVi counter=0, LABEL, CMP/CMPi counter,bound, JGE exit, and records the counter-to-label mapping.

**Example:** RANGE(4) → i=0; .LOOP: cmp i,4; jge .OUT.

**Why (explicit):** allocation needs the loop value before concrete jumps and labels are expanded.

**Edge:** the void form serves loops whose compare is on the backedge; ordinary entry uses signed JGE, so this is not a generic unsigned-bound branch template.

This is the ordinary `for i in range(4)` structure written explicitly: start at zero, test before entering, run the body only when `i<4`, then let END increment and return to this test. A zero bound exits before running the body.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.RANGE, name="x"), lower_range)
```

</details>

### renderer/isa/x86.py:L520 — Expand END into increment and backedge

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L520)

Matches END; looks up the associated range counter’s label, emits ADDi counter,1; JMP loop label; exit LABEL, returning the increment as replacement.

**Example:** after processing i=0, increment to 1 and revisit the entry bound check.

**Why (explicit):** realizes counted-loop recurrence and supplies the forward jump’s exit target.

**Edge:** label lookup uses `x.src[1]` as the original range/allocated counter; losing that edge prevents correct control-flow reconstruction.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.END, name="x"), lower_end)
```

</details>

### renderer/isa/x86.py:L522 — Repair destructive two-address instructions

[Source](../../../../tinygrad/tinygrad/renderer/isa/x86.py#L522)

Matches INS only when opcode belongs to TwoAddress. Removes the graph’s first source (now implicit destination); if its physical register differs from destination, first copies it to destination.

**Example:** graph `r10 = ADD(r8,r9)` → `mov r10,r8; add r10,r9`; if destination is already r8, only ADD remains.

**Why (explicit):** SSA-style separate definitions must become the x86 overwrite form after coalescing decisions.

**Edge:** running this before physical allocation cannot know whether a copy is necessary; skipping it silently uses the destination’s old contents.

SSA means static single assignment: each graph value has one definition, so the result and the old input are distinct values. Hardware registers can be overwritten repeatedly; this final repair connects those two representations without losing a still-needed input.

<details>
<summary>Exact pattern and replacement</summary>

```python
(UPat(Ops.INS, name="x"), lambda ctx,x: (nx:=x.replace(src=x.src[1:]),
   [ctx.ren.copy(x.src[0], rdef(x)), nx] if rdef(x) != rdef(x.src[0]) else [nx]) if x.arg[0] in X86GroupOp.TwoAddress else None)
```

</details>
