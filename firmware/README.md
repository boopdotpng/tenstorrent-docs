# Board firmware: architecture and build

This guide covers ARC/SMC and DMC board-management firmware, boot images, configuration, and fwbundles. It does not describe worker kernel compilation. See the current blackhole-py runtime and TT-Metal build guide for worker firmware. Commands and versions below belong to the recorded environment.

<a id="firmware-source-architecture"></a>
## Firmware architecture (source-confirmed)
<a id="firmware-source-architecture--firmware-architecture-source-confirmed"></a>

> Scope: TT-Metal/LLK source reference. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](../build-and-dispatch/blackhole-py-runtime.md) for its separate implementation.

Confirmed against `tt-zephyr-platforms` source. Supersedes the reverse-engineering guesses in `firmware.md`.

<a id="firmware-source-architecture--firmware-components"></a>
### Firmware components

The firmware bundle (`.fwbundle`) is a tar.gz containing per-board directories. Each board has an `image.bin` (base16 hex ASCII with `@addr` markers) and a `mask.json` (`[{"tag": "write-boardcfg"}]`) that tells tt-flash what to preserve.

<a id="firmware-source-architecture--binaries"></a>
#### Binaries

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

<a id="firmware-source-architecture--config--metadata-protobuf"></a>
#### Config / metadata (protobuf)

| Component | Flash offset | Format | Contents |
|---|---|---|---|
| boardcfg | 0xd4000 (4K) | protobuf (ReadOnlyTable) | Board ID, ASIC location, vendor info |
| origcfg | 0xd5000 (4K) | protobuf (FwTable) | Chip limits, features, fan table, harvesting |
| cmfwcfg | 0x1f7000 (4K) | protobuf (FwTable) | Same as origcfg, field-updatable copy |
| flshinfo | 0x1fb000 (4K) | protobuf (FlashInfoTable) | Reprogram count, date, tt-flash version |

<a id="firmware-source-architecture--config--metadata-raw-binary"></a>
#### Config / metadata (raw binary)

| Component | Flash offset | Format | Contents |
|---|---|---|---|
| ethfwcfg | 0x1f8000 (4K) | Raw u32 LE array | Ethernet parameters (erisc_params.bin) |
| memfwcfg | 0x1f9000 (4K) | Raw u32 LE array | GDDR parameters (per-product) |
| ethsdreg | 0x1fa000 (4K) | (addr, val) u32 pairs | SerDes register init script |
| pci0_property_table | inside FwTable | protobuf field | BAR sizes, PCIe speed/mode |

<a id="firmware-source-architecture--storage"></a>
#### Storage

| Component | Flash offset | Size |
|---|---|---|
| bootrom_data | 0x0 (80K) | tt-boot-fs descriptor table |
| storage | 0x500000 (59M) | Free storage |
| Total SPI | | 64 MiB |

<a id="firmware-source-architecture--boot-sequence"></a>
### Boot sequence

Two processors boot in parallel:

<a id="firmware-source-architecture--arc-blackhole-asic---smc-path"></a>
#### ARC (Blackhole ASIC) - SMC path

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

<a id="firmware-source-architecture--stm32g0---dmc-path-parallel"></a>
#### STM32G0 - DMC path (parallel)

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

<a id="firmware-source-architecture--after-both-are-up"></a>
#### After both are up

```
ARC loads tile firmware:
  - ethfw → ethernet RISC-V tiles
  - memfw → GDDR init RISC-V tiles
  - ethsdfw → SerDes init
  - Config applied from ethfwcfg, memfwcfg, ethsdreg
```

<a id="firmware-source-architecture--fwtable-protobuf-the-main-config"></a>
### FwTable protobuf (the main config)

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

<a id="firmware-source-architecture--fan-control-path"></a>
### Fan control path

<a id="firmware-source-architecture--architecture"></a>
#### Architecture

SMC (ARC) calculates target speed → sends CM2DM message → DMC (STM32) writes PWM to MAX6639.

<a id="firmware-source-architecture--fan-curve-hardcoded-in-libtenstorrentbh_arcfan_ctrlc"></a>
#### Fan curve (hardcoded in `lib/tenstorrent/bh_arc/fan_ctrl.c`)

```
ASIC temp:  <49C → 35%    49-90C → 0.03867*(T-49)^2 + 35%    >90C → 100%
GDDR temp:  <43C → 35%    43-82C → 0.04274*(T-43)^2 + 35%    >82C → 100%
Final = max(asic_curve, gddr_curve)
```

The `FanTable` protobuf fields (`fan_table_point_x1/x2/y1/y2`) exist but are **unused** -- all boards set them to 0. Modifying them in the bundle won't change fan behavior (and may corrupt protobuf decoding).

<a id="firmware-source-architecture--data-flow"></a>
#### Data flow

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

<a id="firmware-source-architecture--host-override"></a>
#### Host override

SMC message `TT_SMC_MSG_FORCE_FAN_SPEED` (0xAC) accepts 0-100% or UINT32_MAX to return to auto. Goes through the same CM2DM → DMC → PWM path.

<a id="firmware-source-architecture--max6639-hardware-i2c--0x2c"></a>
#### MAX6639 hardware (I2C @ 0x2C)

| Register | Purpose |
|---|---|
| 0x00, 0x01 | Channel 1/2 temperature |
| 0x05, 0x06 | Extended precision temperature |
| 0x20, 0x21 | Channel 1/2 tachometer (RPM) |
| 0x26, 0x27 | Channel 1/2 PWM duty cycle |

Zephyr drivers: `drivers/mfd/mfd_max6639.c`, `drivers/pwm/pwm_max6639.c`, `drivers/sensor/maxim/max6639/max6639.c`.

<a id="firmware-source-architecture--thermal-trip-emergency"></a>
#### Thermal trip (emergency)

If `therm_trip_l1_limit` exceeded: force 100% fan, set fault LED, trigger ASIC reset.

<a id="firmware-source-architecture--cm2dm-message-protocol"></a>
### CM2DM message protocol

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

<a id="firmware-source-architecture--key-source-files"></a>
### Key source files

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

<a id="firmware-build-system"></a>
## Building firmware and creating custom fwbundles
<a id="firmware-build-system--building-firmware-and-creating-custom-fwbundles"></a>

> Scope: Board-management firmware build snapshot. APIs and layouts belong to that software stack;
> see the [current blackhole-py runtime](../build-and-dispatch/blackhole-py-runtime.md) for its separate implementation.

<a id="firmware-build-system--overview"></a>
### Overview

`tt-zephyr-platforms` uses Zephyr's **sysbuild** system. One `west build` command builds all components (MCUBoot, SMC, DMC, recovery) and assembles the final `.fwbundle`.

```
west build --sysbuild -b <BOARD> app/smc
    ├── mcuboot        (ARC bootloader)
    ├── smc            (ARC app = mainimg)
    ├── recovery       (ARC app = safeimg)
    ├── dmc            (STM32 firmware = dmfwimg)
    ├── dmc-rom-update (= bmfw)
    ├── mcuboot-bl2    (= blupdate)
    ├── MCUBoot trailers (maintail, safetail, dmfwtail)
    ├── protobuf configs (fw_table.bin, read_only.bin, flash_info.bin)
    ├── tt_boot_fs.py generate_bootfs → tt_boot_fs.yaml
    ├── tt_boot_fs.py mkfs → tt_boot_fs.hex (full SPI image)
    └── tt_fwbundle.py create → update.fwbundle
```

<a id="firmware-build-system--local-dev-environment"></a>
### Local dev environment

Installed 2025-02-07 at `~/tenstorrent`.

| Component | Location | Notes |
|---|---|---|
| West workspace | `~/tenstorrent/.west/` | Manifest repo is `tt-zephyr-platforms` |
| Zephyr fork | `~/tenstorrent/zephyr/` | tt-zephyr-v4.3.0 branch |
| Zephyr SDK 0.17.4 | `~/zephyr-sdk-0.17.4/` | All toolchains (ARC, ARM, RISC-V, x86, xtensa) |
| MCUBoot | `~/tenstorrent/bootloader/mcuboot/` | Zephyr module |
| nanopb | `~/tenstorrent/modules/lib/nanopb/` | Protobuf code generation |
| hal_stm32 | `~/tenstorrent/modules/hal/stm32/` | STM32 HAL for DMC |
| mbedtls | `~/tenstorrent/modules/crypto/mbedtls/` | Crypto for MCUBoot signing |
| cmsis_6 | `~/tenstorrent/modules/hal/cmsis_6/` | ARM CMSIS |
| segger | `~/tenstorrent/modules/debug/segger/` | RTT console |
| librpmi | `~/tenstorrent/modules/lib/librpmi/` | RPMI library |
| Python deps | `~/tenstorrent/.venv/` | west, protobuf, grpcio-tools, imgtool, etc. |
| Blobs | `~/tenstorrent/tt-zephyr-platforms/zephyr/blobs/` | erisc, gddr_init, serdes, libpciesd |
| protobuf-compiler | system (`/usr/bin/protoc`) | `dnf install protobuf-compiler` |
| dtc | system (`/usr/bin/dtc`) | `dnf install dtc` |

<a id="firmware-build-system--updating"></a>
#### Updating

```bash
source ~/tenstorrent/.venv/bin/activate
cd ~/tenstorrent
west update                          # pull latest modules
west blobs fetch tt-zephyr-platforms # update blobs
```

<a id="firmware-build-system--setup-from-scratch"></a>
### Setup from scratch

<a id="firmware-build-system--prerequisites"></a>
#### Prerequisites

- Python 3.12+
- Fedora: `sudo dnf install protobuf-compiler cmake ninja-build dtc`
- Ubuntu: `sudo apt install protobuf-compiler cmake ninja-build device-tree-compiler`

<a id="firmware-build-system--initialize-workspace"></a>
#### Initialize workspace

```bash
pip install west

# Initialize west workspace with tt-zephyr-platforms as manifest repo
cd /home/boop/tenstorrent
west init -l tt-zephyr-platforms

# Enable optional modules (hal_stm32, mcuboot, nanopb, etc.)
west config manifest.group-filter +optional

# Pull all Zephyr modules
west update

# Install Zephyr Python deps
west packages pip --install

# Install Zephyr SDK (compilers for ARC, ARM, RISC-V)
west sdk install

# Fetch binary blobs (erisc, gddr_init, serdes, libpciesd, etc.)
west blobs fetch tt-zephyr-platforms
```

<a id="firmware-build-system--required-toolchains-installed-by-west-sdk-install"></a>
#### Required toolchains (installed by `west sdk install`)

- `arc-zephyr-elf` -- ARC HS38 (SMC/CMFW runs on the Blackhole's ARC processor)
- `arm-zephyr-eabi` -- ARM Cortex-M (DMC runs on STM32G0)
- `riscv64-zephyr-elf` -- RISC-V (optional, for tile firmware development)

<a id="firmware-build-system--building"></a>
### Building

<a id="firmware-build-system--board-target-format"></a>
#### Board target format

```
tt_blackhole@<revision>/tt_blackhole/smc
```

Revisions: `p100a`, `p150a`, `p150b`, `p150c`, `p300a`, `p300b`, `p300c`, `galaxy`

Helper script: `scripts/rev2board.sh p100a` → `tt_blackhole@p100a/tt_blackhole/smc`

<a id="firmware-build-system--build-command"></a>
#### Build command

```bash
# P100A
west build --sysbuild -p -b tt_blackhole@p100a/tt_blackhole/smc app/smc

# P150A with shell enabled (for debugging)
west build --sysbuild -p -b tt_blackhole@p150a/tt_blackhole/smc app/smc \
  -- -DCONFIG_SHELL=y

# With image signing
west build --sysbuild -p -b tt_blackhole@p150a/tt_blackhole/smc app/smc \
  -- -DSB_CONFIG_BOOT_SIGNATURE_KEY_FILE="/path/to/key.pem"
```

`-p` is pristine build (clean rebuild). Omit for incremental builds.

<a id="firmware-build-system--build-outputs"></a>
#### Build outputs

```
build/
├── smc/zephyr/zephyr.signed.bin     # mainimg
├── recovery/zephyr/zephyr.signed.bin # safeimg
├── dmc/zephyr/zephyr.signed.bin     # dmfwimg
├── mcuboot/zephyr/zephyr.bin        # cmfw
├── mcuboot-bl2/zephyr/zephyr.bin    # blupdate
├── dmc-rom-update/zephyr/zephyr.signed.bin # bmfw
├── tt_boot_fs.yaml                  # boot filesystem descriptor
├── tt_boot_fs.hex                   # full SPI flash image
└── update.fwbundle                  # FINAL OUTPUT
```

<a id="firmware-build-system--flashing"></a>
### Flashing

```bash
# Normal flash (preserves boardcfg per mask.json)
tt-flash update.fwbundle

# Force flash (overwrite everything including boardcfg)
tt-flash update.fwbundle --force
```

<a id="firmware-build-system--what-to-modify"></a>
### What to modify

<a id="firmware-build-system--fan-curve"></a>
#### Fan curve

Edit `lib/tenstorrent/bh_arc/fan_ctrl.c`. The curve is hardcoded quadratic:

```
ASIC:  <49C → 35%    49-90C → 0.03867*(T-49)^2 + 35%    >90C → 100%
GDDR:  <43C → 35%    43-82C → 0.04274*(T-43)^2 + 35%    >82C → 100%
```

Change the coefficients, thresholds, or replace with a linear/table-driven curve. The `FanTable` protobuf fields are currently unused -- if you want config-driven curves, you'd need to wire them up in `fan_ctrl.c`.

<a id="firmware-build-system--feature-flags-and-chip-limits"></a>
#### Feature flags and chip limits

Edit `boards/tenstorrent/tt_blackhole/spirom_data_tables/<BOARD>/fw_table.txt`. This is the textproto source for the FwTable protobuf. Fields include:

```
feature_enable.fan_ctrl_en        # enable/disable fan control
feature_enable.aiclk_ppm_en       # enable/disable DVFS
feature_enable.watchdog_en        # ARC watchdog
chip_limits.thm_limit             # thermal throttle trigger
chip_limits.therm_trip_l1_limit   # emergency thermal trip
chip_limits.tdp_limit             # power limit
```

<a id="firmware-build-system--smc--dmc-application-logic"></a>
#### SMC / DMC application logic

- `app/smc/src/main.c` -- init sequence, timers, message handling
- `app/dmc/src/main.c` -- fan PWM writes, thermal trip, I2C, power monitoring

<a id="firmware-build-system--mcuboot-configuration"></a>
#### MCUBoot configuration

- `app/smc/sysbuild/mcuboot.conf` -- RAM-load, revert behavior, CSM size
- `app/dmc/sysbuild/mcuboot.conf` -- swap-using-offset, bootstrap

<a id="firmware-build-system--board-level-hardware-config"></a>
#### Board-level hardware config

- `boards/tenstorrent/tt_blackhole/tt_blackhole_fixed_partitions.dtsi` -- SPI flash layout
- `boards/tenstorrent/tt_blackhole/tt_blackhole_dmc.dtsi` -- DMC I2C, fan, GPIO
- Board overlays: `boards/.../tt_blackhole_tt_blackhole_<smc|dmc>_<rev>.overlay`

<a id="firmware-build-system--build-system-internals"></a>
### Build system internals

<a id="firmware-build-system--westyml-dependencies"></a>
#### west.yml dependencies

| Module | Source | Purpose |
|---|---|---|
| zephyr | tenstorrent/zephyr-fork @ tt-zephyr-v4.3.0 | Zephyr RTOS |
| mcuboot | zephyr mcuboot module | Bootloader |
| nanopb | zephyr nanopb module | Protobuf code generation |
| hal_stm32 | zephyr hal module | STM32 HAL for DMC |
| cmsis_6 | zephyr module | ARM CMSIS |
| mbedtls | zephyr module | Crypto for MCUBoot signing |

<a id="firmware-build-system--sysbuild-orchestration-appsmcsysbuildcmake"></a>
#### Sysbuild orchestration (`app/smc/sysbuild.cmake`)

Defines all sub-projects and their board mappings:

```
recovery  → same board as SMC, with CONFIG_TT_SMC_RECOVERY=y
dmc       → mapped per-revision (e.g., p100a → tt_blackhole@p100a/tt_blackhole/dmc)
mcuboot   → same board as SMC
mcuboot-bl2, dmc-rom-update → DMC board variants
```

<a id="firmware-build-system--boot-filesystem-generation"></a>
#### Boot filesystem generation

1. `tt_boot_fs.py generate_bootfs` reads the device tree and generates `tt_boot_fs.yaml`
2. `tt_boot_fs.py mkfs` reads the YAML + all binaries → produces `tt_boot_fs.hex` (Intel HEX of full 64M SPI image)
3. `tt_fwbundle.py create` wraps the hex image into a versioned tarball

<a id="firmware-build-system--protobuf-generation"></a>
#### Protobuf generation

nanopb compiles `.proto` files in `drivers/misc/bh_fwtable/spirom_protobufs/` into C structs used by the fwtable driver. The per-board `.txt` files are textproto that get compiled to `.bin` during build.

<a id="firmware-build-system--version"></a>
#### Version

`VERSION` file at repo root: `MAJOR.MINOR.PATCH.TWEAK` (currently 19.5.99.0).

<a id="firmware-build-system--pre-built-blobs-zephyrblobs"></a>
#### Pre-built blobs (`zephyr/blobs/`)

Fetched via `west blobs fetch`. Not buildable from this repo:

- `tt_blackhole_erisc.bin` -- ethernet RISC-V firmware
- `tt_blackhole_gddr_init.bin` -- GDDR init RISC-V firmware
- `tt_blackhole_serdes_eth_fw.bin` -- SerDes firmware
- `tt_blackhole_libpciesd.a` -- PCIe SerDes library (linked into SMC)
- `tt_blackhole_erisc_params.bin` -- ethernet parameters
- `tt_blackhole_gddr_params_<BOARD>.bin` -- per-board GDDR parameters
- `tt_blackhole_serdes_eth_fwreg.bin` -- SerDes register init values

<a id="firmware-build-system--editing-the-fwbundle-post-build"></a>
#### Editing the fwbundle post-build

`scripts/fwtable_tooling.py` can modify the cmfwcfg protobuf in an existing bundle without rebuilding. `scripts/update_bar4_size.py` can change BAR4 size.

<a id="firmware-build-system--ci-reference"></a>
### CI reference

`.github/workflows/build-fw.yml` builds all boards in parallel. Board list in `.github/boards.json`:
```json
["p100a", "p150a", "p150b", "p150c", "p300a", "p300b", "p300c", "galaxy"]
```
