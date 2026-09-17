# Tensix frontend: issue, expansion, and scheduling

Source-derived frontend model. Instruction issue, expansion, and backend completion are different events. Timing numbers require the evidence labels in the ISA viewer.

<a id="execution-model"></a>
## Execution Model and Scheduling
<a id="execution-model--execution-model-and-scheduling"></a>

<a id="execution-model--1-overview"></a>
### 1. Overview

The emulator is a cycle-approximate, single-threaded Python program that models the entire Blackhole device. No OS threads are needed — all cores across all tiles are driven by a single round-robin main loop. The goal is correctness (bit-accurate results, faithful synchronization ordering), not performance.

<a id="execution-model--2-main-loop"></a>
### 2. Main Loop

Each "tick" of the emulator:

```python
class EmulatedDevice:
    def step(self):
        # 1. Step all RISC-V cores (round-robin across tiles)
        for tile in self.tiles.values():
            for core in tile.cores:
                if not core.in_reset and not core.halted:
                    core.step()  # execute one instruction

        # 2. Step all Tensix coprocessors
        for tile in self.tiles.values():
            tile.tensix.step()  # process one instruction per thread if available

        # 3. Step NOC fabric (deliver pending transactions)
        self.noc.tick()

        self.cycle += 1

    def run_until_done(self, max_cycles=10_000_000):
        while self.cycle < max_cycles:
            self.step()
            if self.all_done():
                break
```

Each RISC-V core executes exactly one instruction per `step()` call. The Tensix coprocessor processes one instruction from each thread's frontend per `step()`. NOC transactions are delivered at the end of each tick.

<a id="execution-model--3-core-scheduling"></a>
### 3. Core Scheduling

All 5 RISC-V cores per tile (BRISC, NCRISC, TRISC0/1/2) are stepped in order within each tile. All tiles are stepped in order within each tick. This round-robin provides deterministic interleaving without threads.

A core is skipped if:
- `in_reset == True` (held by SOFT_RESET_0 register)
- `halted == True` (core has halted)
- The core is stalled on a full Tensix instruction FIFO, a blocking PCBuf read, or similar hardware stall

<a id="execution-model--4-done-detection"></a>
### 4. "Done" Detection

A kernel dispatch is done when BRISC writes `RUN_MSG_DONE` (0x00) to the `go_messages[go_message_index].signal` byte in L1. The host side of the emulator polls this.

For a multi-tile workload, the emulator runs until ALL tiles have signaled done (all go_message signals are 0x00), or until a cycle timeout.

<a id="execution-model--5-host-side-driver"></a>
### 5. Host-Side Driver

The emulator's host interface drives the firmware through its boot and dispatch protocol:

```python
def run_kernel(device, launch_msg):
    # 1. Assert soft reset on all cores
    for tile in device.tiles.values():
        tile.write_mmio(0xFFB121B0, 0x47800)  # SOFT_RESET_ALL

    # 2. Upload firmware and kernel to L1
    upload_firmware(device)
    upload_kernel(device, launch_msg)

    # 3. Write go_message signal = RUN_MSG_INIT
    for tile in device.tiles.values():
        tile.l1.write32(0x373, 0x40)

    # 4. Release BRISC only
    for tile in device.tiles.values():
        tile.write_mmio(0xFFB121B0, 0x47000)

    # 5. Run until all tiles boot (go_msg.signal == RUN_MSG_DONE)
    device.run_until(lambda: all(
        tile.l1.read8(0x373) == 0x00 for tile in device.tiles.values()
    ))

    # 6. Write go_message signal = RUN_MSG_GO
    for tile in device.tiles.values():
        tile.l1.write8(0x373, 0x80)

    # 7. Run until kernel completes
    device.run_until(lambda: all(
        tile.l1.read8(0x373) == 0x00 for tile in device.tiles.values()
    ))
```

<a id="execution-model--6-noc-transaction-timing"></a>
### 6. NOC Transaction Timing

For cycle-approximate modeling, NOC transactions complete with configurable latency:
- Same-tile: 1 tick
- Cross-tile: proportional to Manhattan distance (optional, can be 1 tick for simplicity)
- DRAM: 1 tick (no memory controller latency modeling)

For a functional-first emulator, all NOC transactions can complete immediately when `NOC_CMD_CTRL` is written. Status counters are incremented in the same tick. This makes all firmware barriers (`noc_async_read_barrier`, `noc_async_write_barrier`) resolve on the next poll.

<a id="execution-model--7-tensix-coprocessor-scheduling"></a>
### 7. Tensix Coprocessor Scheduling

Each Tensix coprocessor has 3 threads (T0/T1/T2). Per tick, each thread can advance one instruction through its frontend pipeline (FIFO -> MOP Expander -> Replay Expander -> Wait Gate -> Backend). Backend execution units (FPU, SFPU, Pack, Unpack, etc.) operate concurrently across threads.

For a functional emulator, Tensix instructions can execute synchronously — the instruction completes its side effects immediately when it reaches the backend dispatch stage. STALLWAIT/SEMWAIT still need to block the issuing thread until the condition is met.

<a id="execution-model--8-stall-modeling"></a>
### 8. Stall Modeling

Sources of stalls that must be modeled:
- **Instruction FIFO full**: RISC-V core stalls when pushing to a full 32-entry FIFO
- **STALLWAIT/SEMWAIT**: Tensix thread blocks at Wait Gate until condition met
- **PCBuf blocking read**: `tensix_sync()` blocks until coprocessor thread drains
- **Semaphore spin**: firmware `noc_semaphore_wait()` spins on L1 load (no special modeling needed — the spin loop is just RISC-V instructions)
- **NOC barriers**: firmware spins on NIU status counter reads (no special modeling needed with immediate completion)

<a id="instruction-push"></a>
## Instruction Push Mechanism
<a id="instruction-push--instruction-push-mechanism"></a>

How RISC-V cores push 32-bit opcodes into the Tensix coprocessor's instruction FIFOs. See `tensix-coprocessor-pipeline.md` for the full pipeline these instructions flow through.

<a id="instruction-push--two-delivery-mechanisms-same-result"></a>
### Two Delivery Mechanisms, Same Result

Both put the same 32-bit instruction word into the same per-thread FIFO. The coprocessor cannot tell the difference.

<a id="instruction-push--1-mmio-store-tt_-macros"></a>
#### 1. MMIO Store (`TT_*` macros)

A plain `sw` to `INSTRN_BUF_BASE` (`0xFFE40000`):

```c
instrn_buffer[0] = TT_OP_SETC16(reg, val);   // sw to 0xFFE40000
```

- Goes through the RISC-V load/store unit like any other store
- Value can be computed at runtime
- No fusion (one instruction per store)
- Available on BRISC and all TRISCs

<a id="instruction-push--2-ttinsn-inline-instruction-tti_-macros"></a>
#### 2. `.ttinsn` Inline Instruction (`TTI_*` macros)

The Tensix opcode is encoded directly into the RISC-V binary:

```c
__asm__ __volatile__(".ttinsn %0" : : "i"(TT_OP_SETC16(reg, val)));
```

- Encoding: the 32-bit Tensix opcode is **rotated left by 2 bits** and placed in the RISC-V instruction stream. Since valid Tensix opcodes are `< 0xC0000000`, the low 2 bits of the encoded word are never `0b11`, which is how standard RISC-V marks 32-bit instructions. The hardware detects this (low bits != `0b11`), rotates right by 2, and pushes the result to the FIFO.
- Decoded at the I-cache, bypasses the load/store unit
- Up to 4 consecutive `.ttinsn` can be fused into one cycle (TRISCs only, not BRISC)
- Value must be a compile-time constant
- This is what objdump shows as `ttsetc16`, `ttseminit`, etc.

<a id="instruction-push--summary"></a>
#### Summary

| | `.ttinsn` (`TTI_*`) | `sw` to instrn_buf (`TT_*`) |
|---|---|---|
| Path | I-cache decode -> FIFO | Load/store unit -> FIFO |
| Fusion | Up to 4/cycle (TRISCs only) | No |
| Operand | Compile-time constant | Runtime value |
| Stalls on full FIFO | Yes | Yes |

<a id="instruction-push--address-routing"></a>
### Address Routing

| Address | From BRISC | From TRISC0 | From TRISC1 | From TRISC2 |
|---------|-----------|-------------|-------------|-------------|
| `0xFFE40000` | Push to T0 | Push to T0 | Push to T1 | Push to T2 |
| `0xFFE50000` | Push to T1 | hangs | hangs | hangs |
| `0xFFE60000` | Push to T2 | hangs | hangs | hangs |

Each TRISC writes only to `0xFFE40000` — the hardware routes it to that TRISC's own thread. Only BRISC can use the other two addresses to target specific threads. NCRISC cannot push instructions at all.

<a id="instruction-push--fifo-behavior"></a>
### FIFO Behavior

- Capacity: 32 entries per thread (effective limit ~28 before backpressure, 32 reachable via fusion burst)
- **Non-blocking** until full, then the RISC-V core **hardware-stalls** transparently. No polling needed, no software-visible status to check.
- An instruction is considered "pushed" once it enters the FIFO, not when the coprocessor finishes executing it.
- To wait for execution to complete, use `tensix_sync()` (read from `pc_buf_base[1]`, see `pcbufs.md`).

<a id="instruction-push--emulator-implementation"></a>
### Emulator Implementation

1. Detect `.ttinsn` in the RISC-V instruction stream: any 32-bit word with low 2 bits != `0b11` (and it's not a 16-bit compressed instruction, which these cores don't support anyway).
2. Rotate right by 2 to recover the Tensix opcode.
3. Push to the thread's instruction FIFO — identical to handling a store to `0xFFE40000`.
4. For stores to `0xFFE40000`/`0xFFE50000`/`0xFFE60000`: route based on the source core (see address routing table above).
5. If the FIFO is full, stall the RISC-V core until space is available.

Both paths feed the same pipeline: Instruction FIFO -> MOP Expander -> Replay Expander -> Wait Gate -> Backend dispatch.

<a id="tensix-coprocessor-pipeline"></a>
## Tensix Coprocessor Pipeline
<a id="tensix-coprocessor-pipeline--tensix-coprocessor-pipeline"></a>

<a id="tensix-coprocessor-pipeline--overview"></a>
### Overview

The Tensix coprocessor is a multi-threaded instruction-driven accelerator embedded in each Tensix tile. It has **3 independent threads** (T0, T1, T2), each with its own frontend pipeline, feeding into **9 shared backend execution units** that run concurrently.

The 5 RISC-V cores on a Tensix tile map to these roles:

| Index | Core   | Role                  | Tensix Push Access         |
|-------|--------|-----------------------|----------------------------|
| 0     | BRISC  | Data Movement 0       | All 3 thread FIFOs         |
| 1     | NCRISC | Data Movement 1       | None                       |
| 2     | TRISC0 | Unpack kernels (T0)   | Own thread FIFO (T0) only  |
| 3     | TRISC1 | Math/Compute kernels (T1) | Own thread FIFO (T1) only |
| 4     | TRISC2 | Pack kernels (T2)     | Own thread FIFO (T2) only  |

<a id="tensix-coprocessor-pipeline--frontend-pipeline-per-thread"></a>
### Frontend Pipeline (per-thread)

Each thread has its own independent frontend pipeline:

```
RISC-V store to INSTRN_BUF
         |
         v
  Instruction FIFO (32 slots)
         |
         v
  MOP Expander (expands MOP to up to 32639 instructions)
         |
         v
  Replay Expander (32-slot replay buffer)
         |
         v
  Wait Gate (STALLWAIT/SEMWAIT re-evaluate each cycle)
         |
         v
  Backend Dispatch (by opcode)
```

The three frontend pipelines are fully independent. Instructions are dispatched in-order per thread, but across threads the backend can reorder as each unit processes at its own rate.

<a id="tensix-coprocessor-pipeline--backend-execution-units-shared"></a>
### Backend Execution Units (shared)

The backend has 9 concurrent execution units. Dispatch is purely opcode-driven:

| Unit                | Instructions                                      |
|---------------------|---------------------------------------------------|
| Sync Unit           | STALLWAIT, SEMWAIT, SEMINIT, SEMPOST, SEMGET      |
| Unpacker 0 (SrcA/Dst) | UNPACR variants                                |
| Unpacker 1 (SrcB)  | UNPACR variants                                   |
| Matrix Unit (FPU)   | MVMUL, ELWADD, ELWSUB, ELWMUL, MATMUL (1 IPC)   |
| Packers 0-3         | PACR variants (4 packer units)                    |
| Vector Unit (SFPU)  | SFPLOAD, SFPSTORE, SFPADD, SFPMAD, etc. (32x32b) |
| Scalar Unit (ThCon) | SETDMAREG, ADDDMAREG, LOAD_IND, STORE_IND, CAS   |
| Configuration Unit  | SETC16, WRCFG, RMWCIB, CFGSHIFTMASK              |
| Mover               | Bulk L1 data transfers                            |

The Matrix Unit (FPU) accepts at most 1 instruction per cycle regardless of source thread. Unpackers and packers are similarly contended across threads.

The design intent is triple-buffered execution: T0 unpacks the next tile, T1 computes on the current tile, T2 packs the previous tile's results — all running concurrently. Cross-thread synchronization uses hardware semaphores (MATH_PACK, UNPACK_TO_DEST, MATH_DONE) via STALLWAIT.

<a id="tensix-coprocessor-pipeline--instruction-encoding"></a>
### Instruction Encoding

All Tensix instructions are 32-bit words:

```
bits[31:24] = opcode (8 bits)
bits[23:0]  = parameters (24 bits)
```

Constructed via:
```c
#define TT_OP(opcode, params) ((opcode << 24) + params)
```

<a id="tensix-coprocessor-pipeline--instruction-issue-mechanisms"></a>
### Instruction Issue Mechanisms

There are two ways to push instructions into a thread's FIFO. Both deliver the identical 32-bit instruction word.

<a id="tensix-coprocessor-pipeline--1-mmio-store-runtime-variable-operands"></a>
#### 1. MMIO Store (runtime-variable operands)

Write the 32-bit instruction word to the thread's INSTRN_BUF address:

```c
// volatile pointer to INSTRN_BUF_BASE (0xFFE40000)
volatile uint32_t* instrn_buffer = (volatile uint32_t*)INSTRN_BUF_BASE;
instrn_buffer[0] = TT_OP_MVMUL(src_a, src_b, ...);
```

Used via `TT_XXX()` macros (e.g. `TT_MVMUL(...)`) and the `ex_push_insn()` helper in firmware.

<a id="tensix-coprocessor-pipeline--2-inline-ttinsn-custom-risc-v-instruction-compile-time-constants"></a>
#### 2. Inline `.ttinsn` Custom RISC-V Instruction (compile-time constants)

A custom RISC-V ISA extension that encodes the Tensix instruction directly in the RISC-V instruction stream:

```c
#define INSTRUCTION_WORD(x) __asm__ __volatile__(".ttinsn %0" : : "i"((x)))
```

The 32-bit Tensix opcode is rotated left by 2 bits and stored in the encoding space normally reserved for the RISC-V "C" extension (which these cores do not implement). The hardware rotates right by 2 to recover the original instruction word and pushes it to the thread's FIFO.

Used via `TTI_XXX()` macros (e.g. `TTI_MVMUL(...)`). Requires compile-time constant operands.

On Blackhole, up to 4 adjacent `.ttinsn` instructions can be fused and pushed in a single cycle (though the FIFO still dequeues at most 1 per cycle per thread).

<a id="tensix-coprocessor-pipeline--fifo-backpressure"></a>
#### FIFO Backpressure

The instruction FIFO holds 32 entries per thread. When full, the RISC-V core automatically stalls on the next store/`.ttinsn` until a slot frees up. A slot is freed when the instruction is consumed by the MOP Expander, not when it reaches the backend.

<a id="tensix-coprocessor-pipeline--instrn_buf-address-map"></a>
### INSTRN_BUF Address Map

| Address        | Symbol            | Purpose                                  |
|----------------|-------------------|------------------------------------------|
| `0xFFE40000`   | INSTRN_BUF_BASE   | T0 instruction FIFO                      |
| `0xFFE50000`   | INSTRN1_BUF_BASE  | T1 instruction FIFO                      |
| `0xFFE60000`   | INSTRN2_BUF_BASE  | T2 instruction FIFO                      |

Stride between threads: `0x10000` (64 KB).

<a id="tensix-coprocessor-pipeline--routing-by-source-core"></a>
#### Routing by Source Core

The address `0xFFE40000` is context-sensitive — hardware routes the write based on which RISC-V core performs the store:

| Store Address  | From BRISC    | From TRISC0   | From TRISC1   | From TRISC2   |
|----------------|---------------|---------------|---------------|---------------|
| `0xFFE40000`   | Push to T0    | Push to T0    | Push to T1    | Push to T2    |
| `0xFFE50000`   | Push to T1    | (hangs)       | (hangs)       | (hangs)       |
| `0xFFE60000`   | Push to T2    | (hangs)       | (hangs)       | (hangs)       |

Each TRISC can only push to its own thread via `0xFFE40000`. The hardware remaps the address per-core. Writing to `0xFFE50000` or `0xFFE60000` from a TRISC will hang the core.

BRISC can target any thread by writing to the corresponding address directly.

<a id="tensix-coprocessor-pipeline--brisc-coprocessor-access"></a>
### BRISC Coprocessor Access

BRISC can push Tensix instructions to all three thread FIFOs. However:

- BRISC's pushes enter **after** the MOP Expander (bypassing MOP expansion). This means BRISC cannot issue MOP instructions — only fully-expanded individual instructions.
- There is a mux at each thread's frontend that merges BRISC and TRISC_i inputs. If both push on the same cycle, the **TRISC_i instruction is silently discarded**. BRISC must only push to a thread when that thread's TRISC is not actively issuing.

In practice, BRISC issues instructions only during **initialization** (before TRISCs start their kernels):

```c
// From brisc.cc — device_setup()
instrn_buf[0] = core.instrn_buf_base(0);  // 0xFFE40000
instrn_buf[1] = core.instrn_buf_base(1);  // 0xFFE50000
instrn_buf[2] = core.instrn_buf_base(2);  // 0xFFE60000

core.ex_zeroacc(instrn_buf[0]);                     // Clear dest registers
core.ex_encc(instrn_buf[0]);                         // Enable CC stack
core.ex_load_const(instrn_buf[0]);                   // Load SFPU constants
core.initialize_tensix_semaphores(instrn_buf[0]);    // Init hardware semaphores
```

NCRISC has **no** tensix instruction push capability.

<a id="tensix-coprocessor-pipeline--hardware-semaphores"></a>
### Hardware Semaphores

The Tensix coprocessor has 8 hardware semaphores accessed via the PC Buffer address space (`PC_BUF_BASE + semaphore_offset`). Key semaphores used for inter-thread synchronization:

| Semaphore       | Index | Purpose                                |
|-----------------|-------|----------------------------------------|
| MATH_PACK       | 1     | TRISC1 (math) <-> TRISC2 (pack) sync on Dst register |
| UNPACK_TO_DEST  | 2     | TRISC0 (unpack) <-> TRISC1 (math) sync on unpack-to-dest |
| MATH_DONE       | 7     | Wait for TRISC1 math completion        |

Semaphore operations (SEMINIT, SEMPOST, SEMGET) are Tensix instructions issued through the instruction FIFO. STALLWAIT with semaphore wait conditions allows a thread to stall in the Wait Gate until a semaphore reaches a threshold.

BRISC initializes all semaphores at boot via `SEMINIT` through T0's FIFO.

<a id="tensix-coprocessor-pipeline--other-key-address-regions"></a>
### Other Key Address Regions

| Address        | Symbol              | Purpose                                |
|----------------|---------------------|----------------------------------------|
| `0xFFE00000`   | REGFILE_BASE        | ThCon GPR file (192 regs, 64 per thread) |
| `0xFFE80000`   | PC_BUF_BASE         | T0 PC buffer / sync registers          |
| `0xFFE90000`   | PC1_BUF_BASE        | T1 PC buffer                           |
| `0xFFEA0000`   | PC2_BUF_BASE        | T2 PC buffer                           |
| `0xFFB80000`   | TENSIX_MOP_CFG_BASE | MOP Expander config (write-only, 9 words) |
| `0xFFB11000`   | RISCV_TDMA_REGS     | TDMA mover command registers           |
| `0xFFEC0000`   | TENSIX_MAILBOX0     | Hardware mailbox (BRISC)               |
| `0xFFEC1000`   | TENSIX_MAILBOX1     | Hardware mailbox (TRISC0)              |
| `0xFFEC2000`   | TENSIX_MAILBOX2     | Hardware mailbox (TRISC1)              |
| `0xFFEC3000`   | TENSIX_MAILBOX3     | Hardware mailbox (TRISC2)              |
| `0xFFEF0000`   | TENSIX_CFG_BASE     | Backend config registers (unpack/pack/FPU config) |

<a id="tensix-coprocessor-pipeline--brisc---trisc-orchestration"></a>
### BRISC <-> TRISC Orchestration

BRISC controls TRISC lifecycle via two mechanisms:

<a id="tensix-coprocessor-pipeline--software-mailboxes-l1"></a>
#### Software Mailboxes (L1)

BRISC writes go/done signals to `subordinate_sync` in L1:

```c
subordinate_sync->trisc0 = RUN_SYNC_MSG_GO;   // 0x80 = start kernel
subordinate_sync->trisc1 = RUN_SYNC_MSG_GO;
subordinate_sync->trisc2 = RUN_SYNC_MSG_GO;
// TRISCs write back RUN_SYNC_MSG_DONE (0x00) when finished
```

<a id="tensix-coprocessor-pipeline--pc-buffer"></a>
#### PC Buffer

BRISC writes kernel launch tokens to `pc_buf[thread]` to trigger TRISC execution. TRISCs call `tensix_sync()` (a blocking store to `pc_buf_base[1]`) after each kernel to drain the coprocessor pipeline before signaling done.

<a id="tensix-coprocessor-pipeline--key-opcodes"></a>
### Key Opcodes

| Opcode | Instruction | Execution Unit    |
|--------|-------------|-------------------|
| `0x01` | MOP         | Frontend (MOP Expander) |
| `0x02` | REPLAY      | Frontend (Replay Expander) |
| `0x08`-`0x0f` | STALLWAIT, SEMWAIT, SEMINIT | Sync Unit |
| `0x28` | ELWADD      | Matrix Unit (FPU) |
| `0x29` | ELWSUB      | Matrix Unit (FPU) |
| `0x2a` | ELWMUL      | Matrix Unit (FPU) |
| `0x41` | PACR        | Pack Unit         |
| `0x42` | UNPACR      | Unpack Unit       |
| `0x58` | MATMUL      | Matrix Unit (FPU) |
| `0x80`-`0x8f` | SFP* | Vector Unit (SFPU) |
| `0xa0`-`0xaf` | WRCFG, RMWCIB | Config Unit |
| `0xb0`-`0xbf` | THCON_LD_IND, THCON_ST_IND | Scalar Unit (ThCon) |
| `0xb2` | SETC16      | Config Unit       |

<a id="tensix-coprocessor-pipeline--source-references"></a>
### Source References

- ISA spec (coprocessor overview): `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/README.md`
- Push mechanism: `tt-isa-documentation/WormholeB0/TensixTile/BabyRISCV/PushTensixInstruction.md`
- Blackhole push (`.ttinsn` fusion): `tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/PushTensixInstruction.md`
- MOP Expander: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOPExpander.md`
- Instruction encoding (all opcodes): `tt-llk/tt_llk_blackhole/common/inc/ckernel_ops.h`
- ISA YAML (opcode -> execution unit mapping): `tt-llk/tt_llk_blackhole/instructions/assembly.yaml`
- BRISC firmware: `tt-metal/tt_metal/hw/firmware/src/tt-1xx/brisc.cc`
- Instruction push helpers: `tt-metal/tt_metal/hw/inc/internal/tensix_functions.h`
- Address map: `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h`
- Stall/wait parameters: `tt-llk/tt_llk_blackhole/common/inc/ckernel_instr_params.h`

<a id="mop-and-replay-expanders"></a>
## MOP Expander and Replay Expander
<a id="mop-and-replay-expanders--mop-expander-and-replay-expander"></a>

Two per-thread frontend units that expand single instructions into long sequences,
freeing the RISC-V core after a single push. The MOP Expander feeds into the Replay
Expander — a MOP expansion can emit REPLAY instructions, which are then further expanded.
The converse is not true: replayed sequences cannot contain MOP instructions.

```
RISC-V TRISC_n
    |
[Instruction FIFO, 32 slots]
    |
[MOP Expander]       1 MOP -> up to 32639 instructions
    |
[Replay Expander]    1 REPLAY -> up to 64 instructions from 32-slot buffer
    |
[Wait Gate]
    |
[Backend Units]
```

BRISC's instruction pushes enter **after** the MOP Expander, so BRISC cannot issue MOP
instructions. Only TRISC0/T1/T2 can use MOP.

---

<a id="mop-and-replay-expanders--mop-expander"></a>
### MOP Expander

<a id="mop-and-replay-expanders--instruction-mop-opcode-0x01"></a>
#### Instruction: MOP (opcode `0x01`)

```
[31:24] opcode    = 0x01
[23]    Template  (u1)  — 0 = Template 0 (zmask/unpack), 1 = Template 1 (double loop)
[22:16] Count1    (u7)  — Template 0: loop iterations - 1. Template 1: not used (config only)
[15:0]  MaskLo    (u16) — Template 0: low 16 bits of 32-bit zero-mask. Template 1: not used
```

```c
#define TT_OP_MOP(mop_type, loop_count, zmask_lo16_or_loop_count) \
    TT_OP(0x01, (((mop_type) << 23) + ((loop_count) << 16) + \
                  ((zmask_lo16_or_loop_count) << 0)))
```

<a id="mop-and-replay-expanders--instruction-mop_cfg-opcode-0x03"></a>
#### Instruction: MOP_CFG (opcode `0x03`)

Provides the upper 16 bits of the 32-bit zero-mask for Template 0. Must precede the
MOP instruction that uses it.

```
[31:24] opcode    = 0x03
[23:16] (reserved)
[15:0]  MaskHi    (u16) — high 16 bits of 32-bit zero-mask
```

```c
#define TT_OP_MOP_CFG(zmask_hi16) TT_OP(0x03, (((zmask_hi16) << 0)))
```

<a id="mop-and-replay-expanders--configuration-registers-mopcfg"></a>
#### Configuration Registers (MopCfg)

9 × 32-bit **write-only** registers per thread at `TENSIX_MOP_CFG_BASE = 0xFFB80000`.
Reading these from RISC-V is undefined behavior.

Each TRISC writes its own thread's config. BRISC cannot use MOP but can write any
thread's config registers (though there is no reason to — MOP config is only useful
if the thread can issue MOP instructions).

The registers have **dual interpretations** depending on which template the MOP
instruction selects:

| Index | Template 0 (Unpack Zmask) | Template 1 (Double Loop) |
|-------|---------------------------|--------------------------|
| `MopCfg[0]` | Not used | `OuterCount` (low 7 bits only) |
| `MopCfg[1]` | `Flags` (bit 0: `HasB`, bit 1: `HasA123`) | `InnerCount` (low 7 bits only) |
| `MopCfg[2]` | `InsnB` (only if `HasB`) | `StartOp` (skipped if NOP) |
| `MopCfg[3]` | `InsnA0` | `EndOp0` (skipped if NOP) |
| `MopCfg[4]` | `InsnA1` (only if `HasA123`) | `EndOp1` (skipped if NOP, or if `EndOp0` is NOP) |
| `MopCfg[5]` | `InsnA2` (only if `HasA123`) | `LoopOp` |
| `MopCfg[6]` | `InsnA3` (only if `HasA123`) | `LoopOp1` (alternating; skipped if NOP) |
| `MopCfg[7]` | `SkipA0` | `Loop0Last` (last inner iter of last outer iter) |
| `MopCfg[8]` | `SkipB` (only if `HasB`) | `Loop1Last` (last inner iter of non-last outer iter) |

Programming via MMIO:

```c
volatile uint32_t *mop_cfg = (volatile uint32_t *)0xFFB80000;
mop_cfg[0] = outer_count;
mop_cfg[1] = inner_count;
mop_cfg[2] = start_op;      // e.g. TT_OP_NOP
mop_cfg[3] = end_op0;       // e.g. TT_OP_SETRWC(...)
mop_cfg[4] = end_op1;       // e.g. TT_OP_NOP
mop_cfg[5] = loop_op;       // typically a REPLAY instruction word
mop_cfg[6] = loop_op1;      // TT_OP_NOP for single-instruction inner loop
mop_cfg[7] = loop0_last;    // e.g. MVMUL with CLR_A on final iteration
mop_cfg[8] = loop1_last;    // e.g. MVMUL with CLR_NONE on inner-last
```

The C++ `ckernel_template` class wraps this:

```cpp
ckernel_template tmp(outer, inner, lltt::replay_insn(16, 16));
tmp.set_end_ops(end0, end1);
tmp.set_last_outer_loop_instr(loop0_last);
tmp.set_last_inner_loop_instr(loop1_last);
tmp.program();                  // writes mop_cfg[0..8]
ckernel_template::run();        // TTI_MOP(1, 0, 0)
```

**Software must not modify MopCfg while an expansion is in progress.** Use `mop_sync()`
(blocking store to `pc_buf_base[2]`) or TTSync CSR reads to wait for completion.

<a id="mop-and-replay-expanders--functional-model"></a>
#### Functional Model

```python
async def MOPExpander(MopCfg):  # MopCfg is per-thread state; uint32[9] at 0xFFB80000
    MaskHi = 0                  # per-thread state, set by MOP_CFG instruction
    while True:
        Instruction = await GetNextIncomingInstruction()
        if Instruction.Opcode == 0x03:       # MOP_CFG
            MaskHi = Instruction.MaskHi
        elif Instruction.Opcode == 0x01:     # MOP
            if Instruction.Template == 0:
                async for x in ExpandTemplate0(
                    (MaskHi << 16) | Instruction.MaskLo,
                    Instruction.Count1,
                    MopCfg
                ):
                    yield x
            else:
                async for x in ExpandTemplate1(MopCfg):
                    yield x
        else:
            yield Instruction  # pass through everything else


def IsNop(Instruction):
    """Only recognizes plain NOP (opcode 0x02). NOT DMANOP (0x60) nor SFPNOP (0x8F)."""
    return (Instruction >> 24) == 0x02
```

<a id="mop-and-replay-expanders--template-0-unpack-zero-mask-loop"></a>
#### Template 0: Unpack Zero-Mask Loop

Used for unpack operations with column masking. Each iteration either emits the
unpack instruction(s) or the skip instruction(s), based on the corresponding mask bit.

```python
async def ExpandTemplate0(Mask, Count1, MopCfg):
    Flags  = MopCfg[1]
    InsnB  = MopCfg[2]
    InsnA0 = MopCfg[3]
    InsnA1 = MopCfg[4]
    InsnA2 = MopCfg[5]
    InsnA3 = MopCfg[6]
    SkipA0 = MopCfg[7]
    SkipB  = MopCfg[8]
    HasB    = Flags & 1
    HasA123 = Flags & 2

    for i in range(Count1 + 1):
        if (Mask & 1) == 0:
            yield InsnA0
            if HasA123:
                yield InsnA1
                yield InsnA2
                yield InsnA3
            if HasB:
                yield InsnB
        else:
            yield SkipA0
            if HasB:
                yield SkipB
        Mask >>= 1
```

Typical usage (tilize/untilize/pack):

```c
// Configure the unpack template via MopCfg registers
mop_cfg[1] = has_b | (has_halo << 1);
mop_cfg[2] = TT_OP_UNPACR(...);     // InsnB
mop_cfg[3] = TT_OP_UNPACR(...);     // InsnA0
// ...
mop_cfg[7] = TT_OP_NOP;             // SkipA0
mop_cfg[8] = TT_OP_NOP;             // SkipB

// Precede with MOP_CFG for upper mask bits, then issue MOP
TTI_MOP_CFG(zmask >> 16);
TTI_MOP(0, count - 1, zmask & 0xFFFF);
```

<a id="mop-and-replay-expanders--template-1-double-nested-loop"></a>
#### Template 1: Double-Nested Loop

The common template for compute (matmul, eltwise). Implements a double-nested loop
with start/end framing instructions and last-iteration overrides.

Execution pattern:
```
for outer in 0..OuterCount:
    emit StartOp               (skipped if NOP)
    for inner in 0..InnerCount:
        emit LoopOp            (alternating LoopOp/LoopOp1 if both non-NOP)
        last inner, last outer: emit Loop0Last instead
        last inner, not last outer: emit Loop1Last instead
    emit EndOp0                (skipped if NOP)
    emit EndOp1                (skipped if NOP, or if EndOp0 is NOP)
```

```python
async def ExpandTemplate1(MopCfg):
    OuterCount = MopCfg[0] & 127
    InnerCount = MopCfg[1] & 127
    StartOp    = MopCfg[2]
    EndOp0     = MopCfg[3]
    EndOp1     = MopCfg[4]
    LoopOp     = MopCfg[5]
    LoopOp1    = MopCfg[6]
    Loop0Last  = MopCfg[7]
    Loop1Last  = MopCfg[8]

    # If LoopOp1 is non-NOP, inner loop alternates between LoopOp and LoopOp1
    # by XOR-flipping, and InnerCount doubles.
    if IsNop(LoopOp1):
        LoopOpFlip = 0
    else:
        LoopOpFlip = LoopOp ^ LoopOp1
        InnerCount *= 2

    # Hardware bug: must be replicated exactly
    if OuterCount == 1 and IsNop(StartOp) and InnerCount == 0 and not IsNop(EndOp0):
        OuterCount += 128

    for j in range(OuterCount):
        if not IsNop(StartOp):
            yield StartOp
        for i in range(InnerCount):
            if i != InnerCount - 1:
                yield LoopOp
            elif j != OuterCount - 1:
                yield Loop1Last      # last inner, but not last outer
            else:
                yield Loop0Last      # last inner of last outer
            LoopOp ^= LoopOpFlip     # alternate between LoopOp and LoopOp1
        if not IsNop(EndOp0):
            yield EndOp0
            if not IsNop(EndOp1):
                yield EndOp1
```

<a id="mop-and-replay-expanders--mop-performance"></a>
#### MOP Performance

| State | Ingestion | Emission |
|-------|-----------|----------|
| Pass-through (non-MOP/MOP_CFG) | 1/cycle | 1/cycle |
| During MOP expansion | 0 (blocked) | 1/cycle |
| Transition after expansion ends | **1-cycle penalty** — neither ingests nor emits |

The 1-cycle transition penalty after expansion is why the expanded sequence should
include at least one REPLAY instruction that expands to ≥2 instructions — this fills
the gap so the backend sees uninterrupted 1-instruction/cycle throughput.

---

<a id="mop-and-replay-expanders--replay-expander"></a>
### Replay Expander

<a id="mop-and-replay-expanders--instruction-replay-opcode-0x04"></a>
#### Instruction: REPLAY (opcode `0x04`)

```
[31:24] opcode              = 0x04
[23:14] start_idx   (u10, but only low 5 bits used — wraps mod 32)
[13:4]  len         (u10, but only low 6 bits used — 0 means 64)
[1]     exec_while_loading  (u1) — execute instructions as they're recorded (only when load_mode=1)
[0]     load_mode           (u1) — 1 = record, 0 = playback
```

```c
#define TT_OP_REPLAY(start_idx, len, execute_while_loading, load_mode) \
    TT_OP(0x04, (((start_idx) << 14) + ((len) << 4) + \
                  ((execute_while_loading) << 1) + ((load_mode) << 0)))
```

<a id="mop-and-replay-expanders--replay-buffer"></a>
#### Replay Buffer

32-slot × 32-bit circular buffer per thread. **No memory-mapped address** — the buffer
has no CPU-accessible address. It is accessed exclusively through the REPLAY instruction.

Software convention partitions the buffer (not enforced by hardware):

| Slots | Reserved for |
|-------|-------------|
| 0–15 | SFPU instructions |
| 16–31 | FPU/matmul instructions |

<a id="mop-and-replay-expanders--functional-model-1"></a>
#### Functional Model

```python
async def ReplayExpander():
    ReplayBuffer = [0] * 32  # per-thread state; no CPU address
    while True:
        Instruction = await GetNextIncomingInstruction()
        if Instruction.Opcode != 0x04:       # not REPLAY
            yield Instruction                # pass through
        elif Instruction.Load:               # record mode
            Index = Instruction.Index
            Exec = Instruction.Exec
            for i in range(Instruction.Count or 64):  # 0 means 64
                Instruction = await GetNextIncomingInstruction()
                ReplayBuffer[(Index + i) % 32] = Instruction
                if Exec:
                    yield Instruction         # execute while recording
        else:                                # playback mode
            Index = Instruction.Index
            for i in range(Instruction.Count or 64):
                yield ReplayBuffer[(Index + i) % 32]
```

<a id="mop-and-replay-expanders--c-api"></a>
#### C++ API

```cpp
// sfpi/include/lltt.h
namespace lltt {
    // Record next `length` instructions into replay buffer starting at `start`
    template<ExecBool E = NoExec>
    inline void record(unsigned start, unsigned length) {
        __builtin_rvtt_ttreplay(start, length, bool(E), true);
    }

    // Replay `length` instructions from buffer starting at `start`
    inline void replay(unsigned start, unsigned length) {
        __builtin_rvtt_ttreplay(start, length, false, false);
    }

    // Returns a raw REPLAY instruction word for embedding in MopCfg LoopOp
    constexpr uint32_t replay_insn(unsigned start, unsigned length) {
        return (0x04 << 24) | (start << 14) | (length << 4);
    }
}
```

Blackhole convenience wrapper (disables instruction gathering during recording):

```cpp
// ckernel.h
template <ExecBool Exec = NoExec, typename Callable, typename... Args>
inline void load_replay_buf(uint32_t start, uint32_t len, Callable &&f, Args &&...args) {
    disable_gathering();          // CSR 0x7C0 bit 18 — prevents instruction fusion
    lltt::record<Exec>(start, len);
    f(std::forward<Args>(args)...);  // lambda body emits instructions into buffer
    enable_gathering();
}
```

<a id="mop-and-replay-expanders--replay-performance"></a>
#### Replay Performance

| Mode | Ingestion | Emission |
|------|-----------|----------|
| Pass-through (non-REPLAY) | 1/cycle | 1/cycle |
| Playback (`Load=0`) | 0 (stalls incoming) | 1/cycle from buffer |
| Record+Execute (`Load=1, Exec=1`) | 1/cycle | 1/cycle |
| Record only (`Load=1, Exec=0`) | 1/cycle | 0 |

**No transition penalties** when switching between modes.

During playback, incoming instructions accumulate in the upstream FIFO/MOP expander
(up to 32 slots). The replay expander does not consume from the incoming stream until
playback completes.

---

<a id="mop-and-replay-expanders--mop--replay-composition"></a>
### MOP + Replay Composition

The typical high-throughput pattern: MOP emits REPLAY instructions as its loop body,
which the Replay Expander then further expands. This gives two levels of expansion
from a single RISC-V instruction.

<a id="mop-and-replay-expanders--example-matmul"></a>
#### Example: Matmul

```cpp
// Step 1: Record 16 MVMUL instructions into replay buffer slots 16..31
load_replay_buf<ExecBool::Exec>(16, 16, [&]{
    TTI_MVMUL(CLR_NONE, 0, ADDR_MOD_0, 0);   // slot 16
    TTI_MVMUL(CLR_NONE, 0, ADDR_MOD_1, 0);   // slot 17
    // ... 14 more MVMULs with varying addr modes
});

// Step 2: Program MOP Template 1 with LoopOp = REPLAY(16, 16)
ckernel_template tmp(1, fidelity_phases,
    lltt::replay_insn(16, 16));               // LoopOp
tmp.set_last_outer_loop_instr(
    TT_OP_MVMUL(CLR_A, 0, ADDR_MOD_3, 0));   // Loop0Last: clear accum
tmp.program();

// Step 3: Per tile — one instruction, RISC-V is free
ckernel_template::run();   // TTI_MOP(1, 0, 0)
```

Expansion chain:
```
MOP(1, 0, 0)                                        [1 RISC-V instruction]
  -> MOP Expander emits REPLAY(16, 16) x fidelity    [fidelity REPLAY words]
    -> Replay Expander emits 16 MVMULs x fidelity    [16*fidelity backend ops]
```

<a id="mop-and-replay-expanders--example-sfpu-tile-wide-add"></a>
#### Example: SFPU tile-wide add

```cpp
// Record 4 SFPU instructions into slots 0..3
lltt::record(0, 4);
TTI_SFPLOAD(LREG0, 0, ADDR_MOD_7, 0);
TTI_SFPADD(LREG0, LCONST_0, LREG0, LREG0, 0);
TTI_SFPSTORE(LREG0, 0, ADDR_MOD_7, 0);
TTI_INCRWC(0, 2, 0, 0);

// Program MOP: 32 inner iterations, body = REPLAY(0, 4)
ckernel_template tmp(1, 32, lltt::replay_insn(0, 4));
tmp.program();
ckernel_template::run();
// -> 32 x (SFPLOAD + SFPADD + SFPSTORE + INCRWC) = 128 backend instructions
```

<a id="mop-and-replay-expanders--example-replay-without-mop"></a>
#### Example: Replay without MOP

For shorter sequences, replay can be used standalone without MOP:

```c
// Record 5 SFPU instructions, executing them as they're recorded
TTI_REPLAY(0, 5, 1, 1);     // record+execute, slots 0..4
TTI_SFPLOAD(...);            // slot 0
TTI_SFPADD(...);             // slot 1
TTI_SFPNOP;                  // slot 2
TTI_SFPSTORE(...);           // slot 3
TTI_INCRWC(...);             // slot 4

// Replay 6 more times
TTI_REPLAY(0, 5, 0, 0);     // playback
TTI_REPLAY(0, 5, 0, 0);
TTI_REPLAY(0, 5, 0, 0);
TTI_REPLAY(0, 5, 0, 0);
TTI_REPLAY(0, 5, 0, 0);
TTI_REPLAY(0, 5, 0, 0);
```

---

<a id="mop-and-replay-expanders--emulator-implementation"></a>
### Emulator Implementation

<a id="mop-and-replay-expanders--state-per-thread"></a>
#### State per thread

```python
class MOPExpander:
    def __init__(self):
        self.mop_cfg = [0] * 9    # write-only from RISC-V at 0xFFB80000
        self.mask_hi = 0          # set by MOP_CFG instruction (opcode 0x03)
        self.busy = False         # for qstatus CSR bit 1

class ReplayExpander:
    def __init__(self):
        self.buffer = [0] * 32    # not memory-mapped; no CPU address
        self.busy = False         # for qstatus CSR bit 0

class TensixThread:
    def __init__(self, thread_id):
        self.input_fifo = deque(maxlen=32)
        self.mop = MOPExpander()
        self.replay = ReplayExpander()
```

<a id="mop-and-replay-expanders--mmio-intercepts"></a>
#### MMIO intercepts

| Address | Width | Access | Meaning |
|---------|-------|--------|---------|
| `0xFFB80000 + i*4` (i=0..8) | 32-bit | Write-only | `MopCfg[i]` for the calling TRISC's thread |

Writes from TRISC0 go to T0's MopCfg, TRISC1 to T1's, TRISC2 to T2's. The address
is the same (`0xFFB80000`) for all three — hardware routes by source core.

<a id="mop-and-replay-expanders--csr-0xbc0-tensix_queue_status"></a>
#### CSR `0xBC0` (tensix_queue_status)

Read-only CSR accessible from any TRISC. Reports busy state of frontend and backend
units for the reading thread.

```python
def read_qstatus(thread):
    status = 0
    status |= (thread.replay.busy << 0)    # bit 0: replay expander busy (this thread)
    status |= (thread.mop.busy << 1)       # bit 1: MOP expander busy (this thread)
    # bits 2-12: thcon, xmov, unpack, pack, cfg, sync, tdma, sfpu, fpu, sfpucc
    status |= (any_thread_replay_busy << 13)  # bit 13: any thread's replay busy
    status |= (any_thread_mop_busy << 14)     # bit 14: any thread's MOP busy
    return status
```

<a id="mop-and-replay-expanders--edge-cases-that-must-be-replicated"></a>
#### Edge cases that must be replicated

1. **Hardware bug in Template 1**: When `OuterCount==1 && IsNop(StartOp) && InnerCount==0 && !IsNop(EndOp0)`, then `OuterCount += 128`. This is in the ISA spec and real kernels may depend on it.

2. **LoopOp alternation**: When `LoopOp1` is non-NOP, the inner loop XOR-flips between `LoopOp` and `LoopOp1` each iteration, and `InnerCount` doubles. The last-iteration override (Loop0Last/Loop1Last) replaces whichever instruction would have been emitted.

3. **IsNop semantics**: Only opcode `0x02` (plain NOP) is recognized as NOP. `DMANOP` (opcode `0x60`) and `SFPNOP` (opcode `0x8F`) are **not** NOP for this purpose. If `StartOp` is set to `DMANOP`, it will be emitted — it won't be skipped.

4. **REPLAY Count=0 means 64**: Not 0, not 32 — exactly 64 instructions, wrapping through the buffer twice.

5. **Replay buffer wraps mod 32**: `ReplayBuffer[(Index + i) % 32]`.

6. **MopCfg is write-only**: Reads return undefined values. Only writes are meaningful.

7. **MopCfg is sampled during expansion**: The ISA docs note the hardware "mostly samples values as required during the expansion process." Software must not change MopCfg while a MOP is expanding. The emulator should snapshot at expansion start (matching the functional model) or implement live-sampling with a warning.

8. **mop_sync**: A blocking store to `pc_buf_base[2]` (`PC_BUF_BASE + 8`). The store does not complete until the MOP expansion finishes. The emulator must stall the RISC-V core on this write until the MOP expander is idle.

<a id="mop-and-replay-expanders--what-can-be-skipped-for-functional-non-cycle-accurate-emulation"></a>
#### What can be skipped for functional (non-cycle-accurate) emulation

- **Instruction gathering** (CSR `0x7C0` bit 18): Only affects cycle-level timing of `.ttinsn` fusion, not functional correctness.
- **FIFO backpressure**: If not cycle-accurate, expand MOP and REPLAY synchronously without modeling FIFO occupancy.
- **1-cycle MOP transition penalty**: Cycle-level detail only.
- **RESOURCEDECL** (opcode `0x05`): Resource usage hints for hardware scheduling. Has no effect on instruction semantics.

---

<a id="mop-and-replay-expanders--assembly-encoding"></a>
### Assembly Encoding

The `.ttinsn` mechanism rotates the 32-bit Tensix word left by 2 bits for encoding in
the RISC-V instruction stream. The emulator reverses this:

```python
tensix_word = ((encoded >> 2) | (encoded << 30)) & 0xFFFFFFFF
```

Assembly mnemonics (from disassembly):

```asm
ttmop      1,0,0          # MOP Template 1, Count1=0, MaskLo=0
ttmop_cfg  0xABCD         # MOP_CFG with MaskHi=0xABCD
ttreplay   0,5,1,1        # REPLAY: start=0, len=5, exec=1, load=1
ttreplay   16,16,0,1      # REPLAY: record 16 insns at slots 16..31
ttreplay   0,5,0,0        # REPLAY: playback 5 insns from slot 0
```

Binary encoding examples:

| Hex (after `.ttinsn` rotate) | Tensix word | Meaning |
|-----|-------------|---------|
| `0x06000000` | `MOP(1,0,0)` | Template 1 double-loop |
| `0x10100404` | `REPLAY(16,16,0,1)` | Record 16 slots starting at 16 |
| `0x1000014C` | `REPLAY(0,5,1,1)` | Record+execute 5 slots at 0 |
| `0x10000140` | `REPLAY(0,5,0,0)` | Playback 5 slots from 0 |

---

<a id="mop-and-replay-expanders--source-references"></a>
### Source References

- MOP Expander spec: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOPExpander.md`
- MOP instruction: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOP.md`
- MOP_CFG instruction: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOP_CFG.md`
- REPLAY instruction: `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/REPLAY.md`
- Instruction encoding macros: `tt-llk/tt_llk_blackhole/common/inc/ckernel_ops.h`
- ckernel_template class: `tt-llk/tt_llk_blackhole/common/inc/ckernel_template.h`
- lltt C++ API: `sfpi/include/lltt.h`
- MopCfg base address: `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h` (`TENSIX_MOP_CFG_BASE = 0xFFB80000`)
- Assembly YAML (instruction fields): `tt-llk/tt_llk_blackhole/instructions/assembly.yaml` (MOP at line 3339, REPLAY at line 3388)
- Queue status CSR: `tt-llk/tt_llk_blackhole/common/inc/ckernel.h` (`qstatus_u` union)
- Matmul MOP+replay usage: `tt-llk/tt_llk_blackhole/llk_lib/llk_math_matmul.h`
- SFPU replay patterns: `tt-llk/tt_llk_blackhole/common/inc/sfpu/ckernel_sfpu_welfords.h`
- Developer guide: `boop-docs/kernel-dev/replay-buffer-and-mop-for-sfpu.md`
