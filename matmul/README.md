# Matrix multiplication: layout, precision, and fusion

This guide follows the September 2026 blackhole-py implementation. It brings the execution loop, numerical choices, row-major measurements, and epilogue ownership together. [Scheduling](scheduling.md) covers multicast tradeoffs; [test evidence](../hardware/behavior-from-tests.md) records validation limits.

<a id="fast-matmul-eli5"></a>
## How a Blackhole matmul stays busy
<a id="fast-matmul-eli5--how-a-blackhole-matmul-stays-busy"></a>

To compute `C = A @ B`, divide C into output blocks and assign them to Tensix
tiles. Each tile repeatedly obtains an A block and a B block, multiplies them,
and adds the partial result to its assigned C block. Performance comes from
reusing those operands and overlapping movement with arithmetic.

<a id="fast-matmul-eli5--one-tiles-loop"></a>
### One tile's loop

```text
Read the next A/B block into L1
    → unpack panels into SrcA/SrcB
    → multiply and accumulate in Dst
    → repeat over K
    → apply any epilogue
    → pack C into L1 and write it to DRAM
```

The loop is split across controllers and engines. BRISC/NCRISC commonly handle
transfers and TRISCs handle unpack/math/pack, but assignments are software choices.
Current blackhole-py emits separate controller images; TT-Metal presents its own
reader/compute/writer interface. See [the runtime map](../build-and-dispatch/blackhole-py-runtime.md).

<a id="fast-matmul-eli5--reuse-saves-traffic"></a>
### Reuse saves traffic

If an A panel contributes to several output columns, keep or distribute it
instead of reading it again for every output tile. The same applies to B across
output rows. A 2D multicast scheme reads A at a row's sender and B at a column's
sender, then shares them with the participating workers. Every receiver must
have space and agree on buffer ownership before the sender publishes data.

The [four-role TT-Metal explanation](scheduling.md) describes
one implementation. Four dataflow roles across core subsets do not mean four
dataflow controllers on each tile. Multicast also is not always the best choice:
small shapes, irregular placement, and limited reuse can favor simpler schedules.

<a id="fast-matmul-eli5--overlap-needs-storage-and-completion-rules"></a>
### Overlap needs storage and completion rules

With two input buffers, readers can fill the next block while compute consumes
the current one. With Dst partitioning, math and pack can hand off output blocks.
The buffers must be large enough, and consumers must release them only after
all dependent work is complete. A missing wait can produce a fast wrong result;
an impossible CB reservation can hang.

A matrix instruction is not an entire matmul. An ordinary 8×16 by 16×16
`MVMUL` operation represents 2,048 multiply-accumulates, conventionally counted
as 4,096 FLOPs. More fidelity phases recover more product precision and add work.
Output format alone does not describe that precision. See
[accumulation and spills](README.md#fp32-accumulation).

<a id="fast-matmul-eli5--layout-belongs-in-the-comparison"></a>
### Layout belongs in the comparison

The current example can read row-major arrays and gather panels during unpack.
Its FP8 and BF16 paths have different costs. Avoid comparing a host-tilized
baseline against a row-major path without naming which preparation work is timed.
The [row-major guide](README.md#row-major-matmul) gives concrete results.

Measure through final output completion, compare all outputs against an
appropriate reference, and test tails and repeated launches. To understand a
slow case, find the engine or transfer that finishes last, then change its
schedule and repeat that same comparison.

<a id="fp32-accumulation"></a>
## Matmul accumulation precision
<a id="fp32-accumulation--matmul-accumulation-precision"></a>

Input format, product fidelity, Dst precision, spill format, and output format
are separate choices. Keeping the output in FP32 does not recover information
lost earlier in products or intermediate spills.

This page follows the September 2026 local blackhole-py tests. The earlier
`CkernelConfig` recipe described its retired LLK-based runtime.

<a id="fp32-accumulation--dst-capacity-and-spills"></a>
### Dst capacity and spills

Widening Dst elements from 16 to 32 bits halves element capacity. For ordinary
32×32 tiles:

| Dst representation | Whole Dst | Half-Dst producer/consumer partition |
|---|---:|---:|
| 16-bit | 16 tiles | 8 tiles |
| 32-bit | 8 tiles | 4 tiles |

Half/full partitioning is a software synchronization policy. With half-Dst
ownership, a subblock must fit in that half. Smaller subblocks can increase
scheduling overhead; they do not imply a universal 26% throughput penalty.

For long K reductions, the intermediate packed representation matters too.
FP32 accumulation requires preserving FP32 partials across K blocks, including
pack/unpack configuration and intermediate page sizes. A 32×32 FP32 payload is
4,096 bytes; a BF16 payload is 2,048. BF16 and IEEE FP16 are different formats;
avoid using “fp16” as a synonym for both.

<a id="fp32-accumulation--current-tested-path"></a>
### Current tested path

The inspected [matmul implementation](../../blackhole-py/examples/matmul_peak.py)
defaults to BF16 inputs, HiFi4 products, FP32 accumulation, and FP32 output.
Explicit BF16 accumulation remains available. `--fp8-fast` uses FP16 accumulation
and output; FP8 with FP32 accumulation is another mode.

The [FP32 tests](../../blackhole-py/tests/compute/fpu/test_matmul_peak_fp32.py)
include a K-block cancellation case and compare the complete result to a
reference. The [row-major report](../../blackhole-py/tests/movement/matmul_row_major.md)
records numerical error and timing scope. These support the inspected paths,
not every shape, numerical edge, or future emitter change.

<a id="fp32-accumulation--packer-l1-accumulation"></a>
### Packer L1 accumulation

A blanket statement that FP32 cannot use packer L1 accumulation is incorrect.
[Raw tests](../../blackhole-py/tests/movement/packer/test_l1_accumulation.py)
validate BF16 and FP32 L1 outputs with nonzero initial values, zero contributions,
cancellation, repeated passes, and adjacent guards. The recipe enables both
`Pack_L1_Acc` and `Disable_pack_zero_flags`, then restores them.

This does not establish arbitrary mixed-format behavior. In particular, the
[historical Float16-format bug](../hardware/packer-l1-acc-float16-hardware-bug.md)
concerns a different format/configuration. FP32 Dst and FP32 L1 accumulation
should not be conflated with FP32 Dst converted to a narrower output before
accumulation. See the [test evidence guide](../hardware/behavior-from-tests.md).

<a id="fp32-accumulation--compare-performance-fairly"></a>
### Compare performance fairly

Record input dtype, fidelity, Dst dtype, spill dtype, output dtype, layout,
shape, worker count, clock, and the timed completion boundary. The older
[P100A sweep](../archive/matmul/matmul-peak-sweep.md) remains a historical measurement, not a
prediction for the current runtime. The
[row-major comparison](README.md#row-major-matmul) separates BF16/HiFi2
from BF16/HiFi4/FP32 results.

<a id="row-major-matmul"></a>
## Row-major inputs without a separate tilize pass
<a id="row-major-matmul--row-major-inputs-without-a-separate-tilize-pass"></a>

Scope: local blackhole-py matmul implementation and tests inspected September
17, 2026. See [evidence provenance](../hardware/behavior-from-tests.md); the
matmul files include working-tree changes beyond the baseline commit.

The current example uploads row-major inputs, fetches row spans into L1 circular
buffers, and gathers the source panels during unpacking. Padding preserves the
encoded values. It does not run a separate host tilization pass or scalar RISC
panel-copy loop. This replaces the old proposal in `tilize-fusion-todo.md`.

<a id="row-major-matmul--fp8-and-bf16-take-different-paths"></a>
### FP8 and BF16 take different paths

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

<a id="row-major-matmul--what-the-measurements-say"></a>
### What the measurements say

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

<a id="row-major-matmul--what-to-optimize-next"></a>
### What to optimize next

Measure input preparation once versus gathering on each reuse, including the
extra L1 space and synchronization. Preserve FP32 partials across K blocks when
that is the selected accumulation mode. Include both dataflow controllers'
output completion in the timing boundary. Validate tails, repeated launches,
source order, and cancellation before calling a faster schedule equivalent.

The [TT-Metal layout reference](../kernel-dev/tilize-untilize-and-tile-layout.md) explains the
LLK tilize/untilize APIs. Those APIs and their buffer conventions are a separate
software interface from this raw Python emitter path.

<a id="kernel-fusion"></a>
## Keeping a matmul epilogue in Dst
<a id="kernel-fusion--keeping-a-matmul-epilogue-in-dst"></a>

The matrix engine writes results to Dst. The SFPU loads Dst into vector
registers and stores results back. An epilogue can therefore run before the
final pack, avoiding an intermediate L1/DRAM spill and reload.

This saves memory traffic, not all computation. SFPU instructions, configuration,
register ownership, and engine dependencies still have costs. The current
blackhole-py interface uses Python instruction emitters; the LLK/SFPI names in
older examples belong to the C++ stack.

<a id="kernel-fusion--the-dependency-to-preserve"></a>
### The dependency to preserve

```text
matrix operations on an output block
    → wait for the relevant Dst writes
    → SFPU load / arithmetic / store on that block
    → wait for SFPU completion and publish Dst
    → pack final output
    → finish output transfer before reusing its storage
```

Do not publish a block to the packer while its epilogue still modifies it.
A delayed load-macro store must also finish before ownership changes. A
controller issuing its last instruction is not the same as backend completion.

<a id="kernel-fusion--shared-engines-do-not-imply-universal-serialization"></a>
### Shared engines do not imply universal serialization

The old claim that FPU and SFPU cannot overlap because both use TRISC1 was too
strong. Controller assignment, engine resource arbitration, and data dependence
are separate. Current
[Dst contention probes](../../blackhole-py/tests/compute/fpu/test_dst_bandwidth.py)
compare schedules on independent regions and exercise different issuing TRISCs.
They do not make it legal to read a matrix result before it is ready.

For a simple epilogue on the same block, order the dependent work explicitly.
For overlap across independent blocks, measure the actual Dst port contention
and switching costs; don't assume either perfect overlap or mandatory global
serialization.

<a id="kernel-fusion--configuration-is-part-of-the-fused-kernel"></a>
### Configuration is part of the fused kernel

The unpacker, matrix address modes, SFPU modes, packer format, and synchronization
state must agree. Calling a full datacopy initializer between matrix math and
an epilogue can change more state than intended. Raw SFPI or direct opcodes do
not eliminate the need for correct Dst addressing, predication, format, and
hazard handling.

A 32×32 tile's face layout and vector addressing determine which elements are
visited. A guessed `dst_reg[0..31]` loop is not a universal proof that every
logical element was processed. Validate all outputs and adjacent guards.

<a id="kernel-fusion--capacity-and-precision"></a>
### Capacity and precision

The ordinary whole-Dst capacity is 16 32×32 tiles with 16-bit elements or eight
with 32-bit elements. A half-Dst ownership scheme halves those counts again.
Fused temporaries and a bias operand also consume resources. Large reductions
may still need spills; preserve the chosen precision across them. See
[accumulation](README.md#fp32-accumulation).

Packer ReLU can eliminate a separate SFPU activation sequence when its exact
semantics meet the numerical contract. It still runs within the pack path;
call it an avoided math sequence rather than assuming an end-to-end zero cost.

<a id="kernel-fusion--evidence-to-read"></a>
### Evidence to read

- [Load-macro scale test](../../blackhole-py/tests/compute/sfpu/test_loadmacro_pipeline.py): all 8,192 FP32 values and guards are checked across five schedules; configuration/unpack/pack are outside its timed compute interval.
- [Hardware evidence guide](../hardware/behavior-from-tests.md): reported results and their limitations.
- [Current timing guide](../../blackhole-py/tests/timing/README.md): result readiness, issue spacing, resource sharing, and completion.
- [Compute pipeline](../kernel-dev/tensix-compute-pipeline.md): the TT-Metal/LLK programming interface.

## Product fidelity

Input format, fidelity phase schedule, accumulation representation, spill format,
and output format are separate choices. LoFi uses one product phase; the usual
HiFi2/3/4 schedules use two, three, or four. Address modifiers advance the
fidelity state while revisiting the intended operands and Dst block.

The phase model splits source significands into selected high and low pieces
and accumulates their cross-products. Calling HiFi4 “full precision” without a
format and rounding contract is misleading: more phases do not promise an
IEEE FP32 multiply or erase later accumulation error. Similarly, one/two/four
phases do not guarantee a 1×/½×/¼× end-to-end speed ratio when data movement or
other engines dominate.

A replay sequence's chosen length is not the replay buffer's hardware capacity.
The old fidelity guide incorrectly presented a 16-instruction matmul sequence
as a universal 16-entry limit. Use the [frontend model](../hardware/blackhole-emulator-specs/frontend.md)
and per-instruction ISA entries for replay constraints.

The [FP32 matmul tests](../../blackhole-py/tests/compute/fpu/test_matmul_peak_fp32.py)
check tails, multiple subblocks, repeated launches, range, and a cancellation
case whose small partial must survive across K blocks. Those assertions are more
useful than selecting a fidelity label alone. They cover the exercised paths,
not arbitrary shapes or numerical edge cases.
