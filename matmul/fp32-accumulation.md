# Matmul accumulation precision

Input format, product fidelity, Dst precision, spill format, and output format
are separate choices. Keeping the output in FP32 does not recover information
lost earlier in products or intermediate spills.

This page follows the September 2026 local blackhole-py tests. The earlier
`CkernelConfig` recipe described its retired LLK-based runtime.

## Dst capacity and spills

Widening Dst elements from 16 to 32 bits halves element capacity. For ordinary
32×32 tiles:

| Dst representation | Whole Dst | Half-Dst producer/consumer partition |
|---|---:|---:|
| 16-bit | 16 tiles | 8 tiles |
| 32-bit | 8 tiles | 4 tiles |

Half/full partitioning is a software synchronization policy. With half-Dst
ownership, a subblock must fit in that half. Smaller subblocks can increase
scheduling overhead; they do not imply a universal 26% throughput penalty.

For long K reductions, the intermediate packed representation matters too.
FP32 accumulation requires preserving FP32 partials across K blocks, including
pack/unpack configuration and intermediate page sizes. A 32×32 FP32 payload is
4,096 bytes; a BF16 payload is 2,048. BF16 and IEEE FP16 are different formats;
avoid using “fp16” as a synonym for both.

## Current tested path

The inspected [matmul implementation](../../blackhole-py/examples/matmul_peak.py)
defaults to BF16 inputs, HiFi4 products, FP32 accumulation, and FP32 output.
Explicit BF16 accumulation remains available. `--fp8-fast` uses FP16 accumulation
and output; FP8 with FP32 accumulation is another mode.

The [FP32 tests](../../blackhole-py/tests/compute/fpu/test_matmul_peak_fp32.py)
include a K-block cancellation case and compare the complete result to a
reference. The [row-major report](../../blackhole-py/tests/movement/matmul_row_major.md)
records numerical error and timing scope. These support the inspected paths,
not every shape, numerical edge, or future emitter change.

## Packer L1 accumulation

A blanket statement that FP32 cannot use packer L1 accumulation is incorrect.
[Raw tests](../../blackhole-py/tests/movement/packer/test_l1_accumulation.py)
validate BF16 and FP32 L1 outputs with nonzero initial values, zero contributions,
cancellation, repeated passes, and adjacent guards. The recipe enables both
`Pack_L1_Acc` and `Disable_pack_zero_flags`, then restores them.

This does not establish arbitrary mixed-format behavior. In particular, the
[historical Float16-format bug](../hardware/packer-l1-acc-float16-hardware-bug.md)
concerns a different format/configuration. FP32 Dst and FP32 L1 accumulation
should not be conflated with FP32 Dst converted to a narrower output before
accumulation. See the [test evidence guide](../hardware/behavior-from-tests.md).

## Compare performance fairly

Record input dtype, fidelity, Dst dtype, spill dtype, output dtype, layout,
shape, worker count, clock, and the timed completion boundary. The older
[P100A sweep](../archive/matmul/matmul-peak-sweep.md) remains a historical measurement, not a
prediction for the current runtime. The
[row-major comparison](../kernel-dev/row-major-matmul.md) separates BF16/HiFi2
from BF16/HiFi4/FP32 results.
