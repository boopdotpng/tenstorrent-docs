# Historical studies and retired implementations

These documents retain revision-specific explanations, measurements, and raw
artifacts. Their runtime interfaces and “current” statements refer to the
captured versions. Start with the [current introduction](../intro.md) or
[compiler maps](../compiler-maps/README.md) for new work.

| Collection | Why retained | Current starting point |
|---|---|---|
| [tinygrad studies](tinygrad/README.md) | May/July compiler traces, migration explanations, backend investigations and experimental artifacts | [September compiler maps](../compiler-maps/README.md) |
| [Old CQ bring-up](build-and-dispatch/fast-dispatch-implementation-notes.md) | Bugs and protocol details from the retired TT-Metal-firmware-based blackhole-py runtime | [Current runtime](../build-and-dispatch/blackhole-py-runtime.md) |
| [Old CQ trace](build-and-dispatch/fast-dispatch-cq-dump.md) | Concrete bytes from that runtime | [Current runtime](../build-and-dispatch/blackhole-py-runtime.md) |
| [P100A sweep](matmul/matmul-peak-sweep.md) | Numerical performance records under the original configuration | [Current row-major comparison](../matmul/README.md#row-major-matmul) |
| [Block lifecycle port plan](matmul/matmul-peak-block-lifecycle-and-blackhole-py-port.md) | Original TT-Metal port rationale | [Precision and spills](../matmul/README.md#fp32-accumulation) |
| [Compute synchronization drawing](matmul/matmul-peak-compute-sync-graph-b2.md) | Detailed diagram of the old 118-worker schedule | [Current grid](../hardware/topology.md) |

The [microbenchmark archive](../microbenching/README.md) stays with its scripts
and raw results. [Instruction frequency reports](../llk-sfpi/README.md) also
remain dated workload evidence. Neither collection establishes universal chip
behavior or current API support.

Removed rather than archived: the old tilize-fusion reminder and fixed-10×11
matmul autogenerator plan. Their actionable replacements are the current
[row-major guide](../matmul/README.md#row-major-matmul) and
[placement constraints](../hardware/topology.md). Git history retains
the originals. [Relocations](../maintenance/relocations.json) record every moved
artifact and the two replacements.
