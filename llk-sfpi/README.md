# llk-sfpi/

LLK/SFPI instruction-level compute pipeline docs, ISA analysis, FPU fidelity, kernel fusion.

## Files

- [blackhole-instruction-set-analysis.md](blackhole-instruction-set-analysis.md) — Empirical analysis of which Blackhole instructions are used vs dead, from disassembling all kernel/firmware ELFs across Qwen2.5-3B, ResNet50, ViT, and other workloads. 135/244 used, 42% effectively dead.
- [instruction-frequency-report.md](instruction-frequency-report.md) — Comprehensive frequency report from 747 kernel ELFs (20 C++ examples, 60+ ttnn ops including gcd/lcm/bitwise, transformer decoder block). Tracks both inline TTINSN and sw-to-FIFO instruction paths. 141/243 dsl.py instructions used; identifies 9 mislabeled-as-rare and 102 deletable.
