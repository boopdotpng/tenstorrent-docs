# Add1 SFPU example: CBs, cores, and pipeline

This note explains what the add1 SFPU programming example is doing and how circular buffers (CBs) work on a Tensix core.

## What is a core here?

A "core" in TT-Metal host code refers to a Tensix worker core (a Tensix tile) on the device, not a host CPU core. Each core has:

- Local L1 memory.
- Data-movement RISCs (BRISC and NCRISC) for NoC reads/writes.
- Compute engines (SFPU, pack/unpack).

The example pins all kernels to a single core:

```
constexpr CoreCoord core = {0, 0};
```

## What is a CB?

A CB is a ring buffer in L1 memory on a single core. Each core has 32 CB slots identified by `c_0` through `c_31`. Each slot is its own ring buffer. The capacity (in tiles) is chosen at allocation time.

Key points:

- CBs are per-core. They are not shared across cores.
- CB index (e.g. `c_0`, `c_16`) chooses the ring slot, not a tile index.
- The number of tiles stored in a CB is set by `cb_tiles` when creating it.
- For a given CB ID, only one thread should update the write pointer (`cb_push_back`) and only one thread should update the read pointer (`cb_pop_front`). Multiple producers/consumers on the same CB are undefined.

In the add1 example:

- `c_0` is the input CB (CB0).
- `c_16` is the output CB (CB16).
- Each CB is sized to hold `cb_tiles = 2` tiles.

## What is being pushed into a CB?

Raw tile data (32x32 elements) in L1 memory. There is no C++ struct. The producer reserves space, writes tile bytes, then publishes.

Producer flow:

- `cb_reserve_back(cb_id, 1)` reserves space.
- `get_write_ptr(cb_id)` returns an L1 address to write the tile.
- `cb_push_back(cb_id, 1)` publishes the tile.

Consumer flow:

- `cb_wait_front(cb_id, 1)` waits for a tile.
- `get_read_ptr(cb_id)` or `copy_tile` reads from the front.
- `cb_pop_front(cb_id, 1)` consumes the tile.

## Per-core pipeline in add1_sfpu

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

## Who produces/consumes a CB?

Each CB is local to a single core. The producer and consumer are kernels running on RISCs/compute engines within that same core.

In add1_sfpu on core (0,0):

- CB0 producer: reader kernel on NCRISC.
- CB0 consumer: compute kernel on SFPU (math engine).
- CB16 producer: compute kernel (pack).
- CB16 consumer: writer kernel on BRISC.

There is no cross-core CB sharing in this example. If you use multiple cores, each core has its own CBs and its own producer/consumer pair, and you partition tiles across cores.

## How many elements are processed?

Tiles are 32x32 bfloat16. In the example:

- `n_tiles = 64`
- Each tile has 1024 elements
- Total elements = 64 * 1024 = 65536

A CB does not need to hold all tiles. It just streams tiles through a small ring (2 tiles here) while the loop iterates over all tiles.

## What does "configuring the pipeline" mean?

The compute kernel calls:

- `init_sfpu(c_0, c_16)` to bind CB0 as input and CB16 as output for the unpack/pack hardware.
- `binop_with_scalar_tile_init()` to set up the SFPU microcode/state for the scalar binop family.

This does not move data. It configures the compute datapath so later `add_unary_tile` calls run correctly. Skipping it can leave the SFPU in an undefined state.

## How are arguments passed into the kernel?

Runtime args are inline values stored in a kernel argument buffer and read with `get_arg_val`. For add1:

- Compute kernel args: `n_tiles`, `scalar_bits`.
- Reader/Writer args: DRAM base address, `n_tiles`.

The DRAM address is a pointer to the device buffer, and the dataflow kernels use a tensor accessor + tile index to access tiles.

## BRISC vs NCRISC for data movement

BRISC and NCRISC are both data-movement RISCs on the core. They use different NoCs.

- Functionally either can read or write.
- Common pattern: reader on NCRISC and writer on BRISC to overlap traffic and avoid contention.

## Choosing which core hosts the CB

The host chooses the core when creating CBs and kernels. Change `CoreCoord` (or use a core range) to place CBs and kernels on different Tensix tiles. Each core has its own independent CBs and L1.
