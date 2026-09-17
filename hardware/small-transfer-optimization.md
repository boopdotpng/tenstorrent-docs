# Small-transfer latency in current blackhole-py

The old recommendation to add a resident transfer service has been superseded:
the inspected September 2026 runtime already has one. Its DRAM service occupies
Tensix tile `(14,4)` and uses BRISC/NCRISC firmware, separate from compute workers.
See [the runtime map](../build-and-dispatch/blackhole-py-runtime.md).

`Device._copy_dram` stages payloads in pinned host memory and submits `DramCopy`
commands for supported layouts. Selected bank-start/page-size cases fall back
to `_copy_dram_pcie`. Read [device.py](../../blackhole-py/device.py) for those
conditions. It no longer describes every copy by compiling an NCRISC worker
kernel through the historical `dram.py` API.

To improve small transfers, measure:

1. Host staging and command construction.
2. Queue submission and service response.
3. NoC read/write completion for the actual payload.
4. Host observation and final copy-out.

Keep one-transfer latency separate from batched throughput and from service-only
device cycles. Compare direct TLB access and the service with the same bytes,
bank mapping, completion guarantee, and warm/cold conditions. Include partial
pages and repeated staging-slot reuse in correctness checks.

The old per-stage microsecond estimates were tied to a retired runtime and
included assumptions rather than a current calibration. No new latency target
is asserted here. [Host-memory paths](pcie-dma-and-sysmem.md) distinguishes the
service from PCIe-controller DMA and DRISC GDDR DMA.
