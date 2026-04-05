# Tenstorrent Blackhole Documentation

Unofficial documentation for the Tenstorrent Blackhole P100A / P150 AI accelerator, built from reverse-engineering, disassembly, and hands-on experimentation. Covers hardware architecture, kernel programming, the build/dispatch pipeline, firmware, and multi-chip operation.

Most of this was written by Codex or Claude. The `human/` folder is explicitly human-authored.

Quick bash script to clone all relevant repos: [here](https://gist.github.com/boopdotpng/4577ad1106d903d1566416823dee6140).

## New here?

Start with **[intro.md](intro.md)** — a self-contained introduction to the Blackhole chip, how it computes, and how to run your first program with [blackhole-py](https://github.com/boopdotpng/blackhole-py).

## Reading order

After the intro, go deeper:

1. `hardware/architecture.md` — chip architecture (NoC, Tensix tiles, RISC-V cores, L1, memory map)
2. `matmul/fast-matmul-eli5.md` — how computation works (3-kernel model, matrix engine, multicast)
3. `kernel-dev/sfpi-and-kernel-dev.md` — how to write a kernel (SFPI ops, dst_reg, working examples)
4. `kernel-dev/dataflow-and-cbs.md` — how data moves on-chip (CB semantics, reader/writer patterns)
5. `build-and-dispatch/kernel-build-and-cache.md` — how kernels get built (JIT pipeline, cache, toolchain)
6. `build-and-dispatch/dispatch-modes.md` — how they get to the chip (fast vs slow dispatch)
7. `firmware/firmware-upload-sequence.md` — how the chip boots (reset, firmware segments, GO messages)
8. `multi-chip/multi-host-and-remote-card-architecture.md` — scaling beyond one card

## Folder layout

| Folder | Contents |
|--------|----------|
| `hardware/` | Chip architecture, coordinate systems, PCIe, ERISC, grid utilization, performance counters, known hardware bugs |
| `kernel-dev/` | SFPI/LLK programming, compute pipeline, CBs/dataflow, tile layout, kernel fusion |
| `build-and-dispatch/` | Kernel compilation, loading ABI, dispatch pipeline, CQ protocol, debugging |
| `firmware/` | Firmware architecture, upload sequence, build system |
| `matmul/` | Matrix multiply deep dives (ELI5 through peak performance) |
| `multi-chip/` | Multi-host architecture, TT-Fabric, topology, data-parallel training |
| `llk-sfpi/` | ISA analysis, instruction usage statistics |
| `disasms/` | Raw RISC-V objdump artifacts |
| `human/` | Human-authored notes (read-only) |

## Related repos

| Repo | What it is |
|------|-----------|
| [blackhole-py](https://github.com/boopdotpng/blackhole-py) | Minimal Python driver — compiles and dispatches kernels directly, no TT-Metal. Library docs live there. |
| [tt-metal](https://github.com/tenstorrent/tt-metal) | Official Tenstorrent software stack (TT-Metalium + TT-NN) |
| [tt-llk](https://github.com/tenstorrent/tt-llk) | Low-Level Kernel library (header-only C++ compute primitives) |
| [sfpi](https://github.com/tenstorrent/sfpi) | SFPU compiler toolchain (modified GCC/binutils for Tensix RISC-V) |
| [tt-isa-documentation](https://github.com/tenstorrent/tt-isa-documentation) | Official Blackhole A0 ISA reference |
| [luwen](https://github.com/tenstorrent/luwen) | Rust user-mode hardware access library |
| [tt-kmd](https://github.com/tenstorrent/tt-kmd) | Linux kernel-mode driver |
| [tt-smi](https://github.com/tenstorrent/tt-smi) | System management interface (telemetry, resets) |

## Motivation

The goal is to write a [tinygrad](https://github.com/tinygrad/tinygrad) backend for Tenstorrent cards (Blackhole first). These docs exist to remove as many layers of abstraction as possible from the Tenstorrent stack.

## Current software assessment

- `ttnn` seems largely unfinished (it doesn't support f16 even though tt-metal does)
- the build process hardcodes clang-17 everywhere -- in tt-metal this is particularly annoying to change
- even `tt-metal` is an abstraction layer over a dozen other components. you can see why all the layers above tt-metal barely work, it's because of the number of abstractions and APIs stacked on top of each other.
- `tt-llk` is not the right approach. it makes kernels really inflexible; to write a relu kernel that sets the output value to 3 instead of 1, you have to write SFPI. when the kernel becomes even slightly weird or uncommon, tt-llk is unusable. so why even bother? just write all your compute kernels in SFPU C++ (lowered by the compiler into risc-v instructions the tensix coprocessor can run). importantly, you cannot really generate kernels that use tt-llk using a compiler. take a tinygrad Op graph, for example. i think it's way easier to lower those into SFPU ops than trying to pattern match them with tt-llk kernels *and* SFPU ops (since inevitably your kernel will be too unique for tt-llk).
- the three kernel model is extremely inconvenient. it could be the case that you can combine them, or that you can run multiple kernels on the same data without having to run dataflow kernels, but i'm not sure yet.
- there is also the pending question of what `binop_with_scalar_tile_init()` and friends do. if it truly limits the SFPU ops you can run in your kernel, then the possibility of kernel fusion goes down drastically.
