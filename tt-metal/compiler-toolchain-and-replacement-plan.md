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

