# UOp Reference (from `extra/amdgpu_uops_report.md`)

This describes only the UOps that actually appear in `extra/amdgpu_uops_report.md` (post-opt, post-linearize),
and what they typically lower to in C/HIP-style GPU code (as implemented by `AMDHIPRenderer` in
`tinygrad/renderer/cstyle.py`).

At this stage:
- The input list is *linearized*: it’s already ordered “as code”.
- Many UOps are emitted as SSA-ish expressions; others become statements (`for`, `if`, stores, declarations).
- Pointer-typed dtypes like `dtypes.float.ptr(12)` mean “pointer to float” with a known element-count annotation
  (used by codegen/opts; it’s still just a pointer in emitted code).

## Buffer / lifetime / scheduling

### `Ops.DEFINE_GLOBAL`
- Meaning: a kernel argument that points at an already-allocated device buffer (global memory).
- Lowers to: a parameter like `float* data0` (name derived from `arg`).
- Note: stores mark that buffer as “mutable” so the signature becomes writable.

### `Ops.DEFINE_REG`
- Meaning: a fixed-size register array used as an accumulator / scratch (address space “REG”).
- Lowers to: a local array declaration, e.g. `float acc0[8];` (renderer emits an array).

### `Ops.AFTER`
- Meaning: “same value as src, but with an ordering edge” (used to preserve dependencies/scheduling constraints).
- Lowers to: nothing; renderer aliases it (`r[after] = r[src]`).

### `Ops.GROUP`
- Meaning: grouping marker in the linear stream.
- Lowers to: nothing; skipped by the C-style renderer.

### `Ops.SINK`
- Meaning: terminator carrying `KernelInfo` (name, applied opts, etc).
- Lowers to: nothing; renderer reads metadata from it.

## Work-item / loops / control flow

### `Ops.SPECIAL`
- Meaning: built-in IDs (group/local/global) and related launch info, used to index work.
- Lowers (AMDHIPRenderer):
  - `lidx*`: `__ockl_get_local_id(dim)`
  - `gidx*`: `__ockl_get_group_id(dim)`
  - `iidx*`: `(__ockl_get_group_id(dim)*__ockl_get_local_size(dim)+__ockl_get_local_id(dim))`
- Note: renderer also emits a comment with the symbolic range.

### `Ops.RANGE`
- Meaning: a loop induction variable over `[0, extent)`.
- Lowers to: `for (int ridx... = 0; ridx... < extent; ridx...++) {`

### `Ops.END`
- Meaning: end of a `RANGE` loop.
- Lowers to: `}`.

### `Ops.IF`
- Meaning: structured conditional block (often introduced by gated-store lowering).
- Lowers to: `if (cond) {`

### `Ops.ENDIF`
- Meaning: end of an `IF` block.
- Lowers to: `}`.

## Addressing + memory

### `Ops.INDEX`
- Meaning: pointer arithmetic: base pointer + element offset (optionally carries a “gate”/predicate for masked accesses).
- Lowers to: `(base + idx)` (with some parenthesis stripping for nice code).

### `Ops.LOAD`
- Meaning: read from a pointer.
- Lowers to:
  - ungated: `(*ptr)`
  - gated form (when `INDEX` includes a predicate and a fallback value is provided): `(gate ? *ptr : fallback)`
- Note: this gated `LOAD` is how tinygrad often avoids branching for masked/out-of-bounds reads.

### `Ops.STORE`
- Meaning: write to a pointer.
- Lowers to: `*ptr = value;`
- Note: a gated `STORE` is turned into `IF; STORE; ENDIF` during linearize cleanups (so the store itself is unconditional inside the `if`).

### `Ops.GEP`
- Meaning: “get element pointer / extract lane” from a vector or vector-like value (index given by `arg[0]`).
- Lowers to:
  - small vectors: `.x/.y/.z/.w/...` lane access
  - larger vectors: `[lane]` array indexing

## Types + packing

### `Ops.CONST`
- Meaning: compile-time constant literal.
- Lowers to: a literal in the generated code, with dtype-aware formatting:
  - floats: `1.0f` (or casted for half/bf16/fp8)
  - ints/uints: `123`, `123u`, `123ll`, etc
  - non-finite: `INFINITY`, `NAN` (AMD renderer emits defines if needed)

### `Ops.CAST`
- Meaning: value cast (or pointer cast if the dtype is a pointer type).
- Lowers to:
  - vector cast: `__builtin_convertvector(x, vec_type)` when applicable
  - general: `(target_type)(x)`

### `Ops.BITCAST`
- Meaning: reinterpret bits without changing the bit-pattern.
- Lowers to: `__builtin_bit_cast(target_type, (src_type)(x))`.

### `Ops.VECTORIZE`
- Meaning: pack multiple scalars into a vector type (used for upcasts like float4).
- Lowers (AMDHIPRenderer): `make_float4({a,b,c,d})`-style constructor (type depends on dtype/count).

## ALU / compares / bitwise

### `Ops.ADD`, `Ops.SUB`, `Ops.MUL`, `Ops.NEG`
- Meaning: arithmetic.
- Lowers to: `+`, `-`, `*`, unary `-` (with parentheses added by renderer).

### `Ops.CMPLT`
- Meaning: compare `<` producing a bool.
- Lowers to: `(a < b)`.

### `Ops.WHERE`
- Meaning: select/ternary (predicate, true_value, false_value).
- Lowers to: `(pred ? a : b)`.

### `Ops.AND`, `Ops.OR`, `Ops.XOR`
- Meaning: bitwise ops.
- Lowers to: `&`, `|`, `^`.

### `Ops.SHL`, `Ops.SHR`
- Meaning: bit shifts.
- Lowers to: `<<`, `>>`.

## Math intrinsics

### `Ops.EXP2`, `Ops.LOG2`, `Ops.SIN`, `Ops.SQRT`
- Meaning: transcendental/math ops on floats.
- Lowers (AMDHIPRenderer): `__ocml_*` intrinsics with bitwidth based on dtype (f16/f32/f64), e.g. `__ocml_sqrt_f32(x)`.

## Tensor cores

### `Ops.WMMA`
- Meaning: a warp/wave matrix-multiply-accumulate “tile” op on packed fragments (the TC path).
- Lowers (AMDHIPRenderer):
  - a call to an auto-emitted helper like `__WMMA_16_16_16_half_float(a, b, c)` (helper generation depends on the specific `WMMA` variant).
- Note: this is the main “special” op you’d decide how to map on Tenstorrent (either emulate, lower to a different
  matmul path, or introduce a device-specific instruction).
