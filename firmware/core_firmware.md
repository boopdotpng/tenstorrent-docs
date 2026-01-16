# Core firmware (Tensix, Blackhole)

## What it is
- Core firmware is the L1-resident code that runs on BRISC/NCRISC/TRISC (and ERISC) cores.
- It brings up NOC access, mailbox/dispatch handling, and the kernel-entry wrappers that let host code launch user kernels.
- It is distinct from your kernels: firmware is the persistent “runtime” for the core, kernels are loaded and run on demand.

## Lifecycle and when to load
- L1 is volatile. After a reset or power cycle, core firmware is not present.
- `tt-metal` loads firmware during device/context initialization, then reuses it for all kernels.
- For a pure-Python driver, the safest approach is to always load firmware at startup; it is not per-kernel and is fast enough to do once per device open.

## Holding Tensix RISCs in reset (during firmware upload)
- When (re)loading firmware, keep BRISC/NCRISC/TRISC0/1/2 in reset while you overwrite their L1 code/data regions.
- On Blackhole, the per-tile soft-reset register is `RISCV_DEBUG_REG_SOFT_RESET_0` at tile-local address `0xFFB121B0`.
- Bits (1 = held in reset):
  - BRISC: `0x00800`
  - TRISC0/1/2: `0x07000`
  - NCRISC: `0x40000`
- Assert all Tensix RISCs: write `0x47800` (or RMW: OR these bits into the current value).
- Deassert: clear those bits (write `0x0` if you want everything running; some bring-up sequences release cores in stages).
- Reference: tt-metal/UMD does a cluster broadcast write of this register (`tt_metal/third_party/umd/device/cluster.cpp`).

## Does it change per kernel or runtime args?
- Firmware is built per architecture and build configuration, not per kernel.
- Runtime arguments do not change the firmware image; they are passed through mailboxes and control structures at run time.
- You can keep one firmware image loaded while compiling and launching many kernels.

## Where it comes from (Blackhole sources)
Firmware sources are open C++ under `tt_metal/hw/firmware/src/tt-1xx/`:
- Core firmware:
  - `tt_metal/hw/firmware/src/tt-1xx/brisc.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/ncrisc.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/trisc.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/active_erisc.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/active_erisc-crt0.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/subordinate_erisc.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/idle_erisc.cc`
- Kernel-entry wrappers (used when launching user kernels):
  - `tt_metal/hw/firmware/src/tt-1xx/brisck.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/ncrisck.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/trisck.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/active_erisck.cc`
  - `tt_metal/hw/firmware/src/tt-1xx/idle_erisck.cc`

## Where the built firmware lives
- The host-side build output is cached under:
  - `~/.cache/tt-metal-cache/<build-key>/firmware/<hash>/`
- This cache is per build configuration and architecture; it is not per kernel.
- The cached files are copied into device L1 at init time; nothing in the cache implies firmware is already on the device.

## Practical note for pure-Python drivers
- Always load firmware after opening the device or after any reset.
- You only need to do this once per device/session; it can stay resident while you compile and launch kernels.
