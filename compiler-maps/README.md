# Compiler source maps

Start with [From an array expression to a running program](first-principles.md).
It builds from a numerical RMSNorm example to graphs, memory, rewrite rules,
kernels, and execution. Basic Python and arrays are enough to begin.

Then choose one path:

1. **Understand tinygrad:** read [the module map](tinygrad/module-map.md), then
   [UOps and rewrite passes](tinygrad/uops-and-rewrites.md). Follow the
   [RMSNorm case study](tinygrad/rmsnorm-kernel-fusion.md) to see how the graph
   becomes scheduled kernels and generated code.
2. **Understand MLIR:** read [why the pieces exist](mlir/README.md), then its
   [RMSNorm lowering](mlir/rmsnorm-kernel-fusion.md). Continue to IREE or TT-MLIR
   to see how a concrete compiler uses that infrastructure.
3. **Understand PyTorch:** start with [eager execution](pytorch/eager-execution.md),
   then [torch.compile](pytorch/torch-compile.md) and
   [Inductor](pytorch/inductor-and-fusion.md). The
   [executed RMSNorm study](pytorch/rmsnorm-eager-vs-compile.md) connects those layers.

After following one path, read [the design comparison](design-comparison.md).
Use the individual matcher catalogues as references when a particular rule
needs explanation. You do not need to read hundreds of rules before the
execution story makes sense. Each exercise bank includes worked solutions.

## What is here

| Map | Questions it answers | Exercise bank and worked solutions |
| --- | --- | --- |
| [tinygrad modules](tinygrad/module-map.md) | How do Tensor, scheduling, codegen, execution, devices, and tooling fit together? What does each package module own? | [Module exercises](tinygrad/module-exercises.md) |
| [tinygrad UOps and matchers](tinygrad/uops-and-rewrites.md) | What does a UOp mean at each phase? Why are matchers separate? Which rewrite ordering and typing assumptions matter? | [Rewrite exercises](tinygrad/rewrites-exercises.md) |
| [Every production matcher rule](tinygrad/rules/README.md) | What does each rule match and produce, why is it needed, and what is a concrete example? | Individual examples, guards, and sharp edges for 926 source templates |
| [AMD](tinygrad/amd-pattern-matchers.md) and [IMAGE](tinygrad/image-pattern-matchers.md) | Which rules are chip-specific, which adapt compiler/storage contracts, and which are workarounds? | Chip-fragment probes, image-mask probes, and worked exercises |
| [tinycorp direction](tinygrad/meeting-direction.md) | What changed, what is still a proposal, and where do meeting statements disagree with this checkout? | Source-comparison questions in the guide |
| [MLIR](mlir/README.md) | Why dialects, interfaces, regions, conversion, bufferization, and the Transform dialect? Where should I start reading? | [MLIR exercises](mlir/exercises.md) |
| [IREE](iree/README.md) | How does an MLIR-based compiler become a deployable runtime? Why Flow, Stream, HAL, and VM? | [IREE exercises](iree/exercises.md) |
| [TT-MLIR](tt-mlir/README.md) | How do tensor semantics turn into Tenstorrent library calls or lower-level hardware programs? | [TT-MLIR exercises](tt-mlir/exercises.md) |
| [PyTorch eager and torch.compile](pytorch/README.md) | How do runtime dispatch, autograd, guarded graph capture, AOTAutograd, and Inductor differ from tinygrad? | Module, eager, capture, and Inductor exercises; executed CPU case studies |

## Source snapshots, not a claim about today's upstream

Prepared September 17, 2026. All primary mapped checkouts were updated to their
latest official upstream default branches before final source validation.
IREE and PyTorch were missing; each was cloned from its official repository
with `git clone --depth=1`.
MLIR is part of LLVM, not a separate repository to clone per dialect.

| Source | Local checkout | HEAD used |
| --- | --- | --- |
| tinygrad | `../../tinygrad`, branch `master` | `107adc31701df0247dfa45e175984df906a68b53` |
| MLIR (primary) | `/home/boop/builds/llvm-project/mlir` | `e3c4c16567e3074dcd42da664fcb91298fd8c0fb` |
| IREE | `../../iree` | `2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d` |
| TT-MLIR | `../../tt-mlir` | `33e83a87d335d9f6b6cb066384230382f8a3cd38` |
| PyTorch | `../../pytorch`, branch `main` | `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df` |
| Meeting archive | `../../tinycorp-meetings` | `3779da62412b18e14027489990f77c3ce7122834` |
| LLVM nested in TT-Lang (secondary inventory) | `../../tt-lang/third-party/llvm-project/mlir` (dependency snapshot, unchanged) | `37aca9d384347f4f965fa137b0f5463156ba590f` |

Tinygrad was fetched from `https://github.com/tinygrad/tinygrad.git`, since its
configured `origin` is a personal fork. LLVM, IREE, and TT-MLIR use `main` rather
than `master`. LLVM's previous local `main` is preserved as
`main-before-compiler-map-20260917`; its release branch also remains. The nested
TT-Lang LLVM dependency is an auxiliary inventory, not the primary MLIR map, and
was left at its pinned version.

The paths above are relative to this directory unless absolute. The MLIR
checkouts are different revisions; examples from one must not be assumed to
work unchanged in the other. IREE's third-party dependencies were not recursively
cloned, and these documents do not claim a working IREE or TT-MLIR build.

Tinygrad was switched from `blackhole` to `master`, then fast-forwarded to official upstream master on request.
Uncommitted Blackhole work, including untracked files, was preserved in the stash
named `boop compiler map: preserve Blackhole changes before switching to master`.
The new map excludes that work. The older [tinygrad notes](../tinygrad/README.md)
remain useful historical investigations, but their July UOp schema and compiler
phase descriptions should not be treated as this September snapshot.

## Coverage and evidence

The prose maps production modules and selected important dialects, with deeper
inspection of compiler boundaries and rewrite rules. Generated bindings, tests,
examples, and supporting tools are grouped where appropriate. This is not a
claim that every implementation line or every backend has been audited.

[The manifest](inventory/manifest.json) records revisions, scope, dirty status,
and file counts. The accompanying TSVs enumerate every Git tree entry in that
scope with its blob identity: [tinygrad](inventory/tinygrad.tsv),
[MLIR](inventory/mlir.tsv), [IREE](inventory/iree.tsv),
[TT-MLIR](inventory/tt-mlir.tsv), [meetings](inventory/tinycorp-meetings.tsv),
[PyTorch](inventory/pytorch.tsv), and [TT-Lang's MLIR](inventory/tt-lang-llvm.tsv).
An inventory entry establishes inclusion in the source snapshot, not a claim
of individual review. Source remains in its checkout rather than being copied
into a second enormous text dump.

The guides separate source behavior from inferred design rationale and future
plans. Tests cited as reading material are not automatically tests run during
this task. Exercises distinguish source-only work, runnable probes, and commands
requiring a built toolchain. See each guide's validation notes for actual results.

Regenerate inventory after an intentional source update:

```sh
python3 boop-docs/compiler-maps/snapshot.py
# Override checkout locations when using another machine:
python3 boop-docs/compiler-maps/snapshot.py --workspace /path/to/workspace --llvm /path/to/llvm-project
```

This refreshes inventory only; it does not revalidate the prose. The script
records HEAD blobs and separately reports worktree changes. Source links point
to local checkouts, so line anchors can drift after updates.

## RMSNorm and fusion across kernel boundaries

The advanced examples trace `y = x * rsqrt(mean(x*x) + eps) * weight`,
including residual producers, reduction boundaries, materialized intermediates,
and consumers. They distinguish fusing arithmetic inside an existing kernel
from changing which kernels exist and what crosses their boundaries.

- [tinygrad: executed schedules and numerical checks](tinygrad/rmsnorm-kernel-fusion.md).
- [MLIR: structured fusion, storage, and launch boundaries](mlir/rmsnorm-kernel-fusion.md).
- [IREE: dispatch formation and reduction fusion](iree/rmsnorm-kernel-fusion.md).
- [TT-MLIR: single-core and three-kernel distributed RMSNorm](tt-mlir/rmsnorm-kernel-fusion.md).
- [PyTorch: eager versus compiled CPU execution](pytorch/rmsnorm-eager-vs-compile.md).

[The tinygrad matcher census](tinygrad/matcher-inventory.md) complements these
case studies with constructor and rewrite-driver locations.

## Validation performed

- Tinygrad rewrite machinery: **53 passed, 1 skipped** on the updated master;
  the worked matcher probe also passed with compiled and interpreted matching.
- Tinygrad RMSNorm: **11 CPU cases, 12 numerical output checks passed** against
  float64 NumPy references. A second run reproduced the summary exactly.
  Captured artifacts include input DAGs, scheduled kernel DAGs, generated C,
  buffer dependencies, and errors; no performance claims are made.
- Six additional tinygrad module probe groups passed on the Python backend.
- PyTorch: **eight CPU execution cases passed**, including eager/compiled
  comparisons, backward gradients, and observable input mutation, plus guard,
  dynamic-shape, graph-break, and fullgraph probes. These ran on the existing
  **2.11.0+cu130 wheel**, not the new main checkout; the
  [case study](pytorch/rmsnorm-eager-vs-compile.md) records both revisions and
  preserves captured FX, scheduler IR, and generated code.
- Source paths and line bounds, Markdown reference labels, inventory revisions,
  and selected core/fusion claims were checked. MLIR, IREE, and TT-MLIR were
  source-reviewed; their toolchain and hardware exercises were not executed.

## A proposed CAIR study sequence

No CAIR syllabus was supplied for this pass. This is an adaptable exercise
sequence, not a claim to match an existing course's units.

1. **Represent a computation.** Read MLIR's IR foundation and tinygrad's UOp
   model. Draw the data dependencies for elementwise addition and a reduction.
   Explain what shape, dtype, and effects information each stage needs.
2. **Make a rewrite correct.** Work the tinygrad matcher exercises and MLIR
   rewrite/conversion exercises. Explain why a syntactic match is insufficient
   without typing, legality, effect, and numerical preconditions.
3. **Choose storage and iteration.** Compare tinygrad scheduling/indexing with
   MLIR tensor bufferization and structured loop lowering. Work an aliasing or
   masked-access counterexample before attempting a speed optimization.
4. **Cross the compiler/runtime boundary.** Follow IREE's dispatch, resource,
   and executable stages, then TT-MLIR's backend routes. Identify which layer
   owns allocation, synchronization, executable loading, and ABI decisions.
5. **Investigate a proposed change.** Pick a meeting claim from the direction
   guide; prove whether it is reflected in this tinygrad snapshot. Propose a
   bounded patch and a regression case using the exercise banks as scaffolding.

For each exercise, require a source citation, the invariant being preserved,
one counterexample, and the worked explanation. Performance claims additionally
need an actual measurement; reading an optimization's name is not evidence of
its benefit on Blackhole.
