# Dataflow, buffer ownership, and reductions

TT-Metal's circular-buffer API is a software protocol over L1 storage. Current
blackhole-py uses its own emitters and firmware; translate the ownership rules,
not the C++ API names. See [the runtime map](../build-and-dispatch/blackhole-py-runtime.md).

## Publish only completed data

| Stage | Producer | Consumer |
|---|---|---|
| Input L1 buffer | Reserve space, read input, wait for read completion, publish | Wait for data, unpack, release after the last use |
| Dst block | Acquire ownership, compute, finish dependent writes, publish | Wait for ownership, pack, release after pack completion |
| Output L1 buffer | Reserve space, pack, finish writes, publish | Wait for data, transfer out, wait for transfer completion, release |

These are separate resources. A NoC barrier does not acquire Dst; a CB push does
not by itself finish a pending NoC read. Publishing too early exposes incomplete
data. Releasing too early lets a producer overwrite data still being consumed.

## TT-Metal circular buffers

The producer uses `cb_reserve_back`, `get_write_ptr`, and `cb_push_back`.
The consumer uses `cb_wait_front`, `get_read_ptr`, and `cb_pop_front`.
The ordinary streaming pattern assigns one producer and one consumer to a CB.
Multi-party communication requires an additional protocol.

Host CB configuration and kernel format/shape descriptors must agree on page
size. A reservation larger than capacity cannot become satisfiable. Increasing
buffer depth can enable overlap but consumes L1. The number of usable inputs is
a storage and scheduling question; the earlier “3–4 input” and “8 input” limits
were template choices, not hardware laws.

A minimal streaming pair, shown as pseudocode:

```text
reader: reserve input page
        issue NoC read into write pointer
        wait for read completion
        publish input page

writer: wait for output page
        issue NoC write from read pointer
        wait for write completion
        release output page
```

The compute stage additionally handles unpack, Dst ownership, math, and packing.
See [the compute pipeline](tensix-compute-pipeline.md) for TT-Metal's three-TRISC
convention and [matrix multiplication](../matmul/README.md) for intermediate spills.

## Choose a dataflow pattern from the actual accesses

| Pattern | Required behavior |
|---|---|
| Constant fill | Compute produces output without an input reader |
| Aligned elementwise | Stream corresponding input tiles; publish only when every required input is ready |
| Broadcast / strided access | Generate addresses from the logical indexing expression; do not advance every input identically |
| Reduction | Stream the reduction extent for each output; retain partials and reuse broadcast operands as needed |
| Multicast matmul | Assign senders/receivers and coordinate space before publishing shared panels |
| L1-resident/sharded input | Establish initial ownership explicitly; a DRAM reader may be unnecessary |
| Multiple outputs | Drain every output and prevent one full output CB from blocking progress on the others |

The retired template page inferred “full coverage” from a 4,457-kernel compiler
corpus. Buffer-argument counts do not establish access pattern, aliasing,
reduction shape, or correctness of a fixed reader. A general compiler must lower
indexing and storage lifetimes as well as arithmetic. The source maps in
[Compiler maps](../compiler-maps/README.md) cover that problem separately.

## Partial tiles and reduction identities

Padding is part of the numerical contract:

| Reduction | Padding contribution | Additional condition |
|---|---|---|
| Sum | 0 | Define NaN and overflow behavior |
| Mean | 0 in the numerator | Divide by the logical element count |
| Maximum | Negative infinity | Check format support and NaN policy |
| Minimum | Positive infinity | Check format support and NaN policy |

A generic minimum can be expressed as `-max(-x)` when its numerical semantics
match the desired operation. For `[3,5]`, the maximum of `[-3,-5,-inf]` is `-3`,
so negation gives `3`.

TT-Metal's recorded generic reduction path fills padding with an identity;
selected Moreh sum/mean paths use a separate mask tile. Multiplication by a
zero mask does **not** safely erase arbitrary NaNs or infinities (`0*NaN` remains
NaN). Initialize padding or use a selection operation that meets the desired
semantics. Do not count padded elements in a mean's divisor.

## Validate a schedule

Check all outputs, odd dimensions, format/page-size combinations, repeated
launches, adjacent guards, and cancellation across spills. Tests of one fixed
reader do not validate every stride or broadcast. The
[blackhole-py evidence guide](../hardware/behavior-from-tests.md) identifies actual
assertions and remaining gaps.

TT-Metal source entry points: `tt_metal/hw/inc/api/dataflow/dataflow_api.h`,
`ttnn/cpp/ttnn/operations/reduction/generic/generic_reductions.cpp`, and the
`moreh_sum` / `moreh_mean` program factories in the recorded checkout.
