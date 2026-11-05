# Documentation maintenance

This pass inventories the Markdown collection, separates current entry points
from dated software studies, and rewrites the main hardware/runtime onboarding
against the local blackhole-py source and reviewed tests. It is not a claim that
every instruction model or historical benchmark was independently revalidated.

The website builds its categorized catalogue from the files on disk. There is
no second hand-maintained list to go stale. The
[relocation manifest](relocations.json) maps old paths to replacements;
[the consolidation manifest](consolidation.json) records this pass. Git history
retains removed versions.

## November 2026 pass

- Moved every prose doc out of blackhole-py into `blackhole-py/`, `measurements/`,
  `matmul/results/`, `timing/` and `hardware/fp8-and-fp4.md`. Merged the four ISA
  suite pages into one. Dropped the generated `audit.md`, `coverage.md`,
  `modifiers.md` and `tensix_timing.md` tables, since the `/isa` page renders the
  same JSON. Also dropped the stale 2026-09-16 coverage audit.
- Moved `microbenching/timing-reference` to `timing/`. Moved the rest of
  `microbenching/`, plus `llk-sfpi/` and `disasms/`, into `archive/`. Deleted 127
  microbench scripts that imported modules removed from blackhole-py.
- Corrected the packer L1-accumulation Float16 "hardware bug". It was a
  TT-Metal compiler bug, fixed by direct RISC-V kernels. Reviewed other
  hardware-bug claims and corrected them; the results are in
  [known issues](../kernel-dev/known-issues.md).
- `relocations.json` maps every moved path.

## Consolidation and corrections

The active collection was 142 pages before consolidation and reclassification.
The active collection is now 90 pages. This pass deletes 62 former files and
adds 13 consolidated guides, a net reduction of 49 Markdown files. Other merges
expand existing guides instead of adding files. Related compiler exercises now accompany
their explanations. Emulator frontend, synchronization, configuration, networking,
boot, and topology models are grouped into coherent chapters; large arithmetic
and pack/unpack references remain separate.

Rewritten guides cover host transfers, worker placement, dataflow, SFPI,
compute scheduling, TT-Metal build/loading, and multicast tradeoffs. They remove
unsupported fixed arity limits, universal multicast/compute-bound claims,
misleading FPU/SFPU serialization claims, and the suggestion that concatenating
unmodified ELF segments implements XIP relocation. Reduction padding now calls
out NaN/infinity behavior under a zero mask. The matmul guide collects the
reviewed precision, row-major, and fusion evidence and corrects fidelity and
replay-capacity overclaims.

Historical benchmarks, instruction-frequency surveys, and the old Float16
packer report belong to Archives. They remain evidence of their recorded runs,
not current runtime instructions. Board firmware is categorized separately from
worker boot; compiler projects and emulator models have distinct navigation.
The ISA reference has its own `/isa` page and instruction sidebar.

## Changes

- Rewrote the introduction, architecture, worker placement, matmul walkthrough,
  and accumulation guidance; added a current runtime map, row-major matmul
  explanation, and a test-to-claim evidence guide.
- Moved May/July tinygrad guides and probes, the direct-lowering investigation,
  retired blackhole-py CQ notes, and historical matmul records into `archive/`.
  The archive retains raw experimental outputs rather than treating them as
  current implementation instructions.
- Removed the obsolete tilize-fusion reminder and fixed-grid autogenerator
  plan; linked their current replacements.
- Added topic indexes and clarified the TT-Metal/LLK scope of older kernel,
  build, dispatch, and firmware material. Removed unsupported instruction
  deletion advice from the workload-frequency report.
- Added `./serve.sh`: an offline docs website with full-text search and a
  separate 137-instruction ISA reference. It imports the new September 17
  blackhole-py timing catalogue with its evidence labels intact.

## Evidence and limits

[Source fingerprints](blackhole-py-sources.json) identify the initial hardware
review. The [viewer snapshot](../viewer/data/instructions.json) separately records
updated timing/audit inputs, hashes, source status, and recorded outcomes.
The current blackhole-py tree includes uncommitted/untracked work; its baseline
commit alone is insufficient to reproduce the complete snapshot.

The offline encoder checks passed: 23,211 cases. No hardware tests were rerun
for this documentation edit. Hardware pass counts and timing samples are
attributed to retained blackhole-py evidence. The viewer has offline HTTP/data
checks and was exercised in Chromium at desktop and mobile widths, including
search and source navigation.

The compiler maps retain their own pinned revisions and validation statements.
The emulator documents are detailed source-derived models, not an independently
validated emulator. Historical measurement tables retain their reported scope.
Consolidation preserves the scope of retained source models; it does not
independently validate every numerical edge case or historical measurement.

`human/` remains untouched. The pre-existing timing-reference work and unrelated
working-tree edits were preserved separately from these commits.
