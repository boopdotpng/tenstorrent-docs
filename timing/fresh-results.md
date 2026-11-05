# Fresh Blackhole instruction timing results

September 9, 2026; queued on physical cards0 and1, core index4 `(1,6)`. **161 passing probe cases** across the final/default/configuration runs (95 RISC +23 SFPU +10 context/local-RAM +10 cache-on +23 fusion-on). An initial SFPU run had5 passes then a host-side scalar-sink assertion incorrectly applied to an SFPU case. That assertion was scoped to scalar probes, and all23 SFPU cases subsequently passed. Failed evidence is retained; no timing threshold was changed.

Each curve uses the same16-operation loop body at64/128/256 iterations, one discarded warmup launch and seven measured launches per point. Two reported slopes are adjacent median differences divided by1024/2048 added primary operations. They include amortized loop control and stalls, not constant marker/drain overhead. No automatic empty-loop subtraction. Units are worker wall-clock cycles per primary body operation. `*_nop` cases add one SFPNOP per primary swap/shuffle, so their denominator is the number of primary operations, not total instructions.

RISC scalar sinks are checked for designated deterministic cases. SFPU probes validate completion/timing only; existing operation POCs supply arithmetic oracles for their own covered inputs. Dataset sample arrays, image sizes/hashes, core/card, source hashes, completion scope and modifiers are preserved. Firmware hashes and cfg0/PMA readback were captured in the subsequent context probes on the same card/core and checkout. No clock-MHz telemetry was captured, so no new ns conversion is claimed.

## Default firmware: all five RISC roles

| Probe | BRISC | NCRISC | TRISC0 | TRISC1 | TRISC2 |
|---|---:|---:|---:|---:|---:|
| empty | 0.125/0.125 | 0.125/0.125 | 0.125/0.124512 | 0.125/0.125488 | 0.125/0.124512 |
| addi_dep | 1.124023/1.125488 | 1.125/1.125 | 1.125/1.125 | 1.125/1.125 | 1.125/1.125 |
| add_dep | 1.125/1.125488 | 1.125/1.125 | 1.125977/1.125 | 1.125/1.125 | 1.125/1.125 |
| xor_dep | 1.124023/1.125488 | 1.125/1.125 | 1.125/1.125 | 1.125/1.125 | 1.12207/1.125 |
| mul_dep | 2.0625/2.0625 | 2.0625/2.0625 | 2.0625/2.0625 | 2.0625/2.0625 | 2.0625/2.0625 |
| mul_ind4 | 1.124023/1.125977 | 1.125/1.125 | 1.125/1.125488 | 1.125/1.125 | 1.125/1.125 |
| divu_one | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 |
| divu_large | 33.125/33.125 | 33.125/33.125 | 33.125/33.125 | 33.125/33.125 | 33.125/33.125 |
| remu_large | 33.125/33.125 | 33.125/33.125 | 33.125/33.125 | 33.125/33.125 | 33.125/33.125 |
| fence | 4.125/4.125 | 4.125/4.125 | 4.125/4.125 | 4.125/4.125 | 4.125/4.125 |
| csr_cycle | 4.125/4.125 | 4.125/4.125 | 4.125/4.125 | 4.125/4.125 | 4.125/4.125 |
| load_l1_hot_dep | 8/8 | 7.999023/7.998535 | 8/8.000488 | 8/8 | 8.000977/7.999512 |
| load_l1_miss_dep | 7.99707/8.001465 | 8.001953/8 | 8.001953/7.999512 | 8/8 | 7.999023/8 |
| store_l1_same | 1.124023/1.125 | 1.125/1.125 | 1.125977/1.125 | 1.12793/1.125 | 1.125/1.125488 |
| store_l1_coalesced | 1.125/1.124512 | 1.125/1.125 | 1.126953/1.124023 | 1.128906/1.123047 | 1.124023/1.123535 |
| fadd_dep | 2.125977/2.124512 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 |
| fadd_ind4 | 1.125/1.125 | 1.125/1.125 | 1.125/1.125 | 1.125/1.125 | 1.123047/1.125977 |
| fmul_dep | 2.123047/2.125977 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 |
| fmadd_dep | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 | 2.125/2.125 | 2.125977/2.125 |

Default `cfg0=0x60008` disables L0 data cache and `.ttinsn` fusion. Thus `load_l1_hot_dep` is only nominally hot/same-address; it cannot hit a disabled cache. `divu_large` and `remu_large` use invariant dividend0xffffffff, divisor3; `divu_one` uses3/1. Four-independent-multiply/FP-add rows use distinct destinations. The16-op body plus two loop instructions explains1.125 for 1-cycle issue; dependent MUL2.0625 reflects overlap at the loop boundary, not a2.0625-cycle multiplier.

## SFPU: default versus fusion enabled

| Probe | Default slopes | Fusion-enabled slopes |
|---|---:|---:|
| empty | 0.125/0.125 | 0.125/0.125 |
| nop | 1.125/1.125 | 1/1 |
| loadi | 1.125/1.125 | 1/1 |
| mov_dep | 1.125/1.125 | 1/1 |
| iadd_dep | 1.125/1.125 | 1/1 |
| add_dep | 2/2 | 2/2 |
| add_ind4 | 1.125/1.125 | 1/1 |
| mul_dep | 2/2 | 2/2 |
| mul_ind4 | 1.125/1.125 | 1/1 |
| mad_dep | 2/2 | 2/2 |
| mad_ind4 | 1.125/1.125 | 1/1 |
| arecip_dep | 1.125/1.125 | 1/1 |
| mul24_dep | 2/2 | 2/2 |
| cast_dep | 1.125/1.125 | 1/1 |
| transp | 1.125/1.125 | 1/1 |
| swap | 2/2 | 2/2 |
| swap_nop | 2.125/2.125488 | 2/2 |
| shuffle | 2/2 | 2/2 |
| shuffle_nop | 2.125/2.125488 | 2/2 |
| shft2_bit | 1.125/1.125 | 1/1 |
| setcc | 1.125/1.125 | 1/1 |
| encc | 1.125/1.125 | 1/1 |
| dma_nop | 2.125/2.125 | 2/2 |

Fusion experiment clears only cfg0 bit18 inside the measured kernel setup and restores the saved bits before return. Direct SFPU emission is limited by downstream1/cycle even when four are enqueued in one scalar cycle. Long dependent chains still cost2/cycle spacing. `dma_nop` is a scalar ThCon probe in this suite, not an SFPU arithmetic opcode; observed effective stream cost2 contrasts with documented unit execution1.

## L0 cache enabled

Only cfg0 bit3 is cleared, then restored. Periodic L0 flushing remains enabled. The1-line pointer cycle fits L0; the8-line cycle exceeds four-line capacity.

| Probe | BRISC | NCRISC | TRISC0 | TRISC1 | TRISC2 |
|---|---:|---:|---:|---:|---:|
| load_l1_hot_dep | 2.15625/2.104004 | 2.15625/2.104004 | 2.157227/2.104004 | 2.15625/2.103516 | 2.15625/2.103516 |
| load_l1_miss_dep | 8/8 | 8/7.998535 | 8/7.999512 | 8/8 | 7.999023/8 |

## Context and private local RAM

| Card | Role | cfg0 | PMA0 / PMA1 | Local-RAM dependency slopes |
|---|---|---|---|---:|
| 0 | brisc | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 0 | ncrisc | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 0 | trisc0 | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 0 | trisc1 | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 0 | trisc2 | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 1 | brisc | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 1 | ncrisc | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 1 | trisc0 | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 1 | trisc1 | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |
| 1 | trisc2 | 0x60008 | 0x0 / 0x0 | 2.0625 / 2.0625 |

Local-RAM payload allocates16 bytes from the assembler local allocator and follows a self-pointer. The observed2.0625 slope for every role/card is consistent with2-cycle dependency latency plus partially hidden loop control.

## Reproduction

Run from `blackhole-py`, selecting queue/device explicitly:

```sh
tt-device-queue run --device 0 --cwd "$PWD" -- 'PYTHONPATH=. TIMING_OUTPUT=/tmp/riscv-timing.jsonl /home/boop/tenstorrent/.venv/bin/python -m pytest -q -s -p no:cacheprovider tests/timing/test_instruction_timing.py::test_riscv_timing --bh-hardware --bh-device=0 --bh-core=4'
tt-device-queue run --device 1 --cwd "$PWD" -- 'PYTHONPATH=. TIMING_CLEAR_CFG0_BITS=0x40000 TIMING_OUTPUT=/tmp/sfpu-fused.jsonl /home/boop/tenstorrent/.venv/bin/python -m pytest -q -s -p no:cacheprovider tests/timing/test_instruction_timing.py::test_sfpu_timing --bh-hardware --bh-device=1 --bh-core=4'
```

Use a new output filename for each run: JSONL appends. Set `TIMING_CLEAR_CFG0_BITS=0x8` with `-k load_l1` for the cache experiment. `test_timing_context` reads config and measures private local RAM; it does not apply that optional override. Exact hash-matched probe sources are preserved in `evidence/probe-source/`. Complete commands, statuses, raw logs and output hashes: [runs.json](evidence/runs.json).

## Runs

| Job | Card | Exit | Dataset |
|---|---:|---:|---|
| `21a451ae80e94574b7f5aca1e7518aad` | 0 | 0 | [riscv-card0.jsonl](evidence/riscv-card0.jsonl) |
| `815c4b8b3a994a86ad6e4bc7b8a4e6d8` | 1 | 1 | [sfpu-card1.jsonl](evidence/sfpu-card1.jsonl) |
| `74aef5e0c0d14e2783ec72cd28872cde` | 1 | 0 | [sfpu-card1-final.jsonl](evidence/sfpu-card1-final.jsonl) |
| `e5f860a59a694155b05adc9f927e49ef` | 0 | 0 | [context-card0.jsonl](evidence/context-card0.jsonl) |
| `0eeab71545a041ecbd2dfe811f128e66` | 1 | 0 | [context-card1.jsonl](evidence/context-card1.jsonl) |
| `a8990787833845f892990a5cb79701d6` | 0 | 0 | [riscv-l0-enabled-card0.jsonl](evidence/riscv-l0-enabled-card0.jsonl) |
| `b969de98078e44bd8228d46bce0dffc2` | 1 | 0 | [sfpu-fusion-enabled-card1.jsonl](evidence/sfpu-fusion-enabled-card1.jsonl) |
