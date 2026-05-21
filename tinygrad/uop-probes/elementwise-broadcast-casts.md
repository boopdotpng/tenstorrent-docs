# tinygrad UOp probes: elementwise, broadcast, where, casts

Worker: 2

Scope: scalar/elementwise/broadcast/cast probes using local `TT_DUMP_STAGE`
instrumentation. All probes below were run on the host `PYTHON` device. No
Tenstorrent device queue or TT device execution was used.

## Probe setup

Run shape:

```sh
PYTHONPATH=/home/boop/tenstorrent/tinygrad \
DEVICE=PYTHON \
TT_DUMP_STAGE='tensor:linear_with_vars input,tensor:linear_with_vars,schedule:function input,schedule:scheduled linear,schedule:after memory plan,codegen:base ast,codegen:decompositions,codegen:decomp dtypes,codegen:transcendental,codegen:linearized list' \
python3 probe.py
```

Probe bodies:

```python
from tinygrad import Tensor, dtypes

a = Tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]], dtype=dtypes.float32, device="PYTHON")
b = Tensor([10.0, 20.0, 30.0], dtype=dtypes.float32, device="PYTHON")

probes = {
  "add_broadcast_mul_scalar": ((a + b) * 2.0).contiguous(),
  "where_broadcast": (a > 3.0).where(a, b).contiguous(),
  "transcendentals": (a.exp() + a.log() + a.sqrt() + a.sin()).contiguous(),
  "casts": a.cast(dtypes.float16).cast(dtypes.bfloat16).cast(dtypes.float32).cast(dtypes.int32).contiguous(),
}

for name, out in probes.items():
  print(name, out.shape, out.dtype)
  out.realize()
```

The normalized trees below intentionally omit `DEVICE`, `UNIQUE`, `STACK`,
`CONST(shape)`, and raw `UOp(...)` object syntax unless they carry probe intent.

## Stage map

The useful local stages for these probes were:

| Stage | What it still says |
| --- | --- |
| `tensor:linear_with_vars input` | User-facing lazy tensor intent. Shape ops such as `RESHAPE`, `EXPAND`, `CONTIGUOUS`, and dtype `CAST` chains are still explicit. |
| `tensor:linear_with_vars` | Same expression wrapped as a call: input/output buffers become `PARAM`s, and output appears as `AFTER(STORE(...))`. |
| `schedule:function input` | Callified tensor graph, before kernel scheduling. Broadcast intent is still explicit as `EXPAND`. |
| `schedule:scheduled linear` | One scheduled elementwise kernel. `EXPAND` and `RESHAPE` are gone; loops, indexes, and pointer params have replaced them. |
| `codegen:base ast` | Kernel AST with ranges and scalar expression. This is the last compact place to see the elementwise formula before load/store lowering. |
| `codegen:decompositions` and later | Memory ops become explicit `LOAD`/`STORE`; loop indexes become `SPECIAL`/`MULACC`; dtype and transcendental rewrites may fire depending on renderer support. |
| `codegen:linearized list` | Final flat UOp list for rendering. Intent is mostly operational: params, indexes, loads, scalar ALU, stores. |

## Probe: add, broadcast, scalar multiply

Expression:

```python
((a + b) * 2.0).contiguous()
```

with `a: float32[2,3]` and `b: float32[3]`.

Tensor-stage tree:

```text
CONTIGUOUS float[2,3]
  MUL float[2,3]
    ADD float[2,3]
      RESHAPE a_buffer[6] -> [2,3]
      EXPAND [1,3] -> [2,3]
        RESHAPE b_buffer[3] -> [1,3]
    EXPAND scalar -> [2,3]
      RESHAPE CONST(2.0) -> []
```

Scheduled/codegen tree:

```text
for i in 0..2:
  for j in 0..3:
    out[i*3 + j] =
      (load a[i*3 + j] + load b[j]) * 2.0
```

Observed evolution:

- `EXPAND` is present while the graph is tensor-shaped.
- The broadcast axis disappears at scheduling. The only remaining evidence is
  that `b` is indexed by `j`, not by `i*3+j`.
- Scalar broadcast disappears completely. `2.0` becomes a plain scalar constant
  in the kernel expression.
- By `codegen:decompositions`, pointer arithmetic has become `MULACC(i, 3, j)`,
  and the formula is surrounded by `LOAD` and `STORE`.

Where intent disappears: the phrase "broadcast `[3]` across rows" is gone after
`schedule:scheduled linear`; only the chosen address expression remains.

## Probe: where with broadcast

Expression:

```python
(a > 3.0).where(a, b).contiguous()
```

Tensor-stage tree:

```text
CONTIGUOUS float[2,3]
  WHERE float[2,3]
    CMPLT bool[2,3]
      EXPAND scalar -> [2,3]
        CONST(3.0)
      RESHAPE a_buffer[6] -> [2,3]
    RESHAPE a_buffer[6] -> [2,3]
    EXPAND [1,3] -> [2,3]
      RESHAPE b_buffer[3] -> [1,3]
```

Scheduled/codegen tree:

```text
for i in 0..2:
  for j in 0..3:
    x = load a[i*3 + j]
    out[i*3 + j] = where(3.0 < x, x, load b[j])
```

Observed evolution:

- The comparison is normalized as `CMPLT(3.0, a)`, not as a distinct `GT`.
- `where` keeps three data-flow inputs at tensor and scheduled stages:
  condition, true value, false value.
- Broadcast treatment matches add: `b[3]` becomes `b[j]`; scalar `3.0`
  becomes an immediate.

Where intent disappears: the conditional select survives as `WHERE`, but the
fact that the false arm came from a rank-1 broadcast is gone once indexes are
formed.

## Probe: exp, log, sqrt, sin

Expression:

```python
(a.exp() + a.log() + a.sqrt() + a.sin()).contiguous()
```

Tensor-stage tree:

```text
CONTIGUOUS float[2,3]
  ADD
    ADD
      ADD
        EXP2
          MUL
            a
            CONST(log2(e))
        MUL
          LOG2 a
          CONST(ln(2))
      SQRT a
    SIN a
```

Scheduled/codegen tree:

```text
for i in 0..2:
  for j in 0..3:
    x = load a[i*3 + j]
    out[i*3 + j] =
      exp2(x * 1.4426950408889634) +
      log2(x) * 0.6931471805599453 +
      sqrt(x) +
      sin(x)
```

Observed evolution:

- `Tensor.exp()` is already represented as `EXP2(x * log2(e))` before
  scheduling.
- `Tensor.log()` is already represented as `LOG2(x) * ln(2)` before scheduling.
- `SQRT` and `SIN` were available in this checkout and stayed as direct UOps on
  the `PYTHON` host renderer.
- The `codegen:transcendental` stage did not further expand these for the host
  renderer in this run. Other renderers may lower unsupported transcendental ops
  into polynomial or bit-level sequences later.

Where intent disappears: the original API names `exp` and `log` disappear before
the first tensor dump. The graph records base-2 primitives plus constants, so a
later consumer cannot distinguish "user asked for natural exp/log" from "user
manually wrote the equivalent base-2 form."

## Probe: fp32, fp16, bf16, int casts

Expression:

```python
a.cast(dtypes.float16).cast(dtypes.bfloat16).cast(dtypes.float32).cast(dtypes.int32).contiguous()
```

Tensor-stage tree:

```text
CONTIGUOUS int32[2,3]
  CAST int32
    CAST float32
      CAST bfloat16
        CAST float16
          RESHAPE a_buffer[6] -> [2,3]
```

Scheduled/codegen tree:

```text
for i in 0..2:
  for j in 0..3:
    x = load a[i*3 + j]             # fp32
    out[i*3 + j] = cast_int32(cast_bfloat16(cast_float16(x)))
```

Observed evolution:

- `float32 -> float16 -> bfloat16 -> float32 -> int32` was feasible to build at
  the tensor level.
- Scheduling/codegen removed the explicit cast back to `float32`; the sink only
  needed the final `int32`, and the source load was already `float32`.
- The remaining dtype intent survived through `codegen:linearized list` as
  nested `CAST half`, `CAST bfloat16`, and `CAST int`.

Where intent disappears: redundant or representation-neutral cast steps can be
folded before codegen. If the probe cares about a specific intermediate cast,
inspect `tensor:linear_with_vars input`; later stages may only preserve casts
that affect the final stored value for the target renderer.

## Cross-probe notes

- `CONTIGUOUS` is a tensor-level request to materialize. It does not remain as a
  scalar operation; it becomes an output buffer plus `STORE`.
- `RESHAPE` and `EXPAND` carry high-level shape intent. They are schedule-time
  conveniences, not late codegen operations for these elementwise kernels.
- Elementwise `ADD`, `MUL`, `WHERE`, `CMPLT`, and surviving `CAST` UOps remain
  recognizable longer than movement ops.
- Broadcast legality is resolved before kernel codegen. Late stages know address
  formulas, not broadcast semantics.
- In linearized code, the best human reading is usually:
  params -> loop/special indexes -> `LOAD`s -> scalar ALU/casts -> `STORE`.

## Minimal normalized summary

```text
add/mul broadcast:
  tensor:     MUL(ADD(a, EXPAND(b[3] -> [2,3])), EXPAND(2.0))
  scheduled:  store out[i,j] = (a[i,j] + b[j]) * 2.0

where broadcast:
  tensor:     WHERE(CMPLT(3.0, a), a, EXPAND(b[3] -> [2,3]))
  scheduled:  store out[i,j] = where(3.0 < a[i,j], a[i,j], b[j])

transcendentals:
  tensor:     ADD(ADD(ADD(EXP2(a*log2(e)), LOG2(a)*ln(2)), SQRT(a)), SIN(a))
  scheduled:  same scalar formula under loads/stores

casts:
  tensor:     CAST.int(CAST.float(CAST.bfloat16(CAST.float16(a))))
  scheduled:  CAST.int(CAST.bfloat16(CAST.float16(load a)))
```
