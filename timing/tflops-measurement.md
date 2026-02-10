# TFLOPS Measurement: tt-metal vs blackhole-py

## tt-metal approach

Outer wall-clock timing around a pipelined batch of iterations.

```cpp
// 3 warmup, then:
auto t0 = std::chrono::high_resolution_clock::now();
for (int i = 0; i < 10; i++) {
    distributed::EnqueueMeshWorkload(cq, workload, false);  // non-blocking enqueue
}
distributed::Finish(cq);  // single sync at the END
auto t1 = std::chrono::high_resolution_clock::now();
elapsed_s = (t1 - t0) / TIMED_ITERS;
```

Key details:
- **10 timed iterations** after 3 warmup
- All 10 enqueues happen without synchronization — they pipeline through the CQ
- **Single `Finish()` at the end** — one host-device sync for the whole batch
- Dispatch overhead amortized across iterations
- TFLOPS = `2 * M * N * K / elapsed_s / 1e12`

tt-metal also has a device-side profiler (`TT_METAL_DEVICE_PROFILER=1`) that reads hardware wall clock registers (`RISCV_DEBUG_REG_WALL_CLOCK_L/H`) for cycle-accurate kernel timing, but the standard benchmarks use host-side wall clock.

## blackhole-py approach (current)

```python
for _ in range(TIMED_ITERS):   # TIMED_ITERS = 1
    total, dispatch = device.run(program)  # blocks until done
```

## Problems with blackhole-py timing

### 1. Single sample (`TIMED_ITERS = 1`)

tt-metal uses 10. One iteration gives a noisy single sample with no averaging.

### 2. Each `run()` blocks synchronously

Every iteration does: enqueue -> **block until complete** -> return. No pipelining. The "compute" measurement includes:
- CQ prefetch consuming entries
- Dispatch firmware executing commands
- GO signal delivery latency
- Worker execution
- Stream 48 completion notifications
- HOST_EVENT write + host poll latency

### 3. The dispatch/compute split is misleading

`dispatch` time = Python time to call `enqueue_*()` (pushing entries into prefetch queue). The actual dispatch firmware execution (consuming entries, issuing NOC writes, sending GO) happens **during "compute" time**. So "compute TFLOPS" still includes all real dispatch overhead.

In `SlowDevice.run()`, it's worse — "compute" includes sequentially polling each of 118 cores via separate TLB reconfigurations. That polling loop alone adds significant latency.

## What accurate measurement looks like

Ideal (requires async refactor):
```python
t0 = time.perf_counter()
for _ in range(N):
    device.run_async(program)  # enqueue without blocking
device.sync()                  # one sync at the end
elapsed = (time.perf_counter() - t0) / N
```

Practical fixes without refactoring `run()`:
1. **Increase `TIMED_ITERS` to >= 10** — averaging reduces noise even with per-iteration sync
2. **Only trust `wall` timing** — the dispatch/compute split is not meaningful
3. For real pipelined numbers, `FastDevice.run()` needs to be split into enqueue + sync
