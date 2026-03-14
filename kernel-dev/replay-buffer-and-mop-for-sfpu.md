# Replay buffer and MOP expander for SFPU operations

How to use the Tensix front-end replay buffer and MOP expander to avoid RISC-V loop overhead when executing repetitive SFPU instruction sequences. Covers the two-expander pipeline, the 32-slot replay buffer, `ckernel_template` (MOP Template 1), and practical usage patterns.

See also: `sfpi-execution-model-and-masking.md` for SFPU vector width, face iteration, and per-lane masking.

## Front-end pipeline: MOP expander -> replay expander -> backend

The Tensix coprocessor front-end has two instruction expanders in series, per thread:

```
RISC-V T-core (TRISC_MATH, etc.)
    |
    v
[MOP Expander]        single MOP instruction -> double-nested loop of instructions
    |
    v
[Replay Expander]     REPLAY instruction -> replayed sequence from 32-slot buffer
    |
    v
[Wait Gate]           STALLWAIT conditions gate instruction issue
    |
    v
[Backend Units]       FPU (MatrixUnit), SFPU (VectorUnit), Unpackers, Packers
```

A single `MOP` instruction from the RISC-V can expand through both layers into hundreds of backend instructions. The RISC-V core is free after issuing the MOP.

**Sources:**
- `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOPExpander.md`
- `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/REPLAY.md`

## Replay buffer: 32 slots, instruction-type-agnostic

The replay buffer stores 32 raw 32-bit instruction words per thread. It does not care what instruction type they encode — SFPLOAD, SFPADD, SFPSTORE, MVMUL, INCRWC, etc. are all treated identically.

### REPLAY instruction encoding

```cpp
// ckernel_ops.h (WH and BH)
#define TT_OP_REPLAY(start_idx, len, execute_while_loading, load_mode) \
    TT_OP(0x04, (((start_idx) << 14) + ((len) << 4) + \
                  ((execute_while_loading) << 1) + ((load_mode) << 0)))
```

| Field | Bits | Description |
|---|---|---|
| `start_idx` | u5 | Starting slot index (0-31) |
| `len` | u6 | Number of instructions (0 = 64) |
| `execute_while_loading` | u1 | If 1, execute instructions as they are recorded |
| `load_mode` | u1 | 1 = record next `len` instructions; 0 = replay `len` instructions from buffer |

### Functional model

```python
# Simplified from REPLAY.md
ReplayBuffer = [0] * 32  # per thread

if Load:
    for i in range(Count):
        insn = next_instruction()
        ReplayBuffer[(Index + i) % 32] = insn
        if Exec:
            yield insn          # execute while recording
else:
    for i in range(Count):
        yield ReplayBuffer[(Index + i) % 32]  # replay from buffer
```

### C++ API (lltt.h)

```cpp
// runtime/sfpi/include/lltt.h
namespace lltt {
    template<ExecBool E = NoExec>
    inline void record(unsigned start, unsigned length) {
        __builtin_rvtt_ttreplay(start, length, bool(E), true);   // Load=1
    }

    inline void replay(unsigned start, unsigned length) {
        __builtin_rvtt_ttreplay(start, length, false, false);    // Load=0
    }

    // Returns a REPLAY instruction word for embedding in MOP_CFG
    constexpr uint32_t replay_insn(unsigned start, unsigned length) {
        return (0x04 << 24) | (start << 14) | (length << 4);
    }
}
```

### Buffer partitioning convention

```cpp
// cmath_common.h (WH and BH)
constexpr uint replay_buf_offset = 16;
```

| Slots | Reserved for |
|---|---|
| 0-15 | SFPU instructions |
| 16-31 | FPU (matmul) instructions |

### BH convenience wrapper

Blackhole provides `load_replay_buf` in `ckernel.h`:

```cpp
template <typename F>
inline void load_replay_buf(uint32_t start, uint32_t len, F&& f) {
    TTI_REPLAY(start, len, 0, 1);  // record mode, no exec
    f();                            // lambda emits the instructions
}
```

On Wormhole, use `lltt::record()` directly.

## MOP expander: double-nested loop from a single instruction

The **MOP Expander** sits upstream of the replay expander. `ckernel_template` programs **MOP Template 1**, which defines a double-nested loop:

```
for outer in 0..OuterCount:
    emit StartOp
    for inner in 0..InnerCount:
        emit LoopOp         (alternating LoopOp0/LoopOp1 if both defined)
        on last inner iter:  emit Loop0Last (or Loop1Last) instead
    emit EndOp0
    emit EndOp1
```

### ckernel_template API

```cpp
// ckernel_template.h
ckernel_template tmp(
    outer_loop_count,    // OuterCount
    inner_loop_count,    // InnerCount
    loop_op              // LoopOp — the instruction word emitted each inner iteration
);

tmp.program();           // writes MopCfg[0..8] to TENSIX_MOP_CFG_BASE
ckernel_template::run(); // issues TTI_MOP(1, 0, 0) — single instruction, RISC-V is free
```

The `loop_op` is commonly a `REPLAY` instruction, so the MOP expander emits REPLAY instructions that the replay expander then further expands.

### MOP_CFG register layout

```cpp
// program() writes these MMIO registers:
volatile uint *mop_cfg = (volatile uint *)TENSIX_MOP_CFG_BASE;
mop_cfg[0] = OuterCount;
mop_cfg[1] = InnerCount;
mop_cfg[2] = StartOp;
mop_cfg[3] = EndOp0;
mop_cfg[4] = EndOp1;
mop_cfg[5] = LoopOp;       // typically replay_insn(start, len)
mop_cfg[6] = LoopOp1;
mop_cfg[7] = Loop0Last;    // e.g., MVMUL with CLR_A on last iteration
mop_cfg[8] = Loop1Last;
```

## Combining MOP + replay for tile-wide SFPU ops

### Example: tile-wide add (32 iterations, 1024 elements)

The naive RISC-V loop:

```cpp
// 32 iterations x ~4 SFPU instructions each = 128 instruction pushes from RISC-V
for (uint32_t v = 0; v < 32; ++v)
    sfpi::dst_reg[v] = sfpi::dst_reg[v] + scalar;
```

With MOP + replay:

```cpp
// Record 1 iteration (4 instructions) into replay buffer slots 0..3
lltt::record(0, 4);
TTI_SFPLOAD(p_sfpu::LREG0, 0, ADDR_MOD_7, 0);
TTI_SFPADD(p_sfpu::LREG0, p_sfpu::LCONST_0, p_sfpu::LREG0, p_sfpu::LREG0, 0);
TTI_SFPSTORE(p_sfpu::LREG0, 0, ADDR_MOD_7, 0);
TTI_INCRWC(0, 2, 0, 0);    // dst_reg++ = advance by SFP_DESTREG_STRIDE

// Program MOP: inner loop = 32 iterations, loop body = REPLAY(0, 4)
ckernel_template tmp(1, 32, lltt::replay_insn(0, 4));
tmp.program();

// Fire — single instruction, RISC-V is free to do other work
ckernel_template::run();    // TTI_MOP(1, 0, 0)
```

Expansion chain:

```
MOP(1, 0, 0)
  -> MOP Expander emits REPLAY(0, 4) x 32
    -> Replay Expander emits (SFPLOAD + SFPADD + SFPSTORE + INCRWC) x 32
      -> SFPU processes all 1024 elements
```

`INCRWC` advances the Dst write counter each replay, so successive replays hit successive 32-element groups. The same 4-instruction sequence produces correct sequential addressing.

### What this buys

| Aspect | RISC-V loop | MOP + replay |
|---|---|---|
| RISC-V instructions issued | ~128 SFPU + loop overhead | 4 (record) + program() + 1 (MOP) |
| RISC-V free after | all 32 iterations complete | issuing MOP |
| Backend SFPU cycles | identical | identical |
| Instruction stream gaps | possible (RISC-V fetch stalls) | none (expanders deliver at 1/cycle) |

The SFPU execution time is the same either way. The wins are: no RISC-V loop overhead, tighter instruction delivery, and the RISC-V is free to overlap other work (next tile setup, CB management, etc.).

## How matmul uses MOP + replay (for comparison)

Matmul records 16 MVMUL instructions into slots 16-31, then programs a MOP whose LoopOp is `replay_insn(16, 16)`:

```cpp
// llk_math_matmul.h (WH, trimmed)
lltt::record<ExecBool::Exec>(replay_buf_offset, replay_buf_len);
// ... 16 x TTI_MVMUL instructions recorded while executing ...

ckernel_template tmp(
    outer_loops,
    inner_loops,                                    // fidelity phases
    lltt::replay_insn(replay_buf_offset, replay_buf_len),  // LoopOp
    TT_OP_MVMUL(CLR_A, ...)                        // Loop0Last: clear accumulator
);
tmp.program();

// Per tile pair:
ckernel_template::run();  // TTI_MOP(1, 0, 0) -> MOP -> REPLAY -> 16 MVMULs
```

The MOP transition note from the ISA docs: "at least one of the instructions emitted by the expander should be a REPLAY instruction which expands to at least two instructions" — this fills the 1-cycle MOP transition penalty.

## Which LLK kernels use SFPU replay

| Kernel | File | What's replayed |
|---|---|---|
| **Welford's** | `ckernel_sfpu_welfords.h` | 32 instructions (8 per LREG row): `SFPMAD`, `SFPNOP`, `SFPMOV` |
| **SFPU reduce** | `ckernel_sfpu_reduce.h` | Transpose + add sequence, replayed for column-wise and row-wise accumulation |
| **add_top_row** | `ckernel_sfpu_add_top_row.h` (BH) | `SFPIADD` x4 in slots 0-3, `SFPADD` x4 in slots 4-7 |
| **reciprocal** | `ckernel_sfpu_recip.h` (BH) | `SFPLOADMACRO` + `SFPMAD` in 6 slots, replayed in Newton-Raphson loop |
| **cumsum** | `ckernel_sfpu_cumsum.h` | Similar pattern to reduce |

### Which kernels do NOT use replay

Simple unary ops (abs, relu, exp, sigmoid, tanh, gelu, etc.) use a plain `for (d = 0; d < 8; d++)` loop. The standard `llk_math_eltwise_unary_sfpu_params.h` framework has no replay — it relies on the RISC-V loop.

Reason: for 2-4 instruction SFPU bodies, the RISC-V loop overhead is small relative to SFPU execution time, and the SFPI C++ API (`vFloat`, `v_if`, etc.) generates inline instructions that can't be redirected into the replay buffer. Using replay requires dropping to `TTI_*` macros.

## SFPLOADMACRO: in-SFPU instruction scheduling (separate mechanism)

`SFPLOADMACRO` is **not** the replay buffer. It is an SFPU-internal mechanism: a single instruction that simultaneously does an SFPLOAD and pre-schedules up to 4 additional sub-unit instructions (Simple, MAD, Round, Store) at configurable delays (0-6 cycles).

```
SFPLOADMACRO = SFPLOAD + schedule(Simple, MAD, Round, Store) at future cycles
```

This is the only way to achieve IPC > 1 on the SFPU. The configuration is programmed via `SFPCONFIG` into a per-lane `LoadMacroConfig` table.

SFPLOADMACRO instructions can themselves be stored in the replay buffer (see reciprocal kernel above). The two mechanisms compose: replay delivers the SFPLOADMACRO instruction, which then internally schedules multiple sub-unit ops.

**Source:** `tt-isa-documentation/*/TensixTile/TensixCoprocessor/SFPLOADMACRO.md`

## Practical guidance

| Scenario | Approach |
|---|---|
| Simple unary op (abs, relu, scale) with SFPI C++ API | `for (d = 0; d < 8; d++)` loop — standard, easy, sufficient |
| Same op but performance-critical inner loop | Drop to `TTI_*` macros, record into replay buffer, use MOP |
| Complex multi-instruction sequence repeated across faces | Record once, `lltt::replay()` per face (Welford's pattern) |
| Full tile op with no data-dependent control flow | MOP + replay (tile-wide add example above) |
| Need IPC > 1 on SFPU | `SFPLOADMACRO` (requires `SFPCONFIG` setup, advanced) |

## Key source files

| File | Content |
|---|---|
| `tt-isa-documentation/.../REPLAY.md` | Replay buffer functional model |
| `tt-isa-documentation/.../MOPExpander.md` | MOP Template 0 and 1 functional model |
| `tt-isa-documentation/.../MOP.md` | MOP instruction encoding |
| `tt-isa-documentation/.../SFPLOADMACRO.md` | In-SFPU instruction scheduling |
| `runtime/sfpi/include/lltt.h` | `lltt::record()`, `lltt::replay()`, `lltt::replay_insn()` |
| `tt_llk_*/common/inc/ckernel_template.h` | `ckernel_template` MOP programming |
| `tt_llk_*/common/inc/cmath_common.h` | `replay_buf_offset = 16` partitioning |
| `tt_llk_*/common/inc/ckernel.h` (BH) | `load_replay_buf()` helper |
| `tt_llk_*/common/inc/sfpu/ckernel_sfpu_welfords.h` | SFPU replay example: Welford's |
| `tt_llk_*/common/inc/sfpu/ckernel_sfpu_reduce.h` | SFPU replay example: reduce |
| `tt_llk_*/llk_lib/llk_math_matmul.h` | Matmul MOP + replay pattern |
