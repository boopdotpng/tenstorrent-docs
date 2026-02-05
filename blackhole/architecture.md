# Blackhole P100A architecture

> Focus: compute + DMA behavior for low-level TT-Metal/LLK kernel work.

## Overview

Blackhole is a 2D mesh accelerator:
- **140 Tensix tiles** (compute) - 120 available on p100, 140 on p150
- **2 NoCs** for data movement (independent directions)
- **24 DRAM tiles** - 32 GiB total (p100: 21 tiles/28 GiB enabled, p150: 24 tiles/32 GiB enabled); each 4 GiB region is mirrored on 3 tiles
- **4 L2CPU tiles** - 4x SiFive x280 each (16 cores total)
- **14 Ethernet tiles** - 400 GbE endpoints (0 on p100, 12 enabled on p150; 8 wired to QSFP-DD)
- **2 PCIe tiles** - PCIe 5.0 x16 host interface (1 active in current products)
- **ARC + Security tiles** - management processors (not used for customer workloads)

## NoC (Network on Chip)

The NoC is the primary data-movement fabric connecting all tiles.

### Fundamentals

**Dual independent networks:**
- **NoC0**: data flows right/down
- **NoC1**: data flows left/up
- Together they form a 2D torus with wraparound edges.

**Packet structure:**
- Transaction = 1+ packets
- Packet = 1 header flit + up to 256 data flits
- Flit = 512 bits (64 bytes)
- Max packet size = 16,384 bytes (256 × 64)

**Performance:**
- Clock: 1.35 GHz
- Throughput per NoC: 512 bits/cycle (64 bytes/cycle)
- Aggregate bandwidth: ~172 GB/s per NoC at full utilization
- Router-to-router latency: 9 cycles
- NIU-to-router latency: ~5 cycles

### Transaction Types

**Reads:**
- Read from remote tile address space; response returns to initiator.

**Writes:**
- Posted (no ACK) or non-posted
- Immediate data (32-bit inline to MMIO in Tensix/Ethernet tiles only) or DMA from initiator memory
- Broadcast to rectangle of tiles (Tensix only)
- Writes ≤ 64 bytes can use byte-enable masks; larger writes are contiguous spans
- Max 16,384 bytes for L1↔L1 transfers

**Atomics:**
- 128-bit atomics on remote L1
- Operations: accumulate, compare-and-swap, swap, increment, etc.
- 32-bit result returned to initiator
- Supported only on L1 of Tensix/Ethernet tiles (not DRAM/MMIO/PCIe)

### NIU (NoC Interface Unit) Programming

Each tile has 2 NIUs (one per NoC) with 4 request initiators each. Tensix/Ethernet/DRAM tiles expose NIU initiators;
L2CPU and PCIe tiles inject NoC traffic via different mechanisms.

**Key MMIO registers (per initiator):**
```
NIU_BASE + 0x0000: NOC_TARG_ADDR_LO/MID/HI   # Target tile coords & address
NIU_BASE + 0x000C: NOC_RET_ADDR_LO/MID/HI    # Return address for responses
NIU_BASE + 0x001C: NOC_CTRL                   # Request type & flags
NIU_BASE + 0x0020: NOC_AT_LEN_BE              # Length or atomic opcode
NIU_BASE + 0x0028: NOC_AT_DATA                # Immediate data
NIU_BASE + 0x0040: NOC_CMD_CTRL               # Write 1 to initiate
```

**NIU base addresses:**
- NoC0: `0x0000_0000_FFB2_0000`
- NoC1: `0x0000_0000_FFB3_0000`

### Coordinate System

**Translated address space:**
- X: 0–16, Y: 0–30
- Tensix tiles: X=1–16, Y=2–11 (140 tiles in a 10×14 grid with gaps)
- DRAM tiles: X=17–18, Y=12–23
- L2CPU tiles: X=8, Y=26–29

Translation handles yield variation and renumbers harvested tiles into fixed coordinates.

### Virtual Channels & Ordering

- 4-bit VC number:
  - 2 class bits: `00`/`01` = unicast, `10` = broadcast, `11` = response
  - 1 dateline bit: flips at predetermined route points
  - 1 buddy bit: can change per hop for congestion adaptation
- Ordering is weak by default.
- Ordering can be enforced with `NOC_CMD_VC_LINKED` and `NOC_CMD_VC_STATIC`.
- Atomics provide ordering at the target tile.
- Advanced features (multi-packet transactions, broadcasts without path reservation, nonzero arbitration priority) need
  software care to avoid deadlock.

### Throughput Best Practices

- Use both NoC0 and NoC1 to double bandwidth.
- Use max packet size (16 KiB) for best header:data ratio.
- Avoid small transactions (<128 bytes).
- Use broadcasts for 1-to-N where possible (Tensix only).
- Exploit weak ordering; avoid unnecessary serialization.

## Tensix tile

Each Tensix tile is a complete compute unit: local memory, multiple RISCV cores, NoC endpoints, and the Tensix
coprocessor.

### Tile Components

```
Tensix Tile:
├── L1 RAM: 1536 KiB scratchpad
├── Baby RISC-V cores: 5 cores
│   ├── RISC-V B (Brisc): NoC/DMA orchestration
│   ├── RISC-V T0, T1, T2 (Trisc): Tensix orchestration
│   └── RISC-V NC (Ncrisc): Additional control
├── NoC connections: 2 (NoC0 + NoC1)
├── NoC Overlay: DMA coprocessor
└── Tensix Coprocessor:
    ├── Unpacker × 2: L1 → Tensix
    ├── Matrix Unit (FPU): Matrix ops
    ├── Vector Unit (SFPU): 32-wide SIMD
    ├── Scalar Unit (ThCon): Integer & memory ops
    └── Packer × 4: Tensix → L1
```

### Baby RISC-V Cores

**ISA:** RV32IM + Zicsr + Zaamo + Zba + Zbb + partial F/Zfh + custom `.ttinsn` extension
**RISC-V T2** additionally has partial vector (V) support.

**Pipeline:** in-order, single-issue, 1 instruction/cycle @ 1.35 GHz
- Frontend: fetch + predict
- EX1: execute / address generation
- EX2: multiply / FP ops (1 cycle)
- EX3: vector ops (T2 only)
- Load/Store Unit
- Retire Unit (8-entry reorder buffer)

**Local data RAM:**
- RISC-V B, NC: 8 KiB each
- RISC-V T0/T1/T2: 4 KiB each
- Fast path (`MEM_LOCAL_BASE`): 2-cycle latency
- Slow path: 8-cycle latency, NoC-accessible

**L0 caches:**
- Instruction cache per core (fuses up to 4 adjacent `.ttinsn` into 64/96/128-bit bundles)
- Data cache: 64 bytes (4 lines × 16 bytes), non-coherent

**Instruction fusion detail:**
- `.ttinsn` is a single RISCV instruction that pushes a Tensix instruction.
- The instruction cache can fuse up to four adjacent `.ttinsn` and execute the bundle in one cycle.
- This allows **enqueueing** up to four Tensix instructions per cycle, but the coprocessor **dequeues** at most one per
  cycle.

**Division of labor:**
- **Brisc + Ncrisc**: NoC/DMA setup, copy-in/copy-out, control-plane tasks
- **Trisc T0/T1/T2**: push Tensix instruction streams, coordinate compute

### L1 Scratchpad

**Size:** 1536 KiB
**Address:** `0x0000_0000` to `0x0017_FFFF`

**Access:**
- All 5 RISC-V cores
- NoC (remote read/write)
- Tensix coprocessor (via Unpacker/Packer)
- Atomics supported (128-bit)

**Bandwidth:**
- RISC-V: varies by bank conflicts
- Unpacker/Packer: high bandwidth for tensor ops
- NoC: up to 64 bytes/cycle with proper alignment

**Memory access latency (RISC-V):**
- Local RAM (fast path): 2 cycles
- L1 cache hit: 2 cycles
- L1 cache miss: ≥8 cycles
- MMIO: 3–7+ cycles

**Strategy:** keep stack and hot variables in local RAM.

### RISC-V Memory Map (Tile View)

```
0x0000_0000 - 0x0017_FFFF : L1 (1536 KiB)
0xFFB0_0000 - 0xFFB0_1FFF : Local data RAM (per core)
0xFFB1_1000 - 0xFFB1_1FFF : TDMA-RISC config
0xFFB1_2000 - 0xFFB1_2FFF : Tile control/debug
0xFFB1_3000 - 0xFFB1_3137 : PIC (interrupt controller)
0xFFB2_0000 - 0xFFB2_FFFF : NoC 0 NIU registers
0xFFB3_0000 - 0xFFB3_FFFF : NoC 1 NIU registers
0xFFB4_0000 - 0xFFB7_FFFF : NoC overlay
0xFFB8_0000 - 0xFFB8_0023 : MOP expander config (T0/T1/T2)
0xFFBD_8000 - 0xFFBD_FFFF : Dst access (T0/T1/T2)
0xFFE0_0000 - 0xFFE0_0FFF : Tensix GPRs
0xFFE4_0000 - 0xFFE6_FFFF : Push Tensix instructions
0xFFE8_0000 - 0xFFE8_FFFF : PCBufs, semaphores, TTSync
0xFFEC_0000 - 0xFFEC_3FFF : Mailboxes
0xFFEF_0000 - 0xFFEF_FFFF : Tensix backend config
```

### Who Does What

**Inside a Tensix tile:**
- **L1**: 1.5 MiB scratchpad (not a cache)
- **Brisc + Ncrisc**: NoC/DMA setup, data movement, control tasks
- **Trisc T0/T1/T2**: push instruction streams to the coprocessor

**Other tile types:**
- **DRAM tiles**: NIU data path to GDDR6 (4 GiB per group mirrored on 3 tiles); each has a baby RISCV + small L1
- **L2CPU tiles**: 4x SiFive x280, private L1/L2 + shared 2 MiB L3; NoC access via TLB windows
- **Ethernet tiles**: baby RISCV + L1, can participate in NoC atomics
- **PCIe tiles**: translate PCIe/AXI ↔ NoC for host DMA
- **ARC/Security**: platform management

### Atomic Operations

128-bit atomics on L1:
- Accumulate, swap, compare-and-swap
- Min latency: 12 cycles
- Used for synchronization and reductions

## Tensix coprocessor

The coprocessor is the primary compute engine: Unpack → Compute → Pack on tile-sized data.

### Dst (Destination Register File)

**Dimensions:**
- 1024 rows × 16 columns × 16-bit (Dst16b mode)
- 512 rows × 16 columns × 32-bit (Dst32b mode)
- Same storage: `uint16_t DstBits[1024][16]`

**Supported data types:**
- **Dst16b**: BF16, FP16, INT8 (sign-magnitude), INT16
- **Dst32b**: FP32, INT32 (sign-magnitude)

**Valid bits:** each row has a valid bit for pipeline flow control.

### Vector Unit (SFPU)

32-wide SIMD operating on 32-bit lanes.

**LReg storage:** 17 registers × 32 lanes × 32-bit
- `LReg[0-7]`: general purpose
- `LReg[8]`: constant 0.8373
- `LReg[9]`: constant 0.0
- `LReg[10]`: constant 1.0
- `LReg[11-14]`: broadcast regs (8 lanes → 32 lanes)
- `LReg[15]`: lane indices (0, 2, 4, ..., 62)
- `LReg[16]`: macro scheduling only

**Instruction classes:**
- **FP32 arithmetic (2-cycle, 1 IPC):** `SFPADD`, `SFPMAD`, `SFPMUL`, `SFPADDI`, `SFPMULI`, `SFPLUT`, `SFPLUTFP32`
- **Field manipulation (1-cycle):** `SFPEXMAN`, `SFPEXEXP`, `SFPSETMAN`, `SFPSETEXP`, `SFPSETSGN`, `SFPDIVP2`
- **Integer ops (1–2 cycles):** `SFPIADD`, `SFPMUL24`, `SFPABS`
- **Bit ops (1 cycle):** `SFPAND`, `SFPOR`, `SFPXOR`, `SFPNOT`, `SFPSHFT`, `SFPSHFT2`, `SFPLZ`
- **Conversions (1 cycle):** `SFPCAST`, `SFPSTOCHRND` (FP32↔BF16/TF32/INT)
- **Data movement:** `SFPLOAD`/`SFPSTORE` (Dst ↔ LReg), `SFPTRANSP`, `SFPCONFIG`
- **Conditional execution:** `SFPENCC`, `SFPSETCC`, `SFPPUSHC`, `SFPCOMPC`, `SFPPOPC`

**Lane layout:** 32 lanes as a 4×8 grid for cross-lane ops.

**Execution model:**
- 5 sub-units (load, simple, MAD, round, store) but only 1 instruction accepted per cycle.
- `SFPLOADMACRO` can schedule a load + up to 4 additional SFPU ops to keep sub-units active.
- Per-lane predication uses a flag stack for SIMT-style control flow.

**Reference:** `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/VectorUnit.md`
(architecture is shared; Blackhole adds a small number of instructions).

### Matrix Unit (FPU)

Low-precision matrix engine operating on Dst tiles.

**Capabilities:**
- Matrix multiply-accumulate (MAC)
- Multiple data types (BF16, FP16, INT8, etc)

**Instructions:**
- `MVMUL`, `DOTPV`, `GAPOOL`, `GMPOOL`, `ELWMUL`, `ELWADD`, `ELWSUB`

### Unpacker / Packer

**Unpacker (×2):**
- Moves data L1 → Dst
- Performs format conversion and layout/tilization
- Supports block-floating-point formats (BFP2/4/8)

**Packer (×4):**
- Moves data Dst → L1
- Performs format conversion
- Parallel operation for bandwidth

### Data Type Support (Dst-focused)

- **BF16:** 1+8+7 (sign+exp+mant)
- **FP16:** 1+5+10 (custom encoding, not IEEE754)
- **FP32:** 1+8+23 (custom encoding, closer to IEEE754)
- **INT8/16/32:** sign-magnitude

**Conversions:** Unpacker/Packer handle I/O conversions; SFPU provides cast instructions.

## Programming model

### Execution Model

**Three-level hierarchy:**
1. **Host** (x86/ARM): dispatch + memory management
2. **RISC-V cores**: orchestrate NoC and coprocessor work
3. **Tensix coprocessor**: execute tensor compute

**Typical workflow:**
```
1. RISC-V B/NC: configure NoC, initiate DMA transfers
2. RISC-V T0/T1/T2: push instruction streams to Tensix coprocessor
3. Tensix: Unpack → Compute → Pack
4. RISC-V: monitor completion (counters/interrupts)
5. RISC-V: initiate output transfers via NoC
```

### Data Flow Pattern (per tensor op)

```
L1 (tile A) ──NoC──> L1 (tile B)
                      │
                      ↓
                   Unpacker
                      │
                      ↓
                     Dst
                    / | \
                   /  |  \
      Matrix Unit  Vector  Scalar Unit
                   \  |  /
                    \ | /
                      ↓
                     Dst
                      │
                      ↓
                   Packer
                      │
                      ↓
                   L1 (tile B)
                      │
                      ↓
                     NoC ──> L1 (tile C) or DRAM
```

### Synchronization Primitives

**NoC-level:**
- Transaction counters (`NIU_MST_REQS_OUTSTANDING_ID`)
- Interrupts on counter transitions
- Posted vs. non-posted writes

**Tile-level:**
- Semaphores (Tensix semaphores for inter-thread sync)
- Mailboxes (RISC-V core-to-core communication)
- TTSync (auto/manual synchronization between RISC-V and Tensix)

**Tensix-level:**
- Dst valid bits
- Semaphores (`SEMGET`, `SEMPOST`, `SEMWAIT`, `SEMINIT`)
- Stream wait (`STREAMWAIT`)

### Configuration Management

- `Config[2][CFG_STATE_SIZE*4]`: thread-agnostic, 2 banks
- `ThreadConfig[3][THD_STATE_SIZE]`: per-thread (T0/T1/T2)
- Written via RISC-V (`sw`) or Tensix (`WRCFG`, `SETC16`)
- Auto TTSync prevents races

### Instruction Scheduling

- T0/T1/T2 push independent instruction streams.
- Each thread has separate configuration state.
- Hardware handles resource conflicts and stalls when needed.

**Pipelining tips:**
- Overlap DMA with compute.
- Use multiple Dst blocks (≥5) for zero-bubble pipelines.
- Fidelity phases should be outer loops when accumulating.
