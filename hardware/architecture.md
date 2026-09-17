# Blackhole architecture: engines, memory, and ownership

A Tensix tile combines five RISC-V controllers, 1.5 MiB of L1 SRAM, two NoC
interfaces, and a coprocessor with unpack, matrix, vector, and pack engines.
Software arranges data placement and synchronization explicitly. Start with
[the introduction](../intro.md) for a worked data path and
[test evidence](behavior-from-tests.md) for the claims exercised on hardware.

## A tile is not one instruction stream

BRISC and NCRISC commonly manage NoC movement; three TRISCs feed three Tensix
instruction streams. Unpack, math, and pack are conventional assignments to
TRISC0, TRISC1, and TRISC2. They do not imply three independent copies of every
compute engine or a mandatory three-kernel API.

RISC instruction issue, Tensix instruction delivery, and engine completion are
different events. MOP and replay expand a short issued sequence into more work.
A controller reaching the next instruction does not prove a pack, NoC write,
or delayed SFPU operation has finished. Use the completion event for the engine
whose output will be consumed.

## Memory spaces

| Space | Purpose | Ownership to keep explicit |
|---|---|---|
| Host memory | Uploads, downloads, command queues | CPU mapping and device-visible NoC address are distinct |
| GDDR banks | Large tensor storage | Bank/page layout is chosen by the runtime |
| Tile L1 | Code, firmware state, data, CB storage | Shared within a tile; reserved regions depend on firmware |
| Controller local RAM | Stack and controller-private state | Its address view and capacity depend on the RISC role |
| SrcA / SrcB | Matrix operands | Valid state, bank selection, format, and source reuse |
| Dst | Matrix results, vector input/output, pack input | Format, address interpretation, and producer/consumer lifetime |
| SFPU LReg | Vector operands and intermediate values | Predication, aliasing, and delayed-operation hazards |

L1 spans `0x00000000..0x0017ffff`. The split between firmware, kernels, parameters,
and buffers is not a hardware constant. Use the active runtime's layout; the
[current runtime map](../build-and-dispatch/blackhole-py-runtime.md) points to
`firmware/consts.py`. The [address reference](blackhole-emulator-specs/address-space.md)
contains more MMIO detail and historical firmware partitions.

DRAM endpoints are access ports to banks, not extra copies of the advertised
memory. A bank exposed through multiple NoC endpoints still owns one storage
region. Software interleaving maps logical pages to banks and bank-local offsets.

## Compute paths

The matrix engine reads SrcA/SrcB and accumulates into Dst. In the ordinary
`MVMUL` shape, an 8×16 source block multiplies a 16×16 block, producing an 8×16
accumulation. That represents **2,048 multiply-accumulates**, or **4,096 FLOPs**
when multiply and add count separately, per such matrix operation. Precision
can require multiple fidelity phases. Do not multiply a LoFi issue ceiling by
clock and call it measured high-fidelity throughput.

The SFPU works on 32-lane vector registers, loading/storing Dst through
`SFPLOAD`/`SFPSTORE`. It supports floating-point and integer/bit operations with
instruction-specific semantics. FP32 storage does not make every operation
IEEE-equivalent to a CPU. The [compute-unit reference](tensix-compute-units.md)
and [manual](https://github.com/tenstorrent/tt-isa-documentation/tree/main/BlackholeA0/TensixTile/TensixCoprocessor)
provide the detailed modes.

Two unpackers transform L1 data into source registers or Dst; pack interfaces
write Dst data to L1. Format conversion, address generation, and some layout
transformations happen in these paths. A 32×32 face-tiled payload is a common
layout, not a requirement that all input arrays arrive host-tilized.
[Row-major matmul](../kernel-dev/row-major-matmul.md) demonstrates the distinction.

## NoC and host movement

Two NoCs connect tiles and memory endpoints, with opposite routing directions.
Coordinates must be interpreted in the relevant physical/translated and NoC0/1
space; see [coordinates](coordinates-and-translation.md). A multicast rectangle
must contain the intended endpoints, not just their logical ranks.

For a 64-byte-per-cycle path at 1.35 GHz, the arithmetic ceiling is **86.4 GB/s**.
Two equally capable independent paths sum to **172.8 GB/s** before protocol and
contention costs. The old claim of 172 GB/s for one such path was a factor-of-two
error. Neither number is measured all-chip or DRAM bandwidth. Clock, route,
packet size, NIU issue rate, arbitration, and endpoint capacity all matter.

NoC reads, writes, multicasts, and atomics have different completion semantics.
Posted writes do not offer the same acknowledgment contract as non-posted writes.
A buffer must not be reused merely because its transfer was issued. See the
[NoC reading guide](../microbenching/docs/noc/reading-guide.md) and recorded probes
for route and contention behavior.

The current host interface pins pages through tt-kmd and obtains a device-visible
NoC address; it uses TLB windows for direct tile access. That software path is
separate from a PCIe-controller DMA feature or DRISC GDDR DMA. See
[host-memory transfers](pcie-dma-and-sysmem.md).

## Synchronization is part of correctness

Circular buffers are software protocols over storage, pointers, and counters.
A producer reserves space, fills it, waits for the relevant transfer completion,
and publishes it. A consumer waits for availability, consumes the payload, and
releases storage only after dependent work is finished.

The coprocessor also has hardware semaphores and mutexes. In the tested semaphore
modes, post saturates at 15 and get floors at zero; the configured maximum is a
wait threshold. Mutex indices 0, 2, 3, and 4 are exercised by the conformance tests.
An instruction's block mask can stall a resource while allowing other work to
proceed. See [semaphores](blackhole-emulator-specs/semaphores.md),
[wait gates](blackhole-emulator-specs/stallwait-conditions.md), and
[the test-to-claim map](behavior-from-tests.md).

## Topology and performance limits

A chip floorplan, firmware-enabled resources, runtime-supported resources, and
workers assigned to a program are four different counts. The inspected
blackhole-py supports a 120-Tensix layout with three service tiles, leaving 117
workers. See [placement](grid-utilization.md) instead of assuming every P150
program has 140 workers.

Performance depends on the longest unfinished part of the schedule: input
movement, unpack, arithmetic, pack, output movement, or synchronization. Half-Dst
buffering and input double buffering can overlap work, but consume capacity.
FP32 Dst halves element capacity; its throughput cost is workload-dependent.
Use [precision guidance](../matmul/fp32-accumulation.md) and measurements with
matching configurations instead of a universal percentage penalty.
