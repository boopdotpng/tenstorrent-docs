# AGENTS.md

Compact router for this repo so you can find answers fast without reading everything.

## Start here

- Read `README.md` first for project goal + top-level folder map.
- Next level of routing: open the folder-level `README.md` when it exists:
  - `blackhole/README.md`
  - `tt-metal/README.md`
  - `llk-sfpi/README.md`
  - `disasms/README.md`
- For folders without a `README.md`, jump to the primary doc directly:
  - `tinygrad/` -> `tinygrad/tt-backend-notes.md`
  - `debugging/` -> `debugging/register-memory-tooling.md`
  - `human/` -> read-only notes (`human/chatgpt.md`, `human/tinygrad-backend.md`)

## Folder map (what lives where)

- `blackhole/`: hardware + platform behavior (architecture, PCIe/tt-kmd, firmware, coords/translation, fast-dispatch ABI).
- `tt-metal/`: kernel build/load/dispatch/dataflow/SFPI notes and one launch example (`add1_nondistributed_launch.cpp`).
- `llk-sfpi/`: LLK/SFPI conceptual docs, separate from TT-Metal runtime notes.
- `tinygrad/`: tinygrad backend planning + AMD UOp docs.
- `debugging/`: register/memory tooling workflow.
- `disasms/`: raw RISC-V objdump artifacts.
- `human/`: human-authored docs, read-only.

## Guardrail

- `human/` is read-only: do not edit files there.

## Router: what to read for each question

- **"How does Blackhole hardware work?"** -> `blackhole/architecture.md`
- **"Why is coord X/Y weird or out of range?"** -> `blackhole/coordinates-and-translation.md`
- **"How do PCIe, BARs, TLB, IOCTLs work?"** -> `blackhole/pcie-and-tt-kmd.md`
- **"What is the fast-dispatch queue ABI/layout?"** -> `blackhole/fast-dispatch-abi.md`
- **"Firmware/reset/fan/control flow?"** -> `blackhole/firmware.md`

- **"How are kernels built/cached/disassembled?"** -> `tt-metal/kernel-build-and-cache.md`
- **"How are kernels loaded/XIP/runtime args packed?"** -> `tt-metal/kernel-loading-and-abi.md`
- **"Fast vs slow dispatch behavior?"** -> `tt-metal/dispatch-modes.md`
- **"CB semantics and dataflow patterns?"** -> `tt-metal/dataflow-and-cbs.md`
- **"SFPI kernel writing + Tensix mental model?"** -> `tt-metal/sfpi-and-kernel-dev.md`
- **"Debug env vars?"** -> `tt-metal/debug-env-vars.md`

- **"LLK vs SFPI model and examples?"** -> `llk-sfpi/llk-and-sfpi-model.md`
- **"SFPI API/reference details?"** -> `llk-sfpi/sfpi.md`

- **"How would a tinygrad TT backend be structured?"** -> `tinygrad/tt-backend-notes.md`
- **"What do AMD UOps mean (curated)?"** -> `tinygrad/amdgpu_uops_reference.md`
- **"Need raw UOp dump evidence?"** -> `tinygrad/amdgpu_uops_report.md` (very large; avoid unless necessary)

- **"Need raw instruction dumps for a kernel?"** -> `disasms/add1_sfpu_single_file/*.objdump.txt`

## Very long files (read with intent)

Use these only when you need deep detail or raw artifacts:

- `tinygrad/amdgpu_uops_report.md` (~17k lines): generated raw UOp dump.
- `disasms/add1_sfpu_single_file/firmware_brisc.objdump.txt` (~1.1k lines): raw disasm.
- `tt-metal/sfpi-and-kernel-dev.md` (~1.0k lines): broad SFPI + Tensix deep dive.
- `tt-metal/kernel-build-and-cache.md` (~700 lines): full build/cache/disasm pipeline.
- `tinygrad/tt-backend-notes.md` (~550 lines): complete backend design plan.

If you only need orientation, prefer folder READMEs and the router above.

## Fast search strategy (default)

1. Read `README.md` + relevant folder `README.md`.
2. Open exactly one target doc from the router list.
3. Only expand to long/raw files if the target doc lacks the needed detail.

This repo is intentionally note-heavy; optimize for the shortest path to one authoritative file.
