# Tilize, Untilize, and Tile Layout

How row-major data becomes 32x32 tiles with 4x 16x16 faces, where that conversion happens (host CPU vs device kernel), how data physically moves, and what the hardware expects. Investigated against Blackhole (BH) but largely architecture-neutral except where noted.

## Tile Format

A 32x32 tile is split into **4 contiguous 16x16 faces** stored in row-major face order ("Z" pattern):

```
+------------------+------------------+
|     Face 0       |     Face 1       |
|  rows  0-15      |  rows  0-15      |
|  cols  0-15      |  cols 16-31      |
+------------------+------------------+
|     Face 2       |     Face 3       |
|  rows 16-31      |  rows 16-31      |
|  cols  0-15      |  cols 16-31      |
+------------------+------------------+
```

Flat memory layout per tile:

| Offset range | Face | Logical rows | Logical cols |
|---|---|---|---|
| 0 - 255 | Face 0 | 0-15 | 0-15 |
| 256 - 511 | Face 1 | 0-15 | 16-31 |
| 512 - 767 | Face 2 | 16-31 | 0-15 |
| 768 - 1023 | Face 3 | 16-31 | 16-31 |

Within each face: standard row-major (row 0 first, 16 elements, then row 1, etc.). 256 elements per face, 1024 per tile.

Index formula for datum at tile position (r, c):

```
face_offset = 0   if r < 16 and c < 16   (Face 0)
              256 if r < 16 and c >= 16  (Face 1)
              512 if r >= 16 and c < 16  (Face 2)
              768 if r >= 16 and c >= 16 (Face 3)

flat_index = face_offset + (r % 16) * 16 + (c % 16)
```

Reference implementation: `get_tilized_idx()` in `ttnn/cpp/ttnn/deprecated/tt_dnn/kernels/dataflow/moreh_common.hpp:648`.

This is the `TILED_NFACES` format. Constants: `TILE_HEIGHT=32`, `TILE_WIDTH=32`, `FACE_HEIGHT=16`, `FACE_WIDTH=16` in `tt_metal/api/tt-metalium/constants.hpp`. The `Tile` struct at `tt_metal/api/tt-metalium/tile.hpp` also supports `transpose_within_face` and `transpose_of_faces` flags (column-major face order: F0->F2->F1->F3).

### Why Faces Exist

The Tensix FPU/matrix engine natively multiplies **16x16 matrices**. A 32x32 tile matmul is decomposed into face-level 16x16 multiplies. The unpacker reads face-by-face into source registers; the packer writes face-by-face from the destination register. Source: `tech_reports/tensor_layouts/tensor_layouts.md:62`.

### Supported Tile Shapes

| Tile shape | Face shape | Num faces |
|---|---|---|
| 32x32 | 16x16 | 4 (default) |
| 16x32 | 16x16 | 2 |
| 32x16 | 16x16 | 2 |
| 16x16 | 16x16 | 1 |

Valid combinations defined in `tt_metal/impl/data_format/tile.cpp:19-34`.

## Where Tilize Happens

Two completely independent paths. The decision point is `ttnn/cpp/ttnn/operations/core/to_layout/to_layout_op.cpp`:

```cpp
if (tt::tt_metal::is_device_tensor(tensor_arg)) {
    // DEVICE PATH: launch tilize/untilize kernel
    return ttnn::tilize(tensor, ...);
} else {
    // HOST PATH: CPU reorder
    return tensor.to_layout(layout);
}
```

### Path A: Host CPU Tilize

Used when you create a tensor with `Layout::TILE` and write it to device, or call `to_layout` on a host tensor.

| Step | What happens | Where |
|---|---|---|
| 1 | `encode_tensor_data()` called during host-to-device prep | `ttnn/core/tensor/tensor_impl.cpp:880` |
| 2 | Calls `convert_layout_row_major_to_tile()` | `ttnn/api/ttnn/tensor/tensor_impl.hpp:85` |
| 3 | Runs `convert_layout()` with `TILED_NFACES` target | `tt_metal/impl/data_format/tilize_utils.cpp:428` |
| 4 | Pure CPU loop reorders `std::vector<T>` elements | Same file, `convert_layout_row_major_to_tile_nfaces()` line 256 |
| 5 | Already-tilized bytes written to hugepages | `tt_metal/impl/buffers/dispatch.cpp:707` |
| 6 | Prefetcher + dispatcher move bytes to DRAM/L1 | No transformation during DMA |

### Path B: Device Kernel Tilize

Used when data is already on device in `ROW_MAJOR` layout and you call `ttnn::tilize()` or `ttnn::to_layout(tensor, TILE_LAYOUT)`.

A standard 3-kernel Tensix program is launched:

| Kernel | Role | Key file |
|---|---|---|
| Reader (dataflow) | NOC-reads row-major sticks from DRAM/L1 into input CB | `tilize/device/kernels/dataflow/reader_unary_stick_layout_split_rows_interleaved.cpp` |
| Compute | Unpacker in tilize mode reorders data; datacopy through MATH; pack to output CB | `tilize/device/kernels/compute/tilize.cpp` |
| Writer (dataflow) | NOC-writes tilized tiles from output CB back to DRAM/L1 | standard writer kernel |

The compute kernel is minimal:

```cpp
tilize_init(cb_id_in0, per_core_block_tile_cnt, cb_id_out0);
for (uint32_t b = 0; b < per_core_block_cnt; ++b) {
    cb_wait_front(cb_id_in0, per_core_block_tile_cnt);
    cb_reserve_back(cb_id_out0, per_core_block_tile_cnt);
    tilize_block(cb_id_in0, per_core_block_tile_cnt, cb_id_out0);
    cb_push_back(cb_id_out0, per_core_block_tile_cnt);
    cb_pop_front(cb_id_in0, per_core_block_tile_cnt);
}
```

Multiple parallelization strategies exist (selected by program factory):

| Factory | Strategy |
|---|---|
| `tilize_single_core_program_factory.cpp` | Single core |
| `tilize_multi_core_interleaved_program_factory.cpp` | Multi-core, row-parallel for interleaved memory |
| `tilize_multi_core_block_program_factory.cpp` | Multi-core, splits both W and H across cores |
| `tilize_multi_core_sharded_program_factory.cpp` | Multi-core, height-sharded input |

All under `ttnn/cpp/ttnn/operations/data_movement/tilize/device/`.

### Tilize with Padding

`ttnn::tilize_with_val_padding()` and `ttnn::tilize_with_zero_padding()` use the same compute kernel but specialized reader kernels that fill pad regions with a packed pad value before the tilize compute step. Entry point: `ttnn/cpp/ttnn/operations/data_movement/tilize_with_val_padding/`.

## Untilize

Same 3-kernel Tensix program structure as tilize (reader, compute, writer). Two fundamentally different hardware strategies for where the reordering happens:

| Strategy | Who reorders | Data path | Compute kernel |
|---|---|---|---|
| Unpacker untilize | Unpacker | CB(tiled) -> **UNPACK untilize mode** -> SRCA(row-major) -> MATH datacopy -> DEST -> PACK normal -> CB(row-major) | `untilize.cpp` |
| Pack untilize (optimized) | Packer | CB(tiled) -> UNPACK normal -> SRCA(tiled) -> MATH datacopy -> DEST(tiled) -> **PACK untilize mode** -> CB(row-major) | `pack_untilize.cpp` |

### Strategy 1: Unpacker-Based Untilize

The unpacker is configured in untilize mode to read face-based tiles and output contiguous rows. The compute kernel mirrors the tilize kernel:

```cpp
untilize_init(src_cb_id);
for (b = 0; b < per_core_block_cnt; ++b) {
    cb_wait_front(src_cb_id, per_core_block_tile_cnt);
    cb_reserve_back(out_cb_id, per_core_block_tile_cnt);
    untilize_block(src_cb_id, per_core_block_tile_cnt, out_cb_id);
    cb_push_back(out_cb_id, per_core_block_tile_cnt);
    cb_pop_front(src_cb_id, per_core_block_tile_cnt);
}
```

Inside `untilize_block()` (`compute_kernel_api/untilize.h`), the unpacker reads a full row of tiles at once (`llk_unpack_untilize(icb, full_ct_dim)`), then MATH does datacopy and PACK writes row-major output, processing `block_ct_dim` tiles per DEST acquire.

#### Blackhole LLK Untilize Mechanics

At the LLK level (`tt_llk_blackhole/llk_lib/llk_unpack_untilize.h`), `_llk_unpack_untilize_init_` configures:

- `Tile_x_dim` set to `1x16` (FACE_DIM_1x16) -- reads one 16-element face row at a time
- Y-stride set to `FACE_R_DIM * datum_size` for stepping through face rows
- `TILE_SIZE` loaded into a GPR for advancing across tiles in a row
- Saves prior unpacker state for restoration in `_llk_unpack_untilize_uninit_`

The actual untilize pass (`_llk_unpack_untilize_pass_`) uses a **two-pass scheme**:

```
Pass 1 (first_pass=true):  SET_Z=0  -> reads top faces (Face 0, Face 1)
Pass 2 (first_pass=false): SET_Z=2  -> reads bottom faces (Face 2, Face 3)
```

Within each pass, the replay buffer MOP stitches face rows back into full-width rows:

```cpp
// Replay buffer (6 instructions):
TTI_DMANOP;                          // wait for prior WRCFG to complete
TTI_UNPACR(SrcA, CH1_Y+=1 CH0_Z+=1) // unpack row from left face, Z inc -> right face
TTI_UNPACR(SrcA, CH1_Y+=1 CH0_Z+=1) // unpack row from right face
TTI_ADDDMAREG(TILE_OFFSET += TILE_SIZE)  // advance to next tile
TTI_STALLWAIT(STALL_CFG, THCON)      // stall for offset write
TTI_ADDRCRZW(reset CH0_Z)           // reset Z to left face for next tile
```

For each of the 16 rows in a face-height, the MOP runs across all tiles in the row. The Z-increment toggles between left face (0/2) and right face (1/3) within each tile, while `TILE_OFFSET` advances across tiles. After processing all tiles in a row, `TILE_OFFSET` is zeroed and the L1 Y counter increments to the next source row.

The result: from `block_tile_cols` tiles arranged as `[T0][T1][T2]...`, each containing 4 faces, the unpacker outputs 32 contiguous rows (16 from top faces pass, 16 from bottom faces pass), each `block_tile_cols * 32` elements wide.

### Strategy 2: Packer-Based Untilize (Optimized)

The unpacker reads tiles in normal mode (no special reconfiguration). MATH does datacopy to DEST. The **packer** is then configured to write DEST contents out in row-major order instead of tile order.

```cpp
pack_untilize_init<block_ct_dim, full_ct_dim>(src_cb_id, out_cb_id);
for (r = 0; r < per_core_block_cnt; ++r) {
    cb_reserve_back(out_cb_id, full_ct_dim);
    for (b = 0; b < num_blocks_per_col; ++b) {
        cb_wait_front(src_cb_id, block_ct_dim);
        pack_untilize_block<block_ct_dim, full_ct_dim>(src_cb_id, 1, out_cb_id, b);
        cb_pop_front(src_cb_id, block_ct_dim);
    }
    cb_push_back(out_cb_id, full_ct_dim);
}
pack_untilize_uninit(out_cb_id);
```

Inside `pack_untilize_block`, tiles are unpacked normally and datacopy'd to DEST, then `llk_pack_untilize` configures the packer's destination offset registers to scatter face rows into the correct row-major positions in the output CB.

The `block_ct_dim` is limited by DEST size (max 8 tiles in half-sync 16-bit, 4 in 32-bit). When `full_ct_dim > block_ct_dim`, the block is processed in chunks via the `block_c_index` parameter, with each chunk placed at the correct column offset in the output.

Blackhole-specific initialization in `pack_untilize_dest_init`:
```cpp
#ifdef ARCH_BLACKHOLE
    MATH((llk_math_reconfig_remap(true)));  // needed for setting swizzle_32b
#endif
```

### Which Strategy Gets Used

The `ttnn::untilize` op has a `use_pack_untilize` parameter (defaults to `true` for supported dtypes). **Pack-untilize is generally preferred** because:
- The unpacker operates in normal mode (no reconfiguration overhead)
- The packer's scatter-write is efficient
- It can be fused with other compute ops (see below)

### Fused Untilize

`pack_untilize_dest` is the variant for when data is **already in DEST** from a prior compute step. This enables fusing untilize with any op that produces tiles in DEST:

- **Matmul** `untilize_out=true`: after the last matmul accumulation, `pack_untilize_dest` writes DEST to the output CB in row-major order. No extra unpack/datacopy step needed.
- **Reduce ops**: after `reduce_tile` accumulates into DEST, `pack_untilize_dest` can write row-major output directly.

This avoids a separate untilize kernel launch entirely -- the layout conversion is folded into the packer step of the producing op.

### Untilize with Unpadding

`ttnn::untilize_with_unpadding()` strips padding during the **writer dataflow kernel** step (not during compute). Specialized writer kernels skip pad rows/columns when writing sticks back to DRAM/L1. Entry point: `ttnn/cpp/ttnn/operations/data_movement/untilize_with_unpadding/`.

### Untilize Parallelization

| Factory | Strategy |
|---|---|
| `untilize_single_core_program_factory.cpp` | Single core |
| `untilize_multi_core_program_factory.cpp` | Multi-core row-parallel |
| `untilize_multi_core_block_program_factory.cpp` | Multi-core block-parallel |
| `untilize_multi_core_parallelize_column_program_factory.cpp` | Multi-core column-parallel |
| `untilize_multi_core_sub_core_grids_program_factory.cpp` | Sub-grid parallelization |
| `...identical_program_factory.cpp` | Sharded input/output with identical shard specs |

All under `ttnn/cpp/ttnn/operations/data_movement/untilize/device/factories/`.

## Blackhole LLK Hardware Mechanics

The actual reordering is done by the Tensix **unpacker hardware**, not by software loops. Key register programming in `tt_metal/third_party/tt_llk/tt_llk_blackhole/llk_lib/llk_unpack_tilize.h`:

### `_llk_unpack_tilize_init_` (Blackhole)

```cpp
config.f.tileize_mode = 1;              // enable tilize mode in unpacker
config.f.shift_amount = (SCALE_DATUM_SIZE(unpack_src_format, block_c_dim)) >> 4;  // row stride

// Force entire tile as one flat read:
const uint Tile_x_dim = 1024;           // read 1024 elements as one chunk
const uint Tile_z_dim = 1;              // single "face" iteration
cfg_reg_rmw_tensix<...>(Tile_x_dim | (Tile_x_dim << 16));
cfg_reg_rmw_tensix<...>(0 | (Tile_z_dim << 16));
TTI_SETADCXX(p_setadc::UNP0, 1023, 0x0);  // x-end = 1023
```

The `shift_amount` encodes the source row stride so the unpacker can gather the correct elements from contiguous row-major data into face-based layout in the SRCA register file. MATH does A-to-DEST datacopy, then PACK writes the tile out in standard face format.

### `_llk_unpack_tilize_` (per-tile execution)

1. Compute address from `base_address + SCALE_DATUM_SIZE(format, tile_index) * 2`
2. Clear Z/W address counters
3. Wait for free context, set base address register
4. Run MOP (the pre-programmed micro-op sequence)
5. Release context, switch config context

The MOP itself (`_llk_unpack_tilize_mop_config_`) is a single UNPACR instruction with Z-increment that steps through the tile data:

```cpp
TT_OP_UNPACR(SrcA, 0b1 /*Z inc*/, 0, 0, 0, 1, 1 /*Set Dvalid*/, ...);
```

### `_llk_unpack_tilizeA_B_` (fused tilize + unpack B)

Used by `tilizeA_B_reduce_init` for fused tilize+reduce paths. Iterates over faces explicitly:

```
Face 0: address = base
Face 1: address = base + 1x16 row of datums
Face 2: address = base + block_ct_dim * TILE_C_DIM * face_r_dim
Face 3: address = Face 2 + 1x16 row of datums
```

Each face: unpacks `face_r_dim` rows of 1x16 datums into SrcA using a replay buffer loop, with `CFGSHIFTMASK` instructions incrementing the L1 address by the row stride between rows.

### Blackhole vs Wormhole Differences

| Feature | Wormhole | Blackhole |
|---|---|---|
| `fast_tilize` (multi-tile per DEST acquire) | Supported via `llk_unpack_fast_tilize_*` | **Falls back to regular tilize** |
| Packer tilize flag | Not needed | `llk_pack_init<false, false, true /*tilize_en*/>(ocb)` required |
| Inline DW writes | Native NOC inline writes | Emulated: write value to L1 scratch, then NOC read from it |

From `compute_kernel_api/tilize.h`:
```cpp
#ifdef ARCH_BLACKHOLE
    // Blackhole fallback
    tilize_init(icb, full_dim, ocb);
#else
    UNPACK((llk_unpack_fast_tilize_init(icb, full_dim)));
    ...
#endif
```

## Tilize Is Never a DMA Operation

The command queue dispatch system (`tt_metal/impl/dispatch/kernels/cq_dispatch.cpp`, `cq_commands.hpp`) is completely layout-agnostic. Dispatch commands:

- `CQ_DISPATCH_CMD_WRITE_LINEAR` -- straight NOC write
- `CQ_DISPATCH_CMD_WRITE_PAGED` -- bank-interleaved NOC writes
- `CQ_DISPATCH_CMD_WRITE_PACKED` -- multi unicast/multicast writes

None perform data reordering. The dispatcher copies bytes from its circular buffer to the target NOC address using `cq_noc_async_write_with_state_any_len()`. It does not know or care about tile layout.

There is no "tilize during transfer", "tilize during DMA", or "zero-copy tilize" mechanism.

## How Matmul Gets Tiled Input

**Matmul does NOT auto-tilize.** Both inputs must already be `Layout::TILE`:

```cpp
// matmul_device_operation.cpp:105-107
TT_FATAL(
    (input_tensor_a.layout() == Layout::TILE && input_tensor_b.layout() == Layout::TILE),
    "Inputs to matmul must be tilized");
```

There is **no fused tilize+matmul** path. The practical flow:

1. `ttnn.to_layout(input, ttnn.TILE_LAYOUT)` -- tilizes on host or device
2. `ttnn.matmul(a, b)` -- reader kernels use `noc_async_read_tile()` to read tiles from DRAM into CBs; compute kernel calls `matmul_tiles()` / `matmul_block()` which operate on 16x16 faces
3. Optionally: `untilize_out=true` in `MatmulMultiCoreReuseMultiCast1DProgramConfig` fuses untilization into the packer step via `pack_untilize_dest()`

The `tilizeA_B` LLK variant (fused tilize source A + unpack source B) exists but is used only by `tilizeA_B_reduce_init` for fused tilize+reduce, **not** by standard matmul.

## End-to-End Data Flow

```
Host CPU memory (row-major torch tensor)
    |
    | Option A: tilize on host CPU (convert_layout_row_major_to_tile)
    | Option B: write row-major to device, tilize on device later
    v
Hugepage (host pinned memory)
    |  PCIe DMA -- no transformation
    v
Prefetcher kernel (reads hugepage into dispatch CB)
    |  NOC write -- no transformation, just byte copies
    v
Device DRAM or L1 (whatever layout host sent)
    |
    | [If row-major: ttnn::tilize() launches 3-kernel program]
    |   Reader: NOC reads sticks -> input CB
    |   Compute: unpacker tileize_mode reorders -> DEST -> pack to output CB
    |   Writer: NOC writes tiles -> DRAM/L1
    v
Device DRAM or L1 (tiled: 32x32 tiles, each 4x 16x16 faces)
    |
    |  matmul reader: noc_async_read_tile() -> input CB
    v
Tensix compute (unpack tiles -> FPU 16x16 face matmul -> pack tiles)
    |
    |  matmul writer: noc_async_write_tile() -> DRAM/L1
    v
Output tensor (tiled, or row-major if untilize_out=true)
```

## Key Source Files

| File | Purpose |
|---|---|
| `tt_metal/api/tt-metalium/constants.hpp` | `TILE_HEIGHT`, `TILE_WIDTH`, `FACE_HEIGHT`, `FACE_WIDTH` |
| `tt_metal/api/tt-metalium/tile.hpp` | `Tile` struct with shape, face, transpose fields |
| `tt_metal/api/tt-metalium/tilize_utils.hpp` | `TensorLayoutType` enum, host conversion declarations |
| `tt_metal/impl/data_format/tilize_utils.cpp` | Host CPU tilize/untilize implementations |
| `tt_metal/include/compute_kernel_api/tilize.h` | Device compute API: `tilize_init`, `tilize_block`, `fast_tilize_*` |
| `tt_metal/include/compute_kernel_api/untilize.h` | Device compute API: `untilize_init`, `untilize_block` |
| `tt_metal/include/compute_kernel_api/pack_untilize.h` | Optimized pack-untilize API |
| `tt_metal/third_party/tt_llk/tt_llk_blackhole/llk_lib/llk_unpack_tilize.h` | BH LLK: `_llk_unpack_tilize_init_`, `_llk_unpack_tilize_`, `_llk_unpack_tilizeA_B_` |
| `tt_metal/third_party/tt_llk/tt_llk_blackhole/llk_lib/llk_unpack_untilize.h` | BH LLK: `_llk_unpack_untilize_init_`, `_llk_unpack_untilize_pass_`, two-pass face scheme |
| `ttnn/cpp/ttnn/operations/core/to_layout/to_layout_op.cpp` | Decision point: host vs device tilize |
| `ttnn/cpp/ttnn/operations/data_movement/tilize/` | Device tilize op, program factories, kernels |
| `ttnn/cpp/ttnn/operations/data_movement/untilize/` | Device untilize op, program factories, kernels |
| `tech_reports/tensor_layouts/tensor_layouts.md` | Official tile/face layout documentation |
