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
