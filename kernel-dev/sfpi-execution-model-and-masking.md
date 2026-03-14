# SFPI execution model: vector width, face iteration, and per-lane masking

How SFPI instructions map to 32x32 tiles, and the two masking mechanisms available for partial-tile operations.

## SFPU vector width: 32 elements

A single SFPI instruction operates on **32 elements in parallel**. The SFPU is a 32-lane SIMD engine. Each lane holds one 32-bit datum (FP32, INT32, or UINT32).

```
Source: runtime/sfpi/include/blackhole/sfpi_hw.h
        tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/VectorUnit.md
```

The 32 lanes are physically arranged as a 4-row x 8-column grid:

```
Lane  0  Lane  1  Lane  2  Lane  3  Lane  4  Lane  5  Lane  6  Lane  7   <- row 0
Lane  8  Lane  9  Lane 10  Lane 11  Lane 12  Lane 13  Lane 14  Lane 15   <- row 1
Lane 16  Lane 17  Lane 18  Lane 19  Lane 20  Lane 21  Lane 22  Lane 23   <- row 2
Lane 24  Lane 25  Lane 26  Lane 27  Lane 28  Lane 29  Lane 30  Lane 31   <- row 3
```

One `SFPLOAD`/`SFPSTORE` covers **4 consecutive Dst rows** (32 elements). A `dst_reg[0] = dst_reg[0] + vConst0` reads 32 FP32 values, adds the constant, and writes 32 results back.

## Tile-to-SFPU mapping: 4 faces, 8 iterations each

A 32x32 tile = 1024 elements = 4 faces of 16x16 (256 elements each).

| Constant | Value | Source |
|---|---|---|
| `FACE_HEIGHT` / `FACE_WIDTH` | 16 | `ckernel_defs.h` |
| `TILE_HEIGHT` / `TILE_WIDTH` | 32 | `ckernel_defs.h` |
| `TILE_NUM_FACES` | 4 | `(32*32)/(16*16)` |
| SFPU vector width | 32 | `sfpi_hw.h`, ISA docs |
| Iterations per face | 8 | `256/32` |
| SFPI address slots per tile | 32 | `dst_tile_size_sfpi` |
| `SFP_DESTREG_STRIDE` | 2 | `sfpi_hw.h` |

Face layout in Dst:

```
Face 0 (rows 0-15,  cols 0-15)   Face 1 (rows 0-15,  cols 16-31)
Face 2 (rows 16-31, cols 0-15)   Face 3 (rows 16-31, cols 16-31)
```

### Iteration structure

The SFPU kernel processes **one face** per call with `ITERATIONS = 8`:

```cpp
// ckernel_sfpu_abs.h (trimmed)
template <bool APPROXIMATION_MODE, int ITERATIONS = 8>
inline void calculate_abs() {
    for (int d = 0; d < ITERATIONS; d++) {
        vFloat v = dst_reg[0];
        dst_reg[0] = sfpi::abs(v);
        dst_reg++;  // INCRWC by SFP_DESTREG_STRIDE=2
    }
}
```

The **outer face loop** is in the LLK wrapper, not the SFPU kernel:

```cpp
// llk_math_eltwise_unary_sfpu_params.h (trimmed)
if (mode == VectorMode::RC) {       // full tile
    for (int face = 0; face < 4; face++) {
        sfpu_func(args...);          // 8 iterations = 256 elements = one face
        inc_dst_face_addr();         // SETRWC +8+8 = advance to next face
    }
}
```

### VectorMode controls which faces are processed

| Mode | Faces | Use case |
|---|---|---|
| `VectorMode::RC` | 0, 1, 2, 3 | Full 32x32 tile |
| `VectorMode::R` | 0, 1 | Top half (row vector) |
| `VectorMode::C` | 0, 2 | Left half (column vector) |

### Full tile execution flow

```
LLK sets dst_write_addr to tile base
|
+-- face 0  (top-left 16x16)
|     for d in 0..7:  dst_reg[0] op -> 32 elements; dst_reg++
|     [8 x 32 = 256 elements]
|     inc_dst_face_addr() -> SETRWC +16
|
+-- face 1  (top-right 16x16)
|     8 iterations -> 256 elements
|     inc_dst_face_addr()
|
+-- face 2  (bottom-left 16x16)
|     8 iterations -> 256 elements
|     inc_dst_face_addr()
|
+-- face 3  (bottom-right 16x16)
      8 iterations -> 256 elements

Total: 4 x 256 = 1024 elements = full 32x32 tile
```

## Masking mechanism 1: per-lane condition codes (dynamic)

The primary masking system. SIMT-style per-lane predication using `LaneFlags`:

```cpp
// ISA-level model (VectorUnit.md)
bool LaneFlags[32];                     // per-lane predication bit
bool UseLaneFlagsForLaneEnable[32];     // master enable for the CC system
struct { bool LaneFlags; bool UseLaneFlagsForLaneEnable; } FlagStack[32][8];  // 8-deep stack
```

When active, every SFPU instruction only writes lanes where `LaneFlags[lane] == true`.

### IsLaneEnabled logic

```cpp
bool IsLaneEnabled(unsigned Lane) {
    if (LaneConfig[Lane & 7].ROW_MASK.Bit[Lane / 8])
        return false;                      // static row mask (mechanism 2)
    else if (UseLaneFlagsForLaneEnable[Lane])
        return LaneFlags[Lane];            // dynamic per-lane CC
    else
        return true;                       // no masking
}
```

### CC instructions

| Instruction | Builtin | Effect |
|---|---|---|
| `SFPSETCC` | via `__vCond` | Sets `LaneFlags[lane]` from comparison: `LT0`, `NE0`, `GTE0`, `EQ0` |
| `SFPENCC` | `sfpencc(imm12, mod1)` | Enables/disables `UseLaneFlagsForLaneEnable`; optionally sets `LaneFlags` |
| `SFPCOMPC` | `sfpcompc()` | Implements `else`: inverts `LaneFlags` relative to stack top |
| `SFPPUSHC` | `sfppushc()` | Pushes `{LaneFlags, UseLaneFlagsForLaneEnable}` onto stack |
| `SFPPOPC` | `sfppopc()` | Pops stack, restoring flag state |

Additional instructions with CC side-effects: `SFPEXEXP`, `SFPIADD`, `SFPLZ` (when used with `SET_CC_*` / `CC_LT0` / `CC_GTE0` modes).

### SFPI C++ API

The condition-code machinery is exposed as `v_if`/`v_else`/`v_endif`:

```cpp
vFloat v = dst_reg[0];
v_if (v >= 0.0f) {         // SFPPUSHC + SFPSETCC(GTE0) + SFPENCC
    dst_reg[0] = v * 2.0f; // only writes lanes where v >= 0
}
v_endif;                   // SFPPOPC restores flags
```

Internally:
- `v_if` -> constructor of `__vCCCtrl` calls `SFPPUSHC`, then `SFPSETCC` + `SFPENCC`
- `v_else` -> `SFPCOMPC` (inverts flags relative to parent scope)
- `v_endif` -> destructor calls `SFPPOPC`

### Supported comparisons

```cpp
// Float comparisons (emits SFPXFCMPS -> SFPSETCC)
v_if (a < 5.0f) { ... }       // CC_LT
v_if (a >= 0.0f) { ... }      // CC_GTE

// Integer comparisons (emits SFPXICMPS)
v_if (b == 42) { ... }        // CC_EQ

// Boolean composition (SFPXBOOL builtins)
v_if ((a < 0.0f) && (b > 0)) { ... }
```

Boolean `&&`, `||`, `!` on `__vCond` objects collapse to a single CC state at compile time. Limited to 3 levels of nesting.

### Narrowing with v_and

For narrowing predication in loops (does NOT push the CC stack):

```cpp
// From ckernel_sfpu_exp.h
v_if (exp >= 0) {
    val = val * val;
    for (int s_iter = 0; s_iter < 7; s_iter++) {
        exp = exp - 1;
        v_and(exp >= 0);    // further narrows active lanes each iteration
        val = val * val;
    }
}
v_endif;
```

### Nesting depth

The CC flag stack is **8 levels deep** per lane, supporting deeply nested `v_if`/`v_else`/`v_endif` blocks.

### Real-world example: mask kernel

```cpp
// ckernel_sfpu_mask.h (blackhole)
template <bool APPROXIMATION_MODE, int ITERATIONS = 8>
inline void calculate_mask() {
    for (int d = 0; d < ITERATIONS; d++) {
        vFloat mask = dst_reg[mask_val_idx];
        v_if(_sfpu_is_fp16_zero_(mask, exponent_size_8)) {
            dst_reg[0] = vConst0;   // zero-out lane if mask is zero
        }
        v_endif;
        dst_reg++;
    }
}
```

## Masking mechanism 2: static ROW_MASK (hardware)

A 4-bit field in `LaneConfig` (set via `SFPCONFIG VD=15`). Bit `i` of `ROW_MASK` disables all lanes in "row `i`" of the 4x8 SIMD grid. Indexed by `Lane & 7` (column), so it is column-grouped.

This is a static hardware mask, not a per-cycle predicate. **Not used by any standard LLK code** — the CC system (mechanism 1) is the primary approach.

## Summary: what you can and cannot mask

| Granularity | Supported | Mechanism |
|---|---|---|
| Individual lanes (1 of 32) | Yes | `v_if` / CC predication |
| Rows within a face (groups of 8 lanes) | Yes | `v_if` on those lanes, or `ROW_MASK` |
| Entire faces (16x16 blocks) | Yes | LLK `VectorMode::R`/`C`/`RC` + `SETRWC` |
| Arbitrary subsets of the tile | Yes | Combine face selection + per-lane `v_if` |
| Skip entire tile | Yes | Don't call the SFPU kernel for that tile |

## Key source files

| File | Content |
|---|---|
| `runtime/sfpi/include/sfpi.h` | SFPI C++ API: `vFloat`, `vInt`, `__vCCCtrl`, `v_if`/`v_else`/`v_endif` |
| `runtime/sfpi/include/blackhole/sfpi_hw.h` | Hardware constants, `__builtin_rvtt_*` mappings |
| `tt-isa-documentation/.../VectorUnit.md` | ISA-level `IsLaneEnabled`, `LaneFlags`, `FlagStack` |
| `tt-isa-documentation/.../SFPSETCC.md` | Per-lane flag setting from comparison |
| `tt-isa-documentation/.../SFPENCC.md` | CC system enable/disable |
| `tt-isa-documentation/.../SFPCOMPC.md` | Else (flag inversion) |
| `tt-isa-documentation/.../SFPPUSHC.md` | Push flag state |
| `tt-isa-documentation/.../SFPPOPC.md` | Pop flag state |
| `tt_llk_blackhole/llk_lib/llk_math_eltwise_unary_sfpu_params.h` | Face loop + `VectorMode` |
| `tt_llk_blackhole/common/inc/ckernel_defs.h` | `FACE_HEIGHT`, `TILE_NUM_FACES`, etc. |
