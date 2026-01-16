# TT-Metal kernel cache + disassembly (notes)

## Where the compiled kernels live

TT-Metal caches JIT-compiled firmware + kernels under:

- Default: `~/.cache/tt-metal-cache/`
- Override: `TT_METAL_CACHE=/path/to/cache` (TT-Metal appends `tt-metal-cache/` inside it)
- Fallback when `$HOME` is missing: `/tmp/tt-metal-cache/`

Cache structure (from `tt-metal/tt_metal/api/tt-metalium/tt_metal.hpp`):

`<tt-metal-cache>/<git_hash>/<build_key>/kernels/<kernel name>/<kernel hash>/...`

Notes:

- Firmware is cached too:
  - `.../<git_hash>/<build_key>/firmware/<fw_compile_hash>/{brisc,ncrisc,trisc0,trisc1,trisc2}/*.elf`
- Kernels aren’t “calling firmware” via normal function calls on Blackhole/Wormhole:
  - kernels are linked with `--just-symbols=<...>/firmware/.../*_weakened.elf` so they can reference firmware-defined
    symbols/addresses (mailboxes, counters, `rta_l1_base`, etc) without including firmware code in the kernel ELF.
- `<git_hash>` is the TT-Metal commit (`GIT_COMMIT_HASH`) baked into the build.
- `<build_key>` is architecture-specific (kernels are not portable across arch).
- Kernels created via `CreateKernelFromString(...)` show up under:
  `.../kernels/Kernel_Source_Code/<kernel_hash>/...`
- Each kernel hash directory contains per-core ELFs like `brisc/brisc.elf`, `ncrisc/ncrisc.elf`, `trisc0/trisc0.elf`, etc.
- You’ll often also see `*.elf.xip.elf` variants (they are not identical to `*.elf`).

## Disassembling without source

Use `disasm_kern.py` with `--no-source` to avoid the giant interleaved source dumps:

`python3 disasm_kern.py --no-source --kernels-only <kernel_dir_or_glob> -o disasm.md`

If you want just the raw disassembly text (no headers/symbol tables), run objdump directly:

`/home/boop/tenstorrent/tt-metal/runtime/sfpi/compiler/bin/riscv-tt-elf-objdump -d /path/to/*.elf`

## add1 (single-file, non-distributed) example mapping

The TT-Metal example is:

- `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`

It embeds kernels as strings and uses:

- Reader: `DataMovementProcessor::RISCV_1` (NCRISC)
- Writer: `DataMovementProcessor::RISCV_0` (BRISC)
- Compute: TRISC0/1/2 (compute kernel)

After running the example from the `tt-metal/` repo root, the used kernels can be found by looking for the most recently
written `*.elf.xip.elf` under `.../kernels/Kernel_Source_Code/`.

Quick way to locate them right after a run:

`find ~/.cache/tt-metal-cache -path '*/kernels/Kernel_Source_Code/*/*.elf.xip.elf' -mmin -5`

One concrete set (captured into `pure-py/disasm/add1_sfpu_single_file/`) lives at:

- Writer (BRISC): `~/.cache/tt-metal-cache/a4347c0dda/6213700099554438170/kernels/Kernel_Source_Code/6341274546116784419/brisc/`
- Reader (NCRISC): `~/.cache/tt-metal-cache/a4347c0dda/6213700099554438170/kernels/Kernel_Source_Code/3823300343025789547/ncrisc/`
- Compute (TRISC0/1/2): `~/.cache/tt-metal-cache/a4347c0dda/6213700099554438170/kernels/Kernel_Source_Code/1549901364368368725/trisc{0,1,2}/`
- Firmware (BRISC/NCRISC/TRISC0/1/2): `~/.cache/tt-metal-cache/a4347c0dda/6213700099554438170/firmware/7781187423536176149/{brisc,ncrisc,trisc0,trisc1,trisc2}/`

To regenerate (hardware required):

- `cd /home/boop/tenstorrent/tt-metal`
- `TT_METAL_RUNTIME_ROOT=/home/boop/tenstorrent/tt-metal TT_METAL_SLOW_DISPATCH_MODE=1 ./build/programming_examples/metal_example_add1_sfpu_single_file`
