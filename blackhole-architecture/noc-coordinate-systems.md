# Blackhole (P100a) NoC coordinate systems (why `(16, 2)` is valid)

On Blackhole, you will see multiple coordinate systems in software:

- **NOC0 / physical**: the chip’s full NoC grid. For Blackhole this is `x=0..16` and `y=0..11` (17×12).
- **TRANSLATED / virtual**: a compact “worker grid” view used by higher-level software (width depends on harvesting).
- **LOGICAL**: an even more abstract, harvesting-aware indexing over the translated view.

## Key facts for P100a

- `(16, 2)` **does exist** on Blackhole: it is a Tensix tile in the far-right Tensix column.
- Tensix tiles live at `y=2..11`.
- Tensix columns on Blackhole are `x ∈ {1..7, 10..16}` (columns `0` and `9` are DRAM, `8` is L2CPU/ARC-related).

## Why `(16, 2)` can look “out of range”

If you’re thinking in **translated** (virtual) worker-grid coordinates, the max `x` may be `15` (or less when harvested).
But the same core can have a **NOC0** coordinate of `x=16`.

Concrete example from tt-metal’s Blackhole coord-translation test:

- translated/top-right core: `(15, 2)`
- corresponding NOC0 coord: `(16, 2)`

So a failure talking to `(16, 2)` is not “suggesting a non-existent tile”; it usually means that tile/column is not responding (e.g. harvested/disabled, or the device is in a bad init state).

