# TT-MLIR exercises and worked answers

Source revision and evidence limitations are in the [map](README.md). Exercises 1–8 are source-reading tasks with worked answers; commands are optional and have not been executed against a built compiler here. These are curriculum seeds, not measured performance claims.

## Before starting

Read the [map's implementation choice and hardware vocabulary](README.md#start-with-the-implementation-choice). Then work through these exercises in order: they move from translating an addition to preserving memory, scheduling, and device-launch obligations. Try each prediction before reading the worked answer.

A test's `RUN` line is its command template. The `lit` test runner substitutes filenames and tool paths; `FileCheck` compares emitted text against expected patterns. A matching text pattern is structural evidence about compiler output. Running the compiled program and comparing numbers is a separate check. A **verifier** checks an operation's own rules; **conversion failure** means a transformation could not produce the allowed destination representation.

## 1. Find the smallest dialect-conversion experiment

**Task (20 minutes).** Read [TOSA add conversion test](../../../tt-mlir/test/ttmlir/Conversion/TosaToTTIR/elementwise_binary/add.mlir). Identify the input operation, expected output, command, and assertion mechanism. Explain why this does not establish device execution.

**Worked answer.** Its RUN lines invoke `ttmlir-opt --convert-tosa-to-ttir` and then `FileCheck`. The test checks the textual lowering of TOSA addition into TTIR. It does not serialize an artifact, launch a device, or compare numerical outputs. After a configured build, run the repository's `llvm-lit` command on this test, or use its RUN lines with actual filenames replacing lit substitutions. A complete submission distinguishes parsing, conversion structure, and numerical execution as separate claims.

## 2. Why isn't a rewrite set enough?

**Task (25 minutes).** In [TTIRToTTNNPass.cpp](../../../tt-mlir/lib/Conversion/TTIRToTTNN/TTIRToTTNNPass.cpp), find the conversion target, type conversion, rewrite population, and failure propagation. Predict what happens if an unsupported TTIR op survives.

**Worked answer.** Imagine every addition converted successfully but one unsupported normalization remained. A matcher can simply decline that last candidate, so “the matchers finished” would be too weak a success condition. TTIR is declared illegal and TTNN legal. An identity type conversion is registered and `populateTTIRToTTNNPatterns` supplies rewrites. `applyFullConversion` must satisfy legality; failure calls `signalPassFailure()`. Therefore a surviving illegal TTIR op cannot count as successful full conversion. The identity conversion says what this pass does to types, not that preceding layout preparation is unnecessary. The grading criterion is naming both the legality check and the pass-failure mechanism.

## 3. Is this layout change free?

**Task (30 minutes).** Compare `D2M_ViewLayoutOp` and `D2M_ToLayoutOp` in [D2MOps.td](../../../tt-mlir/include/ttmlir/Dialect/D2M/IR/D2MOps.td). Classify a representational affine remapping and a DRAM→L1 transfer. Find where view returns are materialized in the pipeline.

**Worked answer.** Compare reinterpreting an existing array's indices with copying it to another memory bank. The first can change how consumers calculate addresses; the second must make bytes available in a new location. `view_layout` is specified as a representational view with a remapping attribute and no codegen operation; consumers compose the layout. `to_layout` covers memory-space, dtype, tile-size, and sharding changes and has memory effects. DRAM→L1 needs actual storage/movement, not merely renamed indexing. `createD2MFrontendPipeline` schedules `createD2MMaterializeViewReturns` at multiple stages; returning a view can require materialization even when an internal view is free. Inspect [materialize_view_returns.mlir](../../../tt-mlir/test/ttmlir/Dialect/D2M/materialize_view_returns.mlir) for concrete expected IR. Do not infer that every `to_layout` must survive optimization: redundant transitions can fold.

## 4. Tensor destination versus physical buffer

**Task (30 minutes).** Read `D2M_GenericOp` and its interfaces. Explain why output operands and SSA results coexist, and why an output operand alone does not prove an operation mutates a unique allocation.

**Worked answer.** Suppose `old` is still read after an operation produces `new`. Using old's allocation as a destination must not destroy the old value before that read. This is why the compiler cannot equate an output operand with unrestricted mutation. The op participates in destination-passing style: outputs identify candidate result storage relationships while tensor results preserve SSA value semantics. Its `BufferizableOpInterface` methods describe reads, writes, aliasing, buffer types, and writability. Bufferization resolves the physical realization while preserving observable behavior; aliases or live tensor values can prevent unsafe reuse. In [D2MPipelines.cpp](../../../tt-mlir/lib/Dialect/D2M/Pipelines/D2MPipelines.cpp), TTNN mode uses upstream one-shot bufferization with specified options, while the non-TTNN path uses TTCore's custom pass for Metal layouts. A good answer identifies both interface and pipeline policy.

## 5. Recover an ordering dependency from source

**Task (35 minutes).** Explain why moving EmitC conversion before D2M→TTMetal conversion is suspect. Name the concrete information at risk.

**Worked answer.** The dispatch builder needs to answer a hardware configuration question before the operation carrying the answer is erased. Comments around `createD2MToTTKernelPreEmitCPipeline` and `createTTIRToTTMetalPipeline` state that dispatch-level conversion inspects TTKernel operation structure, including `TypecastTileOp` locality for BFP8 unpack-mode selection. Early EmitC lowering would replace that structure with lower-level source constructs. Init hoisting is likewise deliberately delayed. This is an information-preservation dependency, not merely stylistic ordering. Submit the producer of the information, the consuming conversion, and the pass that would erase it.

## 6. Explain the apparently ignored option

**Task (15 minutes).** Search `enableOpScheduler` in [D2MPipelines.cpp](../../../tt-mlir/lib/Dialect/D2M/Pipelines/D2MPipelines.cpp). Does setting the corresponding options object field false necessarily turn off the scheduler in this pipeline?

**Worked answer.** No. This revision explicitly assigns `true` to the scheduler pass option and leaves `options.enableOpScheduler` commented out. The accompanying TODO links that choice to DST allocation consistency with elementwise fusion. This is an observed snapshot fact, not a prediction about future revisions. An exercise extension is to find a test covering the dependency; absence of one is a research question rather than evidence the dependency is false.

## 7. One model, two products

**Task (30 minutes).** Read [EmitC add test](../../../tt-mlir/test/ttmlir/EmitC/TTNN/eltwise_binary/add.mlir). Draw the common stage and output branches. List the additional surfaces needed to add a brand-new runtime operation.

**Worked answer.** The common TTIR→TTNN pipeline produces shared IR. A runtime preparation branch feeds `ttmlir-translate --ttnn-to-flatbuffer`; an EmitC branch feeds `--mlir-to-cpp`. For a new Flatbuffer-runtime operation, inspect the TTNN op definition/verifier, conversion pattern, schema, serializer, and runtime executor, plus tests. The [adding-an-op guide](../../../tt-mlir/docs/src/adding-an-op.md) enumerates these surfaces and also discusses bindings, builder, and CPU-hoisting support. Supporting one product does not by itself validate all other products. The test's `%system_desc_path%` and temporary-path variables are lit substitutions, not shell environment syntax.

## 8. Design a direct-backend audit

**Task (45 minutes).** You want to lower a fused elementwise-plus-reduction kernel for Blackhole without relying on a preexisting TTNN operation. Use D2M to write a review checklist; do not implement the backend.

**Worked answer.** Trace one output tile from inputs to completed storage. First establish which logical elements it represents and which core owns it. Then establish where its inputs arrive, when compute may read them, where results wait, and when a consumer may use them. With that execution story in mind, check logical versus padded shape and masking; grid/indexing maps; tile/block factors; L1 and DRAM allocation; buffer lifetimes and spill policy; compute scheduling and DST capacity; CB producer/consumer synchronization; DMA completion and NoC addressing; thread-argument normalization; and dispatch metadata. These obligations correspond to visible stages in `createD2MFrontendPipeline` and `createD2MBackendPipeline`. Proving the scalar algebra is insufficient to prove this implementation. A strong submission pairs each item with a pipeline stage and proposes both an IR-structure test and a numerical/runtime test. This checklist is an inference from TT-MLIR's design, not a claim that tinygrad must reproduce its dialect structure.

## Optional implementation project: test an existing invariant

Choose [D2M layout tests](../../../tt-mlir/test/ttmlir/Dialect/D2M/lower_to_layout.mlir), [negative remote-access tests](../../../tt-mlir/test/ttmlir/Dialect/D2M/remote_load_store_negative.mlir), or [thread-argument normalization](../../../tt-mlir/test/ttmlir/Dialect/D2M/arguments/normalize_thread_args.mlir). Copy a small case into a scratch file, predict the result, then run the exact RUN-line pass with the configured toolchain. Change one property at a time. Record the commit, command, actual diagnostic/IR, and explanation.

**Solution standard.** A complete result explains the invariant before showing output, captures a minimal counterexample, and distinguishes a verifier rejection from a conversion failure. For a source patch, follow the repository's pattern-error guidance: a rejected candidate uses `notifyMatchFailure`; an actual pass failure must propagate appropriately. No patch or execution for this optional project is claimed in these notes.
