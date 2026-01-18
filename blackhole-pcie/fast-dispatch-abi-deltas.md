# Fast dispatch ABI deltas / concrete constants (Blackhole)

This note captures a few concrete ABI details that matter for a pure-Python fast-dispatch prototype, and that are easy to get wrong when reading older notes.

## Alignments (Blackhole)

- `L1_ALIGNMENT = 16` bytes (`NOC_L1_{READ,WRITE}_ALIGNMENT_BYTES`)
- `PCIE_ALIGNMENT = 64` bytes (`NOC_PCIE_READ_ALIGNMENT_BYTES = 64`, write is 16, so max is 64)

## Host CQ control area layout (sysmem)

`CommandQueueHostAddrType` offsets are `type * PCIE_ALIGNMENT` (`dispatch_mem_map.cpp:get_host_command_queue_addr`):

- `ISSUE_Q_RD = 0x00`
- `ISSUE_Q_WR = 0x40`
- `COMPLETION_Q_WR = 0x80`
- `COMPLETION_Q_RD = 0xC0`
- `UNRESERVED (issue data start) = 0x100`

These differ from “16B spaced” notes; on Blackhole it’s 64B spaced.

## Device CQ control area layout (prefetch core L1)

`DispatchSettings::with_alignment()` makes most device CQ “registers” 16B-spaced (except `PREFETCH_Q_PCIE_RD`, which lives in the padding after the 4B `PREFETCH_Q_RD` pointer).

Relative to `DEFAULT_UNRESERVED` (Tensix L1 base for CQ structures):

- `PREFETCH_Q_RD_PTR_OFF = 0x00` (4B)
- `PREFETCH_Q_PCIE_RD_PTR_OFF = 0x04` (4B, lives in the 12B padding up to 0x10)
- `COMPLETION_Q_WR_PTR_OFF = 0x10`
- `COMPLETION_Q_RD_PTR_OFF = 0x20`
- `COMPLETION_Q0_LAST_EVENT_PTR_OFF = 0x30`
- `COMPLETION_Q1_LAST_EVENT_PTR_OFF = 0x40`
- `DISPATCH_S_SYNC_SEM_OFF = 0x50` (8 entries * 16B = 0x80 bytes)
- `FABRIC_HEADER_RB_OFF = 0xD0` (currently 1 entry * 128B)
- `FABRIC_SYNC_STATUS_OFF = 0x150` (4B)
- `UNRESERVED_OFF = 0x180` (aligned up to `PCIE_ALIGNMENT = 64`)

The `UNRESERVED` base is where `PREFETCH_Q` (the ring of `uint16_t` sizes) starts. Older notes that place `PREFETCH_Q` at `+0x100` predate the fabric header/sync fields and/or the 64B alignment at `UNRESERVED`.

## Where these come from

- Device offsets / alignment rules: `tt-metal/tt_metal/impl/dispatch/dispatch_settings.hpp`, `tt-metal/tt_metal/impl/dispatch/util/dispatch_settings.cpp`, `tt-metal/tt_metal/impl/dispatch/dispatch_mem_map.cpp`
- `DEFAULT_UNRESERVED` base for Blackhole Tensix: `tt-metal/tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp` (computed from `MEM_MAP_END + 69KB`, aligned)
- PCIe alignment and `NOC_XY_PCIE_ENCODING`: `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h`

## How NoC write bytes are packed (conceptual)

The “issue queue” is a byte FIFO in pinned sysmem. The device-side prefetcher DMA-reads a chunk (size is given by a `uint16` entry in `PREFETCH_Q`) and interprets it as a sequence of packed CQ commands (little-endian), with records typically advanced in `PCIE_ALIGNMENT = 64B` increments.

### Single unicast write (inline payload)

To write raw bytes to a single tile’s local address space, tt-metal emits:

1. A prefetch command that says “relay the next payload bytes to the dispatcher”:
   - `CQPrefetchCmd{ cmd_id = CQ_PREFETCH_CMD_RELAY_INLINE, relay_inline.length = payload_size, relay_inline.stride = align(16 + payload_size, 64) }`
2. Payload bytes of length `payload_size` that begin with a dispatch write command, followed immediately by raw data bytes:
   - `CQDispatchCmdLarge{ cmd_id = CQ_DISPATCH_CMD_WRITE_LINEAR, write_linear.noc_xy_addr = (y<<6)|x, write_linear.addr = dst_addr, write_linear.length = N }`
   - `N` bytes of raw data
3. Padding up to the next 64B boundary.

So the stream looks like:

```
[CQPrefetchCmd 16B: RELAY_INLINE, length=32+N, stride=align(16+(32+N),64)]
[CQDispatchCmdLarge 32B: WRITE_LINEAR, noc_xy_addr=(y<<6)|x, addr=dst, length=N]
[data bytes N]
[pad to 64B]
```

This is the conceptual equivalent of `pure-py/device.py`’s `upload_firmware()` TLB writes, except the NoC fanout is performed by the dispatcher core on-device rather than the host opening/configuring many TLB windows.

### Relevant defs in tt-metal

- Prefetch relay-inline fields (`dispatcher_type`, `length`, `stride`): `tt-metal/tt_metal/impl/dispatch/kernels/cq_commands.hpp`
- Dispatch linear write fields (`noc_xy_addr`, `addr`, `length`): `tt-metal/tt_metal/impl/dispatch/kernels/cq_commands.hpp`
- Packing/stride alignment behavior: `tt-metal/tt_metal/impl/dispatch/device_command.cpp`
