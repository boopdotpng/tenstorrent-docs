# tinygrad UOp reduction probes

Date: 2026-05-21

These probes used local tinygrad `TT_DUMP_STAGE` instrumentation on the host only:

```bash
cd /home/boop/tenstorrent/tinygrad
DEVICE=CPU TT_DUMP_STAGE='codegen:base ast,codegen:add local buffers,codegen:remove reduce,codegen:devectorize' python3 <probe.py>
```

No Tenstorrent device commands or device queue runs were used.

This document rewrites the raw `UOp(...)` dumps into normalized trees. The names below are descriptive; repeated aliases, object IDs, dtype noise, and full Python reprs are intentionally omitted.

Notation:

- `LOOP[i:N]` is a non-reduce output loop range.
- `REDUCE[r:N]` is a reduce range before vectorization or accumulator lowering.
- `UNROLL[k:N]` is a reduce axis selected for horizontal vector expansion.
- `VEC<N>(...)` is a vectorized expression made by `codegen:add local buffers`.
- `GEP(v, n)` extracts lane `n` from vector `v`.
- `REG acc` is the register accumulator shape emitted for a reduce that stays as a loop.

## Short conclusion

For all probes here, the latest stage that still contains explicit `Ops.REDUCE` is `codegen:add local buffers`.

The first stage that is too late for a semantic reduction hook is `codegen:remove reduce`:

- Fully unrolled reductions become a horizontal tree such as `ADD(GEP(v,0), GEP(v,1), ...)` or `MAX(GEP(v,0), ...)`.
- Larger reductions become an accumulator loop with `DEFINE_REG`, initialization `STORE acc = identity`, a reduce `RANGE`, and an update `STORE acc = acc + horizontal_chunk`.

By `codegen:devectorize`, vector loads/arithmetic have been scalarized or folded. At that point the explicit reduction intent is gone; only ordinary scalar operations, loads, stores, and possibly a register accumulator remain.

## Probe 1: non-constant partial sum

Expression:

```python
from tinygrad import Tensor, dtypes
x = Tensor.empty(4, 4, dtype=dtypes.float32, device="CPU")
y = (x * 2 + 1).sum(axis=1).realize()
print(y.shape)  # (4,)
```

This keeps the source non-constant, so the lowered tree contains an input buffer load/index rather than an arange formula.

### `codegen:base ast`

Ops: `ADD:2, CONST:3, END:1, INDEX:2, MUL:2, PARAM:2, RANGE:2, REDUCE:1, SINK:1, STORE:1`

```text
SINK
  END over LOOP[i:4]
    STORE output[i]
      REDUCE ADD
        source:
          ADD
            MUL
              INDEX input[i*4 + REDUCE[r:4]]
              CONST 2.0
            CONST 1.0
        reduce range: REDUCE[r:4]
```

### `codegen:add local buffers`

Ops: `ADD:2, CONST:7, END:1, INDEX:2, MUL:2, PARAM:2, RANGE:1, REDUCE:1, SINK:1, STACK:3, STORE:1`

```text
SINK
  END over LOOP[i:4]
    STORE output[i]
      REDUCE ADD
        source:
          ADD
            MUL
              INDEX
                input pointer vector: VEC4(input, input, input, input)
                offsets: VEC4(i*4 + 0, i*4 + 1, i*4 + 2, i*4 + 3)
              VEC4(2.0)
            VEC4(1.0)
```

The reduce op is still present, but its source is now a `float.vec(4)`. This is the cleanest late semantic point for a TT tile/subtile lowering pass that wants to see both the reduction and the lane grouping.

### `codegen:remove reduce`

Ops: `ADD:5, CONST:7, END:1, GEP:4, INDEX:2, MUL:2, PARAM:2, RANGE:1, SINK:1, STACK:3, STORE:1`

```text
SINK
  END over LOOP[i:4]
    lanes =
      ADD
        MUL INDEX input[VEC4(i*4 + 0..3)], VEC4(2.0)
        VEC4(1.0)
    STORE output[i]
      ADD
        ADD
          ADD GEP(lanes, 0), GEP(lanes, 1)
          GEP(lanes, 2)
        GEP(lanes, 3)
```

`Ops.REDUCE` is gone here. Reduction intent survives only as a horizontal `ADD` tree over `GEP` lane extracts.

### `codegen:devectorize`

Ops: `ADD:4, CAST:1, CONST:3, END:1, GEP:4, INDEX:2, LOAD:1, MUL:5, PARAM:2, RANGE:1, SINK:1, STORE:1`

```text
SINK
  END over LOOP[i:4]
    v = LOAD_VEC4 input[i*4]
    STORE output[i]
      ADD
        ADD
          MUL GEP(v, 3), 2.0
          ADD
            MUL GEP(v, 2), 2.0
            ADD
              MUL GEP(v, 1), 2.0
              MUL GEP(v, 0), 2.0
        CONST 4.0
```

The four `+ 1.0` terms have folded into `+ 4.0`. This is useful renderer input, but too late for a semantic reduce hook.

## Probe 2: full-tile-ish sum

Expression:

```python
from tinygrad import Tensor, dtypes
x = Tensor.arange(1024, dtype=dtypes.float32, device="CPU").reshape(32, 32)
y = (x + 0.25).sum(axis=1).realize()
print(y.shape, y.numpy()[:3].tolist())
# (32,), [504.0, 1528.0, 2552.0]
```

This is a 32-lane row sum, shaped like a natural TT tile-width reduction.

Stage counts:

```text
codegen:base ast          REDUCE:1, RANGE:2, ADD:3, nodes:16
codegen:add local buffers REDUCE:1, RANGE:1, STACK:2, CONST:35, nodes:49
codegen:remove reduce     REDUCE:0, GEP:32, ADD:34, nodes:111
codegen:devectorize       REDUCE:0, GEP:0, CAST:32, ADD:64, nodes:136
```

Normalized lowering:

```text
base ast:
  STORE output[i]
    REDUCE ADD over REDUCE[r:32]
      CAST(i*32 + r + 1) - 1.0 + 0.25

add local buffers:
  STORE output[i]
    REDUCE ADD
      VEC32(CAST(i*32 + lane + 1) - 1.0 + 0.25)

remove reduce:
  lanes = VEC32(...)
  STORE output[i]
    ADD tree over GEP(lanes, 0)..GEP(lanes, 31)

devectorize:
  STORE output[i]
    scalar ADD tree over the 32 expanded lane expressions
```

For TT lowering, `codegen:add local buffers` is the last point that says "this vector is one reduction." `codegen:remove reduce` still exposes the 32 lanes, but the only hint is the contiguous `GEP` fan-in.

## Probe 3: max reduction

Expression:

```python
from tinygrad import Tensor, dtypes
x = Tensor.arange(16, dtype=dtypes.float32, device="CPU").reshape(4, 4)
y = (x * -1 + 7).max(axis=1).realize()
print(y.numpy().tolist())  # [7.0, 3.0, -1.0, -5.0]
```

### Key stages

```text
codegen:base ast:
  STORE output[i]
    REDUCE MAX over REDUCE[r:4]
      (CAST(i*4 + r + 1) * -1.0) + 8.0

codegen:add local buffers:
  STORE output[i]
    REDUCE MAX
      VEC4((CAST(i*4 + lane + 1) * -1.0) + 8.0)

codegen:remove reduce:
  lanes = VEC4(...)
  STORE output[i]
    MAX
      MAX
        MAX GEP(lanes, 0), GEP(lanes, 1)
        GEP(lanes, 2)
      GEP(lanes, 3)

codegen:devectorize:
  STORE output[i]
    MAX tree over four scalar lane expressions
```

Stage counts confirm the boundary:

```text
codegen:add local buffers REDUCE:1, MAX:0, GEP:0
codegen:remove reduce     REDUCE:0, MAX:3, GEP:4
codegen:devectorize       REDUCE:0, MAX:3, GEP:0
```

So max follows the same boundary as sum: explicit reduction survives through `add local buffers`, then turns into ordinary `MAX` fan-in.

## Probe 4: multi-axis reduction

Expression:

```python
from tinygrad import Tensor, dtypes
x = Tensor.arange(24, dtype=dtypes.float32, device="CPU").reshape(2, 3, 4)
y = (x + 1).sum(axis=(1, 2)).realize()
print(y.numpy().tolist())  # [78.0, 222.0]
```

### `schedule:kernel graph` and `codegen:base ast`

The scheduler collapses the two reduced dimensions into two reduce ranges attached to one `REDUCE ADD`.

```text
SINK
  END over LOOP[i:2]
    STORE output[i]
      REDUCE ADD
        source:
          CAST(i*12 + REDUCE[r0:3]*4 + REDUCE[r1:4] + 1)
        reduce ranges:
          REDUCE[r0:3]
          REDUCE[r1:4]
```

Counts at `codegen:base ast`: `RANGE:3, REDUCE:1, ADD:3, MUL:2`.

### `codegen:add local buffers`

```text
SINK
  END over LOOP[i:2]
    STORE output[i]
      REDUCE ADD
        source:
          VEC12(CAST(i*12 + lane + 1))
```

Counts: `REDUCE:1, RANGE:1, STACK:2, CONST:14`.

Both axes have been flattened into a 12-lane horizontal vector, but `Ops.REDUCE` still marks the operation.

### `codegen:remove reduce`

```text
lanes = VEC12(CAST(i*12 + lane + 1))
STORE output[i]
  ADD tree over GEP(lanes, 0)..GEP(lanes, 11)
```

Counts: `REDUCE:0, GEP:12, ADD:13`.

For TT subtile/tile lowering, this means multi-axis reduce intent is still clean at `add local buffers`; one stage later it is just a horizontal lane fan-in.

## Probe 5: `keepdim` plus reshape after reduce

Expression:

```python
from tinygrad import Tensor, dtypes
x = Tensor.arange(24, dtype=dtypes.float32, device="CPU").reshape(2, 3, 4)
y = (x + 1).sum(axis=1, keepdim=True).reshape(2, 4).realize()
print(y.shape, y.numpy().tolist())
# (2, 4), [[15.0, 18.0, 21.0, 24.0], [51.0, 54.0, 57.0, 60.0]]
```

At the tensor level, `keepdim=True` preserves a size-1 axis before the explicit reshape removes it:

```text
tensor:linear_with_vars input:
  RESHAPE [2, 4]
    REDUCE ADD axes=(1)
      ADD
        arange-shaped source [2, 3, 4]
        CONST 1.0
```

By the scheduler/codegen stages, the reshape has become output indexing. The kernel has two output loops and one reduce range:

```text
codegen:base ast:
  END over LOOP[i:2], LOOP[j:4]
    STORE output[i, j]
      REDUCE ADD over REDUCE[r:3]
        CAST(i*12 + r*4 + j + 1)

codegen:add local buffers:
  STORE output[i, j]
    REDUCE ADD
      VEC3(CAST(i*12 + lane*4 + j + 1))

codegen:remove reduce:
  lanes = VEC3(...)
  STORE output[i, j]
    ADD ADD(GEP(lanes, 0), GEP(lanes, 1)), GEP(lanes, 2)
```

Stage counts:

```text
tensor:linear_with_vars input REDUCE:2, RESHAPE:11
codegen:base ast             REDUCE:1, RANGE:3
codegen:add local buffers    REDUCE:1, RANGE:2, STACK:3
codegen:remove reduce        REDUCE:0, GEP:3, ADD:6
```

The reshape/keepdim part does not delay or preserve reduction semantics past `codegen:add local buffers`; it only changes the surviving output loop structure.

## Large reduce: accumulator form

Expression:

```python
from tinygrad import Tensor, dtypes
x = Tensor.arange(4096, dtype=dtypes.float32, device="CPU").reshape(4, 1024)
y = (x + 1).sum(axis=1).realize()
print(y.shape, y.numpy()[:2].tolist())
# (4,), [524800.0, 1573376.0]
```

This reduction is not fully flattened into a single 1024-lane horizontal tree. The optimizer chose a 4-lane unroll inside a 256-iteration reduce loop.

### `codegen:add local buffers`

```text
SINK name=r_4_256_4
  END over LOOP[i:4]
    STORE output[i]
      REDUCE ADD
        source:
          VEC4(CAST(i*1024 + REDUCE[r:256]*4 + lane + 1))
        reduce range:
          REDUCE[r:256]
```

Counts: `REDUCE:1, RANGE:2, STACK:3`.

### `codegen:remove reduce`

```text
SINK name=r_4_256_4
  END over LOOP[i:4]
    REG acc

    initialize:
      STORE acc[0] = 0.0

    END over REDUCE[r:256]
      chunk = VEC4(CAST(i*1024 + r*4 + lane + 1))
      STORE acc[0] =
        LOAD acc[0]
        + GEP(chunk, 0)
        + GEP(chunk, 1)
        + GEP(chunk, 2)
        + GEP(chunk, 3)

    STORE output[i] = LOAD acc[0]
```

Counts: `REDUCE:0, DEFINE_REG:1, STORE:3, RANGE:2, GEP:4`.

### `codegen:devectorize`

```text
SINK name=r_4_256_4
  END over LOOP[i:4]
    REG acc
    STORE acc[0] = 0.0
    END over REDUCE[r:256]
      STORE acc[0] =
        LOAD acc[0]
        + scalar lane 0
        + scalar lane 1
        + scalar lane 2
        + scalar lane 3
    STORE output[i] = LOAD acc[0]
```

Counts: `REDUCE:0, DEFINE_REG:1, LOAD:2, STORE:3, RANGE:2, GEP:0`.

This is the accumulator form to watch for if a TT lowering pass runs after `remove reduce`: the semantic `REDUCE` has already been lowered into explicit state.

## Hook guidance for TT tile/subtile lowering

- Best semantic hook: `codegen:base ast` through `codegen:postopt symbolic`.
- Latest hook that still has explicit `Ops.REDUCE`: `codegen:add local buffers`.
- Best late hook for tile lane grouping: `codegen:add local buffers`, because the reduce source is already vectorized as `VEC3`, `VEC4`, `VEC12`, `VEC32`, etc.
- First too-late stage for explicit reduce matching: `codegen:remove reduce`.
- Recovery clues after `remove reduce`: contiguous `GEP` fan-in for small/full horizontal reduces, or `DEFINE_REG`/`STORE identity`/reduce-loop update for accumulator reduces.
- Definitely too late for semantic matching: `codegen:devectorize`, `codegen:linearized list`, and `renderer:linear`.
