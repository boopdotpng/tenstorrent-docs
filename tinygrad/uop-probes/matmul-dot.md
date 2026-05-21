# tinygrad UOp probes: dot and matmul

Date: 2026-05-21

Scope: local tinygrad host/GPU probes only. No Tenstorrent device work and no TT device queue were used. The probes below used the local `TT_DUMP_STAGE` / `TT_DUMP_LOWERING` instrumentation in the working tree under `/home/boop/tenstorrent/tinygrad`.

Local backend discovery:

```bash
DEV=AMD python3 - <<'PY'
from tinygrad import Device
print(Device.DEFAULT)
for i,tc in enumerate(Device[Device.DEFAULT].renderer.tensor_cores):
  print(i, tc)
PY
```

Observed backend: `AMD::gfx1200`, with tensor core descriptors:

```text
0 WMMA_16_16_16_half_float
1 WMMA_16_16_16_half_half
2 WMMA_16_16_16___bf16_float
3 WMMA_16_16_16___bf16___bf16
```

## How The Dumps Were Taken

The useful local command pattern was:

```bash
TT_DUMP_STAGE=schedule TT_DUMP_LOWERING=1 DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes
r = Tensor.empty(8,8,dtype=dtypes.float32).matmul(Tensor.empty(8,8,dtype=dtypes.float32))
r.schedule_linear()
PY
```

`TT_DUMP_LOWERING=1` keeps the instrumentation readable: it prints stage names and op counts, while avoiding raw UOp object trees in the notes. I used separate inspection code to turn the scheduled forms into the normalized trees below.

Important stages:

```text
schedule:function input       tensor expression form; matmul is REDUCE(ADD) of MUL
schedule:kernel graph         rangeified/bufferized kernel graph; RANGE appears here
schedule:after resolve linear CALL-only launch list; semantic tree is inside the CALL target
codegen/to_program            final program UOps; scalar path loses REDUCE, TC path gains WMMA
```

## Probe Summary

| Probe | Shape | Input dtype | TC setting | Scheduled kernel markers | Program markers |
| --- | ---: | --- | --- | --- | --- |
| vector dot | `(8,) . (8,) -> ()` | `float32` | `TC=0` | `REDUCE`, `RANGE` | no `WMMA`, no `CONTRACT` |
| small matmul | `(8,8) @ (8,8) -> (8,8)` | `float32` | `TC=0` | `REDUCE`, 3 `RANGE` | no `WMMA`, no `CONTRACT` |
| batched matmul | `(2,4,8) @ (2,8,5) -> (2,4,5)` | `float32` | `TC=0` | `REDUCE`, 4 `RANGE` | no `WMMA`, no `CONTRACT` |
| matmul + bias + relu | `(8,8) @ (8,8) + (8,) -> relu` | `float32` | `TC=0` | `REDUCE`, `WHERE`, `CMPLT`, 3 `RANGE` | fused scalar code, no `WMMA` |
| GPU non-TC matmul | `(16,16) @ (16,16)` | `float32` | `TC=0` | `REDUCE`, 3 `RANGE` | local/shared scalar loop, no `WMMA` |
| GPU TC matmul | `(16,16) @ (16,16)` | `half -> float32` | `TC=1` | `REDUCE`, 3 `RANGE` | `WMMA:1`, `GROUP:1`, AMD `__builtin_amdgcn_wmma` |

## Normalized Trees

These are normalized, human-readable trees. They intentionally omit raw UOp ids, Python object syntax, and incidental buffer numbering.

### Vector Dot

Command:

```bash
TT_DUMP_STAGE=schedule TT_DUMP_LOWERING=1 DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes
(Tensor.empty(8,dtype=dtypes.float32) * Tensor.empty(8,dtype=dtypes.float32)).sum().schedule_linear()
PY
```

Normalized scheduled form:

```text
STORE out[]
  REDUCE ADD over k in 0..7
    MUL
      LOAD a[k]
      LOAD b[k]
```

Observed counts:

```text
function input: CONST:2, MUL:1, PARAM:3, REDUCE:1, STORE:1
kernel graph:  INDEX:3, MUL:1, RANGE:1, REDUCE:1, STORE:1
program:       LOAD:4, MUL:8, ADD:7, STORE:1, WMMA:0
```

Takeaway: dot is the minimal matmul pattern. It is a single `REDUCE(ADD)` over a multiply. `RANGE` appears after rangeify. `WMMA` and `CONTRACT` do not appear on this scalar path.

### Small Matmul

Command:

```bash
TT_DUMP_STAGE=schedule TT_DUMP_LOWERING=1 DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes
Tensor.empty(8,8,dtype=dtypes.float32).matmul(Tensor.empty(8,8,dtype=dtypes.float32)).schedule_linear()
PY
```

Normalized scheduled form:

```text
STORE out[m, n]
  RANGE m in 0..7
  RANGE n in 0..7
  REDUCE ADD over k in 0..7
    MUL
      LOAD a[m, k]
      LOAD b[k, n]
```

Observed counts:

```text
function input: EXPAND:2, MUL:1, PERMUTE:1, REDUCE:1, RESHAPE:5
kernel graph:  INDEX:3, MUL:3, RANGE:3, REDUCE:1, STORE:1
program TC=0:  LOAD:10, MUL:8, ADD:16, STORE:1, WMMA:0
```

Takeaway: tinygrad represents matmul first as broadcasted/reshaped multiply plus reduction. After rangeify, the important semantic signature is still `RANGE(m,n,k) + REDUCE(ADD) + MUL`.

### Batched Matmul

Command:

```bash
TT_DUMP_STAGE=schedule TT_DUMP_LOWERING=1 DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes
Tensor.empty(2,4,8,dtype=dtypes.float32).matmul(Tensor.empty(2,8,5,dtype=dtypes.float32)).schedule_linear()
PY
```

Normalized scheduled form:

```text
STORE out[batch, m, n]
  RANGE batch in 0..1
  RANGE m in 0..3
  RANGE n in 0..4
  REDUCE ADD over k in 0..7
    MUL
      LOAD a[batch, m, k]
      LOAD b[batch, k, n]
```

Observed counts:

```text
function input: EXPAND:2, MUL:1, PERMUTE:1, REDUCE:1, RESHAPE:5
kernel graph:  ADD:6, INDEX:3, MUL:7, RANGE:4, REDUCE:1, STORE:1
program TC=0:  LOAD:10, MUL:11, ADD:19, STORE:1, WMMA:0
```

Takeaway: batch is just another non-reduction `RANGE`. The matmul recognizer should not assume exactly two output ranges; it should find one reduction axis and treat the remaining ranges as output/batch tiling dimensions.

### Matmul + Bias + ReLU

Command:

```bash
TT_DUMP_STAGE=schedule TT_DUMP_LOWERING=1 DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes
a = Tensor.empty(8,8,dtype=dtypes.float32)
b = Tensor.empty(8,8,dtype=dtypes.float32)
bias = Tensor.empty(8,dtype=dtypes.float32)
(a.matmul(b) + bias).relu().schedule_linear()
PY
```

Normalized scheduled form:

```text
STORE out[m, n]
  WHERE matmul_plus_bias > 0
    ADD
      REDUCE ADD over k in 0..7
        MUL
          LOAD a[m, k]
          LOAD b[k, n]
      LOAD bias[n]
    CONST 0
```

Observed counts:

```text
function input: ADD:1, CMPLT:1, EXPAND:4, MUL:1, REDUCE:1, WHERE:1
kernel graph:  ADD:4, CMPLT:1, INDEX:4, MUL:3, RANGE:3, REDUCE:1, WHERE:1
program TC=0:  LOAD:11, MUL:8, ADD:17, CMPLT:1, WHERE:1, STORE:1, WMMA:0
```

Takeaway: bias and activation fuse around the reduction. For a TT tile matmul path, the clean split is "tile matmul produces accumulator tile", then epilogue applies bias and activation before packing/storing.

## GPU Matmul Comparison

### Non-Tensor-Core GPU Matmul

Command:

```bash
DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes, Device
from tinygrad.codegen import to_program
from tinygrad.uop.ops import Ops
from collections import Counter
r = Tensor.empty(16,16,dtype=dtypes.float32).matmul(Tensor.empty(16,16,dtype=dtypes.float32))
ast = r.schedule_linear().src[-1].src[0]
prg = to_program(ast, Device[Device.DEFAULT].renderer)
print(Counter(u.op.name for u in prg.src[2].src))
print(any(u.op is Ops.WMMA for u in prg.src[2].src))
PY
```

Observed:

```text
WMMA present: False
program markers: DEFINE_LOCAL, DEFINE_REG, BARRIER, RANGE, LOAD, MUL, STORE
```

This is still AMD GPU codegen, but `TC=0` and `float32` keep it off tensor cores. The final program is a local/shared scalar matmul loop. By codegen time `REDUCE` has been lowered away into explicit loads, arithmetic, barriers, and stores.

Execution smoke:

```bash
DEV=AMD TC=0 python3 - <<'PY'
from tinygrad import Tensor, dtypes
A=Tensor([[1,2],[3,4]], dtype=dtypes.float32, device='AMD')
B=Tensor([[5,6],[7,8]], dtype=dtypes.float32, device='AMD')
print((A@B).numpy().tolist())
PY
```

Output:

```text
[[19.0, 22.0], [43.0, 50.0]]
```

### Tensor-Core GPU Matmul

Command:

```bash
DEV=AMD TC=1 python3 - <<'PY'
from tinygrad import Tensor, dtypes, Device
from tinygrad.codegen import to_program
from tinygrad.uop.ops import Ops
from collections import Counter
r = Tensor.empty(16,16,dtype=dtypes.half).matmul(Tensor.empty(16,16,dtype=dtypes.half), dtype=dtypes.float32)
ast = r.schedule_linear().src[-1].src[0]
prg = to_program(ast, Device[Device.DEFAULT].renderer)
print(Counter(u.op.name for u in prg.src[2].src))
print(any(u.op is Ops.WMMA for u in prg.src[2].src))
print('__builtin_amdgcn_wmma' in prg.src[3].arg)
PY
```

Observed:

```text
WMMA present: True
program counts include: WMMA:1, GROUP:1, STACK:3
code marker: #define __WMMA_16_16_16_half_float __builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12
```

Execution smoke:

```bash
DEV=AMD TC=1 python3 - <<'PY'
from tinygrad import Tensor, dtypes
A=Tensor.ones(16,16, dtype=dtypes.half, device='AMD').realize()
B=Tensor.ones(16,16, dtype=dtypes.half, device='AMD').realize()
print(float((A.matmul(B, dtype=dtypes.float32)).numpy()[0,0]))
PY
```

Output:

```text
16.0
```

Difference from non-TC path: the scheduled kernel graph is still recognizably `REDUCE(ADD)` over `MUL`, but `to_program` rewrites the eligible half-precision 16x16x16 pattern into `WMMA`. The scalar `TC=0` path keeps explicit local memory, barriers, loads, multiply/adds, and stores. The TC path uses vector packing/unpacking around a single `WMMA` op and emits the AMD WMMA builtin.

## Operator Appearance

`REDUCE`: appears in all scheduled matmul/dot kernel graphs. It is the main high-level matmul signature before backend codegen.

`RANGE`: appears after `schedule:kernel graph` / rangeify. Vector dot has one range, 2-D matmul has three, batched matmul has four.

`WMMA`: does not appear in tensor/function input or the rangeified scheduled graph. It appears during `to_program` for eligible TC matmul.

`CONTRACT`: not observed in these ordinary scheduled dumps. In this tinygrad tree, `CONTRACT` is used by the WMMA lowering machinery around `SHAPED_WMMA`/`WMMA`, but these probes showed the final codegen-side `WMMA` marker rather than a stable user-visible `CONTRACT` in the printed scheduled graph.

## Latest Useful Hook Point For TT Tile Matmul Lowering

The latest useful hook is before backend scalar codegen, while the kernel still contains:

```text
RANGE output axes
REDUCE ADD over k
MUL of two indexed loads
optional epilogue ADD/WHERE/CMPLT
```

In this tree, that means around `tinygrad/schedule/rangeify.py:get_kernel_graph`, after `run_rangeify` and the symbolic/reduce cleanup have exposed concrete `RANGE` axes, but before the final `to_program` backend lowering turns non-TC matmul into scalar loops or TC matmul into `WMMA`.

Practically:

```text
too early:  schedule:function input
  Matmul is still wrapped in reshape/expand/permute broadcast structure.

best:       rangeified kernel graph before codegen
  Matmul has explicit output ranges, reduction range, indexed loads, and fused epilogue.

too late:   program UOps / rendered source
  Non-TC path has lost REDUCE; TC path has already become WMMA.
```

For TT tile matmul lowering, match the rangeified `STORE(out) <- epilogue(REDUCE(ADD, MUL(load A, load B)))`, form tile/block metadata from output ranges plus reduction range, lower the core reduction to a TT tile matmul op, then keep bias/activation as an epilogue on the accumulator tile.
