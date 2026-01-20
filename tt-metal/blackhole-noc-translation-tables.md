# Blackhole NOC translation tables (per-tile) and NOC1 failures

This doc is about the *hardware* coordinate-translation tables behind `NIU_CFG_0[14]` (`NOC_ID_TRANSLATE_EN`) on Blackhole (tt-1xx). These tables are distinct from the global “translation enable” bit: you can set the bit and still have broken routing if the per-tile tables (and per-tile `NOC_ID_LOGICAL`) are not programmed.

## 1) Where are the per-tile translation tables?

Blackhole defines X/Y ID translation table registers in:

- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h`
  - `NOC_X_ID_TRANSLATE_TABLE_0..5`
  - `NOC_Y_ID_TRANSLATE_TABLE_0..5`
  - `NOC_ID_LOGICAL`

They live in each tile’s NIU “cfg” register block:

- `NOC_REGS_START_ADDR = 0xFFB20000` (NOC0 regs for that tile)
- `NOC_CFG(reg) = NOC_REGS_START_ADDR + 0x100 + reg*4`

NOC1 uses the same layout, but with a `+0x10000` instance offset:

- `NOC_INSTANCE_OFFSET = 0x00010000`
- `NOC1_REGS_START_ADDR = 0xFFB30000`

### Concrete addresses (Blackhole, per tile)

For NOC0 (base `0xFFB20000`):

- `NIU_CFG_0` (`NOC_CFG[0x0]`) at `0xFFB20100`
- `NOC_X_ID_TRANSLATE_TABLE_0..5` (`NOC_CFG[0x6..0xB]`) at `0xFFB20118..0xFFB2012C`
- `NOC_Y_ID_TRANSLATE_TABLE_0..5` (`NOC_CFG[0xC..0x11]`) at `0xFFB20130..0xFFB20144`
- `NOC_ID_LOGICAL` (`NOC_CFG[0x12]`) at `0xFFB20148`

For NOC1 (base `0xFFB30000`), add `0x10000`:

- `NIU_CFG_0` at `0xFFB30100`
- `NOC_X_ID_TRANSLATE_TABLE_0..5` at `0xFFB30118..0xFFB3012C`
- `NOC_Y_ID_TRANSLATE_TABLE_0..5` at `0xFFB30130..0xFFB30144`
- `NOC_ID_LOGICAL` at `0xFFB30148`

Notes:
- These are “tile MMIO” addresses as seen via NoC/TLB access (UMD’s `get_noc_reg_base(..., noc)` maps `CoreType::{TENSIX,ETH,DRAM}` to `0xFFB2_0000` / `0xFFB3_0000` on Blackhole).
- UMD also exposes BAR0 aliases for (at least) the ARC tile register window:
  - `NIU_CFG_NOC0_BAR_ADDR = 0x1FD04100`
  - `NIU_CFG_NOC1_BAR_ADDR = 0x1FD14100`
  from `tt-metal/tt_metal/third_party/umd/device/api/umd/device/arch/blackhole_implementation.hpp`.

### Quick sanity check: read tables on the ARC tile via BAR

UMD exposes the ARC tile’s NOC register window via BAR0; you can use this to quickly check whether the translation tables look programmed without needing per-tile TLB hopping.

For the ARC tile BAR0 window:

- NOC0 window base appears to be `0x1FD04000` (see `BH_NOC_NODE_ID_OFFSET = 0x1FD04044`)
  - X table regs at `0x1FD04118..0x1FD0412C`
  - Y table regs at `0x1FD04130..0x1FD04144`
  - `NOC_ID_LOGICAL` at `0x1FD04148`
- NOC1 window base appears to be `0x1FD14000`
  - X table regs at `0x1FD14118..0x1FD1412C`
  - Y table regs at `0x1FD14130..0x1FD14144`
  - `NOC_ID_LOGICAL` at `0x1FD14148`

## 2) How are these tables programmed (ARC vs host)?

Evidence in-tree strongly suggests: **ARC firmware programs the hardware translation tables during early init / POST_RESET**.

- UMD docs state: “Wormhole and later architectures implement a programmable coordinate translation table in hardware… Programming is done ahead of time by ARC firmware.”
  - `tt-umd/docs/COORDINATE_SYSTEMS.md`
- Blackhole RISC-V “noc” firmware reads the enable bit and uses `NOC_ID_LOGICAL` when translation is enabled, but does **not** write any table registers:
  - `tt-metal/tt_metal/hw/firmware/src/tt-1xx/blackhole/noc.c`
- No host-side programming of `NOC_X_ID_TRANSLATE_TABLE_*` / `NOC_Y_ID_TRANSLATE_TABLE_*` / `NOC_ID_LOGICAL` was found in UMD/tt-metal sources (only reads of `NIU_CFG` to detect whether translation is enabled).
- The kernel driver kicks ARC firmware as part of hardware init:
  - `tt-kmd/blackhole.c`: `blackhole_init_hardware()` sends `ARC_MSG_TYPE_ASIC_STATE0` (0xA0). This is the most plausible “do early init” hook where translation tables get programmed.

Net: in the standard stack, you generally *don’t* program these tables from the host; you reset and let ARC do it.

## 3) Does tt-metal / UMD program these from the host?

In the open-source code under this workspace:

- No direct writes to `NOC_X_ID_TRANSLATE_TABLE_*`, `NOC_Y_ID_TRANSLATE_TABLE_*`, or `NOC_ID_LOGICAL` were found in:
  - `tt-metal/tt_metal/third_party/umd/device/`
  - `tt-umd/device/`
  - `tt-kmd/` (beyond sending ARC “state” messages)

Host-side code *does* build other coordinate-related tables (e.g. bank-to-NoC tables, worker logical-to-virtual tables) in L1 scratch for RISC-V firmware, but that is separate from the hardware ID translation tables.

## 4) Table format (Blackhole)

From `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h`:

- Each of X and Y tables has **32 entries**
- Each entry is **5 bits** (`NOC_TRANSLATE_ID_WIDTH = 5`)
- Entries are packed across **6 x 32-bit registers**:
  - reg 0 holds entries 0..5 (6 * 5 = 30 bits)
  - reg 1 holds entries 6..11
  - reg 2 holds entries 12..17
  - reg 3 holds entries 18..23
  - reg 4 holds entries 24..29
  - reg 5 holds entries 30..31 (2 * 5 = 10 bits; remaining bits unused/reserved)

Packing (expected; consistent with the comments’ grouping):

```text
reg_k bit [5*j + 4 : 5*j] = table_entry[k*6 + j]    (j = 0..5; reg5 only j=0..1)
```

`NOC_ID_LOGICAL` is a per-tile 12-bit packed coordinate:

```text
NOC_ID_LOGICAL = (logical_y << 6) | logical_x
```

## 5) “Simpler path”: can NOC1 work without translation tables?

If `NIU_CFG_0[14]` is **cleared**, hardware/firmware should treat coordinates as physical NoC coordinates (see `noc.c` choosing `noc_local_node_id()` when translation is disabled). In that mode:

- NOC1 should be usable with *physical* NOC1 coordinates (on Blackhole, NOC1 is the mirrored coordinate system; see `NOC0_X_TO_NOC1_X` / `NOC0_Y_TO_NOC1_Y` in `blackhole_implementation.hpp`).
- The X/Y translation tables and `NOC_ID_LOGICAL` should not be required for basic routing.

If NOC1 still hangs/returns zeros with translation disabled, likely causes include:

- Translation wasn’t actually disabled for the relevant tiles/NOC instance (setting a single BAR alias may not touch every tile).
- Your kernel path is using NOC1-specific runtime tables (e.g. DRAM bank→NoC endpoint tables) that weren’t seeded for NOC1. This shows up as “NoC reads return zeros” even if host DRAM reads/writes look fine; see `boop-docs/pure-py/dram-read-issue-interleavedaddrgenfast.md`.

## Host-side programming: what’s feasible?

Host-side programming is *theoretically* feasible because these are just per-tile MMIO registers, but “getting it right” requires reproducing ARC’s policy:

- Build X/Y translation tables that map your chosen translated coordinate space (0..31) onto physical NOC coordinates, consistent with harvesting for Tensix/DRAM/ETH.
- Program `NOC_ID_LOGICAL` for every tile to the translated coordinate by which that tile should be addressed.
- Program both NOC instances (NOC0 + NOC1) consistently; NOC1’s tables must map to **physical NOC1 coordinates**.
- Only then set `NIU_CFG_0[14]` to enable translation.

If you want to pursue host-side programming, the most realistic approach is:

1) Use UMD’s (already-implemented) coordinate policy as the “source of truth” for the translated↔physical mapping:
   - Blackhole mapping logic lives in `tt-umd/device/coordinates/blackhole_coordinate_manager.cpp`
2) Derive `x_table[0..31]` and `y_table[0..31]` from that mapping (the coordinate design intentionally uses disjoint translated X/Y ranges per core type, so a single X table + single Y table can represent the mapping).
3) Write the packed table registers (`NOC_X_ID_TRANSLATE_TABLE_*`, `NOC_Y_ID_TRANSLATE_TABLE_*`) into every tile for both NOCs, and write `NOC_ID_LOGICAL` per tile.

Today, the open-source tree does not provide the ARC init implementation, so you’ll be validating this experimentally (e.g., by reading back registers on a “known-good” boot and comparing).
