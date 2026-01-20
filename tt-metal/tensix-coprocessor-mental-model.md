# Tensix coprocessor mental model (SrcA/SrcB/Dst, SFPU vs FPU, SFPI, init_sfpu)

This note is a “how to think about it” doc for Tensix compute: what the major units are, what the main register files look like, and how TT-Metal’s `init_sfpu` + SFPI map onto the underlying hardware.

## Scope note (Blackhole vs Wormhole)

You said you’re interested in **Blackhole**.

- The **overall mental model** (Dst as the hub, SFPU/LReg is 32×32-bit SIMD, pack/unpack plumbs tiles in/out, `init_sfpu` configures that plumbing) applies to both Wormhole and Blackhole.
- The **Blackhole ISA docs** cover SFPU/`Dst`/`LReg` well, and include “what changed vs Wormhole” notes in the SFPU page.
- The **Blackhole ISA docs currently appear to be missing** a few key pages (notably `MatrixUnit.md` and `SrcASrcB.md`), so this doc links to the Wormhole versions for those specifics until Blackhole equivalents land.

Primary references (worth skimming in parallel):

- ISA docs: `tt-isa-documentation/WormholeB0/TensixTile/README.md`
- SFPU (Vector Unit): `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/VectorUnit.md`
- FPU (Matrix Unit): `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MatrixUnit.md`
- Register files: `.../TensixCoprocessor/Dst.md`, `.../SrcASrcB.md`, `.../LReg.md`, `.../RWCs.md`
- TT-Metal init: `tt-metal/tt_metal/include/compute_kernel_api/eltwise_unary/eltwise_unary.h:17`

## What “the Tensix coprocessor” is (from a programmer POV)

Treat a Tensix tile as a small heterogeneous machine with:

- A matrix engine (often called “FPU” in TT docs) that consumes `SrcA`/`SrcB` and accumulates into `Dst`.
- A SIMD vector engine (often called “SFPU”) that does 32-lane FP32 / int32-ish operations, primarily by streaming vectors through `LReg` and reading/writing `Dst`.
- Dedicated unpack/pack engines that move tiles between L1 circular buffers and the coprocessor register files (`SrcA`/`SrcB`/`Dst`), doing format conversion / tile layout work along the way.
- Hardware address counters (`RWCs` for math/SFPU, `ADCs` for pack/unpack) so most instructions can “auto-walk” the right rows without software doing explicit address arithmetic.

In TT-Metal kernels, a very common pattern is:

1. Configure unpack/pack + math datapath (`init_sfpu(...)`, `matmul_init(...)`, etc.).
2. For each tile:
   - Acquire a `Dst` tile slot (`tile_regs_acquire()`).
   - Unpack/move input tile(s) into `Dst` (e.g., `copy_tile(...)`).
   - Run math (either SFPU/SFPI or FPU ops) reading/writing `Dst`.
   - Commit/wait to hand results to pack (`tile_regs_commit()`, `tile_regs_wait()`).
   - Pack out of `Dst` back to an output CB (`pack_tile(...)`).
   - Release the slot (`tile_regs_release()`).

## SFPU vs FPU (it’s not scalar vs vector)

The naming is confusing if you come in expecting “FPU = scalar float”.

- **Matrix Unit (FPU)**: specialized low-precision matrix/elementwise engine. Inputs live in `SrcA`/`SrcB` (≤19-bit internal representation), results accumulate into `Dst` (16-bit or 32-bit view). It’s the throughput monster for matmul-ish things.
  - Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MatrixUnit.md`

- **Vector Unit (SFPU)**: general-purpose SIMD engine. It operates on **32 lanes of 32-bit values** and has a small register file `LReg[17][32]`. It’s the flexible tool for elementwise math, bit tricks, conversions, compares/predication, etc.
  - Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/VectorUnit.md`

The “scalar” part of a TT-Metal compute kernel is the RISC-V control code (loops, address arithmetic, kernel control flow). The SFPU is still vector/SIMD.

## The big three register files: `SrcA`, `SrcB`, `Dst`

### `SrcA` / `SrcB` (FPU operands)

`SrcA` and `SrcB` are best thought of as *staging SRAMs* for the matrix engine:

- **Shape:** 2 banks × 64 rows × 16 columns × 19-bit data.
- **Double-buffering:** one bank can be filled by an unpacker while the other is consumed by the matrix unit.
- **Client gating:** a bank has an `AllowedClient` (unpackers vs matrix unit); instructions will wait/stall if the wrong unit tries to use it.

Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/SrcASrcB.md`

### `Dst` (accumulator + shared scratch)

`Dst` is the “hub” register file:

- **Storage:** `uint16_t DstBits[1024][16]` (+ 1024 validity bits).
- **Two common views:**
  - `Dst16b`: 1024×16 of 16-bit values (bf16/fp16/int16-ish).
  - `Dst32b`: 512×16 of 32-bit values (fp32 or 32-bit sign/magnitude int).

Many different units touch `Dst`:

- Matrix Unit accumulates/writes into `Dst`.
- Unpacker 0 can write into `Dst`.
- Packers read from `Dst` to write back to memory/CB.
- SFPU moves between `Dst` and `LReg` via `SFPLOAD` / `SFPSTORE`.

Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/Dst.md`

## SFPU registers: `LReg` (and what “32-wide” really means)

The SFPU’s operand registers are `LReg`:

```c
union {uint32_t u32; int32_t i32; float f32;} LReg[17][32];
```

- 17 vector registers.
- Each register is **32 lanes**, each lane **32 bits**.
- Lanes are often visualized as a 4×8 grid because some cross-lane ops use that structure.

Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/LReg.md`

### How SFPU touches tiles: `SFPLOAD` / `SFPSTORE`

The SFPU does not “magically operate on a whole 32×32 tile in one instruction”.

- `SFPLOAD` moves **up to 32 datums** from **even or odd columns of four consecutive `Dst` rows** into one `LReg[VD]`.
- `SFPSTORE` writes a vector back from `LReg[VD]` into that same 4-rows × 8-cols (even/odd) pattern.

Those vectors are exactly the granularity SFPI exposes as `vFloat` / `vInt` / `vUInt`.

Refs:
- `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/SFPLOAD.md`
- `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/SFPSTORE.md`

### Addressing is via `RWCs`

Both the Matrix Unit and the SFPU use per-thread RWCs (auto-increment counters) to decide *which rows* of `Dst`/`SrcA`/`SrcB` are being accessed.

Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/RWCs.md`

The upshot for kernel authors: you almost never compute “row indices” directly; you rely on whatever LLK/API init set up for RWCs + address modifiers.

## SFPI vs “SFPU instructions”

- **SFPU** is the hardware vector unit.
- **SFPI** is the *C++ programming interface + toolchain* (`~/tenstorrent/sfpi`) that compiles your C++ vector code into SFPU instructions (`SFP*` opcodes).

In the ISA docs you’ll see names like `SFPMAD`, `SFPADD`, and also `SFPIADD`. Those are all SFPU opcodes; `SFPIADD` is just one of the instruction mnemonics.

## The SFPI mental model in TT-Metal kernels

You’ll see code like this:

```cpp
constexpr uint32_t vectors_per_tile = 32;
for (uint32_t v = 0; v < vectors_per_tile; ++v) {
  sfpi::dst_reg[v] = sfpi::dst_reg[v] + scalar;
}
```

The easiest way to think about **it**:

- `sfpi::vFloat` is a **32-lane** vector value (one “SFPU vector”).
- `sfpi::dst_reg[i]` is a convenient *view* of “the current `Dst` tile slot” broken into **32 vectors** (which is why you commonly see `vectors_per_tile = 32`).
  - Intuition: a 32×32 tile has 1024 scalars; 1024 / 32 lanes = 32 vector chunks.
- Under the hood, the SFPI toolchain + LLK plumbing turns those reads/writes into `SFPLOAD`/compute/`SFPSTORE` sequences (often using `SFPLOADMACRO` for throughput when configured).

Example kernel: `tt-metal/tt_metal/programming_examples/add1_sfpu/kernels/compute/add1_sfpi.cpp:1`

### When `SFPLOADMACRO` matters

`SFPLOADMACRO` is the mechanism to get more than “one SFPU sub-op per cycle” by scheduling simple/MAD/round/store sub-ops behind a load.

Ref: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/SFPLOADMACRO.md`

Most TT-LLK ops are written to take advantage of this; hand-written SFPI can be correct-but-slower if it compiles to a naive load/compute/store stream.

## What `init_sfpu(icb, ocb)` actually does in TT-Metal

In TT-Metal, `init_sfpu(icb, ocb)` is a convenience wrapper for “set up the standard unpack → `Dst` → math → pack path for SFPU-style elementwise kernels”.

It does **not** “turn on the SFPU” (it’s there already); it programs the surrounding datapath so tiles can be moved in/out correctly and so the threads agree on formats and synchronization.

Definition:

- `tt-metal/tt_metal/include/compute_kernel_api/eltwise_unary/eltwise_unary.h:47`

Implementation highlights (via `unary_op_init_common`):

- **UNPACK thread**:
  - `llk_unpack_hw_configure<DST_ACCUM_MODE, true>(icb)`
  - `llk_unpack_A_init<...>(..., icb)`
  - This binds *which CB* the unpacker pulls from, and configures format conversion / face shape based on that CB’s metadata.
- **PACK thread**:
  - `llk_pack_hw_configure_disaggregated<DST_ACCUM_MODE, false>(ocb)`
  - `llk_pack_init<false>(ocb)`
  - `llk_pack_dest_init<DST_ACCUM_MODE, false>()`
  - This binds the output CB and configures how to read from `Dst` and emit tiles.
- **MATH thread**:
  - `llk_math_eltwise_unary_datacopy_init<A2D, DST_ACCUM_MODE, ...>(icb)`
  - `llk_math_pack_sync_init<DST_ACCUM_MODE>()`
  - `llk_math_hw_configure(icb, icb)`
  - This configures math-side expectations (formats, face count) and the pack↔math synchronization protocol.

Refs (Wormhole paths shown, Blackhole has analogous headers):

- `tt-metal/tt_metal/hw/ckernels/wormhole_b0/metal/llk_api/llk_unpack_common_api.h:21`
- `tt-metal/tt_metal/hw/ckernels/wormhole_b0/metal/llk_api/llk_pack_api.h:67`
- `tt-metal/tt_metal/hw/ckernels/wormhole_b0/metal/llk_api/llk_math_unary_datacopy_api.h:45`
- `tt-metal/tt_metal/hw/ckernels/wormhole_b0/metal/llk_api/llk_math_common_api.h:24`

### Practical implications

- If you change which CBs you read/write, call `init_sfpu` (or the relevant init) with the new CB indices.
- If you change data formats (bf16 vs fp16 vs fp32) or face count/tiling behavior, you usually need a different LLK init or reconfig path; “it’s just `dst_reg` math” is only true once the unpack/pack plumbing is configured to feed the SFPU correctly.
