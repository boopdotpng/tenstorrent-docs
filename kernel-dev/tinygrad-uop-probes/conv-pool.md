# tinygrad UOp probes for conv/pool lowering

Date: 2026-05-21

Scope: host-only tinygrad probes using local `TT_DUMP_STAGE` instrumentation. I used
`DEV=PYTHON` and explicit `device="PYTHON"` tensors so these runs did not touch
Tenstorrent hardware or the TT device queue.

This document rewrites the raw `UOp(...)` dumps into normalized trees. It keeps
the operation shapes and lowering landmarks, but removes Python object IDs,
alias noise, and repeated constant scaffolding.

## Probe commands

```bash
cd /home/boop/tenstorrent/tinygrad

TT_DUMP_STAGE='tensor:linear_with_vars input,schedule:create_linear input,schedule:function input,codegen:base ast,codegen:early movement ops,codegen:simplify ranges,codegen:add local buffers,codegen:remove reduce,renderer:linear' \
DEV=PYTHON python3 - <<'PY'
from tinygrad import Tensor
x = Tensor.arange(16, device="PYTHON").reshape(1,1,4,4).float()
w = Tensor.ones(1,1,2,2, device="PYTHON")
y = x.conv2d(w).realize()
print(y.numpy().tolist())
PY

TT_DUMP_STAGE='tensor:linear_with_vars input,schedule:create_linear input,schedule:function input,codegen:base ast,codegen:early movement ops,codegen:simplify ranges,codegen:add local buffers,codegen:remove reduce,renderer:linear' \
DEV=PYTHON python3 - <<'PY'
from tinygrad import Tensor
x = Tensor.arange(16, device="PYTHON").reshape(1,1,4,4).float()
y = x.max_pool2d(kernel_size=(2,2), stride=(2,2)).realize()
print(y.numpy().tolist())
PY

TT_DUMP_STAGE='codegen:base ast,codegen:simplify ranges,codegen:add local buffers,codegen:remove reduce' \
DEV=PYTHON python3 - <<'PY'
from tinygrad import Tensor
x = Tensor.arange(16, device="PYTHON").reshape(1,1,4,4).float()
w = Tensor.ones(1,1,2,2, device="PYTHON")
b = Tensor([0.5], device="PYTHON")
y = x.conv2d(w, b).relu().realize()
print(y.numpy().tolist())
PY
```

Observed outputs:

```text
conv2d:          [[[[10, 14, 18], [26, 30, 34], [42, 46, 50]]]]
max_pool2d:      [[[[5, 7], [13, 15]]]]
conv+bias+relu:  [[[[10.5, 14.5, 18.5], [26.5, 30.5, 34.5], [42.5, 46.5, 50.5]]]]
```

## Notation

- `RANGE L extent=N` means an output loop range.
- `RANGE R extent=N` means a reduction range.
- `INDEX(buf, offset)` means pointer/index construction.
- `REDUCE ADD/MAX over ()` is tinygrad's scalar reduction node after scheduling.
- `STACK/GEP vecN` means the expander packed the reduction candidates into a vector and selected lanes.
- `WHERE(CMPLT(0, x), x, 0)` is ReLU.

## conv2d: 1x1x4x4 input, 1x1x2x2 filter

High-level tensor lowering follows the implementation in `OpMixin.conv2d`: pad,
pool/im2col, reshape, expand against reshaped weight, multiply, then sum over
input-channel and kernel axes.

### Tensor graph

Ops: `MUL:1, REDUCE ADD:1, PERMUTE:3, RESHAPE/EXPAND/SHRINK/PAD movement`

```text
SINK
  RESHAPE output [1,1,3,3]
    REDUCE ADD axes=(cin, kh, kw)
      MUL
        PERMUTE
          EXPAND/RESHAPE/PERMUTE
            POOL/IM2COL view of x:
              x padded with 0
              windows [oh=3, ow=3, kh=2, kw=2]
        EXPAND
          RESHAPE weight [1,1,1,1,1,1,2,2]
```

For this probe, the filter is all ones, so by `codegen:base ast` the weight side
has disappeared and the kernel is just an indexed four-lane sum over the input
window.

### Codegen base AST

Ops: `RANGE:4, REDUCE ADD:1, INDEX:1, STORE:1`

```text
SINK kernel test
  STORE output[oh*3 + ow]
    REDUCE ADD over ()
      CAST float
        input_index =
          (oh + kh) * 4 +
          (ow + kw)

  RANGE L oh extent=3
  RANGE L ow extent=3
  RANGE R kh extent=2
  RANGE R kw extent=2
```

The important lowering is that im2col never becomes a materialized matrix here.
It becomes range math on `kh` and `kw`, folded into the load offset expression.

### After local/upcast expansion

Ops at `codegen:add local buffers`: `REDUCE ADD:1, GEP:1, STACK:4`.

```text
STORE output[oh*3 + ow]
  REDUCE ADD over ()
    GEP vec4 order=(0,2,1,3)
      CAST float.vec4
        STACK [
          oh*4 + ow + 0,
          oh*4 + ow + 4,
          oh*4 + ow + 1,
          oh*4 + ow + 5,
        ]
```

At `codegen:remove reduce`, the explicit `REDUCE` is gone:

```text
STORE output[oh*3 + ow]
  ADD(ADD(ADD(lane0, lane2), lane1), lane3)
```

This is the latest clean point for seeing "this is a 2x2 convolution
accumulation" as a reduction. After this, the renderer sees scalar `ADD`s and
`GEP`s, not a semantic convolution.

## max_pool2d: 2x2 stride 2

`max_pool2d` uses the same `_pool`/window view machinery as convolution, then
reduces over the kernel axes with `MAX`. Padding is expressed as `WHERE` before
the pool view, selecting real values or `-inf`. In this no-padding probe the
`WHERE` is visible in the early tensor graph because `_pad_constant` still builds
the validity/value form, but it simplifies away before the base AST.

### Tensor graph

Ops: `WHERE:1, REDUCE MAX:1, PERMUTE:2, RESHAPE/EXPAND/SHRINK/PAD movement`

```text
SINK
  RESHAPE output [1,1,2,2]
    REDUCE MAX axes=(kh, kw)
      PERMUTE
        POOL/IM2COL view of:
          WHERE(valid_input, x, -inf)
          windows [oh=2, ow=2, kh=2, kw=2]
```

### Codegen base AST

Ops: `RANGE:4, REDUCE MAX:1, INDEX:1, STORE:1`

```text
SINK kernel test
  STORE output[oh*2 + ow]
    REDUCE MAX over ()
      CAST float
        input_index =
          (oh*2 + kh) * 4 +
          (ow*2 + kw)

  RANGE L oh extent=2
  RANGE L ow extent=2
  RANGE R kh extent=2
  RANGE R kw extent=2
```

The stride appears in the index math as `oh*2` and `ow*2`; the kernel window is
still the pair of reduction ranges.

### After local/upcast expansion

At `codegen:add local buffers`:

```text
STORE output[oh*2 + ow]
  REDUCE MAX over ()
    GEP vec4 order=(0,2,1,3)
      CAST float.vec4
        STACK [
          oh*8 + ow*2 + 0,
          oh*8 + ow*2 + 4,
          oh*8 + ow*2 + 1,
          oh*8 + ow*2 + 5,
        ]
```

At `codegen:remove reduce`:

```text
STORE output[oh*2 + ow]
  MAX(MAX(MAX(lane0, lane2), lane1), lane3)
```

That is the pool analogue of conv's reduce removal: semantic `REDUCE MAX`
becomes a tree of scalar `MAX` operations over vector lanes.

## conv + bias + ReLU

This probe is the useful fused-pattern check:

```python
y = x.conv2d(w, b).relu()
```

### Codegen base AST

Ops: `RANGE:4, REDUCE ADD:1, INDEX:2, ADD:5, CMPLT:1, WHERE:1`.

```text
SINK kernel test
  STORE output[oh*3 + ow]
    WHERE
      cond: CMPLT(0,
        ADD(
          REDUCE ADD over conv window,
          INDEX(bias, 0)))
      true: ADD(REDUCE ADD over conv window, INDEX(bias, 0))
      false: 0

  REDUCE ADD over ()
    CAST float
      input_index = (oh + kh) * 4 + (ow + kw)

  RANGE L oh extent=3
  RANGE L ow extent=3
  RANGE R kh extent=2
  RANGE R kw extent=2
```

In the raw graph the reduction subexpression is structurally shared. In this
normalized tree it is written twice only to make ReLU's `where` shape obvious.

### After local/upcast expansion

With the constant input and all-ones weight, tinygrad upcasts the whole 3x3
output. `codegen:add local buffers` still has the explicit reduction:

```text
STORE output vec9 at lanes [0,3,6,1,4,7,2,5,8]
  WHERE vec9
    cond: CMPLT(0, conv_sum_vec9 + bias_vec9)
    true: conv_sum_vec9 + bias_vec9
    false: 0.vec9

conv_sum_vec9 =
  REDUCE ADD over ()
    GEP vec36
      CAST float.vec36
        STACK all 2x2 input-window offsets for each of the 9 output pixels

bias_vec9 =
  STACK [bias[0], bias[0], ..., bias[0]]
```

At `codegen:remove reduce`, the reduction has become four vector adds:

```text
conv_sum_vec9 =
  ADD(ADD(ADD(GEP lane group 0, GEP lane group 2), GEP lane group 1), GEP lane group 3)

STORE output vec9
  WHERE(CMPLT(0, conv_sum_vec9 + bias_vec9), conv_sum_vec9 + bias_vec9, 0)
```

This is the best "conv+bias+relu" signature: one `REDUCE ADD` feeding an `ADD`
with a broadcast bias load, wrapped in `WHERE(CMPLT(0, value), value, 0)`.

## Hook points that were useful

Instrumentation locations observed in this checkout:

- Tensor graph hook: `tinygrad/tinygrad/tensor.py`, `_dump_uop_graph`.
- Schedule hooks: `tinygrad/tinygrad/schedule/__init__.py`, `_dump_lowering_stage` and `_dump_ttir_input`.
- Codegen hooks: `tinygrad/tinygrad/codegen/__init__.py`, `dump_codegen_stage`.
- Renderer hook: `tinygrad/tinygrad/codegen/__init__.py`, `dump_renderer_uops`.

Stage filters that worked well:

- `tensor:linear_with_vars input`: best view of `_pool`/im2col as movement ops.
- `schedule:create_linear input` and `schedule:function input`: same semantic
  graph after callification, with stores and output buffers exposed.
- `codegen:base ast`: best compact semantic kernel view. Conv and pool both
  appear as loop ranges plus `REDUCE`.
- `codegen:simplify ranges`: best view of stride/index arithmetic after symbolic
  cleanup.
- `codegen:add local buffers`: latest point where explicit `REDUCE ADD` or
  `REDUCE MAX` still exists, now often with packed `STACK/GEP` lanes.
- `codegen:remove reduce`: first stage where explicit reduction intent is gone.
  It is useful for confirming the exact scalar tree generated from the reduce.
- `renderer:linear`: useful sanity check for final emitted UOps, but too late for
  semantic conv/pool detection.

`TT_DUMP_KERNEL=<substring>` is also available in codegen/renderer hooks when
there are multiple kernels and a probe needs filtering by generated kernel name.

## Lowering summary

Convolution and max-pool share the same window lowering path. `_pool` builds an
im2col-like view with reshape/expand/shrink/permute movement ops. Codegen does
not need to materialize that view for these small probes: it converts the window
coordinates into `RANGE` variables and index arithmetic.

The durable semantic forms are:

```text
conv2d:
  STORE out[oh,ow] = REDUCE ADD over kh,kw (x[(oh+kh),(ow+kw)] * w[kh,kw])

max_pool2d:
  STORE out[oh,ow] = REDUCE MAX over kh,kw x[(oh*stride_h+kh),(ow*stride_w+kw)]

conv+bias+relu:
  STORE out = WHERE(0 < (REDUCE ADD window + bias), REDUCE ADD window + bias, 0)
```

For pattern recognition or TT lowering experiments, `codegen:base ast` through
`codegen:add local buffers` is the sweet spot. Earlier tensor/schedule stages
show the high-level transformation but are movement-heavy. Later stages are
excellent for validating what happened, but the semantic reduce has already
been lowered to scalar `ADD`/`MAX` trees.
