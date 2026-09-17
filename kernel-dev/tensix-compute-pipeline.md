# Compute pipeline and scheduling

A Tensix tile has RISC-V controllers that issue work to shared compute and
movement engines. TT-Metal commonly assigns TRISC0 to unpack, TRISC1 to math,
and TRISC2 to pack. Current blackhole-py emits controller programs directly.
Controller assignment is a software choice; it is not engine ownership wired
into a particular RISC-V core.

## The dependency chain

```text
L1 input → unpack → SrcA/SrcB → matrix math → Dst → pack → L1 output
                                            ↕
                                      SFPU local registers
```

Unpack-to-Dst paths also exist. A matrix instruction consumes configured source
regions; an SFPU load/store uses Dst addressing and local registers. Formats,
address modifiers, and valid/ownership state determine what data each sees.

| Boundary | What must be established |
|---|---|
| Reader to unpack | Input bytes complete and L1 buffer published |
| Unpack to math | Correct source bank filled and ready |
| Math to SFPU epilogue | Dependent Dst writes available |
| Math/SFPU to pack | Final Dst contents complete and ownership published |
| Pack to writer | Packed bytes complete in output L1 |
| Writer to buffer reuse | NoC transfer finished using that storage |

Use [dataflow](dataflow.md) for CB semantics and [matmul](../matmul/README.md)
for Dst partitioning, precision, and fusion.

## Issue rate is not completion time

RISC instruction retirement, coprocessor issue, and backend completion are
different events. A stall or semaphore instruction only establishes the
condition named by its mode and resource mask. It does not act as a universal
barrier for all engines.

The ISA viewer separates result/service latency, issue spacing, and measured
loop slopes. For example, the imported MVMUL timing model has a one-cycle issue
interval and five-cycle result latency. Dependencies and resource contention
can lengthen a real loop. Those numbers do not predict an entire matrix multiply.

An MVMUL micro-operation and a 32-lane SFPMAD do different amounts of work.
Their nominal FLOP counts are not a universal “FPU is 64× faster” statement for
arbitrary arithmetic, dtypes, or fidelity modes.

## Address state and repeated work

RWCs track source/destination position and fidelity state. Configured address
modifiers update that state as instructions execute. Resetting the wrong counter
or advancing a fidelity phase at the wrong boundary can silently compute a
valid-looking result from the wrong panel.

The MOP expander generates repeated instruction patterns; replay reissues a
recorded sequence. They reduce controller issue overhead, but backend hazards,
completion, and address updates still apply. Buffer capacity and legal recording
modes are architecture-specific. See the
[frontend reference](../hardware/blackhole-emulator-specs/frontend.md) for the
functional model and the ISA entries for evidence and encodings.

## Overlap and contention

Independent matrix and SFPU work can contend for shared Dst resources. A single
software math controller is not proof of mandatory hardware serialization;
independent issuing streams are not proof of perfect overlap. Inspect the
[Dst bandwidth probes](../../blackhole-py/tests/compute/fpu/test_dst_bandwidth.py)
and their completion boundary before deriving a schedule.

On the same output block, finish matrix writes before dependent SFPU loads and
finish the epilogue before pack consumes it. Across independent blocks, measure
whether extra buffering and ownership transitions actually improve completion.

## Read the implementation with its runtime

For TT-Metal, initialization wrappers establish LLK format, synchronization,
and address state; the source is compiled for separate TRISCs. For blackhole-py,
read its emitter helpers and [runtime](../build-and-dispatch/blackhole-py-runtime.md).
The [hardware evidence guide](../hardware/behavior-from-tests.md) links actual
assertions. No hardware benchmark was rerun for this reference rewrite.
