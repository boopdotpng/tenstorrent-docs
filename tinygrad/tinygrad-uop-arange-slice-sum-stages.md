# tinygrad UOp stages for `Tensor.arange(100)[45:55].sum()`

Date: 2026-05-20

Expression:

```python
from tinygrad import Tensor
out = Tensor.arange(100)[45:55].sum().realize()
print(out.item())  # 495
```

This document rewrites the raw `UOp(...)` Python dumps into a normalized tree form. It keeps every observed stage standalone, but removes object IDs, repeated source aliases, and Python repr noise.

Notation:

- `INDEX(buffer, offset)` means pointer/index construction.
- `RANGE extent=N axis=...` means a tinygrad range UOp with that extent and axis kind.
- `REDUCE ADD over ()` is the scalar reduction form after scheduling.
- Repeated stages are intentionally repeated so each stage can be read independently.

## Short conclusion

For this expression, the latest stage that still has explicit reduction intent is `codegen:add local buffers`. Immediately after that, `codegen:remove reduce` removes `Ops.REDUCE` and turns the ten-lane reduction into a tree of `ADD` plus `GEP` from a `vec(10)` value. By `codegen:devectorize`, the whole thing has constant-folded to `STORE output[0], CONST 495`.

The practical hook candidates from this probe are:

- Best semantic hook: `codegen:base ast` through `codegen:postopt symbolic`.
- Latest explicit-reduce hook: `codegen:add local buffers`.
- First too-late stage for explicit reduce: `codegen:remove reduce`.
- Definitely too late: `codegen:devectorize`, `codegen:linearized list`, and `renderer:linear`.

## Stage Graphs

### 00. `tensor:linear_with_vars input`

High-level tensor graph. Slice intent exists, but it is buried under movement ops from constructing `arange` lazily.

Ops: `ADD:1, CONST:15, DEVICE:1, EXPAND:3, PAD:1, PERMUTE:1, REDUCE:2, RESHAPE:9, SHRINK:3, SINK:1, STACK:5, UNIQUE:1`

```text
SINK
  RESHAPE []
    REDUCE ADD axes=(0)
      SHRINK [45:55]
        ADD
          RESHAPE [100]
            REDUCE ADD axes=(1)
              PERMUTE (1, 0)
                RESHAPE
                  RESHAPE
                    SHRINK
                      RESHAPE
                        SHRINK
                          RESHAPE
                            EXPAND
                              RESHAPE
                                PAD
                                  EXPAND
                                    RESHAPE
                                      CONST int 1 on device AMD
                                    to shape 100
                                  pad high by 99
                                reshape/expand support for arange construction
                            shape constants around 100/200/20099
          EXPAND CONST int -1 to shape 100
        shrink bounds: 45, 55
```

### 01. `tensor:linear_with_vars`

Callify wraps the graph into an executable call and output store. The movement-heavy tensor graph is still present.

Ops: `ADD:1, AFTER:1, BUFFER:1, CALL:1, CONST:15, DEVICE:1, EXPAND:3, PAD:1, PARAM:1, PERMUTE:1, REDUCE:2, RESHAPE:8, SHRINK:3, SINK:1, STACK:4, STORE:1, UNIQUE:1`

```text
CALL CallInfo(...)
  FUNCTION/SINK
    AFTER output_param
      STORE
        dest: PARAM int slot=0
        value:
          REDUCE ADD axes=(0)
            SHRINK [45:55]
              ADD
                RESHAPE [100]
                  REDUCE ADD axes=(1)
                    PERMUTE/RESHAPE/SHRINK/PAD/EXPAND chain building arange(100)
                EXPAND CONST int -1 to shape 100
  BUFFER output int[1] on AMD
```

### 02. `schedule:create_linear input`

Scheduler entry. This is effectively the callified tensor graph.

Ops: `ADD:1, AFTER:1, BUFFER:1, CALL:1, CONST:15, DEVICE:1, EXPAND:3, PAD:1, PARAM:1, PERMUTE:1, REDUCE:2, RESHAPE:8, SHRINK:3, SINK:1, STACK:4, STORE:1, UNIQUE:1`

```text
CALL CallInfo(...)
  FUNCTION/SINK
    AFTER output_param
      STORE
        dest: PARAM int slot=0
        value:
          REDUCE ADD axes=(0)
            SHRINK [45:55]
              ADD
                RESHAPE [100]
                  REDUCE ADD axes=(1)
                    PERMUTE/RESHAPE/SHRINK/PAD/EXPAND chain building arange(100)
                EXPAND CONST int -1 to shape 100
  BUFFER output int[1] on AMD
```

### 03. `schedule:function input`

Function body before kernel graph extraction. Still high level and movement-heavy.

Ops: `ADD:1, AFTER:1, CONST:15, DEVICE:1, EXPAND:3, PAD:1, PARAM:1, PERMUTE:1, REDUCE:2, RESHAPE:8, SHRINK:3, SINK:1, STACK:4, STORE:1`

```text
SINK
  AFTER output_param
    STORE
      dest: PARAM int slot=0
      value:
        REDUCE ADD axes=(0)
          SHRINK [45:55]
            ADD
              RESHAPE [100]
                REDUCE ADD axes=(1)
                  PERMUTE/RESHAPE/SHRINK/PAD/EXPAND chain building arange(100)
              EXPAND CONST int -1 to shape 100
```

### 04. `schedule:ttir input`

Same function-body snapshot, exposed under the TTIR-input label.

Ops: `ADD:1, AFTER:1, CONST:15, DEVICE:1, EXPAND:3, PAD:1, PARAM:1, PERMUTE:1, REDUCE:2, RESHAPE:8, SHRINK:3, SINK:1, STACK:4, STORE:1`

```text
SINK
  AFTER output_param
    STORE
      dest: PARAM int slot=0
      value:
        REDUCE ADD axes=(0)
          SHRINK [45:55]
            ADD
              RESHAPE [100]
                REDUCE ADD axes=(1)
                  PERMUTE/RESHAPE/SHRINK/PAD/EXPAND chain building arange(100)
              EXPAND CONST int -1 to shape 100
```

### 05. `schedule:kernel graph`

First clean kernel-shaped point: the slice-sum is now `reduce(range(10) + 45)`.

Ops: `ADD:1, AFTER:1, CALL:1, CAST:1, CONST:4, DEVICE:1, INDEX:1, PARAM:2, RANGE:1, REDUCE:1, SINK:2, STORE:1`

```text
SINK
  AFTER output_param
    CALL kernel(test)
      SINK KernelInfo(name='test')
        STORE
          dest:
            INDEX
              buffer: PARAM int* slot=0
              offset: CONST weakint 0
          value:
            REDUCE ADD over ()
              ADD
                CAST int
                  RANGE extent=10 axis=REDUCE
                CONST int 45
```

### 06. `schedule:scheduled linear`

Schedule output is a LINEAR/CALL wrapper around the same compact kernel body.

Ops: `CALL:1`

```text
LINEAR
  CALL kernel(test)
    SINK KernelInfo(name='test')
      STORE
        dest: INDEX(PARAM int* slot=0, CONST 0)
        value:
          REDUCE ADD over ()
            ADD
              CAST int RANGE extent=10 axis=REDUCE
              CONST int 45
    PARAM output slot=0
```

### 07. `schedule:after schedule rewrite`

The schedule is embedded in a linear call; kernel intent is unchanged.

Ops: `ADD:1, BUFFER:1, CALL:2, CAST:1, CONST:4, DEVICE:1, INDEX:1, LINEAR:1, PARAM:2, RANGE:1, REDUCE:1, SINK:1, STORE:1, UNIQUE:1`

```text
CALL
  LINEAR
    CALL kernel(test)
      SINK KernelInfo(name='test')
        STORE
          dest: INDEX(PARAM int* slot=0, CONST 0)
          value: REDUCE_ADD(CAST(RANGE extent=10 axis=REDUCE) + 45)
      PARAM output slot=0
  BUFFER output int[1] on AMD
```

### 08. `schedule:after resolve linear call`

Buffer params are resolved. The kernel body still has `RANGE + REDUCE`.

Ops: `CALL:1`

```text
LINEAR
  CALL kernel(test)
    SINK KernelInfo(name='test')
      STORE
        dest: INDEX(output_buffer, CONST 0)
        value: REDUCE_ADD(CAST(RANGE extent=10 axis=REDUCE) + 45)
```

### 09. `schedule:after memory plan`

Memory planning does not materially change this single-output kernel.

Ops: `CALL:1`

```text
LINEAR
  CALL kernel(test)
    SINK KernelInfo(name='test')
      STORE
        dest: INDEX(output_buffer, CONST 0)
        value: REDUCE_ADD(CAST(RANGE extent=10 axis=REDUCE) + 45)
```

### 10. `codegen:base ast`

Clean codegen entry AST: store a reduction over `range(10) + 45`.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='test')
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=REDUCE
          CONST int 45
```

### 11. `codegen:early movement ops`

No meaningful change for this expression.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='test')
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=REDUCE
          CONST int 45
```

### 12. `codegen:load collapse`

No loads are involved, so no meaningful change.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='test')
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=REDUCE
          CONST int 45
```

### 13. `codegen:split ranges`

Range structure stays compact.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='test')
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=REDUCE
          CONST int 45
```

### 14. `codegen:initial symbolic`

Symbolic simplification preserves the same kernel shape.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='test')
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=REDUCE
          CONST int 45
```

### 15. `codegen:simplify ranges`

Still the compact `RANGE + REDUCE` form.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='test')
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=REDUCE
          CONST int 45
```

### 16. `codegen:apply opts`

Optimizer applies an unroll option, temporarily splitting the reduction into reduce/unroll ranges.

Ops: `ADD:2, CAST:1, CONST:4, INDEX:1, MUL:1, PARAM:1, RANGE:2, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            ADD weakint
              MUL
                RANGE extent=1 axis=REDUCE
                CONST weakint 10
              RANGE extent=10 axis=UNROLL
          CONST int 45
        reduce ranges:
          RANGE extent=1 axis=REDUCE
          RANGE extent=10 axis=UNROLL
```

### 17. `codegen:postopt symbolic`

The optimized form simplifies back to one unroll range feeding the reduction.

Ops: `ADD:1, CAST:1, CONST:3, INDEX:1, PARAM:1, RANGE:1, REDUCE:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      REDUCE ADD over ()
        ADD
          CAST int
            RANGE extent=10 axis=UNROLL
          CONST int 45
        reduce/unroll lanes:
          CONST weakint 0
          RANGE extent=10 axis=UNROLL
```

### 18. `codegen:expander`

The range is expanded into a ten-lane `STACK`, but `Ops.REDUCE` is still explicit.

Ops: `ADD:1, CAST:1, CONST:11, INDEX:1, PARAM:1, REDUCE:1, SINK:1, STACK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      REDUCE ADD over ()
        ADD int.vec(10)
          CAST int.vec(10)
            STACK weakint.vec(10)
              CONST 0
              CONST 1
              CONST 2
              CONST 3
              CONST 4
              CONST 5
              CONST 6
              CONST 7
              CONST 8
              CONST 9
          CONST int.vec(10) 45
```

### 19. `codegen:add local buffers`

Last observed stage with explicit `Ops.REDUCE`; no local buffer materialization was needed here.

Ops: `ADD:1, CAST:1, CONST:11, INDEX:1, PARAM:1, REDUCE:1, SINK:1, STACK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      REDUCE ADD over ()
        ADD int.vec(10)
          CAST int.vec(10)
            STACK weakint.vec(10)
              CONST 0
              CONST 1
              CONST 2
              CONST 3
              CONST 4
              CONST 5
              CONST 6
              CONST 7
              CONST 8
              CONST 9
          CONST int.vec(10) 45
```

### 20. `codegen:remove reduce`

First too-late stage for explicit reduction intent: `Ops.REDUCE` is gone and replaced with scalar `ADD` plus `GEP` lanes.

Ops: `ADD:10, CAST:1, CONST:11, GEP:10, INDEX:1, PARAM:1, SINK:1, STACK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      ADD
        ADD
          ADD
            ADD
              ADD
                ADD
                  ADD
                    ADD
                      ADD
                        GEP lane 0 of vec
                        GEP lane 1 of vec
                      GEP lane 2 of vec
                    GEP lane 3 of vec
                  GEP lane 4 of vec
                GEP lane 5 of vec
              GEP lane 6 of vec
            GEP lane 7 of vec
          GEP lane 8 of vec
        GEP lane 9 of vec

  where vec is:
    ADD int.vec(10)
      CAST int.vec(10)
        STACK weakint.vec(10)
          CONST 0, CONST 1, CONST 2, CONST 3, CONST 4,
          CONST 5, CONST 6, CONST 7, CONST 8, CONST 9
      CONST int.vec(10) 45
```

### 21. `codegen:add gpudims`

No change for this scalar output.

Ops: `ADD:10, CAST:1, CONST:11, GEP:10, INDEX:1, PARAM:1, SINK:1, STACK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      ADD
        ADD
          ADD
            ADD
              ADD
                ADD
                  ADD
                    ADD
                      ADD
                        GEP lane 0 of vec
                        GEP lane 1 of vec
                      GEP lane 2 of vec
                    GEP lane 3 of vec
                  GEP lane 4 of vec
                GEP lane 5 of vec
              GEP lane 6 of vec
            GEP lane 7 of vec
          GEP lane 8 of vec
        GEP lane 9 of vec

  where vec is:
    ADD int.vec(10)
      CAST int.vec(10)
        STACK weakint.vec(10)
          CONST 0, CONST 1, CONST 2, CONST 3, CONST 4,
          CONST 5, CONST 6, CONST 7, CONST 8, CONST 9
      CONST int.vec(10) 45
```

### 22. `codegen:add loads`

Output index becomes pointer typed; the add/GEP tree remains.

Ops: `ADD:10, CAST:1, CONST:11, GEP:10, INDEX:1, PARAM:1, SINK:1, STACK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest: INDEX(PARAM int* slot=0, CONST weakint 0)
    value:
      ADD
        ADD
          ADD
            ADD
              ADD
                ADD
                  ADD
                    ADD
                      ADD
                        GEP lane 0 of vec
                        GEP lane 1 of vec
                      GEP lane 2 of vec
                    GEP lane 3 of vec
                  GEP lane 4 of vec
                GEP lane 5 of vec
              GEP lane 6 of vec
            GEP lane 7 of vec
          GEP lane 8 of vec
        GEP lane 9 of vec

  where vec is:
    ADD int.vec(10)
      CAST int.vec(10)
        STACK weakint.vec(10)
          CONST 0, CONST 1, CONST 2, CONST 3, CONST 4,
          CONST 5, CONST 6, CONST 7, CONST 8, CONST 9
      CONST int.vec(10) 45
```

### 23. `codegen:devectorize`

The add/GEP tree constant-folds to `STORE CONST 495`; reduction/slice/subtile intent is gone.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST weakint 0
    value:
      CONST int 495
```

### 24. `codegen:lower index dtypes`

Only index dtype concreteness changes.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 25. `codegen:post index symbolic`

No meaningful change.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 26. `codegen:decompositions`

No meaningful change.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 27. `codegen:decomp dtypes`

No meaningful change.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 28. `codegen:transcendental`

No meaningful change.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 29. `codegen:move gates from index`

No gate exists in this expression.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 30. `codegen:final rewrite`

Renderer-ready graph is still just store constant.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 31. `codegen:add control flow`

No control flow exists in this expression.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
SINK KernelInfo(name='r_10', applied_opts=(UNROLL axis=0))
  STORE
    dest:
      INDEX
        buffer: PARAM int* slot=0
        offset: CONST int 0
    value:
      CONST int 495
```

### 32. `codegen:linearized list`

Fully linearized UOp list. Only output param, index, constant, store, and sink remain.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
LINEAR
  0000 PARAM int* slot=0
  0001 CONST int 0
  0002 INDEX
       buffer: PARAM int* slot=0
       offset: CONST int 0
  0003 CONST int 495
  0004 STORE
       dest: INDEX(PARAM int* slot=0, CONST int 0)
       value: CONST int 495
  0005 SINK KernelInfo(name='r_10')
       src: STORE(dest=output[0], value=495)
```

### 33. `renderer:linear`

Renderer sees the same linear list. There is no recoverable program intent here.

Ops: `CONST:2, INDEX:1, PARAM:1, SINK:1, STORE:1`

```text
RENDERER LINEAR for AMD HIPRenderer kernel r_10
  0000 PARAM int* slot=0
  0001 CONST int 0
  0002 INDEX output[0]
  0003 CONST int 495
  0004 STORE output[0] = 495
  0005 SINK kernel r_10
```

## Match Stats

`TRACK_MATCH_STATS` is useful for correlating stage names with the pattern matchers that caused changes:

```bash
TRACK_MATCH_STATS=1 PRINT_MATCH_STATS=1 \
TT_DUMP_STAGE='codegen:expander' \
python3 probe.py
```

For this probe, the important pattern locations were `rangeify.py`, `simplify.py`, `expander.py`, and `devectorizer.py`.

## Next Probe

The next thing to run should be `Tensor.rand(100)[45:55].sum()` or a parameterized input buffer. `Tensor.arange` is useful for seeing the rewrite boundary, but because it is fully constant, late passes can fold the whole result to `495`.
