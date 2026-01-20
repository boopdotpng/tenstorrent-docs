# NOC1 Translation Configuration

## Hardware Register

NOC translation is controlled by **bit 14** of the NIU_CFG register:
- `NIU_CFG_0_NOC_ID_TRANSLATE_EN = 14` (defined in `tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h:146`)

## Register Addresses (Blackhole)

From `tt_metal/third_party/umd/device/api/umd/device/arch/blackhole_implementation.hpp:254-258`:

```cpp
inline constexpr uint32_t NIU_CFG_NOC0_BAR_ADDR = 0x1FD04100;
inline constexpr uint32_t NIU_CFG_NOC1_BAR_ADDR = 0x1FD14100;  // +0x10000 offset

inline constexpr uint64_t NIU_CFG_NOC0_ARC_ADDR = 0x80050100;
inline constexpr uint64_t NIU_CFG_NOC1_ARC_ADDR = 0x80058100;
```

## Reading Translation Status

From `tt_metal/third_party/umd/device/tt_device/blackhole_tt_device.cpp:107-118`:

```cpp
bool BlackholeTTDevice::get_noc_translation_enabled() {
    uint32_t niu_cfg;
    const uint64_t addr = blackhole::NIU_CFG_NOC0_BAR_ADDR;

    if (get_communication_device_type() == IODeviceType::JTAG) {
        niu_cfg = get_jtag_device()->read32_axi(0, blackhole::NIU_CFG_NOC0_ARC_ADDR).value();
    } else {
        niu_cfg = bar_read32(addr);
    }
    return ((niu_cfg >> 14) & 0x1) != 0;
}
```

## Runtime NOC Selection

A global `umd_use_noc1` flag (declared in `tt_metal/third_party/umd/device/chip/local_chip.cpp:18`) controls which NOC coordinates are used at runtime.

When set, coordinate translation uses NOC1 mapping tables from `tt_metal/third_party/umd/device/api/umd/device/arch/blackhole_implementation.hpp:62-66`:

```cpp
// NOC0_X_TO_NOC1_X[noc0_x] is the NOC1 x coordinate corresponding to NOC0 x coordinate noc0_x.
static const std::vector<uint32_t> NOC0_X_TO_NOC1_X = {16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};
static const std::vector<uint32_t> NOC0_Y_TO_NOC1_Y = {11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};
```

The coordinates are mirrored between NOC0 and NOC1.

## Wormhole

Similar approach in `tt_metal/third_party/umd/device/tt_device/wormhole_tt_device.cpp:57-68`:

```cpp
bool WormholeTTDevice::get_noc_translation_enabled() {
    uint32_t niu_cfg;
    const tt_xy_pair dram_core =
        umd_use_noc1 ? tt_xy_pair(wormhole::NOC0_X_TO_NOC1_X[0], wormhole::NOC0_Y_TO_NOC1_Y[0]) : tt_xy_pair(0, 0);
    const uint64_t niu_cfg_addr = 0x1000A0000 + 0x100;
    read_from_device(&niu_cfg, dram_core, niu_cfg_addr, sizeof(uint32_t));

    return (niu_cfg & (1 << 14)) != 0;
}
```

## When to Set Translation

The translation bit should be set **after device reset / BAR mapping** but **before firmware runs**. The RISC-V firmware reads this bit during initialization to configure coordinate handling.

In tt-metal, this is typically set by ARC firmware during POST_RESET (before UMD starts). On a fresh boot, it may already be enabled.

Sequence:
1. Device reset / POST_RESET
2. Map BARs
3. **Set NOC translation** (if needed)
4. Upload RISC-V firmware
5. Firmware reads NIU_CFG_0[14] to detect translation state

## Summary

- NOC1 translation is a hardware feature enabled via the NIU configuration register
- Software reads bit 14 to detect if translation is enabled
- Architecture-specific coordinate mapping tables convert between NOC0 and NOC1 addressing
- The `umd_use_noc1` global flag controls runtime behavior
