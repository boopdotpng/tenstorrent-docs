# Small Transfer Optimization: DMA vs Kernel Launch

## Problem

blackhole-py launches a full NCRISC kernel through the CQ dispatch pipeline for every `dram_write` / `dram_read`, even for tiny tensors. The minimum round-trip latency is ~500us+ regardless of data size.

## Current blackhole-py transfer path (fast dispatch)

For every `dram_write` or `dram_read`:

1. **Python** (`device.py:353-384`): build IR, compile kernel (cached), pack CQ commands, write to issue ring
2. **Prefetch core**: NOC-reads command records from host sysmem into L1
3. **Dispatch core**: NOC-writes RTAs + kernel binary + GO signal to worker cores
4. **Worker NCRISC kernels** (`dram.py:56-115`): per-tile serial `noc_async_read` -> barrier -> `noc_async_write_tile` -> barrier, bouncing through a 2-tile L1 CB
5. **Host** (`cq.py:302-322`): polls completion ring with `time.sleep(0.0002)` (200us)

### Where the time goes for a small transfer

| Phase | Latency | Notes |
|-------|---------|-------|
| Python IR/CQ generation | ~100-500us | `build_ir` + struct packing + `_lower_ir` |
| CQ flush (5-7 PCIe MMIO writes) | ~50-100us | Each `_issue_write` is a TLBWindow write through BAR0 |
| Device prefetch -> dispatch -> GO chain | ~10-50us | Three NOC hops before any worker starts |
| `wait_completion` poll granularity | ~200us minimum | `time.sleep(0.0002)` in the poll loop |
| **Total minimum** | **~500us+** | Same whether moving 2 KB or 2 MB |

For large transfers (MBs), this overhead is amortized and multi-core parallelism gives ~10+ GB/s. For small tensors it dominates completely.

## BAR2 PCIe DMA Read Channel (RDCH_0)

Blackhole has a hardware DMA engine in the PCIe controller, accessible through BAR2 uncached registers. It does **H2D only** (D2H explicitly throws).

### Registers (BAR2 offsets)

| Register | Offset | Purpose |
|----------|--------|---------|
| `EN_OFF_RDCH_0` | 0x100 | Enable the channel |
| `DOORBELL_OFF_RDCH_0` | 0x104 | Ring to start transfer |
| `XFERSIZE_OFF_RDCH_0` | 0x11C | Transfer size; polled for completion (reads 0 when done) |
| `SAR_LOW/HIGH` | 0x120/0x124 | Source address (host physical) |
| `DAR_LOW/HIGH` | 0x128/0x12C | Destination address (device AXI, 32-bit) |
| `INT_SETUP_OFF_RDCH_0` | 0x188 | Interrupt config (local + remote stop) |
| `MSI_STOP_LOW/HIGH` | 0x190/0x194 | MSI completion write address |
| `MSI_ABORT_LOW/HIGH` | 0x1A0/0x1A4 | MSI abort write address |
| `MSI_MSGD_OFF_RDCH_0` | 0x1A8 | MSI message data |

### Transfer flow

```
memcpy data to DMA buffer
  -> write INT_SETUP (0x28)
  -> write MSI_STOP addr (completion_pa)
  -> write MSI_ABORT addr
  -> write EN (0x1)
  -> write SAR_LOW/HIGH (host physical)
  -> write DAR_LOW/HIGH (device AXI)
  -> write XFERSIZE
  -> write DOORBELL (0x1)
  -> poll XFERSIZE until 0
```

Reference implementation: `blackhole_dma_transfer.cpp` in tt-umd, used by `blackhole_tt_device.cpp:dma_h2d_transfer()`.

### Comparison with kernel-based transfers

| | BAR2 DMA (RDCH_0) | Kernel-based (current) |
|---|---|---|
| Direction | H2D only (D2H throws) | Both directions |
| Parallelism | Single channel, serialized | Multi-core, parallel across DRAM banks |
| Destination | Raw 32-bit AXI address | Interleaved DRAM via `InterleavedAddrGenFast` |
| Large transfer BW | Limited by single channel | Scales with core count, ~10+ GB/s |
| Small transfer latency | ~10-50us | ~500us+ |
| Host CPU involvement | Busy-polls XFERSIZE | Sleeps 200us per poll |
| Bank interleaving | Must split on host side | Handled by NCRISC kernel |

The AXI address limitation matters: for interleaved DRAM buffers, the host would need to compute per-bank physical addresses and issue separate DMA transfers per bank.

## Optimization options for small tensors

### Option 1: Direct BAR TLB writes for small H2D (easiest win)

blackhole-py already has a slow-dispatch path (`dram.py:145-205`, the `Allocator` class) that writes directly through BAR4 4 GiB TLB windows. Posted PCIe writes give ~2.5 GB/s with zero kernel launch overhead.

For a 4 KB tensor: ~1.6us of PCIe write time + Python overhead.

Implementation: add a size threshold in `dram_write`. Below some cutoff (e.g., 64 KB), bypass the CQ and write directly through the existing TLB window path. Requires handling DRAM bank interleaving on the host side.

**Limitation**: H2D only. BAR reads for D2H are ~0.03 GB/s (non-posted PCIe), so this doesn't help for `dram_read`.

### Option 2: Resident DMA service core (best general solution)

Instead of compiling and dispatching a fill/drain kernel per transfer, keep a **resident NCRISC kernel** on one dedicated core that polls an L1 mailbox for commands.

Transfer flow:

```
Host writes {src_addr, dst_addr, size, direction} to core's L1 mailbox via TLB (1 PCIe MMIO write)
  -> Resident kernel sees command, does NOC transfer (both directions)
  -> Resident kernel writes completion flag to sysmem
  -> Host polls sysmem (local RAM read, no PCIe)
```

Advantages:
- Eliminates entire CQ pipeline for data movement
- Works in both H2D and D2H directions
- Handles interleaved DRAM natively (kernel has `InterleavedAddrGenFast`)
- Round-trip: ~10-50us for small transfers
- Can coexist with the kernel-based path for large transfers

The mailbox write is a single PCIe posted write (~40ns). The completion poll reads local pinned memory (no PCIe round-trip). The dominant latency is the NOC transfer itself.

### Option 3: Batch small transfers into CQ command stream

Instead of calling `run()` per transfer, accumulate multiple small writes as `CQWritePackedLarge` commands targeting DRAM addresses directly, and flush once. This amortizes the dispatch overhead across many tensors.

This doesn't reduce single-transfer latency but helps when many small tensors need to be written in sequence (e.g., loading model weights).

### Option 4: BAR2 DMA RDCH_0 for small H2D

Use the hardware DMA channel directly from Python (mmap BAR2, program registers). Skips the entire software stack.

Advantages:
- Lowest possible H2D latency (~10-50us)
- No kernel, no CQ, no firmware involvement
- Hardware handles the PCIe DMA; host just programs registers and polls

Disadvantages:
- H2D only
- Single channel (contention if used concurrently with UMD)
- Must handle DRAM bank interleaving on host side
- 4-byte alignment required on both address and size
- 10-second timeout on busy-poll (could be tightened)

## Recommended approach

For maximum impact with minimum complexity:

1. **Immediate**: Use direct BAR TLB writes for small H2D (option 1). The code path exists; just add a size-based dispatch in `dram_write`.
2. **Short term**: Implement a resident DMA service core (option 2). This solves both directions and is the right long-term architecture for low-latency data movement.
3. **Keep kernel path**: Continue using multi-core kernel dispatch for large transfers where throughput matters more than latency.
4. **BAR2 DMA**: Consider for the tightest possible H2D latency if the resident core approach isn't fast enough, but it's single-direction and adds complexity around bank interleaving.
