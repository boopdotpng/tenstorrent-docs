# Dataflow Kernel Patterns (tt-metal)

Short, source-backed examples of dataflow kernels across common ops. These are all on BRISC/NCRISC (dataflow RISCVs); compute runs on TRISCs.

## Processor roles (defaults)
- Reader dataflow kernel: RISCV_1 (NCRISC)
- Writer dataflow kernel: RISCV_0 (BRISC)
- Mapping: `tt_metal/api/tt-metalium/data_types.hpp` and defaults in `tt_metal/impl/kernels/kernel_types.cpp`
- You can override per kernel with `DataMovementConfig`

## Programming model (short primer)
At a high level, each core runs multiple kernels that form a pipeline:
dataflow kernels move tiles between DRAM and L1 circular buffers (CBs),
compute kernels consume tiles from CBs and write results back into CBs.
The dataflow kernels run on BRISC/NCRISC (RISCV_0/1), while compute
kernels run on TRISCs (three binaries compiled from one compute source).

Think of CBs as FIFO queues in L1:
- A reader reserves space with `cb_reserve_back`, writes tile data into the CB,
  then publishes with `cb_push_back`.
- A compute kernel waits on input CBs with `cb_wait_front`, reads tiles,
  and pops them with `cb_pop_front`.
- A writer waits on output CBs with `cb_wait_front`, writes to DRAM,
  and then `cb_pop_front`.

The dataflow code is where you define:
- Tile address generation (linear, blocked, transposed, stick, interleaved)
- Per-core partitioning (start tile, tile count, output ranges)
- Reuse patterns (read once, multicast to peers)
- Synchronization (NOC barriers, semaphores for multicasts, ordering)

The compute code is usually a tight loop over tiles, but it is not always
"one tile in, one tile out." For matmul, the compute kernel typically
accumulates across K tiles into Dst registers and only packs once per
output tile. See `tt_metal/programming_examples/matmul/matmul_common/kernels/compute/bmm.cpp`.

## Writing fast dataflow kernels (checklist)
These are the most common levers for performance on this architecture.

Data movement and layout:
- Prefer reading tiles in a layout that matches compute order. Misaligned
  layouts force extra address math or wasted L1 traffic.
- Use `TensorAccessor` with a page size that matches tile size or a
  natural block size for the layout.
- If possible, read or write in blocks (ublocks) rather than single tiles.
  This reduces per-tile overhead and amortizes barriers.
- Use interleaved and banked layouts to spread traffic across DRAM channels.

Overlap and backpressure:
- Keep CBs deep enough to overlap reader/compute/writer, but not so deep
  that they starve L1. CB depth is a direct tradeoff.
- Avoid over-serializing with barriers. Group multiple async reads or
  writes, then issue a single barrier when the batch is done.
- Keep the compute kernel busy by ensuring the reader stays ahead. If
  compute is waiting on `cb_wait_front`, you are underfeeding.

Reuse and multicast:
- For matmul, the fast path usually reads blocks once and multicasts to
  other cores instead of re-reading from DRAM. See the mcast readers in
  `tt_metal/programming_examples/matmul/matmul_common/kernels/dataflow/`.
- Use semaphores to synchronize senders and receivers so multicasts are
  ordered and do not overwrite live data.

Per-core partitioning:
- Use explicit `output_tile_start_id` and `num_output_tiles` per core to
  avoid redundant reads and writes.
- Validate that each core only reads the tiles it needs for its slice.
  Overfetching is usually the first hidden perf killer.

Processor and NOC selection:
- Defaults are reader on NCRISC and writer on BRISC, with dedicated NOC
  choices optimized for DRAM read/write. Override only if you have a clear
  reason and can confirm you are not saturating a single NOC path.

## Unary reader (DRAM -> CB)
From `tt_metal/kernels/dataflow/reader_unary.cpp`:

```cpp
constexpr uint32_t cb_id_in0 = 0;
uint32_t ublock_size_bytes = get_tile_size(cb_id_in0);
for (uint32_t i = 0; i < num_tiles; i++) {
  uint64_t src_noc_addr = get_noc_addr_from_bank_id<true>(bank_id, src_addr);
  cb_reserve_back(cb_id_in0, 1);
  uint32_t l1_write_addr = get_write_ptr(cb_id_in0);
  noc_async_read(src_noc_addr, l1_write_addr, ublock_size_bytes);
  noc_async_read_barrier();
  cb_push_back(cb_id_in0, 1);
  src_addr += ublock_size_bytes;
}
```

## Unary writer (CB -> DRAM)
From `tt_metal/kernels/dataflow/writer_unary.cpp`:

```cpp
constexpr uint32_t cb_id_out0 = tt::CBIndex::c_16;
uint32_t ublock_size_bytes = get_tile_size(cb_id_out0);
for (uint32_t i = 0; i < num_tiles; i++) {
  cb_wait_front(cb_id_out0, 1);
  noc.async_write(cb, experimental::AllocatorBank<experimental::AllocatorBankType::DRAM>{},
                  ublock_size_bytes, {}, {.bank_id = bank_id, .addr = dst_addr});
  noc.async_write_barrier();
  cb_pop_front(cb_id_out0, 1);
  dst_addr += ublock_size_bytes;
}
```

## Binary reader (two inputs)
From `tt_metal/programming_examples/eltwise_binary/kernels/dataflow/read_tiles.cpp`:

```cpp
for (uint32_t i = 0; i < n_tiles; i++) {
  cb_reserve_back(cb_in0, 1);
  cb_reserve_back(cb_in1, 1);
  uint32_t cb_in0_addr = get_write_ptr(cb_in0);
  uint32_t cb_in1_addr = get_write_ptr(cb_in1);
  noc_async_read_tile(i, in0, cb_in0_addr);
  noc_async_read_tile(i, in1, cb_in1_addr);
  noc_async_read_barrier();
  cb_push_back(cb_in0, 1);
  cb_push_back(cb_in1, 1);
}
```

## Matmul: partitioned reader (per-output tile)
From `tt_metal/programming_examples/matmul/matmul_multi_core/kernels/dataflow/reader_mm_output_tiles_partitioned.cpp`:

```cpp
for (uint32_t output_tile = 0; output_tile < num_output_tiles; output_tile++) {
  uint32_t current_tile_id = output_tile_start_id + output_tile;
  uint32_t out_row = current_tile_id / Nt;
  uint32_t out_col = current_tile_id % Nt;
  for (uint32_t k = 0; k < Kt; k++) {
    uint32_t tile_A = out_row * Kt + k;
    cb_reserve_back(cb_id_in0, 1);
    noc_async_read_tile(tile_A, a, get_write_ptr(cb_id_in0));
    noc_async_read_barrier();
    cb_push_back(cb_id_in0, 1);

    uint32_t tile_B = k * Nt + out_col;
    cb_reserve_back(cb_id_in1, 1);
    noc_async_read_tile(tile_B, b, get_write_ptr(cb_id_in1));
    noc_async_read_barrier();
    cb_push_back(cb_id_in1, 1);
  }
}
```

## Matmul: reuse + multicast sender (fast path)
From `tt_metal/programming_examples/matmul/matmul_common/kernels/dataflow/reader_bmm_tile_layout_in0_sender_in1_sender.cpp`:

```cpp
// Read a block into CB, then multicast it to peers.
noc_async_read_barrier();
noc_semaphore_wait(in0_mcast_sender_semaphore_addr_ptr, in0_mcast_num_dests);
noc_semaphore_set(in0_mcast_sender_semaphore_addr_ptr, 0);
uint64_t in0_multicast_data_addr = get_noc_multicast_addr(
  in0_mcast_dest_noc_end_x, in0_mcast_dest_noc_end_y,
  in0_mcast_dest_noc_start_x, in0_mcast_dest_noc_start_y,
  in0_start_address);
noc_async_write_multicast(
  in0_start_address, in0_multicast_data_addr, in0_block_size_bytes, in0_mcast_num_dests);
```

## Layout transform (transpose-style reader)
From `tests/tt_metal/tt_metal/test_kernels/dataflow/reader_unary_transpose_wh.cpp`:

```cpp
for (uint32_t n = 0; n < N; n++) {
  for (uint32_t w = 0; w < Wt; w++) {
    for (uint32_t h = 0; h < Ht; h++) {
      cb.reserve_back(1);
      noc.async_read(dram_src, cb, tile_bytes, {.bank_id = src_dram_bank_id, .addr = src_addr}, {});
      noc.async_read_barrier();
      cb.push_back(1);
      src_addr += WtTileBytes;
    }
    src_addr -= HtWtTileBytes;
    src_addr += tile_bytes;
  }
}
```

## Direct DRAM copy (no CB)
From `tests/tt_metal/tt_metal/test_kernels/dataflow/dram_copy.cpp`:

```cpp
noc.async_read(src_dram, l1_buffer, dram_buffer_size,
               {.bank_id = dram_src_bank_id, .addr = dram_buffer_src_addr}, {});
noc.async_read_barrier();
noc.async_write(l1_buffer, dst_dram, dram_buffer_size, {},
                {.bank_id = dram_dst_bank_id, .addr = dram_buffer_dst_addr});
noc.async_write_barrier();
```

## Notes on compute vs dataflow
- Dataflow kernels handle address generation, layout/banking, core partitioning, and NOC sync.
- Compute kernels are not always "one tile in, one tile out"; matmul accumulates across K before packing.
  See `tt_metal/programming_examples/matmul/matmul_common/kernels/compute/bmm.cpp`.
