# tinygrad Notes

This folder holds tinygrad-specific notes and UOp lowering probes for exploring where a Tenstorrent backend should hook into tinygrad.

- `tinygrad-uop-arange-slice-sum-stages.md`: stage-by-stage walkthrough for `Tensor.arange(100)[45:55].sum()`.
- `uop-probes/`: broader probe corpus covering movement, elementwise ops, reductions, matmul, conv/pool, memory effects, and attention/LLM patterns.
