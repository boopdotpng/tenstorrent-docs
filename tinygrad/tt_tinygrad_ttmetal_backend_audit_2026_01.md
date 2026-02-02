# Tinygrad + Tenstorrent (Blackhole) backend audit (tt-metal toolchain, SFPI compute)

This is a snapshot of what was required to get `tinygrad/test.py` running on a Tenstorrent Blackhole card, what was actually broken, what we changed, and what’s still missing for a “real” backend.

Baseline assumptions:
- Device: Blackhole (p100a/p150a)
- Kernels compiled with tt-metal’s SFPI toolchain (not using the tt-metal runtime)
- Data-movement kernels can stay `tt-llk`-heavy; compute should be SFPI

## Operational notes

Before running any workloads on device:
- Reset the device to clear any wedged state from prior bad kernels:
  - `~/tenstorrent/.venv/bin/tt-smi -r`

If kernel compilation fails, set:
- `TT_METAL_HOME=/home/boop/tenstorrent/tt-metal` (or your checkout)

## What was wrong (root causes)

### 1) Toolchain discovery (`TT_METAL_HOME`)

The TT compiler wrapper needed tt-metal’s SFPI toolchain (`riscv-tt-elf-g++`, `riscv-tt-elf-nm`, etc). The original code effectively assumed a fixed install path, which broke in a repo checkout setup.

Fix: auto-discover `tt-metal/` via `TT_METAL_HOME` or by walking parent dirs.
- `tinygrad/tinygrad/runtime/support/tenstorrent/compiler.py`

### 2) “DRAM allocation / reading is failing” was actually *layout*

tt-metal’s unpack/pack path expects DRAM tensors in a tiled layout. For typical Blackhole elementwise kernels that means:
- 32x32 tiles
- `TILED_NFACES` (four 16x16 faces per tile)

Tinygrad tensors are row-major by default. If you write row-major host data directly to DRAM and then run a tt-metal-style tiled kernel, unpack interprets the bytes as faces/tiles and you get garbage/NaNs (this looks like “bad DRAM reads”).

Fix for bringup correctness:
- tilize host numpy inputs when creating TT tensors
- untilize on TT `Tensor.data()` / `Tensor.numpy()` so results compare correctly
- `tinygrad/tinygrad/runtime/support/tenstorrent/tilize.py`
- `tinygrad/tinygrad/tensor.py`

### 3) Renderer matched the wrong ops (address math vs compute math)

Tinygrad UOps include lots of integer ops (`Ops.ADD`, `Ops.MUL`) for pointer/index arithmetic. If you match “binary add” just because `Ops.ADD` exists, you can emit a 2-input kernel for a program that has no real 2-input float compute.

Fix: only match compute ops based on float-typed ops and actual global buffer count.
- `tinygrad/tinygrad/runtime/ops_tt.py`

### 4) SFPI `dst_reg` indexing for binary ops (Float32)

For a 32x32 tile, tt-metal’s SFPU/SFPI examples operate over:
- `vectors_per_tile = 32`
- operand tile stride = `+32`

Treating Float32 as “64 SFPI rows per tile” and using `+64` for the second operand corrupts results.

Fix: use `32` rows and `+32` stride for SFPI loops and operand placement.
- `tinygrad/tinygrad/runtime/ops_tt.py`

## What changed (code)

### Toolchain path
- `tinygrad/tinygrad/runtime/support/tenstorrent/compiler.py`
  - Add `_find_tt_metal_home()` and define `TT_METAL_HOME` from env or repo.

### Host tilize/untilize (TILED_NFACES)
- `tinygrad/tinygrad/runtime/support/tenstorrent/tilize.py`
  - Implements `tilize_nfaces_bytes` / `untilize_nfaces_bytes` for tile-aligned shapes.
- `tinygrad/tinygrad/tensor.py`
  - Numpy → TT tensor creation tilizes when shape is rank≥2 and tile-aligned.
  - TT tensor `data()`/`numpy()` untilize on the way out (rank≥2).

### Renderer/kernel selection and SFPI compute
- `tinygrad/tinygrad/runtime/ops_tt.py`
  - Add `dtypes.float` to dtype mapping.
  - Add 0-input constant fill kernel when UOps are a constant store pattern.
  - Add unary-scalar kernel lowering for `x op const` (compile-time scalar).
  - Only emit binary kernels when the kernel truly has 2 input globals.
  - Use `vectors_per_tile=32` and `tile_stride=32` for SFPI row loops and second operand offset.
  - NOC index split matches the known-good pattern: NCRISC on noc0, BRISC on noc1.

## Why `blackhole-py` “worked without tilize”

`blackhole-py` is tile-native:
- It allocates DRAM with `page_size = tile_size_bytes` and treats the buffer as “N tiles of 32x32 elements”.
- Reader/writer use `noc_async_read_tile(i, ...)` / `noc_async_write_tile(i, ...)` by tile index.
- It never interprets the buffer as a row-major `(H,W)` matrix, and validation compares element order in the same flat “tile order”.

So there’s no row-major ↔ tiled mismatch in that workflow; it’s already using the tiled convention end-to-end.
- `blackhole-py/main.py`

## What’s still missing (for a “real” backend)

### Layout + shapes
- Only tile-aligned rank≥2 numpy tensors are tilized/untilized. Anything not divisible by 32 needs padding/masking strategy.
- `.to("CPU")` and non-numpy sources (lists/bytes) are not fully layout-aware (boundary handling is incomplete).

### Views and tinygrad semantics
Tinygrad treats many views as “free” (reshape/permute/expand/shrink fold into index math).
With tiled layout, many of these are not representable as metadata-only views:
- `permute/transpose`: generally requires a real relayout kernel
- `reshape` that changes how `(H,W)` is interpreted: generally a relayout
- arbitrary `shrink/slice`: needs mask/pad or real copy unless tile-aligned

A TT-friendly approach is:
- device tensors are *physically tiled* as the invariant
- only a small subset of views remain views; everything else lowers to a small set of templated data-movement relayout kernels

### Op coverage
Currently bringup targets a tiny set:
- fill, unary, unary-scalar, binary ops for float (as exercised by simple tests)

Missing for broader tinygrad:
- reductions, matmul/conv, broadcasts, where/compare, transcendental ops, etc.

## What the “optimal” backend shape should look like

Tenstorrent doesn’t fit “emit arbitrary CUDA-like kernels per graph” well. A better fit is a small kernel library:

### Data movement (keep tt-llk here)
- One unary reader, one binary reader, one writer
- Optional tilize/untilize kernels if you want device-side conversions (often not needed if TT tensors stay tiled)
- Optional relayout kernels for views that can’t stay metadata-only

### Compute (SFPI-only)
- `fill(value)`
- `unary(op)`
- `unary_scalar(op, scalar)` (scalar baked in)
- `binary(op)`

All compute kernels should follow the same boilerplate:
- `copy_tile` inputs to Dst slots
- SFPI loop over `dst_reg[0..31]`, using `+32` for the second operand tile
- `pack_tile` to output CB

## Debugging guidance

- Always reset after a hang:
  - `~/tenstorrent/.venv/bin/tt-smi -r`
- Beware constant folding: `Tensor.ones(...) + Tensor.ones(...)` can compile down to a fill kernel and won’t validate binary readers/unpack.
  - Use non-constant inputs (e.g. `np.arange`) to exercise real binary kernels.

