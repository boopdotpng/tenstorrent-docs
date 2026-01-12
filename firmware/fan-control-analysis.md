# Tenstorrent Firmware Fan Control Analysis

Analysis of Tenstorrent P100A-1 firmware structure for fan speed/curve modification.

## Firmware Structure

The firmware bundle (`.fwbundle` files) contains multiple components stored in a boot filesystem format. When disassembled into `image.bin`, it becomes an ASCII hex format with memory-mapped sections.

### Format
- Lines starting with `@<address>` indicate memory addresses
- Followed by hex-encoded binary data
- The data contains various firmware modules and configurations

### Main Components

From the boot filesystem table at address 0x0:

| Tag | SPI Address | Size (bytes) | Description |
|-----|-------------|--------------|-------------|
| cmfw | 0x14000 | 38,968 | CM (Control/Management) firmware |
| safeimg | 0x34000 | 112,932 | Safe boot image |
| safetail | 0xb3000 | 4,096 | Safe boot tail |
| **boardcfg** | **0xd4000** | **16** | **Board-specific config (fan control?)** |
| origcfg | 0xd5000 | 96 | Original/factory configuration |
| bmfw | 0xd6000 | 45,660 | BM (Board Management) firmware |
| blupdate | 0xe7000 | 40,716 | Bootloader update |
| cmfwcfg | 0x1f7000 | 96 | CM firmware configuration |
| ethfwcfg | 0x1f8000 | 512 | Ethernet firmware config |
| memfwcfg | 0x1f9000 | 256 | Memory firmware config |
| ethsdreg | 0x1fa000 | 1,152 | Ethernet SD registers |
| flshinfo | 0x1fb000 | 4 | Flash info |
| ethfw | 0x1fc000 | 42,628 | Ethernet firmware |
| memfw | 0x20c000 | 13,364 | Memory firmware |
| ethsdfw | 0x21c000 | 19,516 | Ethernet SD firmware |
| dmfw | 0x22d000 | 4,096 | DM (Device Management) firmware |
| dmfwimg | 0x22e000 | 65,296 | DM firmware image |
| dmfwtail | 0x29d000 | 4,096 | DM firmware tail |
| mainimg | 0x29e000 | 141,064 | Main boot image |
| maintail | 0x31d000 | 4,096 | Main boot tail |

## boardcfg - Fan Control Configuration

The `boardcfg` section is only 16 bytes and contains board-specific configuration values.

### P100A-1 boardcfg Data
```
Hex: 08 80 80 80 80 90 86 01 12 00 1a 00 20 d2 3c 00
```

### Byte Analysis
```
Byte  0:   8 (0x08)   - Format/version marker
Byte  1: 128 (0x80)   - PWM value (50% duty cycle)
Byte  2: 128 (0x80)   - PWM value (50% duty cycle)
Byte  3: 128 (0x80)   - PWM value (50% duty cycle)
Byte  4: 128 (0x80)   - PWM value (50% duty cycle)
Byte  5: 144 (0x90)   - PWM value (56% duty cycle)
Byte  6: 134 (0x86)   - PWM value (52% duty cycle)
Byte  7:   1 (0x01)   - Additional config
Byte  8:  18 (0x12)   - Additional config
Byte  9:   0 (0x00)   - Additional config
Byte 10:  26 (0x1a)   - Additional config
Byte 11:   0 (0x00)   - Additional config
Byte 12:  32 (0x20)   - Additional config
Byte 13: 210 (0xd2)   - Additional config
Byte 14:  60 (0x3c)   - Additional config
Byte 15:   0 (0x00)   - Additional config
```

### Interpretation
Bytes 1-6 appear to be **PWM values** (0-255 range) representing fan speeds at different temperature points:
- PWM values: [128, 128, 128, 128, 144, 134]
- As percentages: [50%, 50%, 50%, 50%, 56%, 52%]

This suggests a fan curve with 6 points, likely corresponding to different temperature thresholds.

## Special Handling

The `mask.json` file contains:
```json
[{"tag": "write-boardcfg"}]
```

This triggers special handling in `tt-flash/tt_flash/blackhole.py:writeback_boardcfg()`:
- The function **preserves** the existing boardcfg from the chip when flashing new firmware
- This prevents overwriting board-specific tuning during firmware updates
- Indicates that boardcfg contains hardware-specific calibration/tuning data

## Modification Strategies

### Option A: Direct boardcfg Modification
1. Extract firmware: disassemble `.fwbundle` to `image.bin`
2. Modify bytes 1-6 in boardcfg section at SPI address 0xd4000
3. Modify or remove `mask.json` to allow writing custom boardcfg
4. Reassemble and flash modified firmware bundle

**Risk**: May conflict with hardware-specific tuning for your specific board

### Option B: Runtime Modification via SMC
- Use System Management Controller (SMC) firmware message interface
- Send MSG_TYPE commands to running firmware (seen in `chip.py`)
- Would require finding/creating a tool to send fan control messages

**Status**: Message types for fan control not yet identified

### Option C: Full origcfg Analysis
- The `origcfg` (96 bytes) is larger and may contain complete fan curve table
- Appears to use protobuf encoding
- May provide more granular fan curve control

## Tools & Repositories

- **tt-flash**: Firmware flashing utility - [github.com/tenstorrent/tt-flash](https://github.com/tenstorrent/tt-flash)
- **tt-firmware**: Firmware bundles - [github.com/tenstorrent/tt-firmware](https://github.com/tenstorrent/tt-firmware)
- **tt-zephyr-platforms**: Zephyr firmware source (SMC firmware) - [github.com/tenstorrent/tt-zephyr-platforms](https://github.com/tenstorrent/tt-zephyr-platforms)

## Current Status

As of firmware v19.4.2:
- End-user fan controls are **not officially supported**
- Tenstorrent is evaluating adding this feature in future updates
- SMC firmware manages thermal envelope and power management
- Fan control is handled automatically by firmware based on temperature

## References

- Tenstorrent docs: [docs.tenstorrent.com/aibs/blackhole/](https://docs.tenstorrent.com/aibs/blackhole/)
- Boot filesystem structure: `tt-flash/tt_flash/boot_fs.py`
- Blackhole-specific handling: `tt-flash/tt_flash/blackhole.py`
