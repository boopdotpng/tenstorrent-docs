# RMSNorm and fusion across kernel boundaries

This advanced case study uses the same MLIR snapshot as the [source map](README.md). It is a design and source-reading exercise, **not an executed lowering or a performance result**. The goal is to reason about eliminating a materialized intermediate between independently scheduled computations, including its memory and synchronization consequences.

Before this case study, read the [map's IR and bufferization explanations](README.md). Here a **kernel** is one device program launched over a collection of threads; a **launch** starts that program. A **materialized intermediate** is a temporary result written to addressable memory for later use. A **producer** computes that result; a **consumer** reads it. The question is whether we can keep their arithmetic together and avoid writing the intermediate array at all.

## The computation and the first actual boundary

RMSNorm rescales each row using its root mean square: square the elements, average the squares, take the square root, and divide the original elements by it. `epsilon` is a small positive number added before the square root so an all-zero row does not require division by zero. A learned weight then scales each channel separately.

Let X have B rows of H elements. `b` selects a row, `h` a channel, and `weight[h]` is shared by all rows. `reduce_h` means summing over all H channels; `rsqrt(t)` means `1 / sqrt(t)`. For a row of width H, a common definition is:

```text
sum[b]   = reduce_h (float(x[b,h]) * float(x[b,h]))
inv[b]   = rsqrt(sum[b] / H + epsilon)
y[b,h]   = cast_output(float(x[b,h]) * inv[b] * float(weight[h]))
```

For a concrete arithmetic example, take one row `[3, 4]`, weights `[1, 2]`, and temporarily set epsilon to zero. The sum of squares is `9 + 16 = 25`, the mean is `12.5`, and the inverse RMS is about `0.282843`. Before output rounding the normalized row is approximately `[0.848528, 2.262742]`. There is one inverse statistic per row, but H normalized outputs. This difference in shape is why the reduction and the elementwise work have different scheduling constraints.

In the code above, `float` means conversion to 32-bit floating point (`f32`) before multiplication and summation; `cast_output` means conversion to the requested output type. This chooses f32 accumulation as part of the specification; input/output casts, epsilon, and weight precision must be specified explicitly. `rsqrt` approximation, reassociation, and reduction order can change numerical results, so bitwise equivalence is not the default assumption for differently scheduled implementations.

An unfused implementation might have three kernel launches:

```text
K1: X -> partial/final row statistics S
K2: X, S, W -> normalized output Y
K3: Y, R -> residual output Z = Y + R
```

Here W is the weight array and R is another B-by-H array added as a **residual**. S stands for the statistics K2 needs; the exact division of sum, inverse, and partial statistics between launches is an implementation decision. If a row is split into partial reductions, K1 may itself require more than one launch. The three-launch sketch assumes its row statistics are complete before K2 reads them.

That launch structure is a hypothetical implementation choice, not something `linalg.generic` or a normal `mlir-opt` invocation creates automatically. Generic MLIR describes operations and transformations; the compiler using it decides dispatch boundaries, target mapping, and the runtime dependency model.

The attractive fusion is **K2 + K3**: produce the normalization value and immediately consume it in the residual addition inside the same kernel. If Y has no required external observation, its full-size global allocation, store, later load, and one launch may disappear. This is stronger than folding an arithmetic identity: the observable work and external memory traffic at a launch boundary change. Preserve the `cast_output` rounding at the original Y boundary even when Y stays local: if the separate kernels store Y in a lower-precision type before adding R, the fused kernel must retain that conversion (and any subsequent widening). Feeding an unrounded higher-precision normalization value directly into the residual addition changes the computation unless the numerical contract explicitly permits it.

A schematic fused K2+K3 body makes the storage change explicit:

```python
# One output element, with the row statistic already computed:
x32 = float32(X[b, h])
y_local = cast_output(x32 * inv[b] * float32(W[h]))
Z[b, h] = residual_add(y_local, R[b, h])
# No Y[b, h] global store, and no later Y[b, h] global load.
```

`residual_add` stands for the original addition's promotion and output-casting behavior. Keeping that behavior is part of correctness. `y_local` is still a computational value even though there is no full Y allocation: eliminating a buffer does not mean eliminating the arithmetic that produced its contents. Device-global memory can be read by later kernels; local temporary storage has a more restricted lifetime and visibility.

## Represent the program before selecting launches

A source-level Linalg representation can use the following conceptual operations. These are structural sketches, not pasteable MLIR assembly:

| Stage | Iteration space / maps | Semantics retained |
|---|---|---|
| Square-and-sum | `(b,h)`, parallel b, reduction h; input `(b,h)`, output `(b)` | Accumulation initialized to zero, explicit reduction dimension. |
| Inverse RMS | parallel b; input/output `(b)` | Division by H, epsilon addition, `math.rsqrt`. |
| Normalize | parallel `(b,h)`; X `(b,h)`, inverse `(b)`, weight `(h)`, output `(b,h)` | Row broadcast and weight broadcast without materializing expanded tensors. |
| Residual add | parallel `(b,h)`; Y/R/output `(b,h)` | A consumer with the same output tile domain. |

To read the table, “parallel b” means different rows compute independent results. “Reduction h” means all channels contribute to the same row sum. The map `(b,h) -> (b)` selects one inverse statistic for all channels in a row; `(b,h) -> (h)` selects the same channel weight across rows. This is **broadcasting** expressed as indexing, without copying the statistic or weight into a larger array.

The relevant source contracts are [Linalg structured ops][linalg], [Linalg interfaces][interfaces], and [Linalg fusion][fusion]. Indexing maps answer which producer elements a consumer tile needs; iterator types distinguish independent dimensions from reduction dimensions. `math.rsqrt` remains a mathematical operation requiring a target lowering choice, not a promise of a particular machine instruction.

Do structured fusion before discarding this information, when possible. In an IREE-style compiler, dispatch formation is an additional policy layer; in a custom MLIR compiler it must be supplied by that compiler. The generic `gpu` dialect can represent launches, but it does not supply a universal pass that safely merges arbitrary launches with all allocations and runtime dependencies repaired.

## Easier case: fuse normalization into a residual consumer

Suppose the consumer computes `Z[b, 64:128]`. Its required producer slice is exactly `Y[b, 64:128]`, so the compiler can compute those normalization elements at the point where the residual addition needs them. It needs the corresponding X/R slices, W channels 64 through 127, and just the one completed `inv[b]`. It does not need to compute a different row or a full Y array to serve this tile.

A plausible plan is:

1. Select a tile of Z indexed by row and channel ranges.
2. Derive the corresponding Y tile from the consumer's indexing map.
3. Inline/recompute that producer tile inside the selected loop/dispatch scope.
4. Retain X, inverse statistics, W, and R inputs; compute the local Y value and feed it to the addition.
5. Remove Y's materialization only after proving no other required consumer or externally visible result still needs it.
6. Re-run the relevant bufferization, lifetime, target mapping, and launch ABI analyses for the transformed program.

For a tensor-level rewrite, steps 3-5 can preserve value semantics naturally; later bufferization chooses legal storage. For an already bufferized or launched program, the same fusion must additionally preserve aliasing, ownership, barriers, and runtime event semantics. Moving a store or deleting an allocation is not justified merely because two elementwise indexing maps agree.

Inspect [elementwise fusion][elementwise] for one class of compatible producer/consumer rewrites and [SCF tiling and fusion][scf-tiling] for tile-driven mechanics. The [elementwise fusion tests][fusion-tests] and [multi-use producer tests][multiuse-tests] are useful starting points for positive and boundary cases. Their existence is evidence of reusable transformation machinery, **not** proof that either directly fuses an arbitrary RMSNorm multi-launch implementation.

## Harder case: fuse the reduction kernel too

A GPU **workgroup** is a set of threads that can cooperate using the target's group-local memory and synchronization. A **barrier** makes participating threads wait and supplies the ordering/visibility guarantees defined for its scope. A workgroup barrier does not wait for arbitrary other workgroups. **Occupancy** describes how much work can reside on the processor at once; using more registers or shared memory per group can reduce it.

Fusing K1 into K2 is a different problem because the entire row's reduction must finish before any output uses `inv[b]`.

- **One cooperating group owns an entire row:** threads can reduce locally, synchronize at supported scope, and reuse the resulting statistic. X can be retained or reloaded; the better choice depends on register/shared-memory pressure and occupancy.
- **Multiple groups contribute to one row:** a workgroup barrier does not synchronize those groups. A correct implementation may keep separate kernels, use an explicitly supported global/cooperative synchronization scheme, or redesign ownership so one group completes the row. Simply placing K1 and K2 in one `gpu.launch` is not a synchronization proof.
- **Very large H:** a tiled partial reduction may require scratch storage and a final reduction. Deleting its boundary can introduce an illegal cross-group dependence or excessive resource usage.

For example, split `[3, 4]` across two groups. One computes `9`, the other `16`; both outputs need the full sum `25`. If the first group normalizes after only its own barrier, the second group's `16` might not yet be available. Even a consumer tile containing only the first element needs the complete row statistic. A **kernel boundary with a dependency** solves that ordering problem by ensuring the reduction work completes before normalization starts; deleting the boundary requires another valid solution.

The scalar value `inv[b]` looks small, but its dependence on every x element in the row makes this a global reduction-domain question. The [SCF GPU mapping code][gpu-map] helps show how loop parallelism is mapped; [GPU operations][gpu] define the launch and barrier surface. The target determines legal synchronization scope and resource limits.

## A fusion checklist with concrete failure cases

| Proof obligation | Counterexample if omitted |
|---|---|
| All producer values needed by the consumer tile are available | A tile computes a partial row sum and treats it as the full RMS statistic. |
| Reduction completes before normalization observes it | Threads normalize using incomplete shared statistics. |
| Other users/outputs remain satisfied | Another consumer of Y is left reading an allocation whose stores were removed. |
| Old tensor values / alias observations remain valid | Writing Z in-place over X destroys elements needed by the reduction or another user. |
| Memory space, alignment, and buffer lifetimes remain valid | A workgroup-local temporary is used after leaving its owning scope. |
| Launch dependencies and side effects are preserved | A runtime event or external observer relied on the producer's completion boundary. |
| Numerical policy permits the new schedule | A new reduction tree changes rounding beyond the accepted tolerance. |
| Target resource usage is viable | Fusion increases live values/spills enough to outweigh the eliminated global traffic. |

For buffer proofs, inspect [One-Shot analysis][buffer] and [ownership-based deallocation][ownership]. For movement, effect interfaces and speculation safety are necessary facts; neither alone proves a valid execution schedule. Treat profitability separately from legality: removing a launch is measurable, but does not guarantee lower latency.

## Worked advanced exercises

### A. Count traffic removed without inventing a speedup

Assume X/Y/Z/R use 2-byte elements; Y has exactly one consumer, and fusion K2+K3 removes only Y's full-size write and read. B rows each have H elements. How many bytes disappear from global traffic?

**Solution:** count the two accesses separately. Storing Y writes `B * H * 2` bytes. Reading it in K3 reads another `B * H * 2`. Removing both saves `2 * B * H * 2 = 4BH` bytes, plus one launch in this hypothetical schedule. For B=32 and H=4096 that is 524,288 bytes. This excludes caches, write policies, scratch statistics, X/W/R accesses and new spills. It is a traffic accounting model, not a measured bandwidth or latency result. If Y remains an externally required output, its store cannot simply disappear; only some traffic may be saved.

### B. Find an illegal all-in-one kernel

Split one row across two workgroups. Each computes a partial sum, stores it, executes a workgroup barrier, then reads the combined sum and normalizes. Is it correct?

**Solution:** no. The barrier only orders participants at its defined scope; it does not establish that the other workgroup has completed its partial sum. Preserve a kernel boundary with an appropriate dependency, or use a supported global synchronization/ownership strategy. A transform that only merges operation regions has missed the runtime-level obligation.

### C. Decide where to perform fusion

The compiler has tensor Linalg, buffer Linalg, and already outlined GPU kernels available. Where is normalize-plus-residual fusion easiest to justify, and what must be revalidated if done later?

**Solution:** tensor Linalg retains indexing and immutable SSA semantics, giving a natural place to express producer-consumer fusion before allocating the intermediate. Later stages must additionally account for alias effects, buffer ownership/lifetimes, launch ABI, dependencies, and target mapping. Earlier is not universally optimal: profitability can need target information, and dispatch formation may constrain the available fusion region.

### D. Design an honest experiment

Build a baseline with separate normalization/residual launches and a fused version. Specify evidence needed to claim success.

**Solution:** first establish that the transformation happened: inspect lowered IR to establish the number of launches and whether Y's allocation/store/load remain. Next establish correctness: compare numerical outputs against the stated RMSNorm precision/tolerance policy. Finally test profitability: run on the same target with warmup and synchronization-aware timing; measure memory traffic/resource usage if available. Include rows too large for one workgroup, non-multiple tile widths with masking, small B, multiple Y consumers, and aliasing-sensitive inputs. Report failures and the boundary at which fusion was rejected. Merely seeing a Linalg fusion rewrite or fewer operations is insufficient.

No build or hardware experiment from this section has been run. The first implementation project should fuse the same-domain normalization/residual producer-consumer pair and preserve the reduction boundary, then use the evidence above to decide whether reduction fusion is justified.

[linalg]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Linalg/IR/LinalgStructuredOps.td#L691
[interfaces]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/Linalg/IR/LinalgInterfaces.td
[fusion]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Linalg/Transforms/Fusion.cpp
[elementwise]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Linalg/Transforms/ElementwiseOpFusion.cpp
[scf-tiling]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/SCF/Transforms/TileUsingInterface.cpp#L1755
[gpu-map]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Conversion/SCFToGPU/SCFToGPU.cpp
[gpu]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/include/mlir/Dialect/GPU/IR/GPUOps.td#L1435
[buffer]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/lib/Dialect/Bufferization/Transforms/OneShotAnalysis.cpp
[ownership]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/docs/OwnershipBasedBufferDeallocation.md
[fusion-tests]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/test/Dialect/Linalg/fusion-elementwise.mlir
[multiuse-tests]: https://github.com/llvm/llvm-project/blob/e3c4c16567e3074dcd42da664fcb91298fd8c0fb/mlir/test/Dialect/Linalg/fusion-multiuse-producer.mlir
