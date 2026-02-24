# Tinygrad port: runtime gap analysis and priority plan

Assessment of blackhole-py's readiness for a tinygrad backend port, what's done, what's missing, and build order.

## Runtime mapping to tinygrad's Compiled model

| Tinygrad piece | blackhole-py equivalent | Status |
|---|---|---|
| `Allocator._alloc` | `DramAllocator.alloc` | Done (needs `_free`) |
| `Allocator._copyin` | `dram.write` (auto-tilizes) | Done |
| `Allocator._copyout` | `dram.read` (auto-untilizes) | Done |
| `Compiler` | `codegen.Compiler` (riscv-tt-elf-g++) | Done |
| `Program.__call__` | `device.queue` + `device.run` | Done |
| `Device` | `Device()` (fast/slow dispatch) | Done |
| `Renderer` | **Does not exist** | The main work |

The runtime plumbing is solid. The gap is the renderer and surrounding infrastructure.

## The renderer is three things, not one

Tinygrad normally emits one kernel per op. TT needs three cooperating kernels:

```
Reader (NCRISC)  →  CB  →  Compute (TRISC)  →  CB  →  Writer (BRISC)
  DRAM→L1 tiles         SFPI/FPU on tiles           L1 tiles→DRAM
```

The renderer must decompose a single UOp list (scalar loop nests with RANGE/LOAD/ADD/STORE) into this trio. The UOps have no concept of tiles, CBs, or NOC.

## Approach: template renderer

Don't attempt general-purpose code generation. Pattern-match the UOp graph and select from fixed kernel templates.

### Phase 1 — Elementwise (SFPI)

```
fill:    0-in → 1-out    (SFPLOAD const, SFPSTORE)
unary:   1-in → 1-out    (relu, exp, neg, cast, ...)
binary:  2-in → 1-out    (add, mul, sub, ...)
ternary: 3-in → 1-out    (where/select)
```

Each template: fixed reader/writer kernel (parameterized by tile count + buffer addrs) plus a compute kernel where only the SFPI body varies. The renderer's job is: identify op pattern → pick template → fill in SFPI op.

Reader/writer kernels are boilerplate — parameterized by CB IDs, data format, tile count, per-core tile ranges. Compute kernel follows the standard pattern:
1. `copy_tile` inputs to Dst
2. SFPI loop over `dst_reg[0..31]` (+32 stride for second operand)
3. `pack_tile` to output CB

### Phase 2 — Matmul (FPU)

Wrap the matmul auto-generator (see `blackhole/matmul-autogen-design.md`) as a template. Given (M, K, N), produce the full `Program` with 2D multicast, uneven tile distribution, CB sizing. The renderer detects a matmul-shaped reduce or `WMMA` UOp and dispatches here.

### Phase 3 — Reductions

Softmax, layernorm, etc. Need custom dataflow (partial reduce across tiles, then broadcast). Harder templates but finite set. Key ops: row-reduce-sum, row-reduce-max, followed by elementwise epilogue (exp, reciprocal, multiply).

## Non-renderer gaps

### 1. Allocator needs `_free`

Current `DramAllocator` is bump-only. Tinygrad frees intermediates aggressively. Without free, OOM on anything beyond toy models.

Fix: free-list on top of the bump allocator. Small task.

### 2. Non-32-aligned shapes

Tinygrad will produce shapes like `(batch, 50257)`. 50257 % 32 ≠ 0. Strategy options:
- **Host-side pad** on `_copyin`, mask/unpad on `_copyout`
- **Reader kernel pad** (fill partial tiles with zeros)
- **Writer kernel mask** (discard padding elements on writeback)

Host-side pad is simplest for bringup. Device-side is better for performance later.

### 3. Graph rewrites for TT constraints

TT compute kernels handle ≤3-4 inputs (CB limit). Tinygrad can fuse chains with 10+ inputs.

Required rewrites:
- **Associative fan-in split:** if input count > `MAX_COMPUTE_INPUTS` (3), rewrite to balanced binary tree
- **Concat/stack chunking:** if tensor count > limit, chunk into batches and recursively concat

These are tinygrad graph-level rewrites, not renderer changes.

### 4. Views and strides

Tinygrad relies on zero-cost views (reshape, permute, expand). With tiled memory layout:
- `permute/transpose` → real relayout kernel
- `reshape` that reinterprets (H,W) → relayout
- arbitrary `shrink/slice` → mask/pad or copy unless tile-aligned

A small set of templated relayout kernels covers the common cases.

### 5. SFPU performance reality

The SFPU is ~64× slower than the FPU for bulk compute (see `blackhole/architecture.md`):

| Unit | Per core (1.35 GHz) | 110 cores |
|------|---------------------|-----------|
| FPU (matmul) | 5.53 TFLOP/s | 608 TFLOP/s peak, ~175 sustained |
| SFPU (with load/store) | ~0.029 TFLOP/s | ~3.2 TFLOP/s |

For standalone elementwise ops, the chip delivers ~3 TFLOP/s. This is acceptable when:
- The op is memory-bound anyway (layernorm on large hidden dims)
- The SFPU work is fused into a matmul epilogue (runs on DST registers, no L1 round-trip)

Not acceptable when the op is compute-heavy and standalone (e.g., large softmax with exp+reduce+div).

Fusion strategy: when the scheduler produces `matmul → activation`, emit a single fused kernel where the SFPU epilogue runs between matmul accumulation and pack. The kernel-fusion doc (`llk-sfpi/kernel-fusion.md`) documents the pattern.

## Build order (priority sequence)

| Step | What | Why | Effort |
|------|------|-----|--------|
| 1 | Allocator with `_free` | Unblocks everything beyond toy models | Small |
| 2 | fill/unary/binary templates | Proves full pipeline: renderer → compiler → dispatch → verify | Medium |
| 3 | `test_ops.py` passing for elementwise | Correctness gate | Medium |
| 4 | Non-32-aligned padding | Unlocks real model shapes | Small |
| 5 | Matmul auto-generator + template | Unlocks real performance | Large |
| 6 | Reduction templates | softmax, layernorm | Medium |
| 7 | View/relayout kernels | Unlocks real model graphs | Medium |
| 8 | Graph rewrites (fan-in split) | Handles high-arity fused kernels | Small |
| 9 | Matmul+SFPU fusion | Fused matmul+activation for perf | Medium |

Steps 1-3 prove the architecture. Step 5 delivers performance. Steps 6-9 are the long tail for real models.

## Effort estimate

The renderer is ~40% of total work. The remaining 60% is surrounding infrastructure: allocator, tilize boundary, shape padding, graph rewrites, view handling. Much of this only surfaces when running real tinygrad test suites.
