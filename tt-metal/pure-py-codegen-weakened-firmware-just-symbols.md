# pure-py vs tt-metal: `--just-symbols` requires “weakened” firmware

## Summary
`pure-py` kernel compilation was producing an NCRISC XIP payload that did **not** match TT-metal’s cached binary for `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`.

Root cause: `pure-py/codegen.py` linked kernels with `-Wl,--just-symbols=<firmware>` using an *unmodified* firmware ELF. TT-metal first writes a **weakened firmware** ELF, where:
- global **data** symbols are made **weak**
- other globals are made **local**
- `__fw_export_*` and `__global_pointer$` stay strong

Without this, NCRISC kernels can accidentally bind to firmware globals (notably the NOC counter arrays), changing the code and the XIP output.

Fix: `pure-py/codegen.py` now generates a TT-metal-style `*.weakened.elf` before linking kernels.

## Evidence (before fix)
The mismatching kernel was NCRISC. The firmware exports the NOC counter arrays:
- `pure-py/riscv-firmware/p100a/ncrisc.elf` has `noc_reads_num_issued` / `noc_nonposted_writes_*` symbols in `.bss`.

With an unweakened `--just-symbols` firmware, the kernel ended up binding those as **absolute** symbols (no kernel-local `.bss`), e.g.:
- `noc_reads_num_issued` became `A 0xffb00004` in the kernel ELF, instead of a kernel-local `b` symbol in `.bss`.

TT-metal’s cached NCRISC kernel has a kernel-local `noc_reads_num_issued` in `.bss` (8 bytes), which changes the text bytes and thus the packed XIP bytes.

## Verification (after fix)
Comparing `pack_xip_elf()` output for the five kernels in the single-file example:
- BRISC, NCRISC, TRISC0/1/2 XIP bytes are **byte-identical** to TT-metal’s cache entries.

Note: the full ELF files are not byte-identical (debug/build metadata differs), but the PT_LOAD payload bytes used for upload (`pack_xip_elf`) match.

TT-metal cache locations used for comparison:
- `~/.cache/tt-metal-cache/*/*/kernels/Kernel_Source_Code/3118012248401725933/ncrisc/ncrisc.elf`
- `~/.cache/tt-metal-cache/*/*/kernels/Kernel_Source_Code/18195001282830055389/brisc/brisc.elf`
- `~/.cache/tt-metal-cache/*/*/kernels/Kernel_Source_Code/618986247338201318/trisc{0,1,2}/trisc*.elf`

## Why this matters for runtime hangs
If the kernel binary differs from TT-metal (even slightly), it’s easy to end up with:
- wrong mailbox protocol behavior
- unexpected writes into firmware-owned state
- “kernel never finishes” symptoms (host waits for DONE forever)

This fix eliminates one major source of “same toolchain, but different binary” divergence.

