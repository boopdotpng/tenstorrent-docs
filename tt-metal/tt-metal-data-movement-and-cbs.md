# TT-metal data movement, buffers, and CBs (practical notes)

This document collects practical notes from a discussion about how tt-metal handles DMA-like copies, buffers, and circular buffers (CBs), including how L1-direct flows compare to DRAM + dataflow kernels, and what is or is not possible across processes.

## Copy and buffer basics (tt-metal)

### High-level copies
- The blocking host↔device copy entry points are:
  - `tt::tt_metal::detail::WriteToBuffer(Buffer& buffer, tt::stl::Span<const uint8_t> host_buffer)`
  - `tt::tt_metal::detail::ReadFromBuffer(Buffer& buffer, uint8_t* host_buffer)`
  - Header: `tt_metal/api/tt-metalium/tt_metal.hpp`
- These functions **return `void`**. They do not return a device pointer.
- The device address lives inside the `Buffer` object. That address is passed to kernels via runtime args or tensor accessors.

### Raw address copies (optional)
- You can write directly into DRAM or L1 with:
  - `WriteToDeviceDRAMChannel(...)`
  - `ReadFromDeviceDRAMChannel(...)`
  - `WriteToDeviceL1(...)`
  - `ReadFromDeviceL1(...)`
  - Header: `tt_metal/api/tt-metalium/tt_metal.hpp`
- These return `bool` and are for explicit address targeting (core, DRAM channel, address).

### Buffer address ownership
- Copy calls are side-effect ops that move bytes; they do **not** create allocations or return addresses.
- The `Buffer` object owns the allocation and device address (e.g., `Buffer::address()` in `tt_metal/api/tt-metalium/buffer.hpp`).
- Kernels receive addresses through runtime args or helper utilities (e.g., `TensorAccessorArgs(*buffer)` in examples).

## DMA-like flow vs CUDA-style pointers

- In CUDA/tinygrad, a `Buffer` holds a `CUdeviceptr` and a copy op populates it; kernels take that pointer directly.
- In tt-metal, the **same conceptual flow exists**, but the pointer is stored **inside** the `Buffer` object and passed via runtime args. You do not share raw device pointers across processes.
- Copies are separate ops: allocate buffer → write → run → read back. This matches tinygrad’s “COPY op separate from compute” model.

## Single-device path: do you need distributed?

- **No**, not for single-device, blocking transfers.
- Use `WriteToBuffer` / `ReadFromBuffer` for the minimal API surface.
- Distributed APIs (`distributed::EnqueueWriteMeshBuffer`, etc.) are for multi-device or mesh CQ semantics.

## Example: add1_sfpu_single_file uses DRAM + dataflow

- `tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp` allocates DRAM buffers:
  - `BufferType::DRAM` for input/output.
- Reader kernel: `noc_async_read_tile(...)` pulls DRAM tiles into L1 CBs.
- Compute kernel: reads CBs, operates, writes to output CB.
- Writer kernel: `noc_async_write_tile(...)` pushes CB output back to DRAM.

So DRAM is used as “VRAM,” and L1 is a staging area for tiles.

## L1-direct path: skip dataflow kernels

You can avoid DRAM and reader/writer kernels when data already resides in L1 and CBs point directly at L1 buffers.

Concrete example:
- `tt_metal/programming_examples/vecadd_sharding/vecadd_sharding.cpp`
- It creates **L1 buffers**, then makes CBs that **explicitly point** at those L1 buffers.
- It writes host data directly into L1.
- The compute kernel has **no reader/writer** and avoids `cb_wait_front()`.

Key snippet (compute kernel):
- `tt_metal/programming_examples/vecadd_sharding/kernels/add_sharding.cpp`
- It notes: no read kernel; data already in CBs; do not call `cb_wait_front()` or it will hang.

## CBs: what they are and what they are not

### Correct mental model
- A CB is a **ring buffer in a single core’s L1**.
- CBs are for **intra-core streaming/backpressure** between kernels/threads on that same core.
- You decide the CB size; it can hold **N tiles**.
- CBs are **not one-per-tile**.

### Hardware capacity
- “The hardware supports up to 32 circular buffers and they all act the same.”
  - `tt_metal/programming_examples/add_2_integers_in_compute/add_2_integers_in_compute.cpp`
- CB IDs are per core, typically `c_0..c_31`.

### Producer/consumer rules
- Producer:
  - reserve space at back
  - write data into CB backing storage
  - `cb_push_back(...)`
- Consumer:
  - `cb_wait_front(...)` (if producer is another kernel)
  - read using CB read pointer
  - `cb_pop_front(...)`
- **Only one thread/kernel should push for a given CB ID** to avoid nondeterminism.

### Typical single-core pattern

DRAM → (reader) → CB_in → (compute) → CB_out → (writer) → DRAM

Common mapping on Tensix:
- NCRISC: reader
- TRISC0/1/2: compute
- BRISC: writer

## “Stream 65,536 elements into L1 directly” (single core)

Assume:
- bf16
- 65,536 elements = 64 tiles (32x32)
- Tile size = 2,048 bytes
- Total input = 128 KB, output = 128 KB
- Blackhole L1 per tile = 1536 KiB

Flow:
1) Allocate L1 buffers for input and output.
2) Create CBs that **point at those L1 buffers** (CB_in, CB_out).
3) Host writes input directly into L1.
4) Launch compute kernel only (no reader/writer).
5) Compute loops tiles, uses `cb_pop_front` / `cb_push_back`.
6) Host reads output from L1.

This works because L1 is big enough for small tensors. For larger tensors, use DRAM + dataflow kernels.

## Parallelizing L1-direct across many cores

You can shard tiles across multiple cores (e.g., 16 cores):

1) Partition tiles: 64 tiles → 4 tiles/core.
2) Allocate per-core L1 buffers.
3) Create CBs per core pointing at each core’s L1 buffers.
4) Host writes each shard to the corresponding core’s L1.
5) Launch one program over a core range; each core runs the same compute kernel.
6) Read each core’s output shard and stitch on host.

This is data-parallel and requires no inter-core communication.

## Do you need async host↔L1 to scale?

Not strictly, but blocking per-core writes/reads can dominate if you serialize many L1 transfers from the host.

Options:
- Batch/queue writes across cores and synchronize once.
- Stage in DRAM once and let dataflow kernels pull into L1.

## NoC and remote L1 access

- Any core can access another core’s L1 over the NoC, but it is **not a cache**.
- Useful for:
  - multicast / broadcast from one producer to many consumers
  - cross-core producer/consumer pipelines
  - avoiding DRAM for inter-core traffic
- Not ideal for:
  - shared-memory programming
  - random fine-grained access patterns

## Cross-process sharing of device memory

- tt-metal `Buffer` objects are **process-local**.
- There is no CUDA-style IPC to export/import device allocations across processes.
- UMD provides host-memory DMA mapping (`tt_dma_map`), but that is **host memory**, not device allocations.
- Practical workaround: keep allocation + copy + compute in one process, or use a device-owner service process with RPC.

## Blackhole tile counts and L1

- Blackhole has **140 Tensix tiles**, with **120 available on p100** (others fused off).
  - ` /home/boop/tenstorrent/tt-isa-documentation/BlackholeA0/README.md`
- Each Tensix tile has **1536 KiB L1** and **5 RISCVs**.
  - ` /home/boop/tenstorrent/tt-isa-documentation/BlackholeA0/TensixTile/README.md`

## Takeaways

- Start DRAM-first for correctness and simplicity; add L1-direct as an optimization.
- L1-direct is great for small, per-core-local workloads.
- CBs are per-core ring buffers (up to 32 slots per core), not per tile.
- NoC L1-to-L1 is powerful for structured dataflow, not general shared memory.

## Streaming large tensors through L1 (sharded pipeline)

For tensors larger than a single core’s L1, the standard pattern is **streaming** with small CBs and dataflow kernels:

1) Store the full tensor in DRAM.
2) Reader kernel pulls tiles into per-core input CBs (`noc_async_read_tile`).
3) Compute kernel consumes input CB tiles and produces output CB tiles.
4) Writer kernel drains output CB tiles back to DRAM (`noc_async_write_tile`).
5) CB backpressure keeps the pipeline balanced and overlaps movement with compute.

This is the common “reader/compute/writer” pipeline shown in `add1_sfpu_single_file.cpp` and matmul examples.

### Sharding + streaming for large element counts

You can shard a large tensor across many cores and **stream tiles per core**:

- Each core gets a shard of tiles.
- Each core uses small CBs (e.g., 2–4 tiles) instead of staging the full shard in L1.
- The program loops until the shard is complete.
- This avoids treating total L1 across the chip as a shared pool; each core uses its local L1.

### When L1-direct is still viable

If the **per-core shard fits entirely in L1**, you can skip reader/writer kernels and treat CBs as prefilled buffers (as in `vecadd_sharding`). Otherwise, stream from DRAM through small CBs.
