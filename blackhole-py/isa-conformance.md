# Tensix ISA conformance suite

`blackhole-py/tests/isa` checks the encoding of all 137 public Tensix encoders
and tests selected behavior of 37 instructions on hardware. It does **not**
cover the whole ISA. Passing an encoding test checks instruction bits only.
For cycle costs, see [kernel timing estimation](../timing/kernel-estimation.md).

The per-instruction audit (reviewed claims, test functions, remaining gaps,
modifier obligations) is shown on the viewer's `/isa` page. Its data comes from
`tests/isa/audit.json` and `tests/isa/inventory.json` in blackhole-py; regenerate
the viewer snapshot with `python3 viewer/build_reference.py`.

The tests are Python, using `Asm` and `ttko.isa.Tensix`. C headers are read
only as encoding references.

## Run

From `blackhole-py`, using the shared virtualenv:

```sh
# No device access; hardware cases report as skipped.
../.venv/bin/python -m pytest tests/isa/test_encoding.py -q

# Reserve card 0 and run sequentially.
tt-device-queue run --device 0 --cwd "$PWD" -- \
  '../.venv/bin/python -m pytest tests/isa --bh-hardware --bh-device=0 -q'

# Regenerate inventory.json / audit.json.
../.venv/bin/python -m tests.isa.inventory
../.venv/bin/python -m tests.isa.audit
```

Regeneration requires sibling `tt-isa-documentation`, `tt-ins-docs`, and `tt-llk`
checkouts; running the tests does not. Blackhole LLK supplies all 517 encoded
operand fields, and manual SVG diagrams check additional layouts. The two
LLK X/Y versus Python Z/W parameter names are explicit aliases.

## What is checked

| Test | Assertions |
|---|---|
| `test_encoding.py` | All 137 opcodes and 517 fields: walking bits, boundaries, alternating patterns, combined operands; negative/overflowing operands rejected. Reserved bit patterns are checked as encodings only, never executed. |
| `test_sfpu_bits.py` | Bitwise ops, integer add/sub/mul, shifts, abs, sign/exponent/mantissa manipulation, immediate conversion, comparisons and condition flags, crossed with distinct/aliased registers and all/none/half-lane masks. |
| `test_predicate_stack.py` | All 16 push/pop modifiers, enable/disable, complement, comparison stack mutations; truth tables for current and saved state at depths 0, 1, 7, 8. |
| `test_sync.py` | Walking-bit and multi-bit semaphore masks, saturation, multi-condition waits, mutex exclusion with two/three contenders. |
| `test_sfpu_cast.py` | Sign-magnitude integer → FP32 nearest-even results and stochastic adjacent-value bounds. |
| `test_scalar.py` | Scalar GPR add/sub, low-16-bit multiply, all bitwise/shift/compare modes, immediates, aliases, bank boundaries, all three Tensix threads; checks all 64 GPRs afterwards. |
| `test_audit.py` | Coverage bookkeeping and opt-in native-memory diagnostic guards. |

SFPU bit tests transport results as two normal FP32 mantissas, so all 32 result
bits survive regardless of unpacker/packer NaN, denormal, or signed-zero
handling. Hardware tests also check an untouched adjacent Dst slot and an L1
output guard. Predicate tests observe both enabled lanes and their complement.

Reviewing the existing FPU, SFPU, packer, unpacker, transport and sync tests
gives **66 instructions with a partial reviewed claim and 71 with none**. No
instruction is declared exhaustively tested.

## Recorded validation (2026-09-17)

- Combined run, device 0, worker-core index 0: **33,725 passed, 60 deselected,
  5 xfailed** in 179 s (queue job `531310e844f84262b8e4498f408caa70`). Compact
  outcomes and source fingerprints: [evidence/final.json](../../blackhole-py/tests/isa/evidence/final.json).
- Unfiltered ISA suite under GDB: 32,793 passed (offline encoding checks plus
  5,424 predicate-stack, 1,122 SFPU-bit, 594 scalar, 2,408 semaphore/mutex and
  24 cast hardware cases). Encoding checks were later trimmed from 23,211 to
  9,534 cases (2026-10-07).
- The five xfails are FP8 subnormal divergences (see [FP8 and FP4](../hardware/fp8-and-fp4.md)).
- Fixing two stale `__import__('isa')` calls made all 88 transport cases pass
  ([before](../../blackhole-py/tests/isa/evidence/transport_before_fix.json),
  [after](../../blackhole-py/tests/isa/evidence/transport_after_fix.json)).

Older compact evidence is kept in `tests/isa/evidence/`.

### Unresolved native crash

One early combined run (queue job `7a0da9470a66407aa6fdbca68426f314`) exited
with SIGSEGV during pytest capture teardown, with the native stack ending in an
anonymous rw mapping ([evidence](../../blackhole-py/tests/isa/evidence/original_crash.json)).
It has not reproduced across seven later runs, including GDB, `PYTHONMALLOC=debug`
and mapping bounds checks. Root cause unknown; no fix is claimed. To catch it:

```sh
tt-device-queue run --device 0 --timeout 600 --cwd "$PWD" -- \
  'gdb --batch --return-child-result -x tests/isa/debug.gdb --args ../.venv/bin/python -m pytest tests/isa --bh-hardware -xq'
# or record the current test so it survives a native crash:
  '... -m pytest tests/isa --bh-hardware -q -p tests.isa.record --isa-record=/tmp/isa-debug.json --isa-memory-checks'
```

## Remaining work, in priority order

1. Address-counter/configuration state and replay/MOP semantics: updates, wraps,
   stalls, resource waits, sequence-dependent effects.
2. Remaining scalar memory/atomic and stream instructions; dedicated oracles for
   instructions currently used only as fixture setup.
3. FPU matrix/convolution/pooling semantics: fidelity/address/broadcast modes,
   source-valid and zero flags, exceptional values, accumulation edges.
4. Pack/unpack contexts, compression, addressing, formats, saturation, rounding.
5. SFPU lookup, shuffle, transpose, swap, lane-varying indirect addressing,
   load/store modes, PRNG, constant registers, partially fused arithmetic,
   stochastic rounding distributions.
6. Modifier interactions, scheduling hazards, documented silicon errata,
   other cores/cards, cross-thread interleavings.

NoC, PCIe, Ethernet and L2CPU conformance are out of scope for this suite.
