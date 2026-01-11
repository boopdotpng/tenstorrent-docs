# SFPI / SFPU programming notes

This document summarizes the SFPI repo layout, how to write SFPU code with SFPI, how it plugs into TT-Metal kernels, how to build the toolchain, and what ops are available. It is based on the docs and headers in this repo.

## Repo structure

- `include/`: Public SFPI headers. `include/sfpi.h` is the main C++ API. `include/*/sfpi_lib.h` adds math helpers, and `include/sfpi_fp16.h` provides fp16 helpers.
- `include/wormhole/`, `include/blackhole/`: Arch-specific constants and implementations.
- `gcc/`, `binutils/`, `newlib/`, `riscv-dejagnu/`: Toolchain components (submodules) used to build the SFPI compiler.
- `scripts/`: Build/test/release scripts. `scripts/build.sh` is the normal entry point.
- `tests/`: SFPI compiler tests and golden assembly. `tests/blackhole/sfpi/*.cc` are good usage examples.
- `build/`: Default build output directory (created by `scripts/build.sh`).

## Build and test

From `README.md`:

- Build toolchain:
  ```bash
  git clone git@github.com:tenstorrent/sfpi.git
  git submodule update --init --recursive
  scripts/build.sh
  ```

- Build/run SFPI tests:
  ```bash
  ln -s ../tests build
  CC_PATH=$(pwd)/build/sfpi/compiler make -C build/tests all
  CC_PATH=$(pwd)/build/sfpi/compiler make -C build/tests test
  ```

- Run toolchain tests:
  ```bash
  scripts/build.sh --test
  scripts/build.sh --test-binutils
  scripts/build.sh --test-gcc
  scripts/build.sh --test-tt
  ```

## SFPI API structure (how to write SFPU code)

SFPI is a C++ wrapper over TT-specific GCC builtins. You write idiomatic C++ that the compiler lowers to SFPU instructions. The API is mostly in `include/sfpi.h`.

### Core types

- `vFloat`, `vInt`, `vUInt`: local-register (LREG) vector types. Operators are overloaded for arithmetic, bitwise, and comparisons.
- `dst_reg`: destination register file (`__DestReg`). It is an array-like interface: `dst_reg[0]`, `dst_reg++`, `dst_reg += N`.
- `l_reg`: LREG file access (`__LReg`) indexed by `LRegs` enums.
- `s2vFloat16`, `s2vFloat16a`, `s2vFloat16b`: immediate fp16 constants (use when loading fp16 constants, or for conversions).
- Constant registers: `vConst0`, `vConst1`, `vConstNeg1`, `vConstTileId`, `vConstFloatPrgm0..2`, `vConstIntPrgm0..2`, plus a few fixed constants like `vConst0p8373` (see `include/*/sfpi_imp.h`).

### Predication

- `__vCCCtrl` and macros provide predication via condition codes:
  - `v_if(...)`, `v_elseif(...)`, `v_else`, `v_endif`
  - `v_block`, `v_and(...)`, `v_endblock` for boolean trees
- Comparisons (`==`, `!=`, `<`, `<=`, `>`, `>=`) return a `__vCond` used in these predicates.
- Boolean `&&`/`||` are supported but only to limited depth (3 levels), per `sfpi.h` notes.

### Important constraints (from `sfpi.h`)

- Compile with optimization enabled (`-O`). The wrappers rely on inlining and keeping vectors off the stack.
- Assignments inside predicates require care; SFPI uses `sfpassign_lv` to preserve liveness.
- Boolean trees are limited to three levels in a single conditional.

## SFPU ops: what is available

These are the main ops exposed by `sfpi.h` (operators) and `sfpi_lib.h` (functional helpers). The list is the union of Wormhole and Blackhole implementations.

### Arithmetic and comparisons

- `vFloat` arithmetic: `+`, `-`, unary `-`, `*`, `+=`, `-=`, `*=`
- `vInt`/`vUInt` arithmetic: `+`, `-`, `+=`, `-=`, `add/sub` with immediate
- Comparisons for `vFloat`, `vInt`, `vUInt`: `==`, `!=`, `<`, `<=`, `>`, `>=`

### Bitwise and shifts

- Bitwise: `&`, `|`, `^`, `~` for `vInt`/`vUInt`
- Shifts:
  - Wormhole: `vInt <<`, `vUInt <<`, `vUInt >>` (from `sfpi.h`)
  - Blackhole: `shft(vUInt, vInt/int)` and `shft(vInt, vInt/int)` (logical vs arithmetic)

### Float exponent/mantissa and sign

- `exexp`, `exexp_nodebias`: extract exponent
- `exman8`, `exman9`: extract mantissa
- `setexp`, `setman`: set exponent/mantissa (immediate or vector)
- `addexp`: add to exponent (divide/multiply by powers of two)
- `setsgn`: set sign from immediate or vector
- `lz`, `lz_nosgn`: leading-zero count
- `abs` for `vFloat` and `vInt`

### LUT-based math

- `lut`, `lut_sign`: 3-entry LUT
- `lut2`, `lut2_sign`: 3-entry or 6-entry LUT variants

### Conversions

- `int32_to_float`
- `float_to_fp16a`, `float_to_fp16b`
- `float_to_uint8`, `float_to_int8`
- `float_to_uint16`, `float_to_int16`
- `int32_to_uint8`, `int32_to_int8` (with descale)
- `reinterpret<T>`: bit reinterpret between vector types

### Vector utility ops

- `subvec_transp`: 4-way subvector transpose
- `subvec_shflror1`, `subvec_shflshr1`: subvector shifts
- `vec_swap`, `vec_min_max`: swap or min/max pairing

### Blackhole-only helpers

- `rand()`: pseudo-random value from SFPU config register
- `approx_recip`, `approx_exp`: approximate reciprocal/exp

## What SFPU code looks like (example)

This is a trimmed, idiomatic SFPI example based on `tests/blackhole/sfpi/ckernel.cc`:

```cpp
#include <sfpi.h>

using namespace sfpi;

sfpi_inline void relu_and_scale() {
  #pragma GCC unroll 8
  for (int d = 0; d < 8; d++) {
    vFloat v = dst_reg[0];

    v_if (v < 0.0f) {
      v = vConst0;
    }
    v_endif;

    dst_reg[0] = v * s2vFloat16b(0.5f);
    dst_reg++;
  }
}
```

Key patterns:

- Load from `dst_reg[n]` into a `vFloat` or `vInt`.
- Use `v_if`/`v_endif` for predicated execution; comparisons create condition codes.
- Write back to `dst_reg[n]`, then advance with `dst_reg++`.
- Use `s2vFloat16a/b` to load fp16 immediates and keep code generation efficient.

## Embedding SFPI into TT-Metal kernels

This repo does not include TT-Metal itself, but the integration pattern is visible in the SFPI headers and kernel tests:

1. Write SFPU code in a TT-Metal compute kernel source file compiled with the SFPI toolchain. Include `sfpi.h`, and in many cases include `ckernel_ops.h` first so `ckernel::instrn_buffer` exists (required by `include/*/sfpi_hw.h`).
2. Use `dst_reg` and `l_reg` to read/write SFPU registers. These registers represent the active tile row/column in the SFPU pipeline.
3. Use predicates (`v_if`, `v_elseif`, `v_else`) for per-lane masking; avoid deep boolean trees.
4. Build via TT-Metal’s kernel build flow, which should already invoke the SFPI compiler for SFPU code.
5. For more details on the runtime plumbing and kernel API, refer to the upstream TT-Metal SFPU doc linked in `README.md`:
   https://docs.tenstorrent.com/tt-metalium/latest/tt_metal/apis/kernel_apis/sfpu/llk.html

## Other docs in this repo

- `README.md`: SFPI build/release steps and test invocations.
- `README-riscv.md`: General RISC-V toolchain build info (upstream, not SFPU-specific).
- `riscv-dejagnu/*/README`: DejaGnu harness notes used by toolchain testing.
