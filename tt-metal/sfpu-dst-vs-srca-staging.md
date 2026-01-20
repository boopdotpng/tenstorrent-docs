# SFPU/SFPI: `Dst` math vs `SrcA` staging (common confusion)

When you write SFPI like:

```cpp
sfpi::dst_reg[v] = sfpi::dst_reg[v] + 1.0f;
```

the SFPU is operating on `Dst` via `SFPLOAD`/`SFPSTORE` (moving vectors between `Dst` and `LReg`, then writing back to `Dst`). In that sense, SFPI “reads/writes `Dst`”, not `SrcA`/`SrcB`.

However, many TT-Metal kernels still use `SrcA` as an intermediate on the *data-movement* path that feeds `Dst`:

- `copy_tile(...)` is implemented as an UNPACK step (`llk_unpack_A...`) plus a MATH datacopy (`llk_math_eltwise_unary_datacopy...`) that lands in `Dst`.
- For fp16/bf16 tile inputs, the LLK unpack path commonly stages through `SrcA` (the unpacker programs SrcA/SrcB base addresses and unpacks into that register file).
- The “unpack directly to `Dst`” path (`unpack_to_dest`) is a special-case used for 32-bit inputs (`is_32bit_input(...)`), not the default for fp16/bf16.

Concrete references:

- `tt-metal/tt_metal/include/compute_kernel_api/tile_move_copy.h` (`copy_tile` expands to `llk_unpack_A...` + `llk_math_eltwise_unary_datacopy...`).
- Blackhole/Wormhole LLK unpack implementation:
  - `tt-metal/tt_metal/third_party/tt_llk/tt_llk_blackhole/llk_lib/llk_unpack_A.h`
  - `tt-metal/tt_metal/third_party/tt_llk/tt_llk_wormhole_b0/llk_lib/llk_unpack_A.h`

Rule of thumb:

- SFPI/SFPU math: `Dst`  `LReg`  `Dst`.
- Feeding `Dst` from CB memory (fp16/bf16): often CB  unpack  `SrcA`  math-datacopy  `Dst`.
