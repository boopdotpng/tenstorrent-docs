# Hardware reference

Start with [architecture](architecture.md) and [test evidence](behavior-from-tests.md).
The [emulator reference](blackhole-emulator-specs/README.md) contains detailed
instruction/state models; firmware layouts inside it are software snapshots.
Use [current placement](grid-utilization.md) for the runtime-supported worker set.

## Documents

- [Blackhole architecture: engines, memory, and ownership](architecture.md)
- [Blackhole behavior demonstrated by tests](behavior-from-tests.md)
- [Coordinates, translation, and harvesting (Blackhole)](coordinates-and-translation.md)
- [ERISC Cores: Architecture, Memory Map, and Launching from NOC](erisc-cores-and-ethernet-launch.md)
- [Worker placement and service tiles](grid-utilization.md)
- [Packer L1 Accumulation: IEEE Float16 Hardware Bug](packer-l1-acc-float16-hardware-bug.md)
- [Blackhole P100A low-level PCIe + tt-kmd API spec (host-side)](pcie-and-tt-kmd.md)
- [Host memory, PCIe transfers, and sysmem](pcie-dma-and-sysmem.md)
- [Blackhole Hardware Performance Counters](performance-counters.md)
- [Small-transfer latency in current blackhole-py](small-transfer-optimization.md)
- [Tensix Compute Units: FPU and SFPU Reference](tensix-compute-units.md)
- [Blackhole (P100a) tile write addresses for pure-python bring-up](tile-addresses-and-l1-map.md)
- [tinygrad AMD DMA vs Blackhole host memory](tinygrad-amd-dma-vs-blackhole-host-memory.md)
