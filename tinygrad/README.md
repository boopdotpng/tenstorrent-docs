# tinygrad and Blackhole

Use the September 2026 [compiler source maps](../compiler-maps/README.md) for
current study. Each map names the source revision it describes.

- [Module map](../compiler-maps/tinygrad/module-map.md): Tensor construction through execution.
- [UOps and rewrites](../compiler-maps/tinygrad/uops-and-rewrites.md): representation and rewrite contracts.
- [Individual rules](../compiler-maps/tinygrad/rules/README.md): matcher entries and examples.
- [RMSNorm and fusion](../compiler-maps/tinygrad/rmsnorm-kernel-fusion.md): a worked lowering case.
- [Blackhole runtime](../build-and-dispatch/blackhole-py-runtime.md) and [hardware evidence](../hardware/behavior-from-tests.md): the target's execution model.

May/July internals guides, UOp lists, probes, backend plans, and the direct
lowering investigation are now in the [historical collection](../archive/tinygrad/README.md).
Their API names and compiler stages belong to their recorded revisions.
