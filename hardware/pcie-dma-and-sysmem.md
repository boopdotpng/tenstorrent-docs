# Host memory, PCIe transfers, and sysmem

“DMA” refers to several paths in these notes. Keep the initiating engine, source,
destination, and completion event explicit. Current blackhole-py uses pinned
host memory and NoC transfers through its resident service firmware; this is
separate from a PCIe-controller DMA API and from DRISC GDDR DMA.

## Current blackhole-py path

[pcie.py](../../blackhole-py/pcie.py) opens a tt-kmd device. `Sysmem` maps anonymous
host memory and calls `PinPages` with the NoC-DMA flag. The driver returns a
`noc_address`; use it rather than deriving an address from a CPU pointer or
hardcoding an old hugepage/iATU layout.

[Device._copy_dram](../../blackhole-py/device.py) uses a host staging region and
`DramCopy` commands for its supported page/bank layouts. The DRAM service runs
on a reserved Tensix tile. Some bank-start/page-alignment cases use the direct
PCIe/TLB fallback. Follow the implementation for the current routing criteria.

After the device writes to pinned host memory and reports completion, the CPU
reads local RAM. A direct CPU read through a device BAR instead requires PCIe
read completions. These have different latency and throughput behavior, but
old observed GB/s numbers are not universal hardware constants.

## Distinguish these mechanisms

| Mechanism | What it connects | Reference |
|---|---|---|
| Host TLB window | CPU-visible aperture to a chosen tile/address | `TLBWindow` in pcie.py |
| NoC access to sysmem | Device NoC traffic to driver-mapped host pages | `Sysmem`, resident transfer firmware |
| PCIe-controller DMA | A separate controller/API-specific transfer path | TT-UMD's Blackhole DMA implementation |
| DRISC GDDR DMA | DRAM bank storage and its DRISC L1 | [DRISC microbench archive](../microbenching/docs/tensix/drisc-gddr-dma.md) |
| Tensix local mover | Local tile/configuration movement | [XMOV/TDMA reference](blackhole-emulator-specs/xmov-and-tdma-mover.md) |

The older statement “Blackhole has no PCIe DMA engine” incorrectly generalized
from an unsupported API direction. An API throwing for D2H does not prove the
absence of all controller DMA hardware. Conversely, a controller register map
does not prove that current blackhole-py uses that path.

## Performance measurements need boundaries

State transfer size, page/bank layout, direction, mapping mode, host placement,
PCIe link, and whether timing includes staging copies and completion. Compare
small-transfer latency separately from large-transfer throughput. See
[small transfers](small-transfer-optimization.md) and the
[current runtime](../build-and-dispatch/blackhole-py-runtime.md).
