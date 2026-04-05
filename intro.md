# Intro to Tenstorrent Blackhole

This is a practical introduction to the Tenstorrent Blackhole AI accelerator. By the end, you should understand what the chip is, how it computes, and how to run your first program on it using [blackhole-py](https://github.com/boopdotpng/blackhole-py).

## What is Blackhole?

Blackhole is a PCIe AI accelerator built around a 2D mesh of independent compute tiles connected by a Network-on-Chip (NoC). It is fundamentally different from a GPU.

**Key specs:**

| | P100A | P150 |
|---|---|---|
| Tensix compute tiles | 120 | 140 |
| GDDR6 memory | 28 GB (7 banks) | 32 GB (8 banks) |
| Ethernet (400 GbE) | 0 | 8 active |
| PCIe | 5.0 x16 | 5.0 x16 |
| Peak FP16 matmul (LoFi) | ~175 TFLOPS | ~700+ TFLOPS |

Both variants also have 4 L2CPU tiles (SiFive X280 RISC-V cores capable of running Linux), 2 PCIe tiles, and ARC management processors.

## How is it different from a GPU?

On a **GPU**, you write one kernel and run it across thousands of identical threads. The hardware handles scheduling. You think in warps, blocks, and shared memory.

On **Blackhole**, each Tensix tile is a self-contained mini-computer:

```
Tensix Tile:
├── L1 RAM: 1.5 MiB scratchpad (not a cache!)
├── 5 RISC-V cores
│   ├── BRISC: data movement (reader kernel)
│   ├── NCRISC: data movement (writer kernel)
│   └── TRISC 0/1/2: push instructions to the compute coprocessor
├── Tensix Coprocessor:
│   ├── Matrix Unit (FPU): 8x16 @ 16x16 matmul in one cycle
│   ├── Vector Unit (SFPU): 32-wide SIMD, full FP32
│   ├── Unpacker x2: L1 → register files
│   └── Packer x4: register files → L1
└── 2 NoC connections (one per direction)
```

You write **3 separate programs** that run simultaneously on different RISC-V cores and communicate through circular buffers in L1. This is a **dataflow** architecture, not thread parallelism.

## The Three-Kernel Model

Every operation on Blackhole follows the same pattern:

```
DRAM ──> [Reader] ──> CB ──> [Compute] ──> CB ──> [Writer] ──> DRAM
              ↑                                        ↑
         runs on BRISC                           runs on NCRISC
                              ↑
                      runs on TRISC 0/1/2
                      (pushes to Tensix coprocessor)
```

- **Reader kernel** (BRISC): fetches tiles from DRAM into circular buffers in L1 via NoC DMA
- **Compute kernel** (TRISC): unpacks data from CBs, runs math on the Tensix coprocessor, packs results back
- **Writer kernel** (NCRISC): writes results from L1 back to DRAM via NoC

Circular buffers (CBs) handle all synchronization — no explicit locks. The reader calls `cb_push_back()` when data is ready, compute calls `cb_wait_front()` to block until it arrives, and `cb_pop_front()` to release the slot.

## The Compute Pipeline

Inside the Tensix coprocessor, data flows through a fixed pipeline:

```
L1 → Unpacker → SrcA/SrcB registers → FPU or SFPU → Dst registers → Packer → L1
```

The three TRISC cores (T0, T1, T2) each control a stage:
- **T0 (Unpack thread)**: configures and triggers the unpacker
- **T1 (Math thread)**: issues FPU/SFPU instructions
- **T2 (Pack thread)**: configures and triggers the packer

They coordinate via hardware semaphores — T1 waits for T0 to fill SrcA/SrcB, T2 waits for T1 to produce results in Dst.

### FPU vs SFPU

The **FPU (Matrix Unit)** is a low-precision systolic array:
- One `MVMUL` instruction: `Dst[8,16] += SrcB[8,16] × SrcA[16,16]` — 4096 multiply-adds per cycle
- Inputs are 19-bit max (TF32). Outputs accumulate in Dst.
- A full 32x32 tile multiply takes 16 MVMULs.
- At 1.35 GHz, that's **5.4 TFLOPS per core**.

The **SFPU (Vector Unit)** is a 32-wide SIMD unit for element-wise ops:
- Full FP32 precision, general-purpose (relu, exp, sqrt, any scalar function)
- Operates directly on Dst registers — no L1 round-trip when fused into a matmul epilogue
- ~64x slower than FPU for raw throughput, but fine for memory-bound or fused ops

**Rule of thumb**: matmul → FPU. Everything else → SFPU. Fuse SFPU epilogues (bias, activation) into matmul compute kernels so they run on Dst registers for free.

## The Network-on-Chip (NoC)

All data movement happens over the NoC — there is no global shared memory.

- **Two independent NoCs**: NoC0 (right/down), NoC1 (left/up), forming a 2D torus
- **Bandwidth**: 64 bytes/cycle per NoC at 1.35 GHz (~172 GB/s per NoC)
- **Transaction types**: reads, writes (posted or non-posted), broadcasts (Tensix tiles only), 128-bit atomics
- **Max packet**: 16 KiB

Cores share data by explicitly sending it over the NoC. For matmul, one core reads a tile and **multicasts** it to an entire row or column of cores — this is what makes large matmuls efficient.

## Data Format: Tiles

Blackhole operates on **32x32 tiles** — not individual elements. Data must be converted from row-major to tile format ("tilized") before the chip can use it, and converted back ("untilized") for the host.

```
Row-major (host):          Tilized (device):
[a b c d e f ...]          tile(0,0) = 32x32 block from top-left
                           tile(0,1) = next 32 columns
                           ...
```

This is a real cost. Every input buffer must be tilized; every output must be untilized. The blackhole-py library handles this automatically.

## Memory Hierarchy

```
Host RAM (CPU)
    ↕ PCIe 5.0 x16
Sysmem (pinned host pages, IOMMU-mapped)
    ↕ NoC (via PCIe tile)
DRAM (28-32 GB GDDR6, 7-8 banks)
    ↕ NoC
L1 (1.5 MiB per tile, 120-140 tiles)
    ↕ direct access
Local Data RAM (4-8 KiB per RISC-V core)
```

- **L1 is a scratchpad, not a cache.** You control exactly what goes in and out.
- **DRAM is interleaved** across banks for bandwidth. Each 4 GiB region is mirrored on 3 tiles.
- **Sysmem** is host memory pinned via VFIO so the device can DMA to/from it. This requires IOMMU because Blackhole has no scatter-gather hardware.

## Getting Started with blackhole-py

[blackhole-py](https://github.com/boopdotpng/blackhole-py) is a minimal (~7.5k line) Python driver that compiles and dispatches RISC-V kernels directly — no TT-Metal required.

### Prerequisites

- Blackhole P100A or P150 card
- Linux with VFIO support (`modprobe vfio-pci`)
- Must unload the TT kernel driver first: `modprobe -r tenstorrent`
- Python 3.10+, numpy

### Setup

```sh
git clone https://github.com/boopdotpng/blackhole-py
cd blackhole-py
./setup-deps.sh          # downloads SFPI compiler + TT-Metal headers
./setup_python_cap.sh    # grants Python VFIO capabilities (prompts for sudo)
```

### Run an example

```sh
PYTHONPATH=. uv run examples/add1.py           # element-wise add 1
PYTHONPATH=. uv run examples/matmul_peak.py    # matmul benchmark
```

### What happens when you run a program

1. `device.py` opens the Blackhole card via VFIO, detects board variant (P100A/P150), maps PCIe BARs
2. `compiler.py` compiles your C++ kernels (reader/compute/writer) into flat RISC-V binaries using the SFPI toolchain
3. `dispatch.py` builds a launch message containing kernel binaries, CB configs, and runtime args
4. `cq.py` writes the launch message into the on-device command queue (fast dispatch) or directly via TLB writes (slow dispatch with `TT_USB=1`)
5. The firmware on each Tensix core picks up the launch message, loads the kernels, and executes them
6. Results are DMA'd back to host memory

### Dispatch modes

- **Fast dispatch** (default): uses on-device command queues managed by prefetch + dispatch firmware cores. Commands flow through PCIe → sysmem → prefetch core → dispatch core → worker cores.
- **Slow dispatch** (`TT_USB=1`): host writes directly to each core's L1 via TLB windows. Works over the UT3G USB-C adapter — no VFIO needed. Much slower but useful for debugging.

### Profiler

```sh
PYTHONPATH=. PROFILE=1 uv run examples/matmul_peak.py
```

Captures per-core, per-RISC cycle-level traces and serves a web UI at `localhost:8000`.

## Where to Go Next

Once you understand this page, follow the reading order in the [README](README.md):

1. `hardware/architecture.md` — full chip architecture details
2. `matmul/fast-matmul-eli5.md` — how matmul works (blocking, multicast, circular buffers)
3. `kernel-dev/sfpi-and-kernel-dev.md` — writing compute kernels
4. `kernel-dev/dataflow-and-cbs.md` — circular buffer semantics
5. `build-and-dispatch/kernel-build-and-cache.md` — how kernels get compiled
6. `build-and-dispatch/dispatch-modes.md` — fast vs slow dispatch
7. `firmware/firmware-upload-sequence.md` — how the chip boots

For blackhole-py library docs (compiler pipeline, firmware API, profiler integration), see the [blackhole-py docs](https://github.com/boopdotpng/blackhole-py/tree/main/docs).

## Glossary

| Term | Meaning |
|------|---------|
| **Tensix** | The compute tile — 5 RISC-V cores + coprocessor + 1.5 MiB L1 |
| **NoC** | Network-on-Chip — how tiles communicate (2 independent networks) |
| **L1** | 1.5 MiB scratchpad per Tensix tile (not a cache) |
| **CB** | Circular Buffer — lock-free queue in L1 for inter-kernel communication |
| **FPU** | Matrix Unit — low-precision systolic array for matmul |
| **SFPU** | Vector Unit — 32-wide FP32 SIMD for element-wise ops |
| **Dst** | Destination register file — holds compute results between FPU/SFPU and packer |
| **BRISC** | Baby RISC-V core for reader kernels and NoC orchestration |
| **NCRISC** | Baby RISC-V core for writer kernels |
| **TRISC** | Three Baby RISC-V cores (T0/T1/T2) that drive the Tensix coprocessor |
| **Tilize** | Convert row-major data to 32x32 tile format |
| **LLK** | Low-Level Kernel library — pre-built compute primitives (header-only C++) |
| **SFPI** | SFPU Programming Interface — the compiler toolchain for SFPU kernels |
| **Fast dispatch** | On-device command queues (prefetch + dispatch cores) |
| **Slow dispatch** | Host-driven TLB writes, works over USB |
| **VFIO** | Linux subsystem for userspace device access with IOMMU |
| **Sysmem** | Host memory pinned and IOMMU-mapped so the device can DMA to it |
