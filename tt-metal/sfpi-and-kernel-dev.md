# SFPI and kernel development (Blackhole)

This consolidates SFPI mental models, add1 SFPI kernel notes, dst/srca staging, and the Blackhole SFPI audit.

## add1_sfpu: SFPI-based compute kernel

This note shows how to replace `add_unary_tile` with raw SFPI ops in the `add1_sfpu` programming example.

### What changed

- New compute kernel: `tt-metal/tt_metal/programming_examples/add1_sfpu/kernels/compute/add1_sfpi.cpp`.
- Uses `sfpi::vFloat` and `sfpi::dst_reg` to add a scalar across all 32 vectors in a tile.
- Keeps existing CB flow (`init_sfpu`, `copy_tile`, `pack_tile`) but removes LLK unary ops from the compute path.

### Switch the example to the new kernel

```cpp
KernelHandle add1_kernel_id = CreateKernel(
  program,
  OVERRIDE_KERNEL_PREFIX "add1_sfpu/kernels/compute/add1_sfpi.cpp",
  core,
  ComputeConfig{
    .math_fidelity = MathFidelity::HiFi4,
    .math_approx_mode = false,
  });
```

### Notes

- SFPI code is guarded by `#ifdef TRISC_MATH` since the SFPU is only on the MATH core.
- `sfpi::dst_reg` is indexed by vector; a full 32x32 tile is 32 vectors.
- This approach is compatible with compiler-generated SFPI C++.

### TT-LLK dependencies in the original unary-op kernel

The original compute kernel depends on TT-LLK through these headers and APIs:

- Headers:
  - `compute_kernel_api/eltwise_unary/eltwise_unary.h`
  - `compute_kernel_api/eltwise_unary/binop_with_scalar.h`
  - `compute_kernel_api/tile_move_copy.h`
  - `compute_kernel_api/common.h`
- APIs used:
  - `init_sfpu(...)`
  - `binop_with_scalar_tile_init()`
  - `add_unary_tile(...)`
  - `tile_regs_acquire/commit/wait/release`, `copy_tile`, `pack_tile`, `cb_*`

## SFPU/SFPI: Dst math vs SrcA staging

When you write SFPI like:
```cpp
sfpi::dst_reg[v] = sfpi::dst_reg[v] + 1.0f;
```

the SFPU operates on `Dst` via `SFPLOAD`/`SFPSTORE` (Dst ↔ LReg). Many kernels still use `SrcA` as an intermediate on the data-movement path:

- `copy_tile(...)` is an UNPACK step plus a MATH datacopy that lands in `Dst`.
- For fp16/bf16, the LLK unpack path commonly stages through `SrcA`.
- Unpack directly to `Dst` is a special-case used for 32-bit inputs.

## Tensix coprocessor mental model (SrcA/SrcB/Dst, SFPU vs FPU, SFPI, init_sfpu)

This is a “how to think about it” doc for Tensix compute: what the major units are, what the main register files look like, and how TT-Metal’s `init_sfpu` + SFPI map onto the underlying hardware.

### Scope note (Blackhole vs Wormhole)

- The overall mental model applies to both Wormhole and Blackhole.
- The Blackhole ISA docs currently appear to be missing a few key pages (notably `MatrixUnit.md` and `SrcASrcB.md`), so this doc links to the Wormhole versions for those specifics.

Primary references:
- ISA docs: `tt-isa-documentation/WormholeB0/TensixTile/README.md`
- SFPU (Vector Unit): `.../VectorUnit.md`
- FPU (Matrix Unit): `.../MatrixUnit.md`
- Register files: `.../Dst.md`, `.../SrcASrcB.md`, `.../LReg.md`, `.../RWCs.md`
- TT-Metal init: `compute_kernel_api/eltwise_unary/eltwise_unary.h:17`

### What “the Tensix coprocessor” is (from a programmer POV)

Treat a Tensix tile as a small heterogeneous machine with:
- Matrix engine (FPU) consuming `SrcA`/`SrcB`, accumulating into `Dst`.
- SIMD vector engine (SFPU) operating on 32 lanes of 32-bit values.
- Unpack/pack engines that move tiles between L1 and the register files.
- Hardware address counters (`RWCs` and `ADCs`).

### SFPU vs FPU

- **Matrix Unit (FPU)**: specialized low-precision matrix/elementwise engine. Inputs in `SrcA`/`SrcB`, outputs in `Dst`.
- **Vector Unit (SFPU)**: general-purpose SIMD engine operating on 32×32-bit lanes via LReg and Dst.

### Register files

**SrcA/SrcB**
- 2 banks × 64 rows × 16 columns × 19-bit data
- Double-buffered between unpackers and matrix unit

**Dst**
- `uint16_t DstBits[1024][16]` + valid bits
- Dst16b (bf16/fp16/int) or Dst32b (fp32/int32)

**LReg**
- `LReg[17][32]`, 32 lanes × 32 bits

### SFPLOAD/SFPSTORE granularity

SFPI vectors correspond to 32-lane loads from Dst; address selection uses RWCs configured by LLK.

### What `init_sfpu(icb, ocb)` does

`init_sfpu` configures unpack/pack + math datapath so tiles can be moved in/out and threads agree on formats and sync.


## Full audit notes (verbatim)

# Tenstorrent tt-metal (Blackhole / p100a) Kernel Development Audit (SFPI-first)

Scope: low-level kernel primitives and patterns, with emphasis on SFPI (SFPU) usage over high-level tt-llk wrappers.
Primary code search roots:

- `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/`
- `tt-metal/tt_metal/include/compute_kernel_api/`
- `tt-metal/ttnn/cpp/ttnn/operations/eltwise/`
- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/`
- `tt-metal/tests/`

Key “ground truth” references used heavily below:

- SFPI interface and HW constants: `sfpi/include/sfpi.h`, `sfpi/include/blackhole/sfpi_hw.h`
- Dst register definition (Blackhole ISA doc): `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/Dst.md`
- Compute kernel thread macros + runtime args: `tt-metal/tt_metal/include/compute_kernel_api/common_globals.h`, `tt-metal/tt_metal/include/compute_kernel_api/common.h`
- Address generation + tile-byte math: `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h`
- A known-good SFPI compute example: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`

---

## 0. Execution model refresher (what runs where)

- Dataflow kernels:
  - NCRISC (“reader”, often `DataMovementProcessor::RISCV_1`) pulls from DRAM/L1 → CB(s) in L1.
  - BRISC (“writer”, often `DataMovementProcessor::RISCV_0`) pushes from CB(s) in L1 → DRAM/L1.
  - APIs live in `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`.
- Compute kernel:
  - Single C++ source compiled three times into TRISC0/1/2 threads: UNPACK, MATH, PACK.
  - Thread selection is macro-driven: `UNPACK(...)`, `MATH(...)`, `PACK(...)`, and `MAIN` (`unpack_main/ math_main/ pack_main`) in `tt-metal/tt_metal/include/compute_kernel_api/common_globals.h`.

For a compiler backend, the most important constraint is: compute kernels must explicitly synchronize between UNPACK→MATH→PACK (DST ownership + CB availability).

---

## 1. SFPI operations catalog + Dst (`dst_reg`) layout

### 1.1 What “SFPI” is in tt-metal

SFPI is a C++ wrapper around Tensix SFPU builtins that compiles down to SFPU instructions at `-O` with no runtime overhead (when used as intended): `sfpi/include/sfpi.h`.

It models:

- “local registers” (LREGs): `sfpi::vFloat`, `sfpi::vInt`, `sfpi::vUInt`
- the destination register file (“Dst”): `sfpi::dst_reg[...]` (global object), implemented in `sfpi/include/sfpi.h`

### 1.2 `sfpi::` symbols used inside tt-metal ckernels + bundled tt_llk

Direct `sfpi::...` tokens found under `tt-metal/tt_metal/hw/ckernels/` and `tt-metal/tt_metal/third_party/tt_llk/`:

```
sfpi::abs
sfpi::addexp
sfpi::approx_recip
sfpi::dst_reg
sfpi::exexp
sfpi::exexp_nodebias
sfpi::exman9
sfpi::float_to_fp16b
sfpi::float_to_int16
sfpi::float_to_uint16
sfpi::int32_to_float
sfpi::l_reg
sfpi::LRegs
sfpi::lut
sfpi::reinterpret
sfpi::s2vFloat16
sfpi::s2vFloat16a
sfpi::s2vFloat16b
sfpi::setexp
sfpi::setman
sfpi::setsgn
sfpi::{many SFPU mod constants…}
sfpi::vConst0
sfpi::vConst0p8373
sfpi::vConst1
sfpi::vConstFloatPrgm{0,1,2}
sfpi::vConstIntPrgm{0,1,2}
sfpi::vConstNeg1
sfpi::vec_min_max
sfpi::vFloat
sfpi::vInt
sfpi::vUInt
```

Notes:

- Many SFPI calls appear without the `sfpi::` prefix because kernels frequently do `using namespace sfpi;` (see e.g. `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_relu.h`).
- “Binary ops” like `+`, `*`, comparisons, etc. are implemented via operator overloads on `vFloat` / `__vDReg` (see `sfpi/include/sfpi.h`), so they won’t appear as `sfpi::add` tokens.

### 1.3 The exact hardware layout of Dst, and how tiles map onto it

Blackhole ISA doc (authoritative): `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/Dst.md`.

Dst can be viewed as:

- `Dst16b`: `1024 rows × 16 cols` of 16-bit data
- `Dst32b`: `512 rows × 16 cols` of 32-bit data

Internally:

```
uint16_t DstBits[1024][16];
bool DstRowValid[1024];
```

tt-metal’s compute API models Dst as **16 tiles of 32×32 elements** (see `tile_regs_acquire()` docs in `tt-metal/tt_metal/include/compute_kernel_api/reg_api.h`), and that matches the Dst geometry:

- A 32×32 tile has 1024 elements.
- With `Dst16b`, each Dst row holds 16 elements.
- Therefore **one tile occupies 64 consecutive Dst rows** (`64 * 16 = 1024`).
- `1024 / 64 = 16` tiles → exactly the “16 tiles” model.

This is encoded in LLK math constants for Blackhole:

- `DstTileSize[Tile32x32] = 64`, `DstTileSizeLog2[Tile32x32] = 6` in `tt-metal/tt_metal/third_party/tt_llk/tt_llk_blackhole/common/inc/cmath_common.h`.
- When LLK sets the base for “tile index N”, it does `dst_index = N << 6` (multiply by 64 rows) and uses that as the Dst row base.

### 1.4 `sfpi::dst_reg` index mapping (practical compiler view)

SFPI’s `dst_reg[i]` addresses Dst via a stride constant:

- `SFP_DESTREG_STRIDE = 2` in `sfpi/include/blackhole/sfpi_hw.h`
- SFPI constructs each Dst register address as `i * SFP_DESTREG_STRIDE` (see `__vDReg` in `sfpi/include/sfpi.h`)

In tt-metal kernels, the practical/observed convention for a 32×32 tile is:

- **32 SFPI vectors per tile**
- Each `sfpi::dst_reg[row]` corresponds to **one logical tile row** (32 elements wide).

This is demonstrated by the shipped, working example `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`:

- `constexpr uint32_t vectors_per_tile = 32;`
- Loop does `sfpi::dst_reg[v] = sfpi::dst_reg[v] + scalar;` for `v in [0, 31]`.

Reconciliation with the “Dst rows are 16 columns” view:

- Dst stores “half-rows” of 16 elements.
- SFPI’s `dst_reg[row]` behaves like a 32-wide row by addressing both halves under the hood (this is why the SFPI stride is 2 and why LLK’s “tile size” is 64 rows but SFPI uses 32 rows).

### 1.5 Where `copy_tile(cb, tile_in_cb, dst_idx)` lands in `dst_reg`

Compute API: `tt-metal/tt_metal/include/compute_kernel_api/tile_move_copy.h`.

`copy_tile(in_cb_id, in_tile_index, dst_tile_index)` does:

- UNPACK thread: unpack CB tile → SRC regs (`llk_unpack_A(...)`)
- MATH thread: SRC regs → Dst slot `dst_tile_index` (`llk_math_eltwise_unary_datacopy<A2D>(dst_tile_index, ...)`)

In SFPI terms (Blackhole convention):

- A tile copied to `dst_tile_index = t` occupies `sfpi::dst_reg[t*32 + 0 .. t*32 + 31]`.

So:

- `copy_tile(cb0, 0, 0)` → data in `sfpi::dst_reg[0..31]`
- `copy_tile(cb0, 0, 1)` → data in `sfpi::dst_reg[32..63]`

### 1.6 Binary op placement: if I copy A to `dst_idx=0` and B to `dst_idx=1`

With `copy_tile(..., dst_idx)` used as intended (one full tile per dst slot):

- Tile A (`dst_idx=0`) is in `sfpi::dst_reg[0..31]`.
- Tile B (`dst_idx=1`) is in `sfpi::dst_reg[32..63]`.

This matches Blackhole SFPI/LLK SFPU binary kernels, which often read the second operand at offset `+32` (e.g. `ckernel_sfpu_min.h` reads `dst_reg[0]` and `dst_reg[32]` per iteration).

### 1.7 Working SFPI row-wise code snippets (Blackhole)

All snippets assume:

- You’re in a compute kernel (TRISC) and already did:
  - `init_sfpu(cb_in, cb_out)` (or equivalent init)
  - `tile_regs_acquire()`
  - `copy_tile(..., dst_idx)` for needed inputs
- You will later do:
  - `tile_regs_commit(); tile_regs_wait(); pack_tile(dst_idx, cb_out); tile_regs_release();`

#### Add / Sub / Mul (two tiles)

```c++
constexpr uint32_t kRows = 32;
constexpr uint32_t kTileStride = 32;

for (uint32_t r = 0; r < kRows; ++r) {
  auto a = sfpi::dst_reg[0 * kTileStride + r];
  auto b = sfpi::dst_reg[1 * kTileStride + r];
  sfpi::dst_reg[0 * kTileStride + r] = a + b;      // add
  // sfpi::dst_reg[0 * kTileStride + r] = a - b;   // sub
  // sfpi::dst_reg[0 * kTileStride + r] = a * b;   // mul
}
```

#### Max / Min (two tiles)

```c++
constexpr uint32_t kRows = 32;
constexpr uint32_t kTileStride = 32;

for (uint32_t r = 0; r < kRows; ++r) {
  auto a = sfpi::dst_reg[0 * kTileStride + r];
  auto b = sfpi::dst_reg[1 * kTileStride + r];
  // max:
  v_if(a < b) { a = b; }
  v_endif;
  sfpi::dst_reg[0 * kTileStride + r] = a;

  // min:
  // v_if(a > b) { a = b; }
  // v_endif;
  // sfpi::dst_reg[0 * kTileStride + r] = a;
}
```
Note: tt-metal SFPU kernels typically use predication (`v_if`) for min/max (see `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_max.h`, `.../ckernel_sfpu_min.h`).

#### ReLU (unary, in-place)

```c++
constexpr uint32_t kRows = 32;
for (uint32_t r = 0; r < kRows; ++r) {
  auto x = sfpi::dst_reg[r];
  v_if(x < 0.0f) { x = 0.0f; }
  v_endif;
  sfpi::dst_reg[r] = x;
}
```

#### Exp / Log / Sqrt / Recip / Sigmoid / Tanh

There is no single “one instruction = exp/log/…” in SFPI; tt-metal implements these as SFPI sequences (polynomials, LUTs, bit-twiddling) in the `ckernel_sfpu_*.h` files under:

- `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/`

Practical compiler pattern: call the existing SFPI helpers on each row vector.

Examples (see the referenced files for the exact helper names and accuracy modes):

- Exp: `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_exp.h` (e.g. `_sfpu_exp_21f_`, `sfpu_exp`)
- Log: `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_log.h`
- Sqrt: `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_sqrt.h`
- Recip: `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_recip.h`
- Sigmoid: `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_sigmoid.h`
- Tanh: `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_sfpu/ckernel_sfpu_tanh.h`

Conceptual usage:

```c++
for (uint32_t r = 0; r < 32; ++r) {
  auto x = sfpi::dst_reg[r];
  sfpi::dst_reg[r] = ckernel::sfpu::sfpu_exp(x);  // example; choose the helper you want
}
```

### 1.8 SFPI vs `add_tiles` / `mul_tiles` (what’s different internally)

- SFPI:
  - Generates SFPU (vector unit) instructions via compiler builtins (`sfpi/include/sfpi.h`).
  - Operates “in-place” on Dst (and LREGs), typically after `copy_tile` has staged a tile into Dst.
  - Best suited for transcendental / activation-style ops (exp/log/tanh/sigmoid/etc) and bit-level transforms.
- `add_tiles` / `mul_tiles` (LLK math binary ops):
  - Uses the math pipeline, not SFPU. The compute API calls `llk_unpack_AB(...)` then `llk_math_eltwise_binary<...>(...)` (see `tt-metal/tt_metal/include/compute_kernel_api/eltwise_binary.h`).
  - Typically higher throughput for plain arithmetic because it’s the “native” tile math datapath.

Compiler implication:

- If you want “SFPI-only” kernels, you still must use **UNPACK/PACK machinery** (or equivalent) to move tiles into/out of Dst; the part you avoid is the **LLK math op selection** for arithmetic.

---

## 2. Dataflow kernels: dtype variants + `InterleavedAddrGenFast`

### 2.1 What `InterleavedAddrGenFast<is_dram>` actually does per dtype

Definition: `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h`.

`InterleavedAddrGenFast<DRAM, tile_hw>` computes the base address for “tile/page id `id`” as:

- bank selection: `id → (bank_offset_index, bank_index)`
- address offset: `MUL_WITH_TILE_SIZE<tile_hw>(data_format, bank_offset_index)`

The `MUL_WITH_TILE_SIZE` logic is compile-time and uses `data_format` to compute bytes-per-tile:

- For `tile_hw = 1024` (32×32):
  - `Float32 / Int32 / UInt32`: `index << 12` → `4096` bytes per tile
  - `Float16 / Float16_b / UInt16`: `index << 11` → `2048` bytes per tile
  - `UInt8`: `index << 10` → `1024` bytes per tile
  - `Bfp8 / Bfp8_b`: `index<<10 + index<<6` → `1024 + 64 = 1088` bytes per tile (mantissas + exponents)
  - `Bfp4`: `index<<9 + index<<6` → `512 + 64 = 576` bytes per tile
  - `Bfp2`: `index<<8 + index<<6` → `256 + 64 = 320` bytes per tile

See the exact switch in `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h`.

### 2.2 Does `data_format` affect NOC transactions?

Not directly.

- Address: yes (via `MUL_WITH_TILE_SIZE`).
- Transaction size: determined by `addrgen.page_size` passed to `noc_async_read_tile` / `noc_async_write_tile` (see `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h` around `noc_async_read_tile` overloads).

So:

- `data_format` must be consistent with `page_size`.
- If you pass mismatched `page_size`, you can read/write the wrong number of bytes even if the address math is “right”.

### 2.3 Reader/writer kernels (complete examples)

These are minimal “tile stream” kernels; change only `DataFormat::*` and CB ids / args.

Authoritative baseline: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp` embeds both reader and writer kernels as strings.

#### Reader (NCRISC): Float32 / Float16_b / Bfp8 (DRAM → CB)

Float32:

```c++
void kernel_main() {
  uint32_t in_addr = get_arg_val<uint32_t>(0);
  uint32_t n_tiles = get_arg_val<uint32_t>(1);

  constexpr uint32_t cb_in = tt::CBIndex::c_0;
  const uint32_t tile_bytes = get_tile_size(cb_in);

  const InterleavedAddrGenFast<true> in = {
    .bank_base_address = in_addr,
    .page_size = tile_bytes,
    .data_format = DataFormat::Float32,
  };

  for (uint32_t i = 0; i < n_tiles; ++i) {
    cb_reserve_back(cb_in, 1);
    uint32_t l1 = get_write_ptr(cb_in);
    noc_async_read_tile(i, in, l1);
    noc_async_read_barrier();
    cb_push_back(cb_in, 1);
  }
}
```

Float16_b: identical except `data_format = DataFormat::Float16_b`.

Bfp8: identical except `data_format = DataFormat::Bfp8` (or `DataFormat::Bfp8_b`).

#### Writer (BRISC): Float32 / Float16_b / Bfp8 (CB → DRAM)

Float32:

```c++
void kernel_main() {
  uint32_t out_addr = get_arg_val<uint32_t>(0);
  uint32_t n_tiles = get_arg_val<uint32_t>(1);

  constexpr uint32_t cb_out = tt::CBIndex::c_16;
  const uint32_t tile_bytes = get_tile_size(cb_out);

  const InterleavedAddrGenFast<true> out = {
    .bank_base_address = out_addr,
    .page_size = tile_bytes,
    .data_format = DataFormat::Float32,
  };

  for (uint32_t i = 0; i < n_tiles; ++i) {
    cb_wait_front(cb_out, 1);
    uint32_t l1 = get_read_ptr(cb_out);
    noc_async_write_tile(i, out, l1);
    noc_async_write_barrier();
    cb_pop_front(cb_out, 1);
  }
}
```

Float16_b / Bfp8: identical except `data_format = ...`.

---

## 3. Runtime args (memory layout, sharing, limits, mutability)

### 3.1 What `get_arg_val<T>(idx)` does

Compute side (TRISC): `tt-metal/tt_metal/include/compute_kernel_api/common.h`.

- `rta_l1_base` is a pointer to an array of 32-bit words in L1.
- `get_arg_addr(i) = &rta_l1_base[i]`
- `get_arg_val<T>(i)` reads `*(T*)get_arg_addr(i)` with `static_assert(sizeof(T) == 4)`.

Dataflow side (BRISC/NCRISC): `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h` has the same model.

### 3.2 Do BRISC/NCRISC/TRISC share the same arg buffer?

They have **separate base pointers** per processor instance.

Firmware sets `rta_l1_base` / `crta_l1_base` from per-processor offsets in the launch message:

- `tt-metal/tt_metal/hw/inc/internal/firmware_common.h` (`firmware_config_init(...)`)
- For TRISC specifically: `tt-metal/tt_metal/hw/firmware/src/tt-1xx/trisc.cc` sets the bases using `PROCESSOR_INDEX`.

Practical compiler takeaway:

- Treat runtime args as **per-(core, processor)** memory.
- tt-metal usually populates each processor’s args consistently, but the hardware layout supports them being distinct.

### 3.3 Maximum number of args

Docs in `tt-metal/tt_metal/include/compute_kernel_api/common.h` state valid `arg_idx: 0..341`.

- That’s **342 32-bit args** for “unique” args.
- And **another 342** for “common” args (`crta_l1_base`).

### 3.4 Can args be modified during kernel execution?

Yes (they live in writable L1 memory), but:

- There’s no implicit synchronization with host, and no ABI guarantees if you treat args as scratch.
- For “compiler-generated kernels”, consider using a CB or explicit L1 scratch instead of mutating the arg region.

---

## 4. Circular buffer (CB) deep dive (reserve/push/wait/pop)

CB API (compute): `tt-metal/tt_metal/include/compute_kernel_api/cb_api.h`.
CB API (dataflow): `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`.

### 4.1 Semantics

- Producer side:
  - `cb_reserve_back(cb, n)`: wait until at least `n` free tiles exist in the CB.
  - write tile bytes into `get_write_ptr(cb)` region.
  - `cb_push_back(cb, n)`: publish those tiles (increments “received” counter).
- Consumer side:
  - `cb_wait_front(cb, n)`: wait until at least `n` tiles are available to read.
  - read from `get_read_ptr(cb)`.
  - `cb_pop_front(cb, n)`: consume/free those tiles (increments “acked” counter + advances rd ptr).

### 4.2 `get_tile_size(cb)` source of truth

Dataflow side: `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`:

- `get_tile_size(operand)` returns `unpack_tile_size[operand]` (format/shape metadata compiled into the kernel when `DATA_FORMATS_DEFINED` is enabled).

Host side must configure CB page sizes consistently (see `CircularBufferConfig::set_page_size` usage in `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`).

### 4.3 What if you reserve more than the CB can hold?

Behavior is “hang forever” (blocking spin).

There is no hard runtime error; `cb_reserve_back` will spin until `free_space_pages >= num_pages`.
If `num_pages > fifo_num_pages`, that condition is impossible.

### 4.4 Reader → Compute → Writer synchronization pattern (canonical)

`tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp` shows the full pipeline:

- Reader (NCRISC):
  - `cb_reserve_back(cb_in, 1)`
  - `noc_async_read_tile(...)`
  - `cb_push_back(cb_in, 1)`
- Compute (TRISC):
  - `tile_regs_acquire()`
  - `cb_wait_front(cb_in, 1)`
  - `copy_tile(cb_in, 0, dst_idx)`
  - SFPI compute
  - `tile_regs_commit(); tile_regs_wait();`
  - `cb_reserve_back(cb_out, 1)`
  - `pack_tile(dst_idx, cb_out)`
  - `cb_pop_front(cb_in, 1)`
  - `tile_regs_release()`
  - `cb_push_back(cb_out, 1)`
- Writer (BRISC):
  - `cb_wait_front(cb_out, 1)`
  - `noc_async_write_tile(...)`
  - `cb_pop_front(cb_out, 1)`

Double buffering is achieved by:

- CB depth ≥ 2 (so reader and compute can overlap),
- and the DST “section” ping/pong mechanism (see next section).

---

## 5. Non-tile-aligned shapes (partial tiles, padding, masking)

### 5.1 The key invariant: most compute kernels assume full tiles

Dataflow tile reads/writes are full “page_size” transfers:

- `noc_async_read_tile` uses `addrgen.page_size` (see `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`).

So a 3×3 (9-element) tensor cannot be “read as 9 elements” by default; it is read as a full tile page.

Concrete answers to the “3×3” questions:

- Reader special-casing partial tiles: typically no; it reads one full tile page. The “partial” logic lives in padding/tilize/untilize operations, not generic readers.
- Tile mask / valid element count passed to compute: typically no for tile-layout eltwise; compute kernels just process full tiles.
- `noc_async_read_tile` size: always `addrgen.page_size` bytes (full tile for the configured dtype).
- Packer output for unused elements: it writes a full tile. Correctness depends on padding being correct (or being later unpadded).

### 5.2 Where padding happens in TTNN

TTNN tracks both logical and padded shapes (`logical_shape()` vs `padded_shape()`).
Padding is generally handled *outside* compute kernels, via:

- `ttnn::pad` (`tt-metal/ttnn/cpp/ttnn/operations/data_movement/pad/pad.cpp`)
- layout conversion paths like `to_layout` that can pad with value `0` (see `tt-metal/ttnn/cpp/ttnn/operations/core/to_layout/to_layout_op.cpp` calling `ttnn::pad(..., 0, ...)`)
- tilize/untilize variants with padding/unpadding helpers:
  - `tt-metal/ttnn/cpp/ttnn/operations/data_movement/tilize_with_val_padding/`
  - `tt-metal/ttnn/cpp/ttnn/operations/data_movement/untilize_with_unpadding/`

### 5.3 Is there a “tile mask” passed to compute?

For standard eltwise tile-layout kernels: typically no.

Instead:

- Inputs are padded to tile boundaries (padded tiles exist in memory).
- Outputs are produced as padded tiles.
- Logical shape metadata is used later for untilize/unpadding when needed.

### 5.4 What’s in the padding region?

It depends on which padding operation was used.

Commonly observed:

- `ttnn::pad(..., value = 0)` is used in multiple places (see callsites in `tt-metal/ttnn/cpp/ttnn/operations/...` and `tt-metal/ttnn/cpp/ttnn/operations/data_movement/pad/pad.cpp`).

For reductions, padding value must be chosen so as not to affect the reduction (e.g. sum pads with 0; max pads with -inf). TTNN has dedicated reduction program factories (see `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/reduce_*.cpp` for the low-level kernels and how they’re configured).

### 5.5 Compute-kernel “partial” patterns that do exist

You’ll see “partial face” / “narrow tile” flags and tilize/untilize support:

- `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_io/llk_operands.h`
- `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_unpack_tilize_api.h`
- `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/dst_untilize.cpp`

This is mostly about **tile-shape variants** (like 32×16) and layout transforms (tilize/untilize), not “arbitrary 3×3 tiles” flowing through generic eltwise compute.

Compiler implication:

- For tinygrad element-level IR, you almost always lower to tiles by choosing:
  - a padding strategy (value depends on op semantics),
  - a tilize path to materialize padded tiles,
  - and an untilize/unpadding path to recover logical output if required.

---

## 6. Init functions catalog (what they configure)

These are compute-kernel APIs; they configure UNPACK/MATH/PACK hardware state (data formats, address mods, sync).

### 6.1 `init_sfpu(cb_in, cb_out)`

Alias for `unary_op_init_common(cb_in, cb_out)`:

- `tt-metal/tt_metal/include/compute_kernel_api/eltwise_unary/eltwise_unary.h`

Configures:

- UNPACK: `llk_unpack_hw_configure`, `llk_unpack_A_init(...)`
- PACK: `llk_pack_hw_configure_disaggregated`, `llk_pack_init`, `llk_pack_dest_init`
- MATH: `llk_math_eltwise_unary_datacopy_init<A2D>`, `llk_math_pack_sync_init`, `llk_math_hw_configure`

### 6.2 `binary_op_init_common(cb0, cb1, cb_out)`

`tt-metal/tt_metal/include/compute_kernel_api/eltwise_binary.h`

Configures:

- UNPACK: `llk_unpack_hw_configure`, `llk_unpack_AB_init`
- MATH: `llk_math_pack_sync_init`, `llk_math_hw_configure`
- PACK: `llk_pack_hw_configure_disaggregated`, `llk_pack_init`, `llk_pack_dest_init`

### 6.3 `add_tiles_init`, `mul_tiles_init`, `sub_tiles_init`

Thin wrappers over `binary_tiles_init<...>` in `tt-metal/tt_metal/include/compute_kernel_api/eltwise_binary.h`.

They configure the *LLK math binary op* (not SFPI); if you’re SFPI-first, you can skip these and just use `copy_tile` + SFPI loops, but you still need UNPACK/PACK configured for your formats.

### 6.4 `copy_tile_init`

`tt-metal/tt_metal/include/compute_kernel_api/tile_move_copy.h`

Configures UNPACK A and math datacopy (SRC→DST) without reconfiguring data types.

### 6.5 Re-entrancy (can you call init multiple times?)

Yes, these are “configure HW state” calls; you can call them multiple times, but:

- avoid doing so inside the hot tile loop unless you must switch formats,
- prefer the `*_reconfig_data_format_*` helpers when switching inputs/outputs across CBs.

---

## 7. Tile register management (DST ownership, sections, deadlocks)

Compute API: `tt-metal/tt_metal/include/compute_kernel_api/reg_api.h`.

- `tile_regs_acquire()`: MATH waits until it owns a DST “section”.
- `tile_regs_commit()`: MATH publishes the DST section to PACK (and flips section when enabled).
- `tile_regs_wait()`: PACK waits until MATH commits.
- `tile_regs_release()`: PACK releases the section so MATH can acquire it again.

Important facts:

- Dst holds **16 tiles** (the “dst_idx” argument range for `copy_tile` / `pack_tile`).
- If you don’t `tile_regs_release()`, the pipeline can deadlock (next `tile_regs_acquire()` will block indefinitely).

---

## 8. Compute pipeline coordination (TRISC0/1/2 + macros)

### 8.1 Do all three run the same kernel code?

Yes: the same source file is compiled for each TRISC thread, and macros gate code:

- `UNPACK(x)`, `MATH(x)`, `PACK(x)` in `tt-metal/tt_metal/include/compute_kernel_api/common_globals.h`
- `MAIN` is mapped to `unpack_main()`, `math_main()`, or `pack_main()` based on `TRISC_*` define.

### 8.2 What are `NAMESPACE` and `MAIN` in compute kernels?

`MAIN` is defined in `tt-metal/tt_metal/include/compute_kernel_api/common_globals.h`.

`NAMESPACE` is injected by the tt-metal kernel build (it’s not a user-facing API macro in headers); you’ll see it used in examples like `add1_sfpu_single_file.cpp` to avoid symbol collisions across kernels.

### 8.3 How does `pack_tile(dst_idx, cb_out)` know which tile to pack?

`pack_tile(ifrom_dst, icb, ...)` (in `tt-metal/tt_metal/include/compute_kernel_api/pack.h`) passes `ifrom_dst` to `llk_pack(...)`, which reads Dst slot `ifrom_dst` (tile index 0..15) under the current committed section.

---

## 9. Memory layouts (tiles, faces, Bfp8, L1)

### 9.1 Tile in memory (tiled layout)

From the Dst geometry, a 32×32 tile is naturally decomposed into 4 “faces” of 16×16, because most coprocessor datapaths operate on 16-wide chunks.

Practical invariants:

- Tile byte size depends on dtype (see `MUL_WITH_TILE_SIZE` in `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h`).
- Bfp8 tiles include an exponent side-band (the `+ 64` bytes for a 32×32 tile).

The “+64 bytes” Bfp8 rule shows up directly in tests, e.g. `tt-metal/tests/tt_metal/tt_metal/llk/test_reconfig.cpp` comments a 32×32 `Bfp8_b` tile as `(1 * 32 * 32) + 64`.

If you need the exact face ordering and pack/unpack mapping for Blackhole, start from:

- Dst addressing rules: `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/Dst.md`
- Pack/unpack address generators: `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/Packers/README.md` (and related files)
- LLK tilize/untilize paths in tt-metal (e.g. `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_unpack_tilize_api.h`)

tt-metal/LLK’s “working mental model” for Dst tile layout (useful for compiler lowering) is:

- One 32×32 tile slot occupies 64 consecutive `Dst16b` rows (each row has 16 columns).
- Those 64 rows are typically treated as 4 faces of 16 rows each:
  - Face 0: rows `[0..15]` (top-left 16×16)
  - Face 1: rows `[16..31]` (top-right 16×16)
  - Face 2: rows `[32..47]` (bottom-left 16×16)
  - Face 3: rows `[48..63]` (bottom-right 16×16)

The LLK SFPU unary helpers “advance face” using `math::inc_dst_addr<8>()` twice (16 rows) in `tt-metal/tt_metal/third_party/tt_llk/tt_llk_blackhole/llk_lib/llk_math_eltwise_unary_sfpu.h`.

### 9.2 L1 address space layout (mailbox, config, etc.)

See:

- `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/README.md`
- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h`

For kernels, the key practical regions are:

- mailbox/launch message area (firmware-managed),
- CB regions (allocated by host program via `CircularBufferConfig`),
- runtime arg blocks (`rta_l1_base` / `crta_l1_base`), set per processor by firmware.

tt-metal kernel launch also provides per-core “kernel_config_base” with offsets for these regions; you can see TRISC firmware wiring them up in `tt-metal/tt_metal/hw/firmware/src/tt-1xx/trisc.cc` (e.g. `local_cb_offset`, `remote_cb_offset`, `rta_offset[...]`, `sem_offset[...]`).

---

## 10. Error handling & debugging (hangs, registers, readback)

### 10.1 Detecting hangs

Most kernel “hangs” manifest as:

- spinning forever in a blocking wait (`cb_wait_front`, `cb_reserve_back`, `tile_regs_acquire`, `tile_regs_wait`)
- a NoC barrier never completing (`noc_async_*_barrier`) because the transaction never issued or never finished

Useful built-in instrumentation:

- `WAYPOINT("....")` markers appear throughout LLK code (see e.g. `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h` and `tt-metal/tt_metal/hw/ckernels/blackhole/metal/llk_api/llk_unpack_*_api.h`).
- `DPRINT_*` debug print kernels in tests:
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/misc/trisc_print.cpp`
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/misc/ncrisc_print.cpp`

### 10.2 Debug registers / GDB interface

Blackhole debug docs:

- `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/README.md`
- `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/CSRs.md`
- `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/Mailboxes.md`

### 10.3 Reading intermediate values

Common patterns:

- Pack Dst tiles back to a CB and have the writer store them to DRAM for host-side inspection.
- Use specialized “print tile” kernels in tests:
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/misc/print_tile_trisc.cpp`
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/misc/print_tile_ncrisc.cpp`

---

## 11. Multi-core considerations (per-core args and tile ranges)

TTNN/tt-metal programs typically shard work by:

- computing a linear “tile id” range per core
- setting `start_tile` and `num_tiles` (or equivalent) as per-core runtime args

Search for these patterns in program factories under `tt-metal/ttnn/cpp/ttnn/operations/.../device/*program_factory*.cpp` and in tests under `tt-metal/tests/tt_metal/tt_metal/*`.

Minimal formula for 1D partitioning:

- `tiles_per_core = ceil_div(total_tiles, num_cores)`
- `start = core_id * tiles_per_core`
- `count = min(tiles_per_core, total_tiles - start)`

No cross-core synchronization is required for pure data-parallel eltwise; each core is independent as long as it reads/writes disjoint tiles.

---

## 12. Complete working kernel sets (pragmatic SFPI-first)

### 12.1 Unary eltwise (SFPI add constant) – working reference

Use `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`.

It includes:

- Reader kernel (NCRISC) using `InterleavedAddrGenFast<true>` + `noc_async_read_tile`.
- Compute kernel that:
  - uses `init_sfpu(cb_in, cb_out)`
  - `copy_tile(...)` into Dst
  - runs a pure SFPI loop over `sfpi::dst_reg[0..31]`
  - packs to output CB.
- Writer kernel (BRISC) using `InterleavedAddrGenFast<true>` + `noc_async_write_tile`.

### 12.2 Binary eltwise (SFPI add) – minimal recipe

Start from the same example and extend:

- Two input CBs (e.g. `c_0`, `c_1`) and one output CB (e.g. `c_16`).
- In the compute loop:
  - `copy_tile(cb0, 0, 0)` → A in `dst_reg[0..31]`
  - `copy_tile(cb1, 0, 1)` → B in `dst_reg[32..63]`
  - SFPI add into slot 0, then `pack_tile(0, cb_out)`.

If you switch inputs across CB ids, use the `copy_tile_to_dst_init_short_with_dt(old_cb, new_cb, ...)` helper in `tt-metal/tt_metal/include/compute_kernel_api/tile_move_copy.h` (even when dtypes match, it’s a good template for explicit reconfig).

### 12.3 Reduce sum / Matmul

For now, tt-metal’s “complete, known-good” reduce and matmul examples are LLK-heavy (for good reasons: they map to dedicated datapaths and use specialized unpack/pack flows):

- Reduce kernels:
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/reduce_w.cpp`
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/reduce_h.cpp`
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/reduce_hw.cpp`
- Matmul kernels:
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/matmul.cpp`
  - `tt-metal/tests/tt_metal/tt_metal/test_kernels/compute/matmul_large_block*.cpp`

SFPI can be used inside these pipelines (e.g. for epilogues/activations), but “SFPI-only matmul” is not how tt-metal is structured today.

Compiler takeaway:

- If you want full performance, you’ll almost certainly emit “matmul/reduce as LLK primitives”, and reserve SFPI for non-linear elementwise pieces.
- If you insist on SFPI-only, treat it as a correctness-first fallback for small shapes, not a throughput path.

---

## 13. Element-to-tile mapping (compiler integration, non-aligned shapes)

For a logical `H×W` tensor in tile layout:

- `Ht = ceil_div(H, 32)`, `Wt = ceil_div(W, 32)`
- Physical storage is `Ht * Wt` tiles in DRAM/L1
- The “wasted” region in edge tiles is padding; TTNN tracks logical vs padded shapes and uses pad/unpad operations to keep semantics correct.

### 13.1 Concrete examples

#### Add two 5×5 tensors

- Logical shape: 5×5
- Padded shape (tile layout): 32×32
- Tile grid: `Ht=1`, `Wt=1` → **1 tile**

Device implication:

- Reader reads 1 tile for each input (full tile transfer).
- Compute runs 1 tile iteration (SFPI loop over `dst_reg[0..31]`).
- Writer writes 1 tile for the output.
- If you need a 5×5 host-visible result, you must unpad/untilize later (TTNN does this via `untilize_with_unpadding` when converting layouts).

#### Add two 100×100 tensors (edge tiles)

- Logical shape: 100×100
- Padded shape: 128×128
- Tile grid: `Ht=4`, `Wt=4` → **16 tiles**

Device implication:

- Kernels still treat it as 16 full tiles.
- Edge tiles (rightmost column tiles and bottom row tiles) contain padding in the unused region; correct semantics rely on padding value being correct.

### 13.2 Where TTNN decides “tile loop bounds”

In TTNN eltwise program factories, tile loops are derived from `padded_shape()` (not `logical_shape()`), e.g.:

- `output_width = output.padded_shape()[-1] / TILE_WIDTH;` in `tt-metal/ttnn/cpp/ttnn/operations/eltwise/binary/device/eltwise_multi_core_program_factory_common.hpp`

This is the pattern your compiler should mirror: execute over the padded tile grid, not the logical shape.

Concrete implications for your compiler:

- Track per tensor:
  - logical shape
  - padded shape
  - tile grid (Ht, Wt)
  - dtype / tile byte size
  - layout (tile vs row-major vs sharded variants)
- Lowering strategy:
  - decide padding value per op (sum pads with 0; max pads with -inf; etc)
  - materialize padding before tile compute (via tilize/pad), or handle via specialized “untilize/unpadding” transforms after compute

---

## 14. Where TTNN “lowers” high-level ops (breadcrumbs)

Useful places to read for lowering patterns:

- Binary eltwise device ops:
  - `tt-metal/ttnn/cpp/ttnn/operations/eltwise/binary/device/binary_device_operation.cpp`
  - `tt-metal/ttnn/cpp/ttnn/operations/eltwise/binary/device/*program_factory*.cpp`
- Common program factory helpers:
  - `tt-metal/ttnn/cpp/ttnn/operations/eltwise/binary/device/eltwise_multi_core_program_factory_common.hpp`
- Layout conversions and padding:
  - `tt-metal/ttnn/cpp/ttnn/operations/core/to_layout/to_layout_op.cpp`
  - `tt-metal/ttnn/cpp/ttnn/operations/data_movement/pad/pad.cpp`

These are the places where:

- padded-vs-logical shape decisions are made,
- CB sizes and tile loops are computed,
- per-core runtime args like `start_tile`/`num_tiles` are chosen.
