# tenstorrent documentation

this is documentation for the tenstorrent blackhole p100a. most of this has been written by Codex orClaude, but the human folder is explicitly my own writing and documentation.

This will eventually cover all repos in tenstorrent-land, in greater detail the more I start digging into how the card works.

Quick bash script to clone all relevant repos is [here](https://gist.github.com/boopdotpng/4577ad1106d903d1566416823dee6140).

## objective

write a tinygrad backend for tenstorrent cards (blackhole first). The goal of these docs is to remove as many layers of abstraction as possible from the tenstorrent stack. The highest level I'm willing to read and use is tt-metal. 


## current software

The current tenstorrent software approach is not great (from an end user's perspective):

- `ttnn` seems largely unfinished (it doesn't support f16 even though tt-metal does) 
- the build process hardcodes clang-17 everywhere -- in tt-metal this is particularly annoying to change
- even `tt-metal` is an abstraction layer over a dozen other components. you can see why all the layers above tt-metal barely work, it's because of the number of abstractions and APIs stacked on top of each other. 
- `tt-llk` is not the right approach. it makes kernels really inflexible; to write a relu kernel that sets the output value to 3 instead of 1, you have to write SFPI. when the kernel becomes even slightly weird or uncommon, tt-llk is unusable. so why even bother? just write all your compute kernels in SFPU C++ (lowered by the compiler into risc-v instructions the tensix coprocessor can run). importantly, you cannot really generate kernels that use tt-llk using a compiler. take a tinygrad Op graph, for example. i think it's way easier to lower those into SFPU ops than trying to pattern match them with tt-llk kernels *and* SFPU ops (since invevitably your kernel will be too unique for tt-llk).
- the three kernel model is extremely inconvenient. it could be the case that you can combine them, or that you can run multiple kernels on the same data without having to run dataflow kernels, but i'm not sure yet.  
- there is also the pending question of what `binop_with_scalar_tile_init()` and friends do. if it truly limits the SFPU ops you can run in your kernel, then the possibility of kernel fusion goes down drastically. 

## layout

Top-level folders:
- `blackhole/`: architecture, PCIe/tt-kmd, firmware, coordinates/translation, fast-dispatch ABI, L1 maps.
- `tt-metal/`: kernel build/cache, loading/ABI, dispatch modes, dataflow/CBs, SFPI kernel dev notes.
- `llk-sfpi/`: SFPI/LLK notes kept separate.
- `tinygrad/`: tinygrad TT backend notes + AMD UOps references.
- `debugging/`: register/memory tooling notes.
- `disasms/`: disassembly dumps and notes.
- `human/`: human-written docs (read-only).
