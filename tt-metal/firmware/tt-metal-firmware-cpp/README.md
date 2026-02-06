# tt-metal firmware C++ snapshot

This folder contains a Blackhole-focused copy of firmware C++ sources from `tt-metal/tt_metal/hw/firmware/src/tt-1xx`.

## What is here

- `tt-1xx/brisc.cc`: BRISC worker firmware (orchestrates launches, reset/read-pointer handling, dispatch signaling).
- `tt-1xx/ncrisc.cc`: NCRISC worker firmware (NoC/data-mover side setup + kernel launch path).
- `tt-1xx/trisc.cc`: TRISC worker firmware (math thread synchronization and kernel execution flow).
- `tt-1xx/erisc.cc`, `active_erisc.cc`, `idle_erisc.cc`, `subordinate_erisc.cc`: Ethernet RISC firmware variants.
- `tt-1xx/*k.cc` and `*crt0.cc`: startup/kernel-entry wrappers used to jump into per-launch kernels.
- `tt-1xx/tt_eth_api.cpp`: supporting firmware-side C++ helper.

## How they work together

At a high level, host dispatch writes launch descriptors into L1 mailboxes, then signals workers (`RUN_MSG_GO`).

- BRISC is the central worker-side coordinator on Tensix worker cores.
- BRISC waits for go/reset/replay control messages, manages launch message read pointers, and fans out work.
- NCRISC and TRISC consume the current launch config, set up local/remote resources, then run their kernel payload.
- ERISC variants do the same pattern for Ethernet-facing cores (active routing/data movement vs idle/subordinate roles).
- `*k` firmware files are kernel entry trampolines (single launch execution path), while non-`*k` files are persistent resident loops.

## Main loops (where execution lives)

- BRISC: `tt_metal/hw/firmware/src/tt-1xx/brisc.cc` in `main()` (`while (1)`).
- NCRISC: `tt_metal/hw/firmware/src/tt-1xx/ncrisc.cc` in `main(...)` (`while (1)`).
- TRISC: `tt_metal/hw/firmware/src/tt-1xx/trisc.cc` in `main(...)` (`while (1)`).
- ERISC base routing FW: `tt_metal/hw/firmware/src/tt-1xx/erisc.cc` in `Application()` (`while (routing_info->routing_enabled)`).
- Active/Idle/Subordinate ERISC: each has `main()` with a persistent `while (1)` work loop.

In short: resident firmware loops block on mailbox signals, load launch context, run per-core work, acknowledge completion, and return to wait for the next launch.
