# MLIR exercises and worked solutions

These exercises use the snapshot and source links in the [map](README.md). Tasks 1-8 require only the checkout and a text editor. Tasks 9-11 require `mlir-opt`; task 12 is a source investigation. None requires a GPU or Tenstorrent card.

**Validation status:** source paths and relevant contracts were inspected. `mlir-opt` was not found on PATH or among enumerated files in `/home/boop/builds`; the optional command exercises below were **not executed**. Their outputs are expectations derived from the source, not captured logs. Existing unrelated toolchain installations may provide another version; check the revision before interpreting differing output.

Read the [map's first-principles introduction](README.md#start-with-the-problem-mlir-solves) before starting. Each exercise asks for a **contract**: a condition the representation or transformation must preserve. Try answering in three steps: what result does the original program promise, what changes, and what observation could expose a mistake? Source filenames below are relative to `/home/boop/builds/llvm-project/mlir` unless explicitly prefixed with `mlir/`.

## 1. Count the IR objects (15 minutes; SSA)

Using `@twice` in the map, identify operation results, block arguments, blocks, and regions. Explain why `%x` has no defining operation. Inspect `mlir/include/mlir/IR/Value.h` in the standalone checkout.

**Worked solution:** start at the outermost operation. The module has a body region containing a block; that block contains the function operation. The function has its own body region and entry block, containing the addition and return. `%result` is the sole arithmetic operation result; `%x` is the entry block argument owned by the function's body block. The module and function each have a region and a block in this example. `func.return` is an operation without a result. `Value` represents both `OpResult` and `BlockArgument`, so following a defining-op link is not valid for every SSA value. An argument's meaning comes from its enclosing operation/control-flow contract.

**Assessment:** credit requires explaining ownership and why values are not all expression-tree nodes.

## 2. Find the generated/handwritten boundary (20 minutes; ODS)

Find integer addition in `include/mlir/Dialect/Arith/IR/ArithOps.td`. Follow its base class and locate its handwritten folding logic in `lib/Dialect/Arith/IR/ArithOps.cpp`. Which facts come from the declaration, and which require C++?

**Worked solution:** separate “is this operation well formed?” from “can this computation be simplified?” The TableGen declaration/base constraints describe the op name, operands/results, traits and assembly surface. The `hasFolder` hook requests generated declarations for folding; C++ implements cases such as constant evaluation and arithmetic identities. The generated `*.inc` is a build artifact connecting the two. A verifier accepting an operation does not prove a newly added fold is equivalent.

**Extension:** explain why integer `x + 0` and floating-point `x + 0.0` need different semantic care (signed zero and floating-point flags).

## 3. Design a rewrite that terminates (20 minutes; patterns)

A pass has rules `x + x -> x * 2` and `x * 2 -> x + x`, each with positive benefit. Does greediness guarantee convergence? How should the pass be repaired?

**Worked solution:** apply the rules by hand: `x + x -> x * 2 -> x + x -> ...`. Neither result is permanent, so the driver can revisit the same forms indefinitely. Benefits rank matches and do not prevent a cycle. Select a preferred representation appropriate to the stage and keep one direction there, or require each rewrite to decrease a quantity that cannot decrease forever, such as a suitable nonnegative complexity score. Separating stages can be appropriate if each stage has a clear contract and is not repeatedly cycled. An iteration cap bounds time but does not establish canonicality. See `docs/Canonicalization.md` and `include/mlir/IR/PatternMatch.h`.

**Assessment:** reject solutions that simply raise benefit or increase the iteration cap.

## 4. Partial conversion is not complete lowering (25 minutes; legality)

A target marks `toy.add` illegal and `arith.addf` legal; an unrelated `toy.print` is unknown. A pattern converts every `toy.add`. Explain possible outcomes of partial versus full conversion. Then mark the enclosing module recursively legal: what danger appears?

**Worked solution:** after the pattern runs, the program contains `arith.addf` and `toy.print`. Check each against the chosen policy. `arith.addf` is accepted; `toy.print` has no classification. Partial conversion may succeed while leaving pre-existing unknown `toy.print`; all explicitly illegal operations must be handled. Full conversion cannot simply accept the unknown operation without legalizing it or making it legal through the target policy. A recursively legal module can exempt its nested operations from legalization, defeating the intended check. Read `ConversionTarget` and `applyPartialConversion` contracts in `include/mlir/Transforms/DialectConversion.h`.

**Extension:** distinguish "dynamically legal when operand types meet a predicate" from "recursively legal". The former checks a condition on an instance; the latter changes how nested IR is treated.

## 5. Why a bufferization copy can be required (30 minutes; aliasing)

Suppose `%old` is a tensor. `%new = tensor.insert %v into %old[%i]` produces a modified version. A later operation reads `%old[%i]`, and the program also needs `%new`. Is reusing `%old`'s buffer for `%new` always valid?

**Worked solution:** choose `old = [10, 20]`, `i = 0`, and `v = 99`. The required observations are `old[0] == 10` and `new[0] == 99`. In tensor semantics `%old` retains its previous element. A store into the same buffer before the later old-value read would change the result. The implementation needs a proof that the read cannot observe the write, a legal reordering, or distinct storage/copy. The example's same index deliberately prevents relying on disjointness. Inspect read-after-write discussion in `docs/Bufferization.md` and conflict analysis in `lib/Dialect/Bufferization/Transforms/OneShotAnalysis.cpp`.

**Assessment:** same shape, single result, and destination style alone are insufficient proofs. The answer must identify the observation that would change.

## 6. The uninitialized matmul trap (20 minutes; Linalg)

Consider a tensor `linalg.matmul` with `outs(%empty)` where `%empty = tensor.empty()`. Does this compute `A * B`? Give a correct initialization strategy.

**Worked solution:** test the smallest case: A contains `2`, B contains `3`, and the destination contains `7`. Matmul produces `7 + 2*3 = 13`, not `6`, because it accumulates into its destination. `tensor.empty` provides a shaped value with unspecified contents, not zeros. Fill the destination with a zero constant via `linalg.fill`, then use that initialized tensor as the matmul output operand. Alternatively, pass an existing initialized accumulator when the intended computation is `C + A * B`. Follow `include/mlir/Dialect/Linalg/IR/LinalgStructuredOps.td`, the named-op definitions, and `TensorOps.td`'s `EmptyOp` description.

**Assessment:** explicitly distinguish destination storage selection from destination numerical contents.

## 7. Preserve enough structure to schedule (30 minutes; lowering)

Why might a compiler tile a `linalg.matmul` before lowering it into loads/stores and nested loops? Does keeping Linalg guarantee fast code?

**Worked solution:** consider computing only output rows 0–15 and columns 0–15. The matmul indexing maps tell us immediately which A rows and B columns this tile needs, and that their products must still sum over the full reduction dimension. Parallel/reduction iterator roles distinguish the independent output elements from contributions to each element. These facts make legality and slicing structure explicit. Generic loop analysis may recover some information later, but that requires additional proofs. Keeping the structured form makes transformations easier to express; it does not choose profitable tile sizes, data layout, or a hardware instruction. Inspect `lib/Dialect/Linalg/Transforms/Tiling.cpp`, `Vectorization.cpp`, and `Loops.cpp`.

**Extension:** identify what a Blackhole backend must add: placement/memory spaces, inter-core transfers, synchronization/resource ownership, compute instruction selection, and launch/runtime ABI. A generic GPU conversion does not supply these contracts automatically.

## 8. A valid rewrite with an invalid lifetime (20 minutes; Transform)

A Transform dialect operation consumes a handle while replacing its payload operation. A later transform reuses that old handle. Why is valid payload IR insufficient to guarantee that this schedule succeeds?

**Worked solution:** imagine a handle selecting one matmul operation. A transform replaces that matmul with tiled operations. The old selected object no longer identifies the new operations, even if those operations correctly compute the answer. Transform IR therefore has its own handle use and invalidation contract. Replacing/consuming payload entities can invalidate mappings represented by old handles, including affected nested handles. Later schedule operations must use valid returned/reacquired handles as specified by the transform. Payload verification alone checks a different set of invariants. Inspect `docs/Dialects/Transform.md` and `include/mlir/Dialect/Transform/Interfaces/TransformInterfaces.td`.

## Optional tools: what is actually required?

Source reading requires no build. Parsing and running standard passes needs **`mlir-opt`**. Translating LLVM dialect to LLVM IR needs **`mlir-translate`**. Running arbitrary lowered programs additionally requires a compatible execution engine/runtime and correct ABI; none of that is needed for the following inspection exercises.

If no compatible tools already exist, this is an optional CPU-only build from the inspected checkout. It has **not** been run as part of this map; LLVM/MLIR compilation can consume substantial time, disk, and RAM. Use an independent build directory and choose parallelism suitable for the machine.

```bash
cmake -S /home/boop/builds/llvm-project/llvm \
  -B /home/boop/builds/mlir-map-build -G Ninja \
  -DLLVM_ENABLE_PROJECTS=mlir \
  -DLLVM_TARGETS_TO_BUILD=Native \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_BUILD_EXAMPLES=OFF
cmake --build /home/boop/builds/mlir-map-build \
  --target mlir-opt mlir-translate --parallel 2
export MLIR_OPT=/home/boop/builds/mlir-map-build/bin/mlir-opt
"$MLIR_OPT" --version
```

This requires CMake, Ninja, a supported C/C++ compiler and normal LLVM build prerequisites. `Native` targets the host CPU; no vendor GPU SDK is needed for these passes. `FileCheck` and lit are only required when running the upstream regression harness, not for manually inspecting the examples below.

## 9. See the common operation representation (15 minutes; tool)

Save this as `/tmp/mlir-map-add.mlir`:

```mlir
module {
  func.func @add_zero(%x: i32) -> i32 {
    %zero = arith.constant 0 : i32
    %result = arith.addi %x, %zero : i32
    return %result : i32
  }
}
```

```bash
"$MLIR_OPT" /tmp/mlir-map-add.mlir --mlir-print-op-generic
"$MLIR_OPT" /tmp/mlir-map-add.mlir --canonicalize
```

**Worked solution / expected observations:** generic printing exposes quoted operation names such as `"arith.addi"`, operand lists, and function input/output type information. Canonicalization can replace integer addition with `%x` and remove the unused constant; the function returns its argument directly. SSA names and exact formatting are not part of the expected result. A failure to parse should be investigated before blaming the optimization.

## 10. Lower a small matmul to explicit loops (25 minutes; tool)

Save this as `/tmp/mlir-map-matmul.mlir`:

```mlir
module {
  func.func @matmul(%a: memref<2x3xf32>, %b: memref<3x4xf32>,
                    %c: memref<2x4xf32>) {
    linalg.matmul ins(%a, %b : memref<2x3xf32>, memref<3x4xf32>)
                  outs(%c : memref<2x4xf32>)
    return
  }
}
```

```bash
"$MLIR_OPT" /tmp/mlir-map-matmul.mlir --convert-linalg-to-loops
"$MLIR_OPT" /tmp/mlir-map-matmul.mlir \
  --convert-linalg-to-loops --convert-scf-to-cf
```

**Worked solution / expected observations:** use the dimensions to predict the result before reading printed IR. A is 2-by-3 and B is 3-by-4, so C has two rows and four columns; each C element receives three products. The first command exposes loops with bounds 2, 4, and 3, element loads from A/B/C, multiplication/addition, and a store to C. C remains an accumulator: this example intentionally starts with memrefs and does not allocate or initialize them. The second command replaces structured loop control with control-flow blocks/branches. A structured loop packages “initialize, test, run body, advance” in one operation; the lower form expresses those transitions as branches between blocks. This still is not machine code and has not tested numerical execution. Compare the `RUN` lines and checks in `mlir/test/Dialect/Linalg/loops.mlir`.

**Assessment:** explain which semantic information becomes less explicit after each step and which work (LLVM conversions, ABI, codegen/runtime) remains.

## 11. Ask a verifier for a useful failure (15 minutes; tool)

Change `@add_zero`'s return type to `i64` while leaving its argument/result/return operand at `i32`. Run `mlir-opt` again.

**Worked solution / expected observation:** parsing/verification rejects the mismatch between the return operand and the function's declared result. Restore the correct type; then try returning an out-of-scope SSA name and distinguish name resolution/dominance concerns from a numerical optimization bug. Diagnostic wording may vary; the exercise grades the violated invariant, not the exact string.

## 12. Turn one upstream test into a CAIR assignment (60-90 minutes; source or tool)

Choose one case in `mlir/test/Dialect/Linalg/loops.mlir` or `mlir/test/Dialect/Arith/canonicalize.mlir`. Record the input contract, transform, expected property, and one near-miss case where the transformation must behave differently. Locate the implementation. If tools exist, execute only the relevant pass command from the test's `RUN` line; do not assume `%s` or FileCheck substitutions work directly in a shell.

**Worked solution outline:** write the specification first: `C[m,n] += sum_k A[m,k] * B[k,n]`. Then connect each loop/index in the expected output to that formula. For matmul lowering, the input contract includes shaped buffer operands and an initialized accumulator at execution time. Expected properties include reduction-carried updates to C and correct indexing of A(m,k)/B(k,n). A near-miss is a different contraction indexing pattern: hard-coding those accesses would be incorrect. The implementation is `Loops.cpp`, supported by Linalg indexing-map interfaces. A useful solution includes an argument about dataflow and dimensions, rather than only counting loops.

**Suggested submission rubric:** source evidence (2), invariant stated correctly (3), counterexample or negative case (3), validation status reported honestly (2). Require source-only and executed work to be labeled separately. This produces reusable exercises without confusing inferred behavior with tested behavior.

For the next level, [RMSNorm and fusion across kernel boundaries](rmsnorm-kernel-fusion.md) adds four worked exercises on launch elimination, reduction synchronization, memory traffic, and experimental evidence.
