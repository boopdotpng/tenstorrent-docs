# tinygrad UOp probes for attention and LLM-ish lowering

Date: 2026-05-21

Scope: host-only tinygrad probes using local `TT_DUMP_STAGE`
instrumentation. I used `DEV=PYTHON DEVICE=PYTHON` for pure tensor/codegen
probes and did not use Tenstorrent hardware or the TT device queue.

This document rewrites the raw `UOp(...)` dumps into normalized trees. It keeps
the operation shapes, reductions, stores, and stage boundaries, but removes
Python object IDs, repeated constants, and incidental `arange` construction
noise.

## Probe commands

```bash
cd /home/boop/tenstorrent/tinygrad

TT_DUMP_STAGE='tensor:linear_with_vars input,schedule:function input,schedule:kernel graph,schedule:scheduled linear,codegen:base ast,codegen:simplify ranges,codegen:add local buffers,codegen:remove reduce,renderer:linear' \
DEV=PYTHON DEVICE=PYTHON python3 - <<'PY'
from tinygrad import Tensor, dtypes

q = Tensor.arange(2*3, device="PYTHON").reshape(1,1,2,3).float()
k = Tensor.arange(4*3, device="PYTHON").reshape(1,1,4,3).float()
print((q @ k.transpose(-2,-1)).realize().numpy().tolist())

x = Tensor([[1.0, 2.0, 3.0, 4.0], [2.0, 0.0, -1.0, 1.0]],
           device="PYTHON", dtype=dtypes.float32)
print(x.softmax(-1).realize().numpy().tolist())

q = Tensor.arange(2*3, device="PYTHON").reshape(1,1,2,3).float() / 10
k = Tensor.arange(4*3, device="PYTHON").reshape(1,1,4,3).float() / 10
v = Tensor.arange(4*2, device="PYTHON").reshape(1,1,4,2).float()
print(q.scaled_dot_product_attention(k, v).realize().numpy().tolist())
PY

TT_DUMP_STAGE='tensor:linear_with_vars input,schedule:function input,schedule:kernel graph,schedule:scheduled linear,codegen:base ast,codegen:simplify ranges,codegen:add local buffers,codegen:remove reduce' \
DEV=PYTHON DEVICE=PYTHON python3 - <<'PY'
from tinygrad import Tensor

x = Tensor.arange(2*3, device="PYTHON").reshape(2,3).float()
w = Tensor.arange(3*12, device="PYTHON").reshape(3,12).float()
print((x @ w).reshape(2,3,4).contiguous().realize().numpy().tolist())

cache = Tensor.zeros(2,1,1,4,2, device="PYTHON").realize()
k = Tensor.ones(1,1,1,2, device="PYTHON") * 7
v = Tensor.ones(1,1,1,2, device="PYTHON") * 8
assigned = Tensor(cache.uop.after(
  cache[:, :, :, 2:3, :].uop.store(Tensor.stack(k, v).uop)))
print((assigned + 1).realize().numpy().tolist())
PY
```

Observed outputs for the fully scheduled probes:

```text
q @ k.T:
  [[[[5, 14, 23, 32], [14, 50, 86, 122]]]]

softmax:
  [[0.0320586, 0.0871443, 0.2368828, 0.6439142],
   [0.6439142, 0.0871443, 0.0320586, 0.2368828]]

scaled_dot_product_attention:
  [[[[3.1298048, 4.1298051], [3.5133586, 4.5133586]]]]
```

The explicit `cache.uop.after(...store(...))` probe exposed the same tensor
pattern used by `tinygrad/llm/model.py`, but the small standalone realize failed
during callify with an invalid-shrink shape error. I treat that as a tensor-stage
hook observation, not a scheduled-kernel result.

## Notation

- `RANGE L extent=N` means an output loop range.
- `RANGE R extent=N` means a reduction range.
- `INDEX(buf, offset)` means pointer/index construction.
- `REDUCE ADD/MAX over ()` is tinygrad's scalar reduction node after scheduling.
- `EXP2((x - max) * log2(e))` is tinygrad's numerically stable softmax exponent.
- `AFTER(base, effect)` returns the same logical buffer identity as `base`, but
  orders later consumers after `effect`.

## Stage map for attention

| Stage | What it still says |
| --- | --- |
| `tensor:linear_with_vars input` | Best high-level intent point. Matmul is still `EXPAND -> MUL -> REDUCE ADD`; softmax is still max-reduce, exponent, sum-reduce, reciprocal; KV cache update is still `AFTER` plus `STORE` into a `SHRINK` view. |
| `schedule:function input` | Same graph wrapped around params and output stores. Useful for seeing callified buffer identity and `AFTER`, but movement intent is already more verbose. |
| `schedule:kernel graph` | Good dependency view. Softmax becomes three dependent calls: row max, row reciprocal-sum, final normalize. SDPA becomes qk, softmax pieces, then probability-value matmul. |
| `codegen:base ast` | Best compact kernel view. Reductions still exist with output and reduction ranges; matmul and softmax-reduce kernels are recognizable. |
| `codegen:add local buffers` | Latest useful pre-render hook for reduction shape. Upcast/local choices are visible, vector lanes are packed with `STACK`, and `REDUCE` is still present. |
| `codegen:remove reduce` and `renderer:linear` | Too late for semantic attention matching. Reductions are scalar `ADD`/`MAX` trees over `GEP` lanes, and SDPA intent is just a sequence of ordinary kernels. |

## QK matmul: `q @ k.transpose(-2, -1)`

Probe shape:

```text
q: [B=1, H=1, Tq=2, D=3]
k: [B=1, H=1, Tk=4, D=3]
out: [1, 1, 2, 4]
```

### Tensor graph

Ops include one float `MUL` and one float `REDUCE ADD`; extra integer
reductions come from `arange` construction and are not part of matmul intent.

```text
SINK
  RESHAPE out [1,1,2,4]
    REDUCE ADD axes=(D)
      MUL
        EXPAND
          RESHAPE q -> [1,1,Tq,1,D]
        EXPAND
          PERMUTE k [1,1,Tk,D] -> [1,1,D,Tk]
          RESHAPE -> [1,1,1,Tk,D]
```

### Codegen base AST

```text
SINK kernel test
  STORE out[tq*4 + tk]
    REDUCE ADD over ()
      CAST(q_index)
      *
      CAST(k_index)

  q_index = tq*3 + d
  k_index = tk*3 + d

  RANGE L tq extent=2
  RANGE L tk extent=4
  RANGE R d  extent=3
```

The transpose on `k` is gone by this point; the remaining evidence is the
address expression `tk*3 + d`, not `d*4 + tk`.

### After local/upcast expansion

The `D=3` reduction is unrolled into lanes. At `codegen:add local buffers`, it is
still a reduction:

```text
STORE out[tq*4 + tk]
  REDUCE ADD over ()
    STACK/GEP lanes for d = 0,1,2
      q[tq*3 + d] * k[tk*3 + d]
```

At `codegen:remove reduce`, the same intent is only:

```text
STORE out[tq*4 + tk]
  ADD(ADD(lane0, lane1), lane2)
```

Hook note: for a TT backend trying to identify a QK score matmul, use
`codegen:base ast` or `codegen:add local buffers` if matching lowered kernels,
and `tensor:linear_with_vars input` if matching attention-shaped tensor intent.

## Softmax over the last axis

Probe shape: `x: [2,4]`, softmax axis `-1`.

### Tensor graph

```text
SINK
  MUL
    e =
      EXP2
        MUL
          ADD
            x[row, col]
            MUL
              EXPAND DETACH(REDUCE MAX axis=col x[row, col])
              -1.0
          log2(e)
    EXPAND
      RECIPROCAL
        REDUCE ADD axis=col
          e
```

The user-level `softmax` has already decomposed into stable softmax:

```text
e = exp2((x - max(x, axis)) * log2(e))
y = e / sum(e, axis)
```

### Scheduled kernel graph

Softmax became three dependent kernels:

```text
K0 row_max:
  maxbuf[row] = REDUCE MAX col x[row, col]

K1 row_inv_sum:
  invbuf[row] =
    RECIPROCAL(
      REDUCE ADD col EXP2((x[row,col] - maxbuf[row]) * log2(e)))

K2 normalize:
  out[row,col] =
    EXP2((x[row,col] - maxbuf[row]) * log2(e)) * invbuf[row]
```

This is important for FA/LLM inference: by the time the scheduler emits calls,
there is no single softmax op. There is a recognizable max/sum/normalize chain,
but it is already a multi-kernel pattern unless a backend intercepts earlier or
fuses the dependent calls.

### Codegen base ASTs

Row max:

```text
STORE maxbuf[row]
  REDUCE MAX over ()
    x[row*4 + col]

RANGE L row extent=2
RANGE R col extent=4
```

Inverse denominator:

```text
STORE invbuf[row]
  RECIPROCAL
    REDUCE ADD over ()
      EXP2((x[row*4 + col] - maxbuf[row]) * log2(e))

RANGE L row extent=2
RANGE R col extent=4
```

Normalize:

```text
STORE out[row*4 + col]
  EXP2((x[row*4 + col] - maxbuf[row]) * log2(e)) * invbuf[row]

RANGE L row extent=2
RANGE L col extent=4
```

At `codegen:remove reduce`, `REDUCE MAX` becomes a `MAX(MAX(MAX(...)))` lane
tree and `REDUCE ADD` becomes scalar `ADD`s. That is too late to ask "is this a
softmax?" without rebuilding a pattern from arithmetic.

## `scaled_dot_product_attention`

Probe expression:

```python
q.scaled_dot_product_attention(k, v)
```

with:

```text
q: [1,1,2,3]
k: [1,1,4,3]
v: [1,1,4,2]
out: [1,1,2,2]
```

The implementation in `tensor.py` builds:

```text
qk = (q @ k.transpose(-2, -1)) * (1 / sqrt(D))
out = softmax(qk, axis=-1) @ v
```

### Normalized tensor tree

```text
SINK
  REDUCE ADD axes=(Tk)
    MUL
      EXPAND
        softmax_scores [B,H,Tq,Tk]
      EXPAND
        v [B,H,Tk,Dv]

softmax_scores =
  EXP2((scores - REDUCE MAX(scores, axis=Tk)) * log2(e))
  *
  RECIPROCAL(REDUCE ADD axis=Tk EXP2(...))

scores =
  MUL
    REDUCE ADD axes=(D)
      q[B,H,Tq,D] * k[B,H,Tk,D]
    CONST(1 / sqrt(3))
```

### Stage evolution

At tensor stage, this is the last place where the full attention formula is in
one graph. There is no dedicated `SDPA` UOp; the hook must match the composite
shape:

```text
matmul(q, transpose(k))
  -> scale
  -> stable softmax over key/time axis
  -> matmul(probabilities, v)
```

At schedule/kernel stages, the formula splits into ordinary kernels:

```text
K0 qk_scores:
  scores[tq, tk] = REDUCE ADD d q[tq,d] * k[tk,d] * scale

K1 row_max:
  maxbuf[tq] = REDUCE MAX tk scores[tq,tk]

K2 row_inv_sum:
  invbuf[tq] = 1 / REDUCE ADD tk exp(scores[tq,tk] - maxbuf[tq])

K3 pv:
  out[tq, dv] =
    REDUCE ADD tk
      exp(scores[tq,tk] - maxbuf[tq]) * invbuf[tq] * v[tk,dv]
```

In the renderer dump, these are just matmul/reduction/elementwise fragments with
register/local buffers. The useful FA hook is therefore before or around
`schedule:kernel graph`, not after `renderer:linear`.

## QKV projection pattern

Probe expression:

```python
(x @ w).reshape(2, 3, 4).contiguous()
```

with `x: [tokens=2, in=3]` and `w: [in=3, qkv=12]`.

This models a fused projection whose output channel dimension is later viewed as
`[qkv=3, head_dim=4]`.

### Tensor graph

```text
SINK
  CONTIGUOUS
    RESHAPE [2,12] -> [2,3,4]
      REDUCE ADD axes=(in)
        MUL
          EXPAND x -> [2,12,3]
          EXPAND PERMUTE(w) -> [2,12,3]
```

The `RESHAPE [2,12] -> [2,3,4]` survives at tensor and function-input stages,
so this is a good point to notice "the matmul result is being partitioned into
Q/K/V-like groups."

### Codegen base AST

```text
STORE out[token*12 + qkv_lane]
  REDUCE ADD over ()
    x[token*3 + in] * w[in*12 + qkv_lane]

RANGE L token    extent=2
RANGE L qkv_part extent=3
RANGE L hd       extent=4
RANGE R in       extent=3

qkv_lane = qkv_part*4 + hd
```

By base AST, the reshape has become output address math. It is still possible to
infer the split because the output loops are `2,3,4`, but the original projection
API shape is gone.

Hook note: for LLM inference, `tensor:linear_with_vars input` is better for
recognizing fused `qkv` projection layout. `codegen:base ast` is still useful if
the backend wants to select a matmul implementation and preserve the output tile
layout.

## KV-cache slice update

tinygrad's current LLM path does not use plain multidimensional view `assign`
for KV cache update. In `tinygrad/llm/model.py`, it builds the update directly:

```python
assigned_kv = Tensor(self.cache_kv.uop.after(
  self.cache_kv[:, :, :, start_pos:start_pos+T, :].uop.store(
    Tensor.stack(k, v).uop)))
```

The small host probe mirrors that shape with a fixed `start_pos=2`.

### Tensor-stage tree

```text
SINK
  ADD
    AFTER
      base:
        cache [2, B=1, KVH=1, max_context=4, D=2]
      effect:
        STORE
          dest:
            SHRINK cache
              axis kv:      0:2
              axis batch:   0:1
              axis head:    0:1
              axis time:    2:3
              axis dim:     0:2
          value:
            STACK(k, v) shaped [2,1,1,T=1,D=2]
    CONST(1.0)
```

This is the clean hook point for cache update:

```text
AFTER(cache, STORE(SHRINK(cache, time=start:start+T), STACK(k, v)))
```

The `AFTER` carries the updated cache identity to later `k = assigned_kv[...]`
and `v = assigned_kv[...]` slices. A TT backend can use this as a side-effect
marker: the destination is a slice of the same cache buffer, and the value is a
new token block.

### Scheduling status

In this checkout, my standalone fixed-shape version exposed the tensor-stage
tree above, then failed during callify with:

```text
ValueError: invalid shrink ... for (2, 1, 1, 1, 2)
```

So this probe is useful as a latest high-level hook observation, not as a proven
scheduled local kernel. The simpler 1-D slice assign corpus in
`memory-effects-after.md` remains the working scheduled reference for
`AFTER -> STORE -> CALL` dependency evolution.

## Latest useful TT hook points for FA/LLM inference

For full flash-attention-style matching, the best hook is before attention is
split into independent kernels:

```text
tensor:linear_with_vars input
  match qk matmul + scale + stable softmax + pv matmul
```

For a backend that operates after scheduling, the latest still-useful point is:

```text
schedule:kernel graph
  match dependent qk -> max -> inv_sum -> pv calls
```

This stage still preserves call dependencies and temporary buffers, which are
needed to recognize softmax rows and fuse them back into an FA kernel. It no
longer preserves a single `softmax` or `SDPA` op.

For individual matmul lowering, `codegen:base ast` and `codegen:add local
buffers` are useful:

```text
codegen:base ast
  REDUCE ADD with output loops and reduction loop intact

codegen:add local buffers
  local/upcast choices visible while REDUCE still exists
```

After `codegen:remove reduce`, reductions are scalar trees. After
`renderer:linear`, the graph is renderer-ready operational code. Those stages are
good for validating emitted address math, but they are poor places to discover
LLM intent.

For KV-cache update, the latest clean semantic hook is earlier:

```text
tensor:linear_with_vars input or schedule:function input
  AFTER(cache, STORE(SHRINK(cache, time slice), new_kv))
```

Once lowered, this should become ordinary slice-store kernels plus dependency
edges. The important semantic fact is not the scalar store itself; it is that the
write updates a time slice of a persistent cache and returns the cache identity
for the following attention read.
