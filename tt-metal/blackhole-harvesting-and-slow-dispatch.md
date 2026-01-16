# Blackhole harvesting + coordinate translation, and what tt-metal does (slow dispatch)

This note answers: what happens with harvested tiles/columns, how translation affects what you see, and why tt-metal’s slow-dispatch path mostly does per-core writes instead of “one big multicast”.

## Key concepts

- **Harvesting**: some tiles/columns/banks are fused off for yield (unavailable endpoints).
- **Coordinate translation**: a hardware NIU feature. When enabled, the `(X,Y)` you program is not raw mesh coords; it is translated via tables that firmware configures.
  - The ISA doc explicitly calls out that translation is used to provide a stable coordinate scheme across harvesting variation.

## What you see on P100A

- P100A has fewer usable Tensix tiles than “full grid”, so in the Tensix region there are always “holes” in the translated coordinate space.
  - The ISA doc describes Tensix at `2 ≤ Y < 12` and notes `X = 15..16` are fused off on P100 (present on P150).

## How tt-metal handles harvesting (high level)

tt-metal relies on UMD’s `SocDescriptor` + coordinate manager to:

- build a **logical** Tensix grid that excludes harvested columns (logical coords are packed)
- build a **translated** coordinate space that matches firmware’s translation behavior, so “harvested columns end up at the max-X side” of the translated grid

Metal itself mostly uses harvesting to choose a smaller logical compute grid configuration:

- It reads `tensix_harvesting_mask`, takes `popcount()`, and selects `unharvested` / `1xharvested` / `2xharvested` core-descriptor config.

## Slow dispatch behavior (host direct writes)

In “slow dispatch” (direct host → device writes through the driver’s MMIO/TLB path):

- tt-metal writes **per core** (unicast), even when the bytes being written are identical across cores.
- It also writes lots of per-core state that is *not identical*:
  - runtime args can vary per tile
  - CB config and launch structures are per tile

So you should not expect “one host multicast uploads everything” in slow dispatch.

## Why this matters for manual NoC/TLB IOCTL work

- If you’re doing your own TLB + multicast rectangles, you must avoid including harvested coordinates in your rectangles, or you risk missing updates or hangs (depending on ordering/completion behavior).
- If you instead do per-core unicast writes (Metal’s slow-dispatch style), you can simply iterate the enabled core list and avoid all missing endpoints.

## Where to look in code

- Metal requires NoC translation tables on Blackhole (`tt_metal/llrt/tt_cluster.cpp`).
- Harvesting mask → product selection (`tt_metal/llrt/core_descriptor.cpp`, `tt_metal/core_descriptors/blackhole_140_arch.yaml`).
- UMD Blackhole coordinate manager (logical/translated mapping + “push harvested columns to max-X”) (`tt_metal/third_party/umd/device/coordinates/blackhole_coordinate_manager.cpp`).
- Slow-dispatch kernel upload is per-core unicast (`tt_metal/impl/kernels/kernel.cpp` → `tt_metal/llrt/llrt.cpp`).
- `WriteRuntimeArgsToDevice` writes per-core runtime args (and “common” args, still per-core in this path) (`tt_metal/tt_metal.cpp`).
