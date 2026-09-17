# Tensix synchronization: waits, semaphores, and mutexes

These chapters describe distinct synchronization resources. An L1 software semaphore is not a Tensix hardware semaphore. Preserve the wait condition and resource mask when translating a protocol.

<a id="stallwait-conditions"></a>
## STALLWAIT and SEMWAIT — Wait Gate Conditions
<a id="stallwait-conditions--stallwait-and-semwait--wait-gate-conditions"></a>

<a id="stallwait-conditions--overview"></a>
### Overview

`STALLWAIT` (opcode `0xA2`) and `SEMWAIT` (opcode `0xA6`) are the primary synchronization instructions in the Tensix coprocessor. Both install a "latched wait instruction" into the **Wait Gate** of the issuing thread's frontend pipeline. The Wait Gate re-evaluates the condition every cycle and holds back the selected categories of downstream instructions until all selected conditions are simultaneously satisfied.

Both instructions are dispatched to the **Sync Unit** (1-cycle throughput, shared with SEMINIT/SEMPOST/SEMGET), and the latched condition takes effect immediately — the instruction immediately following STALLWAIT/SEMWAIT is subject to the block mask for at least one cycle, even if the condition is already met.

---

<a id="stallwait-conditions--instruction-encodings"></a>
### Instruction Encodings

```
STALLWAIT: opcode=0xA2, word = (0xA2 << 24) | (stall_res << 15) | (wait_res << 0)
SEMWAIT:   opcode=0xA6, word = (0xA6 << 24) | (stall_res << 15) | (sem_sel << 2) | (wait_sem_cond << 0)
```

Field widths: `stall_res` is 9 bits [23:15]; `wait_res` is 13 bits [12:0] for STALLWAIT; `sem_sel` is 8 bits [9:2] and `wait_sem_cond` is 2 bits [1:0] for SEMWAIT.

```c
// ckernel_ops.h macros
#define TT_OP_STALLWAIT(stall_res, wait_res) \
    TT_OP(0xa2, (((stall_res) << 15) + ((wait_res) << 0)))

#define TT_OP_SEMWAIT(stall_res, sem_sel, wait_sem_cond) \
    TT_OP(0xa6, (((stall_res) << 15) + ((sem_sel) << 2) + ((wait_sem_cond) << 0)))
```

---

<a id="stallwait-conditions--stall_res--block-mask-9-bits"></a>
### `stall_res` — Block Mask (9 bits)

The block mask selects which categories of instructions are held back at the Wait Gate until the wait condition is satisfied. Named B0 (LSB) through B8 (MSB).

| Bit | `p_stall` constant | Value  | Instructions blocked |
|----:|--------------------|-------:|----------------------|
| B0  | `STALL_TDMA`       | `0x01` | Misc Unit (ADDRCRXY, ADDRCRZW, INCADCXY, INCADCZW, RSTDMA, SETADC, SETADCXX, SETADCXY, SETADCZW, SETDVALID), Mover (XMOV), Scalar Unit (ThCon) (ATCAS, ATINCGET, ATINCGETPTR, ATSWAP, DMANOP, LOADIND, LOADREG, REG2FLOP, SETDMAREG, STOREIND, STOREREG, arithmetic DMA ops), and Packer (PACR, PACR_SETREG) |
| B1  | `STALL_SYNC`       | `0x02` | Sync Unit (ATGETM, ATRELM, SEMGET, SEMINIT, SEMPOST, SEMWAIT, STALLWAIT, STREAMWAIT) |
| B2  | `STALL_PACK`       | `0x04` | Packer (PACR, PACR_SETREG) |
| B3  | `STALL_UNPACK`     | `0x08` | Unpacker (UNPACR, UNPACR_NOP) |
| B4  | `STALL_XMOV`       | `0x10` | Mover (XMOV) |
| B5  | `STALL_THCON`      | `0x20` | Scalar Unit / ThCon (ADDDMAREG, ATCAS, ATINCGET, ATINCGETPTR, ATSWAP, BITWOPDMAREG, CMPDMAREG, DMANOP, FLUSHDMA, LOADIND, LOADREG, MULDMAREG, REG2FLOP, SETDMAREG, SHIFTDMAREG, STOREIND, STOREREG, SUBDMAREG) |
| B6  | `STALL_MATH`       | `0x40` | Matrix Unit / FPU (APOOL3S1, APOOL3S2, CLEARDVALID, CLREXPHIST, CONV3S1, CONV3S2, DOTPV, ELWADD, ELWMUL, ELWSUB, GAPOOL, GATESRCRST, GMPOOL, INCRWC, MFCONV3S1, MOVA2D, MOVB2A, MOVB2D, MOVD2A, MOVD2B, MOVDBGA2D, MPOOL3S1, MPOOL3S2, MVMUL, SETRWC, SHIFTXA, SHIFTXB, TRNSPSRCB, ZEROACC, ZEROSRC) |
| B7  | `STALL_CFG`        | `0x80` | Configuration Unit (CFGSHIFTMASK, RDCFG, RMWCIB, SETC16, WRCFG, STREAMWRCFG) |
| B8  | `STALL_SFPU`       | `0x100`| Vector Unit / SFPU (all SFP* instructions) |

**Special cases:**
- `NOP` is blocked only if **all** block bits B0–B8 are set.
- `MOP`, `MOP_CFG`, `REPLAY`, `RESOURCEDECL` are never blocked (handled before the Wait Gate).
- `SEMWAIT`, `STALLWAIT`, and `STREAMWAIT` themselves are always blocked by any block bit (B0–B8 all apply).

**Combined constants in `p_stall`:**
```cpp
STALL_THREAD = 0x1ff   // all bits B0–B8: block everything
```

**Default when `stall_res == 0`:** Hardware treats it as `1 << 6` = `STALL_MATH` (B6 only).

---

<a id="stallwait-conditions--wait_res--condition-mask-for-stallwait-13-bits"></a>
### `wait_res` — Condition Mask for STALLWAIT (13 bits)

The condition mask selects which "keep waiting" conditions must all clear before the STALLWAIT is released. Named C0 (LSB) through C12 (MSB). The STALLWAIT remains latched as long as **any** selected condition is true.

| Bit  | `p_stall` constant  | Value   | Keep waiting while... |
|-----:|---------------------|--------:|----------------------|
| C0   | `THCON`             | `0x001` | Scalar Unit (ThCon) has memory requests outstanding for the current thread |
| C1   | `UNPACK0`           | `0x002` | Current thread has an instruction in any stage of Unpacker 0's pipeline |
| C2   | `UNPACK1`           | `0x004` | Current thread has an instruction in any stage of Unpacker 1's pipeline |
| C3   | `PACK0`             | `0x008` | Current thread has an instruction in any stage of the Packer pipeline |
| C4   | `MATH`              | `0x010` | Current thread has an instruction in any stage of the Matrix Unit (FPU) pipeline |
| C5   | `SRCA_CLR`          | `0x020` | `SrcA[Unpackers[0].SrcBank].AllowedClient != SrcClient::Unpackers` |
| C6   | `SRCB_CLR`          | `0x040` | `SrcB[Unpackers[1].SrcBank].AllowedClient != SrcClient::Unpackers` |
| C7   | `SRCA_VLD`          | `0x080` | `SrcA[MatrixUnit.SrcABank].AllowedClient != SrcClient::MatrixUnit` |
| C8   | `SRCB_VLD`          | `0x100` | `SrcB[MatrixUnit.SrcBBank].AllowedClient != SrcClient::MatrixUnit` |
| C9   | `XMOV`              | `0x200` | The Mover has any outstanding memory requests (from any thread or TDMA-RISC) |
| C10  | `TRISC_CFG`         | `0x400` | The associated RISC-V T core has an emitted-but-unprocessed memory request to Tensix GPRs, Tensix config, or TDMA-RISC |
| C11  | `SFPU1` / `WAIT_SFPU` | `0x800` | Current thread has an instruction in any stage of the Vector Unit (SFPU) pipeline |
| C12  | `CFGEXU`            | `0x1000`| **Any** thread has an instruction in any stage of the Configuration Unit pipeline |

> Note: C4 (MATH) and C11 (SFPU1) may wait longer than strictly necessary when the respective unit is being shared by multiple threads simultaneously, since the hardware cannot distinguish per-thread occupancy in those units.

**Combined constants:**
```cpp
UNPACK = UNPACK0 | UNPACK1   // 0x006  — both unpackers
PACK   = PACK0               // 0x008  — alias
ALL_THREAD_RES = THCON | UNPACK0 | UNPACK1 | PACK0 | MATH | XMOV  // 0x21f
```

**Default when `wait_res == 0`:** Hardware uses `0x0F` (C0|C1|C2|C3: ThCon + both unpackers + packer).

**Usage notes from ISA documentation:**
- C0 (THCON): Use after `LOADIND`/`LOADREG`/`ATINCGET` to ensure the GPR contains the result.
- C1, C2 (UNPACK0/1): Block mask should include B3 or B0 to prevent new unpacker instructions from flowing in.
- C3 (PACK): Block mask should include B2 or B0.
- C4 (MATH): Block mask should include B6.
- C5, C6 (SRCA_CLR/SRCB_CLR): Rarely needed directly; UNPACR automatically waits for this.
- C7, C8 (SRCA_VLD/SRCB_VLD): Rarely needed directly; Matrix Unit instructions automatically wait. Needed for MOVD2A/MOVD2B because those instructions do NOT automatically wait.
- C9 (XMOV): Block mask should include B4 or B0.
- C10 (TRISC_CFG): Guards against a RISC-V store to config not yet visible to the coprocessor. Auto TTSync normally handles this.
- C11 (SFPU1): Block mask should include B8.
- C12 (CFGEXU): Block mask should include B7. **Cross-thread:** any thread's config instructions count.

---

<a id="stallwait-conditions--semwait--condition-fields"></a>
### SEMWAIT — Condition Fields

SEMWAIT uses the same `stall_res` block mask as STALLWAIT. Its wait condition is defined by two additional fields:

<a id="stallwait-conditions--sem_sel--semaphore-mask-8-bits-field-92"></a>
#### `sem_sel` — Semaphore Mask (8 bits, field [9:2])

A bitmask selecting which hardware semaphores to observe. The hardware semaphores are indexed 0–7. The `sem_sel` field uses `t6_sem(index) = (1 << index)` to select semaphores:

| Semaphore index | `t6_sem()` value | `p_stall` constant | Logical name |
|----------------:|----------------:|---------------------|--------------|
| 0 | `0x001` | `SEMAPHORE_0` | `FPU_SFPU` — FPU↔SFPU sync |
| 1 | `0x002` | `SEMAPHORE_1` | `MATH_PACK` — math↔pack sync on Dest |
| 2 | `0x004` | `SEMAPHORE_2` | `UNPACK_TO_DEST` — unpack↔math sync |
| 3 | `0x008` | `SEMAPHORE_3` | `UNPACK_OPERAND_SYNC` — unpack↔pack/math operand sync |
| 4 | `0x010` | `SEMAPHORE_4` | `PACK_DONE` — pack iteration |
| 5 | `0x020` | `SEMAPHORE_5` | `UNPACK_SYNC` — TRISC↔unpack sync on HW kernel |
| 6 | `0x040` | `SEMAPHORE_6` | `UNPACK_MATH_DONE` — unpack or math iteration done |
| 7 | `0x080` | `SEMAPHORE_7` | `MATH_DONE` — math done when unpacking to dest |

The `sem_sel` field occupies the 8-bit span [9:2] of the instruction, so `sem_sel = (1 << sem_index)` directly selects one semaphore. Multiple bits may be set to wait on any of several semaphores simultaneously.

`SEMAPHORE_BIAS = SEMAPHORE_4 = 0x10` appears in `p_stall` as a legacy offset name.

<a id="stallwait-conditions--wait_sem_cond--semaphore-condition-2-bits-field-10"></a>
#### `wait_sem_cond` — Semaphore Condition (2 bits, field [1:0])

| Bit | `p_stall` constant | Value | Keep waiting while... |
|----:|--------------------|------:|----------------------|
| C0  | `STALL_ON_ZERO`    | `0x1` | Any selected semaphore has `Value == 0` |
| C1  | `STALL_ON_MAX`     | `0x2` | Any selected semaphore has `Value >= Max` |

Both bits may be set. A `wait_sem_cond == 0` is undefined behavior.

The SEMWAIT is released when the selected condition(s) are cleared on all selected semaphores simultaneously. The canonical patterns are:

- `STALL_ON_ZERO` (C0=1, C1=0): Wait until `Value > 0` — i.e., "wait until something has been posted to this semaphore."
- `STALL_ON_MAX` (C0=0, C1=1): Wait until `Value < Max` — i.e., "wait until there is room to post again."

<a id="stallwait-conditions--semwait-vs-stallwait"></a>
#### SEMWAIT vs STALLWAIT

| Feature | STALLWAIT | SEMWAIT |
|---------|-----------|---------|
| Opcode | `0xA2` | `0xA6` |
| Block mask (`stall_res`) | Same | Same |
| Wait condition | 13-bit `ConditionMask` against hardware status signals | 2-bit comparison against 1-of-8 semaphore values |
| `ConditionMask == 0` behavior | Hardware substitutes `0x0F` | Undefined behavior |
| Cleared by | Hardware units becoming idle, ownership changing | SEMPOST or SEMGET from any thread, or RISC-V write to PCBuf semaphore window |
| Typical use | Wait for pipeline stages to drain | Cross-thread handshake (math→pack, unpack→math) |

---

<a id="stallwait-conditions--the-wait-gate"></a>
### The Wait Gate

Each of the three Tensix threads has its own Wait Gate stage in the frontend pipeline:

```
Replay Expander
      |
      v
  Wait Gate  <-- STALLWAIT/SEMWAIT latch installed here
      |           re-evaluated every cycle
      v
Backend Dispatch
```

When a STALLWAIT or SEMWAIT reaches the Wait Gate (via the Sync Unit), it installs a latched wait instruction. From that point on, **every cycle**, the Wait Gate tests the condition:
- If any selected condition still signals "keep waiting": hold the next instruction.
- If all selected conditions simultaneously clear: release the latch and allow instructions to flow.

There is a **one-cycle lag** between the condition clearing and the block mask lifting. The instruction immediately following STALLWAIT will always be held for at least one cycle.

Once the block mask is installed, instructions pass through the Wait Gate in order. When the first instruction matching the block mask arrives, **no further instructions of any kind** can pass until the condition clears — not just the blocked category.

<a id="stallwait-conditions--python-pseudocode-for-wait-gate-evaluation"></a>
#### Python pseudocode for Wait Gate evaluation

```python
@dataclass
class LatchedWait:
    opcode: str          # "STALLWAIT" or "SEMWAIT" or None
    block_mask: int      # 9-bit
    cond_mask: int       # 13-bit (STALLWAIT) or 0 (SEMWAIT)
    sem_mask: int        # 8-bit (SEMWAIT) or 0 (STALLWAIT)
    sem_cond: int        # 2-bit (SEMWAIT)

def wait_gate_stall_condition(latch: LatchedWait, hw: HardwareState, thread: int) -> bool:
    """Return True if the Wait Gate should hold the next instruction."""
    if latch.opcode is None:
        return False

    if latch.opcode == "STALLWAIT":
        cond = latch.cond_mask
        keep_waiting = False
        if (cond >> 0) & 1:  keep_waiting |= hw.thcon_requests_outstanding[thread]
        if (cond >> 1) & 1:  keep_waiting |= hw.unpacker0_pipeline_nonempty[thread]
        if (cond >> 2) & 1:  keep_waiting |= hw.unpacker1_pipeline_nonempty[thread]
        if (cond >> 3) & 1:  keep_waiting |= hw.packer_pipeline_nonempty[thread]
        if (cond >> 4) & 1:  keep_waiting |= hw.fpu_pipeline_nonempty[thread]
        if (cond >> 5) & 1:  keep_waiting |= (hw.srca_unpack_bank_owner != "unpackers")
        if (cond >> 6) & 1:  keep_waiting |= (hw.srcb_unpack_bank_owner != "unpackers")
        if (cond >> 7) & 1:  keep_waiting |= (hw.srca_fpu_bank_owner != "matrix_unit")
        if (cond >> 8) & 1:  keep_waiting |= (hw.srcb_fpu_bank_owner != "matrix_unit")
        if (cond >> 9) & 1:  keep_waiting |= hw.mover_requests_outstanding
        if (cond >> 10) & 1: keep_waiting |= hw.trisc_config_request_pending[thread]
        if (cond >> 11) & 1: keep_waiting |= hw.sfpu_pipeline_nonempty[thread]
        if (cond >> 12) & 1: keep_waiting |= hw.cfgu_pipeline_nonempty_any_thread
        return keep_waiting

    if latch.opcode == "SEMWAIT":
        keep_waiting = False
        for i in range(8):
            if not (latch.sem_mask >> i) & 1:
                continue
            sem = hw.semaphores[i]
            if (latch.sem_cond >> 0) & 1:  keep_waiting |= (sem.value == 0)
            if (latch.sem_cond >> 1) & 1:  keep_waiting |= (sem.value >= sem.max)
        return keep_waiting

    return False

def can_instruction_pass(instr, latch: LatchedWait) -> bool:
    """Return True if the instruction is blocked by the current latch."""
    if latch.opcode is None:
        return True
    block = latch.block_mask
    # Instruction's block bits are OR-d; blocked if any matching bit is set
    return (instr.block_bits & block) == 0

# Each cycle:
def wait_gate_cycle(thread):
    latch = thread.latched_wait
    if latch.opcode is not None:
        if not wait_gate_stall_condition(latch, hw, thread.id):
            latch.opcode = None   # condition met, release latch
    # Pass instruction through only if condition is cleared AND instr not blocked
    if thread.next_instr is not None:
        if latch.opcode is None or not can_instruction_pass(thread.next_instr, latch):
            thread.dispatch(thread.next_instr)
```

<a id="stallwait-conditions--per-thread-independence"></a>
#### Per-thread independence

Each of the three Tensix threads has its own independent Wait Gate. A STALLWAIT issued by T0 (unpack thread) blocks only T0's future instructions; T1 (math) and T2 (pack) continue unaffected. This is the mechanism that enables the three threads to run concurrently at different pipeline stages.

---

<a id="stallwait-conditions--common-stallwait-patterns"></a>
### Common STALLWAIT Patterns

<a id="stallwait-conditions--pattern-1-before-wrcfg--wait-for-thcon-or-packer"></a>
#### Pattern 1: Before WRCFG — wait for ThCon or Packer

Used throughout the LLK to ensure a GPR value written by SETDMAREG/ADDDMAREG is visible before WRCFG commits it to configuration registers.

```cpp
// Block CFG unit until ThCon (SETDMAREG/ADDDMAREG) completes
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::THCON);
TTI_WRCFG(p_gpr_pack::TMP0, p_cfg::WRCFG_32b, SOME_CFG_ADDR);
```

Decoded: `ttstallwait 128, 1` — block=`STALL_CFG`(B7), wait=`THCON`(C0).

The WRCFG is a Configuration Unit instruction (blocked by B7). The wait condition C0 says "keep waiting while ThCon has memory requests outstanding for this thread." The sequence is: SETDMAREG writes a GPR via ThCon → STALLWAIT waits for ThCon to finish → WRCFG reads the GPR.

When packer is also running and the config register belongs to it:
```cpp
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::THCON | p_stall::PACK0);
```
Decoded: `ttstallwait 128, 9` — additionally waits for packer pipeline to drain (C3).

<a id="stallwait-conditions--pattern-2-before-movd2amovd2b--wait-for-srcasrcb-valid"></a>
#### Pattern 2: Before MOVD2A/MOVD2B — wait for SrcA/SrcB valid

MOVD2A and MOVD2B move data from Dest to SrcA/SrcB register files. They are Matrix Unit instructions but do **not** automatically wait for the SrcA/SrcB bank ownership to transfer to the Matrix Unit (unlike most FPU read operations). The LLK must wait explicitly.

```cpp
// Before MOVD2A: wait until SrcA bank is owned by Matrix Unit
TTI_STALLWAIT(p_stall::STALL_MATH, p_stall::SRCA_VLD);
TTI_MOVD2A(0, p_mova2d::MATH_HALO_ROWS + 0, addrmod, p_movd2a::MOV_4_ROWS, 0);
```

Decoded: `ttstallwait 64, 128` — block=`STALL_MATH`(B6), wait=`SRCA_VLD`(C7).

```cpp
// Before MOVD2B: wait until SrcB bank is owned by Matrix Unit
TTI_STALLWAIT(p_stall::STALL_MATH, p_stall::SRCB_VLD);
TTI_MOVD2B(0, p_movd2b::SRC_ZERO_OFFSET + 0, addrmod, p_movd2b::MOV_4_ROWS, 0);
```

For transpose operations needing both SrcA and SrcB:
```cpp
TTI_STALLWAIT(p_stall::STALL_MATH, p_stall::WAIT_SFPU | p_stall::SRCA_VLD | p_stall::SRCB_VLD);
```

<a id="stallwait-conditions--pattern-3-unpack_to_dest-semaphore--unpackmath-handshake"></a>
#### Pattern 3: UNPACK_TO_DEST semaphore — unpack→math handshake

Used when unpacking directly into the Dest register (bypass mode). Unpack thread posts to semaphore 2 (`UNPACK_TO_DEST`) when a tile is ready; math thread waits before starting computation.

```cpp
// In T0 (unpack thread): after unpacking tile to dest
t6_semaphore_post<p_stall::UNPACK0>(semaphore::UNPACK_TO_DEST);
//   expands to:
//   TTI_STALLWAIT(p_stall::STALL_SYNC, p_stall::UNPACK0)  [optional wait]
//   TTI_SEMPOST(semaphore::t6_sem(semaphore::UNPACK_TO_DEST))  // sem_sel=0x4

// In T1 (math thread): before consuming the dest data
t6_semaphore_wait_on_zero<p_stall::STALL_SYNC>(semaphore::UNPACK_TO_DEST);
//   expands to:
//   TTI_SEMWAIT(p_stall::STALL_SYNC, t6_sem(UNPACK_TO_DEST), p_stall::STALL_ON_ZERO)
//   = TTI_SEMWAIT(0x2, 0x4, 0x1)
t6_semaphore_get<p_stall::MATH | p_stall::WAIT_SFPU>(semaphore::UNPACK_TO_DEST);
//   expands to:
//   TTI_STALLWAIT(p_stall::STALL_SYNC, p_stall::MATH | p_stall::WAIT_SFPU)
//   TTI_SEMGET(t6_sem(UNPACK_TO_DEST))
```

<a id="stallwait-conditions--pattern-4-math_pack-semaphore--mathpack-handshake"></a>
#### Pattern 4: MATH_PACK semaphore — math→pack handshake

The most common cross-thread synchronization. Semaphore 1 (`MATH_PACK`) tracks how many tiles math has written into Dest and pack has not yet consumed. Initialized with `Max = number of dest half-buffers`.

```cpp
// T1 (math): before writing results to dest
// STALL_MATH|STALL_SFPU: block math and SFPU until semaphore has room
TTI_SEMWAIT(p_stall::STALL_MATH | p_stall::STALL_SFPU,
            semaphore::t6_sem(semaphore::MATH_PACK),
            p_stall::STALL_ON_MAX);
// = ttsemwait 322, 2, 2
//   stall_res=0x142 (B1|B6|B8), sem_sel=0x2 (sem[1]), cond=C1

// T1: after math is done, signal packer
t6_semaphore_post<p_stall::MATH | p_stall::WAIT_SFPU>(semaphore::MATH_PACK);
//   TTI_STALLWAIT(STALL_SYNC, MATH|WAIT_SFPU)  — wait for FPU+SFPU idle
//   TTI_SEMPOST(t6_sem(MATH_PACK))             — increment sem[1]

// T2 (pack): wait until math has something to pack
TTI_SEMWAIT(p_stall::STALL_TDMA,
            semaphore::t6_sem(semaphore::MATH_PACK),
            p_stall::STALL_ON_ZERO);
// = ttsemwait 1, 2, 1
//   stall_res=0x1 (B0), sem_sel=0x2 (sem[1]), cond=C0

// T2: after pack is done, release dest slot to math
t6_semaphore_get<WaitRes>(semaphore::MATH_PACK);
//   TTI_STALLWAIT(STALL_SYNC, WaitRes) [if WaitRes != NONE]
//   TTI_SEMGET(t6_sem(MATH_PACK))
```

<a id="stallwait-conditions--pattern-5-wait-for-packer-before-reconfiguring"></a>
#### Pattern 5: Wait for packer before reconfiguring

When reconfiguring packer-owned configuration registers, the current packer operation must complete first:

```cpp
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::PACK);
TTI_WRCFG(p_gpr_pack::TMP0, p_cfg::WRCFG_32b, PCK_EDGE_OFFSET_SEC0_mask_ADDR32);
```

Or waiting for both packer and ThCon:
```cpp
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::PACK | p_stall::THCON);
```

<a id="stallwait-conditions--pattern-6-wait-for-sfpu-before-math-dest-bank-flip"></a>
#### Pattern 6: Wait for SFPU before math (dest bank flip)

Before flipping the dest buffer (via SETC16 to configuration), wait for both FPU and SFPU to drain:

```cpp
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::MATH | p_stall::SFPU1);
TT_SETC16(DEST_TARGET_REG_CFG_MATH_Offset_ADDR32, base_addr);
```

Decoded: `ttstallwait 128, 0x810` — block=`STALL_CFG`(B7), wait=`MATH`(C4)|`SFPU1`(C11).

<a id="stallwait-conditions--pattern-7-block-unpacker-until-risc-v-config-writes-complete"></a>
#### Pattern 7: Block unpacker until RISC-V config writes complete

When TRISC0 programs configuration registers from RISC-V code (not through the coprocessor), the unpacker must not start until those writes have propagated:

```cpp
TTI_STALLWAIT(p_stall::STALL_UNPACK, p_stall::TRISC_CFG);
```

Decoded: `ttstallwait 8, 1024` — block=`STALL_UNPACK`(B3), wait=`TRISC_CFG`(C10).

<a id="stallwait-conditions--pattern-8-wait-for-sfpu-then-post-to-sempost-math-thread"></a>
#### Pattern 8: Wait for SFPU then post to SEMPOST (math thread)

After SFPU operations but before posting a semaphore (so the semaphore signals true completion):

```cpp
// In T1, end of compute: wait for FPU+SFPU, then post MATH_PACK
// ttstallwait 2, 2064
TTI_STALLWAIT(p_stall::STALL_SYNC, p_stall::MATH | p_stall::WAIT_SFPU);
TTI_SEMPOST(semaphore::t6_sem(semaphore::MATH_PACK));

// Then wait for FPU+SFPU before changing CFG (dest flip)
// ttstallwait 128, 2064
TTI_STALLWAIT(p_stall::STALL_CFG, p_stall::MATH | p_stall::WAIT_SFPU);
TT_SETC16(...);
```

---

<a id="stallwait-conditions--annotated-disassembly-examples"></a>
### Annotated Disassembly Examples

<a id="stallwait-conditions--t0-unpack-matmul_trisc0s"></a>
#### T0 (unpack): matmul_trisc0.S

```asm
; Before WRCFG — wait for ThCon (SETDMAREG) to complete
6130:  ttstallwait  128, 1          ; STALL_CFG | wait THCON(C0)
6130:  ttwrcfg      12, 0, 124      ; write unpack config reg

; Before UNPACR — wait for TRISC_CFG (RISC-V config write) to complete
62ac:  ttstallwait  8, 1024         ; STALL_UNPACK | wait TRISC_CFG(C10)
62b0:  ttunpacr     ...             ; start unpacking

; Wait for unpack pipelines to drain before ThCon operation
6344:  ttstallwait  32, 6           ; STALL_THCON | wait UNPACK0(C1)|UNPACK1(C2)
```

<a id="stallwait-conditions--t1-math-matmul_trisc1s"></a>
#### T1 (math): matmul_trisc1.S

```asm
; Before dest section flip — wait for FPU to drain
64e4:  ttstallwait  128, 16         ; STALL_CFG | wait MATH(C4=FPU)

; Math/SFPU done, block sync unit, wait for FPU+SFPU
6794:  ttstallwait  2, 2064         ; STALL_SYNC | wait MATH(C4)|SFPU1(C11)
6798:  ttsempost    2               ; post to MATH_PACK (sem[1]) — signal packer

; Block CFG until FPU+SFPU drain (dest flip)
67a4:  ttstallwait  128, 2064       ; STALL_CFG | wait MATH(C4)|SFPU1(C11)

; Wait for MATH_PACK semaphore room (math blocked until packer consumes)
654c:  ttsemwait    322, 2, 2       ; stall=B1|B6|B8, sem[1]=MATH_PACK, cond=STALL_ON_MAX
```

<a id="stallwait-conditions--t2-pack-matmul_trisc2s"></a>
#### T2 (pack): matmul_trisc2.S

```asm
; Block CFG, wait for ThCon (SETDMAREG completing)
6f80:  ttstallwait  128, 1          ; STALL_CFG | wait THCON(C0)
6f84:  ttwrcfg      28, 0, 12       ; write packer config

; Block TDMA+THCON, wait for PACK pipeline to drain
70e8:  ttstallwait  33, 8           ; STALL_TDMA|STALL_THCON | wait PACK0(C3)

; Block CFG, wait for ThCon + PACK (reconfiguring while packing)
7258:  ttstallwait  128, 9          ; STALL_CFG | wait THCON(C0)|PACK0(C3)

; Wait for MATH_PACK semaphore: stall TDMA until math posts something
71fc:  ttsemwait    1, 2, 1         ; stall=B0(TDMA), sem[1]=MATH_PACK, cond=STALL_ON_ZERO

; Block MATH, wait for PACK to finish (before math reads freed dest)
7294:  ttstallwait  64, 8           ; STALL_MATH | wait PACK0(C3)

; Block THCON, wait for PACK (ThCon config after pack done)
72fc:  ttstallwait  32, 8           ; STALL_THCON | wait PACK0(C3)
```

---

<a id="stallwait-conditions--emulator-implementation-notes"></a>
### Emulator Implementation Notes

1. **Latched wait per thread**: Each thread state holds one `LatchedWait` struct (opcode, block_mask, cond_mask, sem_mask, sem_cond). It is overwritten each time a new STALLWAIT or SEMWAIT executes.

2. **Re-evaluation**: Every cycle the Wait Gate evaluates the latched condition against current hardware state. The hardware state inputs needed:
   - Per-thread pipeline occupancy signals: ThCon outstanding, Unpacker 0 in-flight, Unpacker 1 in-flight, Packer in-flight, FPU in-flight, SFPU in-flight.
   - SrcA/SrcB bank ownership state (four possible owners: `None`, `Unpackers`, `MatrixUnit`, or other).
   - Global Mover outstanding count.
   - Per-thread RISC-V config-write-pending flag (C10, rarely needed).
   - Configuration Unit pipeline occupancy across all threads (for C12).
   - 8-element semaphore array `{value: u4, max: u4}`.

3. **Block mask application**: When the condition is not cleared, any instruction whose `block_bits & block_mask != 0` is stalled at the Wait Gate. The Wait Gate holds a single instruction slot; everything behind it in the pipeline is implicitly stalled.

4. **One-cycle release lag**: Implement by letting the release take effect at the start of the next cycle. The instruction that caused the release (the first one past the Wait Gate when the condition clears) sees the block mask still active for one cycle.

5. **Default substitution**: If `stall_res == 0`, treat as `0x40` (B6=STALL_MATH). If `wait_res == 0` in STALLWAIT, treat as `0x0F`.

6. **SEMWAIT `sem_sel` encoding**: The field occupies bits [9:2] of the instruction word. After decoding: `sem_sel_actual = (word >> 2) & 0xFF`. A bit at position `i` selects semaphore `i`. The LLK uses `t6_sem(index) = (1 << index)`.

---

<a id="stallwait-conditions--source-references"></a>
### Source References

- `~/tenstorrent/tt-llk/tt_llk_blackhole/common/inc/ckernel_instr_params.h` — `struct p_stall` (all `STALL_*` and wait condition constants)
- `~/tenstorrent/tt-llk/tt_llk_blackhole/common/inc/ckernel_structs.h` — `struct semaphore` (named semaphore indices, `t6_sem()`)
- `~/tenstorrent/tt-llk/tt_llk_blackhole/common/inc/ckernel_ops.h` — `TT_OP_STALLWAIT`, `TT_OP_SEMWAIT` encoding macros
- `~/tenstorrent/tt-llk/tt_llk_blackhole/common/inc/ckernel.h` — `t6_semaphore_post/get/wait_on_max/wait_on_zero` helpers
- `~/tenstorrent/tt-llk/tt_llk_blackhole/common/inc/cmath_common.h` — `wait_math_semaphores()`, `set_math_semaphores()`, `dest_section_flip()`, MOVD2A/MOVD2B stall patterns
- `~/tenstorrent/tt-llk/tt_llk_blackhole/llk_lib/llk_pack_common.h` — `_llk_packer_wait_for_math_done_()`, pack stall patterns
- `~/tenstorrent/tt-llk/tt_llk_blackhole/common/inc/cpack_common.h` — packer configuration STALLWAIT sequences
- `~/tenstorrent/tt-llk/tt_llk_blackhole/llk_lib/llk_unpack_tilize.h` — unpack STALLWAIT patterns including TRISC_CFG
- `~/tenstorrent/tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/STALLWAIT.md` — authoritative block mask table, condition mask semantics
- `~/tenstorrent/tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SEMWAIT.md` — SEMWAIT functional model, condition mask
- `~/tenstorrent/tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SyncUnit.md` — semaphore data structure, RISCV access
- `~/tenstorrent/blackhole-py/dsl.py` — field definitions: `TT_STALLWAIT`, `TT_SEMWAIT`
- `~/tenstorrent/blackhole-py/disasms/matmul_peak/matmul_trisc{0,1,2}.S` — real-world examples decoded above

<a id="semaphores"></a>
## Semaphores
<a id="semaphores--semaphores"></a>

There are two completely separate semaphore systems. They share the name but have nothing in common architecturally.

<a id="semaphores--1-tensix-hardware-semaphores-coprocessor-sync-unit"></a>
### 1. Tensix Hardware Semaphores (Coprocessor Sync Unit)

8 semaphores inside the Tensix coprocessor, each with a 4-bit `Value` (0-15) and 4-bit `Max` (0-15).

| Index | Name                  | Purpose                                   |
|------:|-----------------------|-------------------------------------------|
|     0 | `FPU_SFPU`            | FPU <-> SFPU sync                         |
|     1 | `MATH_PACK`           | Math <-> Packer sync on dest register     |
|     2 | `UNPACK_TO_DEST`      | Unpack <-> Math sync                      |
|     3 | `UNPACK_OPERAND_SYNC` | Unpack <-> Pack/Math on operand get/release|
|     4 | `PACK_DONE`           | Pack iteration start/end                  |
|     5 | `UNPACK_SYNC`         | TRISC <-> Unpack sync                     |
|     6 | `UNPACK_MATH_DONE`    | Unpack or math iteration done             |
|     7 | `MATH_DONE`           | Wait for math when unpacking to dest      |

<a id="semaphores--manipulation-via-coprocessor-instructions"></a>
#### Manipulation via Coprocessor Instructions

These are Tensix instructions pushed through the instruction FIFO (see `instruction-push.md`):

| Instruction | Behavior |
|---|---|
| `SEMINIT` | Set Value and Max for every selected semaphore |
| `SEMPOST` | Increment selected Values, saturating at **15**, not Max |
| `SEMGET` | Decrement selected Values, flooring at zero |
| `SEMWAIT` | Latch a condition and block the selected resource classes until it clears |

The named roles above are LLK conventions. The September 17
[hardware tests](../../../blackhole-py/tests/isa/test_sync.py) exercise all 256
masks and deliberately choose initial/max pairs that distinguish saturation
at 15 from saturation at Max. Max participates in the wait condition.
Use the encoder or manual for raw words: a RISC custom-instruction encoding
and a FIFO-pushed Tensix word are not interchangeable.

These go through the coprocessor pipeline like any other Tensix instruction. They are ordered with respect to other Tensix instructions in the same thread.

<a id="semaphores--manipulation-via-pcbuf-semaphore-window-risc-v-bypass"></a>
#### Manipulation via PCBuf Semaphore Window (RISC-V bypass)

TRISC0/1/2 can also read/write hardware semaphores directly from RISC-V code through a memory-mapped window in the PCBuf address space, bypassing the instruction FIFO entirely. See `pcbufs.md` for details.

| Operation | Address | Behavior |
|-----------|---------|----------|
| Read sem[i] | `PC_BUF_BASE + 0x20 + i*4` | Returns `Semaphores[i].Value` |
| SEMPOST sem[i] | Write with `val & 1 == 0` | Increment Value (cap at 15) |
| SEMGET sem[i] | Write with `val & 1 == 1` | Decrement Value (floor at 0) |

The semaphore window is at a fixed offset from `PC_BUF_BASE` (`0xFFE80000`), so:

| Semaphore | Address |
|-----------|---------|
| sem[0] | `0xFFE80020` |
| sem[1] | `0xFFE80024` |
| ... | ... |
| sem[7] | `0xFFE8003C` |

All three TRISCs access the same address range (`0xFFE80020-0xFFE8003C`) since there is only one set of 8 semaphores per tile. BRISC and NCRISC cannot access this window.

<a id="semaphores--brisc-initialization"></a>
#### BRISC Initialization

At boot, BRISC initializes semaphores 1 (`MATH_PACK`), 2 (`UNPACK_TO_DEST`), and 7 (`MATH_DONE`) by constructing SEMINIT instruction words and pushing them through `instrn_buf_base(0)`:

```
opcode = 0xa3100000 | (1 << (sem_id + 2))
store opcode to 0xFFE40000   // push SEMINIT to T0's instruction FIFO
```

<a id="semaphores--per-core-access"></a>
#### Per-Core Access

| Core   | Via coprocessor instructions | Via PCBuf window | Notes |
|--------|------------------------------|------------------|-------|
| BRISC  | Can push SEMINIT through instrn_buf | No | Only at init time |
| NCRISC | No | No | No access to hardware semaphores at all |
| TRISC0 | Yes | Yes | Both paths available |
| TRISC1 | Yes | Yes | Both paths available |
| TRISC2 | Yes | Yes | Both paths available |

<a id="semaphores--emulator-implementation"></a>
#### Emulator Implementation

Model the 8 semaphores as an array of `{value: u4, max: u4}`. Handle:
1. Coprocessor instructions (`ttseminit/post/get/wait`) when they reach the execution stage of the Tensix pipeline.
2. Loads from `0xFFE80020-0xFFE8003C` return `semaphores[offset].value`.
3. Stores to `0xFFE80020-0xFFE8003C` do SEMPOST or SEMGET based on bit 0 of the written value.

---

<a id="semaphores--2-software-semaphores-l1-memory-words"></a>
### 2. Software Semaphores (L1 Memory Words)

These are plain `uint32_t` values in L1. No special hardware. If the emulator already supports L1 memory and NOC operations, these work automatically.

<a id="semaphores--what-they-are"></a>
#### What They Are

A "software semaphore" is just a 32-bit word at a 16-byte-aligned L1 address. The API:

```c
// Set = plain store
void noc_semaphore_set(volatile uint32_t* sem_addr, uint32_t val) {
    *sem_addr = val;
}

// Wait = spin-loop on a plain load
void noc_semaphore_wait(volatile uint32_t* sem_addr, uint32_t val) {
    do { invalidate_l1_cache(); } while (*sem_addr != val);
}
```

`invalidate_l1_cache()` is for Blackhole's optional L1 data cache. In emulation there's no cache, so this is a no-op. The wait is just a spin on a load.

<a id="semaphores--layout-in-l1"></a>
#### Layout in L1

The base address is not fixed. It's computed at kernel launch:

```c
sem_l1_base[index] = kernel_config_base[index] + launch_msg->kernel_config.sem_offset[index];
```

Each semaphore slot is 16 bytes (only first 4 used), up to 16 semaphores per core type = 256 bytes total.

```
get_semaphore(id) = sem_l1_base + id * 16
```

<a id="semaphores--remote-signaling-cross-tile"></a>
#### Remote Signaling (Cross-Tile)

Three mechanisms, all using the NOC:

| Function | Mechanism | Use case |
|----------|-----------|----------|
| `noc_semaphore_set_remote` | Plain 4-byte NOC write | Single sender overwrites remote sem |
| `noc_semaphore_inc` | NOC atomic increment (`NOC_AT_INS_INCR_GET`) | Multiple senders safely increment one receiver |
| `noc_semaphore_set_multicast` | NOC multicast write | Signal multiple tiles at once |

The NOC atomic increment (`noc_semaphore_inc`) is the only part that uses hardware assist. It programs the NIU AT command buffer with opcode `0x1` (INCR_GET), which performs a read-modify-write at the destination L1 address and returns the old value to `MEM_NOC_ATOMIC_RET_VAL_ADDR` (L1 offset 4).

Blackhole-specific: all atomics are forced non-posted (require ack) due to a hardware issue with memory port contention.

<a id="semaphores--per-core-access-1"></a>
#### Per-Core Access

All 5 RISC-V cores can read/write software semaphores (they're just L1 memory). BRISC and NCRISC are the primary users for cross-tile coordination. TRISCs can access them too but typically use hardware semaphores for intra-tile sync.

<a id="semaphores--emulator-implementation-1"></a>
#### Emulator Implementation

Nothing to do. These are plain L1 loads/stores and NOC writes/atomics, all of which the emulator already handles.

<a id="mutexes"></a>
## Mutexes
<a id="mutexes--mutexes"></a>

Hardware mutexes in the Tensix Sync Unit provide exclusive mutual exclusion among the three coprocessor threads (T0, T1, T2) within a single tile. They are manipulated by two instructions: `ATGETM` (acquire) and `ATRELM` (release).

Mutexes are unrelated to semaphores. Semaphores are counting primitives for producer/consumer synchronization (see `semaphores.md`). Mutexes are exclusive locks for protecting shared register read-modify-write sequences.

---

<a id="mutexes--hardware-state"></a>
### Hardware State

There are 4 mutexes per tile. Each mutex holds a 2-bit owner field:

```
Mutex[i].HeldBy : enum { Nobody, T0, T1, T2 }
```

Valid indices: **0, 2, 3, 4**. Index 1 is invalid. Indices > 4 are invalid. Using an invalid index causes the issuing thread to wait forever.

| Index | Name     | Typical use |
|------:|----------|-------------|
|     0 | `math`   | Atomic config register read-modify-write (`REG_RMW`) between threads |
|     2 | `unpack0`| Unpacker 0 |
|     3 | `unpack1`| Unpacker 1 |
|     4 | `pack0`  | Packer 0 / SFPU (SFPU instructions can be issued by both T1 and T2) |

Initial state at reset: all mutexes are `Nobody` (not held).

<a id="mutexes--comparison-with-wormhole-b0"></a>
#### Comparison with Wormhole B0

Wormhole B0 has 7 mutexes (indices 0, 2, 3, 4, 5, 6, 7) — the extra three are `pack1` (5), `pack2` (6), `pack3` (7). Index 1 is still invalid. Blackhole reduced the count to 4.

---

<a id="mutexes--instruction-encodings"></a>
### Instruction Encodings

Both instructions are 32 bits wide. The top 8 bits are the opcode, the bottom 24 bits are the `mutex_index` field (only the low 3 bits matter in practice).

<a id="mutexes--atgetm--acquire-mutex-opcode-0xa0"></a>
#### ATGETM — Acquire Mutex (opcode `0xA0`)

```
 31      24 23                              0
┌─────────┬──────────────────────────────────┐
│ 0xA0    │         mutex_index              │
│ [31:24] │            [23:0]                │
└─────────┴──────────────────────────────────┘
```

```c
#define TT_OP_ATGETM(mutex_index) TT_OP(0xa0, ((mutex_index) << 0))
// word = (0xA0 << 24) | (mutex_index & 0xFFFFFF)
```

<a id="mutexes--atrelm--release-mutex-opcode-0xa1"></a>
#### ATRELM — Release Mutex (opcode `0xA1`)

```
 31      24 23                              0
┌─────────┬──────────────────────────────────┐
│ 0xA1    │         mutex_index              │
│ [31:24] │            [23:0]                │
└─────────┴──────────────────────────────────┘
```

```c
#define TT_OP_ATRELM(mutex_index) TT_OP(0xa1, ((mutex_index) << 0))
// word = (0xA1 << 24) | (mutex_index & 0xFFFFFF)
```

Both instructions use execution resource `SYNC` and are routed to the Sync Unit backend.

---

<a id="mutexes--functional-model"></a>
### Functional Model

<a id="mutexes--atgetm-acquire"></a>
#### ATGETM (Acquire)

The instruction blocks at the Wait Gate until it can acquire the mutex, then proceeds through the Sync Unit in 1 cycle.

```c
void ATGETM(uint thread_id, uint index) {
    // 1. Validate index
    if (index == 1 || index > 4) {
        while (true) { wait; }  // infinite stall
    }

    // 2. Wait for availability
    if (Mutex[index].HeldBy == thread_id) {
        // Already held by this thread — reentrant acquire.
        // May wait 1-2 cycles due to contention with other threads'
        // concurrent ATGETM/ATRELM on the same mutex.
    } else {
        // Spin at the Wait Gate until the mutex is free.
        while (Mutex[index].HeldBy != Nobody) {
            wait;
        }
    }

    // 3. Acquire
    Mutex[index].HeldBy = thread_id;
}
```

If multiple threads are waiting for the same free mutex simultaneously, one is chosen to acquire it. The fairness guarantee comes from `ATRELM` (see below).

<a id="mutexes--atrelm-release"></a>
#### ATRELM (Release)

```c
void ATRELM(uint thread_id, uint index) {
    // 1. Validate index
    if (index == 1 || index > 4) {
        while (true) { wait; }  // infinite stall
    }

    // 2. May wait 1-2 cycles due to contention with concurrent
    //    ATGETM/ATRELM from other threads on the same mutex.

    // 3. Release (only if held by this thread)
    if (Mutex[index].HeldBy == thread_id) {
        Mutex[index].HeldBy = Nobody;
    }
    // If not held by this thread, instruction completes with no effect.
}
```

**Round-robin fairness:** When thread `i` releases a mutex and *both* other threads are waiting on it via `ATGETM`, thread `(i + 1) % 3` is chosen as the next acquirer.

---

<a id="mutexes--timing-and-throughput"></a>
### Timing and Throughput

| Property | Value |
|----------|-------|
| Latency | 1 cycle (once through the Wait Gate) |
| Throughput | Up to 3 ATGETM/ATRELM per cycle, if they reference **different** mutexes |
| Contention delay | 1-2 extra cycles if multiple threads touch the same mutex simultaneously |
| Blocked-thread behavior | Thread stalls at the Wait Gate; no instructions from that thread proceed past the gate |

Semaphore instructions (SEMINIT, SEMPOST, SEMGET, SEMWAIT) share the Sync Unit but have independent throughput — at most 1 semaphore instruction per cycle. Mutex and semaphore instructions can execute concurrently.

---

<a id="mutexes--interaction-with-stallwait"></a>
### Interaction with STALLWAIT

ATGETM and ATRELM are classified as Sync Unit instructions. They are blocked by the `STALL_SYNC` (B1, value `0x02`) bit in a `STALLWAIT`/`SEMWAIT` block mask.

If a thread has a latched `STALLWAIT` with B1 set and the wait condition has not yet been met, any ATGETM or ATRELM from that thread is held at the Wait Gate until the STALLWAIT condition clears.

See `stallwait-conditions.md` for the full block mask reference.

---

<a id="mutexes--per-core-access"></a>
### Per-Core Access

Mutexes are only accessible from the three Tensix coprocessor threads (T0, T1, T2) via pushed Tensix instructions.

| Core   | Can use ATGETM/ATRELM? | Notes |
|--------|------------------------|-------|
| TRISC0 (T0) | Yes | Pushes instructions to T0's FIFO |
| TRISC1 (T1) | Yes | Pushes instructions to T1's FIFO |
| TRISC2 (T2) | Yes | Pushes instructions to T2's FIFO |
| BRISC        | No  | Cannot push ATGETM/ATRELM |
| NCRISC       | No  | Cannot push ATGETM/ATRELM |

There is no memory-mapped interface for mutexes (unlike semaphores, which have the PCBuf semaphore window). The only way to manipulate mutexes is through the Tensix instruction FIFO.

---

<a id="mutexes--emulator-implementation"></a>
### Emulator Implementation

<a id="mutexes--state"></a>
#### State

```python
# 4 mutexes. HeldBy is None (nobody) or 0/1/2 (thread id).
mutex_held_by = [None] * 5  # indexed 0-4; index 1 is unused/invalid

VALID_MUTEX_INDICES = {0, 2, 3, 4}
```

<a id="mutexes--decoding"></a>
#### Decoding

```python
def decode(word):
    opcode = (word >> 24) & 0xFF
    mutex_index = word & 0xFFFFFF  # only low bits matter
    return opcode, mutex_index
```

<a id="mutexes--execution"></a>
#### Execution

```python
def exec_atgetm(thread_id, index):
    """Returns True if acquired, False if must stall."""
    if index not in VALID_MUTEX_INDICES:
        return False  # stall forever (or raise in emulator)

    held = mutex_held_by[index]
    if held is None or held == thread_id:
        mutex_held_by[index] = thread_id
        return True   # acquired
    else:
        return False  # stall — re-evaluate next cycle

def exec_atrelm(thread_id, index):
    """Always completes (never stalls, beyond 1-2 cycle contention)."""
    if index not in VALID_MUTEX_INDICES:
        return False  # stall forever (or raise in emulator)

    if mutex_held_by[index] == thread_id:
        mutex_held_by[index] = None
    # else: no effect
    return True
```

For a cycle-accurate emulator, `exec_atgetm` should be called each cycle while the thread's instruction pointer is parked on the ATGETM. The thread's pipeline stalls (no further instructions issue) until the function returns `True`.

For a functional emulator that doesn't model cycle-level timing, you can treat ATGETM as an immediate acquire if the mutex is free, and use a simple scheduling policy (round-robin or arbitrary) to resolve contention when multiple threads attempt to acquire the same mutex in the same "step."

<a id="mutexes--fairness-optional-for-functional-emulation"></a>
#### Fairness (optional for functional emulation)

If modeling round-robin fairness: when `exec_atrelm` releases mutex `i` from thread `t`, and both other threads are stalled on ATGETM for mutex `i`, the next acquirer should be thread `(t + 1) % 3`.

---

<a id="mutexes--real-world-usage-pattern"></a>
### Real-World Usage Pattern

The primary use of mutexes in existing kernels is protecting shared config register read-modify-write (RMW) sequences between T0 (unpack) and T2 (pack), since both threads need to modify `ALU_FORMAT_SPEC_REG` registers:

```c
// T0 (cunpack_common.h) — unpack config
t6_mutex_acquire(mutex::REG_RMW);    // ATGETM(0)
cfg_reg_rmw_tensix<ALU_FORMAT_SPEC_REG_SrcA_val_ADDR32, ...>(alu_src_format);
// ... more RMW operations ...
t6_mutex_release(mutex::REG_RMW);    // ATRELM(0)

// T2 (cpack_common.h) — pack config
t6_mutex_acquire(mutex::REG_RMW);    // ATGETM(0)
cfg_reg_rmw_tensix<ALU_FORMAT_SPEC_REG2_Dstacc_RMW>(pack_output_src_format);
cfg_reg_rmw_tensix<STACC_RELU_ApplyRelu_ADDR32, ...>(relu_config);
t6_mutex_release(mutex::REG_RMW);    // ATRELM(0)
```

The C++ layer provides an RAII guard for convenience:

```c++
// ckernel_mutex_guard.h
{
    T6MutexLockGuard guard(mutex::REG_RMW);
    // critical section — automatically released on scope exit
}
```

<a id="pcbufs"></a>
## PCBufs (PC Buffers)
<a id="pcbufs--pcbufs-pc-buffers"></a>

<a id="pcbufs--overview"></a>
### Overview

3 PCBufs per Tensix tile. Each is a 16-entry FIFO of 32-bit values from BRISC to one TRISC. They serve as the control/dispatch channel: BRISC tells TRISCs what kernel to run, and uses PCBuf reads as a synchronization barrier.

PCBufs are completely separate from instruction buffers (see `instruction-push.md`). Instruction buffers push Tensix coprocessor opcodes. PCBufs pass control tokens between RISC-V cores and provide a semaphore access window.

<a id="pcbufs--addresses"></a>
### Addresses

| PCBuf | Address | Direction |
|-------|---------|-----------|
| PCBuf[0] | `0xFFE80000` (`PC_BUF_BASE`) | BRISC -> TRISC0 |
| PCBuf[1] | `0xFFE90000` (`PC1_BUF_BASE`) | BRISC -> TRISC1 |
| PCBuf[2] | `0xFFEA0000` (`PC2_BUF_BASE`) | BRISC -> TRISC2 |

<a id="pcbufs--access-rules"></a>
### Access Rules

| Core | Write (push) | Read (pop/sync) |
|------|-------------|-----------------|
| BRISC | Yes (all 3 PCBufs) | Yes (sync barrier) |
| NCRISC | No | No |
| TRISC0 | No | Yes (own PCBuf[0] only) |
| TRISC1 | No | Yes (own PCBuf[1] only) |
| TRISC2 | No | Yes (own PCBuf[2] only) |
| NOC | No | No |
| Tensix coprocessor | No | No |

<a id="pcbufs--memory-map-within-each-pcbuf"></a>
### Memory Map Within Each PCBuf

From the TRISC's perspective, the PCBuf region starting at `0xFFE80000` contains:

| Offset | Word | Name | Behavior |
|--------|------|------|----------|
| `0x00` | 0 | FIFO pop | TRISC read: blocks until a value is available, returns the next queued word. BRISC write: pushes a value into the FIFO. |
| `0x04` | 1 | `CoprocessorDoneCheck` | TRISC read: blocks until this TRISC's coprocessor thread is idle (no in-flight instructions). Used by `tensix_sync()`. |
| `0x08` | 2 | `MOPExpanderDoneCheck` | TRISC read: blocks until the MOP expander has finished expanding. Used by `mop_sync()`. |
| `0x0C-0x1C` | 3-7 | Reserved/padding | |
| `0x20` | 8 | `SemaphoreAccess[0]` | Read/write to hardware semaphore 0 (see semaphores.md) |
| `0x24` | 9 | `SemaphoreAccess[1]` | sem 1 |
| `0x28` | 10 | `SemaphoreAccess[2]` | sem 2 |
| `0x2C` | 11 | `SemaphoreAccess[3]` | sem 3 |
| `0x30` | 12 | `SemaphoreAccess[4]` | sem 4 |
| `0x34` | 13 | `SemaphoreAccess[5]` | sem 5 |
| `0x38` | 14 | `SemaphoreAccess[6]` | sem 6 |
| `0x3C` | 15 | `SemaphoreAccess[7]` | sem 7 |

Note: all three TRISCs read the semaphore window at the same base address (`0xFFE80020-0xFFE8003C`) because there is only one set of 8 hardware semaphores per tile.

<a id="pcbufs--brisc-write-semantics"></a>
### BRISC Write Semantics

BRISC pushes control tokens into a TRISC's PCBuf FIFO. Known token formats:

| Token | Value | Meaning |
|-------|-------|---------|
| `TENSIX_NEWPC_VAL(addr)` | `0x80000000 \| addr` | Unhalt the TRISC and jump to `addr` |
| `TENSIX_LOOP_PC_VAL(arg)` | `0x00000000 \| arg` | Start a PC buffer loop |
| `TENSIX_UNHALT_VAL` | `0x40000000` | Unhalt and resume at previous PC |
| `TENSIX_PC_SYNC(arg)` | `0xC0000000 \| arg` | Sync block until kernels done |

If the FIFO is full (16 entries), BRISC's write stalls until space is available.

<a id="pcbufs--brisc-read-semantics-sync-barrier"></a>
### BRISC Read Semantics (Sync Barrier)

A BRISC read from `PC_BUF_BASE` / `PC1_BUF_BASE` / `PC2_BUF_BASE` is a **three-condition hardware barrier**. It blocks until ALL of:
1. The FIFO is fully drained (TRISC has consumed all queued values)
2. The TRISC itself is blocking on a PCBuf read (waiting for more work)
3. The Tensix coprocessor thread for that TRISC is idle (no in-flight instructions)

This is how BRISC knows a TRISC has completely finished its kernel.

<a id="pcbufs--trisc-read-semantics"></a>
### TRISC Read Semantics

<a id="pcbufs--fifo-pop-offset-0x00"></a>
#### FIFO Pop (offset 0x00)
Blocking read. Returns the next 32-bit value BRISC pushed. If the FIFO is empty, the TRISC stalls until BRISC pushes something.

<a id="pcbufs--coprocessordonecheck-offset-0x04"></a>
#### CoprocessorDoneCheck (offset 0x04)
Blocking read. Returns only when this TRISC's coprocessor thread has finished executing all previously-pushed instructions. Used by `tensix_sync()`:
```c
inline void tensix_sync() {
    store_blocking(&pc_buf_base[1], 0);  // write 0 then read, blocks until idle
}
```

<a id="pcbufs--mopexpanderdonecheck-offset-0x08"></a>
#### MOPExpanderDoneCheck (offset 0x08)
Blocking read. Returns only when the MOP expander has finished expanding all queued MOPs.

<a id="pcbufs--semaphore-window-offsets-0x20-0x3c"></a>
#### Semaphore Window (offsets 0x20-0x3C)
See `semaphores.md`. Read returns the semaphore value. Write does SEMPOST (bit 0 == 0) or SEMGET (bit 0 == 1).

<a id="pcbufs--observed-usage-in-disassembly"></a>
### Observed Usage in Disassembly

<a id="pcbufs--triscs-polling-pcbuf-status"></a>
#### TRISCs polling PCBuf status
TRISCs poll `0xFFE80034` (offset 0x34 = `SemaphoreAccess[5]`) to check semaphore state before proceeding:
```
ffe806b7  lui   a3, 0xffe80
0346a703  lw    a4, 52(a3)     # read 0xFFE80034
0ff77713  zext.b a4, a4
fe071ce3  bnez  a4, <spin>     # spin until zero
```

<a id="pcbufs--brisc-pushing-instructions-at-init"></a>
#### BRISC pushing instructions at init
BRISC writes SEMINIT opcodes through `instrn_buf_base(0)` at `0xFFE40000` (not through PCBuf). PCBuf is for control tokens, not coprocessor instructions.

<a id="pcbufs--current-tt-metal-firmware"></a>
### Current tt-metal Firmware

In current tt-metal Blackhole firmware, TRISCs don't actually pop from PCBuf for kernel dispatch. Instead, BRISC writes `RUN_SYNC_MSG_GO` to an L1 mailbox and TRISCs poll that. The PCBuf mechanism is still available and used for `tensix_sync()` and hardware semaphore access, but primary dispatch uses L1 polling.

<a id="pcbufs--emulator-implementation"></a>
### Emulator Implementation

Model each PCBuf as:
1. A 16-entry FIFO of uint32_t (BRISC pushes, TRISC pops)
2. BRISC write stalls if full, TRISC read stalls if empty
3. BRISC read from PCBuf base = three-condition barrier (FIFO drained + TRISC waiting + coprocessor idle)
4. Offset 0x04: read blocks until coprocessor thread idle
5. Offset 0x08: read blocks until MOP expander done
6. Offsets 0x20-0x3C: semaphore access window (shared across all TRISCs)
