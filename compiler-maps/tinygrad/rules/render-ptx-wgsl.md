# PTX and WGSL: every local matcher rule

## The two targets, from Python to device code

PTX is NVIDIA's assembly-like intermediate language. Tinygrad prints PTX instructions and another compiler turns them into machine code. WGSL is the shader language used by WebGPU; a compute shader is a GPU kernel, even when no graphics are involved. These are separate renderer routes, so their different rules solve different target-language constraints.

A **UOp** describes an operation and its inputs. Legalization rules replace UOps with supported operations; emission rules print code. Both work inside kernels whose boundaries were chosen earlier. In `out[i]=a[i]+b[i]`, indexing, reading, adding, and writing survive as separate responsibilities even if the final compiler combines some instructions.

PTX `%f` and `%p` are named registers: small per-thread working values, rather than Python variables stored in an array. A **predicate** is a boolean register used to enable instructions; `@%p instruction` runs that instruction only when this thread's predicate is true. It is not a single boolean shared by the whole warp. A **warp** is a group of NVIDIA threads that cooperate in hardware. A **vector lane** below is one component held by a thread; do not confuse it with a thread's position in a warp.

GLOBAL memory is accessible across workgroups; LOCAL/shared memory is scratch space shared by threads of one workgroup (a CUDA thread block). REG denotes register-backed storage. The **ABI** is the convention for passing addresses, values, and matrix fragments to a kernel or intrinsic. `CAST` converts a numeric value; `BITCAST` keeps its bit pattern. Thus float32 `1.0` casts to integer `1` but bitcasts to `0x3f800000`.

In PTX spellings, `.f32` means float32, `.s32` signed integer, `.u32` unsigned integer, and `.b32` an uninterpreted 32-bit payload. Destination comes first. WGSL instead spells these types `f32`, `i32`, and `u32`. A **word** here is 32 bits, enough to contain four bytes. WGSL's packed rules let several small tensor elements share one word; their shifts and masks locate one element without overwriting its neighbors. An atomic operation updates that word indivisibly, but a sequence of two atomics is still two separate updates.

Source snapshot: tinygrad `107adc31701df0247dfa45e175984df906a68b53`. These are **source-derived, schematic examples, not executed GPU tests**. Register names and temporary names are shortened for readability. `h`, `f`, `i`, `u`, and `p` mean half, float32, int32, uint32, and predicate. `cast` converts values; `bitcast` preserves bits. An arrow describes the local rule, before later simplification. The heading line identifies the outer rule tuple, including a rule that dispatches several opcodes. Inherited WGSL `base_rewrite` rules belong to the C-style catalog.

“Why” below is an inference from the implementation unless explicitly described as a source comment. This establishes the rule's present purpose; it does **not** establish the historical motivation for its introduction. Neither file contains IMAGE-specific matchers. PTX is NVIDIA-specific; WGSL is a WebGPU language backend, not an AMD chip-specific matcher.

## PTX legalization (`ptx_matcher`)

### renderer/ptx.py:L42 — Boolean inequality

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L42). Match `CMPNE(x:bool,y)`; replace with `XOR(x,y)`. Example: `false != true → false XOR true → true`. The source comment explains that booleans are PTX predicates and this is a renderer-local rewrite because doing it universally is slow. The normal comparison emitter expects a numeric comparison type; predicate XOR directly expresses inequality.

### renderer/ptx.py:L43 — Boolean equality

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L43). Match `CMPEQ(x:bool,y)`; replace with `(x XOR y) XOR true`. Example: `true == true → (true XOR true) XOR true → true`. This shares the source's renderer-local boolean comparison rationale: negate inequality with a predicate instruction.

### renderer/ptx.py:L44 — Boolean ordering

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L44). Match `CMPLT(x:bool,y)`; replace with `(x XOR true) AND y`. Example: `false < true → (!false) AND true → true`; `true < true → false`. With false=0 and true=1, only that first combination is less-than. The source comment calls this the boolean comparison legalization.

### renderer/ptx.py:L46 — Unsupported half ALU operations widen

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L46). Match an opcode in `doesnt_support_half` with **result dtype half**; cast every source to float32, reconstruct the op with its original argument, and cast the result back to half. Example: `SQRT(h) → half(SQRT(float32(h)))`. The source comment explicitly calls this upcasting unsupported half operations. The exclusion list is computed from `asm_for_op`: supported half operations are `EXP2, ADD, MUL, MAX, CMPLT, WHERE, TRUNC`; everything else in that table is a template variant. This is this renderer's support policy, not a claim that all NVIDIA chips lack corresponding instructions. Result-dtype matching matters: an ordinary half-input comparison returning bool does not satisfy this rule.

### renderer/ptx.py:L49 — Boolean loads use byte storage

The logical array still has one boolean per element. The rule does not compress eight booleans into one byte; it bridges byte-addressed storage and the predicate registers used to compute with them.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L49). Match `LOAD(idx,...):bool`, with at least the index source. Only rewrite when `idx.addrspace != REG`. Change the storage view to uint8, cast an alternate source to uint8 when present, preserve later sources such as a gate, and cast the loaded value to bool. Example: `LOAD(bool_buffer[i],false,g) → bool(LOAD(uint8_view[i],uint8(false),g))`. The comment explicitly identifies the mismatch: booleans are predicate registers but bytes in memory. Register-backed booleans already have the desired representation.

### renderer/ptx.py:L52 — Boolean stores use byte storage

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L52). Match `STORE(idx,value:bool,...)`, excluding `REG` addresses. Replace the address storage view and value with uint8 versions, preserving remaining sources. Example: `STORE(B[i],true) → STORE(uint8_view(B)[i],uint8(true))`. Same explicit predicate-versus-byte rationale as loads; casting the address alone would leave an incompatible predicate value at the store.

### renderer/ptx.py:L55 — Left-shift counts become unsigned

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L55). Match `SHL(x,y)`; return a replacement only if `y.dtype != uint32`. Example: `i << int32(3) → SHL(i,uint32(3))`. The source comment states that PTX shift instructions require the second operand to be uint. The left operand retains its type.

### renderer/ptx.py:L56 — Right-shift counts become unsigned

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L56). Match `SHR(x,y)` with the same non-uint32 count guard; replace only the count. Example: `int32(-8) >> int32(1) → SHR(int32(-8),uint32(1))`. Keeping the signed left operand preserves arithmetic right-shift semantics while satisfying the explicit PTX count requirement.

## PTX string emission (`string_rewrite`)

These rules consume the renderer's allocated register map. Most emit strings rather than new UOps; matching order therefore selects concrete assembly syntax.

### renderer/ptx.py:L82 — Constant-to-predicate materialization

`setp.ne` means “set predicate if not equal.” Comparing the normalized constant with zero creates a truth value in the register class required for predicates.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L82). Match `CAST(CONST(c)):bool`; emit `setp.ne.s16 dst, render_val(c,bool), 0;`. Example: `bool(CONST(1)) → setp.ne.s16 %p, 1, 0;`. A predicate is materialized by a comparison rather than an ordinary integer move. `render_val(c,bool)` uses `int(c)`, so this path assumes an appropriately normalized constant; it is not an independent implementation of arbitrary float-to-bool conversion.

### renderer/ptx.py:L83 — Typed constant materialization

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L83). Match any other `CAST(CONST(c))`; emit `mov.b<bits> dst, render_val(c,destination_dtype);`. Example: `float32(CONST(1)) → mov.b32 %f, 0f3F800000;`; `uint32(CONST(7)) → mov.b32 %u, 7U;`. Float constants are emitted as exact bit patterns rather than decimal text. The preceding bool rule prevents trying to use a predicate as an ordinary bit-width register.

### renderer/ptx.py:L84 — Grid and thread coordinates

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L84). Match `SPECIAL`; use `%ctaid` when `arg[0]=='g'`, otherwise `%tid`, and choose x/y/z from the final digit. Example: `SPECIAL(arg='gidx0') → mov.u32 %gidx0, %ctaid.x;`; `lidx1 → mov.u32 %lidx1, %tid.y;`. The abstract launch coordinate becomes the corresponding PTX special register; argument spelling is an upstream contract.

### renderer/ptx.py:L85 — Kernel parameters

A pointer to float32 data is still a 64-bit address on this route. The 32-bit size of each element affects later address arithmetic; it does not shrink the pointer argument itself.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L85). Match `PARAM`. A GLOBAL address uses `ld.param.u64`; other values use `mem_types[dtype]`. Example: global buffer parameter slot 0 emits `ld.param.u64 %ptr, [data0+0];`; a scalar int32 parameter emits `ld.param.s32 %i, [data1+0];`. This separates pointer ABI width from element width.

### renderer/ptx.py:L88 — Element index to byte address

`cvt` first widens the index. `mad` then multiplies it by element size and adds the base address. For base 1000 and float32 index 3, the two stages produce index 3 in the wider type and address 1012.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L88). Match `INDEX` or `SHRINK` whose first two sources are `(buf,idx)`, allowing additional sources. Emit `cvt.s64.<idx_type> dst, idx; mad.lo.s64 dst, dst, itemsize, buf;`. Example: float32 `B[3] → address(B)+3*4`. The source comment explicitly states the address equation. The result is an address register, not a loaded value. REG/ALU indexing is intercepted separately by `render()` and does not take this path.

### renderer/ptx.py:L90 — Comparisons use operand type

The result of either `3<4` or `3.0<4.0` is boolean, but the comparison must interpret its operands differently. That is why this rule looks at an input dtype before choosing the instruction.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L90). Match `CMPLT`, `CMPNE`, or `CMPEQ`, binding the first source while allowing the remaining operands. Dispatch `code_for_op` using **source 0's dtype**, not the bool result dtype. Examples: `f < g → setp.lt.f32 %p, %f, %g;`; `i == j → setp.eq.s32 %p, %i, %j;`; `f != g → setp.neu.f32 %p, %f, %g;`. `neu` is selected for floating inequality so an unordered NaN comparison yields true; integer inequality uses `ne`. This rule must precede generic ALU emission.

### renderer/ptx.py:L92 — Generic ALU instruction templates

To read `fma.rn.f32 %d,%f,%g,%h`, start at the inputs: multiply f by g, add h, and round once into d. That is instruction fusion inside one kernel. It says nothing about combining two kernel launches or eliminating an intermediate tensor allocation.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L92). Match any `GroupOp.ALU`; dispatch by opcode using the **result** dtype. The implementation relies on earlier lowering to leave an opcode present in `asm_for_op`. Every dictionary variant is below; `%d` is the destination, and inputs have the stated type.

| Opcode/variant | Example input → emitted instruction | Why that form |
|---|---|---|
| RECIPROCAL float | `1/f → rcp.approx.f32 %d, %f;` | Approximate reciprocal primitive. Nonfloat branch omits `.approx`; its presence in the formatting lambda does not establish a supported integer reciprocal pipeline. |
| EXP2 | `2**f → ex2.approx.f32 %d, %f;` | Base-two transcendental instruction. |
| LOG2 | `log2(f) → lg2.approx.f32 %d, %f;` | Base-two transcendental instruction. |
| SIN | `sin(f) → sin.approx.f32 %d, %f;` | Native approximate transcendental. |
| SQRT | `sqrt(f) → sqrt.approx.f32 %d, %f;` | Native approximate square root. |
| TRUNC | `trunc(f) → cvt.rzi.f32.f32 %d, %f;` | Round toward zero while keeping the floating type. |
| SHR signed/unsigned | `i >> u → shr.s32 %d, %i, %u;`; unsigned left input uses `shr.u32` | Left type selects signed versus unsigned shift. |
| SHL | `i << u → shl.b32 %d, %i, %u;` | Left shift operates on bits. |
| ADD numeric/bool | `i+j → add.s32 %d, %i, %j;`; `p+q → or.pred %d, %p, %q;` | Boolean addition follows logical OR. |
| MUL float/int/bool | `f*g → mul.f32 %d, %f, %g;`; `i*j → mul.lo.s32 %d, %i, %j;`; `p*q → and.pred %d, %p, %q;` | Integer multiplication keeps low bits; bool multiplication is AND. |
| XOR numeric/bool | `i XOR j → xor.b32 %d, %i, %j;`; predicate case `xor.pred %d, %p, %q;` | Bit-width versus predicate instruction classes. |
| AND numeric/bool | `i AND j → and.b32 %d, %i, %j;`; bool `and.pred %d, %p, %q;` | Same representation distinction. |
| OR numeric/bool | `i OR j → or.b32 %d, %i, %j;`; bool `or.pred %d, %p, %q;` | Same representation distinction. |
| CDIV | `i/j → div.s32 %d, %i, %j;` | Truncating integer division reaching this stage. |
| CMOD | `i%j → rem.s32 %d, %i, %j;` | Corresponding integer remainder. |
| MAX | `max(f,g) → max.f32 %d, %f, %g;` | Direct maximum. |
| CMPEQ/CMPLT/CMPNE | See L90 | Earlier comparison rule supplies the input dtype correctly. |
| MULACC float/int | `f*g+h → fma.rn.f32 %d, %f, %g, %h;`; integer `mad.lo.s32 %d, %i, %j, %k;` | Fused float round-to-nearest versus low-word integer multiply-add. |
| WHERE numeric | `p?f:g → selp.f32 %d, %f, %g, %p;` | Predicate is the last assembly operand. |
| WHERE half | `p?h:j → selp.b16 %d, %h, %j, %p;` | Half payload selected as 16 bits. |
| WHERE bool | `p?q:r → @%p mov.pred %d, %q; @!%p mov.pred %d, %r;` | Predicate results use complementary predicated moves. |

Approximate opcode spelling is explicit in source; no error bounds are asserted here. This rule emits instructions **within a kernel**, not kernel fusion.

### renderer/ptx.py:L93 — Bitcast is a register bit move

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L93). Match `BITCAST(a,...)`, allowing extra sources. Emit `mov.b<bits-of-result> dst, a;`. Example: `bitcast<uint32>(float32(1)) → mov.b32 %u, %f;`, preserving `0x3f800000`. No numerical conversion should occur.

### renderer/ptx.py:L94 — Predicate-to-number conversion

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L94). Match `CAST(a:bool)`. Emit `selp.b<bits> dst, typed_one, typed_zero, a;`. Example: `float32(p) → selp.b32 %f, 0f3F800000, 0f00000000, %p;`. Predicates are represented by truth, so select numeric 1/0 instead of trying an ordinary numeric `cvt`.

### renderer/ptx.py:L96 — General numeric conversion

Rounding toward zero turns -1.75 into integer -1; round-to-nearest chooses a nearby representable floating value. A physical 16-bit register holding an int8 value does not make that value semantically int16, hence the separate conversion-width table.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L96). Match other single-source CASTs. Emit `cvt<modifier>.<destination cast_type>.<source cast_type> dst, a;`. Examples: `int32(f) → cvt.rzi.s32.f32 %i, %f;`; `half(f) → cvt.rn.f16.f32 %h, %f;`; `float32(i) → cvt.rn.f32.s32 %f, %i;`; `float32(h) → cvt.f32.f16 %f, %h;`. `modifier` chooses `.rzi` for float-to-int, `.rn` when converting to float from int/bool or narrowing a larger type, otherwise nothing. Separate cast types preserve int8/uint8 conversion width even though those values occupy 16-bit registers.

### renderer/ptx.py:L99 — Register-backed store

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L99). Match exactly `STORE(loc,var)`; only return a string when `loc.addrspace==REG`. Emit `mov.pred` for bool or `mov.b<bits>` otherwise. Example: storing float32 into accumulator slot 0 gives `mov.b32 %acc0, %f;`. A register buffer is an allocation fiction: there is no memory transaction.

### renderer/ptx.py:L102 — Memory store, scalar and vector

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L102). Match exactly `STORE(INDEX-or-SHRINK,var)`. Emit `st.<shared-or-global>[.v<count>].<memory_type> [loc+0], value;`, with braces for vectors. Examples: `STORE(global_float[i],f) → st.global.f32 [%addr+0], %f;`; four local half values become `st.shared.v4.b16 [%addr+0], {%h0, %h1, %h2, %h3};`. Address space and physical memory width decide instruction syntax. This rule does not itself add a gate; control-flow legalization must already account for a masked store.

### renderer/ptx.py:L106 — Gated memory load

For a false scalar gate, the load instruction is skipped and the complementary move supplies the alternate. For a false vector gate, only the prior zero initialization remains. These two paths explain why a nonzero alternate is meaningful in the scalar case but not honored by this vector branch.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L106). Match exactly `LOAD(INDEX-or-SHRINK,alt,gate)`. Scalar alternate: emit `@gate ld... dst,[loc+0]; @!gate mov.b<bits> dst,alt;`. Example: `LOAD(B[i],7,g) → @%g ld.global.s32 %v,[%a+0]; @!%g mov.b32 %v,%seven;`. Vector alternate (`alt.max_numel()>1`): first zero every result register, then issue one predicated vector load. Example: four float lanes initialize with `mov.f32 %v0,0f00000000;` etc., then `@%g ld.global.v4.f32 {%v0,%v1,%v2,%v3},[%a+0];`. **Sharp edge:** the vector branch does not read alternate values; it assumes zero alternatives have been established upstream. This is observable source behavior, not a proof that arbitrary nonzero vector alternates work.

### renderer/ptx.py:L113 — Ungated memory load

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L113). Match exactly `LOAD(INDEX-or-SHRINK)`. Emit scalar `ld.<space>.<type>` or vector `ld.<space>.v<count>.<type>`. Example: scalar float32 `→ ld.global.f32 %v,[%a+0];`; two half lanes `→ ld.shared.v2.b16 {%h0,%h1},[%a+0];`. Address calculation happened earlier; this rule supplies the actual memory transaction.

### renderer/ptx.py:L117 — Buffer declaration

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L117). Match BUFFER. REG emits no lines; otherwise emit `.shared .align 16 .b8 local<slot>[numel*itemsize];` and a base-address `mov.u64`. Example: 32 float32 local elements slot 0 become `.shared .align 16 .b8 local0[128]; mov.u64 %base, local0[0];`. `render()` already allocates register-backed buffers separately. The non-REG branch assumes this BUFFER is shared allocation; global arguments arrive through PARAM.

### renderer/ptx.py:L119 — Wait-loop header

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L119). Match `RANGE:void`; emit `WAITLOOP_<position>:`. Example: void RANGE at linearized index 12 emits `WAITLOOP_12:`. Unlike a counted RANGE, this is a label for retrying a condition and has no induction register.

### renderer/ptx.py:L120 — Wait-loop backedge

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L120). Match END with exactly `(anything,RANGE:void,c)`. Emit `@c bra WAITLOOP_<range-position>;`. Example: `END(token,range12,p) → @%p bra WAITLOOP_12;`. True means repeat, not exit. The dependency source is not an assembly operand.

### renderer/ptx.py:L122 — Counted-loop header

With bound 2, entry jumps to the test: -1 increments to 0, then the body runs; next it increments to 1 and runs again; then 2 fails the test. The unusual -1 initialization is a consequence of placing the test after the body in the emitted text.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L122). Match remaining RANGE. Emit counter initialization to -1, jump to `END_<counter>`, then `LOOP_<counter>:`. Example: counter `%r` emits `mov.u32 %r,-1; bra END_r; LOOP_r:`. The initial jump reaches the increment/test first, producing first body index 0 and skipping the body when the extent is zero.

### renderer/ptx.py:L126 — Counted-loop increment/test/backedge

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L126). Match END with exactly `(anything,RANGE r)`. Emit end label, signed ADD of 1, signed CMPLT against `r.src[0]`, and predicated branch to the loop label. Example: `END(...,RANGE(4)) → END_r: add.s32 %r,%r,1; setp.lt.s32 %p,%r,%four; @%p bra LOOP_r;`. Together with L122, body indices are 0,1,2,3.

### renderer/ptx.py:L131 — Conditional skip

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L131). Match IF; emit `@!condition bra IF_<condition-register>_<if-position>;`. Example: IF at position 20 on `%p` gives `@!%p bra IF_p_20;`. A false condition skips the guarded body; including the position distinguishes separate IFs using the same predicate.

### renderer/ptx.py:L132 — Conditional end label

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L132). Match ENDIF; recover the matching IF from source 0 and emit its destination label. Example: `ENDIF(IF20(p)) → IF_p_20:`. This pairs with L131; deriving the label from the original IF avoids accidental cross-branch targets.

### renderer/ptx.py:L133 — Tensor-core matrix fragment emission

A fragment is the subset of a matrix tile assigned to one thread. First pairs of 16-bit values occupy one 32-bit argument word; then the warp cooperatively executes the tile multiply-add; finally results are exposed as the expected per-thread components. No thread supplies the entire tile on its own.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L133). Match WMMA and call `render_wmma`. It packs source lanes into 32-bit registers, emits `mma.sync.aligned.m<M>n<N>k<K>.row.col.<out>.<in>.<in>.<out>`, then unpacks result lanes. Example: a `(N,M,K)=(8,16,16)`, half-input, float-output fragment emits `mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 {acc...},{a...},{b...},{acc...};`; pairs of half inputs are first packed by `mov.b32 %packed,{%h0,%h1};`. Float input maps to `tf32`; half input maps to `f16`; float/half output maps to `f32`/`f16`. This is a warp-fragment layout contract, not a complete arbitrary-shaped matmul in one instruction. The helper requires `wmma_r` to have been populated by register allocation.

### renderer/ptx.py:L134 — Workgroup barrier

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L134). Match BARRIER; emit `ctx.barrier`, here `bar.sync\t0;`. Example: a dependency barrier between shared-memory stores and loads becomes `bar.sync 0;`. It synchronizes within the kernel's thread block; it cannot synchronize two kernel launches.

## PTX architecture-specific extension

### renderer/ptx.py:L148 — Pre-sm80 half MAX/EXP2 widening

The architecture name acts as a feature switch for this specific lowering. An older target gets additional conversions around the same mathematical operation; newer targets can use the half form directly in this renderer’s policy.

[Source](../../../../tinygrad/tinygrad/renderer/ptx.py#L148). This matcher is appended only when `int(target.arch[3:]) < 80`. Match `MAX` or `EXP2` with half result; widen every input to float32, reconstruct the same opcode/argument, then narrow to half. Examples: on `sm_75`, `MAX(h,j) → half(MAX(float32(h),float32(j)))`; `EXP2(h) → half(EXP2(float32(h)))`. On `sm_80`, this extra rule is absent. Inference: the renderer treats those half instruction forms as requiring sm80 while leaving other supported-half operations available earlier. Do not turn this into “all half ops require sm80”: `supported_dtypes()` independently admits half starting at sm53; tensor-core choices independently distinguish sm75 and sm80.

## WGSL legalization (`wgsl_matcher`)

Packing is the recurring abstraction leak. The type map represents byte/short arithmetic as i32/u32, while memory uses 32-bit words. `packed_field` computes word index `i//(4/itemsize)`, shift `(uint32(i)%(4/itemsize))*8*itemsize`, and mask `2**(8*itemsize)-1`. Packed memory uses `atomic<u32>`; register arrays and half values are excluded. For bool, the field is one byte even though only a truth value is needed.

### renderer/wgsl.py:L44 — Boolean less-than and XOR through integers

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L44). Match `CMPLT` or `XOR` with first source bool; cast both operands to int32, perform the original opcode, and cast to bool. Examples: `false < true → bool(int32(false)<int32(true))`; `true XOR false → bool(int32(true) XOR int32(false))`. Inference: use integer operators supported by the target language for these boolean operations. A comparison already produces bool, so its final cast may later simplify.

### renderer/wgsl.py:L46 — Packed byte/short loads

Element 5 is the second byte of the second 32-bit word: `5//4=1`, `5%4=1`, and `1×8=8` gives the shift. Right shift brings its byte down to bits 0–7; AND 255 discards neighboring bytes. Signed types then interpret the top bit of that extracted field as a sign.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L46). Match LOAD whose first source is INDEX, permitting alternate/gate sources; rewrite only if `is_packed(l)` (buffer dtype itemsize<4, not half, not REG). Call `packed_load`: load the containing uint32 word, shift and mask its field, then cast; char/short additionally sign-extend. Example: uint8 element 5 in word `0x0000AB00` uses word index 1, shift 8, mask 255: `(word>>8)&255 → 171`. For int8 byte `0xFE`, sign extension yields -2. Original load argument and alternate/gate sources are carried into the word load (alternate cast to uint32). **Sharp edge:** extraction happens after the alternate is selected; a general scalar nonzero alternate is not automatically positioned into the selected field. The rule alone does not prove all masked alternate forms correct.

### renderer/wgsl.py:L47 — Packed read-modify-write stores

Split the example into two pieces: `0x11223344 & 0xffff00ff = 0x11220044` clears only the selected byte; OR with `0x00007a00` inserts its replacement and gives `0x11227a44`. The rest of the word is unchanged.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L47). Match STORE; only packed storage takes `packed_store`. Compute `new_v=(uint32(value & mask)<<shift)` and `wmask=uint32((mask<<shift) XOR 0xffffffff)`; store `(LOAD(word)&wmask)|new_v`. Propagate gates to both load and store; gated load uses zero alternate. Example: store uint8 0x7A at element 5: word index 1, shift 8, `wmask=0xffff00ff`, `new_v=0x00007a00`, so word `0x11223344 → 0x11227a44`. Bool is first cast to int32: the source comment explicitly says `bool & 0xFF` would create a weakint constant after weak dtypes were already lowered. This builds an intermediate expression recognized by the atomic emission rule at L90.

### renderer/wgsl.py:L48 — Left shift through unsigned bit pattern

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L48). Match `SHL(a,b)` and rewrite only when count dtype is not uint32. Emit `(bitcast<uint32>(a) << uint32(b)).bitcast(a.dtype)`. Example: `int32(-1)<<int32(1) → bitcast<int32>(uint32(0xffffffff)<<uint32(1)) → -2`. Inference: unsigned shift syntax and explicit bit-preserving casts avoid signed-left-shift type issues. **Exact guard:** when the count is already uint32, this rule does not bitcast the left operand.

### renderer/wgsl.py:L49 — Right-shift count conversion

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L49). Match `SHR(x,y)` where count dtype differs from uint32. Replace only the count with its uint32 cast. Example: `int32(-8)>>int32(1) → int32(-8)>>uint32(1) → -4`. Keeping the signed left operand retains sign extension.

### renderer/wgsl.py:L51 — Self-inequality becomes bitwise NaN detection

Float infinity has all exponent bits set and zero fraction bits. A NaN has the same exponent with a nonzero fraction. After removing the sign bit, a pattern greater than positive infinity therefore identifies NaN; finite numbers fall below it.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L51). Match `a != a` with exactly the same floating UOp bound twice. Replace with `is_nan(a)`: bitcast to same-width unsigned, clear the sign, and compare with the infinity exponent pattern. Float32 example: `(bits(a)&0x7fffffff)>0x7f800000`; `0x7fc00001` is true, `0x7f800000` is false. The source comment explicitly calls this a NaN-check fix. Inference: avoid relying on the target's treatment of a reflexive floating comparison to implement NaN detection. Half uses its own width/exponent/mantissa, not the float32 constants.

### renderer/wgsl.py:L52 — Self-equality becomes negated bitwise NaN detection

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L52). Match floating `CMPEQ(a,a)` and return `is_nan(a).ne(True)`. Example: `a==a → ((bits(a)&0x7fffffff)>0x7f800000) != true`; finite 3.0 gives true, NaN gives false. The source comment explicitly explains the second form: decomposition can turn `(a!=a).logical_not()` into CMPEQ, so fixing only self-inequality misses it.

## WGSL string emission (before inherited `base_rewrite`)

### renderer/wgsl.py:L68 — Packed address cast is an alias

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L68). Match `CAST(INDEX x):uint32`; emit `ctx[x]` only if the indexed buffer is packed. Example: the packed load's uint32 storage cast of `bytes[word_i] → bytes[word_i]`, not `u32(bytes[word_i])`. Inference: this cast changes the storage interpretation used by lowering, while the actual declaration already uses atomic uint32 words; emitting a numeric value conversion here would destroy the address-like role.

### renderer/wgsl.py:L69 — Unsigned negation as subtraction

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L69). Match NEG with unsigned result; emit `(0-operand)`. Example: `NEG(u32(1)) → (0-u)` (wrapping unsigned value 0xffffffff). Inference: express unsigned modular negation with subtraction rather than the unary negation spelling used for signed values.

### renderer/wgsl.py:L70 — Boolean literal

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L70). Match `CAST(CONST c):bool`; emit `true` when `c.val` is truthy, otherwise `false`. Example: `bool(CONST(0)) → false`. This materializes a correctly typed WGSL bool literal, not integer 0/1.

### renderer/wgsl.py:L71 — Unsigned literals, including negative bit patterns

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L71). Match constant casts to uchar, ushort, or uint32. If negative emit `bitcast<u32>(c.val)`; otherwise emit `(c.val & 0xffffffff)u`. Examples: `uint32(CONST(-1)) → bitcast<u32>(-1)`; `uint32(CONST(7)) → 7u`. Inference: negative integer syntax must not be interpreted as a negative unsigned literal; widening byte/short values to u32 follows `type_map`. This formatting rule applies a 32-bit mask, not an additional 8/16-bit mask.

### renderer/wgsl.py:L74 — Signed constants with explicit negative type

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L74). Match constant cast to int32, truncate the value with `truncate[int32]`, emit `i32(v)` if negative and bare `v` otherwise. Examples: `int32(CONST(4294967295)) → i32(-1)`; `int32(CONST(3)) → 3`. The comment explicitly says contextual conversion rejects a bare negative abstract integer in a u32 position. Giving it a signed concrete type permits later bit-preserving operations.

### renderer/wgsl.py:L75 — Packed and unpacked arrays

Ten one-byte elements need `ceil(10/4)=3` words. The unused final two bytes are allocation padding, not extra logical tensor elements. Register arrays use another representation because their accesses do not race between threads.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L75). Match BUFFER; emit `var<workgroup>` for LOCAL, `var` otherwise, then `array<buf_map(x),_packed_size(x)>`. Examples: 10 local uint8 elements become `var<workgroup> b: array<atomic<u32>,3>;`; 10 register int8 elements become `var b: array<i32,10>;`; 10 local half elements use `array<f16,10>`. Inference: packed allocation rounds up word count, while ordinary arrays preserve element count. `render_kernel` later moves workgroup declarations outside the entry function.

### renderer/wgsl.py:L77 — Integer bits to half via two-lane bitcast

The target bitcast needs equal total widths: one u32 and two f16 components are both 32 bits. Selecting component 0 then recovers the desired low 16-bit floating value.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L77). Match BITCAST to half whose source dtype is short, ushort, or uint32. Emit `bitcast<vec2<f16>>(source)[0]`. Example: `half_bits(uint32(0x00003c00)) → bitcast<vec2<f16>>(u)[0] → 1.0h`. Inference: the source is physically 32 bits, so preserve bitcast width by producing two half lanes and taking the low one.

### renderer/wgsl.py:L79 — Bitcast to unsigned byte

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L79). Match BITCAST with uchar result; emit `bitcast<u32>(source&0xFF)`. Example: int8 -1 stored in i32 has low byte 0xff; result becomes u32 255. Inference: WGSL has no separate byte arithmetic type in this renderer, so preserve only the desired 8 bits in a u32 container.

### renderer/wgsl.py:L80 — Bitcast to signed byte

For 0xfe, shifting left 24 moves bit 7 to the 32-bit sign position: `0x000000fe → 0xfe000000`. The signed right shift fills the upper bits with ones, producing `0xfffffffe`, which is int32 -2.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L80). Match BITCAST with char result; emit `((i32(source&0xFF)<<24)>>24)`. Example: unsigned byte 254 becomes i32 -2. The left/right signed shifts extend bit 7 through the high 24 bits, making the widened representation behave like int8.

### renderer/wgsl.py:L81 — Bitcast to unsigned short, including half

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L81). Match BITCAST with ushort result. Half source emits `bitcast<u32>(vec2<f16>(source,0))`; other sources emit `bitcast<u32>(source&0xFFFF)`. Examples: half 1.0 bits become `0x00003c00`; int16 -1 becomes 65535. Pairing half with zero produces a 32-bit bitcast operand, whereas integer paths mask to the low 16 bits.

### renderer/wgsl.py:L83 — Bitcast to signed short, including half

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L83). Match BITCAST with short result. Half source emits `bitcast<i32>(vec2<f16>(source,0))`; other sources emit `((i32(source&0xFFFF)<<16)>>16)`. Examples: integer bits 0xfffe become -2 in the non-half path; half 1.0 gives bit pattern 0x00003c00. **Sharp edge:** the half branch zeroes the upper half instead of sign-extending bit 15: half -1.0 (`0xbc00`) gives positive i32 48128 at this local step. Do not claim both branches independently establish a normalized signed-int16 arithmetic value; later use determines whether extra normalization is needed.

### renderer/wgsl.py:L85 — General bitcast

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L85). Match remaining BITCASTs; emit `bitcast<type_map[result_dtype]>(source)`. Example: `bitcast<float32>(uint32(0x3f800000)) → bitcast<f32>(u) → 1.0`. Earlier rules handle narrow-width cases that cannot simply use this generic spelling.

### renderer/wgsl.py:L86 — Gated load as selection

In Python terms, `select(0, data[i], valid)` behaves like passing both values to a function, not like the short-circuit expression `data[i] if valid else 0`. The distinction matters whenever evaluating `data[i]` needs its own safety guarantee.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L86). Match `LOAD(b,v,gate)`; emit `select(alternate,render_load(address,b.src[0]),gate)`. Example: ordinary float load `→ select(0.0, data[i], valid)`; packed word load uses `select(0u,atomicLoad(&data[word_i]),valid)`. WGSL `select` takes false value before true value, opposite to the UOp source order. **Sharp edge:** this is not an `if` guarding the memory access; the emitted select expression evaluates its arguments. The rule itself does not establish that an invalid address is never accessed.

### renderer/wgsl.py:L88 — Ordinary or atomic load

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L88). Match single-source `LOAD(b)`; call `render_load(ctx[b],b)`. Example: float buffer load `→ data[i]`; packed buffer word load `→ atomicLoad(&bytes[word_i])`. This pairs with `buf_map`, which declares packed storage as atomic words.

### renderer/wgsl.py:L90 — Packed stores become field-preserving atomic updates

Why can the second operation be addition? Immediately after this writer clears its field, that field contains zero, so adding the shifted replacement sets it without a carry into neighboring fields. Writers to different fields can preserve each other’s bits. Writers to the same field violate that reasoning, and a reader between clear and add can observe the temporary zero.

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L90). Match STORE whose value is either `packed_rmw` or `packed_rmw | nv`. `packed_rmw` specifically binds `(LOAD(CAST(b):uint32,...) & wmask)`; the same `b` must be the store address. Return a string only for packed `b`. Emit `atomicAnd(&b,wmask);` and, when `nv` exists, `atomicAdd(&b,nv);`. Example: writing byte 0x7a in bits 8..15 emits `atomicAnd(&words[1],0xffff00ffu); atomicAdd(&words[1],0x00007a00u);`. Zero byte has no add when simplification removed `|0`. The source comment explicitly identifies the clear-then-set scheme. Inference: atomic updates preserve other threads' disjoint byte fields within the same word, unlike a plain full-word read-modify-write. **Not an atomic transaction:** two operations can interleave; this does not make simultaneous writes to the same field or racing readers safe. The OR pattern expresses the packed_store output shape; binding the same address prevents substituting this trick for an unrelated loaded word.

### renderer/wgsl.py:L92 — Generic store assignment

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L92). Match `STORE(b,v)` not already emitted by the packed atomic rule; emit `address = value;`. Example: `STORE(float_buffer[i],f) → data[i] = f;`. Correct packed write shapes must hit L90 first: generic assignment is not a replacement for an atomic update to `atomic<u32>` storage.

### renderer/wgsl.py:L93 — Array index syntax

[Source](../../../../tinygrad/tinygrad/renderer/wgsl.py#L93). Match `INDEX(b,idx)` with exactly two sources; emit `b[idx]`. The formatting guard strips surrounding parentheses only when `idx.arg is Ops.ADD`. Example: index text `(i+1)` in that specific representation becomes `data[i+1]`; a plain `i` becomes `data[i]`. Inference: this is syntax formatting, not bounds checking or address arithmetic optimization. Notice that the actual guard tests `arg`, not `idx.op`; do not paraphrase it as “all ADD UOps lose parentheses.”

## Reading these rules as larger lowerings

For a packed uint8 write, follow **L47 → packed_field → L68/L88 → L90**, not just the final atomic strings. The expanded read/AND/OR UOps are a recognition form: the final emitter can avoid an explicit old-word load and keep the other bytes intact with atomic field updates. A zero write is a separate shape because ordinary simplification can erase the OR; that is why L90 accepts both alternatives.

For half RMSNorm on PTX, reduction and scheduling happen before these matchers. A remaining half SQRT is widened by L46, whereas half EXP2/MAX widening depends on sm80 via L148. A scalar masked float load uses L106's true alternate; a vector masked load takes its zero-initialization branch. WMMA fragments that follow a normalization stage use L133 only if earlier tensor-core lowering produced WMMA. None of these emission rules decides whether RMSNorm and a following matmul share a kernel; the matcher changes instructions in an already formed kernel.

The most useful exercises here are to trace **representation boundaries**: (1) store/load a predicate through byte memory in PTX, (2) write adjacent uint8 fields from separate WGSL invocations, (3) compare masked scalar and vector PTX loads with nonzero alternatives, (4) inspect half→short WGSL bitcast of a negative half. The worked local transformations above expose what these rules actually guarantee and where a complete correctness argument must inspect the caller and earlier lowering.
