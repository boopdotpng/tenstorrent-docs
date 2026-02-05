# Kernel build pipeline, cache, and disassembly

This consolidates TT-metal kernel compilation details, cache layout, and disassembly notes. It also captures pure-py parity findings when using the tt-metal toolchain.

## JIT build overview

TT-metal kernel compilation is a JIT build system around the SFPI toolchain and generated glue files.

- Compiler: `runtime/sfpi/compiler/bin/riscv-tt-elf-g++`
- Two program types:
  - **Firmware** ELFs (core runtime)
  - **Kernel** ELFs (user kernels linked against firmware symbols)

Kernels are linked with:
- `-Wl,--just-symbols=<firmware.weakened.elf>`

TT-metal **weakens** firmware ELFs before linking:
- global **data** symbols are made **weak**
- other globals are made **local**
- `__fw_export_*` and `__global_pointer$` stay strong

If you link against unmodified firmware, kernel binaries can diverge (e.g., NOC counter arrays become absolute symbols).

## Generated files (compute kernels)

TRISC kernels are compiled through `trisck.cc`, which expects generated files:
- `chlkc_unpack.cpp`, `chlkc_math.cpp`, `chlkc_pack.cpp`
- `defines_generated.h`
- `chlkc_unpack_data_format.h`, `chlkc_pack_data_format.h`
- `chlkc_unpack_tile_dims.h`, `chlkc_pack_tile_dims.h`
- `chlkc_dst_accum_mode.h`, `chlkc_dst_sync_mode.h`
- `chlkc_math_fidelity.h`, `chlkc_math_approx_mode.h`

These are generated in `tt_metal/jit_build/genfiles.cpp` and depend on your kernel source + CB formats/dims + compute config.

## Per-processor builds (Blackhole)

Separate ELFs are produced for each processor:
- BRISC: data-movement (writer)
- NCRISC: data-movement (reader)
- TRISC0/1/2: compute (unpack / math / pack)

### CPU/ISA flags
- BRISC/NCRISC: `-mcpu=tt-bh -mno-tt-tensix-optimize-replay`
- TRISC0/1/2: `-mcpu=tt-bh-tensix -mno-tt-tensix-optimize-replay`

### Linker scripts
- BRISC: `runtime/hw/toolchain/blackhole/kernel_brisc.ld`
- NCRISC: `runtime/hw/toolchain/blackhole/kernel_ncrisc.ld`
- TRISC0/1/2: `runtime/hw/toolchain/blackhole/kernel_trisc{0,1,2}.ld`

### Link objects
- Always: `runtime/hw/lib/blackhole/substitutes.o`
- BRISC only: `runtime/hw/lib/blackhole/noc.o`

## Cache layout (kernels + firmware)

Root:
- `~/.cache/tt-metal-cache/<git_hash>/<build_key>/`

Kernels:
- File-based: `kernels/<kernel_name>/<hash>/...`
- String-based: `kernels/Kernel_Source_Code/<hash>/...`

Each kernel hash dir contains:
- `brisc/brisc.elf`
- `ncrisc/ncrisc.elf`
- `trisc0/trisc0.elf`, `trisc1/trisc1.elf`, `trisc2/trisc2.elf`

Firmware:
- `firmware/<fw_compile_hash>/{brisc,ncrisc,trisc0,trisc1,trisc2}/*.elf`

The cache may also contain `*.elf.xip.elf` (post-XIP transform debug dumps).

### Finding exact ELFs used by a run
After running once, watcher writes:
- `./generated/watcher/kernel_names.txt`
- `./generated/watcher/kernel_elf_paths.txt`

## Disassembly notes

- `disasm_kern.py --no-source --kernels-only <kernel_dir> -o disasm.md`
- Or objdump directly:
  `runtime/sfpi/compiler/bin/riscv-tt-elf-objdump -d <elf>`

`*.elf.xip.elf` corresponds to TT-metal’s post-XIP transform image, which is what gets uploaded when using XIP loading.

## Pure-py parity findings (add1_sfpu)

When using tt-metal wrappers and the same firmware symbols, pure-py can produce **byte-identical XIP payloads** for:
- BRISC
- NCRISC
- TRISC0/1/2

Important compile-time defines:
- `DISPATCH_MESSAGE_ADDR`
- `PCIE_NOC_X`, `PCIE_NOC_Y`
- `NUM_DRAM_BANKS`, `NUM_L1_BANKS`
- `IS_NOT_POW2_NUM_DRAM_BANKS`, `IS_NOT_POW2_NUM_L1_BANKS`

If `NUM_*_BANKS` differ from the firmware you link against, kernels can index the wrong global tables at runtime.

### Weakened firmware requirement

If you link against unweakened firmware, NCRISC kernels can bind to firmware globals (notably NOC counter arrays), changing the XIP output. Generate `*.weakened.elf` before linking.


## Kernel compilation without tt-llk (pure-py)

# Pure-py kernel compilation without `tt_llk` (Blackhole)

This is the smallest working compile/link setup for generating per-core ELFs from C++ source strings in `pure-py`, with:

- slow-dispatch (firmware-driven) launch
- **no** `tt_metal/third_party/tt_llk` include paths
- runtime args only (no compile-time args required unless your kernel uses them)

## Toolchain

- Compiler: `TT_HOME/runtime/sfpi/compiler/bin/riscv-tt-elf-g++`
- Objcopy: `TT_HOME/runtime/sfpi/compiler/bin/riscv-tt-elf-objcopy`

## Per-processor builds (Blackhole worker tiles)

These are separate ELFs; you upload one ELF per processor slot:

- BRISC: data-movement (commonly writer)
- NCRISC: data-movement (commonly reader)
- TRISC0/1/2: compute (custom TRISC kernels only; see compute note below)

### CPU/ISA flags

- BRISC/NCRISC: `-mcpu=tt-bh -mno-tt-tensix-optimize-replay`
- TRISC0/1/2: `-mcpu=tt-bh-tensix -mno-tt-tensix-optimize-replay`

### Linker scripts

- BRISC: `TT_HOME/runtime/hw/toolchain/blackhole/kernel_brisc.ld`
- NCRISC: `TT_HOME/runtime/hw/toolchain/blackhole/kernel_ncrisc.ld`
- TRISC0/1/2: `TT_HOME/runtime/hw/toolchain/blackhole/kernel_trisc{0,1,2}.ld`

### Link objects

- Always: `TT_HOME/runtime/hw/lib/blackhole/substitutes.o`
- BRISC only: `TT_HOME/runtime/hw/lib/blackhole/noc.o`

### Link against firmware symbols (slow-dispatch)

Kernels reference firmware-defined globals (e.g. `rta_l1_base`, mailbox pointers, coordinate globals).
Resolve their addresses at link time with:

- `-Wl,--just-symbols=<firmware.elf>`

The firmware ELF here is the same firmware you upload in `pure-py` (it defines those globals at fixed L1 addresses); it is not re-uploaded as part of the kernel.

## Includes (minimal set)

This is enough to build BRISC/NCRISC kernels that use `api/dataflow/dataflow_api.h` and to build SFPI-only TRISC kernels:

- `-I$TT_HOME/tt_metal`
- `-I$TT_HOME/tt_metal/hw/inc`
- `-I$TT_HOME/tt_metal/hw/inc/internal/tt-1xx`
- `-I$TT_HOME/tt_metal/hw/inc/internal/tt-1xx/blackhole`
- `-I$TT_HOME/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc`
- `-I$TT_HOME/tt_metal/hostdevcommon/api`
- `-I$TT_HOME/tt_metal/api` (for `tt-metalium/*`)
- `-I$TT_HOME/tt_metal/include`
- `-I$TT_HOME/runtime/sfpi/include` (for `sfpi.h`)

## Entry stub (what `pure-py` compiles)

The generated translation unit:

- includes the necessary headers for the processor type
- spins on mailbox `RUN_MSG_GO` (with `invalidate_l1_cache()` in the loop)
- calls your `kernel_main()`
- does **not** write `RUN_MSG_DONE` (BRISC firmware owns completion)

In `pure-py/codegen.py` this is done by generating a small `*_entry.cc` that includes your kernel source via a generated `kernel_includes.hpp`.

## Runtime args ABI (what `get_arg_val()` reads)

Runtime args are a `uint32_t[]` stored in L1 inside the “kernel-config” region.

- Host writes args to `kernel_config_base + rta_offset[processor_index].rta_offset`
- Firmware sets `rta_l1_base` to that address before jumping into the kernel
- `get_arg_val<T>(i)` is just a 4-byte load from `rta_l1_base[i]`

Constraints:

- only 4-byte types are supported (`uint32_t`, `int32_t`, bit-cast floats, etc.)

## Notes

### `TensorAccessor` implies compile-time args

If you use `TensorAccessorArgs<0>()` / `TensorAccessor`, you are using the compile-time-arg buffer (`KERNEL_COMPILE_TIME_ARGS`).
If you want runtime-only kernels, avoid `TensorAccessor` and do your own NoC address generation from runtime args.

### `compute_kernel_api/*` implies `tt_llk`

Headers like `compute_kernel_api/common.h` include `ckernel.h`/`ckernel_include.h`, which live under `tt_metal/third_party/tt_llk`.
If you want to avoid `tt_llk`, write TRISC kernels directly (e.g. SFPI-only) and avoid `compute_kernel_api/*`.

SFPI uses `ckernel::instrn_buffer` in its builtin wrappers; `pure-py/codegen.py` provides a tiny shim:
`ckernel::instrn_buffer = (volatile uint32_t*)INSTRN_BUF_BASE`.

### p100a vs p150*

For Blackhole worker cores, the compile/link setup is the same.
What changes across boards is the firmware you upload (and harvesting / enabled tiles), not the toolchain flags.

## Kernel compilation with ckernel / compute_kernel_api (pure-py)

# Pure-py kernel compilation with `ckernel` / `compute_kernel_api` (Blackhole)

Use this when your TRISC kernel source includes things like:

- `#include "compute_kernel_api/common.h"`
- `#include "compute_kernel_api/tile_move_copy.h"`
- `#include "sfpi.h"` (via `TRISC_MATH`)
- `namespace NAMESPACE { void MAIN { ... } }`

That stack pulls in `ckernel.h` and the LLK helpers under `tt_metal/third_party/tt_llk`, so a “no-tt_llk” build won’t work.

## What `pure-py` generates

To mimic the TT-metal JIT enough for compilation, `pure-py/codegen.py` generates into the build dir:

- `chlkc_unpack.cpp`, `chlkc_math.cpp`, `chlkc_pack.cpp` (each includes your kernel source with `TRISC_UNPACK/MATH/PACK`)
- `defines_generated.h` (empty for now)
- The descriptor headers that TT-metal normally JIT-generates:
  - `chlkc_unpack_data_format.h`, `chlkc_pack_data_format.h`
  - `chlkc_unpack_tile_dims.h`, `chlkc_pack_tile_dims.h`
  - `chlkc_dst_accum_mode.h`, `chlkc_dst_sync_mode.h`
  - `chlkc_math_fidelity.h`, `chlkc_math_approx_mode.h`

Then it compiles `TT_HOME/tt_metal/hw/firmware/src/tt-1xx/trisck.cc` (this is a *kernel wrapper*, not firmware) with:

- `-DUCK_CHLKC_UNPACK` + `-DNAMESPACE=chlkc_unpack` (TRISC0)
- `-DUCK_CHLKC_MATH` + `-DNAMESPACE=chlkc_math` (TRISC1)
- `-DUCK_CHLKC_PACK` + `-DNAMESPACE=chlkc_pack` (TRISC2)

## Required include paths (Blackhole)

In addition to the usual `tt_metal/hw/inc` includes, TRISC+ckernel builds need:

- `tt_metal/hw/ckernels/blackhole/metal/common` (for `chlkc_list.h`)
- `tt_metal/hw/ckernels/blackhole/metal/llk_api` (+ `llk_sfpu/`)
- `tt_metal/hw/ckernels/blackhole/metal/llk_io` (for `llk_io.h`)
- `tt_metal/third_party/tt_llk/tt_llk_blackhole/common/inc` (for `ckernel.h`, `ckernel_include.h`, etc.)

## Important constraints

- Tile dims / formats / math fidelity are compile-time in this model. `pure-py` currently emits a single fixed set (defaults to `Float16_b` 32x32 tiles).
- If your runtime CB config doesn’t match what was compiled into those descriptor headers, the kernel may run wrong.

## Tweaking compile-time descriptors

`pure-py/codegen.py` exposes this as a small dataclass:

- `codegen.CkernelConfig` (format, tile dims, math fidelity, etc.)

## Pure-Python kernel compilation (JIT parity notes)

# Pure-Python Kernel Compilation (Blackhole)

This note captures what tt-metal’s JIT does for BRISC/NCRISC/TRISC so a pure-Python launcher can compile kernels and upload the raw ELFs. It is based on the Blackhole HAL and JIT sources.

## One compiler, multiple builds

tt-metal uses a single compiler binary:

- `runtime/sfpi/compiler/bin/riscv-tt-elf-g++`

but it runs it **separately** for:

- BRISC (data-movement writer)
- NCRISC (data-movement reader)
- TRISC0/1/2 (compute: unpack / math / pack)

The difference is **defines**, **linker scripts**, and sometimes **link objects**.

## Why do TRISC builds need `chlkc_*` files?

TRISC kernels are compiled through `trisck.cc`, which includes `chlkc_list.h`. That file expects to include:

- Generated per-trisc C++ source wrappers:
  - `chlkc_unpack.cpp`
  - `chlkc_math.cpp`
  - `chlkc_pack.cpp`
- Generated descriptors used by the compute kernel:
  - `chlkc_unpack_data_format.h`
  - `chlkc_pack_data_format.h`
  - `chlkc_unpack_tile_dims.h`
  - `chlkc_pack_tile_dims.h`
  - `chlkc_dst_accum_mode.h`
  - `chlkc_dst_sync_mode.h`
  - `chlkc_math_fidelity.h`
  - `chlkc_math_approx_mode.h`
- `defines_generated.h` (defines added via kernel config)

These files are generated by tt-metal in `tt_metal/jit_build/genfiles.cpp`. They are derived from:

- Your kernel source string
- CB data formats and tile dims
- Compute config (math fidelity, approx, fp32 dest, dst sync)

**Bottom line:** For compute kernels, the kernel source string is not enough. You must generate the `chlkc_*` files (or reuse JIT outputs). For BRISC/NCRISC dataflow kernels, you only need a generated `kernel_includes.hpp` that includes the kernel source.

## Why are there three TRISC ELFs?

TRISC0/1/2 run **different roles** (unpack, math, pack). The JIT compiles the **same kernel source** three times with different defines, so the binaries differ:

- TRISC0: `UCK_CHLKC_UNPACK`, `COMPILE_FOR_TRISC=0`, includes `chlkc_unpack_*`
- TRISC1: `UCK_CHLKC_MATH`, `COMPILE_FOR_TRISC=1`, includes `chlkc_math_*`
- TRISC2: `UCK_CHLKC_PACK`, `COMPILE_FOR_TRISC=2`, includes `chlkc_pack_*`

That is why you upload **three different ELFs**. Uploading the same ELF to all TRISCs would only work if you wrote a custom kernel that branches at runtime based on the TRISC ID and carries unpack+math+pack in one binary (not how the default pipeline is built).

## Minimal generated files (per kernel)

Dataflow kernel (BRISC/NCRISC):
- `kernel_includes.hpp` (wraps the kernel source as an include)

Compute kernel (TRISC0/1/2):
- `chlkc_unpack.cpp`, `chlkc_math.cpp`, `chlkc_pack.cpp`
- `defines_generated.h`
- `chlkc_unpack_data_format.h`, `chlkc_pack_data_format.h`
- `chlkc_unpack_tile_dims.h`, `chlkc_pack_tile_dims.h`
- `chlkc_dst_accum_mode.h`, `chlkc_dst_sync_mode.h`
- `chlkc_math_fidelity.h`, `chlkc_math_approx_mode.h`

## Compiler flags and linker scripts (Blackhole)

All of these come from:
- `tt_metal/jit_build/build.cpp`
- `tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal.cpp`
- `tt_metal/llrt/hal/tt-1xx/hal_1xx_common.cpp`

### Common flags (all RISCs)
```
-std=c++17 -flto=auto -ffast-math -fno-exceptions
-MMD -fno-use-cxa-atexit
-Wall -Werror -Wno-unknown-pragmas -Wno-deprecated-declarations
-Wno-error=multistatement-macros -Wno-error=parentheses
-Wno-error=unused-but-set-variable -Wno-unused-variable -Wno-unused-function
```

Linker flags:
```
-Wl,-z,max-page-size=16 -Wl,-z,common-page-size=16 -nostartfiles
-Wl,--emit-relocs
```

### BRISC (writer)
- Source: `tt_metal/hw/firmware/src/tt-1xx/brisck.cc`
- Linker script: `runtime/hw/toolchain/blackhole/kernel_brisc.ld`
- Extra objs: `runtime/hw/lib/blackhole/noc.o`, `runtime/hw/lib/blackhole/substitutes.o`
- Defines:
  - `COMPILE_FOR_BRISC`, `PROCESSOR_INDEX=0`, `ARCH_BLACKHOLE`, `KERNEL_BUILD`

### NCRISC (reader)
- Source: `tt_metal/hw/firmware/src/tt-1xx/ncrisck.cc`
- Linker script: `runtime/hw/toolchain/blackhole/kernel_ncrisc.ld`
- Extra objs: `runtime/hw/lib/blackhole/substitutes.o`
- Defines:
  - `COMPILE_FOR_NCRISC`, `PROCESSOR_INDEX=1`, `ARCH_BLACKHOLE`, `KERNEL_BUILD`

### TRISC0/1/2 (compute)
- Source: `tt_metal/hw/firmware/src/tt-1xx/trisck.cc`
- Linker scripts:
  - `runtime/hw/toolchain/blackhole/kernel_trisc0.ld`
  - `runtime/hw/toolchain/blackhole/kernel_trisc1.ld`
  - `runtime/hw/toolchain/blackhole/kernel_trisc2.ld`
- Extra objs: `runtime/hw/lib/blackhole/substitutes.o`
- Defines (per TRISC):
  - TRISC0: `UCK_CHLKC_UNPACK`, `NAMESPACE=chlkc_unpack`, `COMPILE_FOR_TRISC=0`, `PROCESSOR_INDEX=2`
  - TRISC1: `UCK_CHLKC_MATH`, `NAMESPACE=chlkc_math`, `COMPILE_FOR_TRISC=1`, `PROCESSOR_INDEX=3`
  - TRISC2: `UCK_CHLKC_PACK`, `NAMESPACE=chlkc_pack`, `COMPILE_FOR_TRISC=2`, `PROCESSOR_INDEX=4`

### Dispatch message define

All kernels also define:
```
DISPATCH_MESSAGE_ADDR=<value>
```
This comes from `DispatchMemMap::get_dispatch_message_addr_start()` in `tt_metal/impl/dispatch/dispatch_mem_map.cpp`.

## Practical shortcut (bootstrap)

If you want to avoid reimplementing `chlkc_*` generation:

1) Run the original example once with JIT enabled.
2) Grab the ELFs from `~/.cache/tt-metal-cache/<git_hash>/<build_key>/kernels/...`.

See `boop-docs/tt-metal/jit-kernel-binaries.md` for the cache layout.

## ELF loading: DISCRETE vs XIP (tt-metal)

tt-metal supports two broad ways of turning an ELF into “bytes written to L1”:

- `DISCRETE`: write each span to its linked address (PT_LOAD-by-address).
- `CONTIGUOUS_XIP`: run the in-memory “XIP” transform (`ElfFile::MakeExecuteInPlace()`), then pack spans contiguously and stream them into a chosen base address.

Notes:

- The cache may contain `*.elf.xip.elf` files. These are post-transform debug dumps; they are not just “different PT_LOAD addresses”. The transform primarily rewrites RISC-V relocation sites/instructions so the code can run from the packed placement (notably translating some absolute `lui`/`lo12` sequences into PC-relative `auipc`/`pcrel_lo12` sequences).
- Even if the program headers look similar before/after, the bytes differ (patched instruction immediates / relocation addends).
- Separately from XIP, Blackhole uses a RISCV “local mem” alias range at `0xFFB0_0000..`. tt-metal does not host-write this directly; it relocates these addresses into per-core L1 init scratch (`local_init_addr`) and device firmware copies them into true local-mem at runtime.

## Blackhole firmware sources

Firmware is built from C++ sources in `tt_metal/hw/firmware/src/tt-1xx/` (not blobs). The Blackhole HAL selects these
sources for `is_fw=true` builds:

Tensix (worker tiles):
- `tt_metal/hw/firmware/src/tt-1xx/brisc.cc`
- `tt_metal/hw/firmware/src/tt-1xx/ncrisc.cc`
- `tt_metal/hw/firmware/src/tt-1xx/trisc.cc`

Ethernet / idle ETH (if enabled):
- `tt_metal/hw/firmware/src/tt-1xx/active_erisc.cc`
- `tt_metal/hw/firmware/src/tt-1xx/active_erisc-crt0.cc` (2‑ERISC mode only)
- `tt_metal/hw/firmware/src/tt-1xx/subordinate_erisc.cc`
- `tt_metal/hw/firmware/src/tt-1xx/idle_erisc.cc`

Kernel wrappers (not firmware, used for per‑kernel builds):
- `tt_metal/hw/firmware/src/tt-1xx/brisck.cc`
- `tt_metal/hw/firmware/src/tt-1xx/ncrisck.cc`
- `tt_metal/hw/firmware/src/tt-1xx/trisck.cc`
- `tt_metal/hw/firmware/src/tt-1xx/active_erisck.cc`
- `tt_metal/hw/firmware/src/tt-1xx/idle_erisck.cc`

## Reference files

- `tt_metal/jit_build/build.cpp`
- `tt_metal/jit_build/genfiles.cpp`
- `tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal.cpp`
- `tt_metal/llrt/hal/tt-1xx/hal_1xx_common.cpp`
- `tt_metal/hw/firmware/src/tt-1xx/brisck.cc`
- `tt_metal/hw/firmware/src/tt-1xx/ncrisck.cc`
- `tt_metal/hw/firmware/src/tt-1xx/trisck.cc`
- `tt_metal/hw/ckernels/blackhole/metal/common/chlkc_list.h`

## Compiler toolchain and replacement plan (verbatim)

# tt-metal kernel compiler: what it does, what runs, and how to replace it

This is a Blackhole-focused “what actually happens” report for TT-metal kernel builds, with an eye toward eventually eliminating the SFPI compiler toolchain.

The short version:
- BRISC/NCRISC “dataflow” kernels are *mostly ordinary RISC-V + MMIO*: you can realistically replace the compiler with “emit RV32 + linker script + pack XIP”.
- TRISC “compute” kernels execute TT’s *custom Tensix instruction set* (SFPU ops, replay, RWCs, stalls). You can still eliminate the C++ compiler, but you must be able to emit those custom opcodes (as raw 32-bit words) and understand how SFPU instruction streams are constructed and executed.

---

## 1) What TT-metal’s kernel compiler pipeline really is

TT-metal kernel compilation is a *JIT build system* around a cross toolchain (SFPI) and a set of generated glue files.

### 1.1 Toolchain selection (the “bloat”)

TT-metal does not use your system GCC/Clang for kernels. It locates SFPI’s cross compiler:
- `tt-metal/tt_metal/jit_build/build.cpp` discovers `runtime/sfpi/compiler/bin/riscv-tt-elf-g++` (or `/opt/tenstorrent/sfpi/...`).
- Kernel flags include `-mcpu=tt-bh` (DM) or `-mcpu=tt-bh-tensix` (compute) and `-mno-tt-tensix-optimize-replay`.

That SFPI bundle is a full “gcc + binutils + newlib + gdb + …” distribution; TT-metal uses a *tiny* subset (compiler driver + ld + objcopy/objdump).

### 1.2 Two different “program types”: firmware vs kernel

TT-metal builds *firmware* ELFs (base runtime for each RISC) and *kernel* ELFs (your kernel code).

Key idea: kernels are *not freestanding*. They reference firmware globals (mailboxes, CB state, coordinate globals, NOC counter arrays, etc.). TT-metal resolves those references by linking the kernel against firmware symbols:
- firmware is built first
- firmware symbols are “weakened/localized”
- kernels are linked with `-Wl,--just-symbols=<firmware.weakened.elf>`

See:
- `tt-metal/tt_metal/jit_build/build.cpp` (`--just-symbols=…`, `--emit-relocs`)
- `tt-metal/tt_metal/llrt/tt_elffile.cpp` (symbol weakening/localization)

### 1.3 JIT-generated “genfiles” that kernels implicitly depend on

TT-metal generates headers/sources into the per-kernel build directory:
- DM kernels get `kernel_includes.hpp` which includes the user kernel file.
- TRISC kernels get `chlkc_{unpack,math,pack}.cpp` which include the same user kernel file with different stage defines.

See:
- `tt-metal/tt_metal/jit_build/genfiles.cpp`

These generated files are why kernel compilation feels “weird” compared to a normal embedded build: the real translation units are not the kernel `.cpp` you wrote, but wrappers that pull your code in with a big pre-baked environment.

### 1.4 Linker scripts hard-code the execution model

Each programmable core type uses an arch-specific linker script:
- Blackhole scripts live at `tt-metal/runtime/hw/toolchain/blackhole/`.
- Example: `tt-metal/runtime/hw/toolchain/blackhole/kernel_trisc0.ld` declares `PROVIDE(__instrn_buffer = 0xFFE40000);` and lays out `.text/.data/.bss` at the expected L1 addresses.

If you want to replace the toolchain, you still need to follow these link-time constraints (or replace the loader/firmware that assumes them).

---

## 2) What instructions actually execute (proof by disassembly)

This section uses kernels compiled *offline* (no device interaction) via `blackhole-py/codegen.py` and disassembled with `riscv-tt-elf-objdump`.

### 2.1 Dataflow: `noc_async_read` becomes MMIO + polling + counters

In a simple NCRISC reader kernel (`kernels/dataflow/reader_unary.cpp`), the inner “issue NOC read” path compiles into:
- a poll of `noc_cmd_buf_ready()` (loads from NOC CMD buffer status MMIO)
- a sequence of MMIO stores to program NOC command buffer registers
- an increment of `noc_reads_num_issued[noc]`
- a barrier that polls “reads flushed” then issues a `fence`

Example excerpt (from a compiled NCRISC kernel disassembly):
```text
5938:  ...                 while (!noc_cmd_buf_ready(noc, cmd_buf));
593c:  80a72623            sw a0,-2036(a4)   ; NOC_RET_ADDR_LO  (dest L1)
5940:  80b72023            sw a1,-2048(a4)   ; NOC_TARG_ADDR_LO (src)
5944:  80072223            sw zero,-2044(a4) ; NOC_TARG_ADDR_MID (upper / pcie mask)
594c:  80d72423            sw a3,-2040(a4)   ; NOC_TARG_ADDR_HI  (coords)
5954:  84572023            sw t0,-1984(a4)   ; NOC_CMD_CTRL      (send req)
5958:  ...                 noc_reads_num_issued[noc] += 1;
5968:  ...                 while (!ncrisc_noc_reads_flushed(noc));
596c:  0ff0000f            fence
```

The exact addresses/offsets come from `tt_metal/hw/inc/internal/tt-1xx/blackhole/noc_nonblocking_api.h`:
- `NOC_CMD_BUF_WRITE_REG()` computes an MMIO pointer as:
  - `(buf << NOC_CMD_BUF_OFFSET_BIT) + (noc << NOC_INSTANCE_OFFSET_BIT) + <reg offset>`
- `ncrisc_noc_fast_read()` writes `NOC_RET_ADDR_*`, `NOC_TARG_ADDR_*`, `NOC_AT_LEN`, then `NOC_CMD_CTRL`.

So for *dataflow kernels*, “issuing DMA” is literally “write a few MMIO registers, bump a software-visible counter, poll status”.

### 2.2 Dataflow: `noc_async_write` is similar (different counters/barriers)

In a BRISC writer kernel (`kernels/dataflow/writer_unary.cpp`), the write path is the same pattern:
- poll CMD buffer ready
- program RET/TARG addresses + len + ctrl
- increment `noc_nonposted_writes_num_issued` and `noc_nonposted_writes_acked`
- barrier polls “nonposted writes flushed” then `fence`

Example excerpt:
```text
4aa4:  ...                 while (!noc_cmd_buf_ready(noc, cmd_buf));
4aac:  00872023            sw s0,0(a4)       ; NOC_TARG_ADDR_LO (src L1)
4ab0:  00b72623            sw a1,12(a4)      ; NOC_RET_ADDR_LO  (dest)
4abc:  00d72a23            sw a3,20(a4)      ; NOC_RET_ADDR_HI  (coords)
4ac0:  03c72023            sw t3,32(a4)      ; NOC_AT_LEN
4ac4:  04772023            sw t2,64(a4)      ; NOC_CMD_CTRL (send req)
4ac8:  ...                 noc_nonposted_writes_num_issued[noc] += 1;
4ae4:  ...                 while (!ncrisc_noc_nonposted_writes_flushed(noc));
4ae8:  0ff0000f            fence
```

### 2.3 Compute: SFPI emits real “SFPU instructions” in the TRISC stream

SFPI is not “just a library”. It is a C++ wrapper around compiler builtins, and those builtins lower to TT’s Tensix/SFPU opcodes.

You can see this directly in a TRISC1 (math) kernel disassembly that calls `ckernel::relu_tile(0)`:
```text
6488:  c4000001            sfploadi L0,0,0
648c:  100001cc            ttreplay 0,7,1,1
6490:  c0438001            sfpload  L1,0,0,7
6494:  1002c442            sfpmad   L1,L0,L11,L1,0
649c:  ec000401            sfpsetcc L1,0x000,0
64a0:  c8038001            sfpstore 0,L0,0,7
64a4:  2800c02a            sfpencc  0x003,10
64a8:  e0020000            ttincrwc 0,2,0,0
64ac:  100001c0            ttreplay 0,7,0,0
```

This is the critical take-away for “compiler replacement”:
- TRISC compute kernels are not RV32I-only. They execute custom opcodes like `sfploadi`, `sfpmad`, `sfpsetcc`, `ttreplay`, `ttincrwc`, `ttstallwait`, `ttmop`, `ttsetrwc`, etc.
- SFPI is the main “front-end” that makes it easy to emit those opcodes from C++.

Where these come from:
- SFPI headers: `sfpi/include/sfpi.h` and `sfpi/include/blackhole/sfpi_hw.h`
  - they wrap builtins like `__builtin_rvtt_bh_sfpmad`, `__builtin_rvtt_bh_sfpstore`, …
- ISA semantics: `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/` (Vector Unit / SFPU instruction docs)

---

## 3) Can you “issue raw SFPI ops” without the compiler?

Yes, but you need to be precise about what you mean:

### 3.1 If you mean “compile SFPI C++ without SFPI GCC”

Not realistically.

SFPI relies on compiler builtins (example guard in `sfpi/include/sfpi.h`):
- `__builtin_rvtt_synth_opcode` must exist
- a large set of `__builtin_rvtt_bh_*` builtins must exist

Without a compiler that implements those builtins, SFPI won’t compile.

### 3.2 If you mean “emit the same SFPU opcodes from Python”

Yes, and this is the promising path.

The disassembly above shows SFPU ops as fixed-width instruction words in the TRISC instruction stream. That means you can:
- encode those opcodes yourself (using ISA docs + sfpi_hw.h constants)
- emit them with `.word 0x…` (assembler) or directly into an ELF `.text` segment (Python ELF writer)

For control flow / predication, you’ll also need to emit the non-obvious “support” ops that SFPI inserts:
- condition code ops (`sfpsetcc`, `sfpencc`, `sfppushc/sfppopc`)
- RWC manipulation (`ttsetrwc`, `ttincrwc`)
- replay / macro sequencing (`ttreplay`, and how `__instrn_buffer` is used)

---

## 4) How feasible is “raw RISC‑V kernels” (no compiler toolchain)?

### 4.1 BRISC/NCRISC dataflow: high feasibility

For pure data movement kernels:
- You can write “normal” RV32 code that does:
  - mailbox wait (GO)
  - CB pointer math
  - NOC command buffer MMIO programming
  - polling barriers + `fence`
- You do not *need* SFPU/Tensix compute opcodes.

Practical minimal tooling:
- either “any RV32 toolchain + `.word` where needed + TT linker scripts”
- or “Python emits ELF + raw instructions”

### 4.2 TRISC compute: medium feasibility (but doable)

To run compute kernels without SFPI GCC, you must be able to emit:
- TT’s custom SFPU opcodes
- TT’s TRISC helper opcodes (replay, RWCs, stalls/mops)

You can still avoid “a compiler” by using:
- a tiny assembler that only knows:
  - RV32 base instructions
  - `.word` for TT custom ops
- or a Python emitter that never invokes `as/ld` at all.

The hard part is not “ELF”, it’s “getting the SFPU instruction stream exactly right”.

---

## 5) A realistic replacement plan (incremental)

### Phase A: stop depending on “C++ compilation” for dataflow

Goal: BRISC/NCRISC kernels generated from Python as RV32 + linker script.

Implementation sketch:
- Implement a tiny encoder for RV32I + a handful of pseudo ops (or embed `riscv-tt-elf-as` but only for `.S`).
- Directly emit the NOC MMIO sequences shown in `noc_nonblocking_api.h`.
- Keep using TT-metal linker scripts so load addresses and ABI match firmware expectations.

### Phase B: keep SFPI, but shrink it to “binutils + objdump” (optional)

If the complaint is “SFPI is bloated”, the pragmatic move is to ship only:
- `riscv-tt-elf-as`, `riscv-tt-elf-ld`, `riscv-tt-elf-objcopy`, `riscv-tt-elf-objdump`

and drop:
- C++ front-end, libstdc++, gdb, gcov, etc.

This still lets you author kernels as assembly + `.word` for custom ops.

### Phase C: TRISC compute without SFPI GCC

Goal: generate TRISC compute code from Python with explicit SFPU instruction emission.

Implementation sketch:
- Start with a “known-good” minimal SFPU sequence (e.g. ReLU) and reproduce the opcode stream.
- Use disassembly as a golden reference while building your encoder.
- Only then scale up to richer SFPU ops (exp/log/gelu, etc.).

---

## 6) Practical offline workflow (no device access)

### Compile kernels offline (pure Python wrapper)

`blackhole-py/codegen.py` already implements “TT-metal-like” kernel compilation and packaging:
- it generates minimal genfiles (`kernel_includes.hpp`, `chlkc_*.cpp`, descriptor headers)
- it links against a “weakened” firmware ELF using `--just-symbols=…`

### Disassemble

Use either:
- `tt-metal/runtime/sfpi/compiler/bin/riscv-tt-elf-objdump -d -S <elf>`
- or the helper script `disasm_kern.py` in the repo root (writes a markdown report).

---

## Appendix: where to read “what an instruction does”

SFPU/Tensix ISA docs:
- `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/`

MMIO + NoC programming:
- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc_nonblocking_api.h`
- `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`

SFPI builtin surface area:
- `sfpi/include/sfpi.h`
- `sfpi/include/blackhole/sfpi_hw.h`

