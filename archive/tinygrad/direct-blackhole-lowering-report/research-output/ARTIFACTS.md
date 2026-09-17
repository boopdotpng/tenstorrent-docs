# Investigation artifacts

All paths below are relative to the extracted bundle root. Every experiment was host-only. No Tenstorrent device execution or internet access was used.

## Primary deliverables

- `research-output/technical-report.md` — the 13-section technical report requested by the root `README.md`. It contains 353 path-and-line references across 69 bundle files.
- `research-output/report-validation.out` — structural and citation validation: all 13 sections present, no missing cited files, no invalid line ranges, no absolute-path leakage, balanced Markdown fences.
- `research-output/validate_report.py` — rerunnable validator used to produce the preceding output.

## Source/corpus experiments

- `research-output/corpus_inventory.py` and `research-output/corpus_inventory.out` — reads the pre-generated stable JSONL/call ABI and inventories final calls for `matmul_epilogue`, `rmsnorm`, `sdpa_gqa_decode`, `kv_cache_update_symbolic`, and `llama32_1b_block_decode`. This is the source of the 1/2/4/1/14 call counts and per-call operation/parameter summaries.
- `research-output/fusion_boundary_experiment.py` and `research-output/fusion_boundary_experiment.out` — constructs lazy `PYTHON`-device graphs, never realizes tensors, and independently toggles the two explicit FFN `CONTIGUOUS` sites. Removing the gate temporary changes the block from 14 calls to 13; removing only the outer output `contiguous()` does not.
- `research-output/add1_host_lowering.out` — host lowering of `blackhole-py-rewrite/examples/add1.py` without `--run`; records cores, CBs, parameter slots, and all five role-image sizes.

## UOp regeneration

- `research-output/regenerated-uops-full/` — full canonical-order regeneration of every probe using the bundled Tinygrad and `PYTHON` device.
- `research-output/uop_renderer_neutral_regeneration.out` — byte comparison for renderer-neutral stages 00–50 plus call ABI on the five central probes. All compared files are byte-identical. Stages 60/70 are deliberately excluded because they are late Python-renderer negative examples.
- `research-output/uop_full_regeneration_compare.out` — unfiltered full-tree comparison. It shows late Python-renderer stages may differ even when renderer-neutral evidence and the full Llama probe are stable.
- `research-output/regenerated-uops/` and `research-output/uop_regeneration_compare.out` — exploratory subset regeneration. It exposed process-global buffer-ID sensitivity when probes are generated in a different subset/order; this output is retained as a reproducibility warning, not used as semantic evidence.

Canonical full regeneration from the bundle root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONHASHSEED=0 \
  python3 uop-dumps/generate_uop_dumps.py \
  --output research-output/regenerated-uops-full
```

## Experimental patches

- `research-output/architecture_hook.diff` — generic Tinygrad post-callify graph-lowering hook. It adds `tinygrad/tinygrad/schedule/backend.py`, changes only `lower_sink_to_linear`, and adds focused tests.
- `research-output/architecture_hook_test.out` — four dedicated hook tests passing.
- `research-output/architecture_hook_selected_regression.out` — six selected assignment, `AFTER`/`STORE`, precompiled/multi-output, and custom-kernel regressions passing. This is not a claim that the entire Tinygrad test suite passed.
- `research-output/first_patch.diff` — `blackhole-py-rewrite/program.py::Program.bind` ABI hardening plus four tests.
- `research-output/first_patch_test.out` — all four binding tests passing.
- `research-output/patch_dry_run.out` — both diffs apply cleanly, in dry-run mode, to the captured source trees.

These are experimental diffs against copies of the snapshot. They were not committed to the bundled projects.

## Re-running the focused host tests

After applying `architecture_hook.diff` to a disposable copy of the bundle root:

```bash
cd tinygrad
PYTHONDONTWRITEBYTECODE=1 PYTHONHASHSEED=0 \
  python3 -m unittest -v test.unit.test_backend_graph_lowerer
```

After applying `first_patch.diff` inside a disposable copy of `blackhole-py-rewrite`:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONHASHSEED=0 \
  python3 -m unittest -v tests.test_program_bind
```

Host-only add1 lowering:

```bash
python3 blackhole-py-rewrite/examples/add1.py
```

Fusion-boundary experiment:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONHASHSEED=0 \
  python3 research-output/fusion_boundary_experiment.py
```

Report validation:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 research-output/validate_report.py
```

## Limits

The bundle explicitly omits TT-Metal, TT-LLK, and referenced historical branch/stash material. No silicon behavior, numerical accuracy, performance, firmware compatibility, or external document claim was independently verified. The report labels implementation, host experiment, proposal, historical evidence, inference, and unverified claims separately.
