# Tinygrad + Tenstorrent backend notes (Blackhole)

This file merges the TT backend design doc, SFPI layout notes, and the 2026-01 audit.

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

## Renderer details: what tinygrad feeds it

Tinygrad’s renderer takes a **linearized list of UOps** for a single kernel. This list is already fully lowered:
loads, stores, index math, loops (`Ops.RANGE`/`Ops.END`), and workitem IDs (`Ops.SPECIAL`) are explicit.
The renderer never sees a high-level “matmul”; it sees straight-line kernel IR.

Relevant code path:
- `tinygrad/codegen/__init__.py` (`get_program`, `do_linearize`, `do_render`)
- `tinygrad/renderer/__init__.py` (`ProgramSpec.from_uop`)
- `tinygrad/renderer/cstyle.py` (`CStyleLanguage.render`)

## AMD renderer complexity (baseline for TT)

AMD’s C-style renderer is not huge. It builds on `CStyleLanguage` and adds:
- workitem intrinsics (`__ockl_get_*`)
- barriers and local memory annotations
- type maps for bf16/fp8
- tensor core intrinsics and wrapper glue
- extra headers/prefix code in `render_kernel`

Files:
- `tinygrad/renderer/cstyle.py` (CStyleLanguage + AMD HIP renderer)
- `tinygrad/renderer/llvmir.py` (AMD LLVM renderer)

The core pattern-match rules live in `CStyleLanguage`. AMD adds a relatively thin layer on top.

## TT’s 3-kernel model in tinygrad terms

Tinygrad expects **one ProgramSpec per kernel**. TT typically needs three kernels (reader, compute, writer).
The least invasive approach is:

- Renderer emits multiple sources (BRISC/NCRISC/TRISC).
- Compiler builds all of them and bundles the outputs into one `lib` blob.
- `TTProgram.__call__` unpacks and launches all three cores, then syncs.

This keeps tinygrad’s core IR and scheduler unchanged.

## L1 reuse: how often and where it matters

Cross-kernel L1 reuse is likely **rare** in a default tinygrad flow, because tinygrad already fuses long
elementwise chains into a single kernel. The critical L1 reuse is **within** each kernel’s reader/compute/writer trio.

Practical expectations by kernel type:

- Elementwise chains: fused, L1 reuse is intra-kernel only.
- Reductions / layernorm stats: L1 reuse is important inside the kernel; cross-kernel reuse is uncommon.
- GEMM / conv: heavy L1 tiling inside the kernel; cross-kernel reuse usually not needed.
- Attention: strong L1 reuse inside each matmul/softmax; cross-kernel reuse only if you write fused attention kernels.
- Norm + residual + activation: cross-kernel reuse only if you fuse; otherwise DRAM between kernels.

So: you can ship a correct backend without persistent L1 across kernels, as long as each TT kernel stages
tiles in L1 for its own reader/compute/writer flow.

## Launch shape and BEAM constraints for TT

TT kernels do not expose GPU-style threads/workgroups. Expect one launch shape per kernel and no local size tuning.

Recommended renderer defaults:
- `has_threads = False`, `has_local = False`
- ignore `local_size`, and treat `global_size` as a single scalar range
- avoid emitting `Ops.SPECIAL` for workitem IDs unless you define a TT-specific mapping

This implies BEAM/local/global tuning should be disabled or ignored for TT:
- ensure no tensor-core or workgroup-dependent opts are applied
- keep opts focused on algebraic transforms, not launch dims

## Tiling parameters

TT kernels still need explicit tiling, even without threads. The simplest path is to pass tiling
parameters as kernel arguments and let the kernel implement the reader/compute/writer loops using those args.
# Tinygrad TT backend (tt-metal toolchain): layout + SFPI bringup notes

This captures the root causes behind `tinygrad/test.py` not working on Blackhole, what fixes were needed, and what a “templated” TT backend should look like when:
- data movement stays in `tt-llk`-heavy kernels, and
- compute is authored in SFPI.

## Quick checklist (before running any workloads)

- Reset the card (isolates kernel issues from bad device state):
  - `~/tenstorrent/.venv/bin/tt-smi -r`
- Ensure the SFPI RISC-V toolchain is discoverable:
  - Set `TT_METAL_HOME` to your `tt-metal` checkout, or rely on tinygrad’s auto-discovery.

## Root causes

### 1) Toolchain path: `TT_METAL_HOME`

Tinygrad’s TT kernel compiler needs `riscv-tt-elf-g++` and friends from tt-metal’s SFPI toolchain.
If `TT_METAL_HOME` is unset/mis-set, compilation fails (commonly at `riscv-tt-elf-nm` lookup).

Current behavior is: prefer `TT_METAL_HOME`, else search upward for an in-tree `tt-metal/`, else fall back to `/opt/tenstorrent/tt-metal`.

Relevant code:
- `tinygrad/tinygrad/runtime/support/tenstorrent/compiler.py`

### 2) Memory layout mismatch: row-major vs `TILED_NFACES`

tt-metal’s unpack/pack path (and the standard “dataflow + SFPI compute” examples) assume tensors in DRAM are in **tiled layout**. For Blackhole elementwise kernels, the common expectation is `TILED_NFACES`:
- tiles are `32x32`
- each tile is stored as 4 faces (`16x16`) in face order (nfaces)

If you write row-major host buffers directly into DRAM, kernels will “work” only for degenerate cases (like fills), and produce garbage/NaNs for real inputs because unpack interprets the bytes as tiled faces.

Fix approach used here:
- tilize host data *when creating TT tensors from numpy*
- untilize on `Tensor.data()` / `Tensor.numpy()` for TT tensors

Relevant code:
- `tinygrad/tinygrad/runtime/support/tenstorrent/tilize.py`
- `tinygrad/tinygrad/tensor.py`

Practical note:
- This is intentionally a “boundary conversion” hack to get correctness; longer-term, TT should store tensors internally as tiled and only convert when crossing CPU/host boundaries.

### 3) Renderer op selection: avoid matching address math

Tinygrad UOps contain lots of integer `Ops.ADD`/`Ops.MUL` for pointer/index math. A naive “if `Ops.ADD` exists” check will incorrectly emit a binary add kernel even when the kernel is actually a fill/store-const pattern.

The renderer must:
- match compute ops based on **float-typed** ops (not integer address ops)
- only emit true binary kernels when it actually has 2 input globals (in addition to output)
- treat scalar ops (`x * const`, `x + const`) as a unary-scalar kernel (or as binary with an explicit constant tile)

Relevant code:
- `tinygrad/tinygrad/runtime/ops_tt.py`

## SFPI specifics that matter for correctness

### `dst_reg` indexing for binary ops

For `32x32` tiles, the SFPI convention used by shipped tt-metal SFPU examples is:
- iterate `r in [0..31]` per tile
- second operand tile starts at `+32`

In other words:
- `vectors_per_tile = 32`
- `tile_stride = 32`

If you treat a tile as “64 rows” in SFPI space, you’ll read/write the wrong `dst_reg` slots and corrupt results.

Reference:
- `boop-docs/tt-metal/blackhole-kernel-development-audit-sfpi.md`

## What the “templated” backend should look like

Tinygrad’s CUDA-like “emit arbitrary kernels per graph” model doesn’t match Tenstorrent well. A better fit is a small kernel library with a few valid dataflow templates, plus SFPI compute templates:

### Data movement (keep `tt-llk` here)

- `reader_unary`: DRAM → CB0
- `reader_binary`: DRAM → CB0/CB1
- `writer`: CBout → DRAM
- Optional: dedicated tilize/untilize kernels if you want device-side conversions (but host-side is simpler for bringup).

These should be mostly boilerplate, parameterized by:
- CB ids
- data format
- tile_bytes / page_size
- per-core tile ranges

### Compute (SFPI-only)

Compute kernels should be minimal and template-driven:
- `compute_fill(value)`
- `compute_unary(op)`
- `compute_unary_scalar(op, scalar)` (compile-time constant)
- `compute_binary(op)`

All should follow:
- `copy_tile` inputs to Dst slots
- SFPI loop over `dst_reg[0..31]` (+32 for second tile)
- `pack_tile` to output CB

## Debugging tips

- If a kernel times out/hangs, reset the device before retrying:
  - `~/tenstorrent/.venv/bin/tt-smi -r`
- Beware tinygrad constant folding: `Tensor.ones(...) + Tensor.ones(...)` may compile to a fill kernel and won’t validate binary add paths.
  - Use non-constant inputs (e.g. `np.arange`) to validate real readers/unpack.

# Tinygrad + Tenstorrent (Blackhole) backend audit (tt-metal toolchain, SFPI compute)

This is a snapshot of what was required to get `tinygrad/test.py` running on a Tenstorrent Blackhole card, what was actually broken, what we changed, and what’s still missing for a “real” backend.

Baseline assumptions:
- Device: Blackhole (p100a/p150a)
- Kernels compiled with tt-metal’s SFPI toolchain (not using the tt-metal runtime)
- Data-movement kernels can stay `tt-llk`-heavy; compute should be SFPI

## Operational notes

Before running any workloads on device:
- Reset the device to clear any wedged state from prior bad kernels:
  - `~/tenstorrent/.venv/bin/tt-smi -r`

If kernel compilation fails, set:
- `TT_METAL_HOME=/home/boop/tenstorrent/tt-metal` (or your checkout)

## What was wrong (root causes)

### 1) Toolchain discovery (`TT_METAL_HOME`)

The TT compiler wrapper needed tt-metal’s SFPI toolchain (`riscv-tt-elf-g++`, `riscv-tt-elf-nm`, etc). The original code effectively assumed a fixed install path, which broke in a repo checkout setup.

Fix: auto-discover `tt-metal/` via `TT_METAL_HOME` or by walking parent dirs.
- `tinygrad/tinygrad/runtime/support/tenstorrent/compiler.py`

### 2) “DRAM allocation / reading is failing” was actually *layout*

tt-metal’s unpack/pack path expects DRAM tensors in a tiled layout. For typical Blackhole elementwise kernels that means:
- 32x32 tiles
- `TILED_NFACES` (four 16x16 faces per tile)

Tinygrad tensors are row-major by default. If you write row-major host data directly to DRAM and then run a tt-metal-style tiled kernel, unpack interprets the bytes as faces/tiles and you get garbage/NaNs (this looks like “bad DRAM reads”).

Fix for bringup correctness:
- tilize host numpy inputs when creating TT tensors
- untilize on TT `Tensor.data()` / `Tensor.numpy()` so results compare correctly
- `tinygrad/tinygrad/runtime/support/tenstorrent/tilize.py`
- `tinygrad/tinygrad/tensor.py`

### 3) Renderer matched the wrong ops (address math vs compute math)

Tinygrad UOps include lots of integer ops (`Ops.ADD`, `Ops.MUL`) for pointer/index arithmetic. If you match “binary add” just because `Ops.ADD` exists, you can emit a 2-input kernel for a program that has no real 2-input float compute.

Fix: only match compute ops based on float-typed ops and actual global buffer count.
- `tinygrad/tinygrad/runtime/ops_tt.py`

### 4) SFPI `dst_reg` indexing for binary ops (Float32)

For a 32x32 tile, tt-metal’s SFPU/SFPI examples operate over:
- `vectors_per_tile = 32`
- operand tile stride = `+32`

Treating Float32 as “64 SFPI rows per tile” and using `+64` for the second operand corrupts results.

Fix: use `32` rows and `+32` stride for SFPI loops and operand placement.
- `tinygrad/tinygrad/runtime/ops_tt.py`

## What changed (code)

### Toolchain path
- `tinygrad/tinygrad/runtime/support/tenstorrent/compiler.py`
  - Add `_find_tt_metal_home()` and define `TT_METAL_HOME` from env or repo.

### Host tilize/untilize (TILED_NFACES)
- `tinygrad/tinygrad/runtime/support/tenstorrent/tilize.py`
  - Implements `tilize_nfaces_bytes` / `untilize_nfaces_bytes` for tile-aligned shapes.
- `tinygrad/tinygrad/tensor.py`
  - Numpy → TT tensor creation tilizes when shape is rank≥2 and tile-aligned.
  - TT tensor `data()`/`numpy()` untilize on the way out (rank≥2).

### Renderer/kernel selection and SFPI compute
- `tinygrad/tinygrad/runtime/ops_tt.py`
  - Add `dtypes.float` to dtype mapping.
  - Add 0-input constant fill kernel when UOps are a constant store pattern.
  - Add unary-scalar kernel lowering for `x op const` (compile-time scalar).
  - Only emit binary kernels when the kernel truly has 2 input globals.
  - Use `vectors_per_tile=32` and `tile_stride=32` for SFPI row loops and second operand offset.
  - NOC index split matches the known-good pattern: NCRISC on noc0, BRISC on noc1.

## Why `blackhole-py` “worked without tilize”

`blackhole-py` is tile-native:
- It allocates DRAM with `page_size = tile_size_bytes` and treats the buffer as “N tiles of 32x32 elements”.
- Reader/writer use `noc_async_read_tile(i, ...)` / `noc_async_write_tile(i, ...)` by tile index.
- It never interprets the buffer as a row-major `(H,W)` matrix, and validation compares element order in the same flat “tile order”.

So there’s no row-major ↔ tiled mismatch in that workflow; it’s already using the tiled convention end-to-end.
- `blackhole-py/main.py`

## What’s still missing (for a “real” backend)

### Layout + shapes
- Only tile-aligned rank≥2 numpy tensors are tilized/untilized. Anything not divisible by 32 needs padding/masking strategy.
- `.to("CPU")` and non-numpy sources (lists/bytes) are not fully layout-aware (boundary handling is incomplete).

### Views and tinygrad semantics
Tinygrad treats many views as “free” (reshape/permute/expand/shrink fold into index math).
With tiled layout, many of these are not representable as metadata-only views:
- `permute/transpose`: generally requires a real relayout kernel
- `reshape` that changes how `(H,W)` is interpreted: generally a relayout
- arbitrary `shrink/slice`: needs mask/pad or real copy unless tile-aligned

A TT-friendly approach is:
- device tensors are *physically tiled* as the invariant
- only a small subset of views remain views; everything else lowers to a small set of templated data-movement relayout kernels

### Op coverage
Currently bringup targets a tiny set:
- fill, unary, unary-scalar, binary ops for float (as exercised by simple tests)

Missing for broader tinygrad:
- reductions, matmul/conv, broadcasts, where/compare, transcendental ops, etc.

## What the “optimal” backend shape should look like

Tenstorrent doesn’t fit “emit arbitrary CUDA-like kernels per graph” well. A better fit is a small kernel library:

### Data movement (keep tt-llk here)
- One unary reader, one binary reader, one writer
- Optional tilize/untilize kernels if you want device-side conversions (often not needed if TT tensors stay tiled)
- Optional relayout kernels for views that can’t stay metadata-only

### Compute (SFPI-only)
- `fill(value)`
- `unary(op)`
- `unary_scalar(op, scalar)` (scalar baked in)
- `binary(op)`

All compute kernels should follow the same boilerplate:
- `copy_tile` inputs to Dst slots
- SFPI loop over `dst_reg[0..31]`, using `+32` for the second operand tile
- `pack_tile` to output CB

## Debugging guidance

- Always reset after a hang:
  - `~/tenstorrent/.venv/bin/tt-smi -r`
- Beware constant folding: `Tensor.ones(...) + Tensor.ones(...)` can compile down to a fill kernel and won’t validate binary readers/unpack.
  - Use non-constant inputs (e.g. `np.arange`) to exercise real binary kernels.

