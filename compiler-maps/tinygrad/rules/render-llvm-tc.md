# Every LLVM and tensor-core matcher rule

## What the output represents

LLVM IR is a compiler intermediate language, not GPU assembly. Tinygrad renders explicit loads, arithmetic, branches, and calls into LLVM IR; an LLVM compiler subsequently chooses machine instructions. The CPU and AMD routes share the basic language but use different target intrinsics, meaning compiler-recognized operations. Graph legalization changes tinygrad UOps before rendering; string rules below print the already lowered program. Neither stage here chooses kernel fusion.

LLVM examples use **SSA (static single assignment)**: `%x` names one computed value and is assigned once. `i32` means 32 integer bits, `float` means float32, and `<4 x float>` is four components held as one vector value. A **basic block** is a straight-line instruction sequence ending in a branch. A **phi** joins control-flow paths by selecting the value supplied by the predecessor actually taken. Thus `if valid: x=load(p); else: x=0` needs a branch and a phi; the invalid path must never execute the load. A plain `select` only chooses between already available values.

GLOBAL and LOCAL identify device and workgroup-shared memory; ALU identifies computed values rather than pointers, and REG denotes register-backed storage. `INDEX` therefore has two very different meanings: find an address in a buffer or extract a component from a vector. `CAST` changes a number's representation numerically; `BITCAST` keeps the bits and changes their interpretation. bf16 is a 16-bit float format, FP8 an 8-bit float format; integer containers for their bits are not integer-valued tensor elements.

The tensor-core rules concern cooperative matrix instructions. A GPU executes threads in groups called warps (NVIDIA) or waves (AMD). Each thread supplies only a **fragment**, its assigned subset of the matrix tile. `WMMA(A,B,C)` expresses the cooperative tile calculation `A @ B + C`; MFMA and WMMA are AMD instruction families used to implement it. For an `M×N×K` tile, `K` is the number of products accumulated per output element. A vector lane in an individual thread's fragment is distinct from a thread's lane number in its wave. The **ABI** fixes the argument bits and component layout expected by an intrinsic. The validators below adapt that layout after earlier passes have distributed matrix elements among threads.

Snapshot: `107adc31701df0247dfa45e175984df906a68b53`. Scope: every direct PatternMatcher rule tuple in `renderer/llvmir.py` and `renderer/tc.py`, including the matcher created in AMDLLVMRenderer.__init__. Inherited/composed C-style float-emulation rules are explained individually in [render-cstyle.md](render-cstyle.md). Tensor-core layout lists are not PatternMatcher rules; [the AMD guide](../amd-pattern-matchers.md) explains how those layouts constrain these rules.

Examples are schematic, source-derived and unexecuted unless explicitly labeled **observed**. `%a`, `%p`, and similar names stand for renderer-assigned SSA names. “Why” below is an inference from the current input/output contract unless explicitly attributed to a source comment; this is not commit-history attribution. Source links point at the exact rule's outer tuple.

## How these matchers compose

LLVMRenderer inherits `create_non_native_float_pats((bfloat16,)) + pm_manual_bf16_cast` as its graph `extra_matcher`. CPULLVMRenderer selects `base_rewrite` for strings. AMDLLVMRenderer instead puts its five GPU string rules before `base_rewrite`, then appends a WMMA rule during construction. Its extra graph rules add FP8 emulation and two double-transcendental decompositions, followed by a target-selected WMMA validator. `extra_matcher` runs during final codegen graph rewriting; `string_rewrite.rewrite(u, ctx=r)` runs for each linear UOp while rendering.

The renderer handles PARAMs, BUFFER declarations, AFTER aliases, SINK metadata, constant casts, and same-storage LLVM casts in ordinary Python before calling string_rewrite. Therefore a PM tuple can be statically present without every syntactically matching node reaching it. The first matching rule returning a non-None result other than the original UOp wins; returning the identical UOp also falls through. This is particularly important for AMD barriers vs generic fences, gated vs plain loads, unbounded vs bounded ranges, and buffer-address vs vector-element indexing.

## renderer/llvmir.py: base_rewrite

### renderer/llvmir.py:L79 — Buffer address INDEX/SHRINK

Read `getelementptr` as “compute the address of an element.” It does not load that element. The element type supplies scaling, so index 3 into float32 storage means 12 bytes from its base.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:79). Matches INDEX or SHRINK whose first source is BUFFER, PARAM, or AFTER, allowing further sources. Emits `getelementptr inbounds` using the buffer element type and index dtype. Example: `INDEX(param_f32, i)` → `%p = getelementptr inbounds float, float* %data, i32 %i`.

Why: converts abstract address selection into a typed LLVM pointer calculation. Sharp edge: `inbounds` is a semantic promise, not a runtime bounds check; validity/gating must already have been settled. SHRINK's extra shape extent is not an additional GEP coordinate here. This rule precedes the constant register-index rule so a constant memory index remains a pointer.

### renderer/llvmir.py:L82 — Constant register-vector extraction

Given `%v=[10,20,30,40]`, extracting lane 2 returns 30 without touching device memory. That is why even a constant index cannot determine the operation by itself: the kind of thing being indexed matters.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:82). Matches INDEX with a committed constant index; returns text only when the indexed value's address space is ALU. Emits `extractelement` with a literal i32 lane. Example: `INDEX(float4_value, CAST_i32(CONST(2)))` → `%x = extractelement <4 x float> %v, i32 2`.

Why: LLVM vectors are SSA values, not memory pointers. Sharp edge: a dynamic index or a non-ALU buffer does not use this rule; it returns None for the latter, rather than forcing memory through vector syntax. Vector shape/count comes from `max_numel`, not a vector-valued dtype object.

### renderer/llvmir.py:L86 — Gated LOAD with control flow and phi

Trace the false path: branch to exit, carry the alternate value, and let the phi pick it. No instruction on that path reads `%p`. The phi joins values after the safety decision; it does not make the decision safe on its own.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:86). Matches three-source LOAD(pointer, alternate, mask). Emits entry/load/exit blocks; the mask controls entry into the load block and a phi chooses the loaded value or alternate. Volatile qualification comes from the underlying PARAM's volatile flag. Example: `LOAD(p,0,i<n)` → `if i<n then load p else 0`, represented by branch and phi.

Why: selecting a value after an unconditional invalid memory read would not make the read safe. Sharp edge: this rule changes control flow; do not replace it with unconditional load + LLVM select merely because the algebraic result appears identical. Alternate and loaded vector shapes must already agree.

### renderer/llvmir.py:L94 — Ordinary LOAD

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:94). Matches a pointer-like UPat variable's plain `.load()`. Emits typed `load`, optionally `volatile`, with vector width taken from the indexed pointer. Example: `LOAD(INDEX(A,i))` → `%x = load float, float* %p`.

Why: materializes memory into an SSA value. Sharp edge: the preceding gated rule is what prevents invalid accesses; this one adds no predicate. The nontemporal annotation has a dedicated HIP rule but no equivalent special branch here, so do not claim identical cache-hint behavior between backends.

### renderer/llvmir.py:L97 — STORE

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:97). Matches `idx.store(var)` and emits a typed, optionally volatile LLVM store. Example: `STORE(p,float4_value)` → `store <4 x float> %v, <4 x float>* %p`.

Why: fulfills the side effect represented by STORE. Sharp edge: there is no gate argument in this rule's pattern. Gated stores must already have been linearized into IF/STORE/ENDIF by the generic linearization cleanup; adding a select to the stored value would still perform the memory side effect.

### renderer/llvmir.py:L102 — STACK to insertelement chain

Start with two unfilled components. The first insertion makes `[a,unfilled]`; the second makes `[a,b]`. `poison` denotes a value whose use can invalidate program semantics, so the intermediate unfilled component must not escape.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:102). Matches STACK and creates one `insertelement` per source, starting with `poison`, threading temporary names, and assigning the final insertion to the UOp's name. Example: `STACK(a,b)` → `%x_0 = insertelement <2 x float> poison, float %a, i32 0; %x = insertelement <2 x float> %x_0, float %b, i32 1`.

Why: LLVM has no general vector-literal syntax for arbitrary runtime scalar SSA operands. Sharp edge: poison is safe here only because all represented lanes are filled before consuming the completed vector. The inner comprehension generates output instructions, not separately registered PM rules.

### renderer/llvmir.py:L107 — BITCAST

Eight FP8 values have 64 encoded bits in total. Repack them into one i64 argument without changing any bit; the later matrix intrinsic still interprets them as eight floating elements.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:107). Matches BITCAST and emits a LLVM bitcast with source and destination vector widths. Example: `BITCAST_u32(float_value)` → `%u = bitcast float %f to i32`; `BITCAST_u64(fp8×8)` preserves the same 64 bits.

Why: representation adaptation must preserve bits rather than numerically convert them. Sharp edge: total source/destination bit size must agree, and pointer-address-space adaptation is handled elsewhere. This is the primitive used by AMD WMMA validators to satisfy integer-typed fragment ABIs.

### renderer/llvmir.py:L109 — Numeric CAST

`zext` fills new high bits with zero, so uint8 255 becomes uint64 255. A signed extension instead repeats the sign bit, so signed int8 -1 stays -1 when widened. Picking the wrong family changes values, not just spelling.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:109). Matches CAST and delegates opcode selection to `lcast`: float widening/truncation, signed/unsigned integer-to-float, float-to-signed/unsigned integer, integer truncation or sign/zero extension. Examples: `CAST_f32(i16)` → `sitofp i16 %x to float`; `CAST_u64(u8)` → `zext i8 %x to i64`; `CAST_f16(f32)` → `fptrunc float %x to half`.

Why: preserves conversion semantics beyond simply changing a type annotation. Sharp edge: equal-storage signedness changes and constant casts are intercepted by the renderer loop; unsupported BF16/FP8 conversions should have been decomposed earlier or caught by AMD-specific rules. This scalar spelling is not a universal vector conversion implementation.

### renderer/llvmir.py:L110 — TRUNC intrinsic

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:110). Matches TRUNC and emits the dtype-suffixed LLVM trunc intrinsic. Example: `TRUNC(f32(1.75))` → a call to `llvm.trunc.float` in this renderer's spelling, semantically producing floating-point 1.0.

Why: truncation toward zero within floating-point is not integer conversion. Sharp edge: this is the literal renderer's naming convention (`ldt` returns `float`/`double`/`half`); do not silently substitute another intrinsic declaration convention when tracing generated text. Downstream compiler normalization/declarations are a separate stage.

### renderer/llvmir.py:L112 — Binary operation table dispatch

The float flags grant the downstream compiler specific freedoms: `nsz` relaxes signed-zero distinctions, `arcp` permits reciprocal transformations, `contract` allows contraction such as multiply-add, and `afn` permits approximate functions. Integer `nsw` promises no signed overflow. These permissions/promises are part of the generated program’s semantics.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:112). Matches any GroupOp.Binary and selects `lop[first_source.dtype][op]`. Template examples: float ADD→`fadd nsz arcp contract afn`; signed CDIV→`sdiv`; unsigned CDIV→`udiv`; signed CMPLT→`icmp slt`; unsigned CMPLT→`icmp ult`; float CMPLT→`fcmp ... olt`.

Why: the same graph operation has different LLVM signedness and floating-point semantics. This is one rule template expanded by the opcode/dtype tables, not one registered PM per table entry. Sharp edge: float flags permit numerical transformations; integer signed ADD/MUL use `nsw` in the table. Unsupported table combinations should have been decomposed before rendering, otherwise lookup fails rather than becoming a safe fallback.

### renderer/llvmir.py:L114 — WHERE to select

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:114). Matches WHERE and emits typed LLVM select. Example: `WHERE(p,a,b)` → `%x = select i1 %p, float %a, float %b`.

Why: an already computed value choice belongs in SSA, without introducing unnecessary control-flow blocks. Sharp edge: select is not lazy evaluation of arbitrary source expressions. It cannot substitute for the gated-LOAD branch rule when evaluating a source would be unsafe.

### renderer/llvmir.py:L118 — Unbounded RANGE header

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:118). Matches RANGE of void dtype and emits a branch to its loop label followed by the label. Example: `RANGE:void` → `br label %loop_r; loop_r:`.

Why: represents an unbounded/recurrent loop without inventing an induction counter. Sharp edge: this precedes generic RANGE rendering, which assumes a typed counter and a bound. Termination belongs to its special END rule.

### renderer/llvmir.py:L119 — Conditional END of unbounded RANGE

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:119). Matches END with a body source, void RANGE, and condition. Emits a branch back to the loop when condition is true, otherwise to exit. Example: `END(body, forever, keep_going)` → `br i1 %keep_going, label %loop_r, label %loop_exit_r`.

Why: makes the loop continuation condition explicit. Sharp edge: the predicate means continue, not break; inverting it silently changes execution. The ordinary two-source END rule below has a different contract.

### renderer/llvmir.py:L123 — Bounded RANGE with SSA induction phi

On the first visit the phi supplies 0. After one body execution, the backedge supplies the incremented counter 1. Repeating that selection implements a changing loop counter while every individual SSA name is still assigned only once.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:123). Matches ordinary RANGE; emits entry/latch/body labels, an induction phi initialized to zero, counter+1, unsigned `< bound`, and a branch into body or exit. Example: `RANGE(32)` → SSA loop visiting indices 0…31.

Why: LLVM loop variables are SSA definitions connected by a phi, not mutable C counters. Sharp edge: zero-based nonnegative range assumptions justify unsigned comparison; this is not a general negative-step Python range implementation. Its backedge label must be supplied by the associated END.

### renderer/llvmir.py:L133 — END of bounded RANGE

CFG means control-flow graph: blocks connected by possible branches. This footer supplies the edge back to the loop test and the label reached once the test fails.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:133). Matches END(body, RANGE) and emits the footer branch, footer label, backedge to latch, then exit label. Example: the end of `RANGE(32)` → `br footer; footer: br latch; exit:`.

Why: closes the CFG structure begun by the induction-phi rule. Sharp edge: pairing and unique range labels must already be correct; this is textual CFG construction, not loop-dependence analysis or a scheduler.

### renderer/llvmir.py:L140 — IF header

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:140). Matches IF and branches on its first source to an ifbody label or ifskip label. Example: `IF(i<n)` before a store → `br i1 %gate, label %ifbody_x, label %ifskip_x; ifbody_x:`.

Why: represents guarded side effects such as gated STORE. Sharp edge: IF's other dependency sources are ordering information, not additional boolean tests; the condition is source zero.

### renderer/llvmir.py:L141 — ENDIF join

A value dominates its use if every path reaching the use has already computed it. A value created only in the true branch cannot automatically be used after the join, because the false path never defined it.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:141). Matches ENDIF and branches to the skip/join label named from its corresponding IF source. Example: `ENDIF(if_x)` → `br label %ifskip_x; ifskip_x:`.

Why: reconnects the guarded side-effect path with skipped execution. Sharp edge: it adds no phi for values defined only inside the IF; producers and linearization must obey the resulting dominance requirements.

### renderer/llvmir.py:L143 — Generic BARRIER fence

A fence constrains memory ordering. A rendezvous additionally waits for participating threads to arrive. A cooperative GPU algorithm can require both; the same word “barrier” in the input graph needs a target-appropriate implementation.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:143). Matches BARRIER and emits `fence seq_cst`. Example: `BARRIER` in the CPU LLVM route → sequentially consistent LLVM fence.

Why: provides a generic memory-ordering primitive. Sharp edge: this alone is not a GPU workgroup rendezvous. AMD's earlier BARRIER rule replaces it with workgroup release/barrier/acquire semantics; reordering composition would lose that distinction.

## renderer/llvmir.py: AMD rules

### renderer/llvmir.py:L231 — AMD SPECIAL IDs

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:231). Matches SPECIAL and looks up group vs local ID from the first character of `arg`, and x/y/z from its last digit. Example: `SPECIAL(arg='lidx0')` → call `llvm.amdgcn.workitem.id.x`; `gidx1` → workgroup.id.y.

Why: GPU launch axes come from hardware execution state rather than loop counters. Sharp edge: malformed or unexpected argument naming is not normalized by this rule. The launch-shape bounds attached to SPECIAL must remain consistent with scheduling.

### renderer/llvmir.py:L232 — AMD-supported LLVM transcendental template

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:232). One pattern matches the keys of `llvm_intrinsics`: SQRT, LOG2, EXP2. Emits a dtype-specific LLVM intrinsic call. Examples: `SQRT(f32 x)` → `@llvm.sqrt.float(float %x)`; LOG2→`@llvm.log2.float`; EXP2→`@llvm.exp2.float` in renderer spelling.

Why: exposes backend-supported math operations directly instead of polynomial expansion. Sharp edge: op-level support does not mean every dtype is supported; the two double rules below are necessary precisely because the op table alone is too coarse. The three opcode cases share one registered rule template.

### renderer/llvmir.py:L234 — AMD workgroup BARRIER

Release orders the writes before synchronization, the barrier waits for the workgroup, and acquire orders later reads after it. Another workgroup does not participate in this rendezvous.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:234). Matches BARRIER and emits `fence syncscope("workgroup") release`, `llvm.amdgcn.s.barrier()`, then acquire fence. Example: local partial-sum stores → this barrier sequence → local partial-sum loads.

Why: a cooperative reduction needs both memory ordering and a workgroup rendezvous. Sharp edge: it cannot synchronize different workgroups or fuse separate kernel launches. It must run before generic BARRIER rendering; this is correctness-sensitive composition ordering.

### renderer/llvmir.py:L235 — AMD float32 to FP8

Clamping means limiting a finite number to the representable endpoint before encoding it. FP8 formats have different endpoints, so the format selector changes the conversion rather than merely tagging the result.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:235). Matches CAST to any dtype in `dtypes.fp8s` from float32. Emits `call i8 @f32_to_fp8(float value, i1 format)` with format=1 for fp8e5m2 and 0 otherwise. Example: `CAST_fp8e5m2(x_f32)` → `f32_to_fp8(x,1)`.

Why: FP8 bytes encode floating-point, so ordinary integer truncation is wrong. The generated helper finite-clamps to ±57344 for BF8 or ±448 for FP8, bypasses clamp for NaN/Inf, performs a packed conversion, and extracts the low byte. Sharp edge: the syntactic pattern includes more FP8 dtypes than target support; unsupported variants are expected to be dealt with earlier. Do not infer full FNUZ support from this predicate.

### renderer/llvmir.py:L237 — AMD FP8 to float32

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:237). Matches CAST to float32 from FP8. Emits `zext i8` to i32 then `llvm.amdgcn.cvt.f32.bf8` for fp8e5m2 or `.fp8` otherwise, with byte selector zero. Example: a storage byte `0x38` of e4m3 → zero-extended encoded byte → hardware FP8 conversion, not integer value 56.0.

Why: the conversion intrinsic accepts an encoded byte packed in a 32-bit argument. Sharp edge: zero-extension is representation setup, not the desired numeric conversion itself; selecting a different byte changes the value. As above, pattern breadth is not advertised dtype support.

### renderer/llvmir.py:L243 — Double LOG2 decomposition

The helper separates a number into a power-of-two exponent and a mantissa. Since `log2(m×2**e)=log2(m)+e`, it can approximate the smaller mantissa problem and combine the result with e; exact special cases remain the helper’s responsibility.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:243). Matches LOG2 with double output and one named input; calls `xlog2`. Example: `LOG2(x_f64)` → the UOp exponent/mantissa decomposition and approximation graph produced by `xlog2(x)` rather than a native double log2 intrinsic.

Why: **explicit source comment:** AMD LLVM log2/exp2 intrinsics do not support double. Sharp edge: this is dtype-specific even though AMD advertises LOG2 in `code_for_op`; otherwise the generic unsupported-op decomposition would miss it. The schematic graph example is not a claim of a particular polynomial degree or a hardware-validated error bound.

### renderer/llvmir.py:L244 — Double EXP2 decomposition

Range reduction splits the input into a manageable part and a power-of-two scale: conceptually `2**(n+r)=2**n * 2**r`. This explains the shape of the replacement graph without assuming a particular internal polynomial or error bound.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:244). Matches EXP2 with double output and invokes `xexp2`. Example: `EXP2(x_f64)` → a range-reduced approximation and power-of-two reconstruction UOp graph from `xexp2(x)`.

Why: **same explicit source comment:** a double intrinsic is unavailable on this route. Sharp edge: preserves the decomposition helper's handling of extreme/special values; replacing the helper with `EXP2(CAST_f32(x)).cast(f64)` would introduce a different precision contract. It is a separate rule from LOG2 despite sharing the limitation.

### renderer/llvmir.py:L276 — Target-captured WMMA text rule

The metadata says what matrix operation is intended; the rewritten inputs say how its bits are passed. Keeping both is essential: a uint64 argument can still contain eight FP8 matrix elements, so selecting an integer-matrix intrinsic from its container type would be wrong.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:276). Matches WMMA; a constructor-created lambda captures `cdna` and `rdna4` from the target and calls `render_wmma_amd`. Examples: RDNA3 half→float → WMMA f32.16x16x16.f16; RDNA4 BF16→float → overloaded `.v8f32.v8bf16` suffix; CDNA K32 FP8→float → MFMA f32.16x16x32.fp8.fp8; CDNA K128 → scale-MFMA with identity E8M0 scale bytes 127.

Why: one mathematical WMMA abstraction spans incompatible intrinsic spellings and calling conventions. Sharp edge: argument types follow rewritten sources while the intrinsic's mathematical dtype name comes from WMMA `arg`. Target-specific graph validators must run first. The rule is appended after generic LLVM strings because there is no generic WMMA string rule there; unlike HIP, this ordering does not hide it. This is one dynamic rule template with captured target branches, not a finite enumeration of every possible target instance.

## renderer/tc.py: RDNA3 validator

AMDLLVMRenderer appends this PM only for exact arch strings `gfx1100` or `gfx1151`. HIP handles corresponding compiler ABI details through C wrappers instead. Guards on first-input shape/dtype assume compatible second-input fragments; these are not general shape validators.

### renderer/tc.py:L115 — RDNA3 packed signed-int8 fragments

Packing sixteen bytes into four words preserves the number of bits: `16×8 = 4×32`. The intrinsic must still be told those bytes represent signed int8 values; the unsigned word container alone cannot carry that meaning.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:115). Matches int32-output WMMA; only rewrites when the first input is int8 with 16 elements. Bitcasts A/B to uint32, preserving C. **Observed:** A/B int8×16 → uint32×4; C remains int32×8; LLVM emits WMMA iu8 with signedness flags true for A and B.

Why: sixteen byte values occupy four hardware/compiler words. Numeric CAST would not pack them. Sharp edge: unsigned storage words do not make the matrix elements unsigned; the original mathematical int8 dtype in WMMA metadata determines the intrinsic signedness flags. Rewritten inputs no longer match the guard, which provides progress.

### renderer/tc.py:L118 — RDNA3 half accumulator expansion and extraction

For two useful accumulator values, the same layout idea is `[c0,c1] → [c0,0,c1,0] → matrix instruction → [r0,unused,r1,unused] → [r0,r1]`. The actual rule does this for eight useful values. Input padding and output extraction are a matched pair.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:118). Matches half-output WMMA only when result element count is eight. Builds a half16 C fragment `[c0,0,c1,0,...,c7,0]`, creates the expanded WMMA with `arg=(*old_arg[:3],None)`, indexes its even result lanes, and STACKs them into half8. **Observed:** outer result STACK half8, inner WMMA result and C half16; the renderer adds `opsel=false`.

Why: adapts eight useful per-thread accumulator values to the intrinsic's 16-slot representation. Sharp edge: forgetting either zero interleaving or even-lane extraction changes semantics/layout. `arg` metadata is deliberately reset in the inner replacement; blindly copying the old fourth field is not what this rule does. The two comprehensions build graph nodes under one registered rule.

### renderer/tc.py:L124 — RDNA3 BF16 fragment storage type

BF16 1.0 is encoded as `0x3f80`. An intrinsic parameter declared uint16 expects those bits, not the integer 1 produced by a numeric cast. The matrix metadata supplies the BF16 interpretation.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:124). Matches any WMMA, then guards for BF16 first input with 16 elements. Bitcasts A/B to uint16 and leaves C unchanged. Schematic example: `WMMA(bf16[16],bf16[16],f32[8])` → `WMMA(u16[16],u16[16],f32[8])` with original BF16 mathematical metadata.

Why: LLVM intrinsic fragment parameters use BF16 bit encodings in integer vectors. Sharp edge: this broad final WMMA pattern is not restricted by output dtype; supported tensor-core configurations come from upstream layout selection. A numeric conversion to ushort would erase BF16 encoding rather than adapt it.

## renderer/tc.py: RDNA4 validator

Installed by AMDLLVMRenderer for exact `gfx1200` or `gfx1201`. RDNA4 `TensorCore` definitions choose different lane ownership and eight-element fragments before these PMs run.

### renderer/tc.py:L130 — RDNA4 BF16 inputs and BF16 accumulator/result

There are three boundaries: adapt the input fragments, adapt the accumulator, then restore the result’s BF16 type. Omitting the last boundary would let later arithmetic treat float encodings as unsigned numbers.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:130). Matches BF16-output WMMA, guarded by result count eight and BF16 first-input count eight. Bitcasts A, B, and C to uint16; the resulting WMMA follows the uint16 accumulator representation, and an outer bitcast restores BF16 result semantics. Example: BF16 A8/B8/C8 → integer-bit-pattern A8/B8/C8 WMMA → BF16 result8.

Why: both arguments and accumulator/result need representation adaptation for the BF16-output intrinsic. Sharp edge: the outer BITCAST is necessary; exposing the internal unsigned representation as the tensor value would be a type/semantic bug. There is no numeric float→integer rounding here.

### renderer/tc.py:L133 — RDNA4 BF16 inputs with float accumulator

Accumulation is the repeated addition of products into C. Keeping C as float32 means this rule changes how the small input values are passed without reducing the accumulator to BF16.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:133). Matches float-output WMMA with result count eight, BF16 first-input dtype and count eight. Bitcasts A/B to uint16, leaving float C/result unchanged. **Observed:** uint16×8 inputs plus float×8 C; emitted intrinsic ends `.bf16.v8f32.v8bf16`.

Why: BF16 operand representation changes without changing float accumulation. Sharp edge: this is not the RDNA3 BF16 rule with a renamed target: fragment lengths are different. Its guards prevent a 16-element RDNA3 input from being silently treated as RDNA4.

## renderer/tc.py: CDNA validator

Installed when `HIPRenderer.is_cdna(arch)` recognizes gfx942 or gfx950 after splitting any colon suffix. The first K128 rule precedes the more specific BF16/FP8 K16/K32 packing forms.

### renderer/tc.py:L139 — CDNA K128 word-packed inputs

In the observed case, each thread supplies 32 FP8 components, totaling 256 bits. Eight uint32 words carry exactly those 256 bits. The scale bytes are separate intrinsic parameters and do not replace any matrix elements.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:139). Matches float-output WMMA and guards only K==128 plus first-input dtype itemsize≤8. Bitcasts A/B to uint32. **Observed:** FP8×32 inputs become uint32×8, while C remains float×4; LLVM emits scale-MFMA with format selectors and scale bytes 127.

Why: scale-MFMA's input fragments use packed 32-bit words. Sharp edge: the actual predicate is broader than FP8 or gfx950; upstream tensor-core selection supplies legal K128 configurations. Once input is uint32, a repeated bitcast to uint32 can return the same node; do not describe the callback alone as validating the original source dtype. Float output and K are part of the exact contract.

### renderer/tc.py:L142 — CDNA BF16 four-element fragments

The four-element count describes this thread’s fragment, not a 4-element whole matrix. Different chip families distribute the same mathematical tile differently, which is why changing only the dtype is insufficient.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:142). Matches float-output WMMA with four result values and BF16 first input of length four; bitcasts A/B to uint16. Example: BF16 A4/B4 + float C4 → uint16 A4/B4 + float C4 while retaining BF16 WMMA metadata.

Why: fulfills the BF16 MFMA intrinsic's integer-storage fragment signature. Sharp edge: the count guard is four, unlike the RDNA3/RDNA4 counts sixteen/eight. Copying a validator across architectures without its lane/fragment layout would be incorrect even if the dtype spelling looked compatible.

### renderer/tc.py:L145 — CDNA eight-byte FP8 fragments

Each thread’s eight bytes become one 64-bit argument, while its four running sums remain a float vector. This distinction lets input storage stay compact without forcing integer or FP8 accumulation.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:145). Matches float-output WMMA with four output values, first input in FP8 OCP dtypes, and first-input count eight. Bitcasts A/B to uint64. **Observed:** FP8×8 A/B become scalar uint64; the K32 example renders MFMA with i64 A/B and float×4 C.

Why: one compiler argument carries each lane's eight encoded input bytes. Sharp edge: an arbitrary FP8 format does not match the OCP membership guard. K128 is handled by the earlier rule, and advertised ordinary FP8 dtype support is a separate renderer policy; presence of this rule is not proof that every tensor operation on FP8 is natively supported on every CDNA target.

## Reading tests and validation scope

The five **observed** cases were executed with `ALLOW_DEVICE_USAGE=0` using direct PM rewrites and `render_wmma_amd`, with no renderer/compiler/device construction. [The AMD guide](../amd-pattern-matchers.md) gives the exact reproducer pattern. All other examples in this file are schematic source readings; no full LLVM compilation, hardware execution, error-bound measurement, or performance result is claimed.

Related test anchors: [tensor-core optimizer tests](/home/boop/tenstorrent/tinygrad/test/opt/test_tensor_cores.py:1), [AMD LLVM compiler tests](/home/boop/tenstorrent/tinygrad/test/device/test_amd_llvm.py:1), [custom-kernel LLVM case](/home/boop/tenstorrent/tinygrad/test/backend/test_custom_kernel.py:226). Reading a related test is not equivalent to proving every rule above has independent test coverage.
