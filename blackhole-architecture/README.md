# BlackHole P100A Architecture (Split)

> **Focus**: Compute + DMA behavior for low-level TT-Metal/LLK kernel work.

## Overview

BlackHole is a 2D mesh accelerator:
- **140 Tensix tiles** (compute) - 120 available on p100, 140 on p150
- **2 NoCs** for data movement (independent directions)
- **24 DRAM tiles** - 32 GiB total (p100: 21 tiles/28 GiB enabled, p150: 24 tiles/32 GiB enabled); each 4 GiB region is mirrored on 3 tiles
- **4 L2CPU tiles** - 4x SiFive x280 each (16 cores total)
- **14 Ethernet tiles** - 400 GbE endpoints (0 on p100, 12 enabled on p150; 8 wired to QSFP-DD)
- **2 PCIe tiles** - PCIe 5.0 x16 host interface (1 active in current products)
- **ARC + Security tiles** - management processors (not used for customer workloads)

![NoC Layout](../../tt-isa-documentation/Diagrams/Out/NoC_BH_Layout.svg)

## Docs

- `boop-docs/blackhole-architecture/01_noc.md` (NoC data movement)
- `boop-docs/blackhole-architecture/02_tensix_tile.md` (tile anatomy + baby RISCVs)
- `boop-docs/blackhole-architecture/03_coprocessor.md` (Dst, SFPU, Matrix Unit, Unpack/Pack)
- `boop-docs/blackhole-architecture/04_programming_model.md` (execution model + scheduling)
- `boop-docs/tt-metal/tt-metal-notes.md` (CBs, tile data path, async DMA, matmul example, FP16 note)
- `boop-docs/blackhole-architecture/06_references.md` (stack layers, deltas vs Wormhole, doc map)
