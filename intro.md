# Start here: programming Blackhole

Blackhole is an accelerator made of compute tiles connected by two networks on
chip (NoCs). Each Tensix tile has 1.5 MiB of explicitly managed L1 SRAM, five
RISC-V controllers, and compute engines for matrix and vector operations.
A kernel must arrange both the arithmetic and the movement of its operands.

This introduction follows the **September 17, 2026 local blackhole-py runtime**.
The [evidence guide](hardware/behavior-from-tests.md) identifies the source
snapshot, tests, recorded results, and limits of those results. TT-Metal/LLK
examples elsewhere in this repository use a different software interface.

## Follow one piece of data

A common matrix pipeline is:

```text
DRAM --NoC read--> L1 --unpack--> SrcA / SrcB
                                      |
                               matrix operations
                                      v
                                     Dst <--> SFPU vector registers
                                      |
                                     pack
                                      v
DRAM <--NoC write-- L1 <---------------+
```

The unpackers interpret the input format and layout. The matrix engine combines
source operands into Dst, the destination register file. The SFPU loads values
from Dst into vector registers, performs lane-wise work, and stores them back.
The packer writes results to L1, potentially converting their format. NoC
transfers move bytes between L1, other tiles, DRAM, and mapped host memory.
Some unpack modes write directly to Dst; not every computation uses SrcA/SrcB.

For an activation after matmul, keep the result in Dst and apply SFPU operations
before packing. That saves an intermediate memory round trip. The activation
still consumes instructions, engine time, and register capacity.

## Five controllers, several possible schedules

BRISC and NCRISC commonly manage data transfers. TRISC0, TRISC1, and TRISC2
commonly drive unpack, math, and pack respectively. These are useful roles,
not a requirement to write exactly three programs or to dedicate BRISC to reads.

TT-Metal compiles a compute source for three TRISC roles and supplies dataflow
kernels separately. Current blackhole-py can launch raw images for any of the
five controllers; `Program` fills omitted roles with firmware-return stubs.
Tests often initialize L1 from the host and launch only the controllers needed
for an isolated experiment. See the [runtime map](build-and-dispatch/blackhole-py-runtime.md).

Circular buffers track when L1 pages are available and when consumers have
released them. Hardware semaphores coordinate coprocessor work. NoC completion
waits establish when transferred data can be consumed or its source reused.
A published buffer counter alone does not finish an outstanding transfer.

## Layout and precision are part of the algorithm

A 32×32 tile is a common software unit. It is not the minimum size of every
hardware operation. The tests exercise partial transfers and other layouts.
A face-tiled 32×32 array consists of four 16×16 faces; merely grouping 1,024
row-major elements does not put them in this order.

Inputs do not always need a separate host tilization or device conversion pass.
The current matmul example reads row-major spans and gathers source panels
through unpacking. Its FP8 and BF16 paths use different unpack schedules.
See [row-major matmul](matmul/README.md#row-major-matmul).

Choose input precision, matrix fidelity, Dst accumulation precision, intermediate
spill precision, and final output precision separately. An FP32 output cannot
recover precision lost in BF16 intermediate spills. SFPU supports FP32 values,
but that does not imply every operation has CPU IEEE-754 behavior for NaNs,
subnormals, rounding, or fused arithmetic.

## Which cores can I use?

Use the runtime's discovered and supported topology. In the inspected
blackhole-py source, both supported P100A and P150 configurations expose 120
Tensix tiles. Three are reserved for services, leaving 117 workers. P100A uses
seven DRAM banks; the supported P150 configurations use eight.
These are runtime constraints, not a claim about every possible Blackhole SKU.
See [grid placement](hardware/topology.md).

## Start with a test

From the sibling `blackhole-py` checkout, use the shared workspace virtualenv:

```sh
cd ~/tenstorrent/blackhole-py
../.venv/bin/python -m pytest tests/isa/test_encoding.py -q
```

That command checks instruction encodings without accessing a card. Passing it
means the emitted words match the encoding expectations; it does not demonstrate
execution behavior.

For a small hardware example, reserve device 0 and run the packer accumulation
tests. The following form passes the command as one string to `tt-device-queue`:

```sh
tt-device-queue run --device 0 --cwd "$PWD" --timeout 120 -- \
  '../.venv/bin/python -m pytest tests/movement/packer/test_l1_accumulation.py --bh-hardware --bh-device=0 -q'
```

The tests initialize data, launch raw controller images, compare every output,
and check that adjacent memory was not overwritten. Read the test alongside
[the explanation of its hardware contract](hardware/behavior-from-tests.md).
Do not use pytest-xdist on one card. Without `--bh-hardware`, hardware tests skip.

Current blackhole-py uses `/dev/tenstorrent/<index>` through **tt-kmd**, with
pinned host pages and allocated TLB windows. Its README requires tt-kmd newer
than 2.9.0, Clang, and RISC-V binutils. Firmware is built from C on boot;
Python `Asm`/`ttko` emit worker instructions. Follow the
[checkout's README](../blackhole-py/README.md) for setup. The old VFIO setup
scripts, SFPI worker compiler, and `TT_USB=1` instructions are historical.

## Next steps

- [Hardware architecture](hardware/architecture.md): memory, engines, and synchronization.
- [Behavior demonstrated by tests](hardware/behavior-from-tests.md): assertions and gaps.
- [Current runtime](build-and-dispatch/blackhole-py-runtime.md): device access through completion.
- [Matmul](matmul/README.md#fast-matmul-eli5): blocking, reuse, and multicast.
- [Compiler maps](compiler-maps/README.md): source-guided compiler study.
