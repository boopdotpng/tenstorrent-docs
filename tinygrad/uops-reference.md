# UOps reference

This is the complete `Ops` enum at tinygrad commit
`4234a9d727e52a6bb033c387d2c869cea4caf641` (2026-07-10): **82 ops** in enum
order. The ordinals are useful when reading this revision, but are not a stable
ABI. Enum order also affects preferred UOp ordering, so reordering is not
cosmetic.

The "phase" column is shorthand:

- **all**: structural value used across phases;
- **tensor**: lazy Tensor/function graph;
- **schedule**: rangeification, kernel splitting, or call scheduling;
- **program**: target-independent lowered kernel;
- **target**: renderer, instruction selection, or command submission;
- **matcher**: internal IR for compiling `UPat` patterns.

The legal subset and exact source/argument form come from
`tinygrad/uop/spec.py`. See [the internals guide](internals-guide.md) for the
phase flow.

## Definitions, calls, and containers

| # | Op | Phase | Meaning and important detail |
|---:|---|---|---|
| 1 | `BIND` | all | Pairs a symbolic `PARAM` with a concrete value. Scheduling records the value and later removes the binding node. |
| 2 | `SPECIAL` | program | A hardware launch dimension/work-item coordinate, such as a global or local GPU index. It is range-like but not an ordinary shape variable. |
| 3 | `BUFFER` | all | Defines storage with shape, dtype, device, slot, and address-space metadata. Concrete runtime buffers live in a weak side table. Current code no longer uses `PtrDType`. |
| 4 | `NOOP` | all | Explicit no-op, passthrough, or temporary structural placeholder. Cleanup matchers normally remove it. |
| 5 | `REWRITE_ERROR` | all | Sentinel used to surface an invalid or failed rewrite rather than silently accepting it. |
| 6 | `PARAM` | all | Function/kernel argument or symbolic scalar. `ParamArg` carries slot, dtype, device, address space, and related metadata; shape is a UOp source. |
| 7 | `FUNCTION` | tensor | Differentiable graph function. Its body returns a `TUPLE`; unlike an opaque `CALL`, it can participate in gradient rewriting. |
| 8 | `CALL` | all | Opaque invocation whose first source is the callee/body and remaining sources are arguments. Used for scheduled kernels, copies, views, and runtime functions. |
| 9 | `PROGRAM` | program | Progressive compiled-program container. It grows from `PROGRAM(SINK)` to include `LINEAR`, `SOURCE`, and `BINARY`. |
| 10 | `LINEAR` | schedule/program | Ordered sequence. At schedule level it contains `CALL`s; inside `PROGRAM` it contains the ordered low-level UOps for one kernel. |
| 11 | `SOURCE` | target | Human-readable rendered source or assembly text. |
| 12 | `BINARY` | target | Compiled or assembled program bytes. |
| 13 | `SINK` | all | Root that keeps requested values/effects reachable. A kernel `SINK` also carries `KernelInfo`. It does not by itself order sources. |
| 14 | `AFTER` | tensor/schedule | Returns `src[0]` while promising that consumers occur after `src[1:]`. Mutation and buffer-state ordering remain explicit in a functional DAG. |
| 15 | `GROUP` | all | Shapeless structural merge/no-op used to collect operations. Nested or one-item groups are commonly flattened. |
| 16 | `STACK` | all | Adds a leading axis by collecting equally typed values. It represents shaped/vector-like data, shape tuples, and late lane expansion; its dtype remains the element dtype. |
| 17 | `TUPLE` | tensor | Packs multiple function results. |
| 18 | `GETTUPLE` | tensor | Selects one result from a `TUPLE` or function result. |
| 19 | `GETADDR` | target | Requests a 64-bit buffer address in the HCQ/command-queue path. It has scalar shape. |

## Addressing and memory

| # | Op | Phase | Meaning and important detail |
|---:|---|---|---|
| 20 | `INDEX` | schedule/program | Forms an indexed storage reference from a buffer-like source and index expressions. Validity may be carried by an index `WHERE` until moved to an explicit gate. With pointer dtypes removed, addressability comes from the source/address space rather than a pointer-typed dtype. |
| 21 | `SHRINK` | tensor/program | Tensor movement that keeps `[begin,end)` regions; late code can also use it as a narrowed storage/index view. It is phase-overloaded. |
| 22 | `LOAD` | program | Reads an indexed global/local/register value. Alternate values or a gate can appear in later sources depending on lowering point. |
| 23 | `STORE` | tensor/program | Writes a value to an indexed destination, optionally under a gate. It is void; assignment's returned buffer state is represented by `AFTER`. |

## Matrix and elementwise math

| # | Op | Arity | Meaning and important detail |
|---:|---|---:|---|
| 24 | `WMMA` | 3 | Warp/tensor-core matrix multiply-accumulate. Its output dtype/shape follow the accumulator and its configuration remains target specific. |
| 25 | `CAST` | 1 | Numerically converts to the dtype carried in `arg`. |
| 26 | `BITCAST` | 1 | Reinterprets bits as another dtype; item-size changes adjust the last shape dimension. |
| 27 | `EXP2` | 1 | Base-2 exponential. Kept native when supported or decomposed to software math. |
| 28 | `LOG2` | 1 | Base-2 logarithm. Native or decomposed. |
| 29 | `SIN` | 1 | Sine. Native or decomposed. |
| 30 | `SQRT` | 1 | Square root. Native or decomposed. |
| 31 | `RECIPROCAL` | 1 | `1/x`. May replace floating division or be target-decomposed. |
| 32 | `NEG` | 1 | Arithmetic negation; often decomposed when the target lacks it. |
| 33 | `TRUNC` | 1 | Floating-point truncation toward zero. |
| 34 | `ADD` | 2 | Addition. Commutative, associative, and a legal reduction operator. |
| 35 | `MUL` | 2 | Multiplication. Commutative, associative, and a legal reduction operator. |
| 36 | `SHL` | 2 | Integer left shift. |
| 37 | `SHR` | 2 | Integer right shift, with signedness determined by dtype/renderer. |
| 38 | `CDIV` | 2 | C-style/truncating integer division. Distinct from floor division for negative operands. |
| 39 | `MAX` | 2 | Maximum. Commutative, associative, idempotent, and a legal reduction operator. |
| 40 | `CMOD` | 2 | Remainder paired with truncating `CDIV`. Distinct from floor modulo for negative operands. |
| 41 | `CMPLT` | 2 | Less-than comparison; produces boolean. |
| 42 | `CMPNE` | 2 | Not-equal comparison; produces boolean. |
| 43 | `CMPEQ` | 2 | Equal comparison; produces boolean. |
| 44 | `XOR` | 2 | Bitwise/logical exclusive-or. |
| 45 | `OR` | 2 | Bitwise/logical or; associative and idempotent. |
| 46 | `AND` | 2 | Bitwise/logical and; associative and idempotent. |
| 47 | `THREEFRY` | 2 | Threefry counter-based pseudo-random mixing primitive; decomposed if unsupported. |
| 48 | `SUB` | 2 | Subtraction. Usually late-legalized if a target lacks it. |
| 49 | `FDIV` | 2 | Floating-point division. It can become multiply-by-reciprocal. |
| 50 | `POW` | 2 | Power. Often decomposed through log/exp or integer-exponent cases. |
| 51 | `FLOORDIV` | 2 | Mathematical integer floor division. Index algebra uses this heavily. |
| 52 | `FLOORMOD` | 2 | Modulo paired with floor division. Index algebra uses it heavily. |
| 53 | `WHERE` | 3 | Selects source 1 when boolean source 0 is true, otherwise source 2. It also carries invalid/padding index semantics in intermediate graphs. |
| 54 | `MULACC` | 3 | Abstract/fused `a*b+c`; target lowering decides whether it remains fused. |

`GroupOp.Unary`, `Binary`, `Ternary`, `ALU`, `Elementwise`, `Commutative`,
`Associative`, `Idempotent`, and `Reduce` are compiler classifications over
these ops, not additional UOps.

## Control flow, constants, and target escape hatches

| # | Op | Phase | Meaning and important detail |
|---:|---|---|---|
| 55 | `BARRIER` | program/target | Synchronizes participating work-items or represents a target barrier dependency. |
| 56 | `RANGE` | schedule/program | Iterator over `[0,bound)`, annotated with an axis type such as global, local, reduce, upcast, or unroll. |
| 57 | `IF` | program | Begins explicit conditional control flow. Gated stores are converted to it only when needed. |
| 58 | `END` | schedule/program | Closes one or more ranges/regions. Multi-range ends are split before final ordering. |
| 59 | `ENDIF` | program | Ends an `IF` region. |
| 60 | `WAIT` | target | Waits on a signal/timeline or queue event, principally in HCQ lowering. |
| 61 | `CONST` | all | Typed scalar constant. Shaped constants are represented with `STACK`, not vector dtypes. |
| 62 | `CUSTOM` | target/matcher | Custom formatted output or internal callable/predicate node. It is an escape hatch, not portable computation. |
| 63 | `CUSTOMI` | target/matcher | Inline variant used by renderers and compiled pattern machinery. |
| 64 | `INS` | target | One selected machine instruction plus target-specific operands/metadata. Used by ISA renderers. |

## Tensor- and scheduler-only ops

These should be gone from an ordinary final program. Seeing one at the renderer
usually means a pass was skipped or the target deliberately owns custom
lowering.

| # | Op | Phase | Meaning and important detail |
|---:|---|---|---|
| 65 | `CONTIGUOUS` | tensor | Requests materialization with contiguous layout. Callify/rangeify decides whether it needs storage or can be a view. |
| 66 | `CONTIGUOUS_BACKWARD` | tensor | Gradient-side marker requesting contiguous behavior in the backward pass. |
| 67 | `DETACH` | tensor | Stops gradient propagation; forward computation otherwise passes through. |
| 68 | `STAGE` | schedule | Materialization/bufferization boundary. Later passes choose global/local storage and emit stores. |
| 69 | `COPY` | tensor/schedule | Device or host copy executed as its own call rather than ordinary ALU codegen. |
| 70 | `SLICE` | schedule/runtime | Zero-copy offset/length view of an allocated buffer, also used by temporary arena suballocation. Do not confuse it with initial Tensor slicing. |
| 71 | `MSELECT` | tensor/schedule | Selects one shard/device value from a multi-device aggregate. |
| 72 | `MSTACK` | tensor/schedule | Collects per-device values into a multi-device aggregate. |
| 73 | `CUSTOM_FUNCTION` | tensor/runtime | Opaque operation dispatched by name, including encode/decode, graph, HCQ, and validation helpers. |
| 74 | `RESHAPE` | tensor/program intermediate | Row-major shape reinterpretation with equal element count. Rangeify turns Tensor reshape into index arithmetic; current shape-based codegen also uses reshape while expanding lanes. |
| 75 | `PERMUTE` | tensor/program intermediate | Reorders axes. Rangeify maps coordinates; current expansion/codegen also uses it for shaped lane order. |
| 76 | `EXPAND` | tensor/program intermediate | Prepends broadcast dimensions without storage. General Tensor broadcasting first reshapes/permutates existing size-one axes so the needed dimensions can be prepended; rangeify drops those new leading coordinates. Current codegen also uses it while making broadcasting explicit. |
| 77 | `PAD` | tensor | Adds zero/invalid regions. Rangeify creates coordinate offsets and an explicit validity predicate. |
| 78 | `FLIP` | tensor | Reverses selected axes. Rangeify maps coordinate `i` to `size-1-i`. |
| 79 | `MULTI` | tensor | Wrapper/movement op for a value distributed across devices/shards. Multi-device rewriting distributes or removes it. |
| 80 | `REDUCE` | tensor/program | Reduces with `ADD`, `MUL`, or `MAX`. Tensor form names leading axes; rangeified form depends on reduction `RANGE`s; codegen replaces it with local accumulators/horizontal trees. |
| 81 | `ALLREDUCE` | tensor/schedule | Cross-device reduction with an operation and target devices. Multi-device scheduling lowers it to communication plus local work. |

## Pattern-compiler IR

| # | Op | Phase | Meaning and important detail |
|---:|---|---|---|
| 82 | `PYLITERAL` | matcher | Carries an arbitrary Python literal in `arg` while `upat.py` builds/optimizes the internal graph used to compile a `UPat`. It is compiler infrastructure, not a Tensor or device-program op. |

## Ops that are easy to misread

- `STACK` is not always a user-visible Tensor stack. It is the current shaped
  lane/constant representation and also packs shape expressions.
- `SHRINK` starts as Tensor movement but can describe narrowed storage late.
- `SLICE` is an allocated buffer view, not the first form of `tensor[a:b]`.
- `WMMA` means a warp/fragment tensor-core primitive, not generic tiled matmul
  and not directly a Tensix program.
- `RESHAPE`, `PERMUTE`, and `EXPAND` are tensor-only semantically, but the July
  2026 codegen deliberately reuses them for shape-based lane expansion before
  eliminating them.
- `PROGRAM` is progressive: its source pattern determines whether it is
  unlinearized, rendered, or compiled.
- `LINEAR` means either ordered calls (outer schedule) or ordered operations
  (one program), depending on its parent.
- `STORE` does not return the assigned value. `AFTER(buffer, store, ...)`
  represents the new ordered buffer state.

## What changed in the July 2026 codegen rewrite

The previous July 2 enum had 85 ops. Current master:

- removed `GEP`; shaped `INDEX`/`STACK` now express lane extraction;
- removed `UNROLL` and `CONTRACT`; expansion uses shaped
  `RESHAPE`/`PERMUTE`/`STACK` transformations;
- removed `SHAPED_WMMA`; `WMMA` itself carries the shaped form until expanded;
- added `PYLITERAL` for compiled pattern predicates;
- removed vector dtypes and `PtrDType` in favor of explicit shapes and address
  space metadata;
- introduced a distinct `dtypes.index`, then lowers it to target integer types.

This is why an op list without a commit is unreliable even when it is only a
week old.

## What is not a UOp

`AxisType`, `OptOps`, dtypes, `KernelInfo`, `ProgramInfo`, `BufferizeOpts`,
renderer capabilities, and runtime queue objects are metadata/enums consumed by
UOps and passes. They matter, but are not members of the IR op enum.

The standalone May 2026 `tinyspec` is a conceptual snapshot. Its `BufferView`,
`Vconst`, `Replicated`, and `AtomicAdd` entries are not in this current enum;
current code uses `SLICE`, `STACK`/scalar `CONST`, multi-device ops, and
target-specific lowering instead.
