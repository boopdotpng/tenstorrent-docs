# FP32 Destination Accumulation on Blackhole

## Overview

Blackhole Tensix cores can accumulate matmul partial results in FP32 (32-bit) in the DST registers instead of the default FP16 (bfloat16). This gives better numerical precision at the cost of halved DST capacity and ~26% lower throughput.

## Benchmark Results (P100A, 110 cores, 4096x4096x4096)

| Config         | TFLOPS | Latency |
|----------------|--------|---------|
| LoFi  fp16 acc | 175.5  | 0.783ms |
| LoFi  fp32 acc | 129.7  | 1.060ms |
| HiFi2 fp16 acc | 173.6  | 0.792ms |
| HiFi2 fp32 acc | 127.7  | 1.076ms |
| HiFi4 fp16 acc | 115.6  | 1.189ms |
| HiFi4 fp32 acc | 113.7  | 1.209ms |

Key takeaway: **HiFi2 fp16 acc is the sweet spot** — nearly identical throughput to LoFi with better precision. FP32 acc costs ~26% throughput at LoFi/HiFi2, less at HiFi4 (where math is already the bottleneck).

## How It Works

### Hardware mechanism

The ALU_ACC_CTRL register has two bits:
- **Bit 29** (`Fp32_enabled`): FP32 in the matrix engine DST
- **Bit 30** (`SFPU_Fp32_enabled`): FP32 in the SFPU vector engine DST

When enabled, each DST element occupies 4 bytes instead of 2. The total DST register file is fixed-size, so capacity halves.

### DST capacity table

| fp32_dest_acc | dst_sync   | Tiles per half | Total tiles |
|---------------|------------|----------------|-------------|
| false         | SyncHalf   | 8              | 16          |
| false         | SyncFull   | 16             | 16          |
| true          | SyncHalf   | 4              | 8           |
| true          | SyncFull   | 8              | 8           |

### Subblock constraint

Output subblock must fit in one DST half:
- **FP16 acc (SyncHalf)**: `out_subblock_h * out_subblock_w <= 8` (e.g. 4×2)
- **FP32 acc (SyncHalf)**: `out_subblock_h * out_subblock_w <= 4` (e.g. 2×2)

This is the main source of the throughput hit — smaller subblocks = more iterations = more overhead.

## How to Switch a blackhole-py Kernel from FP16 to FP32 Accumulation

### 1. CkernelConfig — flip one flag

```python
cfg = CkernelConfig(
  input_format=DataFormat.Float16_b,
  output_format=DataFormat.Float16_b,
  math_fidelity=MathFidelity.HiFi2,
  dst_accum_mode=True,   # <-- was False
)
```

This generates `constexpr bool DST_ACCUM_MODE = true;` in `chlkc_dst_accum_mode.h`. All LLK functions (`matmul_block`, `pack_tile`, `copy_tile`, etc.) are templated on this constant and handle wider registers automatically. **No kernel C code changes needed.**

### 2. Shrink subblock

```python
# fp16 acc
OUT_SUBBLOCK_H, OUT_SUBBLOCK_W = 4, 2  # 8 tiles

# fp32 acc
OUT_SUBBLOCK_H, OUT_SUBBLOCK_W = 2, 2  # 4 tiles
```

Update derived constants:
```python
IN0_NUM_SUBBLOCKS = PER_CORE_M // OUT_SUBBLOCK_H  # doubles
IN0_SUBBLOCK_NUM_TILES = OUT_SUBBLOCK_H * IN0_BLOCK_W  # halves
OUT_SUBBLOCK_NUM_TILES = OUT_SUBBLOCK_H * OUT_SUBBLOCK_W  # halves
```

### 3. CB24 (spill buffer) page size doubles

Intermediate tiles are FP32 — 4 bytes/element:

```python
TILE_BYTES_F32 = 32 * 32 * 4  # 4096 bytes

cb_config = {
  0:  (CB0_PAGES, TILE_BYTES),       # in0: fp16 unchanged
  1:  (CB1_PAGES, TILE_BYTES),       # in1: fp16 unchanged
  16: (CB16_PAGES, TILE_BYTES),      # output: fp16 unchanged
  24: (CB24_PAGES, TILE_BYTES_F32),  # intermediate: FP32
}
```

The packer automatically converts FP32→FP16 when packing to the FP16 output CB16. No explicit format conversion needed.

### 4. That's it

The compute kernel C code (matmul_block, pack_tile, copy_tile, PACKER_L1_ACC flow) is **identical** between FP16 and FP32 accumulation. The LLK handles everything via compile-time templates.

## PACKER_L1_ACC + FP32 Compatibility

There is a known issue (tt-metal #28800) where L1 accumulation doesn't work correctly with `fp32_dest_acc_en=true` due to format conversion happening before accumulation in the packer pipeline. The workaround is to use the manual spill/reload path (copy_tile loop every block) instead of hardware L1 accumulation when in FP32 mode.

In tt-metal's factory code:
```cpp
// Only enable packer l1 accumulation when there are num_blocks > 2
bool packer_l1_acc_en = packer_l1_acc && (num_blocks > 2);

// Intermediate format matches accumulation precision
tt::DataFormat interm0_data_format = packer_l1_acc_en
  ? (fp32_dest_acc_en ? tt::DataFormat::Float32 : tt::DataFormat::Float16_b)
  : (fp32_dest_acc_en ? tt::DataFormat::Float32 : output_data_format);
```

## Target TFLOPS Summary

| Mode              | 110 cores | Notes |
|-------------------|-----------|-------|
| HiFi2 fp16 acc    | ~170      | Best throughput-to-precision ratio |
| HiFi2 fp32 acc    | ~130      | When precision matters |
| LoFi fp16 acc      | ~175      | Max throughput, low precision |
