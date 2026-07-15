# tinygrad internals and Blackhole notes

These notes explain current tinygrad internals and explore where a
Tenstorrent Blackhole backend should hook into the compiler.

Start here:

- [`internals-guide.md`](internals-guide.md): Tensor-method DAG through
  callify, rangeify, scheduling, codegen, and the current linearizer; also the
  ShapeTracker migration and present compiler rough edges.
- [`uops-reference.md`](uops-reference.md): all 82 current `Ops`, grouped and
  explained by compiler phase.
- [`pattern-matchers-reference.md`](pattern-matchers-reference.md): exhaustive
  production matcher inventory and purpose, with HCQ2/test scopes separated.
- [`blackhole-backend-map.md`](blackhole-backend-map.md): how compiler stages
  and UOps map to P100A/P150 programs, tiles, cores, CBs, NoC, and runtime.
- [`patch-projects.md`](patch-projects.md): a learning and contribution ladder
  from compiler probes through bounded tinygrad patches and backend milestones.
- [`direct-blackhole-lowering-report/`](direct-blackhole-lowering-report/README.md):
  source-snapshot investigation of the post-callify backend seam, with proposed
  architecture, experimental patches, validation logs, and regenerated UOps.

Historical material:

- [`tinygrad-uop-arange-slice-sum-stages.md`](tinygrad-uop-arange-slice-sum-stages.md):
  May 2026 stage trace for `Tensor.arange(100)[45:55].sum()`.
- [`uop-probes/`](uop-probes/README.md): pre-July probe corpus covering
  movement, elementwise, reductions, matmul, conv/pool, effects, and LLM graphs.
- [`llama3-blackhole-backend-plan.md`](llama3-blackhole-backend-plan.md):
  Llama 3.2 1B target plan; compiler-stage details are partly historical.
