# FPU Matmul Fidelity Phases

## Overview

The Tensix FPU matrix engine has **5-bit x 7-bit hardware multipliers** — each multiply consumes at most 5 significand bits from SrcA and 7 significand bits from SrcB. ("Significand" = the implicit leading 1 from IEEE 754 normalized representation, plus some number of explicit mantissa bits.) To achieve higher precision than a single pass allows, the engine runs the same matmul **multiple times**, each time processing a different slice of the significand bits. The partial products accumulate into Dst via `+=`.

This applies to both `MVMUL` (matrix multiply: `Dst += SrcB @ SrcA`) and `ELWMUL` (element-wise: `Dst += SrcA * SrcB`).

## The Fidelity Phase Counter

There's a 2-bit counter called `FidelityPhase` in the RWC (Read/Write Counter) state:

```c
uint2_t FidelityPhase = RWCs[CurrentThread].FidelityPhase;
FidelityPhase += ThreadConfig[CurrentThread].FIDELITY_BASE_Phase;
FidelityPhase &= 3;  // wraps at 4
```

- **Bit 0** controls which SrcA mantissa bits are used
- **Bit 1** controls which SrcB mantissa bits are used

The LLK configures `ADDR_MOD_5` to increment this counter by 1 after each fidelity phase iteration, and clears it when the full tile is done.

## Significand Bit Extraction Per Phase

A quick IEEE 754 refresher: a normalized float stores its mantissa as `1.xxxxx` but the leading `1` is implicit (not stored in the bit encoding). The full significand is `1 + mantissa_bits`. When we say "5 bits from SrcA," we mean 5 bits of significand — the implicit 1 plus 4 explicit mantissa bits.

### Notation: A_hi, A_lo, B_hi, B_lo

We split each operand's significand into two halves:

- **A_hi** = implicit 1 + top 4 mantissa bits of SrcA (the most significant part)
- **A_lo** = remaining lower mantissa bits of SrcA (the residual: `A - A_hi`)
- **B_hi** = implicit 1 + top 6 mantissa bits of SrcB
- **B_lo** = remaining lower mantissa bits of SrcB (the residual: `B - B_hi`)

The full value is `A = A_hi + A_lo` and `B = B_hi + B_lo`. HiFi4 uses the distributive property to recover the full product:

```
A * B = (A_hi + A_lo) * (B_hi + B_lo)
      = A_hi*B_hi + A_lo*B_hi + A_hi*B_lo + A_lo*B_lo
        phase 0     phase 1     phase 2     phase 3
```

### SrcA (5 significand bits per phase, controlled by FidelityPhase bit 0)

```c
float SrcAFidelityBits(float x, uint2_t FidelityPhase) {
  union {uint32_t u; float f;} bits;
  bits.f = x;
  if ((FidelityPhase & 1) == 0) {
    bits.u &= 0xfff80000; // Sign + Exp + implicit 1 + top 4 mantissa bits → A_hi
    return bits.f;
  } else {
    bits.u &= 0xfff83fff; // Isolate next 5 mantissa bits
    return x - bits.f;     // → A_lo (the residual = A - A_hi)
  }
}
```

### SrcB (7 significand bits per phase, controlled by FidelityPhase bit 1)

```c
float SrcBFidelityBits(float x, uint2_t FidelityPhase) {
  union {uint32_t u; float f;} bits;
  bits.f = x;
  if ((FidelityPhase & 2) == 0) {
    bits.u &= 0xfffe0000; // Sign + Exp + implicit 1 + top 6 mantissa bits → B_hi
    return bits.f;
  } else {
    bits.u &= 0xfffe1fff; // Isolate next 4 mantissa bits
    return x - bits.f;     // → B_lo (the residual = B - B_hi)
  }
}
```

Note: The hardware multiplier tree is physically 5x7 bits wide. Phase 0 feeds it 5 significand bits from SrcA (implicit 1 + 4 mantissa) and 7 from SrcB (implicit 1 + 6 mantissa). Phase 1 feeds 5 explicit mantissa bits from SrcA (no implicit 1 — it was already consumed in phase 0's A_hi) with the same 7 SrcB bits.

## Math Fidelity Modes

The `MathFidelity` enum controls how many phases run:

| Mode  | Enum | Phases | What's computed (accumulated into Dst) | Throughput |
|-------|------|--------|----------------------------------------|------------|
| LoFi  | 0    | 1      | A_hi * B_hi | Full (1x) |
| HiFi2 | 2    | 2      | A_hi * B_hi **+ A_lo * B_hi** | 1/2x |
| HiFi3 | 3    | 3      | A_hi * B_hi + A_lo * B_hi **+ A_hi * B_lo** | 1/3x |
| HiFi4 | 4    | 4      | A_hi * B_hi + A_lo * B_hi + A_hi * B_lo **+ A_lo * B_lo** | 1/4x |

HiFi4 computes all four terms of the distributive expansion `(A_hi + A_lo) * (B_hi + B_lo)`, recovering full precision. Each lower mode drops the least significant cross-terms.

### Phase-to-bits mapping (BF16 mantissa as 11-bit value including hidden bit)

From the golden model (`golden_generators.py`):

```python
FP_FIDELITY_ITER_MASK = [
    (0b11111000000, 0b11111110000),  # Phase 0: SrcA top 5, SrcB top 7
    (0b00000111110, 0b11111110000),  # Phase 1: SrcA bot 5, SrcB top 7
    (0b11111000000, 0b00000001111),  # Phase 2: SrcA top 5, SrcB bot 4
    (0b00000111110, 0b00000001111),  # Phase 3: SrcA bot 5, SrcB bot 4
]
```

## How the LLK Implements This

### MOP and Replay Buffer (two separate things)

The **MOP** (Micro-Op Processor) is a small hardware loop controller that sits in front of the FPU. It has an outer loop count and an inner loop count; on each iteration it issues a configured instruction.

The **replay buffer** is a separate 16-entry instruction FIFO. You record a sequence of up to 16 FPU instructions into it, then `TT_OP_REPLAY` replays all of them as a single "macro instruction."

For matmul, 16 MVMUL instructions (covering all the 8x16 sub-blocks of a 32x32 tile) get recorded into the replay buffer. The MOP's inner loop then runs that replay N times — once per fidelity phase. The **RWCs are not part of either** — they're persistent hardware state that lives alongside the FPU. The MOP and replay buffer just issue instructions; the RWCs track where those instructions read/write and which fidelity phase is active.

### MOP configuration

In `llk_math_matmul.h`, the MOP is configured with the fidelity loop:

```cpp
constexpr int NUM_FIDELITY_PHASES = get_math_num_fidelity_phases(MATH_FIDELITY);
// → just (MATH_FIDELITY & 0x7), so LoFi=0, HiFi2=2, HiFi3=3, HiFi4=4

constexpr bool high_fidelity = NUM_FIDELITY_PHASES > 0;
constexpr uint inner_loops = high_fidelity ? NUM_FIDELITY_PHASES : 1;

// Programs the MOP:
//   outer_loop = 1
//   inner_loop = NUM_FIDELITY_PHASES (or 1 for LoFi)
//   body = TT_OP_REPLAY (replays the 16 MVMUL instructions from the replay buffer)
//   last_inner_loop_instr = TT_OP_MVMUL with ADDR_MOD_5 (increments fidelity counter)
ckernel_template tmp(1, inner_loops, TT_OP_REPLAY(...), TT_OP_MVMUL(...));
```

### Address modifier setup for fidelity stepping

```cpp
// ADDR_MOD_5: fires at end of each fidelity phase inner loop iteration
addr_mod_t {
    .srca     = {.incr = 0, .clr = 1, .cr = 0},  // reset SrcA pointer
    .srcb     = {.incr = 0, .clr = 1, .cr = 0},  // reset SrcB pointer
    .dest     = {.incr = 0, .clr = 0, .cr = 1},   // reset Dst pointer
    .fidelity = {.incr = 1, .clr = 0},             // INCREMENT fidelity counter
}.set(ADDR_MOD_5);

// ADDR_MOD_3: fires at end of all phases for a tile — clears fidelity
// and resets SrcA or SrcB for the next tile
```

The key insight: after each inner loop iteration (one fidelity phase), SrcA and SrcB pointers are reset to the same data, Dst is rewound to accumulate on top of the previous phase's result, and the fidelity counter increments by 1. The hardware automatically uses different mantissa bits based on the counter value.

## Source Files

- ISA functional model: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MVMUL.md` and `ELWMUL.md`
- LLK matmul config: `tt_llk_blackhole/llk_lib/llk_math_matmul.h` (also `tt_llk_quasar/`)
- Fidelity phase helpers: `tt_llk_blackhole/common/inc/cmath_common.h` (`get_math_num_fidelity_phases`, `get_math_fidelity_increment`)
- Golden model with bitmasks: `tt_llk/tests/python_tests/helpers/golden_generators.py`
- MathFidelity enum: `tt_metal/api/tt-metalium/base_types.hpp`
- Tech report: `tt-metal/tech_reports/matrix_engine/matrix_engine.md`
