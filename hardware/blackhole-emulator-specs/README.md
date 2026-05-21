# Blackhole Emulator Specs

Detailed emulator reference for Blackhole Tensix tiles, NoC, DRAM, firmware boot,
and Tensix coprocessor behavior. This folder is organized as topic-sized files
instead of one monolithic spec.

## Start Here

- [execution-model.md](execution-model.md) - top-level scheduler and host-side run loop.
- [device-grid.md](device-grid.md) - Blackhole grid topology and coordinate layout.
- [address-space.md](address-space.md) - per-tile memory map and L1 layout.
- [firmware-upload.md](firmware-upload.md) - firmware upload and core boot sequence.

## Core Tile Model

- [ldm-layouts.md](ldm-layouts.md) - per-core local data memory layout.
- [registers.md](registers.md) - tile control and debug registers.
- [instruction-push.md](instruction-push.md) - RISC-V to Tensix instruction push path.
- [tensix-coprocessor-pipeline.md](tensix-coprocessor-pipeline.md) - Tensix frontend/backend pipeline.
- [rwc-and-addressing.md](rwc-and-addressing.md) - RWC and addressing model.
- [mop-and-replay-expanders.md](mop-and-replay-expanders.md) - MOP and replay expansion.
- [stallwait-conditions.md](stallwait-conditions.md) - wait gates and synchronization conditions.

## Memory, NoC, and Streams

- [dram.md](dram.md) - DRAM and PCIe endpoint model.
- [niu.md](niu.md) - NoC interface unit model.
- [noc-atomics.md](noc-atomics.md) - NoC atomic operations.
- [logical-to-virtual-coordinates.md](logical-to-virtual-coordinates.md) - coordinate translation.
- [stream-registers.md](stream-registers.md) - stream and NoC overlay registers.
- [circular-buffers.md](circular-buffers.md) - circular buffer state and tile headers.

## Tensix Compute and Data Paths

- [dest-srca-srcb-registers.md](dest-srca-srcb-registers.md) - matrix register files.
- [data-types-and-conversions.md](data-types-and-conversions.md) - internal formats and conversions.
- [fpu-operations.md](fpu-operations.md) - matrix unit operations.
- [specialty-fpu-operations.md](specialty-fpu-operations.md) - specialty matrix operations.
- [sfpu-operations.md](sfpu-operations.md) - vector unit operations.
- [pack-unpack-registers.md](pack-unpack-registers.md) - pack/unpack configuration registers.
- [unpack-data-path.md](unpack-data-path.md) - unpacker data path.
- [pack-data-path.md](pack-data-path.md) - packer data path.

## Scalar, Config, and Synchronization

- [gpr-and-dma-instructions.md](gpr-and-dma-instructions.md) - Tensix GPRs, scalar unit, and DMA register instructions.
- [additional-scalar-unit-instructions.md](additional-scalar-unit-instructions.md) - extra scalar unit instructions.
- [config-sync-instructions.md](config-sync-instructions.md) - config and sync unit instructions.
- [sfploadmacro-and-sfptransp.md](sfploadmacro-and-sfptransp.md) - SFPLOADMACRO and SFPTRANSP.
- [xmov-and-tdma-mover.md](xmov-and-tdma-mover.md) - XMOV and TDMA mover.
- [semaphores.md](semaphores.md) - semaphore behavior.
- [mutexes.md](mutexes.md) - mutex behavior.
- [pcbufs.md](pcbufs.md) - PC buffer behavior.

## Implementation Notes Preserved From The Old Monolith

Implementation order:

1. Core infrastructure: RISC-V decoder/executor, L1 memory, tile glue, device grid, and memory map routing.
2. Tensix coprocessor: instruction FIFO, MOP/replay, sync unit, register files, FPU, SFPU, config unit, and scalar unit.
3. Memory subsystem: NoC fabric, NIU registers, sparse DRAM banks, circular buffers, streams, unpacker, and packer.
4. Integration: host interface, firmware boot sequence, dispatch completion, `add1.py`, and multi-core matmul.
5. Correctness: hardware bug modeling, fidelity phases, stochastic rounding, ADC, XMOV, and coordinate translation.

Testing strategy:

- Unit-test RISC-V instructions, Tensix opcodes, format conversions, and semaphore sequences.
- Run real firmware boot and simple kernels end to end.
- Compare emulator outputs and selected register state against real hardware.
