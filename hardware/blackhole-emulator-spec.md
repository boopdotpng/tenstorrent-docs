# Blackhole Emulator Specification

## 1. Overview

A cycle-approximate Python emulator for the Tenstorrent Blackhole A0 ASIC. The emulator
executes real firmware and kernel binaries (ELF or raw instruction streams from dsl.py)
against a faithful model of the Tensix tile, NoC, DRAM, and host interface. The goal is
correctness, not performance — we need bit-accurate results for every instruction, and
faithful modeling of synchronization, so that programs that work on the emulator also work
on hardware (and vice versa, modulo known HW bugs we choose to model).

### Non-goals (for now)
- Cycle-exact timing (cycle-approximate is fine; relative ordering must be correct)
- Full PCIe/iATU emulation (host writes go directly into the model)
- Ethernet/ERISC tiles (add later)
- L2CPU tiles (add later)
- ARC firmware (stub out reset/init)

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    EmulatedDevice                        │
│                                                         │
│  ┌──────────┐  ┌──────────┐       ┌──────────────────┐ │
│  │ TensixTile│  │ TensixTile│ ...  │  DramBank × 8    │ │
│  │  (1,2)    │  │  (1,3)    │      │  (sparse storage)│ │
│  │           │  │           │      └──────────────────┘ │
│  │ ┌───────┐ │  │           │                           │
│  │ │5×RISCV│ │  │           │      ┌──────────────────┐ │
│  │ │Tensix │ │  │           │      │  NocRouter       │ │
│  │ │L1 1536K│ │  │           │      │  (2 networks)    │ │
│  │ │NOC NIU │ │  │           │      └──────────────────┘ │
│  │ └───────┘ │  │           │                           │
│  └──────────┘  └──────────┘       ┌──────────────────┐ │
│                                    │  HostInterface    │ │
│                                    │  (sysmem model)   │ │
│                                    └──────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Top-level classes

| Class | Responsibility |
|---|---|
| `EmulatedDevice` | Owns grid of tiles, DRAM banks, NoC fabric, host interface. Drives the main execution loop. |
| `TensixTile` | One compute tile: 5 RISCV cores, 1 Tensix coprocessor, 1536 KiB L1, 2 NOC NIUs. |
| `RiscVCore` | RV32IM + Zicsr + Zaamo + Zba + Zbb + `.ttinsn`. Fetches/decodes/executes. Has local data RAM (4 or 8 KiB). |
| `TensixCoprocessor` | 3-threaded backend: FPU, SFPU, Unpackers, Packers, Sync, Config, Scalar, Mover. |
| `NocFabric` | Models both NoC0 and NoC1. Routes reads, writes, broadcasts, atomics between tiles. |
| `DramBank` | Sparse storage for one 4 GiB bank. Tracks written regions. |
| `HostInterface` | Models sysmem (hugepages). Host can read/write any tile via TLB-like addressing. |

---

## 3. RISC-V Emulator

### 3.1 ISA support

Implement every instruction present in `dsl.py` plus those found in disassemblies:

**RV32I base:**
ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI,
LB, LBU, LH, LHU, LW, SB, SH, SW,
BEQ, BNE, BLT, BGE, BLTU, BGEU,
LUI, AUIPC, JAL, JALR, FENCE

**M extension:**
MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU

**Zicsr:**
CSRRW, CSRRS, CSRRC (and immediate variants CSRRWI, CSRRSI, CSRRCI)

**Zaamo (atomics against local L1 only):**
AMOADD.W, AMOXOR.W, AMOOR.W, AMOAND.W, AMOMIN.W, AMOMAX.W, AMOMINU.W, AMOMAXU.W, AMOSWAP.W

**Zba:**
SH1ADD, SH2ADD, SH3ADD

**Zbb:**
MIN, MINU, MAX, MAXU, CTZ, CLZ, CPOP, SEXT.B, SEXT.H, ZEXT.H, REV8, ORC.B, ANDN, ORN, XNOR, ROL, ROR, RORI

**Custom `.ttinsn` encoding:**
When the RISCV executes a `.ttinsn IMM32` instruction, rotate IMM32 right by 2 bits and
push the resulting 32-bit Tensix word into the coprocessor instruction FIFO for the
appropriate thread. Only RISCV T0/T1/T2 can push to their own thread; RISCV B can push
to any thread (T0 at `0xFFE40000`, T1 at `0xFFE50000`, T2 at `0xFFE60000`).

### 3.2 Registers

- 32 × 32-bit integer registers (x0 hardwired to 0)
- PC (32-bit)
- CSRs (see section 7)

### 3.3 Core instances

| Core | Name | Index | Local RAM | NOC access | Can push Tensix |
|---|---|---|---|---|---|
| RISCV B | BRISC | 0 | 8 KiB | NOC1 | Any thread (T0/T1/T2) |
| RISCV NC | NCRISC | 1 | 8 KiB | NOC0 | No |
| RISCV T0 | TRISC0 | 2 | 4 KiB | No | T0 only |
| RISCV T1 | TRISC1 | 3 | 4 KiB | No | T1 only |
| RISCV T2 | TRISC2 | 4 | 4 KiB | No | T2 only |

### 3.4 Local data RAM

Each core has private data RAM at fast-path address `0xFFB00000`:
- BRISC/NCRISC: 8 KiB (`0xFFB00000–0xFFB01FFF`)
- TRISC0/1/2: 4 KiB (`0xFFB00000–0xFFB00FFF`)

Slow-path (NOC-visible) addresses for external access:
| Core | Address | Size |
|---|---|---|
| BRISC | `0xFFB14000` | 8 KiB |
| NCRISC | `0xFFB16000` | 8 KiB |
| TRISC0 | `0xFFB18000` | 4 KiB |
| TRISC1 | `0xFFB1A000` | 4 KiB |
| TRISC2 | `0xFFB1C000` | 4 KiB |

Initialized to zero on reset (real HW takes up to 2048 cycles; emulator can zero
immediately).

### 3.5 L0 data cache

Model as a 4-line, 16-byte-per-line direct-mapped cache with non-coherent behavior:
- Stores to L1 flush the containing line
- Any `fence` or atomic flushes the entire cache
- Optionally model the ~0.8% random flush per access (configurable, default off for
  determinism)

### 3.6 Memory map (per-core view)

Loads and stores from any RISCV core go through a unified address decoder:

```
0x00000000–0x0017FFFF  → L1 scratchpad (1536 KiB, shared by all 5 cores)
0xFFB00000–0xFFB01FFF  → own local data RAM (fast path, 2-cycle equivalent)
0xFFB11000–0xFFB11FFF  → TDMA-RISC registers (see §11)
0xFFB12000–0xFFB12FFF  → tile control/debug/status registers (see §8)
0xFFB13000–0xFFB1314B  → PIC registers (see §12)
0xFFB14000–0xFFB1DFFF  → per-core local data RAM (slow path, any core can access)
0xFFB20000–0xFFB2FFFF  → NOC0 NIU registers
0xFFB30000–0xFFB3FFFF  → NOC1 NIU registers
0xFFB40000–0xFFB7FFFF  → NOC overlay / stream registers (64 streams × 0x1000)
0xFFB80000–0xFFB80023  → MOP config registers (per-thread, write-only)
0xFFBD8000–0xFFBDFFFF  → Dst register file direct access (T0/T1/T2 only, 32 KiB)
0xFFE00000–0xFFE00FFF  → Tensix GPRs (scalar unit DMA registers)
0xFFE40000             → Push Tensix T0 instruction
0xFFE50000             → Push Tensix T1 instruction (BRISC only)
0xFFE60000             → Push Tensix T2 instruction (BRISC only)
0xFFE80000–0xFFE8001F  → PCBuf B→T0 + manual TTSync
0xFFE80020–0xFFE8FFFF  → Tensix semaphores (RISCV-side view)
0xFFE90000             → PCBuf B→T1
0xFFEA0000             → PCBuf B→T2
0xFFEC0000–0xFFEC3FFF  → Mailboxes (4 × 4 KiB)
0xFFEF0000–0xFFEFFFFF  → Tensix backend config registers (Config/ThreadConfig)
```

### 3.7 Execution model

Each RISCV core is modeled as a coroutine or generator that yields after each instruction.
The main loop round-robins across all active cores (across all tiles) and the Tensix
backend. This gives us deterministic interleaving without threads.

```python
class RiscVCore:
    def __init__(self, tile, core_id, ram_size):
        self.x = [0] * 32          # integer register file
        self.pc = 0
        self.csr = {}              # CSR map
        self.local_ram = bytearray(ram_size)
        self.tile = tile           # back-pointer for memory access
        self.halted = False
        self.in_reset = True

    def step(self):
        """Execute one instruction. Returns number of cycles consumed."""
        insn = self.fetch()
        return self.execute(insn)
```

---

## 4. L1 Scratchpad

### 4.1 Storage

```python
class L1Memory:
    def __init__(self):
        self.data = bytearray(0x180000)  # 1536 KiB, zero-initialized
```

### 4.2 Layout (firmware reserves)

```
0x000000  FIRMWARE_BASE / boot vector
0x000004  NOC_ATOMIC_RET_VAL_ADDR
0x00000C  L1_BARRIER
0x000010  ARC_FW_SCRATCH (16 bytes)
0x000020  NOC_INLINE_BASE (64 bytes, workaround for inline write bug)
0x000060  MAILBOX_BASE
0x003270  MAILBOX_END
0x003280  ZEROS_BASE (1024 bytes)
0x003480  LLK_DEBUG_BASE (1024 bytes)
0x003840  BRISC_FIRMWARE_BASE
0x003E40  NCRISC_FIRMWARE_BASE
0x004440  TRISC0_FIRMWARE_BASE
0x004A40  TRISC1_FIRMWARE_BASE
0x005440  TRISC2_FIRMWARE_BASE
0x0086B0  KERNEL_CONFIG_BASE (CB configs, kernel RTAs, XIP code)
0x037000  DATA_BUFFER_SPACE_BASE (CB backing storage starts here)
0x180000  END (top of L1)
```

### 4.3 Atomics

Zaamo instructions (amoadd.w, etc.) operate atomically on L1 addresses. The emulator
serializes all L1 access so atomicity is trivially correct. NOC atomics (see §9.4) also
target L1.

### 4.4 Concurrency

All 5 RISCV cores share the L1. In the emulator's round-robin model, no true data races
exist, but we must still honor `fence` semantics and ensure that store visibility follows
the memory ordering configured in CSR `cfg0`.

---

## 5. Tensix Coprocessor

### 5.1 Architecture overview

The Tensix coprocessor is a 3-threaded (T0/T1/T2) in-order processor with specialized
execution units. Instructions arrive via per-thread instruction FIFOs, pass through MOP
expansion and replay, and execute on the backend.

```
RISCV T0 ──► [Input FIFO 32×32b] ──► [MOP Expander] ──► [Replay Buffer 32×32b]
                                           │                      │
RISCV T1 ──► [Input FIFO 32×32b] ──► [MOP Expander] ──► [Replay Buffer 32×32b]
                                           │                      │
RISCV T2 ──► [Input FIFO 32×32b] ──► [MOP Expander] ──► [Replay Buffer 32×32b]
                                           │                      │
                                     [Wait Gate] ◄── Sync Unit
                                           │
                            ┌──────────────┼──────────────┐
                            ▼              ▼              ▼
                    ┌─────────────┐ ┌───────────┐ ┌────────────┐
                    │ Unpackers   │ │ FPU/SFPU  │ │ Packers    │
                    │ (T0 ctrl)   │ │ (T1 ctrl) │ │ (T2 ctrl)  │
                    └─────────────┘ └───────────┘ └────────────┘
```

### 5.2 Instruction format

All Tensix instructions are 32-bit words: `[opcode:8][params:24]`.

The `.ttinsn IMM32` RISCV instruction encodes a Tensix word as:
`encoded = ((IMM32 << 2) | (IMM32 >> 30)) & 0xFFFFFFFF`

The emulator reverses this on push:
`tensix_word = ((encoded >> 2) | (encoded << 30)) & 0xFFFFFFFF`

### 5.3 Instruction FIFO

Each thread has a 29–32 entry input FIFO. When a RISCV core writes to `0xFFE4xxxx` /
`0xFFE5xxxx` / `0xFFE6xxxx`, the 32-bit value is enqueued. If the FIFO is full, the
RISCV write stalls (the RISCV core blocks until space is available).

```python
class TensixThread:
    def __init__(self, thread_id):
        self.input_fifo = deque(maxlen=32)
        self.mop_cfg = [0] * 9           # MOP config regs
        self.replay_buf = [0] * 32       # replay buffer
```

### 5.4 MOP expander

The `MOP` instruction (opcode `0x01`) expands into a configurable sequence of Tensix
instructions using a hardware macro-op template. There are two templates (MOP_A, MOP_B)
selected by `mop_type`.

MOP instruction fields:
```
[0x01:8][mop_type:1][loop_count:7][zmask_lo16:16]
```
- `mop_type` (bit 23, 1 bit): 0 = MOP_A template, 1 = MOP_B template
- `loop_count` (bits 22:16, 7 bits): outer loop iterations (0–127)
- `zmask_lo16` (bits 15:0, 16 bits): low 16 bits of 32-bit zero-column mask

The full 32-bit zero-column mask is assembled from a preceding `MOP_CFG` instruction
(opcode `0x03`, provides `zmask_hi16`) concatenated with `zmask_lo16`. Each bit
corresponds to a column to skip/zero during the macro-op expansion.

The MOP config registers at `0xFFB80000 + thread_id * 0x24` define the template
instructions. The hardware expands the MOP by iterating over the configured template
`loop_count` times, applying the zero-column mask to skip specified columns.

### 5.5 Replay buffer

32-slot circular buffer per thread. `REPLAY(start_idx, len, execute_while_loading, load_mode)`
replays previously recorded instructions without RISCV involvement.

### 5.6 Backend execution units

Each unit processes instructions from specific threads:

| Unit | Controlled by | Key operations |
|---|---|---|
| Sync | Any thread | STALLWAIT, SEMWAIT, SEMINIT, SEMPOST, SEMGET, ATGETM, ATRELM |
| Unpack (×2) | T0 | UNPACR (L1→SrcA/SrcB), UNPACR_NOP |
| FPU (Matrix) | T1 | MVMUL, ELWADD, ELWMUL, ELWSUB, ZEROACC, ZEROSRC, MOVx2x, etc. |
| SFPU (Vector) | T1 | SFPLOAD/STORE, SFPMAD, SFPMUL, SFPADD, SFPIADD, etc. |
| Scalar (ThCon) | T1 | SETDMAREG, ADDDMAREG, MULDMAREG, DMANOP |
| Pack (×4) | T2 | PACR (Dst→L1) |
| Config | Any thread | WRCFG, RDCFG, SETC16, RMWCIB0-3 |
| Mover (XMOV) | Any thread | Bulk L1 data movement |

---

## 6. Tensix Register Files

### 6.1 SrcA and SrcB

```python
class SrcRegFile:
    def __init__(self):
        # 2 banks × 64 rows × 16 columns × 19 bits
        # Store as 32-bit for convenience; only low 19 bits are meaningful
        self.banks = [[[0]*16 for _ in range(64)] for _ in range(2)]
        self.active_bank = 0        # bank currently owned by FPU
        self.dvalid = [False, False] # data-valid flag per bank
```

Storage format is **shuffled**: `{sign(1), mantissa(10), exponent(8)}` for TF32.
The emulator must convert to/from this format when data enters/leaves SrcA/SrcB.

Supported input formats (set by Config registers):
- TF32: 1+10+8 = 19 bits
- BF16: 1+7+8 = 16 bits (padded to 19)
- FP16: 1+10+5 = 16 bits (padded to 19)
- INT8: 1+8+0 = 9 bits (sign-magnitude)

### 6.2 Dst (Destination register file)

```python
class DstRegFile:
    def __init__(self):
        self.bits = [[0]*16 for _ in range(1024)]  # 1024 rows × 16 × 16-bit
        self.row_valid = [False] * 1024

    # Two logical views:
    # Dst16b: 1024 rows × 16 cols × 16 bits → 16 tiles (8 per half)
    # Dst32b: 512 rows × 16 cols × 32 bits → 8 tiles (4 per half)
    # In 32b mode, logical row R maps to physical rows Adj32(R) and Adj32(R)+8
```

Double-buffered: rows 0–511 = half 0, rows 512–1023 = half 1. MATH writes one half
while PACK reads the other, coordinated by the `MATH_PACK` semaphore.

RISCV T0/T1/T2 can directly access Dst at `0xFFBD8000` (32 KiB window). The format is
controlled by `RISC_DEST_ACCESS_CTRL_SEC[i].fmt`:
- 0=float32, 1=int32, 2=fp16, 3=bf16, 4=int16, 5=int8

### 6.3 LReg (SFPU local registers)

```python
class LRegFile:
    def __init__(self):
        # 17 registers × 32 lanes × 32 bits
        self.data = [[0]*32 for _ in range(17)]
        self._init_constants()

    def _init_constants(self):
        import struct
        def f2u(f): return struct.unpack('<I', struct.pack('<f', f))[0]
        # Read-only constants
        self.data[8]  = [f2u(0.8373)] * 32
        self.data[9]  = [0] * 32               # 0.0
        self.data[10] = [f2u(1.0)] * 32
        self.data[15] = [i * 2 for i in range(32)]  # lane_id * 2
        # LReg[11] initialized to -1.0 by firmware via SFPLOADI + SFPCONFIG
        self.data[11] = [f2u(-1.0)] * 32
```

- LReg[0–7]: general-purpose, read/write
- LReg[8–10]: read-only hardware constants
- LReg[11–14]: programmable via SFPCONFIG (write LReg[0] lane 0 → target)
- LReg[15]: read-only lane IDs (lane i = i*2)
- LReg[16]: SFPLOADMACRO scratch

### 6.4 DMA registers (Scalar Unit)

```python
class ScalarUnit:
    def __init__(self):
        # 64 × 16-bit DMA registers per thread, 3 threads
        self.dma_regs = [[0]*64 for _ in range(3)]
```

Accessed via:
- `SETDMAREG(reg_idx, value)`: load immediate
- `ADDDMAREG(dst, src_a, src_b)`: integer add
- `MULDMAREG(dst, src_a, src_b)`: integer multiply

Also visible at `0xFFE00000` (Tensix GPR base).

---

## 7. CSR Registers

### 7.1 Standard CSRs

| CSR | Address | Notes |
|---|---|---|
| `mcycle` | 0xB00 | Cycle counter low (read-only) |
| `mcycleh` | 0xB80 | Cycle counter high (read-only) |
| `minstret` | 0xB02 | Instructions retired low |
| `minstreth` | 0xB82 | Instructions retired high |

### 7.2 Custom CSRs

| CSR | Address | Description |
|---|---|---|
| `cfg0` | 0x7C0 | Core configuration (see below) |
| `tt_cfg_qstatus` | 0xBC0 | Tensix frontend queue status / SFPU CC status |
| `tt_cfg_bstatus` | 0xBC1 | Tensix backend busy status |
| `tt_cfg_sstatus0–7` | 0xBC2–0xBC9 | Stream status (T0/T1/T2) or scratch (B/NC) |
| `intp_restore_pc` | 0xBCA | Interrupt return PC |

### 7.3 `cfg0` bit fields

| Bit | Name | Default | Effect |
|---|---|---|---|
| 0 | DisLdBufByp | 0 | Load waits for store queue empty |
| 1 | DisBp | 0 | Disable branch predictor (no effect in emulator) |
| 3 | DisLowCash | 0 | Disable L0 data cache |
| 18 | DisTriscCache | 0 | Disable `.ttinsn` fusion (no effect in emulator) |
| 24 | DisLowCachePeriodicFlush | 0 | Disable random L0 flush |
| 30 | EnBFloat | 0 | BF16 mode for Zfh instructions |
| 31 | EnBFloatRTNE | 0 | BF16 rounding mode (0=RTZ, 1=RTNE) |

---

## 8. Tile Control / Debug Registers

Located at `0xFFB12000–0xFFB12FFF`:

| Address | Register | Emulator behavior |
|---|---|---|
| `0xFFB121B0` | SOFT_RESET_0 | Controls which cores are in/out of reset (see §14) |
| `0xFFB121F0` | WALL_CLOCK_0 | Low 32 bits of 64-bit cycle counter |
| `0xFFB121F4` | WALL_CLOCK_1 | High 32 bits (live) |
| `0xFFB121F8` | WALL_CLOCK_1_AT | Latched high bits (snapshot on read of WALL_CLOCK_0) |
| `0xFFB12228` | TRISC0_RESET_PC | Reset PC for T0 |
| `0xFFB1222C` | TRISC1_RESET_PC | Reset PC for T1 |
| `0xFFB12230` | TRISC2_RESET_PC | Reset PC for T2 |
| `0xFFB12234` | TRISC_RESET_PC_OVERRIDE | 3-bit mask: enable custom reset PC per TRISC |
| `0xFFB12238` | NCRISC_RESET_PC | Reset PC for NCRISC |
| `0xFFB1223C` | NCRISC_RESET_PC_OVERRIDE | 1-bit enable |
| `0xFFB12240` | DEST_CG_CTRL | Dst clock gating (model as no-op) |
| `0xFFB12244` | CG_CTRL_EN | Clock gating enable (model as no-op) |
| `0xFFB120B4` | FPU_STICKY_BITS | NaN/Inf/denorm sticky flags |

### Soft reset register (`0xFFB121B0`)

| Bit | Target |
|---|---|
| 0,1,7 | Unpackers |
| 2–5 | Packers 0–3 |
| 6 | Mover |
| 8 | TDMA-RISC |
| 9 | Scalar Unit + THCON |
| 10 | FPU + SFPU + SrcA |
| 11 | RISCV B |
| 12 | RISCV T0 |
| 13 | RISCV T1 |
| 14 | RISCV T2 |
| 15–17 | SrcA/SrcB ownership, Packer-Dst |
| 18 | RISCV NC |
| 19–22 | SrcA data columns |
| 23 | Auto TTSync |

Key values:
- `SOFT_RESET_ALL = 0x47800`: all 5 RISC-V cores held in reset
- `SOFT_RESET_BRISC_ONLY_RUN = 0x47000`: TRISCs + NCRISC in reset, BRISC released
- `SOFT_RESET_NONE = 0x00000`: all cores running

Firmware boots with `0x47800` (all in reset). Host releases BRISC first (`0x47000`),
BRISC firmware then writes `0x00000` to release the others.

---

## 9. NOC Emulation

### 9.1 Fabric model

```python
class NocFabric:
    def __init__(self, device):
        self.device = device
        # pending_transactions: list of in-flight NOC ops
        self.pending = []

    def submit_write(self, src_tile, noc_id, targ_xy, targ_addr, data, flags):
        """Unicast or multicast write."""
        ...

    def submit_read(self, src_tile, noc_id, targ_xy, targ_addr, ret_addr, length):
        """Read request: data returned to ret_addr in src_tile's L1."""
        ...

    def submit_atomic(self, src_tile, noc_id, targ_xy, targ_addr, op, operand):
        """Atomic operation on target tile's L1."""
        ...

    def tick(self):
        """Process pending transactions. Move data between tiles."""
        ...
```

Two independent networks (NOC0 and NOC1). Each tile has 4 command buffer slots per NIU.

NOC base addresses:
```python
NOC0_REGS = 0xFFB20000
NOC1_REGS = 0xFFB30000
# Generic: noc_base = 0xFFB20000 + (noc_id << 16)
```

### 9.2 NIU register model

Per-NOC command buffer registers. Each command buffer is at
`NOCx_REGS + (buf_index << 11)`:

| Offset | Register | Model |
|---|---|---|
| `+0x00` | NOC_TARG_ADDR_LO | Written by RISCV, consumed on CMD_CTRL |
| `+0x04` | NOC_TARG_ADDR_MID | Target address high bits |
| `+0x08` | NOC_TARG_ADDR_COORDINATE | Target X/Y: bits [5:0]=X, [11:6]=Y |
| `+0x0C` | NOC_RET_ADDR_LO | Return/source address low |
| `+0x10` | NOC_RET_ADDR_MID | Return address high |
| `+0x14` | NOC_RET_ADDR_COORDINATE | Return X/Y |
| `+0x18` | NOC_PACKET_TAG | Transaction ID |
| `+0x1C` | NOC_CTRL | Command type and flags (see §9.3) |
| `+0x20` | NOC_AT_LEN_BE | Length / byte-enable / atomic opcode |
| `+0x28` | NOC_AT_DATA | Inline data / atomic operand |
| `+0x2C` | NOC_BRCST_EXCLUDE | Broadcast exclusion mask |
| `+0x40` | NOC_CMD_CTRL | Write 1 to trigger; cleared when command accepted |
| `+0x44` | NOC_NODE_ID | This tile's X/Y (read-only, set at init) |

Command buffer indices (4 per NIU, stride `0x800` = `1 << 11`):
```python
WR_CMD_BUF     = 0   # Write command buffer:    NOCx_REGS + 0x000
RD_CMD_BUF     = 1   # Read command buffer:     NOCx_REGS + 0x800
WR_REG_CMD_BUF = 2   # Write register cmd buf:  NOCx_REGS + 0x1000
AT_CMD_BUF     = 3   # Atomic operation cmd buf: NOCx_REGS + 0x1800
```

The read command buffer is pre-loaded during `noc_init()` with:
```python
NOC_RD_CMD_CTRL = 0x2090  # CPY | RD | RESP_MARKED | VC_STATIC | STATIC_VC(1)
```

### 9.3 NOC_CTRL flags

```python
NOC_CMD_CPY            = 0 << 0   # copy (vs atomic)
NOC_CMD_AT             = 1 << 0   # atomic
NOC_CMD_RD             = 0 << 1   # read
NOC_CMD_WR             = 1 << 1   # write
NOC_CMD_WR_BE          = 1 << 2   # byte-enable write
NOC_CMD_WR_INLINE      = 1 << 3   # inline data (BH: broken for L1, ok for MMIO)
NOC_CMD_RESP_MARKED    = 1 << 4   # request ack/response
NOC_CMD_BRCST_PACKET   = 1 << 5   # multicast
NOC_CMD_VC_LINKED      = 1 << 6   # linked VC (multi-packet transaction)
NOC_CMD_VC_STATIC      = 1 << 7   # software-controlled VC
NOC_CMD_BRCST_XY       = 1 << 16  # broadcast direction (0=X-major, 1=Y-major)
NOC_CMD_BRCST_SRC_INCLUDE = 1 << 17  # include source in broadcast
```

### 9.4 Address encoding

XY coordinate packing (6 bits per coordinate):
```python
def noc_xy(x, y):
    """Pack X/Y into a 12-bit coordinate word."""
    return ((y << 6) | x) & 0xFFFF
```

Full 40-bit NOC address construction:
```python
def noc_unicast_addr(x, y, local_addr):
    """Encode 40-bit NOC address for unicast."""
    return (y << 36) | (x << 32) | (local_addr & 0xFFFFFFFF)

def noc_multicast_addr(x_start, y_start, x_end, y_end, local_addr):
    """Encode multicast rectangle (C firmware API)."""
    return (y_start << 36) | (x_start << 32) | (y_end << 24) | (x_end << 18) | local_addr
```

TLB/dispatch-level multicast coordinate encoding (different from NOC address):
```python
def noc_mcast_xy(x0, x1, y0, y1):
    """Encode multicast rectangle as a coordinate word for TLB config."""
    # bits [5:0]=x_start, [11:6]=y_start, [17:12]=x_end, [23:18]=y_end
    return (y1 << 18) | (x1 << 12) | (y0 << 6) | x0
```

Node ID extraction from `NOCx_REGS + 0x148`:
```python
x = node_id & 0x3F          # bits [5:0]
y = (node_id >> 6) & 0x3F   # bits [11:6]
```

### 9.5 NOC completion tracking

NIU status counters at `NOCx_REGS + 0x200`, indexed as `NOCx_REGS + 0x200 + index * 4`:

| Index | Register | Description |
|---|---|---|
| 0 | `NIU_MST_ATOMIC_RESP_RECEIVED` | Nonposted atomics acknowledged |
| 1 | `NIU_MST_WR_ACK_RECEIVED` | Nonposted writes acknowledged |
| 2 | `NIU_MST_RD_RESP_RECEIVED` | Read responses received |
| 0xA | `NIU_MST_NONPOSTED_WR_REQ_SENT` | Nonposted write requests sent |
| 0xB | `NIU_MST_POSTED_WR_REQ_SENT` | Posted write requests sent |

Firmware shadows these hardware counters into software variables in LDM. BRISC LDM layout:
```
0xFFB0000C  reads_issued
0xFFB00010  nonposted_writes_issued
0xFFB00014  nonposted_writes_acked
0xFFB0001C  posted_writes_issued
0xFFB00024  nonposted_atomics_acked
```

NCRISC LDM layout:
```
0xFFB00004  reads_issued
0xFFB00008  nonposted_writes_issued
0xFFB0000C  nonposted_writes_acked
0xFFB00010  nonposted_atomics_acked
0xFFB00014  posted_writes_issued
```

Barrier logic: `noc_async_write_barrier()` polls `NOCx_REGS + 0x200 + 1*4`
(WR_ACK_RECEIVED) until it matches the software `nonposted_writes_issued` counter.
`noc_async_read_barrier()` polls index 2 (RD_RESP_RECEIVED). Both issue `fence` before
returning.

### 9.6 NOC configuration registers

| Offset | Register | Key bits |
|---|---|---|
| `+0x100` | NIU_CFG_0 | bit 14: coordinate translation enable |
| `+0x104` | ROUTER_CFG_0 | reserved |
| `+0x108` | ROUTER_CFG_1 | broadcast column opt-out mask |
| `+0x110` | ROUTER_CFG_3 | broadcast row opt-out mask |
| `+0x118..0x144` | translate tables | X/Y coordinate translation (5-bit entries, packed) |
| `+0x148` | NOC_ID_LOGICAL | this tile's logical X/Y |

### 9.7 NOC atomics

Supported against L1 of Tensix tiles only:
- Atomic increment (with width mask)
- Compare-and-swap
- Swap (unconditional write, returns old)
- AMOADD, AMOXOR, AMOOR, AMOAND, AMOMIN, AMOMAX, AMOMINU, AMOMAXU
- Parallel accumulation: fp32×4, fp16×8, bf16×8, u32×4, u8×16 (128-bit)

### 9.8 PCIe / sysmem NOC addressing

The PCIe endpoint appears as a NOC tile at coordinates `(x=19, y=24)`:
```python
PCIE_NOC_XY = (24 << 6) | 19   # = 0x619
PCIE_NOC_X = 19
PCIE_NOC_Y = 24
```

The NOC address for device-to-host writes uses the PCIe offset:
```python
NOC_PCIE_OFFSET = 4 << 58      # = 0x1000000000000000 (also = 1 << 60)
```

To write to sysmem from a tile:
```python
sysmem_noc_addr = (PCIE_NOC_XY << 36) | NOC_PCIE_OFFSET | (local_offset & ((1 << 36) - 1))
```

NOC atomic return values are written to `L1[0x4]` (`MEM_NOC_ATOMIC_RET_VAL_ADDR = 4`).

### 9.9 noc_init() sequence

Called by BRISC firmware at boot. For each NOC (0 and 1):
1. Read `NOCx_REGS + 0x148` → extract local tile's X/Y coordinates
2. Pre-load WR_CMD_BUF (0): write `0` to `+0x04`, write local XY to `+0x08`
3. Pre-load WR_REG_CMD_BUF (2): same as WR_CMD_BUF
4. Pre-load AT_CMD_BUF (3): write `0` to `+0x10`, write XY to `+0x14`, write `0x4`
   (atomic return addr) to `+0x0C`
5. Pre-load RD_CMD_BUF (1): write `0x2090` to `+0x1C` (NOC_CTRL), write `0` to `+0x10`,
   write XY to `+0x14`

### 9.10 Known hardware bugs to model

- **Inline write to L1 is broken** on Blackhole A0. `NOC_CMD_WR_INLINE` must only target
  MMIO addresses, not L1. Firmware works around this by writing data to
  `MEM_L1_INLINE_BASE` (0x20) and issuing a normal write. The emulator should reject or
  warn on inline writes to L1 addresses.

---

## 10. DRAM Model

### 10.1 Architecture

8 banks × 4 GiB = 32 GiB total. Each bank is fronted by 3 DRAM tiles on the NoC (all 3
expose the same data).

NOC coordinates of DRAM tiles:
- West banks 0–3: X=0, various Y
- East banks 4–7: X=9, various Y

### 10.2 Sparse storage

Do NOT allocate 32 GiB. Use a sparse dict-of-pages model:

```python
class DramBank:
    PAGE_SIZE = 4096  # 4 KiB pages

    def __init__(self, bank_id):
        self.bank_id = bank_id
        self.pages = {}  # page_number → bytearray(PAGE_SIZE)

    def read(self, offset, length):
        result = bytearray(length)
        for i in range(length):
            addr = offset + i
            page = addr // self.PAGE_SIZE
            off = addr % self.PAGE_SIZE
            if page in self.pages:
                result[i] = self.pages[page][off]
            # else: 0 (uninitialized)
        return result

    def write(self, offset, data):
        for i, byte in enumerate(data):
            addr = offset + i
            page = addr // self.PAGE_SIZE
            off = addr % self.PAGE_SIZE
            if page not in self.pages:
                self.pages[page] = bytearray(self.PAGE_SIZE)
            self.pages[page][off] = byte
```

### 10.3 Interleaved addressing

For interleaved DRAM buffers: tile N goes to bank `N % num_banks` at offset
`(N // num_banks) * tile_size + base_offset`.

### 10.4 DRAM tile NOC handling

When a NOC read/write targets a DRAM tile (identified by X/Y coordinate), the fabric
routes to the appropriate `DramBank`. The local address within the DRAM tile maps to the
GDDR offset.

---

## 11. Tensix Instruction Emulation

### 11.1 Instruction encoding

All Tensix instructions are 32 bits: `[opcode:8][params:24]`. Opcode is bits [31:24],
parameters are bits [23:0]. The encoding helper:
```python
def _tt(op, p=0):
    return (op << 24) | p
```

### 11.2 Complete instruction table

Every instruction from `dsl.py` with opcode, parameter bit-field layout, and semantics.

#### Flow control
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x01 | MOP | `mop_type[1]<<23 \| loop_count[7]<<16 \| zmask_lo16[16]` | Expand macro-op template |
| 0x02 | NOP | `0` | No operation |
| 0x03 | MOP_CFG | `zmask_hi16[16]` | Set upper 16 bits of MOP zero-mask |
| 0x04 | REPLAY | `start_idx[10]<<14 \| len[10]<<4 \| exec_while_load[1]<<1 \| load_mode[1]` | Replay buffer instructions |
| 0x05 | RESOURCEDECL | `linger_time[11]<<13 \| resources[9]<<4 \| op_class[4]` | Declare resource usage (rare) |

#### Sync unit
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0xA0 | ATGETM | `mutex_index[24]` | Acquire mutex (spin if held) |
| 0xA1 | ATRELM | `mutex_index[24]` | Release mutex |
| 0xA2 | STALLWAIT | `stall_res[9]<<15 \| wait_res[15]` | Stall `stall_res` units until `wait_res` bits clear |
| 0xA3 | SEMINIT | `max_value[4]<<20 \| init_value[4]<<16 \| sem_sel[8]<<2` | Init semaphore |
| 0xA4 | SEMPOST | `sem_sel[8]<<2` | `sem[sel].value++` (saturate at max) |
| 0xA5 | SEMGET | `sem_sel[8]<<2` | `sem[sel].value--` (saturate at 0) |
| 0xA6 | SEMWAIT | `stall_res[9]<<15 \| sem_sel[8]<<2 \| wait_sem_cond[2]` | Stall on semaphore condition |
| 0xA7 | STREAMWAIT | `stall_res[9]<<15 \| target_val[10]<<4 \| target_sel[1]<<3 \| wait_stream_sel[2]` | Stall on stream (BH-new) |

`stall_res` (BlockMask) bit meanings: B0=Misc/Mover/ThCon/Pack/Unpack, B1=Sync,
B2=Pack, B3=Unpack, B4=Mover, B5=ThCon(Scalar), B6=FPU, B7=Config, B8=SFPU.

`wait_sem_cond`: 0 = wait while value==0, 1 = wait while value>=max.

#### Configuration unit
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0xB0 | WRCFG | `GprAddr[6]<<16 \| wr128b[1]<<15 \| CfgReg[11]` | Write GPR to Config reg |
| 0xB1 | RDCFG | `GprAddr[6]<<16 \| CfgReg[11]` | Read Config reg to GPR |
| 0xB2 | SETC16 | `setc16_reg[8]<<16 \| setc16_value[16]` | Write 16-bit imm to ThreadConfig |
| 0xB3–0xB6 | RMWCIB0–3 | `Mask[8]<<16 \| Data[8]<<8 \| CfgRegAddr[8]` | RMW byte in Config |
| 0xB7 | STREAMWRCFG | `stream_id_sel[2]<<21 \| StreamRegAddr[10]<<11 \| CfgReg[11]` | Write stream reg to config (rare) |
| 0xB8 | CFGSHIFTMASK | `dis_mask[1]<<23 \| op[3]<<20 \| width[5]<<15 \| shift[5]<<10 \| scratch[2]<<8 \| CfgReg[8]` | Config shift-mask op (rare) |

#### FPU (matrix unit)
| Opcode | Mnemonic | Bit layout | Semantics | Latency |
|---|---|---|---|---|
| 0x08 | MOVD2A | `d32b_lo[1]<<23 \| src[6]<<17 \| amode[3]<<14 \| imod[2]<<12 \| dst[12]` | Dst → SrcA (rare) | 3 |
| 0x09 | MOVDBGA2D | same as 0x08 | Debug: SrcA → Dst (rare) | 3 |
| 0x0A | MOVD2B | `d32b_lo[1]<<23 \| src[6]<<17 \| amode[3]<<14 \| imod[2]<<12 \| dst[12]` | Dst → SrcB | 3 |
| 0x0B | MOVB2A | `srca[6]<<17 \| amode[3]<<14 \| imod[2]<<12 \| srcb[12]` | SrcB → SrcA (rare) | 3 |
| 0x0C | MOVDBGB2D | `d32b_lo[1]<<23 \| src[6]<<17 \| amode[3]<<14 \| imod[3]<<11 \| dst[11]` | Debug: SrcB → Dst (rare) | 3 |
| 0x10 | ZEROACC | `clr_mode[5]<<19 \| use32b[1]<<18 \| clr_zero[1]<<17 \| amode[3]<<14 \| where[14]` | Clear Dst rows | 1 |
| 0x11 | ZEROSRC | `zero_val[20]<<4 \| write_mode[1]<<3 \| bank_mask[1]<<2 \| src_mask[2]` | Zero/fill SrcA/SrcB | 1 |
| 0x12 | MOVA2D | same as 0x08 | SrcA → Dst (rare) | 3 |
| 0x13 | MOVB2D | `d32b_lo[1]<<23 \| src[6]<<17 \| amode[3]<<14 \| imod[3]<<11 \| dst[11]` | SrcB → Dst | 4 |
| 0x14 | TRNSPSRCA | `0` | Transpose SrcA (dead on BH) | 1 |
| 0x16 | TRNSPSRCB | `0` | Transpose SrcB rows 16–31 | 1 |
| 0x26 | MVMUL | `clr_dvalid[2]<<22 \| imod19[3]<<19 \| amode[2]<<14 \| dst[10]` | `Dst += SrcB @ SrcA` (8×16) | 5 |
| 0x27 | ELWMUL | `clr_dvalid[2]<<22 \| accum_en[1]<<21 \| imod19[2]<<19 \| amode[2]<<14 \| dst[14]` | Element-wise multiply | 5 |
| 0x28 | ELWADD | `clr_dvalid[2]<<22 \| accum_en[1]<<21 \| imod19[2]<<19 \| amode[2]<<14 \| dst[14]` | Element-wise add | 5 |
| 0x29 | DOTPV | same as ELWMUL | Dot product (rare) | 5 |
| 0x30 | ELWSUB | same as ELWMUL | Element-wise subtract (rare) | 5 |
| 0x33 | GMPOOL | `clr_dvalid[2]<<22 \| imod19[3]<<19 \| pmode[4]<<15 \| idx_en[1]<<14 \| dst[14]` | Global max pool | 5 |
| 0x34 | GAPOOL | same as GMPOOL | Global avg pool (rare) | 5 |
| 0x36 | CLEARDVALID | `cleardvalid[2]<<22 \| reset[22]` | Clear data-valid flags | 1 |
| 0x37 | SETRWC | `clr_ab_vld[2]<<22 \| rwc_cr[4]<<18 \| rwc_d[4]<<14 \| rwc_b[4]<<10 \| rwc_a[4]<<6 \| BitMask[6]` | Set read/write counters | 1 |
| 0x38 | INCRWC | `rwc_cr[3]<<18 \| rwc_d[4]<<14 \| rwc_b[4]<<10 \| rwc_a[4]<<6` | Increment RWC values | 1 |
| 0x39 | SETIBRWC | `rwc_cr[3]<<18 \| rwc_bias[12]<<6 \| set_inc_ctrl[6]` | Set indirect bias RWC (rare) | 1 |

`clr_dvalid` (bits [23:22]): bit 0 = clear SrcA valid flag, bit 1 = clear SrcB valid flag.

Dead on Blackhole (implement as NOP): 0x14 TRNSPSRCA, 0x15 RAREB, 0x22 CONV3S1,
0x23 CONV3S2, 0x24 MFCONV3S1, 0x25 APOOL3S1, 0x2A MPOOL3S2, 0x31 MPOOL3S1,
0x32 APOOL3S2.

#### Unpack
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x42 | UNPACR | `blk_sel[1]<<23 \| amode[8]<<15 \| cfg_inc[2]<<13 \| cfg_id[3]<<10 \| adc_id[2]<<8 \| ovrd_thd[1]<<7 \| set_dvalid[1]<<6 \| srcb_bcast[1]<<5 \| zero_wr[1]<<4 \| auto_inc[1]<<3 \| row_search[1]<<2 \| cache_flush[1]<<1 \| last[1]` | Unpack L1 → SrcA/SrcB |
| 0x43 | UNPACR_NOP | `unp_sel[1]<<23 \| stream_id[7]<<16 \| msg_clr[4]<<12 \| set_dvalid[4]<<8 \| clr_fmt[2]<<6 \| stall_clr[1]<<5 \| bank_clr[1]<<4 \| src_clrval[2]<<2 \| unpack_pop[2]` | NOP with side effects |

`blk_sel`: 0 = unpack to SrcA (Unpacker 0), 1 = unpack to SrcB (Unpacker 1).

#### Pack
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x41 | PACR | `CfgCtx[3]<<21 \| RowPadZero[3]<<18 \| DstAccMode[1]<<17 \| AMode[2]<<15 \| AdcCtx[2]<<13 \| ZeroWr[1]<<12 \| RdIntfSel[4]<<8 \| OvrdThd[1]<<7 \| Concat[3]<<4 \| CtxtCtrl[2]<<2 \| Flush[1]<<1 \| Last[1]` | Pack Dst → L1 (16 rows per call) |
| 0x4A | PACR_SETREG | `Push[1]<<23 \| ModeSel[1]<<22 \| Unused[10]<<12 \| DisStall[2]<<10 \| AddrSel[2]<<8 \| StreamId[6]<<2 \| Flush[1]<<1 \| Last[1]` | Set packer register (rare) |

#### Mover
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x40 | XMOV | `Mov_block_sel[1]<<23 \| Last[23]` | Bulk L1 data movement (rare) |

#### SFPU (vector unit)

**Encoding families:**

Load/Store: `[op:8][lreg_ind:4][instr_mod0:4][sfpu_addr_mode:3][dest_reg_addr:13]`
Immediate FP: `[op:8][imm16_math:16][lreg_dest:4][instr_mod1:4]`
Simple: `[op:8][imm12_math:12][lreg_c:4][lreg_dest:4][instr_mod1:4]`
MAD: `[op:8][lreg_src_a:4][lreg_src_b:4][lreg_src_c:4][lreg_dest:4][instr_mod1:4]`

Data movement:
| Opcode | Mnemonic | Encoding | Semantics |
|---|---|---|---|
| 0x70 | SFPLOAD | Load/Store | Load 32 elements from Dst → LReg |
| 0x71 | SFPLOADI | `lreg_ind[4]<<20 \| instr_mod0[4]<<16 \| imm16[16]` | Load immediate → LReg |
| 0x72 | SFPSTORE | Load/Store | Store LReg → Dst |
| 0x93 | SFPLOADMACRO | Load/Store | Pipelined load + 4 ops |

Arithmetic (MAD sub-unit, 2-cycle latency):
| Opcode | Mnemonic | Encoding | Operation |
|---|---|---|---|
| 0x84 | SFPMAD | MAD | VD = ±VA * ±VB ± VC (FMA) |
| 0x85 | SFPADD | MAD | VD = ±VB ± VC |
| 0x86 | SFPMUL | MAD | VD = VA * ±VB |
| 0x98 | SFPMUL24 | MAD | 24-bit multiply (BH-new, rare) |
| 0x74 | SFPMULI | Imm FP | VD *= BF16ToFP32(imm16) |
| 0x75 | SFPADDI | Imm FP | VD += BF16ToFP32(imm16) |
| 0x95 | SFPLUTFP32 | `lreg_dest[4]<<4 \| instr_mod1[4]` | 3-piece FP32 LUT |

Simple sub-unit (1-cycle latency):
| Opcode | Mnemonic | Encoding | Operation |
|---|---|---|---|
| 0x76 | SFPDIVP2 | Simple | Multiply/divide by power of 2 |
| 0x77 | SFPEXEXP | Simple | Extract FP32 exponent |
| 0x78 | SFPEXMAN | Simple | Extract FP32 mantissa |
| 0x79 | SFPIADD | Simple | Integer add (VC ± VD or VC ± imm11) |
| 0x7A | SFPSHFT | Simple | Bit shift |
| 0x7B | SFPSETCC | Simple | Set per-lane condition flags |
| 0x7C | SFPMOV | Simple | Move/negate/PRNG |
| 0x7D | SFPABS | Simple | Absolute value |
| 0x7E | SFPAND | Simple | Bitwise AND |
| 0x7F | SFPOR | Simple | Bitwise OR (rare) |
| 0x80 | SFPNOT | Simple | Bitwise NOT |
| 0x81 | SFPLZ | Simple | Leading zeros (rare) |
| 0x82 | SFPSETEXP | Simple | Set FP32 exponent |
| 0x83 | SFPSETMAN | Simple | Set FP32 mantissa (rare) |
| 0x89 | SFPSETSGN | Simple | Set/clear/copy sign |
| 0x8A | SFPENCC | Simple | Enable/disable conditional execution |
| 0x8B | SFPCOMPC | Simple | Complement condition flags ("else") |
| 0x8C | SFPTRANSP | Simple | Transpose lanes (rare) |
| 0x8D | SFPXOR | Simple | Bitwise XOR (rare) |
| 0x87 | SFPPUSHC | Simple | Push condition flags |
| 0x88 | SFPPOPC | Simple | Pop condition flags |
| 0x8F | SFPNOP | `0` | SFPU no-op |
| 0x90 | SFPCAST | `lreg_src_c[4]<<8 \| lreg_dest[4]<<4 \| instr_mod1[4]` | Type cast |
| 0x91 | SFPCONFIG | `imm16_math[16]<<8 \| config_dest[4]<<4 \| instr_mod1[4]` | Write LReg[0] lane 0 → const reg |
| 0x92 | SFPSWAP | Simple | Min/max swap (2 cycles) |
| 0x94 | SFPSHFT2 | Simple | Two-source shift |
| 0x96 | SFPLE | Simple | Less-or-equal compare (BH-new, rare) |
| 0x97 | SFPGT | Simple | Greater-than compare (BH-new, rare) |
| 0x99 | SFPARECIP | Simple | Approximate 1/x (7-bit, BH-new) |
| 0x8E | SFPSTOCHRND | `rnd_mode[3]<<21 \| imm8[8]<<16 \| lreg_b[4]<<12 \| lreg_c[4]<<8 \| lreg_d[4]<<4 \| imod1[4]` | Stochastic rounding |

SFPU conditional execution:
- Each lane has a `UseLaneFlagsForLaneEnable` flag
- SFPENCC enables/disables per-lane predication
- SFPSETCC sets flags based on comparisons
- SFPPUSHC/SFPPOPC: 4-deep condition flag stack (enables SIMT if/else/endif)
- SFPCOMPC: flips flags ("else" branch)

#### Scalar unit (ThCon/DMA)
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x45 | SETDMAREG | `Payload_Size[2]<<22 \| Payload[14]<<8 \| SetSigMode[1]<<7 \| RegIdx[7]` | Load 16-bit imm → DMA reg |
| 0x58 | ADDDMAREG | `OpBConst[1]<<23 \| Result[11]<<12 \| OpB[6]<<6 \| OpA[6]` | DMA[dst] = DMA[a] + DMA[b] |
| 0x59 | SUBDMAREG | same as ADDDMAREG | DMA[dst] = DMA[a] - DMA[b] (rare) |
| 0x5A | MULDMAREG | same as ADDDMAREG | DMA[dst] = DMA[a] * DMA[b] |
| 0x5B | BITWOPDMAREG | `OpBConst[1]<<23 \| OpSel[5]<<18 \| Result[6]<<12 \| OpB[6]<<6 \| OpA[6]` | Bitwise op on DMA regs (rare) |
| 0x5C | SHIFTDMAREG | same as BITWOPDMAREG | Shift DMA reg (rare) |
| 0x5D | CMPDMAREG | same as BITWOPDMAREG | Compare DMA regs (rare) |
| 0x60 | DMANOP | `0` | DMA no-op |

#### Memory operations (Scalar unit, rare)
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x44 | RSTDMA | — | Reset DMA engine |
| 0x46 | FLUSHDMA | `FlushSpec[24]` | Flush DMA |
| 0x48 | REG2FLOP | `SizeSel[2]<<22 \| TargetSel[2]<<20 \| ByteOff[2]<<18 \| CtxId[2]<<16 \| FlopIdx[10]<<6 \| RegIdx[6]` | DMA reg → flop |
| 0x49 | LOADIND | `SizeSel[2]<<22 \| OffIdx[8]<<14 \| AutoInc[2]<<12 \| DataReg[6]<<6 \| AddrReg[6]` | Indirect load |
| 0x57 | SETDVALID | `setvalid[24]` | Set data-valid flags (rare) |
| 0x66 | STOREIND | `MemHier[1]<<23 \| SzSel[1]<<22 \| RegSzSel[1]<<21 \| OffIdx[7]<<14 \| AutoInc[2]<<12 \| DataReg[6]<<6 \| AddrReg[6]` | Indirect store |
| 0x67 | STOREREG | `TdmaDataReg[6]<<18 \| RegAddr[18]` | Store to TDMA register |
| 0x68 | LOADREG | `TdmaDataReg[6]<<18 \| RegAddr[18]` | Load from TDMA register |

#### Atomic memory ops (Scalar unit, rare)
| Opcode | Mnemonic | Bit layout |
|---|---|---|
| 0x61 | ATINCGET | `MemHier[1]<<23 \| WrapVal[9]<<14 \| Sel32b[2]<<12 \| DataReg[6]<<6 \| AddrReg[6]` |
| 0x62 | ATINCGETPTR | `MemHier[1]<<23 \| NoIncr[1]<<22 \| IncrVal[4]<<18 \| WrapVal[4]<<14 \| Sel32b[2]<<12 \| DataReg[6]<<6 \| AddrReg[6]` |
| 0x63 | ATSWAP | `MemHier[1]<<23 \| SwapMask[9]<<14 \| DataReg[6]<<6 \| AddrReg[6]` |
| 0x64 | ATCAS | `MemHier[1]<<23 \| SwapVal[5]<<18 \| CmpVal[4]<<14 \| Sel32b[2]<<12 \| DataReg[6]<<6 \| AddrReg[6]` |

#### ADC (address counter) unit
| Opcode | Mnemonic | Bit layout | Semantics |
|---|---|---|---|
| 0x50 | SETADC | `CntSetMask[3]<<21 \| ChIdx[1]<<20 \| DimIdx[2]<<18 \| Value[18]` | Set single ADC dimension (rare) |
| 0x51 | SETADCXY | `CntSetMask[3]<<21 \| Ch1_Y[6]<<15 \| Ch1_X[3]<<12 \| Ch0_Y[3]<<9 \| Ch0_X[3]<<6 \| BitMask[6]` | Set X/Y counters |
| 0x52 | INCADCXY | `CntSetMask[3]<<21 \| Ch1_Y[6]<<15 \| Ch1_X[3]<<12 \| Ch0_Y[3]<<9 \| Ch0_X[3]<<6` | Increment X/Y counters (rare) |
| 0x54 | SETADCZW | `CntSetMask[3]<<21 \| Ch1_W[6]<<15 \| Ch1_Z[3]<<12 \| Ch0_W[3]<<9 \| Ch0_Z[3]<<6 \| BitMask[6]` | Set Z/W counters |
| 0x55 | INCADCZW | `CntSetMask[3]<<21 \| Ch1_W[6]<<15 \| Ch1_Z[3]<<12 \| Ch0_W[3]<<9 \| Ch0_Z[3]<<6` | Increment Z/W counters |
| 0x5E | SETADCXX | `CntSetMask[3]<<21 \| x_end2[11]<<10 \| x_start[10]` | Set X start/end for address gen |

#### Read/write counters
| Opcode | Mnemonic | Semantics |
|---|---|---|
| 0x37 | SETRWC | Set RWC values for SrcA/SrcB/Dst/CR |
| 0x38 | INCRWC | Increment RWC values |

---

## 12. Semaphore & Synchronization Model

### 12.1 Tensix hardware semaphores

```python
class TensixSemaphore:
    def __init__(self):
        self.value = 0  # 4-bit (0–15)
        self.max = 0    # 4-bit

    def post(self):
        if self.value < self.max:
            self.value += 1

    def get(self):
        if self.value > 0:
            self.value -= 1

    def check_wait(self, cond):
        # cond=0: value == 0
        # cond=1: value >= max
        if cond == 0:
            return self.value == 0
        elif cond == 1:
            return self.value >= self.max
```

8 semaphores per tile, shared across all 3 Tensix threads.

RISCV access via MMIO at `0xFFE80020 + sem_idx * 4`:
- Read → returns current value
- Write even value → SEMPOST
- Write odd value → SEMGET

### 12.2 STALLWAIT

```python
def stallwait(self, block_mask, condition_mask):
    """
    Stall execution units in block_mask until ALL condition_mask bits are 0.

    block_mask bits (B0-B8):
      B0=Misc/Scalar/Pack/Unpack, B1=Sync, B2=Pack, B3=Unpack,
      B4=Mover, B5=Scalar, B6=FPU, B7=Config, B8=SFPU

    condition_mask bits (C0-C12):
      C0=Scalar outstanding, C1=Unpack0 busy, C2=Unpack1 busy,
      C3=Pack busy, C4=FPU busy, C5/C6=SrcA/B not owned by Unpack,
      C7/C8=SrcA/B not owned by FPU, C9=Mover busy, C10=RISCV pending,
      C11=SFPU busy, C12=Config busy
    """
    while self._check_conditions(condition_mask):
        yield  # stall for one cycle
```

### 12.3 SEMWAIT

```python
def semwait(self, block_mask, sem_mask, condition):
    """
    Stall units in block_mask until semaphore condition met.
    sem_mask: bitmask of which semaphores to check
    condition: 0=any selected sem has value==0, 1=any selected sem has value>=max
    """
    while self._check_sem_condition(sem_mask, condition):
        yield
```

### 12.4 Mutexes

4 hardware mutexes (indices 0, 2, 3, 4):
- `ATGETM(idx)`: spin until mutex is free, then acquire
- `ATRELM(idx)`: release

### 12.5 Firmware semaphore protocol

Three well-known semaphores initialized at boot:
- Sem 0 (`MATH_PACK`): max=1 (or 2 for SyncHalf), init=0
- Sem 1 (`UNPACK_TO_DEST`): max=1, init=0
- Sem 2 (`MATH_DONE`): max=1, init=0

**Dst double-buffer protocol:**
```
MATH (T1):                        PACK (T2):
  tile_regs_acquire()               tile_regs_wait()
    → SEMWAIT(value < max)            → SEMWAIT(value > 0)
  ... compute into Dst half ...     ... pack from Dst half ...
  tile_regs_commit()                tile_regs_release()
    → STALLWAIT(FPU+SFPU drain)       → ZEROACC(half)
    → SEMPOST(MATH_PACK)              → SEMGET(MATH_PACK)
    → flip Dst half                   → flip Dst half
```

### 12.6 Software semaphores (NOC-based)

Used for inter-core synchronization (e.g., matmul multicast):
- Semaphore is a 32-bit word in L1 at a known address
- `noc_semaphore_wait(ptr, val)`: spin until `*ptr == val`
- `noc_semaphore_set(ptr, val)`: `*ptr = val`
- `noc_semaphore_inc(noc_addr, incr)`: NOC atomic increment to remote tile's L1

### 12.7 BRISC ↔ TRISC sync protocol

Uses `RUN_SYNC_MSG` in mailbox area:
```
RUN_SYNC_MSG_INIT             — all cores idle
RUN_SYNC_MSG_GO               — BRISC signals "start kernel"
RUN_SYNC_MSG_DONE             — each core signals "kernel done"
RUN_SYNC_MSG_INIT_SYNC_REGS  — T0 signals "CB semaphores zeroed"
```

---

## 13. Circular Buffer Emulation

### 13.1 CB structure

```python
class CircularBuffer:
    def __init__(self, cb_id, base_addr, size, num_pages, page_size):
        self.cb_id = cb_id
        self.base_addr = base_addr   # L1 byte address of backing storage
        self.size = size             # total bytes (page_size * num_pages)
        self.num_pages = num_pages   # depth (number of tiles)
        self.page_size = page_size   # bytes per tile

        # Producer/consumer pointers (in stream registers)
        self.tiles_received = 0      # producer has written this many tiles
        self.tiles_acked = 0         # consumer has consumed this many tiles
```

### 13.2 CB ↔ Stream mapping

CB indices map to hardware streams:
```
CB 0–7   (inputs)        → streams 8–15    (unpack reads)
CB 8–15  (params)        → streams 16–23   (unpack reads)
CB 16–23 (outputs)       → streams 24–31   (pack writes)
CB 24–31 (intermediates) → streams 32–39   (both)
```

Stream ID = 8 + CB index.

### 13.3 CB config in L1

Each CB is described by 4 × u32 = 16 bytes in L1 at
`KERNEL_CONFIG_BASE + local_cb_offset + cb_id * 16`:

```c
struct CBConfig {
    uint32_t fifo_addr;       // L1 base address
    uint32_t fifo_size;       // total size in bytes
    uint32_t fifo_num_pages;  // number of pages (tiles)
    uint32_t fifo_page_size;  // page size in bytes
};
```

### 13.4 CB synchronization via stream registers

The `tiles_received` and `tiles_acked` counters live at fixed MMIO addresses in the
NOC overlay stream register space. For CB `n` (0–31):

```python
SYNC_REG_BASE   = 0xFFB48028   # tiles_received for CB 0
SYNC_REG_STRIDE = 0x10000      # per-CB stride in stream register space

tiles_received[n] = 0xFFB48028 + n * 0x10000   # offset +0x00 from per-CB base
tiles_acked[n]    = 0xFFB48020 + n * 0x10000   # offset -0x08 from per-CB base
```

TRISC0 is responsible for zeroing all 32 CB sync register pairs when it receives the
`RUN_SYNC_MSG_INIT_SYNC_REGISTERS` signal from BRISC between kernel dispatches.

Stream register general base: `0xFFB40000 + stream_id * 0x1000`.

### 13.5 CB API semantics

**Producer (e.g., unpacker writing input tiles):**
```python
def cb_reserve_back(cb, num_tiles):
    """Block until num_tiles free slots available."""
    while (cb.tiles_received - cb.tiles_acked) + num_tiles > cb.num_pages:
        yield  # stall

def cb_push_back(cb, num_tiles):
    """Signal that num_tiles have been written."""
    cb.tiles_received += num_tiles
```

**Consumer (e.g., math reading input tiles):**
```python
def cb_wait_front(cb, num_tiles):
    """Block until num_tiles are available to read."""
    while (cb.tiles_received - cb.tiles_acked) < num_tiles:
        yield  # stall

def cb_pop_front(cb, num_tiles):
    """Signal that num_tiles have been consumed."""
    cb.tiles_acked += num_tiles
```

### 13.6 Data layout in L1

CB data starts at `DATA_BUFFER_SPACE_BASE = 0x037000`. Tiles are stored contiguously
within each CB's allocation. The write pointer wraps: `write_addr = base + (tiles_received
% num_pages) * page_size`.

### 13.7 Tile format

Tiles are 32×32 elements, arranged as 4 faces of 16×16 in face-major order:
`(face_r, face_c, row, col)` where face_r/face_c ∈ {0,1}.

Tile sizes by data type:
| Dtype | BPE | Tile bytes |
|---|---|---|
| Float32 / Int32 / UInt32 | 4 | 4096 |
| Float16 / Float16_b / UInt16 | 2 | 2048 |
| Int8 / UInt8 | 1 | 1024 |

---

## 14. Unpack Pipeline Model

### 14.1 UNPACR instruction

`UNPACR(block_sel, ...)`:
- `block_sel=0`: unpack to SrcA (Unpacker 0)
- `block_sel=1`: unpack to SrcB (Unpacker 1)

Reads tile data from L1 (at address determined by CB config + ADC counters), converts
format, and loads into the appropriate SrcA/SrcB bank.

### 14.2 Format conversion

On-the-fly conversion during unpack:
- BFP8 → BF16 (expand shared exponent)
- FP32 → TF32 (truncate mantissa to 10 bits)
- FP16 → internal 19-bit format
- BF16 → internal 19-bit format
- Controlled by `ALU_FORMAT_SPEC_REG0_SrcA` / `SrcB` config fields

### 14.3 Special modes

- **XY transpose** (`haloize_mode=1`, Unpacker 0 only): swap low 4 row bits with column index
- **Tilize** (`tileize_mode=1`): gather row-major L1 data into tiled SrcA
- **Unpack-to-Dst** (`UnpackToDst=1`): write directly to Dst instead of SrcA

### 14.4 Ownership protocol

SrcA/SrcB banks are double-buffered. Ownership alternates between Unpackers and FPU:
- `SETDVALID`: Unpacker signals "bank ready for FPU"
- `CLEARDVALID`: FPU signals "bank consumed, Unpacker can refill"

---

## 15. Pack Pipeline Model

### 15.1 PACR instruction

Reads 16 rows from Dst and writes to L1. Multiple PACR calls pack a full tile
(4 faces × 16 rows = 4 PACR calls per 32×32 tile).

### 15.2 Pipeline stages

```
Dst → Edge Mask → Format Conv → ReLU → Exp Threshold → Late Conv → L1
```

- **Edge masking**: 16-bit column mask, replace masked with 0 or -inf
- **ReLU**: 4 modes (none, zero, min-threshold, max-threshold) — free in HW
- **Format conversion**: e.g., FP32 Dst → BF16 L1, with optional shared exponent (BFP)
- **L1 accumulation** (`PACKER_L1_ACC`): `L1[addr] += packed_value` instead of overwrite

### 15.3 Known bugs

**Packer L1 accumulation + IEEE Float16**: produces NaN (0x7fff/0xffff) when combining
FPU matmul + L1 acc + IEEE FP16 + multiple sub-blocks. BF16 and FP32 work correctly.
The emulator should model this bug (configurable flag to enable/disable).

---

## 16. FPU Computation Model

### 16.1 MVMUL (matrix-vector multiply)

```python
def mvmul(self, fidelity_phase=0):
    """Dst += SrcB @ SrcA for one 8×16 face."""
    # SrcA: 8 rows (selected by RWC_A) × 16 cols
    # SrcB: 16 rows × 16 cols
    # Result: 8 rows × 16 cols accumulated into Dst

    for dst_row in range(8):
        for dst_col in range(16):
            acc = self.read_dst(dst_row_addr + dst_row, dst_col)
            for k in range(16):
                a = self.decode_src(self.srca[row_a + dst_row][k], fidelity_phase, 'a')
                b = self.decode_src(self.srcb[k][dst_col], fidelity_phase, 'b')
                acc += a * b
            self.write_dst(dst_row_addr + dst_row, dst_col, acc)
```

### 16.2 Fidelity phases

The FPU multiplier is bandwidth-limited: 5 bits of SrcA mantissa × 7 bits of SrcB
mantissa per phase:

| Phase | SrcA bits | SrcB bits |
|---|---|---|
| 0 (LoFi) | [9:5] | [9:3] |
| 1 (HiFi2) | [4:0] | [9:3] |
| 2 (HiFi3) | [9:5] | [2:0]+pad |
| 3 (HiFi4) | [4:0] | [2:0]+pad |

**LLK convention**: in0 ("A" matrix) → SrcB (7-bit path), in1 ("B" matrix) → SrcA
(5-bit path). This is swapped from the mathematical convention.

For exact BF16: HiFi2 is sufficient (7+7 ≤ 14 mantissa bits).
For exact FP16/TF32: HiFi4 required.

### 16.3 Accumulation modes

- **Dst16b**: accumulate in BF16/FP16 (16 tiles capacity)
- **Dst32b**: accumulate in FP32 (8 tiles capacity, ~26% throughput reduction)
- Controlled by `ALU_ACC_CTRL_Fp32_enabled` config bit

### 16.4 RWC (Read/Write Counter) mechanics

MVMUL's `addr_mode` field selects one of 8 pre-programmed `ADDR_MOD` slots (0–7).
Each slot holds: `{srca.incr, srca.clr, srca.cr, srcb.incr, srcb.clr, srcb.cr,
dest.incr, dest.clr, dest.cr, fidelity.incr, fidelity.clr}`.

After each MVMUL the hardware:
1. Adds `srca.incr` to RWC_A (selects next SrcA block)
2. Adds `srcb.incr` to RWC_B (selects next 8 SrcB rows)
3. Adds `dest.incr` to RWC_D (advances Dst write pointer)
4. If `clr=1`: resets counter to CR (count-reset value) instead
5. `fidelity.incr`: advances the fidelity phase counter for multi-phase math

Typical matmul ADDR_MOD_0: `{srca.incr=0, srcb.incr=8, dest.incr=8}` — SrcA stays fixed,
SrcB advances by 8 rows, Dst advances by 8 rows. After 4 MVMULs, a final ADDR_MOD resets
all counters and optionally increments the fidelity phase.

### 16.5 Dst address remapping

`DEST_ACCESS_CFG` config register (ADDR32=220) controls row remapping:

| Bit | Field | Purpose |
|---|---|---|
| 0 | `swizzle_32b` | Column-pair swizzle within each row group |
| 1 | `remap_addrs` | Enable Adj32 row remapping |
| 3 | `zeroacc_absolute_tile_mode` | ZEROACC uses absolute tile addressing |

**`remap_addrs` transform** (Adj32): Within bits [5:3] of the row address, the pattern
`{b5,b4,b3}` becomes `{b3,b5,b4}`:
```python
def remap_row(row_id):
    return (row_id & 0xFFC7) | ((row_id & 0x0008) << 2) | ((row_id & 0x0030) >> 1)
```

**Float32 Dst encoding**: In 32b mode, logical row R maps to two physical 16-bit rows
8 apart: `phys_row = ((R & 0xFFF8) << 1) | (R & 0x7)`. The low 16-bit word (exp+top
mantissa) is at `phys_row`, the high word (low mantissa) at `phys_row + 8`.

### 16.6 ELWADD, ELWMUL, ELWSUB

Element-wise operations on aligned SrcA/SrcB rows → Dst. Same face structure as MVMUL.

---

## 17. SFPU Computation Model

### 17.1 SFPLOAD / SFPSTORE addressing

```python
def sfp_effective_addr(base_imm, dst_offset):
    """Compute which Dst rows/cols are accessed."""
    addr = base_imm + dst_offset
    for lane in range(32):
        row = (addr & ~3) + (lane // 8)   # 4 consecutive Dst rows
        col = (lane & 7) * 2 + (addr & 2) # 8 even or 8 odd columns
        yield lane, row, col
```

One SFPLOAD accesses half the columns of 4 Dst rows → 32 elements into one LReg.
Full 32×32 tile (64 Dst rows) needs 16 SFPLOAD/SFPSTORE pairs for even columns, or 32
for all columns.

### 17.2 SFPLOAD / SFPSTORE modes

`sfpu_addr_mode` (3-bit field):

| Value | Effect |
|---|---|
| 0–6 | Normal increment mode: `dest_reg_addr` selects ADDR_MOD slot for RWC increment |
| 7 | No-increment mode (`SFPLOAD_ADDR_MODE_NOINC`): `dest_reg_addr` is an absolute Dst row address |

`instr_mod0` (4-bit field) selects format conversion:

| Value | SFPLOAD interpretation | SFPSTORE interpretation |
|---|---|---|
| 0 | Use current SrcB format config | Use current SrcB format |
| 1 (FP16A) | IEEE FP16 → FP32 into LReg | LReg → IEEE FP16 in Dst |
| 2 (FP16B) | BF16 → FP32 into LReg | LReg → BF16 in Dst |
| 3 (FP32) | Load FP32 directly | Store FP32 directly |
| 4 (BOB32) | Bag-of-bits 32-bit (no conversion) | BOB32/Int32 |
| 5 | — | Int8 |
| 6 | — | UInt16 |

One SFPLOAD accesses 4 Dst rows × 8 columns (even or odd column set) = 32 lanes.
`SFP_DESTREG_STRIDE = 2`: incrementing `dest_reg_addr` by 2 steps between even and odd
column subsets of the same 4 rows.

### 17.3 SFPSETCC comparison modes

`instr_mod1` (4-bit field) selects the comparison:

| Value | Constant | Semantics |
|---|---|---|
| 0 | `LREG_LT0` | flag = (VC < 0) |
| 1 | `IMM_BIT0` | flag = imm12[0] (constant per-lane) |
| 2 | `LREG_NE0` | flag = (VC != 0) |
| 4 | `LREG_GTE0` | flag = (VC >= 0) |
| 6 | `LREG_EQ0` | flag = (VC == 0) |
| 8 | `COMP` | complement existing flags (same as SFPCOMPC) |

### 17.4 SFPMOV modes

`instr_mod1` (4-bit field):

| Value | Effect |
|---|---|
| 0 | Plain move: `VD = VC` |
| 1 | Complement sign: `VD = -VC` (flip sign bit) |
| 8 | Config mode: `VD = <programmable constant register>` (selected by lreg_c) |

PRNG mode is accessed via `SFPMOV` with config mode + `SFPCONFIG_SRC_RAND = 9`: generates
a 32-bit LFSR output per lane into VD. The PRNG seed is at config register
`PRNG_SEED_Seed_Val` (ADDR32=186), initialized to 0 by TRISC firmware at boot.

### 17.5 SFPLUTFP32 modes

`instr_mod1` selects LUT type:

| Value | Mode | Semantics |
|---|---|---|
| 0 | FP32_3ENTRY_TABLE | `VD = LReg[i] * |LReg[3]| + LReg[4+i]` where i∈{0,1,2} selected by `|LReg[3]|` magnitude |
| 2 | FP16_6ENTRY_TABLE1 | 6-entry FP16 LUT, first half |
| 3 | FP16_6ENTRY_TABLE2 | 6-entry FP16 LUT, second half |
| 10 | FP16_3ENTRY_TABLE | 3-entry FP16 LUT |
| +4 | SGN_RETAIN | OR with above: preserve input sign (default: update sign) |

For 3-piece FP32 mode: LReg[0–2] hold slopes, LReg[3] is input, LReg[4–6] hold
intercepts. Hardware uses `|LReg[3]|` to select piece `i`.

### 17.6 SFPSTOCHRND modes

`rnd_mode` (3-bit field, bits [23:21]):

| Value | Mode |
|---|---|
| 0 | Round-to-nearest-even (deterministic) |
| 1 | Stochastic rounding (uses per-lane LFSR/PRNG) |

`instr_mod1` (4-bit field) selects conversion type:

| Value | Conversion |
|---|---|
| 0 | FP32 → IEEE FP16 |
| 1 | FP32 → BF16 |
| 2 | FP32 → uint8 |
| 3 | FP32 → int8 |
| 4 | sign-mag INT32 → uint8 |
| 5 | sign-mag INT32 → int8 |
| 6 | FP32 → uint16 |
| 7 | FP32 → int16 |
| +8 | OR flag: use `imm8_math` field as shift amount (INT→INT right-shift-and-round) |

### 17.7 SFPCAST modes

`instr_mod1` (4-bit field):

| Value | Conversion |
|---|---|
| 0 | sign-mag INT32 → FP32, round-to-nearest-even |
| 1 | sign-mag INT32 → FP32, round nearest stochastic |
| 2 | sign-magnitude → two's-complement INT32 |
| 3 | two's-complement INT32 → sign-magnitude |

**Known HW bug**: mode 2 converts sign-mag -0 to the most-negative INT32 instead of zero.

### 17.8 Conditional execution

```python
class SFPUCondState:
    def __init__(self):
        self.enabled = False
        self.lane_flags = [True] * 32   # per-lane enable
        self.flag_stack = []            # up to 4 deep

    def setcc(self, lreg, comparison):
        """Set flags based on comparison of LReg values."""
        for lane in range(32):
            self.lane_flags[lane] = compare(lreg[lane], comparison)

    def pushc(self):
        self.flag_stack.append(self.lane_flags[:])

    def popc(self):
        self.lane_flags = self.flag_stack.pop()

    def compc(self):
        """Complement: flip all flags (else branch)."""
        self.lane_flags = [not f for f in self.lane_flags]
```

When conditional execution is enabled (`SFPENCC`), only lanes with `flag=True` execute
the instruction; other lanes retain their previous value.

### 17.3 PRNG

32-bit LFSR per lane, used by `SFPMOV` (mode=PRNG) and `SFPSTOCHRND` for stochastic
rounding. Seed initialized by hardware; emulator should use a deterministic seed.

---

## 18. Tensix Backend Configuration

### 18.1 Config registers

```python
class TensixConfig:
    def __init__(self):
        # Two ping-pong banks of config state
        self.config = [bytearray(CFG_STATE_SIZE * 4) for _ in range(2)]
        # Plus dual-write bank (writes go to both)
        self.config_dual = bytearray(CFG_STATE_SIZE * 4)
        # Per-thread config (3 threads)
        self.thread_config = [[0] * THD_STATE_SIZE for _ in range(3)]
        # Active bank per thread
        self.cfg_state_id = [0, 0, 0]
```

RISCV access at `0xFFEF0000`:
- Writes to Config are auto-synchronized with Tensix pipeline (Auto TTSync)
- ThreadConfig only writable via `SETC16` Tensix instruction

### 18.2 Key config fields

| Field | Purpose |
|---|---|
| `ALU_ACC_CTRL_Fp32_enabled` | FP32 vs FP16 accumulation in Dst |
| `ALU_FORMAT_SPEC_REG0_SrcA/SrcB` | Input data format |
| `DEST_REGW_BASE_Base` | Base row offset in Dst |
| `DEST_ACCESS_CFG_remap_addrs` | Dst address remapping mode |
| `CFG_STATE_ID_StateID` | Active Config bank (ThreadConfig) |
| `FIDELITY_BASE_Phase` | Starting fidelity phase (ThreadConfig) |
| `RISC_DEST_ACCESS_CTRL_SEC[i].fmt` | Dst RISCV access format |

---

## 19. NOC Overlay / Stream Registers

64 streams per tile, base `0xFFB40000`, stride `0x1000` per stream.

Used primarily for:
1. CB tile counters (`tiles_received`, `tiles_acked`)
2. Dispatch message delivery (stream 48)
3. DMA coprocessor commands (firmware-managed)

The emulator needs to model the stream registers that CB synchronization reads/writes,
and stream 48 for dispatch signaling. Full stream overlay DMA is a stretch goal.

---

## 20. Host Interface

### 20.1 Sysmem model

```python
class HostInterface:
    def __init__(self, sysmem_size=96 * 1024 * 1024):
        self.sysmem = bytearray(sysmem_size)  # host hugepage memory

    def write_to_device(self, tile_xy, local_addr, data):
        """Host writes to a tile's L1 or MMIO (via TLB)."""
        ...

    def read_from_device(self, tile_xy, local_addr, length):
        """Host reads from a tile (slow, MMIO path)."""
        ...
```

### 20.2 Device-to-host writes

When a tile writes to `4ULL << 58` + offset (= `1 << 60`), the data lands in sysmem at
the specified offset. The emulator routes these to `HostInterface.sysmem`. The PCIe tile
is at NOC coordinates `(x=19, y=24)`.

### 20.3 Firmware boot sequence

#### Step 1: Host asserts full soft reset
```python
SOFT_RESET_0 ← 0x47800   # SOFT_RESET_ALL: all 5 cores held in reset
```
Written via multicast TLB write to `0xFFB121B0`.

#### Step 2: Host uploads firmware
Via multicast writes to L1:
- All firmware segments for BRISC, NCRISC, TRISC0/1/2 at their respective text bases
- A `JAL` instruction at L1 address 0 that jumps to `BRISC_FIRMWARE_BASE (0x3840)`
- `GO_MSG` signal byte initialized to `RUN_MSG_INIT (0x40)` at `L1[0x370 + 3]`
- Bank-to-NOC table written to `MEM_BANK_TO_NOC_SCRATCH (0x0116B0)`
- Core info (logical X/Y) written to `L1[0x09A0]` / `L1[0x09A1]`

#### Step 3: Host programs subordinate reset PCs
Via UC TLB writes:
```
0xFFB12228 ← TRISC0 text base (0x5A40)
0xFFB1222C ← TRISC1 text base (0x6040)
0xFFB12230 ← TRISC2 text base (0x6A40)
0xFFB12238 ← NCRISC text base (0x5440)
```

#### Step 4: Host releases BRISC only
```python
SOFT_RESET_0 ← 0x47000   # SOFT_RESET_BRISC_ONLY_RUN
```

#### Step 5: Host polls for boot completion
Reads `L1[GO_MSG + 3]` until it equals `RUN_MSG_DONE (0x00)`. Timeout: 2 seconds.

#### Step 6: BRISC firmware init
BRISC `main()` executes:
1. **`configure_csr()`**: CSR 0x7C0 ← bit 18 (gathering disabled) + bit 3 (L0 cache
   disabled). Sequence: `CSRS bit1, fence, CSRS bit18, fence, CSRC bit1, fence, fence,
   CSRS bit3`.
2. **`do_crt1()`**: zeros BSS (`LDM_BASE+4` .. `+0x6C0`), copies init image from
   `MEM_BRISC_INIT_SCRATCH (0x86B0)` to LDM.
3. **`noc_bank_table_init()`**: initializes DRAM bank address translation tables.
4. **`risc_init()`**: reads NOC0/NOC1 node ID registers (`0xFFB20148`/`0xFFB30148`),
   extracts X/Y coordinates, stores to `my_x[0/1]` and `my_y[0/1]` in LDM.
5. **`device_setup()`**:
   - Writes 0 to `RISCV_DEBUG_REG_DEST_CG_CTRL (0xFFB12240)`
   - Enables wall clock: `0xFFB11024` ← 63
   - Enables NOC overlays (ORs bit 0 into NOC cfg registers)
   - Programs reset PC override: `0xFFB12234` ← 7, `0xFFB1223C` ← 1
   - Zeros Tensix scratch memory (range `0x240..0x440`)
   - Invalidates icache: `TENSIX_CFG_BASE + 0x2E4` ← 31
   - Executes Tensix init: `ZEROACC`, `ENCC`, loads LReg constants, RMW config words,
     initializes hardware semaphores
6. **`deassert_ncrisc_trisc()`**:
   - Writes `RUN_SYNC_MSG_ALL_INIT (0x40404040)` to subordinate_sync
   - Writes 0 to `SOFT_RESET_0` — releases all cores from reset
7. **`wait_ncrisc_trisc()`**: polls subordinate_sync until `0x00000000` (all subordinates
   report DONE).
8. Writes `RUN_MSG_DONE (0x00)` to `go_messages[0].signal` — signals host boot complete.
9. **`noc_init()` + `noc_local_state_init()`**: initializes NOC command buffers and
   software counters.
10. **`trigger_sync_register_init()`**: writes `RUN_SYNC_MSG_INIT_SYNC_REGISTERS (0x03)`
    to TRISC0's byte of subordinate_sync.
11. Enters main dispatch loop.

#### NCRISC boot (runs after BRISC releases reset)
1. `configure_csr()` — identical to BRISC
2. `do_crt1()` — zeros BSS, copies init from `0xA6B0`
3. `risc_init()` — reads NOC node IDs
4. Writes `DONE (0x00)` to byte 0 of subordinate_sync
5. Enters `wait_notify` loop: polls `L1[0x68]` for LOAD (0x40) or GO (0x80) signals

#### TRISC boot (runs after BRISC releases reset)
1. `configure_csr()` — identical to BRISC
2. `do_crt1()` — zeros BSS, copies init from respective scratch
3. Zeros 64 GPR entries at `0xFFE00000..0xFFE00100`
4. Zeros PRNG seed, waits 600 clock cycles
5. Writes `DONE (0x00)` to its byte of subordinate_sync (`0x69 + trisc_id`)
6. Enters poll loop on its subordinate_sync byte

### 20.4 RUN_SYNC_MSG protocol

The subordinate_sync word (4 bytes at L1 pointer stored in `L1[0x68]`) has 4 byte lanes:

| Byte | Lane | Writer → Reader |
|---|---|---|
| 0 | NCRISC | BRISC → NCRISC |
| 1 | TRISC0 | BRISC → TRISC0 |
| 2 | TRISC1 | BRISC → TRISC1 |
| 3 | TRISC2 | BRISC → TRISC2 |

Signal values:
| Constant | Value | Meaning |
|---|---|---|
| `RUN_SYNC_MSG_DONE` | `0x00` | Core idle/done |
| `RUN_SYNC_MSG_INIT` | `0x40` | Core initializing |
| `RUN_SYNC_MSG_GO` | `0x80` | Run kernel now |
| `RUN_SYNC_MSG_LOAD` | `0x40` | NCRISC: load CB config |
| `RUN_SYNC_MSG_INIT_SYNC_REGISTERS` | `0x03` | TRISC0: zero CB sync registers |
| `RUN_SYNC_MSG_ALL_INIT` | `0x40404040` | All four bytes = INIT |

#### Per-kernel dispatch protocol
```
BRISC dispatch:
  1. If NCRISC enabled: byte 0 ← LOAD (0x40)
     [NCRISC wakes, sets up CBs, waits for GO]
  2. Set TRISC bytes to GO (0x80) for enabled TRISCs
  3. If NCRISC enabled: byte 0 ← GO (0x80)
  4. BRISC runs its own kernel
  5. wait_ncrisc_trisc(): poll subordinate_sync until == 0x00000000
  6. trigger_sync_register_init(): byte 1 ← 0x03
     [TRISC0 zeros tiles_received/tiles_acked for 32 CBs, writes DONE back]
```

### 20.5 Go message protocol

`go_msg_t` at `L1[0x370 + index * 4]` (4 bytes each):

| Byte | Field | Description |
|---|---|---|
| 0 | `dispatch_message_offset` | Offset into dispatch ring |
| 1 | `master_x` | Dispatch core X (used for NOC completion notify) |
| 2 | `master_y` | Dispatch core Y |
| 3 | `signal` | Go/done flag |

Signal values:
| Constant | Value | Direction |
|---|---|---|
| `RUN_MSG_INIT` | `0x40` | Host → tile: initial value |
| `RUN_MSG_GO` | `0x80` | Host/dispatch → tile: launch kernel |
| `RUN_MSG_DONE` | `0x00` | Tile → host: kernel done |
| `RUN_MSG_RESET_READ_PTR` | `0xC0` | Host → tile: reset launch ring rd_ptr |
| `RUN_MSG_REPLAY_TRACE` | `0xF0` | Host → tile: replay trace |

### 20.6 Launch message structure

Launch messages form a ring buffer of 8 × 96-byte entries at `L1[0x70]`. Read pointer
at `L1[0x6C]`, masked with `& 7`.

| Offset | Field | Type | Description |
|---|---|---|---|
| 0 | `kernel_config_base[0..2]` | u32×3 | Base addr for TENSIX/DM0/DM1 config sections |
| 12 | `sem_offset[0..2]` | u16×3 | Semaphore region offset from config_base |
| 18 | `local_cb_offset` | u16 | CB config offset from config_base |
| 20 | `remote_cb_offset` | u16 | Remote CB config offset |
| 22 | `rta_offset[0..4]` | struct×5 | Per-processor: rta_offset(u16) + crta_offset(u16) |
| 42 | `mode` | u8 | 0=DISPATCH_MODE_DEV, 1=DISPATCH_MODE_HOST |
| 44 | `kernel_text_offset[0..4]` | u32×5 | Text offset: [0]=BRISC, [1]=NCRISC, [2..4]=TRISC0/1/2 |
| 64 | `local_cb_mask` | u32 | Bitmask of active local CBs |
| 68 | `brisc_noc_id` | u8 | NOC index for BRISC (typically 1) |
| 69 | `brisc_noc_mode` | u8 | 0=dedicated |
| 70 | `min_remote_cb_start_index` | u8 | Set to 32 |
| 72 | `host_assigned_id` | u32 | Profiler ID |
| 76 | `enables` | u32 | Bitmask: bit0=BRISC, bit1=NCRISC, bit2+=TRISCs |
| 92 | `sub_device_origin_x` | u8 | Sub-device grid origin X |
| 93 | `sub_device_origin_y` | u8 | Sub-device grid origin Y |
| 95 | `preload` | u8 | 0x80 if preload enabled |

### 20.7 LDM (Local Data Memory) layout

#### BRISC LDM (`0xFFB00000`, 8 KiB)

| Address | Field | Description |
|---|---|---|
| `0xFFB00000` | subordinate_sync | 4 sync bytes (NCRISC/T0/T1/T2) |
| `0xFFB00004` | my_y[0] | NOC0 Y coordinate |
| `0xFFB00008` | my_x[0] | NOC0 X coordinate |
| `0xFFB0000C` | active_noc_instance | Active NOC for this core |
| `0xFFB0000C` | reads_issued | NOC reads issued counter |
| `0xFFB00010` | nonposted_writes_issued | — |
| `0xFFB00014` | nonposted_writes_acked | — |
| `0xFFB0001C` | posted_writes_issued | — |
| `0xFFB00024` | nonposted_atomics_acked | — |
| `0xFFB00030` | crta_l1_base | CRTA L1 base address |
| `0xFFB00034` | rta_l1_base | RTA L1 base address |
| `0xFFB00044` | my_logical_y | Logical Y coordinate |
| `0xFFB00045` | my_logical_x | Logical X coordinate |
| `0xFFB00046` | noc_index | NOC index byte |
| `0xFFB00048` | cb_interface[32] | CB interface array (32 bytes each) |
| `0xFFB006C0` | BSS end | End of BRISC BSS |
| `0xFFB007F0` | GP | Global pointer |
| `0xFFB01FF0` | SP | Stack pointer (8 KiB stack) |

#### NCRISC LDM (`0xFFB00000`, 8 KiB)

| Address | Field |
|---|---|
| `0xFFB00004` | reads_issued |
| `0xFFB00008` | nonposted_writes_issued |
| `0xFFB0000C` | nonposted_writes_acked |
| `0xFFB00010` | nonposted_atomics_acked |
| `0xFFB00014` | posted_writes_issued |
| `0xFFB00038` | my_logical_y |
| `0xFFB00039` | my_logical_x |
| `0xFFB0003C` | my_y[2] |
| `0xFFB00040` | my_x[2] |
| `0xFFB00044` | cb_interface[32] |
| `0xFFB01FF0` | SP (8 KiB stack) |

#### TRISC LDM (`0xFFB00000`, 4 KiB)

TRISC0/TRISC2 (unpack/pack):

| Address | Field |
|---|---|
| `0xFFB00000` | dest_offset_id |
| `0xFFB0000C` | my_relative_y |
| `0xFFB0000D` | my_relative_x |
| `0xFFB00010` | crta_l1_base |
| `0xFFB00014` | rta_l1_base |
| `0xFFB00018` | my_logical_y |
| `0xFFB00019` | my_logical_x |
| `0xFFB0001C` | cfg_state_id |
| `0xFFB00020` | cb_interface |
| `0xFFB00FF0` | SP (4 KiB stack) |

TRISC1 (math — no CB interface):

| Address | Field |
|---|---|
| `0xFFB00014` | my_logical_y |
| `0xFFB00015` | my_logical_x |
| `0xFFB00018` | cfg_state_id |
| `0xFFB00FF0` | SP (4 KiB stack) |

### 20.8 CB local interface structure

Each CB entry in the LDM `cb_interface` array is 32 bytes:

| Offset | Field | Description |
|---|---|---|
| 0 | `fifo_size` | FIFO size in bytes |
| 4 | `fifo_limit` | FIFO limit address |
| 8 | `fifo_page_size` | Page size in bytes |
| 12 | `fifo_num_pages` | Number of pages |
| 16 | `fifo_rd_ptr` | Read pointer |
| 20 | `fifo_wr_ptr` | Write pointer |
| 24 | `tiles_acked_received_init` | Init value for tiles counters |
| 28 | `fifo_wr_tile_ptr` | Write tile pointer (pack only) |

### 20.9 PCBuf (BRISC ↔ TRISC synchronization)

PC buffer bases for Tensix instruction completion handshake:
```python
PC_BUF_BASES = (0xFFE80000, 0xFFE90000, 0xFFEA0000)
# TRISC0 → 0xFFE80000, TRISC1 → 0xFFE90000, TRISC2 → 0xFFEA0000
```

After a TRISC kernel finishes, the TRISC performs `tensix_sync()`: writes to its PC buffer
slot at offset +4, then reads back. The read stalls until the Tensix fabric acknowledges
(effectively a synchronization barrier). BRISC monitors these to detect kernel completion.

### 20.10 Tensix init via firmware

During `device_setup()`, BRISC pushes these Tensix instructions:
```python
TENSIX_WZEROACC   = 0x10180000   # Zero accumulator
TENSIX_WENCC      = 0x8A00300A   # Enable conditional execution
TENSIX_WNOP       = 0x02000000   # NOP
TENSIX_WLOAD_CONST = 0x7100BF80  # SFPLOADI: load -1.0 (BF16=0xBF80) into LReg
TENSIX_WCONFIG_LREG11 = 0x910000B0  # SFPCONFIG: write LReg[0] to LReg[11]
TENSIX_SEMINIT_BASE   = 0xA3100000  # Semaphore init opcode base
```

Config register initialization via RMW:
- Config word 0: mask=0x1, value=1
- Config word 2: mask=0x1, value=1
- Config word 3: mask=0x3FF8, value=256

Icache invalidate mask: `RISCV_IC_ALL_MASK = 0x1F` (all 5 cores).

---

## 21. Device Grid

### 21.1 Tile coordinates

P100 (120 Tensix cores):
- X: {1,2,3,4,5,6,7,10,11,12,13,14} (12 columns)
- Y: {2,3,4,5,6,7,8,9,10,11} (10 rows)
- Dispatch: (14,2) prefetch, (14,3) dispatch
- Available workers: 110 cores (excluding dispatch)

P150 (140 Tensix cores):
- X: {1,2,3,4,5,6,7,10,11,12,13,14,15,16} (14 columns)
- Y: {2,3,4,5,6,7,8,9,10,11} (10 rows)
- Dispatch: (16,2) prefetch, (16,3) dispatch

### 21.2 DRAM tile coordinates

From `hw.py` (authoritative source):
```python
BANK_TILE_YS = {
    0: (0, 1, 11),   1: (2, 3, 10),   2: (4, 8, 9),   3: (5, 6, 7),
    4: (0, 1, 11),   5: (2, 3, 10),   6: (4, 8, 9),   7: (5, 6, 7),
}
BANK_X = {b: 0 if b < 4 else 9 for b in range(8)}

# Per-bank port selection by NOC ID:
BANK_PORT = [[2,1],[0,1],[0,1],[0,1],[2,1],[2,1],[2,1],[2,1]]
# BANK_PORT[bank][noc_id] → index into BANK_TILE_YS tuple
```

| Bank | X | Port Y values (3 tiles) | NOC0 port idx | NOC1 port idx |
|---|---|---|---|---|
| 0 | 0 | 0, 1, 11 | 2 (Y=11) | 1 (Y=1) |
| 1 | 0 | 2, 3, 10 | 0 (Y=2) | 1 (Y=3) |
| 2 | 0 | 4, 8, 9 | 0 (Y=4) | 1 (Y=8) |
| 3 | 0 | 5, 6, 7 | 0 (Y=5) | 1 (Y=6) |
| 4 | 9 | 0, 1, 11 | 2 (Y=11) | 1 (Y=1) |
| 5 | 9 | 2, 3, 10 | 2 (Y=10) | 1 (Y=3) |
| 6 | 9 | 4, 8, 9 | 2 (Y=9) | 1 (Y=8) |
| 7 | 9 | 5, 6, 7 | 2 (Y=7) | 1 (Y=6) |

### 21.3 Coordinate translation

The emulator should support translated coordinates (used by NOC1). Translation tables
are programmed in NIU_CFG registers at `0xFFB20118–0x144`. When bit 14 of NIU_CFG_0 is
set, X/Y coordinates in NOC commands are translated through these tables before routing.

---

## 22. Execution Model

### 22.1 Main loop

```python
class EmulatedDevice:
    def step(self):
        """Advance one global tick."""
        # 1. Step all RISCV cores (round-robin across tiles)
        for tile in self.tiles.values():
            for core in tile.cores:
                if not core.in_reset and not core.halted:
                    core.step()

        # 2. Step all Tensix coprocessors
        for tile in self.tiles.values():
            tile.tensix.step()

        # 3. Step NOC fabric (deliver pending transactions)
        self.noc.tick()

        self.cycle += 1

    def run_until_done(self, max_cycles=10_000_000):
        """Run until all cores halt or timeout."""
        while self.cycle < max_cycles:
            self.step()
            if self.all_done():
                break
```

### 22.2 "Done" detection

A kernel is done when BRISC writes `RUN_MSG_DONE` to the dispatch stream (stream 48).
The host polls for this completion signal.

### 22.3 Multi-core execution

All tiles execute concurrently in the round-robin. NOC transactions have a configurable
latency (default: 1 tick for same-tile, proportional to Manhattan distance for
cross-tile). This is cycle-approximate, not cycle-exact.

---

## 23. Data Types

### 23.1 Format conversion utilities

```python
import struct

def fp32_to_bf16(f):
    """Truncate FP32 to BF16 (top 16 bits)."""
    bits = struct.unpack('<I', struct.pack('<f', f))[0]
    return (bits >> 16) & 0xFFFF

def bf16_to_fp32(bf16):
    """Expand BF16 to FP32."""
    bits = bf16 << 16
    return struct.unpack('<f', struct.pack('<I', bits))[0]

def fp32_to_fp16(f):
    """Convert FP32 to IEEE FP16 (non-conformant: no inf/NaN)."""
    ...

def fp32_to_tf32(f):
    """Truncate FP32 to TF32 (19-bit: 1+8+10)."""
    bits = struct.unpack('<I', struct.pack('<f', f))[0]
    return bits & 0xFFFFE000  # zero low 13 mantissa bits

def shuffled_to_ieee(val_19bit):
    """Convert {sign, mantissa, exponent} to IEEE {sign, exponent, mantissa}."""
    sign = (val_19bit >> 18) & 1
    mantissa = (val_19bit >> 8) & 0x3FF
    exponent = val_19bit & 0xFF
    return (sign << 31) | (exponent << 23) | (mantissa << 13)

def ieee_to_shuffled(ieee_bits):
    """Convert IEEE FP32 to 19-bit shuffled {sign, mantissa, exponent}."""
    sign = (ieee_bits >> 31) & 1
    exponent = (ieee_bits >> 23) & 0xFF
    mantissa = (ieee_bits >> 13) & 0x3FF
    return (sign << 18) | (mantissa << 8) | exponent
```

### 23.2 Sign-magnitude integers

Tensix uses sign-magnitude (not two's complement) for integers in Dst and SFPU:
```python
def int_to_signmag(val, bits=32):
    if val < 0:
        return (1 << (bits-1)) | (-val & ((1 << (bits-1)) - 1))
    return val

def signmag_to_int(val, bits=32):
    sign = (val >> (bits-1)) & 1
    mag = val & ((1 << (bits-1)) - 1)
    return -mag if sign else mag
```

---

## 24. PIC (Programmable Interrupt Controller)

Base: `0xFFB13000`. 32 software IRQs + 4 hardware IRQs.

```python
class PIC:
    def __init__(self):
        self.sw_int = [0] * 32          # atomic single-slot queues
        self.hw_int = [0] * 4
        self.brisc_sw_int_en = 0        # enable mask
        self.brisc_hw_int_en = 0
        self.ncrisc_sw_int_en = 0
        self.ncrisc_hw_int_en = 0
        self.sw_int_pc = [0] * 32       # handler PCs
        self.hw_int_pc = [0] * 4
```

Model as needed; initially stub out (no interrupt delivery in V1).

---

## 25. Implementation Plan

### Phase 1: Core infrastructure
1. `RiscVCore` — full RV32IM + Zicsr + Zaamo + Zba + Zbb decoder and executor
2. `L1Memory` — 1536 KiB scratchpad with atomic support
3. `TensixTile` — glue: 5 cores + L1 + memory map decoder
4. `EmulatedDevice` — grid of tiles + main loop
5. Memory map routing (loads/stores to correct backing store)

### Phase 2: Tensix coprocessor
6. Instruction FIFO + MOP expander + replay buffer
7. Sync unit (STALLWAIT, SEMWAIT, semaphores, mutexes)
8. SrcA/SrcB/Dst register files with format conversion
9. FPU: MVMUL, ELWADD, ELWMUL, ZEROACC, ZEROSRC, MOVx2x
10. SFPU: all instructions from §11, conditional execution, LReg file
11. Config unit (WRCFG, RDCFG, SETC16, RMWCIB)
12. Scalar unit (SETDMAREG, ADDDMAREG, MULDMAREG)

### Phase 3: Memory subsystem
13. NOC fabric (reads, writes, broadcasts, atomics, completion counters)
14. NOC NIU register model
15. DRAM banks (sparse storage)
16. Circular buffer state + stream register model
17. Unpack pipeline (L1 → SrcA/SrcB with format conversion)
18. Pack pipeline (Dst → L1 with format conversion, ReLU, accumulation)

### Phase 4: Integration
19. Host interface (firmware upload, kernel dispatch, completion detection)
20. Firmware boot sequence support (CSR init, soft reset, BRISC→TRISC handoff)
21. End-to-end test: run `add1.py` kernel through emulator
22. End-to-end test: run `matmul_peak.py` multi-core matmul

### Phase 5: Correctness & completeness
23. Hardware bug modeling (FP16 L1 acc, inline write to L1)
24. Fidelity phase modeling for MVMUL
25. Stochastic rounding (SFPSTOCHRND)
26. ADC (address counter) unit
27. XMOV (mover) unit
28. Coordinate translation tables

---

## 26. Testing Strategy

### Unit tests
- RISCV: test each instruction against known-good values
- Tensix: test each opcode in isolation (SFPMAD, MVMUL, etc.)
- Format conversion: round-trip tests for all data types
- Semaphore: test SEMINIT/SEMPOST/SEMGET/SEMWAIT sequences

### Integration tests
- Run real firmware boot sequence; verify BRISC reaches main loop
- Run add1.py kernel; compare output against hardware/expected values
- Run matmul_peak.py; verify multi-core NOC communication + result correctness

### Comparison tests
- Run same kernel on emulator and real hardware; diff outputs
- Use `dsl.py` to generate instruction sequences, run on both, compare register state

---

## 27. File Structure

```
blackhole-py-emu/
  emulator/
    __init__.py
    device.py           # EmulatedDevice, main loop
    tile.py             # TensixTile
    riscv.py            # RiscVCore (decoder + executor)
    riscv_decode.py     # Instruction decoding tables
    tensix.py           # TensixCoprocessor (frontend + backend dispatch)
    tensix_sync.py      # Sync unit (STALLWAIT, semaphores, mutexes)
    tensix_fpu.py       # FPU (MVMUL, ELWADD, etc.)
    tensix_sfpu.py      # SFPU (all vector instructions)
    tensix_scalar.py    # Scalar unit (DMA regs)
    tensix_config.py    # Config/ThreadConfig management
    tensix_unpack.py    # Unpacker pipeline
    tensix_pack.py      # Packer pipeline
    regfiles.py         # SrcA, SrcB, Dst, LReg register files
    l1.py               # L1Memory
    noc.py              # NocFabric + NIU register model
    dram.py             # DramBank (sparse)
    host.py             # HostInterface
    cb.py               # CircularBuffer state
    formats.py          # Data type conversion utilities
    constants.py        # All address constants, register offsets
    pic.py              # PIC (stub)
  tests/
    test_riscv.py
    test_tensix.py
    test_sfpu.py
    test_fpu.py
    test_noc.py
    test_cb.py
    test_formats.py
    test_integration.py
```
