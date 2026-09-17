# Kernel development

For current blackhole-py, begin with [row-major matmul](row-major-matmul.md),
[fusion](kernel-fusion.md), and [test evidence](../hardware/behavior-from-tests.md).
SFPI/LLK tutorials below describe the C++ stack. Their APIs are not the current
Python emitter API; their synchronization and layout concepts remain useful.

## Documents

- [Dataflow, buffers, and CBs](dataflow-and-cbs.md)
- [Dataflow Kernel Templates for Compiler-Generated Ops](dataflow-kernel-templates.md)
- [FPU Matmul Fidelity Phases](fpu-matmul-fidelity-phases.md)
- [Keeping a matmul epilogue in Dst](kernel-fusion.md)
- [LLK + SFPI model and kernel inventory](llk-and-sfpi-model.md)
- [Reduction padding strategies in tt-metal](reduction-padding-strategies.md)
- [Replay buffer and MOP expander for SFPU operations](replay-buffer-and-mop-for-sfpu.md)
- [Row-major inputs without a separate tilize pass](row-major-matmul.md)
- [SFPI and kernel development (Blackhole)](sfpi-and-kernel-dev.md)
- [SFPI execution model: vector width, face iteration, and per-lane masking](sfpi-execution-model-and-masking.md)
- [SFPI / SFPU programming notes](sfpi.md)
- [Tensix compute pipeline: TRISC, FPU, SFPU, MOP](tensix-compute-pipeline.md)
- [Tilize, Untilize, and Tile Layout](tilize-untilize-and-tile-layout.md)
