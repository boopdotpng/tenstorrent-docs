# Firmware: core loading, reset sequencing, and fan control

## Core firmware (Tensix, Blackhole)

### What it is
- Core firmware is the L1-resident code that runs on BRISC/NCRISC/TRISC (and ERISC) cores.
- It brings up NOC access, mailbox/dispatch handling, and the kernel-entry wrappers that let host code launch user kernels.
- It is distinct from your kernels: firmware is the persistent “runtime” for the core, kernels are loaded and run on demand.

### Lifecycle and when to load
- L1 is volatile. After a reset or power cycle, core firmware is not present.
- `tt-metal` loads firmware during device/context initialization, then reuses it for all kernels.
- For a pure-Python driver, the safest approach is to always load firmware at startup; it is not per-kernel and is fast enough to do once per device open.

### Holding Tensix RISCs in reset (during firmware upload)
- Keep BRISC/NCRISC/TRISC0/1/2 in reset while you overwrite their L1 code/data regions.
- Per-tile soft-reset register: `RISCV_DEBUG_REG_SOFT_RESET_0` at tile-local address `0xFFB121B0`.
- Bits (1 = held in reset):
  - BRISC: `0x00800`
  - TRISC0/1/2: `0x07000`
  - NCRISC: `0x40000`
- Assert all Tensix RISCs: write `0x47800`.
- Deassert: clear those bits (write `0x0` if you want everything running; some bring-up sequences release cores in stages).

### Does it change per kernel or runtime args?
- Firmware is built per architecture and build configuration, not per kernel.
- Runtime arguments do not change the firmware image; they are passed through mailboxes and control structures at run time.
- You can keep one firmware image loaded while compiling and launching many kernels.

### Where it comes from (Blackhole sources)
Firmware sources are open C++ under `tt_metal/hw/firmware/src/tt-1xx/`:
- Core firmware:
  - `brisc.cc`, `ncrisc.cc`, `trisc.cc`
  - `active_erisc.cc`, `active_erisc-crt0.cc`, `subordinate_erisc.cc`, `idle_erisc.cc`
- Kernel-entry wrappers:
  - `brisck.cc`, `ncrisck.cc`, `trisck.cc`, `active_erisck.cc`, `idle_erisck.cc`

### Where the built firmware lives
- Host-side build output cached under:
  - `~/.cache/tt-metal-cache/<build-key>/firmware/<hash>/`
- This cache is per build configuration and architecture; it is not per kernel.

### Practical note for pure-Python drivers
- Always load firmware after opening the device or after any reset.
- You only need to do this once per device/session.

## Firmware loading gaps (pure-py vs tt-metal)

### 1) Missing JAL at address 0 (BRISC bootstrap)

BRISC reset PC is 0, but firmware doesn't start at address 0. tt-metal generates a JAL at address 0 that jumps to the firmware base.

`tt_metal/llrt/hal.cpp`:
```cpp
uint32_t generate_risc_startup_addr(uint32_t firmware_base) {
  constexpr uint32_t jal_opcode = 0x6f;
  uint32_t jal_offset_bit_20 = 0;
  uint32_t jal_offset_bits_10_to_1 = (firmware_base & 0x7fe) << 20;
  uint32_t jal_offset_bit_11 = (firmware_base & 0x800) << 9;
  uint32_t jal_offset_bits_19_to_12 = (firmware_base & 0xff000) << 0;
  uint32_t jal_offset = jal_offset_bit_20 | jal_offset_bits_10_to_1 |
                        jal_offset_bit_11 | jal_offset_bits_19_to_12;
  return jal_offset | jal_opcode;
}
```

### 2) Missing reset PC override for TRISC/NCRISC

TRISC0/1/2 and NCRISC have configurable reset PC via debug registers:
```
RISCV_DEBUG_REG_TRISC0_RESET_PC = 0xFFB12228
RISCV_DEBUG_REG_TRISC1_RESET_PC = 0xFFB1222C
RISCV_DEBUG_REG_TRISC2_RESET_PC = 0xFFB12230
RISCV_DEBUG_REG_NCRISC_RESET_PC = 0xFFB12238
```

Write the firmware base for each core after upload.

### 3) Wrong reset sequence (release all vs BRISC-first)

Pure-py releases all cores at once. tt-metal deasserts BRISC only, and BRISC brings up the others.

Soft reset bits:
```
RISCV_SOFT_RESET_0_BRISC  = 0x00800
RISCV_SOFT_RESET_0_NCRISC = 0x40000
RISCV_SOFT_RESET_0_TRISCS = 0x07000
```

### Complete reset sequence (tt-metal style)

1. Assert all cores in reset: `0x47800`
2. Write firmware to L1
3. Write JAL at address 0 for BRISC
4. Write reset PC registers for TRISC/NCRISC
5. Memory barrier (read from register)
6. Deassert BRISC only: keep TRISC/NCRISC in reset
7. Wait for BRISC init (it brings up others)

### XIP (Execute-In-Place)

`XIPify()` transforms ELF relocations from absolute to PC-relative so firmware can run from any address. tt-metal’s cached ELFs are already processed. If compiling custom firmware, you may need XIP translation.

## Fan control analysis

### Firmware structure

Firmware bundles (`.fwbundle`) contain multiple components stored in a boot filesystem format. Disassembled to `image.bin`, they are ASCII hex with `@<address>` markers.

### Boot FS table (summary)

Key tags:
- `cmfw`, `safeimg`, `safetail`, `bmfw`, `blupdate`, `cmfwcfg`, `ethfwcfg`, `memfwcfg`, `ethsdreg`, `ethfw`, `memfw`, `ethsdfw`, `dmfw`, `dmfwimg`, `dmfwtail`, `mainimg`, `maintail`
- `boardcfg` (16 bytes): likely fan config

### boardcfg data (P100A-1)

```
Hex: 08 80 80 80 80 90 86 01 12 00 1a 00 20 d2 3c 00
```

Bytes 1-6 appear to be PWM values:
- `[128, 128, 128, 128, 144, 134]` → roughly `[50%, 50%, 50%, 50%, 56%, 52%]`

### Special handling

`mask.json` includes:
```json
[{"tag": "write-boardcfg"}]
```

`tt_flash/blackhole.py:writeback_boardcfg()` preserves existing boardcfg during flash, indicating board-specific calibration.

### Modification strategies

**Option A: Direct boardcfg modification**
1. Extract firmware bundle → `image.bin`
2. Modify bytes 1-6 at SPI address `0xd4000`
3. Modify/remove `mask.json` to allow writeback
4. Reassemble and flash

**Option B: Runtime modification via SMC**
- Use System Management Controller message interface
- Message types for fan control not yet identified

**Option C: Full origcfg analysis**
- `origcfg` (96 bytes) may contain full fan curve table

### Tools & repos
- `tt-flash`
- `tt-firmware`
- `tt-zephyr-platforms`

