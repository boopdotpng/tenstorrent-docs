# Coordinates, translation, and harvesting (Blackhole)

This consolidates coordinate systems, NOC translation tables, harvesting behavior, and DRAM bank table pitfalls.

## Coordinate systems (why `(16, 2)` is valid)

On Blackhole, you will see multiple coordinate systems in software:

- **NOC0 / physical**: the chip’s full NoC grid. For Blackhole this is `x=0..16` and `y=0..11` (17×12).
- **TRANSLATED / virtual**: a compact “worker grid” view used by higher-level software (width depends on harvesting).
- **LOGICAL**: an even more abstract, harvesting-aware indexing over the translated view.

### Key facts for P100a

- `(16, 2)` **does exist** on Blackhole: it is a Tensix tile in the far-right Tensix column.
- Tensix tiles live at `y=2..11`.
- Tensix columns on Blackhole are `x ∈ {1..7, 10..16}` (columns `0` and `9` are DRAM, `8` is L2CPU/ARC-related).

### Why `(16, 2)` can look “out of range”

If you’re thinking in **translated** (virtual) worker-grid coordinates, the max `x` may be `15` (or less when harvested).
But the same core can have a **NOC0** coordinate of `x=16`.

Concrete example from tt-metal’s Blackhole coord-translation test:
- translated/top-right core: `(15, 2)`
- corresponding NOC0 coord: `(16, 2)`

So a failure talking to `(16, 2)` is not “suggesting a non-existent tile”; it usually means that tile/column is not responding (e.g. harvested/disabled, or the device is in a bad init state).

## NOC translation enable (bit 14)

NOC translation is controlled by **bit 14** of the NIU_CFG register:
- `NIU_CFG_0_NOC_ID_TRANSLATE_EN = 14` (in `tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h`)

Blackhole register addresses:
```
NIU_CFG_NOC0_BAR_ADDR = 0x1FD04100
NIU_CFG_NOC1_BAR_ADDR = 0x1FD14100  // +0x10000 offset

NIU_CFG_NOC0_ARC_ADDR = 0x80050100
NIU_CFG_NOC1_ARC_ADDR = 0x80058100
```

UMD reads translation state via BAR or ARC access and checks bit 14.

When translation is enabled, firmware uses `NOC_ID_LOGICAL` and translation tables for routing.

## Per-tile translation tables (hardware)

These tables are distinct from the global “translation enable” bit: you can set the bit and still have broken routing if the per-tile tables (and per-tile `NOC_ID_LOGICAL`) are not programmed.

Blackhole defines X/Y ID translation table registers in:
- `tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h`
  - `NOC_X_ID_TRANSLATE_TABLE_0..5`
  - `NOC_Y_ID_TRANSLATE_TABLE_0..5`
  - `NOC_ID_LOGICAL`

Per-tile MMIO addresses (NoC0 base `0xFFB20000`):
- `NIU_CFG_0` at `0xFFB20100`
- `NOC_X_ID_TRANSLATE_TABLE_0..5` at `0xFFB20118..0xFFB2012C`
- `NOC_Y_ID_TRANSLATE_TABLE_0..5` at `0xFFB20130..0xFFB20144`
- `NOC_ID_LOGICAL` at `0xFFB20148`

NoC1 uses the same layout with `+0x10000` instance offset.

### Table format

- Each of X and Y tables has **32 entries**
- Each entry is **5 bits** (`NOC_TRANSLATE_ID_WIDTH = 5`)
- Entries are packed across **6 x 32-bit registers**

Packing expectation:
```
reg_k bit [5*j + 4 : 5*j] = table_entry[k*6 + j]    (j = 0..5; reg5 only j=0..1)
```

`NOC_ID_LOGICAL` is a per-tile 12-bit packed coordinate:
```
NOC_ID_LOGICAL = (logical_y << 6) | logical_x
```

### Who programs these tables?

Evidence in-tree strongly suggests ARC firmware programs the translation tables during early init / POST_RESET:
- UMD docs say programming is done ahead of time by ARC firmware.
- Blackhole RISC-V “noc” firmware reads the enable bit and uses `NOC_ID_LOGICAL` but does not write the tables.
- No host-side writes to the table registers were found in open-source UMD/tt-metal.

Net: in the standard stack, you typically reset and let ARC handle the tables.

### If translation is disabled

If `NIU_CFG_0[14]` is cleared:
- coordinates are physical for the selected NoC
- NOC1 uses mirrored coordinates (`NOC0_X_TO_NOC1_X`, `NOC0_Y_TO_NOC1_Y`)

If NOC1 still hangs with translation disabled, likely causes include:
- translation wasn’t disabled for the relevant tiles/NOC instance
- runtime bank tables were not seeded for NOC1

## Harvesting and ioctl coordinate space

`TENSTORRENT_IOCTL_CONFIGURE_TLB` expects literal NoC coordinates and does **not** apply logical↔physical translation or harvesting masks.

If you bypass UMD and call the ioctl directly:
- you must pass physical NoC coordinates
- you must avoid harvested columns/tiles yourself
- multicast rectangles must be split to avoid harvested or non-Tensix columns

For Tensix NoC0 access on Blackhole:
- valid Tensix coords: `x ∈ {1..7,10..16}`, `y ∈ {2..11}`
- remove harvested Tensix columns from target set
- avoid non-Tensix columns (`x=0` DRAM west, `x=8` ARC/L2CPU/security, `x=9` DRAM east)

## DRAM bank tables and translated coords (pure-py pitfall)

When NOC translation / coordinate virtualization is enabled (default after `tt-smi -r`), DRAM endpoints are **translated** coordinates, not physical. If you build `dram_bank_to_noc_xy` from physical coords, NoC1 nonposted writes can hang.

Fix:
- use the tt-umd Blackhole mapping for logical `(bank_id, port)` → translated `(x,y)` in DRAM space
- apply `dram_views[].worker_endpoint` using logical bank id

## DRAM reads returning zeros (InterleavedAddrGenFast)

`InterleavedAddrGenFast<true>` does **not** hardcode DRAM NoC endpoints. It reads per-core tables:
- `dram_bank_to_noc_xy[noc][bank_index]`
- `bank_to_dram_offset[bank_index]`

These tables live in each RISC-V core’s local memory and are populated by firmware at boot via:
- `noc_bank_table_init(MEM_BANK_TO_NOC_SCRATCH)`

In pure-py bring-up, missing or mismatched tables can cause NCRISC reads to return zeros.

The scratch layout for Blackhole:
- `MEM_BANK_TO_NOC_SCRATCH` size: 2048 bytes
- layout: `dram_bank_to_noc_xy` + `l1_bank_to_noc_xy` + `bank_to_dram_offset` + `bank_to_l1_offset`

Key note: NOC1 coordinate transforms are mirrored; if only NoC0 tables are correct, NOC1 reads can still fail.

### Practical next steps (highest signal)

1. Compile NCRISC with `NOC_INDEX=0` and re-run the repro.
2. Add a tiny NCRISC kernel to read one DRAM word and copy to L1 for host readback.
3. Replicate tt-metal’s host-side init:
   - `MetalContext::generate_device_bank_to_noc_tables`
   - `MetalContext::initialize_device_bank_to_noc_tables`
