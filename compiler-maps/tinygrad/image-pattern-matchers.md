# IMAGE: late buffer views, mask proofs, packing, and the workarounds

Audited at clean tinygrad master `107adc31701df0247dfa45e175984df906a68b53` (2026-09-17). This chapter explains the complete IMAGE-specific matcher path and the surrounding code that makes it work. [Individual NIR/coalescing rules](rules/render-nir-image.md) enumerate each rule, including non-image rules in those files. Examples marked schematic are source-derived, not GPU measurements.

`IMAGE` does **two different jobs**. At the Tensor level it selects specially packed convolution/matmul expressions. Much later, it lets the compiler reinterpret eligible flat buffers as RGBA images. These choices can affect packing kernels, materialization, numeric precision, and memory instructions. An image is not an operation-fusion annotation, and enabling it does not prove fewer kernels or faster execution.

## Start with a flat array and a four-number pixel

Here an **image** is a GPU memory-access facility, not necessarily a picture. An ordinary buffer might hold `[a0, a1, ..., a15]`. The same storage can be viewed as four RGBA pixels, each with four channels: `[a0,a1,a2,a3]`, then `[a4,a5,a6,a7]`, and so on. The channel names are inherited from graphics; these values can be neural-network activations or weights.

A buffer load asks for an element offset. An image load asks for a two-dimensional pixel coordinate and obtains four values together. Hardware and drivers impose restrictions on which buffers can have such a view. The compiler must arrange values, choose a valid image shape, and preserve the behavior of masked or out-of-bounds accesses. Those obligations explain most of the rules below.

A **mask**, **predicate**, or **gate** is a Boolean condition such as `j < width`. A masked load must return its specified fallback, often zero, when that condition is false. **OOB** means out of bounds. **Pitch** is the distance between starts of successive physical rows, which can exceed the logical row width because of padding. Alignment requires that an address or pitch be a multiple of a specified size. Always check whether that size is measured in bytes, pixels, or scalar elements.

A **lane** in this chapter usually means one of the four components of a shaped value; it does not necessarily mean a GPU thread. **Coalescing** here combines adjacent scalar memory operations into one wider operation. **Upcasting** in tinygrad's loop optimizer exposes multiple elements together for this purpose; it does not mean converting float16 to float32. **Materialization** means actually storing a computed array so later kernels can read it.

## What exists now, versus older IMAGE explanations

There is no current `ImageDType`, `dtypes.imageh`, `dtypes.imagef`, or `Ops.IMAGE`. Storage dtype remains `half` or `float`. The image view is [`ParamArg.image=(height,width)`](../../../tinygrad/tinygrad/uop/ops.py#L25), yielding shape `(height,width,4)`; indexing it by `(y,x)` yields four lanes with float32 access dtype even when storage is half. [`is_image_shape`](../../../tinygrad/tinygrad/helpers.py#L37) recognizes the three-dimensional shape ending in four. Do not confuse a shaped high-level tensor with an already promoted late image parameter.

Local git history establishes these changes:

| Commit | Change | Consequence for old notes |
|---|---|---|
| `1560b534a`, 2026-03-20 | remove `IMAGE=2` | Current image selection uses truthiness; do not teach the old 1-versus-2 storage policy. Old comments/commands still say `IMAGE=2`. |
| `a94a32ff7` | move image to post-coalesce | Four-lane memory formation precedes image conversion. |
| `63cb1369c`, 2026-07-08 | remove `ImageDType` | Current layout lives on parameters, not a custom dtype. |
| `034d68380` then `168a96439`, 2026-09-14 revert | remove then restore float→half→float folding | The fold is present at this snapshot; its precision implications are current, not historical. |
| `f24806b1d`, 2026-09-13 | assert image convolution dtype float32 | `image_conv2d(dtype=half)` is not a supported way to request half compute. |

These are verified local commit subjects/diffs, not claims about author intent or subsequent direction.

## The actual pipeline and every IMAGE-facing matcher

| Stage | Matcher / code | Why it exists and what to inspect |
|---|---|---|
| Tensor expression construction | [`image_dot`, `image_conv2d`](../../../tinygrad/tinygrad/mixin/op.py#L1463), ordinary methods rather than PMs | Matmul becomes 1×1 convolution; padding and transposes arrange channels in groups of four. |
| Materialization reuse | [`pm_fold_moved_after`](../../../tinygrad/tinygrad/schedule/prepare.py#L26), guarded by `OPENPILOT_HACKS` | Three rules discover `AFTER(STORE(...))`, discover self-copy materializations, and replace ALU inputs with these already materialized values. `found_after` reverses reshape/permute/Invalid padding; with `FLOAT16`, it also follows a half cast and reloads as float. This can change kernel dependencies. |
| Index simplification | [`pm_simplify_valid`](../../../tinygrad/tinygrad/uop/symbolic.py#L439) inside `sym` | Its `gated_given_valid` helper deliberately declines div/mod-containing weak integer expressions under IMAGE. Source labels image indexing/openpilot as the reason; it does not establish a universal div/mod bug. |
| Axis optimization | [`hand_coded_optimizations`](../../../tinygrad/tinygrad/codegen/opt/heuristic.py#L49), not a PM | Finds unit-stride axes divisible by four whose range does not occur in the validity mask; upcasts/unrolls four lanes early. |
| Scalar memory consolidation | [`memory_coalescing`](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L104), not a PM | Four contiguous accesses with common buffer, base, validity and memory-op argument become one shaped access. Volatile accesses are excluded. |
| Image promotion | [`pm_simplify_add_image`](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L97), **three rules** | Promote `SHRINK(PARAM, offset, 4)`; cast half stores to float for float image access; fold float→half→float. The last rule is not guarded by IMAGE. |
| Image mask proof | [`indexing_simplify`](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L58), **two rules total** | First simplifies ordinary gated indices. Second handles two image coordinates carrying the same predicate and removes conjuncts proven redundant under image OOB semantics. |
| Explicit gates | [`pm_move_gates_from_index`](../../../tinygrad/tinygrad/codegen/late/gater.py#L9), **two leading image rules** | Convert validity on both coordinates into `LOAD(index, zero, gate)` or `STORE(index, data, gate)`. Must precede the generic single-index rules. Other rules fold outer WHERE alternatives into gated loads. |
| OpenCL emission | [`OpenCLRenderer.string_rewrite`](../../../tinygrad/tinygrad/renderer/cstyle.py#L325), **four image rules** | Two-coordinate INDEX placeholder; gated `read_imagef`; ungated `read_imagef`; `write_imagef`. Ordinary fallback rendering comes after these. |
| NIR legalization | [`NIRRenderer.extra_matcher`](../../../tinygrad/tinygrad/renderer/nir.py#L137), **two relevant rules** | Ordinary memory offsets become int64, excluding images; image coordinates become int32 without changing float access dtype. |
| Adreno NIR emission | [`IR3Renderer.def_rewrite`](../../../tinygrad/tinygrad/renderer/nir.py#L292), **three rules** | Image store intrinsic; gated image load via control flow/phi; plain image load intrinsic. These precede generic NIR memory rules. |

Read the stage table as three practical tasks: arrange reusable storage, combine four compatible accesses, then emit the backend’s image operations. A `PM` is an ordered pattern matcher; its guards decide which cases are safe to transform.

The exact late ordering is [codegen lines 335–373](../../../tinygrad/tinygrad/codegen/__init__.py#L335): devectorize with index simplification → symbolic → memory coalescing → `symbolic_simple + ew_devectorizer + pm_simplify_add_image` with `bottom_up=True` and a fresh `(shapes, renderer)` context → symbolic/index simplification with weak-type commitment → weak-index lowering → later gate extraction. Moving image creation before coalescing violates the current coalescer's single-flat-index assumption; a comment explicitly acknowledges incomplete handling of already formed images.

## Why the four-lane restriction matters

For scalar element offset `s` and image width `W`, promotion uses:

```
pixel_x = (s // 4) % W
pixel_y = s // (4 * W)
component = s % 4
```

For example, with `W=8` and aligned offset `s=44`, the pixel is `(y=1,x=3)` and its four channels correspond to offsets 44–47. `SHRINK` selects a portion of a shaped value. A promoted SHRINK already denotes four aligned adjacent elements. Its image INDEX returns the whole RGBA pixel; users take lane indices from that value. This is not a generic way to load any four unrelated elements.

A shared predicate can gate the entire pixel. Four different lane predicates generally cannot. The heuristic therefore rejects candidate upcast axes referenced by validity, and the coalescer groups accesses by the identical validity node. Example: indices `4*p+i` with validity `4*p+i < 1023` have different masks for `i=0..3`; they cannot blindly become one RGBA transaction. The [probe](probe-image-matchers.py) checks that this case is not image-promoted.

[`image_valid_dims`](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L66) requires pitch-alignment metadata, half/float storage, and dimensions bounded by 16384. It enumerates layouts without pitch padding, using 4 scalars per pixel. Ordinary multirow widths must be multiples of the advertised pixel alignment. Height-one images have a special byte-alignment route, using 64 bytes on OSX. Example: 16 float32 elements are only 4 pixels, yet can form a height-one image with `IMAGE_PITCH_ALIGNMENT=64` because their 64 bytes meet this special case. Treat this helper as an internal policy for packed candidate buffers, not a general API validating arbitrary byte arrays.

`transform_to_image` only enables targets named `QCOM`, `CL`, `PYTHON`, or `NULL`, with IMAGE truthy. AMD's native `AMD` target is absent: AMD hardware accessed through CL is a different target path. A bare `IMAGE=1` on native AMD does not enable image instructions.

For each candidate `(H,W)`, the promotion helper calculates how many validity clauses could disappear, chooses the maximum, then breaks ties by the number of nodes in the simplified **y coordinate**. A per-pass dictionary pins the chosen layout by parameter slot. All promoted accesses to a slot must agree within that kernel. It is not a global tensor layout registry across kernels.

The executable probe turns four scalar loads from a 1024-element buffer into one pixel load. With no useful mask, the tie breaker chooses `(H,W)=(1,256)`, making y constant zero. For a different access, a multirow layout can win by making a mask redundant. Thus logical tensor dimensions need not equal texture dimensions.

## The OOB trick: remove the test only when the image supplies the same zero

Why remove a mask at all? Testing a condition or branching on it costs instructions. If an image read already returns the required zero for the excluded coordinates, the explicit test is redundant.

The image load matcher is trying to prove **invalid lanes necessarily address outside the image**. It is not proving all coordinates are always in bounds. `_drop_valid_stmts` considers each AND clause; when that clause fails, it substitutes symbolic ranges and proves x or y is negative or at/above its bound. It also recognizes the special nonnegative sum `X0+X1+... >= 1`: the failing case forces every term to zero. If the proof is incomplete, keep the gate.

Concrete paired example from [upstream tests](../../../tinygrad/test/null/test_simplify_valid_idx.py#L234):

```
image shape (10,10,4): load(y, x), valid y<10 → load(y, x)        # y>=10 is OOB
image shape (20,10,4): load(y, x), valid y<10 → gated load(y, x)  # y=10..19 is real data
```

Another convolution-padding case: `valid y>=1`, coordinate `y-1`. When the gate fails at y=0, coordinate -1 is out of bounds; the read supplies zero. But `valid x>=1`, coordinate `x+1` does **not** qualify—x=0 addresses pixel 1. The probe exhaustively checks 1024 `(x,y)` pairs for each of the two height examples using a host reference image model and separately checks the actual rewrite and gate extraction.

A **sampler** specifies how image coordinates are interpreted and what happens at the border. Nearest sampling reads a pixel without interpolating its neighbors. Unnormalized coordinates are pixel coordinates rather than fractions of image size.

The emitted OpenCL sampler is [`CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST`](../../../tinygrad/tinygrad/renderer/cstyle.py#L150), not `CLAMP_TO_EDGE`. The optimization relies on image border semantics. The [Python interpreter](../../../tinygrad/tinygrad/runtime/ops_python.py#L115) explicitly returns an invalid address for image OOB, supplying the emulator's zero-load behavior. Hardware behavior for this snapshot was source-reviewed, not exercised here. Generic [OOB spec checking](../../../tinygrad/tinygrad/uop/spec.py#L16) explicitly skips image buffers; passing that checker does not independently validate the image-mask proof.

## Half precision: three distinct mechanisms, one particularly sharp edge

1. **Storage conversion.** `FLOAT16` makes `image_conv2d` pack through `cast(half).contiguous().cast(float)`. Memory holds half values; image math is float32. Image reads/writes use `read_imagef`/`write_imagef` even with half storage. Runtime descriptors carry the actual half format.
2. **Materialization reuse.** `found_after` can reuse the half-packed materialization as float when `FLOAT16` and `OPENPILOT_HACKS` are active. This is a scheduler choice with potential kernel-boundary and precision consequences, not just an instruction spelling choice.
3. **Round-trip cast elimination.** `pm_simplify_add_image` rewrites `float_value.cast(half).cast(float)` to `float_value`. It is in the always-run add-images pass and has **no IMAGE guard**. This is not an identity under strict rounding semantics: 1.0001 rounds to 1.0 in binary16. The matcher probe confirms the fold even under `IMAGE=0`. The recent remove/revert commits show this is a recently changing implementation detail; they do not make a general numeric equivalence true.

Do not use this fold as a tutorial example of universally valid cast cleanup. It is a good exercise in distinguishing a backend policy from a theorem.

## The genuinely unusual packing workarounds

All these are in [`image_conv2d`](../../../tinygrad/tinygrad/mixin/op.py#L1490), outside PatternMatcher objects:

- Pad input channels and per-group output channels to multiples of four, except special grouped-single-channel cases. Crop extra output channels after reduction. Real mathematical padding is zero-valued.
- Pack activations NHWC (batch, height, width, channels), making channels adjacent in memory; arrange weights differently for `cin==1`, spatial size 1×1, and the general case. These are concrete lane-layout choices, not an abstract convolution optimization hint.
- Pad physical pitch with **Invalid**, then materialize and slice back to the logical extent. Invalid pitch padding is distinct from mathematical convolution zeros; subsequent legal accesses must not observe it.
- Detect `cin>=8` with `cin/4` a power of two and force padding of the channel-block dimension. The source labels this “bank conflicts.” Memory banks service different addresses in parallel; conflicting accesses can compete for the same bank. Adding unused spacing changes which addresses coincide. This explains the purpose of perturbing physical strides, but neither the source nor these probes establishes its performance for every GPU.
- `pad_align` uses a 64-byte case for eligible short/one-row packing and a 64-pixel/256-scalar case otherwise. This frontend policy and late device alignment checks are separate; a packed expression still may fail late promotion.
- Upcast early so local dimensions do not obstruct four-lane formation. Also skip certain masked-global-axis upcasts when they leave fewer than `OCCUPANCY_FLOOR` (default 4096) global work-items under IMAGE. Keeping enough work-items available lets the device do other work while some wait for memory. This is a performance heuristic, not a condition required for the numerical answer.

## CL and Adreno-specific integration

[CL runtime](../../../tinygrad/tinygrad/runtime/ops_cl.py#L120) obtains `IMAGE_PITCH_ALIGNMENT` only when `cl_khr_image2d_from_buffer` exists. At dispatch it wraps a backing allocation in an RGBA image view with the parameter's shape and storage dtype. OSX uses a row-pitch rounding special case to 256 pixels. CPU probes do not validate driver acceptance of that combination.

[QCOM runtime](../../../tinygrad/tinygrad/runtime/ops_qcom.py#L326) attaches `IMAGE_PITCH_ALIGNMENT=64` when IMAGE is enabled and selects QCOMCL or IR3 rendering. This driver explicitly rejects GPU IDs at/above its `(7,3)` cutoff; do not infer support for newer Adreno parts from the generic image matchers. Its [descriptor construction](../../../tinygrad/tinygrad/runtime/ops_qcom.py#L88) chooses half/full RGBA format, pitches, texture/IBO slots and NIR texture-to-image remapping.

[QCOMCLRenderer](../../../tinygrad/tinygrad/renderer/cstyle.py#L600) has two additional ordinary-method workarounds: half dtype support is exposed only when **both IMAGE and FLOAT16** are enabled (source comment: the QCOM compiler is flaky with half), and global bool buffers are declared as uint8 because the QCOM load vectorizer otherwise emits invalid IR with a range/load type mismatch. Neither is a PatternMatcher rule, but omitting them would hide real backend constraints.

NIR is the intermediate representation used by the Mesa compiler path here; IR3 targets Adreno. IR3's three image rules emit NIR image intrinsics, operations the backend recognizes as image accesses. `IR3Renderer.postrender` renumbers read images and write images into their appropriate slot groups; runtime consumes the compiled mapping. A gated read becomes a conditional branch: one path reads the image, the other supplies the fallback. A **phi** joins those paths by selecting the value produced on the path actually taken. The ABI is the calling contract between compiled code and runtime, including image argument order. Getting that order wrong makes the kernel read the wrong resource even if its arithmetic is correct.

## Kernel fusion exercise: packed matmul → matmul + residual

Use the upstream [image half residual tests](../../../tinygrad/test/null/test_schedule.py#L607) as a concrete scheduling question. The first constructs:

```
a = relu(x @ y)
out = relu(a @ z) + a
# float input tensors, FLOAT16=1, OPENPILOT_HACKS=1, IMAGE=1
```

Its expected compiled kernel count is **5**. The larger residual block with two output heads expects **9**. These are source assertions for their exact test setup, not measured GPU counts in this chapter. They are useful precisely because two matmuls plus an add do not describe the actual kernel boundaries: packing/materialization and reuse must be accounted for. Never assume a reduction's consumer is fused because its elementwise add can be combined algebraically.

Worked investigation: locate both packed copies created by `image_conv2d`; follow `found_after`'s map from an unpacked value to its materialized packed representation; inspect whether the residual path reads that stored value or recomputes its producer; then count scheduled calls **before** looking at image load counts. Image promotion happens after the scheduler chose kernel boundaries, so `pm_simplify_add_image` itself does not fuse these kernels.

Further exercises with answers:

1. **Why keep a mask for y<10 on a height-20 image?** Rows 10–19 contain valid data. Removing it replaces required zero with unrelated values.
2. **Can four aligned lanes with four different masks become one image load?** Not with the current grouping contract. Restructure validity or retain ordinary memory accesses; the upcast heuristic checks this early.
3. **Does moving `contiguous()` across a residual edge preserve kernel count and rounding?** No general guarantee. It changes materialization/reuse opportunities and, with half packing, an observable rounding point. Compare scheduled CALL/buffer dependencies and a numerical reference.
4. **Would native AMD use IMAGE after setting the flag?** Late promotion rejects device `AMD`. CL on AMD hardware follows CL's path if its runtime provides alignment support.
5. **Which candidate layout wins for the probe's 256 pixels and no mask?** `(1,256)`: y simplifies to zero, winning the y-expression complexity tie breaker.

## Reproduce the checked portion

From `/home/boop/tenstorrent`, using its existing virtual environment:

```
.venv/bin/python boop-docs/compiler-maps/tinygrad/probe-image-matchers.py --tinygrad tinygrad
DEV=NULL .venv/bin/python -m pytest tinygrad/test/null/test_simplify_valid_idx.py -q -n12
```

Observed test result: **40 passed, 1 xfailed**. The expected failure remains
visible; it is not counted as a passing case.

[Probe output](image-matcher-probes.json) records six successful groups: coalescing/promotion, different lane masks, two image-bound mask cases, cast folding, and layout eligibility. The probe uses UOps and a plain `Renderer(Target(...))`; it does not initialize CL, QCOM, AMD, or Mesa. Existing validity tests additionally exercise convolution/openpilot-derived symbolic cases. This validates matcher behavior and host reference semantics, not hardware execution, throughput, descriptor correctness, or a full image RMSNorm/matmul numerical pipeline.
