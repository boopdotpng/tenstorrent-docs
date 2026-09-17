# Emulator models

Source-derived models for Blackhole hardware and the recorded firmware ABI.
These are not an independently validated emulator. Use the ISA viewer for
per-instruction test assertions and timing evidence, and the
[current runtime](../../build-and-dispatch/blackhole-py-runtime.md) for
blackhole-py software allocations and launch behavior.

Frontend, synchronization, scalar/configuration, boot state, topology, and
network chapters combine related former pages. Large pack/unpack and arithmetic
models remain separate so each chapter has a coherent subject.

- [Blackhole Tensix Tile Address Space](address-space.md)
- [Emulator boot state and firmware memory](boot-state.md)
- [Circular Buffers and Tile Headers](circular-buffers.md)
- [Data Types and Format Conversions](data-types-and-conversions.md)
- [Dest, SrcA, and SrcB Register Files](dest-srca-srcb-registers.md)
- [DRAM and PCIe Endpoint Emulator Specification (Blackhole)](dram.md)
- [FPU (Matrix Unit) Operations](fpu-operations.md)
- [Tensix frontend: issue, expansion, and scheduling](frontend.md)
- [NoC interfaces, atomics, and streams](network.md)
- [PACR — Packer Data Path Specification (Blackhole)](pack-data-path.md)
- [Pack/Unpack Configuration Registers](pack-unpack-registers.md)
- [RWC and Addressing — Blackhole Tensix Coprocessor](rwc-and-addressing.md)
- [Scalar and configuration instructions](scalar-and-config.md)
- [SFPLOADMACRO and SFPTRANSP](sfploadmacro-and-sfptransp.md)
- [Vector Unit (SFPU) Operations](sfpu-operations.md)
- [Specialty FPU (Matrix Unit) Operations](specialty-fpu-operations.md)
- [Tensix synchronization: waits, semaphores, and mutexes](synchronization.md)
- [Emulator topology and coordinate translation](topology.md)
- [Unpack Data Path](unpack-data-path.md)
- [XMOV Instruction and TDMA Mover](xmov-and-tdma-mover.md)
