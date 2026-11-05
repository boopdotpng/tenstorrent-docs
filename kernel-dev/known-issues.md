# Known issues and misattributed "hardware bugs"

Several failures were first blamed on the hardware. They were only ever seen
through TT-Metal's compiled kernels (LLK headers, the SFPI GCC toolchain,
program factories) or through an old microbench harness. Blackhole-py now emits
RISC-V and Tensix instructions directly, so check an old claim against a direct
kernel before treating it as silicon behavior.

Real silicon errata are documented in the Blackhole ISA manual
(`tt-isa-documentation/BlackholeA0`). Examples are the SFPU auto-stall cautions
on `SFPMAD`, the `SFPSTOCHRND` bias, and `NOC_CMD_L1_ACC_AT_EN`, which cannot be
used safely. The `/isa` page shows these as caveats. Treat everything else as
software until a direct kernel reproduces it.

## Packer L1 accumulation with IEEE Float16: TT-Metal compiler bug

**Status: not a hardware bug.** This was a bug in TT-Metal's compiled kernel
path. Writing the RISC-V kernels directly fixed it.

The old observation used `matmul_peak` compiled through TT-Metal/LLK with
`PACKER_L1_ACC` and a Float16 (5-bit exponent) partials buffer. It had all
three of these:

- a matmul feeding Dst;
- two or more subblocks per L1 accumulation cycle;
- an IEEE Float16 intermediate buffer.

Under those conditions, data-dependent elements came out as all-ones NaN
(`0x7fff` / `0xffff`). For a given input the NaN was deterministic. The same
data with Float16_b, or with the spill-and-reload path, was clean.

The original report argued that the cause was hardware because the Float16 and
Float16_b disassembly differed only in format constants. That argument was
wrong. Equal opcodes do not prove the toolchain programmed a correct packer and
unpacker configuration sequence for that format. Direct kernels set this
configuration explicitly.

TT-Metal never uses Float16 for an L1-accumulated intermediate buffer:
`interm0_data_format` is Float16_b or Float32 whenever `packer_l1_acc_en` is set.
So nothing upstream exercised the broken path.

Consequences:

- Do not reject Float16 L1 accumulation as a hardware rule in planners or ttk.
- `tests/movement/packer/test_l1_accumulation.py` only parametrizes F32 and
  BF16. Adding `u.FP16` there is the regression test for this case.

## Other claims corrected in this pass

| Old claim | Where it came from | What direct kernels show |
|---|---|---|
| `MOVA2D` hangs, so avoid it; `MOVD2B` needs a pause | An old `dsl.py` microbench ([xmov bench](../timing/evidence/historical/xmov-microbench.md)) | Used routinely: `tests/compute/fpu/test_dst_bandwidth.py`, `tests/compute/sfpu/test_argmax.py`, `test_max_tree.py`, `test_sum_finish.py`, `test_rmsnorm_reduce.py` |
| SrcA, SrcB and Dst are not RISC-addressable | Old bench plan | Wrong. The manual (`Dst.md`, "RISCV access to Dst") maps Dst at `0xFFBD8000` for T0–T2. No blackhole-py test reads Dst from RISC yet. |
| NCRISC reads and atomics never complete while BRISC writes | One harness using Metal's command-buffer ownership layout | [DRAM traffic patterns](../measurements/dram-traffic-patterns.md) runs BRISC and NCRISC concurrently with a separate command buffer and TID per RISC. Sharing one command buffer and TID corrupts commands, which is a software error. |
| Tilize "times out" or is missing | Old microbench status | `tests/probes/test_bf16_tilize.py` (unpacker tilize), `tests/movement/unpacker/test_unpack_row_major.py` (row-major gather) |
| Blackhole has no fused tilize+matmul; inline writes are emulated; `fast_tilize` falls back | TT-Metal/LLK source policy | The [row-major matmul](../matmul/results/row-major-peak.md) gathers row-major input in the unpacker. `ttko/noc.py` issues native inline writes, posted by default. |
| Inline NoC writes must be non-posted (a "BH hardware bug") | TT-Metal `risc_attribs.h` | TT-Metal's own comment says they *may hang under back-pressure*. That is a vendor report of an intermittent hang, not a rule. Blackhole-py's posted inline writes pass `test_remote_cb.py`, but that does not rule out the back-pressure case. |
| Treat BRISC writes as one-wide | Metal command-buffer convention | A software convention, not an NIU limit |

## Still unverified

These rest only on vendor software or on Wormhole documentation. Test them
before depending on them either way.

- **`TRNSPSRCA` "not functional", and `CONV3`/`POOL3` "neutered".** The source is
  LLK annotations. There is no Blackhole manual page and no direct test.
- **`SHIFTXA` bug, TDMA ParameterCredits stall.** Wormhole B0 manual text,
  carried over to Blackhole.
- **FP16-source `GMPOOL` into FP32 Dst.** This is a strict xfail in
  `tests/compute/fpu/test_arithmetic_slots.py`. It was seen in one direct
  configuration; a format/config setup error has not been ruled out. Native
  FP16-Dst `GMPOOL` is untested.
- **ERISC:** BH-55 status polling, "cannot receive multicasts", and the
  3072-NOP delay come only from TT-Metal. Blackhole-py has no ERISC tests.

FP8 E4M3 subnormals failing through unpack/pack *is* seen in direct kernels;
see [FP8 and FP4](../hardware/fp8-and-fp4.md).
