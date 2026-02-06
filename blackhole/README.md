# Blackhole (P100A) docs

This folder consolidates Blackhole-specific architecture, PCIe/tt-kmd, firmware, and coordinate translation notes.

Files:
- `architecture.md`: NoC + Tensix tile + coprocessor + programming model.
- `coordinates-and-translation.md`: physical/translated/logical coords, NOC1, harvesting, per-tile translation tables, DRAM bank translation tables.
- `pcie-and-tt-kmd.md`: BAR/TLB/IOCTL behavior, sysmem DMA, CQ host/device ABI, PCIe bandwidth notes.
- `fast-dispatch-abi.md`: fast-dispatch queue layout, alignments, compile-time defines, and packing details.
- `fast-dispatch-bugs.md`: blackhole-py fast-dispatch bug list.
- `fast-dispatch-host-bringup-notes.md`: host-side bring-up gotchas from tt-metal kernel sources.
- `tile-addresses-and-l1-map.md`: tile coords and Tensix L1 offsets used for kernel/CB/mailbox bring-up.
- `firmware.md`: core firmware lifecycle, reset sequencing, and fan control analysis.
