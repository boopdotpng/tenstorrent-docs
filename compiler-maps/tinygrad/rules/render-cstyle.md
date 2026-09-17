# C-style renderer: every pattern rule

## Read this as a translation boundary

Start with a Python expression such as `out[i] = a[i] + b[i]`. By this stage, tinygrad has chosen a kernel, its loops, and its memory accesses. A **UOp** is one node in that lowered program: `INDEX` finds a location, `LOAD` reads it, `ADD` computes, and `STORE` writes. A **pattern matcher (PM)** recognizes a node and its inputs. Here a rule either changes those nodes into forms the target supports (**legalization**) or prints target-language text (**rendering**). Printing `a+b` does not decide whether two previously separate kernels should be fused.

A renderer emits a language accepted by another compiler: Clang compiles the CPU C-style route; OpenCL, Metal, CUDA, and HIP provide GPU language routes. CUDA targets NVIDIA; HIP is the AMD route here. CDNA and RDNA name AMD architecture families; `gfx...` names distinguish target chips. A **builtin/intrinsic** is a compiler-recognized function that requests a particular operation. An **ABI**, or calling convention, specifies how arguments and results must be represented, even when that representation differs from their mathematical type.

Keep three distinctions in view. **Address spaces** say where something lives: GLOBAL is device memory, LOCAL is memory shared by a GPU workgroup, REG is register-backed storage, and ALU denotes computed values. A **vector lane** is one component of a per-thread value such as `float4`; it is not itself another GPU thread. And a numeric `CAST` preserves a value as closely as the new type allows, while `BITCAST` preserves its bits: float32 `1.0` numerically casts to integer `1`, but bitcasts to integer `0x3f800000`.

`half`/fp16 and bf16 are different 16-bit floating formats; fp8 uses eight bits. A backend may hold those encoded bits in an integer container without intending integer arithmetic. For example, bf16 `1.0` has bits `0x3f80`, which as an ordinary unsigned integer would mean 16256. Many apparently strange rules below prevent exactly that confusion. `src[0]` means the first input node, `dtype` its scalar type, and `max_numel` the maximum element count. A **weak constant** has a value but has not yet committed to a concrete machine type.

Read the common rules first, then the target-specific ones you need. For matrix hardware and image storage, keep the [AMD guide](../amd-pattern-matchers.md) and [IMAGE guide](../image-pattern-matchers.md) alongside this reference.

Pinned source: `107adc31701df0247dfa45e175984df906a68b53`. This appendix enumerates all **59 rule definitions/templates** in `renderer/cstyle.py`, including the five templates emitted by `create_non_native_float_pats`. A template instantiated for several backends remains one definition. Each entry links the outer tuple line. All before → after examples below are **symbolic and unexecuted**; names and parentheses may be simplified. No GPU device was opened to produce this guide.

`extra_matcher` rules transform UOps during backend legalization. `string_rewrite` rules return source strings during rendering; those do not fuse kernels or rewrite the execution schedule. Within a composed matcher, earlier successful rules win and a `None` result or the original UOp allows later candidates. “Why” below is an inference from the implementation unless explicitly attributed to a source comment; this does not claim commit history or benchmark evidence.

Composition and order: CStyle uses `base_rewrite`. Clang prepends its three conversion bridges to the non-native bf16 factory and manual bf16 casts. OpenCL uses non-native bf16 plus manual casts for legalization, and bf16 storage constants → its bitcast/image rules → base for strings. Metal has its bf16 math rule plus manual casts, and Metal bitcasts → base for strings. CUDA uses the fp8 factory with `casting=False` followed by cross-fp8 conversion; CUDA bitcasts precede base. HIP uses the bf16/fp8 factory plus the eight-lane WMMA rule, appending manual bf16 casts except on gfx950. CDNA replaces its initial string matcher with its five rules → base; all HIP variants prepend non-temporal loads, and non-gfx950 variants then prepend bf16 storage constants. HIPCC/NVCC aliases inherit these rules rather than defining new ones.

Architecture-sensitive behavior outside PM definitions is equally important: HIP `render_kernel` selects CDNA MFMA, gfx12 WMMA, RDNA integer wrappers, and half accumulator lane shuffles; `supported_dtypes` gates fp8; QCOM changes global bool storage to uchar and gates half support. These are ordinary Python branches, so they are not additional pattern rules. See the AMD and IMAGE guides for the full lowering context.

### renderer/cstyle.py:L13 — Declare a local or register buffer

For a reduction, each thread can put a partial sum into this shared array before a barrier lets its neighbors read it. A register buffer instead describes storage belonging to one thread; the same BUFFER concept needs different declarations in those two cases.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:13). **Match and output:** Any BUFFER delegates to render_buffer, which chooses shared-memory qualifiers for LOCAL and emits a scalar-element array sized by max_numel.

**Example (unexecuted):** `BUFFER(local,float,256) → shared-qualified float buf0[256];`. **Why:** Provide addressable storage for subsequent accesses. **Sharp edge:** This is a declaration, not an allocation API call; qualifiers and alignment depend on the renderer.

### renderer/cstyle.py:L16 — Unbounded loop

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:16). **Match and output:** A void-typed RANGE emits for (;;) {.

**Example (unexecuted):** `RANGE<void> → for (;;) {`. **Why:** Represent loops whose exit is a separate condition. **Sharp edge:** Must precede the general RANGE rule; pairing with the right END matters.

### renderer/cstyle.py:L17 — Counted loop

Read the bound as a length: `N=3` visits indices 0, 1, and 2. The induction variable is simply the loop counter; all scheduling decisions that chose this loop have already happened.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:17). **Match and output:** Any remaining RANGE emits a typed zero-initialized induction variable bounded by src[0] and incremented by one.

**Example (unexecuted):** `RANGE<int>(N) → for (int i = 0; i < N; i++) {`. **Why:** Translate normalized iteration into C syntax. **Sharp edge:** Bounds and induction types must already be legal; no overflow repair happens here.

### renderer/cstyle.py:L19 — Conditional loop termination

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:19). **Match and output:** END with three sources, second RANGE and third bool c, emits a negated-condition break before closing the loop.

**Example (unexecuted):** `END(body,range,c) → if (!(c)) { break; } }`. **Why:** Make continuation predicates explicit in emitted control flow. **Sharp edge:** The polarity is continuation: false breaks, true continues.

### renderer/cstyle.py:L20 — Conditional block

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:20). **Match and output:** IF emits an if statement using its first source.

**Example (unexecuted):** `IF(gate) → if (gate) {`. **Why:** Preserve explicit control dependence. **Sharp edge:** It does not construct or hoist a predicate.

### renderer/cstyle.py:L21 — Close a block

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:21). **Match and output:** ENDIF or any otherwise unmatched END emits a closing brace.

**Example (unexecuted):** `ENDIF → }`. **Why:** Finish the structured control-flow syntax. **Sharp edge:** Special conditional END must match earlier.

### renderer/cstyle.py:L24 — Nonfinite floating constant

Infinity and NaN (not-a-number) cannot be printed as ordinary decimal numbers. The rule supplies target-recognized expressions, then gives them the requested floating type.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:24). **Match and output:** A weak constant cast to a floating dtype returns None for finite values; otherwise it selects renderer NAN or signed INFINITY and render_cast.

**Example (unexecuted):** `CAST<float>(+inf) → ((float)(INFINITY))`. **Why:** Render values with no ordinary numeric literal. **Sharp edge:** Backend macros and narrow casts determine representation; it does not preserve an arbitrary NaN payload.

### renderer/cstyle.py:L26 — Float32 literal

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:26). **Match and output:** A constant cast to float renders the constant value followed by f.

**Example (unexecuted):** `CAST<float>(1.25) → 1.25f`. **Why:** Select float rather than double literal semantics. **Sharp edge:** The preceding nonfinite rule is essential.

### renderer/cstyle.py:L27 — Signed 64-bit literal

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:27). **Match and output:** A constant cast to int64 renders a lowercase l suffix.

**Example (unexecuted):** `CAST<int64>(7) → 7l`. **Why:** Supply the intended wide integer spelling to the compiler. **Sharp edge:** The selected compiler ABI must interpret emitted type and suffix consistently.

### renderer/cstyle.py:L28 — Unsigned 64-bit literal

A uint64 has exactly 64 bits. Keeping the low 64 bits of -1 gives all ones, which unsigned arithmetic interprets as `2**64-1`; the long decimal spelling is that same value.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:28). **Match and output:** A constant cast to uint64 is truncated using its target dtype and suffixed ul.

**Example (unexecuted):** `CAST<uint64>(-1) → 18446744073709551615ul`. **Why:** Encode modular unsigned values explicitly. **Sharp edge:** Truncation is intentional, not a range check.

### renderer/cstyle.py:L29 — Unsigned 32-bit literal

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:29). **Match and output:** A constant cast to uint32 is truncated and suffixed u.

**Example (unexecuted):** `CAST<uint32>(-1) → 4294967295u`. **Why:** Avoid an intermediate signed literal. **Sharp edge:** The emitted value reflects target-width wraparound.

### renderer/cstyle.py:L30 — Boolean literal

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:30). **Match and output:** A constant cast to bool emits 1 or 0 according to truthiness.

**Example (unexecuted):** `CAST<bool>(True) → 1`. **Why:** Use portable C boolean constants. **Sharp edge:** It emits a numeric token, not a bool keyword.

### renderer/cstyle.py:L32 — Narrow floating constant

There is no universally usable half or bf16 literal syntax across these C-like targets. Starting with a float32 literal gives the compiler a known value to convert, provided the target type really is numeric rather than an integer container for float bits.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:32). **Match and output:** Constants cast to any fp8, bf16, or half render as float literals wrapped by render_cast.

**Example (unexecuted):** `CAST<half>(1.5) → ((half)(1.5f))`. **Why:** The source comment specifies rendering to a larger type and casting. **Sharp edge:** Storage-emulated bf16 must intercept this rule; otherwise a numeric ushort cast would be wrong.

### renderer/cstyle.py:L33 — Narrow unsigned constant

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:33). **Match and output:** uint8/uint16 constants render a u-suffixed literal wrapped in the target cast.

**Example (unexecuted):** `CAST<uint16>(5) → ((unsigned short)(5u))`. **Why:** Use a larger literal type then narrow as the source comment states. **Sharp edge:** This path does not call the truncation helper used by uint32/64.

### renderer/cstyle.py:L34 — Narrow signed constant

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:34). **Match and output:** int8/int16 constants render a plain numeric literal wrapped in the target cast.

**Example (unexecuted):** `CAST<int16>(-5) → ((short)(-5))`. **Why:** Express narrow integer typing without a dedicated literal suffix. **Sharp edge:** Exact spelling comes from renderer type_map.

### renderer/cstyle.py:L36 — Fallback constant

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:36). **Match and output:** Any remaining constant CAST emits str(c.val).

**Example (unexecuted):** `CAST<int32>(7) → 7`. **Why:** Cover constants whose ordinary textual spelling is sufficient. **Sharp edge:** Ordering matters: this catches specialized constants if their earlier rules are removed.

### renderer/cstyle.py:L39 — Register vector conversion

For `int4_v=[1,2,3,4]`, the intended result is `[1.0,2.0,3.0,4.0]`. It is four numeric conversions, not a reinterpretation of the vector as a pointer or one large integer.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:39). **Match and output:** CAST returns __builtin_convertvector only when max_numel > 1 and destination addrspace is REG; otherwise declines.

**Example (unexecuted):** `CAST<reg float4>(int4_v) → __builtin_convertvector(int4_v, float4)`. **Why:** Convert vector elements using compiler vector semantics. **Sharp edge:** A multi-element value outside REG does not take this branch.

### renderer/cstyle.py:L41 — General value cast

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:41). **Match and output:** Any remaining CAST wraps render_cast around its source expression.

**Example (unexecuted):** `CAST<float>(i) → ((float)(i))`. **Why:** Provide the default numeric conversion. **Sharp edge:** Backend-specific emulated types must be lowered or intercepted first.

### renderer/cstyle.py:L42 — Pointer bitcast

Imagine the address stays at byte 1000. Casting its pointer type changes how subsequent accesses interpret bytes starting there; it does not fetch a value or turn a floating value into an integer.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:42). **Match and output:** BITCAST in GLOBAL or LOCAL emits a C pointer-type cast; other address spaces decline.

**Example (unexecuted):** `BITCAST<global float*>(p) → ((float*)(p))`. **Why:** Change pointer interpretation without loading data. **Sharp edge:** Address-space qualifiers are renderer-specific and must survive type rendering.

### renderer/cstyle.py:L44 — Value bitcast

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:44). **Match and output:** Remaining BITCAST uses __builtin_bit_cast with destination render_type and explicitly typed source.

**Example (unexecuted):** `BITCAST<uint>(f) → __builtin_bit_cast(unsigned int, (float)(f))`. **Why:** Preserve bits across value representations. **Sharp edge:** Source and destination sizes must already agree; backend overrides may replace the intrinsic.

### renderer/cstyle.py:L47 — Barrier emission

In a cooperative sum, threads write partial sums, reach this barrier, then read other threads’ partial sums. The emitter only prints the synchronization already requested by the graph; it does not discover that need.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:47). **Match and output:** BARRIER returns ctx.barrier verbatim.

**Example (unexecuted):** `BARRIER on OpenCL → barrier(CLK_LOCAL_MEM_FENCE);`. **Why:** Make synchronization syntax backend-defined. **Sharp edge:** Fence scope is whatever the backend string specifies; no new synchronization analysis occurs.

### renderer/cstyle.py:L48 — GPU work-item identifier

If a workgroup has 64 threads, its local IDs distinguish those threads with values 0 through 63. A group ID identifies which workgroup is running; multiplying by the group size and adding a local ID is separate arithmetic.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:48). **Match and output:** SPECIAL selects code_for_workitem from arg[0], dimension arg[-1], and appends a comment rendering src[0].

**Example (unexecuted):** `SPECIAL(l0,extent=64) on HIP → __ockl_get_local_id(0); /* 64 */`. **Why:** Bind launch axes to backend builtins. **Sharp edge:** Arg layout and legal dimensions are assumed; the comment is not a runtime bound check.

### renderer/cstyle.py:L51 — Scalar index rendering

For a float buffer, `(p+i)` advances by `i` float elements; C handles the byte scaling. Indexing a computed `float4` instead selects a component already in registers and requires no memory access.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:51). **Match and output:** INDEX with exactly buffer and index delegates to render_index.

**Example (unexecuted):** `INDEX(global_buf,i) → (global_buf+i)`. **Why:** Choose pointer arithmetic or vector lane syntax using address space. **Sharp edge:** ALU lane access differs from pointer indexing; a two-coordinate image index needs the OpenCL override.

### renderer/cstyle.py:L52 — Contiguous shrink rendering

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:52). **Match and output:** SHRINK(buffer,index,cast(constant)) also delegates to render_index, ignoring the extent in the textual address.

**Example (unexecuted):** `SHRINK(buf,i,CAST(4)) → (buf+i)`. **Why:** Represent a contiguous subview by its starting address. **Sharp edge:** The extent remains in UOp shape/type information used by later access rendering, not in the address text.

### renderer/cstyle.py:L53 — Vector construction

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:53). **Match and output:** STACK emits the renderer float4-style constructor with its actual rendered type and all source expressions.

**Example (unexecuted):** `STACK(a,b,c,d) on OpenCL → (float4)(a,b,c,d)`. **Why:** Assemble vector values with backend syntax. **Sharp edge:** Constructor availability and lane counts are responsibilities of renderer typedef generation.

### renderer/cstyle.py:L58 — Unconditional load

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:58). **Match and output:** A one-source LOAD emits parenthesized render_access(bidx).

**Example (unexecuted):** `LOAD(INDEX(p,i)) → (*(p+i))`. **Why:** Dereference a prepared address. **Sharp edge:** render_access may vector-cast the pointer according to access shape; alignment is not checked here.

### renderer/cstyle.py:L59 — Predicated load with fallback

With `i=N` and `g=(i<N)`, the false branch returns the fallback without evaluating `p[i]`. Choosing zero after performing an invalid load would not have the same behavior.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:59). **Match and output:** A three-source LOAD emits gate ? render_access(address) : fallback.

**Example (unexecuted):** `LOAD(p,0,g) → (g?*p:0)`. **Why:** Avoid dereferencing masked addresses while preserving explicit fallback. **Sharp edge:** Source order is address, fallback, gate; this is not the one-source non-temporal path.

### renderer/cstyle.py:L61 — Store

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:61). **Match and output:** Two-source STORE emits render_access(address) = value;.

**Example (unexecuted):** `STORE(p,v) → *p = v;`. **Why:** Write the prepared scalar/vector access. **Sharp edge:** Any predication must already be represented by surrounding control flow or lowered addressing.

### renderer/cstyle.py:L64 — Tensor-core wrapper call

The mathematical operation is a tile of `A @ B + C`. Each thread holds only a fragment of those tiles, and the wrapper arranges the hardware instruction’s expected arguments. It does not implement an arbitrary whole-matrix multiplication by itself.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:64). **Match and output:** WMMA calls __ plus _wmma_name with its three source expressions.

**Example (unexecuted):** `WMMA(A,B,C) → __WMMA_16_16_16_half_float(A,B,C)`. **Why:** Bridge a generic matrix primitive to renderer-generated wrappers/macros. **Sharp edge:** The name incorporates dimensions/input/output types; chip-specific calling conventions may need earlier overrides.

### renderer/cstyle.py:L65 — Ordinary arithmetic emission

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:65). **Match and output:** Any ALU operation calls code_for_op[x.op] with rendered operands and dtype; same-op ADD/MUL/XOR/OR/AND children have outer parentheses stripped.

**Example (unexecuted):** `ADD(ADD(a,b),c) → (a+b+c)`. **Why:** Centralize operator and intrinsic spelling. **Sharp edge:** This is text generation, not an associativity rewrite; unsupported operations must be lowered before reaching the map.

### renderer/cstyle.py:L69 — External function-pointer call

An ABI is the calling agreement: argument types, return type, and how the machine passes them. Printing a typed call is necessary because an address alone does not describe that agreement.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:69). **Match and output:** CALL whose first source is CUSTOM_FUNCTION with a function-pointer source accepts extra argument sources, builds a typed function-pointer cast including ctx.abi, casts each argument, and adds semicolon for void.

**Example (unexecuted):** `CALL(CUSTOM_FUNCTION(fp),x) → typed_fp_cast(fp)((arg_type)(x))`. **Why:** Emit an indirect call with explicit ABI and argument types. **Sharp edge:** The function pointer must actually obey that ABI/signature; renderer cannot validate it.

### renderer/cstyle.py:L74 — Custom formatted expression or statement

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:74). **Match and output:** CUSTOM/CUSTOMI inserts rendered sources into x.arg[0] using Python format.

**Example (unexecuted):** `CUSTOM("foo({0})",x) → foo(x)`. **Why:** Provide an escape hatch for already-selected target syntax. **Sharp edge:** Correct syntax, side effects, and placeholder indices are the producer’s responsibility.

### renderer/cstyle.py:L80 — Commit weak constants before emulation

Python-like literal `1` has no fixed width at this point. Committing it to bf16 gives the following emulation rules a concrete format to decode; otherwise one input would be typed storage and the other still an untyped value.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:80). **Match and output:** Any ALU calls commit_weak_consts using the first source whose dtype belongs to factory dts; the helper returns the unchanged node when no change is needed, allowing later rules to run.

**Example (unexecuted):** `ADD(bf16_x,weak_const(1)) → ADD(bf16_x,CAST<bf16>(1))`. **Why:** Source comment: a weak CONST states no width; commit it at the emulated dtype stated by a sibling. **Sharp edge:** Factory dts and source order matter; the rule does not blindly force every constant to float32.

### renderer/cstyle.py:L81 — Emulated floating arithmetic

Follow the three steps: decode x and y to float32 numbers, add those numbers, then round/encode the sum back to bf16. Adding their unsigned storage words directly would add encodings rather than values.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:81). **Match and output:** ALU except WHERE with output dtype in factory dts casts each input to float, reconstructs the same op/arg, and casts result back.

**Example (unexecuted):** `ADD<bf16>(x,y) → CAST<bf16>(ADD(CAST<float>(x),CAST<float>(y)))`. **Why:** Perform arithmetic on storage-emulated/non-native float formats. **Sharp edge:** WHERE is deliberately excluded; extra rounding at the narrow result remains.

### renderer/cstyle.py:L83 — Emulated floating comparison

For example, bf16 encodes -1.0 as `0xbf80` and +1.0 as `0x3f80`. Comparing those words as unsigned integers gives the opposite order from comparing the decoded numbers.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:83). **Match and output:** Bool ALU with exactly two sources both in factory dts rebuilds the op with float-cast sources.

**Example (unexecuted):** `CMPLT(bf16_x,bf16_y) → CMPLT(float(x),float(y))`. **Why:** Compare numeric values rather than their storage bits. **Sharp edge:** Only the exact binary source pattern is covered; mixed-dtype inputs require earlier normalization.

### renderer/cstyle.py:L88 — Cast into non-native float through float32

Instead of implementing a conversion from every integer and float type to bf16, the backend funnels them through one float32-to-bf16 implementation. That reduces implementation cases, but the extra rounding point explains the precision caveat.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:88). **Match and output:** When casting=True, CAST to factory dts from a source other than float and other than raw CONST inserts float32 first.

**Example (unexecuted):** `CAST<bf16>(int_x) → CAST<bf16>(CAST<float>(int_x))`. **Why:** Reduce the conversion surface to float32-to-emulated-format. **Sharp edge:** Float64 conversion gains an intermediate rounding; constants bypass this rule.

### renderer/cstyle.py:L90 — Cast out of non-native float through float32

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:90). **Match and output:** When casting=True, CAST from factory dts to any destination other than float inserts float32.

**Example (unexecuted):** `CAST<int>(bf16_x) → CAST<int>(CAST<float>(bf16_x))`. **Why:** Reduce decoding to the supported emulated-format-to-float32 path. **Sharp edge:** The float destination guard prevents an infinite insertion chain.

### renderer/cstyle.py:L101 — Manual bf16 widening

A bf16 word occupies the high 16 bits of the corresponding float32 encoding. Widening `0x3f80` to uint32 first gives `0x00003f80`; shifting by 16 gives `0x3f800000`; only the final bitcast interprets those bits as float32 1.0.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:101). **Match and output:** CAST bf16 to float bitcasts to ushort, widens to uint, shifts left 16, and bitcasts to float.

**Example (unexecuted):** `bf16 bits 0x3f80 → uint 0x3f800000 → float 1.0`. **Why:** Source comment: shared LLVM/Clang/AMD manual casts avoid compiler intrinsics. **Sharp edge:** A numeric ushort-to-float conversion would be wrong; zeros and NaN payload bits are transported through the bit representation.

### renderer/cstyle.py:L103 — Manual bf16 narrowing

For an ordinary finite value, keeping only the top 16 bits would always discard the low part. Adding `0x7fff` plus the retained low bit implements round-to-nearest with even ties on the rounding branch: halfway patterns `0x3f808000` and `0x3f818000` become bf16 `0x3f80` and `0x3f82`. The separate exceptional branch must still be retained; this finite-value walkthrough is not a replacement for its exact predicate.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:103). **Match and output:** CAST float to bf16 calls cast_float_to_bf16: bitcast to uint, apply the source’s (-bits & 0x7f800000)!=0 branch, add low-bit tie correction plus 0x7fff on that branch, otherwise preserve/force an upper mantissa bit when low bits are nonzero, shift 16, narrow, and bitcast.

**Example (unexecuted):** `float 1.0 bits 0x3f800000 → bf16 bits 0x3f80`. **Why:** Implement bf16 rounding and exceptional-value bit handling without compiler intrinsics (shared-matcher comment). **Sharp edge:** Do not replace the exact branch with a guessed exponent-only test; NaN/overflow/tie behavior belongs to this helper’s bit arithmetic.

### renderer/cstyle.py:L106 — bf16 storage literal

The printed 16256 is not the value the tensor means. It is decimal for `0x3f80`, the bf16 encoding of 1.0, placed into the ushort container used by this route.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:106). **Match and output:** A constant cast to bf16 emits to_storage_scalar(value,bf16) with u suffix.

**Example (unexecuted):** `CAST<bf16>(1.0) → 16256u`. **Why:** Source comment: bf16 stored as ushort needs its bit pattern as the literal. **Sharp edge:** Must precede generic narrow-float constant rendering and only be used with the matching storage representation.

### renderer/cstyle.py:L282 — Clang double to half bridge

A libcall is a call to a helper function supplied by a compiler runtime library. If that helper is unavailable, otherwise reasonable generated code can fail to link. The bridge changes which conversion the compiler must implement.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:282). **Match and output:** CAST float64 to float16 inserts float32.

**Example (unexecuted):** `double_x → float(double_x) → half`. **Why:** Source comment: LLVM can legalize direct double-to-half into an unavailable compiler-rt libcall on CPUs without native support. **Sharp edge:** Intermediate float32 rounding differs from ideal direct conversion in some cases.

### renderer/cstyle.py:L283 — Clang double to bf16 bridge

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:283). **Match and output:** CAST float64 to bf16 inserts float32.

**Example (unexecuted):** `double_x → float(double_x) → bf16`. **Why:** The adjacent source comment identifies compiler-rt legalization of double-to-bf16 as the issue. **Sharp edge:** The subsequent non-native/manual bf16 matchers must finish the conversion.

### renderer/cstyle.py:L284 — Clang bf16 to half bridge

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:284). **Match and output:** CAST bf16 to half inserts float32.

**Example (unexecuted):** `bf16_x → float(bf16_x) → half`. **Why:** Source comment: relevant CPUs lack a native bf16-to-fp16 conversion. **Sharp edge:** Support for the resulting float-to-half path is still required.

### renderer/cstyle.py:L326 — OpenCL value bitcast

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:326). **Match and output:** BITCAST outside GLOBAL/LOCAL uses as_destination_type with a source-type cast; pointer bitcasts decline.

**Example (unexecuted):** `BITCAST<uint>(f) → as_uint((float)(f))`. **Why:** Select OpenCL’s bit reinterpretation builtin. **Sharp edge:** Uses render_dtype rather than render_type; legal vector lowering must already be arranged.

### renderer/cstyle.py:L329 — Image-coordinate marker

`IMAGE<img,y,x>` is a temporary spelling carrying an image handle and two coordinates between renderer rules. Think of it as a note to the subsequent read/write rule, rather than code that an OpenCL compiler can execute.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:329). **Match and output:** INDEX with two coordinates after a buffer emits IMAGE<buffer,y,x>. There is no explicit image-dtype guard in this pattern.

**Example (unexecuted):** `INDEX(img,y,x) → IMAGE<img,y,x>`. **Why:** Keep a recognizable coordinate expression available while LOAD/STORE rules emit image calls (inference). **Sharp edge:** IMAGE<...> is not valid final OpenCL syntax; a direct consumer outside the specialized paths is a sharp edge.

### renderer/cstyle.py:L330 — Masked image read

One image read returns a four-component pixel. If the gate is false, the fallback must supply the matching four-component result; a scalar zero in schematic notation abbreviates the already normalized fallback.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:330). **Match and output:** Float LOAD with two-coordinate INDEX plus fallback and gate emits a conditional read_imagef using sampler smp and (x,y) int2 order.

**Example (unexecuted):** `LOAD(INDEX(img,y,x),zero,g) → (g?read_imagef(img,smp,(int2)(x,y)):zero)`. **Why:** Preserve masking for image-backed accesses. **Sharp edge:** read_imagef returns four float channels; shape/lane and fallback consistency were established earlier, not by this pattern.

### renderer/cstyle.py:L332 — Image read

Array position `[2,7]` means row 2, column 7. OpenCL takes horizontal coordinate first, so the emitted pair is `(7,2)`. Nearest sampling selects a pixel rather than interpolating nearby pixels; unnormalized coordinates use pixel positions rather than a 0-to-1 coordinate scale.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:332). **Match and output:** One-source float LOAD of a two-coordinate INDEX emits read_imagef(img,smp,(int2)(x,y)).

**Example (unexecuted):** `LOAD(INDEX(img,2,7)) → read_imagef(img,smp,(int2)(7,2))`. **Why:** Lower image coordinates to the OpenCL image ABI. **Sharp edge:** Logical source order y,x is reversed for OpenCL int2; kernel emission supplies an unnormalized clamp/nearest sampler.

### renderer/cstyle.py:L334 — Image write

The four values are the channels of one pixel. Writing one arbitrary tensor scalar would require earlier packing or another access strategy; this rule assumes that work is complete.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:334). **Match and output:** STORE to a two-coordinate INDEX with float-typed value emits write_imagef using (x,y) int2.

**Example (unexecuted):** `STORE(INDEX(img,2,7),rgba) → write_imagef(img,(int2)(7,2),rgba);`. **Why:** Use the image write intrinsic rather than pointer dereference. **Sharp edge:** No gate exists in this rule and a full compatible channel value is required; image parameter mutability comes from separate store analysis.

### renderer/cstyle.py:L371 — Metal bf16 transcendental bridge

A transcendental is a function such as sine, logarithm, or exponential; square root is grouped with them by this rule. The target restriction concerns these operations on bf16, not whether bf16 can be stored at all.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:371). **Match and output:** bf16 SQRT/EXP2/LOG2/SIN casts all operands to float, performs the same operation, then casts back to bf16.

**Example (unexecuted):** `SQRT<bf16>(x) → bf16(SQRT(float(x)))`. **Why:** Source comment: these operations do not support bf16; another comment says copied from PTX. **Sharp edge:** Only these four operations are covered; manual bf16 casts are appended afterward.

### renderer/cstyle.py:L376 — Metal value bitcast

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:376). **Match and output:** BITCAST outside GLOBAL/LOCAL uses as_type<destination> with source render_dtype.

**Example (unexecuted):** `BITCAST<uint>(f) → as_type<uint>((float)(f))`. **Why:** Select Metal bit reinterpretation syntax. **Sharp edge:** Pointer bitcasts deliberately fall through to the base matcher.

### renderer/cstyle.py:L428 — CUDA cross-fp8 conversion

e4m3 and e5m2 allocate their exponent/fraction bits differently. Decode the first byte format to a float32 number, then encode that number in the other format; keeping the same byte bits would generally change its value.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:428). **Match and output:** CAST between any two fp8 dtypes inserts float only if source and destination differ.

**Example (unexecuted):** `CAST<fp8e5m2>(fp8e4m3_x) → fp8e5m2(float(fp8e4m3_x))`. **Why:** Supply a shared intermediate between distinct CUDA fp8 representations (inference). **Sharp edge:** CUDA’s factory uses casting=False; this selective bridge is not the full generic cast emulation.

### renderer/cstyle.py:L431 — CUDA value bitcast

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:431). **Match and output:** BITCAST outside GLOBAL/LOCAL calls tg_bitcast<destination> with a source-type cast.

**Example (unexecuted):** `BITCAST<uint>(f) → tg_bitcast<uint>((float)(f))`. **Why:** Use the union-based helper emitted by CUDA render_kernel. **Sharp edge:** This relies on CUDA compiler interpretation of that helper; pointer bitcasts fall through.

### renderer/cstyle.py:L498 — CDNA scaled MFMA call

MFMA is AMD’s matrix multiply-accumulate family. The extra integers are control/format operands required by the builtin’s calling convention; they are not six extra tensors in the matrix expression. The K=128 case has a different signature from the ordinary case below.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:498). **Match and output:** Installed only for is_cdna targets; WMMA additionally requires `K=x.arg[0][2] == 128` and appends two identical fp8_index(source0.dtype) selectors plus four zero arguments.

**Example (unexecuted):** `WMMA<16,16,128,fp8e5m2>(A,B,C) → __WMMA_...(A,B,C,1,1,0,0,0,0)`. **Why:** Match the scaled MFMA builtin signature chosen by render_kernel for K=128 (inference from code). **Sharp edge:** Both format selectors come from source0: mixed A/B formats are not independently encoded. fp8_index accepts only the two OCP formats.

### renderer/cstyle.py:L500 — CDNA ordinary MFMA call

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:500). **Match and output:** Installed only for is_cdna targets; remaining WMMA calls append three zero arguments.

**Example (unexecuted):** `WMMA<16,16,32>(A,B,C) → __WMMA_...(A,B,C,0,0,0)`. **Why:** Adapt the generic three-operand UOp to the MFMA control-argument ABI. **Sharp edge:** Must follow the K=128 specialization; is_cdna recognizes gfx942 and gfx950 base architecture names only.

### renderer/cstyle.py:L501 — CDNA fp8 constant conversion

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:501). **Match and output:** Installed for CDNA; a constant cast to any fp8 emits f32_to_fp8(value,format_index), selecting NAN/INFINITY spellings explicitly.

**Example (unexecuted):** `CAST<fp8e4m3>(2.0) → f32_to_fp8(2.0f,0)`. **Why:** Use the same target conversion helper for constants and runtime float inputs. **Sharp edge:** Helper clamps finite values to ±448 or ±57344; fp8_index only accepts OCP e4m3/e5m2 despite the broader pattern.

### renderer/cstyle.py:L504 — CDNA float32 to fp8

A packed conversion produces multiple encoded bytes in one larger integer result. This helper asks it to convert duplicate values, then keeps the byte corresponding to the value it needs.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:504). **Match and output:** Installed for CDNA; CAST from float to fp8 calls f32_to_fp8 with destination format index.

**Example (unexecuted):** `CAST<fp8e5m2>(f) → f32_to_fp8(f,1)`. **Why:** Emit AMD packed-conversion builtins through the clamping helper. **Sharp edge:** The helper converts duplicate inputs then returns the low byte; enabled dtype policy separately restricts usable architectures.

### renderer/cstyle.py:L506 — CDNA fp8 to float32

Zero selects the low byte from the integer argument. The builtin decodes that byte as an FP8 number; the unsigned integer cast only positions the encoded bits for the call.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:506). **Match and output:** Installed for CDNA; CAST fp8 to float selects __builtin_amdgcn_cvt_f32_fp8 or ..._bf8 and supplies the unsigned source plus selector zero.

**Example (unexecuted):** `CAST<float>(fp8e5m2_x) → __builtin_amdgcn_cvt_f32_bf8((unsigned int)x,0)`. **Why:** Decode the stored fp8 byte with the AMD builtin. **Sharp edge:** The zero selector and storage cast assume the intended byte position; FNUZ dtypes are outside fp8_index.

### renderer/cstyle.py:L510 — HIP non-temporal global load

Non-temporal means the producer marks this access as having a special cache policy, often useful for streamed data. The flag changes the load builtin; this local rule provides no evidence that it improves a particular workload.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:510). **Match and output:** Installed for every HIPRenderer; one-source LOAD with arg exactly nontemporal emits __builtin_nontemporal_load(render_ptr(address)).

**Example (unexecuted):** `LOAD[nontemporal](INDEX(p,i)) → __builtin_nontemporal_load(p+i)`. **Why:** Source comment: a flagged load uses the cache-bypassing builtin and is only used on global loads. **Sharp edge:** The pattern itself has no GLOBAL guard; producers enforce that invariant. Three-source masked loads do not match.

### renderer/cstyle.py:L527 — Pack eight fp8 operands for HIP WMMA

Eight fp8 components contain `8×8=64` bits. The uint64 bitcast packages those same bits into one argument; numerically converting eight small floats to integers would be a completely different operation.

[Source](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:527). **Match and output:** WMMA with float output rewrites both A/B sources to uint64 bitcasts when source0 has eight elements and dtype in fp8_ocp. Accumulator is unchanged.

**Example (unexecuted):** `WMMA(float_out,A:fp8[8],B:fp8[8],C) → WMMA(bitcast<uint64>(A),bitcast<uint64>(B),C)`. **Why:** Pack eight one-byte lanes into the operand representation expected by the selected builtin (inference). **Sharp edge:** Only source0 is checked; compatibility of B is an upstream invariant. This is instruction ABI legalization, not kernel fusion.

