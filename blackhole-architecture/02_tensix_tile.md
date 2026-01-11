# Tensix Tile

Each Tensix tile is a complete compute unit: local memory, multiple RISCV cores, NoC endpoints, and the Tensix
coprocessor.

## Tile Components

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

## Baby RISC-V Cores

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

## L1 Scratchpad

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

## RISC-V Memory Map (Tile View)

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

## Who Does What

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

## Atomic Operations

128-bit atomics on L1:
- Accumulate, swap, compare-and-swap
- Min latency: 12 cycles
- Used for synchronization and reductions
