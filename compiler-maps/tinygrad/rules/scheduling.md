# Scheduling rules, individually

## Read this first: why a scheduler exists

For `t = A + B; y = t * 2`, the array result is clear, but there are two possible execution plans. One launches a kernel to store `t` in a temporary buffer, then another kernel reads that temporary to produce `y`. Another launches one kernel computing `(A[i]+B[i])*2` for each output element, keeping the intermediate in a worker's local arithmetic. The latter removes a launch and temporary memory traffic. Choosing and ordering such pieces of work is **scheduling**; removing a producer/consumer boundary is **kernel fusion**.

Fusion becomes harder for `s[row] = sum(x[row,:]**2)` followed by `y[row,col] = x[row,col] / sqrt(s[row]/N + eps)`. Many output columns reuse one row statistic. Inlining its formula into each output could recompute the entire reduction per column; sharing it inside one kernel needs a suitable worker layout and synchronization. The rules here make concrete, conservative decisions about those tradeoffs. They do not assume that every pair of adjacent Python operations should form a single kernel.

| Term | Meaning used below |
| --- | --- |
| UOp / PatternMatcher (PM) | A graph node describing work / an ordered set of patterns and callbacks that recognize and transform those nodes |
| Source / base | An input node of an operation / the underlying storage or value after relevant view wrappers are peeled |
| Buffer / materialize / realize | Storage for elements / compute and store a value there / the scheduler's term for requiring that storage-backed value |
| View / movement operation | A coordinate reinterpretation such as reshape, transpose, slicing, or broadcast; it can often be represented by indexing without copying |
| Range / extent / axis | An explicit iteration coordinate / number of its possible positions / the logical dimension it describes |
| Reduction / identity | Combine many inputs with an operator / neutral value for that operator, such as 0 for sum |
| Mask / validity / gate | A Boolean condition saying which coordinates exist or which accesses should occur |
| STAGE / INDEX | A proposed stored intermediate over producer coordinates / selecting that intermediate at consumer coordinates |
| STORE / END / SINK | Write a value / close specified iteration ranges around work / collect required work at a graph root |
| AFTER | The value or buffer state that may be used only after specified effects have happened |
| PARAM / CALL / ABI | A function's formal argument / invocation with actual arguments / calling convention mapping argument positions to values |
| ALU / CAST / BITCAST | Arithmetic or logical operation / numeric conversion / reinterpretation preserving bits |
| GLOBAL / LOCAL | Storage accessible across device kernels / storage shared within a workgroup inside one kernel |

In `END(STORE(out[i],v),i)`, the store's work is complete for all values of `i`; `i` is a **closed** range. A range that the expression still needs from an enclosing context is **open**. A separately launchable kernel must account for its iteration domain, rather than silently depending on the caller's unfinished loop. DEVICE ranges are special because the launch machinery chooses which device runs the work.

Buffer identity and buffer **state** are different. If a kernel overwrites `A`, both the old and new contents have the same address. `AFTER(A,write)` lets the graph distinguish which contents a consumer expects. **RAW**, read after write, orders a producer before its consumer. **WAR**, write after read, orders an old-value reader before an overwrite. For `B = A+1; A = 0`, the first launch must finish reading A before the second destroys those values, even though B is not an input to the second launch.

A **workgroup** is a set of GPU workers that can share LOCAL memory and synchronize inside one kernel. A **shard** is one owner’s portion of a logical tensor; `UNSHARD` describes the logical tensor represented by those portions, while `MSTACK` and `MSELECT` group and select per-device values. Their communication rules are developed in the Multi section. **Contiguous** means the logical elements have the required dense storage layout; a self-device COPY can request that layout without changing devices.

Parameter slots also have scope: slot 0 in one function can mean its output buffer, while slot 0 in a nested function means a different argument. Reusing a cached schedule must bind each function's slots to its own CALL arguments and give each invocation fresh anonymous temporaries. The final section explains these rules.

The entries keep exact source guards because those guards say where the intuitive explanation stops being safe. A callback returning `None` may still record a fact in a **context** for a later rule; it has not necessarily done nothing. `marg` means movement arguments; `numel` is the product of shape dimensions. A **weak dtype** is unresolved type/promotion information; committing it chooses a concrete storage dtype. A **tag** is compiler bookkeeping, not a tensor element.

Source snapshot: tinygrad `107adc31701df0247dfa45e175984df906a68b53` (master). This chapter covers every rule tuple in `schedule/{__init__,prepare,indexing,multi,rangeify}.py`; composed matchers are identified below. Examples are **schematic UOp rewrites**, source-reviewed rather than executable test results. `S(v; r)` means `STAGE(v, r)`, a proposed materialization; `I(b,i)` means `INDEX(b,i)`. `after(b, store(...))` identifies the buffer *state after* a write, not merely its address. `U(v,axis)` means `UNSHARD` of local shards; it does not itself copy them together. Reasons marked **inference** explain the current mechanism; they are not claims about an undocumented historical commit.

The important kernel boundary is `STAGE → BUFFER + STORE/END + AFTER → CALL`. Range propagation proposes boundaries; the cost rule can remove some; buffer-count limits can add others. An arithmetic simplification inside a kernel is not kernel fusion. For example, removing a `STAGE(x*scale)` consumed by an epilogue can erase a global temporary and its producer launch. Removing a stage containing a buffer-reading RMSNorm reduction is expressly rejected by the current cost rule.

## Prepare: normalize tensor semantics before deciding kernels

Preparation preserves the meaning of array operations before choosing where to cut the computation into kernels: views become coordinate formulas, explicit copies become stored values, and assignments retain the old inputs they need. **Bottom-up** rewriting processes inputs before the operations that use them; `pm_a + pm_b` concatenates two ordered matcher lists.

`prepare_rangeify` runs `multi_pm`, optionally `pm_fold_moved_after` under `OPENPILOT_HACKS`, then bottom-up `pm_mops + earliest_rewrites`. `earliest_rewrites` begins with imported `mop_cleanup`; its movement rules are catalogued with the UOp movement module, not duplicated here. Stateful callbacks that return `None` still matter: they may update context or reject invalid graphs.

### schedule/prepare.py:L27 — Remember a materialized moved value

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L27). **Match → action:** `AFTER(buffer, STORE(dst, src))`, where src is movement/CAST/WHERE, calls `found_after`: peel PERMUTE with inverse permutation, RESHAPE with original shape, and invalid-WHERE over PAD with a shrink; record original value → restored view of AFTER. With FLOAT16, a half CAST is peeled and the restored materialized value cast to float.

**Example:** If `b := contiguous(x.T)`, record `x → b.T`; a subsequent consumer can reuse b rather than recompute x.

**Why:** Source labels this an openpilot hack: reuse already-materialized work through reversible views.

**Sharp edge:** Only the listed inversions are supported; arbitrary CAST/WHERE is not inverted. FLOAT16 reuse incorporates half rounding.

### schedule/prepare.py:L29 — Remember contiguous COPY as a materialization

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L29). **Match → action:** COPY of movement/CAST/WHERE uses the same context collector only when `is_self_copy`.

**Example:** `COPY_same_device(reshape(x))` records x → reshape-back(COPY).

**Why:** Source explicitly says contiguous is also a materialization point.

**Sharp edge:** Cross-device COPY does not participate in this hack.

### schedule/prepare.py:L32 — Redirect arithmetic to remembered materializations

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L32). **Match → action:** Every ALU substitutes immediate sources found in the context map, returning a replacement only if sources changed.

**Example:** `x + y → reshape_back(materialized_x) + y`.

**Why:** Inference: make the preceding two collector rules affect later compute and possible kernel boundaries.

**Sharp edge:** This is context/order-sensitive reuse, not a general common-subexpression proof.

### schedule/prepare.py:L49 — Translate views into index arithmetic

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L49). **Match → action:** INDEX of a movement op calls `apply_movement_op` when indexing all dimensions. Partial RESHAPE indexing is allowed only when the untouched suffix matches; a zero-length indexed prefix returns the base, otherwise result shape must agree.

**Example:** `INDEX(reshape(A[2,3], [6]), k) → INDEX(A, k//3, k%3)`; `INDEX(permute(A,[1,0]),i,j) → INDEX(A,j,i)`.

**Why:** Inference: memory access can encode a view without a transpose kernel.

**Sharp edge:** Partial indexing of arbitrary views is deliberately unsupported; PAD also carries validity.

For the reshape example, flat index `k=4` maps to `(4//3,4%3)=(1,1)`: row 1, column 1 of the original 2×3 array. Computing that address gives the desired value without physically rearranging all six elements. The same reasoning fails for an unhandled partial view, which is why the guards matter.

### schedule/prepare.py:L51 — Move a view outside AFTER

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L51). **Match → action:** `AFTER(view_or_INDEX(base), deps...) → view_or_INDEX(AFTER(base,deps...), original view operands)`.

**Example:** `after(reshape(b,[2,3]), write) → reshape(after(b,write),[2,3])`.

**Why:** Inference: attach mutation state to storage, retaining the consumer view.

**Sharp edge:** Dependencies are preserved; dropping AFTER would permit reading the wrong buffer version.

### schedule/prepare.py:L53 — Discard movement wrapper on END payload

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L53). **Match → action:** `END(movement(base), ranges...) → END(base,ranges...)`.

**Example:** `END(reshape(store_result),r) → END(store_result,r)`.

**Why:** Inference: END closes control ranges; an output shape view adds no work.

**Sharp edge:** Only the payload view is discarded; all ended ranges remain.

### schedule/prepare.py:L98 — Collect positional function parameters

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L98). **Match → action:** `pm_gather_params` visits PARAM and appends it to the context list iff slot ≥ 0; no replacement.

**Example:** Body using PARAM(slot=2) records slot 2; a named shape variable at slot -1 is omitted.

**Why:** Inference: `resolve_function` needs the body’s parameter list for argument substitution.

**Sharp edge:** This is an analysis rule. Negative-slot symbolic variables are not positional buffer arguments.

### schedule/prepare.py:L153 — Inline calls with unbound outputs

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L153). **Match → action:** CALL with `has_unbound_outputs` invokes `resolve_function`. Precompiled calls stay; otherwise collect/sort PARAMs, substitute arguments, flatten/pad storage-shaped args, and verify size/dtype/scalar compatibility.

**Example:** A function body `out.store(inp+1)` called with input A/output B becomes the body with those actual buffers and views substituted.

**Why:** Source: value-producing RETURNED inputs bind positionally to output PARAMs; these calls must be resolved before scheduling.

**Sharp edge:** Storage size includes maximum symbolic shape and shard shape, not just the current logical view. Mismatches raise.

### schedule/prepare.py:L156 — Resolve returned AFTER dependencies

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L156). **Match → action:** AFTER with first value r and a following SINK t delegates to `resolve_returned_after`: require r.unsharded_base.is_unbound, find direct STOREs in t targeting exactly that unsharded base, and return the assigned value only when exactly one matches.

**Example:** `after(returned_placeholder, sink(store(returned_placeholder, x+1))) → x+1`.

**Why:** Source: extract the value assigned to an unbound RETURNED placeholder, making the value-producing function inlineable.

**Sharp edge:** Zero or multiple matching STOREs return None; ordinary already-bound output buffers do not satisfy the guard. This is value extraction, not generic effect elimination.

### schedule/prepare.py:L159 — Expand collective into a function

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L159). **Match → action:** ALLREDUCE(buf) delegates to `create_allreduce_function`.

**Example:** `allreduce_ADD(local_sum on AMD:0,AMD:1) → collective function CALL(local_sum)` containing the selected transfer/reduction plan.

**Why:** Source requires bottom-up resolution; an explicit function gives the collective a schedulable boundary.

**Sharp edge:** Algorithm, topology and precompilation decisions are in `schedule/allreduce.py`, not in this tuple.

### schedule/prepare.py:L162 — Split very large reductions across kernels

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L162). **Match → action:** REDUCE invokes `split_reduceop`: require nonempty output, SPLIT_REDUCEOP, all integer input dimensions, reduction ratio ≥ REDUCEOP_SPLIT_THRESHOLD (32768 default), and a non-broadcast reduced dimension divisible by some d between 8 and min(256,2**REDUCEOP_SPLIT_SIZE/output_numel). Pick first candidate; reshape, move split axis last, reduce, contiguous, reduce split axis, reshape back.

**Example:** Sum of 65536 numbers can become 256 partial sums of 256 values, materialize those 256, then sum them.

**Why:** Source: improve occupancy when too few global outputs exist, cap temporary size, preserve second-phase locality.

**Sharp edge:** Creates a real extra kernel boundary. Divisibility and broadcast rejection matter; floating sums may round differently.

Why can an extra launch be faster? One output sum provides very little independent work if handled by one workgroup. Producing many partial sums lets more workgroups run at once (**occupancy** is the degree to which hardware execution capacity is populated). The final small reduction combines those partials, at the cost of a temporary and another launch. The threshold and divisibility tests decide when this particular split is attempted.

### schedule/prepare.py:L165 — Erase backward-only annotations

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L165). **Match → action:** DETACH or CONTIGUOUS_BACKWARD returns its data source.

**Example:** `DETACH(x*2) → x*2`.

**Why:** Inference: gradient semantics are already resolved; these markers need no forward kernel operation.

**Sharp edge:** CONTIGUOUS_BACKWARD is not the forward contiguous COPY materialization request.

### schedule/prepare.py:L168 — Make SINK reference unsharded bases

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L168). **Match → action:** SINK replaces each source with `unsharded_base`.

**Example:** `sink(reshape(buffer,[2,3])) → sink(buffer)` (with unsharding wrappers also peeled).

**Why:** Source: SINK only references the base; roots demand storage state rather than a result view.

**Sharp edge:** Does not mean movement on data reads is free to discard; only sink roots are treated this way.

### schedule/prepare.py:L173 — Use STORE itself for a cross-device copy

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L173). **Match → action:** `STORE(dst,COPY(x)) → STORE(dst,x)` iff copy is not self-copy, dst device equals COPY target, and dst has buffer identity.

**Example:** `B_CPU.store(A_AMD.copy(CPU)) → B_CPU.store(A_AMD)`.

**Why:** Source: a STORE between device buffers already denotes the copy, avoiding an anonymous intermediate destination.

**Sharp edge:** A view without buffer identity or a mismatched destination device cannot take this shortcut.

### schedule/prepare.py:L177 — Turn COPY into explicit storage state

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L177). **Match → action:** COPY callback removes redundant self-copy of an existing buffer identity or COPY; otherwise cross-device source pads to max shape, allocate fresh destination buffer, store x, return AFTER shrunk to logical shape.

**Example:** `contiguous(x+y) → tmp.after(tmp.store(x+y))`; existing contiguous A copied to itself returns A.

**Why:** Source: bare COPY is an anonymous store. This exposes the requested materialization to scheduling.

**Sharp edge:** Cross-device transfer storage uses max shape; the final logical SHRINK must survive until accesses are resolved.

### schedule/prepare.py:L180 — Remove matching reshapes from STORE

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L180). **Match → action:** STORE(RESHAPE(dst), RESHAPE(src)) becomes STORE(dst,src) iff original dst/src shapes agree.

**Example:** `reshape(B,[6]).store(reshape(A,[6])) → B[2,3].store(A[2,3])`.

**Why:** Inference: equal storage-order reshapes do not alter which element is assigned.

**Sharp edge:** Same final shape alone is insufficient; the original shapes must match.

### schedule/prepare.py:L187 — Materialize a cross-device expression before transfer

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L187). **Match → action:** STORE(dest,src) with different non-None devices and src lacking buffer identity becomes STORE(dest, contiguous(src)).

**Example:** `B_CPU.store(A_AMD+1) → T_AMD.store(A+1); B_CPU.store(T_AMD)`.

**Why:** Source: SDMA requires a whole buffer and cannot do offset copies. Separates computation from transfer.

**Sharp edge:** Constants/deviceless values and already buffer-identifiable sources bypass it; no mixed-device arithmetic kernel is implied.

### schedule/prepare.py:L190 — Prevent in-place index-reordering hazards

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L190). **Match → action:** If destination base occurs in source, traverse until COPY or matching materializing AFTER boundaries. A PERMUTE/FLIP on a path reaching that base, or SHRINK when destination also shrinks, forces contiguous(src). Exclude destination’s own SHRINK.

**Example:** `A.store(A.flip(0)) → tmp.store(A.flip(0)); A.store(tmp)`; overlapping `A[1:].store(A[:-1])` also needs protection.

**Why:** Source cites assignment regression tests: parallel writes must not destroy inputs other threads still read.

**Sharp edge:** Pure pointwise `A.store(A+1)` need not trigger this particular rule; later realization analysis also handles hazards.

For `A=[1,2,3,4]`, an intended reversal is `[4,3,2,1]`. If one worker writes `A[0]=4` before another reads the old `A[0]` for the last position, the last position incorrectly receives 4. Reading the source into a temporary first preserves the original four values until every source read is complete.

### schedule/prepare.py:L193 — Deduplicate repeated assignment of identical value

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L193). **Match → action:** Exact nested states `a1=after(buf,store(buf,src)); after(a1,store(a1,src)) → a1`.

**Example:** `A.assign(B); A.assign(B)` with unchanged B collapses the second state.

**Why:** Source cites `TestSchedule.test_dedup_Assign`.

**Sharp edge:** Uses exact UOp identity for buf and src; does not prove two different expressions equal.

### schedule/prepare.py:L196 — Remove writeback of the same updated state

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L196). **Match → action:** `after(buf, store(buf, a1=after(buf,store(buf,src)))) → a1`.

**Example:** An outer assignment writing the result of `A.assign(B)` back into A reduces to `A.assign(B)`.

**Why:** Source cites nested-after contiguous assignment regression.

**Sharp edge:** Must preserve the inner assignment; this is not equivalent to returning the original buffer state.

### schedule/prepare.py:L199 — Move destination BITCAST to assigned value

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L199). **Match → action:** STORE(BITCAST(target),src) becomes STORE(target,BITCAST(src,target.dtype)).

**Example:** Writing uint32 bits through a float32 buffer view becomes a float32-typed store of those same bits.

**Why:** Source cites assign-bitcast support; memory identity stays attached to original storage.

**Sharp edge:** BITCAST preserves bits, unlike CAST, and shape-changing bitcasts may need the next rule.

### schedule/prepare.py:L202 — Implement size-changing bitcasts with packing

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L202). **Match → action:** BITCAST changing element byte width, except DISK, is rewritten via unsigned integers. Widen: reshape to groups, slice parts, cast/shift by byte offsets, sum, squeeze, bitcast. Narrow: shift parts, STACK, flatten, cast narrow uint, bitcast.

**Example:** uint8 `[0x34,0x12] → uint16 [0x1234]`; uint16 `[0x1234] → uint8 [0x34,0x12]`.

**Why:** Inference: express reinterpretation with changed tensor shape in normal tensor operations before rangeification.

**Sharp edge:** Assumes the implemented little-endian byte ordering and divisible last dimension; same-width and DISK cases are intentionally left alone.

### schedule/prepare.py:L207 — Supply identities for empty reductions

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L207). **Match → action:** REDUCE whose input shape contains zero but output shape does not returns const_like(identity_element(op,dtype)).

**Example:** SUM over shape `[0,4]` reducing the leading axis becomes four zeros; MAX uses its dtype-appropriate identity.

**Why:** Source: reducing size zero produces the reduction identity.

**Sharp edge:** An empty output is different and falls through to the generic empty-tensor rule.

### schedule/prepare.py:L210 — Canonicalize empty-shaped values

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L210). **Match → action:** Any op except SINK with known shape containing zero becomes zero const_like with original tag.

**Example:** An elementwise result of shape `[3,0]` becomes an empty-shaped zero value.

**Why:** Inference: no elements exist, so no compute or buffer allocation is required.

**Sharp edge:** The preserved tag can still matter to rewrite bookkeeping; nonempty scalar zero is not substituted for an empty shape.

### schedule/prepare.py:L213 — Clean SINK dependencies

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L213). **Match → action:** SINK filters NOOP inputs and applies recursive `walk_mop` to others; walk strips movement, INDEX, UNSHARD, BITCAST and repairs AFTER around stripped bases.

**Example:** `sink(NOOP, reshape(after(B,store))) → sink(after(B,store))`.

**Why:** Inference: scheduling roots should name effects/storage, not view descriptions.

**Sharp edge:** `walk_mop` preserves AFTER dependencies; do not generalize to stripping views in arithmetic operands.

### schedule/prepare.py:L214 — Clean only the dependencies of AFTER

[Source](../../../../tinygrad/tinygrad/schedule/prepare.py#L214). **Match → action:** AFTER keeps first source unchanged, removes NOOP dependencies, and `walk_mop`s remaining dependency sources.

**Example:** `after(B,NOOP,reshape(effect)) → after(B,effect)`.

**Why:** Inference: dependency views carry no additional effect.

**Sharp edge:** First source is the value/state returned and is deliberately not rewritten by this tuple.

## Indexing: propose materialization boundaries and replace shape with ranges

Start from the outputs and ask which input coordinates each output needs. A transpose swaps coordinates; a broadcast reuses one coordinate; a reduction introduces additional coordinates to sum over. **Rangeification** makes these relationships explicit. A producer may need its own iteration domain and temporary when its consumers disagree about how to visit it. The collector rules record candidates first; later rules make or remove the proposed boundaries.

### schedule/indexing.py:L47 — Force custom kernel arguments to be buffers

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L47). **Match → action:** CALL with SINK/PROGRAM body strips RESHAPE from args; args not in ALWAYS_CONTIGUOUS are entered into realize_map and non_removable.

**Example:** `custom_kernel(A+B) → custom_kernel(materialize(A+B))`.

**Why:** Source: custom kernel inputs must be realized. Their compiled interface cannot absorb arbitrary producer expressions.

**Sharp edge:** non_removable prevents the later cost heuristic from fusing this producer back into the opaque call.

### schedule/indexing.py:L49 — Realize stores

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L49). **Match → action:** Every STORE is recorded in realize_map with no axes assigned yet.

**Example:** Output STORE of `[B,N]` receives fresh output ranges b,n in the subsequent reverse walk.

**Why:** Inference: writes anchor the computation demand and ranges that must be closed.

**Sharp edge:** The callback returns None but mutates context; it does not replace STORE immediately.

### schedule/indexing.py:L51 — Materialize stack/select inputs

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L51). **Match → action:** MSELECT/MSTACK records each source whose base is not ALWAYS_CONTIGUOUS.

**Example:** `MSTACK(A0+B0,A1+B1)` gets per-device materialization points.

**Why:** Inference: multi-device container members must be concrete per-device values.

**Sharp edge:** Existing BUFFER/PARAM/AFTER/CONST/CALL and the other ALWAYS_CONTIGUOUS bases bypass new realization.

### schedule/indexing.py:L53 — Protect self-referential stores

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L53). **Match → action:** STORE(dest,src) records src for realization if dest.base occurs in src’s topological graph (without entering CALLs).

**Example:** A source reading the old A in an assignment diamond is materialized before A’s state is overwritten.

**Why:** Source mentions write-after-read hazard `test_assign_double_diamond_reduce`.

**Sharp edge:** Comment mentions cross-device stores, but this callback’s actual condition is self-access; cross-device preparation is elsewhere.

### schedule/indexing.py:L136 — Replace tensor reduction axes with explicit ranges

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L136). **Match → action:** REDUCE with nonzero axis count requires range_map; bufferize/index inputs, append first axis-count input ranges, change arg to `(reduction_op,0)`.

**Example:** `REDUCE_ADD(X[32,8], first_axis) → REDUCE_ADD(INDEX(X,k,j), RANGE(k,32))`.

**Why:** Inference: codegen must know the loop to accumulate, not a tensor-axis number.

**Sharp edge:** No range-map entry raises; axis-count zero is already lowered and stays unchanged.

### schedule/indexing.py:L138 — Make padding zero-fill local

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L138). **Match → action:** PAD in range_map gets indexed inputs, multiplies/ANDs validities of its own input ranges, returns WHERE(valid,input,typed_zero).

**Example:** `pad([a,b], left=1,right=1)[i] → (1≤i<3) ? x[i-1] : 0`.

**Why:** Source: preserve pad behavior locally; later operations can change the zero value, so padding cannot be only a final load mask.

**Sharp edge:** Nested pad validities must be scoped correctly; apply_movement_op deliberately keeps the newly introduced validity distinguishable.

Take padded `[a,b]` and then add 1. The desired result is `[1,a+1,b+1,1]`. A load mask that only suppresses reads of padding is insufficient unless the zero supplied at the padding positions still flows through `+1`. The WHERE makes padding's zero a value at the correct point in the expression.

### schedule/indexing.py:L140 — Lower data STACK to selection

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L140). **Match → action:** STACK with range-map entry and nonvoid dtype becomes a backwards-built WHERE chain testing the leading output range against source numbers; sources get trailing ranges.

**Example:** `stack(A,B,C)[s,i] → s==0 ? A[i] : (s==1 ? B[i] : C[i])`.

**Why:** Source avoids building a transient mid-rangeify STACK that violates shape verification.

**Sharp edge:** Shape-tuple STACKs and void empty tuples do not match the callback guard; the last source is the default for valid s.

### schedule/indexing.py:L142 — Insert indexing and proposed materializations

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L142). **Match → action:** All ops except STAGE/INDEX replace sources using range_map. Concrete storage sources get INDEX only in data positions. Realized STORE gets END over selected RANGE axes; other realized values get STAGE over selected axes and corresponding consumer INDEX. Full-axis closure is GLOBAL, partial closure LOCAL.

**Example:** A proposed temporary for `t[i]=A[i]+B[i]` consumed at j becomes `INDEX(STAGE(A[i]+B[i],i),j)`; a STORE gets `END(store,i)`.

**Why:** Inference: separates producer iteration coordinates from consumer access coordinates, making kernel-boundary removal an explicit transformation.

**Sharp edge:** Shape/index/range metadata must not be indexed like data; removable is false for explicit contiguous classes and custom-call args.

Producer and consumer range names serve different roles even if both run from 0 to N−1. `r` describes how every temporary element is produced; `j` describes which element this consumer currently needs. Keeping these separate lets a later rule substitute `r=j` for an ordinary read, or `r=N−1−j` for a reversed read, rather than incorrectly assuming identical access order.

### schedule/indexing.py:L144 — Remove views whose indexing is already encoded

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L144). **Match → action:** Movement op returns its first source iff it has a range-map entry or its input is INDEX.

**Example:** After permutation indices were swapped, `PERMUTE(INDEX(A,j,i)) → INDEX(A,j,i)`.

**Why:** Inference: retaining the tensor view would apply it twice.

**Sharp edge:** An untouched movement node without mapped ranges is not erased.

### schedule/indexing.py:L148 — Assign a device to constant-derived temporaries

[Source](../../../../tinygrad/tinygrad/schedule/indexing.py#L148). **Match → action:** GLOBAL STAGE with device None gets context sink device; other STAGEs stay.

**Example:** A materialized index/constant expression feeding an AMD output acquires AMD storage.

**Why:** Source: a deviceless value requiring materialization must be placed on the sink device.

**Sharp edge:** LOCAL stage device fields have other meanings and are not filled here.

### The boundary decisions hidden outside a PatternMatcher

[`run_rangeify`](../../../../tinygrad/tinygrad/schedule/indexing.py#L188) is an imperative reverse consumer walk; reading only the PM tuples misses its fusion policy:

- Explicitly realized nodes get new output ranges and close every output axis. One consumer otherwise passes its access ranges back to the producer.
- With multiple consumers, compare index expressions **without validity**. If every axis agrees, OR the consumer validity predicates and retain common indexing. If they do not all agree, create fresh ranges and mark the axes for realization. For example, a producer accessed as both `t[i]` and `t[N-1-i]` cannot simply inherit one consumer loop.
- Broadcasted consumer axes enter `ending_ranges`. At a REDUCE they are accounted for before the next decision; elementwise/reduction nodes encountering pending ended ranges materialize all their output axes. This is central to the reduction-then-broadcast case in RMSNorm: the row statistic has a different iteration lifetime from the final elementwise output.
- Movement ops transform input coordinates; STACK removes its selector axis from source coordinates; tensor REDUCE creates new REDUCE ranges for the leading reduced dimensions. Ordinary EXPAND adds ended ranges, except explicit injected RANGE extents. Source calls out this heuristic as a reason convolutions materialize.

These are current implementation rules, not a promise that every RMSNorm always has a particular launch count. Shapes, consumers, explicit contiguous calls, and later simplification decide the final graph.

## Rangeify: remove, allocate, and split materializations

At entry, STAGE nodes are proposals, so they can still disappear. Think of `INDEX(STAGE(f(r),r),j)` as “fill temporary T using `T[r]=f(r)`, then read `T[j]`.” Substituting `r=j` gives `f(j)` directly and can remove that producer launch. This is useful only when recomputation, dependencies, and backend limits permit it. The chapter then commits surviving stages to storage and extracts closed writes into actual calls.

### schedule/rangeify.py:L47 — Prune substitutions outside affected ranges

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L47). **Match → action:** `pm_gate_substitute` matches every op; raise BottomUpGate when none of the substitution-context keys occur in its ranges. It is explicitly compiled=False.

**Example:** Substituting producer range r→j visits `A[r]+1`; a subtree depending only on unrelated q is skipped.

**Why:** Inference: avoid traversing irrelevant expression subgraphs while fusing STAGE reads.

**Sharp edge:** This is a traversal gate, not a value replacement or algebraic rule; incorrect range metadata would make it unsafe.

### schedule/rangeify.py:L116 — Shrink away unused staged axes

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L116). **Match → action:** Removable STAGE, excluding NOOP/AFTER source, scans axes. Abort on nonconstant RANGE extents. Constant axes and RANGE axes absent from source.ranges become size 1; remove those stage sources and reshape/expand back.

**Example:** `STAGE(A[i], i∈[0,4), j∈[0,8)) → expand(reshape(STAGE(A[i],i),[4,1]),[4,8])`.

**Why:** Source: dead axes become visible after EXPAND propagation; avoid storing 32 copies of 4 values.

**Sharp edge:** AFTER is storage identity, so lack of source computation dependence on a range cannot justify shrinking its storage.

### schedule/rangeify.py:L118 — Remove identity re-materialization

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L118). **Match → action:** STAGE(INDEX(b,idxs), stage_ranges) returns b, shrunk from zero to stage shape if non-scalar, only when idxs exactly equal stage_ranges.

**Example:** `STAGE(INDEX(B,r),r) → B[0:N]`.

**Why:** Inference: copying the same storage traversal into an equivalent temporary is unnecessary.

**Sharp edge:** Equality is exact range-tuple equality; a permutation/offset does not satisfy this shortcut.

### schedule/rangeify.py:L120 — Replace staged constants with shaped constants

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L120). **Match → action:** STAGE of CONST or casted CONST returns stage.const_like(original constant value).

**Example:** `STAGE(float(3),r∈[0,1024)) → shaped_constant(3,[1024])`.

**Why:** Source: no buffers for constants in either spelling.

**Sharp edge:** The stage’s dtype/shape define const_like; this does not allocate a repeated-value buffer.

### schedule/rangeify.py:L122 — Remove scalar constant indexing

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L122). **Match → action:** INDEX whose only source is CONST or casted CONST returns that constant/cast.

**Example:** `INDEX(CAST(CONST(3))) → CAST(CONST(3))`.

**Why:** Source: indexing a constant is the constant.

**Sharp edge:** This tuple has exact one-source INDEX; arbitrary explicit indices are not matched by this spelling.

### schedule/rangeify.py:L124 — Propagate wholly invalid buffer states

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L124). **Match → action:** INDEX(AFTER(...),...) returns Invalid const_like only if every dependency is END(STORE) writing invalid to the same underlying buffer, each ended range is used by the store target, and product of range extents equals buffer numel.

**Example:** A full N-element invalid write followed by B[i] becomes Invalid. A half-buffer invalid write does not.

**Why:** Inference: erase computation reading a buffer proven entirely invalid, enabling dead writes to disappear.

**Sharp edge:** Coverage proof rejects broadcast/pad/shrink patterns; checks are stricter than merely seeing an Invalid source.

### schedule/rangeify.py:L127 — Index replicated deviceless values directly

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L127). **Match → action:** INDEX(MSTACK(s,...),idxs) replaces stack by its first source if s.device is None.

**Example:** `INDEX(MSTACK(CONST(7),CONST(7)),i) → INDEX(CONST(7),i)`.

**Why:** Source: a deviceless stack source represents the same value on every device.

**Sharp edge:** Relies on that representation invariant; the tuple itself does not compare all stack sources.

### schedule/rangeify.py:L133 — Fuse a staged producer by substituting consumer indices

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L133). **Match → action:** INDEX(STAGE(src,producer_axes),consumer_indices) requires equal arity and RANGE/CONST producer axes. Reject NOOP or nonremovable stage. Traverse src, stopping at global STAGE, MSTACK, AFTER and STORE; collect distinct accessed buffers and reductions. Reject >3 accessed buffers, or any reduction whose data depends on PARAM/STAGE/AFTER. Otherwise substitute nonconstant producer ranges with consumer indices, except Invalid indices, using pm_gate_substitute.

**Example:** `INDEX(STAGE(A[r]*scale[r]+bias[r],r),j) → A[j]*scale[j]+bias[j]`: three input buffers can be recomputed in the consumer, erasing the temporary/producer boundary. `INDEX(STAGE(sum_k(X[k,r]**2),r),j)` is retained because the reduction reads X.

**Why:** Source explicitly calls this a cost function. Inference: cap input pressure/recomputation and avoid duplicating expensive buffer-reading reductions across consumers.

**Sharp edge:** This is a heuristic, not a global profitability model. Four distinct input buffers block removal even for cheap math; a buffer-free reduction can pass. Explicit nonremovable boundaries always win.

For one consumer at `j=5`, the temporary route first stores `T[5]=A[5]*scale[5]+bias[5]`, then reads `T[5]`. Substitution puts those same three reads and arithmetic directly in the consumer. For a row statistic, that substitution could instead place an entire reduction inside each consumer element's computation. The reduction guard prevents that specific expensive expansion; it does not prove all reductions are fundamentally unfusable.

### schedule/rangeify.py:L135 — Erase exact self-store

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L135). **Match → action:** STORE(x,x) becomes NOOP.

**Example:** `INDEX(B,i).store(INDEX(B,i)) → NOOP`.

**Why:** Inference: writing the identical current value to the same target has no tensor effect.

**Sharp edge:** Exact UOp identity is required; equal addresses with different AFTER states are not automatically the same x.

### schedule/rangeify.py:L137 — Erase range closure around no work

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L137). **Match → action:** END(NOOP,ranges...) returns its NOOP payload.

**Example:** `END(NOOP,r0,r1) → NOOP`.

**Why:** Inference: no kernel should be created merely to close loops around an erased store.

**Sharp edge:** Does not drop END around a real side effect.

### schedule/rangeify.py:L161 — Remove access views from call arguments

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L161). **Match → action:** Every CALL maps sources: INDEX→its base unconditionally; SHRINK→base only if every offset resolves to zero; MSTACK→apply the zero-offset SHRINK removal to each member.

**Example:** `CALL(kernel,INDEX(B,r),SHRINK(C,0:N)) → CALL(kernel,B,C)`.

**Why:** Source: child references can accidentally give call args INDEX; calls require storage arguments after body accesses were lowered.

**Sharp edge:** Source TODO explicitly requests contiguous safety checks. Nonzero-offset SHRINK is retained, so this is a sharp representation assumption rather than general view equivalence.

### schedule/rangeify.py:L166 — Strip kernel-graph storage views

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L166). **Match → action:** RESHAPE/SHRINK directly over AFTER/PARAM/UNSHARD/MSTACK/BUFFER returns its base.

**Example:** The call-graph edge `RESHAPE(AFTER(tmp,producer),[B,N])` becomes `AFTER(tmp,producer)`.

**Why:** Source: executable kernel graph has no shape views; logical indexing is inside kernel bodies.

**Sharp edge:** Running this at tensor-graph time would be wrong; stage ordering is essential.

### schedule/rangeify.py:L198 — Split expressions exceeding backend buffer limits

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L198). **Match → action:** Binary/ternary root with device checks MAX_KERNEL_BUFFERS override or DEVICE_MAX_BUFS (METAL/CPU31, WEBGPU8). Count distinct STAGE/AFTER/PARAM/MSELECT/MSTACK leaves, with one reserved output. If too many, bufferize each device-bearing elementwise immediate source, replacing non-DEVICE ranges with fresh WEAK ranges.

**Example:** A WEBGPU expression combining nine independent inputs through two arithmetic subtrees can materialize the subtrees, so the final kernel reads two temporaries instead of nine inputs.

**Why:** Inference from limits and output reservation: meet backend argument-count constraints, even if previous fusion was legal.

**Sharp edge:** Creates real boundaries and does not promise an optimal partition. Actual lookup uses a string device unchanged; tuple devices normalize the first string before lookup. Override can make behavior explicit.

An argument limit counts distinct buffers a kernel must receive, not just arithmetic operations. Splitting a large expression trades more launches and temporary traffic for a legal interface. This is why a previously profitable-looking fused expression can be split again later.

### schedule/rangeify.py:L251 — Flatten multidimensional staging into one storage index

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L251). **Match → action:** STAGE with source count other than two combines axes with reshape index arithmetic, returns flattened stage reshaped to original shape; if any range extent is symbolic, shrink the maximum storage view to symbolic shape.

**Example:** `STAGE(v,i∈[0,2),j∈[0,3)) → reshape(STAGE(v,3*i+j),[2,3])`.

**Why:** Source: collapse bufferize to single input [index] form, preparing contiguous storage allocation.

**Sharp edge:** Size-one constant axes and symbolic maximum extents affect the final reshape/shrink; not a change in loop semantics.

### schedule/rangeify.py:L262 — Commit global stages to allocated buffers and writes

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L262). **Match → action:** Two-source STAGE(x,idx) invokes bufferize_to_store with locals disabled. Commit weak dtype, require positive integer storage size, sort idx ranges. GLOBAL: new BUFFER, indexed STORE of committed value, END, AFTER, cast back. AFTER payload instead reuses existing buffer and closes its indexed stores, unwraps STAGE(INDEX) targets, and skips self-stores.

**Example:** `STAGE(A[i]+1,i) → CAST_weak(AFTER(tmp,END(STORE(tmp[i],CAST_concrete(A[i]+1)),i)))`. A stage over an assignment returns that assignment’s original buffer with closed writes.

**Why:** Inference: proposed global materialization becomes concrete producer work and dependency state.

**Sharp edge:** LOCAL stages intentionally survive here for later lowering. The shared helper can allocate local placeholders when allow_locals=True elsewhere; symbolic allocation sizes must already be represented by integer maxima.

### schedule/rangeify.py:L266 — Move weak casts from buffer to loaded scalar

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L266). **Match → action:** INDEX(CAST_weak(buf),indices) becomes CAST_weak(INDEX(buf,indices)), preserving the original indexed dtype.

**Example:** `INDEX(CAST_weak_float(tmp[4096]),i) → CAST_weak_float(INDEX(tmp,i))`.

**Why:** Source: must run with buffer creation, otherwise the expander can turn the whole casted buffer into one giant VECTORIZE.

**Sharp edge:** Weak types are compile-time promotion metadata; the actual buffer uses committed storage dtype.

### schedule/rangeify.py:L270 — Move shapes outside multi-device containers

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L270). **Match → action:** MSELECT/MSTACK whose source pattern is RESHAPE replaces each input by its reshape source’s base and reshapes the resulting container to m.shape.

**Example:** `MSELECT(RESHAPE(multi_buffer,[2,3]),1) → RESHAPE(MSELECT(multi_buffer,1),[2,3])`.

**Why:** Source: move RESHAPEs through MSELECT/MSTACK so storage identities remain accessible.

**Sharp edge:** The result shape is restored; this does not concatenate shards.

### schedule/rangeify.py:L274 — Remove immediate reshapes from call sources

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L274). **Match → action:** CALL replaces each immediate RESHAPE source by its first source.

**Example:** `CALL(kernel,RESHAPE(tmp,[B,N])) → CALL(kernel,tmp)`.

**Why:** Inference: call ABI passes storage; access shape already belongs in the body.

**Sharp edge:** Only one immediate reshape layer is removed per application; no arbitrary index offset is inferred.

### schedule/rangeify.py:L277 — Erase invalid writes

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L277). **Match → action:** STORE(any, CONST(Invalid)) becomes NOOP.

**Example:** `STORE(B[i],Invalid) → NOOP`.

**Why:** Source: remove invalid writes. Inference: Invalid denotes no valid value/work at that position, not numeric zero.

**Sharp edge:** A zero store remains a store; invalid propagation has separate correctness conditions.

### schedule/rangeify.py:L278 — Remove empty AFTER dependencies

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L278). **Match → action:** AFTER filters zero-source NOOP and recursively END(NOOP). If none remain, return first source; otherwise rebuild only when changed.

**Example:** `AFTER(B,END(NOOP,r),real_write) → AFTER(B,real_write)`; `AFTER(B,NOOP) → B`.

**Why:** Inference: dead stores must not leave phantom producer dependencies or launches.

**Sharp edge:** A NOOP carrying sources is not considered empty and is retained.

### schedule/rangeify.py:L321 — Reject simultaneous incompatible buffer states

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L321). **Match → action:** STORE invokes check_buf_states: traverse while not entering AFTER, collect INDEXes, and ensure each BUFFER/PARAM buf_uop is indexed through a single identical source state. Otherwise raise cycle error.

**Example:** A single kernel body reading both INDEX(B,i) and INDEX(AFTER(B,write),j) can be rejected as two states of the same storage.

**Why:** Inference: a kernel cannot in general observe both pre-write and post-write versions without a valid schedule boundary.

**Sharp edge:** Analysis rule, no replacement; state identity matters even if underlying pointer is equal.

Imagine a body asking for `old_A[i] + new_A[j]` after A was overwritten in place. A pointer to A cannot provide both versions at once. Some computations can be restructured or given an explicit temporary to preserve the old version, but this rule does not invent that algorithm: it detects the incompatible representation and rejects it.

### schedule/rangeify.py:L322 — Convert external storage to kernel parameters

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L322). **Match → action:** BUFFER/MSTACK/MSELECT invokes debuf. Variables become PARAM directly. Other storage gets fresh positional PARAM with max storage size, dtype/address space/device, reshaped to max shape and shrunk if symbolic; register original buffer in lctx.map.

**Example:** A kernel reading a 2×3 global B gets PARAM(slot=0,size=6).reshape(2,3), and CALL receives B.

**Why:** Inference: turn graph-global identities into a reusable kernel ABI.

**Sharp edge:** ctx.map preserves actual arguments separately from body PARAMs; symbolic logical size is not the allocated maximum size.

### schedule/rangeify.py:L323 — Keep named variables out of buffer slots

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L323). **Match → action:** PARAM with name and value-range metadata and slot != -1 gets slot=-1.

**Example:** `PARAM(name=n,range=[1,1024],slot=2) → PARAM(name=n,...,slot=-1)`.

**Why:** Inference: scalar symbolic values must not be replaced by positional buffer arguments.

**Sharp edge:** Both name and vmin_vmax are required; an ordinary unnamed scalar-shaped parameter is handled differently.

### schedule/rangeify.py:L327 — Renumber tagged storage parameters

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L327). **Match → action:** PARAM invokes debuf only if tag==(), name is None, and shape exists.

**Example:** Outer-body PARAM(slot=7,size=128,tag=()) becomes the next local kernel PARAM, perhaps slot=1; original parameter is a CALL argument.

**Why:** Source: renumber parameters, decoupling standalone kernel ABI from outer call slots.

**Sharp edge:** Only marked original params are eligible; freshly produced untagged params are not endlessly renumbered.

### schedule/rangeify.py:L331 — Remove INDEX from scalar symbolic params

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L331). **Match → action:** One-source INDEX(PARAM v) returns v iff address space is ALU.

**Example:** `INDEX(PARAM(n,addrspace=ALU)) → PARAM(n)`.

**Why:** Source: ALU params are scalar symbolic values, not buffers.

**Sharp edge:** No arbitrary indexed buffer read can be removed; the pattern has no explicit index operands.

### schedule/rangeify.py:L334 — Peel binding stores off variables

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L334). **Match → action:** AFTER b returns b.src[0] iff b.is_bound_var.

**Example:** `AFTER(variable_n, STORE(variable_n,16)) → variable_n` inside the kernel.

**Why:** Source: bound variables are input values; the buffer becomes ALU PARAM. Actual binding is retained by outer scheduling.

**Sharp edge:** Does not discard writes to actual tensor buffers.

### schedule/rangeify.py:L335 — Move global AFTER dependencies outside kernel body

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L335). **Match → action:** AFTER with non-LOCAL address space records buf_uop→after in ctx.map if absent, then returns buf_uop; LOCAL AFTER stays.

**Example:** Body `INDEX(AFTER(B,producer_call),i)` becomes `INDEX(B,i)` while the consumer CALL argument is AFTER(B,producer_call).

**Why:** Inference: producer/consumer launch order belongs to the kernel graph, not instructions inside a consumer.

**Sharp edge:** Bottom-up first insertion is significant; local synchronization remains inside the kernel.

The consumer's machine code needs a pointer to B; it does not contain instructions that launch B's producer. Moving AFTER outward puts “launch producer before consumer” on the schedule edge, while leaving “read B[i]” inside the consumer body. LOCAL storage is different because its producer and consumer are workers inside the same kernel, so their ordering must remain there.

### schedule/rangeify.py:L338 — Clear stage device in a kernel

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L338). **Match → action:** STAGE replaces BufferizeOpts.device with None.

**Example:** A surviving LOCAL STAGE carrying an outer device identifier becomes an anonymous local stage in the extracted body.

**Why:** Source: remove device from local bufferize, enabling local allocation independent of graph device identity.

**Sharp edge:** Pattern matches all STAGEs, but globals should already be gone at this point; this relies on pipeline order.

### schedule/rangeify.py:L341 — Normalize tagged range numbers

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L341). **Match → action:** RANGE with tag==() gets next sequential ctx.range id, keeps remaining arg fields, clears tag; otherwise no change.

**Example:** The same kernel expressed with ranges r42,r89 becomes r0,r1.

**Why:** Source: renumber from zero so equivalent kernels deduplicate.

**Sharp edge:** Axis types and bounds remain; numerical identifier normalization is not loop reordering.

### schedule/rangeify.py:L345 — Mark original params and ranges for local renumbering

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L345). **Match → action:** PARAM/RANGE gets empty-tuple tag.

**Example:** `RANGE(128,id=42,WEAK,tag=None) → same RANGE(tag=())`.

**Why:** Inference: distinguish outer graph nodes from new nodes made while extracting a kernel.

**Sharp edge:** The empty tuple is a sentinel; to_define_global consumes it and does not renumber arbitrary tagged nodes.

### schedule/rangeify.py:L363 — Extract a closed store as a kernel call

[Source](../../../../tinygrad/tinygrad/schedule/rangeify.py#L363). **Match → action:** STORE/END invokes split_store. Refuse if any open range is non-DEVICE; refuse bound-variable STORE. Rewrite body with fresh local context using to_define_global+pm_flatten_range, wrap in SINK(KernelInfo), CALL with collected storage-state args.

**Example:** `END(STORE(out[i],A[i]+1),i) → CALL(SINK_kernel(STORE(P0[i],P1[i]+1)...),out,A)`. A scalar store with an open reduction range cannot split yet.

**Why:** Inference: closed iteration scope is a launchable computation; the resulting CALL is the concrete kernel boundary.

**Sharp edge:** DEVICE ranges may stay open because they bind at launch. Cross-device storage is temporarily allowed here and recognized as transfer later, not compiled as mixed-device arithmetic.

`pm_const_buffer_folding` includes `pm_mops`; `pm_add_buffers` includes `pm_mops + pm_flatten_bufferize`. The cleanup invocation also composes imported `symbolic + pm_reduce_simplify`, and extraction composes `pm_flatten_range`; see their owning chapters for individual rules. The two `PatternMatcher([])` objects in VIZ branches are intentionally empty graph-view checkpoints, with zero rewrite rules.

For RMSNorm, follow **three distinct questions**: did range propagation propose a row-statistic boundary; can `remove_bufferize` legally/cost-effectively inline it (a buffer-reading reduction usually blocks this); and does `split_store` finally close a launch? A later elementwise epilogue may still fuse into either side of an existing boundary. Conversely, `split_reduceop` deliberately creates a two-phase reduction, so counting elementwise operations tells you nothing reliable about launches.

In the example, `END(...,i)` closes the output loop, so extraction can build a complete kernel. It assigns fresh body-local names `P0` and `P1`, while the CALL stores the mapping `P0→out`, `P1→A`. The same kernel body can then be reused with different actual buffers without confusing their identities.

## Multi: distinguish logical unsharding from communication

A **shard** is the portion of a logical tensor owned by one device or worker; a **replica** is a complete copy. For an eight-element vector on two devices, sharding might put elements 0–3 on device 0 and 4–7 on device 1. Replication puts all eight on both. `UNSHARD` describes how local pieces represent a logical tensor; it does not necessarily move bytes. `MSTACK` groups per-device values and `MSELECT` selects a member. **ALLREDUCE** combines corresponding contributions from participating devices and makes the combined result available to them. Distinguishing description from actual transfers is the central task of these rules.

`multi_pm` appends `replace_allreduce`. If `LATE_ALLREDUCE=0`, `_early_allreduce` is prepended to `replace_allreduce` at import time. The same tuple can therefore occur in more than one composed matcher without being a second distinct rule. In the examples below, two devices each own a contiguous four-element shard of a logical eight-element vector unless stated otherwise. Current UNSHARD also represents thread/register fragments, so not every rule is about multiple physical GPUs.

### schedule/multi.py:L31 — Expand one-to-many broadcast copies

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L31). **Match → action:** COPY from string-device x to tuple-device c becomes MSTACK of one x.copy_to_device(d) per target. If x.simplify() is deviceless, stack that simplified value repeatedly.

**Example:** `COPY(A_CPU, (AMD:0,AMD:1)) → MSTACK(COPY(A,AMD:0), COPY(A,AMD:1))`; constant 3 may need no transfers.

**Why:** Source: explicitly expand broadcast copies.

**Sharp edge:** This is replication, not sharding: each target receives the full source.

### schedule/multi.py:L33 — Choose a replica for many-to-one copy

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L33). **Match → action:** COPY from tuple-device x to a string target selects replica 0, returning it directly when already on target or copying otherwise.

**Example:** A replicated value on AMD:0/AMD:1 copied to CPU becomes COPY(MSELECT(x,0),CPU).

**Why:** Source TODO says it currently selects the first instead of using a little from each.

**Sharp edge:** A logical UNSHARD must first use its own reconstruction rule; selecting one replica is not gathering shards.

### schedule/multi.py:L37 — Resolve selection of an explicit stack

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L37). **Match → action:** MSELECT(MSTACK(sources),i) returns sources[i].

**Example:** `MSELECT(MSTACK(A0,A1),1) → A1`.

**Why:** Inference: direct projection of a known per-device tuple.

**Sharp edge:** Index denotes stack member/device position, not a tensor-element index.

### schedule/multi.py:L39 — Move shrink before device transfers

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L39). **Match → action:** SHRINK(MSTACK) applies shrink to each source, specializing DEVICE range expressions to its ordinal. COPY sources are shrunk before copy; self-device copies become contiguous. Other sources shrink then contiguous.

**Example:** Broadcasting a full eight-element value then choosing each device’s four-element range becomes two four-element source shrinks followed by corresponding copies.

**Why:** Inference: avoid transferring/materializing elements discarded by each device’s view.

**Sharp edge:** The inserted contiguous matters for whole-buffer transfer; shrink args containing DEVICE ranges are specialized per member.

### schedule/multi.py:L41 — Select device before applying a view

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L41). **Match → action:** MSELECT(movement(s,metadata),i) becomes movement(MSELECT(s,i),same metadata).

**Example:** `MSELECT(reshape(M,[2,4]),1) → reshape(MSELECT(M,1),[2,4])`.

**Why:** Inference: a replicated/per-device view can be applied to the selected member.

**Sharp edge:** Only the data source is selected; shape metadata is preserved.

### schedule/multi.py:L43 — Select device before arithmetic

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L43). **Match → action:** MSELECT(ALU(args),i) rebuilds ALU with MSELECT on tuple-device operands, leaving single-device/deviceless operands unchanged.

**Example:** `MSELECT(M + 2,1) → MSELECT(M,1) + 2`.

**Why:** Inference: expose independent per-device arithmetic for later scheduling.

**Sharp edge:** The tuple-device check avoids trying to select a scalar constant as if it were a device tuple.

### schedule/multi.py:L48 — Optional early collective lowering

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L48). **Match → action:** ALLREDUCE(buf) delegates to handle_allreduce; matcher is included before replace_allreduce only when LATE_ALLREDUCE is false.

**Example:** With LATE_ALLREDUCE=0, a sum collective expands to its transfer/reduction graph during multi rewriting rather than remaining late.

**Why:** Inference: alternative pipeline placement for communication lowering.

**Sharp edge:** This is import-time environment-dependent composition; it is not always active. Collective algorithm details belong to allreduce.py.

### schedule/multi.py:L282 — Run arithmetic within matching shards

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L282). **Match → action:** ALU with an immediate UNSHARD uses first sharding as target. If every source has same sharding, full target shape, or scalar shape, peel UNSHARD, select per-shard subviews of full values, perform ALU, rewrap. Otherwise single-axis fallback normalizes operands with shard_srcs, possibly gathering/resharding.

**Example:** `U(a_local,0) + 2 → U(a_local+2,0)`; adding a full `[8]` B uses B[4*d:4*d+4] on device d.

**Why:** Inference: compute each shard locally instead of materializing the full logical tensor.

**Sharp edge:** Fallback asserts compatible devices and a usable single sharding axis; matching logical shapes alone does not prove communication-free execution.

### schedule/multi.py:L283 — Reduce local shards and communicate only when needed

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L283). **Match → action:** REDUCE(UNSHARD) locally reduces leading num_axes. If sharded axes were reduced, require no remaining sharded axes and allreduce local result. Otherwise rewrap remaining axes shifted down by num_axes. ALLREDUCE_CAST can communicate in original half/bfloat16 when source was a widening CAST, then restore local dtype.

**Example:** Sum an eight-element sharded vector: sum each four-element shard, then allreduce two scalars. Reduce columns of row-sharded `[8,16]`: each device computes its own four row sums without allreduce.

**Why:** Inference: distinguish reducing within ownership from reducing across owners. Source explicitly rejects partial allreduce for mixed reduced/remaining multi-axis sharding.

**Sharp edge:** ALLREDUCE_CAST trades communication dtype/rounding; partial multi-axis collective case raises rather than silently producing an answer.

### schedule/multi.py:L284 — Reshape only when shard boundaries survive

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L284). **Match → action:** RESHAPE(UNSHARD) requires equal total size. For every sharded axis, its preceding element-count prefix must appear in new-shape prefix products; choose corresponding new axis and require its extent divisible by shard count. Reshape local shard and rewrap mapped axes.

**Example:** Logical `[8,4]` sharded on axis0 can reshape to `[8,2,2]`, each local `[4,4] → [4,2,2]`; a reshape that interleaves ownership is rejected.

**Why:** Source: shard axis boundary must survive intact and remain divisible.

**Sharp edge:** This is not a general distributed reshape; it raises “moved items between shards” rather than adding communication.

A reshape is local only when each owner's elements still form the required local block after reshaping. The `[8,4]→[8,2,2]` example splits each row's four columns into two by two and leaves ownership of rows unchanged. A reshape requiring one new row to contain elements from multiple owners needs data movement, which this callback deliberately does not create.

### schedule/multi.py:L285 — Shift shard axes when expanding leading dimensions

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L285). **Match → action:** EXPAND(UNSHARD) expands local source with same marg and increases each shard axis by len(marg).

**Example:** Adding leading broadcast extent 3 to a sharded `[8]` value yields local `[3,4]` with sharding on logical axis1.

**Why:** Inference: inserted leading broadcast axes move the ownership axis position.

**Sharp edge:** Here EXPAND’s internal marg is leading inserted dimensions, not the public full target-shape spelling.

### schedule/multi.py:L286 — Pad only unsharded dimensions

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L286). **Match → action:** PAD(UNSHARD) requires each sharded-axis marg to equal `(0,logical_extent)`. Replace those bounds by local extent, pad local source, retain sharding.

**Example:** Row-sharded `[8,4]` may pad columns to width6; each local `[4,4] → [4,6]`. Padding rows is rejected.

**Why:** Inference: nonsharded-axis padding is independent per owner; padding the ownership axis would change partitioning.

**Sharp edge:** Internal marg uses `(start,length)`; public pad arguments often use `(before,after)`, so do not copy the tuple convention blindly.

### schedule/multi.py:L287 — Resolve shrinks by shard ownership

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L287). **Match → action:** SHRINK(UNSHARD) handles each shard axis: a symbolic exact own-shard slice `(rng*shard_size,shard_size)` removes that sharding dimension; full logical axis maps to full local axis. Otherwise permit only legacy single-axis device selection of one exact partition, copy that partition to all devices, and shrink other dimensions.

**Example:** `U(v_local,0)[4*d:4*d+4] → v_local`; full `[0:8]` retains sharding. Selecting fixed `[4:8]` on two devices uses the selected shard-copy path.

**Why:** Source highlights thread fragments: own-shard shrinking turns logical full fragment into thread-local registers without copying.

**Sharp edge:** Arbitrary crossing slices and unsupported multi-axis partial shrinks raise; this is not a general distributed slicing implementation.

### schedule/multi.py:L288 — Permute shard-axis metadata with the tensor

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L288). **Match → action:** PERMUTE(UNSHARD) permutes local source, maps each old shard axis to its position in permutation, retains ranges.

**Example:** Row-sharded `[8,4]` transposed to `[4,8]` becomes column-sharded; local `[4,4]` transposes too.

**Why:** Source says all permutes are supported: ownership moves with the axes.

**Sharp edge:** The data stays on its owner; this is not an inter-device transpose redistribution.

### schedule/multi.py:L289 — Reject flips that reverse ownership

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L289). **Match → action:** FLIP(UNSHARD) raises if any flipped axis is sharded; otherwise flip local source and rewrap.

**Example:** For row-sharded `[8,4]`, column reversal is local; reversing all eight rows is rejected.

**Why:** Inference: whole-axis reversal across owners would need exchanging/reordering shards.

**Sharp edge:** Cannot substitute independent local row flips for global row reversal; they produce a different tensor.

### schedule/multi.py:L290 — Stack local shards and shift ownership axes

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L290). **Match → action:** STACK with UNSHARD inputs and equal sharding peels those inputs, stacks locally, increments shard axes by one, rewraps. Different shardings use single-axis shard_srcs fallback.

**Example:** `STACK(U(A,0),U(B,0)) → U(STACK(A,B),1)`; logical result `[2,8]`, local `[2,4]`.

**Why:** Source: STACK adds a leading axis.

**Sharp edge:** Fast path checks sharding of UNSHARD inputs; heterogeneous full nonsharded operands rely on existing shape invariants, unlike ALU’s explicit subview logic.

### schedule/multi.py:L291 — Turn owner-qualified global indices into local indices

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L291). **Match → action:** INDEX(UNSHARD,idxs) checks each sharded axis. First try local=idx-rng*shard_size with bounds [0,shard_size). Otherwise require (idx-rng)%shard_size==0 and bounded local=(idx-rng)//shard_size. Then index local source.

**Example:** Contiguous: `INDEX(U(v),4*d+j) → INDEX(v,j)` for 0≤j<4. Strided: `INDEX(U(v),d+4*j) → INDEX(v,j)` when the callback’s bounds/modulo proof holds.

**Why:** Source supports contiguous and strided ownership for fragments.

**Sharp edge:** The exact stride in this implementation is shard_size, not an assumed device count. A failed proof raises; arbitrary remote reads are not introduced.

### schedule/multi.py:L292 — Keep assignment states sharded

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L292). **Match → action:** AFTER(UNSHARD,STORE(dest_UNSHARD,src_UNSHARD)) invokes store_after_multi: `dest.after(dest.store(src.src[0])).unshard(src.arg,src.src[1:])`.

**Example:** A state representing “distributed destination after writing shard values” is rewritten around per-shard source values and returned with source ownership metadata.

**Why:** Inference: preserve assignment effects while moving ownership wrappers out of data computation.

**Sharp edge:** This exact callback retains dest in the constructed STORE, allowing later STORE sharding rules to finish lowering; it is not just blindly stripping every wrapper.

### schedule/multi.py:L294 — Materialize local shards or reconstruct a full copy

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L294). **Match → action:** COPY(UNSHARD) self-copy passes through to local COPY then rewraps. Copy to one device copies all device pieces and concatenates in shard-coordinate order, last shard axis first. Copy to tuple devices pads each shard into its full logical position, then ADD allreduces.

**Example:** Self-contiguous of logical `[8]` makes each `[4]` shard contiguous. Copy to CPU concatenates CPU copies of `[0:4]` and `[4:8]`; copy to replicated devices uses disjoint zero-padded contributions plus sum.

**Why:** Inference: distinguish local layout request, gather-to-one, and gather-to-all.

**Sharp edge:** This callback can introduce substantial communication and kernels. It assumes device tuples for physical gather and valid nonoverlapping shard ownership.

For gather-to-all with two four-element shards, the contributions can be represented as `[a,b,c,d,0,0,0,0]` and `[0,0,0,0,e,f,g,h]`. Their elementwise sum reconstructs `[a,b,c,d,e,f,g,h]`. Padding determines where each owner contributes; the collective performs the actual exchange and sum. Thus a view-like UNSHARD can lead to substantial work when a consumer finally demands a full copy.

### schedule/multi.py:L296 — Apply a collective to each local shard payload

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L296). **Match → action:** ALLREDUCE(UNSHARD) becomes UNSHARD(ALLREDUCE(local, original red.arg),same sharding).

**Example:** `allreduce(U(tile_local,axis1)) → U(allreduce(tile_local),axis1)`.

**Why:** Inference: preserve the logical shard view while the requested collective acts on represented local values.

**Sharp edge:** Different from REDUCE crossing a sharded dimension, which removes that dimension and constructs its own collective.

### schedule/multi.py:L300 — Rewrite bodies of value-producing functions for shards

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L300). **Match → action:** CALL with unbound outputs invokes rewrite_into_function unless arg absent/precompile. Rewrite its body with multi_pm, require SINK, and strip immediate UNSHARD wrappers from all actual arguments/RETURNED outputs.

**Example:** A parametric function producing `out = in+1` for distributed inputs gets per-shard body and per-shard argument views.

**Why:** Source: body is an ordinary parametric program; output PARAM destinations subview through normal STORE rules.

**Sharp edge:** Precompiled calls are left intact; value-producing calls are distinct from opaque void custom kernels.

### schedule/multi.py:L301 — Pass ownership through value/dependency wrappers

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L301). **Match → action:** CALL/AFTER whose first source is UNSHARD invokes passthrough_multi: peel first and any other immediate UNSHARD sources, rebuild same op/arg, rewrap first source’s sharding.

**Example:** `AFTER(U(v,0),effect) → U(AFTER(v,effect),0)`.

**Why:** Inference: dependence on an effect need not gather a sharded value.

**Sharp edge:** Sharding compatibility is a representation invariant here; callback does not do general resharding of other arguments.

### schedule/multi.py:L303 — Pass local storage into void custom calls

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L303). **Match → action:** Void CALL with immediate UNSHARD inputs and no unbound outputs strips wrappers from each source, preserving arg.

**Example:** `CALL(custom_kernel,U(out),U(in)) → CALL(custom_kernel,out_local,in_local)`.

**Why:** Source: non-value-producing custom calls consume local shard storage directly; value calls have separate handling.

**Sharp edge:** A value-producing CALL must not take this shortcut because its body/output bindings need rewriting.

### schedule/multi.py:L305 — Push casts and backward markers into shards

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L305). **Match → action:** CAST/BITCAST/DETACH/CONTIGUOUS_BACKWARD with UNSHARD source uses passthrough_multi and rewraps same ownership.

**Example:** `CAST_fp32(U(half_local,0)) → U(CAST_fp32(half_local),0)`.

**Why:** Inference: these payload operations generally act independently within each owner.

**Sharp edge:** The general passthrough keeps sharding metadata unchanged; shape-changing bitcasts still rely on other shape invariants/preparation.

### schedule/multi.py:L308 — Store shard values into corresponding full-destination slices

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L308). **Match → action:** STORE(dest,UNSHARD(multi)) becomes STORE(shard_subview(dest,multi),multi.src[0]); full shape must match. Scalar-expanded full destinations/values have a special local-expand path in helper.

**Example:** A thread/device owning logical `[4*d:4*d+4]` writes its local four values into that slice of full `[8]` output.

**Why:** Source: supports fragment-to-full-output-tile stores.

**Sharp edge:** Ownership-qualified subviews prevent all shards from racing on the whole destination; mismatched shapes assert.

### schedule/multi.py:L310 — Store into each local destination shard

[Source](../../../../tinygrad/tinygrad/schedule/multi.py#L310). **Match → action:** STORE with UNSHARD destination peels destination. Other UNSHARD operands peel; full logical-shaped operands take per-shard subviews; others pass through.

**Example:** `U(B_local,0).store(A_full[8]) → B_local.store(A_full[4*d:4*d+4])`.

**Why:** Source: every owner writes its own shard; same operand treatment as local ALU.

**Sharp edge:** Expanded scalars arrive as full shapes and must be subviewed; simply indexing every owner at zero would be incorrect for nonconstant full values.

## Scheduling and copy recognition: preserve effects across launches

The earlier stages have formed calls; this section binds reusable call templates to actual buffers and orders them. A plain transfer can be performed by a device copy engine (**DMA**, direct memory access; SDMA names the transfer path here), but that engine does not evaluate an expression such as `A+1`. Copy recognition therefore checks the body has exactly the required load/store structure before replacing a compute call with a transfer.

### schedule/__init__.py:L95 — Bind cached schedule buffer parameters

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L95). **Match → action:** PARAM with nonnegative slot returns corresponding outer CALL argument from context; negative slots stay.

**Example:** Cached PARAM(slot=1) → caller’s B; named n at slot=-1 remains n.

**Why:** Source: only buffer PARAMs bind to positional call args, not ALU/shape variables.

**Sharp edge:** Lexical argument scope matters; nested LINEAR calls resolve recursively rather than using a single global slot table.

### schedule/__init__.py:L97 — Freshen anonymous buffers when reusing schedules

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L97). **Match → action:** Source-free BUFFER with ParamArg and GLOBAL address space invokes create_new_buffer, memoized per rewrite context by old buffer identity.

**Example:** A cached temporary descriptor T becomes fresh buffer T_this_call; all uses within this call share it.

**Why:** Inference: schedule caching reuses structure without aliasing every invocation’s temporary storage.

**Sharp edge:** Existing buffers with sources, non-ParamArg buffers, and nonglobal buffers do not match callback guards.

### schedule/__init__.py:L115 — Instantiate and flatten a scheduled function call

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L115). **Match → action:** CALL whose body is LINEAR runs pm_post_sched_cache over body with actual args, gathers bound-variable names p{i} merged over enclosing binds, recursively resolves nested LINEAR calls, and substitutes matching scalar variables into each item’s sources.

**Example:** `CALL(LINEAR(kernel(P0),kernel2(P1)), A,B)` becomes instantiated LINEAR with concrete A,B and fresh temporary buffers.

**Why:** Source: nested calls have lexical scope; positional scalar bindings shadow enclosing bindings, scalar-free calls inherit them.

**Sharp edge:** The matcher also appends imported pm_flatten_linear; flattening is separate from binding and must preserve call scopes.

Think of ordinary Python calls `outer(A)` and `inner(B)`: the first parameter of `inner` refers to B, even if `outer` also has a parameter numbered 0. Flattening the execution lists must happen with the bindings of each nested call still available. Otherwise a syntactically reasonable flat list could read the wrong buffer or use the wrong symbolic size.

### schedule/__init__.py:L148 — Schedule an ordinary tensor program

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L148). **Match → action:** CALL invokes lower_sink_to_linear only for SINK bodies not tagged KernelInfo and without unbound outputs. Cache by function.key if SCACHE, otherwise verify, prepare, rangeify/split, and create_schedule; replace body by LINEAR.

**Example:** A tensor function computing RMSNorm becomes CALL(LINEAR(reduction_kernel, normalization_kernel),args), subject to actual shapes/boundaries.

**Why:** Inference: this is the transition from tensor-level function to ordered launches; kernel SINKs must not recursively reschedule themselves.

**Sharp edge:** Value-producing functions inline elsewhere. A cache hit reuses schedule structure, with actual argument instantiation deferred.

### schedule/__init__.py:L170 — Canonicalize potential transfer kernels

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L170). **Match → action:** CALL(SINK ast,dst,src) with exactly two args and different devices, or DISK same-device, rewrites ast with sym+pm_mops+pm_flatten_range+pm_simplify_ranges. Same-device nondisk leaves it.

**Example:** A two-dimensional full-buffer copy body is simplified to a single flat range so the next exact rule can recognize it.

**Why:** Source calls this codegen for SDMA devices: lower copy-shaped compute to transfer representation.

**Sharp edge:** This rule does not itself prove or emit a COPY; a remaining arithmetic or offset kernel may subsequently fail mixed-device validation.

### schedule/__init__.py:L173 — Recognize a scalar transfer

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L173). **Match → action:** CALL body exactly SINK(STORE(INDEX(dst_PARAM,0),INDEX(src_PARAM,0))) invokes copy_kernel_to_copy_uop; different devices or DISK required. Replace body by COPY(src_PARAM,target_device), retain actual args.

**Example:** A one-element CPU→AMD assignment becomes a transfer CALL instead of compiled load/store kernel.

**Why:** Inference: scalar case has no loop RANGE/END to match the next rule.

**Sharp edge:** Same-device nondisk copy stays a compute kernel here; pointer offsets other than zero do not match.

### schedule/__init__.py:L176 — Recognize a flat full-range transfer

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L176). **Match → action:** CALL body exactly SINK(END(STORE(dst_PARAM[r],src_PARAM[r]),r)) uses the same copy callback and device guard.

**Example:** `for r in 0..N: AMD_B[r]=CPU_A[r] → COPY CALL(CPU_A → AMD_B)`.

**Why:** Inference: expose DMA/backend transfer path once identical contiguous indexing is proven syntactically.

**Sharp edge:** Both accesses and END must reference the same RANGE; transformed indices or additional arithmetic prevent recognition.

### schedule/__init__.py:L181 — Reject remaining mixed-device compute kernels

[Source](../../../../tinygrad/tinygrad/schedule/__init__.py#L181). **Match → action:** CALL with SINK body collects distinct non-None PARAM devices from ast; raises if two or more remain.

**Example:** A surviving kernel computing AMD_B[i]=CPU_A[i]+1 fails here; preparation should have computed on source device then transferred.

**Why:** Source: a call that was not recognized as copy currently cannot be cross-device.

**Sharp edge:** Validation-only rule returns no replacement. Correct transfer extraction must precede it.

### Effect ordering is also outside the matchers

[`create_schedule`](../../../../tinygrad/tinygrad/schedule/__init__.py#L28) constructs RAW edges from producers of each buffer state to readers, then WAR edges from readers of an old state to later overwriting kernels. It topologically orders launches and raises on cycles. Example: kernel K1 reads old A to produce B; K2 overwrites A. Even if B does not feed K2, K1 must precede K2. Comparing pointer addresses alone loses that constraint; AFTER state identity carries it.

This means “fusion between kernels” is constrained by both iteration compatibility and buffer-version ordering. A clever algebraic rewrite cannot safely eliminate a boundary if it would make one kernel require mutually inconsistent states of the same buffer.

### Shared collective callback: why the ALLREDUCE rules can create many kernels

[`handle_allreduce`](../../../../tinygrad/tinygrad/schedule/allreduce.py#L6) only handles tuple-device inputs. It pads to maximum shape and makes input contiguous. Its source comment gives an empirical reason for the default small-case path: ring overhead is not beneficial for only two nodes or fewer than roughly 256k elements.

- **Naive:** copy each device's whole contribution to target device(s), reduce those copies, shrink back to logical shape. Two GPUs each contributing `[1,2]` and `[3,4]` produce `[4,6]` on every requested target.
- **All-to-all:** for concrete shapes, forced by `ALL2ALL>=2`, or enabled for more than two devices and `numel > RING_ALLREDUCE_THRESHOLD` with `ALL2ALL>=1`. Split into near-equal chunks; choose the largest dividing factor in `[32,16,8,4,2]` or 1 for chunk alignment. Device i receives chunk i from every contributor and reduces it; copy reduced chunks to all targets and reconstruct.
- **Ring:** concrete shapes only, and only if all-to-all was not selected. Force with `RING>=2` or enable under the same size/device threshold with `RING>=1`. Each chunk traverses successive devices, accumulating each contribution; then the reduced chunk is forwarded around the devices for gathering. The implementation expresses copies and arithmetic as UOps, not one magical hardware collective instruction.

For a forced four-device, 128-element example, the dividing factor is 32 and chunks are 32 elements each: device 0's reduced chunk in the all-to-all path represents the sum of all four contributors' elements 0–31; similarly for the other chunks. Gathering places each nonoverlapping chunk back at its original position using padding and addition. The actual alignment chooser and chunk sizes follow the code, and larger workloads amortize transfer/dispatch overhead better. Floating reduction order can differ between algorithms.

[`create_allreduce_function`](../../../../tinygrad/tinygrad/schedule/allreduce.py#L60) wraps that expansion in a precompiled function: output PARAM slot 0, source PARAM slot 1, an output STORE, and actual arguments `(output, contiguous(input))`. If no output was supplied it starts with an invalid output placeholder. The returned AFTER tracks completion of the collective. Thus the prepare rule's one replacement can generate multiple compute and transfer launches; it is not equivalent to fusing neighboring arithmetic operations.
