# Firmware Loading Analysis: tt-metal vs pure-py

## Summary

The pure-py firmware loading is missing several critical steps that tt-metal performs. Here's what's wrong and how to fix it.

---

## Key Issues in pure-py

### 1. Missing JAL Instruction at Address 0 (BRISC bootstrap)

**Problem:** BRISC has a hardcoded reset PC of 0, but firmware doesn't start at address 0. tt-metal generates a JAL (jump-and-link) instruction at address 0 that jumps to the actual firmware base.

**tt-metal code** (`tt_metal/llrt/hal.cpp:111-134`):
```cpp
uint32_t generate_risc_startup_addr(uint32_t firmware_base) {
  constexpr uint32_t jal_opcode = 0x6f;
  // RISC-V JAL encoding: imm[20|10:1|11|19:12] rd opcode
  uint32_t jal_offset_bit_20 = 0;
  uint32_t jal_offset_bits_10_to_1 = (firmware_base & 0x7fe) << 20;
  uint32_t jal_offset_bit_11 = (firmware_base & 0x800) << 9;
  uint32_t jal_offset_bits_19_to_12 = (firmware_base & 0xff000) << 0;
  uint32_t jal_offset = jal_offset_bit_20 | jal_offset_bits_10_to_1 |
                        jal_offset_bit_11 | jal_offset_bits_19_to_12;
  return jal_offset | jal_opcode;
}
```

**Fix for pure-py:**
```python
def generate_jal_instruction(target_addr: int) -> int:
  """Generate RISC-V JAL x0, target_addr instruction (unconditional jump)."""
  assert target_addr < 0x80000, f"JAL offset too large: {target_addr:#x}"
  jal_opcode = 0x6f
  # RISC-V JAL immediate encoding
  imm_20 = 0  # bit 20 is 0 for positive offsets < 0x80000
  imm_10_1 = (target_addr & 0x7fe) << 20
  imm_11 = (target_addr & 0x800) << 9
  imm_19_12 = (target_addr & 0xff000)
  return imm_20 | imm_10_1 | imm_11 | imm_19_12 | jal_opcode

# Usage: write generate_jal_instruction(0x3840) to L1 address 0x0
```

### 2. Missing Reset PC Override for TRISC/NCRISC

**Problem:** TRISC0/1/2 and NCRISC have configurable reset PC via debug registers. pure-py doesn't set these.

**Registers** (from `tensix.h`):
```
RISCV_DEBUG_REG_TRISC0_RESET_PC = 0xFFB12228
RISCV_DEBUG_REG_TRISC1_RESET_PC = 0xFFB1222C
RISCV_DEBUG_REG_TRISC2_RESET_PC = 0xFFB12230
RISCV_DEBUG_REG_NCRISC_RESET_PC = 0xFFB12238
```

**Firmware base addresses** (from `configs.py`):
```python
BRISC_FIRMWARE_BASE  = 0x003840
NCRISC_FIRMWARE_BASE = 0x005440
TRISC0_BASE          = 0x005a40
TRISC1_BASE          = 0x006040
TRISC2_BASE          = 0x006640
```

**Fix:** After writing firmware, write the firmware base address to each reset PC register:
```python
# Write reset PC for TRISC/NCRISC (BRISC uses JAL at 0 instead)
win.writei32(0xFFB12228 - reg_base, TensixL1.TRISC0_BASE)   # TRISC0
win.writei32(0xFFB1222C - reg_base, TensixL1.TRISC1_BASE)   # TRISC1
win.writei32(0xFFB12230 - reg_base, TensixL1.TRISC2_BASE)   # TRISC2
win.writei32(0xFFB12238 - reg_base, TensixL1.NCRISC_FIRMWARE_BASE)  # NCRISC
```

### 3. Wrong Reset Sequence (release all vs BRISC-first)

**Problem:** pure-py releases ALL cores simultaneously by writing 0x0 to soft reset. tt-metal only deasserts BRISC, and BRISC firmware brings up the other cores.

**Current pure-py** (`device.py:251`):
```python
win.writei32(reg_off, 0x0)  # releases ALL cores at once
```

**tt-metal approach** (`metal_context.cpp:1638`):
```cpp
reset_val = tt::umd::RiscType::BRISC;  // Only deassert BRISC
cluster_->deassert_risc_reset_at_core(..., reset_val);
```

**Soft reset bits** (from `tensix.h`):
```
RISCV_SOFT_RESET_0_BRISC  = 0x00800  (bit 11)
RISCV_SOFT_RESET_0_NCRISC = 0x40000  (bit 18)
RISCV_SOFT_RESET_0_TRISCS = 0x07000  (bits 12-14)
```

**Fix:** Only clear BRISC reset bit, keep others in reset:
```python
# Current value: 0x47800 (all in reset)
# To release only BRISC: clear bit 11, keep bits 12-14 and 18 set
BRISC_RESET_BIT = 0x00800
KEEP_OTHERS_RESET = 0x47000  # TRISCS (0x7000) + NCRISC (0x40000)
win.writei32(reg_off, KEEP_OTHERS_RESET)  # Release only BRISC
```

---

## Complete Reset Sequence (tt-metal style)

1. **Assert all cores in reset**
   ```python
   win.writei32(reg_off, 0x47800)  # SOFT_RESET_ALL
   ```

2. **Write firmware to L1** (PT_LOAD segments)

3. **Write JAL instruction at address 0** (for BRISC)
   ```python
   jal = generate_jal_instruction(TensixL1.BRISC_FIRMWARE_BASE)
   win.writei32(0x0, jal)
   ```

4. **Write reset PC registers** (for TRISC/NCRISC)
   ```python
   win.writei32(0xFFB12228 - reg_base, TensixL1.TRISC0_BASE)
   win.writei32(0xFFB1222C - reg_base, TensixL1.TRISC1_BASE)
   win.writei32(0xFFB12230 - reg_base, TensixL1.TRISC2_BASE)
   win.writei32(0xFFB12238 - reg_base, TensixL1.NCRISC_FIRMWARE_BASE)
   ```

5. **Memory barrier** (read from register to flush writes)
   ```python
   win.readi32(reg_off)
   ```

6. **Deassert BRISC only**
   ```python
   win.writei32(reg_off, 0x47000)  # Keep TRISC/NCRISC in reset
   ```

7. **Wait for firmware init** (BRISC will bring up other cores)

---

## XIP (Execute-In-Place) Translation

tt-metal has an `XIPify()` function in `tt_elffile.cpp` that transforms ELF relocations from absolute addressing (LUI/ADDI pairs) to PC-relative addressing (AUIPC/ADDI pairs). This allows firmware to run from any address.

**Key insight:** The firmware ELFs from tt-metal cache are already processed. If using the same binaries, XIP should work. But if you're compiling custom firmware, you may need XIP translation.

The pure-py `pack_xip_elf()` function just concatenates PT_LOAD segments without doing relocation fixups - this may be a problem for custom firmware but should be fine for tt-metal's pre-built binaries.

---

## File References

| File | Key Content |
|------|-------------|
| `tt-metal/tt_metal/llrt/hal.cpp:111-134` | `generate_risc_startup_addr()` - JAL generation |
| `tt-metal/tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp:90-127` | Processor configs with fw_launch_addr |
| `tt-metal/tt_metal/impl/context/metal_context.cpp:1156-1268` | `initialize_firmware()` |
| `tt-metal/tt_metal/impl/context/metal_context.cpp:1627-1645` | Deassert sequence (BRISC only) |
| `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h:103-106,208-213` | Reset bits and PC registers |
| `pure-py/device.py:187-266` | Current upload_firmware() |
| `pure-py/configs.py:68-79` | TensixMMIO register addresses |

---

## Recommended Changes to pure-py

### 1. Add to `configs.py`:
```python
class TensixMMIO:
  # ... existing ...
  # Individual soft reset bits
  SOFT_RESET_BRISC = 0x00800
  SOFT_RESET_TRISCS = 0x07000
  SOFT_RESET_NCRISC = 0x40000
  # For releasing only BRISC
  SOFT_RESET_KEEP_OTHERS = SOFT_RESET_TRISCS | SOFT_RESET_NCRISC  # 0x47000
```

### 2. Add to `helpers.py`:
```python
def generate_jal_instruction(target_addr: int) -> int:
  """Generate RISC-V JAL x0, offset instruction for BRISC bootstrap."""
  assert target_addr < 0x80000, f"target too far for JAL: {target_addr:#x}"
  opcode = 0x6f
  imm_10_1 = (target_addr & 0x7fe) << 20
  imm_11 = (target_addr & 0x800) << 9
  imm_19_12 = target_addr & 0xff000
  return imm_19_12 | imm_11 | imm_10_1 | opcode
```

### 3. Update `device.py` `upload_firmware()`:
- Write JAL instruction at address 0
- Write reset PC registers for TRISC/NCRISC
- Only release BRISC, not all cores
