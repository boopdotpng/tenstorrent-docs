# References

## Software Stack Layers

1. **TT-Forge**: high-level framework
2. **TT-NN**: neural network operations
3. **TT-Metalium**: runtime + memory management
4. **TT-LLK**: low-level kernels
5. **ISA**: hardware instructions (Tensix, RISC-V, NoC)

## Key Differences vs. Wormhole B0

- Higher clock: 1.35 GHz (vs. 1.0 GHz)
- Wider NoC: 512 bits/flit (vs. 256 bits/flit)
- 64-bit NoC addresses (vs. 36-bit)
- Enhanced RISC-V: better ISA support, larger local RAM
- New SFPU instructions: `SFPARECIP`, `SFPGT`, `SFPLE`, `SFPMUL24`
- Vector support on RISC-V T2
- `NOC_CMD_WR_INLINE` no longer safe for L1 writes (MMIO-only)

## Documentation Organization

- `tt-isa-documentation/BlackholeA0/NoC/`: NoC architecture, routing, atomics
- `tt-isa-documentation/BlackholeA0/TensixTile/`: tile architecture
- `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/`: RISCV cores, instruction set
- `tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/`: coprocessor instruction docs
- `tt-isa-documentation/Diagrams/Out/`: architecture diagrams (SVG)
