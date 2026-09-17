# Blackhole cycle cheat sheet and five-stream predictor reference

Snapshot: **2026-09-09**. Target: one Blackhole Tensix tile, its **BRISC, NCRISC, TRISC0, TRISC1, TRISC2** programs, and the shared engines they drive. This is a timing reference and calibration dataset, **not an already validated full-chip cycle simulator**. Wormhole material is used where the Blackhole ISA explicitly shares it; Wormhole-only bandwidth or cache details are not silently promoted to Blackhole facts.

For predicting cycles, use the instruction/resource rules below. For comparing existing implementations, use the measured sequence tables and their exact configurations. A number such as “19.25 cycles/vector add” includes instrumentation and completion and does **not** replace the SFPU add's **2-cycle result latency / 1-instruction-per-cycle throughput**.

## Navigation and complete data

- [Quick constants](#quick-constants) and [what a cycle count means](#timing-definitions).
- [RISC-V](#risc-v-core), [instruction delivery](#tensix-instruction-delivery), [SFPU register availability](#sfpu), [FPU](#matrix-fpu), [unpacker/packer](#unpackers-and-packers), [scalar/configuration/synchronization](#scalar-configuration-and-synchronization).
- [Five-stream predictor design](#five-stream-predictor-design), [measurement pitfalls](#measurement-pitfalls), [remaining gaps](#remaining-gaps).
- **[Every compiler opcode](instruction-catalog.md)**: 134 entries, including explicit unknowns; [JSON](instruction-timing.json). **[All 75 documented SFPU mode rows](sfpu-modes.json)** preserve modifier-dependent differences.
- **[Fresh hardware results](fresh-results.md)**: all five RISC roles, scalar FP, SFPU dependencies/issue, local RAM, cache and fusion configurations; raw seven-sample arrays in `evidence/*.jsonl`.
- **[All archived timing tables and measured cases](evidence-index.md)**: searchable [CSV](measurement-tables.csv) and [JSONL](measurement-records.jsonl), with original source/line or JSON pointer. These include NoC/DRAM and the full operation/format/placement/length sweeps. Controls and historical records remain labeled.
- [Source hashes/revisions](sources.json), [hardware run provenance](evidence/runs.json), [catalog regeneration script](build_catalog.py).

Evidence labels: **D** = ISA documentation; **M** = hardware measurement under the stated conditions; **I** = inference/modeling rule; **?** = unmeasured or insufficiently characterized. A lower bound is not an exact latency. An opcode's presence in an encoding file is not a performance or correctness guarantee.

The follow-up [FP8 single-card inference comparison](../../../blackhole-py-llama3-8b-fp8/validation/risc-config-results.md) measured about 0.76–0.77% higher throughput with L0 and fusion enabled, with exact token and sampled-logit matches. Both are now enabled in that FP8 runtime; the original `blackhole-py` baseline timings below retain their stated configuration.

## Quick constants

| Component / operation | Result or service latency, cycles | Initiation / issue | Evidence / qualification |
|---|---:|---|---|
| RISC integer ALU, shifts, comparisons | 1 | 1/core/cycle | D; M approximately 1 excluding loop |
| RISC integer multiply | 2 | 1/core/cycle independent | D; dependency interleaving matters |
| RISC scalar FP add/mul/FMA | 2 for arithmetic pipeline | 1/core/cycle independent | D; M for `.s`; not SFPU |
| RISC div/rem | 2 for special operands; otherwise 6–33 | EX1 occupied for duration | D; M 2 for divide by 1 and 33 for `0xffffffff / 3` |
| Correctly predicted branch | 1 | 1/core/cycle | D; misprediction adds 4, plus possible fetch miss |
| Core-local RAM load / enabled L0 hit | 2 | Dependencies and retire queue limit | D; M local-RAM chain and enabled-cache probe |
| L1 load, no L0 hit | ≥8 | Memory/port/bank dependent | D; M dependency-chain slope 8 in default firmware |
| CSR read / empty `fence` | approximately 4 measured | Serializing by default | M; not a fixed bound with outstanding work |
| SFPU simple operation / load / store | 1 at SFPU boundary | 1 SFPU instruction/cycle | D; Dst cross-engine visibility is separate |
| SFPU add/mul/MAD/LUT/MUL24 | 2 | 1/cycle independent; dependent chain 2 | D + M for add/mul/MAD/MUL24 |
| SFPU swap / selected shuffle modes | 2 | Following-cycle restriction | D; M sustained repeated operation every 2 cycles |
| FPU arithmetic | 5 | 1 architectural instruction/cycle | D; fidelity/row/format/scheduling restrictions apply |
| Uncompressed `UNPACR` initial address calculation | 2 | Blocks issuing thread and other UNPACR starts during these cycles | D; data completion is additional and variable |
| Unpacker desired input rate | 16 / 32 / 64 bytes/cycle | x1 / x2 / x4 | D; two unpackers interfere, see matrix below |
| Pack command admission | Variable | At most 1 command starts/cycle | D; command accepted ≠ pack finished ≠ L1 visible |
| `SETDMAREG`, `DMANOP` unit execution | 1 | Shared scalar unit, no internal pipeline | D; fresh DMANOP stream costs ~2, so keep thread continuation separate |
| Scalar GPR arithmetic | 3 or 4 | Shared unit and issuing thread blocked | D; immediate/register-group dependent |
| `SETC16` | 1 | One/thread/cycle, up to 3 | D; separate from shared Config pipeline |
| `WRCFG` / `RMWCIB` / `CFGSHIFTMASK` | 2 / 1 / 2 | 1 / 1 / 0.5 per cycle, shared Config group | D |
| Semaphore/mutex instruction execution | 1 | Resource-specific; waits can be unbounded | D; don't price blocked waits at 1 |
| TRISC `.ttinsn` fusion | Up to 4 enqueued per RISC cycle | At most 1 dequeued/thread/cycle | D; disabled by the measured default firmware |
| First Tensix FIFO | Capacity 32, admission threshold 28 | Backpressure if occupancy >28 | D; not a simple unconstrained depth-32 queue |

Sources for this table are expanded in each unit section below. For ns, use `cycles / actual_GHz`; for microseconds, `cycles / (actual_GHz * 1000)`. **Do not assume 1.35 GHz or 800 MHz from a historical report** when converting a new run. AICLK, NoC clock, host elapsed time, and device cycle counters are distinct quantities.

## Timing definitions

At minimum keep these separate in an instruction model:

| Quantity | Meaning |
|---|---|
| RISC issue cost | Time to execute the producer RISC instruction(s), including address/constant formation if in scope |
| Frontend acceptance | When an instruction enters the Tensix FIFO; a pushed instruction may wait there |
| Backend start | When the relevant unit accepts the expanded instruction after arbitration and wait gates |
| Initiation interval (II) | Earliest spacing between starts using that resource; `IPC = 1/II` for a single stream |
| Result latency | Backend start to result usable by the specified consumer, not necessarily by every engine |
| Occupancy | How long a stage/resource is reserved; distinct from both latency and II for pipelined units |
| Retirement | RISC architectural commit, which can lag a forwarded result |
| Completion / visibility | Work drained to an explicitly named boundary: SFPU, packer, L1, NoC source-read, remote acknowledgement, etc. |
| Sequence cost | A measured helper, loop, tile, or kernel interval; may include setup, markers and synchronization |

Use `t_consumer >= t_producer + L` with backend issue at cycle `t` and a latency `L`. A 1-cycle result can be consumed by the next instruction at `t+1`; a 2-cycle result requires one intervening cycle. This convention avoids ambiguous “two NOPs for latency two” interpretations.

## RISC-V core

Primary sources: [Blackhole pipeline and memory latency](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/README.md), [supported ISA](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/InstructionSet.md), [CSR/chicken bits](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/CSRs.md), [memory ordering](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/MemoryOrdering.md).

### Integer, FP, branches and system operations

| Instructions / family | Latency / blocking rule | Throughput / caveat |
|---|---|---|
| `ADD SUB ADDI`, `LUI AUIPC`, `AND OR XOR ANDI ORI XORI`, `SLL SRL SRA SLLI SRLI SRAI`, `SLT SLTU SLTI SLTIU` | Ordinary 1-cycle EX1 | 1/cycle with ready inputs |
| Zba: `SH1ADD SH2ADD SH3ADD` | Ordinary integer path; older adjusted measurements ~1 | 1/cycle in tested cases |
| Zbb: `ANDN ORN XNOR CLZ CTZ CPOP MIN MINU MAX MAXU ORC.B REV8 ROL ROR RORI SEXT.B SEXT.H ZEXT.H`; `PACK BREV8 GREVI` | Supported; covered by ordinary integer EX1 description | Not every opcode independently calibrated; historical tests cover a subset |
| `MUL MULH MULHSU MULHU` | EX1+EX2 = 2 | 1/cycle independent; next dependent multiply stalls |
| `DIV DIVU REM REMU` | Divisor 0 or 1: 2; signed `INT_MIN / -1`: 2; otherwise 6–33 depending on dividend magnitude | EX1 blocked, so independent integer instructions cannot issue around division; don't assign 6 to all operands |
| `BEQ BNE BLT BGE BLTU BGEU JAL JALR` | 1 when prediction correct; misprediction adds 4 | Taken/not-taken alone does not determine cost; fetch miss can add more |
| `CSRRW CSRRS CSRRC CSRRWI CSRRSI CSRRCI` | Subsequent instructions wait for retirement unless `DisCsrSync` changes it | Read-only CSRRS/CSRRC ~4 in old probes; fresh `CSRRS cycle` ~4 excluding loop |
| `FENCE` | Waits for store queue drain and in-flight loads' values; flushes L0 | Empty fence ~4 measured; does not guarantee every device write has reached its final destination |
| `EBREAK` | Debug pause until externally resumed | Not a finite normal instruction latency |
| `ECALL`, `MRET`, interrupt handling | Special control flow, not calibrated here | `MRET` supported only on B/NC; model external service/handlers |
| Scalar `FADD.S FSUB.S FMUL.S FMADD.S FMSUB.S FNMSUB.S FNMADD.S`, half counterparts | FP arithmetic EX1+EX2 | Fresh `.s` add/mul/FMA dependency slope ~2; half and other modes not independently measured |
| FP moves/conversions/comparisons/sign operations | Supported subset must be decoded from ISA | Do not infer an exact latency for all FP instructions from FADD's two stages |
| `LB LBU LH LHU LW`, `FLW FLH` | Address-region dependent; scalar forwarding where supported | Misalignment/unsupported mode behavior needs separate treatment |
| `SB SH SW`, `FSW FSH` | Store instruction can retire before memory visibility | Queue coalescing/port occupancy matters |
| `AMOADD.W AMOSWAP.W AMOXOR.W AMOOR.W AMOAND.W AMOMIN.W AMOMAX.W AMOMINU.W AMOMAXU.W` | L1 only, documented ≥12 load-result latency | Executes as if `aq=rl=1`; flush/serialization and contention additional |

Unsupported examples: RISC compressed `C`, `LR.W/SC.W`, scalar `FDIV/FSQRT`, several vector div/sqrt/reciprocal operations. Their encodings must not be given a plausible cycle cost. Floating arithmetic is not fully IEEE-conforming: denormal behavior and partial-FMA semantics affect correctness and data-dependent downstream execution.

### Memory-result availability

| Load target | Minimum result latency | Predictor dependency/state |
|---|---:|---|
| Own local RAM via `0xFFB00000` mapping | 2 | Private low-latency path, not the slow alias |
| L1 with enabled L0 hit | 2 | Per-RISC 4 lines ×16 bytes; noncoherent; replacement/flush state |
| Mailbox, PCBuf, manual TTSync, Tensix semaphore | ≥3 | Empty FIFO/synchronization can wait indefinitely |
| Tensix GPRs, backend config, TDMA register interface | ≥4 | Shared unit access, Auto TTSync, conflicts |
| Tile/debug/PIC/NoC0/NoC1/overlay MMIO | ≥7 | Endpoint and bus arbitration |
| Another RISC's local RAM via slow alias | ≥8 | Shared interconnect, even with different target RAMs |
| L1 cache miss or cache disabled | ≥8 | Request/port/bank arbitration and outstanding-load capacity |
| L1 atomic result | ≥12 | Read-modify-write and serialization |

An `N`-cycle load generally needs `N-1` independent instructions after it to hide latency. There are **8 retire-order entries**, every normal instruction reserves one (including stores and writes to `x0`), and retirement commits at most one per cycle. Scalar operands can forward from completed entries before retirement. Multiple pending writes to the same register can defeat forwarding; the ISA specifically recommends distinct destination registers in the seven instructions after a slow load. Vector instructions cannot use this scalar forwarding network.

Sustained L1 stores: coalescible aligned 16-byte groups can support 1 scalar store/cycle. If they cannot form suitable full writes, service can be 1 coalesced store/5 cycles. Coalescing also merges repeated writes to the same word; “same address store =1 cycle” does **not** establish 1 visible uncoalesced word/cycle. Non-L1 MMIO stores are not coalesced this way. Store-to-overlapping-load forces draining; nonoverlapping loads can bypass the store queue, subject to configuration.

### Firmware state is part of the timing model

Fresh readback on **both cards, all five roles**: `cfg0=0x60008`, `pmacfg0=pmacfg1=0`.

- Bit 3 `DisLowCash=1`: L0 data cache disabled. Thus the test named `load_l1_hot_dep` is a same-address workload, **not an actual cache hit** in the default run; measured ~8 cycles/load.
- Bit 18 `DisTriscCache=1`: adjacent `.ttinsn` fusion disabled.
- `StMergeTimer=16`; store coalescing remains enabled. Branch prediction and scalar forwarding remain enabled.
- Clearing bit 3 temporarily brings the same-address pointer chase close to 2 cycles/load; periodic cache flushing remains enabled, so samples are not exactly 2. Eight distinct lines still cost ~8. Clearing bit 18 brings independent SFPU throughput to 1/cycle under the test loop.

The new probes restore the original cleared bits before returning. They do not change persistent firmware. Data-cache enablement requires correct `fence`/publication/polling behavior: L0 is noncoherent. A search optimizer must not remove fences just because the resulting instruction sequence has a lower predicted count.

### TRISC2 RISC vector instructions

TRISC2 alone has a **128-bit RISC-V vector register file**, separate from the 32-lane Tensix SFPU. LMUL>1 splits instructions into micro-ops and consumes multiple retire entries. Some operations further split per element; vector operands must wait for register-file retirement. The ISA reports destination false dependencies and fractional-LMUL dependency issues. VLEN, SEW, LMUL, VL, mask/tail policy and opcode all affect time. **No universal RVV CPI is supplied here**; don't use SFPU timings for these instructions. The [local ISA's RVV section](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/InstructionSet.md) links an external per-op RVV benchmark; its data is not part of the local calibration snapshot.

## Tensix instruction delivery

Sources: [Blackhole push/fusion/FIFO](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/PushTensixInstruction.md), [shared coprocessor frontend](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/README.md), [MOP](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOPExpander.md), [REPLAY](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/REPLAY.md), [Auto TTSync](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/AutoTTSync.md), [Manual TTSync](../../../tt-isa-documentation/BlackholeA0/TensixTile/BabyRISCV/ManualTTSync.md).

```text
B / NC / T0 / T1 / T2: independent scalar PCs and retire queues
                  T0/T1/T2 each feed their own Tensix frontend:
RISC store / fused .ttinsn -> FIFO -> MOP -> REPLAY -> wait gate -> shared engines
                                      ^
                           BRISC injects after MOP
```

1. `sw` to an instruction FIFO and `.ttinsn` are asynchronous submissions. RISC issue completion says nothing by itself about arithmetic completion.
2. TRISC0/1/2 write `0xFFE40000`, remapped to their own thread. BRISC can target T0/T1/T2 with `0xFFE40000/0xFFE50000/0xFFE60000`; NCRISC cannot issue Tensix. BRISC bypasses MOP expansion. Simultaneous BRISC/TRISC injection to the same downstream path is not a safe extra issue channel; honor the frontend mux/discard rules.
3. Inline words rotate the Tensix encoding left by 2; FIFO stores contain the unrotated word. Decode both, including runtime-computed instruction words. Up to four adjacent inline instructions fuse when enabled; each still consumes downstream work.
4. First FIFO admits more only when occupancy is ≤28; a fused four-word push can reach 32. Downstream capacities are not simply additive for ordinary instructions because tracking limits apply even with Auto TTSync off.
5. Each thread expands/dispatches at most one downstream instruction/cycle, subject to stalls. Different threads can dispatch to different engines simultaneously. Shared-engine arbitration limits combined throughput.
6. **REPLAY:** execution emits N stored instructions at one/cycle, backpressure permitting; command-cycle emission starts immediately. Recording with `Load=1, Exec=0` consumes the command plus N incoming instructions and emits none. Record-and-execute has pass-through behavior. There is no intrinsic transition penalty. Preserve the 32-entry buffer and instruction order.
7. **MOP:** execute the configured templates, counters, end instructions, zmask and replay behavior. Count expanded architectural instructions, not encoded MOP words. It is not “MOP = fixed X cycles.”
8. **Auto TTSync:** tracks coarse GPR/TDMA/config resources, creating some conservative stalls. For MOP/REPLAY, resource declarations describe expansion and tracking behavior is not equivalent to checking each child independently. It has documented holes (notably store-queue ordering before a RISC read).
9. **Manual sync:** select the exact drain scope. A frontend-empty or PC sync marker is not automatically equivalent to every backend and NoC output being visible. The fresh SFPU probes explicitly use SFPU `STALLWAIT` plus PC sync.

Historical MMIO-push benchmark: TTNOP issue ~0.995 cycles/push, issue+sync ~1.999; no-condition STALLWAIT ~1.542 issue and ~2.874 issue+sync; SEMINIT ~0.990 issue and ~2.998 issue+sync. These are measured loop paths, not contradictory unit latencies. [Original table](evidence/historical/tensix-instr-microbench.md).

## SFPU

Source: [Blackhole Vector Unit](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/VectorUnit.md). Each instruction normally processes up to **32 lanes ×32 bits**. LRegs are shared SFPU architectural state, not one independent register file per TRISC. Track actual lanes/registers and predicate state. L0–L7 are general writable registers; special/configurable constants and lane tags need their own semantics ([LReg](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/LReg.md)).

### Complete SFPU family timing table

All numbers below are **backend** result latencies; IPC is the common SFPU instruction-admission limit unless a special restriction applies. The machine-readable mode table preserves all separate ISA rows.

| Instructions / modes | Latency | IPC | Notes |
|---|---:|---:|---|
| `SFPADD SFPADDI SFPMUL SFPMULI SFPMAD` | 2 | 1 | Adjacent dependent consumer generally stalls one cycle |
| `SFPLUT SFPLUTFP32` | 2 | 1 | Reads implicit LRegs / LUT coefficient registers; include these dependencies |
| `SFPMUL24` | 2 | 1 | Integer multiplication modes, not a scalar RISC MUL |
| `SFPARECIP` | 1 | 1 | Native approximate reciprocal / exp-related modes; not the refined helper |
| `SFPABS SFPMOV SFPDIVP2 SFPEXEXP SFPEXMAN SFPSETEXP SFPSETMAN SFPSETSGN` | 1 | 1 | Mode selects read/write operands and FP/sign-magnitude semantics |
| `SFPIADD SFPSHFT SFPAND SFPOR SFPXOR SFPNOT SFPLZ` | 1 | 1 | Some modes read VD implicitly; SFPLZ can also modify flags |
| `SFPCAST` int→float / int→int / integer absolute | 1 | 1 | Not every desired numeric conversion is one SFPCAST |
| `SFPSTOCHRND` float→float / float→int / int→int | 1 | 1 | Rounding/PRNG/config dependencies and format semantics |
| `SFPLOADI` | 1 | 1 | A general 32-bit constant normally needs two immediate instructions; partial writes preserve the other half |
| `SFPLOAD` Dst→LReg | 1 | 1 | Dst read arbitration / earlier producer completion can delay admission |
| `SFPSTORE` LReg→Dst | 1 | 1 | Not an L1 store; pack/unpack/FPU/RISC visibility is separate |
| `SFPTRANSP` | 1 | 1 | Reads/writes multiple implicit LRegs; do not treat as scalar copy |
| `SFPSWAP` swap/minmax/argminmax modes | 2 | ≤1 | Only SFPNOP accepted by SFPU in following cycle; automatic stall otherwise |
| `SFPSHFT2` bit shifts (`SHFT_LREG`, `SHFT_IMM`) | 1 | 1 | Source tracking differs from actual operands in some interlock cases |
| `SFPSHFT2` register shift/copy / chained-copy modes | 1 | 1 | Multiple implicit LReg reads/writes |
| `SFPSHFT2` `SUBVEC_SHFLROR1_AND_COPY4`, `SUBVEC_SHFLROR1`, `SUBVEC_SHFLSHR1` | 2 | ≤1 | Same following-cycle SFPNOP-only restriction as swap |
| `SFPGT SFPLE SFPSETCC SFPENCC SFPPUSHC SFPPOPC SFPCOMPC` | 1 | 1 | Predicate/stack operations; masked lanes do not make instruction issue free |
| `SFPCONFIG` broadcast into L11–L14 | 1 | 1 | Configuration-constant register write |
| `SFPCONFIG` configuration update | ≤2 | 1 | Check consumer-specific visibility; not just a normal GPR write |
| `SFPNOP` | 1 | 1 | Occupies an SFPU issue slot; RISC NOP is not an equivalent guaranteed backend gap |
| `SFPLOADMACRO` | Load 1, remaining events scheduled | Up to five subunits active | Must expand configured events; no single completion latency |

### Exactly when results are available

For an ordinary `SFPMAD` issued at backend cycle **0**, a dependent ordinary `SFPADD` can issue at **2**. An independent SFPU instruction can occupy cycle **1**. A chain of N dependent 2-cycle operations issues at `0,2,...,2N-2` and has final result ready at **2N**, ignoring frontend/drain overhead. Independent 2-cycle operations can issue at `0,1,...,N-1` and finish by **N+1**, provided destinations, ports and subsequent consumers permit it.

```text
backend cycle     0                1                   2               3
single chain      MAD -> L0         automatic stall     ADD reads L0
interleaved       MAD -> L0         MAD -> L1           ADD reads L0    ADD reads L1
explicit gap      MAD -> L0         SFPNOP              consumer L0
```

The interleaved example must use source registers independent of the other chain. Merely renaming the destination does not remove reads of old VD, a LUT coefficient, an indirect operand or a predicate.

### Automatic interlocks have holes

[SFPMAD scheduling](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SFPMAD.md) specifies two cycles and explicitly lists missed/conservative dependencies. Related MAD-subunit instruction pages refer to the same scheduling behavior. Model the **actual** read/write sets for correctness and a **separate detected** read/write set for hardware stalls.

| Consumer after MAD-family producer | Interlock issue | Safe schedule requirement |
|---|---|---|
| `SFPAND` with `USE_VB` | Hardware tracks VD instead of VB | Explicit cycle gap when producer writes actual VB |
| `SFPOR` with `USE_VB` | Same | Same |
| `SFPIADD` | VD read not detected | Gap when dependent through VD |
| `SFPSHFT` | VD read not detected | Gap when dependent through VD |
| `SFPCONFIG` | LReg0 read not detected | Gap after producer of L0 when this mode reads it |
| `SFPSWAP`, except plain SWAP | First-cycle comparison reads not detected; rereads on second cycle | Ensure inputs ready before comparison, and preserve both-cycle reads |
| `SFPSHFT2` subvector rotate/shift modes | Actual reads not detected | Explicit producer-to-consumer gap |
| `SFPSHFT2` bit-shift modes | Tracks VD, actually reads VB | Gap for actual VB dependency |
| Indirect `SFPMAD` VA/VD | Conservatively reads/writes every LReg | May stall despite actual independent lane-selected registers |
| Macro-scheduled operations | Normal automatic stalls do not apply | Static schedule must satisfy every dependency/resource constraint |

The swap/shuffle pages say a following `SFPNOP` may fill the otherwise blocked cycle; a two-instruction pair containing a useful follower takes three total cycles when the follower must be stalled. This is **not** a claim that every swap costs three: fresh sustained swaps and shuffles issue every two cycles. With fusion disabled, explicitly adding NOPs in this particular loop adds issue overhead; with fusion enabled both tested variants approach two cycles/primary operation. [SFPSWAP](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SFPSWAP.md), [SFPSHFT2](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SFPSHFT2.md).

### Load macros, configuration and cross-engine visibility

[SFPLOADMACRO](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SFPLOADMACRO.md) can schedule load + simple + MAD + round + store subunits. A configured delay 0 executes **the next cycle**, not the load's cycle. Delay counters can count elapsed cycles or elapsed SFPU instructions; if any pending instruction uses instruction-count mode, that affects countdown of all pending events. Decode this state explicitly.

Scheduled operations can overwrite prior scheduled slots. When a scheduled and directly issued instruction target the same subunit/cycle, the scheduled operation wins and the direct instruction may be **silently discarded**. Simple/round simultaneous-write restrictions and swap's extra cycle apply. Automatic dependency stalls do not protect macro schedules. Treat collisions and missing operand gaps as invalid/undefined schedules, not as fast executions.

`SFPSTORE` completion is only the SFPU-to-Dst step. Before another thread packs it, model the SFPU drain, publication, semaphore ordering, Dst ownership and packer's Dst read. Likewise, don't issue `SFPLOAD` on a Dst row whose FPU/unpack producer has merely been enqueued. ZEROACC invalid rows are not an arbitrary valid SFPU input source. RISC memory-mapped Dst readback and debug-array readback have their own synchronization/format paths.

### Useful measured sequence costs, not opcode costs

| Sequence | Measured cycles | Scope |
|---|---:|---|
| Fresh dependent add/mul/MAD/MUL24 | 2.000 per primary operation | Long-batch slope including loop; on card1 default and fusion-enabled |
| Fresh independent add/mul/MAD, 4 destinations | 1.125 default; 1.000 fusion-enabled | 16 body ops + 2 RISC loop instructions; result dependencies do not bottleneck |
| Fresh simple/loadi/arecip/transpose families | ~1.125 default; 1.000 fusion-enabled | Same loop shape; no arithmetic-output oracle in these timing-only probes |
| Current raw API add/sub/mul/MAD single vector | 19.25 | Four separately drained intervals, K=4, total77; matched control64 |
| Current raw API neg/abs/native reciprocal | 18.25 | K=4, total73 |
| Refined reciprocal | 29.25 | K=4, total117; helper sequence with refinement |
| Native exp / refined exp | 20.25 / 62.25 | K=4, total81 /249; very different accuracy/domains |
| Repeated API add/sub/mul/MAD | 3.078125 | K=64, total197 including four drains/markers; not architectural latency |
| Older validated unary sequences | recip16, exp40, rsqrt58, sigmoid59, SiLU62 per reported operation | Archived harness normalization; different code from current APIs |
| Older reductions / softmax | sum/max51 per reported op; rowmax293/tile; softmax2746/tile | Whole sequence/tile, not one SFPU instruction |

[Current math records](../../../blackhole-py/tests/operation_pocs/sfpu_math/final-results.json), [current math report](../../../blackhole-py/tests/operation_pocs/sfpu_math/results.md), [older suite status](../status.md). Full movement/predicate/load/store/placement timings remain in [the evidence index](evidence-index.md).

## Matrix FPU

Source: [Blackhole's shared MatrixUnit reference](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/MatrixUnit.md), [full timing table](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MatrixUnit.md). The FPU operates on SrcA/SrcB and Dst, with matrix-specific layouts; these are not scalar RISC registers or SFPU LRegs.

| Instructions | Result latency | IPC | Scheduling / work count |
|---|---:|---:|---|
| `MVMUL DOTPV GAPOOL ELWMUL` | 5 | 1 | One architectural operation per fidelity phase; effective work/second changes with phases |
| `GMPOOL ELWADD ELWSUB` | 5 | 1 | No multiply-fidelity expansion for add/sub/max itself |
| `SETRWC INCRWC CLEARDVALID CLREXPHIST GATESRCRST` | 1 | 1 | RWC/control state affects following instruction footprints |
| `SHIFTXA ZEROACC ZEROSRC TRNSPSRCB` | 1 | 1 | Effects include validity and bank state, not just numeric writes |
| `SHIFTXB` | 2 | 0.5 | Occupancy restriction |
| `MOVD2A` | 2 | 1 | Next cycle accepts only MOVD2A/MOVB2A |
| `MOVA2D MOVDBGA2D MOVB2D MOVB2A` | 4 | 1 | Only certain following instructions hide latency |
| `MOVD2B` | 4-cycle scheduling window | 1 for repeated MOVD2B | Next 3 cycles accept only another MOVD2B; detailed page fills omission in unit summary |
| Legacy CONV/POOL / unusual source-control encodings | Not safely generalized | ? | Some have neutered/noncontractual semantics; catalog marks uncalibrated entries |

[MOVA2D scheduling](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOVA2D.md) requires avoiding Dst reads for the next three cycles. Hardware stalls a specified list of consumer opcodes **regardless of row overlap**, but the list is not every possible consumer. [MOVD2A](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOVD2A.md) and [MOVD2B](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MOVD2B.md) don't automatically enforce Src-bank ownership. Model explicit source-valid/free waits and the Blackhole implied-format configuration.

For arithmetic, keep the 5-cycle result pipeline distinct from the legal accumulator-forwarding/row schedule of each opcode. Don't impose an invented global “5 cycles between all FPU operations,” and don't assume any arbitrary same-row mixed sequence is safely forwarded. Address modifiers, broadcast, clear-dvalid bits, fidelity, Src banks, Dst accumulation format and row write masks belong in decode/state. Inspect per-instruction semantics and validate mixed dependency schedules.

**Fidelity and instruction count:** HiFi2/3/4 use additional phase work. Do not charge a “tile matmul constant” in addition to already expanded phase instructions. A nominal 32×32 BF16 tile multiply is multiple MVMUL footprints, not one instruction. The [historical MVMUL report](evidence/historical/math-mvmul.md) explicitly corrects a count from encoded TTMVMUL slots to architectural MVMUL instructions; use the corrected denominator. A `MATMUL` helper/macro name does not by itself identify a distinct opcode in the local 134-entry Blackhole encoding catalog.

Current measured FPU sequences (card0/core `(1,3)`, FP32 Dst, K=16, operation+drain interval):

| Helper | Batch cycles | Cycles/helper call, including overhead |
|---|---:|---:|
| elwadd / elwsub | 119–120 | 7.4375–7.5 |
| elwmul | 215–216 | 13.4375–13.5 |
| mvmul | 119–216 | 7.4375–13.5; mode-dependent |
| gapool | 215–216 | 13.4375–13.5 |
| gmpool | 119–120 | 7.4375–7.5 |
| zero | 156 | 9.75 |
| a2d | 43–58 | 2.6875–3.625 |
| b2d / d2a / d2b | 59 | 3.6875 |

BF16 Dst K=1 intervals are 29 for add/sub/gmpool/moves, 36 for elwmul/gapool, 29–36 for mvmul, 35 for zero. All include substantial completion/marker overhead; FP32 vs BF16 rows use different K and cannot be directly compared as throughput. [224-case final evidence](../../../blackhole-py/tests/operation_pocs/fpu/measurements.json).

Historical matmul MOP proxies: unthrottled54 cycles/output-tile-K; throttle0 variant49; a 2×2 subblock proxy216. They are separate measured emitter configurations, not MOP/MVMUL opcode latencies. [Report](evidence/historical/math-backend-microbench.md).

## Unpackers and packers

### Unpack

[UNPACR performance](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/UNPACR_Regular.md), explicitly shared by [Blackhole UNPACR](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/UNPACR_Regular.md): uncompressed input starts with **2 cycles** of address generation; compressed input takes more. During that phase no other thread can start UNPACR and the issuing thread cannot start its next instruction. Subsequent execution is pipelined and depends on input bytes, format, throttle, L1 access and output path.

Desired speed x1/x2/x4 = **16/32/64 B per cycle**. With simultaneous unpackers, their realized rates can fall:

| Unpacker1 wants ↓ / Unpacker0 wants → | x1 | x2 | x4 |
|---|---|---|---|
| x1 | U0 x1, U1 x1 | U0 x2, U1 x1 | U0 x4, U1 x1 |
| x2 | U0 x1, U1 x2 | U0 x1, U1 x1 | U0 x2, U1 x1 |
| x4 | U0 x1, U1 x4 | U0 x1, U1 x2 | U0 x2, U1 x2 |

Throttle0/1/2 selects x1/x2/x4 where the mode permits a choice. Compression/BFP2/upsampling and discontiguous-row modes constrain the choice. Include header/exponent sections and physical bytes actually read, not only logical element bytes. Unpacker0 targets SrcA or Dst; unpacker1 targets SrcB. Preserve address counters, row/layout transforms, input offset alignment, config context, output format and source ownership.

Useful **lower-bound component**, not complete formula:

```text
unpack service >= address-generation + input-transfer critical path
input-transfer ideal >= ceil(physical_input_bytes / realized_input_bytes_per_cycle)
```

Pipeline overlap means don't blindly add all per-stage times for each tile; schedule transfers/events and output availability. A tile can comprise multiple commands, and serialized configuration/credit handoff can dominate. `UNPACR_NOP` occupies one cycle only in its plain no-op mode; mode variants can set/clear/zero/publish state and need separate semantics.

| Measured unpack path | Cycles | Interpretation |
|---|---:|---|
| Historical matmul row, steady | ~37.5/row | 2×2 subblock, bw1..5; one row includes a particular A/B work sequence |
| Historical standalone row | 51.3 | Non-amortized proxy |
| Historical 2×2 bw4 | 300/subblock | Includes chosen command/control schedule |
| Historical reload+reconfiguration 2×2 | 273.9 | Four reload tiles plus MOP reconfiguration/restore |
| CB-backed BF16 stream, 2 /8 /16 tiles | 376 /563.4 /591.6 per tile | Consumer/CB pacing included; not raw unpacker bandwidth |
| CB-backed FP16 /FP32, 8 tiles | 557.1 /614.4 per tile | Different physical byte counts |

[Historical backend](evidence/historical/unpack-backend-microbench.md), [stream results](../docs/tensix/pack-unpack-units.md). Config-context flip9.5 and ready PC-unpack poll4.2 are helper measurements; reported negative adjusted empty-ready timings are noise/subtraction artifacts, never negative or zero architectural instructions.

### Pack

[Packers reference](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/Packers/README.md): four packers can receive one PACR command controlling a selected subset. At most one pack command starts/cycle. The issuing thread waits until those packers **accept** the work and then continues; `STALLWAIT` is needed to wait for completion. `PACR_SETREG` is sequenced after earlier late format conversion, not a generic RISC configuration store.

No single “PACR latency” describes all configurations. Model Dst read width/format, packer subset, rows, output format/compression, address counters, destination L1 bank, partial line buffers, flushes, L1 accumulation and completion boundary. Packer0's L1→L1 input path is distinct from ordinary Dst packing. L1 accumulation changes read/modify/write traffic. Blackhole-specific measured bandwidth must take precedence over Wormhole-only bandwidth paragraphs in shared L1 documentation.

Historical pack-body proxy: CB16 final1316 cycles/tile, partial-off1856, partial-on1316, generic two-block average1586. These were inferred from **full kernel pack-body microseconds at assumed1.35GHz**, not isolated PACR. Keep them as low-confidence implementation proxies. [Original provenance](evidence/historical/pack-backend-microbench.md).

### Exact API transport includes staging/copy

Current correctness-oriented transport emitters stage/zero-fill exact inputs and copy exact output prefixes, so these are intentionally much larger than raw unit time. Representative K=1 medians, slot0, card1/core `(1,11)`:

| Operation | Format | N=1 | N=128 |
|---|---|---:|---:|
| Unpack to Dst for SFPU | BF16 | 2300 | 4067 |
| Unpack to Dst for SFPU | FP32 | 2301 | 5089 |
| Unpack SrcA | BF16 | 690 | 4247 |
| Unpack SrcB | BF16 | 687 | 4244 |
| Unpack SrcA | FP32 | 1041 | 8154 |
| Unpack SrcB | FP32 | 1038 | 8151 |
| Exact pack | BF16 | 2600 | 6144 |
| Exact pack | FP32 | 2627 | 9746 |

Full N=1..128 / placement / format / staging/control data: [6,924 interval records](../../../blackhole-py/tests/operation_pocs/transport/final-sweep.json), [interpretation and min/max](../../../blackhole-py/tests/operation_pocs/transport/results.md). Do not fit an intrinsic unpacker latency to these scalar-copy-dominated totals.

## Scalar, configuration and synchronization

### Scalar ThCon and miscellaneous units

[Scalar unit](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/ScalarUnit.md) is **shared, nonpipelined**. While executing, it blocks other threads entering that unit **and blocks every next instruction from the issuing thread**, even instructions intended for another engine. It can start before prior work at other engines completes.

| Instructions | Unit execution cycles | Further effects |
|---|---:|---|
| `DMANOP SETDMAREG` | 1 | Fresh DMANOP complete stream slope~2; admission/continuation isn't calibrated by the unit number alone |
| `REG2FLOP FLUSHDMA` | ≥2 | Destination/flush conditions can add time |
| `ADDDMAREG SUBDMAREG MULDMAREG CMPDMAREG BITWOPDMAREG SHIFTDMAREG` | 3 or4 | Immediate vs register and aligned GPR groups |
| `STOREIND STOREREG ATSWAP` | ≥3 | Memory acceptance/visibility and port contention |
| `LOADIND LOADREG ATINCGET` | ≥3 | Load result arrives later; occupancy is not GPR-ready latency |
| `ATCAS ATINCGETPTR` | ≥15 | Conditional wait can be unbounded |

For [ADDDMAREG](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/ADDDMAREG.md), immediate RHS takes3; two registers take3 in the same aligned group of4 GPRs, else4. Use individual pages for other modes rather than assuming every ternary operation has that rule.

Tensix GPRs are **64/thread**, distinct from RISC GPRs. RISC stores to them may still be in flight when a consuming Tensix command is pushed. Likewise LOADIND completion requires the appropriate wait/flush/sync; an arbitrary seven-DMANOP delay is explicitly described as racy in [LOADIND](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/LOADIND.md).

[Miscellaneous unit](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/MiscellaneousUnit.md): `SETADC SETADCXY SETADCXX SETADCZW INCADCXY INCADCZW ADDRCRXY ADDRCRZW SETDVALID NOP` execute in **1 cycle**, can accept **one per thread per cycle**. They are not part of the serialized scalar-GPR arithmetic unit despite some similar names.

### Configuration unit

[Blackhole configuration pipeline](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/ConfigurationUnit.md):

| Instruction | Latency | Sustained IPC | Shared group |
|---|---:|---:|---|
| `SETC16` | 1 | 3, one/thread | ThreadConfig |
| `WRCFG` | 2 | 1 | Config |
| `RMWCIB` variants | 1 | 1 | Config |
| `CFGSHIFTMASK` | 2 | 0.5 | Config |
| `RDCFG` | ≥2 | 1 | Config; GPR write contention can extend |
| `STREAMWRCFG` | ≥5 | 1 | Config; overlay transfer and pipeline ordering |
| RISC read/write or mover write at unit | 1 | 1 | Config; travel latency outside the unit |

Different entry stages can admit different instructions together transiently, but the Config access stage limits sustained rate. WRCFG from one thread can starve RISC config requests. Pipeline ordering and the STREAMWRCFG stage-4 hole need explicit modeling when optimizing configuration-heavy streams. [RDCFG's shared detailed page](../../../tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/RDCFG.md) also warns about simultaneous cross-thread reads being dropped; respect that documented restriction unless hardware-specific evidence supersedes it.

### Sync unit, waits, source flags and CBs

[Blackhole SyncUnit](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/SyncUnit.md): mutex acquire/release **1-cycle execution**, up to3/cycle when referring to different mutexes; acquisition waits until ownership permits admission. SEMINIT/SEMPOST/SEMGET/STALLWAIT/SEMWAIT/STREAMWAIT and RISC semaphore writes share **one instruction/request per cycle**, each with1-cycle unit execution. RISC semaphore reads have separate per-RISC admission.

[STALLWAIT](../../../tt-isa-documentation/BlackholeA0/TensixTile/TensixCoprocessor/STALLWAIT.md) latches a **condition plus a class block mask**. It does not necessarily freeze every instruction. Conditions reevaluate each cycle; after conditions become true there is a **one-cycle lag** before removal of the block mask. A following matching-class instruction encounters that mask for at least one cycle even if the condition was already true. SEMWAIT similarly depends on actual count/threshold, not an assigned finite worst-case latency.

| Block bit | Approximate class |
|---|---|
| B0 | Misc/mover/scalar/packer/unpacker broad group |
| B1 | Sync |
| B2 | Pack |
| B3 | Unpack |
| B4 | Mover |
| B5 | Scalar |
| B6 | Matrix FPU |
| B7 | Configuration |
| B8 | SFPU |

Use the ISA's opcode-by-bit table for exact membership. Track each wait condition's specific engine/bank/credit scope; “wait math” is not a global all-engine barrier. Source-valid/free state is a ping-pong bank ownership protocol. Changing a flag early can enable an incorrect consumer even if a dependency graph of scalar registers looks valid.

Circular buffers are software protocols built from memory-mapped counters, fences, addresses and loops. Measure/predict the emitted reserve/publish/wait/release sequence plus blocking time. Current synchronous API examples include per-call address setup and completion:

| Primitive | K | Representative raw median / normalized cycles |
|---|---:|---|
| CB reserve, slot31/wrap fixture | 16 | 424 /26.5 |
| CB publish | 16 | 399 /24.938 |
| CB wait, ready | 16 | 387 /24.188 |
| CB release | 16 | 397 /24.812 |
| Semaphore post /get | 7 | 76 /10.857 |
| Semaphore wait-ready /wait-space, already satisfied | 7 | 90 /12.857 |
| SrcA publish /release | 8 | 162 /20.25; 157 /19.625 |
| SrcA wait-valid /wait-free, ready | 8 | 136 /17 |
| SrcB publish /release | 8 | 164 /20.5; 154 /19.25 |
| SrcB wait-valid /wait-free, ready | 8 | 136 /17 |

[Runtime records and seven-sample distributions](../../../blackhole-py/tests/operation_pocs/runtime/evidence/measurements.json). Delayed-peer cases around2100–3200 cycles contain intentional waiting and are **not opcode costs**. Historical CB helpers use different sequences (~22/23/31/31.5 cycles for wait/reserve/push/pop), retained in [the older report](evidence/historical/sem-cb-microbench.md).

## L1, NoC, DRAM and mover costs

Five streams alone cannot determine a NoC/DRAM duration without addresses/routes/traffic. Other cores and command buffers may contend even when their RISC instructions are outside the input tile.

- Use explicit L1 ports, bank mapping, request widths, coalescing and outstanding queues. A scalar 4-byte access is not necessarily a4-byte hardware transaction. [Shared L1 reference](../../../tt-isa-documentation/WormholeB0/TensixTile/L1.md) mixes architecture-specific material: its blanket “RISCs have no atomics / can't merge stores” discussion is Wormhole-era and conflicts with the explicit Blackhole RISC page. Follow the Blackhole page for Blackhole scalar accesses.
- Model NoC command-programming RISC instructions separately from packet execution. A send-register store, command buffer ready, source payload consumed, reply received and non-posted write acknowledged are separate events.
- Reads, posted writes, acknowledged writes, atomics, multicast and overlay streams require different completion rules. Track selected NoC, VC, route, TID, outstanding counters, command buffer, burst length and packetization. Track coordinate translation before computing hop count.
- DRAM adds bank/channel/endpoint mapping, row state, controller queue and competing traffic. A single “DRAM load latency” is insufficient for a streamed workload.
- `XMOV`/TDMA service is length/configuration/L1 dependent; completion and register visibility are distinct. Older XMOV/readback attempts include timeouts and incorrect data, so no intrinsic latency is invented from them.

The archive contains extensive [NoC/DRAM reports](../docs/README.md), [packet/dependency timings](../docs/noc/noc-dependency-latency.md), [one-way/round-trip interpretation](../docs/noc/reading-guide.md), and a [NoC scheduler model](../docs/noc/noc-scheduler-model.md). The model initially uses9 cycles/hop,45 base,8 issue,24 atomic-target and45 command-buffer hold; **several are explicitly placeholders**, and later calibrations differ. Do not promote those defaults to hardware truths or combine one-way link clocks with RISC round-trip measurements.

Fresh loop calibration here does not calibrate intertile timestamps. Historical clock-skew measurements showed stable offsets (−144 and+623 for selected pairs), but launch alignment was not separated from actual clock skew. [Clock-skew evidence](evidence/historical/wall-clock-skew.md).

## Five-stream predictor design

### Required input contract

To predict more than a lower bound, supply:

1. **Five actual instruction streams**, PCs/code addresses, decoded branches or initial register/memory values sufficient to execute them, and a common start convention. A static disassembly without dynamic paths/loop counts cannot determine a total.
2. **Chip/config state:** architecture/stepping, cfg0/PMA bits per RISC, clock domains, cache/branch-predictor initial state, firmware and text layout, enabled Auto TTSync and resource declarations.
3. **Tensix state:** per-thread MOP/replay contents, GPR/config contexts, address modifiers/RWCs/ADCs, bank-valid/owner flags, Dst validity/layout/dtype, LRegs/predication/load-macro schedules, semaphores/mutexes, pack/unpack config.
4. **Memory/I/O environment:** initial L1/CB/counter values, payload addresses and shapes, DRAM/NoC mapping, external producer/consumer arrivals and competing traffic. For omitted traffic, state the idle-environment assumption.
5. **Completion definition:** last RISC instruction retired, all Tensix work complete, output in L1, NoC write acknowledged, or full launch complete. These can differ substantially.

If state is unknown, output an interval/scenario estimate and a list of assumptions. If a wait has no possible producer, report deadlock/unbounded completion; do not return a finite default. If a schedule violates a documented unprotected hazard, report invalid/undefined instead of silently adding a stall the hardware lacks.

### Minimal event model

A useful implementation is a deterministic discrete-event simulator with resource queues and functional state updates. The following equation is only the local admission skeleton:

```text
start(i) = max(frontend_available, required_operand_ready,
               queue_space_available, allowed_by_wait_gate,
               resource_admission_available)
result_event(i) = start(i) + consumer_specific_latency(i, state)
```

Do **not** independently evaluate that maximum for all instructions and call it done. A new event changes queue occupancy, source ownership, memory values, branch paths and future instruction construction.

Suggested state machines:

| State / resource | Necessary behavior |
|---|---|
| Five RISC frontends/EX1s | In-order issue; dependencies; division occupancy; prediction/fetch; selected fusion |
| Five retire queues | 8 entries, in-order retirement, early scalar forwarding, vector retirement dependency |
| Five load/store queues | Address spaces, merge timer, same-address hazards, cache flushes, device write visibility |
| Three Tensix frontends | Thresholded FIFO, MOP/replay expansion, backpressure, BRISC injection |
| Three wait gates | Latched block masks, condition release lag, thread-blocking scalar instructions |
| Shared SFPU | One direct instruction/cycle; subunit event calendar; actual vs detected operand sets; masks |
| Shared matrix unit | One architectural instruction/cycle; 5-cycle result pipeline; movement-specific restrictions |
| Two unpackers / four packers | Setup/address phase, input/output transfer, config contexts/credits, ownership, flush |
| Scalar/config/sync/misc | Distinct admission groups, thread stalls and memory-result events |
| L1/NoC/DRAM | Physical request scheduling and endpoint completion, optional external traffic model |
| Ownership / software protocols | Semaphores, mutexes, CB counters, Src bank flags and Dst publication |

At each timestamp: retire/complete due work, apply visibility and ownership events, update wait conditions (with lag), arbitrate eligible requests, issue ready RISC instructions, enqueue/expand Tensix commands, schedule future work. Define a consistent subcycle ordering to avoid inventing same-cycle forwarding. Treat this as a modeling convention until validated against dependency-gap tests. Unknown arbitration tie-breaking is a calibration parameter, not a documented certainty.

### Lower bounds and search use

Useful rough lower bounds include the largest per-core scalar issue demand, critical-path result dependencies, total expanded instructions divided by each shared unit's capacity, per-thread frontend demand, and physical memory traffic divided by achievable bandwidth. They combine primarily with **max**, not by adding all five stream runtimes. Real completion also includes fill/drain, queue stalls, resource collisions and synchronization.

Return diagnostics alongside total cycles: per-role retired instructions/stalls; per-unit busy time; queue high-water marks; wait time by condition; first/last output visibility; assumptions; invalid hazards. For kernel search, a count without an explanation makes it difficult to detect a falsely cheap candidate.

Calibrate on isolated instructions, then held-out mixed streams (unpack+math+pack, Dst consumers, CB blocking, NoC overlap). Validate output data/guards as well as cycles. Record absolute cycle error and relative error; inspect short kernels separately because fixed marker/start costs dominate them. Validate ranking on actual search candidates, not only fit error on the calibration suite.

## Measurement pitfalls

1. **Empty-loop subtraction is not exact latency isolation.** Historical four-dependent-multiply tests report ~1.75 adjusted cycles/op although hardware multiply result latency is2. Fresh 16-op loops measure2.0625 cycles/op including loop: the final multiply latency partly overlaps loop work. Similarly an old single-load pointer chase reports ~5 adjusted from an~8-cycle full iteration minus a3-cycle baseline. It does not demonstrate5-cycle L1 latency.
2. **RISC control overlaps asynchronous engines.** Fresh SFPU dependent slopes are2 both with/without fusion; simple independent slopes change1.125→1 when fusion lets the backend hide loop control. Subtracting0.125 from every SFPU slope would falsely claim1.875-cycle MAD.
3. **Timing-only probes don't establish numerical semantics.** The new SFPU cases intentionally test completion/throughput without a full arithmetic oracle. Existing independent operation POCs provide bounded semantic coverage. They do not prove every undocumented hazard/mode.
4. **Config changes are part of the result.** Cache/fusion-on records are separate datasets, not pooled with default. Raw source/image hashes identify each version; the initial SFPU run had a host assertion mixup, retained as failed evidence.
5. **No marker is universal.** Preserve whether a sample ends before or after PC sync, unit drain, payload source consumption, or remote ACK. A profiler's NoC export occurs after the measured region and is not part of its count.
6. **Don't divide by wrong work units.** Vector call (32 lanes), logical128-element allocation, four-vector sequence,32×32 tile, face, subblock, fidelity phase and encoded replay/MOP word differ.
7. **Do not average incomparable modes.** Dst FP32/BF16, input format, fidelity, alias, mask, placement, code revision, card/core and K must remain keyed.
8. **Cold fetch/launch != steady state.** Fixed-body iteration sweeps reduce fixed overhead but still need source layout/branch/cache state. For long unrolled candidates, include I-cache capacity/prefetch; no Blackhole cache-size constant is invented from a missing Blackhole InstructionCache page.
9. **Old backend failures aren't measurements.** Archived tilize/XMOV/debug-readback/pack fixtures include timeouts or only empty passes. Newer operation suites establish some valid paths, not universal correctness of the old scripts.
10. **Sources can conflict.** Prefer explicit Blackhole per-instruction rules over general local summaries. Preserve unknowns and contrary measurements (e.g. DMANOP1-cycle unit vs2-cycle observed stream) rather than forcing every fact into one latency field.

## Remaining gaps

The catalogs list every compiler opcode, but **the available evidence does not supply exact cycles for every mode and every overlap**. In particular:

| Gap | Existing evidence | Next experiment needed |
|---|---|---|
| Full 5-stream mixed arbitration | Older scalar contention matrices, isolated current probes | Simultaneous per-engine saturation with matched per-role PCs/addresses, then real kernel validation |
| SFPU missed RAW/WAW/implicit-operand hazards | Detailed ISA list, current arithmetic/movement oracles | Gap sweep0..3 with lane-by-lane output oracles; separate normal vs macro schedules |
| SFPU load/store vs FPU/pack/unpack Dst ports | Unit timings and complete transport tests | Producer-consumer gaps, overlap/no-overlap Dst rows, both Dst widths |
| `SFPLOADMACRO` full throughput | Documented subunit delays/collision rules | Correctness-checked configured event sequences, then mixed direct/macro issue |
| Scalar ThCon thread continuation / memory return | Documented occupancy, fresh DMANOP stream~2 | Repeat via direct/fused/replay; following different-engine op; GPR visible timestamp |
| Isolated PACR/UNPACR data service across modes | Address phase/rates, historical and API sequence costs | One-command length/format/throttle/packer-count sweeps with output oracle, then two-engine overlap |
| All RVV, scalar half/conversion/atomics | Supported ISA, pipeline rules | Operand/SEW/LMUL/VL/mask sweeps and explicit result checking |
| Branch predictor / Blackhole I-cache details | Branch penalty documented, archived footprint script | Warm/cold footprints, target patterns, alignment and five-role fetch contention |
| L1 bank-port mapping under all clients | Shared docs and archived probes | Address sweep with scalar+NoC+packer+unpacker contention |
| Exact divider operand formula | 2 and6–33 bounds, fresh2/33 points | Dividend bit-length/sign/divisor sweep; preserve values in record |
| NoC/DRAM arbitrary concurrent traffic | Large archival calibration set | Workload-specific holdout traces, burst/route/endpoint/clock context |
| Firmware flags on inference | Microbench improvements established | End-to-end outputs, polling correctness, throughput/latency comparison with identical model/workload |

New timing tests: [test_instruction_timing.py](../../../blackhole-py/tests/timing/test_instruction_timing.py). Historical scripts reference retired `KernelBase`/`dsl` APIs; copying the old directory alone is no longer enough to run every bench on current blackhole-py. Prefer the current raw `Asm` fixture or explicitly reproduce the recorded historical checkout. No hardware reset or persistent firmware modification was needed for this report.
