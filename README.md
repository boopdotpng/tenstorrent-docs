# tenstorrent documentation

documentation for the tenstorrent blackhole p100a. most of this has been written by Codex or Claude, but the human folder is explicitly my own writing and documentation.

Quick bash script to clone all relevant repos is [here](https://gist.github.com/boopdotpng/4577ad1106d903d1566416823dee6140).

## objective

write a tinygrad backend for tenstorrent cards (blackhole first). The goal of these docs is to remove as many layers of abstraction as possible from the tenstorrent stack. The highest level I'm willing to read and use is tt-metal.

## suggested reading order

if you're learning how tenstorrent cards work from scratch:

1. `hardware/architecture.md` -- what is the chip (NoC, Tensix tiles, RISC-V cores, L1, memory map)
2. `matmul/fast-matmul-eli5.md` -- how computation works (ELI5: 3-kernel model, matrix engine, multicast)
3. `kernel-dev/sfpi-and-kernel-dev.md` -- how to write a kernel (SFPI ops, dst_reg, working examples)
4. `kernel-dev/dataflow-and-cbs.md` -- how data moves on-chip (CB semantics, reader/writer patterns)
5. `build-and-dispatch/kernel-build-and-cache.md` -- how kernels get built (JIT pipeline, cache, toolchain)
6. `build-and-dispatch/dispatch-modes.md` -- how they get to the chip (fast vs slow dispatch)
7. `firmware/firmware-upload-sequence.md` -- how the chip boots (reset, firmware segments, GO messages)
8. `multi-chip/multi-host-and-remote-card-architecture.md` -- scaling beyond one card

## folder layout

- `hardware/` -- chip architecture, coordinate systems, PCIe, ERISC, grid utilization
- `kernel-dev/` -- SFPI/LLK programming, compute pipeline, CBs/dataflow, tile layout, kernel fusion
- `build-and-dispatch/` -- kernel compilation, loading ABI, dispatch pipeline, CQ protocol, debugging
- `firmware/` -- firmware architecture, upload sequence, build system
- `matmul/` -- matrix multiply deep dives (ELI5 through peak performance analysis)
- `multi-chip/` -- multi-host architecture, TT-Fabric, topology, data-parallel training
- `tinygrad/` -- tinygrad TT backend design, gap analyses, test progression
- `disasms/` -- raw RISC-V objdump artifacts
- `human/` -- human-authored notes (read-only)

## current software assessment

- `ttnn` seems largely unfinished (it doesn't support f16 even though tt-metal does)
- the build process hardcodes clang-17 everywhere -- in tt-metal this is particularly annoying to change
- even `tt-metal` is an abstraction layer over a dozen other components. you can see why all the layers above tt-metal barely work, it's because of the number of abstractions and APIs stacked on top of each other.
- `tt-llk` is not the right approach. it makes kernels really inflexible; to write a relu kernel that sets the output value to 3 instead of 1, you have to write SFPI. when the kernel becomes even slightly weird or uncommon, tt-llk is unusable. so why even bother? just write all your compute kernels in SFPU C++ (lowered by the compiler into risc-v instructions the tensix coprocessor can run). importantly, you cannot really generate kernels that use tt-llk using a compiler. take a tinygrad Op graph, for example. i think it's way easier to lower those into SFPU ops than trying to pattern match them with tt-llk kernels *and* SFPU ops (since inevitably your kernel will be too unique for tt-llk).
- the three kernel model is extremely inconvenient. it could be the case that you can combine them, or that you can run multiple kernels on the same data without having to run dataflow kernels, but i'm not sure yet.
- there is also the pending question of what `binop_with_scalar_tile_init()` and friends do. if it truly limits the SFPU ops you can run in your kernel, then the possibility of kernel fusion goes down drastically.
