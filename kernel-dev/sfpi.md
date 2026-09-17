# SFPI and LLK programming

SFPI is the C++ interface compiled to SFPU instructions by Tenstorrent's GCC
extensions. LLK supplies architecture-specific unpack/math/pack sequences;
TT-Metal's `compute_kernel_api` wraps them. These are separate from current
blackhole-py's Python instruction emitters.

## What runs where

A TT-Metal compute source is compiled for three TRISCs. Its `UNPACK`, `MATH`,
and `PACK` sections follow the stack's controller assignment. Normal C++ scalar
control flow runs on the issuing RISC-V core. SFPI vector operations target the
shared Tensix vector engine.

The SFPU is not private hardware physically attached only to “the MATH core.”
That is a software assignment. Likewise, sharing a controller in one software
schedule does not prove that independent FPU and SFPU work can never overlap.
The [Dst contention tests](../../blackhole-py/tests/compute/fpu/test_dst_bandwidth.py)
exercise that distinction.

## Registers and movement

| Interface | Meaning |
|---|---|
| `vFloat`, `vInt`, `vUInt` | 32-lane values held in SFPU local registers |
| `dst_reg` | Dst load/store interface using the configured address state |
| `l_reg` | Explicit local-register access |
| `vConst*` | Fixed or programmable constant registers |
| `s2vFloat16a/b` | Helpers for encoded 16-bit constants |

SFPU math loads Dst into local registers, computes, and stores back. The matrix
engine consumes SrcA/SrcB and accumulates into Dst. Unpack/pack connect these
register files to L1. LLK initialization establishes formats, addressing, and
synchronization; replacing a math wrapper with SFPI does not replace that setup.

## Tile traversal

A conventional 32×32 tile has four 16×16 faces. A 32-element vector operation
covers one vector, not an entire tile. A common LLK wrapper visits four faces
and executes eight vector iterations per face. Address modifiers, Dst format,
and the wrapper's face selection determine the actual mapping.

```cpp
// Math body only, for a wrapper that already positioned one face.
// Initialization, ownership, outer face iteration, and packing are omitted.
using namespace sfpi;
for (int i = 0; i < 8; ++i) {
    vFloat x = dst_reg[0];
    dst_reg[0] = x + vConst1;
    dst_reg++;
}
```

Do not copy this body into an arbitrary kernel and assume it visits all 1,024
elements. Verify address stride, face transitions, and every output. The old
flat `dst_reg[0..31]` recipe conflated element count with a configured traversal.

## Predication and masking

`v_if`, `v_elseif`, `v_else`, and `v_endif` produce vector condition-code
operations. They select active lanes; they are not scalar branches that skip an
entire hardware instruction stream. C++ `if` and `for` are scalar control flow.
`v_block` / `v_and` can narrow a predicate; consult the local SFPI headers for
nesting and expression limits.

The lane's enable and condition-code state, condition-code stack, and static
row masking are different mechanisms. A false predicate does not necessarily
cancel address-counter updates or other instruction side effects. Re-establish
predicate state when the next operation requires all lanes. Row masks alone
are not a general solution to arbitrary two-dimensional tails.

For reductions, replace invalid elements with the operation's identity rather
than relying on zero multiplication for every dtype/value. See
[dataflow and padding](dataflow.md).

## Choosing the implementation layer

| Need | Starting point |
|---|---|
| Standard tile operation | TT-Metal `compute_kernel_api` wrapper |
| Architecture-specific operation or scheduling | Blackhole LLK headers |
| Custom vector arithmetic | SFPI body inside a correctly initialized compute kernel |
| Raw scheduling or instruction experiments | blackhole-py emitters and the ISA reference |

LLK implements matrix, reduction, data movement, conversion, and SFPU families;
it is not exclusively a collection of SFPU instructions. SFPI arithmetic helpers
may expand into multiple instructions. An API name such as approximate exp does
not establish IEEE-exact behavior or a one-cycle implementation.

## Build and inspect

Use the SFPI-enabled compiler with optimization as required by the wrapper
headers. Inspect the generated TRISC ELF when instruction choice or scheduling
matters. The [TT-Metal build guide](../build-and-dispatch/tt-metal-build.md)
describes generated descriptors and firmware linking. The sibling SFPI
checkout's README and `scripts/build.sh` define toolchain build/test commands.

Source entry points are `sfpi/include/sfpi.h`,
`sfpi/include/blackhole/sfpi_hw.h`, Blackhole LLK's `llk_lib` and
`common/inc/sfpu`, and TT-Metal's `compute_kernel_api`.

## Test evidence and timing

Use the ISA tab to distinguish encoding checks, reviewed behavioral assertions,
and measurement records. Its timing fields separate issue spacing from result
availability. A throughput loop is not an isolated dependent latency test.
For fused epilogues, wait for matrix writes before loading the same Dst block,
then finish SFPU stores before handing it to the packer. The
[matmul guide](../matmul/README.md) covers this ownership transition.
