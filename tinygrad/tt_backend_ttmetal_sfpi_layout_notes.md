# Tinygrad TT backend (tt-metal toolchain): layout + SFPI bringup notes

This captures the root causes behind `tinygrad/test.py` not working on Blackhole, what fixes were needed, and what a “templated” TT backend should look like when:
- data movement stays in `tt-llk`-heavy kernels, and
- compute is authored in SFPI.

## Quick checklist (before running any workloads)

- Reset the card (isolates kernel issues from bad device state):
  - `~/tenstorrent/.venv/bin/tt-smi -r`
- Ensure the SFPI RISC-V toolchain is discoverable:
  - Set `TT_METAL_HOME` to your `tt-metal` checkout, or rely on tinygrad’s auto-discovery.

## Root causes

### 1) Toolchain path: `TT_METAL_HOME`

Tinygrad’s TT kernel compiler needs `riscv-tt-elf-g++` and friends from tt-metal’s SFPI toolchain.
If `TT_METAL_HOME` is unset/mis-set, compilation fails (commonly at `riscv-tt-elf-nm` lookup).

Current behavior is: prefer `TT_METAL_HOME`, else search upward for an in-tree `tt-metal/`, else fall back to `/opt/tenstorrent/tt-metal`.

Relevant code:
- `tinygrad/tinygrad/runtime/support/tenstorrent/compiler.py`

### 2) Memory layout mismatch: row-major vs `TILED_NFACES`

tt-metal’s unpack/pack path (and the standard “dataflow + SFPI compute” examples) assume tensors in DRAM are in **tiled layout**. For Blackhole elementwise kernels, the common expectation is `TILED_NFACES`:
- tiles are `32x32`
- each tile is stored as 4 faces (`16x16`) in face order (nfaces)

If you write row-major host buffers directly into DRAM, kernels will “work” only for degenerate cases (like fills), and produce garbage/NaNs for real inputs because unpack interprets the bytes as tiled faces.

Fix approach used here:
- tilize host data *when creating TT tensors from numpy*
- untilize on `Tensor.data()` / `Tensor.numpy()` for TT tensors

Relevant code:
- `tinygrad/tinygrad/runtime/support/tenstorrent/tilize.py`
- `tinygrad/tinygrad/tensor.py`

Practical note:
- This is intentionally a “boundary conversion” hack to get correctness; longer-term, TT should store tensors internally as tiled and only convert when crossing CPU/host boundaries.

### 3) Renderer op selection: avoid matching address math

Tinygrad UOps contain lots of integer `Ops.ADD`/`Ops.MUL` for pointer/index math. A naive “if `Ops.ADD` exists” check will incorrectly emit a binary add kernel even when the kernel is actually a fill/store-const pattern.

The renderer must:
- match compute ops based on **float-typed** ops (not integer address ops)
- only emit true binary kernels when it actually has 2 input globals (in addition to output)
- treat scalar ops (`x * const`, `x + const`) as a unary-scalar kernel (or as binary with an explicit constant tile)

Relevant code:
- `tinygrad/tinygrad/runtime/ops_tt.py`

## SFPI specifics that matter for correctness

### `dst_reg` indexing for binary ops

For `32x32` tiles, the SFPI convention used by shipped tt-metal SFPU examples is:
- iterate `r in [0..31]` per tile
- second operand tile starts at `+32`

In other words:
- `vectors_per_tile = 32`
- `tile_stride = 32`

If you treat a tile as “64 rows” in SFPI space, you’ll read/write the wrong `dst_reg` slots and corrupt results.

Reference:
- `boop-docs/tt-metal/blackhole-kernel-development-audit-sfpi.md`

## What the “templated” backend should look like

Tinygrad’s CUDA-like “emit arbitrary kernels per graph” model doesn’t match Tenstorrent well. A better fit is a small kernel library with a few valid dataflow templates, plus SFPI compute templates:

### Data movement (keep `tt-llk` here)

- `reader_unary`: DRAM → CB0
- `reader_binary`: DRAM → CB0/CB1
- `writer`: CBout → DRAM
- Optional: dedicated tilize/untilize kernels if you want device-side conversions (but host-side is simpler for bringup).

These should be mostly boilerplate, parameterized by:
- CB ids
- data format
- tile_bytes / page_size
- per-core tile ranges

### Compute (SFPI-only)

Compute kernels should be minimal and template-driven:
- `compute_fill(value)`
- `compute_unary(op)`
- `compute_unary_scalar(op, scalar)` (compile-time constant)
- `compute_binary(op)`

All should follow:
- `copy_tile` inputs to Dst slots
- SFPI loop over `dst_reg[0..31]` (+32 for second tile)
- `pack_tile` to output CB

## Debugging tips

- If a kernel times out/hangs, reset the device before retrying:
  - `~/tenstorrent/.venv/bin/tt-smi -r`
- Beware tinygrad constant folding: `Tensor.ones(...) + Tensor.ones(...)` may compile to a fill kernel and won’t validate binary add paths.
  - Use non-constant inputs (e.g. `np.arange`) to validate real readers/unpack.

