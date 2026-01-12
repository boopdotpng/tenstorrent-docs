# TT-LLK + SFPI programming model

This note explains what TT-LLK is, how TT-Metal kernels invoke it today, and gives a short SFPI model overview.

## What is TT-LLK?

TT-LLK (low-level kernels) is the thin, architecture-specific layer that exposes SFPU/FPU primitives, packing/unpacking helpers, and related math operations used inside compute kernels. It lives under `tt_metal/hw/ckernels/<arch>/metal/llk_api` and is implemented as `inline` C++ functions that emit the SFPU instruction sequences for the target architecture.

## How TT-LLK is called from TT-Metal kernels

Most compute kernels use the `compute_kernel_api` wrappers (for example, `add_unary_tile`). Those wrappers expand to TT-LLK calls such as `llk_math_eltwise_unary_sfpu_binop_with_scalar`. The call chain is typically:

1) Kernel calls a `compute_kernel_api` helper.
2) The helper expands (inline) to an LLK call.
3) The LLK call emits SFPU instructions or configures the SFPU pipeline.

You can bypass the wrapper and call LLK directly, but you are still using TT-LLK. To go lower than LLK, you need custom SFPI code (custom SFPU instruction sequences).

## Example call chains

### Wrapper -> LLK

This is the style used in many TT-Metal compute kernels (wrapper call):

```cpp
#include "compute_kernel_api/eltwise_unary/binop_with_scalar.h"

// ...
binop_with_scalar_tile_init();
add_unary_tile(/*idst=*/0, scalar_bits);
```

The wrapper expands to LLK (simplified), which lives under `tt_metal/hw/ckernels/<arch>/metal/llk_api`:

```cpp
#include "llk_math_eltwise_unary_sfpu_binop_with_scalar.h"

// ...
llk_math_eltwise_unary_sfpu_binop_with_scalar_init<APPROX>();
MATH((llk_math_eltwise_unary_sfpu_binop_with_scalar<APPROX, ADD_UNARY>(0, scalar_bits)));
```

### SFPI custom op (no LLK wrapper)

Custom SFPI code runs inside a compute kernel and operates on SFPU vector registers:

```cpp
#include "sfpi.h"

using namespace sfpi;

inline void relu_to_three(uint32_t dst_idx) {
  vFloat x = dst_reg[dst_idx];
  v_if (x < 0.0f) {
    dst_reg[dst_idx] = 3.0f;
  }
  v_endif;
}
```

You would call `relu_to_three(0)` between `copy_tile` (unpack to regs) and `pack_tile` in your compute kernel.

## SFPI programming model (approximate)

SFPI is the C++-like programming interface to the SFPU. It compiles to SFPU vector instructions via a custom GCC toolchain.

Key ideas:
- Vector types: `vFloat`, `vInt`, `vUInt` operate on the SFPU vector lanes (e.g., 32 lanes on WH/BH).
- Registers: `dst_reg[]` and `l_reg[]` access SFPU destination and general-purpose registers.
- Predication: `v_if` / `v_elseif` / `v_else` / `v_endif` implement vector predication. Both sides execute, only enabled lanes write.
- Scalar control flow: normal C++ `if` / `for` runs on the RISC-V side (not predicated).
- Constants: scalar constants expand across vector lanes (e.g., `2.0f` becomes a vector constant).
- Typical flow: unpack a tile into registers, run SFPI ops on `dst_reg`, then pack back to a CB.

When LLK wrappers are missing for an op, the usual path is: implement the op in SFPI, then call it from a compute kernel.

## Notes from the scan (LLK + SFPI)

From the SFPI docs and custom SFPI examples:

- SFPI code runs inside compute kernels and is compiled with the SFPI-enabled toolchain.
- Vector predication is the primary control mechanism for per-lane logic (`v_if`/`v_elseif`/`v_else`/`v_endif`); both sides execute and only enabled lanes write.
- Custom SFPI examples use internal helpers like `_llk_math_eltwise_unary_sfpu_params_`, `_llk_math_eltwise_binary_sfpu_params_`, and `_llk_math_eltwise_ternary_sfpu_params_` to iterate tile faces and pass scalar parameters into SFPI functions.
- The custom SFPI docs call out that those internal helpers are not guaranteed to be stable across releases; keep them up to date when upgrading.

From the LLK headers:

- LLK is split by architecture (`wormhole_b0`, `blackhole`) under `tt_metal/hw/ckernels/<arch>/metal/llk_api`.
- The LLK layer includes families for unary, binary, ternary, reduce, and matmul operations, plus pack/unpack and sync helpers.

From `tt-isa-documentation` (SFPU instruction docs):

- There are per-instruction docs for SFPU/SFPI ops under `tt-isa-documentation/<arch>/TensixTile/TensixCoprocessor`, for example `SFPIADD.md`, `SFPMAD.md`, `SFPSTORE.md`, and `SFPLOADMACRO.md`.
- The ISA docs describe scheduling/latency constraints (e.g., `SFPMAD` hazards and when to insert `SFPNOP`), and how `SFPLOADMACRO` can schedule multiple SFPU sub-unit ops in a single cycle.
