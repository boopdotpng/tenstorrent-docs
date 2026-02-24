# Grid utilization: 10×11, column 14, and the notch problem

Analysis of Blackhole P100A's Tensix grid shape for matmul workloads, why column 14 can't participate in 2D multicast matmul, and performance implications.

## Physical grid layout

The full Tensix grid is **12 columns × 10 rows = 120 cores**:

| Bank | NOC X columns | NOC Y rows |
|------|---------------|------------|
| West | 1, 2, 3, 4, 5, 6, 7 | 2..11 |
| East | 10, 11, 12, 13, 14 | 2..11 |

Gap at x=8, x=9 (DRAM/PCIe — not Tensix).

### Fast dispatch steals 2 cores from column 14

| Core | Role |
|------|------|
| (14, 2) | CQ prefetch (BRISC, NOC0) |
| (14, 3) | CQ dispatch (BRISC+NCRISC, NOC1) |

Dispatchable grid: **118 cores**. Column 14 has only 8 usable cores at y=4..11.

```
        col1  col2  ...  col13  col14
y=2  [  ✓     ✓    ...    ✓     ██  ]  ← prefetch
y=3  [  ✓     ✓    ...    ✓     ██  ]  ← dispatch
y=4  [  ✓     ✓    ...    ✓     ✓   ]
y=5  [  ✓     ✓    ...    ✓     ✓   ]
...
y=11 [  ✓     ✓    ...    ✓     ✓   ]
```

The matmul uses a **10×11 = 110 core** rectangular subgrid (columns 1-13, rows y=2..11), leaving 8 column-14 cores idle.

## Why column 14 can't join the 2D multicast matmul

### Multicast rectangles avoid dispatch cores — that part is fine

**in0 (row-wise, NOC0):** For rows y=4..11, extending the east rectangle from `x=10..13` to `x=10..14` is safe. Dispatch cores at (14,2) and (14,3) are at different y values — never hit.

**in1 (column-wise, NOC1):** Column 14's sender at (14,4) multicasts to `y=5..11`. Rectangle covers y=5..11 only — never touches y=2 or y=3.

### The real constraint: 2D multicast requires a rectangular grid

The two invariants for 2D multicast matmul:
1. All cores in the same **row** process the same M tile range (they receive identical in0 multicast)
2. All cores in the same **column** process the same N tile range (they receive identical in1 multicast)

With column 14 active at y=4..11 but missing at y=2..3, the output region `(M rows 0-1) × (column 14's N strip)` has **no core to compute it**. The grid has a notch, and no assignment of tiles can fill it without breaking one of the multicast invariants.

### Workarounds considered and rejected

**Variable N-width per row (rows 2,3 cover more N):**
Rows 2,3 partition Nt across 11 columns; rows 4..11 across 12. Fully covers the output, but cores in the same column now process different N ranges → breaks in1 multicast. Could fix by having rows 2,3 skip in1 multicast and read from DRAM directly, but 22 cores lose multicast benefit for 8 extra compute cores. Not worth it.

**Column 13+14 share one N strip:**
Column 13 handles rows 0-1, column 14 handles rows 2-9, same N range. But in1 multicast across x=13..14 hits (14,2) and (14,3). Splitting into sub-rectangles creates asymmetric dataflow. Very messy for marginal gain.

**Column 14 as independent mini-grid:**
Gets in0 for free (extend row multicast), reads its own in1 from DRAM. But the notch tiles (M rows 0-1 × column 14's N) still need someone to compute them. Assigning extra M work to column 14 breaks row-alignment. Dead end.

## Performance cost of the 10×11 grid

The 8 idle cores represent **6.8% waste** (8/118). This is the fixed cost of fast dispatch on a 10×14 Tensix grid.

For slow dispatch (`TT_USB=1`), all 120 cores are available as a clean **10×12 rectangle** — no notch, no idle cores. But slow dispatch overhead (per-core TLB window opens + PCIe writes) far exceeds the compute gain from 10 extra cores.

## Uneven tile distribution on the 10×11 grid

For matrices where M or N isn't divisible by the grid dimensions, tiles can be distributed unevenly across the grid. This keeps all 110 cores active.

### Example: 4096×4096 matmul

```
Mt = 128 tiles    128 = 10×12 + 8  →  8 rows get 13 tiles, 2 rows get 12
Nt = 128 tiles    128 = 11×11 + 7  →  7 cols get 12 tiles, 4 cols get 11
```

Slowest core: 13 × 12 = 156 output tiles. Ideal uniform: 128×128/110 = 149.1 tiles.

**Grid efficiency: 149.1 / 156 ≈ 95.6%** — only ~4.4% waste from uneven distribution.

### Worst-case bound

The maximum waste from uneven distribution is bounded by `1/NUM_ROWS + 1/NUM_COLS = 1/10 + 1/11 ≈ 19%`. This worst case only occurs at the smallest dimensions where `remainder/quotient` is maximized. For any reasonably large matrix, efficiency converges to ~100% quickly.

### Dimension constraints

For the grid to be fully utilized (all 110 cores active):
- M ≥ 10 × 32 = 320 (at least 1 tile per row)
- N ≥ 11 × 32 = 352 (at least 1 tile per column)

Below these thresholds, the grid must shrink (use fewer rows or columns), and idle cores are unavoidable.

For peak performance (current `matmul_peak.py`), dimensions are chosen so tiles divide evenly:
- M must be divisible by 10 × 32 = 320
- N must be divisible by 11 × 32 = 352
- K must be divisible by 32 (and ideally by `IN0_BLOCK_W × 32`)

The peak example uses M=5120, K=4096, N=5632 → 16 tiles per core in each dimension.
