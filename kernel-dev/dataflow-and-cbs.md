# Dataflow, buffers, and CBs

Single source of truth for CB semantics, dataflow kernel patterns, buffer copy behavior, and dtype/address-generation details.

CB API (compute): `tt-metal/tt_metal/include/compute_kernel_api/cb_api.h`.
CB API (dataflow): `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`.

## CBs (circular buffers)

- 32 CBs per Tensix tile (`c_0` through `c_31`)
- CBs are **per-core**, not shared across cores
- CB config: base address, total size, page size, page count

Producer flow:
- `cb_reserve_back(cb, n)`: wait until at least `n` free tiles exist in the CB.
- Write tile bytes into `get_write_ptr(cb)` region.
- `cb_push_back(cb, n)`: publish those tiles (increments "received" counter).

Consumer flow:
- `cb_wait_front(cb, n)`: wait until at least `n` tiles are available to read.
- Read from `get_read_ptr(cb)`.
- `cb_pop_front(cb, n)`: consume/free those tiles (increments "acked" counter + advances rd ptr).

Rules:
- One producer and one consumer per CB ID
- CB depth is a tradeoff: overlap vs L1 capacity

### `get_tile_size(cb)` source of truth

Dataflow side: `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h`:

- `get_tile_size(operand)` returns `unpack_tile_size[operand]` (format/shape metadata compiled into the kernel when `DATA_FORMATS_DEFINED` is enabled).

Host side must configure CB page sizes consistently (see `CircularBufferConfig::set_page_size` usage in `add1_sfpu_single_file.cpp`).

### What if you reserve more than the CB can hold?

Behavior is "hang forever" (blocking spin). `cb_reserve_back` will spin until `free_space_pages >= num_pages`. If `num_pages > fifo_num_pages`, that condition is impossible. There is no hard runtime error.

## Add1 SFPU example (CB pipeline)

Pipeline on a single core:
```
DRAM
  |
  |  (NCRISC read kernel)
  v
CB0 (L1 input ring)
  |
  |  (SFPU compute kernel)
  v
Register tile 0 -> add scalar -> register tile 0
  |
  |  (pack)
  v
CB16 (L1 output ring)
  |
  |  (BRISC write kernel)
  v
DRAM
```

## Dataflow kernel patterns

### Unary reader (DRAM → CB)
```cpp
for (uint32_t i = 0; i < num_tiles; i++) {
  cb_reserve_back(cb_id_in0, 1);
  uint32_t l1_write_addr = get_write_ptr(cb_id_in0);
  noc_async_read(src_noc_addr, l1_write_addr, ublock_size_bytes);
  noc_async_read_barrier();
  cb_push_back(cb_id_in0, 1);
}
```

### Unary writer (CB → DRAM)
```cpp
for (uint32_t i = 0; i < num_tiles; i++) {
  cb_wait_front(cb_id_out0, 1);
  noc.async_write(cb, ..., ublock_size_bytes, ...);
  noc.async_write_barrier();
  cb_pop_front(cb_id_out0, 1);
}
```

### Binary reader (two inputs)
```cpp
for (uint32_t i = 0; i < n_tiles; i++) {
  cb_reserve_back(cb_in0, 1);
  cb_reserve_back(cb_in1, 1);
  noc_async_read_tile(i, in0, get_write_ptr(cb_in0));
  noc_async_read_tile(i, in1, get_write_ptr(cb_in1));
  noc_async_read_barrier();
  cb_push_back(cb_in0, 1);
  cb_push_back(cb_in1, 1);
}
```

### Matmul: reuse + multicast sender
```cpp
noc_async_read_barrier();
noc_semaphore_wait(in0_mcast_sender_semaphore_addr_ptr, in0_mcast_num_dests);
noc_semaphore_set(in0_mcast_sender_semaphore_addr_ptr, 0);
uint64_t in0_multicast_data_addr = get_noc_multicast_addr(...);
noc_async_write_multicast(in0_start_address, in0_multicast_data_addr, in0_block_size_bytes, in0_mcast_num_dests);
```

## Address generation and dtype: `InterleavedAddrGenFast`

Definition: `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h`.

`InterleavedAddrGenFast<DRAM, tile_hw>` computes the base address for "tile/page id `id`" as:
- bank selection: `id -> (bank_offset_index, bank_index)`
- address offset: `MUL_WITH_TILE_SIZE<tile_hw>(data_format, bank_offset_index)`

Bytes per tile for `tile_hw = 1024` (32x32):

| Data format | Bytes per tile | Shift |
|---|---|---|
| Float32 / Int32 / UInt32 | 4096 | `index << 12` |
| Float16 / Float16_b / UInt16 | 2048 | `index << 11` |
| UInt8 | 1024 | `index << 10` |
| Bfp8 / Bfp8_b | 1088 | `index<<10 + index<<6` (mantissas + exponents) |
| Bfp4 | 576 | `index<<9 + index<<6` |
| Bfp2 | 320 | `index<<8 + index<<6` |

`data_format` does not directly affect NOC transactions -- it determines the address and page size. If you pass mismatched `page_size`, you read/write the wrong number of bytes.

### Complete reader kernel (NCRISC): DRAM -> CB

```c++
void kernel_main() {
  uint32_t in_addr = get_arg_val<uint32_t>(0);
  uint32_t n_tiles = get_arg_val<uint32_t>(1);

  constexpr uint32_t cb_in = tt::CBIndex::c_0;
  const uint32_t tile_bytes = get_tile_size(cb_in);

  const InterleavedAddrGenFast<true> in = {
    .bank_base_address = in_addr,
    .page_size = tile_bytes,
    .data_format = DataFormat::Float32,  // change per dtype
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

### Complete writer kernel (BRISC): CB -> DRAM

```c++
void kernel_main() {
  uint32_t out_addr = get_arg_val<uint32_t>(0);
  uint32_t n_tiles = get_arg_val<uint32_t>(1);

  constexpr uint32_t cb_out = tt::CBIndex::c_16;
  const uint32_t tile_bytes = get_tile_size(cb_out);

  const InterleavedAddrGenFast<true> out = {
    .bank_base_address = out_addr,
    .page_size = tile_bytes,
    .data_format = DataFormat::Float32,  // change per dtype
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

For Float16_b / Bfp8: identical except `data_format = DataFormat::Float16_b` or `DataFormat::Bfp8`.

## Buffer copies (host <-> device)

Blocking copies:
- `detail::WriteToBuffer(Buffer&, Span<const uint8_t>)`
- `detail::ReadFromBuffer(Buffer&, uint8_t*)`

Raw address copies:
- `WriteToDeviceDRAMChannel`, `ReadFromDeviceDRAMChannel`
- `WriteToDeviceL1`, `ReadFromDeviceL1`

`Buffer` owns the device allocation and address; copy calls move bytes but do not return device pointers.

## L1-direct path (skip dataflow kernels)

If data already resides in L1 and CBs point directly at L1 buffers, you can skip reader/writer kernels and run compute-only.
Example: `vecadd_sharding` uses L1 buffers and does not call `cb_wait_front()`.

## DRAM -> L1 -> Dst -> L1 -> DRAM

Data path:
1. DRAM -> L1 (NoC DMA)
2. L1 -> Dst (Unpacker)
3. Compute in Dst (Matrix/SFPU/Scalar)
4. Dst -> L1 (Packer)
5. L1 -> DRAM (NoC DMA)

This is why kernels are commonly structured as **reader -> compute -> writer**.

### Canonical reader -> compute -> writer sync pattern

From `add1_sfpu_single_file.cpp`:

- Reader (NCRISC):
  - `cb_reserve_back(cb_in, 1)` / `noc_async_read_tile(...)` / `cb_push_back(cb_in, 1)`
- Compute (TRISC):
  - `tile_regs_acquire()` / `cb_wait_front(cb_in, 1)` / `copy_tile(cb_in, 0, dst_idx)` / SFPI compute / `tile_regs_commit(); tile_regs_wait();` / `cb_reserve_back(cb_out, 1)` / `pack_tile(dst_idx, cb_out)` / `cb_pop_front(cb_in, 1)` / `tile_regs_release()` / `cb_push_back(cb_out, 1)`
- Writer (BRISC):
  - `cb_wait_front(cb_out, 1)` / `noc_async_write_tile(...)` / `cb_pop_front(cb_out, 1)`

Double buffering is achieved by CB depth >= 2 (so reader and compute overlap) and the DST "section" ping/pong mechanism (see `kernel-dev/sfpi-and-kernel-dev.md` section 7 for tile register management).

## Async vs sync NoC DMA

- Use `noc_async_read()` / `noc_async_write()` for DMA; these are asynchronous to the core.
- You **must** call `noc_async_read_barrier()` / `noc_async_write_barrier()` before reusing the L1 buffer.

## Where C lives during matmul

- Output tiles are accumulated in **Dst**, packed into L1 output CBs, then DMA-written to DRAM.
- Tiles can be streamed out as they finish; no need to wait for full C completion.
- For `C += A*B`, the C tile is typically read from DRAM into L1/Dst, accumulated, then written back.

## Example: 2000×2000 FP16 matmul (tile-based)

- Tile shape: 32×32
- Tiles per dimension: `ceil(2000 / 32) = 63`
- A/B/C tile grids: 63×63
- Last tile in each dimension is partial (2000 = 62×32 + 16)
Per-core structure:
- L1 CBs: `c_in0` (A), `c_in1` (B), `c_out` (C)
- Double-buffering: 2 pages per CB

Loop view (tile indices):
- Outer: `m = 0..62`, `n = 0..62`
- Inner: `k = 0..62`
- Each step uses A `(m, k)` and B `(k, n)`

## FP16 support note

- TT-Metal/LLK supports FP16 via `tt::DataFormat::Float16` / `Float16_b`.
- TTNN does **not** expose float16 as a Python dtype today; nanobind maps float16 → bfloat16 (`ttnn_dtype_traits.hpp`).
