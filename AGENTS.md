# AGENTS.md

## Start here

- Run `./serve.sh`; optional `--port`. Bind is `0.0.0.0`; no browser launch.
- `/` is documentation, `/isa` is the dedicated Tensix reference, `/archives`
  is historical material. Each has its own navigation. `/` key opens global search.
- Read `README.md`, then `intro.md` for orientation.
- `human/` is read-only. Never edit files there.

## Topic router

| Question | Reference |
|---|---|
| Hardware architecture | `hardware/architecture.md` |
| What blackhole-py tests establish | `hardware/behavior-from-tests.md` |
| Coordinates, harvesting, worker placement | `hardware/topology.md` |
| Host transfers, pinned memory, DMA distinctions | `hardware/host-memory.md` |
| PCIe registers and driver interface | `hardware/pcie-and-tt-kmd.md` |
| Performance counters | `hardware/performance-counters.md` |
| Instruction behavior, timing, caveats, tests | `/isa`; `viewer/data/instructions.json` |
| Detailed state-machine/register models | `hardware/blackhole-emulator-specs/README.md` |
| Compute scheduling, MOP/replay, ownership | `kernel-dev/tensix-compute-pipeline.md` |
| CBs, dataflow patterns, reduction padding | `kernel-dev/dataflow.md` |
| SFPI/LLK programming and masking | `kernel-dev/sfpi.md` |
| TT-Metal tile layouts | `kernel-dev/tilize-untilize-and-tile-layout.md` |
| Matmul, row-major input, fidelity, FP32, fusion, results | `matmul/README.md`, `matmul/results/` |
| Matmul multicast and scheduling tradeoffs | `matmul/scheduling.md` |
| Current blackhole-py build/dispatch | `blackhole-py/runtime.md` |
| blackhole-py tests, ISA suite, ttk design | `blackhole-py/README.md` |
| Hardware results (DRAM, NoC, RMSNorm, Llama) | `measurements/README.md` |
| Misattributed "hardware bugs", unverified errata | `kernel-dev/known-issues.md` |
| FP8/FP4 unpack/pack behavior | `hardware/fp8-and-fp4.md` |
| TT-Metal build, ELF/XIP, worker boot | `build-and-dispatch/tt-metal-build.md` |
| TT-Metal CQ commands and launch ABI | `build-and-dispatch/tt-metal-dispatch.md` |
| Debug tools, environment variables, dispatch benchmark | `build-and-dispatch/debugging.md` |
| Board firmware, ARC/SMC/DMC, fwbundles | `firmware/README.md` |
| Multi-chip/host and TT-Fabric | `multi-chip/README.md` |
| Compiler internals, rules, worked exercises | `compiler-maps/README.md` |
| Historical experiments, reports, instruction frequencies | `/archives`; `archive/README.md` |

- **"Cycle counts / instruction latency / five-RISC predictor?"** -> `timing/README.md` (cheat sheet, predictor) and `timing/kernel-estimation.md` (current per-encoder table, also on `/isa`).

## Maintenance

- Refresh ISA evidence with `python3 viewer/build_reference.py`. It reads local
  sibling checkouts without executing their code or touching hardware.
- Validate with `python3 -m unittest discover -s viewer/tests -v`.
- Old-to-new document paths are in `maintenance/relocations.json`.
- Read `maintenance/README.md` for provenance, consolidation scope, and limits.
- blackhole-py keeps no prose docs; write them here. Its root README links here.
- Do not call something a hardware bug unless a direct (non-TT-Metal) kernel
  reproduces it or the ISA manual documents it. Record cases in `kernel-dev/known-issues.md`.
- Keep hardware behavior separate from runtime conventions. Encoding checks,
  behavioral claims, and measured timing are different evidence.
- Compiler maps retain pinned source revisions. Historical corpus frequency
  does not establish that an instruction is unsupported or safe to delete.
