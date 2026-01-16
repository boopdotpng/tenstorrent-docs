Disassembly dumps for the TT-Metal single-file add1 example:

- Example: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`
- Writer dataflow kernel (BRISC): `writer_brisc*.objdump.txt`
- Reader dataflow kernel (NCRISC): `reader_ncrisc*.objdump.txt`
- Compute kernels (TRISC0/1/2): `compute_trisc{0,1,2}*.objdump.txt`
- Firmware disassembly (for context): `firmware_{brisc,ncrisc,trisc0,trisc1,trisc2}.objdump.txt`

Each kernel has 2 variants:

- `*.objdump.txt`: disassembly of `*.elf`
- `*.xip.objdump.txt`: disassembly of `*.elf.xip.elf` (TT-Metal’s post-XIP-transform image; this is what gets packed/uploaded when using XIP loading)

Cache structure + how to regenerate is in `boop-docs/tt-metal/kernel-cache-and-disasm.md`.
