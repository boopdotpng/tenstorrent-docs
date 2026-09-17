# AMD pattern matchers: chip contracts, lowering, and kernel boundaries

Source snapshot: tinygrad `107adc31701df0247dfa45e175984df906a68b53`. This chapter distinguishes source-established behavior from inferred rationale. Five WMMA matcher/render probes below were executed with `ALLOW_DEVICE_USAGE=0`; no GPU was opened, and no AMD numerical or performance result is claimed. The [LLVM/tensor-core reference](rules/render-llvm-tc.md) and [C-style reference](rules/render-cstyle.md) expand each renderer rule separately.

## The hardware problem these rules solve

A GPU executes many copies of a kernel. One copy is a **work-item**, often called a thread. AMD groups these into **waves**; other GPU documentation often calls the equivalent group a warp. A **lane** is one thread position within a wave. A **workgroup** contains cooperating work-items that can share local memory and wait at a barrier. Many workgroups form a launch's grid. A barrier inside one workgroup cannot make every workgroup wait.

A matrix instruction computes a small matrix multiply and adds an accumulator, `C = A @ B + C`. The participating lanes each hold only a **fragment** of those matrices. For example, `BF16×8` below means eight BF16 values owned by one lane; it does not describe the whole matrix tile. BF16 is a 16-bit floating format; FP8 uses eight bits. `half` means IEEE float16. These formats represent numbers differently even when they occupy the same number of bits.

Tinygrad calls its matrix operation `WMMA`. AMD exposes different instruction families, including WMMA and MFMA, on RDNA and CDNA chips. A compiler **intrinsic** is a specially recognized function that requests such an operation. Its **ABI** is the exact calling contract: argument types, counts, order, control fields, and result layout. Many apparently strange PMs exist because the intrinsic expects a different representation from the useful values tinygrad tracks.

The critical distinction is **cast versus bitcast**. A numeric cast of float `1.0` to an integer produces integer `1`. A bitcast preserves the stored bits and changes how they are interpreted. BF16's encoding of `1.0` is `0x3f80`, so presenting that value as a uint16 argument requires those bits, not integer `1`. **Packing** similarly puts several encoded values into a larger argument: eight FP8 values occupy the same 64 bits as one uint64. No arithmetic sum or numeric conversion is implied.

`PM` means an ordered pattern matcher; a `UOp` is a node in tinygrad's computation representation. A **graph PM** rewrites nodes. A **string PM** spells those nodes as compiler input text. The sections below follow those two jobs separately.

## First distinguish three routes

[AMDDevice's renderer registration](/home/boop/tenstorrent/tinygrad/tinygrad/runtime/ops_amd.py:883) offers HIPRenderer, AMDLLVMRenderer, and HIPCCRenderer. HIPRenderer emits HIP-flavored C++ and passes it to AMD's COMGR compiler interface. HIPCCRenderer shares its patterns but invokes a different compiler. AMDLLVMRenderer emits LLVM IR, a lower-level compiler representation, and uses AMDLLVMCompiler. Thus the same mathematical operation can need different repair rules depending on which compiler interface receives it.

There is also explicit AMD instruction assembly: [pm_to_program](/home/boop/tenstorrent/tinygrad/tinygrad/codegen/__init__.py:462) recognizes a LINEAR whose sources are INS **before** the ordinary render rule and invokes `asm`. Both AMD renderers route that to [assemble_linear](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/amd/elf.py:15). Here `LINEAR` is an ordered sequence and `INS` denotes explicit machine instructions. Assembly packages those instructions and their register usage into ELF, the executable object format used here. It is not a general AMD instruction-selection PM translating arbitrary scalar UOps into AMD assembly. At this snapshot `renderer/isa/` contains the shared ISA framework and x86 implementation, not an AMD ISARenderer; the generic `pre_regalloc_matcher → pm_regalloc_rewrite → post_regalloc_matcher` path in [do_linearize](/home/boop/tenstorrent/tinygrad/tinygrad/codegen/__init__.py:427) is guarded by `isinstance(ctx, ISARenderer)` and does not describe ordinary HIP/AMDLLVM kernels.

`renderer/amd/{dsl,generate,__init__,elf,sqtt}.py` therefore deserves a module-map entry, but not an invented collection of AMD optimization PMs: these files implement instruction bitfields/encoding generation, decoding, ELF packaging, and trace decoding. Source-level HIP `.text` assembly through COMGR is another compiler input mode; do not conflate it with the explicit INS route.

## Where AMD-specific PMs run

The [late codegen pipeline](/home/boop/tenstorrent/tinygrad/tinygrad/codegen/__init__.py:358) first settles operand dtypes, constructs decomposition rules from `ren.code_for_op`, decomposes unsupported dtypes, lowers operations, and relocates load/store gates. A load/store **gate** is a condition deciding whether a memory access happens. A **weak** constant has a type that still needs to be settled from context. With those jobs mostly done, its final graph matcher is:

```text
pm_commit_weak + pm_decomp + ren.extra_matcher + pm_split_ends + pm_remove_invalid
```

Then constants are committed, implicit workgroup barriers are introduced, control flow is built, and the graph is linearized. HIP and LLVM `string_rewrite` subsequently turn individual UOps into text. A string PM does not return a better tensor graph: it fulfills the backend's syntax/intrinsic contract.

Composition is ordered: an earlier matching callback that returns a non-None result other than the original UOp wins for that attempt. A callback returning None or the identical UOp allows later rules to run. Backend-specific text rules precede the generic rules where the generic rule would otherwise swallow the same operation. Graph rewriting may revisit replacements, so progress guards such as an input dtype change matter.

## HIP graph PMs: why small floats need several layers

[create_non_native_float_pats](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:77) is a factory, not one immutable PM. HIP instantiates it for BF16 and FP8. It (1) commits weak constant siblings at the emulated dtype, (2) performs non-WHERE arithmetic in float32 and casts back, (3) performs comparisons in float32, and (4–5) routes conversions into/out of emulated types through float32 when needed. `WHERE(condition, a, b)` selects an existing value. Selection needs no arithmetic on the encoded float, so it can preserve the original representation without a round trip through float32.

For example, `ADD(a_bf16,b_bf16)` becomes `CAST_bf16(ADD(CAST_f32(a),CAST_f32(b)))`. This is a legality/emulation choice with rounding implications, not evidence that a sequence of BF16 operations is accumulated indefinitely in float32. Each rewritten result retains the original dtype boundary. Unsupported FP8 formats may already have been handled by `pm_dtype_decomps`; having an FP8 pattern does not imply the target advertises all FP8 dtypes.

[pm_manual_bf16_cast](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:100) is explicitly documented as avoiding compiler intrinsics. BF16→FP32 shifts the 16 stored bits into the high half of a uint32 and bitcasts to float. FP32→BF16 uses integer rounding logic: add `0x7fff + retained_lsb` for round-to-nearest-even and preserve NaN information before truncation. The retained least-significant bit (`retained_lsb`) decides which way an exact halfway case rounds. NaN means “not a number”; its encoding must remain distinguishable from infinity. Simply using `bits >> 16` would discard that rounding and can turn a NaN into infinity.

HIP appends that PM on every target **except** `HIPRenderer.is_cdna4(arch)`, i.e. `arch.split(':')[0] == 'gfx950'`. In the same non-CDNA4 branch [pm_bf16_ushort_const](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:106) renders BF16 constants as unsigned storage bit patterns. Otherwise a cast such as `(unsigned short)1.0f` would produce integer 1 instead of BF16's encoding of 1.0. HIP's typedef is `unsigned short` there, but `__bf16` on gfx950. AMDLLVM inherits the manual BF16 graph PM even on gfx950: do not transfer HIP's exception to the LLVM route.

HIP's additional [FP8 WMMA input rule](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:527) matches float-output WMMA with eight FP8 OCP values in the first input and bitcasts both inputs to uint64. The shape changes from eight bytes to one 64-bit argument without numerically converting them. It is an intrinsic ABI adaptation, not eight FP8 numbers becoming one large mathematical integer.

## HIP string PMs and non-PM chip adaptations

In the table, `K` is the inner dimension of the matrix multiply: each result sums K products. A **format selector** tells an intrinsic how to interpret its packed input bits.

On [CDNA, recognized as gfx942/gfx950](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:488), HIP installs five rules before `base_rewrite`:

| Rule | Contract and example | Why / sharp edge |
|---|---|---|
| K=128 WMMA | Emit wrapper call with six trailing fields: two A/B format selectors plus four zeros. | Must precede the general WMMA rule. Uses scale MFMA builtin naming in the generated prefix; do not copy its C builtin control argument spelling directly into LLVM IR. |
| Other WMMA | Emit wrapper call with three trailing zero controls. | MFMA's C builtin ABI differs from the generic three-argument WMMA spelling. |
| FP8 constant CAST | Emit `f32_to_fp8(value, format)` with special NaN/Inf handling. | The storage typedef is byte-sized; integer truncation would not encode FP8. |
| FP32→FP8 | Call the same `f32_to_fp8` helper. | Helper clamps finite values to ±448 or ±57344 before the packed conversion builtin; NaN/Inf bypass the finite clamp. |
| FP8→FP32 | Call `__builtin_amdgcn_cvt_f32_fp8/bf8((unsigned int)x,0)`. | Integer widening supplies the encoded byte and selects its lane, rather than numerically converting its storage integer. |

All HIP targets prepend [nontemporal LOAD rendering](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:510): a one-source LOAD with `arg='nontemporal'` becomes `__builtin_nontemporal_load(pointer)`. “Nontemporal” marks data that is not expected to benefit from ordinary cache reuse. The source comment says it is only used on global loads, which read device-wide memory. This rule consumes an existing annotation; it does not discover streaming accesses, fuse kernels, or tag every load in a reduction. Its pattern does not include the three-source gated-load shape, so producer invariants matter.

Several important chip accommodations are **ordinary code, not PMs**:

- [WMMA wrapper generation](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:565) selects CDNA MFMA, RDNA4 `_w32_gfx12` builtins, RDNA3 signed-int8 argument bitcasts, or RDNA3 half accumulator packing. RDNA3's half-output wrapper expands eight accumulators into even positions of half16, invokes WMMA with `opsel=false`, then extracts the even positions. This corresponds to a graph PM on the LLVM route.
- [tc.get_amd](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:112) selects fragment layouts, tile shapes, and allowed dtype pairs. RDNA3 uses 16-element A/B fragments; RDNA4 uses eight for the listed 16×16×16 forms. CDNA has 64 lane layouts and four float accumulators per lane. These layout descriptions constrain optimization before renderer PMs ever run.
- [global_max](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:483) limits workgroup grid dimensions; the source explicitly says the limit is really needed on gfx12 despite gfx11 reporting it too. This is a documented target limitation, not a pattern rewrite.
- HIP and AMDLLVM [supported_dtypes](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/cstyle.py:588) advertise FP8 OCP only for the exact arch string `gfx950` and exclude FNUZ. `is_cdna` strips suffixes but `tc.get_amd`, exact RDNA validator guards, and dtype guards do not all do so. A target string such as `gfx950:...` is therefore not uniformly normalized by these helpers; read the actual call site instead of assuming a family-wide guarantee.

## AMDLLVM's graph and text PMs

[AMDLLVMRenderer.extra_matcher](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:241) starts with LLVMRenderer's BF16 emulation/manual-cast PM, adds FP8 emulation, and adds **two separate float64 rules**: LOG2→`xlog2` and EXP2→`xexp2`. The source explicitly says AMD's LLVM log2/exp2 intrinsics do not support double. Without these rules the renderer's advertised op support would prevent the generic unsupported-op path from decomposing that dtype. This is a backend/dtype workaround, not a chip-specific tensor-core optimization.

Its [string PM](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:230) maps SPECIAL to workgroup/workitem IDs, SQRT/LOG2/EXP2 to LLVM intrinsics, BARRIER to release-fence + AMD barrier + acquire-fence, FP32→FP8 to `f32_to_fp8`, and FP8→FP32 to byte zero-extension plus the AMD conversion intrinsic. Generic LLVM rules follow. A WMMA text rule is appended in `__init__`; the generic LLVM PM has no WMMA rule to intercept it.

A release fence orders earlier memory writes before a synchronization point; an acquire fence orders later accesses after it. The barrier makes the workgroup rendezvous. Both ordering and rendezvous matter when lanes exchange data through shared storage.

### Each chip validation PM

In these rules A and B are the matrix inputs, and C is the running accumulator. A condition mentioning the “first input” is the actual matcher guard; do not silently assume it independently checks every operand. These are called "validate" but return rewritten UOps. Their names should not be read as assertions that all other illegal fragments will be rejected.

#### RDNA3: exact `gfx1100` or `gfx1151`

[pm_validate_wmma_rdna3](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:114) has three rules, in this order:

1. **Integer operands:** match int32 output with an int8×16 first input. Bitcast both inputs to uint32 representation. Sixteen one-byte values become four four-byte values (`int8×16 → uint32×4`), matching the intrinsic's packed argument contract. Their bits and intended matrix elements stay the same.
2. **Half accumulator slots:** match half output×8. The instruction interface expects half16 although tinygrad tracks eight useful values per lane. Expand `[c0,...,c7]` to `[c0,0,c1,0,...,c7,0]`, invoke WMMA, and collect the even result positions. The inserted zeros occupy unused slots; this is not an extra mathematical reduction.
3. **BF16 operands:** match BF16 first input×16. Bitcast both inputs to uint16 representation. Each BF16 keeps its own 16 bits (`BF16×16 → uint16×16`); the intrinsic accepts those encodings through integer-typed arguments.

#### RDNA4: exact `gfx1200` or `gfx1201`

[pm_validate_wmma_rdna4](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:129) has two rules:

1. **BF16 result and accumulator:** match BF16 output×8 and BF16 first input×8. Bitcast A, B, and C to uint16 representation, then bitcast the result back to BF16. The compiler interface uses integer-typed arguments and result for these BF16 bit patterns.
2. **Float32 result and accumulator:** match float output×8 and BF16 first input×8. Bitcast only A/B to uint16. For example, A becomes `uint16×8` while C remains `float×8`: there is no need to reinterpret a float accumulator that already matches the interface.

#### CDNA: `is_cdna` guard

[pm_validate_wmma_cdna](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/tc.py:138) has three rules:

1. **K=128 packed inputs:** match float output, K=128, and first-input `itemsize≤8`. Bitcast inputs to uint32 representation. For example, FP8×32 occupies 32 bytes and becomes uint32×8. The predicate is deliberately quoted literally: it is broader than “FP8 only.” This specialized case appears before the smaller-fragment cases.
2. **BF16 inputs:** match float output×4 and BF16 first input×4. Bitcast A/B to uint16; `BF16×4 → uint16×4` preserves each encoded value and leaves the float accumulator alone.
3. **FP8 OCP inputs:** match float output×4 and FP8 OCP first input×8. Bitcast A/B to uint64; eight bytes become one scalar uint64 argument. Again, that scalar is a package of bits, not the numeric conversion of eight floats into one integer. OCP and FNUZ name different FP8 format families; a rule supporting one does not establish support for the other.

The [LLVM WMMA renderer](/home/boop/tenstorrent/tinygrad/tinygrad/renderer/llvmir.py:37) names the intrinsic using original mathematical input dtype in `wmma.arg`, while its argument types come from rewritten sources. That is why simply changing dtype metadata instead of inserting bitcasts is wrong. RDNA4 gets overloaded vector-type suffixes. CDNA K128 emits scale-MFMA with E8M0 scale bytes 127, representing scale 1.0. That is source-comment-established behavior; do not describe 127 as an arbitrary magic performance constant.

## A nontrivial RMSNorm → matmul reading exercise

Take `x:[B,4096]`, learned `gamma:[4096]`, and `W:[4096,N]`:

```text
s[b] = sum_k float(x[b,k])² / 4096
r[b] = reciprocal(sqrt(s[b] + eps))
y[b,k] = cast_bf16(float(x[b,k]) * r[b] * float(gamma[k]))
z[b,n] = sum_k float(y[b,k]) * float(W[k,n])
```

The existing [RMSNorm/kernel-fusion walkthrough](rmsnorm-kernel-fusion.md) contains CPU schedule measurements; those kernel counts are not AMD predictions. Here is a source-derived AMD lowering audit, not an executed AMD schedule:

1. **Before renderer selection**, inspect scheduler boundaries. A per-row reduction can require materialized partial sums or a separate result; matmul's consumers can require a complete normalized row. Establish whether `y` is an actual buffer or an inlined producer inside the matmul AST. Backend cast PMs cannot make a materialized `y` disappear across separate PROGRAMs.
2. **Within an RMSNorm kernel**, generic local-reduction lowering chooses lane/workgroup work, introduces LOCAL buffers as necessary, then implicit-barrier rules protect local communication. HIP BARRIER rendering expands to release fence → `s_barrier` → acquire fence. LLVM renders the corresponding intrinsic sequence. Changing a barrier string cannot legally combine two grid launches; a workgroup barrier has no cross-workgroup rendezvous.
3. **At BF16 loads and stores**, HIP gfx1100/gfx1200/gfx942 uses integer bit manipulations for conversion. HIP gfx950 uses its native BF16 type path. AMDLLVM retains manual BF16 casting. If the computation explicitly casts once to float32 before reduction, the sum stays float32; if a BF16 ALU chain is retained, its per-operation conversion boundaries may differ. Compare UOps, not just Python spelling.
4. **Inside matmul**, the optimizer has to select a tensor-core layout before a WMMA ABI matcher can help. For RDNA3 BF16→FP32 WMMA, the LLVM matcher presents A/B as uint16×16; RDNA4 presents uint16×8. Replacing just an intrinsic suffix while retaining RDNA3 fragments is not a valid port.
5. **If normalizing inside the matmul kernel**, decide which output tiles redundantly compute `r[b]`, which lanes own row reduction values, how the other lanes obtain them, and whether the normalized row fits in registers or LDS. Registers hold a thread’s working values; LDS is AMD’s workgroup-shared local memory. Both have limited capacity. Using more per workgroup can reduce **occupancy**, the number of waves that can run concurrently. Fusion may save the intermediate global write/read while duplicating reductions or leaving fewer waves available to hide memory delays. None of the ABI rules proves a net performance win. Recount PROGRAM nodes, global buffer traffic, and local barriers, then measure on hardware separately.

An equally instructive existing kernel-level boundary is [LLM quantized linear](/home/boop/tenstorrent/tinygrad/tinygrad/llm/kernels/amd.py:155): `q8_quantize` writes quantized activations, scales, and sums; later decode consumes them. [The custom-kernel gate](/home/boop/tenstorrent/tinygrad/tinygrad/llm/kernels/amd.py:29) explicitly restricts these kernels to gfx11 with HIPRenderer because register layouts, wave32 operations, and dp4a builtins are not portable to gfx12/CDNA. This is ordinary algorithm-selection code, not a general fusion PM. Fusing quantize into decode requires an ownership/reuse design for activation groups across output tiles; merely seeing a MULADD or WMMA rule is insufficient.

## CPU-only observed matcher examples

The following five synthetic fragment probes were executed at this snapshot, importing PMs and `render_wmma_amd` only, with `ALLOW_DEVICE_USAGE=0`. They exercise matcher output and text generation, not the scheduler, full compiler, or numerical execution.

| Synthetic input | Observed output |
|---|---|
| RDNA3 half16 A/B, half8 C | outer STACK half8; inner WMMA half16 C/result; `llvm.amdgcn.wmma.f16.16x16x16.f16(..., i1 false)` |
| RDNA3 int8×16 A/B, int32×8 C | uint32×4 A/B; `llvm.amdgcn.wmma.i32.16x16x16.iu8(i1 true, <4 x i32> A, i1 true, <4 x i32> B, <8 x i32> C, i1 false)` |
| RDNA4 BF16×8 A/B, float×8 C | uint16×8 A/B; `llvm.amdgcn.wmma.f32.16x16x16.bf16.v8f32.v8bf16` |
| CDNA K32 FP8×8 A/B, float×4 C | uint64 scalar A/B; `llvm.amdgcn.mfma.f32.16x16x32.fp8.fp8` |
| CDNA4 K128 FP8×32 A/B, float×4 C | uint32×8 A/B; scale-MFMA trailing arguments `0,0,0,127,0,127` |

Reproduce an individual case without constructing a renderer/compiler/device:

```python
from tinygrad import UOp, dtypes
from tinygrad.uop.ops import Ops
from tinygrad.renderer import tc
from tinygrad.renderer.llvmir import render_wmma_amd

def frag(n, dt, slot):
  return UOp.placeholder((n,), dt, slot=slot).load()

x = UOp(Ops.WMMA, src=(frag(8, dtypes.bfloat16, 0),
                       frag(8, dtypes.bfloat16, 1),
                       frag(8, dtypes.float, 2)),
        arg=((16,16,16), dtypes.bfloat16, dtypes.float, None))
y = tc.pm_validate_wmma_rdna4.rewrite(x)
assert y.src[0].dtype == dtypes.uint16 and y.src[0].shape == (8,)
print(render_wmma_amd({y:'%r', **{s:f'%arg{i}' for i,s in enumerate(y.src)}}, y, rdna4=True))
```

Run from the checkout with `ALLOW_DEVICE_USAGE=0 python3 ...`. Existing test anchors worth reading include [tensor-core optimization tests](/home/boop/tenstorrent/tinygrad/test/opt/test_tensor_cores.py:1), [AMD LLVM compiler tests](/home/boop/tenstorrent/tinygrad/test/device/test_amd_llvm.py:1), [AMD integration](/home/boop/tenstorrent/tinygrad/test/amd/test_integration.py:82), [BF16 rounding tests](/home/boop/tenstorrent/tinygrad/test/null/test_dtype_spec.py:107), and [backend dtype conversions](/home/boop/tenstorrent/tinygrad/test/backend/test_dtype.py:176). They are related validation coverage, not a claim that every rule has a dedicated unit test or that those hardware tests were run here.

## Runtime PMs that do not optimize arithmetic

[AMDDevice.pm_encode](/home/boop/tenstorrent/tinygrad/tinygrad/runtime/ops_amd.py:840) has two rules: compute submit CUSTOM_FUNCTION → encoded AMD compute queue, and copy submit → encoded SDMA queue. [Its bufferization prefix](/home/boop/tenstorrent/tinygrad/tinygrad/runtime/ops_amd.py:887) resolves scratch PARAMs, program PARAMs, then other queue PARAMs before the inherited bufferizer. The compute queue tells the GPU which kernels to run; the SDMA queue tells its copy engine which transfers to perform. Bufferization resolves symbolic parameter references to the allocations the commands will use. Profiling conditionally prepends a generated PARAM-tag rule for each of `prof_log`, `pmc_buf`, `sqtt_buf`, `sqtt_wptrs`. USB transport substitutes shared USB batching/lowering PMs and prepends USB bufferization. These PMs explain how an already selected kernel becomes queue work; they are not WMMA ABI fixups or tensor fusion rules.

## Worked exercises

1. **Why is half8 not passed directly to RDNA3 half WMMA?** Expand an accumulator `[c0,...,c7]`. **Solution:** the rule constructs `[c0,0,c1,0,...,c7,0]`, requests the half16 intrinsic with `opsel=false`, and extracts indices `0,2,...,14`. The generic tensor-core abstraction carries useful per-lane values; the backend adapts the machine/compiler fragment representation. This is representation repair, not a reduction over the inserted zeros.
2. **Would moving a backend WMMA rule ahead of scheduling fuse RMSNorm→matmul?** **Solution:** no. The rule matches a single WMMA already within a kernel graph and changes fragment representation. Kernel fusion must establish shared iteration domains, reduction completion, producer lifetime, and synchronization before materialization/launch boundaries are fixed.
3. **Port a gfx1100 BF16 matmul to gfx1200. What must change besides the intrinsic name?** **Solution:** select RDNA4 tensor-core opts/fragment ownership, change A/B per-lane count 16→8, apply RDNA4 validator guards, and use its overloaded signature. Reusing RDNA3 register ownership is explicitly unsafe; inspect custom-kernel architecture gating for a concrete example.
4. **Delete manual BF16 conversion on HIP gfx942. Why could ordinary tests miss it?** **Solution:** storage is typedef'd unsigned short. Direct numeric casts mishandle the encoded value; integer-like inputs or a test that never crosses the cast can hide this. Include 1.0, ties with even/odd retained LSBs, small values, NaN/Inf, and both directions. gfx950 HIP uses a different type path, so success there does not validate gfx942.
5. **K128 FP8 scale byte is 127: why not zero?** **Solution:** LLVM's E8M0 scale encoding is `2^(byte−127)`, making 127 the identity scale. The HIP builtin argument convention is a separate contract; do not replace its zeros mechanically using the LLVM spelling.
6. **How do you distinguish evidence that fusion occurred from prettier generated code?** **Solution:** compare scheduled PROGRAM count and intermediate global allocations/accesses for the same workload. A WMMA, fused ALU expression, nontemporal load, or eliminated CAST inside one kernel says nothing by itself about removed launches. Then validate numerically and benchmark separately.
