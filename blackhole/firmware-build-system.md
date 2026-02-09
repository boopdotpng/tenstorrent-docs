# Building firmware and creating custom fwbundles

## Overview

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

## Setup from scratch

### Prerequisites

- Python 3.12+
- Fedora: `sudo dnf install protobuf-compiler cmake ninja-build dtc`
- Ubuntu: `sudo apt install protobuf-compiler cmake ninja-build device-tree-compiler`

### Initialize workspace

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

### Required toolchains (installed by `west sdk install`)

- `arc-zephyr-elf` -- ARC HS38 (SMC/CMFW runs on the Blackhole's ARC processor)
- `arm-zephyr-eabi` -- ARM Cortex-M (DMC runs on STM32G0)
- `riscv64-zephyr-elf` -- RISC-V (optional, for tile firmware development)

## Building

### Board target format

```
tt_blackhole@<revision>/tt_blackhole/smc
```

Revisions: `p100a`, `p150a`, `p150b`, `p150c`, `p300a`, `p300b`, `p300c`, `galaxy`

Helper script: `scripts/rev2board.sh p100a` → `tt_blackhole@p100a/tt_blackhole/smc`

### Build command

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

### Build outputs

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

## Flashing

```bash
# Normal flash (preserves boardcfg per mask.json)
tt-flash update.fwbundle

# Force flash (overwrite everything including boardcfg)
tt-flash update.fwbundle --force
```

## What to modify

### Fan curve

Edit `lib/tenstorrent/bh_arc/fan_ctrl.c`. The curve is hardcoded quadratic:

```
ASIC:  <49C → 35%    49-90C → 0.03867*(T-49)^2 + 35%    >90C → 100%
GDDR:  <43C → 35%    43-82C → 0.04274*(T-43)^2 + 35%    >82C → 100%
```

Change the coefficients, thresholds, or replace with a linear/table-driven curve. The `FanTable` protobuf fields are currently unused -- if you want config-driven curves, you'd need to wire them up in `fan_ctrl.c`.

### Feature flags and chip limits

Edit `boards/tenstorrent/tt_blackhole/spirom_data_tables/<BOARD>/fw_table.txt`. This is the textproto source for the FwTable protobuf. Fields include:

```
feature_enable.fan_ctrl_en        # enable/disable fan control
feature_enable.aiclk_ppm_en       # enable/disable DVFS
feature_enable.watchdog_en        # ARC watchdog
chip_limits.thm_limit             # thermal throttle trigger
chip_limits.therm_trip_l1_limit   # emergency thermal trip
chip_limits.tdp_limit             # power limit
```

### SMC / DMC application logic

- `app/smc/src/main.c` -- init sequence, timers, message handling
- `app/dmc/src/main.c` -- fan PWM writes, thermal trip, I2C, power monitoring

### MCUBoot configuration

- `app/smc/sysbuild/mcuboot.conf` -- RAM-load, revert behavior, CSM size
- `app/dmc/sysbuild/mcuboot.conf` -- swap-using-offset, bootstrap

### Board-level hardware config

- `boards/tenstorrent/tt_blackhole/tt_blackhole_fixed_partitions.dtsi` -- SPI flash layout
- `boards/tenstorrent/tt_blackhole/tt_blackhole_dmc.dtsi` -- DMC I2C, fan, GPIO
- Board overlays: `boards/.../tt_blackhole_tt_blackhole_<smc|dmc>_<rev>.overlay`

## Build system internals

### west.yml dependencies

| Module | Source | Purpose |
|---|---|---|
| zephyr | tenstorrent/zephyr-fork @ tt-zephyr-v4.3.0 | Zephyr RTOS |
| mcuboot | zephyr mcuboot module | Bootloader |
| nanopb | zephyr nanopb module | Protobuf code generation |
| hal_stm32 | zephyr hal module | STM32 HAL for DMC |
| cmsis_6 | zephyr module | ARM CMSIS |
| mbedtls | zephyr module | Crypto for MCUBoot signing |

### Sysbuild orchestration (`app/smc/sysbuild.cmake`)

Defines all sub-projects and their board mappings:

```
recovery  → same board as SMC, with CONFIG_TT_SMC_RECOVERY=y
dmc       → mapped per-revision (e.g., p100a → tt_blackhole@p100a/tt_blackhole/dmc)
mcuboot   → same board as SMC
mcuboot-bl2, dmc-rom-update → DMC board variants
```

### Boot filesystem generation

1. `tt_boot_fs.py generate_bootfs` reads the device tree and generates `tt_boot_fs.yaml`
2. `tt_boot_fs.py mkfs` reads the YAML + all binaries → produces `tt_boot_fs.hex` (Intel HEX of full 64M SPI image)
3. `tt_fwbundle.py create` wraps the hex image into a versioned tarball

### Protobuf generation

nanopb compiles `.proto` files in `drivers/misc/bh_fwtable/spirom_protobufs/` into C structs used by the fwtable driver. The per-board `.txt` files are textproto that get compiled to `.bin` during build.

### Version

`VERSION` file at repo root: `MAJOR.MINOR.PATCH.TWEAK` (currently 19.5.99.0).

### Pre-built blobs (`zephyr/blobs/`)

Fetched via `west blobs fetch`. Not buildable from this repo:

- `tt_blackhole_erisc.bin` -- ethernet RISC-V firmware
- `tt_blackhole_gddr_init.bin` -- GDDR init RISC-V firmware
- `tt_blackhole_serdes_eth_fw.bin` -- SerDes firmware
- `tt_blackhole_libpciesd.a` -- PCIe SerDes library (linked into SMC)
- `tt_blackhole_erisc_params.bin` -- ethernet parameters
- `tt_blackhole_gddr_params_<BOARD>.bin` -- per-board GDDR parameters
- `tt_blackhole_serdes_eth_fwreg.bin` -- SerDes register init values

### Editing the fwbundle post-build

`scripts/fwtable_tooling.py` can modify the cmfwcfg protobuf in an existing bundle without rebuilding. `scripts/update_bar4_size.py` can change BAR4 size.

## CI reference

`.github/workflows/build-fw.yml` builds all boards in parallel. Board list in `.github/boards.json`:
```json
["p100a", "p150a", "p150b", "p150c", "p300a", "p300b", "p300c", "galaxy"]
```
