# Pack/unpack/tilize/untilize walkthrough (Blackhole)

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
