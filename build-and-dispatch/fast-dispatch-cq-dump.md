# Fast Dispatch CQ Command Stream

What actually gets sent over PCIe when you run a single kernel on Blackhole P100A with fast dispatch enabled.

The example is `add1.py` — a reader/compute/writer pipeline across all 118 dispatchable worker cores. The kernel reads BF16 tiles from DRAM, adds 1.0 via SFPI, and writes them back. One program, one `device.run()`.

## How commands reach the device

The host writes dispatch commands into a **host sysmem hugepage** (128 MB, pinned for NOC DMA). Each dispatch command is wrapped in a **prefetch envelope** (`RELAY_INLINE`, cmd_id=5) that tells the prefetch core how many bytes to pull:

```
Host sysmem layout:
  [0x100..0x100+64M)   Issue queue (dispatch commands, padded to 64B)
  [64M+0x100..96M+0x100) Completion queue (host events written by dispatch)

Prefetch queue (on-device L1 at 0x19840):
  1534 x 2-byte entries, each = record_size >> 4
  Prefetch BRISC polls these, DMA-reads the record from sysmem,
  forwards the inner dispatch payload to dispatch core's CB.
```

Each record in the issue queue:

```
 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15  16 ...
[   CQPrefetchCmd (16 bytes)                    ] [dispatch payload (variable)]
 ^cmd_id=5      ^inner_length     ^stride
                (RELAY_INLINE)
```

## The command stream for add1

Below is the exact sequence of dispatch commands built by `_enqueue_program_setup()`, `_enqueue_program_dispatch()`, and `enqueue_host_event()` for a single add1 program on 118 cores. The dispatch core on NOC coordinates `(14, 3)` processes these in order.

```
[ 0] SET_GO_SIGNAL_NOC_DATA (cmd_id=17)
     Load 118 unicast NOC destinations for GO signal:
       (1,2), (1,3), (1,4), (1,5), (1,6), (1,7), (1,8), (1,9), (1,10), (1,11),
       (2,2), (2,3), (2,4), (2,5), (2,6), (2,7), (2,8), (2,9), (2,10), (2,11),
       (3,2), (3,3), ... (7,11),
       (10,2), (10,3), ... (13,11),
       ... all 118 worker cores (columns 1-7, 10-13; rows 2-11)
     Purpose: preloads the NOC XY word list that SEND_GO_SIGNAL will iterate.

[ 1] WRITE_PACKED_LARGE (cmd_id=6)
     mcast (1,2)-(7,11) -> GO_MSG  (4 bytes, 60 cores)
     mcast (10,2)-(13,11) -> GO_MSG  (4 bytes, 40 cores)
     mcast (14,2)-(14,2) -> GO_MSG  (4 bytes, 1 core)    [dispatch-col straggler]
     ... additional 1x1 rects for cores sharing column 14 with dispatch
     Payload: GoMsg { signal=0xE0 (RESET_READ_PTR_FROM_HOST) }
     Purpose: resets each worker's kernel read pointer state for the new launch.

[ 2] WRITE_PACKED_LARGE (cmd_id=6)
     mcast (1,2)-(7,11) -> GO_MSG_INDEX  (4 bytes, 60 cores)
     mcast (10,2)-(13,11) -> GO_MSG_INDEX  (4 bytes, 40 cores)
     ...
     Payload: 0x00000000
     Purpose: zeroes the go message index on all workers.

[ 3] WRITE_PACKED (cmd_id=5)
     118 cores, per-core, 12 bytes -> KERNEL_CONFIG_BASE (0x0082B0)
     cores: (1,2), (1,3), (1,4), (1,5), (1,6), (1,7), ... +112 more
     Payload per core: runtime args (3x u32):
       Writer: [dst_buf_addr, tile_offset, n_tiles]
       Reader: [src_buf_addr, tile_offset, n_tiles]
       Compute: [n_tiles]
     Purpose: each core gets its own tile offset/count for the data-parallel split.

[ 4] WRITE_PACKED (cmd_id=5)
     118 cores, per-core, 88 bytes -> LAUNCH (0x000070)
     Payload per core: LaunchMsg (KernelConfigMsg):
       kernel_config_base = [0x82B0, 0x82B0, 0x82B0]
       sem_offset = [24, 24, 24]
       local_cb_offset, remote_cb_offset = CB offsets
       local_cb_mask = 0x10001 (CB 0 + CB 16)
       enables = 0x1F (BRISC + NCRISC + TRISC0 + TRISC1 + TRISC2)
       kernel_text_offset = [off_brisc, off_ncrisc, off_trisc0, off_trisc1, off_trisc2]
       mode = DISPATCH_MODE_DEV (0)
       brisc_noc_id = 1
     Purpose: tells firmware where to find the kernel images and CB config in L1.

[ 5] WRITE_PACKED_LARGE (cmd_id=6)
     mcast (1,2)-(7,11) -> KERNEL_CONFIG_BASE+0x20  (~6000 bytes, 60 cores)
     mcast (10,2)-(13,11) -> KERNEL_CONFIG_BASE+0x20  (~6000 bytes, 40 cores)
     ...
     Payload: shared kernel image blob:
       [CB config: LocalCBConfig[0] + LocalCBConfig[16] + padding]
       [BRISC XIP binary  (~800 bytes)]
       [NCRISC XIP binary (~900 bytes)]
       [TRISC0 XIP binary (~600 bytes)]
       [TRISC1 XIP binary (~1200 bytes)]
       [TRISC2 XIP binary (~500 bytes)]
     Purpose: uploads the actual compiled kernel code to all cores at once via mcast.
     This is the largest command — contains all 5 RISC-V kernel binaries.

[ 6] TIMESTAMP (cmd_id=18)
     -> DRAM tile (0,1) addr=<alloc>
     Purpose: captures dispatch-side timestamp before kernel launch (pre-GO).

[ 7] WAIT (cmd_id=7)
     wait+clear stream=48 count=0
     Purpose: drain any pending completions from a previous run.
     Stream 48 is the worker completion semaphore.

[ 8] SEND_GO_SIGNAL (cmd_id=14)
     signal=0x80 (RUN_MSG_GO) master=(14,3) unicast_txns=118
     Purpose: dispatch iterates the NOC data list (loaded in cmd 0) and sends
     a GO word to each of the 118 worker cores. Each core's BRISC firmware sees
     GO, releases NCRISC/TRISCs, and they start executing the uploaded kernel.

[ 9] TIMESTAMP (cmd_id=18)
     -> DRAM tile (0,1) addr=<alloc+16>
     Purpose: captures dispatch-side timestamp after GO (post-dispatch).
     Cycle delta [6]-[9] = dispatch overhead; [9]-completion = compute time.

[10] WAIT (cmd_id=7)
     wait+clear stream=48 count=118
     Purpose: dispatch blocks until all 118 worker cores have written their
     completion notification to stream 48. Each core increments the stream
     counter when its kernel finishes.

[11] WRITE_LINEAR_H_HOST (cmd_id=3)
     host_event  event_id=1
     Purpose: dispatch writes event_id=1 into the host sysmem completion queue.
     Host is polling HOST_COMPLETION_Q_WR_OFF (byte 128 in sysmem) and sees
     the write pointer advance, confirming all kernels are done.
```

## Command size summary

| Command | Inner size (approx) | Description |
|---------|-------------------|-------------|
| SET_GO_SIGNAL_NOC_DATA | 16 + 118*4 = 488 B | NOC XY list |
| WRITE_PACKED_LARGE (reset) | 16 + subs + 4*N | GO_MSG reset |
| WRITE_PACKED_LARGE (index) | 16 + subs + 4*N | GO_MSG_INDEX zero |
| WRITE_PACKED (RTA) | 16 + 118*4 + 118*16 = ~2.4 KB | per-core runtime args |
| WRITE_PACKED (launch) | 16 + 118*4 + 118*96 = ~12 KB | per-core LaunchMsg |
| WRITE_PACKED_LARGE (shared) | 16 + subs + ~6 KB*N | shared kernel images |
| TIMESTAMP | 16 B | pre/post dispatch timing |
| WAIT | 16 B | stream synchronization |
| SEND_GO_SIGNAL | 16 B | the actual launch |
| WRITE_LINEAR_H_HOST | 32 B | host completion event |

Total CQ stream for add1: ~30-40 KB per program invocation (dominated by the shared kernel image upload).

## Host-side completion polling

After `flush()` writes all records into sysmem and pokes the prefetch queue entries, the host enters a tight poll loop:

```python
while True:
    wr_16b, wr_toggle = self._read_completion_wr_ptr()
    # dispatch writes completion_wr_ptr when it processes WRITE_LINEAR_H_HOST
    if (wr_16b != self._completion_rd_16b) or (wr_toggle != self._completion_rd_toggle):
        event_id = self._read_completion_event_id()
        self._pop_completion_page()
        return  # done!
    time.sleep(0.0002)
```

The full cycle: host writes issue queue -> prefetch DMA-reads from sysmem -> forwards to dispatch CB -> dispatch executes commands -> workers run kernel -> workers signal stream 48 -> dispatch writes host event -> host sees completion.
