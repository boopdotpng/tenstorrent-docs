# Slow Dispatch: What TLB Writes Actually Happen

When `TT_USB=1` (or the CQ firmware isn't available), blackhole-py falls back to **slow dispatch** — the host directly MMIO-writes everything into each worker core's L1 through TLB windows. No prefetch core, no dispatch core, no command queue. Just the host CPU driving the NOC through the PCIe BAR.

## TLB mechanics

A **TLB window** is a 2 MB MMIO region mapped into the host's virtual address space via the `tenstorrent` kernel driver. The driver's `CONFIGURE_TLB` ioctl sets up the NOC routing:

```
NocTlbConfig {
  addr:    u64    # L1 base address (aligned to TLB size)
  x_start: u16    # NOC X start (for mcast: left edge)
  y_start: u16    # NOC Y start (for mcast: top edge)
  x_end:   u16    # NOC X end (for mcast: right edge)
  y_end:   u16    # NOC Y end (for mcast: bottom edge)
  noc:     u8     # NOC 0 or 1
  mcast:   u8     # 0=unicast, 1=multicast
  ordering: u8    # STRICT(2) or RELAXED(0)
}
```

When `mcast=1`, any write to the TLB window hits **every core** in the bounding box `(x_start, y_start)` to `(x_end, y_end)`. This is how one MMIO write can program 60+ cores at once.

Writes use the **uncached (UC) mapping** (`mmap_offset_uc`) to guarantee write ordering. The driver exposes both a write-combining (WC) mapping for bulk data and a UC mapping for ordered control writes.

## The full sequence for one program

Here's what `SlowDevice._run_single()` does for add1, step by step. All writes go through mcast TLB windows configured for the worker core grid.

### Step 1: Reset worker state

```
TLB mcast write -> L1 0x000370 (GO_MSG)
  Rectangle: (1,2)-(7,11)  = 60 cores
  Rectangle: (10,2)-(13,11) = 40 cores
  ... additional rects for remaining workers
  Data: GoMsg { signal = 0xE0 (RESET_READ_PTR_FROM_HOST), master_x=0, master_y=0 }
        + 4 bytes zero padding
  Total: 8 bytes per mcast group
```

This tells each worker's BRISC firmware to reset its internal read pointers. The firmware sees `signal=0xE0` in the GO_MSG mailbox and resets without starting any kernel.

### Step 2: Upload per-core runtime args (RTA)

```
TLB mcast write -> L1 0x0082B0 (KERNEL_CONFIG_BASE)
  Per unique RTA group — cores with identical args are grouped into mcast rectangles.

  For add1: each core gets unique args (different tile offsets), so this typically
  degrades to one mcast write per column, or one per core in the worst case.

  Data per core (24 bytes):
    writer_args:  [dst_buf_addr: u32, tile_offset: u32, n_tiles: u32]
    reader_args:  [src_buf_addr: u32, tile_offset: u32, n_tiles: u32]
    compute_args: [n_tiles: u32]
    (packed contiguously as little-endian u32s)
```

The RTA sits at the base of `KERNEL_CONFIG_BASE`. Each RISC-V core reads its arguments with `get_arg_val<uint32_t>(N)` which indexes into this region.

### Step 3: Upload per-core LaunchMsg

```
TLB mcast write -> L1 0x000070 (LAUNCH = MAILBOX_BASE + 0x10)
  Per unique LaunchMsg group.

  Data: LaunchMsg / KernelConfigMsg (88 bytes):
    kernel_config_base = [0x82B0, 0x82B0, 0x82B0]  (one per ProgrammableCoreType)
    sem_offset = [24, 24, 24]
    local_cb_offset = offset to CB config within KERNEL_CONFIG_BASE region
    local_cb_mask = 0x10001  (bits set for CB 0 and CB 16)
    enables = 0x1F  (all 5 RISCs: BRISC + NCRISC + TRISC0 + TRISC1 + TRISC2)
    mode = DISPATCH_MODE_HOST (1)  <-- NOTE: host mode, not dev mode
    brisc_noc_id = 1
    kernel_text_offset = [brisc_off, ncrisc_off, trisc0_off, trisc1_off, trisc2_off]
```

Key difference from fast dispatch: `mode = DISPATCH_MODE_HOST (1)` tells the firmware that the host will poll for completion (no dispatch core to signal).

### Step 4: Upload shared kernel image

```
TLB mcast write -> L1 0x0082B0 + shared_off (KERNEL_CONFIG_BASE + offset)
  Per unique kernel image group. For add1, all cores run the same kernels,
  so this is one mcast write per rectangle.

  Rectangle: (1,2)-(7,11) = 60 cores
  Rectangle: (10,2)-(13,11) = 40 cores
  ...

  Data (~6 KB):
    [LocalCBConfig[0]:  addr=0x37000, size=4096, pages=2, page_size=2048]
    [LocalCBConfig[16]: addr=0x37800, size=4096, pages=2, page_size=2048]
    [padding to 17 CB slots * 16 bytes]
    [BRISC XIP binary  - writer kernel, ~800 bytes]
    [NCRISC XIP binary - reader kernel, ~900 bytes]
    [TRISC0 XIP binary - unpack, ~600 bytes]
    [TRISC1 XIP binary - math (SFPI add1), ~1200 bytes]
    [TRISC2 XIP binary - pack, ~500 bytes]
```

The kernel binaries are compiled as **XIP (execute-in-place)** — position-independent code relocated to run directly from their L1 address. No loader needed on-device; the firmware just jumps to `kernel_text_offset[proc]`.

### Step 5: Send GO

```
TLB mcast write -> L1 0x000370 (GO_MSG)
  Rectangle: (1,2)-(7,11) = 60 cores
  Rectangle: (10,2)-(13,11) = 40 cores
  ...
  Data: GoMsg { signal = 0x80 (RUN_MSG_GO) }
  Total: 4 bytes per mcast group
```

This is the launch. Every worker's BRISC firmware is spinning on `GO_MSG+3` (the signal byte). When it sees `0x80`:
1. BRISC reads the `LaunchMsg` from L1 0x70
2. BRISC sets up CB pointers from the `local_cb_offset` region
3. BRISC releases NCRISC and TRISCs from reset (they were held since firmware upload)
4. All 5 RISCs jump to their respective `kernel_text_offset` and start executing

### Step 6: Poll for completion

```
For each worker core (x, y):
  TLB unicast read -> L1 0x000373 (GO_MSG + 3, the signal byte)
  Spin until value == 0x00 (RUN_MSG_DONE)
```

When each kernel finishes, the firmware writes `signal = 0x00` back to `GO_MSG+3`. The host polls each core individually. This is the main latency cost of slow dispatch — 118 sequential TLB reads, each a PCIe round-trip.

## Total MMIO traffic

For add1 on 118 cores:

| Step | Write target | Mcast groups | Bytes per group | Total bytes |
|------|-------------|--------------|-----------------|-------------|
| Reset GO_MSG | 0x000370 | ~4 rects | 8 | ~32 |
| RTA | 0x0082B0 | 118 (per-core) | ~28 | ~3.3 KB |
| LaunchMsg | 0x000070 | 1 (uniform) | 88 | ~350 |
| Shared image | 0x0082D0+ | ~4 rects | ~6000 | ~24 KB |
| GO | 0x000370 | ~4 rects | 4 | ~16 |
| **Poll** | 0x000373 | 118 reads | 1 | 118 PCIe reads |

Total write traffic: ~28 KB. Total TLB reconfigurations: ~130 `CONFIGURE_TLB` ioctls.

The bottleneck isn't bandwidth — it's the **latency of TLB reconfigurations** and the **sequential polling loop**. Each `CONFIGURE_TLB` ioctl is a kernel round-trip. The polling loop makes 118 PCIe BAR reads. This is why fast dispatch exists.
