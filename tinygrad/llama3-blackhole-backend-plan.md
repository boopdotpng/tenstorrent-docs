# Llama 3.2 1B as a Blackhole/tinygrad backend target

Date: 2026-05-31

> **Historical design note.** The model target and Blackhole strategy remain
> useful, but tinygrad's July 2026 codegen rewrite removed `GEP`, vector dtypes,
> and several stages referenced below. Use
> [the current internals guide](internals-guide.md) and
> [Blackhole mapping](blackhole-backend-map.md) for the current compiler seam.

This note collects the current plan for using a small modern Llama-family model as
the end-to-end target for a Tenstorrent Blackhole backend. The intended path is:

1. Run the model directly in `blackhole-py` with hand-written primitives.
2. Use that primitive set as the target surface for a tinygrad integration.
3. Hook tinygrad early enough to recover tensor program intent instead of
   reverse-engineering GPU-oriented scalar address math from a renderer.

The short version: **Llama 3.2 1B Instruct is the right first target**. It is
modern enough to exercise the dense decoder stack used by many current LLMs, but
small and regular enough that failures should mostly be backend/compiler issues,
not model-architecture surprises.

## Why Llama 3.2 1B first

The local tinygrad checkout has a practical runner in:

```text
/home/boop/tenstorrent/tinygrad/examples/llama3.py
```

The supported local model sizes include:

```text
1B, 8B, 70B, 405B
```

The built-in 1B download path points at `Llama-3.2-1B-Instruct-Q6_K.gguf`.
For Blackhole bring-up, prefer f16/bf16 weights first if possible; quantized GGUF
formats add dequant/block-format work that is not core Llama architecture.

Llama 3.2 1B config in tinygrad:

```text
layers:      16
dim:         2048
heads:       32
kv heads:    8
head dim:    64
hidden dim:  8192
vocab:       128256
norm eps:    1e-5
RoPE theta:  500000
```

This gives one concrete, bounded goal:

```text
greedy decode, batch=1, one token at a time, host-side token selection
```

Once that works, extend to prompt prefill, larger context, sampling, quantized
weights, and then MoE/MLA models.

## What tinygrad actually supports locally

Practical runners:

- `examples/llama3.py`: Llama 3.x-style dense decoder models, including Llama
  3.2 1B and DeepSeek-R1-Distill-Llama-70B through the same Llama-shaped path.
- `examples/qwq.py`: Qwen/QwQ-32B-Preview, but implemented by reusing the Llama
  transformer with Qwen-ish dimensions and QKV bias. This is useful later, but
  too large for first bring-up.
- `examples/olmoe.py`: OLMoE-1B-7B-0924. This exercises router softmax, top-k
  expert selection, expert matmuls, and weighted expert combine.

Test-level architecture support:

- `test/unit/test_llm_moe.py`: MoE/shared-expert behavior.
- `test/unit/test_llm_mla.py`: DeepSeek-style MLA/compressed KV attention
  behavior.

There is no polished local runner for Qwen3, Gemma 3, Llama 4, or DeepSeek V3 in
this checkout. Those architectures matter long term, but the dense Llama path is
the smallest useful first compiler target.

## Llama 3.2 layer order

Tinygrad's Llama forward pass is in `extra/models/llama.py`.

Top-level:

```text
tokens
  -> token embedding lookup
  -> repeated transformer blocks
  -> final RMSNorm
  -> output/lm_head matmul
  -> logits
  -> argmax or sampling
```

One transformer block:

```text
x
  -> attention_norm = RMSNorm(x)
  -> attention(attention_norm)
  -> residual add with x
  -> ffn_norm = RMSNorm(residual)
  -> feed_forward(ffn_norm)
  -> residual add
```

Attention:

```text
input: x [batch, seq, dim]

q = x @ Wq
k = x @ Wk
v = x @ Wv

reshape:
  q -> [batch, seq, n_heads, head_dim]
  k -> [batch, seq, n_kv_heads, head_dim]
  v -> [batch, seq, n_kv_heads, head_dim]

apply RoPE to q and k

write current k/v into persistent KV cache
read keys/values from cache range [0:start_pos+seq]

GQA:
  n_heads=32, n_kv_heads=8, so each KV head serves 4 Q heads

transpose to [batch, heads, seq, head_dim]

scores = q @ k.T / sqrt(head_dim)
scores += mask when needed
probs = softmax(scores)
attn = probs @ v

reshape to [batch, seq, dim]
out = attn @ Wo
```

Feed-forward:

```text
w1 = silu(x @ W1)
w3 = x @ W3
out = (w1 * w3) @ W2
```

This is SwiGLU/SiLU-style gated MLP.

## Does tinygrad use FlashAttention here?

In this local Llama path, no external FlashAttention kernel is called.

`Tensor.scaled_dot_product_attention` lowers as a composite formula:

```text
qk = q.matmul(k.transpose(-2, -1)) / sqrt(head_dim)
qk = qk + mask
out = softmax(qk) @ v
```

The scheduler may fuse attention-shaped pieces in some paths, and there are
tests around flash-attention-style fusion, but there is no dedicated `SDPA` UOp
in the generic tensor graph. For Blackhole, assume the backend must recognize or
provide:

```text
QK matmul -> row softmax -> PV matmul
```

as either separate primitives first, then optionally as a fused attention kernel.

## blackhole-py primitive checklist

The point of the direct `blackhole-py` implementation is to write all primitives
the later tinygrad backend should need. The first complete target is dense Llama
3.2 1B greedy decode.

### Storage and movement

- Device open/reset and dispatch through existing `blackhole-py`.
- DRAM allocation for weights, activations, logits, and KV cache.
- Host to device weight upload.
- Device to host logits or token id readback.
- Row-major to tile layout conversion and reverse conversion where needed.
- Tiled L1 circular-buffer movement.
- Persistent buffers for per-layer KV cache.

### Tensor/layout primitives

- Reshape/view metadata.
- Transpose/permute where needed for head layout.
- Slice/shrink for KV cache time ranges.
- Expand/broadcast without unnecessary physical copies.
- Concatenate/stack only where useful for convenience; avoid in hot paths if a
  layout-aware kernel can address directly.

### Elementwise SFPU/FPU primitives

- Add, subtract, multiply.
- Multiply by scalar constants.
- Fused multiply-add where useful.
- Reciprocal.
- Approximate exp or exp2.
- Approximate rsqrt.
- Compare: less-than/greater-than/equal as needed.
- Select/where for masks and argmax bookkeeping.
- Cast between f16/bf16/f32 as supported.
- Optional clamp/abs for later quantization paths.

Blackhole SFPU instruction surface in `blackhole-py/dsl.py` includes the useful
building blocks:

```text
TTSFPLOAD, TTSFPSTORE, TTSFPLOADI
TTSFPADD, TTSFPMUL, TTSFPMAD
TTSFPADDI, TTSFPMULI
TTSFPARECIP
TTSFPEXEXP, TTSFPLUT, TTSFPLUTFP32
TTSFPSETCC, TTSFPLE, TTSFPGT
TTSFPMOV, TTSFPABS, TTSFPCAST, TTSFPSTOCHRND
TTSFPSETEXP, TTSFPSETMAN, TTSFPEXMAN
```

The awkward one is `rsqrt`. Tinygrad's RMSNorm expresses this as
`sqrt().reciprocal()`. If Blackhole has no direct exposed sqrt/rsqrt instruction,
implement an approximation with exponent/mantissa manipulation, LUT, and/or
Newton refinement. This is a likely early accuracy/debug hotspot.

### Reductions

- Sum reduction over hidden dimension for RMSNorm.
- Max reduction over attention row for stable softmax.
- Sum reduction over attention row for stable softmax.
- Argmax reduction over vocab logits for greedy decode.
- Optional top-k reduction for sampling and MoE later.

### Matmul/linear

This is the primary performance primitive.

Decode needs mostly:

```text
[1, dim] @ [dim, out]
```

Prefill needs:

```text
[seq, dim] @ [dim, out]
```

Required linears for Llama 3.2 1B:

```text
embedding: token id -> [2048]
attention:
  Wq: [2048, 2048]
  Wk: [2048, 512]
  Wv: [2048, 512]
  Wo: [2048, 2048]
MLP:
  W1/gate: [2048, 8192]
  W3/up:   [2048, 8192]
  W2/down: [8192, 2048]
output:
  lm_head: [2048, 128256]
```

For decode, an optimized matrix-vector path may be useful. For prefill, a normal
tiled matrix-matrix path is needed.

### Embedding lookup

- Gather one or more rows from token embedding matrix.
- For greedy decode, the hot case is one token -> one 2048-vector.
- For prefill, gather `seq` token rows.

This can initially run as a host-side copy/upload for tiny tests, but end-to-end
LLM execution should make it a device primitive.

### RMSNorm

Formula:

```text
y = x * rsqrt(mean(x*x) + eps) * weight
```

Required pieces:

- Square.
- Sum reduce over dim=2048.
- Multiply by `1/2048`.
- Add eps.
- `rsqrt`.
- Elementwise multiply by `x`.
- Elementwise multiply by learned weight.

### RoPE

Precompute cos/sin on host first.

For each pair:

```text
real = x0 * cos - x1 * sin
imag = x0 * sin + x1 * cos
```

Apply to Q and K after projection and head reshape.

### KV cache

Per layer:

```text
K cache: [max_context, n_kv_heads, head_dim]
V cache: [max_context, n_kv_heads, head_dim]
```

For Llama 3.2 1B:

```text
n_kv_heads = 8
head_dim = 64
K token payload = 512 elements
V token payload = 512 elements
```

For each decode token:

1. Write current token K/V at `start_pos`.
2. Read K/V from `0:start_pos+1`.
3. Use GQA mapping instead of physically repeating K/V if possible.

KV addressing is important enough to test independently before full attention.

### GQA attention

Llama 3.2 1B maps:

```text
32 query heads / 8 kv heads = 4 query heads per kv head
```

For head `h`, use:

```text
kv_head = h // 4
```

Decode attention per query head:

```text
scores[t] = dot(q[h, :], K[t, kv_head, :]) * 0.125
probs = softmax(scores over t)
out[h, :] = sum_t probs[t] * V[t, kv_head, :]
```

Prefill adds causal masking.

### Softmax

Stable softmax:

```text
m = max(x)
e = exp(x - m)
s = sum(e)
y = e / s
```

Tinygrad generally represents natural `exp` through `EXP2((x - m) * log2(e))`.
For Blackhole, implement whatever exp/exp2 approximation maps best to SFPU.

### SiLU

Formula:

```text
silu(x) = x * sigmoid(x)
sigmoid(x) = 1 / (1 + exp(-x))
```

Used in the gated MLP:

```text
silu(x @ W1) * (x @ W3)
```

### Logits and token selection

First target:

```text
logits = final_norm(h) @ lm_head
token = argmax(logits)
```

Keep top-k/top-p/multinomial sampling on host at first. Tinygrad's sampling path
uses softmax, optional top-k, cumulative sums, multinomial random sampling, and
alpha penalties. None of that is needed for first end-to-end proof.

## Bring-up order in blackhole-py

Recommended order:

1. Eltwise tile kernel: add/mul/cast sanity.
2. Row/vector reduction: sum and max.
3. RMSNorm on one `[2048]` vector.
4. Linear matvec `[1, 2048] @ [2048, N]`.
5. MLP block: W1/W3, SiLU, multiply, W2.
6. RoPE on Q/K vectors.
7. KV cache write/read for one layer.
8. Single-head decode attention.
9. Full 32-head GQA decode attention.
10. One complete transformer block.
11. 16 blocks + final norm + lm_head.
12. Greedy decode loop.
13. Prefill with causal mask.
14. Quantized weights and sampling.
15. OLMoE-style router/top-k/expert path.
16. MLA/compressed KV path.

## tinygrad integration: current hypothesis

The renderer is almost certainly too late.

The existing UOp probe docs show that by renderer time:

- Matmul intent may be scalar loops or backend-specific `WMMA`.
- Reductions have often become scalar `ADD`/`MAX` trees over `GEP` lane extracts.
- Attention is no longer a single semantic operation.
- GPU-style address math dominates the graph, which is the wrong abstraction for
  a tiled Tenstorrent program.

Useful existing notes:

- `tinygrad/uop-probes/matmul-dot.md`
- `tinygrad/uop-probes/reductions.md`
- `tinygrad/uop-probes/attention-llm.md`
- `tinygrad/tinygrad-uop-arange-slice-sum-stages.md`

The likely TT integration is a **two-level hook**, not one universal hook:

```text
semantic graph hook before scheduling splits intent apart
  use for attention, KV cache, RMSNorm, embedding, and possibly whole block
  recognition

rangeified kernel graph hook before to_program
  use for primitive kernels: matmul, reductions, softmax pieces, elementwise
  epilogues
```

The reason for two levels is that different information becomes useful at
different times:

```text
tensor/function graph
  best for SDPA-shaped intent, KV cache update identity, embedding lookup, and
  model-level structure

schedule/kernel graph after rangeify
  best for matmul/reduction shapes because movement has become explicit ranges
  and indexed loads, but REDUCE still exists

codegen base AST / add local buffers
  latest useful point for REDUCE shape and local/upcast choices

renderer/program UOps
  too late for intent recovery; useful only for validating already-chosen scalar
  codegen
```

### First fork hook

This should start as a fork. The clean abstraction is not obvious yet, and trying
to design the upstream-quality version before `blackhole-py` has a complete LLM
primitive surface would front-load too much uncertainty.

The narrow first experiment is to intercept tinygrad's compile path where
`CALL(SINK)` is currently compiled to `CALL(PROGRAM)` by `to_program`.

In the current tree, `tinygrad/engine/realize.py` has a `pm_compile` rewrite that
does roughly:

```text
CALL(SINK ast, args...)
  -> CALL(to_program(ast, renderer), args...)
```

For a TT device fork, try:

```text
CALL(SINK ast, args...)
  -> if call.device is TT:
       CALL(TT_PROGRAM or CUSTOM_FUNCTION from tt_lower(call, ast), args...)
     else:
       CALL(to_program(ast, renderer), args...)
```

This keeps the initial change small:

- tensor construction remains tinygrad's
- callification remains tinygrad's
- scheduling/rangeify can remain tinygrad's
- ordinary CPU/GPU paths stay on the existing renderer
- TT gets to bypass renderer-level scalar codegen

The TT lowerer can then decide whether to consume:

- the original callified function graph for semantic patterns
- the rangeified kernel graph for primitive patterns
- both, with debug links between them

### Candidate fork strategy

1. Add a TT lowering pass that consumes scheduled kernel graphs or callified
   function graphs before `to_program`.
2. In the fork, route TT-device `CALL(SINK)` through this lowering pass instead
   of the renderer path.
3. Pattern-match high-value LLM structures:
   - matmul: `STORE <- epilogue(REDUCE ADD, MUL(load A, load B))`
   - RMSNorm: square -> sum reduce -> rsqrt -> multiply weight
   - softmax: max reduce -> exp/exp2 -> sum reduce -> reciprocal/multiply
   - attention: QK matmul -> softmax -> PV matmul dependency chain
   - KV cache: `AFTER(cache, STORE(slice(cache), new_kv))`
4. Lower matched patterns to TT semantic primitives, not scalar UOps.
5. Let unmatched simple elementwise kernels fall back to a generic tiled SFPU
   lowering.
6. Keep enough debug metadata to connect TT programs back to the original
   tinygrad graph node or model layer.

### Does tinygrad need an architecture change?

For a local research port: probably not at first.

For a clean, upstream-quality non-GPU target: probably yes.

The needed change is not a rewrite of tinygrad's tensor frontend. It is a cleaner
backend seam between scheduling and code generation:

```text
Tensor graph
  -> schedule / rangeify
  -> BackendLowerer
       RendererLowerer for GPU-style source/binary kernels
       TileProgramLowerer for TT-style multi-core tiled programs
  -> runtime execution
```

The current seam is effectively "give the backend a renderer." That works well
for GPU-like targets where one scheduled kernel becomes one source/binary kernel.
Blackhole wants a program package:

```text
core grid
DRAM tensor layout
L1/CB allocation
reader/writer/dataflow kernels
math kernels
unpack/pack configuration
dispatch metadata
```

That is a different output type from rendered scalar code.

### Hard assumptions to work around

- One scheduled kernel naturally maps to one GPU kernel.
- Program lowering is renderer/source-code shaped.
- Memory is mostly flat buffers plus index expressions.
- Matmul becomes scalar loops or `WMMA`/tensor-core ops.
- Local/shared memory is GPU-like, not CB/tile/dataflow-like.
- Reductions are lowered away too early if the backend waits for renderer UOps.
- Persistent side effects such as KV cache need semantic handling, not just
  scalar stores.

### Unsettled questions

- Whether tinygrad can cleanly support a backend whose native execution model is
  multi-core tiled programs rather than one rendered GPU kernel per schedule
  item.
- Whether the TT path should be a custom `Device` runtime, a graph rewrite pass,
  a custom scheduler/lowerer, or a deliberately separate export path.
- How much model-level pattern matching is acceptable upstream versus kept as a
  local experimental backend.
- How to represent persistent side-effect buffers such as KV cache in a way that
  maps cleanly to TT command queues and DRAM/L1 layouts.

### Practical stance

Start with a fork and make the first working path deliberately narrow:

```text
TT device intercepts CALL(SINK) before to_program.
Pattern-match rangeified kernels.
Lower only:
  matmul
  elementwise
  reductions
  RMSNorm
  softmax pieces
Return executable blackhole-py programs.
```

Then add semantic graph patterns:

```text
attention
KV cache update/read
embedding
maybe whole MLP
```

Only after those experiments work should this be cleaned up into a proposed
tinygrad architecture. The fork is not a failure mode; it is the laboratory for
discovering the actual backend seam.

## UOp visualization goal

The UOp visualization work should answer one question:

```text
At which stage is each LLM operation still recognizable enough to lower to a
Tenstorrent primitive?
```

For every rough optimization stage, record:

- normalized UOp tree/list
- op counts
- shape/range metadata
- where semantic intent first appears
- where semantic intent disappears
- candidate TT primitive match

Suggested next probe documents:

- Full Llama 3.2 1B toy block with tiny dimensions.
- RMSNorm stage-by-stage.
- SiLU/SwiGLU MLP stage-by-stage.
- KV cache update from `extra.models.llama.Attention`, not only the generic
  `tinygrad/llm/model.py` path.
- Decode attention with `T=1` and growing cache length.
- Prefill attention with causal mask.
- Final logits + argmax.

The goal is not to perfectly decode every renderer UOp. The goal is to stop
before that point and preserve enough structure that the TT backend can choose
tile programs, circular-buffer layouts, and core roles deliberately.

## Long-term target ladder

1. Dense Llama 3.2 1B, greedy decode.
2. Dense Llama 3.2 1B, prefill + decode.
3. Dense Llama 3.2 1B with quantized weights.
4. OLMoE or other small MoE model for router/top-k/expert matmuls.
5. MLA unit-test path for compressed KV attention.
6. Larger Qwen/QwQ or DeepSeek-distill model once primitive coverage is mature.

This ladder keeps the first milestone small while still aiming at the operations
used by newer LLM families: GQA, RoPE, RMSNorm, SwiGLU, softmax attention, KV
cache, MoE routing, and eventually MLA.
