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
