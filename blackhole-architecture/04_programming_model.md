# Programming Model

## Execution Model

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

## Data Flow Pattern (per tensor op)

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

## Synchronization Primitives

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

## Configuration Management

- `Config[2][CFG_STATE_SIZE*4]`: thread-agnostic, 2 banks
- `ThreadConfig[3][THD_STATE_SIZE]`: per-thread (T0/T1/T2)
- Written via RISC-V (`sw`) or Tensix (`WRCFG`, `SETC16`)
- Auto TTSync prevents races

## Instruction Scheduling

- T0/T1/T2 push independent instruction streams.
- Each thread has separate configuration state.
- Hardware handles resource conflicts and stalls when needed.

**Pipelining tips:**
- Overlap DMA with compute.
- Use multiple Dst blocks (≥5) for zero-bubble pipelines.
- Fidelity phases should be outer loops when accumulating.
