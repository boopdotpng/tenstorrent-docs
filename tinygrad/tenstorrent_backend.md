# Tinygrad Tenstorrent backend (blackhole, pure python driver)

This document describes what it takes to add a Tenstorrent backend to tinygrad using only:
- the kernel driver (tt-kmd via /dev/tenstorrent/*),
- a pure Python runtime (similar to tinygrad's AMD driver approach),
- the Tenstorrent RISC-V compiler toolchain for kernels,
- no tt-metal/ttnn runtime dependencies.

It also captures where to put the code, the structure tinygrad expects, and the tests that need to pass.

## Scope and goals

- Target: Blackhole cards first (p100a/p150a).
- Runtime level: raw PCIe + IOCTL + BAR/TLB mapping, modeled after `~/tenstorrent/pure-py`.
- Compile: use the Tenstorrent RISC-V toolchain (SFPI) to produce kernels; no other TT deps.
- Tinygrad style: minimal, readable, no file-spam, keep logic tight.

## Required tinygrad pieces

A tinygrad backend is a **Compiled device** plus a **renderer + compiler** and a **runtime** that can run kernels. Minimal interface:

- `Allocator`: alloc/free + copyin/copyout (and optional `_offset`, `_as_buffer`, `_transfer`).
- `Renderer`: render UOps to a source string (or an IR) the compiler understands.
- `Compiler`: compile the source string to a binary kernel.
- `Program` runtime: accept buffers + launch dims, then actually execute on hardware.
- `Device`: wire it all together and add it to `Device.DEFAULT` selection.

Key tinygrad files to follow:
- `tinygrad/device.py` (Compiled, Allocator, Compiler, Device registry)
- `tinygrad/renderer/` (renderers and kernel source generation)
- `tinygrad/runtime/ops_*` (backend implementations)

## Files to add (tinygrad tree)

Minimum set of new files:

- `tinygrad/runtime/ops_tt.py`
  - `TTDevice(Compiled)`
  - `TTAllocator(Allocator)`
  - `TTProgram` (runtime launcher)
  - `TTCompiler` (wraps riscv-tt-elf toolchain)
  - `TTRenderer` (UOps -> TT kernel source)
- `tinygrad/runtime/support/tenstorrent/`
  - `ioctl.py` (ctypes structs + IOCTL numbers, port from `~/tenstorrent/pure-py/autogen.py` or `tt-kmd/ioctl.h`)
  - `device.py` (open `/dev/tenstorrent/N`, query mappings, mmap BARs)
  - `tlb.py` (allocate/configure/free TLB windows, map/unmap)
  - `memory.py` (pin/unpin pages, DMA buffers)
  - `noc.py` (NoC address helpers, tile coordinate encoding)
  - `layout.py` (tile layout tables; can reuse `~/tenstorrent/pure-py/device_layout.py`)
  - `arc.py` (ARC message queue access if needed; see `tt-umd` arc queue docs)
  - `kernel.py` (ELF loading + L1 write helpers; can reuse `tinygrad/runtime/support/elf.py` for parsing)

Tinygrad file(s) that must be touched:

- `tinygrad/device.py`
  - add `TT` to `ALL_DEVICES` so it enumerates in `Device.DEFAULT`

Optional (only if you need device-specific codegen or helpers outside runtime):

- `tinygrad/renderer/tt.py` (if the renderer is big and you want to keep `ops_tt.py` short)
- `tinygrad/runtime/support/compiler_tt.py` (if you want compiler code outside `ops_tt.py`)

## Host-side runtime: what it must do

This is the minimum bring-up path, based on `~/tenstorrent/pure-py` and `tt-kmd/ioctl.h`:

1. **Open device**
   - `os.open("/dev/tenstorrent/0", os.O_RDWR | os.O_CLOEXEC)`
   - `TENSTORRENT_IOCTL_GET_DEVICE_INFO` for vendor/device id.
   - Map BARs with `TENSTORRENT_IOCTL_QUERY_MAPPINGS` + `mmap`.
   - Optional sanity: read ARC boot status (pure-py reads BAR0 at 0x230408).

2. **Memory allocation**
   - Option A (host pinned): `TENSTORRENT_IOCTL_PIN_PAGES` to get physical/IOVA and optional NoC address.
   - Option B (device DMA buffer): `TENSTORRENT_IOCTL_ALLOCATE_DMA_BUF` if you want a kernel-visible buffer managed by driver.
   - Unpin/free on buffer free.

3. **NoC access**
   - Allocate + configure a TLB window (`TENSTORRENT_IOCTL_ALLOCATE_TLB`, `TENSTORRENT_IOCTL_CONFIGURE_TLB`).
   - Use mapped window to read/write L1 or DRAM via NoC addresses.

4. **Kernel execution**
   - Load kernel binary into the appropriate memory (likely L1) and set up runtime arguments.
   - Trigger RISC-V core(s) to run the kernel, then wait for completion.

This is the critical missing piece: TT kernels are not “just a function call.” You must replicate minimal tt-metal runtime behavior to load and start kernels.

Relevant docs and code references:
- `~/tenstorrent/pure-py/main.py` (IOCTL + TLB + BAR mapping example)
- `~/tenstorrent/tt-kmd/ioctl.h` (IOCTLs and structs)
- `~/tenstorrent/tt-umd/device/api/umd/device/arc/blackhole_arc_message_queue.hpp` (ARC queue)
- `~/tenstorrent/tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp` (ARC register offsets)
- `~/tenstorrent/boop-docs/blackhole-architecture/04_programming_model.md` (execution model)

## Kernel compilation path (no tt-metal runtime)

You said “use their RISC-V compiler and nothing else.” That implies:

- A **TT-specific renderer** that emits C/C++ suitable for `riscv-tt-elf-g++`.
- Use SFPI intrinsics to target SFPU / Tensix ops when you want speed.
- The compiler produces an ELF for RISC-V cores; you must still load it, set args, and trigger execution.

Suggested practical approach:

1. **Phase 1 (bring-up):**
   - Use RISC-V cores for simple scalar compute (slow but correct).
   - Keep kernel launch at 1 tile, single core, no vectorization.
   - Goal: pass correctness tests even if slow.

2. **Phase 2 (performance):**
   - Emit SFPI/SFPU compute for elementwise, then reduce, then matmul.
   - Use NoC DMA to move tiles in/out of L1 with RISC-V “data movement” cores.

This maps to the programming model in `boop-docs/blackhole-architecture/04_programming_model.md` and the tt-metal example `add_2_integers_in_riscv.md`.

## Renderer requirements (tinygrad -> TT kernel source)

Renderer responsibilities:
- Choose index mapping (global/local). A minimal backend can treat the kernel as 1D and ignore local dims.
- Generate load/store from TT buffers. Start with L1 buffers and host-managed DRAM addresses.
- Emit a single kernel entry point with parameters matching tinygrad’s `ProgramSpec`.

Minimum viable renderer decisions:
- `has_local = False` if you don’t support local size yet.
- `has_threads = False` until you map threads to tile coords.
- Emit scalar loops for `Ops.RANGE` and use explicit indexing.
- Use simple `global_size = [N,1,1]` mapping.

## Runtime interface in tinygrad terms

`TTProgram.__call__` needs to accept:
- `*bufs`: device buffers from the allocator (must carry enough info to access L1/DRAM).
- `global_size`, `local_size`: launch dims from `ProgramSpec`.
- `vals`: runtime variable values.
- `wait`: allow synchronous completion.

Tinygrad expects you to:
- Compile source -> binary once (cache in `Compiler.compile_cached`).
- On call, set kernel args, launch, optionally synchronize.

## Tests that must pass

Tinygrad policy is: **no functionality change without tests**. For a new backend, you need two categories:

### 1) Core tinygrad tests on the TT device

Run with device selected (`TT=1` or `DEV=TT`):

- `python -m pytest test/test_ops.py`
- `python -m pytest test/test_uops.py`
- `python -m pytest test/test_uops_stats.py`
- `python -m pytest test/test_const_folding.py`
- `python -m pytest test/test_method_cache.py`
- `python -m pytest test/test_kernel_cache.py`
- `python -m pytest test/test_transcendental.py`
- `python -m pytest test/test_setitem.py`

If you support zero-copy (host-visible buffers), add:
- `python -m pytest test/test_zero_copy.py`

### 2) New backend-specific tests

Add `test/device/test_tt.py` with at least:

- Device open + info query (skip if `/dev/tenstorrent/*` missing)
- Buffer alloc/copyin/copyout round-trip
- Simple kernel run (elementwise add) using your TTProgram path
- Synchronization correctness (kernel completion waits)

This is critical: it ensures the IOCTL + TLB + kernel path doesn’t regress.

## “Tinygrad way” guidance

- Keep the backend lean. Prefer a small, readable `ops_tt.py` that delegates to minimal helpers.
- Avoid deep layers. If a helper isn’t reused, keep it in the main file.
- Build in phases: bring-up + correctness first, then performance.
- Don’t add huge new modules until you hit real complexity.
- Use tinygrad’s existing abstractions (Allocator/Compiled/Renderer/Compiler). Don’t re-invent a framework.

## Suggested initial implementation structure

**Step 1: Device + allocator only**
- Implement `TTAllocator` with pinned host pages and/or DMA buffers.
- Support `_copyin`, `_copyout`, `_offset`, and `_as_buffer` if you can map host memory.
- Add `TTDevice` that exposes `allocator` and `synchronize` (even if it’s a no-op).

**Step 2: “Null kernel” runtime**
- Implement `TTCompiler` that just returns the source bytes (for testing render path).
- Implement `TTProgram` that does nothing but return quickly.
- Run renderer-only tests (`test/test_uops.py` will exercise render).

**Step 3: Real kernel execution**
- Use riscv-tt-elf-g++ to compile kernels.
- Load kernel ELF into L1 (or a known region) and trigger execution.
- Add kernel args ABI (registers or memory-mapped argument block).

**Step 4: Expand kernel coverage**
- Start with scalar elementwise ops.
- Then reductions (sum, max) using RISC-V loops.
- Then move compute into SFPU for speed.

## Environment variables and toolchain path

You will likely need an env var for the compiler path, for example:

- `TT_RISCV_GPP=/path/to/riscv-tt-elf-g++`

In tt-metal, the toolchain lives under `tt-metal/runtime/sfpi/compiler/bin/` and is named `riscv-tt-elf-g++`.

## Open questions you’ll need to answer (early)

- **Kernel ABI:** how to pass args + launch dims into RISC-V code? (tt-metal does this; you can copy the ABI.)
- **Start/stop:** how to trigger RISC-V kernel execution without tt-metal? (ARC queue or MMIO registers.)
- **Memory model:** where to place kernel text/data? Which L1 region is safe?
- **NoC addressing:** how to map tile coords and DRAM bank addresses for read/write.

You can find most of these in tt-metal/tt-umd, but the goal is to reimplement the minimum, not to import them.

## Notes and source pointers

- Pure python driver reference: `~/tenstorrent/pure-py/main.py` and `~/tenstorrent/pure-py/autogen.py`.
- IOCTL definitions: `~/tenstorrent/tt-kmd/ioctl.h`.
- ARC queue docs: `~/tenstorrent/tt-umd/device/api/umd/device/arc/blackhole_arc_message_queue.hpp`.
- Host queue memory regions: `~/tenstorrent/tt-umd/src/firmware/riscv/blackhole/host_mem_address_map.h`.
- Programming model: `~/tenstorrent/boop-docs/blackhole-architecture/04_programming_model.md`.
- Example kernel flow: `~/tenstorrent/tt-metal/tt_metal/programming_examples/add_2_integers_in_riscv/add_2_integers_in_riscv.md`.
