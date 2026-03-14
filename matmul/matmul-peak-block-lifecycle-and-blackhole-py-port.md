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

## What blackhole-py needs to add/change

### 1) Kernel feature parity

- Support compute-kernel compile defines needed by peak matmul path:
  - `PACKER_L1_ACC`
  - `FP32_DEST_ACC_EN` (optional for bf16 perf, but needed for parity)
  - existing activation/bias defines as needed
- Ensure compute kernels can include and use `compute_kernel_api/pack.h` APIs (already available in deps).

### 2) Compute config surface parity

Extend blackhole-py compute config so host can request matmul modes similar to TT-Metal:

- `math_fidelity`
- `fp32_dest_acc_en`
- `math_approx_mode`
- `packer_l1_acc`
- `dst_full_sync_en` (if required by selected kernel variant)

Then map these to generated compile-time headers/defines.

### 3) Port TT-Metal block lifecycle faithfully

When enabling packer L1 accumulation, mirror TT-Metal logic exactly:

- block-by-block `llk_pack_reconfig_l1_acc(0/1)` transitions
- partial CB pop timing for early non-last blocks
- single reload boundary before final block
- re-init ordering around copy/reload and matmul re-entry

Do not partially transplant just one piece; mismatched CB/pop/reload ordering can reduce performance or break correctness.

### 4) Keep dataflow + compute contract aligned

Ensure CB page counts, tile formats, and aliasing assumptions match the compute lifecycle. In TT-Metal, compute policy and CB policy are coupled.

### 5) Validation protocol

For each change set:

1. Functional check on a small shape.
2. Perf check fast dispatch.
3. Perf check slow dispatch.
4. Repeat after `tt-smi -r` if measurements look unexpectedly low (to rule out stale device state).

## Expected result progression

Typical path on this stack:

1. `matmul_tiles -> matmul_block`: large jump.
2. Full `PACKER_L1_ACC` lifecycle parity + host config parity: second major jump toward TT-Metal peak.
3. Final tuning: dispatch/dataflow and throttle-state effects.

## Existing related docs in boop-docs

Related but not full lifecycle writeups:

- `tt-metal/matmul-fast-path-gap-analysis-2026-02-05.md`
- `llk-sfpi/kernel-fusion.md`

This file is the dedicated lifecycle + porting checklist.
