This folder holds RISC-V disassembly dumps (generated via `disasm_kern.py` / `riscv-tt-elf-objdump`) for TT-Metal kernels.

`*.xip.objdump.txt` is the disassembly of TT-Metal’s XIP-transformed image (`*.elf.xip.elf`): TT-Metal reads the cached `*.elf`, applies an in-memory “execute-in-place” transform (address/reloc rewriting), then uploads that packed image to the device. The `*.elf.xip.elf` file is just a debug dump of the post-transform ELF (can be disabled with `TT_METAL_DISABLE_XIP_DUMP=1`).

Cache layout + how to find the right binaries lives in `boop-docs/tt-metal/kernel-cache-and-disasm.md`.

## Full-op disassemblies (all 5 cores: BRISC + NCRISC + TRISC0/1/2)

Generated from Qwen2.5-3B-Instruct run on Blackhole P100. Each file contains the reader (NCRISC), unpack (TRISC0), math (TRISC1), pack (TRISC2), and writer (BRISC) kernels for one op.

- `eltwise-binary-all-cores.s` — eltwise binary add (3.5k lines)
- `sdpa-all-cores.s` — scaled dot-product attention / flash decode (27k lines)
- `matmul-all-cores.s` — fused bias activation matmul (6.5k lines)
- `layernorm-all-cores.s` — sharded layernorm with multicast (5.9k lines)
