# Every rule in NIR rendering and late image/coalescing matchers

## What NIR and IMAGE mean here

NIR is the intermediate representation used by Mesa's shader compilers. A shader can be a compute kernel with no graphics involved. Unlike a C or PTX renderer that prints text, this renderer calls a builder to construct NIR instruction objects. Mesa then lowers those objects toward the target device. NAK, LVP, and IR3 are backend routes named in this file; IR3 is the Qualcomm/Adreno route relevant to its image rules. Knowing their names is less important than knowing that each supplies different parameter and memory-access conventions.

Tinygrad's UOps describe computations before that translation. `extra_matcher` **legalizes** them, replacing operations whose types or representations are unsuitable for NIR. `def_rewrite` then builds NIR definitions. An SSA definition is a named value computed once; a **phi** chooses the value supplied by whichever control-flow branch actually ran. This matters for masked loads: the false branch supplies a fallback without reading the invalid address.

An **image** in these rules is a GPU storage resource addressed by `(x,y)` coordinates, not necessarily a picture. Four tensor values occupy a pixel's four channels, often called RGBA. Ordinary buffer indexing starts with an address and an element offset; image indexing starts with an image handle and coordinates. Tinygrad writes coordinates in `(y,x)` order, like a row/column array, while target image calls use `(x,y)`. A **gate** is a boolean condition saying whether an access is logically valid; **OOB** means outside the physical resource's bounds. Those are different tests, which is why some image gates can disappear and others must remain.

GLOBAL means device memory, LOCAL means workgroup-shared scratch space, REG means register-backed storage, and ALU means computed values. A vector lane is a component of one thread's value, not another thread. `CAST` converts numbers; `BITCAST` preserves their encoded bits. Storage type and arithmetic type can differ: an image may store half-precision channels while its read/write interface exchanges float32 values. An **ABI** is the agreement about how kernel arguments or image slots are represented and passed.

Snapshot: clean tinygrad master `107adc31701df0247dfa45e175984df906a68b53`, 2026-09-17. Every outer rule tuple in `renderer/nir.py` and `codegen/late/coalesce.py` has an entry below. Examples use schematic UOp notation; **NIR emission examples are source-derived and unexecuted**. NIR callbacks emit Mesa objects and side effects rather than returning replacement UOps. “Why” is inferred from the code unless explicitly labeled a source comment. The [IMAGE chapter](../image-pattern-matchers.md) explains packing, device constraints, mask proofs, and kernel boundaries; [six CPU probe groups](../image-matcher-probes.json) validate selected coalescing/image rules.

`NIRRenderer.extra_matcher` legalizes UOps during late codegen; `def_rewrite` emits instructions inside the renderer's imperative loop. `IR3Renderer.def_rewrite` prepends its image-specific rules to the generic definition matcher. This priority matters: generic memory rules accept extra INDEX children and would otherwise treat an image as a one-dimensional pointer.

## Late index and image rules

### codegen/late/coalesce.py:L60 — indexing_simplify: ordinary gated index

Under `0<=i<4`, integer division `i//4` is always zero. Substituting that fact removes the multiply and addition from the address, but only on the domain where the gate is true. `Invalid` is the graph’s marker for an unusable coordinate, not a valid integer address.

[Source](../../../../tinygrad/tinygrad/codegen/late/coalesce.py#L60). Match a single-coordinate `INDEX(buf, WHERE(cond,x,Invalid))` via `invalid_gate`. `simplify_valid_load` evaluates x under cond and returns `INDEX(buf, simplified_x.valid(cond))` only if that changes x beyond ordinary simplification. Example (schematic): under `0<=i<4`, `(i//4)*16+j` becomes `j`, while that validity gate remains. Why: remove arithmetic made redundant by the known validity domain. Sharp edge: simplifying the address under the predicate does not authorize discarding the predicate; the callback declines if nothing new is learned.

### codegen/late/coalesce.py:L61 — indexing_simplify: paired image coordinates

Compare the false domain for the two heights: if height is 10, failing `y<10` puts y beyond the image and the image read supplies zero. If height is 20, y=12 fails the logical gate but still names a real pixel, whose data need not be zero. Only the first case can replace that clause with physical bounds behavior.

[Source](../../../../tinygrad/tinygrad/codegen/late/coalesce.py#L61). Match `INDEX(buf, valid?y:Invalid, valid?x:Invalid)` with identical valid nodes. Require image-shaped buffer. Normalize mismatched coordinate dtypes, apply validity assumptions to `(x,y)`, and drop AND clauses whose failure provably puts a coordinate outside the image. Example **executed by the probe**: height 10 with y<10 loses the gate; height 20 with y<10 retains it. Why: image OOB supplies the required zero and can replace a conditional. Sharp edge: the proof is about the false domain, not an always-in-bounds claim; ordinary pointer OOB lacks this contract. If neither coordinates nor gate improve, return `None`.

### codegen/late/coalesce.py:L98 — pm_simplify_add_image: promote a four-element slice

A four-element slice is one candidate pixel. For 1024 values, 256 four-channel pixels preserve all 1024 elements; height 1 and width 256 is one possible layout. Choosing the layout can simplify coordinate arithmetic and gates, but it does not fuse kernels or change how many logical values exist.

[Source](../../../../tinygrad/tinygrad/codegen/late/coalesce.py#L98). Match `SHRINK(PARAM buf, x, CONST(4))`. Require IMAGE and target QCOM/CL/PYTHON/NULL; obtain eligible dimensions or the previously chosen dimensions for the parameter slot. Choose the layout maximizing removable mask clauses, then minimizing simplified y-coordinate graph size. Replace the parameter argument with `image=(h,w)` and use `INDEX(buf,y,x)` with retained validity. Example **executed**: four coalesced reads of 1024 float elements become one `(1,256,4)` image view. Why: convert already aligned/vectorized memory accesses into texture/image accesses while preserving flat allocation size. Sharp edge: integer or unaligned/no-metadata candidates decline; per-slot layout state is local to the pass, not global scheduling state.

### codegen/late/coalesce.py:L100 — pm_simplify_add_image: half data to float image store

The write interface takes four float32 numbers and encodes them into the image’s storage format. Converting the input values to float32 satisfies that interface; it does not change a half-storage image into a float32-storage allocation.

[Source](../../../../tinygrad/tinygrad/codegen/late/coalesce.py#L100). Match a float-typed INDEX storing half-typed data. Rewrite `STORE(float_index, half_value)` to `STORE(float_index, CAST(float,half_value))`. Example: a four-half producer feeding a half-storage image becomes four float values at `write_imagef`; the descriptor still says half storage. Why, source comment: image load/store is always float. Sharp edge: the rule tests INDEX access dtype and stored dtype, not an image-shape predicate or IMAGE flag; do not describe it as guarded exclusively to image nodes.

### codegen/late/coalesce.py:L101 — pm_simplify_add_image: remove float/half/float round trip

The intermediate half cast can round away information before the value widens again. Removing it therefore changes some results even though the beginning and ending dtypes are both float32. Treat this as a documented precision-sensitive rule, not the algebraic identity `float(half(x))=x`.

[Source](../../../../tinygrad/tinygrad/codegen/late/coalesce.py#L101). Match float x cast to half then back to float; return x. Example **structurally executed under IMAGE=0**: `CAST(float, CAST(half, float_param)) → float_param`. Why inferred: remove a conversion chain around image-related float compute/half storage plumbing. Sharp edge: this is numerically nonidentity in general (1.0001→half→float gives 1.0); no IMAGE guard exists. Commit `168a96439` restored it by reverting `034d68380`. See the main IMAGE chapter's precision discussion.

`memory_coalescing` and `image_valid_dims` in this module are algorithms, not hidden PM constructors. Their grouping/alignment/volatile rules and shape search are covered in the [main chapter](../image-pattern-matchers.md#why-the-four-lane-restriction-matters).

## NIR legalization: every extra_matcher rule

### renderer/nir.py:L123 — NIRRenderer.extra_matcher: boolean less-than

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L123). Match `x<y` when x is bool; rewrite `(x XOR True) AND y`. Example: `False < True → (!False)&True → True`. Why: express bool ordering with native boolean logic; source notes it comes from PTX. Sharp edge: the explicit dtype constraint is on x, with normal type invariants expected for y. This is the two-value truth table, not a rewrite of integer comparison.

### renderer/nir.py:L125 — NIRRenderer.extra_matcher: boolean load storage

A one-bit compute value cannot directly describe the byte stride of a boolean array. The rule changes the backing representation as well as the loaded type, keeping `B[i]` one byte apart and converting the byte back to a boolean for computation.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L125). Match any bool LOAD; restate its backing storage through `with_storage(...,uint8)`, cast an alternative operand to uint8 if present, preserve later gate/dependency operands, then cast the loaded result back to bool. Example: `LOAD(bool_buf[i], False, gate) → bool(LOAD(uint8_view[i], uint8(False), gate))`. Why, explicit source comment: NIR bool is one bit, memory bool is one byte. Sharp edge: changing only result dtype would leave address scaling/storage wrong; `with_storage` recursively reaches the buffer owner.

### renderer/nir.py:L128 — NIRRenderer.extra_matcher: boolean store storage

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L128). Match STORE with bool data, allowing extra sources. Restate indexed storage as uint8, cast data to uint8, preserve remaining sources. Example: `STORE(bool_buf[i], flag, gate) → STORE(uint8_view[i], uint8(flag), gate)`. Why: pair byte-addressed memory with NIR bool computation. Sharp edge: the explicit gate survives; this is storage legalization, not a bool-buffer layout compaction pass.

### renderer/nir.py:L131 — NIRRenderer.extra_matcher: shift-count width

The shifted value and the shift count answer different questions: one is the payload, the other says how far to move its bits. A 64-bit payload can therefore legitimately have a 32-bit count.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L131). Match SHL or SHR; if shift operand bitsize is not 32, cast it to uint32 and rebuild. Example: `SHL(int64_value, int64(5)) → SHL(int64_value,uint32(5))`. Why, source comment: NIR requires a 32-bit shift amount. Sharp edge: a 32-bit signed count already passes this callback; it checks width, not signedness or valid shift range.

### renderer/nir.py:L134 — NIRRenderer.extra_matcher: float to narrow unsigned

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L134). Match float-family source CAST to uchar or ushort. Insert int32 intermediate: `CAST(uint8,float_value) → CAST(uint8,CAST(int32,float_value))`, likewise uint16. Why, source comment: float-to-unsigned conversion is undefined when the result type is not wide enough; use int32 on the way. Sharp edge: this does not promise defined behavior for all out-of-range/NaN inputs to int32 either; its scope is the narrow unsigned lowering contract.

### renderer/nir.py:L137 — NIRRenderer.extra_matcher: memory offset width

For a float buffer, offset i eventually becomes byte displacement `4*i`; wide address arithmetic helps represent that displacement. Image coordinates instead name pixels and follow their own 32-bit interface, handled by the next rule.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L137). Match INDEX/SHRINK with buffer and offset, allowing trailing operands. Only GLOBAL/LOCAL buffers that are not image shaped qualify. Conditionally cast offset to long, preserving extra fields. Example: `SHRINK(global_float, int32(i), 4) → SHRINK(global_float,int64(i),4)`. Why: pointer arithmetic uses wide offsets in NIR. Sharp edge: REG/ALU element selections and image coordinates deliberately avoid this path; the shape exclusion compensates for the broadly matching pattern.

### renderer/nir.py:L141 — NIRRenderer.extra_matcher: image coordinate width

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L141). Match two-coordinate `INDEX(buf,y,x)` and cast both coordinates to int32. Example: `INDEX(img,int64(y),int64(x)) → INDEX(img,int32(y),int32(x))`. Why, source comment: NIR images need int coordinates while INDEX retains its access dtype. Sharp edge: the pattern itself has no image-shape test; late two-coordinate INDEX is expected to mean image access by phase invariant.

## NIR instruction definitions: every generic def_rewrite rule

### renderer/nir.py:L146 — NIRRenderer.def_rewrite: typed constant

The bare value 1.5 does not say whether the backend needs a 16-, 32-, or 64-bit encoding. Its CAST supplies that choice before `nimm` creates the concrete constant bits.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L146). Match constant c under CAST x; emit `nimm(builder,c.val,x.dtype)`. Example: `CAST(float,CONST(1.5)) → NIR load_const f32 1.5`. Why: bare constants are weak; the cast specifies concrete storage bits. Sharp edge: `nimm_set` applies dtype truncation/packing. This rule must precede general CAST emission because no emitted definition exists for a bare constant.

### renderer/nir.py:L147 — NIRRenderer.def_rewrite: parameter ABI

A UBO is a uniform buffer supplying values shared by shader invocations. An image-slot ID identifies a bound resource rather than the address of its first pixel. Those are different ways to pass arguments, which is why subclasses supply the actual mapping.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L147). Match PARAM; call backend-specific `param` using dtype byte width for ALU scalars, otherwise 8 bytes. Example: float scalar uses a 4-byte argument; global pointer uses 8-byte argument. Why: separate scalar values from addresses in the kernel ABI. Sharp edge: actual mapping depends on subclass—NAK uses `ldc_nv`, LVP a UBO load, IR3 image parameters become image-slot IDs. This rule alone does not define a universal ABI.

### renderer/nir.py:L148 — NIRRenderer.def_rewrite: workgroup/local ID

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L148). Match SPECIAL; use first argument character `g`/`l` to choose workgroup/local invocation ID intrinsic and final character to select a component. Example: `SPECIAL('g1') → load_workgroup_id.y`. Why: bind iteration axes to hardware launch coordinates. Sharp edge: this is group ID, not automatically a flattened global thread ID; only the recognized prefixes/component form work.

### renderer/nir.py:L149 — NIRRenderer.def_rewrite: ordinary store

With base address 1000 and float index 3, the address helper computes 1012 before the store is emitted. A lane write mask says which components of a vector store are written; it is distinct from a boolean gate deciding whether the store executes at all.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L149). Match a two-source STORE to INDEX/SHRINK(buffer,offset,...). Compute an address with `nidx` and emit `nstore` in global/shared/deref space from buffer address space. Example: `STORE(global_float[i],v) → store_global(base+4*i,v)`. Why: convert element indexing into byte addresses and memory intrinsics. Sharp edge: store gates must already be represented in surrounding control flow; this tuple has no extra STORE source allowance. Vector stores set a lane write mask and alignment from the value.

### renderer/nir.py:L151 — NIRRenderer.def_rewrite: gated ordinary load

If i=N, the false block yields zero. The phi uses that block’s result when control rejoins; it does not load A[N] and later discard it. This control-flow structure is the safety mechanism.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L151). Match LOAD(index,alternate,gate) over INDEX/SHRINK. Emit conditional control flow; true side forms the address and loads, false side supplies alternate, joined with phi. Example: `LOAD(A[i],0,i<N) → if i<N: load(A+4*i) else: 0; phi`. Why: avoid executing invalid memory accesses, not merely selecting away their result. Sharp edge: `nidx` also receives the gate and may guard address formation; replacing this with unconditional load+select would change safety.

### renderer/nir.py:L156 — NIRRenderer.def_rewrite: ungated ordinary load

Here the slice starts at element `4*i` and contains four floats. Because each float occupies four bytes, its starting byte displacement is `16*i`. The vector load fetches those four adjacent elements together.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L156). Match one-source LOAD over INDEX/SHRINK; emit nidx then nload. Example: `LOAD(SHRINK(A,4*i,4)) → vector load_global(A+16*i)`. Why: express the finalized scalar/vector memory transaction. Sharp edge: count/bit width and alignment come from the load's shape/dtype; this emitter trusts previous coalescing/alignment analysis. Global loads receive `ACCESS_CAN_REORDER`.

### renderer/nir.py:L158 — NIRRenderer.def_rewrite: vector construction

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L158). Match STACK and emit NIR `vecN` over emitted source definitions, where N is x.max_numel(). Example: `STACK(a,b,c,d) → vec4(a,b,c,d)`. Why: translate tinygrad's shaped register values to NIR vector SSA. Sharp edge: this is not buffer allocation; empty STACK is skipped in the imperative render loop before this matcher.

### renderer/nir.py:L159 — NIRRenderer.def_rewrite: ALU opcode selection

The output of a comparison is bool regardless of what was compared. Reading its inputs distinguishes floating comparison from signed or unsigned integer comparison, each of which interprets the same raw bits differently.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L159). Match GroupOp.ALU; choose `aop[first_source.dtype][op]` and emit with all sources. Examples: float ADD→fadd, uint CDIV→udiv, signed CDIV→idiv; uint CMPLT→ult versus signed→ilt versus float→flt. Why: NIR encodes type/semantics in opcode selection. Sharp edge: the first source dtype drives selection, not result dtype—comparisons return bool but must compare floats/integers correctly. Unsupported op/type pairs require prior decomposition; a broad structural match does not imply a table entry exists. The opcode-table comprehensions are dispatch data, not additional PatternMatcher rule constructors.

### renderer/nir.py:L160 — NIRRenderer.def_rewrite: ordinary conversion

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L160). Match CAST and invoke ncast with input/output dtypes. Example: `CAST(float,int32_value) → i2f32`; float→int32 uses f2i32. Why: emit numeric conversion after backend legality fixes. Sharp edge: integer-to-integer conversions derive the operation family from input signedness and destination bit width; this is not an arbitrary reinterpretation of bits.

### renderer/nir.py:L161 — NIRRenderer.def_rewrite: bitcast identity in NIR SSA

The same 32-bit definition can feed float arithmetic or integer bit operations. Returning the existing definition is sufficient for a legal same-width reinterpretation because the later opcode supplies the interpretation; a numeric conversion still needs an instruction.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L161). Match BITCAST with first child a, allowing extra operands; return the existing emitted definition of a. Example: float32→uint32 BITCAST shares the same NIR 32-bit SSA bits; a later integer op interprets them as integer. Why: NIR SSA definitions carry bit size/components rather than tinygrad's full scalar type interpretation. Sharp edge: do not replace numeric CAST with this; valid width/shape bitcasts are assumed from earlier lowering.

### renderer/nir.py:L162 — NIRRenderer.def_rewrite: local register array

A mutable accumulator is convenient while building a loop, even though later compiler passes prefer one-assignment SSA values. Creating a local variable here lets Mesa perform that later transformation. “Local variable” in this sentence does not mean workgroup-shared LOCAL address space.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L162). Match BUFFER; create a function-local NIR variable with GLSL array type `(dtype,max_numel)` named `acc{slot}`. Example: register accumulator BUFFER(float,4)→local float[4] variable. Why: represent mutable register-backed accumulators with dereferences before Mesa SSA lowering. Sharp edge: LOCAL shared buffers are intercepted earlier in the render loop and allocated by shared byte offset; this PM callback is not that path.

### renderer/nir.py:L164 — NIRRenderer.def_rewrite: barrier

Threads cooperating on a reduction may need to wait until every partial sum has been written. Workgroup execution scope identifies the participants; it cannot provide a rendezvous between separate workgroups or kernel launches.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L164). Match BARRIER and emit `nir_intrinsic_barrier` with workgroup execution scope. Example: BARRIER after shared writes→workgroup barrier intrinsic. Why: retain synchronization in the hardware program. Sharp edge: inspect `nbarrier` for its exact intrinsic fields; this source sets execution scope and does not explicitly enumerate all possible memory-semantics flags.

### renderer/nir.py:L165 — NIRRenderer.def_rewrite: conditional entry

The builder keeps track of the current block while instructions are added. Opening an IF changes where subsequent instructions are inserted, so the returned handle identifies structure rather than a numerical result.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L165). Match IF x; call `nir_push_if` on the emitted first source predicate. Example: IF(gate)→open NIR if block. Why: preserve explicit control-flow regions produced during gating/linearization. Sharp edge: the returned object is a control-flow handle in the shared `ctx.r` map, not an arithmetic SSA value.

### renderer/nir.py:L166 — NIRRenderer.def_rewrite: conditional exit

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L166). Match ENDIF; recover the handle from its first source, pop the if, return an empty `nir_def` placeholder. Example: ENDIF(IF_handle)→close matching NIR if. Why: connect tinygrad's explicit structured-region markers to Mesa builder state. Sharp edge: pairing and instruction order are imperative invariants, not proved by the local UPat.

## IR3 image definitions: every def_rewrite rule

### renderer/nir.py:L293 — IR3Renderer.def_rewrite: image store

For pixel at row 2, column 7, the coordinate vector starts `(7,2)`. A 2D image does not use the remaining components; the underscores in the example denote unused fields. The image slot identifies the resource, while the coordinates identify the pixel inside it.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L293). Match STORE to two-coordinate image INDEX and data, allowing extra STORE sources. Emit `nir_intrinsic_image_store` with coordinate vector `(x,y,undef,undef)`, value, sample/LOD fields from helper, image dimension 2D, and source float type derived from value dtype. Example: `STORE(img[y,x],vec4) → image_store(slot,(x,y,_,_),vec4)`. Why: an image handle plus coordinates is not pointer arithmetic. Sharp edge: the callback does not itself consume an extra store gate; earlier control-flow lowering must already make execution legal. The pattern has no image-shape guard and relies on the two-coordinate phase contract.

### renderer/nir.py:L295 — IR3Renderer.def_rewrite: gated image load

A padded convolution can request a logically invalid element that maps to an otherwise real image pixel. That pixel may contain nonzero data, so the remaining gate must select the fallback rather than rely on physical image bounds.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L295). Match `LOAD(INDEX(img,y,x),alt,gate)` and emit if/phi around `ctx.nload_img` versus alt. Example: a remaining convolution gate→conditional image_load with zero on false. Why: some invalid coordinates remain physically in bounds; image OOB alone cannot implement those masks. Sharp edge: nload_img registers the handle in `ctx.texs`, affecting postrender argument-slot assignment; emission has ABI bookkeeping effects as well as a returned value.

### renderer/nir.py:L297 — IR3Renderer.def_rewrite: plain image load

A half-storage pixel has four 16-bit stored channels, but this load returns four 32-bit computation components. Recording and later renumbering its slot keeps the emitted access consistent with how the runtime binds the image.

[Source](../../../../tinygrad/tinygrad/renderer/nir.py#L297). Match one-source LOAD of two-coordinate INDEX. Emit `_nload_img`, record read image handle in `ctx.texs`; helper requests four 32-bit components and 2D float image load. Example: image mask proof removes y<height→plain image_load of RGBA pixel. Why: use native image path after redundant gates are removed. Sharp edge: storage half/full type and four-component result are separate; slot numbers are patched by `postrender` after all reads are known.

## Essential non-PM behavior surrounding these rules

The renderer's imperative loop handles RANGE/END, AFTER, SINK, shared allocation and register component extraction before calling `def_rewrite`. Loop END contains a retained extra exit check: a source comment names `TestMultiTensor.test_double_matmul_shard_W_0` segfaulting without it. It is a specific workaround, not an unlisted matcher.

NAK parameter loading uses aligned `ldc_nv` slots; its float16 support is gated to architecture number at least 53. LVP disables EXP2 in `code_for_op`: the source cites Gallivm handling of infinities/zero/NaNs, so earlier decomposition must provide another implementation. IR3 parameters use UBOs for ordinary arguments and image IDs for images; postrender renumbers textures/images. These chip/backend decisions are outside the matcher census but affect which rules can safely run.

Validation scope: coalescing/image probes passed; the full upstream `test_simplify_valid_idx.py` run returned **40 passed, 1 xfailed** with `DEV=NULL`. No NIR/Mesa object construction, hardware compilation, or GPU execution was performed for these per-rule illustrations.
