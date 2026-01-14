# Reading Harvesting Info from Hardware

Harvesting masks indicate which cores are disabled (fused off) on a chip. Each bit set means that core/column is harvested (unavailable).

## Overview

Blackhole stores harvesting info in a telemetry struct readable from the ARC core. No ARC message handshake is required - read the telemetry struct directly.

**ARC Core Location**: NOC0 `(8, 0)`

## Access Methods

1. **BAR0 Direct** (ARC over AXI only): `0x1FF00000 + offset`
2. **Via NOC** (TLB): Map window to ARC core `(8, 0)` at address `0x80000000 + offset`

If BAR0 reads return `0xffffffff`, ARC is not accessible over AXI and you must use the NoC/TLB path.

## Scratch RAM Addresses

These hold pointers to the telemetry data structures:

| Register | Offset | Contents |
|----------|--------|----------|
| SCRATCH_RAM_13 | `0x30434` | telemetry_struct_addr (in CSM) |

Telemetry struct address must be in CSM: `0x10000000..0x1007FFFF`.

## Reading Telemetry

```python
ARC_CORE = (8, 0)
ARC_NOC_BASE = 0x80000000

# 1. Read telemetry struct pointer from scratch RAM (via BAR0 or NOC to ARC)
telemetry_struct_addr = read_from_arc_apb(0x30434)  # SCRATCH_RAM_13
assert 0x10000000 <= telemetry_struct_addr <= 0x1007FFFF

# NOTE: If using a 2 MiB TLB window, rebase the window to the 2 MiB-aligned
# CSM base before reading the telemetry struct contents.

# 2. Read entry_count from telemetry struct (via NOC to ARC core)
# telemetry layout: [version:u32, entry_count:u32, tag_entries..., data_entries...]
entry_count = read_from_noc(ARC_CORE, telemetry_struct_addr + 4)

# 3. Build tag -> offset map from tag_entries
# Each entry is 4 bytes: lower 16 bits = tag, upper 16 bits = offset
tag_to_offset = {}
for i in range(entry_count):
    tag_offset = read_from_noc(ARC_CORE, telemetry_struct_addr + 8 + (i * 4))
    tag = tag_offset & 0xFFFF
    offset = tag_offset >> 16
    tag_to_offset[tag] = offset

# 4. Read a specific telemetry value
def read_telemetry(tag):
    offset = tag_to_offset[tag]
    data_base = telemetry_struct_addr + 8 + (entry_count * 4)
    return read_from_noc(ARC_CORE, data_base + (offset * 4))
```

## Telemetry Tags for Harvesting

| Tag | ID | Mask | Description |
|-----|-----|------|-------------|
| ENABLED_TENSIX_COL | 34 | `~value & 0x3FFF` | 14 tensix columns |
| ENABLED_ETH | 35 | `~value & 0x3FFF` | 14 ethernet cores |
| ENABLED_GDDR | 36 | `~value & 0xFF` | 8 DRAM banks |
| ENABLED_L2CPU | 37 | special | 4 L2CPU cores |
| PCIE_USAGE | 38 | special | 2 PCIe endpoints |

The telemetry values are "enabled" masks, so invert them to get "harvested" masks.

## Tensix Harvesting

### Physical to Logical Mapping

Blackhole harvests **columns** (not rows). The physical bit position maps to tensix column X coordinate:

```python
HARVESTING_NOC_LOCATIONS = [1, 16, 2, 15, 3, 14, 4, 13, 5, 12, 6, 11, 7, 10]
# Bit 0 -> column X=1
# Bit 1 -> column X=16
# Bit 2 -> column X=2
# ...
```

### Tensix Column X Coordinates

All 14 tensix columns in NOC0 coordinates:

```python
T6_X_LOCATIONS = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 16]
T6_Y_LOCATIONS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]  # 10 rows per column
```

### Mask Transformation

Raw harvesting bits are in physical layout order (alternating from edges inward). To convert to logical sorted order:

```python
HARVESTING_NOC_LOCATIONS = [1, 16, 2, 15, 3, 14, 4, 13, 5, 12, 6, 11, 7, 10]
SORTED_LOCATIONS = sorted(HARVESTING_NOC_LOCATIONS)  # [1,2,3,4,5,6,7,10,11,12,13,14,15,16]

def shuffle_tensix_harvesting_mask(raw_mask):
    """Convert physical layout mask to logical sorted mask."""
    new_mask = 0
    for pos, loc in enumerate(HARVESTING_NOC_LOCATIONS):
        if raw_mask & (1 << pos):
            sorted_pos = SORTED_LOCATIONS.index(loc)
            new_mask |= (1 << sorted_pos)
    return new_mask

# Example usage:
enabled_cols = read_telemetry(34)  # ENABLED_TENSIX_COL
raw_harvesting = ~enabled_cols & 0x3FFF
logical_harvesting = shuffle_tensix_harvesting_mask(raw_harvesting)
```

## DRAM Harvesting

8 DRAM banks, simple bitmask:

```python
enabled_gddr = read_telemetry(36)  # ENABLED_GDDR
dram_harvesting = ~enabled_gddr & 0xFF
# Bit N set = DRAM bank N is harvested
```

DRAM core NOC0 locations (8 banks, 3 subchannel ports each):

```python
DRAM_CORES_NOC0 = [
    [(0, 1), (0, 2), (0, 11)],    # Bank 0
    [(0, 5), (0, 6), (0, 7)],     # Bank 1
    [(9, 0), (9, 1), (9, 2)],     # Bank 2
    [(9, 5), (9, 6), (9, 8)],     # Bank 3
    [(9, 9), (9, 10), (9, 11)],   # Bank 4
    [(17, 0), (17, 1), (17, 2)],  # Bank 5
    [(17, 5), (17, 6), (17, 8)],  # Bank 6
    [(17, 9), (17, 10), (17, 11)] # Bank 7
]
```

## Ethernet Harvesting

14 ethernet cores:

```python
enabled_eth = read_telemetry(35)  # ENABLED_ETH
eth_harvesting = ~enabled_eth & 0x3FFF
```

ETH core NOC0 locations:

```python
ETH_CORES_NOC0 = [
    (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1),
    (10, 1), (11, 1), (12, 1), (13, 1), (14, 1), (15, 1), (16, 1)
]
```

## L2CPU Harvesting

4 L2CPU cores with special bit mapping:

```python
enabled_l2cpu = read_telemetry(37)  # ENABLED_L2CPU

def shuffle_l2cpu_harvesting_mask(enabled_physical):
    """Convert L2CPU enabled mask to harvesting mask."""
    mask = 0
    if ~enabled_physical & 0x1: mask |= 1 << 0  # core at (8, 3)
    if ~enabled_physical & 0x2: mask |= 1 << 3  # core at (8, 9)
    if ~enabled_physical & 0x4: mask |= 1 << 1  # core at (8, 5)
    if ~enabled_physical & 0x8: mask |= 1 << 2  # core at (8, 7)
    return mask

l2cpu_harvesting = shuffle_l2cpu_harvesting_mask(enabled_l2cpu)
```

L2CPU core NOC0 locations:

```python
L2CPU_CORES_NOC0 = [(8, 3), (8, 5), (8, 7), (8, 9)]
```

## Complete Example

```python
ARC_CORE = (8, 0)

def get_blackhole_harvesting():
    # Read telemetry struct pointer
    telem_struct = read_from_arc_apb(0x30434)
    if not (0x10000000 <= telem_struct <= 0x1007FFFF):
        raise RuntimeError("telemetry struct addr invalid")

    # Build tag map
    entry_count = read_from_noc(ARC_CORE, telem_struct + 4)
    tag_to_offset = {}
    for i in range(entry_count):
        entry = read_from_noc(ARC_CORE, telem_struct + 8 + (i * 4))
        tag_to_offset[entry & 0xFFFF] = entry >> 16

    def read_tag(tag_id):
        data_base = telem_struct + 8 + (entry_count * 4)
        return read_from_noc(ARC_CORE, data_base + (tag_to_offset[tag_id] * 4))

    # Read all harvesting masks
    tensix_enabled = read_tag(34) if 34 in tag_to_offset else 0x3FFF
    eth_enabled = read_tag(35) if 35 in tag_to_offset else 0x3FFF
    gddr_enabled = read_tag(36) if 36 in tag_to_offset else 0xFF
    l2cpu_enabled = read_tag(37) if 37 in tag_to_offset else 0xF

    return {
        'tensix': shuffle_tensix_harvesting_mask(~tensix_enabled & 0x3FFF),
        'eth': ~eth_enabled & 0x3FFF,
        'dram': ~gddr_enabled & 0xFF,
        'l2cpu': shuffle_l2cpu_harvesting_mask(l2cpu_enabled),
    }
```

## Key Constants Summary

| Constant | Value |
|----------|-------|
| ARC Core NOC0 | `(8, 0)` |
| ARC NOC Base Address | `0x80000000` |
| ARC BAR0 Base | `0x1FF00000` |
| SCRATCH_RAM_13 (telem struct ptr) | `0x30434` |
| CSM range | `0x10000000..0x1007FFFF` |
| Grid Size | 17 x 12 |
| Tensix Grid | 14 columns x 10 rows |

## Key Source Files

- `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp`
- `tt-umd/device/arc/blackhole_arc_telemetry_reader.cpp`
- `tt-umd/device/arc/arc_telemetry_reader.cpp`
- `tt-umd/device/coordinates/coordinate_manager.cpp`
- `tt-umd/device/tt_device/blackhole_tt_device.cpp:121-161`
