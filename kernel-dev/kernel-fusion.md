# Keeping a matmul epilogue in Dst

The matrix engine writes results to Dst. The SFPU loads Dst into vector
registers and stores results back. An epilogue can therefore run before the
final pack, avoiding an intermediate L1/DRAM spill and reload.

This saves memory traffic, not all computation. SFPU instructions, configuration,
register ownership, and engine dependencies still have costs. The current
blackhole-py interface uses Python instruction emitters; the LLK/SFPI names in
older examples belong to the C++ stack.

## The dependency to preserve

```text
matrix operations on an output block
    → wait for the relevant Dst writes
    → SFPU load / arithmetic / store on that block
    → wait for SFPU completion and publish Dst
    → pack final output
    → finish output transfer before reusing its storage
```

Do not publish a block to the packer while its epilogue still modifies it.
A delayed load-macro store must also finish before ownership changes. A
controller issuing its last instruction is not the same as backend completion.

## Shared engines do not imply universal serialization

The old claim that FPU and SFPU cannot overlap because both use TRISC1 was too
strong. Controller assignment, engine resource arbitration, and data dependence
are separate. Current
[Dst contention probes](../../blackhole-py/tests/compute/fpu/test_dst_bandwidth.py)
compare schedules on independent regions and exercise different issuing TRISCs.
They do not make it legal to read a matrix result before it is ready.

For a simple epilogue on the same block, order the dependent work explicitly.
For overlap across independent blocks, measure the actual Dst port contention
and switching costs; don't assume either perfect overlap or mandatory global
serialization.

## Configuration is part of the fused kernel

The unpacker, matrix address modes, SFPU modes, packer format, and synchronization
state must agree. Calling a full datacopy initializer between matrix math and
an epilogue can change more state than intended. Raw SFPI or direct opcodes do
not eliminate the need for correct Dst addressing, predication, format, and
hazard handling.

A 32×32 tile's face layout and vector addressing determine which elements are
visited. A guessed `dst_reg[0..31]` loop is not a universal proof that every
logical element was processed. Validate all outputs and adjacent guards.

## Capacity and precision

The ordinary whole-Dst capacity is 16 32×32 tiles with 16-bit elements or eight
with 32-bit elements. A half-Dst ownership scheme halves those counts again.
Fused temporaries and a bias operand also consume resources. Large reductions
may still need spills; preserve the chosen precision across them. See
[accumulation](../matmul/fp32-accumulation.md).

Packer ReLU can eliminate a separate SFPU activation sequence when its exact
semantics meet the numerical contract. It still runs within the pack path;
call it an avoided math sequence rather than assuming an end-to-end zero cost.

## Evidence to read

- [Load-macro scale test](../../blackhole-py/tests/compute/sfpu/test_loadmacro_pipeline.py): all 8,192 FP32 values and guards are checked across five schedules; configuration/unpack/pack are outside its timed compute interval.
- [Hardware evidence guide](../hardware/behavior-from-tests.md): reported results and their limitations.
- [Current timing guide](../../blackhole-py/tests/timing/README.md): result readiness, issue spacing, resource sharing, and completion.
- [Compute pipeline](tensix-compute-pipeline.md): the TT-Metal/LLK programming interface.
