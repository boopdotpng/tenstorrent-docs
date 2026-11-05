# Llama 3 FP8 decode optimizations

Changes were made on top of the existing `blackhole-py-llama3-fp8-speedup`
worktree. Measurements use card 0 through `tt-device-queue`. The baseline is
that pre-edit worktree, not clean Git HEAD. Its source hash and the measured
results are in [llama_fp8_speedup_results.json](../../../blackhole-py/tools/llama_fp8_speedup_results.json).

## Current status (2026-11-05)

The env vars and flags this page originally described are gone; there is
one decode path per model:

- **Split attention is always on for 8B** (BF16 and FP8 weights). The runtime
  captures a second resident decode trace; from position 511 on, four
  workers per KV head process interleaved quarters of the sequence and a
  merge launch combines their FP32 `(O, m, l)` states with stable
  exponential rescaling. Shorter positions replay the original unsplit
  trace, so short-context speed is unchanged. It costs 32 extra merge
  launches per token on the long trace, extra build time, and resident code
  storage. Rounding differs from unsplit attention (different summation
  order) but stays in FP32/BF16.
- **The FP8 LM head was removed.** It was faster but changed greedy tokens
  (63/64 matched), so it failed the "no quality loss" bar.
- FP8 KV cache/attention (`LLAMA_ATTENTION_DTYPE`), FP8 fidelity 2
  (`LLAMA_FP8_FIDELITY`), and the hybrid RMSNorm (`LLAMA_RMSNORM`) were
  removed. The first two were untested or unmeasured; the hybrid RMSNorm was
  slower in decode.
- 2 KiB FP8 weight pages, DRAM port rotation, 88/96 projection cores, and the
  NoC split at column 7 for the down projection are now fixed constants in
  `examples/llama3/config.py`.

Measured on card 0 against unsplit HEAD (card 1), 64 tokens, 4096-token prefix:

| Model | Unsplit | Split | Speedup | Teacher-forced token agreement |
| --- | ---: | ---: | ---: | ---: |
| 8B FP8 | 28.06 ms | 22.20 ms | 1.26× | 60/64 |
| 8B BF16 | 41.95 ms | 36.06 ms | 1.16× | 63/64 |

Short-context (20-token prompt) timing and tokens are identical to unsplit
(64/64 on both 8B models). At 4K, free-running generation diverges at token
9 (FP8) and 33 (BF16). The 4K prefix is the chat prompt repeated, so FP8's
flips are template tokens (`assistant` vs `<|start_header_id|>`).

Top-2 logits at the disagreeing teacher-forced positions (unsplit → split):

| Model | Step | Unsplit | Split |
| --- | ---: | --- | --- |
| BF16 | 33 | 18.375 vs 18.25 | 18.5 vs 18.5 (exact tie) |
| FP8 | 9 | 21.5 vs 20.75 | 20.75 vs 20.75 (exact tie) |
| FP8 | 14 | 21.5 vs 21.0 | 21.375 vs 21.0 (order flipped) |
| FP8 | 34 | 21.875 vs 21.375 | 21.875 vs 21.625 (order flipped) |
| FP8 | 43 | 16.625 vs 16.25 | 16.875 vs 15.375 (order flipped) |

BF16 differs by one BF16 step. FP8 logits move by up to ~1.5: each FP8
projection rounds its input to E4M3, which amplifies the small change in
attention summation order. Neither path is a higher-precision reference;
an FP32 CPU comparison on natural long text is still to do.

The sections below are the original record and still mention the removed
options.

## Implemented

- Batch all K/V feature tiles of an attention block into one read transaction.
- Batch RoPE cosine/sine reads, KV-append writes, and context scatter writes.
- Read projection token, norm weights, and residual together where independent.
- Let the projection reader proceed before RMSNorm/FP8 conversion finishes;
  the unpacker waits for the converted activation before consuming it.
- Buffer the complete `down` input instead of serializing reads through a
  two-tile conversion buffer. FP8 weight CBs hold 16 rows; BF16 retains two.
- Use 2 KiB FP8 weight pages on eight-bank devices. Logical tensor tiles and
  row ownership are unchanged. `LLAMA_FP8_PAGE_TILES=1` restores 1 KiB pages;
  `4` selects 4 KiB where rows permit it, and 2 KiB for the 14-tile down input.
  The seven-bank path retains its original storage and generic reader.
- Issue dense scatter chunks in one non-posted transaction and wait once.
- Optional per-row FP8 LM head, including resident per-row scale instructions.
- Optional split attention and stable partial-state merge, with correct tail
  masking and empty-partition handling.

## Measurements

These are mean decode-call wall times, excluding loading and prompt ingestion.
Short runs use a 20-token story prompt and 64 measured continuations. The
optimized short runs replay the exact baseline token history. Long runs use
repeated prompt tokens to fill the prefix and measure eight continuations.

| Case | Before | After | Speedup |
| --- | ---: | ---: | ---: |
| Short FP8, BF16 LM head, unchanged arithmetic | 20.79 ms / 48.1 tok/s | 20.08 ms / 49.8 tok/s | 1.035× |
| Short FP8, optional FP8 LM head | 20.79 ms / 48.1 tok/s | 18.93 ms / 52.8 tok/s | 1.10× |
| 1,024-token prefix, batched unsplit vs split attention, BF16 LM head | 22.92 ms | 21.70 ms | 1.06× |
| 4,096-token prefix, original vs FP8 LM head + split attention | 38.57 ms / 25.9 tok/s | 22.70 ms / 44.1 tok/s | 1.70× |

The 4K runs precede the final RoPE read/write batching. They generate
independently from the same prefix; they are timing comparisons, not an
identical-input accuracy comparison. The 1K comparison uses identical inputs.
These are single-card samples, not statistical confidence intervals.
The projected 60 tok/s in the original writeup was **not** reached.

BF16 generation remains numerically unchanged in the tested sequences.
8B BF16 measured approximately 33.7 ms before and 34.1 ms after; no short-context
BF16 speedup is claimed. 1B BF16 was approximately 6.48 ms before and 6.46 ms
after.

## Validation

- Lossless FP8 changes: 64/64 teacher-forced next-token predictions and final
  logits exactly match the saved baseline.
- FP8 LM head: 63/64 next-token predictions match; final-logit correlation is
  about 0.9995. This is a smoke test, not a perplexity/quality evaluation.
- 1K split attention: 8/8 predictions match unsplit attention on identical
  input history; final-logit correlation is about 0.9982 across the full model.
- 8B BF16 and 1B BF16: 32/32 predictions and final logits match their respective
  pre-edit baselines.
- Ten host tests validate E4M3 normal values and ties, the normal/subnormal
  boundary, zero/tiny rows, and physical page allocation constraints.
- Eight hardware tests compare GQA against NumPy at lengths 1, 31, 32, 33,
  129, 512, 1025, and 4096. These exercise empty splits, all tail owners,
  full/partial blocks, distinct query heads, and large masked cache values.
  Split attention has correlation above 0.99984 and relative RMS error below
  2% in these tests. At 4K its error is lower than the unsplit implementation.

```sh
tt-device-queue run --device 0 --timeout 180 -- \
  ../.venv/bin/python -m pytest \
  tests/test_llama_fp8.py tests/compute/fpu/test_llama_attention.py \
  --bh-hardware --bh-device 0 -q -s
```

For repeatable end-to-end comparisons:

```sh
# Run this before editing, or use --source /path/to/saved/llama3.py.
tt-device-queue run --device 0 --timeout 180 -- \
  ../.venv/bin/python -m tools.bench_llama_decode \
  --logits --output /tmp/baseline.json

tt-device-queue run --device 0 --timeout 180 -- \
  ../.venv/bin/python -m tools.bench_llama_decode \
  --replay /tmp/baseline.json --lm-head-dtype fp8 --split-attention \
  --logits --output /tmp/optimized.json
```

The benchmark saves token history and predictions to JSON, plus final logits
to a neighboring `.npy` file. Use `--context 1024` or `--context 4096` for long
prefixes; prompt ingestion still runs through decode. `--dtype bf16` and
`--model 1b --dtype bf16` cover the other existing paths.

## Recommendations not retained or implemented

Multiple-row transactions, alternating per-row TIDs, cached NoC command
fields, and a two-TID pipeline of four-row batches were implemented and
measured. They preserved the sampled output but regressed short FP8 decode
from roughly 20.1 ms to 20.5–24.5 ms, depending on the variant. Those
experiments were removed. The retained weight reader still drains each row;
larger DRAM pages reduce the requests per row. Four-KiB pages did not improve
the full-model result enough to replace the 2 KiB default.

Cross-layer/projection launch fusion is not implemented. The default trace
still has 163 launches and the split-attention trace has 195. Fusion requires
an additional kernel/synchronization redesign; the performance figures here
do not assume that future improvement.
