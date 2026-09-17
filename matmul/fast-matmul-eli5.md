# How a Blackhole matmul stays busy

To compute `C = A @ B`, divide C into output blocks and assign them to Tensix
tiles. Each tile repeatedly obtains an A block and a B block, multiplies them,
and adds the partial result to its assigned C block. Performance comes from
reusing those operands and overlapping movement with arithmetic.

## One tile's loop

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

## Reuse saves traffic

If an A panel contributes to several output columns, keep or distribute it
instead of reading it again for every output tile. The same applies to B across
output rows. A 2D multicast scheme reads A at a row's sender and B at a column's
sender, then shares them with the participating workers. Every receiver must
have space and agree on buffer ownership before the sender publishes data.

The [four-role TT-Metal explanation](matmul-2d-mcast-role-split-eli5.md) describes
one implementation. Four dataflow roles across core subsets do not mean four
dataflow controllers on each tile. Multicast also is not always the best choice:
small shapes, irregular placement, and limited reuse can favor simpler schedules.

## Overlap needs storage and completion rules

With two input buffers, readers can fill the next block while compute consumes
the current one. With Dst partitioning, math and pack can hand off output blocks.
The buffers must be large enough, and consumers must release them only after
all dependent work is complete. A missing wait can produce a fast wrong result;
an impossible CB reservation can hang.

A matrix instruction is not an entire matmul. An ordinary 8×16 by 16×16
`MVMUL` operation represents 2,048 multiply-accumulates, conventionally counted
as 4,096 FLOPs. More fidelity phases recover more product precision and add work.
Output format alone does not describe that precision. See
[accumulation and spills](fp32-accumulation.md).

## Layout belongs in the comparison

The current example can read row-major arrays and gather panels during unpack.
Its FP8 and BF16 paths have different costs. Avoid comparing a host-tilized
baseline against a row-major path without naming which preparation work is timed.
The [row-major guide](../kernel-dev/row-major-matmul.md) gives concrete results.

Measure through final output completion, compare all outputs against an
appropriate reference, and test tails and repeated launches. To understand a
slow case, find the engine or transfer that finishes last, then change its
schedule and repeat that same comparison.
