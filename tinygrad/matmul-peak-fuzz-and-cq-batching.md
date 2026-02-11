# blackhole-py matmul_peak fuzzing + CQ batching stress (2026-02-10)

## Goal
Measure `examples/matmul_peak.py` crash behavior under repeated runs and under large CQ batching depth, then record reproducible thresholds.

## Repo + workspace
- Repo: `~/tenstorrent/blackhole-py`
- Workspace used for fuzz knobs: `~/jj-workspaces/blackhole-py/fuzzing`
- Script under test: `examples/matmul_peak.py` (non-f32-acc variant)

## Device safety rules used
- All device commands serialized with lock:
  - `flock /tmp/tt-device.lock ...`
- Device reset between stress phases (and between CQ boundary attempts):
  - `flock /tmp/tt-device.lock ~/tenstorrent/.venv/bin/tt-smi -r`
- No concurrent device users.

## Test methodology
### 1) Restart fuzzing (process-level stability)
- Run many fresh Python process invocations of `matmul_peak.py`.
- Use short per-run profile for crash hunting:
  - `MATMUL_PEAK_WARMUP_ITERS=0`
  - `MATMUL_PEAK_TIMED_ITERS=1`
  - `MATMUL_PEAK_SKIP_VALIDATION=1`
- Randomize seeds per run (`MATMUL_PEAK_SEED_A/B`) to vary input payloads.
- Apply hard timeout per run.
- Run sequentially only.

### 2) Slow-dispatch drift check
- Same process-level harness but with `TT_SLOW_DISPATCH=1`.
- Compute trend stats on TFLOPS over run index:
  - mean/stddev
  - first-10 vs last-10 means
  - linear slope vs run index

### 3) CQ batching stress (single process, repeated `device.run` before sync)
- Sweep `MATMUL_PEAK_TIMED_ITERS` upward to increase outstanding run count before `device.sync()`.
- Use `MATMUL_PEAK_WARMUP_ITERS=0`, `MATMUL_PEAK_SKIP_VALIDATION=1`.
- First coarse powers-of-two / bracket sweep, then refined depth sweep.
- Reset device before each depth attempt to avoid contamination from prior CQ failures.

## Commands (repro)
Run from `~/jj-workspaces/blackhole-py/fuzzing`.

### A) Fast sanity
```bash
flock /tmp/tt-device.lock env MATMUL_PEAK_WARMUP_ITERS=0 MATMUL_PEAK_TIMED_ITERS=1 MATMUL_PEAK_SKIP_VALIDATION=1 \
  python3 examples/matmul_peak.py
```

### B) Slow sanity
```bash
flock /tmp/tt-device.lock env TT_SLOW_DISPATCH=1 MATMUL_PEAK_WARMUP_ITERS=0 MATMUL_PEAK_TIMED_ITERS=1 MATMUL_PEAK_SKIP_VALIDATION=1 \
  python3 examples/matmul_peak.py
```

### C) Restart fuzz loop skeleton
```bash
for i in $(seq 1 100); do
  A=$RANDOM$RANDOM
  B=$RANDOM$RANDOM
  timeout 240s flock /tmp/tt-device.lock env \
    MATMUL_PEAK_WARMUP_ITERS=0 MATMUL_PEAK_TIMED_ITERS=1 MATMUL_PEAK_SKIP_VALIDATION=1 \
    MATMUL_PEAK_SEED_A=$A MATMUL_PEAK_SEED_B=$B \
    python3 examples/matmul_peak.py || break
done
```

### D) Slow-dispatch fuzz loop skeleton
```bash
for i in $(seq 1 100); do
  A=$RANDOM$RANDOM
  B=$RANDOM$RANDOM
  timeout 240s flock /tmp/tt-device.lock env \
    TT_SLOW_DISPATCH=1 MATMUL_PEAK_WARMUP_ITERS=0 MATMUL_PEAK_TIMED_ITERS=1 MATMUL_PEAK_SKIP_VALIDATION=1 \
    MATMUL_PEAK_SEED_A=$A MATMUL_PEAK_SEED_B=$B \
    python3 examples/matmul_peak.py || break
done
```

### E) CQ threshold sweep (reset before each depth)
```bash
for d in 297 298 299 300 301 302 303; do
  flock /tmp/tt-device.lock ~/tenstorrent/.venv/bin/tt-smi -r
  timeout 240s flock /tmp/tt-device.lock env \
    MATMUL_PEAK_WARMUP_ITERS=0 MATMUL_PEAK_TIMED_ITERS=$d MATMUL_PEAK_SKIP_VALIDATION=1 \
    python3 examples/matmul_peak.py && echo "PASS depth=$d" || echo "FAIL depth=$d"
done
```

## Log snippets
### CQ pass near peak throughput
```text
PASS depth=301 tflops=219.74
```

### CQ first failing depth
```text
FAIL depth=302 rc=1
TimeoutError: timeout waiting for CQ host completion event
```

### Deeper CQ failures
```text
FAIL depth=303 rc=1
TimeoutError: timeout waiting for prefetch queue slot
```

## Results
### Restart fuzzing
- Fast dispatch (`timed_iters=1`):
  - completed runs: `143`
  - crashes: `0`
  - TFLOPS mean/stddev: `91.81 / 2.39`
  - first-10 vs last-10: `91.92 -> 92.06` (no degradation)
- Slow dispatch (`timed_iters=1`):
  - completed runs: `98`
  - crashes: `0`
  - TFLOPS mean/stddev: `69.24 / 1.15`
  - first-10 vs last-10: `69.64 -> 68.93` (small drift, no collapse)

### CQ batching stress (`timed_iters = batched run count before sync`)
- Peak region reached as expected: `~219.5 - 219.7 TFLOPS`.
- Stable pass up to `301` batched runs.
- Failure starts at `302` batched runs.
- `303+` generally fails faster with prefetch-queue-slot timeout.

## Practical takeaway for tinygrad-style graphs
- This is **not** a global "302 ops" limit.
- It is a limit for this specific heavy `matmul_peak` workload shape and CQ record footprint.
- Conservative runtime policy: insert a drain/sync at or before ~`256` heavy outstanding workloads.

## Raw log directories from this run
- `/tmp/matmul_peak_fuzz_20260210_114653`
- `/tmp/matmul_peak_fuzz_20260210_115429`
- `/tmp/matmul_peak_cq_probe_20260210_120001`
- `/tmp/matmul_peak_cq_refine_20260210_120151`
- `/tmp/matmul_peak_cq_threshold_20260210_120335`
