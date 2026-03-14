# When to use 4-role 2D multicast vs simpler kernel architectures

The 4-role 2D multicast pattern (see `matmul-2d-mcast-role-split-eli5.md`) is the optimal kernel architecture for matmul-class ops. It is not optimal — and is actively harmful — for element-wise and reduction ops. This doc explains why, using arithmetic intensity as the deciding metric.

## The 4-role topology (recap)

In `blackhole-py/ops.py`, the compute grid is partitioned into 4 roles:

| Role | Cores | NCRISC (reader) | BRISC (writer) |
|------|-------|------------------|----------------|
| top-left | `grid[0][0]` | DRAM read IN0 + mcast across row | DRAM read IN1 + mcast down column + write output |
| top-row | `grid[0][1:]` | receive IN0 mcast | DRAM read IN1 + mcast down column + write output |
| left-col | `grid[1:][0]` | DRAM read IN0 + mcast across row | receive IN1 mcast + write output |
| interior | all others | receive IN0 mcast | receive IN1 mcast + write output |

Edge cores read DRAM and relay data inward via NoC multicast. Interior cores receive both inputs without touching DRAM. All cores run the same compute kernel.

## Arithmetic intensity determines the right architecture

**Arithmetic intensity** = FLOPs per byte loaded from DRAM. This single number determines whether an op is compute-bound or memory-bound, and therefore whether multicast helps.

### Matmul: compute-bound, high intensity

For `C[M,N] = A[M,K] @ B[K,N]`:

| Metric | Value |
|--------|-------|
| FLOPs | `2 * M * K * N` |
| Bytes from DRAM | `(M*K + K*N + M*N) * sizeof(dtype)` |
| Arithmetic intensity | `O(min(M, K, N))` — grows with problem size |

At 1024x1024x1024 fp16: ~2 billion FLOPs for ~6 MB of data = **~330 FLOPs/byte**. The FPU is the bottleneck. Each row of A is reused across `N/32` column-cores; each column of B is reused across `M/32` row-cores. Multicast amortizes DRAM reads by the grid dimension, keeping the FPU fed.

### Element-wise ops: memory-bound, ~0.2 FLOPs/byte

For `C[N] = A[N] + B[N]`:

| Metric | Value |
|--------|-------|
| FLOPs | `N` |
| Bytes from DRAM | `3 * N * sizeof(dtype)` (2 reads + 1 write) |
| Arithmetic intensity | ~0.17 FLOPs/byte (binary), ~0.33 (unary) — **constant** |

The SFPU/FPU finishes in a fraction of the time it takes to load data. The bottleneck is purely DRAM bandwidth, regardless of problem size.

### Reduction ops: memory-bound, ~0.2 FLOPs/byte

For `C[M] = sum(A[M,N], axis=1)`:

| Metric | Value |
|--------|-------|
| FLOPs | `M * N` |
| Bytes from DRAM | `(M*N + M) * sizeof(dtype)` |
| Arithmetic intensity | ~0.5 FLOPs/byte — still constant |

Memory-bound, though partial-sum aggregation across cores may benefit from 1D multicast along the reduction axis.

## Why 4-role multicast hurts memory-bound ops

For eltwise/reduction ops, 4-role multicast is worse than simple 1D striping:

1. **No data reuse.** Each element is consumed exactly once. Multicasting data that will only be used once is pure overhead — you're adding a relay hop for no computational benefit.

2. **Wasted cores.** Edge cores become pure data movers. On a 10x12 grid (~118 usable cores), ~20 edge cores would be dedicated to relaying data that interior cores could have read themselves.

3. **Reduced aggregate DRAM bandwidth.** With 1D striping, all 118 cores read from DRAM in parallel across all 7 DRAM banks. With 4-role, only ~20 edge cores read DRAM — drastically reducing total bandwidth utilization.

4. **Synchronization overhead.** 4 semaphores per core, multicast barriers, and receiver wait loops add latency that is never hidden by compute (because compute is near-instant).

## Recommended architecture per op class

| Op class | Examples | Arithmetic intensity | Bottleneck | Architecture |
|----------|----------|---------------------|------------|--------------|
| Matmul-class | matmul, conv (im2col), attention QK^T/AV, linear layers, outer product | `O(dim)` — high | FPU compute | **4-role 2D multicast** |
| Binary eltwise | add, mul, sub | ~0.17 FLOPs/byte | DRAM bandwidth | 1D tile striping, no multicast, no semaphores |
| Unary eltwise | exp, log, sqrt, recip | ~0.33 FLOPs/byte | DRAM bandwidth | 1D tile striping, single input CB, SFPU ops |
| Reduction | sum, max | ~0.5 FLOPs/byte | DRAM bandwidth | 1D tile striping, maybe 1D multicast for partial aggregation |

These match the stubs in `blackhole-py/ops.py:573-575`:

```python
# class BinaryEltwiseProgram: ...  # ADD, MUL, SUB — no mcast, no sems, 1D tile striping
# class UnaryEltwiseProgram: ...   # EXP, LOG, SQRT, RECIP — single input CB, SFPU ops
# class ReductionProgram: ...      # SUM, MAX — accumulation loop, maybe 1D mcast
```

## Ops that decompose into matmul (use 4-role)

Any op expressible as a contraction over a shared dimension benefits from 4-role:

- **Dense matmul** — canonical case
- **Batched matmul** — outer loop over batch, same inner kernel
- **Linear / fully-connected** — matmul; bias add is a separate eltwise pass
- **Convolution via im2col** — reshape conv inputs to matrix form, then matmul
- **Attention (QK^T and score @ V)** — both are matmuls; softmax between them is eltwise
- **Outer product** — degenerate matmul with K=1
- **Batched dot product** — degenerate matmul with N=1

## Key insight

The question "should I use 4-role for everything to get faster DRAM streaming?" reverses the causality. 4-role doesn't give you faster DRAM streaming — it gives you **less** DRAM reading by exploiting data reuse via multicast. For ops with no data reuse, multicast is a slower, more complex way to move the same number of bytes. Maximum DRAM bandwidth comes from having every core read independently in parallel.
