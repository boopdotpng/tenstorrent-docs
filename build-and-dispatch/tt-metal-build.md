# TT-Metal kernel build, loading, and worker boot

This is a reference to the recorded TT-Metal stack. Current blackhole-py has a
separate [runtime and firmware builder](blackhole-py-runtime.md); its L1 layout,
entry table, and command protocol must not be mixed with these interfaces.
Board-management ARC/SMC/DMC firmware is covered in [Firmware](../firmware/README.md).

## Compile a kernel for its controllers

TT-Metal's JIT build combines user source, architecture headers, generated
configuration, and the SFPI-enabled toolchain. Dataflow kernels target
BRISC/NCRISC; a compute source produces separate unpack, math, and pack TRISC
ELFs. The assignment is a software convention.

Generated files describe unpack/pack formats, tile dimensions, math fidelity,
approximation mode, Dst precision/synchronization, and wrapper entry points
such as `chlkc_unpack.cpp`, `chlkc_math.cpp`, and `chlkc_pack.cpp`. They are part
of the compiled kernel's contract, not optional decoration.

| Build input | Why it matters |
|---|---|
| Architecture and processor flags | Select the target instruction set and lowering |
| Generated descriptors and defines | Specialize format, dimensions, and execution behavior |
| Processor linker script | Define code/data placement and entry conventions |
| Runtime support objects | Supply required low-level helpers |
| Firmware symbol image | Resolve symbols shared with resident firmware |

The recorded build links against a weakened firmware ELF using
`--just-symbols`. Firmware weakening changes symbol binding/visibility so kernel
data does not accidentally resolve as an inappropriate absolute firmware
symbol. Linking against an arbitrary firmware ELF is not an equivalent shortcut.

Source entry points: `tt_metal/jit_build/genfiles.cpp`, the build implementation,
Blackhole processor linker scripts, and the generated command lines beside
the artifacts. Treat flags and paths as checkout-specific.

## Find and inspect the exact image

The recorded cache root is `~/.cache/tt-metal-cache/<git_hash>/<build_key>/`.
Kernel directories contain processor-specific ELFs; firmware has separate build
keys. Watcher can emit `generated/watcher/kernel_names.txt` and
`kernel_elf_paths.txt`, which are better identifiers than guessing the newest
cache directory.

Disassemble the ELF used by the run with the matching Tenstorrent objdump. If
loading applies an XIP transformation, inspect the transformed image too.
Record source, descriptors, firmware symbols, and toolchain with a reproducer.
A source-only diff does not identify every input that can change generated code.

## ELF and XIP loading

ELF program headers describe loadable segments, addresses, sizes, and zero-fill
requirements. TT-Metal's XIP path performs relocation/address transformation
before packing a contiguous image. Simply concatenating original `PT_LOAD`
bytes is **not** a general equivalent: relocations, alignment, segment memory
sizes, entry points, and local-memory initialization must remain consistent.

The kernel configuration region also contains runtime arguments, common
arguments, local/remote CB configuration, and kernel text offsets. Offsets
come from the host layout builder and matching firmware headers. An address
observed in an old add1 run is not a permanent Blackhole ABI constant.

`get_arg_val<T>` reads the kernel's configured runtime-argument area; common
arguments use their corresponding base. Parameter types and offsets must match
the host's packed layout.

## Worker boot and launch are separate operations

Boot establishes resident firmware and shared runtime state:

1. Hold the relevant worker RISCs in reset.
2. Load firmware segments and initialize required memory.
3. Set reset entry points and the BRISC bootstrap as required by the architecture.
4. Initialize mailbox state and runtime bank tables.
5. Release the prescribed controllers and wait for firmware readiness.

A subsequent kernel launch supplies code/configuration, per-core arguments,
`launch_msg_t`, and a GO signal. Completion follows the firmware's mailbox or
dispatch protocol. Launch readiness and backend data-transfer completion must
both be respected before reusing storage.

Fast dispatch adds resident command-processing kernels. Those are distinct from
worker firmware and from the board's boot firmware. The
[dispatch reference](tt-metal-dispatch.md) describes their roles.

## When reproducing the flow outside TT-Metal

Decide which contract is being reproduced: TT-Metal's firmware/launch ABI, or a
new runtime with its own ABI. Do not mix one runtime's linker assumptions with
another's L1 allocation. For TT-Metal parity, retain generated descriptors,
firmware symbol exports, image transformations, mailbox layout, and completion
semantics. For current blackhole-py, read its actual C firmware builder and
Python image emitters instead of following the removed pure-py port plan.
