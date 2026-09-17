# Matmul dataflow and multicast scheduling

Multicast saves repeated reads when several workers need the same panel. It
adds setup, receiver coordination, and NoC traffic. Choose it from the shape,
reuse pattern, placement, and measured bottleneck; it is not universally the
fastest schedule for every contraction.

## Four roles across the grid

In TT-Metal's recorded 2D multicast matmul, A senders read a panel and distribute
it across an output row; B senders distribute a panel down an output column.
The other workers receive those panels. The B-side role also writes outputs.

| Worker position | A-side role | B-side role |
|---|---|---|
| Top-left | Sender | Sender + output writer |
| Top row | Receiver | Sender + output writer |
| Left column | Sender | Receiver + output writer |
| Interior | Receiver | Receiver + output writer |

These are role-specialized binaries assigned to core subsets. They do not
require four dataflow controllers on each tile. Senders still perform their
assigned compute work; they are not necessarily sacrificed as pure relays.

For each K block, receivers make space, senders fetch and distribute operands,
compute consumes the published panels, and buffers are released after their
last use. Output storage has its own completion/ownership protocol. A multicast
write alone does not prove that every receiver can safely consume or reuse it.

## Reuse and arithmetic intensity

For dense `C[M,N] = A[M,K] @ B[K,N]`, nominal work is `2*M*K*N` FLOPs. A lower
bound on payload traffic is `(M*K + K*N + M*N)*element_bytes` when each input is
read once and C is written once. This gives about 341 FLOPs/byte for a 1024³
problem with two-byte inputs and output. Actual traffic can be higher because
of tiling, limited storage, spills, and padding; FP32 output changes the formula.

Arithmetic intensity helps identify possible bandwidth limits. It does not by
itself prove a kernel is compute-bound. Small dimensions, poor overlap,
instruction issue, unpack cost, and output drain can dominate. Compare measured
rates against the applicable compute and bandwidth ceilings.

An elementwise addition with two-byte values performs one FLOP per six payload
bytes. Independent tile striping is a useful baseline when there is no shared
input reuse. Unary transcendental functions may need many SFPU instructions and
can be compute-limited even with little data reuse. A reduction needs aggregation;
that is not the same communication pattern as broadcasting both matmul operands.

## Choosing a baseline

| Workload | Start with | Reconsider when |
|---|---|---|
| Large, regular dense matmul | Reused panels and a regular worker grid | Storage, packing, or NoC contention dominates |
| Narrow/small matmul or matrix-vector | Smaller grid or simpler streaming | Enough shared panel reuse amortizes multicast setup |
| Elementwise | Independent tile striping | Inputs are shared/broadcast or already sharded |
| Reduction | Local partials plus an explicit combine stage | Cross-worker aggregation or layout dictates another plan |

An outer product (`K=1`) and a dot product (`N=1`) are contractions, but that
alone does not justify four-role multicast. Validate a simpler plan first.

## Source and validation

The TT-Metal source pattern is
`matmul_multicore_reuse_mcast_2d_program_factory.cpp` with role-specific dataflow
kernels and `bmm_large_block_zm_fused_bias_activation.cpp`. These names describe
the recorded source study, not blackhole-py's current API.

For the current Python implementation, inspect
[matmul_peak.py](../../blackhole-py/examples/matmul_peak.py), its emitted plan,
and the [matmul tests](../../blackhole-py/tests/compute/fpu/test_matmul_peak_fp32.py).
Use [the topology guide](../hardware/topology.md) for available workers.
Report dtype, fidelity, layout, grid, clock, and final output completion with
any performance comparison. No new hardware benchmark was run for this rewrite.
