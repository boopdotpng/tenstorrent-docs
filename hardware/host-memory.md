# Host memory and transfers

Scope: the September 17 local blackhole-py implementation. The low-level
[PCIe/tt-kmd reference](pcie-and-tt-kmd.md) describes register and driver details;
this guide explains which paths the runtime uses.

## The two host interfaces

[pcie.py](../../blackhole-py/pcie.py) provides two different mappings:

| Interface | Address the caller uses | Purpose |
|---|---|---|
| `TLBWindow` | Tile coordinate plus tile-local address | CPU access through a retargetable PCIe aperture |
| `Sysmem` | Driver-returned `noc_address` plus offset | Device NoC access to pinned host RAM |

`Sysmem` allocates host pages and pins them with `PinPages` using the NoC-DMA
flag. The returned NoC address is not a CPU virtual pointer. Keep the mapping
alive until all device accesses finish. `TLBWindow` allocates a driver TLB slot,
maps its aperture, and retargets it with `ConfigureTlb`.

## DRAM copy path

[Device._copy_dram](../../blackhole-py/device.py) stages payloads in pinned host
memory and submits `DramCopy` commands to resident BRISC/NCRISC transfer firmware
on `(14,4)`. This service already exists; a new resident transfer kernel is not
needed just to avoid compiling one per copy. Selected bank-start/page-size
combinations use `_copy_dram_pcie` instead. Read the implementation for the
routing conditions rather than assuming all layouts take the same path.

After a device-to-host transfer completes, CPU readback accesses local RAM.
A CPU read through a device BAR instead waits for PCIe read completions. Compare
these paths using the same bytes and completion guarantee.

## Distinguish the engines

| Mechanism | What moves |
|---|---|
| Host TLB access | CPU loads/stores to a selected NoC endpoint |
| Resident transfer service | NoC traffic between mapped host memory and DRAM |
| PCIe-controller DMA | Transfers supported by that controller's own API |
| DRISC GDDR DMA | DRAM-bank storage and DRISC L1 |
| Tensix XMOV/TDMA | Local tile/configuration movement |

An unsupported direction in one DMA API does not establish that Blackhole lacks
all PCIe DMA hardware. A controller register map also does not establish that
blackhole-py uses it. The [DRISC reports](../microbenching/docs/tensix/drisc-gddr-dma.md)
and [local mover model](blackhole-emulator-specs/xmov-and-tdma-mover.md) describe
other paths.

## Measure the boundary you intend to improve

For a small copy, separate host staging, command construction/submission,
service response, payload completion, and final copy-out. For a large copy,
report sustained throughput and the number of outstanding transfers. Record
size, direction, page/bank layout, host mapping, PCIe link, warmup, and whether
staging is timed. Include partial pages and staging-slot reuse in correctness
checks. Old per-stage microsecond estimates from retired runtimes are not a
current calibration.

## Porting the host interface

A generic BAR mapping plus a list of DMA-visible host pages is not a drop-in
implementation of this runtime's interface. A port must supply equivalent TLB
retargeting and device-visible host-address semantics, plus lifetime and
completion guarantees. It may implement those differently from Linux tt-kmd.

The earlier AMD/DriverKit comparison cited retired `hw.py` and `dram.py` paths.
The useful distinction remains: a GPU runtime that programs its own virtual
memory can consume generic DMA pages, while this runtime hands driver-provided
NoC addresses to device firmware. A port must bridge that difference explicitly.
