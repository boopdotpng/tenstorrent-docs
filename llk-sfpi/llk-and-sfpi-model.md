# LLK + SFPI model and kernel inventory

This file merges LLK kernel inventory, SFPU vs non-SFPU examples, and the pack/unpack walkthrough.

## TT-LLK + SFPI programming model

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

## TT-LLK kernel inventory and SFPU op catalog

# TT-LLK kernel inventory (repo scan)

This is a quick scan of the TT-LLK repo to summarize what kernel families and SFPU ops are implemented here, with a focus on traditional ML ops vs custom SFPI work.

## Where kernels live

- `tt_llk_blackhole/llk_lib` contains the LLK kernel families.
- SFPU op implementations live under `tt_llk_blackhole/common/inc/sfpu`.

## Core LLK kernel families (Blackhole)

These are the "traditional" compute/data-movement primitives that higher-level ops are built from:

- Matmul: `llk_math_matmul.h`
- Reductions: `llk_math_reduce.h`, `llk_math_reduce_custom.h`
- Elementwise: `llk_math_eltwise_unary_*`, `llk_math_eltwise_binary*`, `llk_math_eltwise_ternary*`
- Welford stats: `llk_math_welfords_sfpu.h`
- Transpose in dest: `llk_math_transpose_dest.h`
- Pack/unpack + layout transforms: `llk_pack*`, `llk_unpack*`, `llk_unpack_tilize.h`, `llk_unpack_untilize.h`, `llk_pack_untilize.h`, `llk_pack_rows.h`

## SFPU op catalog (Blackhole)

There are 54 SFPU op headers under `tt_llk_blackhole/common/inc/sfpu`:

abs, activations, add_int, add_top_row, binary, binary_bitwise, cast_fp32_to_fp16a, cdf, clamp, comp,
converter, cumsum, dropout, elu, ema, exp, exp2, fill, gelu, hardtanh, is_fp16_zero, isinf_isnan,
load_config, log, max, max_int32, max_pool_indices, mul_int, negative, polyval, quant, recip,
reduce, reduce_custom, relu, reshuffle_rows, rounding_ops, rsqrt, rsqrt_compat, shift, sigmoid, sign,
silu, sqrt, square, sub_int, tanh, tanh_derivative, threshold, topk, trigonometry, typecast, welfords, where

These cover most common ML unary/activation functions, compares, typecasts, and a few higher-level ops (topk, where, dropout).

## ML op buckets (Blackhole SFPU)

- Activations: relu, gelu, silu, sigmoid, tanh, tanh_derivative, hardtanh, threshold, activations
- Elementwise math: abs, negative, sign, square, sqrt, rsqrt, rsqrt_compat, recip, exp, exp2, log, trigonometry, cdf, polyval
- Comparisons/select: comp, where
- Reductions and stats: reduce, reduce_custom, max, max_int32, max_pool_indices, topk, welfords, cumsum, ema
- Quantization and type conversion: typecast, cast_fp32_to_fp16a, converter, quant, rounding_ops, shift
- Integer and bitwise ops: add_int, sub_int, mul_int, binary_bitwise
- Utility/data movement: fill, reshuffle_rows, add_top_row, load_config, isinf_isnan, is_fp16_zero, dropout

Common NN ops that map directly or compose from these:

- Softmax: exp + reduce + recip (plus binary ops for scale and normalization)
- LayerNorm/RMSNorm: welfords or reduce + rsqrt + mul/add
- GELU/SILU/Tanh families: native ops in SFPU
- Top-k / argmax-style flows: topk, max, max_pool_indices
- Dropout: dropout
- Type/quant flows: typecast + quant + rounding_ops

## How many “traditional ML ops” are supported?

- Core kernels: matmul, reduce, elementwise (unary/binary/ternary), Welford stats, transpose, plus pack/unpack/tilize/untilize.
- SFPU ops: 54 named SFPU operations on Blackhole.

If your ML op maps to these kernels or can be composed from unary/binary/ternary SFPU ops, you can stay in LLK. If it is not in the SFPU list or needs a new instruction sequence, you will need custom SFPI.

## SFPU vs non-SFPU kernels (Blackhole)

# TT-LLK Blackhole: SFPU vs non-SFPU kernels

This note highlights which LLK kernels are not purely SFPU, gives a trimmed SFPU kernel example, and summarizes how pack/unpack/tilize/untilize work.

## Non-SFPU kernel examples

These use other Tensix engines or datapaths (FPU/matmul, packer/unpacker), not just SFPU.

- Matmul uses the matmul/FPU datapath via `TT_OP_MVMUL` and a replayable MOP loop.
- Pack/unpack/tilize/untilize configure the packer/unpacker engines (THCON), address modifiers, and MOPs to move/transform tiles.

### Matmul (FPU / MVMUL)

From `tt_llk_blackhole/llk_lib/llk_math_matmul.h` (trimmed):

```cpp
ckernel_template tmp(
  outer_loops,
  inner_loops,
  lltt::replay_insn(ckernel::math::replay_buf_offset, replay_buf_len),
  TT_OP_MVMUL(p_setrwc::CLR_NONE, 0, addr_mod_inner_loop, 0));

tmp.program();
...
ckernel_template::run();
```

This is FPU/matmul hardware, not SFPU.

### Pack/unpack/tilize/untilize (packer/unpacker)

From `tt_llk_blackhole/llk_lib/llk_unpack_tilize.h` (trimmed):

```cpp
static constexpr uint unpack_srca =
  TT_OP_UNPACR(SrcA, 0b1, 0, 0, 0, 1, 1, p_unpacr::RAREFYB_DISABLE, 0, 0, 0, 0, 1);
...
unpack_config_u config = {0};
config.f.tileize_mode = 1;
...
TTI_WRCFG(p_gpr_unpack::TMP0, p_cfg::WRCFG_32b, THCON_SEC0_REG2_Out_data_format_ADDR32);
...
_llk_unpack_tilize_mop_config_(narrow_tile, unpack_to_dest);
```

These kernels are mostly about configuring the unpacker/packer hardware and the MOP (memory operation program), not SFPU math.

## SFPU kernel example

From `tt_llk_blackhole/common/inc/sfpu/ckernel_sfpu_relu.h` (trimmed):

```cpp
TTI_SFPLOAD(p_sfpu::LREG0, InstrModLoadStore::DEFAULT, ADDR_MOD_7, 0);
TTI_SFPSETCC(0, p_sfpu::LREG0, 0, 0);
TTI_SFPMUL(p_sfpu::LREG0, p_sfpu::LREG2, p_sfpu::LCONST_0, p_sfpu::LREG0, 0);
TTI_SFPENCC(0, 0, 0, 0);
TTI_SFPSTORE(p_sfpu::LREG0, InstrModLoadStore::DEFAULT, ADDR_MOD_7, 0);
sfpi::dst_reg++;
```

This is a direct SFPU instruction sequence and uses SFPI for vector register iteration.

## How pack/unpack/tilize/untilize work (Blackhole)

High-level flow across these kernels:

- Configure address modifiers for the packer/unpacker so the hardware walks the right tile layout.
- Program THCON config registers (data formats, tilize/untilize mode, row/face dimensions).
- Build the MOP sequence for repeated unpack/pack operations.
- Set base addresses and kick the hardware for each tile, optionally unpacking to dest registers for int32 formats.

Key entry points:

- Unpack: `tt_llk_blackhole/llk_lib/llk_unpack_A.h`, `tt_llk_blackhole/llk_lib/llk_unpack_AB.h`
- Tilize: `tt_llk_blackhole/llk_lib/llk_unpack_tilize.h`
- Untilize: `tt_llk_blackhole/llk_lib/llk_unpack_untilize.h`, `tt_llk_blackhole/llk_lib/llk_pack_untilize.h`
- Pack: `tt_llk_blackhole/llk_lib/llk_pack.h`, `tt_llk_blackhole/llk_lib/llk_pack_rows.h`

If you need a new tensor layout transform, it usually means adjusting these address mods and MOP loops rather than writing SFPI.

## Pack/unpack/tilize/untilize walkthrough

****# Pack/unpack/tilize/untilize walkthrough (Blackhole)

This is a deeper explanation of what the LLK pack/unpack kernels actually do on Blackhole. These are datapath + control-plane kernels for the packer/unpacker engines, not SFPI math.

## Mental model

The packer/unpacker engines move data between memory/circular buffers and the math destination registers. The LLK code:

- Programs THCON config registers (format, layout, tileize/untilize mode).
- Sets address modifiers so hardware walks rows/faces correctly.
- Builds a MOP (memory operation program) that is replayed for each tile.
- Kicks the engine per tile by setting base addresses and semaphores.

In a typical kernel, the flow is:

1) Unpack into src or dest regs.
2) Math (SFPU/FPU) reads/writes dst regs.
3) Pack results back out.

## Unpack (A / AB)

Entry points:

- `tt_llk_blackhole/llk_lib/llk_unpack_A.h`
- `tt_llk_blackhole/llk_lib/llk_unpack_AB.h`

Key pieces:

- `*_configure_addrmod_` sets `ADDR_MOD_*` to match face strides.
- `*_mop_config_` builds a replayable MOP for the unpack sequence.
- `*_init_` programs THCON (formats, throttle, tile dimensions).
- `*_()` sets base addresses and posts semaphores for the unpacker to run.

Unpack uses `TT_OP_UNPACR` or `TT_OP_UNPACR_NOP` instructions to configure the hardware sequence, for example:

```cpp
static constexpr uint unpack_srca =
  TT_OP_UNPACR(SrcA, 0b1, 0, 0, 0, 1, 1, p_unpacr::RAREFYB_DISABLE, 0, 0, 0, 0, 1);
```

## Tilize (linear -> tile layout)

Entry point:

- `tt_llk_blackhole/llk_lib/llk_unpack_tilize.h`

Tilize uses the unpacker in "tileize" mode. It configures THCON so a linear buffer is reinterpreted as a 32x32 tile, sets tile dimensions to cover the full tile, and runs a MOP that emits the tile.

Key steps:

- Enable `tileize_mode` in the unpack config.
- Force `Tile_x_dim` to 1024 so a whole tile is covered without face iteration.
- Program `TTI_SETADCXX` to set x-dimension endpoints.
- Run `_llk_unpack_tilize_mop_config_` to build the MOP sequence.

## Untilize (tile layout -> linear)

Entry points:

- `tt_llk_blackhole/llk_lib/llk_unpack_untilize.h`
- `tt_llk_blackhole/llk_lib/llk_pack_untilize.h`

Untilize is the inverse of tilize: it walks faces/rows in tile order and writes out linear rows. This is mostly packer/unpacker configuration plus address-mod math:

- Address mods switch to row-based stride.
- The MOP sequences step through rows, not faces.
- The packer can read from dest regs with a stride of 16 (see `llk_math_common.h`).

## Pack (tile -> memory/CB)

Entry points:

- `tt_llk_blackhole/llk_lib/llk_pack.h`
- `tt_llk_blackhole/llk_lib/llk_pack_rows.h`

Pack configures the packer engine to read from dest regs and emit tiles. It uses:

- `*_configure_addrmod_` to control row/face stepping.
- `*_mop_config_` to program the packer sequence.
- `*_init_` to set format and face dims.
- `*_()` to run pack on a tile address.

Pack also includes helpers for synchronization with the math engine:

- `_llk_packer_wait_for_math_done_()` and `_llk_packer_set_math_semaphore_()` gate the pipeline so math and pack stages stay ordered.

## Why this is not SFPI

SFPI is for per-lane math on the SFPU vector regs. Pack/unpack/tilize/untilize are about:

- Engine configuration (THCON regs)
- Address modifier tables
- MOP instruction sequences
- Tile and face iteration

So when you need a new layout transform or a different tilize/untilize behavior, you usually change these LLK pack/unpack kernels rather than writing SFPI.
