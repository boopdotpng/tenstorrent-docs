# LLK + SFPI docs

This folder keeps SFPI/LLK notes separate from TT-Metal runtime docs.

Files:
- `sfpi.md`: SFPI repo layout, build, API, ops, and examples.
- `llk-and-sfpi-model.md`: LLK kernel inventory, SFPU vs non-SFPU examples, and pack/unpack/tilize/untilize walkthrough.
- `sfpi-execution-model-and-masking.md`: SFPU 32-lane vector width, face iteration, per-lane CC predication (v_if/v_else/v_endif), and static ROW_MASK.
- `replay-buffer-and-mop-for-sfpu.md`: 32-slot replay buffer, MOP expander, ckernel_template, and how to use MOP+replay for tile-wide SFPU ops.
