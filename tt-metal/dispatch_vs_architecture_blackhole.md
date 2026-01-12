# Dispatch paths mapped to Blackhole architecture

This doc connects TT-Metal fast/slow dispatch behavior to the Blackhole hardware model described in
`boop-docs/blackhole-architecture`.

## Architecture refresher (Blackhole)
From `blackhole-architecture/04_programming_model.md` and `02_tensix_tile.md`:
- **Host** (x86/ARM) orchestrates device setup and dispatch.
- Each **Tensix tile** contains:
  - **Brisc/Ncrisc**: NoC/DMA orchestration and control-plane tasks.
  - **Trisc T0/T1/T2**: push Tensix instructions (Unpack/Compute/Pack).
  - **Tensix coprocessor**: Unpack → Compute (Matrix/SFPU/Scalar) → Pack.
- **NoC0/NoC1** are the data-movement fabric (`01_noc.md`).

TT-Metal dispatch decides *how the host tells those RISC-V cores to run*, and how it moves data across NoC.

## Slow dispatch ↔ architecture mapping
**Host behavior**
- `detail::LaunchProgram()` (in `tt_metal/tt_metal.cpp`) is a host-driven flow:
  - compiles kernels
  - writes runtime args
  - configures device
  - writes launch messages directly to cores
  - optionally blocks until cores complete

**Hardware mapping**
- Host directly programs per-core state and triggers execution, aligning with the
  **Host → RISC-V (Brisc/Trisc)** steps in the programming model.
- Brisc/Ncrisc handle NoC/DMA setup for reader/writer kernels.
- Trisc threads push Tensix instructions (SFPI ops execute on SFPU for `TRISC_MATH`).

**Why it is “slow”**
- No command queue overlap; each launch is largely synchronous.
- Host does most of the orchestration work per launch.

## Fast dispatch ↔ architecture mapping
**Host behavior**
- Fast dispatch uses command queues (CQ). The host enqueues work and returns.
- `distributed::MeshCommandQueue` + `EnqueueMeshWorkload()` drive this path.

**Hardware mapping**
- The queue/firmware handles scheduling, so the host stops micromanaging per-program launch.
- Device-side dispatch firmware programs the same **Brisc/Trisc/Tensix** pipeline, but does it
  as a queued sequence rather than immediate host actions.
- Data movement still uses **NoC0/NoC1** transactions described in `01_noc.md`, but the
  scheduling of those DMA transactions is pipelined by the CQ.

**Why it is “fast”**
- Overlaps host IO, NoC DMA, and compute across multiple launches.
- Better throughput for many small programs.
- Required for multi-device workflows (mesh coordination).

## Reader/compute/writer kernels in architectural terms
For the `add1_sfpu` style pipeline:
- **Reader kernel**: Brisc/Ncrisc configure NoC reads; DMA brings tiles from DRAM to L1 (NoC). (`01_noc.md`)
- **Compute kernel**: Trisc threads push Tensix instructions; SFPU adds 1.0 on vectors. (`02_tensix_tile.md` + `03_coprocessor.md`)
- **Writer kernel**: Brisc/Ncrisc configure NoC writes; DMA pushes tiles from L1 to DRAM. (`01_noc.md`)

The dispatch mode only changes *how those kernels are scheduled and launched*, not what they do on hardware.

## Choosing a path for a C ABI
- **Slow dispatch** aligns with a minimal C wrapper and single-device control.
- **Fast dispatch** matches the production architecture (command queues) and scales to mesh/multi-device.

## References
- `boop-docs/blackhole-architecture/01_noc.md`
- `boop-docs/blackhole-architecture/02_tensix_tile.md`
- `boop-docs/blackhole-architecture/04_programming_model.md`
- `boop-docs/tt-metal/dispatch_fast_vs_slow.md`
