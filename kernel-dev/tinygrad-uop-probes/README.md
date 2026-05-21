# tinygrad UOp Probe Corpus

This directory collects small, human-readable UOp lowering probes for evaluating where a Tenstorrent backend should hook into tinygrad.

The goal is to compare stages that still preserve program intent against stages that have already become GPU-style address math, scalarized lanes, or renderer-ready linear UOps.

Probe families:

- `movement-indexing.md`: slicing, reshaping, permutation, padding, gather/mask-style indexing.
- `elementwise-broadcast-casts.md`: scalar ops, broadcasts, where, transcendental-ish ops, dtype casts.
- `reductions.md`: partial/full reductions, max/sum, multi-axis reductions.
- `matmul-dot.md`: dot/matmul, non-tensor-core GPU matmul, tensor-core matmul.
- `conv-pool.md`: conv2d, pooling, fused conv/bias/activation shapes.
- `memory-effects-after.md`: `AFTER`, stores, assigns, cache-update-like dependency chains.
- `attention-llm.md`: attention and LLM-ish probes, including qk/softmax/SDPA/KV-cache patterns.

All probes should avoid Tenstorrent device execution. They are meant to inspect tinygrad lowering and renderer/codegen intent, not run TT kernels.
