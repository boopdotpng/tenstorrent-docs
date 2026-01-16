This folder holds RISC-V disassembly dumps (generated via `disasm_kern.py` / `riscv-tt-elf-objdump`) for TT-Metal kernels.

`*.xip.objdump.txt` is the disassembly of TT-Metal’s XIP-transformed image (`*.elf.xip.elf`): TT-Metal reads the cached `*.elf`, applies an in-memory “execute-in-place” transform (address/reloc rewriting), then uploads that packed image to the device. The `*.elf.xip.elf` file is just a debug dump of the post-transform ELF (can be disabled with `TT_METAL_DISABLE_XIP_DUMP=1`).

Cache layout + how to find the right binaries lives in `boop-docs/tt-metal/kernel-cache-and-disasm.md`.
