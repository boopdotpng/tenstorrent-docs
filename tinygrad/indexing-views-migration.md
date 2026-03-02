# Tinygrad Indexing/Views and Tenstorrent Backend Migration

How tinygrad handles indexing operations and views, and what would be needed to adapt this for a Tenstorrent backend built on top of blackhole-py.

## Tinygrad's Current Approach (No More ShapeTracker)

Tinygrad has moved past the old `ShapeTracker`/`View` classes. Everything is now a **UOp DAG** with six primitive movement ops:

| Op | Effect on Index | Example |
|---|---|---|
| `SHRINK` | `r → r + offset` | `t[3:7]` |
| `EXPAND` | `r → 0` (broadcast) | `t.expand(4, 3)` |
| `PERMUTE` | reorder range vars | `t.T` |
| `FLIP` | `r → (size-1) - r` | `t[::-1]` |
| `PAD` | `valid ? (r - pad) : 0` | `t.pad(((2,2),))` |
| `RESHAPE` | div/mod arithmetic | `t.reshape(2, 3)` |

These ops are **lazy graph nodes** — no data moves. They're converted to actual index arithmetic during the **rangeify** pass (`schedule/indexing.py`), which assigns loop `RANGE` variables per dimension and algebraically transforms them through the movement-op chain. The result is explicit expressions like `ptr[r0*stride0 + r1*stride1 + offset]` that the backend renders directly.

### How Indexing Decomposes

- `t[0]` → `SHRINK([0,1])` + `RESHAPE`
- `t[:, 3:5]` → `SHRINK`
- `t[::2]` → pad-to-multiple + reshape + shrink (stride trick)
- `t[mask]` → one-hot + where + sum (no special gather op)
- `t.gather(dim, idx)` → one-hot + where + sum

Advanced indexing is always reduced to elementwise + reduce. There is no special gather/scatter instruction.

### Rangeify Pass (schedule/indexing.py)

The rangeify pass assigns `RANGE` UOp loop variables to each tensor dimension, then transforms them through the movement-op chain:

```
apply_movement_op(SHRINK, rngs)  → r + offset
apply_movement_op(EXPAND, rngs)  → const 0 (broadcast dim reads same element)
apply_movement_op(PERMUTE, rngs) → reorder range variables
apply_movement_op(FLIP, rngs)    → (size-1) - r
apply_movement_op(PAD, rngs)     → valid.where(r - pad_before, invalid)
apply_movement_op(RESHAPE, rngs) → div/mod arithmetic (simplified symbolically)
```

Key fusion rule: if a UOp has only one consumer, its ranges are inherited directly — no intermediate buffer needed. This is how long chains like `a.reshape(...).expand(...).shrink(...) + b` fuse into a single kernel with no copies.

Views are forced to realize (materialize to a buffer) when:
- Multiple consumers have incompatible range structures
- A `CONTIGUOUS` op is explicitly inserted
- EXPAND followed by REDUCE on the same axis (ending ranges)
- The scheduler heuristics decide the view is too expensive to inline

### Reduce Operations

`REDUCE_AXIS(op, axes)` keeps reduced dims as size-1. During rangeify, reduced axes get new `RANGE` variables of type `REDUCE` (vs `LOOP` for output dims). This tells the code generator which loops are output loops vs accumulation loops.

### View Merging

There is no explicit "merge views" step. Instead:
- Adjacent `RESHAPE(RESHAPE(x, s1), s2)` is collapsed to `RESHAPE(x, s2)` by `mop_cleanup`
- Single-consumer chains inherit ranges directly (implicit fusion)
- The symbolic simplifier reduces redundant div/mod/add chains

## blackhole-py's Current State

blackhole-py has **no tensor abstraction**. It operates at the byte level:
- Data goes through `tilize()` → DRAM at upload time
- Kernels receive raw tile counts and DRAM addresses as runtime args
- Kernels compute tile IDs manually with `noc_async_read_tile(tile_id, ...)`
- No lazy eval, no views, no reshape without copying

## The Gap: What a Tenstorrent Backend Would Need

### 1. Index Arithmetic → Tile ID Arithmetic

Tinygrad's rangeify produces linear index expressions: `idx = r0*S0 + r1*S1 + ...`. On Tenstorrent, memory is tiled (32x32 tiles, 4 faces each). The backend needs to convert:

```
linear_element_index → (tile_row, tile_col, face, face_row, face_col)
```

This is a fixed decomposition:
```
tile_row = idx / (row_stride) / 32
tile_col = (idx % row_width) / 32
face = ((row_within_tile >= 16) << 1) | (col_within_tile >= 16)
```

This would be implemented as a custom `Renderer` subclass that emits tile-aware address computation, or as a graph rewrite pass before linearization.

### 2. Movement Ops: Free vs. Expensive on Tenstorrent

| Tinygrad Op | Tenstorrent Cost | Why |
|---|---|---|
| `SHRINK` (contiguous slice) | **Free** | Adjust DRAM base address + tile count in RT args |
| `RESHAPE` (same memory order) | **Free** | Only changes how tile IDs are computed in kernel args |
| `EXPAND` (broadcast) | **Free-ish** | Multicast NOC naturally broadcasts; a core reads the same tile repeatedly |
| `PERMUTE` (transpose) | **Expensive** | Tile format is row-major 32x32; transposing requires a kernel to read tiles and write them in a different order |
| `PAD` | **Moderate** | Tile-aligned padding (multiples of 32) just adds zero-tiles. Non-aligned padding needs a kernel to rewrite partial tiles |
| `FLIP` | **Moderate** | Needs a kernel to reverse tile order and/or intra-tile data |

The backend's `Renderer` would need to express these costs so the scheduler makes good realize/fuse decisions.

### 3. Kernel Emission: The 5-Way Split

Tinygrad backends receive a linearized UOp list (RANGE/LOAD/STORE/ALU ops) and render it to source code. For Tenstorrent, you'd need to emit **5 separate programs** (BRISC/NCRISC/TRISC0/1/2) from a single UOp kernel:

- **NCRISC (reader):** All `LOAD` ops → `noc_async_read_tile()` calls, writing tiles into circular buffers
- **TRISC0 (unpack):** `cb_wait_front()` + `unpack_tile()` for each input CB
- **TRISC1 (math):** All ALU/SFPU operations on DST registers
- **TRISC2 (pack):** `pack_tile()` + `cb_push_back()` to output CB
- **BRISC (writer):** All `STORE` ops → `noc_async_write_tile()` from output CB to DRAM

This is the hardest part. Tinygrad expects one flat code emission; Tenstorrent needs a 5-way split where loads, compute, and stores are decoupled and synchronized via circular buffers.

### 4. Architecture Sketch

```
tinygrad UOp graph
    ↓ rangeify (standard tinygrad pass — produces index expressions)
    ↓ tile_transform (NEW: rewrite flat indices → tile indices,
    │                  insert tile-alignment padding, handle face layout)
    ↓ fission_pass (NEW: split each kernel UOp list into 5 sub-programs:
    │               reader / unpack / math / pack / writer)
    ↓ TenstorrentRenderer.render() → 5 C++ source strings per kernel
    ↓ compiler.py compile_dataflow() / compile_compute()
    ↓ device.py _build_payloads() → L1 image
    ↓ dispatch (slow or fast CQ)
```

### 5. Multicore Mapping

Tinygrad's `SPECIAL` ops (thread/block IDs) map naturally to Tenstorrent's core grid. `SPECIAL(0, "gidx0", N)` becomes the core's position in the dispatch grid. The `ArgGen` pattern in blackhole-py already does per-core argument specialization — per-core tile ranges would be generated from the SPECIAL→core mapping.

For matmul, tinygrad has `TensorCore` support in the renderer. Tenstorrent's SFPU matmul could be defined as `TensorCore(dims=(32,32,32), ...)` and let tinygrad's tensor core matching handle the blocking.

### 6. Key Simplifications

Two things that make this tractable:

1. **All advanced indexing decomposes to elementwise + reduce in tinygrad.** No "gather" kernel needed — `t[idx]` becomes one-hot matmul. This means you only need to support the 6 movement ops + elementwise + reduce, which blackhole-py already has patterns for (add1 = elementwise, matmul = reduce).

2. **Tile alignment can be enforced at the graph level.** Insert PAD ops to round dimensions to multiples of 32 before any realize point. Tinygrad already handles PAD → WHERE conversion, so the generated kernels will naturally produce zeros in the padded region.

### 7. What Doesn't Map Cleanly

- **Stride tricks:** Tinygrad loves non-contiguous strides (e.g., `as_strided` for pooling). Tenstorrent's tile format means non-contiguous access patterns require actual data movement. The backend would need to insert `CONTIGUOUS` (force a copy kernel) more aggressively than GPU backends.

- **Small tensors:** Tinygrad can have tensors smaller than 32x32. These need padding to fill a tile, wasting compute. The scheduler should batch small ops or use scalar mode if available.

- **Dynamic shapes:** Tinygrad supports symbolic shapes via `UOp.variable()`. Tenstorrent kernels have fixed tile counts baked into RT args. Shapes would need to be resolved at dispatch time, or use maximum-size allocation with masking.
