# Current blackhole-py runtime

Scope: local checkout inspected September 17, 2026, based on commit
`0ebd556c6c686b18b7b10bc8ea5bd75ea12259dd` with working-tree changes.
[Evidence and source fingerprints](../hardware/behavior-from-tests.md) distinguish
this snapshot from committed upstream code. This page supersedes old blackhole-py
setup and API descriptions; it does not describe TT-Metal's launch ABI.

## From Python to a running worker

| Stage | Source in the sibling checkout | What it owns |
|---|---|---|
| Open device | [pcie.py](../../blackhole-py/pcie.py) | tt-kmd fd, board configuration, host page pinning, TLB allocation/mapping |
| Build firmware | [firmware/__init__.py](../../blackhole-py/firmware/__init__.py) | C compilation, linking, ELF layout validation, flat images |
| Boot | [Device.boot](../../blackhole-py/device.py) | Reset, resident firmware upload, service images, runtime topology, service readiness |
| Emit worker code | [asm.py](../../blackhole-py/asm.py), [ttko](../../blackhole-py/ttko/) | RISC-V and Tensix instruction construction and lowering |
| Describe launch | [Program / GridProgram](../../blackhole-py/program.py) | Images, entry table, parameters, optional L1 initialization, run command |
| Submit commands | [cq.py](../../blackhole-py/cq.py) | Host command queue and command serialization |
| Execute services | [firmware](../../blackhole-py/firmware/) | Prefetch, dispatch, DRAM transfer, and worker control loops |
| Observe completion | [device.py](../../blackhole-py/device.py), [test harness](../../blackhole-py/tests/harness.py) | Completion waits and readback |

The worker entry table, parameter table, resident code arena, and scratch area
are **software allocations in L1**. Their addresses come from
[firmware/consts.py](../../blackhole-py/firmware/consts.py); they are not immutable
chip registers. Do not copy a TT-Metal L1 partition into this runtime.

## The host interface

`PCIDevice` opens a tt-kmd device. `Sysmem` maps host memory and uses `PinPages`
to obtain the device-visible NoC address. `TLBWindow` allocates a 2 MiB window
through the driver's ioctl interface and retargets it to a tile and address.
This implementation does not require detaching the card from tt-kmd for VFIO.

`board_config` checks card type and enabled Tensix/DRAM counts. The supported
layout reserves `(14,2)` for prefetch, `(14,3)` for dispatch, and `(14,4)` for the
DRAM transfer service. The latter is a Tensix service tile, not the separate
GDDR DMA engine on a DRAM RISC. See [grid placement](../hardware/topology.md).

## Worker images and return behavior

`Program` accepts per-core dictionaries keyed by `brisc`, `ncrisc`, `trisc0`,
`trisc1`, and `trisc2`. It fills omitted roles with firmware-return images and
checks image size/alignment when constructing commands. Its command sequence
writes entry addresses, worker images, parameter tables, optional L1 data, then
runs the selected cores. Identical images can share multicast writes.

A worker kernel must return through this firmware's convention. A plain RISC-V
`ret` is not a substitute: see `RETURN_KERNEL` and `Asm.lower`. Raw tests use
these helpers instead of assuming a C call stack.

`GridProgram` places a resident binary in the kernel arena and sends logical
row/column ranks as data. Physical placement and logical ranks are distinct;
columns separated by a harvested or non-worker gap are not consecutive physical
NoC coordinates.

## Build and dispatch are different costs

Firmware C compilation is separate from worker instruction emission. The old
SFPI/LLK C++ compilation flow documented in this folder describes TT-Metal and
an earlier blackhole-py implementation. It is not the current worker build path.

Likewise, kernel device cycles, host submission time, firmware build/boot time,
and host upload/download time are different measurements. A short compute-only
test may exclude all but the first. Put completion waits inside a timed interval
when claiming completed work; the [load-macro experiment](../hardware/behavior-from-tests.md)
shows why enqueue time is insufficient.

## Testing

The [test README](../../blackhole-py/tests/README.md) documents `--bh-hardware`,
`--bh-device`, sequential device use, and the `bh` fixture. The fixture boots
a device and exposes raw L1/DRAM operations and launches. Encoding checks run
offline. Hardware assertions and retained results have narrower scope than an
entire ISA or runtime certification.
