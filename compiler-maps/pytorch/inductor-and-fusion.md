# Inductor: why its representations exist, and where kernel fusion stops

Source snapshot: PyTorch `e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df`. This is a **source-reviewed map**, not a measurement of that checkout. Examples below are schematic unless explicitly linked to an executed probe. Coverage is module/pass-family level plus individually explained representative rules; it is **not every Inductor pattern, lowering registration, backend, or generated rule**. See [exercises and worked solutions](inductor-exercises.md).

## Start with the work that must actually happen

Suppose Python says `y = (x + 1).sin()`. For every array index `i`, a possible
implementation computes `sin(x[i] + 1)` and writes `y[i]`. It need not allocate
an entire array for `x + 1`. This is the basic reason to compile several tensor
operations together: remove unnecessary intermediate storage and execution
boundaries while preserving the result.

A **kernel** is a unit of generated device computation; launching it asks the
device to run that work. CPU generated functions have a different execution
model, so the guide distinguishes function calls from GPU launches.
### Fusion

combines work that could otherwise execute separately. It can save
launches and memory traffic, but a larger kernel can also use more resources
and run slower. **Materializing** a value means storing its elements in an
addressable array rather than only keeping a recipe to compute them.

Inductor receives an **FX graph**, a record of tensor operations recovered from
Python. It must decide what each array element requires, where results live,
and which computations execute together. A compiler's internal representation
of a program is an **IR**. Inductor uses more than one because “apply sine to a
tensor” and “read element at offset i, compute sine, write offset i” answer
different planning questions. See [capture](torch-compile.md) for how the graph
arrives and [first principles](../first-principles.md) for shared terminology.

## The philosophical difference from tinygrad

Tinygrad tries to carry tensor computation, indexed computation, and kernel computation through a small shared UOp vocabulary and ordered rewrite systems. Inductor accepts an already captured PyTorch program, preserves PyTorch's observable dtype/layout/aliasing behavior, and mixes generated code with established operators and specialized kernel implementations. Its complexity is partly the cost of serving that existing semantic surface and partly a deliberate choice to retain multiple execution strategies.

Compare tinygrad's [rangeify/get_kernel_graph](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/schedule/rangeify.py#L367), [schedule construction](https://github.com/tinygrad/tinygrad/blob/107adc31701df0247dfa45e175984df906a68b53/tinygrad/schedule/__init__.py#L28), and [existing RMSNorm walkthrough](../tinygrad/rmsnorm-kernel-fusion.md) with the representations below. Both compilers perform lazy expression composition, realization, dependency analysis, and kernel optimization; neither is accurately described as merely executing one kernel per operation.

| Question | Tinygrad emphasis | Inductor emphasis |
|---|---|---|
| What is rewritten? | UOp graphs across several abstraction levels | FX operator graphs, then loop/index expressions and buffer/scheduler IR |
| Where does fusion live? | Tensor/range/buffer decisions and subsequent kernel rewrites | Expression inlining, explicit scheduler fusion, specialized template prologues/epilogues, and library choices |
| What is matmul? | Computation lowered and optimized toward target instructions | Choice among external ATen/library calls, generated templates, and selected native loop-IR paths |
| How are exceptions represented? | Additional rules and target renderer/runtime hooks | Decompositions, fallbacks, specialized IR classes, backend guards, patterns and template capabilities |
| What does a PM mean? | A rewrite engine repeatedly used across UOp stages | Primarily an FX subgraph matcher; it is not the entire compiler or scheduler |
| What is the deployment product? | Scheduled calls and compiled device programs | Callable wrapper around generated kernels and external calls; optionally an AOT artifact/runtime ABI |

These are architectural observations, not a claim that one compiler is universally smaller, faster, or more correct.

## From array expressions to a schedule

For `y = (x + 1).sin()`, an elementwise or **pointwise** expression describes
one output element: `sin(load(x, i) + 1)`. Its **iteration domain** is the set
of indices for which to evaluate that expression. Together these describe a
loop without yet committing to exact GPU threads or CPU vector instructions.
For `x.sum(1)`, the expression also has a **reduction domain**: the column
indices that must be combined for each row.

A **buffer** names storage for values. A **layout** describes how array indices
map to that storage. A **dependency** says which reads require which writes to
have happened first. The **scheduler** uses these dependencies to order work
and decide which pieces can share an implementation. It must check both
correctness and whether a backend knows how to generate the combined work.

Matrix multiplication has additional choices. Inductor can call an existing
library implementation through an **external call**, or generate from a
**template**, a kernel skeleton with supported places to insert extra work.
A **prologue** transforms inputs while loading them; an **epilogue** transforms
computed results before storing them. For example, scaling matrix inputs is a
possible prologue, and adding bias plus an activation is a possible epilogue.
An external implementation cannot be opened up by the ordinary scheduler and
arbitrarily edited; only its exposed capabilities are available.

## Module-by-module reading map

All links below pin the snapshot; line anchors identify entry points, not complete implementations.

### [compile_fx.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/compile_fx.py#L3100)

**Role in the program.** Orchestrates backend compilation around AOTAutograd, inference/training, decompositions, graph lowering and caches

**What can go wrong.** One `torch.compile` call can produce several graphs; this file is downstream of Dynamo capture

### [pre_grad.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/pre_grad.py#L336)

**Role in the program.** Optimizes an FX graph before differentiation, retaining useful high-level patterns

**What can go wrong.** A transformation can change the backward graph and saved intermediates; training eligibility matters

### [joint_graph.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/joint_graph.py#L799)

**Role in the program.** Cleans and rewrites joint forward/backward work before partitioning

**What can go wrong.** Removing a cast is a numerical decision; joint optimization is not a promise of one joint kernel

### [post_grad.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L178)

**Role in the program.** Optimizes normalized functional graphs separately for forward/backward

**What can go wrong.** Pass order, fake metadata and inference flag matter; mutation must eventually be restored

### [pattern_matcher.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/pattern_matcher.py#L2586)

**Role in the program.** Indexes FX patterns by node op/target; checks structure, users, metadata and extra predicates

**What can go wrong.** Mutating FX is not UOp hash-consing. The pass rejects matches crossing mutation/stream boundaries

### [decomposition.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/decomposition.py#L1)

**Role in the program.** Expands operators into a smaller supported/operator-optimization surface

**What can go wrong.** Decomposition can erase a useful fused semantic operation, which a later pattern may reconstruct

### [graph.py / GraphLowering](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/graph.py#L388)

**Role in the program.** Interprets FX into Inductor objects; owns buffers, symbolic sizes, layouts, constants and outputs

**What can go wrong.** The same operator may select generated IR or an external fallback; inspect the selected lowering

### [lowering.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/lowering.py#L537)

**Role in the program.** Registry from operator overloads to loop expressions, views, reductions or external nodes

**What can go wrong.** Broadcasting/promotion and layout constraints are semantics, not incidental bookkeeping

### [ir.py / Loops](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/ir.py#L1060)

**Role in the program.** `Pointwise` and `Reduction` carry iteration domains plus Python expression bodies

**What can go wrong.** The body is interpreted through virtual operations; it is not simply a textual loop AST

### [TensorBox / StorageBox](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/ir.py#L10943)

**Role in the program.** Separates tensor identity from mutable storage and lazily represented computation

**What can go wrong.** `realize()` creates/registers a `ComputedBuffer`; that alone does **not** prove a separate eventual kernel

### [ComputedBuffer](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/ir.py#L5535)

**Role in the program.** Attaches layout/storage identity to computed loop data so dependencies can be scheduled

**What can go wrong.** A registered buffer can later become internal to a fused kernel; graph outputs cannot just disappear

### [dependencies.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/dependencies.py#L78)

**Role in the program.** Records indexed reads/writes (`MemoryDep`), whole-buffer dependencies and ordering

**What can go wrong.** Reading `buf[i+1]` differs from reading `buf[i]`; sharing a buffer name does not establish fusion legality

### [scheduler.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L5740)

**Role in the program.** Orders buffers/operations, fuses compatible schedule nodes, plans lifetimes and calls backends

**What can go wrong.** Legality, profitability and code-generation support are different decisions

### [choices.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/choices.py#L770)

**Role in the program.** Centralizes policy choices such as scoring candidate fusion

**What can go wrong.** Defaults are policies, not mathematical facts; inspect active configuration

### [kernel/mm.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/kernel/mm.py#L527)

**Role in the program.** Lowers matmul and collects eligible external/template/native strategies

**What can go wrong.** Shape, dtype, device, precision policy and autotuning select different paths

### [select_algorithm.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/select_algorithm.py#L4070)

**Role in the program.** Builds, benchmarks and caches choices; keeps external and generated candidates behind a common interface

**What can go wrong.** A pattern selecting this layer does not guarantee a particular winning kernel

### [codegen/common.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codegen/common.py#L2152)

**Role in the program.** Shared CSE, argument and template infrastructure

**What can go wrong.** Eliminating redundant expressions inside a kernel differs from eliminating a kernel boundary

### [codegen/simd.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codegen/simd.py#L2816)

**Role in the program.** Shared GPU-style loop grouping, reduction planning and scheduling support

**What can go wrong.** A reduction plan must fit backend iteration and synchronization contracts

### [codegen/triton.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codegen/triton.py#L8622)

**Role in the program.** Emits Triton kernels and implements their scheduling capability

**What can go wrong.** Triton is another compiler stage; emitted Triton is not final GPU machine code

### [codegen/cpp.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codegen/cpp.py#L5110)

**Role in the program.** CPU loop generation, vectorization and CPU fusion policy

**What can go wrong.** GPU heuristics and kernel counts cannot be transferred unchanged to this backend

### [codegen/wrapper.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codegen/wrapper.py#L1653)

**Role in the program.** Allocates/reuses storage, marshals arguments and emits kernel/external calls

**What can go wrong.** A single compiled Python callable may contain many launches and library calls

### [cpp_wrapper_cpu.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codegen/cpp_wrapper_cpu.py#L292)

**Role in the program.** Native wrapper generation, including AOT runtime interactions

**What can go wrong.** The wrapper ABI and tensor ownership matter independently of arithmetic codegen

### [codecache.py](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codecache.py#L2051)

**Role in the program.** Caches compiled FX artifacts; [AotCodeCompiler](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/codecache.py#L2684) builds AOT products

**What can go wrong.** Dynamo guards, FX cache, autotune results and device compiler caches are distinct layers

GPU is not synonymous with NVIDIA here: PyTorch uses the `cuda` device spelling for ROCm too. Inductor may generate Triton for AMD, use eligible AMD-specific template/backend choices, or call ATen that reaches a ROCm library. Check the selected candidate and generated source before assigning a kernel to a vendor library. `mm.py` now also has an explicit native matmul IR path (`ops.dot` plus dot reduction); “all matmul is opaque external code” is outdated.

## FX pass families: what problem each collection addresses

A **pass** is one traversal or transformation of the program. A **pattern
matcher** looks for a particular arrangement of operations and checks whether
a replacement is permitted. For example, it might recognize matrix multiply
followed by bias addition and express them as one compound operator. This
changes the description the backend sees; it does not by itself decide how
many kernels run. Training also determines when a rewrite is legal: changing a
forward computation before differentiation can affect the generated backward.

This directory-level map covers the families one should read before hunting individual registrations. It is not a verified list of every rule within those files. [The source README](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/README.md#L1) and [directory](https://github.com/pytorch/pytorch/tree/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes) give the exact snapshot inventory. Activation is conditional: presence on disk does not imply a pass runs for your graph.

### `pre_grad`, `joint_graph`, `post_grad`

**Problem addressed.** Stage-specific orchestrators. Is the optimization allowed before differentiation, on joint work, or only after functionalization?

### `split_cat`, `misc_patterns`, `dedupe_symint_uses`

**Problem addressed.** Remove graph construction artifacts and repeated shape plumbing. Is data movement real or an inverse pair?

### `fuse_attention`, `serialized_patterns`

**Problem addressed.** Recognize large decomposed attention patterns and store generated matcher descriptions. Can a library/specialized attention primitive replace the decomposition?

### `pad_mm`, `decompose_mem_bound_mm`, `b2b_gemm`

**Problem addressed.** Change GEMM strategy for alignment, small/memory-bound cases, or coupled GEMMs. Is a nominal matmul kernel the right implementation?

### `group_batch_fusion`, `mkldnn_fusion`

**Problem addressed.** Aggregate related operations and exploit CPU library/template compound operations. Does batching or a supported epilogue remove launches/traffic?

### `binary_folding`, `freezing_patterns`, `efficient_conv_bn_eval`

**Problem addressed.** Exploit constants/frozen inference state, including weight/bias transforms. Are weights truly fixed and is training excluded?

### `quantization`

**Problem addressed.** Recover/optimize quantized patterns while preserving scale, zero-point, dtype and layout contracts. Which quantization scheme and target are supported?

### `replace_random`, `apply_gumbel_max_trick`

**Problem addressed.** Handle RNG lowering and selected stochastic algorithm substitutions. Are distribution and RNG-state semantics the required equivalence?

### `reinplace`

**Problem addressed.** Recover safe mutation/storage reuse after functionalization. Could an alias or later user observe the overwritten value?

### `reduced_atomic_contention`

**Problem addressed.** Restructure contention-heavy updates. Are reduction order and scatter semantics preserved?

### `ddp_fusion`, `fsdp`, `decomp_comms`, `low_contention_collectives`, `micro_pipeline_tp`

**Problem addressed.** Handle distributed collectives and compute/communication overlap. A local kernel-only cost model misses network and synchronization costs

### `bucketing`, `overlap_preserving_bucketer`, `overlap_scheduling`, `overlap_manual_scheduling`

**Problem addressed.** Group or reorder distributed work without destroying intended overlap. Fewer calls can increase end-to-end latency

### `node_runtime_estimation`, `profile_guided_estimation`, `memory_estimator`

**Problem addressed.** Supply cost information rather than directly rewriting arithmetic. Is this estimate static or measured?

### `auto_chunker`, `fusion_regions`, `control_dependencies`

**Problem addressed.** Represent/work on explicit regions, chunking and order constraints. Which graph boundaries are user or pass imposed?

### `graph_view`, `spmd_check`, `numeric_utils`, `utils`

**Problem addressed.** Analysis, graph checks, numerical comparison and shared utilities. Supporting code is not itself an optimization rule

## How a pattern actually becomes a kernel change

For `t=x+1; y=sin(t)`, combining the two element expressions already avoids a
standalone `t` array. No special rule spelling out exactly that pair is needed.
For a more structured case such as `A@B+bias`, a pattern can expose a compound
operation whose implementation options differ. These are two routes toward
optimization, and they meet later at scheduling/code generation.

`PatternMatcherPass.apply` looks up candidate rules by FX target, matches a subgraph, rejects forbidden mutation/stream crossings, applies the entry's extra check, then invokes its replacement. A graph replacement changes FX; a lowering pattern can instead install a handler that produces Inductor IR when the matched operator is lowered. Matching a multi-operation shape is therefore neither necessary nor sufficient for kernel fusion. An ordinary chain of separately lowered pointwise operators can already compose into one loop expression.

Here **realized** means the compiler has given a computation a buffer identity
for planning. It has not necessarily committed to an independent kernel or a
permanent memory allocation. Later fusion can still make a buffer internal.

The scheduler then works on realized operations. Its [fusion driver](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L6852) considers pairs, tests support/dependencies, ranks candidates, and may benchmark. [Vertical fusion](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L10310) checks that producer writes satisfy consumer indexed reads and that no intermediate dependency forces an intervening node. [Profitability](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L7154) is separate: benchmark fusion is conditional, and several paths bypass generic benchmarking. It is incorrect to say every fusion is empirically autotuned.

### Representative rules, individually explained

Terminology used in the rules: **GEMM** is matrix multiplication; **AMP** is
automatic mixed precision, which introduces conversions between numerical
formats; **fp16**, **bf16**, and **fp32** are floating-point formats with different
precision/range. A **cast** converts formats and may round. **FMA** computes a
multiply-add with a particular fused rounding behavior. **Autotuning** compares
eligible implementations, often by timing them. A rule's **guard** here is its
eligibility check; it is not necessarily a Dynamo runtime cache guard.

Each entry gives a concrete transformation, the relevant guard, the reason, and a non-example. Rationales are inferred from behavior unless a source comment explicitly explains them. These examples describe candidate transformations, not exact launch counts.

#### Rule 1. Reciprocal of square root → reciprocal square root.

`reciprocal(sqrt(v)) → rsqrt(v)`. [Rule](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1899). Structural match has no additional rule-specific predicate. For RMSNorm's nonnegative second moment plus positive epsilon, this exposes the direct reciprocal-square-root operation. The source comment says it saves one generated operation. It does not prove bitwise equivalence of every floating-point implementation, nor match `1/(sqrt(v)+eps)`.

#### Rule 2. Remove a redundant conversion chain.

`fp16 x → fp32 → fp16` can become `x → fp16`; `fp32 x → fp16 → fp32` is retained because the intermediate dtype is narrower than the final dtype. [Rule](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/joint_graph.py#L929). Only listed floating dtypes participate; `emulate_precision_casts` additionally requires the first conversion to be lossless.

Why: AMP generates conversion chains, but narrowing then widening can encode real rounding. Equal byte widths do not imply equal numerical formats: bf16 and fp16 require attention to the precision policy.

#### Rule 3. Two GEMMs plus add → a specialized algorithm choice.

`[M,K]@[K,N] + [M,L]@[L,N]` routes to `tuned_mm_plus_mm`. [Guard/replacement](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L990). Requires max-autotune or max-autotune-GEMM, metadata, matching output extents and valid reduction extents; BF16x9 paths are excluded.

Why: a combined implementation may avoid intermediate outputs and an add launch. Unlike factoring `A@B+A@D`, it does not require shared inputs. The selected lowering still chooses an implementation; this pattern alone is no one-kernel guarantee.

#### Rule 4. Matmul plus bias → `addmm`.

`A@B + bias` or `bias + A@B` becomes `addmm(bias,A,B)`. [Guard/rule](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L2090). Bias must be tensor-valued, broadcastable to the output and dtype-compatible; preserved GEMM forms and the preference for unfusing block it.

Why: `addmm` exposes a compound operation to library/template choices. An integer scalar bias or mismatched float dtype fails the guard, even if Python accepts the original add through promotion.

#### Rule 5. Deliberately unfuse `addmm` to improve later fusion.

`relu(addmm(bias,A,B))` may become `relu(bias + A@B)`. [Guard and replacement](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1934). GPU, matching dtype/device, bias-like input and all-pointwise users are required, with extra precision exceptions.

Why (architectural inference): the pointwise tail can become one generated epilogue even when the GEMM strategy changes. This is operator unfusing in service of kernel planning, not evidence that the final program necessarily has more kernels.

#### Rule 6. The half-precision `addmm` exception is chip-relevant.

In rule 5, `keep_addmm_fused_for_half_dtypes` keeps fp16/bf16 fused outside the XPU-specific narrowing-cast case. [Comment](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L2012) explicitly cites ROCm `gfx950` training+AMP accuracy regression. Example: bf16 bias on AMD plus bf16 GEMM and pointwise consumers can structurally match yet return without rewriting. Do not attribute this only to speed: preserving where rounding occurs is the stated motivation. The comment references PR #183680; the shallow checkout alone does not establish the complete historical rationale.

#### Rule 7. Reconstruct `addcdiv` after decomposition.

`inp + (t1/t2)*value → aten.addcdiv(inp,t1,t2,value=value)`. [Guard and source rationale](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L2147). All three tensors must be floating, output on `cuda`/`xpu`, and `value` scalar rather than FX tensor node.

Why: CompositeImplicitAutograd decomposed the original operation, hiding its FMA-aware lowering; reconstructing it makes `tl.fma` plus rounded division reachable. Integer `inp` must not pass merely because division promoted the result to float.

#### Rule 8. Constant-filled cumulative sum → arithmetic progression.

`cumsum(full([2,4],3,int64), dim=1)` produces rows `[3,6,9,12]` without a general scan. [Rule](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1035). Scalar shape is excluded; symbolic fill restrictions and boolean handling matter.

Why: the source identifies an OPTForCausalLM pattern. For integer/bool output the replacement first reproduces `full`'s fill cast. `full(...,2.9,int64)` therefore starts from 2, not a late cast of `[2.9,5.8,...]`. The source documents an unresolved symbolic boolean-fill workaround: this is a sharp edge, not an unrestricted algebraic theorem.

#### Rule 9. Fold cat → prefix slice → cat.

Let `a:[B,5]`, `b:[B,7]`, `t=cat([a,b],1)`. `cat([t,t[:,:3]],1)` becomes `cat([a,b,a[:,:3]],1)`. [Rule](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1104). The size must be nonnegative and statically known to fit the first cat input.

Why: eliminate the intermediate concatenation/copy. With prefix length 8, the prefix extends into `b`; this replacement is invalid, and the lowering keeps the two-cat form.

#### Rule 10. Split then cat → original input.

`cat(split_with_sizes(x,[2,3],dim=1),dim=1) → x`. [Guard](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1162), [replacement](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1816). All pieces, original order, matching dimensions are required. Reordering the pieces or omitting one is not an identity.

Why: remove a materialization caused only by graph syntax. Metadata/alias behavior is handled in the compiler context; this is not permission to replace an eager allocating `cat` with a mutable alias in arbitrary Python.

#### Rule 11. Cat then exact split → original list.

`split_with_sizes(cat([a,b],1),[a.shape[1],b.shape[1]],1) → [a,b]`. [Guard/rule](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/fx_passes/post_grad.py#L1842). The cat must have no other users, split sizes must match each input and dimensions/counts must agree.

Why: avoid packing values only to unpack the exact same regions. A second consumer of the concatenated tensor prevents this particular elimination; unequal cut points need views spanning inputs rather than this replacement.

#### Rule 12. Mean lowering explicitly accounts for accumulation dtype.

A half/bfloat16 `mean(x,axis)` is lowered through float32 accumulation, division by the symbolic reduction size and conversion to output dtype. [Lowering](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/lowering.py#L7466). For `[B,H]` reduce axis 1, each row sum divides by `H`, not total `B*H`.

Why: low-precision accumulation loses accuracy. This does not automatically upgrade the multiply in `mean(x*x)`: multiplication occurred before the mean unless the graph cast earlier.

#### Rule 13. Empty sum reduction → correctly typed identity.

A reduction with reduction extent zero produces a pointwise identity instead of a reduction loop. [Reduction.create](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/ir.py#L1767). `sum(empty([B,0]),1)` becomes B zeros; product uses ones; only supported identity-bearing reduction types use this path.

Why: no reduction work exists, but shape and dtype still exist. Max over an empty domain is not covered by this sum identity.

#### Rule 14. Long reduction → staged partial reductions.

`sum(x[B,H],1)` may become partial sums `[B,S]` then final reduction over S. [Selection](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/ir.py#L1503), [creation](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/ir.py#L1767). Device, reduction kind, hints, configuration and size policy determine splitting.

Why: one reduction instance may otherwise expose insufficient parallelism or use too many resources. The introduced intermediate may require an additional kernel; no claim that every size above a fixed H threshold splits on every GPU.

#### Rule 15. Vertical fusion requires matching indexed dependencies.

A producer writing `tmp[i]` and consumer reading `tmp[i]` is a straightforward candidate; consumer reading `tmp[i+1]` does not satisfy that same indexed dependency. [Check](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L10310).

Why: a thread/block cannot assume another producer's value exists at the required moment. A separate layout/index transformation might make another plan legal; “same buffer” alone is insufficient.

#### Rule 16. Template input fusion accepts only supported pointwise producers.

`tmp = x*scale; y=tmp@W` may admit template prologue fusion, whereas `tmp=RMSNorm(x); y=tmp@W` cannot pass this generic path as a reduction producer. [Checks](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L10050). Must enable prologues, select a template with allowed input slots, avoid aliasing/mutation and satisfy use restrictions and heuristics.

Why: a matmul tile loader can often evaluate an elementwise expression; a row-wide reduction has a different synchronization contract. Even `x*scale` is rejected if an external BLAS call wins.

## Worked kernel-boundary analysis: residual RMSNorm → matmul

Use explicit arithmetic so that the example specifies intermediate precision and avoids assuming how a native fused RMSNorm operator is dispatched:

```python
def block(x, residual, weight, matrix, bias, eps=1e-6):
    # x, residual: [B,H]; weight: [H]; matrix: [H,N]; bias: [N]
    z = x.float() + residual.float()
    inv = torch.rsqrt((z * z).mean(-1, keepdim=True) + eps)
    normalized = (z * inv * weight.float()).to(x.dtype)
    y = torch.nn.functional.gelu(normalized @ matrix + bias)
    return y, z, inv
```

This is deliberately **fp32 residual addition**. It is not equivalent in rounding to `(x+residual).float()` for low-precision inputs, or necessarily identical to a native `rms_norm` implementation. Returning `z` and `inv` forces observable outputs; remove those returns to study internal-only values.

Follow one row through the stages. Here `B` is the number of rows, `H` the
number of input features, and `N` the number of output features. GELU is the
activation applied independently to each matrix-multiply result.

```text
z[b,h]   = float(x[b,h]) + float(residual[b,h])
m[b]     = sum_h(z[b,h]^2) / H
inv[b]   = rsqrt(m[b] + eps)
n[b,h]   = cast(z[b,h] * inv[b] * weight[h])
y[b,j]   = GELU(sum_h(n[b,h] * matrix[h,j]) + bias[j])
```

The first reduction computes one scalar per row. Normalization then uses that
scalar at every feature position. Matrix multiplication consumes the whole
normalized row to produce `N` outputs. That change in how values are shared
explains why the boundary before matrix multiplication is interesting.

### FX and loop lowering.

Pointwise producers can be composed into the reduction body, so no standalone `z*z` buffer need exist. `mean` produces a reduction and division; rsqrt is a pointwise expression on the row scalar. The normalized output broadcasts this scalar over H. Views/broadcasts are indexing, not automatically copies. Realization names the intermediate computations needed for scheduling, but the final scheduler can still remove some storage boundaries.

### Candidate plan A: row reduction plus normalization kernel, then external GEMM, then epilogue.

A compatible GPU backend can generate a row-oriented reduction kernel with residual addition and normalization around it. With returned `z`/`inv`, it must also store them.

An external GEMM needs normalized input in addressable storage; its internal accumulator cannot be modified by the general Inductor pointwise scheduler.

Bias/GELU may remain a separate generated tail unless the chosen external operation already offers that exact fused capability. This is a candidate three-stage plan, not an observed universal count; reduction splitting or resource constraints can add stages.

### Candidate plan B: generated matmul template with epilogue.

Keep RMSNorm computation separate and produce normalized storage. Select a matmul template supporting the bias/GELU epilogue, allowing GEMM and tail to become one generated kernel.

The winning choice can differ from the fastest standalone GEMM because saving intermediate traffic/launches changes the end-to-end cost. Calling the outer function “one compiled graph” does not merge the normalization launch into this matmul launch.

### Candidate plan C: keep row statistics separate, fuse only the remaining pointwise normalization into matmul loads.

Compute/store the needed row statistic, then consider `(z * inv * weight).to(dtype)` as a pointwise producer of a template input. This can pass the *kind* restriction that a full reduction producer fails, but only with suitable allowed input slots, use counts, precision/layout support and profitability.

Extra consumers of normalized data can block it.

This may trade away normalized storage for repeated normalization across matmul tiles. It is a conditional architecture possibility, not a claim that this checkout selects it for these dimensions.

### Why cannot the generic path simply inline the entire RMSNorm into every matmul tile?

Each normalized element depends on the whole H row.

Matmul tiles independently process K slices and N columns; inserting a row reduction changes the algorithm and may repeat it per output-column tile.

Fusion must specify synchronization, register/shared-memory usage and recomputation. The generic template-prologue code explicitly rejects a reduction producer; a specialized fused algorithm, native matmul path or future backend capability is a different route, not an exception you can infer from adjacency in FX.

### Multiple outputs.

Returning `z` forces z storage even if its computation shares a kernel with statistics. Returning `inv` costs only `[B,1]` storage but still extends its lifetime.

Returning `normalized` too creates a use beyond the matmul template, defeating the generic single-use prologue condition.

Multiple outputs do not inherently mean multiple kernels: a generated kernel can write several output arrays. Conversely, storage writes do not disappear merely because arithmetic has fused.

### Two kinds of reduction.

RMSNorm reduces H independently per B row. GEMM reduces H independently per `(B,N)` output and wants a matrix tiling/data reuse strategy. The equal symbol H is not evidence that these are interchangeable loop domains. A strict-reduction ordering contract further restricts fusion; [scheduler checks](https://github.com/pytorch/pytorch/blob/e52fd8ff9759e1c4bea7adcf63ca22717fe5e8df/torch/_inductor/scheduler.py#L9930) reject several such combinations.

### Training.

For `n=z*q*w`, with `q=(mean(z²)+eps)^(-1/2)` and upstream derivative `g`, ignoring casts for the analytic formula:

`dz = q*(g*w) - z*q³*mean((g*w)*z, axis=-1, keepdim=True)`.

`dw` sums `g*z*q` over batch dimensions.

Matmul backward adds GEMMs for the normalized-input and matrix gradients. AOTAutograd decides which intermediates to save versus recompute, then Inductor compiles resulting forward/backward graphs.

Saving z or q introduces materialized outputs from the compiled forward even if the Python function did not return them. Gradient casts and reduction accumulation can differ from this idealized real-number derivative. Do not take an inference launch count and append “one backward kernel.”

## Executed CPU comparison: what the schematic plans do not establish

The separate [RMSNorm eager versus compile study](rmsnorm-eager-vs-compile.md) executed an installed **PyTorch 2.11.0+cu130 wheel**, not this source checkout.

For its float32 `[8,128]` CPU case, full RMSNorm used one generated C++ wrapper call, while deliberately staging regions used three.

The fused CPU callable retained row scratch and two inner loops under a shared outer loop: eliminating a function/kernel boundary did not mean eliminating every temporary or loop.

RMSNorm → matmul retained an `extern_kernels.mm` call after the normalization callable. The compiler's generated-kernel metrics differed from wrapper invocation counts. These observations concretely support the distinctions above without predicting AMD GPU launches or newer-main behavior.

## AOTI, caching, and what to inspect when a result surprises you

The arithmetic kernel is only part of an executable program. Something must
allocate arrays, pass their addresses and sizes, and call each kernel in order.
That surrounding code is the **wrapper**. An **ABI** is the agreement between
caller and callee about arguments, ownership, and returned results. Packaging
compiled work for later use must preserve that agreement too.

AOTInductor packages compiled kernels and a native wrapper/runtime contract. It does not make external operations disappear; inspect the wrapper's external call sites. Likewise, a warm cache changes compile latency, not necessarily the set of arithmetic kernels. FX graph cache entries, algorithm timing records and compiled-device binaries have different keys and invalidation concerns.

For a specific workload collect its exact input shapes/strides/dtypes, forward and backward FX graphs, pre/post-fusion IR, generated wrapper and kernel code, and selected matmul choice. A useful kernel inventory has separate columns for generated kernels, external calls, and runtime launches observed by a profiler. A scheduler node count or an Inductor “generated kernel” metric alone cannot count launches hidden inside a library operation. Tests against an older installed wheel are valuable behavior examples, but cannot validate this source snapshot's newer rules.
