# Blackhole Microbenching

Archive of the Blackhole microbenchmark scripts and checked-in reports that
used to live in `blackhole-py/microbenching/`.

## Start Here

| Need | File |
|------|------|
| Current pass/fail state, missing primitives, quarantined benches | `status.md` |
| Raw report index | `docs/README.md` |
| NoC guide from zero | `docs/noc/reading-guide.md` |
| NoC/DRAM/multicast report data | `docs/noc/` |
| Tensix/DRISC/pack-unpack report data | `docs/tensix/` |
| Scripts | `tensix/`, `noc/`, `riscv/`, `matmul/`, `models/` |

## Archive Shape

- `tensix/`: SFPU, DRISC, pack/unpack, semaphore/CB, and instruction-issue benches.
- `noc/`: NoC, multicast, endpoint, topology, and coordinate probes.
- `riscv/`: RISC-V core, memory, contention, clone-model, and visibility probes.
- `matmul/`: GEMV, attention-stage, decode bridge, and shape/model scripts.
- `models/`: host-side summaries, NoC scheduler model, and workload expansion tools.
- `docs/`: raw markdown reports and hardware logs.

## Running

The scripts are preserved with their original `blackhole-py/microbenching/...`
path assumptions. To run one, copy the needed files or this whole directory
back into a `blackhole-py` checkout and run it there:

```bash
PYTHONPATH=. python3 microbenching/tensix/microbench_sfpu_transcendental.py --iters 4096
```

Use `--no-report` for smoke runs unless you intentionally want to append to the
archived markdown reports.
