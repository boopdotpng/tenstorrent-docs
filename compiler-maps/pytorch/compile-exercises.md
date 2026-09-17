# Capture and training exercises, with worked answers

Companion to [the compile source map](torch-compile.md). Source-derived answers
use PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. These exercises are
investigation recipes, not invented execution transcripts. Any measured results
must identify runtime version, device, dtype, shapes, and configuration.

These exercises follow one sequence: first recover a record of array operations,
then preserve its Python behavior, then plan training, then ask how it executes.
A graph is that operation record; a kernel is a unit of generated device work.
A guard checks an assumption used to compile a particular version. If these
are new terms, read [the opening example](torch-compile.md#start-with-one-ordinary-array-function)
first. Each “Work through it” section gives intermediate steps before the answer.

## 1. Separate capture count from kernel count

Use `residual_rmsnorm` from [the source map](torch-compile.md#worked-training-trace-residual-rmsnorm)
and prepare tensors `x`, `residual`, and `weight` with matching shapes. The code
below is a snippet, not a standalone script. A backend receives the captured
graph as `gm`; `gm.code` displays its generated Python and `gm.forward` runs it.
Use this deliberately diagnostic backend:

```python
import torch

submissions = []
def inspect_backend(gm, example_inputs):
    submissions.append(gm)
    print(gm.code)
    return gm.forward

compiled = torch.compile(residual_rmsnorm, backend=inspect_backend)
y = compiled(x, residual, weight)
```

**Task:** Does one backend submission establish that RMSNorm executes as one
kernel? What does it establish, and what information is missing?

**Work through it:** Find the line that appends to `submissions`. It runs when the backend receives a graph, not whenever a device kernel launches. Next find what callable the backend returns. Ask which compiler stages that callable actually uses.

**Answer:** It establishes that this backend received one captured FX region
for this invocation/specialization. Returning `gm.forward` executes its graph
through regular PyTorch operations; it does not invoke Inductor's kernel
scheduler. The example is useful for capture debugging, not fusion claims.
Use the Inductor backend, generated code, and a runtime trace to count executed
kernels/library calls. Record compilation separately from warm execution.

## 2. RMSNorm backward as a graph-boundary problem

**Task:** For `z=x+residual`, `r=rsqrt(mean(z*z)+eps)`, and `y=z*r*weight`,
find the two different reduction directions in backward. Decide which values
might be saved, then verify against actual AOT forward/backward graphs.

**Work through it:** Draw a row of H values and its one normalization scalar. Changing one value affects its own output directly and every output in that row through the scalar. Separately, one weight value is reused across B rows, so its gradient gathers contributions from those rows.

**Worked answer:** The upstream gradient `g` says how each output affects the
loss. Let `s=mean(z*z)+eps` and `r=s^(-1/2)`. The local derivative of `r`
with respect to feature `z[h]` is `-z[h]*r^3/H`: differentiating the mean of
squares gives `2*z[h]/H`, and differentiating the inverse square root gives
`-0.5*s^(-3/2)`. Multiplying cancels the factors of two.

The direct route through `y=z*r*weight` contributes `r*g*weight`. The route
through `r` collects the whole row's contributions, producing the second term
below. For upstream gradient `g`, set `q=g*weight`.
Along the hidden dimension,

```text
a[b] = mean_h(q[b,h] * z[b,h])
grad_z[b,h] = r[b] * q[b,h] - z[b,h] * r[b]^3 * a[b]
```

The weight gradient instead reduces rows:

```text
grad_weight[h] = sum_b(g[b,h] * z[b,h] * r[b])
```

`grad_x` and `grad_residual` are both `grad_z` before the respective cast
backward conversions. Additional leading dimensions are also reduced for the
weight gradient. The row reduction and column reduction want different work
partitioning. Mathematical adjacency therefore does not prove kernel fusion.

Saving `r` costs `B` FP32 elements; saving `z` costs `B*H`. Reconstructing `z`
requires rereading both input tensors and an add. Reconstructing `r` also needs
a reduction. A partitioner weighs such choices, with implementation constraints;
it does not solve this example by a universal “save everything” rule.

For a concrete capture experiment, create your own `rmsnorm_probe.py` that calls
the function with grad-enabled inputs and calls backward on a scalar loss.
The following command is a recipe for that script, not a claim that a file with
this name has been executed here. Run the function and its backward under:

```bash
TORCH_LOGS="aot_graphs,aot_joint_graph,graph_breaks,recompiles" python rmsnorm_probe.py
```

Inspect forward outputs beyond the user's result and the matching backward
placeholders. Distinguish saved tensors from saved symbolic sizes. Then inspect
Inductor output code to see which saved values actually require memory traffic.
The logging interface and graph formatting are version-sensitive; check the
installed runtime when replaying the recipe.

## 3. Add a GEMM and force a real capture boundary

```python
def block(x, residual, weight, projection):
    y = residual_rmsnorm(x, residual, weight)
    return y @ projection

def split_block(x, residual, weight, projection):
    y = residual_rmsnorm(x, residual, weight)
    torch._dynamo.graph_break()
    return y @ projection
```

**Task:** Compare graph regions, generated kernels, external calls, and
intermediate allocations for both. Repeat with `fullgraph=True`. Why might the
unsplit case still materialize `y`?

**Work through it:** Label three kinds of boundary separately: leaving a captured graph, writing an intermediate array, and launching a kernel or library operation. Then compare which of those are forced by the explicit break and which remain backend choices.

**Answer:** The explicit break demands a first compiled region and resumed
Python before the later region; fullgraph rejects this break. In the unsplit
version, capture can expose both operations to a backend, but the chosen GEMM
may be an external library call requiring a materialized input. A template
may support only particular producer/epilogue fusion forms. RMSNorm's reduction
also requires more than substituting a scalar multiply into GEMM indexing.
Therefore removing the graph break can leave the same number of kernel/library
launches. Demonstrate a change using code and traces, not FX node counts.

A useful extension is to return both `y` and `y @ projection`: now `y` is
observable even if a fused consumer could otherwise avoid storing it. Compare
with the tinygrad materialized-versus-lazy RMSNorm exercise, keeping the API
semantics of the two systems explicit.

## 4. Recompilation is an assumption failure

**Task:** Compile a pointwise function and call it with batch sizes 8, 8, 12,
12, 8. Change a Python scale parameter on the fourth call. Repeat with
`dynamic=False` and `dynamic=True`. Then change dtype and use a noncontiguous
input with the same shape. Predict categories of guards, not an invariant
number of recompilations.

**Work through it:** Make a five-row record of call number, batch size, scale, and cumulative backend submissions. A count increase means a new graph was submitted; an unchanged count means no new submission. Keep the dtype/layout experiments separate so one changed property explains each observation.

**Answer:** Static dimension specialization can make 12 violate the first
shape guard. Reusing 8 may find an existing valid entry. A Python scalar may
be specialized or symbolically represented depending on its type, dynamic
policy, and runtime version; do not universally predict a recompile. Changing
layout or dtype can invalidate a specialization even if batch size is symbolic.
`TORCH_LOGS="guards,recompiles,dynamic"` identifies the actual assumptions.

A concrete executed counting-backend probe in the installed **2.11.0+cu130**
wheel used integer scale values `2, 2, 2, 3, 2` with these batch sizes. Cumulative
backend submissions were `1, 1, 2, 3, 3` for `dynamic=False` and
`1, 1, 1, 1, 1` for `dynamic=True`. In that latter run the scalar was symbolic
as well. These are capture observations for that wheel, not kernel counts or a
promise about the source snapshot. Raw evidence:
[`artifacts/rmsnorm/results.json`](artifacts/rmsnorm/results.json).

## 5. Mutation plus output aliasing

```python
def mutate_and_view(x, residual):
    x.add_(residual)
    return x[:, :x.shape[1] // 2]
```

**Task:** In inference with non-grad inputs, compare eager and compiled behavior
for (a) independent input storages and (b) carefully chosen overlapping views.
What must your oracle check besides numerical output equality?

**Work through it:** First check that the same case is legal in eager execution. Then check both what the function returns and what happened to the original inputs. Finally change one element through the returned view and see which input element changes.

**Answer:** Check the mutated input contents, unaffected storage regions,
output sizes/strides, and observable alias behavior: modifying the returned
view should change the corresponding region of `x` in the same way as eager.
For each run, recreate the same alias relationships on fresh storage. Simply
cloning each argument independently destroys the test case. Some overlap
patterns are already illegal in eager; matching eager's legal domain matters.

Read `ViewAndMutationMeta`, `AOTSyntheticBaseWrapper`, and runtime epilogues.
The compiler may represent mutations as output values and reconstruct original
views. An apparently redundant copy or alias operation can be part of the
correct calling convention. In training, do not mutate a leaf requiring grad
and then blame a compiler for preserving eager's error.

## 6. Python state is not tensor state

```python
def record(x, history):
    y = x.sin()
    history.append(y)
    return y.cos()
```

**Task:** Why is eliminating `y` because only `cos(y)` is returned unsound?
Where would you investigate if the list receives the wrong value or wrong
number of entries?

**Work through it:** Call the function twice with the same list. Even if nobody assigns its return value, the caller can inspect the list afterward. Count the expected appended entries and trace where each appended tensor comes from.

**Answer:** `history` is externally observable and must gain the correct tensor
on each supported execution. Dynamo's `SideEffects`, source tracking, generated
bytecode, and resumption are the first places to investigate. AOT tensor
functionalization handles a different layer. Some Python effects are modeled
and replayed; others require breaks or errors. Do not assume every list append
is untraceable or that a graph visualization displays all observable effects.

## 7. Shape-dependent and data-dependent branches

```python
def shape_branch(x):
    return x.sin() if x.shape[0] > 8 else x.cos()

def value_branch(x):
    return x.sin() if x.sum() > 0 else x.cos()
```

**Task:** Why can a symbolic batch still require multiple specializations in the
first function? Why doesn't `dynamic=True` solve the second in general?

**Work through it:** For the first function, determine the branch from the array shape without reading any elements. For the second, make two equal-shaped arrays with opposite-sign sums. Their metadata is identical but the chosen branches differ.

**Answer:** The first branch creates a predicate on the symbolic batch. One
specialization can be valid only for a range such as `B>8`; symbolic does not
mean all branch paths are present. The second predicate depends on data, not
input-shape metadata. Capturing a scalar or an unbacked symbolic value is not
the same as resolving an arbitrary Python branch. Explore explicit structured
control flow when suitable, while respecting branch signature and mutation
constraints. Record whether the runtime breaks, errors, or captures a
supported representation rather than guessing from the flag alone.

## 8. Export the contract, not the cache

**Task:** Wrap residual RMSNorm in a module and export with a dynamic batch and
fixed hidden size. What must travel with the graph? What is absent compared
with normal `torch.compile` execution?

**Work through it:** List what another process would need to run the model without your original Python session: tensor inputs, parameters, input/output structure, and rules for allowed dimensions. Then distinguish that package from machine code for a specific device.

**Answer:** The graph signature, parameter/buffer state, input/output structure,
and shape constraints are part of the program contract. An exported program
is valid within those constraints. The deployment artifact cannot depend on
arbitrary Python fallback to repair an unsupported path. Export alone does
not choose the final GPU kernels or supply every target runtime component.
AOTInductor or another consumer provides further lowering/deployment machinery.
This is closer to MLIR/IREE's explicit program handoff than to Dynamo's ongoing
specialize/check/recompile loop, although the representations differ.

## 9. Diagnose at the narrowest failing boundary

**Task:** RMSNorm is correct eager, but wrong compiled. In what order would you
isolate the failure without claiming every debugging backend runs the same
pipeline?

**Work through it:** Use exactly the same fresh input values for each comparison. Start with the earliest stage that can reproduce the mismatch, and add one compiler layer at a time. Keep a separate record of forward outputs, changed inputs, and gradients.

**Answer:** First fix seeds, inputs, dtype, tolerances, and alias relationships.
A tolerance is the numerical error you accept when comparing floating-point
results; changing addition order can change rounding without indicating an
incorrect transformation.

Compare eager with a capture backend that returns `gm.forward`; that tests
Dynamo's recovered regions and associated Python behavior without Inductor.

Then use an available AOT eager diagnostic backend to exercise functionalization
and differentiation while leaving machine-code generation out of scope.

Finally compare Inductor and inspect the smallest differing forward/backward result.
A passing simpler backend narrows the search but does not prove all common
passes are identical: backend configurations and decomposition tables can
differ. Separate an incorrect result from expected floating-point reassociation
and reduction-order differences using a stated tolerance and high-precision
reference where appropriate.
