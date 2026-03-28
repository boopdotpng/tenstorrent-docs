# AGENTS.md

Compact router for this repo so you can find answers fast without reading everything.

## Start here

- Read `README.md` first for project goal, reading order, and folder map.

## Folder map

- `hardware/`: chip architecture, NoC, Tensix tiles, PCIe, coordinates, ERISC, grid utilization.
- `kernel-dev/`: SFPI/LLK programming, compute pipeline, CBs/dataflow, tile layout, kernel fusion, reduction padding.
- `build-and-dispatch/`: kernel compilation, loading ABI, dispatch pipeline, CQ protocol, debugging tools/env vars.
- `firmware/`: firmware architecture, upload sequence, build system.
- `matmul/`: matrix multiply (ELI5 intros through peak performance analysis and gap analysis).
- `multi-chip/`: multi-host architecture, TT-Fabric, topology/routing, data-parallel training walkthrough.
- `llk-sfpi/`: LLK/SFPI instruction-level compute pipeline, ISA analysis, FPU fidelity, kernel fusion.
- `disasms/`: raw RISC-V objdump artifacts.
- `human/`: human-authored notes (read-only).

## Guardrail

- `human/` is read-only: do not edit files there.

## Router: what to read for each question

### Hardware
- **"How does Blackhole hardware work?"** -> `hardware/architecture.md`
- **"Tensix compute units / FPU / SFPU ISA?"** -> `hardware/tensix-compute-units.md`
- **"Why is coord X/Y weird or out of range?"** -> `hardware/coordinates-and-translation.md`
- **"How do PCIe, BARs, TLB, IOCTLs work?"** -> `hardware/pcie-and-tt-kmd.md`
- **"PCIe DMA vs sysmem?"** -> `hardware/pcie-dma-and-sysmem.md`
- **"L1 address map / tile addresses?"** -> `hardware/tile-addresses-and-l1-map.md`
- **"Grid utilization / column 14?"** -> `hardware/grid-utilization.md`
- **"ERISC / ethernet cores?"** -> `hardware/erisc-cores-and-ethernet-launch.md`
- **"Packer L1 acc Float16 bug?"** -> `hardware/packer-l1-acc-float16-hardware-bug.md`

### LLK / SFPI / ISA
- **"Which instructions are actually used on Blackhole?"** -> `llk-sfpi/blackhole-instruction-set-analysis.md`
- **"Which instructions are dead / unused?"** -> `llk-sfpi/blackhole-instruction-set-analysis.md`

### Kernel development
- **"How to write SFPI kernels?"** -> `kernel-dev/sfpi-and-kernel-dev.md`
- **"SFPI API reference?"** -> `kernel-dev/sfpi.md`
- **"LLK vs SFPI model?"** -> `kernel-dev/llk-and-sfpi-model.md`
- **"Compute pipeline / matmul programming?"** -> `kernel-dev/tensix-compute-pipeline.md`
- **"Replay buffer / MOP for SFPU?"** -> `kernel-dev/replay-buffer-and-mop-for-sfpu.md`
- **"SFPU execution model / masking?"** -> `kernel-dev/sfpi-execution-model-and-masking.md`
- **"Kernel fusion (matmul + SFPU epilogue)?"** -> `kernel-dev/kernel-fusion.md`
- **"FPU fidelity phases?"** -> `kernel-dev/fpu-matmul-fidelity-phases.md`
- **"CB semantics / dataflow patterns?"** -> `kernel-dev/dataflow-and-cbs.md`
- **"Tile layout / tilize / untilize?"** -> `kernel-dev/tilize-untilize-and-tile-layout.md`
- **"Reduction padding strategies?"** -> `kernel-dev/reduction-padding-strategies.md`

### Build and dispatch
- **"How are kernels built/cached?"** -> `build-and-dispatch/kernel-build-and-cache.md`
- **"How are kernels loaded/XIP/runtime args?"** -> `build-and-dispatch/kernel-loading-and-abi.md`
- **"Fast vs slow dispatch?"** -> `build-and-dispatch/dispatch-modes.md`
- **"Dispatch kernel catalog / CQ command protocol?"** -> `build-and-dispatch/dispatch-kernel-pipeline-internals.md`
- **"Fast dispatch ABI / compile-time defines?"** -> `build-and-dispatch/fast-dispatch-abi.md`
- **"Concrete CQ command trace?"** -> `build-and-dispatch/fast-dispatch-cq-dump.md`
- **"Blackhole-py fast dispatch bugs/notes?"** -> `build-and-dispatch/fast-dispatch-implementation-notes.md`
- **"Slow dispatch TLB write sequence?"** -> `build-and-dispatch/slow-dispatch-tlb-writes.md`
- **"Debug env vars?"** -> `build-and-dispatch/debug-env-vars.md`
- **"Dispatch benchmarking?"** -> `build-and-dispatch/dispatch-benchmark-howto.md`
- **"Register/memory debugging tools?"** -> `build-and-dispatch/register-memory-tooling.md`

### Firmware
- **"Firmware source architecture?"** -> `firmware/firmware-source-architecture.md`
- **"Firmware upload sequence?"** -> `firmware/firmware-upload-sequence.md`
- **"Building firmware / fwbundles?"** -> `firmware/firmware-build-system.md`

### Matmul
- **"How does matmul work on TT? (ELI5)"** -> `matmul/fast-matmul-eli5.md`
- **"Why 4 dataflow roles for matmul?"** -> `matmul/matmul-2d-mcast-role-split-eli5.md`
- **"When to use 4-role multicast?"** -> `matmul/when-to-use-4-role-mcast.md`
- **"Matmul autogen design?"** -> `matmul/matmul-autogen-design.md`
- **"Matmul peak performance / porting?"** -> `matmul/matmul-peak-block-lifecycle-and-blackhole-py-port.md`
- **"FP32 vs FP16 accumulation?"** -> `matmul/fp32-accumulation.md`
- **"Matmul benchmark results?"** -> `matmul/matmul-peak-sweep.md`

### Multi-chip
- **"Multi-host / remote cards / training walkthrough?"** -> `multi-chip/multi-host-and-remote-card-architecture.md`
- **"TT-Fabric / topology / routing?"** -> `multi-chip/fabric-and-topology-internals.md`

### Raw artifacts
- **"Need raw instruction dumps?"** -> `disasms/add1_sfpu_single_file/*.objdump.txt`

## Very long files (read with intent)

- `kernel-dev/sfpi-and-kernel-dev.md` (~780 lines): broad SFPI + kernel dev audit.
- `hardware/tensix-compute-units.md` (~770 lines): complete ISA reference.
- `build-and-dispatch/kernel-build-and-cache.md` (~700 lines): full build/cache pipeline.
If you only need orientation, prefer the README reading order and this router.

## Fast search strategy (default)

1. Read `README.md` for orientation.
2. Use the router above to find the one target doc.
3. Only expand to long/raw files if the target doc lacks the needed detail.
