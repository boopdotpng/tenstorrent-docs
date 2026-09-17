# Scalar and configuration instructions

GPR arithmetic and backend configuration share state but have different execution units. The ISA viewer attaches reviewed test claims and timing evidence to individual encoders.

<a id="gpr-and-dma-instructions"></a>
## Tensix GPRs, Scalar Unit, and Configuration Unit Instructions
<a id="gpr-and-dma-instructions--tensix-gprs-scalar-unit-and-configuration-unit-instructions"></a>

The Tensix coprocessor has a 192-register GPR (General Purpose Register) file that serves as a staging area for values destined for backend configuration registers. The RISC-V cores load constants into GPRs, then Tensix instructions copy those values into the config registers that control hardware units (unpackers, packers, matrix unit, etc.).

```
SETDMAREG → GPR → (sync) → WRCFG/RDCFG/RMWCIB/SETC16 → Config/ThreadConfig → controls hardware
```

Two execution units are involved:
- **Scalar Unit (ThCon):** Operates on GPRs. Runs SETDMAREG, ADDDMAREG, MULDMAREG, DMANOP, etc.
- **Configuration Unit:** Reads/writes config registers. Runs WRCFG, RDCFG, SETC16, RMWCIB, etc.


<a id="gpr-and-dma-instructions--gpr-file-layout"></a>
### GPR File Layout

The GPR file is mapped at `0xFFE00000` in the RISC-V address space:

```
0xFFE00000 .. 0xFFE000FF   Thread 0 (T0) — 64 x 32-bit registers (256 bytes)
0xFFE00100 .. 0xFFE001FF   Thread 1 (T1) — 64 x 32-bit registers
0xFFE00200 .. 0xFFE002FF   Thread 2 (T2) — 64 x 32-bit registers
```

The ISA models them as:
```c
uint32_t GPRs[3][64];   // 192 total, 64 per thread
```

The address space reservation extends to `0xFFE3FFFF` (256 KiB), but only 768 bytes are populated.

<a id="gpr-and-dma-instructions--access-rules"></a>
#### Access Rules

- Each coprocessor thread (T0/T1/T2) can only access its own 64 GPRs via Tensix instructions.
- BRISC has full MMIO read/write access to all three threads' GPRs.
- NCRISC has no access.
- Each RISC-V T*i* also has its own GPRs mapped at `REGFILE_BASE` (`0xFFE00000`), but can only see `GPRs[i]`.

<a id="gpr-and-dma-instructions--sub-word-addressing"></a>
#### Sub-Word Addressing

SETDMAREG addresses GPRs in **16-bit half-register** units. The index space is 0–127 (7 bits):
- Index `2*n` = low 16 bits of GPR `n`
- Index `2*n+1` = high 16 bits of GPR `n`

```c
#define LO_16(REG) (2 * (REG))       // low half of GPR
#define HI_16(REG) (2 * (REG) + 1)   // high half of GPR
```

<a id="gpr-and-dma-instructions--named-gpr-conventions"></a>
#### Named GPR Conventions

From `tt-llk/.../ckernel_gpr_map.h`:

**Common (all threads):**
| GPR | Name | Purpose |
|-----|------|---------|
| 0 | `ZERO` | Always 0 |
| 1 | `DBG_RESERVED` | Reserved |
| 2 | `DBG_MSG` | Firmware debug message |
| 3 | `DBG_CKID` | Ckernel ID |

**T0 (unpack thread):** GPRs 4–59 hold operand base/offset addresses, tile sizes, face dimensions, stride save/restore values.

**T1 (math thread):** GPRs 4–61 hold dest register offsets for SFPU, perf counters.

**T2 (pack thread):** GPRs 4–63 hold output L1 address, tile headers, stride configs, edge offsets.


<a id="gpr-and-dma-instructions--instructions"></a>
### Instructions

All four instructions execute on the **Scalar Unit (ThCon)**. The Scalar Unit is fully serialized: at most one instruction at a time, no internal pipelining, and it blocks all threads' Wait Gates while executing.

<a id="gpr-and-dma-instructions--setdmareg--set-16-bits-of-one-gpr-opcode-0x45"></a>
#### SETDMAREG — Set 16 bits of one GPR (opcode 0x45)

The workhorse instruction. Writes a 16-bit immediate to one half of a GPR, leaving the other half unchanged. Loading a full 32-bit constant requires two SETDMAREG instructions.

**Encoding:**
```
[31:24] = 0x45  (opcode)
[23:22] = Payload_SigSelSize  (2 bits — used in signal mode only)
[21:8]  = Payload_SigSel      (14 bits — immediate value in load mode)
[7]     = SetSignalsMode       (0 = immediate load, 1 = signal/packer read)
[6:0]   = RegIndex16b          (7 bits — half-register index 0–127)
```

```c
#define TT_OP_SETDMAREG(Payload_SigSelSize, Payload_SigSel, SetSignalsMode, RegIndex16b) \
    TT_OP(0x45, (((Payload_SigSelSize) << 22) + ((Payload_SigSel) << 8) \
               + ((SetSignalsMode) << 7) + ((RegIndex16b) << 0)))
```

**Functional model (immediate mode, SetSignalsMode=0):**
```c
uint16_t *HalfReg = (char*)&GPRs[CurrentThread][0] + ResultHalfReg * 2;
*HalfReg = NewValue;
```

**Signal mode (SetSignalsMode=1):** Reads 128 bits of packer configuration or state, then writes 16–128 bits to GPRs. The field layout changes meaning:

```c
TT_SETDMAREG(/* u2 */ ResultSize,
           ((/* u4 */ WhichPackers) << 7) +
           ((/* u4 */ InputSource ) << 3) +
             /* u3 */ InputHalfReg,
             1,  // SetSignalsMode = 1
             /* u7 */ ResultHalfReg)
```

`InputSource` selects what 128-bit value to read:

| InputSource | Value read (128 bits across Values[0..3]) |
|---|---|
| 0 | Per-packer `{AccTileSize[hi16], LastTileSize[lo16]}` for packers 0–3 |
| 1 | Per-packer `AllZeroFlags` for packers 0–3 |
| 2–5 | Full tile header for packer `InputSource-2`: TileSize, DataFormat, DisableZeroCompression, AllZeroFlags |
| 6–7 | 16-byte slice of exponent histogram for packer `WhichPackers` (bytes `[0..15]` or `[16..31]`) |
| 8 | Bit 0 of each packer's AllZeroFlags packed into Values[0] bits [3:0]; optionally resets AccTileSize (masked by WhichPackers) |
| 9 | `Packers[0].ExponentHistogramMaxExponent` |

`ResultSize` selects how many bits to write to GPRs:

| ResultSize | Effect |
|---|---|
| 0 | 16-bit: `HalfRegs[ResultHalfReg] = InputHalves[InputHalfReg]` |
| 1 | 32-bit: `GPRs[ResultHalfReg >> 1] = Values[InputHalfReg >> 1]` |
| 2 | 128-bit: writes all 4 Values to 4 consecutive aligned GPRs |
| 3 | 128-bit tile header: writes only tile header fields, preserving reserved bits |

**Performance:** 1 cycle (both modes).

<a id="gpr-and-dma-instructions--adddmareg--32-bit-gpr-addition-opcode-0x58"></a>
#### ADDDMAREG — 32-bit GPR addition (opcode 0x58)

```c
TT_ADDDMAREG(0, ResultReg, RightReg, LeftReg)   // reg + reg
TT_ADDDMAREG(1, ResultReg, RightImm6, LeftReg)  // reg + 6-bit unsigned immediate
```

**Encoding:**
```
[31:24] = 0x58
[23]    = OpBisConst  (0 = reg-reg, 1 = reg-immediate)
[17:12] = ResultRegIndex  (6 bits)
[11:6]  = OpBRegIndex     (6 bits — GPR index or 6-bit constant)
[5:0]   = OpARegIndex     (6 bits — GPR index)
```

**Functional model:**
```c
uint32_t LeftVal  = GPRs[CurrentThread][LeftReg];
uint32_t RightVal = OpBisConst ? RightImm6 : GPRs[CurrentThread][RightReg];
GPRs[CurrentThread][ResultReg] = LeftVal + RightVal;  // 32-bit, wraps on overflow
```

**Performance:** 3 cycles (immediate, or same aligned group of 4), 4 cycles otherwise.

<a id="gpr-and-dma-instructions--muldmareg--16-bit-unsigned-multiply--32-bit-result-opcode-0x5a"></a>
#### MULDMAREG — 16-bit unsigned multiply → 32-bit result (opcode 0x5A)

Same encoding layout as ADDDMAREG. Key distinction: **inputs are truncated to 16 bits**, but the product is a full 32-bit result.

```c
GPRs[CurrentThread][ResultReg] = (LeftVal & 0xFFFF) * (RightVal & 0xFFFF);
```

**Performance:** Same as ADDDMAREG.

<a id="gpr-and-dma-instructions--dmanop--scalar-unit-nop-opcode-0x60"></a>
#### DMANOP — Scalar Unit NOP (opcode 0x60)

```c
#define TT_OP_DMANOP TT_OP(0x60, 0)
```

Does nothing, occupies the Scalar Unit for 1 cycle. Used as a pipeline bubble between SETDMAREG and WRCFG when the Scalar Unit is provably already idle (replacing STALLWAIT in carefully scheduled code paths).


<a id="gpr-and-dma-instructions--loadind--indirect-gpr-load-from-l1-opcode-0x49"></a>
#### LOADIND — Indirect GPR Load from L1 (opcode 0x49)

Reads 8, 16, 32, or 128 bits from tile-local L1 memory into one or more GPRs, using an indirect address computed from two GPR values. The address register holds a 16-byte-aligned base, and a separate offset half-register provides the byte offset.

**Encoding:**
```
[31:24] = 0x49  (opcode)
[23:22] = SizeSel        (2 bits — 0=16B/4 GPRs, 1=32-bit, 2=16-bit, 3=8-bit)
[21:14] = OffsetIndex    (8 bits — half-register index for byte offset)
[13:12] = AutoIncSpec    (2 bits — 0=none, 1=+2B, 2=+4B, 3=+16B)
[11:6]  = DataRegIndex   (6 bits — destination GPR index)
[5:0]   = AddrRegIndex   (6 bits — base address GPR index)
```

```c
#define TT_OP_LOADIND(SizeSel, OffsetIndex, AutoIncSpec, DataRegIndex, AddrRegIndex) \
    TT_OP(0x49, (((SizeSel) << 22) + ((OffsetIndex) << 14) + ((AutoIncSpec) << 12) \
               + ((DataRegIndex) << 6) + ((AddrRegIndex) << 0)))
```

**Address computation:**
```c
uint32_t L1Address = GPRs[CurrentThread][AddrRegIndex] * 16 + *OffsetHalfReg;
```

The `AddrRegIndex` GPR holds a **16-byte word address** (multiply by 16 to get byte address). The `OffsetIndex` selects a 16-bit half-register (using the same `HalfReg[index]` scheme as SETDMAREG) that provides a byte offset added to the base.

**Functional model:**
```c
uint32_t* GPR = &GPRs[CurrentThread][DataRegIndex & (SizeSel ? 0x3F : 0x3C)];
uint16_t* Offset = (uint16_t*)((char*)&GPRs[CurrentThread][0] + OffsetIndex * 2);
uint32_t L1Addr = GPRs[CurrentThread][AddrRegIndex] * 16 + *Offset;

// Auto-increment offset register
switch (AutoIncSpec) {
    case 0: break;              // no increment
    case 1: *Offset += 2;  break;  // +2 bytes
    case 2: *Offset += 4;  break;  // +4 bytes
    case 3: *Offset += 16; break;  // +16 bytes
}

// Deferred: data arrives asynchronously after the Scalar Unit releases
switch (SizeSel) {
    case 0: memcpy(GPR, (void*)(L1Addr & ~15), 16); break;  // 16B → 4 aligned GPRs
    case 1: *GPR = *(uint32_t*)(L1Addr & ~3);       break;  // 32-bit word
    case 2: *(uint16_t*)GPR = *(uint16_t*)(L1Addr & ~1); break;  // 16-bit, low half only
    case 3: *(uint8_t*)GPR  = *(uint8_t*)L1Addr;    break;  // 8-bit, low byte only
}
```

For `SizeSel=0` (16B), the destination register index is masked to a 4-aligned boundary (`& 0x3C`), and four consecutive GPRs are written.

**Synchronization:** The Scalar Unit dispatches the read request and releases after >= 3 cycles, but the GPR data arrives asynchronously. Software must issue `STALLWAIT(STALL_CFG, THCON)` (block=B7, wait=C0) before any instruction that consumes the loaded GPR value.

**Performance:** >= 3 cycles occupying the Scalar Unit.

**Parameter constants** (from `ckernel_instr_params.h`):
```c
struct p_ind {
    static constexpr uint32_t HIER_L1   = 0x1;  // MemHierSel for STOREIND
    static constexpr uint32_t INC_NONE  = 0x0;
    static constexpr uint32_t INC_2B    = 0x1;
    static constexpr uint32_t INC_4B    = 0x2;
    static constexpr uint32_t INC_16B   = 0x3;
    static constexpr uint32_t LD_16B    = 0;
    static constexpr uint32_t LD_32bit  = 1;
    static constexpr uint32_t LD_16bit  = 2;
    static constexpr uint32_t LD_8bit   = 3;
};
```

<a id="gpr-and-dma-instructions--storeind--indirect-store-from-gpr-opcode-0x66"></a>
#### STOREIND — Indirect Store from GPR (opcode 0x66)

The counterpart to LOADIND. A polymorphic instruction with three modes selected by bit [23] (`MemHierSel`) and bit [22] (`SizeSel`):

| MemHierSel | SizeSel | Mode |
|---|---|---|
| 1 | x | **L1 mode**: write GPR data to L1 memory |
| 0 | 1 | **MMIO mode**: write 32-bit GPR to MMIO register |
| 0 | 0 | **Src mode**: write 2 GPRs (4×BF16) to SrcA or SrcB register file |

**Encoding:**
```
[31:24] = 0x66  (opcode)
[23]    = MemHierSel     (1 = L1 write, 0 = regfile/MMIO write)
[22]    = SizeSel        (mode-dependent — see above)
[21]    = RegSizeSel     (mode-dependent — data width or Src select)
[20:14] = OffsetIndex    (7 bits — half-register index for byte offset)
[13:12] = AutoIncSpec    (2 bits — auto-increment: 0=none, 1=+2B, 2=+4B, 3=+16B)
[11:6]  = DataRegIndex   (6 bits — source GPR index)
[5:0]   = AddrRegIndex   (6 bits — base address GPR index)
```

```c
#define TT_OP_STOREIND(MemHierSel, SizeSel, RegSizeSel, OffsetIndex, AutoIncSpec, DataRegIndex, AddrRegIndex) \
    TT_OP(0x66, (((MemHierSel) << 23) + ((SizeSel) << 22) + ((RegSizeSel) << 21) \
               + ((OffsetIndex) << 14) + ((AutoIncSpec) << 12) \
               + ((DataRegIndex) << 6) + ((AddrRegIndex) << 0)))
```

<a id="gpr-and-dma-instructions--l1-mode-memhiersel1-gpr--l1"></a>
##### L1 Mode (`MemHierSel=1`): GPR → L1

Address computation identical to LOADIND. `SizeSel` and `RegSizeSel` together encode the transfer size (same 0/1/2/3 scheme: 16B, 32-bit, 16-bit, 8-bit).

```c
// Functional model (L1 mode):
uint32_t* GPR = &GPRs[CurrentThread][DataRegIndex & (Size ? 0x3F : 0x3C)];
uint16_t* Offset = (uint16_t*)((char*)&GPRs[CurrentThread][0] + OffsetIndex * 2);
uint32_t L1Addr = GPRs[CurrentThread][AddrRegIndex] * 16 + *Offset;

// Auto-increment
switch (AutoIncSpec) { /* same as LOADIND */ }

// Write to L1
switch (Size) {
    case 0: memcpy((void*)(L1Addr & ~15), GPR, 16); break;  // 16B from 4 GPRs
    case 1: *(uint32_t*)(L1Addr & ~3)  = *GPR;      break;  // 32-bit
    case 2: *(uint16_t*)(L1Addr & ~1)  = (uint16_t)*GPR; break;  // 16-bit
    case 3: *(uint8_t*)L1Addr          = (uint8_t)*GPR;  break;  // 8-bit
}
```

<a id="gpr-and-dma-instructions--mmio-mode-memhiersel0-sizesel1-gpr--mmio-register"></a>
##### MMIO Mode (`MemHierSel=0, SizeSel=1`): GPR → MMIO Register

Always a 32-bit write to the `0xFFB_____` address range (Tensix MMIO window, lower bound `0xFFB11000`).

```c
uint16_t* Offset = (uint16_t*)((char*)&GPRs[CurrentThread][0] + OffsetIndex * 2);
uint32_t Addr = GPRs[CurrentThread][AddrRegIndex] + (*Offset >> 4);
Addr = 0xFFB00000 + (Addr & 0x000FFFFC);
*(uint32_t*)Addr = GPRs[CurrentThread][DataRegIndex];
// then apply AutoIncSpec to Offset
```

<a id="gpr-and-dma-instructions--src-mode-memhiersel0-sizesel0-2gpr--srcasrcb"></a>
##### Src Mode (`MemHierSel=0, SizeSel=0`): 2×GPR → SrcA/SrcB

Bit [21] (`RegSizeSel`) selects SrcA (0) or SrcB (1). Writes 4×BF16 values extracted from two consecutive GPRs into the FPU source register file. Waits on bank ownership semaphore. Rarely used — for software-feeding matrix input data.

**Performance:** >= 3 cycles (all modes).

**Common usage (L1 mode — writing tile header from packer):**
```c
// Write 16B tile header from GPRs to output L1 address
TTI_STOREIND(1, 0, p_ind::LD_16B, LO_16(0), p_ind::INC_NONE,
             p_gpr_pack::TILE_HEADER, p_gpr_pack::OUTPUT_ADDR);
```


<a id="gpr-and-dma-instructions--backend-configuration-model"></a>
### Backend Configuration Model

Before describing the Config Unit instructions, here's the data they operate on. Two distinct configuration spaces exist:

```c
uint32_t Config[2][CFG_STATE_SIZE * 4];                          // thread-agnostic, two banks
struct {uint16_t Value, Padding[7];} ThreadConfig[3][THD_STATE_SIZE]; // per-thread, one bank each
```

Both are mapped contiguously at `TENSIX_CFG_BASE` (`0xFFEF0000`, 64 KiB).

**Config** — Thread-agnostic, double-buffered. The active bank is selected by `ThreadConfig[CurrentThread].CFG_STATE_ID_StateID`. Holds unpack tile descriptors, pack config, ALU formats, ADDR_MOD slots, packer output addresses, stride configs, etc. Writes to indices `>= GLOBAL_CFGREG_BASE_ADDR32` write to *both* banks simultaneously.

**ThreadConfig** — Per-thread, single-banked. Holds thread-specific fields like `CFG_STATE_ID` (bank selector), dest register offsets, unpack context config, clock gater control. Only writable by `SETC16`; RISC-V `sw` cannot write ThreadConfig.

The `cfg_defines.h` file defines `Name_ADDR32`, `Name_MASK`, `Name_SHAMT` constants for both spaces. The `// Registers for THREAD` section indexes ThreadConfig; all other sections index Config.

| | Config (thread-agnostic) | ThreadConfig (per-thread) |
|---|---|---|
| **Tensix write** | WRCFG, RMWCIB, REG2FLOP | SETC16 only |
| **Tensix read** | RDCFG, various implicit | Various implicit only |
| **RISC-V write** | `sw` only (with ordering hazards) | Cannot write directly |
| **RISC-V read** | `lw`/`lh`/`lb` | `lw`/`lh`/`lb` |

**Special side effects on write:**
- Writing anything to `Config[i][STATE_RESET_EN_ADDR32]` (except via RMWCIB) zeros all non-global config in that bank.
- Writing to `Config.PRNG_SEED_Seed_Val_ADDR32` reseeds all PRNGs.
- Writing to `ThreadConfig[i][CG_CTRL_EN_*]` or `[CG_CTRL_KICK_*]` immediately affects clock gaters.


<a id="gpr-and-dma-instructions--configuration-unit-instructions"></a>
### Configuration Unit Instructions

The Configuration Unit handles all config register reads and writes. It accesses the same GPRs as the Scalar Unit. Key throughput rules:

- **SETC16** has its own IPC group: up to 3 per cycle (one per thread), independent of everything else.
- **All other instructions** (WRCFG, RDCFG, RMWCIB, RISCV requests, Mover requests) share a single `Config` IPC group with sustained throughput of at most 1 per cycle. Excessive WRCFG from one thread can starve RDCFG/RMWCIB from other threads and delay RISC-V config accesses.

<a id="gpr-and-dma-instructions--wrcfg--write-gpr-to-config-opcode-0xb0"></a>
#### WRCFG — Write GPR to Config (opcode 0xB0)

Copies 32 or 128 bits from a GPR to `Config`.

**Encoding:**
```
[31:24] = 0xB0
[21:16] = GprAddress  (6 bits — which GPR provides the data)
[15]    = wr128b      (0 = 32-bit write, 1 = 128-bit write)
[10:0]  = CfgReg      (11 bits — config register index, matches Name_ADDR32)
```

```c
#define TT_OP_WRCFG(GprAddress, wr128b, CfgReg) \
    TT_OP(0xb0, (((GprAddress) << 16) + ((wr128b) << 15) + ((CfgReg) << 0)))
```

**Functional model:**
```c
uint1_t StateID = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID;

if (Is128Bit) {
    // InputReg aligned to 4-GPR boundary; writes 4 consecutive config words
    memcpy(&Config[StateID][CfgIndex & ~3], &GPRs[CurrentThread][InputReg & ~3], 16);
} else {
    Config[StateID][CfgIndex] = GPRs[CurrentThread][InputReg];
}
```

**Performance:** 2 cycles, fully pipelined (one per cycle). The issuing thread is not blocked during the 2nd cycle. **The instruction immediately after WRCFG must not consume the config just written** — insert a NOP.

<a id="gpr-and-dma-instructions--rdcfg--read-config-to-gpr-opcode-0xb1"></a>
#### RDCFG — Read Config to GPR (opcode 0xB1)

Reads 32 bits from `Config` into a GPR. Cannot read ThreadConfig.

**Encoding:**
```
[31:24] = 0xB1
[23:16] = GprAddress  (8 bits — but only low 6 used for GPR index)
[15:0]  = CfgReg      (16 bits — but only low 11 used for config index)
```

```c
#define TT_OP_RDCFG(GprAddress, CfgReg) \
    TT_OP(0xb1, (((GprAddress) << 16) + ((CfgReg) << 0)))
```

**Functional model:**
```c
uint1_t StateID = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID;
GPRs[CurrentThread][ResultReg] = Config[StateID][CfgIndex];
```

**Performance:** At least 2 cycles. The GPR result is not available immediately — the instruction(s) after RDCFG must not read the destination GPR. Use `STALLWAIT(STALL_CFG, CFGEXU)` after issuing RDCFG(s) to ensure the result has landed before consuming it.

**Wormhole B0 hardware bug:** If multiple threads issue RDCFG on the same cycle, all but one are silently dropped. Software must ensure single-thread RDCFG. Blackhole does not have this bug — RDCFG is fully pipelined there (one per cycle, non-blocking, but still needs a stall before consuming the GPR result).

<a id="gpr-and-dma-instructions--setc16--write-16-bit-immediate-to-threadconfig-opcode-0xb2"></a>
#### SETC16 — Write 16-bit immediate to ThreadConfig (opcode 0xB2)

The **only instruction that can write ThreadConfig**. Writes a 16-bit immediate to one entry in the current thread's ThreadConfig bank.

**Encoding:**
```
[31:24] = 0xB2
[23:16] = CfgIndex    (8 bits — indexes ThreadConfig, matches "Registers for THREAD" Name_ADDR32)
[15:0]  = NewValue    (16 bits — immediate value)
```

```c
#define TT_OP_SETC16(setc16_reg, setc16_value) \
    TT_OP(0xb2, (((setc16_reg) << 16) + ((setc16_value) << 0)))
```

**Functional model:**
```c
ThreadConfig[CurrentThread][CfgIndex].Value = NewValue;
```

It always writes to the **current thread's** bank — there is no cross-thread ThreadConfig access. The 16-bit value replaces the entire `Value` field of the ThreadConfig entry (each entry is 16 bits of value + padding).

**Performance:** 1 cycle. Up to 3 SETC16 instructions can execute per cycle (one from each thread) because it has its own IPC group, independent of the Config pipeline.

**Common uses:**
```c
// Switch active config bank (double-buffering)
TT_SETC16(CFG_STATE_ID_StateID_ADDR32, new_state_id);

// Set math dest offset
TT_SETC16(DEST_TARGET_REG_CFG_MATH_Offset_ADDR32, dst_index);

// Set unpack config context
TT_SETC16(UNPACK_MISC_CFG_CfgContextOffset_0_ADDR32, 0x0104);
```

**Blackhole scheduling restriction:** After reset, `SETC16(CFG_STATE_ID_StateID_ADDR32, x)` must be executed once before any other config-bank-dependent instruction. Also, within a fused instruction bundle, instructions after a `CFG_STATE_ID` write must not depend on the new value.

<a id="gpr-and-dma-instructions--rmwcib0123--read-modify-write-config-byte-opcodes-0xb30xb6"></a>
#### RMWCIB0/1/2/3 — Read-Modify-Write Config Byte (opcodes 0xB3–0xB6)

Atomic read-modify-write on a single byte of `Config`. The digit suffix (0/1/2/3) selects which byte within the 32-bit config word to modify.

**Encoding (same for all four, opcode differs):**
```
[31:24] = 0xB3 (RMWCIB0), 0xB4 (RMWCIB1), 0xB5 (RMWCIB2), 0xB6 (RMWCIB3)
[23:16] = Mask          (8 bits — which bits to modify)
[15:8]  = NewValue      (8 bits — new bit values)
[7:0]   = CfgRegAddr    (8 bits — config register index, matches Name_ADDR32)
```

```c
#define TT_OP_RMWCIB0(Mask, Data, CfgRegAddr) TT_OP(0xb3, (((Mask)<<16)+((Data)<<8)+((CfgRegAddr)<<0)))
#define TT_OP_RMWCIB1(Mask, Data, CfgRegAddr) TT_OP(0xb4, (((Mask)<<16)+((Data)<<8)+((CfgRegAddr)<<0)))
#define TT_OP_RMWCIB2(Mask, Data, CfgRegAddr) TT_OP(0xb5, (((Mask)<<16)+((Data)<<8)+((CfgRegAddr)<<0)))
#define TT_OP_RMWCIB3(Mask, Data, CfgRegAddr) TT_OP(0xb6, (((Mask)<<16)+((Data)<<8)+((CfgRegAddr)<<0)))
```

**Functional model:**
```c
uint1_t StateID = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID;
uint8_t* ByteAddr = (uint8_t*)&Config[StateID][CfgRegAddr] + Index1;  // Index1 = opcode digit (0-3)
atomic {
    uint8_t OldValue = *ByteAddr;
    *ByteAddr = (NewValue & Mask) | (OldValue & ~Mask);
}
```

The formula is: **bits where Mask=1 get NewValue; bits where Mask=0 keep OldValue**. This is the standard RMW pattern `(new & mask) | (old & ~mask)`.

**Performance:** 1 cycle (but may wait at Wait Gate if Config pipeline is busy).

**LLK wrapper** — `cfg_reg_rmw_tensix<CfgAddr32, Shamt, Mask>(val)` in `ckernel.h` decomposes a 32-bit mask+value write into up to 4 RMWCIB calls (one per non-zero byte lane):
```c
// Only emits RMWCIB for byte lanes where the mask is non-zero
if (mask_b0) TT_RMWCIB0(mask_b0, data_b0, CfgAddr32);
if (mask_b1) TT_RMWCIB1(mask_b1, data_b1, CfgAddr32);
if (mask_b2) TT_RMWCIB2(mask_b2, data_b2, CfgAddr32);
if (mask_b3) TT_RMWCIB3(mask_b3, data_b3, CfgAddr32);
```


<a id="gpr-and-dma-instructions--synchronization-setdmareg--wrcfg"></a>
### Synchronization: SETDMAREG → WRCFG

The Scalar Unit and Configuration Unit are independent asynchronous backend units. Software must synchronize between them. The standard pattern:

```c
// 1. Load 32-bit constant into GPR via two 16-bit halves
TT_SETDMAREG(0, LOWER_HALFWORD(value), 0, LO_16(p_gpr_pack::TMP0));
TT_SETDMAREG(0, UPPER_HALFWORD(value), 0, HI_16(p_gpr_pack::TMP0));

// 2. Stall Config Unit until Scalar Unit finishes
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::THCON);
//             B7=0x80: block CFG   C0=0x001: wait while ThCon busy

// 3. Copy GPR to config register
TTI_WRCFG(p_gpr_pack::TMP0, p_cfg::WRCFG_32b, TARGET_ADDR32);

// 4. NOPs — WRCFG takes 2 cycles, next insn must not read this config
TTI_NOP;
TTI_NOP;
```

<a id="gpr-and-dma-instructions--risc-v-direct-write-alternative"></a>
#### RISC-V Direct Write Alternative

BRISC can write GPRs directly via stores to `0xFFE00000`, but must ensure the write completes before pushing a Tensix instruction that reads the GPR. Three approaches:
1. Use SETDMAREG instead (preferred).
2. Push a STALLWAIT with condition C13 before the consuming instruction.
3. Use a load-back fence: `sw` to GPR, `lw` from same address, consume result, then `sw` to push the Tensix instruction.


<a id="gpr-and-dma-instructions--examples-from-real-disassemblies"></a>
### Examples from Real Disassemblies

<a id="gpr-and-dma-instructions--firmware-gpr-init-fw_trisc2s"></a>
#### Firmware GPR Init (fw_trisc2.S)

TRISC2 firmware zeroes the T0 GPR file at boot:

```asm
# from disasms/rvir/fw_trisc2.S — zero_gprs
    lui  a5, 0xffe00          # a5 = 0xFFE00000 (GPR base)
    addi a4, a5, 256          # a4 = 0xFFE00100 (end of 64 GPRs)
zero_gprs:
    sw   zero, 0(a5)          # *a5 = 0
    addi a5, a5, 4            # next GPR
    bne  a5, a4, zero_gprs    # loop until all 64 zeroed
```

<a id="gpr-and-dma-instructions--setdmareg--wrcfg-sequence-add1_trisc2s"></a>
#### SETDMAREG → WRCFG Sequence (add1_trisc2.S)

Pack thread loading constants into GPRs 28–29, then writing to config:

```asm
# Build SETDMAREG instructions and push them to the T2 instruction FIFO (s0 = 0xFFE60000)
    lui  a4, 0x45000          # opcode 0x45, payload=0x0000
    addi a4, a4, 56           # RegIndex16b = 56 = LO_16(28)
    sw   a4, 0(s0)            # push: SETDMAREG(0, 0x0000, 0, LO_16(28))

    lui  a4, 0x45002          # opcode 0x45, payload=0x0002
    addi a4, a4, 57           # RegIndex16b = 57 = HI_16(28)
    sw   a4, 0(s0)            # push: SETDMAREG(0, 0x0002, 0, HI_16(28))

    lui  a4, 0x45020          # opcode 0x45, payload=0x0020
    addi a4, a4, 58           # RegIndex16b = 58 = LO_16(29)
    sw   a4, 0(s0)            # push: SETDMAREG(0, 0x0020, 0, LO_16(29))

    lui  a4, 0x45080          # opcode 0x45, payload=0x0080
    addi a4, a4, 59           # RegIndex16b = 59 = HI_16(29)
    sw   a4, 0(s0)            # push: SETDMAREG(0, 0x0080, 0, HI_16(29))

    # Inline Tensix: wait for Scalar Unit to finish
    TT_STALLWAIT 0x400001     # STALL_CFG, THCON

    # Inline Tensix: copy GPRs 28-29 to config
    TT_WRCFG 0x1c000c        # GPR 28 → Config[12], 32-bit
    TT_WRCFG 0x1d000d        # GPR 29 → Config[13], 32-bit
    TT_NOP
    TT_NOP
```

Note: The SETDMAREG instructions are built manually with `lui`+`addi` and pushed to the instruction FIFO via `sw` to `0xFFE60000`, while STALLWAIT/WRCFG/NOP appear as inline Tensix instructions in the rvir disassembly.

<a id="gpr-and-dma-instructions--risc-v-direct-gpr-write-add1_trisc2s"></a>
#### RISC-V Direct GPR Write (add1_trisc2.S)

TRISC2 also writes GPRs directly via MMIO stores, bypassing SETDMAREG entirely:

```asm
    lui  s2, 0xffe00          # s2 = GPR base for this thread
    lui  a4, 0x1
    addi a4, a4, -2048        # a4 = 0x800
    sw   a4, 64(s2)           # GPR[16] = 0x800     (offset 64 = GPR index 16)
    sw   zero, 68(s2)         # GPR[17] = 0
    sw   zero, 72(s2)         # GPR[18] = 0
    sw   zero, 76(s2)         # GPR[19] = 0
    lw   a4, 76(s2)           # load-back fence: read GPR[19]
    sw   a4, 76(s2)           # consume result before pushing Tensix insn
```


<a id="gpr-and-dma-instructions--encoding-quick-reference"></a>
### Encoding Quick Reference

<a id="gpr-and-dma-instructions--scalar-unit-thcon--gpr-operations"></a>
#### Scalar Unit (ThCon) — GPR operations

| Instruction | Opcode | Key Fields |
|---|---|---|
| SETDMAREG | 0x45 | `[23:22]` SigSelSize, `[21:8]` Payload, `[7]` SignalMode, `[6:0]` RegIndex16b |
| LOADIND | 0x49 | `[23:22]` SizeSel, `[21:14]` OffsetIndex, `[13:12]` AutoIncSpec, `[11:6]` DataReg, `[5:0]` AddrReg |
| ADDDMAREG | 0x58 | `[23]` OpBisConst, `[17:12]` Result, `[11:6]` OpB, `[5:0]` OpA |
| SUBDMAREG | 0x59 | (same as ADDDMAREG) |
| MULDMAREG | 0x5A | (same as ADDDMAREG) |
| DMANOP | 0x60 | (no fields) |
| STOREIND | 0x66 | `[23]` MemHierSel, `[22]` SizeSel, `[21]` RegSizeSel, `[20:14]` OffsetIdx, `[13:12]` AutoInc, `[11:6]` DataReg, `[5:0]` AddrReg |

<a id="gpr-and-dma-instructions--configuration-unit--config-register-operations"></a>
#### Configuration Unit — Config register operations

| Instruction | Opcode | Key Fields |
|---|---|---|
| WRCFG | 0xB0 | `[21:16]` GprAddr, `[15]` wr128b, `[10:0]` CfgReg |
| RDCFG | 0xB1 | `[23:16]` GprAddr, `[15:0]` CfgReg |
| SETC16 | 0xB2 | `[23:16]` CfgIndex (ThreadConfig), `[15:0]` NewValue |
| RMWCIB0 | 0xB3 | `[23:16]` Mask, `[15:8]` Data, `[7:0]` CfgRegAddr |
| RMWCIB1 | 0xB4 | (same as RMWCIB0, targets byte 1) |
| RMWCIB2 | 0xB5 | (same as RMWCIB0, targets byte 2) |
| RMWCIB3 | 0xB6 | (same as RMWCIB0, targets byte 3) |


<a id="gpr-and-dma-instructions--isa-documentation-pointers"></a>
### ISA Documentation Pointers

| File | Content |
|---|---|
| **Scalar Unit** | |
| `tt-isa-documentation/.../ScalarUnit.md` | GPR model, access rules, instruction latency table |
| `tt-isa-documentation/.../SETDMAREG_Immediate.md` | SETDMAREG load mode functional model |
| `tt-isa-documentation/.../SETDMAREG_Special.md` | SETDMAREG signal/packer-state mode (all InputSource/ResultSize combos) |
| `tt-isa-documentation/.../ADDDMAREG.md` | Addition functional model |
| `tt-isa-documentation/.../MULDMAREG.md` | Multiply functional model, 16-bit truncation |
| `tt-isa-documentation/.../DMANOP.md` | NOP functional model |
| **Configuration Unit** | |
| `tt-isa-documentation/.../ConfigurationUnit.md` | IPC groups, pipeline stages, throughput rules, starvation bugs |
| `tt-isa-documentation/.../BackendConfiguration.md` | Config vs ThreadConfig model, address space, special side effects |
| `tt-isa-documentation/.../WRCFG.md` | Config write from GPR, 32b vs 128b, scheduling |
| `tt-isa-documentation/.../RDCFG.md` | Config read to GPR, WH multi-thread bug, BH pipelining |
| `tt-isa-documentation/.../SETC16.md` | ThreadConfig write, BH scheduling restrictions |
| `tt-isa-documentation/.../RMWCIB.md` | Read-modify-write byte, mask formula, all 4 variants |
| **LLK headers** | |
| `tt-llk/.../ckernel_gpr_map.h` | Named GPR constants |
| `tt-llk/.../ckernel_ops.h` | Instruction encoding macros |
| `tt-llk/.../ckernel_defs.h` | `LO_16`/`HI_16`/`LOWER_HALFWORD`/`UPPER_HALFWORD` macros |
| `tt-llk/.../ckernel.h` | `cfg_reg_rmw_tensix` wrapper, `flip_cfg_state_id` |
| **Indirect Memory Ops** | |
| `tt-isa-documentation/.../LOADIND.md` | LOADIND functional model (WormholeB0 dir, applies to Blackhole) |
| `tt-isa-documentation/.../STOREIND.md` | STOREIND dispatcher (WormholeB0 dir) |
| `tt-isa-documentation/.../STOREIND_L1.md` | STOREIND L1 mode |
| `tt-isa-documentation/.../STOREIND_MMIO.md` | STOREIND MMIO mode |
| `tt-isa-documentation/.../STOREIND_Src.md` | STOREIND SrcA/SrcB mode |
| `tt-llk/.../ckernel_instr_params.h` | `struct p_ind` (HIER_L1, INC_*, LD_* constants) |

<a id="additional-scalar-unit-instructions"></a>
## Additional Scalar Unit Instructions
<a id="additional-scalar-unit-instructions--additional-scalar-unit-instructions"></a>

Four additional Scalar Unit (ThCon) instructions operate on the GPR file. They are used infrequently in LLK kernels (~400–450 occurrences across 747 Blackhole ELFs) and are not needed for matmul or add1, but they appear in STALLWAIT block masks and must be modeled for completeness.

All four share the same execution characteristics as ADDDMAREG/MULDMAREG: they execute on the Scalar Unit (ThCon), which is fully serialized. They stall under STALLWAIT block bit B5 (`STALL_THCON`).


<a id="additional-scalar-unit-instructions--shiftdmareg--bitwise-shift-gpr-opcode-0x5c"></a>
### SHIFTDMAREG — Bitwise Shift GPR (opcode 0x5C)

Performs an unsigned bitwise shift (left or right) of one GPR by another GPR, or by a 5-bit immediate.

**Encoding:**
```
[31:24] = 0x5C
[23]    = OpBisConst  (0 = reg-reg, 1 = reg-immediate)
[20:18] = Mode        (3 bits — shift direction)
[17:12] = ResultRegIndex  (6 bits)
[11:6]  = OpBRegIndex     (6 bits — GPR index or 5-bit shift amount if OpBisConst=1)
[5:0]   = OpARegIndex     (6 bits — source GPR)
```

```c
#define TT_OP_SHIFTDMAREG(OpBisConst, OpSel, ResultRegIndex, OpBRegIndex, OpARegIndex) \
    TT_OP(0x5c, (((OpBisConst) << 23) + ((OpSel) << 18) + ((ResultRegIndex) << 12) \
               + ((OpBRegIndex) << 6) + ((OpARegIndex) << 0)))
```

**Modes:**
| Mode | Name | Operation |
|------|------|-----------|
| 0 | `SHIFTDMAREG_MODE_LEFT` | `Result = Left << Right` |
| 1 | `SHIFTDMAREG_MODE_RIGHT` | `Result = Left >> Right` (unsigned) |

**Functional model:**
```python
def SHIFTDMAREG(OpBisConst, mode, result_reg, right_reg_or_imm, left_reg):
    left_val = GPRs[CurrentThread][left_reg]
    if OpBisConst:
        right_val = right_reg_or_imm & 0x1F    # 5-bit immediate
    else:
        right_val = GPRs[CurrentThread][right_reg_or_imm] & 0x1F

    if mode == 0:    # LEFT
        result = (left_val << right_val) & 0xFFFFFFFF
    elif mode == 1:  # RIGHT
        result = left_val >> right_val
    else:
        raise UndefinedBehaviour()

    GPRs[CurrentThread][result_reg] = result
```

**Performance:** 3 cycles (immediate variant, or both regs in same aligned group of 4 GPRs), 4 cycles otherwise.


<a id="additional-scalar-unit-instructions--bitwopdmareg--bitwise-andorxor-on-gpr-opcode-0x5b"></a>
### BITWOPDMAREG — Bitwise AND/OR/XOR on GPR (opcode 0x5B)

Performs a bitwise AND, OR, or XOR between two GPRs, or between a GPR and a 6-bit immediate.

**Encoding:**
```
[31:24] = 0x5B
[23]    = OpBisConst  (0 = reg-reg, 1 = reg-immediate)
[20:18] = OpSel       (3 bits — operation select)
[17:12] = ResultRegIndex  (6 bits)
[11:6]  = OpBRegIndex     (6 bits — GPR index or 6-bit constant)
[5:0]   = OpARegIndex     (6 bits — source GPR)
```

```c
#define TT_OP_BITWOPDMAREG(OpBisConst, OpSel, ResultRegIndex, OpBRegIndex, OpARegIndex) \
    TT_OP(0x5b, (((OpBisConst) << 23) + ((OpSel) << 18) + ((ResultRegIndex) << 12) \
               + ((OpBRegIndex) << 6) + ((OpARegIndex) << 0)))
```

**Modes:**
| OpSel | Name | Operation |
|-------|------|-----------|
| 0 | `BITWOPDMAREG_MODE_AND` | `Result = A & B` |
| 1 | `BITWOPDMAREG_MODE_OR` | `Result = A \| B` |
| 2 | `BITWOPDMAREG_MODE_XOR` | `Result = A ^ B` |

**Functional model:**
```python
def BITWOPDMAREG(OpBisConst, mode, result_reg, right_reg_or_imm, left_reg):
    left_val = GPRs[CurrentThread][left_reg]
    if OpBisConst:
        right_val = right_reg_or_imm & 0x3F    # 6-bit immediate
    else:
        right_val = GPRs[CurrentThread][right_reg_or_imm]

    if mode == 0:    result = left_val & right_val
    elif mode == 1:  result = left_val | right_val
    elif mode == 2:  result = left_val ^ right_val
    else:            raise UndefinedBehaviour()

    GPRs[CurrentThread][result_reg] = result
```

**Performance:** 3 cycles (immediate variant, or both regs in same aligned group of 4 GPRs), 4 cycles otherwise.


<a id="additional-scalar-unit-instructions--cmpdmareg--compare-gprs-opcode-0x5d"></a>
### CMPDMAREG — Compare GPRs (opcode 0x5D)

Unsigned comparison (GT, LT, EQ) between two GPRs, or between a GPR and a 6-bit immediate. Result is 0 or 1.

**Encoding:**
```
[31:24] = 0x5D
[23]    = OpBisConst  (0 = reg-reg, 1 = reg-immediate)
[20:18] = OpSel       (3 bits — comparison mode)
[17:12] = ResultRegIndex  (6 bits)
[11:6]  = OpBRegIndex     (6 bits — GPR index or 6-bit constant)
[5:0]   = OpARegIndex     (6 bits — source GPR)
```

```c
#define TT_OP_CMPDMAREG(OpBisConst, OpSel, ResultRegIndex, OpBRegIndex, OpARegIndex) \
    TT_OP(0x5d, (((OpBisConst) << 23) + ((OpSel) << 18) + ((ResultRegIndex) << 12) \
               + ((OpBRegIndex) << 6) + ((OpARegIndex) << 0)))
```

**Modes:**
| OpSel | Name | Operation |
|-------|------|-----------|
| 0 | `CMPDMAREG_MODE_GT` | `Result = (A > B) ? 1 : 0` |
| 1 | `CMPDMAREG_MODE_LT` | `Result = (A < B) ? 1 : 0` |
| 2 | `CMPDMAREG_MODE_EQ` | `Result = (A == B) ? 1 : 0` |

**Functional model:**
```python
def CMPDMAREG(OpBisConst, mode, result_reg, right_reg_or_imm, left_reg):
    left_val = GPRs[CurrentThread][left_reg]
    if OpBisConst:
        right_val = right_reg_or_imm & 0x3F    # 6-bit unsigned immediate
    else:
        right_val = GPRs[CurrentThread][right_reg_or_imm]

    if mode == 0:    result = 1 if left_val > right_val else 0
    elif mode == 1:  result = 1 if left_val < right_val else 0
    elif mode == 2:  result = 1 if left_val == right_val else 0
    else:            raise UndefinedBehaviour()

    GPRs[CurrentThread][result_reg] = result
```

All comparisons are **unsigned**. Performance: same as SHIFTDMAREG/BITWOPDMAREG.


<a id="additional-scalar-unit-instructions--flushdma--occupy-scalar-unit-until-conditions-met-opcode-0x46"></a>
### FLUSHDMA — Occupy Scalar Unit Until Conditions Met (opcode 0x46)

Stalls the issuing thread **and all other threads** trying to use the Scalar Unit until selected conditions are met. In almost every case, STALLWAIT should be preferred — it waits without blocking other threads' Scalar Unit access.

**Encoding:**
```
[31:24] = 0x46
[3:0]   = ConditionMask  (4 bits — conditions C0–C3)
```

```c
#define TT_OP_FLUSHDMA(FlushSpec) TT_OP(0x46, (((FlushSpec) << 0)))
```

**Condition mask:**

| Bit | Condition | Keep waiting if... |
|-----|-----------|-------------------|
| C0 | Scalar Unit memory | The Scalar Unit has outstanding memory requests for the current thread |
| C1 | Unpacker 0 | The current thread has an instruction in any stage of Unpacker 0's pipeline |
| C2 | Unpacker 1 | The current thread has an instruction in any stage of Unpacker 1's pipeline |
| C3 | Packer 0 | The current thread has an instruction in any stage of Packer 0's pipeline |

If `ConditionMask == 0`, it defaults to `0xF` (all conditions). The instruction waits until **all** selected conditions are simultaneously met (i.e., none of the "keep waiting" conditions are true). These condition bits coincide exactly with the low four bits of STALLWAIT's condition mask.

**Functional model:**
```python
def FLUSHDMA(condition_mask):
    if condition_mask == 0:
        condition_mask = 0xF

    # Block the Scalar Unit for all threads until conditions are met
    while any_selected_condition_indicates_busy(condition_mask, CurrentThread):
        wait()  # stalls this thread AND any other thread trying to use ThCon
```

**Performance:** At least 2 cycles, plus however long the wait takes.

**Emulator note:** For a synchronous emulator, FLUSHDMA is functionally equivalent to STALLWAIT with block mask `0x20` (STALL_THCON) and the same condition bits. The distinction (blocking other threads' ThCon access) only matters for cycle-accurate timing.


<a id="additional-scalar-unit-instructions--autottsync-classification"></a>
### AutoTTSync Classification

All four instructions share the same STALLWAIT behavior:

| Class | Instructions | Behavior |
|-------|-------------|----------|
| 0 | ADDDMAREG, SUBDMAREG, MULDMAREG, **BITWOPDMAREG**, **SHIFTDMAREG**, **CMPDMAREG**, SETDMAREG | Read and write Tensix GPRs |
| 7 | **FLUSHDMA** | Write TDMA-RISC state (synchronization barrier) |


<a id="additional-scalar-unit-instructions--encoding-quick-reference"></a>
### Encoding Quick Reference

| Instruction | Opcode | Field Layout |
|---|---|---|
| BITWOPDMAREG | 0x5B | `[23]` OpBisConst, `[20:18]` OpSel, `[17:12]` Result, `[11:6]` OpB, `[5:0]` OpA |
| SHIFTDMAREG | 0x5C | (same — but immediate is 5-bit, not 6-bit) |
| CMPDMAREG | 0x5D | (same as BITWOPDMAREG) |
| FLUSHDMA | 0x46 | `[3:0]` ConditionMask |


<a id="additional-scalar-unit-instructions--source-references"></a>
### Source References

| Source | Path |
|--------|------|
| ISA functional models | `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/{SHIFTDMAREG,BITWOPDMAREG,CMPDMAREG,FLUSHDMA}.md` |
| Blackhole C macros | `tt-llk/tt_llk_blackhole/common/inc/ckernel_ops.h` |
| Blackhole assembly YAML | `tt-llk/tt_llk_blackhole/instructions/assembly.yaml` |
| Python instruction encoders | `tt-exalens/ttexalens/hardware/blackhole/tensix_ops.py` |
| Instruction frequency data | `boop-docs/llk-sfpi/instruction-frequency-report.md` |
| AutoTTSync classes | `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/AutoTTSync.md` |

<a id="config-sync-instructions"></a>
## Configuration Unit and Sync Unit: Additional Instructions
<a id="config-sync-instructions--configuration-unit-and-sync-unit-additional-instructions"></a>

Four instructions that interact with the backend configuration registers and the NoC overlay stream system. CFGSHIFTMASK and STREAMWRCFG execute on the Configuration Unit; STREAMWAIT executes on the Sync Unit; REG2FLOP executes on the Scalar Unit (ThCon).


<a id="config-sync-instructions--cfgshiftmask--read-modify-write-config-via-scratch-register-opcode-0xb8"></a>
### CFGSHIFTMASK — Read-Modify-Write Config via Scratch Register (opcode 0xB8)

<a id="config-sync-instructions--overview"></a>
#### Overview

Performs a masked, rotated, ALU read-modify-write on a thread-agnostic `Config` register, using a value from one of the `SCRATCH_SEC[].val` configuration registers as the operand. This is more powerful than RMWCIB (which only does byte-granularity mask-and-set) — CFGSHIFTMASK can rotate, mask to arbitrary width, and apply one of 8 ALU operations.

Used 263 times across LLK ELFs, primarily in unpack tilize routines to update tile descriptor base addresses.

<a id="config-sync-instructions--encoding"></a>
#### Encoding

```
[31:24] = 0xB8
[23]    = MaskMode        (1 bit — 0=clear mask region first, 1=don't clear)
[22:20] = AluMode         (3 bits — ALU operation)
[19:15] = MaskWidth       (5 bits — mask is (2 << MaskWidth) - 1, i.e., MaskWidth+1 bits wide)
[14:10] = RotateAmt       (5 bits — circular right shift amount)
[9:8]   = ScratchIndex    (2 bits — which SCRATCH_SEC, or 3=use thread ID)
[7:0]   = CfgIndex        (8 bits — Config register ADDR32 index)
```

```c
#define TT_OP_CFGSHIFTMASK(disable_mask_on_old_val, operation, mask_width, \
                            right_cshift_amt, scratch_sel, CfgReg) \
    TT_OP(0xb8, (((disable_mask_on_old_val) << 23) + ((operation) << 20) \
               + ((mask_width) << 15) + ((right_cshift_amt) << 10) \
               + ((scratch_sel) << 8) + ((CfgReg) << 0)))
```

<a id="config-sync-instructions--alu-modes"></a>
#### ALU Modes

| AluMode | Operation |
|---------|-----------|
| 0 | `CfgValue \|= ScratchValue` (OR) |
| 1 | `CfgValue &= ScratchValue` (AND) |
| 2 | `CfgValue ^= ScratchValue` (XOR) |
| 3 | `CfgValue += ScratchValue` (ADD) |
| 4 | `CfgValue \|= ~ScratchValue` (OR-NOT) |
| 5 | `CfgValue &= ~ScratchValue` (AND-NOT) |
| 6 | `CfgValue ^= ~ScratchValue` (XOR-NOT) |
| 7 | `CfgValue -= ScratchValue` (SUB) |

<a id="config-sync-instructions--functional-model"></a>
#### Functional Model

```python
def CFGSHIFTMASK(mask_mode, alu_mode, mask_width, rotate_amt, scratch_index, cfg_index):
    # Select scratch register value
    if scratch_index < 3:
        scratch_val = Config.SCRATCH_SEC[scratch_index].val
    else:
        scratch_val = Config.SCRATCH_SEC[CurrentThread].val

    # Build mask and apply rotation
    mask_val = (2 << mask_width) - 1                     # MaskWidth+1 bits of 1s
    scratch_val = rotr32(scratch_val & mask_val, rotate_amt)

    # Read current config value
    state_id = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID
    cfg_val = Config[state_id][cfg_index]

    # Optionally clear the mask region in the old value
    if mask_mode == 0:
        cfg_val &= ~rotr32(mask_val, rotate_amt)

    # Apply ALU operation
    if   alu_mode == 0: cfg_val |=   scratch_val
    elif alu_mode == 1: cfg_val &=   scratch_val
    elif alu_mode == 2: cfg_val ^=   scratch_val
    elif alu_mode == 3: cfg_val  +=  scratch_val
    elif alu_mode == 4: cfg_val |=  ~scratch_val & 0xFFFFFFFF
    elif alu_mode == 5: cfg_val &=  ~scratch_val & 0xFFFFFFFF
    elif alu_mode == 6: cfg_val ^=  ~scratch_val & 0xFFFFFFFF
    elif alu_mode == 7: cfg_val  -=  scratch_val

    Config[state_id][cfg_index] = cfg_val & 0xFFFFFFFF

def rotr32(val, amount):
    amount &= 31
    return ((val >> amount) | (val << (32 - amount))) & 0xFFFFFFFF
```

<a id="config-sync-instructions--performance-and-scheduling"></a>
#### Performance and Scheduling

- 2 cycles, not pipelined (can start one every other cycle)
- The issuing thread is **not** blocked — it can start its next instruction during the 2nd cycle
- The instruction immediately after CFGSHIFTMASK must **not** consume the config value just written. Insert a NOP if needed. This restriction does not apply if the next instruction is itself a Configuration Unit instruction (the pipeline rules handle it).

<a id="config-sync-instructions--llk-usage-example"></a>
#### LLK Usage Example

```c
// From llk_unpack_tilize.h — update tile descriptor base address
TTI_CFGSHIFTMASK(1, 0b011, 32-1, 0, 0b11, THCON_SEC0_REG3_Base_address_ADDR32);
// MaskMode=1 (don't clear), AluMode=3 (ADD), MaskWidth=31 (full 32 bits),
// RotateAmt=0, ScratchIndex=3 (use thread ID), CfgReg=THCON_SEC0_REG3 base address
```


<a id="config-sync-instructions--reg2flop--move-from-gprs-to-thcon-configuration-opcode-0x48"></a>
### REG2FLOP — Move from GPRs to THCON Configuration (opcode 0x48)

<a id="config-sync-instructions--overview-1"></a>
#### Overview

Uses the Scalar Unit (ThCon) to write from the current thread's GPRs into `THCON_*` backend configuration fields. The target is always the `THCON_*` portion of the configuration register space — this instruction **cannot** address other configuration targets. For a more general configuration write (not limited to `THCON_*` fields), use `WRCFG` instead.

Used 414 times across LLK ELFs, heavily in unpack/pack routines (tilize, untilize, matmul).

> **ISA source:** `REG2FLOP_Configuration.md` in the WormholeB0 TensixCoprocessor ISA documentation.

<a id="config-sync-instructions--encoding-1"></a>
#### Encoding

```
TT_REG2FLOP(/* u2 */ SizeSel, 0, 0, 0, /* u7 */ ThConCfgIndex, /* u6 */ InputReg)
```

Fields other than `SizeSel`, `ThConCfgIndex`, and `InputReg` are reserved (must be zero) in the configuration variant documented by the ISA.

<a id="config-sync-instructions--sizesel-values"></a>
#### SizeSel Values

| SizeSel | Transfer width |
|---------|----------------|
| 0       | 128-bit (16 bytes): copies 4 consecutive GPRs starting at `InputReg & ~3` into the 4 consecutive THCON config words starting at `ThConCfgIndex & ~3` |
| 1–3     | 32-bit: copies `GPRs[CurrentThread][InputReg]` into `ThConCfgBase[ThConCfgIndex]` |

No 8-bit or 16-bit write modes are defined for this instruction variant in the ISA.

<a id="config-sync-instructions--functional-model-1"></a>
#### Functional Model

> Source: `REG2FLOP_Configuration.md` (WormholeB0 ISA)

```c
if (ThConCfgIndex >= (GLOBAL_CFGREG_BASE_ADDR32 - THCON_CFGREG_BASE_ADDR32)) {
  // Can only write to backend configuration whose field name starts with THCON_.
  // See WRCFG for a similar instruction without this limitation.
  UndefinedBehaviour();
}

uint1_t StateID = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID;
uint32_t* ThConCfgBase = &Config[StateID][THCON_CFGREG_BASE_ADDR32];

if (SizeSel == 0) {
  // 128-bit configuration write
  memcpy(&ThConCfgBase[ThConCfgIndex & ~3], &GPRs[CurrentThread][InputReg & ~3], 16);
} else {
  // 32-bit configuration write
  ThConCfgBase[ThConCfgIndex] = GPRs[CurrentThread][InputReg];
}
```

<a id="config-sync-instructions--emulator-note"></a>
#### Emulator Note

REG2FLOP (configuration variant) writes only to `THCON_*` configuration fields, routed through `Config[StateID]` offset by `THCON_CFGREG_BASE_ADDR32`. Indices at or above `GLOBAL_CFGREG_BASE_ADDR32 - THCON_CFGREG_BASE_ADDR32` are undefined behaviour per ISA. If the emulator models unpack/pack config through `Config`/`ThreadConfig` registers, map `ThConCfgIndex` to the corresponding `THCON_*` field offset; there is no separate "flop" target space for this variant.

<a id="config-sync-instructions--performance"></a>
#### Performance

Typically two cycles; longer if Configuration Unit instructions from any Tensix thread or baby RISCV are contending for write bandwidth to THCON configuration. The Scalar Unit (ThCon) is occupied for the entire duration and the issuing thread is blocked until completion.

Stall bits: STALL_THCON (B5).


<a id="config-sync-instructions--streamwait--wait-on-noc-overlay-stream-condition-opcode-0xa7"></a>
### STREAMWAIT — Wait on NoC Overlay Stream Condition (opcode 0xA7)

<a id="config-sync-instructions--overview-2"></a>
#### Overview

A Blackhole-new instruction. Sets a persistent "wait condition" on the current thread keyed to a NoC overlay stream register. The thread can continue executing until it reaches an instruction type that is blocked by the block mask; at that point, execution pauses until the selected stream condition is met.

Unlike STALLWAIT (which stalls immediately), STREAMWAIT sets a latched condition that only triggers when a blocked instruction is encountered. This allows non-blocked work to continue in the meantime.

Used 235 times across LLK ELFs. Only exists on Blackhole (not Wormhole B0).

<a id="config-sync-instructions--encoding-2"></a>
#### Encoding

```
[31:24] = 0xA7
[23:15] = stall_res       (9 bits — block mask, same bits as STALLWAIT block mask B0–B8)
[14:4]  = target_value    (11 bits — low 10/11 bits of the target comparison value)
[3]     = target_sel      (1 bit — 0=compare phase, 1=compare num_msgs)
[1:0]   = wait_stream_sel (2 bits — selects one of 4 thread-private STREAM_ID_SYNC registers)
```

```c
#define TT_OP_STREAMWAIT(stall_res, target_value, target_sel, wait_stream_sel) \
    TT_OP(0xa7, (((stall_res) << 15) + ((target_value) << 4) + \
                  ((target_sel) << 3) + ((wait_stream_sel) << 0)))
```

<a id="config-sync-instructions--condition-index"></a>
#### Condition Index

| ConditionIndex | Condition | Keep blocking if... |
|---|---|---|
| 0 (C0) | Phase | `NOC_STREAM_READ_REG(StreamIndex, STREAM_CURR_PHASE_REG_INDEX) < TargetValue` |
| 1 (C1) | Num msgs | `NOC_STREAM_READ_REG(StreamIndex, STREAM_NUM_MSGS_RECEIVED_REG_INDEX) < TargetValue` |

Where `StreamIndex = ThreadConfig[CurrentThread].STREAM_ID_SYNC_SEC[StreamSelect].BankSel`.

The full target value is formed by combining the low bits from the instruction with high bits from ThreadConfig:
- C0: `TargetValue = (ThreadConfig[t].STREAMWAIT_PHASE_HI_Val << 10) | TargetValueLo`
- C1: `TargetValue = (ThreadConfig[t].STREAMWAIT_NUM_MSGS_HI_Val << 10) | TargetValueLo`

<a id="config-sync-instructions--block-mask"></a>
#### Block Mask

Same 9-bit block mask as STALLWAIT (B0–B8). If `BlockMask == 0`, it defaults to `1 << 6` (STALL_MATH). The block mask determines which instruction types are held until the condition is met.

<a id="config-sync-instructions--functional-model-2"></a>
#### Functional Model

```python
def STREAMWAIT(block_mask, target_value_lo, condition_index, stream_select):
    # Compute full target value
    if condition_index == 0:
        target = (ThreadConfig[CurrentThread].STREAMWAIT_PHASE_HI_Val << 10) | target_value_lo
    else:
        target = (ThreadConfig[CurrentThread].STREAMWAIT_NUM_MSGS_HI_Val << 10) | target_value_lo

    # Latch the wait condition into the Wait Gate
    if block_mask == 0:
        block_mask = 1 << 6   # default: block Math instructions

    WaitGate[CurrentThread].latch(
        opcode=STREAMWAIT,
        condition_mask=(1 << condition_index),
        target_value=target,
        stream_select=stream_select,
        block_mask=block_mask
    )
    # The wait condition takes effect immediately — subsequent instructions
    # of blocked types will stall until the stream register >= target_value.
    # There is a 1-cycle lag: even if the condition is already met,
    # the instruction immediately after STREAMWAIT is subject to the block
    # for at least 1 cycle.
```

<a id="config-sync-instructions--emulator-note-1"></a>
#### Emulator Note

For a synchronous emulator that does not model stream/overlay data movement, STREAMWAIT conditions will typically be immediately satisfied (stream registers are at their final values). The emulator should still decode the instruction and apply the block mask logic for correctness. If the emulator does model stream progress, the Wait Gate must evaluate the condition each time a blocked instruction type is encountered.

<a id="config-sync-instructions--performance-1"></a>
#### Performance

Executes on the Sync Unit. Stall bit: STALL_SYNC (B1).


<a id="config-sync-instructions--streamwrcfg--copy-stream-register-to-config-opcode-0xb7"></a>
### STREAMWRCFG — Copy Stream Register to Config (opcode 0xB7)

<a id="config-sync-instructions--overview-3"></a>
#### Overview

Reads one 32-bit register from a NoC overlay stream and writes it to a thread-agnostic `Config` register. The stream is selected via one of the thread-private `STREAM_ID_SYNC_SEC` registers.

Used 260 times across LLK ELFs. Provides a direct path from overlay stream state to backend configuration, avoiding the roundabout path of LOADREG + WRCFG.

<a id="config-sync-instructions--encoding-3"></a>
#### Encoding

```
[31:24] = 0xB7
[22:21] = stream_id_sel   (2 bits — selects which STREAM_ID_SYNC register to use)
[20:11] = StreamRegAddr   (10 bits — stream register index to read)
[10:0]  = CfgReg          (11 bits — config register ADDR32 index)
```

```c
#define TT_OP_STREAMWRCFG(stream_id_sel, StreamRegAddr, CfgReg) \
    TT_OP(0xb7, (((stream_id_sel) << 21) + ((StreamRegAddr) << 11) + ((CfgReg) << 0)))
```

<a id="config-sync-instructions--functional-model-3"></a>
#### Functional Model

```python
def STREAMWRCFG(stream_select, reg_index, cfg_index):
    stream_index = ThreadConfig[CurrentThread].STREAM_ID_SYNC_SEC[stream_select].BankSel
    state_id = ThreadConfig[CurrentThread].CFG_STATE_ID_StateID
    Config[state_id][cfg_index] = NOC_STREAM_READ_REG(stream_index, reg_index)
```

<a id="config-sync-instructions--performance-and-scheduling-1"></a>
#### Performance and Scheduling

- At least 5 cycles, fully pipelined (one per cycle assuming no contention)
- The issuing thread is **not** blocked
- **Hardware bug:** During the initial "prepare" phase (1+ cycles), if the same thread issues another Configuration Unit instruction (that is not STREAMWRCFG), that instruction will re-order and jump ahead of the pending STREAMWRCFG. After the prepare phase completes, subsequent Config instructions correctly wait.
- **Recommended:** Follow STREAMWRCFG with `STALLWAIT` before consuming the written config value. Alternatively, use `LOADREG` + `WRCFG` instead of STREAMWRCFG.

<a id="config-sync-instructions--emulator-note-2"></a>
#### Emulator Note

For a synchronous emulator, STREAMWRCFG reduces to a simple read from the stream register array and write to the config register. The hardware bug (instruction reordering during the prepare phase) is not relevant unless the emulator models cycle-accurate Configuration Unit pipeline stages. The emulator should still honor the STALLWAIT synchronization that software inserts.


<a id="config-sync-instructions--encoding-quick-reference"></a>
### Encoding Quick Reference

| Instruction | Opcode | Backend | Stall Block | Key Fields |
|---|---|---|---|---|
| CFGSHIFTMASK | 0xB8 | Config Unit | B7 (STALL_CFG) | MaskMode, AluMode, MaskWidth, RotateAmt, ScratchIndex, CfgIndex |
| REG2FLOP | 0x48 | Scalar Unit (ThCon) | B0 (STALL_TDMA), B5 (STALL_THCON) | SizeSel, TargetSel, ByteOffset, ContextId, FlopIndex, RegIndex |
| STREAMWAIT | 0xA7 | Sync Unit | B1 (STALL_SYNC) | BlockMask, TargetValue, ConditionIndex, StreamSelect |
| STREAMWRCFG | 0xB7 | Config Unit | B7 (STALL_CFG) | StreamSelect, StreamRegAddr, CfgReg |


<a id="config-sync-instructions--source-references"></a>
### Source References

| Source | Path |
|--------|------|
| CFGSHIFTMASK ISA (BH) | `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/CFGSHIFTMASK.md` |
| STREAMWAIT ISA (BH) | `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/STREAMWAIT.md` |
| STREAMWRCFG ISA (BH) | `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/STREAMWRCFG.md` |
| STALLWAIT block mask | `./stallwait-conditions.md` |
| Blackhole C macros | `tt-llk/tt_llk_blackhole/common/inc/ckernel_ops.h` |
| Blackhole assembly YAML | `tt-llk/tt_llk_blackhole/instructions/assembly.yaml` |
| Config register defines | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/cfg_defines.h` |
| STREAMWAIT hi-value defs | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/cfg_defines.h` (lines 1299–1308) |
| REG2FLOP target constants | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h` (lines 388–390) |
| Python instruction encoders | `tt-exalens/ttexalens/hardware/blackhole/tensix_ops.py` |
