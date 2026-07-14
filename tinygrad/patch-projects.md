# A tinygrad-internals patch project ladder

This ladder assumes you can already write and run models in tinygrad. It is
ordered to move from observing the compiler, through small upstream-quality
patches, to a Blackhole backend without making "write a backend" the first task.

The source anchors and project claims were audited at tinygrad commit
`4234a9d727e52a6bb033c387d2c869cea4caf641` (2026-07-10). Recheck the named
TODOs and APIs before starting a project on a later revision.

The recommended first sequence is **1 → 2 → 3 → 7**. It exercises every major
compiler boundary, produces two plausible upstream patches, and only then puts
hardware underneath the current device API.

Each project has a narrow definition of done. Keep before/after UOp fixtures and
compile-time measurements; graph rewrites that merely "look simpler" are hard to
review and easy to regress.

## 1. Build a stage-diff explorer

**Level:** beginner internals; tooling/docs

Write a small tool that accepts a Tensor-producing function and captures:

1. raw `Tensor.uop` / `SINK`;
2. callified graph;
3. rangeified kernel graph;
4. schedule-level `LINEAR`;
5. program `SINK` just before linearization;
6. program-level `LINEAR` and emitted source.

For each stage, print op histogram, node count, maximum dependency depth,
buffers, ranges, and a stable textual tree. Start with:

```python
(a + 2).permute(1, 0).sum(axis=1)
```

Then compare contiguous/transposed matmul, softmax, RMSNorm, padding, broadcast,
and assignment.

**You learn:** exactly where movement, reduction, effects, and vectorization
change form; how to call compiler stages without relying on `repr` object IDs.

**Done when:** a test asserts phase invariants rather than a huge fragile dump:
Tensor-level movement is absent immediately after rangeify; `REDUCE` survives
to a documented boundary; schedule `LINEAR` children are calls; program
`LINEAR` is ordered. Do not assert that movement ops never reappear: current
codegen intentionally reintroduces shaped movement during lane expansion.

**Starting points:** `Tensor.linear_with_vars`, `transform_to_call`,
`get_kernel_graph`, `full_rewrite_to_sink`, `to_program`; the existing
[probe corpus](uop-probes/README.md).

**Upstream fit:** perhaps `extra/` or tests, but its main value is your local
compiler microscope.

## 2. Fix the explicit `limit_bufs` quadratic walk

**Level:** small upstream performance patch

`schedule/rangeify.py::limit_bufs` traverses an input subgraph to discover its
leaf buffers every time the matcher visits a binary/ternary root. The source
contains `TODO: add cache to fix n^2`.

Replace repeated gated topological walks with a pass-local memoized buffer
footprint. A node's footprint is:

- itself for a load boundary (`STAGE`, `AFTER`, `PARAM`, `MSELECT`, `MSTACK`);
- otherwise the union of its sources' footprints.

Keep context local to one rangeify invocation, and preserve early cutoff if a
bounded count is cheaper than constructing a full large set.

**You learn:** DAG sharing, matcher context, hash-consed node identity, kernel
buffer constraints, and why an apparently local matcher can scale globally.

**Done when:** output schedules are structurally/effect-equivalent; a synthetic
shared-DAG case demonstrates subquadratic scaling; ordinary rangeify/schedule
tests pass.

**Tests:** `test/backend/test_rangeify.py`, `test/backend/test_schedule.py`,
`test/external/external_test_schedule_scaling.py`, and a focused new scaling
case. Measure several graph sizes and report medians—do not assert wall-clock
microseconds in a unit test.

**Upstream fit:** strong. It fixes an explicit current-source TODO with a bounded
behavioral claim.

## 3. Restore or replace the stale rangeify shape invariant

**Level:** small correctness/cleanup patch

`schedule/indexing.py` has a disabled assertion that output range count matches
`x.shape`, accompanied by "enable this after the `.st` property is removed".
`.st` and ShapeTracker have been gone since October 2025.

Enable it locally, run broad schedule/rangeify tests, and minimize the first
counterexample. Then choose the honest result:

- fix the op whose derived shape is wrong;
- narrow the invariant to shaped ops;
- state a different invariant that matches valid void/tuple/call nodes; or
- delete the stale comment with a regression test explaining why equality is
  not valid.

**You learn:** the ShapeTracker replacement, shaped versus void UOps, consumer
range propagation, and how compiler invariants rot.

**Done when:** there is no knowingly false broad assertion, and the minimized
case documents the legal exception or the bug fix.

**Upstream fit:** strong if the patch includes the reduced reproducer and does
not just uncomment an assertion.

## 4. Profile one PatternMatcher family and remove wasted work

**Level:** small/medium compiler patch

Use `TRACK_MATCH_STATS=3` / `PRINT_MATCH_STATS=1` and the rewrite visualization
on representative movement, reduction, and model graphs. Pick one matcher with
high attempts and few successful rewrites. Improve its root-op index, dtype/src
constraints, `custom_early_reject`, or pass placement without changing rule
order semantics.

**You learn:** compiled `UPat`, first-match behavior, composite order,
fixed-point rewriting, and the difference between match attempts and graph
traversal time.

**Done when:** the same graph/program and numeric result are produced; matcher
attempts or measured compile time improve on at least two workloads; a targeted
test covers the rule ordering you touched.

**Tests:** `test/null/test_pattern_matcher.py`,
`test/null/test_graph_rewrite.py`, the affected compiler tests, and
`test/external/external_benchmark_pyrender.py` when relevant.

**Upstream fit:** good if evidence is reproducible. Avoid a broad matcher
reordering as a first contribution.

## 5. Make kernel buffer limits a target capability

**Level:** medium upstream architecture patch

`schedule/rangeify.py` currently contains:

```python
DEVICE_MAX_BUFS = {"METAL": 31, "WEBGPU": 8}  # TODO: get from device?
```

Move this capability to the target/renderer/device description used by
scheduling. Preserve schedule-cache correctness: a cache key must distinguish
targets if the limit can change kernel splitting.

**You learn:** where device facts enter a nominally generic scheduler, renderer
construction, schedule caching, and why backend capabilities affect fusion.

**Done when:** METAL and WEBGPU generate the same split schedules as before,
ordinary targets remain unlimited, an artificial low-limit target has a small
test, and no device is opened merely to schedule.

**Upstream fit:** good, but agree on the capability's owner before writing a
large patch. This can touch a public internal interface.

## 6. Optimize validity/`WHERE` handling

**Level:** medium symbolic patch

`uop/symbolic.py` contains a disabled nested-`WHERE` closure fold labeled
`O(number of WHERE * number of node)`, and notes duplicated gated-load behavior.
The duplicate now spans `pm_move_where_on_load` and
`codegen/late/gater.py::pm_move_gates_from_index`; the source comment still
mentions the deleted devectorizer module.

Two safe project choices are:

- implement indexed lookup/memoization that makes the desired fold cheap; or
- consolidate one duplicated gated-load rewrite while preserving phase-specific
  legality.

Use generated expressions with many repeated conditions and fuzz numeric
equivalence over integer/bool domains. Pay special attention to `Invalid`, image
indexes, and overflow semantics.

**You learn:** symbolic value bounds, invalid/padding semantics, condition
canonicalization, and why mathematically obvious rewrites can be invalid for
memory operations.

**Done when:** a minimized correctness suite and scaling benchmark accompany the
change. Do not enable the commented rule unchanged.

**Upstream fit:** good after fuzzing; this has a wider correctness surface than
projects 2–3.

## 7. Port only Blackhole device discovery and a DRAM round trip

**Level:** hardware beginner; research branch

On current tinygrad master, reuse the maintained `blackhole-py` runtime boundary
and implement the smallest tinygrad device/runtime slice:

- open and identify a P100A or P150 through current `blackhole-py` abstractions;
- expose allocator handles through current tinygrad device APIs;
- allocate one tile-aligned DRAM page;
- copy host → DRAM → host;
- verify exact bytes for bf16/fp32 tile and several allocation sizes;
- close/reopen cleanly and report capacity errors.

No compute renderer is required. Keep board discovery and buffer transport in
separate modules so they can be tested without compiling kernels.

**You learn:** current `Compiled`/allocator/runtime interfaces, tt-kmd/VFIO,
tile face layout, pinned staging, and ownership/lifetime semantics.

**Done when:** repeated allocations can be freed/reused; transfers larger than
the staging window are chunked; `SLICE`/offset behavior has a test; both board
topologies have pure-Python tests even if only one card is available.

**Upstream fit:** research/fork until it has CI strategy and a maintained
runtime dependency story.

## 8. Adapt `blackhole-py` P100A/P150 `BoardInfo` into a topology planner

**Level:** medium backend infrastructure

Use the existing `blackhole-py` board description as the source of truth and
adapt it to an immutable compiler view containing:

- active and dispatchable Tensix coordinates;
- reserved command-queue cores;
- enabled DRAM banks and their NoC ports;
- PCIe and Ethernet resources;
- L1 capacity and usable CB region;
- board/revision identifiers used in program cache keys.

Add helpers for contiguous rectangles, row/column multicast groups, and an even
tile-span partition over an arbitrary coordinate list.

**You learn:** topology versus cardinality, harvesting, dispatch reservations,
NoC geometry, and why P100A's 118 workers do not form the best matmul rectangle.

**Done when:** fixtures cover P100A 120/118 and P150 140/138 layouts, seven/eight
DRAM banks, invalid reserved-core selection, and deterministic plan/cache keys.

**Starting points:** current `blackhole-py` board configuration and
[device-grid docs](../hardware/blackhole-emulator-specs/device-grid.md).

## 9. One-tile current-master elementwise backend

**Level:** medium backend/compiler

Lower one rangeified kernel `SINK` to a Blackhole program supporting exactly:

- contiguous tiled bf16 or fp32 buffers;
- one output store;
- parameter-backed loads with equal shape;
- `ADD` and `MUL`, then a fused chain;
- one core and one complete 32×32 tile.

Keep the classifier strict and give every rejection a useful reason. Build a
plan object that already separates tensor metadata, CB allocation, dataflow
roles, compute source, and runtime args.

**You learn:** the `pm_compile` seam, rangeified indexes, TT reader/compute/writer
coordination, CB protocol, program caching, and numeric validation.

**Done when:** tinygrad Tensor expressions run and compare against CPU; compile
cache hits avoid recompilation/upload where safe; unsupported movement is
rejected before dispatch; generated artifacts can be inspected.

Then extend in this order: several tiles → several cores → tails/masks →
broadcast → casts/comparisons/`WHERE` → SFPU transcendental approximations.

## 10. Shape-aware tiled layout and DMA

**Level:** advanced backend

Make layout a property of allocations/views rather than an implicit Python
face transform:

- logical shape versus padded tile grid;
- row-major, tiled, and face-swizzled layouts;
- tilize/untilize at explicit boundaries;
- dtype-dependent tile page bytes;
- `SLICE` and view offsets;
- chunked, bank-interleaved transfers;
- reclaimable DRAM allocation.

**You learn:** which Tensor movements are metadata-only, when a physical layout
conversion is unavoidable, and how rangeified indexes relate to tile addresses.

**Done when:** randomized shapes including tails round-trip; view/slice aliases
write the expected parent bytes; layout is in every relevant program/cache key;
no allocator code needs the original Tensor object to guess its shape.

## 11. Preserve and lower a reduction

**Level:** advanced compiler/hardware

Intercept before generic `pm_reduce_local`. Start with last-axis sum over complete
tiles on one core, then max, padding identities, multiple tiles, and cross-core
staging.

The plan should explicitly state:

- accumulation dtype;
- within-tile and across-tile phases;
- Dst/L1 residency;
- identity for invalid lanes;
- synchronization and output layout.

**You learn:** reduction ranges, invalid predicates, SFPU/FPU reduction paths,
accumulation accuracy, and hierarchical scheduling.

**Done when:** randomized numerical tests cover positive/negative values,
non-multiple tails, NaN policy where applicable, and fp32 versus bf16
accumulation. The raw `REDUCE` must be visible in a checked-in lowering fixture.

## 12. Tile matmul and fused epilogues

**Level:** advanced compiler/hardware

Recognize matmul before GPU `WMMA` selection and lower to a Tensix tile plan.
Begin one core with padded M/N/K; then block K, choose Dst capacity from
accumulation dtype, add multicore tile partitioning, and finally 1D/2D multicast.

Fuse one SFPU epilogue while the output remains in Dst, such as bias + SiLU or a
residual add. This demonstrates the architectural reason for an earlier TT
handoff rather than merely matching GPU-like UOps late.

**You learn:** reduction-of-products recognition, FPU fidelity phases, Dst
double buffering, CB depth, NoC traffic, multicast rectangle constraints, and
the interaction of compiler schedule with measured performance.

**Done when:** a slow, obviously correct one-core baseline and an optimized plan
share the same semantic matcher; output is tested across edge shapes/dtypes;
performance reports separate compute, NoC, and dispatch time.

## 13. Semantic patterns: RMSNorm, softmax, and attention

**Level:** research compiler

At the callified/pre-split graph, add conservative patterns that produce a
tile-native plan with an explicit ordinary-tinygrad fallback. Recommended order:

1. RMSNorm;
2. stable row softmax;
3. matmul + epilogue;
4. QK → mask → softmax → PV;
5. KV-cache update and read.

Treat `blackhole-py/TTIR.md` as a design specification, not implemented code.
Its `Tile`, `Tensor`, `Stream`, capacity, wait, and configuration-state concepts
are useful target abstractions.

**Done when:** every matcher has positive and near-miss tests; layout/dtype/shape
guards are explicit; fallback produces the same result; a graph fixture proves
the semantic region is recognized before the ordinary scheduler fragments it.

## 14. P150 multi-card and tinygrad `MULTI`

**Level:** research/distributed systems

Only after single-device P150 works, connect tinygrad sharding/allreduce to
ERISC/fabric transport:

- peer buffer identity and addressability;
- topology discovery and routing;
- remote program/dispatch path;
- broadcast, all-gather, reduce-scatter, and allreduce;
- timeline/failure semantics across devices;
- placement-aware `MSELECT`, `MSTACK`, `MULTI`, and `ALLREDUCE` lowering.

**You learn:** tinygrad's multi-device graph, command dependency scheduling,
TT-Fabric, and when a collective is a compiler op versus a runtime program.

**Done when:** start with a two-device deterministic copy/allreduce test and
fault/time-out behavior. Model-scale benchmarks come later.

## Patch hygiene for tinygrad

For an upstream-oriented patch:

- pin the tinygrad commit in benchmarks and graph fixtures;
- make one compiler claim per patch;
- add the smallest reproducer before changing a matcher;
- test numeric behavior and graph structure only where structure is the API;
- report compile time separately from kernel time;
- run with multiple `DEBUG`, `SPEC`, and optimization settings relevant to the
  change;
- inspect matcher order when composing with `+`;
- avoid retaining UOps accidentally in a global benchmark cache;
- include a scaling table for complexity fixes, not a single before/after time;
- expect internal APIs to move and rebase small patches quickly.

For Blackhole work, keep three layers independently testable: board/runtime,
tile program generation, and tinygrad graph lowering. That separation lets you
learn and land useful patches even while the full backend is incomplete.
