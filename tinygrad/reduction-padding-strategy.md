# TT Backend: Reduction Padding Strategy

## Problem

Tensix cores process 32x32 tiles — SFPI operates on all 1024 elements identically with no per-element masking. The TT allocator pads DRAM buffers to tile boundaries with zeros on upload (`TTAllocator._copyin` in `ops_tt.py`).

For **elementwise ops** this is fine — zero padding doesn't affect correctness.

For **reductions**, the padding values affect correctness:
- `sum` needs pad value `0`
- `max` needs pad value `-inf` (`dtypes.min(dt)`)
- `min` needs pad value `+inf` (`dtypes.max(dt)`)

tinygrad already has `identity_element()` in `uop/ops.py:32` that maps `{Ops.ADD: 0, Ops.MUL: 1, Ops.MAX: dtypes.min(dt)}`.

## Options Considered

### Option A: Pad-fill kernel before reductions

Run a separate kernel to overwrite padding regions with the correct identity value before the reduction kernel executes.

**Pros:** Simple to implement, no core tinygrad changes.
**Cons:** Extra kernel launches, mutates source buffers, awkward when one tensor feeds multiple different reductions (e.g. both sum and max).

### Option B: SFPI predication in compute kernel

Add per-element validity checks inside the SFPI compute body.

**Pros:** No extra kernels.
**Cons:** Fundamentally mismatched with the hardware model — SFPI has no efficient per-element predication. The current compute template only receives `n_tiles` as a runtime arg, with no tail-mask path. Would require significant rework.

### Option C: Graph rewrite inserting PAD ops with identity values

Insert logical `Tensor.pad()` on each reduction input to TT tile alignment, using identity values per reduction op, as a graph transformation.

**Pros:** Clean semantic approach, reuses existing tinygrad PAD infrastructure, no extra kernel launches, handles the "one tensor, multiple reductions" case naturally.
**Cons:** Requires a TT-specific graph rewrite at the right stage of the pipeline.

## Recommendation: Option C (early graph rewrite)

**Use Option C, but implement it as an early TT-specific reduction rewrite — NOT `renderer.extra_matcher`.**

### Why not `extra_matcher`?

`extra_matcher` runs too late in the pipeline. Reductions are lowered at `codegen/__init__.py:67` (`pm_reduce` pass), but `extra_matcher` is applied later at line 103 (`pm_final_rewrite`). By the time `extra_matcher` runs, `REDUCE_AXIS` ops have already been converted to `DEFINE_ACC` + range loops — there's no reduction op left to intercept.

### Where to hook

The rewrite needs to happen **before rangeify / reduction lowering**. Candidate hook points:
- A TT-specific schedule-level transform (pre-rangeify)
- A custom pass in the TT renderer that runs before codegen

### Implementation sketch

```python
# Pseudocode for TT reduction padding rewrite
from tinygrad.uop.ops import identity_element

def pad_reduction_inputs_to_tiles(reduce_op):
    """For each REDUCE_AXIS input, pad to 32x32 tile boundary with identity value."""
    op_type = reduce_op.arg[0]  # Ops.ADD, Ops.MAX, etc.
    dtype = reduce_op.dtype
    pad_value = identity_element(op_type, dtype.scalar())

    # Compute padding needed to reach tile boundary
    # Insert Tensor.pad() with value=pad_value on each reduction axis
    ...
```

### Key references

| What | Where |
|------|-------|
| `identity_element()` | `tinygrad/uop/ops.py:32` |
| `Tensor._pad_constant()` | `tinygrad/tensor.py:1071` |
| Reduction lowering (pm_reduce) | `tinygrad/codegen/__init__.py:67` |
| `extra_matcher` application | `tinygrad/codegen/__init__.py:103` |
| `PADTO` optimization | `tinygrad/codegen/opt/postrange.py:189` |
| `reduce_to_acc` (REDUCE → DEFINE_ACC) | `tinygrad/codegen/late/devectorizer.py:320` |
| PAD → WHERE conversion | `tinygrad/schedule/indexing.py:85` |
| Allocator zero-pad | `tinygrad/runtime/ops_tt.py:42` (TTAllocator._copyin) |
| Compute template n_tiles arg | `tinygrad/runtime/support/compiler_tt.py:391` |

## Phase Plan

- **Phase 1 (elementwise only):** Zero-pad in allocator is sufficient. No reduction padding needed.
- **Phase 2 (reductions):** Implement the early graph rewrite described above.

## Source

Analysis performed by gpt-5.3-codex (reasoning effort: xhigh, 139k tokens used) on 2025-03-02, cross-validated against tinygrad source and TT hardware constraints.
