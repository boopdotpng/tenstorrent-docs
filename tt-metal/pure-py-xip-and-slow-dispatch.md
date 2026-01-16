# pure-py notes: XIP, binaries, slow dispatch, DRAM access

This is a quick bridge between `pure-py` bringup and the relevant `tt-metal` runtime behavior.

## Are all needed addresses in `pure-py/configs.py`?

No.

`pure-py/configs.py` has a useful subset (Blackhole L1 base layout, some MMIO addresses, ARC tags, DRAM bank tile coords).
For host-side *kernel dispatch* you also need:

- Kernel-config region base (`MEM_MAP_END` in tt-metal’s `dev_mem_map.h`). This is where CB configs, runtime args, and (for XIP) kernel text are placed.
- Mailbox layout inside L1 (offsets of `launch`, `go_messages`, `launch_msg_rd_ptr`, `go_message_index`).
- The run-state values (`RUN_MSG_GO`, `RUN_MSG_DONE`, etc.).

In tt-metal these are not hardcoded as raw offsets sprinkled around the code; they come from:
- Arch mem-map (`tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h`)
- Device-message structs (`tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h`) and generated accessors (`tt-metal/tt_metal/llrt/hal/generated/dev_msgs.hpp`)
- HAL mapping of “LAUNCH/GO_MSG/KERNEL_CONFIG” to concrete L1 addresses (`tt-metal/tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp`)

## What “XIP” means in tt-metal

In tt-metal, kernels are commonly loaded with `ll_api::memory::Loading::CONTIGUOUS_XIP`.

- `tt-metal/tt_metal/llrt/tt_memory.cpp` applies XIP behavior when loading a kernel ELF.
- `ElfFile::MakeExecuteInPlace()` (currently) sets the text segment’s execution address to 0 (`tt-metal/tt_metal/llrt/tt_elffile.cpp` → `XIPify()`).
- The loader then *packs PT_LOAD segments contiguously* into one blob and writes it into the per-core kernel-config region.

The practical consequence: you write the kernel text once (contiguous) and point the firmware at it via `kernel_text_offset`.

### Python replication

In `pure-py`, you can mirror the important part as:

1) Parse ELF PT_LOAD segments
2) 4B-pad each segment
3) Concatenate in ELF order
4) Upload the blob contiguously into L1 at the kernel-text destination

(`pure-py/helpers.py:pack_xip_elf()` is a minimal helper for the packing.)

## Do binaries vary per tile?

- Across many Tensix tiles: usually the *same* binaries are uploaded to each participating tile.
- Within a tile: binaries differ per processor slot.
  - Data-movement: BRISC vs NCRISC
  - Compute: TRISC0/TRISC1/TRISC2 are distinct binaries (tt-metal compiles the same compute source 3 times with per-core-type code sections).

See `tt-metal/METALIUM_GUIDE.md` for the “one source → three TRISC binaries” explanation.

## Slow-dispatch: CB setup, start, poll completion

Think in four host steps (per core / per kernel-group):

1) **Write CB config** into the kernel-config region (`kernel_config_base + cb_offset`).
   - CB config format is a packed `uint32_t[]` with 4 words per local CB index.
   - tt-metal reference: `tt-metal/tt_metal/tt_metal.cpp` (CB config packing/writes) and `tt-metal/tt_metal/impl/program/dispatch.cpp` (`finalize_cbs()`).

2) **Write runtime args** into the kernel-config region (`kernel_config_base + rta_offset`).

3) **Write launch message** (`launch_msg_t`) into L1 mailbox `LAUNCH`.
   - `tt-metal/tt_metal/llrt/llrt.cpp:write_launch_msg_to_core()`

4) **Write go message** (`go_msg_t`) into `GO_MSG` with `signal = RUN_MSG_GO`.

Polling:
- Read `GO_MSG.signal` until it becomes `RUN_MSG_DONE`.
  - tt-metal’s polling helper is `tt-metal/tt_metal/llrt/llrt.cpp` (`wait_until_cores_done`).

## DRAM (“global memory”) access from kernels

Kernels don’t dereference DRAM directly; they issue NoC reads/writes.

### Best pattern: `TensorAccessor`

Use `TensorAccessor` + `noc_async_read_tile` / `noc_async_write_tile`.
This hides bank interleaving and addressing.

- Example: `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp` (reader/writer kernels embedded as strings).
- Also described in `tt-metal/docs/source/tt-metalium/tt_metal/examples/dram_loopback.rst`.

### Manual pattern (striped/interleaved)

If you don’t use `TensorAccessor`, the canonical striping is:

- `bank = page_id % num_banks`
- `offset_in_bank = (page_id / num_banks) * page_size + in_page_offset`
- `noc_addr = get_noc_addr_from_bank_id<true>(bank, base + offset_in_bank)`

Then issue `noc_async_read/write(...)`.

## Handling tails when size isn’t evenly bank-divisible

Interleaving is by pages/tiles.

- If `num_pages` (or `num_tiles`) isn’t divisible by `num_banks`, the last few banks naturally get one fewer page.
- If you operate on raw bytes, handle the last transfer as either:
  - padded to a full page, or
  - a short transfer guarded by a `remaining_bytes` runtime arg.

## pure-py notes

- `pure-py/dram.py` should select exactly one DRAM tile per bank; each bank has multiple NoC endpoints exposing the same 4 GiB.
