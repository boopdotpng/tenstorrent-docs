# Blackhole Microbenching

This directory archives the Blackhole microbenchmark scripts and their
checked-in reports. It was moved out of `blackhole-py` so the driver repo can
stay focused on library code and runnable examples.

## Layout

| Path | Contents |
|------|----------|
| `status.md` | Current pass/fail/timing summary and known quarantined benches |
| `docs/noc/` | NoC, DRAM endpoint, multicast, arbitration, and scheduler reports |
| `docs/tensix/` | Tensix pack/unpack, DRISC DMA, and related reports |
| `tensix/` | Tensix/SFPU/DRISC benchmark scripts |
| `noc/` | NoC, multicast, endpoint, and topology benchmark scripts |
| `riscv/` | RISC-V core, memory, contention, and clone-model scripts |
| `matmul/` | Matmul, GEMV, attention-stage, and decode bridge scripts |
| `models/` | Host-side summary and NoC scheduling/modeling utilities |

## Running

The scripts are archived with their original `blackhole-py/microbenching/...`
path assumptions. To run or revive one, copy the relevant files or this whole
directory back into a `blackhole-py` checkout and run it there, for example:

```bash
PYTHONPATH=. python3 microbenching/tensix/microbench_sfpu_transcendental.py --iters 4096
```

Report-writing defaults append under `microbenching/docs/` after the directory
has been copied back. Use `--no-report` for smoke runs that should not modify
checked-in reports.
