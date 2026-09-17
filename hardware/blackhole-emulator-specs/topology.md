# Emulator topology and coordinate translation

The chapters retain their recorded board and firmware assumptions. Current launchable workers and service reservations come from blackhole-py Device.cores, described in the hardware topology guide.

<a id="device-grid"></a>
## Blackhole Device Grid Topology — Emulator Specification
<a id="device-grid--blackhole-device-grid-topology--emulator-specification"></a>

This document describes the NOC grid layout for the Blackhole P100A and P150 boards as the emulator must model it. All coordinates are in the translated NOC coordinate space that firmware uses. The `hw.py` references below belong to a retired runtime. For current supported
board/core counts and service reservations, use [grid placement](../topology.md)
and `blackhole-py/pcie.py`; the 140-core P150 model below is not the current runtime contract.

---

<a id="device-grid--1-grid-overview"></a>
### 1. Grid Overview

Blackhole has a 2D NOC grid with several classes of tile. Not every grid position is a Tensix compute tile; some columns and rows are occupied by DRAM controllers, the PCIe endpoint, and ARC/router tiles, or are harvested.

| Tile class | Description |
|---|---|
| Tensix compute | Worker cores with 5 RISC-V processors, L1, and Tensix FPU |
| DRAM controller | DDR controller tiles; each physical bank has 3 NOC ports |
| PCIe endpoint | Single tile that bridges to host system memory |
| ARC / router | Management processor; defined in `TileGrid.ARC = (8, 0)` |

The full NOC grid is 32 columns × 32 rows in the physical address space, but most of that area is routing fabric. Only the tiles enumerated in this document are functional nodes the emulator must register.

---

<a id="device-grid--2-p100a-tensix-tile-coordinates"></a>
### 2. P100A Tensix Tile Coordinates

Source: `device.py` `P100 = BoardConfig(tensix_x=(*range(1, 8), *range(10, 15)), ...)`

<a id="device-grid--x-columns-tensix"></a>
#### X columns (Tensix)

P100A has two non-contiguous bands of Tensix columns:

| Band | X values |
|---|---|
| West band | 1, 2, 3, 4, 5, 6, 7 |
| East band | 10, 11, 12, 13, 14 |

Total: 12 Tensix columns.

Columns 0, 8, 9, 15–18 are not Tensix columns on P100A. Columns 17 and 18 are the DRAM controller columns (see section 4). Column 0 is the western NOC edge / router. Column 8 is ARC. Column 9 is a router / NOC bridge column.

<a id="device-grid--y-rows-tensix"></a>
#### Y rows (Tensix)

Source: `hw.py` `worker_cores()`:
```python
def worker_cores(tensix_x: tuple[int, ...]) -> list[Core]:
    return [(x, y) for x in tensix_x for y in range(2, 12)]
```

Y rows are **2 through 11**, inclusive (10 rows).

Rows 0 and 1 are edge/router rows not used for compute. Rows 12 and above are in the DRAM controller area.

<a id="device-grid--core-count"></a>
#### Core count

12 columns × 10 rows = **120 Tensix cores** on P100A (before any Tensix column harvesting).

<a id="device-grid--dispatch-cores"></a>
#### Dispatch cores

When fast-dispatch is enabled, two cores in the east band are reserved for the command queue (CQ) infrastructure and are not available for user kernels:

| Role | Coordinate (x, y) |
|---|---|
| Prefetch core | (14, 2) |
| Dispatch core | (14, 3) |

Both sit in the last east-band column (x=14). Cores (14, 4) through (14, 11) remain available for compute. The prefetch core reads the command ring buffer from host sysmem via PCIe; the dispatch core writes launch messages to worker tile L1.

User-visible worker count with fast-dispatch: 120 − 2 = **118 cores**.

---

<a id="device-grid--3-p150-tensix-tile-coordinates"></a>
### 3. P150 Tensix Tile Coordinates

Source: `device.py` `P150 = BoardConfig(tensix_x=(*range(1, 8), *range(10, 17)), ...)`

<a id="device-grid--x-columns-tensix-1"></a>
#### X columns (Tensix)

| Band | X values |
|---|---|
| West band | 1, 2, 3, 4, 5, 6, 7 |
| East band | 10, 11, 12, 13, 14, 15, 16 |

Total: 14 Tensix columns. The east band is two columns wider than P100A, extending to x=16.

<a id="device-grid--y-rows-tensix-1"></a>
#### Y rows (Tensix)

Same as P100A: rows **2 through 11** (10 rows).

<a id="device-grid--core-count-1"></a>
#### Core count

14 columns × 10 rows = **140 Tensix cores** on P150.

<a id="device-grid--dispatch-cores-1"></a>
#### Dispatch cores

| Role | Coordinate (x, y) |
|---|---|
| Prefetch core | (16, 2) |
| Dispatch core | (16, 3) |

Both sit at x=16 (the last east-band column on P150). User-visible worker count with fast-dispatch: 140 − 2 = **138 cores**.

---

<a id="device-grid--4-dram-bank-tile-coordinates"></a>
### 4. DRAM Bank Tile Coordinates

Source: `hw.py` `class Dram`

<a id="device-grid--physical-layout-constants"></a>
#### Physical layout constants

```python
BANK_COUNT   = 8           # physical banks total
TILES_PER_BANK = 3         # NOC port tiles per bank

BANK_X = {b: 0 if b < 4 else 9 for b in range(8)}
# Physical NOC column: banks 0-3 at x=0 (west), banks 4-7 at x=9 (east)
# Note: these are physical coordinates. build_bank_noc_table() assigns
# translated coordinates (x=17 west, x=18 east) to the active banks.

BANK_TILE_YS = {
    0: (0, 1, 11),
    1: (2, 3, 10),
    2: (4, 8, 9),
    3: (5, 6, 7),
    4: (0, 1, 11),
    5: (2, 3, 10),
    6: (4, 8, 9),
    7: (5, 6, 7),
}
# Three physical Y coordinates (the 3 NOC ports) for each physical bank.
# East and west banks share the same Y pattern.
```

<a id="device-grid--translated-coordinates-used-in-firmware"></a>
#### Translated coordinates used in firmware

`build_bank_noc_table()` assigns **translated** coordinates from the `x=17` (west) and `x=18` (east) columns, not the raw physical ones above. Each bank gets a base Y and occupies 3 consecutive Y values (the 3 ports). The 7-bank P100A layout always places 4 banks on x=17 and 3 on x=18:

| Software bank ID | Column | Base Y (y₀) | Port Y range |
|---|---|---|---|
| 0 | 17 | 12 | 12, 13, 14 |
| 1 | 17 | 15 | 15, 16, 17 |
| 2 | 17 | 18 | 18, 19, 20 |
| 3 | 17 | 21 | 21, 22, 23 |
| 4 | 18 | 12 | 12, 13, 14 |
| 5 | 18 | 15 | 15, 16, 17 |
| 6 | 18 | 18 | 18, 19, 20 |

The 8-bank P150 layout (no harvested bank) uses the same scheme but fills both x=17 and x=18 with 4 banks each:

| Software bank ID | Column | Base Y (y₀) | Port Y range |
|---|---|---|---|
| 0 | 17 | 12 | 12, 13, 14 |
| 1 | 17 | 15 | 15, 16, 17 |
| 2 | 17 | 18 | 18, 19, 20 |
| 3 | 17 | 21 | 21, 22, 23 |
| 4 | 18 | 12 | 12, 13, 14 |
| 5 | 18 | 15 | 15, 16, 17 |
| 6 | 18 | 18 | 18, 19, 20 |
| 7 | 18 | 21 | 21, 22, 23 |

<a id="device-grid--port-selection-per-noc-bank_port"></a>
#### Port selection per NOC (`BANK_PORT`)

Firmware does not use all 3 ports simultaneously. `build_bank_noc_table()` selects one port per bank per NOC using this table:

```python
BANK_PORT = [[2,1],[0,1],[0,1],[0,1],[2,1],[2,1],[2,1],[2,1]]
# Index:  bank 0  1    2    3    4    5    6    7
# [noc0_port_offset, noc1_port_offset]
# Port offset is added to the bank's base Y.
```

The actual NOC coordinate firmware targets for a given bank and NOC is `(x, y₀ + BANK_PORT[bank][noc])`.

For P100A 7-bank layout the active port coordinates are:

| SW bank | Base (x, y₀) | NOC 0 port | NOC 1 port |
|---|---|---|---|
| 0 | (17, 12) | (17, 14) — offset +2 | (17, 13) — offset +1 |
| 1 | (17, 15) | (17, 15) — offset +0 | (17, 16) — offset +1 |
| 2 | (17, 18) | (17, 18) — offset +0 | (17, 19) — offset +1 |
| 3 | (17, 21) | (17, 21) — offset +0 | (17, 22) — offset +1 |
| 4 | (18, 12) | (18, 14) — offset +2 | (18, 13) — offset +1 |
| 5 | (18, 15) | (18, 17) — offset +2 | (18, 16) — offset +1 |
| 6 | (18, 18) | (18, 20) — offset +2 | (18, 19) — offset +1 |

All 3 port tiles per bank alias the same physical DDR controller and the same backing memory in the emulator.

---

<a id="device-grid--5-pcie-endpoint"></a>
### 5. PCIe Endpoint

Source: `hw.py` `class Sysmem`

```python
PCIE_NOC_XY = (24 << 6) | 19  # = 0x613 = 1555 decimal
```

| Field | Value |
|---|---|
| X coordinate | 19 |
| Y coordinate | 24 |
| Packed uint16 `(y << 6) \| x` | `0x0613` (1555) |

The PCIe endpoint is a single NOC node. Transactions targeting it must also set **bit 60** of the 64-bit NOC address, which appears as **bit 28 of `NOC_TARG_ADDR_MID`** (value `0x10000000`). See `niu.md` §4 and `dram.md` §3 for the full PCIe transaction encoding.

---

<a id="device-grid--6-bank-to-noc-table"></a>
### 6. Bank-to-NOC Table

Before firmware boots, the emulator must write a bank-to-NOC lookup table to every worker tile's L1 at:

```
MEM_BANK_TO_NOC_SCRATCH = 0x0116B0    (from TensixL1 in hw.py)
```

Firmware's `noc_bank_table_init()` reads this table during the BRISC/NCRISC/TRISC init phase and copies it into core-private LDM (see `firmware-upload.md` §BRISC Init). The table must be present and correct before any RISC-V core exits reset.

<a id="device-grid--table-layout"></a>
#### Table layout

All fields are little-endian. The table is produced by `build_bank_noc_table()` in `hw.py`.

```
Offset from 0x0116B0    Size                    Contents
─────────────────────────────────────────────────────────────────────
+0x000                  NUM_NOCS × NUM_DRAM_BANKS × 2 bytes    dram_bank_to_noc_xy  (uint16[])
                        (continues)             NUM_NOCS × NUM_L1_BANKS × 2 bytes    l1_bank_to_noc_xy    (uint16[])
+0x400                  NUM_DRAM_BANKS × 4 bytes                bank_to_dram_offset  (uint32[])
                        (continues)             NUM_L1_BANKS × 4 bytes                bank_to_l1_offset    (uint32[])
```

Constants for P100A with 1 harvested bank:

| Constant | Value |
|---|---|
| `NUM_NOCS` | 2 |
| `NUM_DRAM_BANKS` | 7 (8 physical − 1 harvested) |
| `NUM_L1_BANKS` | number of active worker cores (120 for P100A, or 118 with fast-dispatch) |

For P150 (no harvested bank): `NUM_DRAM_BANKS = 8`.

<a id="device-grid--entry-encoding"></a>
#### Entry encoding

Each `uint16` NOC XY entry is packed as:

```
entry = (y << 6) | x
```

matching the `noc_xy()` helper in `hw.py`:
```python
def noc_xy(x: int, y: int) -> int:
    return ((y << 6) | x) & 0xFFFF
```

<a id="device-grid--dram_bank_to_noc_xy-layout"></a>
#### `dram_bank_to_noc_xy` layout

The DRAM section is laid out as `[noc][bank]` order:

```
NOC 0: bank 0 xy, bank 1 xy, ..., bank 6 xy   (7 × uint16 = 14 bytes)
NOC 1: bank 0 xy, bank 1 xy, ..., bank 6 xy   (7 × uint16 = 14 bytes)
```

Each entry is the translated port coordinate selected by `BANK_PORT[bank][noc]`.

<a id="device-grid--l1_bank_to_noc_xy-layout"></a>
#### `l1_bank_to_noc_xy` layout

The L1 section assigns one NOC coordinate per logical L1 bank. `build_bank_noc_table()` iterates worker cores in column-major order (all rows of column 0, then all rows of column 1, etc.):

```python
cols = sorted({x for x, _ in worker_cores})
for _ in range(NOCS):
    for i in range(num_l1_banks):
        l1.append(noc_xy(cols[i % len(cols)], 2 + (i // len(cols)) % 10))
```

Both NOC 0 and NOC 1 sections use identical coordinate values for L1.

<a id="device-grid--bank_to_dram_offset-and-bank_to_l1_offset"></a>
#### `bank_to_dram_offset` and `bank_to_l1_offset`

Both offset arrays are filled with zeros in the current implementation:

```python
struct.pack(f"<...{num_dram_banks + num_l1_banks}i", ..., *([0] * (num_dram_banks + num_l1_banks)))
```

The per-bank offset fields exist to allow non-zero base addresses within a bank's address space. In practice they are unused and the emulator can initialize them to zero.

---

<a id="device-grid--7-harvesting"></a>
### 7. Harvesting

<a id="device-grid--dram-bank-harvesting"></a>
#### DRAM bank harvesting

P100A chips have exactly **1 of 8 physical DRAM banks disabled** (harvested). The harvested bank varies per chip and is reported in the ARC telemetry tag `TAG_GDDR_ENABLED` (tag 36, an 8-bit mask where bit N = 0 means bank N is harvested). The default enabled mask is `0xFF` (all 8 banks enabled); a chip with bank 2 harvested would report `0xFB`.

`build_bank_noc_table()` handles this remap: it takes `harvested_dram_banks: list[int]` and ensures the 7 active banks occupy software IDs 0–6 contiguously. The harvested bank's "mirror" (the bank on the opposite column at the equivalent controller position) is pushed to the last slot of its column so that the 4+3 split is maintained.

From `hw.py`:
```python
if len(harvested_dram_banks) == 1:
    h = harvested_dram_banks[0]
    half = 4
    mirror = h + half - 1 if h < half else h - half
    if h < half:
        right = list(range(half - 1))
        left = [b for b in range(half - 1, Dram.BANK_COUNT - 1) if b != mirror] + [mirror]
    else:
        left = [b for b in range(half) if b != mirror] + [mirror]
        right = list(range(half, Dram.BANK_COUNT - 1))
```

The emulator must query the harvesting mask before constructing the bank table. In a software emulator without real hardware, default to bank 7 harvested (or any single bank, consistently) unless the spec under test requires a specific bank.

<a id="device-grid--tensix-column-harvesting"></a>
#### Tensix column harvesting

The ARC tag `TAG_TENSIX_ENABLED_COL` (tag 34) is a 14-bit mask of enabled Tensix columns. The default is `0x3FFF` (all 14 columns enabled). If a column is disabled, the corresponding X value should not appear in the `tensix_x` tuple and those 10 cores should not be registered.

Active Tensix core count from mask:
```python
def active_tensix_core_count(enabled_col_mask: int) -> int:
    return (enabled_col_mask & Arc.DEFAULT_TENSIX_ENABLED).bit_count() * 10
```

---

<a id="device-grid--8-emulator-setup"></a>
### 8. Emulator Setup

The emulator must perform the following steps before releasing any RISC-V core from reset.

<a id="device-grid--step-1--register-tensix-tiles"></a>
#### Step 1 — Register Tensix tiles

For each `(x, y)` in `worker_cores(tensix_x)`:
- Allocate 1.5 MB (`TensixL1.SIZE = 0x180000`) of L1 backing memory.
- Register the tile in the NOC routing table at coordinate `(x, y)`.
- Pre-populate both NIU instances (NOC 0 and NOC 1):
  - `NOC_ID_LOGICAL` at `NIU_base + 0x148` = `(y << 6) | x`
  - `NOC_NODE_ID` at `NIU_base + 0x44` = `(y << 6) | x`
  - All status counters initialized to 0.

The `NOC_ID_LOGICAL` register is what firmware reads in `noc_init()` to discover its own coordinates (see `niu.md` §5 and §9).

<a id="device-grid--step-2--register-dram-controller-nodes"></a>
#### Step 2 — Register DRAM controller nodes

For each active software bank (0 through `NUM_DRAM_BANKS − 1`):
- Allocate a single backing buffer (e.g. 64 MiB) for the bank.
- Register all 3 port coordinates `(x, y₀ + 0)`, `(x, y₀ + 1)`, `(x, y₀ + 2)` in the NOC routing table, all pointing to the same backing buffer.

Total NOC entries for DRAM: 7 banks × 3 ports = **21 NOC coordinates** on P100A, or 8 × 3 = **24** on P150.

Reads and writes to any port of a bank address into the same flat `bytearray`. There is no data striping across ports.

<a id="device-grid--step-3--register-pcie-endpoint"></a>
#### Step 3 — Register PCIe endpoint

Register NOC coordinate `(19, 24)` in the routing table as the PCIe endpoint node with a separate host-sysmem backing buffer.

When a NIU transaction targets `(19, 24)` with `NOC_TARG_ADDR_MID` bit 28 set (the PCIe flag), route it to this buffer at the address given by the low 36 bits.

<a id="device-grid--step-4--pre-populate-noc_id_logical"></a>
#### Step 4 — Pre-populate `NOC_ID_LOGICAL`

For every registered Tensix tile, write the packed coordinate `(y << 6) | x` into the `NOC_ID_LOGICAL` configuration register (at offset `0x148` from each NIU base). This is done for both NOC 0 (`NIU_base = 0xFFB20000`) and NOC 1 (`NIU_base = 0xFFB30000`).

On real hardware, ARC firmware programs this before releasing Tensix cores. In the emulator, it must be set before `SOFT_RESET_0` is cleared.

<a id="device-grid--step-5--write-bank-to-noc-tables-to-l1"></a>
#### Step 5 — Write bank-to-NOC tables to L1

For every registered Tensix tile (including the dispatch and prefetch cores), write the output of `build_bank_noc_table(harvested_dram_banks, all_worker_cores)` to that tile's L1 at offset `MEM_BANK_TO_NOC_SCRATCH = 0x0116B0`.

The same byte blob is written identically to every tile's L1 — the table content does not vary per tile.

```python
bank_table = build_bank_noc_table(harvested_dram_banks, all_worker_cores)
for tile in all_worker_cores:
    tile.l1[TensixL1.MEM_BANK_TO_NOC_SCRATCH :
            TensixL1.MEM_BANK_TO_NOC_SCRATCH + len(bank_table)] = bank_table
```

<a id="device-grid--step-6--write-boot-jal-and-go_message"></a>
#### Step 6 — Write boot JAL and go_message

As documented in `firmware-upload.md`:
- Write JAL instruction to L1 offset `0x000` (jump to `BRISC_FIRMWARE_BASE = 0x3840`).
- Write `go_msg.signal = RUN_MSG_INIT = 0x40` to L1 offset `0x373`.

---

<a id="device-grid--9-source-references"></a>
### 9. Source References

| File | Contents relevant to this spec |
|---|---|
| `blackhole-py/hw.py` | `Dram.BANK_COUNT`, `BANK_TILE_YS`, `BANK_X`, `build_bank_noc_table()`, `BANK_PORT`, `noc_xy()`, `Sysmem.PCIE_NOC_XY`, `TensixL1.MEM_BANK_TO_NOC_SCRATCH`, `TileGrid.ARC`, `worker_cores()` |
| `blackhole-py/device.py` | `P100` and `P150` `BoardConfig` (tensix_x, prefetch, dispatch), `_worker_cores()`, `harvested_dram_banks`, `build_bank_noc_table()` call site |
| `./niu.md` | `NOC_ID_LOGICAL` register offset, XY encoding, status counters, firmware boot sequence |
| `./dram.md` | DRAM bank interleaving, `InterleavedAddrGenFast`, PCIe address encoding, bank table population detail |
| `./firmware-upload.md` | Boot JAL, go_message initialization, `noc_bank_table_init()` call in BRISC/NCRISC init |
| `tt-metal/hw/inc/internal/firmware_common.h` | `noc_bank_table_init()` implementation |
| `tt-metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h` | `MEM_BANK_TO_NOC_SCRATCH`, table size constants, `NUM_DRAM_BANKS`, `NUM_L1_BANKS` |

<a id="logical-to-virtual-coordinates"></a>
## Logical-to-Virtual Coordinate Mapping
<a id="logical-to-virtual-coordinates--logical-to-virtual-coordinate-mapping"></a>

Blackhole firmware operates with three coordinate systems for Tensix worker tiles. This document specifies the runtime translation mechanism between them, including what the emulator must populate.

<a id="logical-to-virtual-coordinates--1-coordinate-systems"></a>
### 1. Coordinate Systems

| System | Description | Example (unharvested P150) |
|---|---|---|
| **Physical (NOC0)** | Hardware wire coordinates on the NOC0 mesh. Fixed by chip layout. | x=1..7, 10..16; y=2..11 |
| **Virtual (Translated)** | Post-NIU-translation coordinates. What firmware writes to `NOC_TARG_ADDR_HI`; the NIU hardware converts these to physical before routing. | Same as physical when translation is identity |
| **Logical** | Sequential, harvesting-agnostic index. Logical (0,0) is always the first active worker. Stable across harvesting configurations. | x=0..13; y=0..9 |

The translation chain:
```
Logical → Virtual (software table in LDM) → Physical (NIU hardware translate tables)
```

Firmware kernels receive logical coordinates from launch messages. The firmware converts them to virtual coordinates using per-core LDM lookup tables, then issues NOC transactions with virtual coordinates. The NIU hardware performs the final virtual-to-physical mapping transparently.


<a id="logical-to-virtual-coordinates--2-ldm-translation-arrays"></a>
### 2. LDM Translation Arrays

Each BRISC and NCRISC core holds two translation arrays in LDM, copied from L1 at boot:

```c
uint8_t worker_logical_col_to_virtual_col[round_up_to_mult_of_4(noc_size_x)];  // [20] for BH
uint8_t worker_logical_row_to_virtual_row[round_up_to_mult_of_4(noc_size_y)];  // [12] for BH
```

Where `noc_size_x = 17` and `noc_size_y = 12` for Blackhole.

<a id="logical-to-virtual-coordinates--ldm-offsets"></a>
#### LDM offsets

| Core | `col` array offset | `row` array offset |
|---|---|---|
| BRISC | `0x04E8` (20 bytes) | `0x04FC` (12 bytes) |
| NCRISC | `0x04E0` (20 bytes) | `0x04F4` (12 bytes) |

TRISC0/1/2 do not carry these arrays — they do not issue NOC transactions that require coordinate translation.

<a id="logical-to-virtual-coordinates--array-contents-unharvested-p150"></a>
#### Array contents (unharvested P150)

For an unharvested P150 (14 Tensix columns, 10 rows), the arrays map logical to virtual (= physical on NOC0 with identity translation):

```
worker_logical_col_to_virtual_col:
  [0]=1, [1]=2, [2]=3, [3]=4, [4]=5, [5]=6, [6]=7,   // west band
  [7]=10, [8]=11, [9]=12, [10]=13, [11]=14, [12]=15, [13]=16  // east band
  [14..19] = unused (zero-padded to 20 bytes)

worker_logical_row_to_virtual_row:
  [0]=2, [1]=3, [2]=4, [3]=5, [4]=6, [5]=7, [6]=8, [7]=9, [8]=10, [9]=11
  [10..11] = unused (zero-padded to 12 bytes)
```

When a Tensix column is harvested, the logical indices shift to skip it. For example, if physical column x=3 is harvested (P100A with 12 Tensix columns), the col array would be:

```
  [0]=1, [1]=2, [2]=4, [3]=5, [4]=6, [5]=7,   // west band, x=3 skipped
  [6]=10, [7]=11, [8]=12, [9]=13, [10]=14      // east band (P100A)
  [11..19] = unused
```

<a id="logical-to-virtual-coordinates--runtime-usage"></a>
#### Runtime usage

```c
// firmware_common.h
FORCE_INLINE coord_t get_virtual_coord_from_worker_logical_coord(
        uint8_t worker_x, uint8_t worker_y) {
    return {worker_logical_col_to_virtual_col[worker_x],
            worker_logical_row_to_virtual_row[worker_y]};
}
```

Firmware uses this to convert logical coordinates (from kernel launch messages) into virtual NOC coordinates for use in `NOC_TARG_ADDR_HI`/`NOC_RET_ADDR_HI`.


<a id="logical-to-virtual-coordinates--3-l1-scratch-region"></a>
### 3. L1 Scratch Region

The host writes the translation arrays to a scratch area in each tile's L1 before boot. Firmware copies them into LDM during init.

```c
// dev_mem_map.h
#define MEM_LOGICAL_TO_VIRTUAL_SCRATCH  (MEM_BANK_TO_NOC_SCRATCH + MEM_BANK_TO_NOC_SIZE)
#define MEM_LOGICAL_TO_VIRTUAL_SIZE     ((20 + 12) * sizeof(uint8_t))  // 32 bytes
```

Resolved address: `0x116B0 + 2048 = 0x11EB0`.

<a id="logical-to-virtual-coordinates--scratch-layout-at-l10x11eb0"></a>
#### Scratch layout at `L1[0x11EB0]`

```
Offset  Size   Contents
0x00    20 B   worker_logical_col_to_virtual_col[0..19]
0x14    12 B   worker_logical_row_to_virtual_row[0..11]
```


<a id="logical-to-virtual-coordinates--4-boot-initialization-noc_worker_logical_to_virtual_map_init"></a>
### 4. Boot Initialization: `noc_worker_logical_to_virtual_map_init()`

Called by both BRISC and NCRISC during their init phase (after `noc_bank_table_init()`, before `risc_init()`).

```c
// firmware_common.h
inline void noc_worker_logical_to_virtual_map_init(uint64_t worker_logical_to_virtual_map_addr) {
    // Copy col table from L1 scratch into LDM
    l1_to_local_mem_copy(
        (uint*)worker_logical_col_to_virtual_col,
        (uint tt_l1_ptr*)(worker_logical_to_virtual_map_addr),
        sizeof(worker_logical_col_to_virtual_col) >> 2);  // 20/4 = 5 words

    // Copy row table from L1 scratch into LDM (immediately after col table)
    l1_to_local_mem_copy(
        (uint*)worker_logical_row_to_virtual_row,
        (uint tt_l1_ptr*)(worker_logical_to_virtual_map_addr
                          + sizeof(worker_logical_col_to_virtual_col)),
        sizeof(worker_logical_row_to_virtual_row) >> 2);  // 12/4 = 3 words
}
```

`l1_to_local_mem_copy` copies in 32-bit word units, which is why the array sizes are rounded up to multiples of 4.


<a id="logical-to-virtual-coordinates--5-host-side-population"></a>
### 5. Host-Side Population

The host builds the mapping from the SoC descriptor and multicasts it to all worker tile L1:

```cpp
// risc_firmware_initializer.cpp

// Step 1: Build the mapping
for (size_t x = 0; x < tensix_grid_size.x; x++) {
    worker_logical_col_to_virtual_col.push_back(
        soc_desc.translate_coord_to(
            {tt_xy_pair{x, 0}, CoreType::TENSIX, CoordSystem::LOGICAL},
            CoordSystem::TRANSLATED).x);
}
for (size_t y = 0; y < tensix_grid_size.y; y++) {
    worker_logical_row_to_virtual_row.push_back(
        soc_desc.translate_coord_to(
            {tt_xy_pair{0, y}, CoreType::TENSIX, CoordSystem::LOGICAL},
            CoordSystem::TRANSLATED).y);
}

// Step 2: NOC multicast to all tiles at MEM_LOGICAL_TO_VIRTUAL_SCRATCH
cluster_.noc_multicast_write(worker_logical_col_to_virtual_col.data(), ...);
cluster_.noc_multicast_write(worker_logical_row_to_virtual_row.data(), ...);
```

The same byte blob is written identically to every tile's L1 — the table content does not vary per tile (it describes the grid-wide mapping, not a per-tile view).


<a id="logical-to-virtual-coordinates--6-per-core-logical-identity"></a>
### 6. Per-Core Logical Identity

Each core's own logical coordinates are stored in `core_info_msg_t`, part of the `mailboxes_t` structure in L1:

```c
struct core_info_msg_t {
    // ... (NOC addresses, non-worker coords, etc.)
    volatile uint8_t absolute_logical_x;  // this core's logical X
    volatile uint8_t absolute_logical_y;  // this core's logical Y
    // ...
};
```

Firmware reads these after init:
```c
my_logical_x_ = mailboxes->core_info.absolute_logical_x;
my_logical_y_ = mailboxes->core_info.absolute_logical_y;
```

These per-core values are written by the host into each tile's L1 mailbox before boot, and are distinct per tile (unlike the translation arrays which are uniform).


<a id="logical-to-virtual-coordinates--7-niu-hardware-translation-tables"></a>
### 7. NIU Hardware Translation Tables

Separate from the software logical-to-virtual mapping, the NIU hardware performs virtual-to-physical coordinate translation on every NOC transaction when `NIU_CFG_0[14]` (`NOC_ID_TRANSLATE_EN`) is set.

<a id="logical-to-virtual-coordinates--register-layout"></a>
#### Register layout

6 registers for X translation and 6 for Y, each holding up to 6 entries packed at 5 bits:

| Config index | Register | Entries |
|---|---|---|
| `0x06`–`0x0B` | `NOC_X_ID_TRANSLATE_TABLE_0..5` | X entries 0–31 |
| `0x0C`–`0x11` | `NOC_Y_ID_TRANSLATE_TABLE_0..5` | Y entries 0–31 |

Each 32-bit register holds 6 entries (6 x 5 = 30 bits):
```
bits [4:0]   = table_entry[reg*6 + 0]
bits [9:5]   = table_entry[reg*6 + 1]
bits [14:10] = table_entry[reg*6 + 2]
bits [19:15] = table_entry[reg*6 + 3]
bits [24:20] = table_entry[reg*6 + 4]
bits [29:25] = table_entry[reg*6 + 5]
```

The tables are indexed by **virtual (pre-translation)** coordinate and produce the **physical (post-translation)** coordinate. ARC firmware programs these during `ProgramNocTranslation()` before Tensix cores boot.

NOC1 translation tables are derived by mirroring NOC0: `noc1_x[i] = NOC_X_SIZE - noc0_x[i] - 1`.

<a id="logical-to-virtual-coordinates--additional-translation-registers"></a>
#### Additional translation registers

| Config index | Register | Purpose |
|---|---|---|
| `0x12` | `NOC_ID_LOGICAL` | This tile's logical coords: `(y << 6) \| x` |
| `0x14` | `NOC_ID_TRANSLATE_COL_MASK` | Which columns bypass translation |
| `0x15` | `NOC_ID_TRANSLATE_ROW_MASK` | Which rows bypass translation |

`NOC_ID_LOGICAL` is what firmware reads in `noc_init()` to discover "who am I." The emulator must pre-populate this (see `niu.md` §9).


<a id="logical-to-virtual-coordinates--8-emulator-setup-requirements"></a>
### 8. Emulator Setup Requirements

Before releasing any RISC-V core from reset, the emulator must:

<a id="logical-to-virtual-coordinates--step-1--write-translation-arrays-to-l1"></a>
#### Step 1 — Write translation arrays to L1

For every worker tile, write the logical-to-virtual mapping at `L1[0x11EB0]`:

```python
# Build col table: logical index → virtual NOC X
col_table = []
for logical_x in range(len(tensix_columns)):
    col_table.append(tensix_columns[logical_x])  # e.g., [1,2,3,4,5,6,7,10,11,12,13,14,15,16]
col_table += [0] * (20 - len(col_table))  # pad to 20 bytes

# Build row table: logical index → virtual NOC Y
row_table = []
for logical_y in range(10):  # 10 Tensix rows
    row_table.append(2 + logical_y)  # Y=2..11
row_table += [0] * (12 - len(row_table))  # pad to 12 bytes

# Write to every tile's L1
for tile in all_worker_tiles:
    tile.l1[0x11EB0 : 0x11EB0 + 20] = bytes(col_table)
    tile.l1[0x11EC4 : 0x11EC4 + 12] = bytes(row_table)
```

<a id="logical-to-virtual-coordinates--step-2--write-per-core-logical-identity"></a>
#### Step 2 — Write per-core logical identity

For every worker tile at grid position `(virtual_x, virtual_y)`, compute its logical coordinates and write them to `core_info_msg_t.absolute_logical_x/y` in that tile's L1 mailbox.

```python
for logical_x, virtual_x in enumerate(tensix_columns):
    for logical_y in range(10):
        virtual_y = 2 + logical_y
        tile = tiles[(virtual_x, virtual_y)]
        core_info_offset = ...  # offset of core_info_msg_t within mailboxes_t
        tile.l1[core_info_offset + offsetof_absolute_logical_x] = logical_x
        tile.l1[core_info_offset + offsetof_absolute_logical_y] = logical_y
```

<a id="logical-to-virtual-coordinates--step-3--pre-populate-noc_id_logical"></a>
#### Step 3 — Pre-populate `NOC_ID_LOGICAL`

Already documented in `niu.md` §9 and `device-grid.md` §8 step 4. Write `(y << 6) | x` to both NIU instances for each tile.

<a id="logical-to-virtual-coordinates--niu-translate-tables"></a>
#### NIU translate tables

For a basic emulator that does not model the NIU hardware translation layer (virtual == physical), the `NOC_X/Y_ID_TRANSLATE_TABLE` registers can be left as identity mappings or zeros. The emulator routes NOC transactions based on the virtual coordinates directly, bypassing the hardware translation step. If the emulator does model translation, program the same tables that ARC would program (see `tt-zephyr-platforms/lib/tenstorrent/bh_arc/noc_init.c`).


<a id="logical-to-virtual-coordinates--9-source-references"></a>
### 9. Source References

| File | Content |
|---|---|
| `tt-metal/tt_metal/hw/inc/internal/firmware_common.h` | `noc_worker_logical_to_virtual_map_init()`, `get_virtual_coord_from_worker_logical_coord()` |
| `tt-metal/tt_metal/hw/firmware/src/tt-1xx/brisc.cc` | Call site in BRISC `main()` |
| `tt-metal/tt_metal/hw/firmware/src/tt-1xx/ncrisc.cc` | Call site in NCRISC `main()` |
| `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h` | `MEM_LOGICAL_TO_VIRTUAL_SCRATCH`, `MEM_LOGICAL_TO_VIRTUAL_SIZE` |
| `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/core_config.h` | `noc_size_x = 17`, `noc_size_y = 12` |
| `tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h` | `core_info_msg_t` with `absolute_logical_x/y` |
| `tt-metal/tt_metal/impl/device/firmware/risc_firmware_initializer.cpp` | Host-side mapping generation and L1 upload |
| `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h` | NIU translate table register defines |
| `tt-zephyr-platforms/lib/tenstorrent/bh_arc/noc_init.c` | ARC firmware: NIU translation table computation and programming |
| `./ldm-layouts.md` | LDM offsets for col/row arrays |
| `./niu.md` | `NOC_ID_LOGICAL` register, NIU config register map |
| `./device-grid.md` | Grid topology, coordinate assignments |
