# Dataflow, buffers, and CBs

This consolidates CB semantics, dataflow kernel patterns, and buffer copy behavior.

## CBs (circular buffers)

- 32 CBs per Tensix tile (`c_0` through `c_31`)
- CBs are **per-core**, not shared across cores
- CB config: base address, total size, page size, page count

Producer flow:
- `cb_reserve_back()` → write to L1 → `cb_push_back()`

Consumer flow:
- `cb_wait_front()` → read from L1 → `cb_pop_front()`

Rules:
- One producer and one consumer per CB ID
- CB depth is a tradeoff: overlap vs L1 capacity

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

## Buffer copies (host ↔ device)

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

## DRAM → L1 → Dst → L1 → DRAM

Data path:
1. DRAM → L1 (NoC DMA)
2. L1 → Dst (Unpacker)
3. Compute in Dst (Matrix/SFPU/Scalar)
4. Dst → L1 (Packer)
5. L1 → DRAM (NoC DMA)

This is why kernels are commonly structured as **reader → compute → writer**.

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
