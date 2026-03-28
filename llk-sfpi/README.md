# llk-sfpi/

LLK/SFPI instruction-level compute pipeline docs, ISA analysis, FPU fidelity, kernel fusion.

## Files

- [blackhole-instruction-set-analysis.md](blackhole-instruction-set-analysis.md) — Empirical analysis of which Blackhole instructions are used vs dead, from disassembling all kernel/firmware ELFs across Qwen2.5-3B, ResNet50, ViT, and other workloads. 135/244 used, 42% effectively dead.
