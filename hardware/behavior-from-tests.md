# Blackhole behavior demonstrated by tests

Reviewed September 17, 2026 against the local `../blackhole-py` checkout,
baseline commit `0ebd556c6c686b18b7b10bc8ea5bd75ea12259dd`. That tree contains
uncommitted matmul changes and an untracked ISA suite. Links below target that
sibling checkout, including files that may not yet exist upstream.
[Source fingerprints](../maintenance/blackhole-py-sources.json) identify the
inspected files. Recorded hardware outcomes below were produced by the source
repository's earlier runs, not by rerunning the card for this documentation edit.

## What counts as evidence?

An encoding test checks bits. A hardware test with a numerical oracle checks
its particular inputs, modes, placement, and output. A benchmark with no output
check establishes neither numerical correctness nor general instruction semantics.
A test used only to initialize an engine does not validate all that engine's modes.

The [ISA review](../../blackhole-py/tests/isa/review.md) records partial behavioral
claims for 66 instructions and no reviewed claim for 71 others. It explicitly
declares none exhaustively tested. Its [recorded combined run](../../blackhole-py/tests/isa/results.md)
has 33,725 passes, 60 deselections, and five expected failures, mixing offline
checks and hardware cases. Those counts must not be presented as 33,725 distinct
hardware features. The reported device/core scope is device 0, worker index 0.

## Read these experiments first

| Hardware question | Test / source | What the assertions establish | What remains outside the claim |
|---|---|---|---|
| Is the controller split fixed? | [Program](../../blackhole-py/program.py), [sync tests](../../blackhole-py/tests/isa/test_sync.py) | Launches can supply selected roles; semaphore tests exercise all three TRISCs | Arbitrary engine/thread combinations are not thereby validated |
| Do semaphore posts stop at configured Max? | [test_semaphore_masks_saturation](../../blackhole-py/tests/isa/test_sync.py) | For the tested initialization boundaries and all 256 masks, post saturates at 15; get floors at zero; unselected counters retain their values | Max controls the maximum-value wait condition; it is not the post saturation limit |
| Does a wait release after any selected semaphore changes? | [test_semaphore_wait_all_conditions](../../blackhole-py/tests/isa/test_sync.py) | Selected masks and conditions require the tested full release; a partial release does not let the observer pass early | All possible schedules and fairness are not tested |
| Are mutexes recursive locks? | [test_mutex_exclusion](../../blackhole-py/tests/isa/test_sync.py) | Indices 0, 2, 3, 4 protect a shared counter with two/three contenders; reacquisition by the owner needs only one release | No recursive depth counter is implied; invalid indices are not exercised |
| Can the packer add to existing L1? | [test_l1_accumulation](../../blackhole-py/tests/movement/packer/test_l1_accumulation.py) | BF16 and FP32 output, 16/256/1,024 elements, one/four passes, nonzero initial L1, zero contributions, cancellation, guards | FP16 format A, arbitrary rounding, overflow, and all mixed-format combinations |
| Can SFPU work overlap across load macros? | [test_scale_pipeline](../../blackhole-py/tests/compute/sfpu/test_loadmacro_pipeline.py) | Five schedules double all 8,192 FP32 inputs and preserve output guards | A model-level speedup or universal replay advantage |
| Does min/max implement the desired argmax ties? | [min/max tests](../../blackhole-py/tests/movement/sfpu/test_minmax.py), [argmax implementation](../../blackhole-py/ttko/argmax.py) | Paired indices, signed zero and negative ties need explicit treatment; sortable keys preserve the tested first-index rule | NaN ordering is unspecified by the prototype |
| Must matmul inputs be host-tilized? | [row-major unpack tests](../../blackhole-py/tests/movement/unpacker/test_unpack_row_major.py) | FP8/BF16 panels can be gathered from row-major L1 into source banks | The two formats do not have identical gather cost |
| Does FP32 output ensure FP32 partials? | [matmul FP32 tests](../../blackhole-py/tests/compute/fpu/test_matmul_peak_fp32.py) | End-to-end reference checks and K-block cancellation cases test the current partial-sum path | Every fidelity/shape/format combination and numerical boundary |
| Does an opcode absent from compiled C++ matter? | [scalar tests](../../blackhole-py/tests/isa/test_scalar.py), [SFPU bit tests](../../blackhole-py/tests/isa/test_sfpu_bits.py) | Raw Python emitters use and validate operations outside an old LLK workload sample | Frequency in a workload is not an ISA support/deletion criterion |

## Three lessons for kernel writers

### Packer accumulation needs two configuration changes

The tested recipe enables `Pack_L1_Acc` (configuration word 71, bit 19) and
`Disable_pack_zero_flags` (word 70, bit 2), drains pack work, and clears both
settings afterward. If a new Dst contribution is zero, the old L1 sum must
survive. The tests include a whole zero face to detect this failure.

The [recorded pack timings](../../blackhole-py/tests/compute/sfpu/hardware_probe_results.md)
show identical overwrite/accumulate medians for these cases. That demonstrates
no added measured cost within the pack interval, not a free end-to-end matmul.
BF16 L1 accumulation rounds at spills; FP32 L1 accumulation does not have the
same precision loss. Neither observation disproves a separate Float16-format
bug or a mixed-format limitation.

### A load macro is a schedule, not just a shorter spelling

In the scale experiment, a macro launches multiply at t+1 and store at t+3.
Four rotating registers avoid overwriting values awaiting delayed stores.
The recorded Dst-to-Dst interval is 306 cycles for that pipeline versus 1,054
for the explicit load/multiply/NOP/store sequence. Serial macros take 1,164.
Configuration, initial unpack, and final pack are excluded. Both timing
boundaries synchronize the issuing thread; the final drain includes delayed work.

### Layout choice can dominate matrix performance

The row-major matmul path removes host tilization, but BF16 needs more gather
instructions than FP8 in the inspected implementation. Compare schedules with
the same input format, fidelity, accumulation, layout, and completion boundary.
The [row-major guide](../matmul/README.md#row-major-matmul) records the evidence and
avoids comparing different numerical modes as though only layout changed.

## Limits and remaining work

The ISA suite retains five expected FP8 subnormal failures and reports an
unresolved intermittent native crash; successful diagnostic repetitions are
not a root-cause fix. Read its results and source fingerprints before reusing
old pass counts after changes.

Major gaps include address-counter/config state, replay/MOP transitions,
modifier interactions, exceptional arithmetic values, wider format coverage,
stream transport, cross-thread scheduling, and additional cards/cores. The
[coverage audit](../../blackhole-py/tests/hardware_coverage_audit.md) also separates
DRISC GDDR DMA from the current Tensix DRAM service and overlay counter use from
autonomous overlay message transport.

For normative instruction descriptions use the
[Blackhole A0 manual](https://github.com/tenstorrent/tt-isa-documentation/tree/main/BlackholeA0).
These experiments complement the manual and bound our claims; they do not
replace it with a complete executable specification.
