# Runtime and execution: every pattern rule

Snapshot: `107adc31701df0247dfa45e175984df906a68b53`. These are **source-read, conceptual examples**, not device-tested examples. This chapter covers every outer rule/template in `device.py`, `engine/{jit,realize}.py`, `runtime/ops_{amd,nv,qcom,rdma}.py`, and `runtime/support/{hcq2,usb}.py`. Generated templates enumerate their individual tags below.

The crucial distinction: these PMs often **perform host actions or select device-owned buffers**. `q_rewrite` appends packet bytes; `pm_bufferize` returns a `Buffer`; `pm_exec` launches work and returns timings. They are not all algebraic UOp-to-UOp transformations. `pm_link` actually writes memory. Do not run them against arbitrary examples on a live device just to inspect a match.

Notation: `CALL(body, args...)`, `AFTER(value, dependencies...)`, and `b[i]` abbreviate UOps; examples illustrate the structural transformation or side effect, not an exact Python construction. A match whose helper returns `None` falls through to later rules. Unless a historical reason is explicitly identified as a source comment, “why” below is an inference from the current implementation and its callers, not a claim about the author's original motivation. Source links identify the rule; follow its named helper in the same file for guards hidden outside the pattern.

## Start with the job of a runtime

The [shared first-principles guide](../../first-principles.md) explains graphs and kernels. Once a kernel exists, something still has to allocate its input/output memory, put their addresses in its arguments, request execution, and make later work wait for the result. That is the runtime's job. The **host** is the CPU process issuing requests; the **device** is the accelerator carrying them out. Submission is usually asynchronous: returning from the request does not mean the device has finished using its inputs.

A **queue** is an ordered stream of device commands. A **packet** is a command encoded as binary fields, such as “launch this program at this address.” A **ring** stores queue entries in a fixed-size circular array; producer and consumer positions track which entries are new and which storage can be reused. A **doorbell** is a hardware notification written after commands are ready so the device knows to inspect them. It is not the command itself or proof of completion. A **timeline** is a memory counter used to report progress. For example, queue A runs RMSNorm and publishes 12; queue B waits for at least 12 before running matmul. Commands, publication, and waits must appear in the correct order.

HCQ means **hardware command queue**. Tinygrad describes queue operations and the host code that submits them using UOps too. This lets it reuse graph dependencies, pattern matching, lowering, and compilation for the runtime. The operations are different from tensor arithmetic: matching a placeholder can choose an existing device buffer; matching an instruction can append packet bytes; linking can actually write those bytes to memory. **PM** means pattern matcher. A rule's result therefore need not be another UOp.

Three moments recur below. **Encoding** creates commands, possibly with symbolic addresses. **Linking** supplies concrete allocations/addresses and fills fields fixed for this executable. **Replay** runs it again with current inputs, patching fields that can change. Suppose the first input lives at address `0x1000` and the next at `0x9000`: immutable packet headers can be reused, but the input address cannot be frozen at link time. An address is only a number; the object owning its storage must also stay alive until device work completes. A host-visible address and a GPU-visible address for the same allocation may differ.

UOp notation here is deliberately compact. `PARAM` is a placeholder whose `tag` names its role; `BUFFER` identifies storage; `GETADDR` asks for its address; `LOAD` reads and `STORE` writes. `LINEAR(A,B)` is an ordered schedule, while `SINK` groups work to carry forward. `CALL` invokes a body with arguments. `AFTER(value,dependency)` retains a dependency that must be honored before using the value. `RANGE`/`END` describe a loop; `STACK` packs values together, not a CPU call stack. A **view** selects part of existing storage without allocating a new copy. `ctx` is the context supplied to a matcher, such as a device or a table of buffers. A rule that declines lets the next rule try; its visible pattern can match even when a helper guard rejects it.

Vocabulary used across the entries: **JIT** is just-in-time compilation/capture; **DMA** is direct memory access, a transfer engine moving bytes without a tensor arithmetic kernel. **ABI** is application binary interface, the agreement on argument layout. **LRU** is least-recently-used cache eviction; `nolru` prevents ordinary reuse/eviction of these persistent resources. **MMIO** is memory-mapped input/output, where an apparent memory store controls hardware. **RMSNorm** normalizes a row using its root mean square; its internal math is irrelevant to these launch rules, which must submit any compiled kernel correctly.

## Execution and JIT

### engine/realize.py:L222 — pm_flatten_linear: splice nested schedules

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L222). Match a `LINEAR` with the `LINEAR` early-reject requirement; splice each immediate `LINEAR` child's sources into its parent, preserving sequence.

**Example:** `LINEAR(A, LINEAR(B,C), D) → LINEAR(A,B,C,D)`. The comment explicitly says this flattens nested linears: passes such as copy staging replace one call with several calls, while consumers expect a flat execution list. This is sequence flattening, **not kernel fusion**; B and C still launch separately. Order must survive the splice.

For a Python analogy, this turns `[A,[B,C],D]` into `[A,B,C,D]` while keeping the execution order. The `LINEAR` early-reject check is a quick structural test for a nested sequence before attempting the rule.

### engine/realize.py:L231 — pm_validate: preserve inputs and add a reference call

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L231). Match `CALL(SINK, args...)`, allowing additional arguments. `_validate` allocates CPU shadow UOps for each call argument (one CPU lane per multi-device lane), emits copies into them, then the original call, then a `CUSTOM_FUNCTION("validate")` call carrying shadows followed by original arguments.

**Example:** an in-place RMSNorm kernel becomes `copy x→shadow; RMSNorm(x); validate(shadow,x)`.

Why: a CPU reference needs pre-kernel inputs, especially for overwritten buffers. Appended `pm_flatten_linear` flattens this schedule. Copy placement before the call is correctness-critical; this is intentionally expensive instrumentation, not a scheduling optimization.

“Shadow” means a preserved copy used as the reference input. If the kernel overwrites `x`, running the reference afterward on that overwritten `x` would test the wrong starting data; copying first avoids that mistake.

### engine/realize.py:L235 — pm_beam: fill an unspecified search budget

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L235). Match `CALL(SINK, args...)`; only if `sink.arg.beam == 0`, replace the sink's kernel metadata with `beam=ctx`.

**Example:** caller budget 4 changes an RMSNorm sink's beam 0 to 4, but leaves beam 8 alone.

Why: propagate the selected optimization search setting without overwriting an explicit per-kernel one. It does not itself search or fuse anything; subsequent compilation consumes this metadata. A nonzero existing value is a fall-through guard.

A beam search keeps several promising compilation choices while exploring optimizations. This rule supplies its configured budget; it does not change the tensor values or launch the search at this moment.

### engine/realize.py:L279 — pm_exec: COPY dispatch

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L279). Match `CALL(COPY, args...)`; `exec_copy` resolves parameter slots, iterates device lanes and allocates buffers. It tries, in order: supported same-backend `_transfer`; sufficiently large supported disk transfer (at least 4096 bytes and a disk fd); synchronized host-view assignment when both are host accessible; `_copyout` into a host destination; otherwise `_copyin` from the source's memory view.

**Example:** a supported AMD→AMD peer copy uses `_transfer`, whereas two CPU-visible buffers use a synchronized host copy.

Why: one logical COPY has several transport implementations. Returns an empty timing list; it executes work, not a replacement UOp. Branch order affects transport choice and synchronization.

A disk `fd` is a file descriptor, the operating system’s handle for an open file. “Host accessible” means the CPU can obtain a view of the storage; synchronization is still needed so an earlier device writer has finished before the CPU reads it.

### engine/realize.py:L280 — pm_exec: PROGRAM dispatch, including HCQ

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L280). Match `CALL(PROGRAM, args...)`. `HCQInfo` in `call.arg.aux` selects `exec_hcq`; otherwise use `exec_kernel`.

**Example:** an ordinary compiled RMSNorm launches its device binary; a compiled HCQ schedule launches a host program that submits both RMSNorm and its consumer.

Why: executable programs share a representation although one is a GPU kernel and another drives GPU queues. The HCQ path patches current input addresses, incorporates device runtime variables, and manages profiling/timelines. The ordinary path binds symbolic launch sizes and passes globals in `ProgramInfo.globals` order. Neither branch merges GPU kernels.

### engine/realize.py:L282 — pm_exec: encdec dispatch

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L282). Match a call whose custom-function body has `arg="encdec"`. Resolve/allocate arguments; derive shape from constant body sources and position from the body's first variable; call the output allocator's `_encode_decode` with the first three buffers, remaining buffer list, shape and current position.

**Example:** `encdec(out,a,b,weights..., shape=(...), pos=p)` dispatches the allocator hook at `ctx.var_vals[p]`.

Why: an allocator-specific operation needs an execution hook outside normal compiled kernels. The positional ABI and existence of the first variable are assumptions, not validated by the pattern. Returns `[]` after the action.

The positional ABI means “argument zero has this role, argument one that role.” Matching the name alone cannot establish that a manually constructed call supplied those arguments in the right order.

### engine/realize.py:L283 — pm_exec: graph replay

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L283). Match `CALL(CUSTOM_FUNCTION("graph"), args...)`; get/create the cached device graph runtime, then invoke it with current inputs, variable values and the wait flag.

**Example:** a captured three-kernel sequence replays through one graph runtime.

Why: amortize host launch overhead across an already captured schedule. Its return is a one-element timing list. Graph replay is not fusion into one GPU kernel, and its cached executable must remain associated with the graph UOp and correct input binding.

Replay saves repeated Python/driver setup by remembering how to launch a sequence. The device still executes the captured kernels and their dependencies each time; the saved work is primarily submission overhead.

### engine/realize.py:L284 — pm_exec: numerical validation

[Source](../../../../tinygrad/tinygrad/engine/realize.py#L284). Match `CALL(CUSTOM_FUNCTION("validate"), args...)`. Split resolved buffers into shadow and device halves, compile/run the saved sink with the CPU renderer, then compare each output in `ProgramInfo.outs` with NumPy `assert_allclose(rtol=1e-3, atol=1e-3)`.

**Example:** the shadow RMSNorm result is compared to the already computed GPU output.

Why: verify kernel transformations against another backend. Only designated outputs are compared; these fixed tolerances are not a universal numerical specification. Returns no timings and can raise an assertion.

### engine/jit.py:L67 — empty matcher: captured-linear visualization

[Source](../../../../tinygrad/tinygrad/engine/jit.py#L67). `PatternMatcher([])` contains **zero rules**. Under `VIZ`, rewriting records the captured schedule for the viewer.

**Example:** two captured calls remain two calls.

Why: reuse rewrite instrumentation without a transformation. Do not count this as an optimization or infer fusion from the visualization pass name.

### engine/jit.py:L74 — empty matcher: graphed-linear visualization

[Source](../../../../tinygrad/tinygrad/engine/jit.py#L74). Another **zero-rule** matcher records the schedule after parameterization, memory planning, compilation and optional graph batching.

**Example:** a graph wrapper created earlier is displayed unchanged.

Why: expose the post-JIT boundary. This matcher is not what created the graph.

## Shared device buffer binding

### device.py:L433 — pm_bufferize: timeline

[Source](../../../../tinygrad/tinygrad/device.py#L433). Match `PARAM(tag="timeline")`; return `ctx.timeline`, a device-owned buffer.

**Example:** a symbolic completion timeline binds to the same device timeline used by other schedules.

Why: coordination must observe shared state, not allocate a fresh counter per schedule. This is a Buffer return, not a UOp rewrite; device ownership/lifetime are part of its meaning.

If producer and consumer accidentally received different counters, the consumer could wait forever even after the producer completed. Returning the existing timeline is therefore a coordination requirement, not just an allocation optimization.

### device.py:L434 — pm_bufferize: program

[Source](../../../../tinygrad/tinygrad/device.py#L434). Match `PARAM(tag="program")`; cache a `Buffer(ctx.device, b.max_numel(), b.dtype)` keyed by the placeholder, with `cpu_access=True, nolru=True`.

**Example:** repeated links of the same code placeholder get the same program storage.

Why: code addresses must stay stable and code storage must survive ordinary buffer eviction. The buffer is not uploaded by this matcher; link-time blob stores do that. Backend rules prepended before this one can override allocation.

A placeholder is the symbolic identity used during compilation. Reusing its allocation keeps embedded code addresses meaningful on later replays; the bytes of the program are filled in during a later linking step.

### device.py:L436 — pm_bufferize: cfunc tuple tag

[Source](../../../../tinygrad/tinygrad/device.py#L436). Match any `PARAM`, but act only for a tuple tag whose first element is `"cfunc"`; return `cfunc_buf(*b.tag[1:])`.

**Example:** a placeholder tagged for a host library function resolves its callable-address storage.

Why: generated runtime code needs callable host addresses through the same linking mechanism as other buffers. Ordinary string tags fall through. The tuple is an internal ABI, not an arbitrary user string to resolve.

A host library function has a process-local callable address. The tuple carries the information needed to resolve it; treating that tuple as ordinary tensor contents would not make the function callable.

## AMD runtime matchers and chip-dependent helpers

AMD has separate compute and copy command paths. AQL (Architected Queuing Language) and PM4 are different command formats; SDMA is the dedicated DMA copy path. An XCC is a compute complex within a device, so a multi-XCC device may need resources sized across several such complexes. A **wave** is a group of GPU threads executing together. **Scratch** backs private per-thread storage when it cannot all remain in registers. **IP** below means a hardware engine/version, not an Internet address.

These entries are host-side queue/storage rules. Chip-specific instruction-selection PMs live in the renderer chapter. Here, chip differences are often **inside helpers**, rather than separate visible PM tuples: `is_aql` defaults from multi-XCC topology; scratch alignment differs for gfx9; queue state-save sizes depend on targets. Do not look only for `UPat` to find AMD specialization.

### runtime/ops_amd.py:L841 — pm_encode: AMD compute submit

[Source](../../../../tinygrad/tinygrad/runtime/ops_amd.py#L841). Match `CUSTOM_FUNCTION(arg="submit_amd_compute")`; build the selected queue and run `encode_submit`. `amd_compute_queue` selects `AMDComputeAQLQueue` when the submitting device's `is_aql` is true, otherwise `AMDComputeQueue`.

**Example:** the same logical kernel dispatch becomes AQL packets on an AQL-configured device and PM4 compute commands otherwise.

Why: a common scheduled representation can target different AMD submission protocols. `AMD_AQL` overrides the default based on `xccs > 1`; this is not a universal “gfx9 versus gfx11” match. The returned UOp graph includes command-buffer storage/patching and ordered submission actions, not just packet bytes.

The scheduled request is “submit this compute work.” The queue helper translates it into the vocabulary understood by the selected AMD submission path; choosing a packet format does not change the arithmetic instructions inside the compiled kernel.

### runtime/ops_amd.py:L842 — pm_encode: AMD copy submit

[Source](../../../../tinygrad/tinygrad/runtime/ops_amd.py#L842). Match `CUSTOM_FUNCTION(arg="submit_amd_copy")`; encode through `AMDSDMAQueue`.

**Example:** a 1 MiB device copy with waits/signals becomes an SDMA command stream plus its ring submission graph.

Why: DMA engines have different packet formats and scheduling from compute engines. Queue/helper code selects IP-specific packet definitions and copy-size limits. A logical copy may already have become a compute kernel during staging if no copy queue exists; this rule does not decide that fallback.

For a copy, the engine mainly needs source address, destination address, byte count, and dependency commands. Those fields differ from a compute launch, which needs a program and its execution dimensions.

### runtime/ops_amd.py:L888 — pm_bufferize: scratch

[Source](../../../../tinygrad/tinygrad/runtime/ops_amd.py#L888). Match `PARAM(tag="scratch")`; pass `b.max_numel()` as the requested private-segment size to `scratch_buffer`. The helper takes the maximum of request, 128 and the class-wide high-water mark; grow backing storage if necessary.

**Example:** a kernel requesting 512 bytes of private storage per thread raises the backing allocation requirement from a previous 128-byte requirement.

Why: AMD scratch is a shared backing resource sized by per-thread usage and available wave slots, not a `max_numel`-byte ordinary tensor. gfx9 uses 1024-byte wave alignment versus 256 elsewhere; multi-XCC size multiplies accordingly. Existing AQL descriptors are updated when scratch grows. The class-wide maximum can make one kernel/device affect later allocation sizes.

A 512-byte per-thread requirement does not mean a single 512-byte allocation is enough: many threads can need private storage simultaneously. Alignment rounds storage placement to hardware-required boundaries, and the high-water mark remembers the largest requirement seen so far.

### runtime/ops_amd.py:L889 — pm_bufferize: AMD program allocation/profiling

[Source](../../../../tinygrad/tinygrad/runtime/ops_amd.py#L889). Match `PARAM(tag="program")`; `program_buffer` allocates once per placeholder with CPU access and no LRU eviction, ensures allocation, and records a `ProfileProgramEvent` on first allocation when profiling.

**Example:** linking an RMSNorm binary yields an allocated code address, with a profiler mapping from that address to the program.

Why: AMD profiling needs actual loaded-code addresses, so the shared program allocator is overridden. No second event is emitted for an already cached placeholder; upload still happens through patches.

### runtime/ops_amd.py:L890 — pm_bufferize: queue-owned resources

[Source](../../../../tinygrad/tinygrad/runtime/ops_amd.py#L890). Match any `PARAM`; `queue_buffer` only accepts string tags beginning `ring_`, `write_ptr_`, `doorbell_`, or `put_value_`. Split from the right into resource, queue kind and index; use `compute_queue` for kind `compute`, otherwise `sdma_queue(int(idx))`; return the named resource.

**Example:** `write_ptr_compute_0` selects the compute queue's write pointer, while `ring_copy_1` selects copy queue 1's ring.

Why: command submission must modify driver/hardware-owned queue state. Unrecognized tags fall through to shared rules; malformed recognized tags can fail. Queue creation may occur lazily, so matching is not side-effect-free.

The ring holds commands; the write pointer publishes how far they extend; the doorbell notifies hardware; the software `put_value` tracks progress across submissions. All four refer to the same queue, so accidentally binding one resource from a different queue breaks the protocol.

### runtime/ops_amd.py:L904 — generated pm_bufferize: profiling resources

[Source](../../../../tinygrad/tinygrad/runtime/ops_amd.py#L904). Only installed when `PROFILE > 0` and either `PMC > 0` or `SQTT > 0`. Four exact-tag rules return `getattr(ctx,n)`; default argument `n=n` captures each tag separately.

- `prof_log`: binds the shared slot/log buffer. **Example:** a schedule's `prof_log` placeholder resolves to the device's `1 + prof_slots` uint64 entries, not a new log.
- `pmc_buf`: binds counter-sample storage sized from the counter schedule and number of slots. **Example:** writes for sample slot 2 land in the persistent PMC buffer.
- `sqtt_buf`: binds trace storage across windows, slots and shader engines. **Example:** a trace for shader engine 1 resolves into the configured SQTT allocation.
- `sqtt_wptrs`: binds per-slot/per-engine uint32 trace write pointers. **Example:** the profiler reads the stored pointer for the trace window it will decode.

Why: producer submissions and later profiler reads must share these exact resources. Some properties allocate lazily; asking for a resource without the corresponding setup is not safe. These rules are prepended ahead of generic binding. The source's explicit profiling-overhead comment explains why SQTT is off by default; it does not prove a separate historical rationale for each tag.

PMC here refers to performance-monitor counters; SQTT is shader-thread tracing, which records shader execution activity. A counter sample is a small numerical measurement, while a trace can be a much larger event stream, explaining the separate buffers and write pointers.

## NVIDIA and Qualcomm queue binding

### runtime/ops_nv.py:L100 — q_rewrite: raw NV packet words

[Source](../../../../tinygrad/tinygrad/runtime/ops_nv.py#L100). Added after `HWQueue.q_rewrite`; match `INS(arg=("nv", void))`, then call `ctx.q(*u.src)`.

**Example:** an already assembled NV method header plus payload words are appended verbatim to the queue stream.

Why: carry device-specific packets through a schedule that otherwise uses portable wait/copy/barrier operations. `q` embeds constants and records symbolic words as patches; this dispatch does not validate a packet's method semantics. It appends bytes and returns a byte offset, not a replacement graph node.

A method header identifies the device command and payload layout. “Verbatim” means this rule serializes words already chosen elsewhere; it does not infer a valid launch merely from their being integers.

### runtime/ops_nv.py:L561 — pm_encode: NV compute

[Source](../../../../tinygrad/tinygrad/runtime/ops_nv.py#L561). Match custom function `submit_nv_compute`; instantiate `NVComputeQueue` and `encode_submit`.

**Example:** a kernel CALL in the submitted LINEAR is translated through compute-queue launch encoding into command-buffer bytes and submission UOps.

Why: isolate compute packet/launch-descriptor handling behind the shared scheduler. Its wait and signaling instructions remain ordered with the launch; do not treat the result as a fused kernel.

### runtime/ops_nv.py:L562 — pm_encode: NV copy

[Source](../../../../tinygrad/tinygrad/runtime/ops_nv.py#L562). Match `submit_nv_copy`; use `NVCopyQueue`.

**Example:** a peer copy surrounded by dependency signals becomes a copy-engine stream.

Why: select engine-specific commands using the submit tag. It assumes scheduling picked a supported queue; changing the tag alone does not make an arbitrary compute call legal on a copy engine.

### runtime/ops_nv.py:L563 — pm_encode: NV raw queue

[Source](../../../../tinygrad/tinygrad/runtime/ops_nv.py#L563). Match `submit_nv_raw`; use the base `NVQueue`.

**Example:** a LINEAR containing raw `INS("nv")` initialization/control packets is serialized without choosing compute/copy-specific dispatch logic.

Why: some queue commands are already in device packet form. Preserve packet ordering and symbolic address patches; this is not an escape hatch for arbitrary bytes to bypass queue lifetime management.

### runtime/ops_nv.py:L657 — generated pm_bufferize: GPFIFO resources

[Source](../../../../tinygrad/tinygrad/runtime/ops_nv.py#L657). At FIFO creation, prepend one `PARAM(tag=to_name(n,name))` rule per resource. The closure captures the **specific FIFO's Buffer** as `b=getattr(fifo,n)`.

- `ring`: GPU FIFO entry array. **Example:** a compute-ring placeholder binds to its entries, not the copy FIFO's entries.
- `gpput`: mapped write-index word. **Example:** publishing entry 7 updates the FIFO's own GPPut location.
- `doorbell`: CPU buffer pointing at MMIO offset `0x90`. **Example:** the final host store rings this device's submission doorbell.
- `put_value`: host uint64 software producer counter, initially zero. **Example:** the next replay resumes after the last submitted FIFO index.

Why: placeholders must link to state installed during queue creation. Names qualify the queue; a generic allocation would silently disconnect submissions from hardware. Doorbell storage is an external pointer, not regular RAM. Capturing the loop value prevents all generated rules from returning the last resource.

GPFIFO is NVIDIA’s GPU command FIFO (first-in, first-out queue). Publishing a new producer index and notifying the doorbell advertises already prepared entries. MMIO stores can have device effects, unlike writes into an ordinary temporary Python byte array.

### runtime/ops_qcom.py:L307 — pm_encode: QCOM compute

[Source](../../../../tinygrad/tinygrad/runtime/ops_qcom.py#L307). Match `submit_qcom_compute`; encode using `QCOMComputeQueue`.

**Example:** a scheduled Adreno kernel launch becomes a command buffer and its submission UOps.

Why: retain a common HCQ representation while emitting Qualcomm packets/host calls. This is separate from IMAGE arithmetic/lowering rules. The current device constructor rejects chip IDs at or above `(7,3)`; this matcher alone is not evidence of support for later Adreno chips.

### runtime/ops_qcom.py:L341 — pm_bufferize: private stack

[Source](../../../../tinygrad/tinygrad/runtime/ops_qcom.py#L341). Match `PARAM(tag="stack")`; `_ensure_stack_size(b.max_numel())` allocates/grows the device's uint8 private-memory stack. If an existing stack is too small, synchronize before replacing it.

**Example:** a later program requiring 2 MiB expands a previously 1 MiB stack.

Why: one reusable stack serves programs with different private-memory needs; explicit synchronization prevents freeing storage still used by earlier work. Requests within capacity reuse storage.

Even though Python has moved on to another call, a previous kernel may still read the old private stack. Waiting for completion before replacing it prevents that kernel from accessing freed or reassigned storage.

### runtime/ops_qcom.py:L342 — pm_bufferize: dummy buffer

[Source](../../../../tinygrad/tinygrad/runtime/ops_qcom.py#L342). Match `PARAM(tag="dummy")`; return `ctx.dummy`.

**Example:** `QCOMComputeQueue._cache_flush(write_back=True)` emits `CP_EVENT_WRITE/CACHE_FLUSH_TS` targeting this 0x1000-byte buffer.

Why is explicit in the helper: dirty cache write-back needs a target, and `dummy` is the device's cache-flush target. The dummy absorbs the command's write instead of clobbering a tensor. Its stable device-owned identity matters; this is cache-protocol plumbing, not an IMAGE arithmetic rule.

A cache holds copies of memory near the processor; dirty data is a copy changed there but not yet written back. This dummy buffer provides a safe location for the flush command’s accompanying write.

### runtime/ops_qcom.py:L343 — pm_bufferize: border colors

[Source](../../../../tinygrad/tinygrad/runtime/ops_qcom.py#L343). Match `PARAM(tag="border_color")`; return `ctx.border_color`.

**Example:** a texture/image state's border-color-table address links to the device-owned zero-filled table.

Why is explicit in the resource helper: samplers clamp to a black border, so this 0x1000-byte table is initialized to zeros. This connects runtime image state to out-of-bounds sampling, but does not itself fix image coordinate calculations; those belong to image lowering and descriptor setup. Replacing it with uninitialized memory would lose the zero-border guarantee.

A sampler reads an image using configured addressing rules. With a black border, an out-of-range sample obtains zero components from this table; the table is part of runtime image state, not a tensor of training data.

## RDMA

RDMA means remote direct memory access: transfer data between machines through a network interface controller (**NIC**). A queue pair (**QP**) holds send and receive state. A work queue entry (**WQE**) describes requested work, while a completion queue (**CQ**) reports completed work. Packet sequence numbers and message sequence numbers (**MSN**) distinguish new traffic from earlier traffic. **MTU**, maximum transmission unit, limits bytes per network packet; one tensor chunk may need several packets. Ring **epoch** bits distinguish a newly reused entry from stale data left there on an earlier trip around the ring.

### runtime/ops_rdma.py:L78 — generated pm_bufferize: queue-pair resources

[Source](../../../../tinygrad/tinygrad/runtime/ops_rdma.py#L78). During `rdma_qp(pair)`, install exact-tag rules `PARAM(to_name("rdma", *pair, n)) → captured Buffer` on each NIC. One queue pair is cached per GPU pair. The templates expand to eight resources:

- `sq`: send work ring. **Example:** outbound chunk WQE 0 writes to this QP's send ring.
- `rq`: receive work ring. **Example:** the destination posts its receive buffer through this QP's receive ring.
- `scq`: send completion ring. **Example:** sending waits on entry 0's completion in this ring.
- `rcq`: receive completion ring. **Example:** receiving waits for its own receive completion before exposing data.
- `sq_seq`: persistent uint64 send sequence. **Example:** a second batch starts at send sequence 8 rather than restarting at zero.
- `rq_seq`: persistent uint64 receive sequence. **Example:** receive ring wrap uses the accumulated receive count.
- `psn`: persistent uint64 packet sequence number. **Example:** a chunk spanning several MTUs advances the next packet sequence accordingly.
- `db`: NIC doorbell mapping. **Example:** posting work writes the NIC-owned doorbell, not a tensor buffer.

Why: both peers need agreed queue-pair state; sequence counters outlive one compiled schedule. The closure captures `b=b` to avoid Python late binding. Pair-qualified tags prevent two GPU pairs from sharing counters/rings accidentally. Creating these rules entails NIC queue setup and connection: it is emphatically not a harmless import-time pattern experiment.

In Python, a closure normally looks up a loop variable when called, after the loop may have changed it. The default argument `b=b` freezes each resource for that generated rule, so the send-ring rule keeps returning the send ring.

### runtime/ops_rdma.py:L162 — pm_rdma_encode: lower RDMA copies inside a submit

[Source](../../../../tinygrad/tinygrad/runtime/ops_rdma.py#L162). Match any `CUSTOM_FUNCTION` with exactly one `LINEAR` source. `rdma_submit` returns `None` if no child is an RDMA operation. Otherwise group matching positions by queue, call `rdma_copies`, and substitute generated instruction sequences at the original positions.

**Example:** `submit(LINEAR(wait, RDMA_COPY, signal))` becomes `submit(LINEAR(wait, WQE writes, doorbell, completion wait, CQ acknowledgment, [receive barrier], signal))`.

Why: the GPU copy queue can post NIC work directly using the same instruction vocabulary as normal queue commands. Receive-side barriers invalidate GPU caches; sends also update packet-sequence/MSN state. The helper asserts a batch fits work/completion rings. Position preservation and ring epoch bits prevent stale completions being mistaken for current work. This runs before device submit encoding so the replacement instructions are included in the encoded stream.

A receive completion says the NIC has finished its transfer; it does not by itself guarantee an earlier GPU cache entry was refreshed. The barrier makes the receiving GPU’s subsequent reads observe the newly transferred memory through the backend’s cache protocol.

## HCQ preparation and queue vocabulary

### runtime/support/hcq2.py:L119 — pm_replace_buffers: bindable schedule inputs

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L119). Match `BUFFER`. In context `(use_rt, bufs, slots)`, assign/reuse a stable slot, append a newly seen buffer to `bufs`, and return a matching `PARAM`; when `use_rt` is false tag it `"lt_input"`.

**Example:** two calls using the same weight buffer both reference parameter slot 1.

Why: cache a schedule independently of its eager input-buffer UOps. Runtime parameters are later addressed via an input table; link-time inputs bind actual buffers and inhibit the corresponding linked-schedule cache. Slot identity and the side effect on `bufs` must agree; duplicating a slot would change which tensor a kernel reads.

Think of turning a function that mentions one particular array into `run(input0,input1)`. Stable parameter slots let the compiled schedule refer to the same argument positions on each replay even when the actual arrays change.

### runtime/support/hcq2.py:L129 — pm_unwrap_multi: one call per device lane

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L129). Match `CALL`. Fall through if `get_enqueue_devs` is unavailable or the largest argument device-tuple length is one. Otherwise produce a LINEAR of per-lane calls, selecting each non-bound-variable argument's lane and adding `_device_num.bind(i)`; preserve already-bound variables.

**Example:** a two-GPU RMSNorm call becomes calls for lanes 0 and 1 with the corresponding shard arguments.

Why: queue scheduling needs concrete device submissions. The device number is a bound parameter, not a new tensor dimension; flattening the LINEAR later does not fuse the calls.

“Lane” here means one device’s share of a multi-device argument, not a vector register lane. If two GPUs each own half the rows, the two resulting calls receive their respective halves.

### runtime/support/hcq2.py:L172 — pm_insert_copy_staging: split cross-node RDMA

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L172). Match `CALL(COPY,dst,src,...)`. Require both devices to have interfaces, different `peer_group`s, and an RDMA NIC on both nodes. Replace with a LINEAR of send/receive copies via NIC placeholders tagged by the remote peer.

**Example:** copy from GPU A on node 0 to GPU B on node 1 becomes A→B's NIC wire, then A's NIC wire→B.

Why: a cross-node transfer needs paired NIC operations rather than a direct GPU pointer copy. This rule precedes ordinary staging, so reachable NIC routes are selected before host fallback. The generated wire shapes/dtypes come from the source, and each placeholder identifies the far GPU.

A peer group describes devices that can use the direct peer-access route. Across machines, a source GPU address is not directly dereferenceable by the remote GPU; paired send/receive operations provide the transport instead.

### runtime/support/hcq2.py:L173 — pm_insert_copy_staging: inaccessible buffers or missing copy queue

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L173). Same COPY shape; decline RDMA endpoints and calls without an enqueue device. Attempt to map both resolved buffers on that device. On `RuntimeError`/`OSError`, map a cached host staging buffer and emit chunked source→stage→destination copies, alternating two slots. Normal staging size is 128 MiB (4 MiB for mock interfaces), split in half. If both buffers map and a copy queue exists, return `None`; if no copy queue exists, compile a bytewise copy kernel instead.

**Example:** a 150 MiB inaccessible transfer becomes 64 MiB, 64 MiB and 22 MiB staged pairs; an accessible transfer with SDMA unavailable becomes a GPU copy kernel.

Why: retain COPY semantics despite connectivity/engine limitations. Alternating slot reuse depends on schedule dependencies; this rule does not imply asynchronous copies may overwrite a slot before its reader finishes.

With two staging slots, chunk 3 reuses slot 1. Its source-to-stage copy must wait until chunk 1’s stage-to-destination copy has consumed that slot. Alternation alone would not prevent overwriting data still in flight.

### runtime/support/hcq2.py:L321 — HWQueue.q_rewrite: executable program

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L321). Match `CALL(PROGRAM,args...)`; call `ctx.exec(call,prg)`.

**Example:** an RMSNorm PROGRAM appends the queue's dispatch packet with patched buffer addresses and launch dimensions.

Why: queues decide how a compiled program is launched. A copy-only queue need not implement `exec`; dispatch support comes from the selected subclass, not the structural match alone. This is an encoder action; ignore the temptation to read it as `CALL → another kernel`.

### runtime/support/hcq2.py:L322 — HWQueue.q_rewrite: copy

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L322). Match `CALL(COPY,args...)`; invoke `ctx.copy(call)`.

**Example:** `COPY(dst,src,4096 bytes)` appends the subclass's DMA packets.

Why: schedule-level copies share a representation across engines. The helper handles hardware transfer sizes/address formats; the pattern does not prove that arbitrary devices can access either buffer. Prep passes establish that first.

### runtime/support/hcq2.py:L323 — HWQueue.q_rewrite: memory barrier

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L323). Match `INS(arg=("barrier",void))`; call `ctx.memory_barrier()`.

**Example:** an RDMA receive inserts this before consumers so a compute queue's implementation can invalidate relevant caches.

Why: ordering a command does not necessarily make cached memory fresh. The base implementation is explicitly a no-op because a copy queue has nothing to flush; therefore do not describe every barrier UOp as a global GPU cache flush.

A wait answers “has the producer reached this point?” A cache barrier answers “will my next read see the right memory contents?” Those are related but different requirements, which is why both operations appear in queue schedules.

### runtime/support/hcq2.py:L324 — HWQueue.q_rewrite: timeline wait

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L324). Match exactly two-source `INS(("wait",void),dst,val)`; call `ctx.wait(dst,val)` with the subclass's default comparison.

**Example:** wait for a producer timeline to reach the needed value before launching the consumer.

Why: dependencies spanning queues need hardware waits. Do not substitute equality: monotonic timelines may advance beyond a target. The exact packet comparison is supplied by each queue implementation.

For a monotonic counter, observing 13 satisfies a wait for progress 12: the producer has already passed the target. Waiting for equality to 12 could miss that moment and stall forever.

### runtime/support/hcq2.py:L325 — HWQueue.q_rewrite: equality wait

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L325). Match exactly two-source `INS(("wait_eq",void),dst,val)`; call `ctx.wait(dst,val,eq=True)`.

**Example:** USB SRAM half readiness waits for the exact chunk sentinel; an RDMA completion waits for the expected epoch bits.

Why: flags/epochs are identities, not monotonic progress values. Using the default timeline comparison can accept stale or unrelated flags. The source dtype and queue helper determine the actual memory operand width. This shared pattern is not a promise that every queue accepts equality waits: in this snapshot the AMD SDMA helper takes `eq`, while several other queue `wait` signatures do not. Scheduling must place these instructions on a compatible queue.

For a slot marked with a chunk identifier, seeing 13 while expecting 12 is not automatically success: it names a different chunk. This is why exact-identity flags use a separate wait form.

### runtime/support/hcq2.py:L326 — HWQueue.q_rewrite: timestamp

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L326). Match one-source `INS(("timestamp",void),dst)`; `ctx.timestamp(dst)` emits timestamp capture.

**Example:** timestamps surrounding RMSNorm write into two profiling slots.

Why: GPU execution time must come from ordered device events rather than only Python wall time. Hardware tick units are device-specific; this rule neither converts them to seconds nor synchronizes the CPU reader.

If Python takes 20 microseconds to submit work and the GPU spends 5 microseconds executing it, a host stopwatch mixes those costs. Device timestamps placed before and after the kernel measure the ordered device interval.

### runtime/support/hcq2.py:L327 — HWQueue.q_rewrite: signal store

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L327). Match exactly two-source `INS(("store",void),dst,val)`; invoke `ctx.signal(dst,val)`.

**Example:** publish timeline value 12 after the producer's kernel packets.

Why: queue progress needs an externally visible signal. This is a queue instruction, distinct from ordinary UOp `STORE` used by generated host code. The queue's signal method supplies completion/memory semantics; reordering before the producer would violate the schedule.

A signal is data written for another observer to check. Publishing 12 too early would let a consumer read an output while its producer is still computing it, so the signal’s placement is part of correctness.

### runtime/support/hcq2.py:L328 — HWQueue.q_rewrite: arbitrary write words

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L328). Match `INS(arg=("write",void))` and forward every source to `ctx.write`.

**Example:** RDMA lowering emits `write(WQE_address,header_words...,payload_address,key,size)`.

Why: queue engines can populate structured memory without launching a GPU kernel. Operand layout is a helper ABI; unlike the signal rule it allows multiple payload words. Encoders must preserve symbolic patches and address width.

## HCQ encoding and address/ordering transforms

### runtime/support/hcq2.py:L377 — pm_hcq_encode: replay fence

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L377). Match `CUSTOM_FUNCTION(arg="hcq_fence")`. Split sources into one previous-slot view per device and remaining signals. For each device, link-zero the slots, spin until its timeline reaches the prior target, bump the next timeline value, and store it in the slot; then zero/re-arm signals in sequence.

**Example:** replay N+1 waits for replay N's slot completion before reusing command storage.

Why is explicit in the helper comment: prevent the previous schedule colliding with this one. The code contains a `TODO: timeout?`; this is not a bounded host wait. Timeline and signal reset dependencies must remain ordered.

A fence is a completion boundary controlling reuse. If replay N still reads the command bytes, replay N+1 cannot safely overwrite those bytes with new arguments; the stored prior timeline target tells the host when reuse is allowed.

### runtime/support/hcq2.py:L380 — pm_hcq_encode: rechain lowered stores

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L380). Match `AFTER(root,deps...)` where `root.dtype` is void. Replace each STORE buffer in `root`'s topology with that buffer `.after(*deps)`, walking the substitution.

**Example:** `AFTER(block_that_writes_ring, previous_submit)` transfers `previous_submit` into the actual stores' buffer dependencies.

Why is explicit: after blocks lower, preserve original store order. Merely retaining a dependency on a now-replaced wrapper can lose ordering in the resulting graph. This is a graph dependency repair, not an arithmetic identity for arbitrary AFTER nodes.

The original block boundary may disappear during lowering. Moving the dependency onto each affected store makes the ordering survive that disappearance: the actual memory writes still wait for the prerequisite.

### runtime/support/hcq2.py:L408 — pm_patches: input GETADDR becomes runtime table load

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L408). First tuple on this line. Match `GETADDR`; act only if `unwrap_lane(g.src[0])[0]` is an untagged PARAM. Determine view base/offset, assign or reuse a slot keyed by `(base, first_requested_device, off)`, and replace the address with `ctx.table[slot].load()`.

**Example:** `GETADDR(input0[16:32], AMD:0)` becomes a table load whose replay value is the current input0 address plus that view's byte offset.

Why: compiled schedules can replay with different tensor allocations. Different device mappings or view offsets require distinct entries; the GPU address is not necessarily the host pointer.

The two rules at this source line serve opposite sides of replay: input addresses stay dynamic, while provably fixed stores can move to one-time linking. The decisive question is whether the value can change between calls, not whether the expression happens to look simple.

### runtime/support/hcq2.py:L408 — pm_patches: hoist link-time stores out of AFTER

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L408). Second tuple on this line. Match any `AFTER`; partition its dependency sources into STOREs satisfying `_is_link_patch` and the rest. If any qualify, append them to `ctx.lt_patches` and return the original value AFTER only the remaining dependencies.

**Example:** fixed binary command bytes move to link-time initialization, while a word depending on a runtime input-address load remains a runtime store.

Why: avoid repatching immutable command fields on every replay. `_is_link_patch` rejects loads, AFTERs, variables, untagged PARAMs and register buffers, and recurses through expressions; tagged placeholders and non-input GETADDRs can qualify. Hoisting a runtime word would freeze a stale address or loop-dependent value.

The two rules at this source line serve opposite sides of replay: input addresses stay dynamic, while provably fixed stores can move to one-time linking. The decisive question is whether the value can change between calls, not whether the expression happens to look simple.

### runtime/support/hcq2.py:L450 — pm_views: compose nested SHRINK

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L450). Match SHRINK of SHRINK, allowing additional movement-op sources; compose each axis's start/length metadata into a single shrink of the original source.

**Example:** `b[8:24][3:7] → b[11:15]`.

Why: queue buffers are repeatedly sliced into packed regions; canonical views make byte offsets resolvable later. Source uses `marg` as `(start,length)` but passes `(start,end)` to `.shrink`; confusing those conventions silently changes patch locations. No data is copied.

A slice of a slice still refers to the same allocation. Starting at element 8 and then advancing another 3 reaches original element 11; composing the offsets gives the linker one address calculation.

### runtime/support/hcq2.py:L453 — pm_views: bitcast a storage view

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L453). Match BITCAST of SHRINK of a PARAM/BUFFER, optionally AFTER-wrapped. Require a one-dimensional view and byte alignment of its start, length and full storage size to the target item size. Return bitcast of the storage followed by a rescaled shrink.

**Example:** `uint8_buffer[8:24].bitcast(uint32) → uint8_buffer.bitcast(uint32)[2:6]`.

Why is explicit: allow `pm_mops` to fold the view into the index. `uint8_buffer[1:5].bitcast(uint32)` declines because the start is unaligned. Moving a cast without these guards can change layout or create an invalid typed view.

A uint32 occupies four bytes, so bytes 8 through 23 correspond to uint32 elements 2 through 5. The alignment guards ensure the view begins and ends on whole uint32 elements.

### runtime/support/hcq2.py:L457 — pm_renumber: unique loop IDs

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L457). Match RANGE; replace only the first element of `u.arg` with `next(ctx)`, preserving remaining axis metadata.

**Example:** loops built independently with ID 0 become IDs 0 and 1 after combining the schedule.

Why: lower_call merges fragments whose local numbering can collide. This changes identifiers, not trip counts; stable references are preserved by graph rewriting.

### runtime/support/hcq2.py:L458 — pm_renumber: unique register-buffer slots

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L458). Match BUFFER; only `AddrSpace.REG` receives a new `arg.slot` from the same counter.

**Example:** two local scratch temporaries with slot 0 become separate slots.

Why: merged host-runtime code needs distinct register-local storage identifiers. Global buffers fall through; renumbering them would change actual storage identity. Sharing the counter with ranges avoids collisions in the combined naming space.

These slot numbers name compiler temporaries. They are not physical device addresses or permission to combine allocations; giving two independent temporaries the same slot would falsely make them appear to be the same storage.

### runtime/support/hcq2.py:L502 — pm_encode: lower a whole HCQ call

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L502). Match `CALL(SINK,args...)`; `lower_call` requires `HCQInfo` metadata and `nargs == 0`, declining ordinary kernels and already lowered HCQ calls. Compose RDMA, device submit and fence encoders with address patching; apply device lowering (USB when present); resize the address table; combine compatible placeholders into aligned storage views; assign call parameters and variable slots; renumber loops/registers; attach link-time patches and updated `HCQInfo`.

**Example:** a two-kernel AMD batch becomes one host-runtime SINK that patches arguments, submits streams and manages dependencies, still dispatching two GPU kernels.

Why: make the entire submission schedule compilable by the ordinary compiler. Alignment, volatile flags and tags control which resources may share backing storage. `nargs` is the guard against encoding twice.

The result is a CPU-side program for submitting device work. It can be compiled using ordinary arithmetic, loads, stores, and loops because packet preparation and address patching are themselves computations over memory.

### runtime/support/hcq2.py:L468 — empty matcher: device-encoder composition identity

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L468). `sum(device_matchers, PatternMatcher([]))` uses an empty, zero-rule identity to concatenate available device encoders.

**Example:** one AMD device type contributes its two submit rules; an absent device encoder contributes none.

Why: allow a uniform composition for varying device sets. The empty seed does not match or transform anything.

### runtime/support/hcq2.py:L470 — empty matcher: device-lowerer composition identity

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L470). Same zero-rule sum seed for `pm_lower`.

**Example:** USB contributes memory-access transport rules; a device without a lowerer leaves this stage empty apart from the separate patching pass.

Why: optional backend lowering without a fake catch-all rule.

### runtime/support/hcq2.py:L496 — empty matcher: visualize link-time patches

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L496). Under VIZ, zero rules record the patch SINK.

**Example:** binary upload and fixed-address stores are shown unchanged.

Why: debugging the compile/link split. This invocation does not apply those stores to memory.

### runtime/support/hcq2.py:L497 — empty matcher: visualize lowered body

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L497). Under VIZ, zero rules record the final host SINK.

**Example:** the two-kernel dispatch body appears unchanged.

Why: inspection of generated submission code. Encoding happened earlier; displaying it is not a second lowering pass.

## HCQ link-time rules: these may write memory

### runtime/support/hcq2.py:L565 — pm_link: strip an intermediate constant cast

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L565). Match `CAST(CAST(CONST))`; return the original constant cast directly to the outer dtype.

**Example:** a constant address widened to uint64 after a bookkeeping uint64 cast keeps only the final cast.

Why (inference): normalize constant patch expressions so `.val` and constant ALU folding can resolve them during linking. This is a specialized linker rule, not a general algebraic law: a narrowing intermediate cast could discard bits. Do not copy it into arbitrary numerical optimization without proving the linker operand invariants.

For contrast, `uint16(0x1234) → uint8 → uint16` normally yields `0x0034`, not `0x1234`. That is why removing an intermediate cast requires the restricted linker setting described above.

### runtime/support/hcq2.py:L566 — pm_link: resolve parameters and allocate placeholders

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L566). Match PARAM. If it is in `ctx.inputs`, return that UOp; otherwise `bufferize_buf` declines untagged params, tries the device's `pm_bufferize`, then allocates owned storage when `use_rt` is false or a 256-byte-aligned runtime-ring view when true.

**Example:** an `lt_input` binds to the actual input tensor; a `cmdbuf` placeholder receives uncached CPU-accessible storage.

Why: symbolic resources finally need actual allocations. The helper wraps returned buffers as UOps on the runtime device. Owned versus borrowed ring storage has different lifetime constraints; even a zero-size runtime request reserves at least one byte.

Owned storage has an allocation retained for this resource. A borrowed view into a reusable runtime ring instead depends on the ring’s completion/reuse protocol; its address can be valid now without being safe to retain indefinitely.

### runtime/support/hcq2.py:L567 — pm_link: resolve concrete addresses and retain owners

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L567). Match GETADDR. Unwrap a view and only proceed when its base is BUFFER or MSELECT; add the base to `ctx.refs`, then return uint64 `buffer.get_buf(requested_device) + byte_offset`.

**Example:** an AMD-visible mapping at `0x100000` with a 64-byte view offset becomes `0x100040`.

Why: packet fields need real device addresses, and encoded integers alone would not keep the allocation alive. Unresolved params decline; reference retention is as important as numeric substitution.

An integer address does not act like a Python reference to an allocation. Without `ctx.refs`, storage could be freed or reused while the command still contains its old numeric address.

### runtime/support/hcq2.py:L568 — pm_link: constant ALU words

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L568). Match any `GroupOp.ALU` whose sources are all constants or casted constants. Evaluate `exec_alu(op,dtype,source_values,False)` and return a constant of the result dtype.

**Example:** `(resolved_addr >> 32) | flags` folds to the packet's fixed high word once the address is concrete.

Why: finalize bitfields and address arithmetic before uploading patches. Dynamic loads do not match. The `False` flag disables `exec_alu` output truncation for scalar operands; packet-writing helpers later mask to field width. Do not assume this is identical to general symbolic folding.

A packet may split a 64-bit address across two 32-bit words. For address `0x0000000212345678`, shifting right by 32 yields the high word `2`; combining that with fixed flags can be completed once the address is known.

### runtime/support/hcq2.py:L570 — pm_link: upload binary blob

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L570). Match STORE to any buffer of BINARY or BITCAST(BINARY). Resolve base/view offset and write blob bytes into its host view, unless `_hcq_written[offset]` is already the **same bytes object**; then return NOOP.

**Example:** a 256-byte command template uploads once at offset 0.

Why: executable/program/command data becomes real memory at link time. The source marks the identity cache `TODO: remove me`; it is a performance shortcut, not content equality. It records only offset→object identity, so do not use this helper as a general coherent memory cache after unrelated mutations.

Object identity means the exact same Python bytes object, not merely another object containing equal bytes. The cache therefore records a narrow initialization shortcut, not a general proof that destination memory still matches the blob.

### runtime/support/hcq2.py:L571 — pm_link: write constant scatter patches

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L571). Match a STORE indexed by STACK of constants/casted constants whose value is likewise STACK of constants/casted constants. For each paired index/value, write its item-size bytes little-endian at `view_offset + index * itemsize`, mask to that width, and return NOOP.

**Example:** uint32 indices `[2,5]`, words `[0x1234,0xabcd]` patch byte offsets 8 and 20.

Why: a command template's fixed words need only be initialized once at link time. The helper relies on matching lengths and valid backing storage; zip would otherwise truncate. Runtime-dependent values do not match.

Little-endian layout puts the least significant byte first: uint32 `0x1234` is written as bytes `34 12 00 00`. The indices are element indices, so uint32 index 2 starts at byte offset 8.

### runtime/support/hcq2.py:L573 — pm_link: remove completed patches around CALL

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L573). Match `AFTER(CALL,deps...)`; rebuild the CALL's AFTER with only dependencies that are not NOOP.

**Example:** `AFTER(dispatch,NOOP,owner_ref) → AFTER(dispatch,owner_ref)`.

Why: executed link-time stores have become NOOP but buffer ownership/remaining dependencies still matter. Calls are allowed to retain dependencies, unlike ordinary linked buffer wrappers handled next. This ordering intentionally catches calls first.

### runtime/support/hcq2.py:L575 — pm_link: reject unresolved non-call link dependencies

[Source](../../../../tinygrad/tinygrad/runtime/support/hcq2.py#L575). Match any AFTER. Decline bound variables or CALL roots. For all other roots, return the root if every dependency is NOOP; otherwise raise `RuntimeError("unresolved link words on ...")`.

**Example:** `AFTER(cmdbuf,NOOP,NOOP) → cmdbuf`, but `AFTER(cmdbuf,unresolved_store)` fails.

Why: linking must not silently erase a patch that still needs an address/value. This is a validation guard as much as a cleanup. Bound-variable AFTER nodes encode a different semantic relationship and must survive.

A remaining dependency can mean “this command word has never been initialized.” Raising here prevents execution of a partially linked schedule, where an unresolved address might otherwise be mistaken for usable packet data.

## USB: transport lowering and explicit workarounds

USB (Universal Serial Bus) requires explicit transfers instead of direct CPU reads/writes to remote GPU memory. Controller **SRAM** is a small staging memory between the host and GPU **VRAM**, the GPU’s main memory. A **sentinel** is a chosen marker value meaning that a staging slot is ready or consumed. The two halves let one chunk move while another is prepared, but a half cannot be reused until its previous reader finishes. A libusb **transfer descriptor** is a host object recording a pending transfer and its status; “reaping” it means observing its completion before reuse.

These are AMD-over-USB transport rules, unrelated to the `IMAGE` tensor option. Many odd-looking constraints here have explicit comments: 32-bit control writes, one-trip-loop unrolling, and zero-byte streams hanging. They are useful examples of how a PM's simple shape hides a protocol/state-machine requirement.

### runtime/support/usb.py:L326 — pm_usb_copy_slicer: staged COPY to SRAM protocol

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L326). Match exactly `CALL(COPY,dst,src)`; only act if the call has assigned chunk/run numbers in the context map. For host→device, chunk by CHUNK (`0x40000 - 512`, or 261632) bytes and alternate SRAM halves: wait for the exact sentinel, copy SRAM payload to VRAM, clear sentinel, signal fence. For device→host, chunk by `2*CHUNK`: wait for host GO, clear GO, copy up to two payload segments into SRAM halves, clear completion word and advance fence. Return LINEAR; the appended `pm_flatten_linear` flattens it.

**Example:** a three-chunk upload uses halves 0,1,0; the third waits for a fresh sentinel before reusing half 0.

Why: bridge host USB transfers with GPU-local DMA through controller SRAM. Sentinel words and payload alignment are protocol fields, not tensor data. The exact three-source pattern does not automatically cover arbitrary extra CALL arguments.

The sender and receiver share staging memory but progress independently. The sentinel means “this half contains the expected chunk”; clearing it means “that chunk was consumed.” Waiting for a fresh marker before reuse avoids reading an earlier chunk twice.

### runtime/support/usb.py:L349 — pm_usb_batch: add host side of staged transfers

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L349). Match SINK. Inspect submitted linears for COPYs where exactly one endpoint is host memory; decline if none. Group consecutive copies by upload/download direction, assign chunk numbers, rewrite GPU copies with the slicer, then append an ordered host USB sequence and update the stored chunk count.

**Example:** upload A, upload B, download C forms one upload run and one download run, with matching GPU sentinel/fence numbers and host transfers.

Why: both sides of the protocol must be generated from the same chunk numbering. `is_host` includes CPU and non-HCQ endpoints; it is not simply `device == "CPU"`. Dependencies on submission/draining prevent host-side buffer reuse while an earlier transfer is active.

The helper's `usb_copyin` explicitly unrolls a single pair because “the linearizer misplaces one-trip loops.” That workaround is below this rule rather than a separate PM: two chunks are emitted directly, while larger numbers of pairs can use a RANGE. `usb_drained` reads one fence byte to avoid tearing. These are documented implementation motivations, not guessed hardware errata.

Tearing means reading part of an old multi-byte value and part of a new one while it changes. The one-byte fence read avoids that particular mixed-value observation. The loop workaround is about the compiler’s placement of generated control flow, not a mathematical need to process two chunks together.

### runtime/support/usb.py:L472 — pm_usb_lower: contiguous copy/fill loop becomes one stream

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L472). Match `END(STORE(INDEX(dst,di),v),RANGE r)` in the indicated pattern construction. Require `dst` to be remote. If `v` is a load from a nonremote source, require source index `r` or `base+r` with base independent of r; alternatively a value provably zero uses the host zero area. Require the destination index to have the same affine form. Successful matches produce one `usb_stream` write; noncontiguous/other-value remote loops fall back to `usb_store(...).end(r)` rather than declining.

**Example:** `for r<256: remote[16+r]=host[4+r]` becomes one 256-element stream, whereas a non-affine destination keeps per-element stores.

Why: amortize USB protocol overhead across contiguous data.

Two explicit edge workarounds matter. Zero-byte streams hang, so a zero-trip loop redirects to device scratch and sends at least one element. The source index is clamped to the last valid element so that this dummy transfer has a safe source view. Real zero-length semantics are preserved by changing the destination, not by issuing a zero-byte transfer. Dependencies from both views and the RANGE are retained. A strided source is not a single contiguous transfer simply because the destination is contiguous.

An affine index of the required form advances by exactly one element per iteration, like `16+r`. That permits a single contiguous transfer. `16+2*r` skips elements and cannot be replaced by the same contiguous byte stream.

### runtime/support/usb.py:L473 — pm_usb_lower: scalar/patch-word stores become control transfers

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L473). Match `STORE(INDEX(b,idx),v)`; only act if `idx.ranges` is empty and `b` is remote. `is_remote` unwraps views and requires a device PARAM outside host devices, excluding tags starting `usb_host`, `usb_xfer`, `put_value`, `cmdbuf_copy`. `usb_store` serializes STACK-index patches, emits one poke for 4-byte values or two ordered 32-bit pokes for wider values.

**Example:** a uint64 kernel argument `0x1122334455667788` writes low word `0x55667788` then high word `0x11223344` at address+4.

Why is explicit: each control transfer writes 32 bits.

For 8-byte values to `kernargs*` placeholders, a host cache compares the previous value, conditionally sends only changed arguments, then updates the cache.

**Example:** replaying with the same pointer avoids two USB pokes; a changed input pointer sends both words. The index-range guard leaves loop bodies for the preceding loop rule. The helper's non-4-byte branch is designed around its callers' word widths, not a generic arbitrary-dtype byte store. The cache starts at zero; avoiding a zero-valued first poke relies on surrounding initialization assumptions, so do not generalize this into a cache for uninitialized remote memory.

A “poke” is a small explicit remote write. Splitting an eight-byte pointer into two pokes requires the surrounding submission order to prevent the device from using the pointer halfway through its update.

### runtime/support/usb.py:L474 — pm_usb_lower: remote load through a host slot

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L474). Match `LOAD(INDEX(b,idx))`; require the same `is_remote(b)` predicate. Allocate a host stack slot of the load dtype, issue a USB read stream from `rt_addr(b)+idx*itemsize` into it after the view's dependencies, then load the slot after the transfer.

**Example:** a remote uint32 completion-word read becomes a four-byte USB read followed by a CPU load.

Why: host code cannot dereference device memory as ordinary local RAM across USB. The dependency on transfer completion is essential; loading the stack slot early reads stale/uninitialized data. Unlike scalar stores, this match has no `idx.ranges` exclusion.

The temporary host slot bridges two different operations: first transport bytes across USB, then read those bytes with a CPU instruction. The AFTER dependency prevents the second operation from overtaking the first.

### runtime/support/usb.py:L496 — pm_usb_bufferize: persistent host block

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L496). Match `PARAM(tag="usb_host")`; return cached `_host_block(ctx)`. It allocates `0x180020` uint8 bytes on CPU with no LRU eviction, and writes the USB device handle and libusb context pointers into the first 16 bytes.

**Example:** host transfer code's link/staging/zero-region views all bind into the same block.

Why: the compiled host protocol needs stable handles and scratch storage. This resource includes runtime pointers and has process/device lifetime; it is not transferable as a serialized tensor or reusable across unrelated device instances.

### runtime/support/usb.py:L497 — pm_usb_bufferize: two asynchronous transfer descriptors

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L497). Match PARAM with tag in `{usb_xfer0,usb_xfer1}`; return cached `_xfer(ctx,b.tag)`. Each helper allocation creates a libusb transfer with endpoint `0x02`, BULK type, 10,000 ms timeout, and wraps the external struct pointer in a non-LRU CPU Buffer.

**Example:** the two upload halves have separate descriptors so transfer 0 can be reaped while transfer 1 is prepared.

Why: pipelining requires independently tracked in-flight transfers. Status, length and data pointer are mutable per chunk; descriptor reuse is legal only after the previous transfer completes. Both tags are one outer pattern with two explicit alternatives.

An in-flight descriptor can still be read or updated by the USB library. Keeping two descriptors permits overlap, but neither its data pointer nor its backing bytes may be repurposed while that particular transfer is unfinished.

### runtime/support/usb.py:L498 — pm_usb_bufferize: remote signal/scratch words

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L498). Match `PARAM(tag="usb_vram")`; return cached `_words(ctx)`, two device uint32 words allocated uncached, CPU-accessible and non-LRU, initialized to eight zero bytes.

**Example:** the read-side GO signal starts at zero and the second word can absorb a dummy empty-loop transfer.

Why is explicit: zero the read signal and scratch. Initialization and persistent identity prevent an old signal from accidentally authorizing a new read.

### runtime/support/usb.py:L499 — pm_usb_bufferize: controller command storage

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L499). Match `PARAM(tag="usb_asm24")`; return the interface's `ctrl` buffer.

**Example:** generated controller-command operations bind to the interface's existing control area.

Why: controller commands require the transport-owned allocation. The pattern performs no allocation or validation of command bytes; it relies on USB interface setup and the command helpers. This is another reason inspecting by actually rewriting a fabricated placeholder can touch device state.

### runtime/support/usb.py:L500 — pm_usb_bufferize: keep copy command buffers on CPU

[Source](../../../../tinygrad/tinygrad/runtime/support/usb.py#L500). Match any PARAM; only tags whose string starts `cmdbuf_copy` allocate `Buffer("CPU", b.max_numel(), b.dtype, preallocate=True)`. Other tags decline.

**Example:** `cmdbuf_copy_0` stores its command template in CPU memory, from which the USB submission path streams it to the device ring.

Why (inference from transport lowering and `is_remote`): host-visible command bytes must remain local so preparing/uploading the stream does not recursively lower every command-buffer store to an individual remote USB poke. This prefix is also explicitly excluded from `is_remote`; both decisions belong together. A renamed tag can change placement and lowering behavior even with identical dtype/shape.

The host builds a command list locally, then sends the list as a stream. If its local preparation stores were mistaken for remote stores, each word would itself require a USB command, defeating the intended batching.

## Reading this chapter as a whole

A useful two-kernel example is **RMSNorm → matmul with an actual dependency**. Compilation leaves two PROGRAM calls if the compute schedule did not fuse them. HCQ then picks queues, encodes dispatch packets, represents buffers and addresses symbolically, moves fixed command words into link-time writes, and retains runtime address loads for replay. Linking allocates storage and writes immutable packet data; execution patches current arguments and launches the host submission program. A single HCQ call or graph replay can therefore contain two GPU kernels. None of the runtime PMs above is evidence that those two kernels became one GPU kernel.

For unusual rules, ask three separate questions: is this an arithmetic rewrite, an ordered protocol transformation, or an action that binds/writes storage? An algebraically plausible rewrite can be invalid for packet order or buffer lifetime. Conversely, a deliberately redundant-looking AFTER, dummy transfer or cached buffer may be the mechanism that makes replay safe.
