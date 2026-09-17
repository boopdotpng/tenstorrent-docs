# Worker placement and service tiles

Scope: September 17, 2026 local blackhole-py. The authoritative runtime inputs
are [board_config and endpoint tables](../../blackhole-py/pcie.py), followed by
`Device.cores`. Do not infer a launchable grid from a product's advertised core
count or from an older benchmark.

## Supported runtime layout

Both the P100A and supported P150 configurations in this checkout require 120
firmware-enabled Tensix tiles. The runtime selects these translated NoC0 axes:

| Axis | Coordinates |
|---|---|
| Worker-capable columns | 1–7 and 10–14 |
| Rows | 2–11 |

These are runtime/translated coordinates, not a drawing of physical silicon.
The gap between column 7 and 10 must be respected by multicast construction.
See [coordinate translation](coordinates-and-translation.md).

Three of the 120 tiles run services:

| Coordinate | Service |
|---|---|
| `(14,2)` | CQ prefetch |
| `(14,3)` | CQ dispatch |
| `(14,4)` | DRAM transfer service on BRISC/NCRISC |

That leaves **117 worker tiles**. Column 14 contributes seven workers, at
rows 5–11. The older 118-worker figure belonged to a two-service runtime.
It is not the current `Device.cores` length. The supported P100A topology has
seven DRAM banks; the supported P150 topology has eight. Other enabled-core
counts are rejected by this implementation, even if the underlying SKU permits them.

## Why some matmuls use fewer workers

A simple 2D multicast schedule assigns one M range to each grid row and one N
range to each grid column. Every output region needs an owner at their
intersection. The service tiles make the worker set nonrectangular: blindly
using all 12 columns for all ten rows leaves three output intersections missing.

A 10-row × 11-column schedule excludes column 14 and uses 110 workers. A
7-row × 12-column schedule on rows 5–11 uses 84 workers. These are examples of
valid logical rectangles; NoC multicast may still need separate physical
rectangles around the column gap. A planner must also satisfy L1, Dst,
divisibility, operand-reuse, and synchronization constraints.

The remaining seven workers are not unusable hardware. Elementwise work can
partition tiles across all workers; matmul can use additional launches, separate
subgrids, or a different communication schedule. Whether that beats a regular
grid is a measurement question, not a fixed architectural waste percentage.

## Check a placement

1. Take available coordinates from the device instance.
2. Verify every proposed worker belongs to that set.
3. Assign every output block exactly once, including tails.
4. Construct multicast rectangles that exclude services and invalid endpoints.
5. Make sender/receiver counts agree with actual recipients.

For uneven tile counts, compute each worker's actual load. For a fixed grid with
`R` rows, `C` columns, `Mt` M tiles and `Nt` N tiles, the simple equal-block model
has efficiency
`Mt * Nt / (R * C * ceil(Mt/R) * ceil(Nt/C))` when all workers participate.
Small problems can leave many workers idle; there is no universal 19% imbalance
bound. Padding, K blocking, and nonuniform communication can further change timing.
