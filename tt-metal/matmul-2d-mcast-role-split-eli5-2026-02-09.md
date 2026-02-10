# Matmul 2D mcast role split (ELI5) (2026-02-09)

This note explains the part that is easy to miss when porting TTNN fast matmul:

- The peak path is not "one reader + one writer" for all cores.
- It uses role-specific dataflow kernels assigned to disjoint core subsets.
- Each core still runs one BRISC kernel and one NCRISC kernel at a time.

## Why "4 dataflow kernels" does not contradict "one BRISC/NCRISC per core"

On a Tensix worker core, a launch runs:

- one kernel on `RISCV_0` (BRISC-side dataflow lane),
- one kernel on `RISCV_1` (NCRISC-side dataflow lane),
- one compute kernel on TRISCs.

TTNN creates multiple dataflow kernel handles globally, but each handle is bound to a different core set.

For a single core, exactly one `RISCV_0` role kernel and one `RISCV_1` role kernel apply.

## The 4 dataflow roles in TTNN 2D multicast matmul

In `matmul_multicore_reuse_mcast_2d_program_factory.cpp`, host code partitions cores and assigns:

1. `in0 sender` (A reader + row multicast) on `RISCV_1`
2. `in0 receiver` (A receive/wait) on `RISCV_1`
3. `in1 sender + writer` (B reader + col multicast + output write) on `RISCV_0`
4. `in1 receiver + writer` (B receive/wait + output write) on `RISCV_0`

Compute (`bmm_large_block_zm_fused_bias_activation.cpp`) runs on all working cores.

So "4-kernel split" means 4 role binaries across the grid, not 4 binaries on one core/lane.

## Fast-path timeline (single K-block step)

For each inner-dimension block:

- `in0 sender` cores read A tiles from DRAM into `c_0`, then multicast across row.
- `in0 receiver` cores signal ready, wait on semaphore, then use received `c_0` data.
- `in1 sender` cores read B tiles into `c_1`, then multicast down column.
- `in1 receiver` cores signal ready, wait on semaphore, then use received `c_1` data.
- compute waits on `c_0/c_1`, runs matmul subblocks, packs partial/final tiles.
- writer path is integrated with the in1-side role kernels (`sender+writer` and `receiver+writer`).

## Why this is faster than a generic branchy dataflow kernel

- Fewer cores read DRAM directly (senders do, receivers do not).
- NoC traffic pattern is controlled (row multicast for A, column multicast for B).
- Less per-core branching in hot loops (role logic moves to host partition + role-specific binaries).
- Per-role compile/runtime arg ABI is exact, avoiding semaphore bubbles and deadlocks.

## What blackhole-py runtime must support for parity

To match TTNN fast path behavior, runtime needs:

- multiple dataflow kernel handles per program,
- per-handle core subsets,
- per-handle processor selection (`RISCV_0` vs `RISCV_1`),
- per-handle compile args and defines,
- per-handle, per-core runtime args.

Compute-side tuning (`PACKER_L1_ACC`, block lifecycle) helps, but dataflow role/orchestration parity is the main gap to 170+ TFLOPS.
