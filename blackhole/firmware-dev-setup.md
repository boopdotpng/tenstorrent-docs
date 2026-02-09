# Firmware dev environment setup

Installed 2025-02-07. Everything lives under `~/tenstorrent`.

## What's installed

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

## Quick build

```bash
source ~/tenstorrent/.venv/bin/activate
cd ~/tenstorrent
west build --sysbuild -p -b tt_blackhole@p100a/tt_blackhole/smc tt-zephyr-platforms/app/smc
```

Output: `build/update.fwbundle`

## Other boards

Replace `p100a` with: `p150a`, `p150b`, `p150c`, `p300a`, `p300b`, `p300c`, `galaxy`

## Updating

```bash
source ~/tenstorrent/.venv/bin/activate
cd ~/tenstorrent
west update                          # pull latest modules
west blobs fetch tt-zephyr-platforms # update blobs
```
