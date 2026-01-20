# Pure-py vs TT-metal kernel binaries: `add1_sfpu_single_file.cpp` (Blackhole)

Goal: verify that `pure-py/codegen.py` produces the same device-kernel binaries (ELF/XIP payload) as TT-metal’s JIT for:

- `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`
  - BRISC: writer kernel
  - NCRISC: reader kernel
  - TRISC0/1/2: compute kernel stages (unpack/math/pack)

## Outcome

- **XIP payloads match byte-for-byte** between TT-metal and `pure-py/codegen.py` when using:
  - TT-metal’s wrappers (`dm_wrapper='tt-metal'` → `brisck.cc/ncrisck.cc`, and `trisck.cc` for TRISCs)
  - The same firmware symbol ELFs for `--just-symbols` (TT-metal uses `*_weakened.elf`)
  - The same device-specific compile defines and `DISPATCH_MESSAGE_ADDR`
- **Full ELF files do not match byte-for-byte** (expected): debug/build-path metadata differs, but the PT_LOAD contents (what gets uploaded) match.

This strongly suggests that the **toolchain + flags + XIP packing in `pure-py` are correct**, and that any hang/failure is more likely from:

- not propagating TT-metal’s device-specific defines into `codegen.py` (bank counts, PCIe coords, etc), and/or
- runtime/kernel-config packing (where the host uploads the packed XIP images inside the kernel-config buffer).

## What mattered for parity (TT-metal compile command)

From running the example with `TT_METAL_LOG_KERNELS_COMPILE_COMMANDS=1`, TT-metal compiled the kernels with:

- `DISPATCH_MESSAGE_ADDR=0xffb70438`
- `PCIE_NOC_X=19`, `PCIE_NOC_Y=24`
- `NUM_DRAM_BANKS=7`, `NUM_L1_BANKS=110`
- `IS_NOT_POW2_NUM_DRAM_BANKS=1`, `IS_NOT_POW2_NUM_L1_BANKS=1`

These values affect both:

- address-generation code paths (e.g. `InterleavedAddrGenFast`, L1/DRAM bank → noc-xy tables), and
- the *ABI* of firmware-provided globals like `bank_to_l1_offset[]` / `dram_bank_to_noc_xy[][]` (declared with sizes that depend on these macros).

If `codegen.py` compiles kernels with different `NUM_*_BANKS` than the firmware it links against (`--just-symbols`), the kernel will still link, but will index the wrong global tables at runtime.

### `pure-py/codegen.py` improvements made

- `pure-py/codegen.py` now always defines `IS_NOT_POW2_NUM_DRAM_BANKS` by default (TT-metal relies on this; otherwise `LOG_BASE_2_OF_NUM_DRAM_BANKS` is referenced but not defined in current headers).
- `pure-py/codegen.py` now **infers `NUM_DRAM_BANKS` and `NUM_L1_BANKS` from the firmware ELF** (via `riscv-tt-elf-nm` symbol sizes for `bank_to_dram_offset` / `bank_to_l1_offset`) when the caller doesn’t pass them explicitly.
  - This makes default compilation match the firmware bundle shipped in `pure-py/riscv-firmware/*` for bank-count-dependent code.

## TT-metal upload addresses (kernel-config buffer)

To verify whether pure-py uploads kernels “to the same place”, I read TT-metal’s `launch_msg` back out of L1 after running the example.

For Blackhole, TT-metal logical core `{0,0}` maps to physical noc0 tile `(1,2)`; reading `TensixL1.LAUNCH` on that tile gives:

- `kernel_config_base[WORKER] = 0x82b0` (matches `pure-py/configs.py:TensixL1.KERNEL_CONFIG_BASE`)
- `kernel_text_offset[0..4] = [0x130, 0x3b0, 0x610, 0xa10, 0xcb0]`

These offsets match TT-metal’s packing rule: start after CB config, then append packed XIP images with 16B alignment:

- BRISC (636B) at `0x82b0 + 0x130 = 0x83e0`
- NCRISC (600B) at `0x82b0 + 0x3b0 = 0x8660`
- TRISC0 (1020B) at `0x82b0 + 0x610 = 0x88c0`
- TRISC1 (660B) at `0x82b0 + 0xa10 = 0x8cc0`
- TRISC2 (1180B) at `0x82b0 + 0xcb0 = 0x8f60`

`pure-py/device.py` currently uses fixed offsets (`0x0000, 0x0400, 0x0800, 0x1000, 0x1400`) instead of TT-metal’s packed layout. That does *not* match TT-metal’s upload locations, even though the base (`0x82b0`) matches.

If firmware assumes the TT-metal packing scheme (or if other parts of the runtime depend on it), this mismatch is a plausible explanation for “kernel never runs / timeout waiting for done”.

## How I compared binaries

1. Run TT-metal example to populate cache and collect exact compile command-lines:
   - `TT_METAL_RUNTIME_ROOT=/home/boop/tenstorrent/tt-metal`
   - `TT_METAL_CACHE=/tmp/tt-metal-cache`
   - Optional: `TT_METAL_LOG_KERNELS_COMPILE_COMMANDS=1 TT_METAL_FORCE_JIT_COMPILE=1`
2. Compile the kernel strings from `add1_sfpu_single_file.cpp` with `pure-py/codegen.py` using TT-metal wrappers and TT-metal’s firmware symbols.
3. Compare the **packed XIP bytes** by concatenating PT_LOAD segments (the same thing TT-metal writes via `llrt::write_binary_to_address` for config-buffer kernels).

With matching inputs (firmware symbols + defines), all 5 packed images matched byte-for-byte:

- BRISC: 636B
- NCRISC: 600B
- TRISC0: 1020B
- TRISC1: 660B
- TRISC2: 1180B

## Notes

- Running `tt-metal/build_Release/programming_examples/metal_example_add1_sfpu_single_file` from `/home/boop/tenstorrent` requires setting `TT_METAL_RUNTIME_ROOT=/home/boop/tenstorrent/tt-metal` (otherwise TT-metal can’t find its root dir).
