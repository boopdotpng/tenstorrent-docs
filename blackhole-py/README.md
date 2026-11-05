# blackhole-py

Docs for the [blackhole-py](../../blackhole-py/README.md) runtime: Llama 3 chat
on one Blackhole card using tt-kmd, C firmware, and Python-emitted RISC-V and
Tensix kernels (no TT-Metal, LLK or SFPI compiler). These pages used to live
inside the blackhole-py repo.

| Page | Contents |
|---|---|
| [Runtime map](runtime.md) | Device open → firmware build → boot → launch → completion |
| [Tests](tests.md) | How to run the hardware test suite, fixtures, profiling |
| [ISA conformance suite](isa-conformance.md) | Encoding and behavior checks for the Tensix ISA, results, gaps |
| [Test viewer](test-viewer.md) | Browse the instructions each test emits |
| [ttk graph frontend](ttk.md) | Current trace-only data/effect graph |
| [ttk v2 design](ttk-v2-design.md) | Draft design for a complete kernel frontend |
| [Kernel model plan](kernel-model-plan.md) | Plan to train a model that writes kernels for this runtime |

Measurements made with this runtime are in [measurements](../measurements/README.md),
[matmul results](../matmul/README.md#measured-results) and [timing](../timing/README.md).

## ttko (model kernels)

The model kernels use `ttko` while the new `ttk/model.py` develops independently.
The shared root `asm.py` supports both scoped physical registers and virtual
register allocation through one instruction/lowering path. `device.py` owns
hardware access and exposes `Device` for raw launches and `TensorDevice` for
queued tensor programs. `program.py` owns raw `Program` and `TensorProgram`
builders; `cq.py` owns the command queue and its optional trace arena.
There are no private assembler/device/program/CQ copies in this package.
Firmware comes from the central `firmware/__init__.py`.


Sources: FP8 TTK, the 1B NoC operand-lifetime fix, and the 8B prefill retained-row
unpacker.

`matmul_peak` also uses the shared ISA plus this package's loop templates, NoC and circular
buffer operations, and blocked math/unpack/pack helpers. Those helpers take
explicit scratch registers for schedules that keep values in fixed registers.
The example retains its tiling, multicast schedule, and mailbox initialization.
