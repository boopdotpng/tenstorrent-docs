# Kernel Fusion: Matmul + SFPU Epilogues on Blackhole

How to run matmul then apply elementwise ops (add, relu, gelu, etc.) to the result without round-tripping through L1. This is the key to high-performance fused kernels.

## The core insight: FPU and SFPU share DST

```
                  ┌──────────────────────────┐
  SrcA ──────────►│                          │
                  │  FPU (Matrix Engine)     ├──────► DST registers
  SrcB ──────────►│  MVMUL instructions      │          ▲  │
                  └──────────────────────────┘          │  │
                                                        │  ▼
                  ┌──────────────────────────┐      ┌──────────┐
                  │  SFPU (Vector Engine)    │◄─────┤  LReg    │
                  │  SFPLOAD/SFPSTORE       ├─────►│  (32x32b)│
                  └──────────────────────────┘      └──────────┘
```

FPU writes matmul results to DST. SFPU reads/writes DST via SFPLOAD/SFPSTORE through LReg. They **cannot run simultaneously**, but they share the same DST registers. This means:

1. Do matmul → results land in DST
2. Do SFPU ops → read/modify the same DST data
3. Pack once → write final result to L1

No intermediate pack/unpack. No CB round-trip. The data stays in registers.

## What `mm_init` and `init_sfpu` actually configure

Both are one-time hardware setup calls that program three subsystems independently:

### `mm_init(in0_cb, in1_cb, out_cb)`

| Subsystem | What it programs |
|-----------|-----------------|
| UNPACK | `llk_unpack_hw_configure` + `llk_unpack_AB_matmul_init` — sets up unpacker for dual-input matmul mode (A→SrcB, B→SrcA, note the swap) |
| MATH | `llk_math_matmul_init<FIDELITY>` — records MVMUL instruction sequence into replay buffer, programs MOP, sets ADDR_MODs for face iteration |
| PACK | `llk_pack_hw_configure_disaggregated` + `llk_pack_init` + `llk_pack_dest_init` — configures packer data format and DST sync |

### `init_sfpu(in_cb, out_cb)`

| Subsystem | What it programs |
|-----------|-----------------|
| UNPACK | `llk_unpack_hw_configure` + `llk_unpack_A_init` — sets up unpacker for single-input datacopy mode |
| MATH | `llk_math_eltwise_unary_datacopy_init<A2D>` + `llk_math_pack_sync_init` + `llk_math_hw_configure` — configures datacopy (CB→DST) path |
| PACK | Same as mm_init (format + sync) |

### Key difference

- `mm_init` programs the MATH subsystem for FPU matmul (MVMUL replay buffer + MOP)
- `init_sfpu` programs it for datacopy (CB→DST via FPU A2D path)
- Both configure the same DST sync mechanism (double-buffered halves with semaphores)

### For fusion, you need both

You call `mm_init` first for the matmul. Then before the SFPU epilogue, you need to initialize the SFPU operation — but **not** reinit unpack/pack (DST is already loaded). Just the SFPU-specific setup:

```cpp
// The *_init() calls only configure SFPU address modifiers and config regs
// They do NOT touch unpack/pack or DST contents
exp_tile_init();    // configures SFPU for exp
relu_tile_init();   // configures SFPU for relu
// etc.
```

## Fusion pattern 1: Matmul + SFPU (simple)

This is the simplest case — matmul accumulates into DST, then SFPU operates on DST in-place:

```cpp
mm_init(cb_a, cb_b, cb_out);

for (uint32_t i = 0; i < num_output_tiles; ++i) {
  tile_regs_acquire();

  // === FPU phase: matmul accumulates into DST ===
  for (uint32_t kt = 0; kt < Kt; ++kt) {
    cb_wait_front(cb_a, 1);
    cb_wait_front(cb_b, 1);
    matmul_tiles(cb_a, cb_b, 0, 0, 0);  // DST[0] += A * B
    cb_pop_front(cb_a, 1);
    cb_pop_front(cb_b, 1);
  }

  // === SFPU phase: operate on DST in-place ===
  // Just need the *_init() to reconfigure SFPU, not full reinit
  add_unary_tile_init();
  add_unary_tile(0, scalar_1_0f);  // DST[0] += 1.0

  // === Pack the final result ===
  tile_regs_commit();
  tile_regs_wait();
  cb_reserve_back(cb_out, 1);
  pack_tile(0, cb_out);
  cb_push_back(cb_out, 1);
  tile_regs_release();
}
```

The `add_unary_tile_init()` call just programs SFPU address modifiers. DST contents are untouched. Then `add_unary_tile(0, ...)` runs SFPU instructions that SFPLOAD from DST[0], add the scalar, and SFPSTORE back.

## Fusion pattern 2: Matmul + bias + activation (tt-metal production pattern)

This is what `bmm_large_block_zm_fused_bias_activation.cpp` does. The pattern is more complex because bias requires a second unpack:

```
Matmul accumulation (inner K loop)
  → pack partial results to intermediate CB (spill)
  → reload partials + bias into DST via add_tiles_bcast_rows
  → SFPU activation on DST
  → pack final result
```

The key fusion point (from the actual tt-metal kernel):

```cpp
// After matmul and bias addition are done in DST...

#ifdef SFPU_OP_INIT_ACTIVATION
  // SFPU activation runs on DST tiles before commit
  for (uint32_t i = 0; i < out_subblock_num_tiles; i++) {
    SFPU_OP_FUNC_ACTIVATION  // e.g. relu_tile(i), gelu_tile(i)
  }
  tile_regs_commit();  // only commit AFTER sfpu is done
#else
  tile_regs_commit();  // no sfpu, commit immediately
#endif
```

The `SFPU_OP_INIT_ACTIVATION` and `SFPU_OP_FUNC_ACTIVATION` are compile-time macros injected by the host program factory. The pattern: **do all math (FPU + SFPU) between `tile_regs_acquire()` and `tile_regs_commit()`**, then pack.

## Fusion pattern 3: Raw SFPI (blackhole-py flexibility)

Since you control the runtime, you can skip the LLK wrappers entirely and use raw SFPI:

```cpp
mm_init(cb_a, cb_b, cb_out);

for (...) {
  tile_regs_acquire();

  // Matmul into DST[0]
  for (uint32_t kt = 0; kt < Kt; ++kt) {
    cb_wait_front(cb_a, 1);
    cb_wait_front(cb_b, 1);
    matmul_tiles(cb_a, cb_b, 0, 0, 0);
    cb_pop_front(cb_a, 1);
    cb_pop_front(cb_b, 1);
  }

  // Raw SFPI: add 1.0 to every element in DST[0]
#ifdef TRISC_MATH
  {
    using namespace sfpi;
    vFloat one = 1.0f;
    for (uint32_t v = 0; v < 32; ++v) {
      dst_reg[v] = dst_reg[v] + one;
    }
  }
#endif

  tile_regs_commit();
  tile_regs_wait();
  cb_reserve_back(cb_out, 1);
  pack_tile(0, cb_out);
  cb_push_back(cb_out, 1);
  tile_regs_release();
}
```

No init calls needed for raw SFPI. The `dst_reg` accesses compile to SFPLOAD/SFPSTORE instructions. You're just reading and writing DST directly.

## What you can chain (flexibility summary)

Within a single `tile_regs_acquire()` / `tile_regs_commit()` window:

| Sequence | Works? | Notes |
|----------|--------|-------|
| matmul → SFPU unary (relu, exp, add_scalar, ...) | Yes | Production pattern |
| matmul → multiple SFPU ops chained | Yes | Call `*_init()` between different op types |
| matmul → raw SFPI | Yes | No init needed, just `dst_reg[]` |
| matmul → FPU binary (add_tiles) → SFPU | Needs reconfig | Must reconfigure unpack for the binary input |
| SFPU → matmul | Unusual but possible | Would need `mm_init` / `mm_block_init_short` to reprogram MOP |
| matmul → copy_tile (load more data) → SFPU binary | Yes | copy_tile loads into a different DST slot |

### The reconfig cost

Switching between operation types within a kernel requires reconfiguring hardware state:

- **SFPU op switch** (`relu_tile_init()` → `exp_tile_init()`): Very cheap. Just reprograms SFPU address modifiers and config registers. ~10 instructions.
- **Unpack reconfig** (`reconfig_data_format(old_cb, new_cb)`): Moderate. Reprograms THCON format registers. Needed when switching input CBs with different data formats.
- **Full matmul reinit** (`mm_block_init_short(...)`): Heavier. Reprograms MOP, replay buffer, ADDR_MODs. Needed if you want to do matmul again after switching to a different operation mode.

## Constraints and gotchas

### DST capacity limits your subblock size

- `fp32_dest_acc_en = false`: 16 tiles total, 8 per half (double-buffered)
- `fp32_dest_acc_en = true`: 8 tiles total, 4 per half
- Your fused output subblock must fit in one half

### FPU and SFPU are sequential, not parallel

They share the MATH TRISC (TRISC1). You cannot overlap matmul with SFPU — they execute sequentially on the same processor. The benefit is zero memory traffic, not compute parallelism.

### PACK_RELU: a special case

ReLU can also be fused into the **packer** instead of SFPU:

```cpp
PACK((llk_pack_relu_config(ReluType::ZERO_RELU)));
```

This applies relu during the pack step with zero math overhead. tt-metal uses this for `PACK_RELU` in the fused matmul kernel. For blackhole-py, this is worth knowing about — if your epilogue is just relu, pack-side relu is free.

### The `*_init_short` pattern

tt-metal uses `mm_block_init_short(...)` (not full `mm_init`) when reconfiguring matmul within a loop that already did the full init. The `_short` variant skips HW configure and only reprograms the MOP and address modifiers. Saves ~50% of init overhead.

## LLK test: matmul_and_unary_sfpu_test.cpp

The tt-llk test at `tt_llk/tests/sources/matmul_and_unary_sfpu_test.cpp` demonstrates the exact fusion sequence at the LLK level:

```
MATH thread:
  1. _llk_math_matmul_init_<FIDELITY>()     — program MOP for matmul
  2. _llk_math_matmul_<FIDELITY>(0)          — run matmul, result in DST
  3. _llk_math_dest_section_done_()           — signal PACK, flip DST half
     ... (PACK packs matmul result to intermediate buffer) ...
  4. _llk_math_eltwise_unary_datacopy_init_() — reprogram for datacopy
  5. _llk_math_eltwise_unary_datacopy_()      — reload tile into DST
  6. _llk_math_eltwise_unary_sfpu_init_()     — configure SFPU
  7. call_sfpu_operation(...)                  — run SFPU op on DST
  8. _llk_math_dest_section_done_()           — signal PACK
```

Note: this test does a spill+reload between matmul and SFPU (steps 3-5). This is **not required** for simple fusion — it's an artifact of the test structure. For fusion, you skip the intermediate pack and go directly from matmul to SFPU within the same DST lifetime.

## Blackhole-py specific opportunities

Since you control the full runtime:

1. **Custom firmware**: You can modify TRISC firmware to pre-configure common fusion patterns, avoiding per-kernel init overhead.

2. **Embedded RISC-V in kernels**: You can inline arbitrary RISC-V code alongside SFPI, enabling complex control flow (dynamic epilogue selection, conditional fusion).

3. **Multiple SFPU ops without init overhead**: If you pre-program all needed SFPU address modifiers at kernel start, you can chain ops without per-op `*_init()` calls. The inits are just ADDR_MOD writes — you can do them all upfront.

4. **Direct DST manipulation**: With raw SFPI, you can implement arbitrary elementwise functions. The 32-wide SIMD `vFloat` type supports `+`, `-`, `*`, comparisons, `v_if`/`v_endif` predication, and bit manipulation (`setexp`, `setman`, `setsgn`, `exexp`, `exman9`).

5. **Pack format flexibility**: You can reconfigure the packer between subblocks to write different output formats (e.g., fp32 accumulation → bf16 output) without touching the compute path.

## Practical recipe: matmul + add(1.0) in blackhole-py

For your specific example (matmul then add 1):

```
Compute kernel:
  mm_init(cb_a, cb_b, cb_out)
  loop over output tiles:
    tile_regs_acquire()
    K-loop: matmul_tiles(cb_a, cb_b, 0, 0, 0)  # accumulate in DST[0]
    # Raw SFPI epilogue — no init needed
    MATH:
      for v in 0..31:
        dst_reg[v] = dst_reg[v] + 1.0f
    tile_regs_commit()
    tile_regs_wait()
    pack_tile(0, cb_out)
    tile_regs_release()
```

Total overhead of fusion: 32 SFPLOAD + 32 SFPADD + 32 SFPSTORE instructions. No memory traffic. The matmul itself is ~2048 MVMUL instructions for HiFi4, so the epilogue is ~5% overhead.
