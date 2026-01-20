# Pure-py runtime: match TT-metal kernel-config packing (add1 SFPU)

This follows up on `boop-docs/tt-metal/pure-py-vs-tt-metal-kernel-binaries-add1-sfpu.md`:

- `pure-py/codegen.py` can already produce TT-metal-identical packed XIP payloads for `add1_sfpu_single_file.cpp` when given the same firmware symbols + device defines.
- The remaining mismatch that can plausibly cause “kernel never runs / timeout waiting for done” is **where and how the host packs/uploads the kernel config buffer** in L1.

## What TT-metal does (Blackhole, slow-dispatch)

TT-metal packs everything into the kernel-config ring buffer at `TensixL1.KERNEL_CONFIG_BASE`:

- Runtime args (RTA) at offset `0x0`
- “Common” runtime args (CRTA) at offset aligned to 16B (often immediately after RTA; may be size 0)
- Local CB configs at `local_cb_offset`
  - Sized to `max_local_end_index * 16B`, where `max_local_end_index = 32 - clz(local_cb_mask)`
  - For `local_cb_mask = (1<<0)|(1<<16)`, size is `17 * 16B = 0x110`
- Remote CB configs at `remote_cb_offset`
  - Sized to `(32 - min_remote_cb_start_index) * 8B`
  - For `min_remote_cb_start_index = 32`, size is `0`
- Packed kernel images appended next, 16B-aligned

For `add1_sfpu_single_file.cpp` on my board, TT-metal’s `launch_msg` readback showed:

- `kernel_config_base = 0x82b0`
- `local_cb_offset = 0x20`
- `remote_cb_offset = 0x130`
- `kernel_text_offset = [0x130, 0x3b0, 0x610, 0xa10, 0xcb0]` (BRISC, NCRISC, TRISC0, TRISC1, TRISC2)

## What changed in pure-py

`pure-py/device.py` now mirrors TT-metal’s packing rules for the kernel-config buffer:

- Runtime args are written into the start of the kernel-config buffer (instead of fixed offsets like `+0x2400`).
- Local CB configs are packed as `max_local_end_index * sizeof(LocalCBConfig)` starting at the aligned end of the RT args region (instead of `+0x2000`).
- Kernel XIP images are packed sequentially after CB configs with 16B alignment (instead of fixed `+0x0000/+0x0400/+...` slots).
- `LaunchMsg.kernel_config.{local_cb_offset,remote_cb_offset,kernel_text_offset,rta_offset}` are filled to match the packed layout.

This makes `pure-py` upload the kernel payloads to the same L1 addresses TT-metal uses for the same CB mask + kernel sizes.

## Running `add1_sfpu_single_file.cpp` kernels via pure-py

`pure-py/main.py` now embeds the kernel strings from:

- `tt-metal/tt_metal/programming_examples/add1_sfpu/add1_sfpu_single_file.cpp`

It compiles them with `dm_wrapper="tt-metal"` (so BRISC/NCRISC kernels use TT-metal’s `brisck.cc`/`ncrisck.cc` wrappers) and can launch them on one Tensix core.

Safety: it is **compile-only by default**; launching requires `--run`.

Example (physical noc0 core `(1,2)` is TT-metal logical `{0,0}` on Blackhole):

- Compile only:
  - `python pure-py/main.py`
- Compile + run + verify:
  - `python pure-py/main.py --run --verify --core 1,2`

Note: the DRAM buffers are allocated with `page_size = tile_size_bytes` to match `InterleavedAddrGenFast` expectations (TT-metal’s `InterleavedBufferConfig.page_size`).

