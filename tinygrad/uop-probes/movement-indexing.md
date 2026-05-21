# tinygrad UOp movement/indexing probes

Date: 2026-05-21

Host-only probe run:

```bash
PYTHONPATH=/home/boop/tenstorrent/tinygrad \
DEFAULT_DEVICE=PYTHON DEVICE=PYTHON \
TT_DUMP_STAGE='tensor:linear_with_vars input,schedule:kernel graph,codegen:base ast,codegen:early movement ops,codegen:load collapse,codegen:postopt symbolic,codegen:expander,codegen:add local buffers,codegen:remove reduce,codegen:add loads,codegen:devectorize,codegen:lower index dtypes,codegen:move gates from index,codegen:final rewrite,codegen:linearized list,renderer:linear' \
TT_DUMP_LOWERING=2 \
python3 probe.py
```

No Tenstorrent device command was used. The probes used `PYTHON` buffers so lowering and rendering stayed on the host.

This document rewrites the raw `UOp(...)` dumps into normalized trees. It keeps the useful stage boundaries, removes Python repr noise, object aliases, and repeated source spelling, and focuses on the index expressions that survive into codegen.

Notation:

- `OUT[i]` means an `INDEX` into the output parameter.
- `IN[i]` means an `INDEX` into an input parameter.
- `R0`, `R1`, `R2` are loop, local, global, upcast, or reduce ranges as named in each tree.
- `VALID ? a : Invalid` means a gated index. It normally becomes a guarded load/store or a zero-fill path later.
- `vecN(...)` means a vector value created by `STACK`, lane extraction, or vector load/store lowering.

## Short conclusion

For pure movement ops, high-level `RESHAPE`, `SHRINK`, `PAD`, `PERMUTE`, and `EXPAND` are visible only before rangeify: `tensor:linear_with_vars input`, `schedule:function input`, and `schedule:ttir input`. By `schedule:kernel graph` and `codegen:base ast`, the movement ops have become affine index maps, gated indexes, and sometimes reductions.

The most practical TT backend hook points are therefore split by intent:

- If TT wants semantic movement ops, hook before or at `schedule:function input` / `schedule:ttir input`.
- If TT wants ready-to-lower elementwise kernels, hook at `schedule:kernel graph` or `codegen:base ast`.
- If TT wants optimized loop partitioning while retaining readable index math, `codegen:postopt symbolic` is the latest broadly useful point.
- If TT wants explicit host-renderer-style loads and stores, `codegen:add loads` through `codegen:final rewrite` is viable, but movement identity is mostly gone.
- `renderer:linear` is too late for semantic movement/indexing decisions. It is useful for validating exact emitted UOps only.

Important per-op exceptions:

- Advanced indexing/gather is still recognizable at `codegen:base ast` as a reduction over candidate source rows. `codegen:load collapse` is the key rewrite that converts it into a gated direct index. That makes `load collapse` / `postopt symbolic` the latest useful gather hook.
- Pad is easiest to understand at `codegen:base ast` or `postopt symbolic`, where the valid region and `Invalid` source index are still explicit. Later vectorization can split it into several constant-zero stores and partial vector loads.
- Pure reshape did not schedule a kernel in this probe because it remained a view. A backend looking for reshape semantics must inspect pre-schedule tensor graphs or observe reshape only when another op forces materialization.

## Probes

### Slice

Expression:

```python
Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float)[1:3, 2:5].contiguous().realize()
```

`tensor:linear_with_vars input`

Ops: `BUFFER:1, CONST:6, CONTIGUOUS:1, DEVICE:1, RESHAPE:1, SHRINK:1, SINK:1, STACK:3, UNIQUE:1`

```text
SINK
  CONTIGUOUS
    SHRINK low=(1,2) high=(3,5)
      RESHAPE (4,6)
        BUFFER float[24] on PYTHON
```

`codegen:base ast`

Ops: `ADD:3, CONST:4, END:1, INDEX:2, MUL:2, PARAM:2, RANGE:2, SINK:1, STORE:1`

```text
SINK kernel test
  STORE over R0 in [0,2), R1 in [0,3)
    OUT[R0*3 + R1] =
      IN[(R0*6 + R1) + 8]

where:
  8 = 1*6 + 2
```

`codegen:postopt symbolic`

```text
SINK kernel E_2_3
  STORE over local R0 in [0,2), local R1 in [0,3)
    OUT[R0*3 + R1] =
      IN[(R0*6 + R1) + 8]
```

`codegen:add loads` and later

```text
STORE
  dest: OUT[lidx0*3 + lidx1]
  value: LOAD IN[lidx0*6 + lidx1 + 8]
```

Slice conclusion: simple rectangular slice is already an affine input offset at `schedule:kernel graph`. The original `SHRINK` op is gone by codegen, but the base offset and output shape are easy to recover from `base ast`.

### Strided slice

Expression:

```python
Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float)[:, ::2].contiguous().realize()
```

`tensor:linear_with_vars input`

Ops: `BUFFER:1, CONST:7, CONTIGUOUS:1, DEVICE:1, PAD:1, RESHAPE:3, SHRINK:1, SINK:1, STACK:4, UNIQUE:1`

```text
SINK
  CONTIGUOUS
    RESHAPE/SHRINK/PAD/RESHAPE view chain
      BUFFER float[24] on PYTHON
```

The tensor graph encodes the stride using a movement chain rather than a standalone `STRIDE` op.

`codegen:base ast`

Ops: `ADD:2, CONST:4, END:1, INDEX:2, MUL:3, PARAM:2, RANGE:2, SINK:1, STORE:1`

```text
SINK kernel test
  STORE over R0 in [0,4), R1 in [0,3)
    OUT[R0*3 + R1] =
      IN[R0*6 + R1*2]
```

`codegen:postopt symbolic`

```text
SINK kernel E_3_4
  STORE over local R0 in [0,3), upcast R1 lanes [0,4)
    OUT[R0*4 + R1] =
      IN[R0*8 + R1*2]
```

This stage has changed the loop layout for optimization, so it no longer mirrors the logical `(4,3)` iteration directly.

`codegen:final rewrite`

```text
STORE vec4
  dest: OUT[lidx0 << 2]
  value:
    vec4(
      LOAD IN[lidx0 << 3],
      LOAD IN[lidx0*8 + 2],
      LOAD IN[lidx0*8 + 4],
      LOAD IN[lidx0*8 + 6],
    )
```

Strided-slice conclusion: the stride survives as an input-index multiplier at `base ast`. After upcasting, it becomes lane-specific load offsets.

### Gather / advanced row indexing

Expression:

```python
x = Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float)
idx = Tensor([2, 0, 3], device="PYTHON", dtype=dtypes.int)
x[idx].contiguous().realize()
```

`tensor:linear_with_vars input`

Ops: `ADD:2, BUFFER:2, CMPLT:1, CMPNE:2, CONST:19, CONTIGUOUS:1, DEVICE:1, EXPAND:11, PAD:1, PERMUTE:1, REDUCE:2, RESHAPE:18, SHRINK:2, SINK:1, STACK:11, UNIQUE:3, WHERE:2`

The high-level tensor graph is much noisier than simple slicing. Advanced indexing is represented by broadcast/expand/where/reduce machinery before rangeify.

`codegen:base ast`

Ops: `ADD:3, CAST:1, CMPLT:1, CMPNE:1, CONST:6, END:1, INDEX:3, MUL:2, PARAM:3, RANGE:3, REDUCE:1, SINK:1, STORE:1, WHERE:2`

```text
SINK kernel test
  STORE over output row O in [0,3), col C in [0,6)
    OUT[O*6 + C] =
      REDUCE_ADD over candidate source row S in [0,4)
        WHERE normalized_idx(idx[O]) != S
          then 0.0
          else IN[S*6 + C]

where:
  normalized_idx(i) = i < 0 ? i + 4 : i
```

`codegen:load collapse`

Ops: `ADD:3, AND:1, CAST:1, CMPLT:3, CMPNE:1, CONST:9, END:1, INDEX:3, MUL:2, PARAM:3, RANGE:2, SINK:1, STORE:1, WHERE:3`

```text
SINK kernel test
  STORE over O in [0,3), C in [0,6)
    OUT[O*6 + C] =
      WHERE valid_idx
        then IN[valid_idx ? normalized_idx(idx[O])*6 + C : Invalid]
        else 0.0

where:
  valid_idx = normalized_idx(idx[O]) >= 0 and normalized_idx(idx[O]) < 4
```

`codegen:postopt symbolic`

```text
SINK kernel E_2_3_3
  STORE over global/local/upcast output partition
    OUT[output_offset] =
      IN[
        valid_idx
          ? output_col + normalized_idx(idx[output_row])*6
          : Invalid
      ]
```

`codegen:final rewrite`

The final form is no longer a compact gather expression. It is three vector/scalar stores with repeated index loads, validity predicates, and `WHERE` values.

```text
GROUP
  STORE lane/group 0:
    OUT[...] = WHERE valid(idx[...]) ? LOAD IN[...] : 0
  STORE lane/group 1:
    OUT[...] = WHERE valid(idx[...]) ? LOAD IN[...] : 0
  STORE lane/group 2:
    OUT[...] = WHERE valid(idx[...]) ? LOAD IN[...] : 0
```

Gather conclusion: the best semantic hook is `codegen:base ast`; the most compact executable hook is immediately after `codegen:load collapse`. After vectorization, gather is still correct but much harder to identify.

### Pad

Expression:

```python
Tensor.empty((2, 3), device="PYTHON", dtype=dtypes.float).pad(((1, 1), (2, 0))).contiguous().realize()
```

Output shape is `(4,5)`.

`tensor:linear_with_vars input`

Ops: `BUFFER:1, CONST:4, CONTIGUOUS:1, DEVICE:1, PAD:1, RESHAPE:1, SINK:1, STACK:3, UNIQUE:1`

```text
SINK
  CONTIGUOUS
    PAD low=(1,2) high=(1,0)
      RESHAPE (2,3)
        BUFFER float[6] on PYTHON
```

`codegen:base ast`

Ops: `ADD:3, AND:3, CMPLT:3, CMPNE:2, CONST:9, END:1, INDEX:2, MUL:2, PARAM:2, RANGE:2, SINK:1, STORE:1, WHERE:2`

```text
SINK kernel test
  STORE over R0 in [0,4), R1 in [0,5)
    OUT[R0*5 + R1] =
      WHERE inside_pad_region
        then IN[
          inside_pad_region
            ? (R0*3 + R1 - 5)
            : Invalid
        ]
        else 0.0

where:
  inside_pad_region = (1 <= R0 < 3) and (R1 >= 2)
  input offset       = (R0 - 1)*3 + (R1 - 2)
                     = R0*3 + R1 - 5
```

`codegen:postopt symbolic`

```text
SINK kernel E_5_4
  STORE over upcast R0 in [0,4), upcast R1 in [0,5)
    OUT[R0*5 + R1] =
      IN[
        inside_pad_region
          ? R0*3 + R1 - 5
          : Invalid
      ]
```

`codegen:final rewrite`

Vectorization specializes the mostly-zero output:

```text
GROUP
  STORE OUT[0:4]   = vec4(0, 0, 0, 0)
  STORE OUT[4:8]   = vec4(0, 0, 0, IN[0])
  STORE OUT[8:12]  = vec4(IN[1], IN[2], 0, 0)
  STORE OUT[12:16] = vec4(IN[3], IN[4], IN[5], 0)
  STORE OUT[16:20] = vec4(0, 0, 0, 0)
```

Pad conclusion: `base ast` and `postopt symbolic` show the useful region predicate. `final rewrite` can be efficient but has lost the original pad rectangle.

### Reshape

Expression:

```python
Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float).reshape(2, 12).contiguous().realize()
```

Observed result: no `TT_DUMP_STAGE` lowering sections were emitted for this probe. In this configuration, reshape remained a view and did not schedule a copy kernel.

Reshape conclusion: a TT backend cannot rely on codegen stages to observe pure reshape. It must either inspect tensor graphs before scheduling or handle reshape as metadata attached to producer/consumer buffers.

### Permute

Expression:

```python
Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float).permute(1, 0).contiguous().realize()
```

`tensor:linear_with_vars input`

Ops: `BUFFER:1, CONST:2, CONTIGUOUS:1, DEVICE:1, PERMUTE:1, RESHAPE:1, SINK:1, STACK:1, UNIQUE:1`

```text
SINK
  CONTIGUOUS
    PERMUTE order=(1,0)
      RESHAPE (4,6)
        BUFFER float[24] on PYTHON
```

`codegen:base ast`

Ops: `ADD:2, CONST:2, END:1, INDEX:2, MUL:2, PARAM:2, RANGE:2, SINK:1, STORE:1`

```text
SINK kernel test
  STORE over R0 in [0,6), R1 in [0,4)
    OUT[R0*4 + R1] =
      IN[R1*6 + R0]
```

`codegen:postopt symbolic`

```text
SINK kernel E_2_3_4
  STORE over optimized output partition
    OUT[global*12 + local*4 + lane] =
      IN[global*3 + local + lane*6]
```

`codegen:final rewrite`

```text
STORE vec4
  dest: OUT[base]
  value:
    vec4(
      LOAD IN[row_base + 0*6],
      LOAD IN[row_base + 1*6],
      LOAD IN[row_base + 2*6],
      LOAD IN[row_base + 3*6],
    )
```

Permute conclusion: `base ast` is the cleanest hook. It expresses transpose as swapped stride math. Later stages turn that into lane-wise strided loads.

### Expand

Expression:

```python
Tensor.empty((4, 1), device="PYTHON", dtype=dtypes.float).expand(4, 6).contiguous().realize()
```

`tensor:linear_with_vars input`

Ops: `BUFFER:1, CONST:3, CONTIGUOUS:1, DEVICE:1, EXPAND:1, RESHAPE:1, SINK:1, STACK:2, UNIQUE:1`

```text
SINK
  CONTIGUOUS
    EXPAND to (4,6)
      RESHAPE (4,1)
        BUFFER float[4] on PYTHON
```

`codegen:base ast`

Ops: `ADD:1, CONST:2, END:1, INDEX:2, MUL:1, PARAM:2, RANGE:2, SINK:1, STORE:1`

```text
SINK kernel test
  STORE over R0 in [0,4), R1 in [0,6)
    OUT[R0*6 + R1] =
      IN[R0]
```

`codegen:postopt symbolic`

```text
SINK kernel E_2_4_3
  STORE over optimized output partition
    OUT[global*3 + local + row_lane*6] =
      IN[row_lane]
```

`codegen:add loads`

```text
STORE
  dest: OUT[... includes row and expanded-column lanes ...]
  value: LOAD IN[row]
```

Expand conclusion: broadcasted dimensions disappear from the input index. That zero-stride behavior is visible as the absence of `R1` from `IN[...]` at `base ast`.

### Where / mask

Expression:

```python
mask_src = Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float)
x = Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float)
y = Tensor.empty((4, 6), device="PYTHON", dtype=dtypes.float)
(mask_src > 0).where(x, y).contiguous().realize()
```

`tensor:linear_with_vars input`

Ops: `BUFFER:3, CMPLT:1, CONST:4, CONTIGUOUS:1, DEVICE:1, EXPAND:1, RESHAPE:4, SINK:1, STACK:1, UNIQUE:3, WHERE:1`

```text
SINK
  CONTIGUOUS
    WHERE
      condition: 0 < mask_src
      true: x
      false: y
```

`codegen:base ast`

Ops: `ADD:1, CMPLT:1, CONST:3, END:1, INDEX:4, MUL:1, PARAM:4, RANGE:2, SINK:1, STORE:1, WHERE:1`

```text
SINK kernel test
  STORE over R0 in [0,4), R1 in [0,6)
    OUT[I] =
      WHERE 0.0 < MASK[I]
        then X[I]
        else Y[I]

where:
  I = R0*6 + R1
```

`codegen:postopt symbolic`

```text
SINK kernel E_2_3_4n1
  STORE over optimized output partition
    OUT[I] =
      WHERE 0.0 < MASK[I]
        then X[I]
        else Y[I]
```

`codegen:final rewrite`

```text
STORE vec4
  dest: OUT[base]
  value:
    vec4(
      WHERE 0.0 < lane0(MASK[base]) ? lane0(X[base]) : lane0(Y[base]),
      WHERE 0.0 < lane1(MASK[base]) ? lane1(X[base]) : lane1(Y[base]),
      WHERE 0.0 < lane2(MASK[base]) ? lane2(X[base]) : lane2(Y[base]),
      WHERE 0.0 < lane3(MASK[base]) ? lane3(X[base]) : lane3(Y[base]),
    )
```

Where conclusion: normal elementwise `WHERE` survives all the way to final rewrite, but vectorization scalarizes it per lane. This is different from pad/gather, where `WHERE` often participates in gated indexes using `Invalid`.

## Stage notes

The movement probes show three useful stage families:

```text
tensor:* / schedule:function input
  high-level tensor semantics:
    SHRINK, PAD, RESHAPE, PERMUTE, EXPAND, WHERE

schedule:kernel graph / codegen:base ast
  compact kernel semantics:
    STORE OUT[affine output index] =
      LOAD/INDEX input using affine or gated source index
    optional REDUCE for gather-style advanced indexing

codegen:postopt symbolic
  optimized but still readable:
    local/global/upcast ranges introduced
    index expressions are simplified
    gather has usually passed through load-collapse

codegen:add loads and later
  renderer-facing:
    explicit LOAD and STORE
    SPECIAL lidx/gidx ranges
    vector lanes, GEP, STACK, MULACC, SHL
```

For TT backend work, the latest generally viable hook for movement/indexing semantics is `codegen:postopt symbolic`. Use `codegen:base ast` when preserving the original logical shape and movement intent matters. Use `codegen:add loads` or `final rewrite` only when the backend wants concrete memory operations and is prepared to reconstruct or ignore high-level movement intent.
