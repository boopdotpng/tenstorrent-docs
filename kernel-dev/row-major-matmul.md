# Row-major inputs without a separate tilize pass

Scope: local blackhole-py matmul implementation and tests inspected September
17, 2026. See [evidence provenance](../hardware/behavior-from-tests.md); the
matmul files include working-tree changes beyond the baseline commit.

The current example uploads row-major inputs, fetches row spans into L1 circular
buffers, and gathers the source panels during unpacking. Padding preserves the
encoded values. It does not run a separate host tilization pass or scalar RISC
panel-copy loop. This replaces the old proposal in `tilize-fusion-todo.md`.

## FP8 and BF16 take different paths

The [source report](../../blackhole-py/tests/movement/matmul_row_major.md) describes:

- **FP8:** native tileize gathers two 32×16 panels into each source bank and
  expands FP8 to FP16 sources. Physical input row stride is padded to 1,024 bytes.
- **BF16:** replayed 16-element UNPACR reads with descriptor row strides gather
  the panels while preserving BF16. The native tileize mode reads 32 BF16
  elements per row, so it cannot simply reuse FP8's two-instruction sequence.

The matrix address schedule must consume the resulting panel order. The
[unpack tests](../../blackhole-py/tests/movement/unpacker/test_unpack_row_major.py)
exercise both source banks and row strides. The
[matmul tests](../../blackhole-py/tests/compute/fpu/test_matmul_peak_fp32.py)
check complete outputs and K-block cancellation; poisoned outputs help expose
missing stores. Changing layout is not just changing a buffer's metadata.

## What the measurements say

The source report records 5,000³ matmuls on P150 device 0 on September 16:

| Comparison | TFLOP/s | Numerical mode / scope |
|---|---:|---|
| Host-tilized FP8 baseline | 392.30 | Historical `2b5d51a`, ten runs |
| Row-major FP8 | 370.75 | Native unpack, ten runs |
| Host-tilized BF16 baseline | 182.53 | HiFi2 / BF16 accumulation, five runs |
| Row-major BF16 | 50.93 | HiFi2 / BF16 accumulation, five runs |
| Row-major BF16 | 47.52 | HiFi4 / FP32 accumulation, ten runs |

The last two rows use different numerical modes. Compare 50.93 with 182.53 for
the reported matched BF16 mode; comparing 47.52 directly would mix layout and
precision changes. The BF16 gather work is repeated on reuse and remains costly.
The FP8 profile locates the remaining completion gap in data movement/output.

These intervals include device reads, unpack, computation, and final DRAM
writes. They exclude host generation, upload, and reference calculation.
Removing host tilization can improve a different end-to-end boundary even when
device-only throughput falls. No fresh benchmark was run for this page.

## What to optimize next

Measure input preparation once versus gathering on each reuse, including the
extra L1 space and synchronization. Preserve FP32 partials across K blocks when
that is the selected accumulation mode. Include both dataflow controllers'
output completion in the timing boundary. Validate tails, repeated launches,
source order, and cancellation before calling a faster schedule equivalent.

The [TT-Metal layout reference](tilize-untilize-and-tile-layout.md) explains the
LLK tilize/untilize APIs. Those APIs and their buffer conventions are a separate
software interface from this raw Python emitter path.
