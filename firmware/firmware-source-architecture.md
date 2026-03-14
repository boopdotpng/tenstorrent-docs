# Firmware architecture (source-confirmed)

Confirmed against `tt-zephyr-platforms` source. Supersedes the reverse-engineering guesses in `firmware.md`.

## Firmware components

The firmware bundle (`.fwbundle`) is a tar.gz containing per-board directories. Each board has an `image.bin` (base16 hex ASCII with `@addr` markers) and a `mask.json` (`[{"tag": "write-boardcfg"}]`) that tells tt-flash what to preserve.

### Binaries

| Component | Type | Flash offset | Description |
|---|---|---|---|
| cmfw | ARC (MCUBoot + Zephyr) | 0x14000 (128K) | Bootloader, validates/loads mainimg or safeimg |
| failover | ARC (MCUBoot copy) | 0xb4000 (128K) | Backup bootloader |
| safeimg | ARC app (MCUBoot container) | 0x34000 (512K) | Recovery SMC firmware |
| safetail | MCUBoot trailer | 0xb3000 (4K) | Magic marker + image_ok for safeimg |
| mainimg | ARC app (MCUBoot container) | 0x29e000 (512K) | Primary SMC firmware |
| maintail | MCUBoot trailer | 0x31d000 (4K) | Magic marker + image_ok for mainimg |
| bmfw | Cortex-M (signed) | 0xd6000 (68K) | DMC ROM update binary |
| blupdate | Cortex-M (MCUBoot) | 0xe7000 (64K) | DMC bootloader update |
| dmfwimg | Cortex-M (STM32G0, signed) | 0x22e000 (448K) | DMC application firmware |
| dmfwtail | MCUBoot trailer | 0x29d000 (4K) | DMC image trailer |
| dmfw | Padding | 0x22d000 (452K) | MCUBoot swap slot (includes dmfwimg) |
| ethfw | RISC-V (erisc) | 0x1fc000 (64K) | Ethernet tile firmware |
| memfw | RISC-V (gddr_init) | 0x20c000 (64K) | GDDR init firmware |
| ethsdfw | RISC-V (serdes) | 0x21c000 (64K) | SerDes ethernet firmware |

### Config / metadata (protobuf)

| Component | Flash offset | Format | Contents |
|---|---|---|---|
| boardcfg | 0xd4000 (4K) | protobuf (ReadOnlyTable) | Board ID, ASIC location, vendor info |
| origcfg | 0xd5000 (4K) | protobuf (FwTable) | Chip limits, features, fan table, harvesting |
| cmfwcfg | 0x1f7000 (4K) | protobuf (FwTable) | Same as origcfg, field-updatable copy |
| flshinfo | 0x1fb000 (4K) | protobuf (FlashInfoTable) | Reprogram count, date, tt-flash version |

### Config / metadata (raw binary)

| Component | Flash offset | Format | Contents |
|---|---|---|---|
| ethfwcfg | 0x1f8000 (4K) | Raw u32 LE array | Ethernet parameters (erisc_params.bin) |
| memfwcfg | 0x1f9000 (4K) | Raw u32 LE array | GDDR parameters (per-product) |
| ethsdreg | 0x1fa000 (4K) | (addr, val) u32 pairs | SerDes register init script |
| pci0_property_table | inside FwTable | protobuf field | BAR sizes, PCIe speed/mode |

### Storage

| Component | Flash offset | Size |
|---|---|---|
| bootrom_data | 0x0 (80K) | tt-boot-fs descriptor table |
| storage | 0x500000 (59M) | Free storage |
| Total SPI | | 64 MiB |

## Boot sequence

Two processors boot in parallel:

### ARC (Blackhole ASIC) - SMC path

```
1. Blackhole ROM reads tt-boot-fs descriptor table at SPI 0x0
2. ROM loads cmfw (MCUBoot) from 0x14000 → ARC SRAM 0x10000000, jumps
3. MCUBoot (RAM-load mode) validates mainimg @ 0x29e000
   - If valid: copies to CSM RAM 0x10010000 (444K)
   - If invalid: falls back to safeimg @ 0x34000
4. MCUBoot jumps to loaded image

5. CMFW init (app/smc/src/main.c):
   - SYS_INIT: write FW version, record boot timestamp, set HW_INIT_STARTED
   - Load FwTable protobuf from SPI (origcfg partition)
   - If fan_ctrl_en: init_fan_ctrl() (quadratic curve, 1s timer)
   - If aiclk_ppm_en: InitDVFS()
   - init_msgqueue() (CM2DM and SMC message handling)
   - init_telemetry() + StartTelemetryTimer() (1s)
   - Send kCm2DmMsgIdReady to DMC
   - boot_write_img_confirmed() (mark MCUBoot image safe)
   - Set HW_INIT_DONE

6. Main loop: feed watchdog every 100ms
```

### STM32G0 - DMC path (parallel)

```
1. STM32 ROM → MCUBoot (dual-image swap-using-offset)
   - Primary: internal flash 0x10000 (448K)
   - Secondary (update): SPI 0x22d000 (452K)
   - If new image in secondary: swap to primary
2. MCUBoot jumps to DMFW

3. DMFW init (app/dmc/src/main.c):
   - Run BIST
   - JTAG bootrom workaround
   - I2C/SMBus setup (for ARC communication)
   - GPIO IRQ setup (thermal trip, power good)
   - Detect max PSU power from GPIO straps
   - Start timers: 20ms CM2DM polling, 1ms power update

4. Wait for kCm2DmMsgIdReady from SMC
5. Send init data back to SMC
6. Main loop: poll CM2DM, update PWM, monitor thermals
```

### After both are up

```
ARC loads tile firmware:
  - ethfw → ethernet RISC-V tiles
  - memfw → GDDR init RISC-V tiles
  - ethsdfw → SerDes init
  - Config applied from ethfwcfg, memfwcfg, ethsdreg
```

## FwTable protobuf (the main config)

Source: `drivers/misc/bh_fwtable/spirom_protobufs/fw_table.proto`

```protobuf
message FwTable {
  uint32 fw_bundle_version = 1;
  ChipLimits chip_limits = 2;           // TDP, freq, voltage limits
  FeatureEnable feature_enable = 3;     // fan_ctrl_en, aiclk_ppm_en, watchdog, etc.
  FanTable fan_table = 4;               // UNUSED - all zeros, curve is hardcoded
  DramTable dram_table = 5;
  ChipHarvestingTable chip_harvesting = 6;
  PciPropertyTable pci0_property_table = 7;  // BAR sizes, PCIe speed/mode
  PciPropertyTable pci1_property_table = 8;
  EthPropertyTable eth_property_table = 9;
  ProductSpecHarvesting product_spec = 10;
}
```

Per-board configs live in `boards/tenstorrent/tt_blackhole/spirom_data_tables/<BOARD>/fw_table.txt`.

## Fan control path

### Architecture

SMC (ARC) calculates target speed → sends CM2DM message → DMC (STM32) writes PWM to MAX6639.

### Fan curve (hardcoded in `lib/tenstorrent/bh_arc/fan_ctrl.c`)

```
ASIC temp:  <49C → 35%    49-90C → 0.03867*(T-49)^2 + 35%    >90C → 100%
GDDR temp:  <43C → 35%    43-82C → 0.04274*(T-43)^2 + 35%    >82C → 100%
Final = max(asic_curve, gddr_curve)
```

The `FanTable` protobuf fields (`fan_table_point_x1/x2/y1/y2`) exist but are **unused** -- all boards set them to 0. Modifying them in the bundle won't change fan behavior (and may corrupt protobuf decoding).

### Data flow

```
Telemetry (ASIC + GDDR temps, 1s interval)
  → Exponential moving avg filter (alpha ~33%)
  → fan_curve() (hardcoded quadratic)
  → UpdateFanSpeedRequest(speed_pct)
  → CM2DM message queue
  → DMC process_cm2dm_message()
  → update_fan_speed(): pwm_set_cycles(max6639, 0, 255, speed*255/100, 0)
  → I2C write to MAX6639 reg 0x26 (ch1) or 0x27 (ch2)
  → Physical fan
```

### Host override

SMC message `TT_SMC_MSG_FORCE_FAN_SPEED` (0xAC) accepts 0-100% or UINT32_MAX to return to auto. Goes through the same CM2DM → DMC → PWM path.

### MAX6639 hardware (I2C @ 0x2C)

| Register | Purpose |
|---|---|
| 0x00, 0x01 | Channel 1/2 temperature |
| 0x05, 0x06 | Extended precision temperature |
| 0x20, 0x21 | Channel 1/2 tachometer (RPM) |
| 0x26, 0x27 | Channel 1/2 PWM duty cycle |

Zephyr drivers: `drivers/mfd/mfd_max6639.c`, `drivers/pwm/pwm_max6639.c`, `drivers/sensor/maxim/max6639/max6639.c`.

### Thermal trip (emergency)

If `therm_trip_l1_limit` exceeded: force 100% fan, set fault LED, trigger ASIC reset.

## CM2DM message protocol

SMC → DMC via SMBUS:

| Message | ID | Data |
|---|---|---|
| kCm2DmMsgIdReady | - | Signals DMC that SMC initialized |
| kCm2DmMsgIdFanSpeedUpdate | 3 | Fan speed 0-100% (automatic) |
| kCm2DmMsgIdForcedFanSpeedUpdate | 7 | Fan speed 0-100% (forced) |
| kCm2DmMsgIdResetReq | - | ASIC or system reset |
| kCm2DmMsgTelemHeartbeatUpdate | - | Watchdog heartbeat |
| kCm2DmMsgIdLedBlink | - | LED on/off |
| kCm2DmMsgIdAutoResetTimeoutUpdate | - | Auto-reset watchdog timeout |

DMC → SMC: fan RPM feedback (20ms), power updates (1ms), thermal trip alerts, logs.

## Key source files

| File | Purpose |
|---|---|
| `app/smc/src/main.c` | SMC init and main loop |
| `app/dmc/src/main.c` | DMC init, fan PWM, CM2DM handler |
| `lib/tenstorrent/bh_arc/fan_ctrl.c` | Fan curve + thermal monitoring |
| `lib/tenstorrent/bh_arc/cm2dm_msg.c` | CM2DM message posting |
| `lib/tenstorrent/bh_arc/telemetry.c` | ASIC/GDDR temperature collection |
| `lib/tenstorrent/bh_arc/pcie.c` | PCIe init, BAR config, TLBs, iATU |
| `lib/tenstorrent/bh_arc/noc_init.c` | NOC initialization + translation |
| `drivers/misc/bh_fwtable/bh_fwtable.c` | FwTable protobuf loading from SPI |
| `boards/.../tt_blackhole_fixed_partitions.dtsi` | SPI flash partition layout |
| `boards/.../spirom_data_tables/*/fw_table.txt` | Per-board protobuf config |
