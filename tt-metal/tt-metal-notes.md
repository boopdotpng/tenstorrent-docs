# TT-Metal / LLK Notes

This file collects kernel-facing notes and TT-Metal/LLK API behaviors.

## Circular Buffers (CBs)

CBs are the on-tile streaming primitive used to move tiles between reader, compute, and writer kernels.

- **32 CBs per Tensix tile** (`CB[0..31]`).
- Configured with **base address**, **total size**, **page size**, **page count**; read/write pointers wrap at the limit.
- Producer flow: `cb_reserve_back()` → write to L1 → `cb_push_back()`.
- Consumer flow: `cb_wait_front()` → read from L1 → `cb_pop_front()`.
- Double-buffering (2 pages per CB) is common to overlap producer/consumer work.

References:
- `tt-metal/tt_metal/hw/inc/internal/circular_buffer_interface.h`
- `tt-metal/tt_metal/programming_examples/add_2_integers_in_compute/add_2_integers_in_compute.md`
- `tt-metal/tt_metal/programming_examples/eltwise_sfpu/eltwise_sfpu.md`

## DRAM → L1 → Dst → L1 → DRAM (tile data path)

**Where data lives:**
- **DRAM (VRAM)** is accessed over the NoC into a Tensix tile's **L1**.
- **L1** is byte-addressed; it does not impose tile shape.
- **Dst** is the coprocessor register file, organized as tiles.

**Tile shape (32×32):**
- A tile is a logical compute unit (1024 elements), not the size of L1.
- Tile byte size depends on format (e.g., FP16/BF16 = 2048 bytes, FP32 = 4096 bytes).

**Preprocessing / format conversion:**
1. **DRAM → L1**: RISC-V cores orchestrate NoC DMA reads into L1 CBs.
2. **L1 → Dst** (Unpacker): converts layout + format (BF16/FP16/INT8/BFP, tilize/untilize).
3. **Compute in Dst**: Matrix Unit, SFPU, and Scalar Unit operate on tiles.
4. **Dst → L1** (Packer): converts back to requested layout/format.
5. **L1 → DRAM**: RISC-V cores DMA writes back to DRAM.

This is why kernels are structured as **reader → compute → writer**.

## Async vs. Sync NoC DMA

- Use `noc_async_read()` / `noc_async_write()` for DMA; these are asynchronous to the core.
- You **must** call `noc_async_read_barrier()` / `noc_async_write_barrier()` before reusing the L1 buffer.
- “Async” is not implicit for arbitrary stores; it is explicit via the `noc_async_*` APIs.

## Where C Lives During Matmul

- Output tiles are accumulated in **Dst**, packed into **L1** output CBs, then DMA-written to **DRAM**.
- Tiles can be streamed out as they finish; no need to wait for full C completion.
- For `C += A*B`, the C tile is typically read from DRAM into L1/Dst, accumulated, then written back.

## Example: 2000×2000 FP16 Matmul (Tile-Based)

**Problem:** `C = A × B`, A and B are 2000×2000 FP16.

**Tile math:**
- Tile shape: 32×32.
- Tiles per dimension: `ceil(2000 / 32) = 63`.
- A/B/C tile grids: 63×63.
- Last tile in each dimension is partial (2000 = 62×32 + 16); handled via padding or masks.

**Typical per-core structure:**
- L1 CBs: `c_in0` for A, `c_in1` for B, `c_out` for C.
- Double-buffering: 2 pages per CB.

**Conceptual flow:**
1. **Reader (BRISC/NC)** streams A/B tiles from DRAM into `c_in0`/`c_in1`.
2. **Compute (T0/T1/T2 + coprocessor)**:
   - For each output tile `(m, n)`, accumulate over K tiles `k = 0..62`.
   - Unpack A/B tiles into Dst.
   - Matrix Unit performs `Dst += A_tile × B_tile`.
   - On final `k`, pack output tile into `c_out`.
3. **Writer** drains `c_out` to DRAM.

**Loop view (tile indices):**
- Outer: `m = 0..62`, `n = 0..62`
- Inner: `k = 0..62`
- Each step uses A `(m, k)` and B `(k, n)`.

## FP16 Support Note

- TT-Metal/LLK supports FP16 on device via `tt::DataFormat::Float16` / `Float16_b`.
- TTNN does **not** expose float16 as a Python dtype today; nanobind maps float16 → bfloat16.
  - See `tt-metal/ttnn/cpp/ttnn-nanobind/ttnn_dtype_traits.hpp`.
