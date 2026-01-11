# Tensix Coprocessor

The coprocessor is the primary compute engine: Unpack → Compute → Pack on tile-sized data.

## Dst (Destination Register File)

**Dimensions:**
- 1024 rows × 16 columns × 16-bit (Dst16b mode)
- 512 rows × 16 columns × 32-bit (Dst32b mode)
- Same storage: `uint16_t DstBits[1024][16]`

**Supported data types:**
- **Dst16b**: BF16, FP16, INT8 (sign-magnitude), INT16
- **Dst32b**: FP32, INT32 (sign-magnitude)

**Valid bits:** each row has a valid bit for pipeline flow control.

## Vector Unit (SFPU)

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

## Matrix Unit (FPU)

Low-precision matrix engine operating on Dst tiles.

**Capabilities:**
- Matrix multiply-accumulate (MAC)
- Multiple data types (BF16, FP16, INT8, etc)

**Instructions:**
- `MVMUL`, `DOTPV`, `GAPOOL`, `GMPOOL`, `ELWMUL`, `ELWADD`, `ELWSUB`

## Unpacker / Packer

**Unpacker (×2):**
- Moves data L1 → Dst
- Performs format conversion and layout/tilization
- Supports block-floating-point formats (BFP2/4/8)

**Packer (×4):**
- Moves data Dst → L1
- Performs format conversion
- Parallel operation for bandwidth

## Data Type Support (Dst-focused)

- **BF16:** 1+8+7 (sign+exp+mant)
- **FP16:** 1+5+10 (custom encoding, not IEEE754)
- **FP32:** 1+8+23 (custom encoding, closer to IEEE754)
- **INT8/16/32:** sign-magnitude

**Conversions:** Unpacker/Packer handle I/O conversions; SFPU provides cast instructions.
