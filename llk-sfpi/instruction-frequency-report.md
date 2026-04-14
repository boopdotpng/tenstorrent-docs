# Blackhole Instruction Frequency Report

**Date:** 2026-04-14
**Source:** 747 kernel ELFs from `~/.cache/tt-metal-cache/` (785,936 lines of disassembly)
**Workloads:** 20 C++ programming examples, 60+ ttnn Python ops (including niche: gcd, lcm,
bitwise ops, erfinv, i0, cbrt, etc.), manual transformer decoder block (layernorm, QKV matmul,
softmax, attention, FFN+GELU, RMSNorm, embedding, concat)
**Method:** Disassembled with `riscv-tt-elf-objdump -d`, counted inline TTINSN mnemonics +
traced `sw` stores to `INSTRN_BUF_BASE (0xFFE40000)` for dynamically-pushed Tensix instructions.

## Key Findings

- **141 of 243 instructions in dsl.py are used** in real Blackhole workloads
- **102 instructions are NOT seen** in any disassembly
- **9 instructions marked `# rare` are actually used** (mislabeled) -- fix these
- **10 instructions are dead on BH** (neutered, no-op, or non-functional) -- safe to delete
- **All Zaamo atomics (9 instructions) are unused** -- Tensix uses semaphores instead
- **All legacy conv/pool instructions (7) are dead on BH** -- neutered to Dst+=0

## Instructions Marked Rare But Actually Used (FIX THESE)

| Instruction | Count | How Used | dsl.py Line |
|---|---|---|---|
| `TT_RMWCIB0` | 294 | sw to FIFO (firmware config) | 253 |
| `TT_RMWCIB1` | 13 | sw to FIFO (firmware config) | 254 |
| `TT_SETADC` | 6 | sw to FIFO | 422 |
| `TT_MOVD2A` | 4 | inline TTINSN | 359 |
| `TT_SFPXOR` | 18 | inline TTINSN (bitwise ops) | 548 |
| `TT_SFPOR` | 36 | inline TTINSN (gcd/bitwise) | 517 |
| `TT_SFPLZ` | 12 | inline TTINSN (gcd/lcm) | 521 |
| `TT_SFPMUL24` | 4 | inline TTINSN (gcd/lcm) | 578 |
| `TT_SFPGT` | 16 | inline TTINSN (gcd/lcm) | 575 |

These should be uncommented and marked active in dsl.py.

## RISC-V Instructions

### Used (67 instructions)

| Instruction | Count | Category |
|---|---|---|
| `SW` | 52963 | Load/Store |
| `LW` | 34127 | Load/Store |
| `ADDI` | 29844 | ALU |
| `LUI` | 21154 | ALU |
| `ADD` | 12498 | ALU |
| `LI` | 10294 | Pseudo |
| `MV` | 7034 | Pseudo |
| `SLLI` | 6214 | ALU |
| `SUB` | 4739 | ALU |
| `BNE` | 4148 | Branch |
| `AND` | 3420 | ALU |
| `BNEZ` | 2858 | Branch |
| `SRLI` | 2471 | ALU |
| `LBU` | 2429 | Load/Store |
| `BEQ` | 2366 | Branch |
| `BLTU` | 2361 | Branch |
| `J` | 2048 | Jump |
| `ZEXT_H` | 1932 | Zbb |
| `OR` | 1920 | ALU |
| `BGEU` | 1760 | Branch |
| `FENCE` | 1799 | System |
| `BEQZ` | 1480 | Branch |
| `LHU` | 1093 | Load/Store |
| `SH2ADD` | 963 | Zba |
| `SLTU` | 866 | ALU |
| `ANDI` | 832 | ALU |
| `MUL` | 732 | M ext |
| `SH1ADD` | 659 | Zba |
| `RET` | 657 | Jump |
| `BLT` | 600 | Branch |
| `SH` | 535 | Load/Store |
| `SRAI` | 528 | ALU |
| `SNEZ` | 494 | Pseudo |
| `BGE` | 471 | Branch |
| `BLEZ` | 464 | Branch |
| `JAL` | 348 | Jump |
| `ZEXT_B` | 303 | Pseudo |
| `MULHU` | 284 | M ext |
| `MINU` | 195 | Zbb |
| `SH3ADD` | 169 | Zba |
| `SB` | 149 | Load/Store |
| `XORI` | 142 | ALU |
| `SEQZ` | 105 | Pseudo |
| `REMU` | 97 | M ext |
| `DIVU` | 95 | M ext |
| `NEG` | 71 | Pseudo |
| `BLTZ` | 57 | Branch |
| `ORI` | 53 | ALU |
| `SLL` | 48 | ALU |
| `BGTZ` | 47 | Branch |
| `SLTIU` | 18 | ALU |
| `SRL` | 18 | ALU |
| `CSRRS` | 18 | Zicsr |
| `MAXU` | 12 | Zbb |
| `XOR` | 12 | ALU |
| `AUIPC` | 10 | ALU |
| `BGEZ` | 9 | Branch |
| `CSRRC` | 9 | Zicsr |
| `NOT` | 7 | Pseudo |
| `SEXT_H` | 6 | Zbb |
| `JALR` | 6 | Jump |
| `JR` | 17 | Jump |
| `MIN` | 4 | Zbb |
| `SLT` | 4 | ALU |
| `CTZ` | 3 | Zbb |

### Not Used -- Candidates to Delete

| Instruction | Status in dsl.py | Line | Notes |
|---|---|---|---|
| `NOP` | active | 140 | Disassembler shows as `addi zero,zero,0` -- keep for API |
| `SEXT_B` | active | 123 | Likely decoded as different mnemonic by objdump -- keep |
| `SRA` | rare | 58 | |
| `SLTI` | rare | 61 | |
| `LB` | rare | 66 | |
| `LH` | rare | 66 | |
| `SGTZ` | rare | 147 | |
| `SLTZ` | rare | 148 | |
| `CALL` | rare | 158 | |
| `ECALL` | rare | 74 | |
| `EBREAK` | rare | 75 | |
| `CSRRW` | rare | 78 | |
| `CSRRWI` | rare | 81 | |
| `CSRRSI` | rare | 82 | |
| `CSRRCI` | rare | 83 | |
| `MULH` | rare | 87 | |
| `MULHSU` | rare | 88 | |
| `DIV` | rare | 90 | |
| `REM` | rare | 92 | |
| `MAX` | rare | 115 | |
| `ANDN` | rare | 113 | |
| `ORN` | rare | 113 | |
| `XNOR` | rare | 114 | |
| `ROL` | rare | 118 | |
| `ROR` | rare | 118 | |
| `RORI` | rare | 119 | |
| `CLZ` | rare | 120 | |
| `CPOP` | rare | 122 | |
| `REV8` | rare | 126 | |
| `ORC_B` | rare | 127 | |
| `PACK` | rare | 128 | |
| `BREV8` | rare | 129 | |
| `GREVI` | rare | 130 | |
| All 9 `AMO*_W` | rare | 97-105 | Tensix uses semaphores, never emits atomics |

## Tensix Coprocessor Instructions

### Used (46 instructions)

| Instruction | Inline | FIFO sw | Total | Category |
|---|---|---|---|---|
| `TT_SETC16` | 5966 | - | 5966 | Config |
| `TT_STALLWAIT` | 3561 | - | 3561 | Sync |
| `TT_MOP` | 2247 | - | 2247 | Flow Control |
| `TT_SETRWC` | 1887 | - | 1887 | RWC |
| `TT_WRCFG` | 1574 | - | 1574 | Config |
| `TT_MVMUL` | 1521 | - | 1521 | Matrix/FPU |
| `TT_DMANOP` | 1344 | - | 1344 | Scalar/DMA |
| `TT_NOP` | 1049 | - | 1049 | Flow Control |
| `TT_SETADCZW` | 1092 | - | 1092 | ADC |
| `TT_SEMGET` | 676 | - | 676 | Sync |
| `TT_SEMWAIT` | 570 | - | 570 | Sync |
| `TT_SETADCXX` | 519 | - | 519 | ADC |
| `TT_REPLAY` | 484 | - | 484 | Flow Control |
| `TT_SETDMAREG` | 364 | 38 | 402 | Scalar/DMA |
| `TT_SEMPOST` | 311 | - | 311 | Sync |
| `TT_UNPACR` | 271 | - | 271 | Pack/Unpack |
| `TT_MOVD2B` | 232 | - | 232 | Data Move |
| `TT_SETADCXY` | 208 | - | 208 | ADC |
| `TT_MOVB2D` | 197 | - | 197 | Data Move |
| `TT_RMWCIB0` | - | 181 | 181 | Config |
| `TT_RDCFG` | 152 | - | 152 | Config |
| `TT_ATGETM` | 169 | - | 169 | Sync |
| `TT_ATRELM` | 169 | - | 169 | Sync |
| `TT_ADDDMAREG` | 147 | - | 147 | Scalar/DMA |
| `TT_ZEROSRC` | 147 | - | 147 | Data Move |
| `TT_ELWADD` | 140 | - | 140 | Matrix/FPU |
| `TT_INCRWC` | 136 | - | 136 | RWC |
| `TT_TRNSPSRCB` | 122 | - | 122 | Data Move |
| `TT_CLEARDVALID` | 89 | - | 89 | Data Move |
| `TT_SEMINIT` | 82 | - | 82 | Sync |
| `TT_PACR` | 82 | - | 82 | Pack/Unpack |
| `TT_ZEROACC` | 76 | 3 | 79 | Data Move |
| `TT_INCADCZW` | 26 | - | 26 | ADC |
| `TT_GMPOOL` | 20 | - | 20 | Matrix/FPU |
| `TT_UNPACR_NOP` | 12 | - | 12 | Pack/Unpack |
| `TT_RMWCIB1` | - | 13 | 13 | Config |
| `TT_SETADC` | - | 6 | 6 | ADC |
| `TT_MULDMAREG` | 2 | - | 2 | Scalar/DMA |

### Used SFPU Instructions (34 instructions)

| Instruction | Inline | FIFO sw | Total |
|---|---|---|---|
| `TT_SFPLOADI` | 403 | 1 | 404 |
| `TT_SFPNOP` | 309 | - | 309 |
| `TT_SFPMAD` | 249 | - | 249 |
| `TT_SFPSETCC` | 188 | - | 188 |
| `TT_SFPENCC` | 184 | - | 184 |
| `TT_SFPSTORE` | 163 | - | 163 |
| `TT_SFPMUL` | 133 | - | 133 |
| `TT_SFPCONFIG` | 104 | - | 104 |
| `TT_SFPSHFT2` | 103 | - | 103 |
| `TT_SFPLOAD` | 100 | - | 100 |
| `TT_SFPMOV` | 89 | - | 89 |
| `TT_SFPIADD` | 88 | - | 88 |
| `TT_SFPSTOCHRND` | 84 | - | 84 |
| `TT_SFPLOADMACRO` | 57 | 3 | 60 |
| `TT_SFPCOMPC` | 58 | - | 58 |
| `TT_SFPSETEXP` | 55 | - | 55 |
| `TT_SFPEXEXP` | 48 | - | 48 |
| `TT_SFPADDI` | 41 | 3 | 44 |
| `TT_SFPPOPC` | 40 | - | 40 |
| `TT_SFPSHFT` | 39 | - | 39 |
| `TT_SFPADD` | 38 | - | 38 |
| `TT_SFPSWAP` | 36 | - | 36 |
| `TT_SFPCAST` | 29 | - | 29 |
| `TT_SFPPUSHC` | 29 | - | 29 |
| `TT_SFPSETSGN` | 29 | - | 29 |
| `TT_SFPEXMAN` | 28 | - | 28 |
| `TT_SFPARECIP` | 13 | - | 13 |
| `TT_SFPAND` | 12 | - | 12 |
| `TT_SFPABS` | 9 | - | 9 |
| `TT_SFPDIVP2` | 8 | - | 8 |
| `TT_SFPLUTFP32` | 8 | - | 8 |
| `TT_SFPMULI` | 4 | - | 4 |
| `TT_SFPNOT` | 3 | - | 3 |
| `TT_SFPXOR` | 2 | - | 2 |

### Not Used Tensix/SFPU -- Candidates to Delete

**Dead on BH (safe to delete -- neutered hardware, computes nothing useful):**

| Instruction | dsl.py Line | Notes |
|---|---|---|
| `TT_TRNSPSRCA` | 294 | SrcA transpose not functional |
| `TT_RAREB` | 295 | Not used on BH |
| `TT_CONV3S1` | 310 | Neutered, computes Dst+=0 |
| `TT_CONV3S2` | 312 | Neutered, computes Dst+=0 |
| `TT_MFCONV3S1` | 314 | Neutered, computes Dst+=0 |
| `TT_APOOL3S1` | 316 | Neutered, computes Dst+=0 |
| `TT_MPOOL3S2` | 326 | Neutered, behaves like GMPOOL on zero |
| `TT_MPOOL3S1` | 330 | Neutered, behaves like GMPOOL on zero |
| `TT_APOOL3S2` | 332 | Neutered, computes Dst+=0 |
| `TT_TBUFCMD` | 417 | Tile buffer command, not used on BH |

**Rare/commented-out and never seen (safe to delete):**

| Instruction | dsl.py Line | Category |
|---|---|---|
| `TT_MOP_CFG` | 197 | Flow Control |
| `TT_RESOURCEDECL` | 204 | Flow Control |
| `TT_STREAMWAIT` | 235 | Sync |
| `TT_STREAMWRCFG` | 260 | Config |
| `TT_CFGSHIFTMASK` | 263 | Config |
| `TT_RMWCIB2` | 255 | Config |
| `TT_RMWCIB3` | 256 | Config |
| `TT_MOVA2D` | 289 | Data Move |
| `TT_MOVDBGA2D` | 361 | Data Move (debug) |
| `TT_MOVB2A` | 366 | Data Move |
| `TT_MOVDBGB2D` | 368 | Data Move (debug) |
| `TT_SETDVALID` | 370 | Data Move |
| `TT_SHIFTXA` | 297 | Data Move |
| `TT_SHIFTXB` | 300 | Data Move |
| `TT_DOTPV` | 324 | Matrix/FPU (legacy matmul) |
| `TT_ELWMUL` | 320 | Matrix/FPU (experimental) |
| `TT_ELWSUB` | 328 | Matrix/FPU (experimental) |
| `TT_GAPOOL` | 336 | Matrix/FPU |
| `TT_GATESRCRST` | 338 | Matrix/FPU (power mgmt) |
| `TT_SETIBRWC` | 353 | RWC |
| `TT_XMOV` | 376 | Mover |
| `TT_PACR_SETREG` | 399 | Pack/Unpack |
| `TT_RSTDMA` | 407 | Scalar/DMA |
| `TT_FLUSHDMA` | 413 | Scalar/DMA |
| `TT_REG2FLOP` | 414 | Scalar/DMA |
| `TT_LOADIND` | 416 | Scalar/DMA |
| `TT_SUBDMAREG` | 443 | Scalar/DMA |
| `TT_BITWOPDMAREG` | 447 | Scalar/DMA |
| `TT_SHIFTDMAREG` | 448 | Scalar/DMA |
| `TT_CMPDMAREG` | 449 | Scalar/DMA |
| `TT_STOREIND` | 459 | Scalar/DMA |
| `TT_STOREREG` | 461 | Scalar/DMA |
| `TT_LOADREG` | 462 | Scalar/DMA |
| `TT_ATINCGET` | 455 | Atomics |
| `TT_ATINCGETPTR` | 456 | Atomics |
| `TT_ATSWAP` | 457 | Atomics |
| `TT_ATCAS` | 458 | Atomics |
| `TT_INCADCXY` | 426 | ADC |
| `TT_ADDRCRXY` | 427 | ADC |
| `TT_ADDRCRZW` | 432 | ADC |
| `TT_SETASHRMH0` | 304 | Legacy halo/conv mask |
| `TT_SETASHRMH1` | 305 | Legacy halo/conv mask |
| `TT_SETASHRMV` | 306 | Legacy halo/conv mask |
| `TT_SETASHRMH` | 307 | Legacy halo/conv mask |
| `TT_SETPKEDGOF` | 308 | Legacy edge offset |
| `TT_CLREXPHIST` | 309 | Legacy |
| `TT_SFPLUT` | 490 | Superseded by SFPLUTFP32 |
| `TT_SFPSETMAN` | 525 | No BH LLK code path |
| `TT_SFPTRANSP` | 546 | No BH LLK code path |
| `TT_SFPLE` | 573 | BH-new, no LLK code path yet |

## Summary

```
Total instructions in dsl.py:     243
Used (seen in disassembly):        141  (58%)
Not seen in any disassembly:       102  (42%)
  - Dead on BH (safe to delete):    10
  - Rare, never seen (delete):      83
  - Active but dead on BH (fix):     7  (TT_CONV3S1, etc.)
  - Active, not dead (keep):         2  (NOP, SEXT_B -- pseudo/objdump artifacts)
Mislabeled as rare (actually used):  9  (TT_RMWCIB0/1, TT_SETADC, TT_MOVD2A,
                                         TT_SFPXOR, TT_SFPOR, TT_SFPLZ,
                                         TT_SFPMUL24, TT_SFPGT)
```

## Workloads Used for Analysis

### C++ Programming Examples (20 binaries)
hello_world_compute_kernel, hello_world_datamovement_kernel, hello_world_datatypes_kernel,
add_2_integers_in_compute, add_2_integers_in_riscv, eltwise_binary, eltwise_sfpu,
matmul_single_core, matmul_multi_core, matmul_multicore_reuse, matmul_multicore_reuse_mcast,
loopback, noc_tile_transfer, pad_multi_core, sfpu_eltwise_chain, shard_data_rm,
vecadd_multi_core, vecadd_sharding, custom_sfpi_add, custom_smoothstep

### TTNN Python Ops (24 operations)
exp, reciprocal, sqrt, sigmoid, abs, neg, relu, gelu, tanh, sin, cos, erf, erfinv,
softmax, softplus, silu, add, sub, mul, maximum, minimum, matmul, sum, mean

### Kernel Types in Cache (371 unique)
tilize, untilize, bmm_large_block_zm, bmm_large_block_zm_fused_bias_activation,
eltwise_binary_no_bcast, eltwise_binary_row_bcast, eltwise_binary_sfpu_no_bcast,
eltwise_copy, eltwise_sfpu, eltwise_typecast, layernorm, layernorm_sharded,
sdpa, sdpa_flash_decode, rotary_embedding_llama, rotary_embedding_llama_sharded,
transpose_wh_sharded, paged_fused_update_cache, mm, compute, tiles_add,
tiles_smoothstep, void_compute_kernel, add_2_tiles, add_multi_core, add_sharding,
and 100+ data-movement reader/writer kernel variants
