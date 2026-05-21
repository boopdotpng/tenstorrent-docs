# tinygrad UOp memory effects: `AFTER`, `STORE`, `CALL`, and `END`

Date: 2026-05-21

This probe uses local `TT_DUMP_STAGE` instrumentation in the checked-out tinygrad tree. All examples were run with explicit `device="CPU"` tensors and no Tenstorrent device queue.

The raw dumps were rewritten by hand into normalized trees. Object IDs, Python repr aliases, and repeated source labels are removed. The important detail is the memory-effect shape: where `AFTER` wraps buffer identity, where `STORE` performs the write, and how `CALL` and `END` become schedule dependencies.

## Commands

```bash
cd /home/boop/tenstorrent/tinygrad

TT_DUMP_STAGE='tensor:linear_with_vars input,tensor:linear_with_vars,schedule:function input,schedule:kernel graph,schedule:scheduled linear,schedule:after resolve linear call,schedule:after memory plan' \
python3 - <<'PY'
from tinygrad import Tensor

a = Tensor.zeros(4, device="CPU")
a.assign(a + 1)
a.assign(a * 2)
a.realize()

a = Tensor.arange(4, device="CPU").float().realize()
a[1:3].assign(Tensor([7.0, 8.0], device="CPU"))
a.assign(a + 1)
a.realize()

Tensor.arange(6, device="CPU").reshape(2, 3).permute(1, 0).contiguous().realize()
PY
```

A focused second run used only `schedule:kernel graph,schedule:scheduled linear` for the slice-assign/update chain so the dependency graph was not lost in unrelated initial-realize output.

## Notation

- `BUF4` means the logical 4-element destination buffer.
- `TMP2` means the temporary 2-element CPU buffer introduced for the Python-list slice source.
- `PY2` means the original Python-side 2-element buffer.
- `INDEX(buf, i)` means pointer/index construction.
- `RANGE n` means a loop range of extent `n`.
- `END(store, ranges...)` means the store is scoped by those ranges.
- `AFTER(base, effects...)` returns the same buffer identity as `base`, but consumers of the `AFTER` are ordered after `effects`.

## Short conclusion

`AFTER` is the memory dependency carrier. It does not compute a value; it passes through the identity of `src[0]` and makes later consumers wait for `src[1:]`.

`STORE` is the write effect. It is void-like and normally appears inside an `AFTER` before scheduling, then inside a kernel `CALL` body after rangeify/splitting.

`CALL` is the scheduled executable effect. In `schedule:kernel graph`, `AFTER(..., CALL(...))` marks that a buffer version is produced by that call. In `schedule:scheduled linear`, only the ordered `CALL`s remain.

`END` closes loop ranges around a `STORE`. It is treated as a kernel-like dependency wrapper by the scheduler when present around calls/stores.

## Probe 1: two full-buffer assigns

Expression:

```python
a = Tensor.zeros(4, device="CPU")
a.assign(a + 1)
a.assign(a * 2)
a.realize()
```

### `tensor:linear_with_vars input`

Before callify, both updates are visible as nested `AFTER` nodes over the same logical tensor. The second store reads the first `AFTER`, not the original zero expression.

Ops: `ADD:1, AFTER:2, CONST:5, DEVICE:1, EXPAND:3, MUL:1, RESHAPE:3, SINK:1, STORE:2, UNIQUE:1`

```text
SINK
  AFTER
    base:
      AFTER
        base: EXPAND(CONST 0.0, shape=4)
        effect:
          STORE
            dest: EXPAND(CONST 0.0, shape=4)
            value: EXPAND(CONST 0.0, shape=4) + EXPAND(CONST 1.0, shape=4)
    effect:
      STORE
        dest: previous AFTER
        value: previous AFTER * EXPAND(CONST 2.0, shape=4)
```

### `tensor:linear_with_vars`

Callify turns the destination into a parameter plus an allocated output buffer. The write-after-write chain is still explicit.

Ops: `ADD:1, AFTER:2, BUFFER:1, CALL:1, CONST:5, DEVICE:1, EXPAND:3, MUL:1, PARAM:1, RESHAPE:3, SINK:1, STORE:2, UNIQUE:1`

```text
CALL
  function:
    SINK
      AFTER
        base:
          AFTER
            base: PARAM BUF4
            effect:
              STORE
                dest: PARAM BUF4
                value: 0.0 + 1.0
        effect:
          STORE
            dest: previous AFTER
            value: previous AFTER * 2.0
  args:
    BUFFER BUF4
```

### `schedule:kernel graph`

Rangeify/splitting lowers the two stores into two kernel calls. The first `AFTER` produces `BUF4` with a fill-1 kernel. The second `AFTER` depends on the first and produces the same `BUF4` with a multiply-by-2 kernel.

Ops: `AFTER:2, CALL:2, CONST:3, DEVICE:1, END:2, INDEX:1, MUL:1, PARAM:2, RANGE:1, SINK:3, STORE:2`

```text
SINK
  a1 = AFTER
    base: PARAM BUF4
    effect:
      CALL kernel K0(PARAM BUF4)
        SINK
          END
            STORE
              dest: INDEX(PARAM BUF4, RANGE 4)
              value: CONST 1.0
            RANGE 4

  AFTER
    base: a1
    effect:
      CALL kernel K1(a1)
        SINK
          END
            STORE
              dest: INDEX(PARAM BUF4, RANGE 4)
              value: LOAD/INDEX(PARAM BUF4, RANGE 4) * CONST 2.0
            RANGE 4
```

### `schedule:scheduled linear`

The scheduler consumes the `AFTER` dependency chain and emits two calls in order.

Ops: `CALL:2`

```text
LINEAR
  0: CALL K0(BUF4)
       STORE INDEX(BUF4, RANGE 4) <- 1.0
  1: CALL K1(BUF4)
       STORE INDEX(BUF4, RANGE 4) <- INDEX(BUF4, RANGE 4) * 2.0
```

## Probe 2: slice assign followed by full-buffer update

Expression:

```python
a = Tensor.arange(4, device="CPU").float().realize()
a[1:3].assign(Tensor([7.0, 8.0], device="CPU"))
a.assign(a + 1)
a.realize()
```

The first `realize()` materializes `a` as `[0, 1, 2, 3]`. The interesting second realize contains a slice store from a Python-created tensor, then a full-buffer update that reads the updated buffer.

### `tensor:linear_with_vars input`

At the tensor level, the slice write is represented by an `AFTER` on the slice view. A second `AFTER` lifts that view effect back to the base buffer identity. The final full-buffer update is another `STORE` after that lifted base.

Ops: `ADD:1, AFTER:3, BUFFER:2, CONST:4, COPY:1, DEVICE:2, EXPAND:1, RESHAPE:1, SHRINK:1, SINK:1, STORE:2, UNIQUE:2`

```text
SINK
  AFTER
    base:
      AFTER
        base: BUFFER BUF4
        effect:
          AFTER
            base: SHRINK(BUFFER BUF4, 1:3)
            effect:
              STORE
                dest: SHRINK(BUFFER BUF4, 1:3)
                value: COPY(PY2 -> CPU)
    effect:
      STORE
        dest: previous base AFTER
        value: previous base AFTER + 1.0
```

### `tensor:linear_with_vars`

Callify makes the slice source and destination explicit parameters. Notice the middle `AFTER(PARAM BUF4, slice_after)`: this is the bridge from the slice view update to the whole-buffer identity.

Ops: `ADD:1, AFTER:3, BUFFER:2, CALL:1, CONST:5, COPY:1, DEVICE:2, EXPAND:1, PARAM:2, RESHAPE:1, SHRINK:1, SINK:1, STORE:2, UNIQUE:2`

```text
CALL
  function:
    SINK
      slice_after = AFTER
        base: SHRINK(PARAM BUF4, 1:3)
        effect:
          STORE
            dest: SHRINK(PARAM BUF4, 1:3)
            value: COPY(PARAM PY2 -> CPU)

      base_after = AFTER
        base: PARAM BUF4
        effect: slice_after

      AFTER
        base: base_after
        effect:
          STORE
            dest: base_after
            value: base_after + 1.0
  args:
    BUFFER BUF4
    BUFFER PY2
```

### `schedule:kernel graph`

The focused dump shows three scheduled effects:

1. copy Python data to a temporary CPU buffer,
2. store that temporary into `BUF4[1:3]`,
3. update all of `BUF4` with `+ 1`.

Ops: `ADD:2, AFTER:3, BUFFER:1, CALL:3, CONST:4, COPY:1, DEVICE:2, END:2, INDEX:3, LUNIQUE:1, PARAM:4, RANGE:2, SINK:3, STORE:2`

```text
SINK
  slice_after = AFTER
    base: PARAM BUF4
    effect:
      CALL K_slice_store(PARAM BUF4, temp_after)
        SINK
          END
            STORE
              dest: INDEX(PARAM BUF4, RANGE 2 + 1)
              value: INDEX(TMP2, RANGE 2)
            RANGE 2
    dependency input:
      temp_after = AFTER
        base: TMP2
        effect:
          CALL COPY(TMP2, PY2)

  slice_after

  AFTER
    base: slice_after
    effect:
      CALL K_full_update(slice_after)
        SINK
          END
            STORE
              dest: INDEX(PARAM BUF4, RANGE 4)
              value: INDEX(PARAM BUF4, RANGE 4) + CONST 1.0
            RANGE 4
```

### `schedule:scheduled linear`

The dependency carriers are gone; the linear call order preserves them.

Ops: `CALL:3`

```text
LINEAR
  0: CALL COPY(TMP2 <- PY2)
       COPY INDEX(PY2, RANGE 2) -> TMP2

  1: CALL K_slice_store(BUF4, TMP2)
       STORE INDEX(BUF4, RANGE 2 + 1) <- INDEX(TMP2, RANGE 2)

  2: CALL K_full_update(BUF4)
       STORE INDEX(BUF4, RANGE 4) <- INDEX(BUF4, RANGE 4) + 1.0
```

This is the clearest store-after-store chain in the probes. The full update reads and writes the same buffer after the slice write. The scheduler does not infer this from textual order; it follows the `AFTER` graph.

## Probe 3: `contiguous()` / copy-style materialization

Expression:

```python
Tensor.arange(6, device="CPU").reshape(2, 3).permute(1, 0).contiguous().realize()
```

### `tensor:linear_with_vars input`

The high-level tensor graph still contains an explicit `CONTIGUOUS` over a permuted view.

Ops: `ADD:1, CONST:15, CONTIGUOUS:1, DEVICE:1, EXPAND:3, PAD:1, PERMUTE:2, REDUCE:1, RESHAPE:9, SHRINK:2, SINK:1, STACK:5, UNIQUE:1`

```text
SINK
  CONTIGUOUS
    PERMUTE (1, 0)
      RESHAPE [2, 3]
        ARANGE(6) expression
```

### `tensor:linear_with_vars`

Callify rewrites `CONTIGUOUS` into `STORE+AFTER` when it needs a real buffer. The destination is a reshaped output parameter with shape `[3, 2]`; the value is the permuted arange expression.

Ops: `ADD:1, AFTER:1, BUFFER:1, CALL:1, CONST:15, DEVICE:1, EXPAND:3, PAD:1, PARAM:1, PERMUTE:2, REDUCE:1, RESHAPE:10, SHRINK:2, SINK:1, STACK:6, STORE:1, UNIQUE:1`

```text
CALL
  function:
    SINK
      AFTER
        base: RESHAPE(PARAM OUT6, [3, 2])
        effect:
          STORE
            dest: RESHAPE(PARAM OUT6, [3, 2])
            value:
              PERMUTE (1, 0)
                RESHAPE [2, 3]
                  ARANGE(6) expression
  args:
    BUFFER OUT6
```

### `schedule:kernel graph`

The contiguous materialization becomes one kernel with two loop ranges. The store writes linearized output indices for shape `[3, 2]`; the value computes the transposed arange index.

Ops: `ADD:2, AFTER:1, CALL:1, CAST:1, CONST:3, DEVICE:1, END:1, INDEX:1, MUL:2, PARAM:2, RANGE:2, SINK:2, STORE:1`

```text
SINK
  AFTER
    base: PARAM OUT6
    effect:
      CALL K_contig(PARAM OUT6)
        SINK
          END
            STORE
              dest:
                INDEX(PARAM OUT6, RANGE0 * 2 + RANGE1)
              value:
                CAST int (RANGE1 * 3 + RANGE0)
            RANGE0 extent=3
            RANGE1 extent=2
```

### `schedule:scheduled linear`

```text
LINEAR
  0: CALL K_contig(OUT6)
       STORE INDEX(OUT6, r0 * 2 + r1) <- int(r1 * 3 + r0)
       loops: r0 in [0,3), r1 in [0,2)
```

## Dependency tracking notes

`Ops.AFTER`

`AFTER` is a pass-through node with ordering. In `tinygrad/uop/__init__.py`, the local comment says it passes `src[0]` through and promises in the toposort that consumers of the `AFTER` run after `src[1:]`. The probes match that exactly:

```text
AFTER(BUF4, CALL K0)       means "BUF4 after K0"
AFTER(AFTER(BUF4,K0), K1)  means "same BUF4 after K0 then K1"
```

`Ops.STORE`

`STORE(dest, value)` is the write effect. Before scheduling it can target a high-level view such as `SHRINK(BUF4, 1:3)` or `RESHAPE(OUT6, [3,2])`. Rangeify lowers those views into `INDEX` expressions under `END`.

`Ops.CALL`

`CALL` is the executable effect used by scheduling. In the kernel graph, calls are still embedded in `AFTER` nodes so the scheduler can build edges. In the linear schedule, calls appear in execution order and the `AFTER` wrappers have served their purpose.

`Ops.END`

`END` closes the ranges for a `STORE`. The schedule code treats `CALL` and `END` as kernel/effect wrappers when splitting `AFTER` sources. In the normalized trees above, `END(STORE(...), RANGE...)` means the store is performed over those loop ranges.

WAR/store-after-store handling

The slice probe exercises the important case for cache-update style writes. The slice store and the later full-buffer update both write `BUF4`, and the later update also reads `BUF4`. Rangeify keeps the write chain explicit by wrapping each produced buffer version in `AFTER`; then `create_schedule` walks those `AFTER` sources to build the linear order.

The practical mental model is:

```text
high-level mutation:
  buffer.assign(expr)

tensor graph:
  AFTER(buffer, STORE(buffer_or_view, expr))

kernel graph:
  AFTER(buffer, CALL(kernel_with_END_STORE, dependencies...))

linear schedule:
  CALL producer
  CALL consumer/update
```

For dependency probes, the best stages are `tensor:linear_with_vars input`, `tensor:linear_with_vars`, `schedule:kernel graph`, and `schedule:scheduled linear`. Earlier stages show user-level mutation shape; `schedule:kernel graph` shows explicit `AFTER/CALL/END/STORE` dependencies; `schedule:scheduled linear` confirms the final ordered calls.
