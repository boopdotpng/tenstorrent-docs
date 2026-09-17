# IREE exercises and worked solutions

Companion to the [source map](README.md), pinned to IREE `2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d`. Exercises 1–4 and 7–10 can be completed by reading source. Exercises 5–6 require compiled tools. The solutions are source-derived expectations, **not recorded execution results**.

For a more complex workload, continue with [residual RMSNorm and kernel fusion](rmsnorm-kernel-fusion.md): six additional worked exercises focus on eliminating or preserving dispatch boundaries.

## How to use the exercises

Read the [map's six stages](README.md#follow-one-program-through-the-compiler) first. For each task, make a prediction before opening the solution. Then explain one concrete example that would break if your reasoning were wrong. The answers distinguish a mathematical claim, an expected IR transformation, and actual execution; those are different kinds of evidence.

A `RUN` line in a source test names the test command. `FileCheck` checks text patterns in its output; `lit` is the test runner that supplies substitutions and invokes such commands. Neither tool, by itself, verifies numerical execution. A compiler **phase** is a named checkpoint; a pass pipeline is the sequence of transformations that reaches it.

## Setup and evidence limits

The checkout is `/home/boop/tenstorrent/iree`. At inspection, `iree-compile` and `iree-opt` were absent from `PATH`; `/usr/bin/FileCheck` existed. Third-party submodules were not initialized. A shallow clone alone is insufficient to build the compiler. Use a configured build with the revision's pinned dependencies, or explicitly record that an installed package is a different compiler version. Building LLVM/IREE and fetching all submodules is a separate, potentially substantial task.

For executable exercises, set paths to tools from a matching build. The following assumes those tools are on `PATH`:

```bash
export IREE_SRC=/home/boop/tenstorrent/iree
export IREE_LAB_DIR="$(mktemp -d /tmp/iree-map-lab.XXXXXX)"
iree-compile --version
iree-compile --help
iree-run-module --list_devices
```

The first two commands require compiler tools; the last requires the runtime tool. Tool presence alone does not establish a supported CPU backend or local runtime driver. Use `set -o pipefail` before FileCheck pipelines so compiler failures cannot be masked. Record tool revision, options, and target alongside artifacts. No hardware accelerator is needed for the CPU exercises.

## 1. Where does MLIR stop and IREE start?

**Task:** Classify `arith.addf`, `linalg.generic`, `flow.dispatch`, `stream.timepoint`, `hal.buffer`, and `vm` as upstream MLIR vocabulary versus IREE vocabulary. Explain why a module containing both Linalg and Flow operations is not inherently malformed.

**Worked solution:** Arith and Linalg are upstream dialects. Flow, Stream, HAL, and VM here are IREE dialects; `!stream.timepoint` and `!hal.buffer` are types rather than executable operations. Dialects define vocabularies and contracts, and MLIR permits them to coexist. A dispatch body can retain structured Linalg operations while its enclosing host program already represents dispatch boundaries. Whether a mixture is legal depends on the enclosing IR and the consuming pass, not a universal rule requiring one dialect per module. Read [Flow operation definitions][flow] and [Stream description][stream].

**Pass criterion:** Distinguish infrastructure, dialect, operation, type, and pipeline phase without treating them as synonyms.

## 2. Recover the real phase order

**Task:** Read the phase enumeration and pipeline builder. Order ABI wrapping, input conversion, dispatch creation, Stream scheduling, HAL executable translation, and VM lowering. Find one exception to the usual tensor path.

**Worked solution:** Input conversion → ABI wrapping → preprocessing/global optimization → dispatch creation → Flow processing → Stream processing → HAL processing, including device executable translation → VM host lowering. Input conversion precedes ABI wrapping because it can alter exported function types. `HostOnly` bypasses Flow/Stream tensor processing and requires no HAL in the main branch. Inline static/dynamic execution takes different HAL-related pipelines. Sources: [phase names][phases], [pipeline implementation][pipeline].

**Pass criterion:** Explain the order as dependencies, not just recite stage names. In particular, device codegen is not “the step after VM.”

## 3. Why does fusion run twice?

**Task:** In dispatch creation preprocessing, locate both early elementwise-fusion calls. What happens between them? Propose what evidence would justify deleting the second call.

**Worked solution:** After the first fusion, reshape transformations expose operations in higher-dimensional forms; the second fusion can match opportunities that did not exist earlier. Later reshape sinking targets producer-consumer opportunities. The repeated calls implement a staged strategy, not merely redundant cleanup. Deleting the second call needs relevant IR regression tests, unchanged result semantics, and measurements of compile time plus downstream dispatch quality on representative inputs. A successful build does not establish unchanged optimization quality. Source: [DispatchCreation/Passes.cpp][dispatch].

**Extension:** Construct a small reshape/elementwise chain and inspect both intermediate forms. Do not assume your example exposes a missed fusion until its emitted IR shows it.

## 4. Copy-on-write is a semantic transformation

**Task:** Read `blockArgsNeedCopies` and `singleUseTiedOperand` in the copy-on-write test. Predict where a clone appears. Why is the incoming argument treated differently from the locally created splat?

**Worked solution:** Imagine the caller retains `old`, calls this function, and then reads `old` again. If the function overwrote the caller's storage while promising a new tensor value, that later read would change. The incoming block argument is cloned before the mutating fill because the local analysis cannot assume exclusive ownership or absence of aliases outside the function. In the single-use local chain, each updated resource feeds the next update without a separately observable old value, so the test expects no clone. Both cases return a resource, but their alias evidence differs. Sources: [test][cow], [implementation][cowimpl].

**Pass criterion:** Say what observable value could be corrupted if a needed clone were removed. “It has a refcount” is not a sufficient aliasing argument.

## 5. Run a focused transform test

**Requires:** matching `iree-opt`, LLVM `FileCheck`, no model importer or GPU.

**Task:** Run the source test's own `RUN` pipeline outside the test runner:

```bash
set -o pipefail
iree-opt --split-input-file \
  --pass-pipeline='builtin.module(util.func(iree-stream-materialize-copy-on-write))' \
  "$IREE_SRC/compiler/src/iree/compiler/Dialect/Stream/Transforms/test/materialize_copy_on_write.mlir" \
  | FileCheck "$IREE_SRC/compiler/src/iree/compiler/Dialect/Stream/Transforms/test/materialize_copy_on_write.mlir"
```

**Worked solution:** A passing check means the output satisfies the checked clone/fill patterns for the test chunks. The first example checks a clone of the block argument followed by a fill of that clone. The locally created splat/update chain checks that no clone appears between the relevant checked operations. It does not prove global alias analysis is correct on all programs, and it does not measure copy costs. The command is copied from the [pinned test's RUN line][cow]; it was not run during this documentation pass.

**Extension:** Copy one chunk to `$IREE_LAB_DIR`, add a second observable use of an old resource value, and inspect the changed output. Keep upstream tests untouched. Judge the result using actual alias relationships, not just total use count.

## 6. Inspect one program at six boundaries

**Requires:** `iree-compile` with the LLVM CPU/local target support and `iree-run-module` with `local-task`. The input uses core MLIR dialects, so no Torch/StableHLO importer is required.

**Task:** Use the repository's tiny absolute-value example and save IR at important boundaries:

```bash
for phase in flow stream executable-sources executable-configurations hal vm; do
  iree-compile "$IREE_SRC/samples/models/simple_abs.mlir" \
    --iree-hal-target-device=local \
    --iree-hal-local-target-device-backends=llvm-cpu \
    --compile-to="$phase" \
    -o "$IREE_LAB_DIR/abs.$phase.mlir"
done

iree-compile "$IREE_SRC/samples/models/simple_abs.mlir" \
  --iree-hal-target-device=local \
  --iree-hal-local-target-device-backends=llvm-cpu \
  -o "$IREE_LAB_DIR/abs.vmfb"

iree-run-module --device=local-task \
  --module="$IREE_LAB_DIR/abs.vmfb" \
  --function=abs --input=f32=-2
```

These flags come from the [pinned runtime tool test][runtest]; the phase flag is **`--compile-to`**, as registered by the [compiler driver][cli]. The [sample][sample] accepts a rank-zero `tensor<f32>`, hence `f32=-2`, not a vector input. Tool/build defaults can affect CPU target selection; record the compiler's diagnostics and selected target rather than assuming a universal binary.

**Worked solution:** The mathematical result is scalar `2`. At Flow, identify the outlined tensor computation and dispatch boundary. At Stream, identify resources and completion relationships. At executable sources/configurations, distinguish a device body from its selected codegen strategy. At HAL, identify device/executable/buffer orchestration. At VM, identify host control operations and native imports. Exact symbol names, operation counts, and retained intermediate operations are compiler-output observations to record, not guaranteed answers.

**Pass criterion:** Label one actual value/operation at each available stage and explain what fact it captures that was absent earlier. A trivial model may optimize away some machinery; report that instead of inventing a token or allocation. Compilation success alone is weaker evidence than running the final artifact and checking its result.

## 7. Draw a lifetime bug

**Task:** Producer P writes buffer X asynchronously; consumer C reads X; unrelated producer Q wants to reuse X's storage. Write the necessary ordering relation. Is “the host submitted P first” enough?

**Worked solution:** The required ordering is `P finishes writing X → C reads X and finishes → Q overwrites X`. C must observe P's completion before consuming P's output. Q must not overwrite overlapping storage until every previous reader/writer that must precede Q has completed, including C in this scenario. Submission order by itself does not express all necessary cross-queue/device dependencies. Stream timepoints describe readiness; lifetime/allocation transforms determine safe storage reuse under those dependencies. Reference ownership by itself does not establish that C finished reading. Source: [Stream's timepoint/resource contract][stream].

**Extension:** Read the first case of [propagate_timepoints.mlir][timepoints]. The transform adds an associated timepoint global and awaits readiness when loading the resource. Explain why loading the resource handle alone was not enough.

## 8. Which layer should own a bug fix?

**Task:** Assign these symptoms an initial investigation point: wrong dispatch fusion; correct values but unnecessary transfer/copy; CPU executable rejected by loader; missing VM native import; unsupported frontend operation. State what additional evidence would change your choice.

**Worked solution:**

| Symptom | Start here | Why this is only an initial hypothesis |
|---|---|---|
| Wrong fusion | DispatchCreation and the pre/post-dispatch IR | Bad input semantics or later codegen can imitate a fusion failure. |
| Unnecessary copy | Stream alias/lifetime/placement and copy-elision passes | An ABI or device accessibility requirement may make the copy necessary. |
| CPU executable rejected | HAL local loader and executable ABI/version/format | Wrong target selection or packaging can also be responsible. |
| Missing native import | HAL-to-VM conversion, VM module linkage, registered runtime native modules | A compiler/runtime version mismatch can create the same symptom. |
| Unsupported frontend op | Input plugin and common input conversion | An omitted build plugin differs from an unsupported op in an enabled plugin. |

Sources: [whole pipeline][pipeline], [Stream passes][streampasses], [CPU ABI][abi].

**Pass criterion:** Pick a first source file and the IR/runtime observation that would support or falsify your hypothesis.

## 9. Review an ABI patch

**Task:** A patch adds a field to a CPU executable-library struct and updates only a runtime loader. Why can that be wrong even if the runtime compiles?

**Worked solution:** Consider a compiler that writes fields as `[pointer, length]`. A loader expecting `[pointer, new_field, length]` would read the old length in the wrong role even though each project compiled successfully. This schematic example explains the compatibility problem; it is not the concrete layout of the cited struct. The compiler emits a representation consumed by the runtime; changing one side can change offsets, sizes, or expectations without updating generated artifacts. The [standalone header][abi] explicitly requires schema-like versioning for incompatible changes or runtime feature detection, and coordinated compiler changes. Distinguish this HAL executable ABI from the public module function ABI and from the VM/native import ABI. A meaningful test loads an artifact produced by the intended compiler and exercises relevant dispatch fields; compatibility claims need version-specific cases.

## 10. Turn this into a CAIR mini-project

**Task:** Investigate one suspicious repeated rewrite/cleanup or one avoidable copy without starting by deleting it. Deliver a reproducible explanation and one narrowly scoped patch proposal.

**Worked solution / rubric:**

1. Pin revision, target, input, and flags. Save a minimal input reproducer.
2. Name the responsible phase and the invariant before/after the transform; cite its pipeline position and implementation.
3. Save pre/post IR. Describe the condition enabling the rewrite and a near-miss where it must not happen.
4. Write a focused structural regression test plus an execution check if semantics or lifetime could change.
5. For a performance claim, measure the relevant outcome: compile time, transfer bytes, peak storage, kernel time, or end-to-end latency. Include warmup and synchronization appropriate to that metric.
6. Explain why a plausible alternative is wrong: e.g., a clone seems removable locally but protects an externally aliased argument.

A strong solution can conclude that the original pass is necessary. The educational artifact is a falsifiable explanation of the abstraction and its boundary, not a mandatory optimization patch.

[flow]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Dialect/Flow/IR/FlowOps.td
[stream]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Dialect/Stream/IR/StreamDialect.td
[phases]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Pipelines/Pipelines.h
[pipeline]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Pipelines/Pipelines.cpp
[dispatch]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/DispatchCreation/Passes.cpp
[cow]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Dialect/Stream/Transforms/test/materialize_copy_on_write.mlir
[cowimpl]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Dialect/Stream/Transforms/MaterializeCopyOnWrite.cpp
[runtest]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/tools/test/iree-run-module.mlir
[cli]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Tools/iree_compile_lib.cc
[sample]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/samples/models/simple_abs.mlir
[timepoints]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Dialect/Stream/Transforms/test/propagate_timepoints.mlir
[streampasses]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/compiler/src/iree/compiler/Dialect/Stream/Transforms/Passes.cpp
[abi]: https://github.com/iree-org/iree/blob/2b05c5dbb2f2ecb27c0d3941e80ee8d2f16e890d/runtime/src/iree/hal/local/executable_library.h
