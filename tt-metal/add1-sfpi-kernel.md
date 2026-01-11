# add1_sfpu: SFPI-based compute kernel

This note shows how to replace `add_unary_tile` with raw SFPI ops in the `add1_sfpu` programming example.

## What changed

- New compute kernel: `tt-metal/tt_metal/programming_examples/add1_sfpu/kernels/compute/add1_sfpi.cpp`.
- Uses `sfpi::vFloat` and `sfpi::dst_reg` to add a scalar across all 32 vectors in a tile.
- Keeps existing CB flow (`init_sfpu`, `copy_tile`, `pack_tile`) but removes LLK unary ops from the compute path.

## Key idea

SFPI provides C++ operators that the Tensix toolchain lowers to raw SFPU instructions. The kernel:

- Converts runtime `scalar_bits` to float inline in `MAIN`.
- Iterates across the 32 vectors that make up a tile.
- Does in-place add on `dst_reg` using SFPI types.

## Switch the example to the new kernel

Update the compute kernel path in the orchestrator:

```cpp
// tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu.cpp
KernelHandle add1_kernel_id = CreateKernel(
  program,
  OVERRIDE_KERNEL_PREFIX "add1_sfpu/kernels/compute/add1_sfpi.cpp",
  core,
  ComputeConfig{
    .math_fidelity = MathFidelity::HiFi4,
    .math_approx_mode = false,
  });
```

## Notes

- SFPI code is guarded by `#ifdef TRISC_MATH` since the SFPU is only on the MATH core.
- `sfpi::dst_reg` is indexed by vector; a full 32x32 tile is 32 vectors.
- This approach is compatible with compiler-generated SFPI C++.

## TT-LLK dependencies in the original unary-op kernel

The original compute kernel (`add1_sfpu/kernels/compute/add1_sfpu.cpp`) depends on TT-LLK through these headers and APIs:

- Headers:
  - `compute_kernel_api/eltwise_unary/eltwise_unary.h` (LLK unary init + CB wiring via `init_sfpu`)
  - `compute_kernel_api/eltwise_unary/binop_with_scalar.h` (LLK scalar binop init + op wrappers)
  - `compute_kernel_api/tile_move_copy.h` and `compute_kernel_api/common.h` (LLK tile regs + CB helpers)
- APIs used:
  - `init_sfpu(...)` (LLK unary op init)
  - `binop_with_scalar_tile_init()` (LLK SFPU pipeline setup)
  - `add_unary_tile(...)` (LLK unary add with scalar)
  - `tile_regs_acquire/commit/wait/release`, `copy_tile`, `pack_tile`, `cb_*` (LLK-backed kernel helpers)

The SFPI variant removes the unary-op LLK dependency (`binop_with_scalar_tile_init` + `add_unary_tile`) and replaces it with direct `sfpi::dst_reg` math, while still using the CB/tile movement helpers.

## Dataflow kernels: APIs and behavior

The `read_tile.cpp` and `write_tile.cpp` kernels are data-movement only. They use NoC DMA helpers plus circular buffer (CB) producer/consumer primitives.

### Runtime args + layout

- `get_arg_val<uint32_t>(index)` pulls runtime args from the host (DRAM base address, tile count).
- `TensorAccessorArgs<0>()` supplies compile-time metadata for DRAM layout.
- `TensorAccessor(args, base_addr, tile_size_bytes)` wraps layout + base address for tiled NoC ops.
- `get_tile_size(cb_id)` returns the page size for the CB (bytes per tile).

### Circular buffer producer (reader)

- `cb_reserve_back(cb, tiles)` reserves space at the CB back for producer writes.
- `get_write_ptr(cb)` returns the L1 address to write the next tile.
- `cb_push_back(cb, tiles)` publishes produced tiles to the consumer.

### Circular buffer consumer (writer)

- `cb_wait_front(cb, tiles)` blocks until tiles are available at the CB front.
- `get_read_ptr(cb)` returns the L1 address of the next tile to read.
- `cb_pop_front(cb, tiles)` releases consumed tiles.

### NoC tiled DMA

- `noc_async_read_tile(tile_idx, tensor_accessor, l1_dst)` enqueues a tiled read from DRAM to L1.
- `noc_async_read_barrier()` waits for the read to complete before publishing.
- `noc_async_write_tile(tile_idx, tensor_accessor, l1_src)` enqueues a tiled write from L1 to DRAM.
- `noc_async_write_barrier()` waits for the write to complete before releasing.

These APIs are part of the dataflow/ckernel runtime (not SFPU math). They orchestrate NoC transfers and CB staging so the compute kernel can operate on tiles in L1.
