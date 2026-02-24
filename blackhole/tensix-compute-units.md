# Tensix Compute Units: FPU and SFPU Reference

Deep dive into the two compute paths in the Tensix coprocessor, their register files,
instruction sets, data movement, synchronization, and the MOP replay system.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [FPU (Matrix Unit)](#fpu-matrix-unit)
  - [Compute Instructions](#fpu-compute-instructions)
  - [Data Movement Instructions](#fpu-data-movement-instructions)
  - [Fidelity Phases](#fidelity-phases)
  - [Supported Data Types](#supported-data-types)
- [SFPU (Vector Unit)](#sfpu-vector-unit)
  - [Native ISA Instructions](#sfpu-native-isa-instructions)
  - [Higher-Level Operations (LLK)](#sfpu-higher-level-operations)
- [Register Files](#register-files)
  - [SrcA and SrcB](#srca-and-srcb)
  - [Dst (Destination)](#dst-destination)
  - [LReg (SFPU Local Registers)](#lreg-sfpu-local-registers)
- [Data Flow and Loading Patterns](#data-flow-and-loading-patterns)
  - [FPU Path: Unpack → SrcA/SrcB → FPU → Dst → Pack](#fpu-path)
  - [SFPU Path: Dst → SFPLOAD → LReg → SFPSTORE → Dst](#sfpu-path)
  - [Unpack-to-Dest Mode](#unpack-to-dest-mode)
- [Pack/Unpack Stage Transformations](#packunpack-stage-transformations)
- [FPU/SFPU Synchronization](#fpusfpu-synchronization)
- [MOP and the Replay Buffer](#mop-and-the-replay-buffer)
- [Tensix Instruction Encoding](#tensix-instruction-encoding)

---

## Architecture Overview

Two compute paths in each Tensix tile:

1. **FPU (Matrix Unit)** — systolic array, processes 8x16 elements/cycle. Matmul (MVMUL)
   plus element-wise add/sub/mul and max-pool reduction.
2. **SFPU (Vector Unit)** — 32-wide SIMD, 32-bit lanes. Everything else: activations,
   transcendentals, comparisons, type conversions, bitwise ops, integer math.

Both share the **Dst register file** as their common interface. The unpacker/packer engines
move data between L1 circular buffers and the register files.

A third unit, the **Scalar Unit (ThCon)**, handles integer and memory ops but is a
control-plane / configuration engine (writing THCON config registers, address modifiers),
not a user-facing compute path.

### Performance Comparison

| Unit | Peak throughput (1 GHz) | Precision |
|------|------------------------|-----------|
| FPU `MVMUL` | 4.096 TFLOP/s | 19-bit (TF32) in SrcA/SrcB, FP32 accumulator |
| SFPU `SFPMAD` | 0.064 TFLOP/s | Full FP32 in every lane |

The FPU is ~64x faster than SFPU for bulk math. The FPU is broader than "just matmul" —
ELWADD/ELWSUB/ELWMUL at 0.128–0.256 TFLOP/s are still 2-4x faster than SFPU's SFPMAD.

---

## FPU (Matrix Unit)

### FPU Compute Instructions

All operate on SrcA/SrcB → Dst, processing 8x16 tile faces:

| Instruction | Operation | Throughput | Latency |
|-------------|-----------|------------|---------|
| `MVMUL` | Dst += SrcB @ SrcA (8x16 matmul) | 1 IPC | 5 cycles |
| `ELWMUL` | Dst += SrcA * SrcB (element-wise) | 1 IPC | 5 cycles |
| `ELWADD` | Dst = SrcA + SrcB (or Dst += with AddDst flag) | 1 IPC | 5 cycles |
| `ELWSUB` | Dst = SrcA - SrcB (or Dst += with AddDst flag) | 1 IPC | 5 cycles |
| `GMPOOL` | Dst = max(Dst, max_along_cols(SrcA)) | 1 IPC | 5 cycles |
| `GAPOOL` | Like MVMUL but 4x16 (half throughput) | 1 IPC | 5 cycles |
| `DOTPV` | Legacy MVMUL (prefer MVMUL) | 1 IPC | 5 cycles |

The `AddDst` flag on ELWADD/ELWSUB gives `Dst += SrcA + SrcB` (3-operand accumulate)
at 2x the throughput of the non-accumulating version. GMPOOL supports `ArgMax=true` for
getting the index of the max element.

ELWADD/ELWSUB/GMPOOL do not use fidelity phases — always full speed.

Legacy/neutered instructions (WH only): `MFCONV3S1`, `CONV3S1`, `CONV3S2`, `APOOL3S1`,
`APOOL3S2` compute Dst += 0 only. `MPOOL3S1`, `MPOOL3S2` behave like GMPOOL on all-zero
SrcA. These opcodes may be repurposed in future architectures.

### Throughput Summary

| Instruction | 1 Phase | 2 Phases | 4 Phases |
|-------------|---------|----------|----------|
| `MVMUL` (no broadcast) | 4.096 TFLOP/s | 2.048 | 1.024 |
| `MVMUL` (broadcast row) | 0.560 TFLOP/s | 0.280 | 0.140 |
| `GAPOOL` | 2.048 TFLOP/s | 1.024 | 0.512 |
| `ELWMUL` | 0.256 TFLOP/s | 0.128 | 0.064 |
| `GMPOOL` | 0.256 TFLOP/s | — | — |
| `ELWADD`/`ELWSUB` (+AddDst) | 0.256 TFLOP/s | — | — |
| `ELWADD`/`ELWSUB` (no AddDst) | 0.128 TFLOP/s | — | — |

### FPU Data Movement Instructions

| Instruction | Direction | Rows | Latency | Special |
|-------------|-----------|------|---------|---------|
| `MOVA2D` | SrcA → Dst | 1 or 8 (aligned) | 4 cy | Auto-waits SrcA; 3-cy Dst hazard; format conversion TF32/BF16→FP32 |
| `MOVB2D` | SrcB → Dst | 1, 4, or 8-bcast | 4 cy | Row broadcast (1→8) and/or column broadcast (col0→all 16); uses SrcAFmt |
| `MOVD2A` | Dst → SrcA | 1 or 4 (aligned) | 2 cy | Manual STALLWAIT required; next cycle only MOVD2A/MOVB2A allowed |
| `MOVD2B` | Dst → SrcB | 1 or 4 (aligned) | 3 cy | Manual STALLWAIT required; 3-cy restriction: only MOVD2B allowed after |
| `MOVB2A` | SrcB → SrcA | 1 or 4 (aligned) | 4 cy | Raw 19-bit copy, no format conversion; auto-waits SrcB, manual for SrcA |
| `MOVDBGA2D` | SrcA → Dst | 1 or 8 (aligned) | 4 cy | Debug variant of MOVA2D — skips SrcA bank ownership check |
| `ZEROACC` | — | 1, 16, 512, or 1024 | 1 cy | Clears DstRowValid flags (not data); readers see identity element (0 or -inf) |
| `ZEROSRC` | → SrcA/SrcB | All 64 rows | 1 cy | Actually writes 0 or -inf; NegativeInfSrcA for max-pool init |
| `SHIFTXA` | SrcA → SrcA | 16 (rows 0-15) | 1 cy | Shift left/right by 1 col, zero-fill; HW bug: source row from prev instr |
| `SHIFTXB` | SrcB → SrcB | 1 (selectable) | 2 cy | Shift or rotate left by 1 col; 0.5 IPC |
| `TRNSPSRCB` | SrcB ↔ SrcB | 16 (rows 16-31) | 1 cy | In-place 16x16 transpose; hardwired to rows 16-31 only |

#### TRNSPSRCB Transpose Pattern
The canonical tile transpose sequence:
```
MOVD2B(SRC_ROW16_OFFSET, MOV_4_ROWS, ...)  // Dst → SrcB[16:20]
MOVD2B(SRC_ROW16_OFFSET+4, MOV_4_ROWS, ...)
MOVD2B(SRC_ROW16_OFFSET+8, MOV_4_ROWS, ...)
MOVD2B(SRC_ROW16_OFFSET+12, MOV_4_ROWS, ...)
TRNSPSRCB                                    // transpose SrcB[16:31] in-place
MOVB2D(SRC_ROW16_OFFSET, MOV_4_ROWS, ...)   // write back to Dst
// ... or MOVB2A to copy transposed data into SrcA
```

### Fidelity Phases

The FPU multiplier is physically narrower than a full mantissa — it consumes **5 bits of
SrcA mantissa and 7 bits of SrcB mantissa per phase**. Multiple phases process different
mantissa slices and accumulate partial products into Dst.

| Phase | SrcA mantissa bits | SrcB mantissa bits |
|-------|-------------------|-------------------|
| Phase 0 | bits [9:5] (top 5) | bits [9:3] (top 7) |
| Phase 1 | bits [4:0] (bottom 5) | bits [9:3] (same 7) |
| Phase 2 | bits [9:5] (top 5) | bits [2:0] + padding (bottom 3) |
| Phase 3 | bits [4:0] (bottom 5) | bits [2:0] + padding (bottom 3) |

The 5x7 split is **asymmetric** — SrcB gets more bits per phase. This is why the LLK
swaps operands: `in0` ("A" matrix, reused) → SrcB (wider 7-bit path), `in1` ("B" matrix,
streamed) → SrcA (narrower 5-bit path).

#### Fidelity Coverage by Input Format

| Input format | Mantissa | LoFi (1 phase) | HiFi2 (2 phases) | HiFi4 (4 phases) |
|-------------|----------|-----------------|-------------------|-------------------|
| FP8 / BFP4 / BFP2 | ≤4 bits | **Exact** | overkill | overkill |
| BFP8 | 7 bits | Top 5 of SrcA, all 7 of SrcB | **Exact** | overkill |
| BF16 | 7 bits | Loses 2 bits from SrcA | **Exact** | overkill |
| FP16 | 10 bits | Rough — top 5x7 only | 10x7 — SrcB still truncated | **Full precision** |
| TF32 | 10 bits | Top 5x7 | 10x7 | Full 10x10 |

#### Practical Fidelity Guidance

| Situation | Fidelity needed |
|-----------|----------------|
| INT8 inference | LoFi (exact) |
| FP8 / BFP8 inference | LoFi (exact) |
| BF16 inference (acceptable error) | LoFi (loses ~2 bits, usually fine) |
| BF16 training (accurate gradients) | HiFi2 |
| FP16 anything | HiFi4 for full precision, HiFi2 as compromise |
| TF32 (max FPU precision) | HiFi4 |

### Supported Data Types

#### SrcA / SrcB Register Types (19-bit storage each)

| Type | Format | Notes |
|------|--------|-------|
| TF32 | 1 sign, 8 exp, 10 mantissa | Widest native type |
| BF16 | 1 sign, 8 exp, 7 mantissa | Overlaid on TF32 (low 3 mantissa bits = 0) |
| FP16 | 1 sign, 5 exp, 10 mantissa | FP8/BFP8a/BFP4a/BFP2a convert to this |
| Integer "8" | 1 sign, 10 magnitude | Range -1023..+1023 |
| Integer "16" | 1 sign, 15 magnitude | Opaque 16-bit transfer only |

#### Dst Register Types

| Dst16b (16-bit mode) | Dst32b (32-bit mode) |
|---------------------|---------------------|
| BF16 | FP32 |
| FP16 | Integer "32" (sign-magnitude) |
| Integer "8" | |
| Integer "16" | |

#### Supported Multiply Combinations (MVMUL, ELWMUL)

| Dst | += | SrcB | * | SrcA |
|-----|----|----|---|------|
| FP32 or BF16 | += | TF32 or BF16 | | TF32 or BF16 |
| FP32 or FP16 | += | FP16 | | FP16 |
| Integer "32" | += | Integer "8" | | Integer "8" |

### FPU Configuration Registers

| Register field | Effect |
|---------------|--------|
| `ALU_ACC_CTRL_Fp32_enabled` | FP32 accumulator in Dst (otherwise 16-bit) |
| `ALU_ACC_CTRL_INT8_math_enabled` | INT8 mode (overrides float formats) |
| `ALU_FORMAT_SPEC_REG0_SrcA` | SrcA data format (BF16/FP16/TF32 path) |
| `FIDELITY_BASE_Phase` (ThreadConfig) | Starting fidelity phase |
| `DEST_REGW_BASE_Base` | Base row offset into Dst |

---

## SFPU (Vector Unit)

The SFPU is a 32-lane SIMD engine operating on 32-bit values (FP32 or integer). It has
8 general-purpose Local Registers (LReg[0..7]) plus constant registers (LReg[8..15]),
and accesses the Dst register file via SFPLOAD/SFPSTORE. Runs at 1.35 GHz on Blackhole
(vs 1 GHz on Wormhole).

### SFPU Native ISA Instructions

#### FP32 Arithmetic (MAD sub-unit, 2-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPMAD` | VD = ±VA * ±VB ± VC (FMA) |
| `SFPMUL` | VD = VA * ±VB |
| `SFPADD` | VD = ±VB ± VC |
| `SFPADDI` | VD += BF16(Imm16) |
| `SFPMULI` | VD *= BF16(Imm16) |

#### LUT-based Piecewise Linear (MAD sub-unit, 2-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPLUT` | 8-bit coefficient LUT; 3 pieces (0-1, 1-2, 2+) indexed by LReg[3] |
| `SFPLUTFP32` | FP32-native 3-entry table; or 16-bit 6-entry table |

#### Simple FP32 Operations (simple sub-unit, 1-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPABS` | VD = Abs(VC) (FP32 or INT mode) |
| `SFPMOV` | VD = VC, VD = -VC, VD = Config, VD = PRNG() |
| `SFPSETSGN` | Set/clear/copy sign bit |
| `SFPSWAP` | Min/max swap, plain swap, subvec variants (2-cy) |
| `SFPGT` | VD > VC comparison, set flags or produce mask (**BH-new**) |
| `SFPLE` | VD <= VC comparison (**BH-new**) |
| `SFPLZ` | Count leading zeros; set CC bits |
| `SFPSETCC` | Set per-lane flags from VC comparisons |
| `SFPARECIP` | Approx 1.0/VC (7-bit accuracy) or approx e^Abs(VC) (**BH-new**) |

#### FP32 Field Manipulation (1-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPEXEXP` | Extract exponent (raw or debiased) |
| `SFPEXMAN` | Extract mantissa |
| `SFPSETEXP` | Replace exponent from imm or register |
| `SFPSETMAN` | Replace mantissa from imm or register |
| `SFPDIVP2` | Multiply/divide by 2^N (add to exponent) |

#### Integer Arithmetic (two's complement, 1-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPIADD` | VD = VC ± VD or VC ± Imm11; optional CC |
| `SFPABS` | VD = Abs(VC) (INT mode) |
| `SFPMUL24` | 24x24→47-bit partial product, lower or upper half (**BH-new**) |

#### Bit Manipulation / Logical (1-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPAND` | VD = VB & VC |
| `SFPOR` | VD = VB \| VC |
| `SFPXOR` | VD ^= VC |
| `SFPNOT` | VD = ~VC |
| `SFPSHFT` | Logical or arithmetic shift left/right |
| `SFPSHFT2` | Two-source shift; also lane-rotation/shift modes |
| `SFPLZ` | Count leading zeros |

#### Data Type Conversion (1-cycle latency)

| Instruction | Conversions |
|-------------|-------------|
| `SFPCAST` | INT32↔FP32, SignMag32↔INT32, IntAbs |
| `SFPSTOCHRND` | FP32→FP16A/BF16/UINT8/INT8/UINT16/INT16 (deterministic or stochastic rounding) |
| `SFPLOADI` | Load immediate: BF16→FP32, FP16→FP32, unsigned/signed short, full INT32/UINT32/FP32 |

#### Data Movement (load/store sub-units)

| Instruction | Operation |
|-------------|-----------|
| `SFPLOAD` | Dst → LReg (4 rows x 8 cols = 32 elements); format conversion |
| `SFPSTORE` | LReg → Dst (same 4x8 slice); inverse format conversion |
| `SFPLOADMACRO` | Load + schedule 4 pipelined ops across all 5 sub-units |
| `SFPMOV` | LReg → LReg copy/negate/config/PRNG |
| `SFPSWAP` | Swap two LRegs |
| `SFPTRANSP` | 4x4 transpose within LReg[0:4] and LReg[4:8] lane groups |
| `SFPSHFT2` | Lane rotation/shift (move data between SIMD lanes) |
| `SFPLOADI` | Load immediate constant → LReg |
| `SFPCONFIG` | Write LReg[0] lane 0 → constant register LReg[11-14] |

#### Conditional Execution / Predication (1-cycle latency)

| Instruction | Operation |
|-------------|-----------|
| `SFPENCC` | Enable/disable conditional execution; load CC result |
| `SFPSETCC` | Set per-lane LaneFlags from comparisons |
| `SFPPUSHC` | Push current LaneFlags onto flag stack |
| `SFPPOPC` | Pop flag stack |
| `SFPCOMPC` | Complement flags (maps to `else` in SIMT if/else) |

#### Blackhole vs Wormhole Differences

| Feature | Wormhole B0 | Blackhole A0 |
|---------|-------------|-------------|
| `SFPARECIP` (approx recip/exp) | No | **Yes** |
| `SFPGT`, `SFPLE` (FP/SM comparisons) | No | **Yes** |
| `SFPMUL24` (24-bit integer multiply) | No | **Yes** |
| Arithmetic right shift (`SFPSHFT`) | No | **Yes** |
| Clock speed | 1 GHz | **1.35 GHz** |

### SFPU Higher-Level Operations

Built from native ISA instructions in the LLK (`tt-llk/.../sfpu/`):

**Transcendental Math:** exp, exp2, log, log2, log10, sqrt, rsqrt, recip (1/x),
sin, cos, tan, asin, acos, atan, sinh, cosh, erf, erfc, erfinv, i0

**Activation Functions:** gelu, silu, sigmoid, tanh, relu, elu, leaky_relu,
hardtanh, softplus, hardsigmoid, gelu_derivative, tanh_derivative, celu

**Comparisons / Boolean:** ==, !=, <, <=, >, >= (float and int), where (ternary select),
isinf, isnan, isfinite, logical_not

**Rounding:** floor, ceil, round, trunc, frac

**Quantization / Type Conversion:** typecast (fp32↔fp16/bf16/uint16), quant/dequant
(int8/uint8 with scale/zero-point)

**Integer Operations:** add_int32, mul_int32, div_int32, remainder, fmod,
left_shift, right_shift, bitwise and/or/xor/not

**Reduction / Statistical:** reduce (sum, max), Welford's mean/variance, cumsum, tiled_prod

**Special:** abs, neg, sign, square, power, clamp, dropout (PRNG), topk, polyval, fill

---

## Register Files

### SrcA and SrcB

```
SrcA[2 banks] = 64 rows x 16 cols x 19 bits/datum
SrcB[2 banks] = 64 rows x 16 cols x 19 bits/datum
```

Each has **2 banks** for double-buffering. At any moment, one bank is owned by the
Unpackers (being filled from L1), the other by the Matrix Unit (being read for compute).
Ownership is transferred atomically:

- **Unpacker → FPU:** `SETDVALID` (or `UNPACR` with `FlipSrc=1`)
- **FPU → Unpacker:** `CLEARDVALID` (or `clear_dvalid` field in MVMUL)

One 32x32 tile = 4 faces of 16x16 = 64 rows x 16 cols = exactly one bank.

The 19-bit datum width accommodates TF32 (1+8+10), BF16 (overlaid on TF32 with low
3 mantissa bits zeroed), FP16 (1+5+10), or INT8 (1+10 sign-magnitude). Bits are stored
in **shuffled** layout: `{Sign, Mantissa, Exponent}` — not IEEE order.

### Dst (Destination)

```
Physical storage: DstBits[1024][16] x 16 bits
                  DstRowValid[1024]  (1 valid bit per row)
```

Two views:

| Mode | Logical shape | Tile capacity | Use case |
|------|--------------|---------------|----------|
| Dst16b | 1024 rows x 16 cols x 16b | **16 tiles** (8 per half) | BF16/FP16 accumulation |
| Dst32b | 512 rows x 16 cols x 32b | **8 tiles** (4 per half) | FP32 accumulation |

In 32-bit mode, each logical row spans two physical rows (high 16b in row R, low 16b
in row R+8). Same physical storage, half the logical rows.

Dst is **soft double-buffered** by splitting into two halves (rows 0-511 and 512-1023).
MATH writes to one half while PACK reads from the other, synchronized via the
`MATH_PACK` semaphore.

**Read-after-write hazard:** After any instruction writes to an aligned 8x16 block of
Dst, that block cannot be read for **4 cycles**. Hardware auto-stalls FPU/packer readers.
SFPLOAD requires at least **3 unrelated instructions** after an FPU write to the same region.

BF16/FP32 data in Dst is stored in shuffled format (`{sign, mantissa, exponent}`).
SFPLOAD/SFPSTORE and the packer unshuffle/reshuffle automatically.

### LReg (SFPU Local Registers)

```
LReg[17] x 32 lanes x 32 bits/lane
```

| Index | Access | Contents |
|-------|--------|----------|
| LReg[0..7] | Read/write | 8 general-purpose, full FP32/INT32 |
| LReg[8] | Read-only | 0.8373 (exp constant) |
| LReg[9] | Read-only | 0.0 |
| LReg[10] | Read-only | 1.0 |
| LReg[11..14] | Programmable via SFPCONFIG | Constants (default: LReg[11] = -1.0) |
| LReg[15] | Read-only | Lane IDs: lane i = i*2 |
| LReg[16] | SFPLOADMACRO only | Macro pipeline scratch |

The 32 lanes are physically arranged as a **4x8 grid** (4 rows of 8 lanes):
```
Lane  0  1  2  3  4  5  6  7
Lane  8  9 10 11 12 13 14 15
Lane 16 17 18 19 20 21 22 23
Lane 24 25 26 27 28 29 30 31
```

Data types per lane: FP32, unsigned int32, signed int32 (two's complement),
signed int32 (sign-magnitude). Implicit bitcast between any is legal.

---

## Data Flow and Loading Patterns

### FPU Path

```
CB (L1) ──UNPACR──→ SrcA / SrcB       ← TRISC0 (unpack thread)
SrcA + SrcB ──MVMUL──→ Dst            ← TRISC1 (math thread, FPU)
Dst ──PACR──→ CB (L1)                 ← TRISC2 (pack thread)
```

**TRISC1 never touches L1 directly.** Unpackers (TRISC0) issue UNPACR instructions that
DMA data from circular buffers in L1 into SrcA/SrcB with on-the-fly format conversion.
Packers (TRISC2) issue PACR instructions that DMA from Dst back to L1.

The unpack pipeline: L1 → Address Generator → Format Converter → Decompressor →
Upsample/Transpose → SrcA/SrcB bank.

**Confusing LLK convention for matmul:** `in0` ("A" matrix CB) loads into **SrcB**,
`in1` ("B" matrix CB) loads into **SrcA**. `MVMUL` computes `Dst += SrcB @ SrcA`.

### SFPU Path

```
Dst ──SFPLOAD──→ LReg                 ← TRISC1
LReg ──SFPU compute──→ LReg           ← TRISC1
LReg ──SFPSTORE──→ Dst                ← TRISC1
```

**SFPLOAD does NOT read from CBs/L1.** It reads from Dst only. There is no direct path
from L1 to LRegs — Dst is always the intermediary.

Each SFPLOAD reads a **4 x 8 = 32 element slice** of Dst:
```
Effective address = Imm10 + Dst_offset + base_offset

For each of 32 lanes:
  Row    = (Addr & ~3) + (Lane / 8)       ← 4 consecutive Dst rows
  Column = (Lane & 7) * 2                 ← 8 even columns: 0,2,4,6,8,10,12,14
  if (Addr & 2): Column += 1              ← or 8 odd columns: 1,3,5,7,9,11,13,15
```

One SFPLOAD gets half the columns of 4 rows. A full 32x32 tile (64 Dst rows) requires
**16 SFPLOAD/SFPSTORE pairs** for even columns, or 32 for full coverage.

SFPLOAD also converts from Dst's shuffled bit layout to proper FP32 in LReg.
SFPSTORE does the inverse.

### Unpack-to-Dest Mode

For pure SFPU operations (no FPU involved), the unpacker can write directly to Dst:
```
TRISC0: UNPACR with UnpackToDst=1  →  CB data lands in Dst directly
TRISC1: SFPLOAD → compute → SFPSTORE  (operates on Dst in-place)
TRISC2: PACR → reads Dst back to CB
```
The `UNPACK_TO_DEST` semaphore (index 2) synchronizes TRISC0 and TRISC1.

---

## Pack/Unpack Stage Transformations

### Unpack-Stage Transforms (before compute)

| Transform | Description | Constraints |
|-----------|-------------|-------------|
| Format conversion | BFP8→BF16, FP32→TF32, FP16→FP16, etc. on the fly | Via InDataFormat/OutDataFormat config |
| XY transpose | Swaps low 4 row bits with col index within 16x16 block | Unpacker 0 → SrcA only; `haloize_mode=1` |
| Tilize | Gathers non-contiguous L1 rows (row-major) into tiled SrcA | `tileize_mode=1`; no upsample/compression |
| Decompression | RLE zero-expansion from compressed L1 | Inverse of packer compression |
| Upsampling | Insert 1/2/4 zeros after each datum, or skip positions | `upsample_rate`, `upsample_and_interleave` |

### Pack-Stage Transforms (after compute)

Pipeline order: Dst → Edge Mask → Early Format Conv → ReLU → Exp Threshold →
Late Format Conv → Compression → L1

| Transform | Description |
|-----------|-------------|
| Edge masking | 16-bit column mask per row; replace masked cols with 0 or -inf |
| Early format conversion | Dst format → intermediate (e.g., FP32 → BF16, FP32 → INT8 with shift+round+sat) |
| **ReLU** (4 modes) | NO_RELU, ZERO_RELU (x≤0→0), MIN_THRESHOLD_RELU (x≤T→0), MAX_THRESHOLD_RELU (clamp) |
| Exponent thresholding | Flush near-zero values (exponent < threshold → 0) |
| Exponent histogram | 32-bin histogram of exponents for adaptive BFP quantization |
| Late format conversion | Intermediate → L1 output (e.g., BF16 → BFP8 with shared exponent) |
| Compression | RLE zero-encoding for L1 bandwidth savings |
| Downsampling | 16-bit rotating mask selects which datums to keep |
| Accumulation | L1 += datum instead of L1 = datum |
| Untilize | Tiled Dst → row-major L1 via strided packer addressing |

**ReLU is free in the packer** — no SFPU needed if it happens at pack time. Format
conversion is also free at both unpack and pack boundaries.

---

## FPU/SFPU Synchronization

### Can They Run Simultaneously?

**Architecturally yes** — they have separate block bits (B6 for FPU, B8 for SFPU) in
STALLWAIT. The hardware can issue an MVMUL and an SFPU instruction on the same cycle,
provided they target non-overlapping Dst regions.

**In practice the LLK serializes them.** Every SFPU operation begins with:
```c
TTI_STALLWAIT(p_stall::STALL_SFPU, p_stall::MATH);
```
This means: block SFPU instruction issuance (B8) until the FPU pipeline is fully
drained (C4). It's a one-way fence — FPU finishes, then SFPU starts.

### Matmul + Activation Pipeline (what actually happens)

```
1. tile_regs_acquire()       — SEMWAIT for free Dst half

2. FPU matmul (via MOP)     — MOP(1,0,0) → 16 MVMULs at 1/cycle
                               TRISC1 RISC-V is FREE during this

3. STALLWAIT(STALL_SFPU, MATH) — blocks until all MVMULs drain

4. SFPU activation           — SFPLOAD/compute/SFPSTORE x16 iterations
                               (~80 cycles for relu on 32x32 tile)

5. tile_regs_commit()        — STALLWAIT both pipelines, SEMPOST(MATH_PACK)
                               signal packer, flip Dst half

6. PACK thread (TRISC2)      — wakes on SEMPOST, reads Dst → L1
                               ZEROACC, SEMGET to free half
```

No overlap between FPU and SFPU in the standard LLK flow. Pipelining across tiles is
handled by Dst double-buffering between MATH and PACK, not between FPU and SFPU.

### MATH_PACK Semaphore

| Event | Semaphore effect |
|-------|-----------------|
| Init | Set max=2 (SyncHalf), value=0 |
| tile_regs_acquire() | SEMWAIT — MATH blocks if both halves committed |
| tile_regs_commit() | SEMPOST — value 0→1, signals packer |
| tile_regs_release() (PACK) | ZEROACC + SEMGET — value 1→0, frees half |

---

## MOP and the Replay Buffer

### What Is MOP?

MOP (Macro Operation) is a hardware instruction expansion mechanism in the Tensix
coprocessor frontend. A single `MOP` instruction triggers the emission of up to
32,639 instructions at one per cycle, completely decoupling the RISC-V instruction-push
rate from the backend consumption rate.

### Tensix Frontend Pipeline (per thread)

```
RISC-V Ti
    ↓
[Input FIFO 29-32 x 32b]
    ↓
[MOP Expander] ←→ [MopCfg 9 x 32b]     ← 0xFFB80000 (MMIO, write-only)
    ↓
[FIFO 8 x 32b]
    ↓
[Replay Expander] ←→ [Replay Buffer 32 x 32b]   ← no CPU address, internal only
    ↓
[FIFO 2 x 32b]
    ↓
[Wait Gate]
    ↓
[Backend execution units]
```

### The Replay Buffer

**32 slots x 32 bits** per thread (3 independent instances for T0/T1/T2). Each entry
holds one raw 32-bit Tensix instruction. Lives inside the coprocessor frontend as
dedicated flip-flop/register-file state — no CPU-visible address.

**Software convention splits it 16/16:**
- Entries 0-15: SFPU sequences
- Entries 16-31: FPU matmul sequences (`replay_buf_offset = 16` in cmath_common.h)

This is not hardware-enforced — you can use any split.

**Recording:** Push `REPLAY(load=1, start=N, count=M)`, then push M instructions.
They get captured into slots N..N+M-1 (mod 32) without executing.

**Playback:** Push `REPLAY(load=0, start=N, count=M)`. The Replay Expander re-emits
those M stored instructions at 1/cycle. Indices wrap mod 32, so you can replay the
same buffer contents multiple times (e.g., count=64 replays all 32 slots twice).

### MOP Templates

There are exactly **2 templates**, hardwired in the MOP Expander. You cannot define new ones.

#### Template 1: Double-Nested Loop (used by TRISC1 for matmul)

The 9 MopCfg registers at `0xFFB80000`:
```
mop_cfg[0] = OuterCount      (1-127)
mop_cfg[1] = InnerCount      (1-127)
mop_cfg[2] = StartOp         (instruction or NOP)
mop_cfg[3] = EndOp0          (instruction or NOP)
mop_cfg[4] = EndOp1          (instruction or NOP)
mop_cfg[5] = LoopOp          (main loop body — usually a REPLAY instruction)
mop_cfg[6] = LoopOp1         (alternating loop body, or NOP)
mop_cfg[7] = Loop0Last       (replaces LoopOp on final inner iter of FINAL outer)
mop_cfg[8] = Loop1Last       (replaces LoopOp on final inner iter of NON-FINAL outer)
```

Expansion:
```python
for j in range(OuterCount):
    if StartOp != NOP: emit(StartOp)
    for i in range(InnerCount):
        if i < InnerCount - 1:       emit(LoopOp)     # normal iteration
        elif j < OuterCount - 1:     emit(Loop1Last)   # last inner, NOT last outer
        else:                        emit(Loop0Last)   # last inner, last outer (the very end)
        if LoopOp1 != NOP: swap(LoopOp, LoopOp1)      # alternate
    if EndOp0 != NOP: emit(EndOp0)
    if EndOp1 != NOP: emit(EndOp1)
```

**LoFi matmul example:** OuterCount=1, InnerCount=1, LoopOp=REPLAY(16,16).
One MOP → one REPLAY → 16 MVMULs. Total: 16 MVMUL executions.

**HiFi2 example:** OuterCount=1, InnerCount=2, LoopOp=REPLAY(16,16),
EndOp0=SETRWC. Two REPLAYs → 32 MVMULs + 1 SETRWC.

**HiFi4 example:** OuterCount=1, InnerCount=4. Four REPLAYs → 64 MVMULs.

#### Template 0: Mask-Driven (used by TRISC0 for unpackers)

Uses a 32-bit zmask with one bit per face. Bit=0: emit normal unpack instructions.
Bit=1: emit skip instructions. Used for zero-face skipping in sparse tiles.

Called as `TTI_MOP(0, count-1, zmask_lo16)` with `TTI_MOP_CFG(zmask_hi16)`.

### Matmul Setup: Complete Example

```c
// === ONE-TIME INIT ===

// Record 16 MVMULs into replay buffer slots 16-31:
load_replay_buf(16, 16, [&]{
    TTI_MVMUL(CLR_NONE, 0, ADDR_MOD_0, 0);  // slot 16
    TTI_MVMUL(CLR_NONE, 0, ADDR_MOD_1, 0);  // slot 17
    // ... 14 more ...
    TTI_MVMUL(CLR_A,    0, ADDR_MOD_5, 0);  // slot 31
});

// Write MOP config (9 stores to 0xFFB80000):
ckernel_template tmp(1, 1, TT_OP_REPLAY(16, 16, 0, 0));
tmp.program();

// === PER TILE (hot loop) ===

tmp.run();  // = TTI_MOP(1, 0, 0) — ONE .ttinsn instruction
// Hardware does the rest:
//   MOP Expander → REPLAY(16,16) → Replay Expander → 16 MVMULs at 1/cycle
// TRISC1 RISC-V is free during all 16 cycles
```

---

## Tensix Instruction Encoding

### Instruction Format

Every Tensix instruction is a **32-bit word**:
```
[31:24]  8-bit opcode
[23: 0]  24-bit operand (layout varies per instruction)
```

Built via: `#define TT_OP(opcode, params) ((opcode << 24) + params)`

This is a completely separate ISA from RISC-V. Tensix instructions are transported from
the RISC-V cores to the coprocessor via the `.ttinsn` custom RV32 instruction extension.

### How .ttinsn Works

```c
#define INSTRUCTION_WORD(x) __asm__ __volatile__(".ttinsn %0" : : "i"((x)))
```

The encoding of `.ttinsn IMM32` is `IMM32` rotated left by 2 bits. The hardware decodes
it, rotates right 2, and writes the 32-bit Tensix instruction to the instruction push
FIFO at `INSTRN_BUF_BASE = 0xFFE40000`.

### Three Macro Flavors

```c
TT_OP_MOP(...)   // Raw 32-bit Tensix value (compile-time constant)
TT_MOP(...)      // Store to instrn_buffer[0] (memory-mapped push)
TTI_MOP(...)     // Inline .ttinsn (fast path — single RV32 instruction)
```

`TTI_*` is what you use in hot loops. `TT_*` exists for dynamic instruction building.

### Selected Opcodes

| Opcode | Instruction | Opcode | Instruction |
|--------|-------------|--------|-------------|
| 0x01 | MOP | 0x12 | MOVA2D |
| 0x02 | NOP | 0x13 | MOVB2D |
| 0x03 | MOP_CFG | 0x16 | TRNSPSRCB |
| 0x04 | REPLAY | 0x26 | MVMUL |
| 0x08 | MOVD2A | 0x27 | ELWMUL |
| 0x0a | MOVD2B | 0x28 | ELWADD |
| 0x0b | MOVB2A | 0x29 | DOTPV |
| 0x10 | ZEROACC | 0x60 | DMANOP |
| 0x11 | ZEROSRC | | |

### Physical Locations

| Component | Size | Location | CPU access |
|-----------|------|----------|-----------|
| Tensix instruction | 32 bits | — | Pushed via `.ttinsn` |
| MopCfg registers | 9 x 32b per thread | 0xFFB80000 MMIO | Write-only `sw` |
| Replay buffer | 32 x 32b per thread | Inside coprocessor frontend | No CPU address; via REPLAY(load=1) |
| Input FIFO | 29-32 x 32b per thread | Between RISC-V and MOP Expander | Written via INSTRN_BUF_BASE = 0xFFE40000 |
| Dst register file | 1024 x 16 x 16b | Inside coprocessor | RISC-V access at 0xFFBD8000 |

---

## Key Source Files

| Topic | File |
|-------|------|
| SrcA/SrcB shape & banking | tt-isa-documentation/WormholeB0/.../SrcASrcB.md |
| Dst shape & addressing | tt-isa-documentation/BlackholeA0/.../Dst.md |
| LReg definition | tt-isa-documentation/BlackholeA0/.../LReg.md |
| SFPLOAD lane mapping | tt-isa-documentation/BlackholeA0/.../SFPLOAD.md |
| SFPSTORE | tt-isa-documentation/BlackholeA0/.../SFPSTORE.md |
| Unpack pipeline | tt-isa-documentation/WormholeB0/.../Unpackers/README.md |
| Pack pipeline | tt-isa-documentation/WormholeB0/.../Packers/README.md |
| CLEARDVALID / SETDVALID | tt-isa-documentation/WormholeB0/.../CLEARDVALID.md |
| MOP Expander | tt-isa-documentation/WormholeB0/.../MOPExpander.md |
| REPLAY buffer | tt-isa-documentation/WormholeB0/.../REPLAY.md |
| MOP instruction | tt-isa-documentation/WormholeB0/.../MOP.md |
| .ttinsn encoding | tt-isa-documentation/BlackholeA0/.../PushTensixInstruction.md |
| Compute pipeline overview | boop-docs/llk-sfpi/tensix-compute-pipeline.md |
| Tile memory map | boop-docs/blackhole/architecture.md |
| Instruction macros | tt-llk/tt_llk_blackhole/common/inc/ckernel_ops.h |
| MOP template code | tt-llk/tt_llk_blackhole/common/inc/ckernel_template.h |
| Math common (semaphores, replay offset) | tt-llk/tt_llk_blackhole/common/inc/cmath_common.h |
| Matmul MOP setup | tt-llk/tt_llk_blackhole/llk_lib/llk_math_matmul.h |
| SFPU types enum | tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu_types.h |
| SFPI hardware intrinsics | sfpi/include/blackhole/sfpi_hw.h |
| SFPI C++ wrapper | sfpi/include/sfpi.h |
