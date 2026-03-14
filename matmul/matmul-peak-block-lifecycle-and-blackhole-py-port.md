# TT-Metal Peak Matmul Block Lifecycle and blackhole-py Port Plan (2026-02-09)

## Scope

This note explains the **compute-side block lifecycle** used by TT-Metal peak matmul kernels, why it is faster than a simple spill/reload loop, and what blackhole-py needs to implement to match it.

Primary reference files:

- `ttnn/cpp/ttnn/operations/matmul/device/kernels/compute/bmm_large_block_zm_fused_bias_activation.cpp`
- `ttnn/cpp/ttnn/operations/matmul/device/factory/matmul_multicore_reuse_mcast_2d_program_factory.cpp`
- `tt_metal/include/compute_kernel_api/matmul.h`
- `tt_metal/include/compute_kernel_api/pack.h`

## Short answer: what is the lifecycle?

At high level, for each output block `(bh, bw)` and K-block iteration `block`:

1. Wait for input tiles (`cb_wait_front` on in0/in1 block windows).
2. For each output subblock:
   - `tile_regs_acquire()`
   - Optionally reload partials into DST (only when needed)
   - Run `matmul_block(...)` in inner-K loop
   - Pack result either to output CB (last K-block) or intermediate partial CB (not last)
   - `tile_regs_release()`
3. Apply block-level partial-buffer maintenance policy (this is the important part).
4. Pop in0/in1 front windows.

The performance-critical difference is in step 3.

## Two partial-accumulation policies

### Policy A: spill/reload every K-block (simpler, slower)

This is the classic pattern:

- Non-last block: pack DST to partial CB
- Next block: reload partial CB into DST
- Repeat for each K-block

Cost: repeated unpack/copy/reinit churn each K-block.

### Policy B: `PACKER_L1_ACC` lifecycle (TT-Metal peak path)

TT-Metal peak kernel uses packer L1 accumulation to avoid repeated reloads:

- Early non-last blocks:
  - enable packer L1 accumulation (`llk_pack_reconfig_l1_acc(1)` after first)
  - pack to partial CB
  - immediately consume/pop completed block-sized partial payloads from partial CB to advance FIFO
- Penultimate block:
  - switch to one final reload boundary (`enable_reload = true` for next/last block)
- Last block:
  - reload once, compute final K contribution, pack final output

Net effect: reload path is paid once near the end instead of every block.

## Why `matmul_block` is necessary but not sufficient

`matmul_block` fixes compute-side operand reuse (SRC/unpack replay efficiency), which is a large gain over `matmul_tiles`.

But TT-Metal peak also depends on:

- compile-time defines and kernel branches (`PACKER_L1_ACC`, `FP32_DEST_ACC_EN`, activation/bias paths)
- exact partial CB lifecycle management
- correct packer reconfiguration timing (`pack_reconfig_data_format`, `llk_pack_reconfig_l1_acc`)

So replacing only `matmul_tiles -> matmul_block` is usually not enough to reach peak.

## Blackhole dynamic throttle note

On Blackhole, `matmul_block` goes through dynamic throttle logic in `compute_kernel_api/matmul.h`:

- reads FW scratch (`MEM_L1_ARC_FW_SCRATCH` parity)
- may switch to throttled MOP (`MM_THROTTLE_MAX`)

If throttle is enabled by FW, throughput can be capped even with a perfect kernel.

For peak matmul, the critical compile-time defines are `PACKER_L1_ACC` and `FP32_DEST_ACC_EN`. The block lifecycle must match the `llk_pack_reconfig_l1_acc` transitions, partial CB pop timing, and reload ordering exactly -- partial transplants break correctness or performance.
