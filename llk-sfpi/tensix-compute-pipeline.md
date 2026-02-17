# Tensix compute pipeline: TRISC, FPU, SFPU, MOP

How the three TRISC processors coordinate to move tiles through the math pipeline, and how matmul works at the instruction level.

## The three TRISC processors

Each Tensix core has three RISC-V processors that run **in parallel** on the same kernel source:

| Processor | Define | Role |
|-----------|--------|------|
| TRISC0 | `TRISC_UNPACK` | Unpacks tiles from circular buffers (L1) into SrcA/SrcB registers |
| TRISC1 | `TRISC_MATH` | Runs FPU/SFPU math on SrcA/SrcB, writes results to DST registers |
| TRISC2 | `TRISC_PACK` | Packs tiles from DST registers back to circular buffers (L1) |

The same `.cpp` file is compiled **three times** with different defines. Guard blocks select what each processor sees:

```cpp
#ifdef TRISC_MATH
  // only TRISC1 compiles this
#endif
```

The macros `UNPACK((...))`, `MATH((...))`, `PACK((...))` are shorthand -- each expands its argument only on the matching processor:

```cpp
// from common_globals.h
#ifdef TRISC_MATH
  #define MATH(x) x
#else
  #define MATH(x)
#endif
```

## Register files

```
L1 (circular buffers)
  |
  v
[Unpacker] ---> SrcA (16x16 face register, holds in1/B for matmul)
            \-> SrcB (16x16 face register, holds in0/A for matmul)
                  |
                  v
              [FPU / SFPU] ---> DST (destination register, 32x32 tile capacity)
                                  |
                                  v
                              [Packer] ---> L1 (output circular buffer)
```

**Important for matmul:** the operand mapping is swapped internally:
- `in0` (your "A" matrix CB) loads into **SrcB**
- `in1` (your "B" matrix CB) loads into **SrcA**
- MVMUL computes `D = B * A`, i.e. `D[8,16] = SrcB[8,16] * SrcA[16,16]`

### SrcA / SrcB physical layout

Each source register file has:
- **2 banks × 64 rows × 16 columns × 19-bit** data
- Double-buffered between the unpackers and the matrix unit

The 19-bit width caps input precision at **TF32** (1+8+10 bits). FP32 is truncated to TF32 on load (losing 13 mantissa bits). Fidelity phases compensate by multiplying different mantissa bit slices across passes — LoFi uses only the top bits, HiFi4 uses all available slices. For full FP32 element-wise ops, use the SFPU (via LReg/Dst32b), which is precise but ~64× slower than the FPU.

### DST physical layout

Same storage viewed two ways:
- **Dst16b mode:** 1024 rows × 16 cols × 16-bit → holds **16 tiles** of 32×32 (8 per half)
- **Dst32b mode:** 512 rows × 16 cols × 32-bit → holds **8 tiles** (4 per half)

One 32×32 tile occupies 64 consecutive Dst rows. From SFPI, each `dst_reg[row]` is a 32-element vector with stride 2, so a tile spans `dst_reg[0..31]`.

## DST double-buffering and semaphores

DST has two halves. MATH and PACK alternate between them using hardware semaphores:

```
MATH thread                          PACK thread
-----------                          -----------
tile_regs_acquire()                  tile_regs_wait()
  SEMWAIT(MATH_PACK, STALL_ON_MAX)    SEMWAIT(MATH_PACK, STALL_ON_ZERO)
  ... write to DST half A ...          ... read from DST half B ...
tile_regs_commit()                   pack_tile(0, cb_out)
  SEMPOST(MATH_PACK)                 tile_regs_release()
  flip to DST half B                   ZEROACC(half B)
                                       SEMGET(MATH_PACK)
                                       flip to DST half A
```

- `tile_regs_acquire()` -- MATH waits until PACK frees a DST half
- `tile_regs_commit()` -- MATH signals PACK that data is ready, flips to other half
- `tile_regs_wait()` -- PACK waits for MATH to produce data
- `tile_regs_release()` -- PACK clears the used half, signals MATH it's free

## FPU vs SFPU

Two different compute units share the DST register file:

| Unit | What it does | Instruction prefix |
|------|-------------|-------------------|
| **FPU** | Matrix multiply (systolic). Reads SrcA + SrcB, accumulates into DST. | `MVMUL` (opcode `0x26`) |
| **SFPU** | Element-wise vector ops. Reads/writes DST directly. | `SFPMUL`, `SFPMAD`, `SFPLOAD`, `SFPSTORE`, etc. |

FPU handles matmul. SFPU handles everything else (activations, eltwise, reductions). They cannot run simultaneously -- a kernel does FPU work (matmul) then SFPU work (post-processing) on the same DST data.

### Why the FPU is ~64× faster than the SFPU

The performance gap comes from how each unit accesses data:

- **FPU (`MVMUL`)**: processes an **8×16 = 128 element** chunk per cycle through a systolic array, reading directly from SrcA/SrcB and accumulating into Dst. One instruction, 128 MACs.
- **SFPU (`SFPMAD`)**: operates on **32 elements** per instruction (one LReg), at 2-cycle latency. Each SFPLOAD/SFPSTORE transfers a **4×8 = 32 element slice** of Dst (4 consecutive rows × 8 even-or-odd columns). Processing a full 32×32 tile requires 16+ load/compute/store rounds.

At 1 GHz: `MVMUL` = 4.096 TFLOP/s per core, `SFPMAD` = 0.064 TFLOP/s per core.

The SFPU's advantage is **full 32-bit precision** on all operands (via LReg), whereas the FPU truncates inputs to ≤19 bits (TF32). The architecture is designed so the FPU handles bulk matmul throughput and the SFPU handles element-wise post-processing (activations, normalization, etc.) where the 64× slowdown doesn't matter because these ops are applied once per output tile rather than in an inner loop.

## MOP: the hardware loop engine

The MOP (Micro-Op Program) is a hardware double-nested loop that replays instruction sequences without RISC-V overhead:

```
LOOP_OUTER: <outer_count>
  START_OP
  LOOP_INNER: <inner_count>
    LOOP_OP0        (often a replay_insn that triggers the replay buffer)
    LOOP_OP1        (replaced on last iteration with special end ops)
  END_LOOP_INNER
  END_OP0
  END_OP1
END_LOOP_OUTER
```

The MOP is configured by writing to memory-mapped config registers:

```cpp
volatile uint *mop_cfg = reinterpret_cast<volatile uint *>(TENSIX_MOP_CFG_BASE);
mop_cfg[0] = outer_loop_len;
mop_cfg[1] = inner_loop_len;
mop_cfg[2] = start_op;
mop_cfg[3] = end_op0;  // ... etc
```

Triggered by `TTI_MOP(1, 0, 0)` which `ckernel_template::run()` wraps.

### Replay buffer

The replay buffer is a small hardware instruction FIFO. You record instructions into it, then the MOP can reference them as loop body operations:

```cpp
// Record 16 instructions starting at slot 0
load_replay_buf(0, 16, [&]{
  TTI_MVMUL(CLR_NONE, 0, ADDR_MOD_0, 0);  // these get captured
  TTI_MVMUL(CLR_NONE, 0, ADDR_MOD_1, 0);  // into the replay buffer
  // ... 14 more ...
});

// Create a MOP loop that replays those 16 instructions
ckernel_template tmp(1, 1, lltt::replay_insn(0, 16));
tmp.program();  // writes to MOP config registers

// Execute the MOP
ckernel_template::run();  // emits TTI_MOP(1, 0, 0)
```

## MVMUL: the matrix multiply instruction

`MVMUL` (opcode `0x26`) is a single FPU instruction that computes:

```
DST[8, 16] += SrcB[8, 16] * SrcA[16, 16]
```

One MVMUL processes 8 rows of output. A full 32x32 tile requires 16 MVMUL instructions across 4 face pairs:

```
Face iteration for 32x32 tile matmul (non-transposed):

  B0*A0 (2x MVMUL)  ->  B0*A1 (2x MVMUL)  ->  B2*A0 (2x MVMUL)  ->  B2*A1 (2x MVMUL)
  B1*A2 (2x MVMUL)  ->  B1*A3 (2x MVMUL)  ->  B3*A2 (2x MVMUL)  ->  B3*A3 (2x MVMUL)
```

Each pair of MVMULs covers one 16x16 face (2 x 8 rows = 16 rows).

### ADDR_MOD: hardware auto-increment

Each MVMUL references an ADDR_MOD slot (0-7) that tells the hardware how to advance SrcA, SrcB, and DST pointers after execution:

```cpp
addr_mod_t {
  .srca = {.incr = 0,  .clr = 0, .cr = 0},   // SrcA stays (reused across 8-row chunks)
  .srcb = {.incr = 8,  .clr = 0, .cr = 0},   // SrcB advances 8 rows
  .dest = {.incr = 8,  .clr = 0, .cr = 0},   // DST advances 8 rows
}.set(ADDR_MOD_0);  // inner loop step

addr_mod_t {
  .srca = {.incr = 16, .clr = 0, .cr = 0},   // SrcA advances to next face
  .srcb = {.incr = 0,  .clr = 0, .cr = 1},   // SrcB resets (carry-reset)
  .dest = {.incr = 8,  .clr = 0, .cr = 0},   // DST continues
}.set(ADDR_MOD_1);  // face boundary
```

The 16-instruction MVMUL sequence alternates between ADDR_MOD slots to walk through all four faces correctly.

### TTI_MVMUL encoding

```c
#define TT_OP_MVMUL(clear_dvalid, instr_mod19, addr_mode, dst) \
    TT_OP(0x26, (((clear_dvalid) << 22) + ((instr_mod19) << 19) + ((addr_mode) << 14) + ((dst) << 0)))
```

- `clear_dvalid` (2 bits): `CLR_NONE`, `CLR_A`, or `CLR_B` -- clears SrcA/SrcB data-valid after this instruction
- `instr_mod19` (3 bits): 0 = full BW (4 rows per cycle), 1 = quarter BW
- `addr_mode` (5 bits): which ADDR_MOD slot to use for pointer auto-increment
- `dst` (14 bits): destination address

The final MVMUL in a tile typically uses `CLR_A` or `CLR_B` to signal the unpacker that source registers are free for reloading.

## SETRWC: resetting source register counters

After each tile's matmul, source register counters must be reset so the next tile starts from address 0:

```cpp
TTI_SETRWC(p_setrwc::CLR_B, 0, 0, 0, 0, p_setrwc::SET_ABD_F);
```

`CLR_B` clears SrcB's data-valid. `SET_ABD_F` resets the A, B, D, and fidelity counters.

## Math fidelity

Matmul supports multiple fidelity levels that trade accuracy for speed:

| Fidelity | Phases | Speed | Notes |
|----------|--------|-------|-------|
| LoFi | 0 | Fastest (1x) | Single pass, lowest precision |
| HiFi2 | 2 | ~0.5x | Two passes with fidelity phase increment |
| HiFi3 | 3 | ~0.33x | Three passes |
| HiFi4 | 4 | ~0.25x | Four passes, highest precision |

Higher fidelity re-runs the MVMUL sequence multiple times with different fidelity phase settings (controlled by ADDR_MOD_5's fidelity increment field).

## Putting it all together: matmul compute kernel

Here's the full pattern using `mm_init` for setup and raw FPU ops for compute:

```cpp
#include <cstdint>
#include "compute_kernel_api/matmul.h"
#ifdef TRISC_MATH
  #include "ckernel_ops.h"
  #include "cmath_common.h"
  #include "ckernel_template.h"
#endif

namespace NAMESPACE {
void MAIN {
  constexpr tt::CBIndex cb_a = tt::CBIndex::c_0;
  constexpr tt::CBIndex cb_b = tt::CBIndex::c_1;
  constexpr tt::CBIndex cb_out = tt::CBIndex::c_16;

  // mm_init programs all three TRISCs:
  //   TRISC0: configure unpacker for AB matmul mode
  //   TRISC1: set ADDR_MOD registers, record MVMUL sequence into replay buffer, program MOP
  //   TRISC2: configure packer for output format
  mm_init(cb_a, cb_b, cb_out);

  for (uint32_t i = 0; i < num_tiles; ++i) {
    tile_regs_acquire();  // MATH waits for free DST half

    for (uint32_t kt = 0; kt < Kt; ++kt) {
      cb_wait_front(cb_a, 1);
      cb_wait_front(cb_b, 1);

      // TRISC0: unpack tiles from CBs into SrcA/SrcB
      UNPACK((llk_unpack_AB_matmul(cb_a, cb_b, 0, 0)));

#ifdef TRISC_MATH
      // Set DST write address (includes double-buffer offset)
      ckernel::math::set_dst_write_addr<DstTileShape::Tile32x32, UnpackDestination::SrcRegs>(0);

      // Run the MOP: replays 16x MVMUL across 4 faces, accumulating into DST
      // Final MVMUL uses CLR_A to free SrcA for next unpack
      ckernel_template::run();

      // Clear SrcB at reuse boundary so unpacker can reload
      TTI_SETRWC(p_setrwc::CLR_B, 0, 0, 0, 0, p_setrwc::SET_ABD_F);
#endif

      cb_pop_front(cb_a, 1);
      cb_pop_front(cb_b, 1);
    }

    tile_regs_commit();            // MATH signals DST data ready
    tile_regs_wait();              // PACK waits for MATH
    cb_reserve_back(cb_out, 1);
    pack_tile(0, cb_out);          // PACK reads DST, writes to output CB
    cb_push_back(cb_out, 1);
    tile_regs_release();           // PACK clears DST half, signals MATH
  }
}
}  // namespace NAMESPACE
```

### What mm_init does vs what the kernel does

| Step | Who | What |
|------|-----|------|
| `mm_init()` | All TRISCs | One-time setup: ADDR_MODs, MOP replay buffer, HW config |
| `UNPACK(llk_unpack_AB_matmul(...))` | TRISC0 | Per-tile: load from CB into SrcA/SrcB |
| `set_dst_write_addr(...)` | TRISC1 | Per-tile: point DST write pointer at correct offset |
| `ckernel_template::run()` | TRISC1 | Per-tile: trigger MOP which replays MVMUL sequence |
| `TTI_SETRWC(CLR_B, ...)` | TRISC1 | Per-tile: reset source counters for next iteration |
| `pack_tile(0, cb_out)` | TRISC2 | Per-tile: read DST, write to output CB |

### Contrast with the high-level API

The high-level `matmul_tiles(cb_a, cb_b, 0, 0, 0)` does exactly the same thing -- it just bundles the UNPACK and MATH calls together:

```cpp
// matmul_tiles expands to:
UNPACK((llk_unpack_AB_matmul(cb_a, cb_b, 0, 0)));
MATH((llk_math_matmul<MATH_FIDELITY, MM_THROTTLE>(0)));
```

Where `llk_math_matmul` calls `set_dst_write_addr` + `ckernel_template::run()` + `TTI_SETRWC`. The explicit version gives you visibility and control over each step.

## Pipeline scheduling constraints

After writing an 8×16 block to DST, the same block **cannot be read for 4 cycles**. This means:
- You need ≥5 distinct 8×16 blocks in flight for a **zero-bubble pipeline**
- For multi-fidelity, the fidelity loop should be the **outer** loop to avoid stalls (each phase writes different blocks before re-reading)

## MOP config registers

The MOP expander is configured through 9 write-only registers at `TENSIX_MOP_CFG_BASE` (`0xFFB80000`). Each TRISC thread has its own set.

**Template 1 (double-nested loop, used for matmul):**

| Register | Field | Purpose |
|----------|-------|---------|
| `MopCfg[0]` | `OuterCount` | Outer loop iterations |
| `MopCfg[1]` | `InnerCount` | Inner loop iterations (e.g. fidelity phases) |
| `MopCfg[2]` | `StartOp` | Emitted once before inner loop |
| `MopCfg[3]` | `EndOp0` | Emitted after inner loop |
| `MopCfg[4]` | `EndOp1` | Emitted after EndOp0 |
| `MopCfg[5]` | `LoopOp0` | Main inner loop body (often a `REPLAY` instruction) |
| `MopCfg[6]` | `LoopOp1` | Alternating inner loop body (or NOP) |
| `MopCfg[7]` | `Loop0Last` | Override LoopOp for last outer iteration |
| `MopCfg[8]` | `Loop1Last` | Override LoopOp for last inner iteration (non-last outer) |

**Template 0 (mask-based, used by unpackers):** uses a 32-bit `zmask` to selectively skip iterations. The high 16 bits are set via `TT_MOP_CFG(zmask >> 16)`, the low 16 via the `TT_MOP` instruction itself.

Always call `mop_sync()` before reprogramming MopCfg -- it blocks until any in-flight MOP expansion finishes.

A single MOP instruction can expand into up to **32,639 backend instructions** (the product of outer × inner × replay length). The MOP emits one instruction per cycle to the backend, so RISC-V is free to set up the next tile's addresses while the current MOP is executing.

## Matmul throttling

Throttling limits FPU throughput by inserting NOP instructions between MVMULs in the MOP replay buffer. It exists for **power/thermal management**, not correctness.

### How it works

Without throttle (`THROTTLE_LEVEL=0`), the replay buffer contains 16 back-to-back MVMULs. With throttle, NOPs are interleaved:

| Level | Throughput | Pattern |
|-------|-----------|---------|
| 0 | 100% (default) | `MVMUL MVMUL MVMUL MVMUL ...` |
| 1 | 73% | 1 NOP per ~3 MVMULs |
| 2 | 67% | 1 NOP per ~2 MVMULs |
| 3 | 50% | 1:1 NOP-to-MVMUL ratio |
| 4 | 40% | ~1.5 NOPs per MVMUL |
| 5 | 33% | 2 NOPs per MVMUL |

The throttled sequence is recorded into the replay buffer at init time, replacing the normal MVMUL-only sequence. The MOP loop structure stays the same.

### Static vs dynamic throttle

**Static (compile-time):** `THROTTLE_LEVEL` is a template parameter on `_llk_math_matmul_init_`. Default is 0. When nonzero, `matmul_configure_mop_throttled` builds a replay buffer with NOPs interleaved. Only supported for full 32×32 tiles.

**Dynamic (runtime, Blackhole only):** `matmul_block` in tt-metal reads an ARC firmware scratch register (`MEM_L1_ARC_FW_SCRATCH`) at runtime. If firmware has flagged thermal constraints, the kernel dynamically switches to the throttled MOP (`MM_THROTTLE_MAX`). This means even a perfectly written kernel can be silently throttled.

### How to tell if a kernel is throttled

- **Static:** check the `THROTTLE_LEVEL` template parameter passed to `_llk_math_matmul_init_`. If 0, no static throttling.
- **Dynamic:** firmware-driven. If throughput is unexpectedly low (e.g. ~130 TFLOPS instead of ~175 TFLOPS on BH LoFi) with everything else correct, dynamic throttle is a likely suspect. The check happens in `compute_kernel_api/matmul.h` inside the `matmul_block` call path.
