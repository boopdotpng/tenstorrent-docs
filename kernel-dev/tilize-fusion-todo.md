# Tilize/Untilize Fusion into Compute Kernels

Reminder for the tinygrad port: fuse tilize and untilize directly into the first/last compute kernel instead of running them as separate programs.

## Current architecture (blackhole-py)

Tilize and untilize run as standalone 3-kernel programs (reader/compute/writer) on all cores. The data path for a matmul is:

```
sysmem ──(tilize reader)──► L1 CB ──(tilize compute)──► L1 CB ──(tilize writer)──► DRAM
                                                                                      │
DRAM ◄──(untilize writer)── L1 CB ◄──(untilize compute)── L1 CB ◄──(untilize reader)──┘
                                                                                      │
                                                                   (matmul in between) │
```

This adds a full DRAM round-trip per input tensor and per output tensor. On a 5120x4096 bf16 matrix (~40 MB), tilize alone takes 100-300 ms depending on PCIe congestion from 118 cores all reading sysmem simultaneously.

## Target architecture (tinygrad port)

### Input tilize: fuse into matmul reader

The matmul reader should read row-major sticks directly from sysmem (or DRAM if pre-staged), then use `tilize_init` / `tilize_block` in the compute kernel's unpack phase to convert to tile format before the FPU matmul. This eliminates the separate tilize program and the DRAM write/read round-trip.

The hardware tilizer (`llk_unpack_tilize`) is designed for exactly this -- it sits in the unpack path and reorders row-major CB data into face-interleaved tile format on the fly.

### Output untilize: fuse into matmul packer

Use `pack_untilize_dest_init` / `pack_untilize_dest` to untilize directly from DEST registers to the output CB. This fuses with the matmul's final pack step -- the packer writes row-major data instead of tile-ordered data. The matmul writer then scatters the row-major sticks to their correct sysmem/DRAM locations.

See `compute_kernel_api/pack_untilize.h` for the `pack_untilize_dest` API (no unpack/math needed since data is already in DEST from matmul).

## Relevant APIs

| API | Header | Purpose |
|-----|--------|---------|
| `tilize_init(icb, block, ocb)` | `compute_kernel_api/tilize.h` | Init unpacker for row-major-to-tile conversion |
| `tilize_block(icb, block, ocb)` | `compute_kernel_api/tilize.h` | Tilize block of tiles from input CB to output CB |
| `tilize_block_no_pack(icb, block, dst_idx)` | `compute_kernel_api/tilize.h` | Tilize into DEST without packing (for chaining with matmul) |
| `pack_untilize_dest_init<block_ct, full_ct>(ocb)` | `compute_kernel_api/pack_untilize.h` | Init packer for tile-to-row-major conversion from DEST |
| `pack_untilize_dest<block_ct, full_ct>(ocb)` | `compute_kernel_api/pack_untilize.h` | Pack-untilize directly from DEST to output CB |

## Notes

- On Blackhole, `fast_tilize` falls back to regular `tilize` (`tilize.h:376-379`), so there is no benefit from the fast path.
- `pack_untilize_dest` max block sizes: 8 tiles (half-sync 16-bit), 4 tiles (half-sync 32-bit), 16/8 tiles (full-sync).
- The `tilize_block_no_pack` variant leaves tilized data in DEST, which is the right primitive for chaining tilize with matmul unpack -- but the matmul expects data to come from the unpacker, not already in DEST. The practical approach is to tilize into a CB and let the matmul reader read from that CB.
