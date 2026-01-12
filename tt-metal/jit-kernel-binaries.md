# JIT kernel binaries (where to grab raw ELFs)

When using `CreateKernelFromString` or other JIT-compiled kernels (for example `programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`), tt-metal writes per-processor ELFs into the JIT cache. This is the simplest place to grab BRISC/NCRISC/TRISC binaries for a pure-Python launcher.

## Cache layout

- Root: `~/.cache/tt-metal-cache/<git_hash>/<build_key>/kernels/`
- File-based kernels: `<kernel_name>/<hash>/`
- String-based kernels: `Kernel_Source_Code/<hash>/`

Each hash directory contains processor-specific ELFs:

- `brisc/brisc.elf` (RISCV_0 data-movement, writer)
- `ncrisc/ncrisc.elf` (RISCV_1 data-movement, reader)
- `trisc0/trisc0.elf`, `trisc1/trisc1.elf`, `trisc2/trisc2.elf` (compute)

## Identifying the exact ELFs for a run

After running a program once, tt-metal’s watcher writes kernel name and ELF path maps in the current working directory:

- `./generated/watcher/kernel_names.txt`
- `./generated/watcher/kernel_elf_paths.txt`

These files map kernel IDs to ELF paths, so you can select the exact BRISC/NCRISC/TRISC ELFs used in that run.

## Converting ELF to flat binary

If you want a raw flat binary instead of ELF:

```bash
riscv-tt-elf-objcopy -O binary brisc.elf brisc.bin
riscv-tt-elf-objcopy -O binary ncrisc.elf ncrisc.bin
riscv-tt-elf-objcopy -O binary trisc0.elf trisc0.bin
```

Note: tt-metal’s loader (`ll_api::memory`) uses ELF spans/relocations. If you load flat binaries directly, you must place them at the correct L1 addresses yourself.
