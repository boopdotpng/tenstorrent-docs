# tinygrad module exercises and worked solutions

These exercises start from arrays and Python. An **IR** (intermediate representation) records a program as data; tinygrad's **UOp** is one node in that program graph. A **kernel** is a unit of device computation, a **buffer** stores values, and **materialization** produces stored contents for a previously pending value. A **contract** is what one component promises another, such as preserving the order of reads and writes. Use the optional [first-principles primer](../first-principles.md) if those distinctions are unfamiliar. Work the prediction first, then compare both the answer and the reasoning with the solution.

Companion to the [module map](module-map.md). Snapshot: `107adc31701df0247dfa45e175984df906a68b53`, clean upstream master. These focus on module boundaries and runtime contracts; use [UOps and rewrites](uops-and-rewrites.md) for matcher-specific problems.

The short numerical probes in exercises 1–3, 5 and 7 were executed with the workspace `.venv` interpreter and `PYTHONPATH=tinygrad`, using `device="PYTHON"`, on 2026-09-17. Other solutions are source-derived explanations, not claims of executed hardware experiments. Suggested assessment: require the result, the source boundary responsible for it, and a counterexample to an overbroad explanation. No accelerator is required for the executed probes.

From the workspace root, a reproducible harness is:

```bash
PYTHONPATH=tinygrad .venv/bin/python your_exercise.py
```

## 1. Where does a scalar get its dtype? (20 minutes)

A **dtype** specifies how a number is represented. “Weak” means a scalar has not yet forced a concrete width; it does not mean low precision or a missing value. **Promotion** chooses a compatible type when two inputs differ.

**Problem.** Predict the types of `Tensor(3)`, `Tensor([3])`, and `Tensor([1,2], device="PYTHON", dtype=dtypes.int8) + 3`. Explain why a weak scalar is useful. Find the boundary where it must become concrete.

**Worked solution.** The observed reprs are `dtypes.weakint`, `dtypes.int`, and `dtypes.char` respectively (`char` is the int8 alias). Work through the cases in order. The standalone scalar records an integer value without choosing array storage. The list records an array with a concrete element type. In the addition, the existing int8 array provides a concrete type that can accommodate the scalar 3. A scalar can therefore participate in promotion without forcing a small array to the default integer storage type. A list requires actual homogeneous storage, so creation chooses a concrete dtype. `Tensor.linear_with_vars` rejects device-backed weak values at realization; host-data conversion can explicitly commit weak values. Read [`dtype.py`](../../../tinygrad/tinygrad/dtype.py#L167), [`Tensor.__init__`](../../../tinygrad/tinygrad/tensor.py#L278), [`linear_with_vars`](../../../tinygrad/tinygrad/tensor.py#L392), and [`uop/weak.py`](../../../tinygrad/tinygrad/uop/weak.py#L53).

**Counterexample obligation.** “All Python ints are int32” is false here. Large scalar bounds, explicit casts and existing array dtypes change the answer. Do not extrapolate the observed `+3` result to arbitrary scalar magnitudes.

## 2. Is Tensor construction computation? (20 minutes)

**Problem.** For `x = Tensor([1,2,3], device="PYTHON"); y = (x+1).sum()`, distinguish input storage creation, graph construction, scheduling, compilation and execution. Why is calling `schedule_linear()` not a harmless substitute for printing the original graph?

**Worked solution.** List construction brings real input data into a buffer representation. Arithmetic adds UOps. `realize` requests storage for pending outputs; `linear_with_vars` transforms the graph into explicit calls/buffers, updates live tensor mappings and calls the scheduler. `run_linear` compiles, links and dispatches it. Calling `schedule_linear` invokes these scheduling transformations and requires no bound variables; it is not a passive printer of the original expression structure (often called an abstract syntax tree, or AST). Inspect `y.uop` before scheduling if the original tensor graph is the object of study. The simple separate probe `Tensor([1,2,3], device="PYTHON").sum().item()` produced `6`; for the expression in the question the expected result is `9`.

Read [`tensor.py`](../../../tinygrad/tinygrad/tensor.py#L392) and [`run_linear`](../../../tinygrad/tinygrad/engine/realize.py#L299). **Assessment:** reject answers equating “lazy” with “no data has ever been allocated.”

## 3. Assignment through a view (30 minutes)

**Problem.** Predict this result and explain the representation needed to preserve it:

```python
from tinygrad import Tensor
x = Tensor([1, 2, 3, 4], device="PYTHON").realize()
x[1:3].assign(Tensor([9, 8], device="PYTHON"))
print(x.tolist())
```

**Worked solution.** Observed output: `[1, 9, 8, 4]`. The slice maps its positions 0 and 1 to base-array positions 1 and 2. Those positions receive 9 and 8; positions 0 and 3 stay unchanged. The slice and base **alias**, meaning they share storage. The destination is an existing allocation, so assignment is an **effect** (an observable write), represented by `STORE` plus `AFTER`. `AFTER` lets a value carry the dependency that the write must happen before it is used. The view identifies the indexed region, while the base tensor must subsequently observe the store; `_apply_map_to_tensors` embeds that dependency below the views. Replacing a temporary view wrapper alone would leave reads through `x` unaware of the write. [`Tensor.assign`](../../../tinygrad/tinygrad/tensor.py#L428) distinguishes this from initializing a pending value without storage identity.

**Extension and solution.** Why does preparation inspect store hazards? A producer expression may still need an old value that an in-place store overwrites. [`fix_store_hazard`](../../../tinygrad/tinygrad/schedule/prepare.py#L65) preserves that required boundary. An optimizer cannot erase the effect dependency just because the mathematical expressions look equivalent.

## 4. Kernel boundaries are not operator boundaries (35 minutes)

A tensor operation describes a mathematical step such as add or sum. A kernel `SINK` collects the work belonging to one kernel; a scheduled `CALL` represents invoking a body with arguments. **Fusion** combines work in a kernel, potentially eliminating an intermediate write/read. It does not mean merely simplifying `x+0` to `x`.

**Problem.** Design an investigation comparing `(x+1).sum()` with a version that explicitly realizes `x+1` first. What should be recorded, and what conclusion is too strong?

**Worked solution.** Record the tensor graph, scheduled calls, kernel SINKs, and buffer identities. In the explicitly realized variant, the intermediate has already become stored data before the reduction is scheduled. In the combined variant, prepare/indexing/rangeify can consider fusion subject to dependencies, reduction structure, buffer constraints and target optimization. It is reasonable to expect different opportunities, but not to promise one fixed kernel count across all shapes/settings/backends. [`get_kernel_graph`](../../../tinygrad/tinygrad/schedule/rangeify.py#L367) and [`create_schedule`](../../../tinygrad/tinygrad/schedule/__init__.py#L28) are the evidence locations. Keep performance measurement separate from graph-count evidence.

**Rubric.** Full credit requires an explicit materialization boundary and a distinction between a tensor operation, kernel SINK, and scheduled CALL.

## 5. Differentiate the graph, not the host result (25 minutes)

**Problem.** Compute the gradient of `sum(x*x)` at `[2,3]`. Where does automatic differentiation happen? Why would replacing the expression with its Python `.item()` value destroy the relevant graph path?

```python
x = Tensor([2., 3.], device="PYTHON")
y = (x*x).sum()
y.backward()
print(x.grad.tolist())
```

**Worked solution.** Observed output is `[4.0, 6.0]`. For one element, write the product as `a*b` with both inputs equal to `x`. The derivative contributed through `a` is `b=x`; through `b` it is `a=x`. Adding both paths gives `2*x`, hence `[4,6]`. The sum sends a derivative of 1 to each product. The reverse traversal applies these derivative rules to UOps, accumulating both uses of `x`. [`compute_gradient`](../../../tinygrad/tinygrad/mixin/gradient.py#L132) handles traversal; reduction/broadcast rules restore the proper input shape. A Python float carries a value but no connection to the original UOp graph. Constructing a new Tensor from that number does not recreate the lost dependence.

**Extension.** For `x.shape=(2,3)` and broadcast bias `b.shape=(3,)`, the bias gradient must sum the upstream gradient over the leading axis. Returning the unreduced `(2,3)` gradient violates the input contract.

## 6. Reuse memory without overwriting a live value (35 minutes)

A value is **live** while a later call still needs it. A **held** buffer has an ownership reason to remain outside temporary reuse. An **arena** is a larger allocation from which the planner assigns byte ranges; sharing an offset means using the same bytes at different times.

**Problem.** Consider three equal-size temporary buffers: A used by calls 0 and 1, B by calls 1 and 2, C by calls 2 and 3. All are compute-only, same device, unheld. Which can share storage? Then explain why applying the same reasoning blindly to a copy buffer is unsafe.

**Worked solution.** A and C may reuse an offset because A's last use is call 1 and C's first is call 2. At call 0 only A is needed; at call 1 both A and B are needed; at call 2 both B and C are needed; at call 3 only C is needed. Thus A/B overlap at call 1; B/C overlap at call 2. Equal size alone is insufficient: overlap determines whether reusing bytes would destroy a needed value. `_collect_bufs` and `memory_plan_rewrite` derive first/last appearances from scheduled call arguments.

Free events occur at `last+1`; at a shared event time, free sorts before allocate. Allocations are rounded to 256-byte blocks and mapped into a byte arena via views/bitcasts. Exact offsets depend on allocation ordering and allocator state, so they are not part of the answer.

Copies have separate arena lanes and an additional hold based on their appearance interval. This avoids turning storage reuse into unwanted copy/compute dependencies. Held buffers are excluded; DISK, CL and WEBGPU are excluded by `_can_plan`. These restrictions live in [`schedule/memory.py`](../../../tinygrad/tinygrad/schedule/memory.py#L12). **Assessment:** a correct answer distinguishes semantic liveness from a claim about simultaneous hardware execution.

## 7. What exactly does TinyJit replay? (30 minutes)

**JIT** means just-in-time compilation. Here, **warmup** runs the function normally, **capture** records executable work, and **replay** runs that work again with compatible new inputs. “Compatible metadata” concerns properties such as shape and type, rather than requiring identical input numbers.

**Problem.** Predict three calls and identify the warmup, capture and replay phases:

```python
from tinygrad import Tensor, TinyJit
@TinyJit
def f(x):
  return (x+1).realize()
for i in range(3):
  print(f(Tensor([i, i+1], device="PYTHON")).tolist())
```

**Worked solution.** Observed outputs are `[1,2]`, `[2,3]`, `[3,4]`. The first call runs normally. The second captures schedules and lowers/links the combined work. The third replays with new input buffers and compatible metadata. This is executable work reuse; it does not mean arbitrary Python control flow is rerun with fresh scalar values. The output `.tolist()` is outside the decorated function and therefore outside capture.

[`_TinyJit.__call__`](../../../tinygrad/tinygrad/engine/jit.py#L236) checks names and input metadata on replay. [`Tensor._buffer`](../../../tinygrad/tinygrad/tensor.py#L474) rejects host data access during capture by default because the value would be baked in. **Extension and solution:** branching on `x.item()` inside the function is not safe dynamic graph control flow; use graph-level operations or deliberately separate such host decisions from capture.

## 8. Function graph versus JIT capture (30 minutes)

**Problem.** Explain why `@function` and `@TinyJit` are not interchangeable. What happens if a function closes over a stored weight but does not declare implicit capture acceptable?

**Worked solution.** `function` runs Python to construct a graph, collects explicit tensor/UOp inputs, substitutes `PARAM`s (named input slots), discovers implicit buffer inputs and creates a `CALL` with output semantics. A closure capture here is a buffer referenced from surrounding Python scope rather than passed as a declared argument. By default `allow_implicit=False`, so remaining captured buffers cause an error. Optional precompilation and custom gradients belong to this call boundary. TinyJit instead captures realized schedules and replays executable work after its warmup/capture phases. See [`function._function`](../../../tinygrad/tinygrad/function.py#L34) and [`engine/jit.py`](../../../tinygrad/tinygrad/engine/jit.py#L214).

**Design answer.** Passing weights as explicit parameters makes dependencies reviewable and helps avoid accidentally freezing/capturing unrelated storage. Allowing implicit capture is an explicit choice, not proof that any Python object in a closure participates correctly.

## 9. Sharded reductions require communication (35 minutes)

**Sharding** divides an array among devices. An **allreduce** combines their local partial results and distributes the combined result to participants. For a matrix split by rows, summing columns within each row is local; summing rows combines contributions from different devices.

**Problem.** A tensor is sharded along an axis. Compare reducing an unsharded axis with reducing the sharded axis. Why is “run the same reduction on each device” incomplete?

**Worked solution.** Reducing an unsharded axis can preserve per-shard independence and update the remaining sharding axes. Reducing the sharded axis combines values owned by different devices, so local partial reductions must feed an allreduce. [`reduce_multi`](../../../tinygrad/tinygrad/schedule/multi.py#L107) performs that distinction and rejects partial allreduce when some multi-axis sharding remains. [`handle_allreduce`](../../../tinygrad/tinygrad/schedule/allreduce.py#L6) chooses naive/ring/all-to-all based on concrete shape, thresholds/settings and device count.

**Counterexample.** Splitting `[1,2,3,4]` into `[1,2]` and `[3,4]` gives local sums 3 and 7, not the global sum 10. Communication is part of semantics; choosing a ring is a performance policy layered on top.

## 10. Write the contract for a new backend (45 minutes)

**Problem.** A renderer emits correct arithmetic for one simple kernel. Enumerate the remaining obligations before claiming a usable backend. Distinguish numerical correctness from runtime correctness.

**Worked solution.** The renderer must accurately advertise launch dimensions, local/shared storage, dtype and instruction capabilities. The compiler must produce a binary in the loader's format. The allocator must provide aligned storage, legal views/offsets, copies, maps where supported and correct lifetime. Program launch must pack buffers/scalars and launch dimensions according to the ABI (the agreed binary interface for arguments and calling conventions). Queue submission must preserve data/effect dependencies and make completion visible before buffers are reused or host data is read. JIT replay must patch runtime addresses rather than reuse stale capture pointers. Errors and synchronization must propagate through the `Compiled` interface. Evidence: [`Renderer`](../../../tinygrad/tinygrad/renderer/__init__.py#L63), [`Buffer`](../../../tinygrad/tinygrad/device.py#L108), [`Compiled`](../../../tinygrad/tinygrad/device.py#L404), [`hcq_compile`](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L507), [`hcq_link`](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L582).

**Assessment.** A portable test progression is arithmetic → reduction → masked indexing → aliasing/view assignment → dtype edge cases → copy/synchronization → replay → multi-device where supported. These are proposed validation stages, not tests run by this document.

## 11. Explain a speedup without conflating costs (40 minutes)

**Problem.** A workload speeds up under JIT without a change in arithmetic or kernel source. Give a plausible explanation and a measurement plan. Would fewer FLOPs reported by `Estimates` prove the program is faster?

**Worked solution.** Reused lowering/compilation and captured/batched submission can remove host work while the kernel stays identical. Measure warmup, capture and steady-state separately; synchronize when measuring device completion; inspect both host and device timelines. `Estimates` counts work/traffic from UOps, which is useful for a model but does not measure achieved bandwidth (bytes moved per second), occupancy (how much execution capacity is kept active), queue overhead or latency. FLOPs are floating-point operations; fewer FLOPs can coexist with more expensive data movement. A new schedule can lower FLOPs yet lose performance through traffic or launch overhead. Read [`Estimates.from_uops`](../../../tinygrad/tinygrad/renderer/__init__.py#L30), [`track_stats`](../../../tinygrad/tinygrad/engine/realize.py#L66) and [`viz/README.md`](../../../tinygrad/tinygrad/viz/README.md#L1).

**Required artifact.** A table with compile/capture time, steady-state host interval, device duration, kernel count and bytes/FLOPs model; mark unavailable measurements rather than inventing them.

## 12. Where should a regression test live? (25 minutes)

A **regression test** preserves a previously fixed behavior. The `NULL` backend lets compiler plumbing run without executing numerical kernels. That makes it useful for examining emitted structure, but it cannot tell you what numbers real hardware produced.

**Problem.** Place tests for a symbolic rewrite, buffer view offset bug, missing renderer operation, ONNX import regression and JIT capture footgun. Explain which failures cannot be settled by `NULL`.

**Worked solution.** A pure graph rewrite belongs near `test/null` symbolic/UOp coverage. Buffer offsets belong near `test/unit/test_buffer.py` or cross-backend `test/backend/test_subbuffer.py` depending on the contract tested. A renderer operation needs backend coverage, with a minimal graph regression if the lowering itself is at fault. ONNX import behavior belongs with existing ONNX/frontend tests and may need external model fixtures only when the minimal fixture cannot reproduce it. JIT capture footguns have existing `test/unit/test_jit_footguns.py` coverage; portable replay behavior also belongs in backend JIT tests. `NULL` can inspect graph/compile/capture structure, but cannot establish numerical output or real device synchronization. The repository's test categories are explained in [`test/README`](../../../tinygrad/test/README#L1).

## Capstone: one optimizer step, every boundary (2–4 hours)

**Problem.** Use a two-parameter linear model and scalar loss. Trace one gradient/update step before and after JIT. Record graph semantics, kernel boundaries, memory ownership and command submission. Then explain how sharding a reduction dimension changes the trace.

**Solution outline.** A complete answer follows parameter storage into forward UOps, loss reduction, reverse UOps and optimizer state writes. It identifies `STORE`/`AFTER` dependencies so the update uses the intended old values, then records scheduled calls and temporary arenas. It separates per-kernel lowering from submission compilation and records which addresses are rebound for replay. Warmup/capture and steady-state measurements are reported separately. Sharding introduces collective dependence wherever local partial results no longer equal the global result; the exact number of calls depends on the chosen collective and optimizer/shape settings. The answer should include a small numerical reference for the parameter update and use tolerance appropriate to dtype, rather than assert that a graph dump proves the update correct.

Read [`nn/optim.py`](../../../tinygrad/tinygrad/nn/optim.py#L7), [`mixin/gradient.py`](../../../tinygrad/tinygrad/mixin/gradient.py#L132), [`schedule/__init__.py`](../../../tinygrad/tinygrad/schedule/__init__.py#L185), and [`engine/jit.py`](../../../tinygrad/tinygrad/engine/jit.py#L214). This capstone is a curriculum assignment with a grading outline, not a supplied benchmark result.
