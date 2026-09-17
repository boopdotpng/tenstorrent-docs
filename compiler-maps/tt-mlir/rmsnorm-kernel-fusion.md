# RMSNorm: where operations become kernels, and why boundaries survive

Revision: `33e83a87d335d9f6b6cb066384230382f8a3cd38`. This is a source-based worked case; no compilation or device measurements were performed for this map. “Observed” below means present in source/tests. Proposed fusion strategies are explicitly identified as design exercises.

The central finding: **this checkout contains an RMSNorm example with three sequential multicore kernel stages, and the boundaries supply synchronization.** Replacing an arithmetic graph with `ttir.rms_norm` is a separate transformation. Neither one tensor operation nor one TTNN call proves one hardware kernel or one launch.

## The workload

RMSNorm scales each row by the reciprocal of its root-mean-square magnitude and then multiplies by learned column weights. `M` counts rows; `H` counts columns, often called hidden features. `rsqrt(a)` means `1/sqrt(a)`. Epsilon is a small positive constant protecting the denominator near zero. Gamma has one weight per column and is reused across rows.

For hardware terms such as grid, tile, DMA, CB, and DST, start with the [map's hardware vocabulary](README.md#hardware-vocabulary-needed-for-the-map). The distinction between a tensor operator, a dispatched program, and its cooperating kernel functions is essential to this example.

For activation `x[M,H]` and learned weight `gamma[H]`:

```text
sum_sq[m] = sum_h x[m,h] * x[m,h]
inv[m]    = rsqrt(sum_sq[m] / H + epsilon)
y[m,h]    = x[m,h] * inv[m] * gamma[h]
```

For a hand calculation, let `x=[1,3]`, `gamma=[1,2]`, and epsilon `1e-5`. The squares sum to `10`, the mean is `5`, and `inv=1/sqrt(5.00001)`. The result is `[inv, 6*inv]`, approximately `[0.447213, 2.683279]`. These numbers illustrate the formula, not a device measurement. The intermediate `inv` has one element per row, while x and y have `H` elements per row; multiplying by inv therefore broadcasts that value across the row.

The dependency matters more than the number of arithmetic nodes: output for a row depends on the complete reduction of that row. If the hidden dimension is partitioned across cores, a core's local sum is insufficient. This is where inter-kernel fusion becomes a question about communication and scheduling.

## Route A: recognize RMSNorm and delegate to TTNN

A pattern matcher starts from a candidate operation and checks that its inputs form the expected expression. Here it recognizes a larger computation and gives it a name so later stages can choose an implementation. Each guard prevents a merely similar-looking graph from being mistaken for this particular normalization.

Observed in [TTIRFusing.cpp](../../../tt-mlir/lib/Dialect/TTIR/Transforms/TTIRFusing.cpp), `RMSNormFusionPattern`: the matcher starts at an outer multiply and recognizes `x * rsqrt(mean(x²) + epsilon) * gamma`. It checks a single last-dimension mean, matches the square as multiply-by-self or power-two, requires a constant epsilon, traces only accepted layout/typecast forms, and checks/squeezes gamma's shape. It builds `RMSNormOp`; result reshape/typecast handling preserves the required external type. [rms_norm_fusion.mlir](../../../tt-mlir/test/ttmlir/Dialect/TTIR/fusing/rms_norm_fusion.mlir) provides the IR cases.

This is **semantic recognition/fusion**. Its useful product is a named operation with enough semantics to select a library implementation. It does not demonstrate that the original graph already consisted of distinct compiled kernels, or that their binaries have been combined.

Next, `RMSNormOpConversionPattern` in [TTIRToTTNN.cpp](../../../tt-mlir/lib/Conversion/TTIRToTTNN/TTIRToTTNN.cpp) checks `normalized_shape` contains exactly the input's last dimension and replaces the operation with `ttnn::RMSNormOp`. Conversion rejection uses `notifyMatchFailure()`.

Finally, [runtime RMSNorm](../../../tt-mlir/runtime/lib/ttnn/operations/normalization/rms_norm.cpp) retrieves the input, optional weight/bias, memory config, and compute config, then calls `::ttnn::rms_norm`. The wrapper passes no residual input and no explicit program config. **Evidence boundary:** determining how many device programs/kernels that call uses requires inspecting the matching TTNN/tt-metal implementation and selected configuration. Counting one TTNN IR operation does not answer that question.

## Route B: an explicit three-kernel multicore implementation

Read [rmsnorm_to_kernel.py](../../../tt-mlir/test/d2m-jit/kernels/patterns/rmsnorm_to_kernel.py), especially `rms_partial`, `rms_allreduce4`, `rms_scale`, and `rmsnorm_run`. The benchmark configuration uses `M=32`, `H=3200`, float32, and grid `(1,4)`. Its source describes previous device validation, but this audit has not rerun or independently verified that result.

A `(1,4)` grid distributes this example across four cores. Each core holds a **shard**, a slice of the hidden columns. An **all-reduce** combines the cores' partial results and makes the combined result available on each participating core. This is needed because a row's normalization depends on all 3200 columns, even when one core owns only a quarter of them.

With 32-wide tiles, `H/32 = 100` hidden tiles and each of four cores owns `KC=25`. The implementation computes:

| Stage | Source behavior | Materialized intermediate | Why the next stage waits |
|---|---|---|---|
| `rms_partial` | Each core loads its hidden shard; calculates `x_shard @ x_shardᵀ`; masks by a 32×32 identity and reduces to extract diagonal sums of squares. | Each core stores one partial tile in `part`. | Every all-reduce participant needs completed partials from all four cores. |
| `rms_allreduce4` | Each core remote-loads partials from cores 0–3, adds them, adds `H*epsilon`, applies rsqrt, and stores its local result. | `inv` contains the inverse scale on every core. | The scaling stage must observe a completed inverse value. |
| `rms_scale` | For each local hidden tile, remote-loads x and gamma, broadcasts gamma by row and inverse by column, multiplies, and stores output. | Final output tiles. | Output consumption must follow completed stores. |

The matrix trick can be derived one entry at a time. Let `A` be the local rows of x for one shard. In `A @ Aᵀ`, entry `(i,j)` is the dot product of row i and row j. Its diagonal entry `(i,i)` is exactly the sum of squares for row i. Multiplying by the identity zeroes the off-diagonal cross-row products; reducing extracts the desired row sums. This computes more products than directly squaring, but uses an implementation path available to this example.

The driver folds a factor into weights on the host: `gamma_prime = gamma * sqrt(H)`. Then

```text
x * gamma_prime * rsqrt(sum_sq + H*epsilon)
  = x * gamma * rsqrt(sum_sq/H + epsilon)     [real arithmetic]
```

To derive it, rewrite `sum_sq/H + epsilon` as `(sum_sq + H*epsilon)/H`. Taking the reciprocal square root gives `sqrt(H)/sqrt(sum_sq + H*epsilon)`. The driver puts the numerator's `sqrt(H)` into gamma, allowing the reduction stage to use the denominator expression directly.

This identity explains both the weight factor and scaled epsilon. Floating-point rounding still differs by arithmetic order; the algebra alone is not a numerical validation.

The matmul/identity trick is intentional. The file says a multi-tile elementwise square runs into a region shard-size limitation. It also sets `use_tile_matmul=False` for transpose-B lowering, restoring the old configuration afterward. These are implementation-specific constraints, not inherent requirements of RMSNorm.

### What fusing these kernel stages would actually remove

Consider two cores. If core 0 finishes its partial sum and immediately reads core 1's partial before core 1 has written it, it can use stale data. The former stage boundary prevented that read. A fused implementation needs an equally strong completion/visibility protocol; algebraic equivalence does not provide one. A **semaphore** can communicate readiness, and a **barrier** establishes a synchronization point, but a specific correct protocol must account for every participant and transfer.

Observed in the file's opening comment: no semaphores are used for the cross-core reduction; **sequential-kernel ordering is the read-after-write barrier**. The driver invokes partial, all-reduce, then scale in that order. Therefore, combining stages into one dispatch cannot simply delete intermediate stores and continue with the same unsynchronized loads.

Design exercise, not implemented here: partial→all-reduce fusion would need a protocol establishing that all four partials are visible before any consuming read. All-reduce→scale fusion could potentially keep the local inverse value in a local buffer/register and begin scaling after its own reduction completes, but must preserve the cross-core readiness protocol upstream. Keeping `part` in L1 rather than DRAM can save traffic without removing its synchronization role. These are different optimizations.

On Tensix, “one fused kernel” also needs clarification. One dispatched program can still contain separate compute and data-movement kernel functions on distinct processors. D2M's [backend pipeline](../../../tt-mlir/lib/Dialect/D2M/Pipelines/D2MPipelines.cpp) explicitly splits unified threads into compute/data-movement threads and lowers DMA. A useful success criterion is fewer dispatch boundaries and less intermediate tensor traffic while preserving these cooperating roles, not forcing the entire program into one instruction stream.

## What D2M's generic fusion does at this revision

[GenericFusion.cpp](../../../tt-mlir/lib/Dialect/D2M/Transforms/GenericFusion.cpp) contains two relevant patterns: `FuseD2MElementwiseOpsPattern` and optional `FuseD2MEltwiseReductionOpsPattern`. They merge producer/consumer `d2m.generic` bodies and erase the original generic operations. This is a more concrete fusion boundary than replacing a TTIR expression with a named tensor op: generic operations carry dispatch-grid and iteration structure.

To read the restrictions, a `d2m.generic` is a region describing work over a grid and iteration space. **Pure-tensor form** still treats outputs as new array values rather than explicit memory mutations. An all-parallel iterator set describes independent elementwise outputs; a reduction iterator combines contributions. A **permutation map** reorders coordinates without combining or discarding them. **Skip traits** mark cases excluded by policy, and “multi-use” means a value has more than one use that the transformation must preserve.

Observed restrictions:

- Both targets must be in the expected compute-only, pure-tensor form. Elementwise targets must have all-parallel iterators and must pass skip-trait and multi-use-input checks.
- Producer results may only be externally consumed by the chosen consumer; uses nested within those operations are treated specially.
- Blocking must be compatible. Indexing-map ranks must fit, and the producer result map must be a permutation.
- `fitsInL1PostFusion` actually checks an estimated **CB count**, with limit 32. Its name is not proof of a complete byte-accurate L1 capacity calculation.
- When either region's largest DST element type exceeds 16 bits, the pass conservatively limits the estimated fused operand count to eight. This is the pass's policy, not a general hardware theorem about all possible schedules.
- Elementwise→reduction fusion requires exactly one reduction iterator. The source explains that this keeps downstream scratch/phase geometry well-defined.
- This pass has no symmetric general reduction→elementwise rule. You cannot conclude that RMSNorm's reduction and scaling phases merge just because elementwise→reduction is enabled.

Both fusion flags default to false in [D2MPipelines.h](../../../tt-mlir/include/ttmlir/Dialect/D2M/Pipelines/D2MPipelines.h). The frontend pipeline instantiates the generic fusion pass when either flag is enabled; within that pass the elementwise pattern is always registered, and reduction fusion is additionally conditional. Consequently enabling the reduction option also gives the instantiated pass its ordinary elementwise pattern.

Why does direction matter? Fusing `exp → sum` computes each exponential as it contributes to the accumulating sum. Fusing `sum → scale` requires the complete sum before any output using it can finish. The latter may require a different loop arrangement, rereads, retained inputs, or cross-core synchronization. Supporting the first direction therefore does not imply support for the second.

The [eltwise_reduction_fusion.mlir test](../../../tt-mlir/test/ttmlir/Dialect/D2M/Transforms/eltwise_reduction_fusion.mlir) is a crisp source-level demonstration: `exp→sum` along one dimension is expected inside one compute generic; a two-dimensional reduction retains a generic boundary. It is **not** an end-to-end RMSNorm fusion test. Generic fusion runs before bufferization/allocation and later scheduling, so passing it is also not proof that no scratch, spilling, or extra movement will be introduced downstream.

For the explicit multicore RMSNorm above, the reduction and cross-core communication dependencies go beyond this ordinary elementwise producer→consumer case. There is no evidence here that turning on a generic fusion flag automatically collapses its three stages.

## A second, deliberately limited RMSNorm rewrite in the same file

The file also registers a `@d2m.pattern(root=ttir.RMSNormOp)` rewrite named `lower_rmsnorm`. Do not conflate it with the multicore benchmark. It uses **two single-core kernel functions**, `rms_reduce_sc` and `rms_scale_sc`, creates identity/`1/H`/epsilon constants in rewrite scope, and expands a rank-one weight to rank two.

A tensor's **rank** is its number of axes: rank-one gamma has shape `[H]`, while a rank-two activation has shape `[M,H]`. A **static** dimension is known at compilation. The rewrite expands the weight representation, so the later pipeline must support that shape transition as well as the arithmetic.

Its predicate requires static rank-two float32 activations, same-dtype rank-one weights of hidden length, and sequence/hidden multiples of 32. Its `PATTERN_TESTS` checks that the rewrite fires and materializes D2M IR. The comments explicitly leave end-to-end rewritten-module execution disabled because the rank-change/reshape path is not lowerable by that d2m-jit device pipeline. The separate multicore benchmark is not a workaround that proves this rewrite works end to end.

This is an instructive sharp edge: a rewrite can recognize the mathematical operation, create plausible kernel IR, and pass a structural check while a layout/rank transition still prevents execution. Source comments describing validation of separate kernels should not be inflated into validation of the entire integration.

## How to prove useful inter-kernel fusion

For a future implementation, record these separately:

1. **Input graph and shape.** Preserve the starting IR and flags; identify every outside user of an intermediate.
2. **Region boundary change.** Compare generic operations before/after the pass; identify the specific producer/consumer boundary removed.
3. **Dispatch and role structure.** Inspect final TTMetal/TTNN dispatch and generated compute/data-movement functions. Count programs and launches, not just arithmetic operations.
4. **Storage and synchronization.** Trace where partials/inverse values live, whether x is reread, CB waits/reservations, DMA completion, and any semaphore/barrier protocol replacing former launch ordering.
5. **Numerics and timing.** Compare results for representative and boundary shapes/dtypes, then measure launches and memory traffic where possible. Fusion can reduce launches yet lose performance from resource pressure or lower occupancy.

These are proposed validation steps; none of these measurements was performed during this documentation task.

## Worked exercises

### 1. Explain why the host folds gamma by `sqrt(H)`.
 Derive the identity above.

**Solution:** moving `1/H` outside the square root gives a factor `sqrt(H)` in the numerator, while epsilon must become `H*epsilon` inside. Omitting the epsilon scaling changes the function, especially for small inputs.

### 2. Count stages for the 32×3200, four-core case.


**Solution:** the driver invokes three named kernel stages; there are 100 hidden tiles total and 25 per core. The all-reduce is explicitly unrolled for four partials. This count describes source orchestration, not a measured count of every internal compute/data-movement binary or runtime launch.

### 3. Can a single-dimension reduction fuse with its producer?
 Use the `exp_then_sum` lit case.

**Solution:** it is a positive case under the specified fusion flags. Changing reduction axes to `[0,1]` is the negative case in the same file. A claim that the pass supports arbitrary reduction fusion contradicts this test and `hasSingleReductionDim`.

### 4. Can we fuse RMSNorm all-reduce with scale by deleting the intermediate kernel boundary?


**Solution:** potentially as a new schedule, but deleting the boundary alone is unjustified. Preserve readiness of all partials, compute the local inverse, then feed scale through local storage or registers. Explain how former sequential ordering is replaced. A complete proposal includes synchronization, x/weight availability, resource limits, and validation; a fused arithmetic formula is not enough.

### 5. A FileCheck says `ttir.rms_norm` disappeared. Has the rewrite succeeded end to end?


**Solution:** no. In this source the rewrite test is intentionally structural; the rank-one→rank-two weight conversion remains a documented device-pipeline blocker. Require successful lowering, artifact execution, and numerical comparison of that rewritten module to make the stronger claim.

### 6. Why might two generics remain despite a producer having one consumer?


**Solution:** sole consumption is necessary but insufficient. Check form, tensor semantics, iterators, skip traits, multi-use inputs, blocking, map permutation/rank, estimated CB count, and DST operand limits. Then ask whether the requested direction is one of the two registered patterns at all.
