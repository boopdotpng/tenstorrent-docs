# Kernel lowering, GPU dimensions, gates, and control flow: every rule

Source snapshot: tinygrad `107adc31701df0247dfa45e175984df906a68b53` (`master`). This chapter covers every rule defined in `codegen/__init__.py`, `simplify.py`, `gpudims.py`, `late/gater.py`, `late/linearizer.py`, and `late/regalloc.py`. Matchers imported or concatenated from other files are documented in their owning chapters. Empty visualization matchers contain no rules.

## Read this first: from an array expression to a runnable loop

Suppose Python asks for `y[row, col] = x[row, col] * scale[row]`. A tensor expression says which values are wanted. A kernel must additionally say which worker handles each element, where each value is stored, when shared values are ready, and which instructions execute in which order. **Lowering** fills in those decisions through successively more explicit representations. These rules do that work after the scheduler has chosen kernel boundaries.

A **UOp** is one node in the compiler's graph. Its `src` fields point to input nodes; its `arg` contains extra metadata such as an axis identifier. A **PatternMatcher** tries an ordered list of shapes to recognize and callbacks to run. A rule's **guard** is an additional condition that must hold before its replacement is valid. A callback that “declines” returns `None`; an analysis callback may still have recorded information for a later rule. A **SINK** is the root collecting the work required from a graph.

The vocabulary below distinguishes choices that are easy to conflate:

| Term | Meaning in this chapter | Array example |
| --- | --- | --- |
| Range / axis | An iteration coordinate and its bound; an axis type says how to execute it | `r = RANGE(8)` visits `0` through `7`; some ranges become loops, others become GPU worker IDs |
| Reduction | Combine many values into fewer with an operator | `sum(x[row,r]**2 for r in range(N))` |
| Identity | Starting value that does not alter a reduction | `0 + x = x`, `1 * x = x` |
| Lane / vector | One component / a bundle of components; a shaped UOp can describe such a bundle | `[x0,x1,x2,x3]` has four value lanes; it need not become one machine vector instruction |
| Upcast / unroll | Represent several fixed iterations explicitly at compile time | Four scalar expressions replace a four-iteration loop; “upcast” here does **not** mean converting fp16 to fp32 |
| Horizontal reduction | Reduce components already present in a shaped value | `[a,b,c,d]` becomes `a+b+c+d`, without a runtime range for that dimension |
| Buffer / address / load | Storage / a location in storage / reading the value at that location | `INDEX(B,i)` locates `B[i]`; `LOAD(INDEX(B,i))` reads it |
| View | A changed logical arrangement of the same values | A transpose swaps which coordinates address each element |
| Gate / predicate / mask | Boolean condition deciding whether an access or lane is valid | `i<N` suppresses padded writes and supplies a fallback for padded reads |
| GLOBAL / LOCAL / REG | Device-visible storage / storage shared by one workgroup / a thread's register-like state | Input tensor / shared partial sums / one thread's accumulator |

A GPU **workgroup** contains workers that can share LOCAL memory and synchronize with a barrier. A **warp** (AMD: wavefront) is a hardware execution group within that model. A *worker lane* is a thread's position in such a group; it is distinct from a *value lane* in a vector. A workgroup barrier cannot synchronize arbitrary workgroups or separately launched kernels.

`AFTER(value,effects...)` says the value is usable after those effects; `END(body,r)` closes the work for range `r`. These are graph-level dependencies, which later become control flow or synchronization. **RAW** (read after write) means a consumer must wait for the producer's write. **WAR** (write after read) means a later overwrite must wait for readers of the previous contents. Both occur when reusing shared memory across loop iterations.

`PARAM(slot=k)` names an argument position in a kernel's calling convention (its **ABI**). A `CALL` supplies the actual buffers and scalars for those positions; a slot has meaning within its own function. `PROGRAM` records compilation stages, `LINEAR` holds an ordered instruction list, and `INS` denotes a machine instruction in a direct-assembly backend. **ISA** means the instruction set accepted by the hardware. **WMMA** names tinygrad's matrix-multiply-accumulate operation: hardware computes a tile of `A @ B + C`, with values packed into prescribed per-thread **fragments**. The packing rules below reconcile those fragments with ordinary array shapes.

Read each entry as **the recognizable input and guard → replacement → worked shape/value example → why this helps → limitation**. “Same UOp” means the same graph node, which is stricter than two formulas that happen to compute equal numbers. Schematics below explain this source snapshot; they are not measurements or promises about every backend.

Examples below are **schematic, source-reviewed UOp transformations**, not captured execution traces. `RANGE(N)` means integer iterations `0..N-1`; `sum_r` is ADD reduction; `after(value, dependency)` orders effects without changing the returned value; `Invalid` denotes an invalid index/value, not floating-point NaN. Where the source comments state a purpose, it is labeled **Source rationale**. **Inferred rationale** explains the present transformation, not an unverified historical reason for its introduction. Rule ordering matters: an earlier matching callback returning a replacement prevents later alternatives from handling that node in that attempt; callbacks returning `None` may still update context.

RMSNorm scales a row by `1/sqrt(mean(x**2)+eps)` (and typically a learned weight). The row sum of squares is the reduction used as a running example here. For a GPU RMSNorm kernel using grouped reduction, a relevant chain is: split work across local lanes; reduce each lane's squares; stage partial sums in local memory; synchronize; reduce those partials; guard the single global result writer. These rules implement that chain inside a kernel. They do **not** fuse separately launched kernels. The [RMSNorm kernel-fusion walkthrough](../rmsnorm-kernel-fusion.md) covers the schedule boundary.

## Main lowering pipeline

The early rules expose fixed value lanes and hardware matrix fragments. The middle rules turn reductions into explicit accumulators, loads, stores, and barriers. The final rules order those operations, render source or assembly, and compile a binary. A **void** operation represents an effect rather than a returned element value; a **renderer** translates the lowered representation into a target language or instruction form. **Legalization** means making the representation satisfy the next stage or target’s requirements.

### codegen/__init__.py:L39 — Allocate missing parameter slots

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L39), `pm_number_params`. Matches any PARAM, but changes only `arg.slot == -1`. `do_number_param` takes the current context counter, assigns that slot, and increments the counter.

**Example:** with three previously numbered parameters, `PARAM(_device_num, slot=-1)` becomes `PARAM(_device_num, slot=3)`.

**Inferred rationale:** late-created scalar parameters need concrete positions in the kernel launch ABI.

**Sharp edge:** existing slots are untouched; the caller initializes the counter to the number of numbered parameters, so it relies on their established numbering convention.

### codegen/__init__.py:L79 — Turn expanded reduction axes into horizontal dimensions

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L79), `expander`. `expand_reduce` separates real RANGE sources from shaped sources replacing upcast/unroll ranges, collecting non-unit dimensions of the latter. With no such dimensions it declines; otherwise it asserts the existing horizontal-axis count is zero, moves collected axes to the front, reduces them horizontally alongside remaining ranges, then restores unit dimensions.

**Example:** a `(2,4)` value reduced over an expanded size-4 axis becomes `permute(4,2) → REDUCE(horizontal_axes=1) → reshape(2,1)`.

**Source rationale:** “permute so new_axes come to front, then reduce.”

**Sharp edge:** the leading-axis representation is an internal contract, not arbitrary NumPy-style reduction axes.

For the `(2,4)` example, name the entries `v[row,lane]`. The result wanted is `[sum(v[0,:]), sum(v[1,:])]`. Moving the lane axis first gives `w[lane,row]`; reducing its first dimension produces two row sums. Reshaping to `(2,1)` restores the singleton reduced dimension so later broadcasting still knows which row each sum belongs to.

### codegen/__init__.py:L80 — Materialize upcast/unroll indices

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L80), `expander`. Matches RANGE but replaces it only if its axis ID is in `build_range_map`, which includes UNROLL and UPCAST axes. It creates `CONST((0,...,r.vmax))`, reshaped so its non-unit dimension occupies that axis's position in the shared expansion shape.

**Example:** two upcast axes of lengths 2 and 4 become index arrays shaped `(2,1)` and `(1,4)`.

**Inferred rationale:** compile-time lanes become explicit shaped values so broadcasting expands the operations.

**Sharp edge:** regular REDUCE/GLOBAL/LOCAL loops must not be expanded here; using `vmax+1` assumes this finite compile-time lane model.

### codegen/__init__.py:L83 — Pack WMMA fragments and restore output lanes

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L83), `expander`. `expand_wmma` acts only when `u.arg[3]` still describes input/output upcast axes. It maps axis IDs to shape positions, permutes A/B's designated fragment axes to the end and flattens those axes, passes accumulator C unchanged, clears that metadata to `None`, and unflattens/permutates the result. C is already expected in the required form.

**Example:** input fragment axes of sizes `(2,4)` become a trailing 8-element fragment; a corresponding 8-element output fragment is restored to `(2,4)` in its designated positions.

**Inferred rationale:** WMMA consumes hardware fragments while surrounding graph arithmetic uses broadcast shapes.

**Sharp edge:** this is layout legalization; axis order is part of tensor-core correctness, not cosmetic reshaping.

The obstacle is that a logical tile coordinate such as `(row,col)` is not necessarily its position in an instruction's register list. Packing gathers the designated fragment axes together and flattens them in the required order. Unpacking applies the inverse arrangement to the result. Keeping all the same numbers but permuting this list incorrectly feeds the instruction the wrong matrix elements.

### codegen/__init__.py:L103 — Fold an addend into WMMA's accumulator

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L103), `pm_wmma_add`. Matches `WMMA(A,B,C) + D` and produces `WMMA(A,B,C+D)`, retaining WMMA arguments.

**Example:** a matmul tile `WMMA(A,B,0)+bias_tile` becomes `WMMA(A,B,bias_tile)`.

**Inferred rationale:** expose the matrix instruction's accumulator operand and eliminate separate output addition where subsequent lowering permits.

**Sharp edge:** this changes where floating-point addition occurs relative to accumulation; it is not a proof of bit-identical IEEE reassociation. It is an operation rewrite inside one kernel, not scheduler-level kernel fusion.

### codegen/__init__.py:L106 — Pull an addend through a permuted WMMA output

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L106), `pm_wmma_add`. Matches `permute(WMMA,p)+D`; output is `permute(WMMA+permute(D,inverse(p)),p)`.

**Example:** `transpose(W)+D[4,2] → transpose(W+transpose(D)[2,4])`.

**Source rationale:** push permute/reshape to the other side of the add. This exposes the L103 rule while preserving logical coordinates.

**Sharp edge:** the inverse permutation is `argsort(p)`; applying `p` directly works for a transpose but fails for non-self-inverse permutations.

### codegen/__init__.py:L108 — Pull an addend through reshape and permutation

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L108), `pm_wmma_add`. Matches `permute(reshape(WMMA,s),p)+D`, inverse-permutes D, reshapes it to the original WMMA shape, adds, then reapplies both output transforms.

**Example:** `transpose(reshape(W[8],(2,4)))+D[4,2] → transpose(reshape(W+reshape(transpose(D),(8,)),(2,4)))`.

**Source rationale:** the same accumulator-exposure strategy as L106.

**Sharp edge:** equal element counts are insufficient without the inverse layout transform; a flat bias in the wrong lane order produces wrong answers.

### codegen/__init__.py:L113 — Make broadcasting explicit

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L113), `pm_expand_broadcast`. Matches binary/ternary operations and STORE. If any source shape is unknown, or all agree, it declines. Otherwise it computes the shared broadcast shape and explicitly expands each source.

**Example:** `(2,1)+(1,4) → expand(a,(2,4))+expand(b,(2,4))`.

**Inferred rationale:** the next devectorization pass requires corresponding input lanes to share a shape.

**Sharp edge:** STORE participates too: destination and data lanes must agree. This rule does not itself generate machine vector instructions.

### codegen/__init__.py:L114 — Split batched WMMA while retaining each fragment

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L114), `pm_expand_broadcast`. `broadcast_and_devec_wmma` broadcasts shapes excluding the final fragment dimension, then emits one WMMA for every leading coordinate and stacks/reshapes outputs. It declines when all operands are already just one-dimensional fragments.

**Example:** two batch positions of 8-lane fragments yield `stack(WMMA(A[0],B[0],C[0]), WMMA(A[1],B[1],C[1]))`.

**Inferred rationale:** one WMMA handles a hardware fragment, not arbitrary tensor batch dimensions.

**Sharp edge:** operand fragment lengths remain their own trailing sizes; blindly broadcasting the whole shape would confuse input and accumulator layouts.

### codegen/__init__.py:L139 — Devectorize shaped elementwise arithmetic

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L139), `ew_devectorizer`. `do_devectorize` declines scalar outputs and inputs whose shapes do not match the output, except Invalid sources. It indexes each source at every output coordinate, runs a scalar operation, and stacks/reshapes results.

**Example:** `ADD([a0,a1],[b0,b1]) → stack(a0+b0,a1+b1)`. Invalid is passed through as its scalar base.

**Source rationale:** broadcasting must already be unpacked.

**Sharp edge:** this early matcher handles elementwise operations only; explicit memory operations have a later pass.

### codegen/__init__.py:L144 — Devectorize elementwise operations and memory accesses

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L144), `devectorizer2`. Uses the same callback/shape guards as L139, now including LOAD and STORE.

**Example:** `STORE([p0,p1],[v0,v1]) → GROUP(STORE(p0,v0),STORE(p1,v1))`, whereas a shaped LOAD becomes a STACK of scalar loads.

**Inferred rationale:** memory effects cannot be represented as a tensor of returned values, so stores become a GROUP.

**Sharp edge:** this exposes scalar lanes for subsequent memory coalescing; it does not imply the final machine code must retain scalar loads/stores.

### codegen/__init__.py:L146 — Remove an index with no indices

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L146), `devectorizer2`. Exact source pattern `INDEX(x)` becomes x.

**Example:** after all shaped coordinates have disappeared, `INDEX(accumulator)` becomes the accumulator.

**Source rationale:** “INDEX without src is nothing,” with a TODO to move this into movement cleanup; the pattern actually retains the base source and has no coordinate sources.

**Sharp edge:** `INDEX(x,0)` is not covered: selecting element zero can change shape/address and is not generally an identity.

### codegen/__init__.py:L148 — Make WMMA operand lanes explicit

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L148), `devectorizer2`. `do_stack_wmma` declines if every input is already STACK or WMMA. Otherwise it asserts a one-dimensional result and turns each non-STACK operand into a STACK of indexed elements.

**Example:** fragment operand `a[8]` becomes `stack(a[0],...,a[7])`.

**Inferred rationale:** downstream hardware instruction selection needs explicit fragment lanes.

**Sharp edge:** when the callback does run, its per-input test is only “not STACK”; a WMMA operand can also be indexed into lanes. The earlier all-STACK-or-WMMA early exit is broader than that inner test.

### codegen/__init__.py:L150 — Distribute a stack of indices over a buffer

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L150), `devectorizer2`. Matches INDEX whose base is PARAM or BUFFER and whose coordinate is STACK.

**Example:** `INDEX(B,stack(3,7)) → stack(INDEX(B,3),INDEX(B,7))`.

**Source rationale:** stacked INDEX is many INDEX.

**Sharp edge:** the restricted base kinds matter; this is not a universal law for indexing arbitrary shaped computed values, whose movement semantics are handled elsewhere.

### codegen/__init__.py:L153 — Move index reshaping to the result

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L153), `devectorizer2`. Matches `INDEX(B,RESHAPE(indices,s))`, again restricting B to PARAM/BUFFER, and produces `RESHAPE(INDEX(B,indices),s)`.

**Example:** index values `[0,2,4,6]` reshaped `(2,2)` become four indexed values reshaped `(2,2)`.

**Inferred rationale:** expose the actual lane list to indexing and coalescing while retaining the requested output shape.

**Sharp edge:** this reshapes index results, not the physical storage layout of B.

### codegen/__init__.py:L156 — Drop a void reshape

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L156), `devectorizer2`. Matches any RESHAPE of void dtype and returns its first source.

**Example:** `RESHAPE(AFTER(void_effect,...),s) → AFTER(void_effect,...)`.

**Source rationale:** explicitly called a “hack for AFTER.” Effects do not have useful element-value shapes for later rendering.

**Sharp edge:** only the reshape disappears; its underlying effect/dependencies remain. Deleting the whole subtree would drop work.

### codegen/__init__.py:L158 — Convert singleton-to-scalar reshape into selection

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L158), `devectorizer2`. Matches RESHAPE, but fires only for destination `()` and source `(1,)`.

**Example:** `reshape(stack(x),()) → index(stack(x),0)`.

**Source rationale:** a single-element shaped value becomes a scalar by indexing.

**Sharp edge:** neither an arbitrary reshape nor a zero-length shape is covered; the exact `(1,)` guard is significant.

### codegen/__init__.py:L160 — Expand a scalar using nested stacks

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L160), `devectorizer2`. Requires scalar input, integer output dimensions, and no zero dimension. It repeats the input with nested STACKs, visiting dimensions in reverse order.

**Example:** `expand(x,(2,3)) → stack(stack(x,x,x),stack(x,x,x))`.

**Inferred rationale:** eliminate remaining broadcast movement in favor of explicit lanes.

**Sharp edge:** symbolic dimensions and empty expansions deliberately decline; constructing an empty STACK is not this rule's representation.

### codegen/__init__.py:L224 — Replace invalid reduction lanes with the identity

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L224), `pm_reduce_identity`. Matches a reduction of the shared `invalid_gate` pattern and replaces its Invalid branch with the reduction operator's identity.

**Example:** `sum_r(where(r<6,x[r],Invalid)) → sum_r(where(r<6,x[r],0))`; product uses 1, floating max uses negative infinity.

**Source rationale:** “an Invalid in a REDUCE source is that reduce's identity.”

**Sharp edge:** zero is wrong for product/max. For padded RMSNorm rows, zero is correct because the reduction sums squared values.

### codegen/__init__.py:L230 — Lower grouped reduction through local memory

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L230), `pm_reduce_local`. `fix_group_for_reduce` acts only if some reduced RANGE is GROUP_REDUCE. It first performs other reductions, stages one partial per grouped lane plus upstream WARP/LOCAL coordinates into LOCAL storage, replaces group axes with ordinary REDUCE axes whose IDs are offset by 100, and reduces those partials.

**Example:** 256-element RMSNorm sum with 32 participating lanes: each lane sums eight squares, stores `partial[lane]`, then a serial reduction sums 32 partials.

**Source rationale:** first non-grouped reduction, then final reduction; horizontal reductions remain in the first stage.

**Sharp edge:** other local coordinates must also index the buffer to prevent unrelated groups overwriting one another. Barriers and single-writer masks arrive later; this is not permission to read unsynchronized partials.

Step through the schematic row sum with lane `l` in `0..31`: compute `p_l = sum(x[row, l+32*k]**2 for k in 0..7)`, then write `shared[l] = p_l`. After the required synchronization, the final reduction reads all 32 partials. Now the 256 input values have each contributed once. The stride spelling here illustrates the division of work; the rule uses the range/layout selected earlier. Dividing by 256 and applying reciprocal square root belong to the surrounding RMSNorm expression.

### codegen/__init__.py:L232 — Turn a loop reduction into a mutable accumulator

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L232), `pm_reduce_local`. Matches REDUCE with at least an input and a range source. `reduce_ranges_to_acc` allocates a fresh REG placeholder, initializes it with the reduction identity after enclosing input ranges, orders update access after initialization and reduction ranges, emits accumulator update stores and ENDs, and returns the accumulator after completion.

**Example:** `sum_r x[row,r] → acc=0; for r: acc=acc+x[row,r]; result=acc`, initialized once per row.

**Inferred rationale:** renderers need explicit loop-carried state.

**Sharp edge:** initialization must sit outside the reduced loop but inside enclosing row loops; AFTER/END encode that correctness requirement. Horizontal components are reduced inside each update when present.

For two rows, the required sequence is `acc=0; sum row 0; save result; acc=0; sum row 1; save result`. Putting `acc=0` inside the column loop would keep only the last term. Putting it outside the row loop would mix rows. The apparently elaborate AFTER/END structure expresses exactly where initialization, updates, and reading the final result belong.

### codegen/__init__.py:L233 — Expand a purely horizontal reduction

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L233), `pm_reduce_local`. Matches a REDUCE with only its input source (no explicit ranges). The callback indexes all coordinates of the first `arg[1]` dimensions and combines values using the operator.

**Example:** `REDUCE(stack(a,b,c,d),ADD,horizontal_axes=1) → ((a+b)+c)+d`.

**Inferred rationale:** compile-time lanes become an explicit arithmetic reduction.

**Sharp edge:** this is a left fold, not necessarily a balanced tree, and it assumes the pass presents a nonempty set of lanes; floating-point association follows this emitted order.

### codegen/__init__.py:L234 — Merge compatible reduction loop endings

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L234), `pm_reduce_local`. At SINK, `merge_reduce_ends` groups only ENDs tagged `mergeable` by their ended ranges, then by surrounding range context. Same-context endings become one END around GROUPed updates; other contexts get cloned ranges with fresh axis IDs.

**Example:** two independent accumulators over r become `for r: {update_a; update_b}`, with one END.

**Source rationale:** one RANGE must map to one END; different nesting depths require cloned ranges.

**Sharp edge:** arbitrary ENDs are not merged, and two equal bounds do not establish equal scope. This fuses compatible loops within a kernel, not separate launches.

### codegen/__init__.py:L240 — Insert explicit loads at value consumers

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L240), `pm_add_loads`. Matches elementwise operations, REDUCE, WMMA, and STACK; converts sources in GLOBAL/LOCAL/REG address spaces to LOADs, leaving ordinary values alone. Shape-changing BITCAST is excluded.

**Example:** `ADD(INDEX(B,i),1) → ADD(LOAD(INDEX(B,i)),1)`.

**Inferred rationale:** separate address-like values from actual scalar data before rendering.

**Sharp edge:** loading through a bitcast that changes shape too early would use the wrong memory view; the special guard preserves that reinterpretation for other lowering.

### codegen/__init__.py:L242 — Load a store's value, not its destination

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L242), `pm_add_loads`. Applies `maybe_load` only to STORE's second source and preserves later sources.

**Example:** `STORE(dst[i],src[i],gate) → STORE(dst[i],LOAD(src[i]),gate)`.

**Inferred rationale:** copying between addresses requires a value read; the destination stays an address and the gate remains intact.

**Sharp edge:** applying the previous all-sources strategy to STORE would accidentally dereference its destination.

### codegen/__init__.py:L250 — Materialize a STAGE allocation and producer writes

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L250), `pm_add_local_buffers`. Matches STAGE, allocates a placeholder with its maximum shape, dtype, fresh slot, and requested address space; stores the producer indexed by stage axes and ends those axes, then returns the buffer AFTER those writes.

**Example:** `STAGE(partial[l],l,LOCAL) → local B; STORE(B[l],partial[l]).END(l); AFTER(B,writes)`.

**Inferred rationale:** turn abstract staging into explicit storage and ordering.

**Sharp edge:** maximum shape accommodates bounded dynamic extents; AFTER orders dependencies but is not itself a GPU barrier. L282 supplies cross-thread synchronization for LOCAL storage.

### codegen/__init__.py:L256 — Cast operands before floating-point decompositions

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L256), `pm_cast_float_alu`. Matches SIN, LOG2, EXP2, SQRT, RECIPROCAL and casts the operand to the result dtype when different.

**Example:** float32 `SQRT(int32(9)) → SQRT(CAST(float32,int32(9)))`.

**Source rationale:** decompositions expand transcendental operations into floating polynomials and assert float operands.

**Sharp edge:** this is not a blanket conversion of every ALU operand; integer operators must retain their own semantics.

### codegen/__init__.py:L282 — Synchronize local-memory read-after-write dependencies

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L282), `pm_implicit_barriers`. Matches AFTER but requires a LOCAL-address result and a LOCAL store among dependency ancestors, searching only until existing BARRIER nodes. Produces `base.after(BARRIER(dependencies))`.

**Example:** `LOAD(AFTER(shared,partial_stores)[lane])` gains a workgroup barrier between partial stores and loads.

**Source rationale:** LOCAL loads ordered after LOCAL stores need a workgroup barrier.

**Sharp edge:** a graph dependency alone orders operations for compilation, not all threads' visibility. This is essential for grouped RMSNorm reduction; global memory and existing barrier-protected dependencies do not trigger it.

### codegen/__init__.py:L283 — Protect shared storage before its next loop iteration

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L283), `pm_implicit_barriers`. Matches END. It requires a multi-iteration REDUCE/WEAK/LOOP range, no existing barrier as its body, a LOCAL store inside that loop, and a LOAD using the same underlying buffer. It replaces the ended body with a BARRIER depending on the body and all matching loads.

**Example:** `for tile: write shared; barrier; read shared; END` becomes `...read shared; barrier; END`.

**Source rationale:** stop next-iteration writes from racing other threads' current-iteration reads (WAR hazard).

**Sharp edge:** the store's range membership excludes unrelated stores reached through previous AFTER chains; a single-iteration loop does not need this reuse barrier.

There are two different waits in a tiled loop. The first says “all workers have finished writing tile t, so reads may start.” The second says “all workers have finished reading tile t, so nobody may overwrite it with tile t+1 too early.” A fast worker can otherwise corrupt a slow worker's input even when the first barrier is present.

### codegen/__init__.py:L410 — Reject graph-level IF/ENDIF

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L410), `pm_linearize_cleanups`. Matching either IF or ENDIF raises `RuntimeError("if not allowed in graph")`.

**Example:** an incoming linearized list already containing IF fails instead of being silently accepted.

**Source rationale:** IF statements are not allowed in the graph; this cleanup creates them only after linearization.

**Sharp edge:** this rule produces an error, not a rewritten graph. The subsequent rule's newly emitted IF/ENDIF are not recursively fed through this same line pass.

### codegen/__init__.py:L412 — Emit a control-flow guard around a store

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L412), `pm_linearize_cleanups`. Matches a three-source STORE to INDEX/SHRINK, optionally casted, with boolean gate. Replaces its line with `IF(gate,address); STORE(address,value); ENDIF`, returning the ungated store as the replacement identity for later references.

**Example:** `STORE(out[i],v,i<N) → if(i<N) out[i]=v`.

**Source rationale:** inject IF/ENDIF for gated stores.

**Sharp edge:** it runs on an ordered list because side-effecting control-flow delimiters need placement. Padding/global-writer masks must suppress the actual memory effect, not merely select a dummy value.

### codegen/__init__.py:L463 — Linearize a kernel program

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L463), `pm_to_program`. Exact `PROGRAM(SINK)` becomes `PROGRAM(SINK,LINEAR(...))` through priority topological linearization and line cleanups. For an ISA renderer it additionally applies pre-register-allocation rewriting, moves source-less register-definition INS nodes first, allocates registers, then applies post-allocation rewriting.

**Example:** `PROGRAM(SINK(store)) → PROGRAM(SINK(store),LINEAR(param,index,load,add,store,...))`.

**Inferred rationale:** dependency graphs must become an ordered instruction stream before text/assembly generation.

**Sharp edge:** moving source-less register definitions early deliberately makes callee-saved registers live across the whole program.

### codegen/__init__.py:L464 — Attach estimates once

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L464), `pm_to_program`. Matches `PROGRAM(SINK,LINEAR)` and fills `sink.arg.estimates` from the linear UOps only when absent, with `ignore_indexing=True`.

**Example:** a program lacking counts gains arithmetic/memory estimates; a second attempt returns None so later rules can render it.

**Inferred rationale:** attach cost metadata to the finalized program without repeated rewrites.

**Sharp edge:** estimates intentionally omit indexing work; they are not measured latency or exact machine instruction counts.

### codegen/__init__.py:L465 — Assemble an all-instruction linear program

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L465), `pm_to_program`. Matches a two-source PROGRAM whose LINEAR sources all match INS. It constructs readable instruction text, calls the renderer's assembler, and appends SOURCE and BINARY together.

**Example:** `PROGRAM(sink,LINEAR(INS(...),INS(...))) → PROGRAM(sink,linear,SOURCE(assembly),BINARY(bytes))`.

**Inferred rationale:** direct ISA renderers bypass the source-language compiler path.

**Sharp edge:** this rule precedes generic rendering; mixed non-INS linear contents must first be lowered appropriately.

### codegen/__init__.py:L466 — Render a linear program to source

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L466), `pm_to_program`. Matches a PROGRAM with precisely its original root and LINEAR, calls `ctx.render`, and appends SOURCE.

**Example:** `LINEAR(load,mul,store) → SOURCE("...out[i] = in[i] * ...;")`.

**Inferred rationale:** C-like/PTX-like renderers need textual code before compilation.

**Sharp edge:** appending SOURCE changes arity so this rule stops matching; retaining the two-source pattern would repeatedly render forever.

### codegen/__init__.py:L467 — Compile rendered source

[Source](../../../../tinygrad/tinygrad/codegen/__init__.py#L467), `pm_to_program`. Matches PROGRAM with root, LINEAR, SOURCE; calls `compiler.compile_cached`, optionally disassembles for debug, and appends BINARY.

**Example:** generated C source becomes the compiler's cached executable blob.

**Inferred rationale:** compilation is another state transition in the UOp program representation.

**Sharp edge:** the callback performs compilation, not pure algebra, and compiler errors propagate. This does not launch a kernel.

## Range and reduction simplification

These rules reduce the work needed to enumerate array coordinates. First they reshape iteration domains or shorten provably unused loops; then they replace special reductions with arithmetic counts or selected loads. A range-free expression has the same value for every iteration of the ranges under consideration. This independence is what makes “count copies of a value” possible.

### codegen/simplify.py:L18 — Flatten expressions naming ended ranges

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L18), `pm_flatten_range`. On REDUCE/END, `flatten_range` finds the range-source offset and replaces range expressions with the actual ranges they depend on. Bool/void sources are retained as backedges rather than traversed for ranges.

**Example:** `END(body, r0*4+r1) → END(body,r0,r1)`; `END(body,r,condition)` retains condition without ending every range mentioned in it.

**Source rationale:** real ranges only; ranges in the condition should not be ended.

**Sharp edge:** a condition or effect dependency is not another loop to close.

### codegen/simplify.py:L55 — Merge axes only when index arithmetic does not worsen

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L55), `pm_simplify_ranges`. Requires actual RANGE ended sources. For END it tries adjacent pairs; for REDUCE all ordered pairs. Types must match and both ranges must participate in exactly the same reductions. It substitutes `r0=k//size1`, `r1=k%size1`, simplifies, and accepts only if the number of FLOORDIV/FLOORMOD nodes does not increase.

**Example:** `i<2,j<4; B[i*4+j]` becomes `k<8; B[k]`.

**Source rationale:** return after one merge so subsequent attempts use fresh ranges.

**Sharp edge:** equal axis types alone do not allow merging when one axis is reduced in an inner operation and the other is not; indexing overhead is explicitly checked.

### codegen/simplify.py:L56 — Record the largest required gated extent

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L56), `pm_simplify_ranges`. INDEX callback `mark_gated` performs analysis only. For a WHERE-gated coordinate it collects AND terms `RANGE < CONST`, records the largest bound observed across accesses, and records full extent for ungated uses.

**Example:** a length-128 loop with only accesses gated at 70 and 80 records 80; an additional ungated access forces 128.

**Source rationale:** maximum across users is required; an ungated use prevents shrinking.

**Sharp edge:** this recognizes a narrow guard shape, not arbitrary equivalent predicates. It returns no rewrite; its effect is the context consumed by L59.

### codegen/simplify.py:L58 — Protect reduction domains against shrinking

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L58), `pm_simplify_ranges`. On REDUCE, records each explicit reduced range's full bound in context.

**Example:** a masked load within `sum_{r<128}` does not by itself authorize replacing the reduction domain with 80 iterations.

**Source rationale:** “reduce ranges can't be shrunk.”

**Sharp edge:** shrinking can change reduction semantics or identities and interacts with other users; the source chooses this conservative protection rather than proving every operation safe. This is an analysis callback, not a new REDUCE node.

### codegen/simplify.py:L59 — Apply recorded loop bounds at the root

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L59), `pm_simplify_ranges`. At SINK, `do_substitute` replaces marked ranges' bounds with context values, clears the context, and simplifies a changed graph.

**Example:** the guarded non-reduction `r<128` collected at L56 becomes `r<80`; the guards may then simplify.

**Inferred rationale:** all uses must be inspected before globally changing a shared range.

**Sharp edge:** context clearing is essential across repeated rewrite attempts; stale facts from an older graph are not safe proof for the next one.

### codegen/simplify.py:L73 — Record an exact-divisor range split

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L73), `pm_split_ranges`. Matches `RANGE % constant`; marks the range only once, excludes WARP and DEVICE axes, requires a constant range extent, and requires that extent be divisible by the modulus.

**Example:** `(r<128)%32` records a split into 4×32; `(r<130)%32` declines.

**Source rationale:** ranges that are not looped over cannot be split.

**Sharp edge:** WARP lane identity and per-device selection are execution contracts; remapping them into nested loops is not an ordinary arithmetic simplification.

### codegen/simplify.py:L74 — Replace a marked range by quotient and remainder loops

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L74), `pm_split_ranges`. At SINK, replaces r with `outer*(divisor)+inner`, where outer has extent `N/divisor`, inner has extent divisor, and their axis arguments gain distinguishing 0/1 components before the axis type.

**Example:** `r<128 → outer<4,inner<32; r=outer*32+inner`, so `r%32 → inner`.

**Inferred rationale:** trade repeated quotient/remainder arithmetic for an explicit multidimensional loop.

**Sharp edge:** exact divisibility was checked by L73; this rule does not construct a tail mask for nonmultiples. Context is cleared after substitution.

### codegen/simplify.py:L96 — Eliminate reduction axes absent from the value

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L96), `pm_reduce_unparented`. Handles ADD/MAX/MUL only, asserting explicit reduction sources are RANGE. Separates axes used by the input from unused ones.

**Example:** `sum_{r<4} x → 4*x`; `product_{r<4} x → x**4`; `max_{r<4} x → x`. Other used axes remain reduced.

**Source rationale:** remove ranges not referenced in the source.

**Sharp edge:** no general reduction operator is assumed idempotent; MAX can drop repeated identical values, ADD and MUL need multiplicity. Floating multiplication/power can reassociate repeated arithmetic.

### codegen/simplify.py:L101 — Isolate a range-dependent addend in a comparison

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L101), `pm_reduce_collapse`. Matches `(x+y).or_casted() < c`, requiring y and c to contain no RANGE. Produces `x < c-y`.

**Example:** `r+3<10 → r<7`, exposing a bound for interval counting.

**Source rationale:** lift x+y out of reduction comparisons.

**Sharp edge:** this is used within the controlled collapse analysis; there is no general overflow/cast-equivalence proof in this callback. See L156 for the special loaded-index issue.

### codegen/simplify.py:L103 — Convert a positive integer stride comparison into a bound

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L103), `pm_reduce_collapse`. `(x*y)<c → x<((c+y-1)//y)` only if y and c are range-free, y is integer, and its minimum is strictly positive.

**Example:** `3*r<10 → r<4`.

**Inferred rationale:** ceil-division isolates the countable range from stride arithmetic.

**Sharp edge:** positive y is essential; negative multiplication reverses inequalities and zero cannot divide. The check is based on value bounds, not merely y being a literal.

### codegen/simplify.py:L106 — Count constant-valued lanes in a bounded interval

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L106), `pm_reduce_collapse`. One template has three alternatives: `sum_r(where(r<upper,val,0))`, `sum_r(where(r<lower,0,val))`, and `sum_r(where(!(r<lower)&(r<upper),val,0))`. It requires val to contain no RANGE. The count is `clamp(min(upper,N)-max(lower,0),0,N)` with absent endpoints defaulting to N/0, then multiplies val.

**Examples at N=8:** upper=3 gives `3*val`; lower=5 gives `3*val`; lower=2,upper=6 gives `4*val`.

**Source rationale:** the complete interval-count formula is in the comment.

**Sharp edge:** bounds are clamped for empty/out-of-domain intervals; simply `upper-lower` would produce negative counts or include nonexistent lanes.

For the bounded interval example, enumerate valid iterations: with `N=8`, `lower=2`, `upper=6`, only `r=2,3,4,5` contribute. Their contributions are `val+val+val+val`, hence `4*val`. If `upper=20`, only iterations through 7 exist; if `lower=9`, none exist. The min/max/clamp arithmetic implements these cases without running the loop.

### codegen/simplify.py:L113 — Distribute summation over addition

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L113), `pm_reduce_collapse`. Any-length ADD reduction of `x+y` becomes separate reductions over the same explicit axes followed by addition.

**Example:** `sum_r(where(r<3,2,0)+where(r>=5,4,0))` becomes two sums that can each collapse to a count.

**Inferred rationale:** expose independent countable terms.

**Sharp edge:** it can expand the temporary graph and changes floating-point association; the outer collapse helper only accepts a result once all relevant ranges disappear.

### codegen/simplify.py:L116 — Pull a parameter gate out of a sum

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L116), `pm_reduce_collapse`. Matches `sum((PARAM x & y).where(c,0))`; output is `sum(y.where(c,0))*x`.

**Example:** `sum_r(where(enabled & (r<3),2,0)) → enabled * sum_r(where(r<3,2,0)) → enabled*6`.

**Inferred rationale:** separate a launch-invariant boolean gate from a range-dependent condition.

**Sharp edge:** x is restricted to PARAM, rather than any arbitrary boolean expression, because it must not hide loop dependence.

### codegen/simplify.py:L119 — Expose multiplication by a boolean as a selection

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L119), `pm_reduce_collapse`. Matches `x * CAST(gate:bool)` and produces `WHERE(gate,x,0)`.

**Example:** `7*int(r<3) → where(r<3,7,0)`, which the interval-counter recognizes.

**Inferred rationale:** normalize indicator arithmetic into the guarded form consumed by the collapse rules.

**Sharp edge:** the boolean-typed source matters; multiplication by an arbitrary integer is not a condition. Exceptional floating values can distinguish IEEE multiplication by zero from selecting zero, so do not present this as unconditional bit-exact algebra for all floats.

### codegen/simplify.py:L124 — Isolate an addend in an inequality used as equality gating

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L124), `pm_reduce_load_collapse`. `(x+y).or_casted()!=c → x!=(cast(c,y.dtype)-y)` if y and c are range-free.

**Example:** `r+4 != index → r != index-4`, exposing the single potentially selected lane.

**Source rationale:** lift x+y out of a reduction's not-equal test.

**Sharp edge:** the subtraction explicitly casts c to y's dtype; loaded indices and overflow need the follow-up correction in L156, rather than assuming arbitrary fixed-width algebra is safe.

### codegen/simplify.py:L126 — Collapse a one-hot sum into one selected value

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L126), `pm_reduce_load_collapse`. Matches `sum_r(where(idx != r.or_casted(),0,expr))`. Casts idx to the range dtype, builds validity `0<=idx<N`, substitutes a validity-marked idx for r in expr, and wraps the result in an outer zero-default WHERE.

**Example:** `sum_{r<8} where(index!=r,0,B[r]) → where(0<=index<8,B[index.valid(...)],0)`.

**Source rationale:** substitute the range and remove the reduction.

**Sharp edge:** the validity must also reach memory addressing, not just the final value selection; otherwise out-of-bounds loads could still execute. This is how gather-like computations avoid scanning the entire axis.

Take `index=3` and `N=8`: the sum is `0+0+0+B[3]+0+0+0+0`, so a single read suffices. For `index=10`, every term was zero, so the replacement must return zero **without reading B[10]**. That is why there is both a value selection and validity attached to the address.

### codegen/simplify.py:L149 — Attempt complete algebraic reduction collapse

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L149), `pm_reduce_simplify`. Matches ADD REDUCE with zero horizontal axes and any number of explicit ranges. `reduce_collapse` processes ranges, isolates their dependent subgraph, rejects included STORE or nested REDUCE nodes, replaces boundary inputs by bounded PARAMs, runs `pm_reduce_collapse`, and accepts only if the result contains no RANGE; then restores original boundary inputs.

**Example:** `sum_{r<8} where(r<3,a,0)` with range-independent a becomes `3*a`.

**Source rationale:** remove reductions for arange/indexing.

**Sharp edge:** boundary parameterization is the reason `no_range` checks can recognize invariant expressions without copying all their producer subgraphs. A partially simplified loop is rejected by this helper.

### codegen/simplify.py:L154 — Attempt single-range gather reduction collapse

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L154), `pm_load_collapse`. Matches ADD REDUCE with zero horizontal axes and exactly one explicit range. Uses the same extraction/parameterization/complete-elimination machinery as L149, but with `pm_reduce_load_collapse`, which includes the one-hot selection rule.

**Example:** a tensor index encoded as a masked sum over 1024 input entries becomes one guarded indexed load.

**Source rationale:** remove reductions arising from indexing a tensor with another tensor.

**Sharp edge:** exact two-source arity limits this entry point to one explicit range; nested effects/reductions can block it.

### codegen/simplify.py:L156 — Keep adjustment arithmetic off a loaded index

[Source](../../../../tinygrad/tinygrad/codegen/simplify.py#L156), `pm_load_collapse`. Matches `(x:weakint + y) < c` when x contains an INDEX but y and c do not. Rewrites to `x < c-y`.

**Example:** a promoted loaded integer tested as `loaded_index+4<1024` becomes `loaded_index<1020`.

**Source rationale:** math on loaded indices can overflow; the comment says this undoes a rule in the load-collapse machinery.

**Sharp edge:** `no_load` actually tests for INDEX anywhere in the graph, not just Ops.LOAD. The weakint guard marks the index-arithmetic domain; this is not a universal fixed-width arithmetic reassociation.

## GPU execution dimensions

### codegen/gpudims.py:L88 — Replace the DEVICE axis with a launch parameter

[Source](../../../../tinygrad/tinygrad/codegen/gpudims.py#L88), `pm_device_to_var`. Matches RANGE but acts only on AxisType.DEVICE; returns bounded PARAM variable `_device_num` of the range's dtype.

**Example:** `RANGE(4,DEVICE)` becomes `_device_num ∈ [0,3]`, bound differently for each device launch.

**Source rationale:** device selection is not a program axis.

**Sharp edge:** emitting a loop over devices inside one GPU program would not run code on the other devices; launch machinery owns this dimension.

### codegen/gpudims.py:L90 — Remove endings of the now-external device axis

[Source](../../../../tinygrad/tinygrad/codegen/gpudims.py#L90), `pm_device_to_var`. On END, if any trailing source is PARAM named `_device_num`, removes PARAM sources from the ending list.

**Example:** `END(body,r,_device_num) → END(body,r)`.

**Source rationale:** ENDs that closed DEVICE ranges no longer close them.

**Sharp edge:** the trigger checks the specific name, but the filtering removes **all** PARAM trailing sources; that behavior assumes this pass's valid END representation and should not be broadened casually.

### codegen/gpudims.py:L96 — Map logical GPU axes onto launch IDs and choose output writers

[Source](../../../../tinygrad/tinygrad/codegen/gpudims.py#L96), `pm_add_gpudims`. SINK callback declines without kernel metadata, if any SPECIAL already exists, or if there are no GLOBAL/local-like axes. It sorts logical GLOBAL axes and WARP/LOCAL/GROUP_REDUCE axes, chooses legal hardware dimensions under renderer limits, then reconstructs logical indices with flatten/divmod arithmetic. Global dimensions are considered in reverse order; a leading WARP fixes the first local maximum to prevent inappropriate folding. Product limits account for local size when limiting globals.

Example: four logical **local** dimensions `(2,3,4,5)` can be grouped to `(6,4,5)` if hardware limits permit, recovering the first two via `lidx0//3` and `lidx0%3`. This illustrates `get_grouped_dims(reverse=False)`; global mapping reverses the logical dimensions before grouping. For a grouped RMSNorm reduction whose global output index depends only on row, it additionally inserts `local_lane==0` validity on that global store, so 32 lanes do not all write `out[row]`.

**Source rationale:** GPU-like execution indices plus invalidation for local indices absent from global stores.

**Sharp edge:** the mask uses **destination index** dependence, not merely value dependence. Shape grouping/splitting can fail with `cannot limit dim`; prime oversized dimensions cannot always be factored. Serial REDUCE ranges sharing an identifier are left as reductions. This one callback combines launch-layout legalization and race prevention, not just arithmetic simplification.

With local dimensions `(2,3,4,5)`, a worker ID `lidx0=4` decodes to `(4//3,4%3)=(1,1)` in the first two logical axes; the remaining hardware IDs supply the last two. This preserves the original set of logical coordinates while fitting a device's small fixed number of launch dimensions. Writer masking then handles a separate problem: if every local worker computes the same row result, only the selected worker may commit it to the common output address.

## Move invalid-index gates to renderable memory operations

The file calls this a temporary step while removing this index style. Before it, invalidity lives inside coordinates; afterwards LOAD has an alternate value and predicate, while STORE has a predicate. IMAGE needs special two-coordinate rules **first** so both coordinates lose their Invalid branches together.

### codegen/late/gater.py:L11 — Extract a shared IMAGE load gate

[Source](../../../../tinygrad/tinygrad/codegen/late/gater.py#L11), `pm_move_gates_from_index`. Matches a two-coordinate indexed LOAD with identical gates in both `where(g,y,Invalid)` and `where(g,x,Invalid)`. Produces ungated coordinates and `LOAD(address,zero,g)`, using `l.vconst_like(0)` for matching scalar/vector zero.

**Example:** `load(image[g?y:Invalid,g?x:Invalid]) → load(image[y,x],float4(0),g)` for a four-channel pixel.

**Source rationale:** image-index rules must be first.

**Sharp edge:** both gates must be the same matched UOp; unrelated x/y predicates are not implicitly combined here. Removing only the first invalid coordinate would leave an unrenderable second one.

### codegen/late/gater.py:L14 — Extract a shared IMAGE store gate

[Source](../../../../tinygrad/tinygrad/codegen/late/gater.py#L14), `pm_move_gates_from_index`. Same two-coordinate/shared-gate shape, now STORE.

**Example:** `store(image[g?y:Invalid,g?x:Invalid],rgba) → store(image[y,x],rgba,g)`.

**Inferred rationale:** the renderer must predicate the pixel write rather than receive Invalid coordinates.

**Sharp edge:** stores have no alternate data value; a false gate suppresses the memory effect. Replacing invalid writes with a write of zero would corrupt the destination.

### codegen/late/gater.py:L19 — Extract a buffer load's invalid-coordinate gate

[Source](../../../../tinygrad/tinygrad/codegen/late/gater.py#L19), `pm_move_gates_from_index`. Matches LOAD of INDEX or SHRINK whose first coordinate is `where(g,idx,Invalid)`, preserving any later address sources. Produces `LOAD(address_with_idx,zero,g)`.

**Example:** padded RMSNorm `load(B[r<100?row*128+r:Invalid]) → load(B[row*128+r],0,r<100)`.

**Source rationale:** create zero alternate and remove WHERE Invalid.

**Sharp edge:** zero here is a provisional load alternate; surrounding WHERE folding can replace it (L25/L27). Reduction-specific identity handling is a separate earlier concern.

### codegen/late/gater.py:L21 — Extract a buffer store's invalid-coordinate gate

[Source](../../../../tinygrad/tinygrad/codegen/late/gater.py#L21), `pm_move_gates_from_index`. Same address pattern for STORE.

**Example:** `store(out[g?i:Invalid],v) → store(out[i],v,g)`.

**Inferred rationale:** represent invalid-address suppression in the store predicate consumed by backend lowering.

**Sharp edge:** remaining address operands are preserved. It must follow the image-specific pattern because an image has two invalid coordinates to remove together.

### codegen/late/gater.py:L25 — Fold a surrounding WHERE into a load alternate

[Source](../../../../tinygrad/tinygrad/codegen/late/gater.py#L25), `pm_move_gates_from_index`. Matches `where(g, optionally_cast(load(addr,old_alt,g)),a)`, requiring the load's gate be boolean. `move_where_load` installs a as the load's alternate, converted to the load dtype: Invalid becomes vector zero; CONST uses a like-typed constant; an already suitable inner CAST is peeled; otherwise a cast is inserted. The result is cast back to the WHERE dtype.

**Example:** `where(g,cast_f32(load_f16(p,0,g)),3.0) → cast_f32(load_f16(p,3.0,g))`.

**Source rationale:** WHERE after gated load becomes its alternate value.

**Sharp edge:** gate identity is required; conversion of a to the load dtype may affect representability, so this is not a generic select-motion theorem for arbitrary precisions.

### codegen/late/gater.py:L27 — Fold the inverted-gate WHERE arrangement

[Source](../../../../tinygrad/tinygrad/codegen/late/gater.py#L27), `pm_move_gates_from_index`. Matches `where(g,a, optionally_cast(load(addr,old_alt,~g)))`; same callback as L25 retains the load's existing inverted predicate and installs a as its alternate.

**Example:** `where(is_padding,7,load(p,0,~is_padding)) → load(p,7,~is_padding)`.

**Inferred rationale:** handle the symmetric branch arrangement without forcing an extra WHERE.

**Sharp edge:** the callback does not replace `~g` with g; the predicate stays `l.src[2]`, preserving which branch performs the memory access.

## Loop control and register allocation

A graph states dependencies, but emitted code is a sequence with properly nested loops. **Topological ordering** places a node after everything it depends on. That alone does not keep two loop bodies from interleaving incorrectly, so the control-flow rules add ordering constraints before linearization. Register allocation then fits the resulting sequence into finite hardware storage.

### codegen/late/linearizer.py:L84 — Add execution-order edges between loops

[Source](../../../../tinygrad/tinygrad/codegen/late/linearizer.py#L84), `pm_add_control_flow`. Matches RANGE and appends an extra dependency only if `CFGContext.edges` contains that range. Context classifies END relationships as nested, dependent, or independent, groups sibling loops, sorts by sibling dependencies, and chains them; nested loops are also anchored after their enclosing RANGE.

**Example:** two sibling loops writing then consuming a temporary gain `RANGE(second).after(END(first))` in source-edge form.

**Source rationale:** dependent sibling ranges must schedule after their predecessors.

**Sharp edge:** topological order of data alone is insufficient to render noninterleaving loop blocks. The context asserts against an edge creating a cycle; the source contains a TODO referencing an infinite-loop case in shufflenet, not a proof that arbitrary control-flow graphs are supported.

### codegen/late/linearizer.py:L94 — Split multi-range endings into nested ENDs

[Source](../../../../tinygrad/tinygrad/codegen/late/linearizer.py#L94), `pm_split_ends`. Matches END, collects actual ranges from non-bool/non-void closing sources, sorts descending by range argument, and wraps the body in one END per range; retained bool/void backedges form an outer END if present. Example with `r0.arg<r1.arg`: `END(body,r0,r1) → END(END(body,r1),r0)`.

**Source rationale:** split ends before control-flow construction/rendering.

**Sharp edge:** close order defines nesting. Treating bool conditions as ranges would end the wrong loops, so backedges remain separate.

A virtual register is a name like `t2` for a computed value; a physical register is one of the finite hardware slots holding such values. A value is **live** if a future instruction still needs it. A **spill** saves a live value elsewhere so its register can be reused; a **fill** reloads it before its next use. “Two-address” means an instruction overwrites one of its input registers, so allocation must respect that overlap. These definitions explain why this rule needs both next-use information and special loop handling.

### codegen/late/regalloc.py:L115 — Replace virtual registers and insert spill/fill instructions

[Source](../../../../tinygrad/tinygrad/codegen/late/regalloc.py#L115), `pm_regalloc_rewrite`. A single template handles INS, RANGE, END, BUFFER, PARAM, SPECIAL, and the pseudo-op set `{CONST,CAST,BITCAST,NOOP,AFTER,BARRIER,GROUP,STACK}`. Every callback invocation advances the list-position counter, including pseudo-ops; pseudo-ops then return None. For real instructions, it remaps definition tags from virtual registers to assigned physical registers, resolves spilled sources via backend fill UOps, emits scheduled fills before the instruction, and spills newly defined spilled values afterwards. Example under two-register pressure: virtual `t2=add(t0,t1)` becomes physical `r0=add(r0,r1)` when constraints permit, followed by a spill if t2 must later be recovered; a subsequent use inserts a fill from that slot.

**Inferred rationale:** direct ISA output needs physical register names and explicit preservation when demand exceeds the available constrained registers. The context computes live uses in reverse, extends lifetimes across loops, chooses a free/dead register or the one with farthest next use, respects register-class constraints, and handles two-address instructions by allowing only the reused first source to coalesce with the first definition. Loop prologues bring soon-used values into registers; epilogues restore the register assignment expected at loop entry. Backend `assign_spill_slot`, `fill`, and `spill` decide actual storage/instructions.

**Sharp edge:** loop handling is correctness work: a register reassigned in the body must regain the entry value before the next iteration. The source explicitly marks hacks around END uses and RANGE's missing comparison, and TODOs mention using moves instead of needless reloads. Do not infer that all spill/fill operations are plain host-stack loads or that the algorithm models every target instruction constraint automatically. The line rewrite must see exactly the instruction ordering used to build `LinearScanRegallocContext`; its integer position maps would otherwise refer to the wrong uses.

