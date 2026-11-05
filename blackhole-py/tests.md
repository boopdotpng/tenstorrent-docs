# Tests

Low-level Blackhole hardware tests: instruction behavior, compute, data movement,
synchronization, and timing. Model/runtime integration tests are removed.
The [ISA conformance suite](isa-conformance.md) additionally has offline checks for
all Tensix encoders and hardware tests with a documented coverage inventory.
Its encoding checks do not establish full functional ISA coverage.
The `operation_pocs/runtime` tests cover hardware primitives such as circular
buffers, semaphores, and NoC transfers.

Run from the repository using the shared workspace virtualenv:

```sh
../.venv/bin/python -m pytest tests --bh-hardware --bh-device=0 -q
```

Reserve the card with `tt-device-queue` when sharing it. Tests run sequentially;
do not use xdist. Without `--bh-hardware`, hardware tests skip; ISA encoding
checks run offline.

The `bh` fixture provides raw DRAM/L1 access and kernel launches. Kernels use
`Asm` directly; `bh.launch` fills missing RISC roles with firmware-return stubs.
A RISC-V `ret` cannot return from a worker kernel.

`tests/profiler.py` records device cycle intervals. Put completion waits inside
an interval when measuring completed work. The [test viewer](test-viewer.md)
can inspect generated instructions offline; captures do not establish hardware correctness.

## Other test directories

- `tests/isa`: see the [ISA conformance suite](isa-conformance.md).
- `tests/timing`: instruction timing probes; `python -m tests.timing.tensix_catalog`
  regenerates `tensix_timing.json`, which the `/isa` viewer page reads.
- `tests/movement/dram_patterns`: scripts, case lists and raw JSON for
  [DRAM traffic patterns](../measurements/dram-traffic-patterns.md). These are
  not pytest tests. Run each script directly:
  `../.venv/bin/python -I tests/movement/dram_patterns/<script>.py <device> <out.json> [cases.json]`.
