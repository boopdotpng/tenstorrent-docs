# Blackhole PCIe NoC Host Access: TLB ioctl coordinate space + harvesting

## Summary

`TENSTORRENT_IOCTL_CONFIGURE_TLB` expects literal NoC coordinates (per selected NoC) and does **not** apply any logical↔physical translation or harvesting masks. If you want a safe `ALL_TILES` abstraction, you must exclude harvested/invalid targets (and split multicast rectangles) in userspace.

## Code paths (userspace → kernel → HW)

- Userspace packs ioctl args without translation:
  - `tt-umd/device/tt_kmd_lib/tt_kmd_lib.c` `tt_tlb_map()`
  - `tt-umd/device/pcie/tlb_handle.cpp` `TlbHandle::configure()` → `tt_tlb_map()`
- Kernel handler passes config through unchanged:
  - `tt-kmd/memory.c` `ioctl_configure_tlb()` → `tenstorrent_device_configure_tlb()`
- Blackhole driver writes coordinates directly into the TLB registers:
  - `tt-kmd/blackhole.c` `blackhole_configure_tlb_2M()` / `blackhole_configure_tlb_4G()`

The ioctl config struct is defined in `tt-kmd/ioctl.h` `struct tenstorrent_noc_tlb_config`.

## Coordinate systems (what you should pass)

The TLB ioctl’s `x_start/y_start/x_end/y_end` are interpreted as physical NoC coordinates for the chosen NoC (`noc=0` or `noc=1`).

Blackhole NoC0 physical layout examples (from UMD arch tables):
- Tensix: `x ∈ {1..7, 10..16}`, `y ∈ {2..11}` (`tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp` `TENSIX_CORES_NOC0`)
- ARC: `(8,0)` (`ARC_CORES_NOC0`)
- DRAM: banks at `x ∈ {0,9}` with multiple ports (`DRAM_CORES_NOC0`)

Special columns like `x=8` (ARC/L2CPU/security) and `x=9` (DRAM column) are *real physical* coordinates; they are not “virtual placeholders” that the driver will reinterpret.

## Harvesting and “logical/remapped” coordinates (UMD-only)

UMD provides logical and translated coordinate spaces, and performs harvesting-aware remaps there (e.g. packing unharvested Tensix columns and moving harvested columns to the maximum X region).

This is implemented in:
- `tt-umd/device/coordinates/blackhole_coordinate_manager.cpp` `BlackholeCoordinateManager::fill_tensix_noc0_translated_mapping()`

If you bypass UMD and call the ioctl directly, you do **not** get this behavior.

### `tensix_tile_cols` values are physical NoC X coordinates

UMD’s harvesting locations are defined as NoC0 X coordinates:
- `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp` `HARVESTING_NOC_LOCATIONS`

So a report like `tensix_tile_cols=(6, 15)` means “NoC0 columns X=6 and X=15 are disabled”.

## Multicast rectangles

Multicast in the TLB config is just a rectangle (`x_start/y_start` → `x_end/y_end`) plus a `mcast` bit; the driver does not apply a harvested-tile mask.

Blackhole does have “strided multicast” hardware support for some windows, but the `CONFIGURE_TLB` ioctl does not expose it and explicitly clears any strided pattern state:
- `tt-kmd/blackhole.c` (`TLB_STRIDED_COUNT`, and the strided register clear in `blackhole_configure_tlb_2M()`)

Practical consequence: if your rectangle spans harvested/invalid columns, you must split it yourself.

## Making `ALL_TILES` safe (recommended rules)

For Tensix NoC0 access on Blackhole:
- Enumerate valid physical Tensix coords from the architecture layout (`x ∈ {1..7,10..16}`, `y ∈ {2..11}`).
- Remove harvested Tensix columns (e.g. `{6,15}`) from the target set.
- When using multicast rectangles, split into rectangles that do not include:
  - harvested Tensix columns, or
  - non-Tensix columns (`x=0` DRAM west, `x=8` ARC/L2CPU/security, `x=9` DRAM east).

Example (p100a with harvested Tensix columns `x={6,15}`):
- `x=1..5, y=2..11`
- `x=7..7, y=2..11`
- `x=10..14, y=2..11`
- `x=16..16, y=2..11`

