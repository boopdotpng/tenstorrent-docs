# Mapping tinygrad UOps to Blackhole P100A/P150

This document maps tinygrad commit `4234a9d72` to the Blackhole execution model.
The conclusion is simple: reuse tinygrad's Tensor graph, callification,
dependency scheduling, and much of rangeify, but do **not** pretend a Tensix
program is a GPU kernel with a funny string renderer.

Current tinygrad master contains no Tenstorrent device or renderer. This is a
design map, not a claim that `Device["TT"]` works today.

## Why Blackhole is not just another GPU renderer

A conventional tinygrad GPU kernel becomes one source/binary function launched
over global and local work-item dimensions. The function performs scalar/vector
loads, ALU, optional warp matrix instructions, barriers, and stores.

A useful Blackhole program is a coordinated package:

```text
host schedule CALL
  └─ Blackhole program
       ├─ core-grid assignment and per-core runtime args
       ├─ DRAM/tile-layout description
       ├─ per-core L1 circular-buffer allocation
       ├─ BRISC reader/dataflow binary
       ├─ NCRISC writer/dataflow binary
       ├─ TRISC0 unpack-control binary
       ├─ TRISC1 math-control binary
       ├─ TRISC2 pack-control binary
       ├─ Tensix/SFPU configuration and instruction streams
       └─ NoC routes, multicast rectangles, semaphores, and dispatch metadata
```

Data normally flows:

```text
DRAM --NoC/reader--> L1 circular buffer
     --unpack--> Src/Dst registers
     --FPU or SFPU--> Dst registers
     --pack--> output circular buffer in L1
     --NoC/writer--> DRAM
```

`SPECIAL(gidx/lidx)` does not describe that division of work. A GPU `WMMA`
describes warp fragments, not the Tensix unpack → MVMUL → pack protocol. GPU
"local memory" is not automatically a Blackhole circular buffer with producer /
consumer semaphore semantics.

## Which tinygrad stages transfer cleanly

| tinygrad stage | Reuse? | Blackhole interpretation |
|---|---|---|
| Tensor methods and raw UOp DAG | Yes | Device-independent math, movement, reduction, dtype, and model structure. |
| Autograd / `FUNCTION` / `CALL` | Yes | Independent of the execution architecture. Function-level graphs are also the last place to recognize attention, RMSNorm, or a fused MLP before kernel splitting. |
| Callify | Mostly | Explicit buffers, params, effects, and cacheable call bodies remain valuable. Layout/tilization may require TT-specific materialization rules. |
| Rangeify | Mostly | Explicit ranges and address maps are a strong basis for correctness and edge masks. A TT planner should reinterpret them in 32×32 tile and core-grid units rather than immediately scalarizing them. |
| Kernel splitting and dependency schedule | Yes | Scheduled `CALL`s map naturally to device programs, copies, and views. `AFTER` dependencies map to dispatch ordering and buffer lifetimes. |
| Global memory planning | With constraints | Arena reuse is useful, but allocations need tile/page alignment, DRAM bank/interleave policy, and persistent-layout metadata. |
| Generic postrange optimization | Selectively | Algebra/range simplification helps. GPU global/local/upcast/thread choices and warp tensor-core selection do not directly map. |
| Reduction removal, GPU dims, devectorization | Usually no | These erase the tile/reduction intent a Tensix planner needs and introduce GPU launch assumptions. |
| Target renderer and final linearizer | Replace for device programs | A Blackhole program is multiple cooperating binaries and launch metadata, not one scalar instruction stream. Individual RISC-V/SFPU subprograms may still have their own instruction ordering. |
| Runtime `CALL` execution | Reuse interface, custom implementation | The runtime must allocate tiled buffers, build/upload the program package, submit it, synchronize, and expose timing. |

The best generic handoff is therefore the **rangeified kernel `SINK` produced by
`get_kernel_graph`**, before `full_rewrite_to_sink` removes reductions and adds
GPU dimensions.

For large semantic fusions there is a second, earlier handoff: the callified
function graph before `split_kernels`. Tinygrad's ordinary scheduler is free to
split `q @ k.T`, softmax, and `probs @ v`; waiting until per-kernel codegen makes
whole-attention recognition impossible.

## Recommended two-level lowering

### Level 1: recognize optional semantic programs

At the callified Tensor/function graph, match only patterns whose Blackhole
implementation materially benefits from owning several ordinary kernels:

- tiled matmul plus SFPU epilogue;
- RMSNorm or LayerNorm;
- stable softmax;
- QK → softmax → PV attention;
- KV-cache update plus indexed read;
- tilize/untilize/layout conversion;
- collective or multicast forms.

Turn a recognized region into an opaque `CALL`/`CUSTOM_FUNCTION` or tagged
program-plan node with a correctness fallback. This should be conservative:
shape, dtype, layout, mask, and alias constraints belong in the match, not in a
hopeful runtime assertion.

### Level 2: lower one rangeified kernel

For everything else, consume `CALL(SINK(KernelInfo), buffers...)` at the compile
seam in `engine/realize.py::pm_compile`. Instead of calling the ordinary
`to_program(ast, renderer)` pipeline, a TT compiler should:

1. classify the kernel as elementwise, reduction, matmul, copy/layout, or
   unsupported;
2. convert scalar shapes/indexes to tiled domains and edge masks;
3. choose a core grid from the exact device topology;
4. partition tiles among cores;
5. plan DRAM placement and NoC movement;
6. allocate L1 circular buffers and choose page counts;
7. synthesize reader, compute, and writer programs plus runtime arguments;
8. compile/cache each sub-binary and package it as one tinygrad `PROGRAM`-like
   executable object;
9. fall back or report a precise unsupported constraint.

The interception can be a device-specific branch in `pm_compile`, a generalized
device compiler hook, or an earlier rewrite to a runtime `CUSTOM_FUNCTION`.
Whichever API is chosen, keep the schedule-level contract: one `CALL` owns its
buffer arguments and returns an executable unit.

Using a normal `Renderer.render(list[UOp])` can still be a productive **bring-up
shortcut** for simple elementwise SFPU. It is the wrong permanent boundary for
matmul, reduction, layout, NoC, and multicore planning because by then generic
codegen has erased or distorted those semantics.

### Relationship to `blackhole-py/TTIR.md`

The tile-native design in the sibling `blackhole-py/TTIR.md` is a strong
concrete version of this handoff:

```text
pre-schedule tinygrad UOps
  -> tile-valued SSA + Tensor layout metadata + Stream queues
  -> schedule / engine assignment / synchronization insertion
  -> five coordinated RISC-V programs
```

Its most useful distinctions are a 32×32 `Tile` computation atom, a tiled
storage `Tensor`, and a `Stream` whose producer/consumer semantics lower to a
circular buffer. It also separates FIFO tile flow from non-queue waits and
models persistent Tensix configuration as state. Those are exactly the concepts
that generic GPU `LOAD`/`BARRIER`/`WMMA` lack.

The status line matters: TTIR is currently a **written specification/design
prototype**, not implemented lowering. Treat it as the target architecture for
experiments, not a library already available to the backend.

Two details have drifted from current tinygrad/hardware. Current rangeified
kernel `SINK`s still preserve `REDUCE` and reduction-of-products matmul intent,
so they are viable for primitive bring-up; the earlier graph is needed for
whole softmax/RMSNorm/attention and movement/layout fusion. Also, TTIR's example
default of eight DRAM banks cannot be universal: P100A normally exposes seven,
so the runtime board description must supply it.

## UOp-to-Blackhole mapping

This table maps intent, not a one-to-one instruction selection.

| UOps / structure | Blackhole lowering |
|---|---|
| `BUFFER`, buffer `PARAM`, `SLICE` | DRAM/sysmem allocation or view plus dtype, tile layout, page size, interleave/bank placement, and address. A local `BUFFER` becomes L1/CB planning, not a cache allocation. |
| `CALL`, schedule `LINEAR`, `AFTER` | Device program submissions and their RAW/WAR/order dependencies. The outer scheduler can remain generic. |
| `COPY` | Host↔DRAM DMA, DRAM↔DRAM/NoC movement, or an explicit tilize/untilize program depending on source/destination layout. |
| `RESHAPE`, `PERMUTE`, `EXPAND`, `SHRINK`, `PAD`, `FLIP` | Prefer metadata/address transforms. Materialize only if the chosen tile layout or kernel requires it. Rangeify's index formulas define correctness. |
| `RANGE`, `INDEX` | Logical tile coordinate, element-within-tile coordinate, core assignment, DRAM page, and NoC address. Scalar floor-div/mod often exposes exactly the tile/face decomposition to recover. |
| `LOAD`, `STORE` | At program scope: reader/writer DMA and CB push/pop. Inside an SFPU expression: unpacked `Dst`/local vector lane access. Do not emit one NoC operation per scalar UOp. |
| `STAGE` | Candidate DRAM or L1 materialization. A TT-specific planner should preserve enough information to turn local stages into CBs with lifetimes and semaphore protocol. |
| `ADD`, `MUL`, comparisons, `WHERE`, casts, transcendental ops | SFPU vector program over 32-lane chunks, ideally fused while values remain in `Dst`. Some simple operations can use FPU/packer features. Unsupported math needs approximations with accuracy tests. |
| `MULACC` | SFPU FMA for vector work, or part of an FPU matrix pipeline when recognized as matmul. Context decides. |
| `REDUCE(ADD/MAX/MUL)` | Tile-local SFPU/FPU reduction plus staged cross-tile and possibly cross-core reduction. Keep it semantic long enough to choose the hierarchy. |
| `WMMA` | Evidence of shaped matrix intent, but **not** a directly compatible primitive. Translate shape/dtype/layout to a Tensix MVMUL program or use a TT-specific tile-matmul plan. |
| `BARRIER`, `WAIT`, `AFTER` | CB producer/consumer semaphores, Tensix synchronization, NoC completion, or command-queue timeline ordering. Their scopes differ and must be modeled explicitly. |
| `SPECIAL` | Usually discard/reinterpret. Blackhole needs core coordinates, role, tile span, and runtime args rather than GPU group/local IDs. |
| shaped `STACK`/`INDEX` plus codegen `RESHAPE`/`PERMUTE`/`EXPAND` | Generic lane expansion and unbroadcasting artifacts in current codegen. Prefer lowering before this scalar-shaped expansion. An SFPU subcompiler can introduce a tile-native lane representation instead. |
| `PROGRAM` | A Blackhole executable bundle with multiple code images, CB/core-grid/dataflow metadata, and launch args. Current tinygrad still stores one `BINARY` bytes object, so the backend must serialize/package those images into that payload or deliberately extend the container contract. |
| `SOURCE`, `BINARY`, `INS` | Source and binary artifacts can exist per BRISC/NCRISC/TRISC program. `INS` may suit an eventual direct RISC-V/Tensix assembler, but current source compilation need not force all components into one `LINEAR`. |

## Elementwise, reduction, and matmul are different backends

### Elementwise

The easiest first compute path is whole-tile elementwise SFPU:

```text
reader(s): DRAM tiles -> input CBs
unpack:     CBs -> Dst/Src
TRISC1:     fused ALU expression over Dst lanes
pack:       Dst -> output CB
writer:     output CB -> DRAM
```

Fuse as much ALU as register pressure and SFPU control allow. Standalone SFPU
kernels are useful for correctness and memory-bound work, but repeated
unpack/pack/DRAM round trips will make a chain of tiny elementwise kernels poor.

### Reduction

Do not wait for `pm_reduce_local` to turn a reduction into register
accumulators and horizontal trees.
Plan a hierarchy:

1. reduce within a face/tile;
2. reduce across tiles assigned to one core;
3. reduce across cores through NoC, multicast, or staged DRAM if needed;
4. apply the epilogue, such as reciprocal for a mean or normalization.

Padding validity and identity values (`0`, `-inf`, `1`) must agree with the
original rangeified predicates.

### Matmul

Recognize the reduction-of-products or preserved matmul shape before generic
WMMA/GPU lowering. The plan must choose:

- 32×32 tile counts for M/N/K and edge padding;
- block sizes and Dst accumulation mode;
- math fidelity and input/accumulator/output formats;
- one-core versus 1D/2D multicore partition;
- reader/writer roles and CB depths;
- NoC0/NoC1 traffic and multicast rectangles;
- whether an SFPU epilogue can run before packing.

This is scheduling and dataflow synthesis, not a single `WMMA` string template.

## P100A versus P150 belongs in device topology

The frontend UOp graph should not care which board is present. The runtime and
planner should expose a `DeviceProperties`/topology object and make all launch
decisions from it.

| Property | P100A | P150 | Compiler consequence |
|---|---:|---:|---|
| Physical Tensix cores | 120 | 140 | Different available core grids and partition choices. |
| Fast-dispatch worker cores in the local documented layout | 118 | 138 | Never hardcode a worker count in the renderer; reserve the actual prefetch/dispatch cores returned by the runtime. |
| Tensix columns × rows | 12 × 10 | 14 × 10 | Multicast rectangles and optimal matmul grids differ. P100A has two fewer east-band columns. |
| Enabled DRAM | 7 banks / 28 GiB | 8 banks / 32 GiB | Interleave, bank-coordinate tables, allocation capacity, and bandwidth model differ. |
| Active Ethernet/fabric | none exposed for P100A product | P150 has active links/ERISC resources | Single-card compute can ignore this initially; multi-card collectives and remote dispatch cannot. |

Yield harvesting and reserved service cores can further alter usable topology.
Query it at device open. A plan cache key must include the relevant topology,
board revision, dtype/layout, and compiler/firmware versions.

The P100A fast-dispatch grid also has a practical notch: its two reserved cores
make all 118 workers an awkward non-rectangle, so the existing tuned matmul uses
a clean 10×11 (110-core) rectangle. A generic "number of cores" field cannot
express that; the planner needs coordinates and rectangle constraints.

See [device-grid details](../hardware/blackhole-emulator-specs/device-grid.md),
[grid utilization](../hardware/grid-utilization.md), and
[the Tensix dataflow model](../kernel-dev/dataflow-and-cbs.md).

## A staged implementation boundary

```text
tinygrad current master                 Blackhole-specific side
-----------------------                 -----------------------
Tensor / FUNCTION graph       ────────> optional semantic fusion matcher
callify + rangeify            ────────> TT kernel classifier and tile planner
schedule LINEAR + memory plan ────────> TT executable calls and tiled allocations
                                          │
                                          ├─ core/grid + NoC plan
                                          ├─ CB/L1 plan
                                          ├─ reader/writer generation
                                          ├─ SFPU/FPU compute generation
                                          └─ program package + runtime dispatch
```

Start with a fallback-capable elementwise path, but make the plan object rich
enough that reduction and matmul do not require replacing the interface. The
[patch-project ladder](patch-projects.md) turns this architecture into bounded
learning projects.
