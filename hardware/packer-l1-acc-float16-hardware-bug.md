# Packer L1 Accumulation: IEEE Float16 Hardware Bug

The packer's L1 accumulation path (`PACKER_L1_ACC`) produces **NaN values when operating on IEEE Float16 (A-exponent) data**. This is a hardware-level bug on Blackhole P100A, confirmed deterministic and reproducible. Float16_b (B-exponent / bfloat16) and Float32 L1 accumulation work correctly.

## Summary

| Format | L1 Accumulation | Status |
|--------|----------------|--------|
| Float16_b (bfloat16) | Read-add-write in L1 | **Works** |
| Float32 | Read-add-write in L1 | **Works** |
| Float16 (IEEE half) | Read-add-write in L1 | **Broken — produces NaN** |

## What PACKER_L1_ACC Does

When `llk_pack_reconfig_l1_acc(1)` is called, the packer hardware performs a fused read-add-write cycle instead of a simple write:

1. **Read** existing tile data from the L1 CB write address
2. **Add** the DST register value to it
3. **Write** the sum back to L1

This is used in matmul to accumulate partial sums across K-dimension blocks without the overhead of a full unpack→copy_tile→DST reload cycle. The hardware sets `Pack_L1_Acc=1` and `Disable_pack_zero_flags=1` in the THCON packer section config registers.

```
Standard pack:     DST ──────────────────────> L1 (write)
L1 accumulation:   DST ──┐                 ┌─> L1 (write)
                         ADD ◄── L1 (read) ─┘
```

## The Bug

When the packer's L1 accumulation operates on **IEEE Float16 (A-exponent, 5-bit exponent, 10-bit mantissa)** tiles, it produces corrupted values. The corrupted values are always NaN with specific bit patterns:

| Raw value | IEEE Float16 interpretation |
|-----------|----------------------------|
| `0x7fff` | +NaN (exp=0x1f, mantissa=0x3ff) |
| `0xffff` | -NaN (exp=0x1f, mantissa=0x3ff) |

These are all-ones patterns in the sign+exponent+mantissa fields.

### Characteristics

- **Deterministic**: exactly the same count and positions on every run with the same inputs
- **1 corrupted value per affected tile**: each bad tile has exactly one NaN element at a seemingly random intra-tile position (varying face, row, column)
- **Scales with accumulation count**: more L1 accumulation cycles → more corrupted tiles
- **Scattered across cores**: no spatial clustering by core, row, or column

### Reproduction data (blackhole-py matmul, `F16=1 TT_USB=1`)

5120×4096×5632 matmul, inputs uniform in [-0.5, 0.5], subblock 8h×1w:

| K | in0_block_w | num_blocks | L1 acc cycles | Bad tiles |
|---|-------------|-----------|---------------|-----------|
| 128 | 4 | 1 | 0 | 0 |
| 256 | 4 | 2 | 0 | 0 |
| 512 | 4 | 4 | 2 | 25 |
| 1024 | 4 | 8 | 6 | 34 |
| 2048 | 4 | 16 | 14 | 60 |
| 4096 | 4 | 32 | 30 | 97 |

`num_blocks=1` has zero L1 acc cycles (only one block, packs directly to output). `num_blocks=2` has zero L1 acc cycles (block 0 writes to intermediate CB, block 1 reloads and writes to output — no accumulation). L1 accumulation engages starting at `num_blocks=3` (block 1 calls `llk_pack_reconfig_l1_acc(1)`).

### Sample corrupted positions

```
[  241, 4150] tile=(7,129)  face=(1,1) intra=(1,6)   raw=0xffff  ref=-0.878
[  243,  852] tile=(7,26)   face=(1,1) intra=(3,4)   raw=0x7fff  ref=4.750
[  324,  792] tile=(10,24)  face=(0,1) intra=(4,8)   raw=0xffff  ref=0.845
[  504, 3704] tile=(15,115) face=(1,1) intra=(8,8)   raw=0x7fff  ref=9.926
[  834, 2114] tile=(26,66)  face=(0,0) intra=(2,2)   raw=0x7fff  ref=-3.276
```

No pattern in face, intra-tile position, or reference value. The sign of the NaN does not consistently match the expected sign.

## Why Float16_b Works

Float16_b (bfloat16) uses B-exponent (8-bit exponent, 7-bit mantissa) — the same exponent format as Float32 and the FPU's internal representation. The packer's L1 accumulation hardware appears to be designed and tested for B-exponent formats.

IEEE Float16 uses A-exponent (5-bit exponent, 10-bit mantissa). The L1 accumulation read-add-write cycle likely mishandles the A-exponent bit layout during the addition step, producing garbage for specific element values or positions.

## How tt-metal Avoids This

tt-metal **never uses IEEE Float16 for the intermediate/partials CB** when L1 accumulation is active. From every matmul program factory:

```cpp
// matmul_multicore_reuse_mcast_2d_program_factory.cpp:87-90
tt::DataFormat interm0_data_format = packer_l1_acc_en
    ? (fp32_dest_acc_en ? tt::DataFormat::Float32 : tt::DataFormat::Float16_b)
    : (fp32_dest_acc_en ? tt::DataFormat::Float32 : output_data_format);
```

When `packer_l1_acc_en=true`, the intermediate CB is **always Float16_b or Float32**, never Float16. This sidesteps the hardware bug entirely.

However, this approach requires the compiler to support **separate `pack_src_format` and `pack_dst_format` per CB**, because the DST register data format (determined by the input exponent precision) may differ from the intermediate CB format. tt-metal's `data_format.cpp` handles this by computing `pack_src_format` and `pack_dst_format` independently:

```cpp
// data_format.cpp — pack_src for Float16 with fp32_dest_acc_en
} else if (data_format == DataFormat::Float16) {
    pack_src_format = DataFormat::Float16_b;  // match DST's B-exponent output
}
```

## Workarounds

| Approach | Complexity | Performance impact |
|----------|-----------|-------------------|
| **Disable L1 acc for Float16**: use standard spill-reload (unpack→copy_tile→DST each block) | Medium — requires alternate compute kernel path | ~10-15% slower (extra unpack/copy per block) |
| **Add pack_src/pack_dst splitting to compiler**: match tt-metal's format header generation | High — changes to `compiler.py` header generation | None (matches tt-metal behavior) |
| **Restrict Float16 to small K**: only allow `num_blocks ≤ 2` for Float16 matmul | Low — planner constraint | Limits use cases |
| **Use Float16_b internally**: convert F16↔BF16 in dataflow kernels | Medium — format conversion in readers/writers | Small (NOC-bound anyway) |

## Related: F32_ACC DST Overflow (Fixed)

A separate issue discovered during the same investigation: when `FP32_DEST_ACC_EN=1`, the DST register file capacity halves (16→8 tiles). With `DST_SYNC_MODE=0` (half-sync), each acquire/release cycle only gets 4 tiles. An 8-tile subblock overflows DST, causing register aliasing and completely garbled output (PCC ≈ 0.5).

**Fix**: set `dst_full_sync=True` when `f32_acc=True` — gives the full 8-tile DST per cycle. Confirmed working in blackhole-py.

## Test Commands

```bash
# Reproduce the Float16 L1 acc bug (97 NaN values)
PYTHONPATH=. F16=1 TT_USB=1 uv run examples/matmul_peak.py

# Verify Float16 works with num_blocks=1 (no L1 acc)
PYTHONPATH=. F16=1 TT_USB=1 uv run examples/matmul_peak.py 5120 128 5632

# Verify F32_ACC fix works
PYTHONPATH=. F32_ACC=1 TT_USB=1 uv run examples/matmul_peak.py

# Verify default bf16 unaffected
PYTHONPATH=. TT_USB=1 uv run examples/matmul_peak.py
```
