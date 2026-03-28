# Blackhole Instruction Set Analysis

Empirical analysis of which instructions the Blackhole ISA actually uses in practice, derived by disassembling every kernel and firmware ELF produced by tt-metal across a diverse set of workloads.

## Methodology

1. Cleared `~/.cache/tt-metal-cache/` to start from a clean slate.
2. Ran workloads on a single Blackhole P100 card to JIT-compile kernels:
   - **Qwen2.5-3B-Instruct** (LLM via `models/tt_transformers/demo/simple_text_demo.py`)
   - **ResNet-50** (vision classification, `models/demos/vision/classification/resnet50/blackhole/`)
   - **ViT** (vision transformer, `models/demos/vision/classification/vit/blackhole/`)
   - **VGG-UNet** (segmentation, `models/demos/vision/segmentation/vgg_unet/blackhole/`)
   - **UFLD-v2** (lane detection, `models/demos/vision/segmentation/ufld_v2/blackhole/`)
   - **SentenceBERT** (embedding, `models/demos/blackhole/sentence_bert/`)
   - **20 C++ programming examples** (eltwise binary/sfpu, custom SFPI, matmul single/multi-core, loopback, vecadd, pad, shard, etc.)
3. Disassembled all 443 cached kernel ELFs with `riscv-tt-elf-objdump -d`.
4. Disassembled pre-compiled firmware ELFs for build key `5327768567736097984` (matching our runtime):
   - 5 Tensix cores: `brisc`, `ncrisc`, `trisc0`, `trisc1`, `trisc2`
   - 4 ethernet RISCs: `active_erisc`, `idle_erisc`, `subordinate_active_erisc`, `subordinate_idle_erisc`
   - 3 CQ kernels: `cq_dispatch` (brisc), `cq_prefetch` (brisc), `cq_dispatch_subordinate` (ncrisc)
5. Extracted unique instruction mnemonics and cross-referenced against the full ISA defined in `blackhole-py/dsl.py`.

### Tools used

| Tool | Location |
|------|----------|
| `riscv-tt-elf-objdump` | `tt-metal/runtime/sfpi/compiler/bin/riscv-tt-elf-objdump` |
| ISA definition | `blackhole-py/dsl.py` (defines `RiscVInsn` and `TensixInsn` classes) |
| Kernel ELF cache | `~/.cache/tt-metal-cache/{build_key}/kernels/{name}/{hash}/{core}/{core}.elf` |
| Firmware ELFs | `tt-metal/tt_metal/pre-compiled/{build_key}/{core}/{core}.elf` |

### Objdump mnemonic mapping

The disassembler uses different naming than `dsl.py`:

| Objdump | dsl.py |
|---------|--------|
| `sfpXXX` (no prefix) | `TT_SFPXXX` |
| `ttXXX` | `TT_XXX` |
| `ttunpacrnop` | `TT_UNPACR_NOP` |
| `sext.h` / `sext.b` | `SEXT_H` / `SEXT_B` |
| `zext.h` / `zext.b` | `ZEXT_H` / `ZEXT_B` |
| `csrs` / `csrc` | `CSRRS` / `CSRRC` (pseudo-instructions) |

## Summary

| Category | Count | % of 244 |
|----------|------:|----------|
| **Used** (confirmed in ELFs) | 135 | 55.3% |
| **Reachable** (need niche ttnn ops) | 5 | 2.0% |
| **Experimental only** (no production path) | 2 | 0.8% |
| **Effectively unused** | 102 | 41.8% |

Breakdown of the 102 effectively unused:

| Subcategory | Count | Detail |
|-------------|------:|--------|
| HW dead/neutered on Blackhole | 10 | Old Grayskull conv/pool opcodes that compute `Dst += 0` |
| No Blackhole LLK code path | 52 | Defined in `tensix.h` but no software emits them |
| RISC-V compiler never emits | 40 | Supported by hardware but compiler chooses alternatives |

## Used instructions (135)

### RISC-V (67)

```
ADD   ADDI  AND   ANDI  AUIPC BEQ   BEQZ  BGE   BGEU  BGEZ
BGTZ  BLEZ  BLT   BLTU  BLTZ  BNE   BNEZ  CSRRC CSRRS CTZ
DIVU  FENCE J     JAL   JALR  JR    LBU   LHU   LI    LUI
LW    MAXU  MIN   MINU  MUL   MULHU MV    NEG   NOP   NOT
OR    ORI   REMU  RET   SB    SEQZ  SEXT_B SEXT_H SH  SH1ADD
SH2ADD SH3ADD SLL SLLI  SLT   SLTIU SLTU  SNEZ  SRAI  SRL
SRLI  SUB   SW    XOR   XORI  ZEXT_B ZEXT_H
```

Notable: no float instructions (F/D extensions). All floating-point work goes through the Tensix SFPU. No AMO atomics — synchronization uses Tensix semaphores (`TT_SEM*`).

### Tensix (68)

#### Flow control / MOP / replay
`TT_NOP`, `TT_MOP`, `TT_REPLAY`

#### Sync unit
`TT_ATGETM`, `TT_ATRELM`, `TT_STALLWAIT`, `TT_SEMINIT`, `TT_SEMPOST`, `TT_SEMGET`, `TT_SEMWAIT`

#### Config unit
`TT_WRCFG`, `TT_RDCFG`, `TT_SETC16`

#### Matrix engine / FPU
`TT_ZEROACC`, `TT_ZEROSRC`, `TT_CLEARDVALID`, `TT_MOVB2D`, `TT_MOVD2B`, `TT_TRNSPSRCB`, `TT_MVMUL`, `TT_ELWADD`, `TT_GMPOOL`, `TT_SETRWC`, `TT_INCRWC`

#### Packer / unpacker
`TT_PACR`, `TT_UNPACR`, `TT_UNPACR_NOP`

#### DMA scalar unit
`TT_DMANOP`, `TT_SETDMAREG`, `TT_ADDDMAREG`, `TT_MULDMAREG`

#### ADC (address counters)
`TT_SETADCXX`, `TT_SETADCXY`, `TT_SETADCZW`, `TT_INCADCZW`

#### SFPU (32 of 39 defined)
```
TT_SFPLOAD    TT_SFPLOADI   TT_SFPSTORE   TT_SFPLOADMACRO
TT_SFPLUTFP32 TT_SFPMAD     TT_SFPADD     TT_SFPMUL
TT_SFPMULI    TT_SFPADDI    TT_SFPDIVP2   TT_SFPEXEXP
TT_SFPEXMAN   TT_SFPSETEXP  TT_SFPSETSGN  TT_SFPIADD
TT_SFPSHFT    TT_SFPSHFT2   TT_SFPAND     TT_SFPNOT
TT_SFPMOV     TT_SFPABS     TT_SFPCAST    TT_SFPSWAP
TT_SFPSETCC   TT_SFPPUSHC   TT_SFPPOPC    TT_SFPENCC
TT_SFPCOMPC   TT_SFPSTOCHRND TT_SFPCONFIG TT_SFPARECIP
TT_SFPNOP
```

## Reachable but not exercised (5)

These have LLK code paths but require specific `ttnn` integer ops (`ttnn.gcd`, `ttnn.lcm`, `ttnn.div_int32_floor`, `ttnn.mul_int32`, `ttnn.remainder_int32`) that no standard model calls.

| Instruction | Triggered by |
|-------------|-------------|
| `TT_SFPMUL24` | `ckernel_sfpu_div_int32_floor.h`, `ckernel_sfpu_lcm.h`, `ckernel_sfpu_mul_int32.h`, `ckernel_sfpu_remainder_int32.h` |
| `TT_SFPLZ` | `ckernel_sfpu_comp.h`, `ckernel_sfpu_gcd.h` |
| `TT_SFPOR` | `ckernel_sfpu_binary_comp.h`, `ckernel_sfpu_gcd.h` |
| `TT_SFPXOR` | `ckernel_sfpu_binary_comp.h`, `ckernel_sfpu_gcd.h` |
| `TT_STOREREG` | `llk_io_unpack.h`, `llk_io_pack.h` (specific pack configurations) |

## Experimental only (2)

| Instruction | Location |
|-------------|----------|
| `TT_ELWMUL` | `llk_api/experimental/llk_math_eltwise_binary_custom_api.h` |
| `TT_ELWSUB` | `llk_api/experimental/llk_math_eltwise_binary_custom_api.h` |

No production kernel path uses these. The production eltwise multiply and subtract go through SFPU instead of the FPU `ELWMUL`/`ELWSUB` opcodes.

## Effectively unused (102)

### Hardware dead on Blackhole (10)

These opcodes exist in the encoding but are neutered — they either compute `Dst += 0` or are non-functional.

| Instruction | Notes |
|-------------|-------|
| `TT_TRNSPSRCA` | SrcA transpose not functional on Blackhole |
| `TT_RAREB` | Not used on Blackhole |
| `TT_CONV3S1` | Was 3x3 conv stride 1 on Grayskull, computes `Dst += 0` |
| `TT_CONV3S2` | Was 3x3 conv stride 2 on Grayskull, computes `Dst += 0` |
| `TT_MFCONV3S1` | Was multi-filter 3x3 conv on Grayskull, computes `Dst += 0` |
| `TT_APOOL3S1` | Was avg pool 3x3 stride 1, computes `Dst += 0` |
| `TT_APOOL3S2` | Was avg pool 3x3 stride 2, computes `Dst += 0` |
| `TT_MPOOL3S1` | Behaves like `GMPOOL` on all-zero SrcA |
| `TT_MPOOL3S2` | Behaves like `GMPOOL` on all-zero SrcA |
| `TT_TBUFCMD` | Tile buffer command, not used on Blackhole |

### No Blackhole LLK code path (52)

Defined in `tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h` as opcode constants but no Blackhole LLK header (`tt_metal/hw/ckernels/blackhole/metal/`) references them. Verified by `grep -r` across the entire LLK tree.

#### Halo / convolution masks (legacy Grayskull)
`TT_SETASHRMH`, `TT_SETASHRMH0`, `TT_SETASHRMH1`, `TT_SETASHRMV`, `TT_SETPKEDGOF`, `TT_SHIFTXA`, `TT_SHIFTXB`

#### Tensix atomics (replaced by semaphores)
`TT_ATINCGET`, `TT_ATINCGETPTR`, `TT_ATSWAP`, `TT_ATCAS`

#### Debug / uncommon register moves
`TT_MOVA2D`, `TT_MOVD2A`, `TT_MOVB2A`, `TT_MOVDBGA2D`, `TT_MOVDBGB2D`

#### DMA scalar ALU (ADDDMAREG/MULDMAREG cover all needs)
`TT_SUBDMAREG`, `TT_CMPDMAREG`, `TT_BITWOPDMAREG`, `TT_SHIFTDMAREG`, `TT_FLUSHDMA`, `TT_RSTDMA`, `TT_REG2FLOP`, `TT_LOADIND`, `TT_STOREIND`, `TT_LOADREG`

#### Scheduling / config
`TT_RESOURCEDECL`, `TT_MOP_CFG`, `TT_CFGSHIFTMASK`, `TT_RMWCIB0`, `TT_RMWCIB1`, `TT_RMWCIB2`, `TT_RMWCIB3`, `TT_PACR_SETREG`

#### Stream
`TT_STREAMWAIT`, `TT_STREAMWRCFG`

#### ADC
`TT_SETADC`, `TT_ADDRCRXY`, `TT_ADDRCRZW`, `TT_INCADCXY`

#### SFPU (no LLK path)
`TT_SFPGT`, `TT_SFPLE`, `TT_SFPLUT`, `TT_SFPSETMAN`, `TT_SFPTRANSP`

#### Other
`TT_GAPOOL`, `TT_DOTPV`, `TT_XMOV`, `TT_CLREXPHIST`, `TT_GATESRCRST`, `TT_SETDVALID`, `TT_SETIBRWC`

### RISC-V compiler never emits (40)

These are valid RISC-V instructions supported by the `riscv-tt-elf-g++` toolchain but the compiler doesn't emit them for the code patterns in tt-metal kernels.

#### Zaamo atomics (9) — no source references at all
`AMOADD_W`, `AMOSWAP_W`, `AMOXOR_W`, `AMOOR_W`, `AMOAND_W`, `AMOMIN_W`, `AMOMAX_W`, `AMOMINU_W`, `AMOMAXU_W`

#### Bit manipulation (13) — compiler uses simpler sequences
`ANDN`, `ORN`, `XNOR`, `CLZ`, `CPOP`, `ROL`, `ROR`, `RORI`, `BREV8`, `ORC_B`, `REV8`, `PACK`, `GREVI`

Note: `CTZ` is used but `CLZ` is not. `MAXU`/`MIN`/`MINU` are used but `MAX` is not.

#### Signed arithmetic (5) — unsigned variants preferred
`DIV`, `REM`, `MULH`, `MULHSU`, `SRA`

The compiler uses `DIVU`, `REMU`, `MULHU`, `SRAI` instead.

#### Other (13)
`CALL` (compiler uses `JAL` directly), `LB`, `LH` (unsigned loads `LBU`/`LHU` preferred), `CSRRW`, `CSRRWI`, `CSRRSI`, `CSRRCI` (only `CSRRS`/`CSRRC` pseudo-forms used), `ECALL`, `EBREAK`, `MAX`, `SGTZ`, `SLTZ`, `SLTI`

## Per-core firmware instruction counts

| Core | Unique instructions |
|------|-------------------:|
| brisc | 44 |
| ncrisc | 34 |
| trisc0 | 34 |
| trisc1 | 28 |
| trisc2 | 34 |
| active_erisc | 36 |
| idle_erisc | 35 |
| subordinate_active_erisc | 31 |
| subordinate_idle_erisc | 29 |
| cq_dispatch (brisc) | 48 |
| cq_prefetch (brisc) | 56 |
| cq_dispatch_subordinate (ncrisc) | 34 |

The CQ prefetch kernel is the most instruction-diverse firmware component (56 unique instructions). Firmware is predominantly RISC-V control flow — Tensix instructions only appear in kernel ELFs (TRISC0/1/2).

## What each workload contributed

| Workload | New instructions added |
|----------|----------------------|
| Qwen2.5-3B (LLM) | 130 (baseline — attention, matmul, RMSNorm, RoPE, SiLU, softmax) |
| ResNet-50 + ViT + VGG-UNet + UFLD-v2 + SentenceBERT | +3: `TT_SFPABS`, `TT_SFPLUTFP32`, `TT_SFPNOT` |
| 20 C++ programming examples | +0 (all instructions already covered by model runs) |
| Firmware + CQ ELFs | +2: `NOP`, `SEXT_B` |

The LLM workload alone covers 96% of the reachable instruction set. Vision models added only SFPU ops for abs value, FP32 LUT approximation, and bitwise NOT.

## Kernel types generated by Qwen2.5-3B

The model run produced 271 kernel ELFs (excluding `.xip.elf`) across these kernel types:

```
bmm_large_block_zm_fused_bias_activation    (trisc0/1/2)
compute                                      (trisc0/1/2)
cq_dispatch                                  (brisc)
cq_dispatch_subordinate                      (ncrisc)
cq_prefetch                                  (brisc)
dm_in0_sender / dm_in1_sender_out            (ncrisc/brisc)
eltwise_binary_no_bcast / row_bcast          (trisc0/1/2)
eltwise_binary_sfpu_no_bcast                 (trisc0/1/2)
eltwise_typecast                             (trisc0/1/2)
embeddings_tilize                            (ncrisc)
layernorm / layernorm_sharded                (trisc0/1/2)
paged_fused_update_cache                     (trisc0/1/2)
reader_* (18 variants)                       (ncrisc or brisc)
reshard_reader / reshard_same_width_reader   (brisc/ncrisc)
rotary_embedding_llama / _sharded            (trisc0/1/2)
sdpa / sdpa_flash_decode                     (trisc0/1/2)
tilize / untilize_wh                         (trisc0/1/2)
writer_* (15 variants)                       (brisc)
```

## ELF locations

| What | Path |
|------|------|
| Cached kernel ELFs | `~/.cache/tt-metal-cache/{build_key}/kernels/{name}/{hash}/{core}/{core}.elf` |
| Pre-compiled firmware | `tt-metal/tt_metal/pre-compiled/{build_key}/{core}/{core}.elf` |
| Copy of kernel ELFs | `/tmp/tt-kernel-elfs/{kernel_name}/{hash}/{core}/` |
| Toolchain | `tt-metal/runtime/sfpi/compiler/bin/riscv-tt-elf-*` |
| Compiler | `riscv-tt-elf-g++ (tenstorrent/sfpi:7.35.0[414]) 15.1.0` |

## Reproducing

```bash
# 1. Clear cache
rm -rf ~/.cache/tt-metal-cache/*

# 2. Set environment
export TT_METAL_HOME=/home/boop/tenstorrent/tt-metal
export ARCH_NAME=blackhole
export LD_LIBRARY_PATH=$TT_METAL_HOME/build/lib:$TT_METAL_HOME/build/tt_metal:$TT_METAL_HOME/build/tt_stl:$TT_METAL_HOME/build/tt_metal/third_party/umd/device
export PYTHONPATH=$TT_METAL_HOME
export HF_MODEL=Qwen/Qwen2.5-3B-Instruct

# 3. Run workloads
~/tenstorrent/.venv/bin/python3 -m pytest models/tt_transformers/demo/simple_text_demo.py -k "performance and batch-1" -s
~/tenstorrent/.venv/bin/python3 -m pytest models/demos/vision/classification/resnet50/blackhole/demo/demo.py -s
# ... etc

# 4. Disassemble all kernel ELFs
OBJDUMP=$TT_METAL_HOME/runtime/sfpi/compiler/bin/riscv-tt-elf-objdump
find ~/.cache/tt-metal-cache/ -name "*.elf" ! -name "*.xip.elf" -path "*/kernels/*" \
    -exec $OBJDUMP -d {} \; | grep -P '^\s+[0-9a-f]+:\s+[0-9a-f]+\s+' | \
    awk '{print $3}' | sort -u
```
