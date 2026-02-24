# Matmul auto-generator design

Given arbitrary (M, K, N), produce a full `Program` with correct per-core args, 2D multicast, and optimal tiling for the 10×11 grid.

## Inputs and outputs

```
Inputs:   (M, K, N), data format, math fidelity
Outputs:  grid dims, tile distribution per row/col,
          subblock sizes, IN0_BLOCK_W, CB page counts,
          compute kernel variants, DataflowLaunch groups,
          per-core runtime args
```

## Step 1 — Tile distribution

Distribute Mt and Nt tiles across rows and columns using `divmod`. First `r` cores get `q+1`, rest get `q`:

```python
def distribute(num_tiles, num_cores):
  q, r = divmod(num_tiles, num_cores)
  return [q + 1] * r + [q] * (num_cores - r)

per_row_m = distribute(Mt, NUM_ROWS)   # length 10
per_col_n = distribute(Nt, NUM_COLS)   # length 11
```

Multicast compatibility: all cores in a row share the same `per_core_m` (in0 multicast). All cores in a column share the same `per_core_n` (in1 multicast). This holds because the distribution is row-uniform and column-uniform.

## Step 2 — Subblock sizing

`OUT_SUBBLOCK_H` must divide both `ceil_m` and `floor_m`. Same for `OUT_SUBBLOCK_W` with N. Since consecutive integers are coprime, common divisors are limited:

```python
def find_subblock(big, small, max_sb=8):
  for s in range(max_sb, 0, -1):
    if big % s == 0 and small % s == 0:
      return s
  return 1
```

Additional constraint: `OUT_SUBBLOCK_H × OUT_SUBBLOCK_W ≤ DST_HALF_SIZE` (8 tiles for fp16 accum, 4 for fp32 accum). Search pairs to maximize the product.

## Step 3 — IN0_BLOCK_W and L1 budget

`IN0_BLOCK_W` controls the inner-loop blocking of K. Must divide Kt. Larger = fewer outer loop iterations = less overhead, but more L1 usage.

L1 budget for the worst-case core (largest `per_core_m × per_core_n`):

```
L1_BUDGET ≈ 1536 KiB - firmware/stack/mailbox overhead

CB0  = 2 × max_per_core_m × IN0_BLOCK_W × TILE_BYTES    (double-buffered in0)
CB1  = 2 × max_per_core_n × IN0_BLOCK_W × TILE_BYTES    (double-buffered in1)
CB16 = max_per_core_m × max_per_core_n × TILE_BYTES      (output accumulator)
CB24 = CB16                                                (L1 acc ping-pong)

total = CB0 + CB1 + CB16 + CB24 ≤ L1_BUDGET
```

Search downward from Kt to find the largest valid `IN0_BLOCK_W`.

## Step 4 — Compute kernel variants

The compute kernel bakes in constants (`in0_num_subblocks`, `in1_num_subblocks`, `in0_block_num_tiles`, etc.). With uneven distribution, up to 4 distinct (per_core_m, per_core_n) combos exist:

```
(ceil_m, ceil_n)     — most cores
(ceil_m, floor_n)    — some cores
(floor_m, ceil_n)    — some cores
(floor_m, floor_n)   — some cores
```

Compile up to 4 compute kernels. If either axis divides evenly, it collapses to fewer variants.

## Step 5 — DataflowLaunch grouping

The grouping key is `(reader_role, writer_role, compute_variant)`:

```python
groups = defaultdict(list)
for r in range(NUM_ROWS):
  for c in range(NUM_COLS):
    reader_role = "sender" if c == 0 else "recv"
    writer_role = "sender" if r == 0 else "recv"
    compute_key = (per_row_m[r], per_col_n[c])
    groups[(reader_role, writer_role, compute_key)].append(grid[r][c])
```

Cross-producting 4 sender/receiver roles with up to 4 compute variants gives up to 16 groups, but most will be empty. Typical count: 4-8.

## Step 6 — Per-core runtime args

Same structure as `matmul_peak.py`, parameterized by each core's position:

**Reader args** (in0 multicast):
- `in0_start_tile_id = sum(per_row_m[:row_idx]) * Kt` — prefix sum of M distribution
- `in0_block_h = per_row_m[row_idx]`
- Multicast rectangles: west/east split at x=8 gap, row-specific receiver lists

**Writer args** (in1 multicast + output write):
- `in1_start_tile_id = sum(per_col_n[:col_idx])` — prefix sum of N distribution
- `in1_block_w = per_col_n[col_idx]`
- `out_start_tile_id = sum(per_row_m[:row_idx]) * Nt + sum(per_col_n[:col_idx])`
- Multicast rectangle: sender at row 0, receivers at rows 1..9 in same column

## Step 7 — Small matrix fallback

If `Mt < NUM_ROWS` or `Nt < NUM_COLS`, shrink the grid:

```python
eff_rows = min(NUM_ROWS, Mt)
eff_cols = min(NUM_COLS, Nt)
```

Use the first `eff_rows × eff_cols` cores. Remaining cores sit idle. This is the only case where grid utilization drops significantly.

## Performance characteristics

| Scenario | Grid | Efficiency |
|----------|------|-----------|
| M, N divisible by grid dims | 10×11 | ~100% (current peak) |
| M=4096, N=4096 | 10×11 | ~95.6% |
| M=1024, N=1024 | 10×11 | ~91% |
| M=256, N=256 (8×8 tiles) | shrink to 8×8 | 64/110 = 58% cores used |
| M=32, N=32 (1×1 tile) | 1×1 | 1/110 = 0.9% |

The auto-generator handles all cases; the programmer doesn't need to worry about dimension constraints.

## Implementation priority

The auto-generator is a prerequisite for the tinygrad matmul template. It should be implemented as a standalone function in `blackhole-py` that takes (M, K, N) + config and returns a ready-to-dispatch `Program`. The tinygrad renderer then calls this function when it detects a matmul-shaped UOp pattern.
