# Dispatch Kernel Pipeline Internals

Complete catalog of every dispatch kernel in tt-metal, how they connect, the CQ command protocol, and the multi-chip dispatch flow. This covers the firmware that turns host command queue entries into kernel launches on Tensix workers.

See also: `dispatch-modes.md` for fast vs slow dispatch overview, `fabric-and-topology-internals.md` for the ethernet fabric layer underneath.

## Dispatch Kernel Types

All dispatch kernels are compiled from three source files with different `#define` flags:

| Source | Variants |
|--------|----------|
| `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` | PREFETCH_HD, PREFETCH_H, PREFETCH_D |
| `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` | DISPATCH_HD, DISPATCH_H, DISPATCH_D |
| `tt_metal/impl/dispatch/kernels/cq_dispatch_subordinate.cpp` | DISPATCH_S |
| `tt_metal/fabric/impl/kernels/tt_fabric_mux.cpp` | FABRIC_MUX, RETURN_FABRIC_MUX |

The variant is selected by compile-time flags:

| Type | IS_H_VARIANT | IS_D_VARIANT |
|------|:---:|:---:|
| PREFETCH_HD | 1 | 1 |
| PREFETCH_H | 1 | 0 |
| PREFETCH_D | 0 | 1 |
| DISPATCH_HD | 1 | 1 |
| DISPATCH_H | 1 | 0 |
| DISPATCH_D | 0 | 1 |

### Core type assignment

All dispatch kernels run on **Tensix** (WORKER) or **idle ETH** cores, selected by `DispatchCoreConfig`:

```cpp
enum class DispatchCoreType : uint32_t { WORKER, ETH, COUNT };
```

When `ETH` is selected, dispatch kernels run on idle (non-routing) ethernet cores compiled with `Eth::IDLE`. This is used on N300/T3000 where idle ETH cores are plentiful.

**Active ERISC cores** (running the fabric router `fabric_erisc_router.cpp`) are never used for dispatch. They are `CoreType::ACTIVE_ETH` with `Eth::SENDER` mode, completely separate from the dispatch pipeline.

## Per-Kernel Reference

### PREFETCH_HD — Single-chip combined prefetcher

**Runs on:** MMIO card only. Tensix or idle ETH.

**What it does:** Reads CQ commands from the host via PCIe. The host writes commands into a pinned sysmem ring buffer (hugepage), then pokes 16-bit size tokens into the prefetch core's L1 queue (`PREFETCH_Q_BASE`). PREFETCH_HD reads the size, DMA-reads that many bytes from sysmem, and feeds them into the downstream dispatch ring buffer.

**Data sources:**
- Host PrefetchQ (16-bit size tokens at `CQ_PREFETCH_Q_BASE`)
- Host issue ring buffer (actual command bytes, read via PCIe DMA)
- Local DRAM (for `RELAY_LINEAR`, `RELAY_PAGED` commands that fetch from device DRAM)

**Outputs:**
- Dispatch CB ring buffer → DISPATCH_HD
- `dispatch_s_buffer` → DISPATCH_S (go-signal-related commands, routed by `dispatcher_type` field)

**Semaphore protocol:** Two semaphores with DISPATCH: `page_ready` (prefetcher increments) and `page_done` (dispatcher increments when consumed).

---

### PREFETCH_H — MMIO-side prefetcher for remote chips

**Runs on:** MMIO card. Tensix or idle ETH. One instance per remote card.

**What it does:** Same command reading as PREFETCH_HD, but instead of feeding a local dispatcher, forwards command pages over the TT-Fabric to the remote card's PREFETCH_D. Uses `CQRelayClient` / `WorkerToFabricMuxSender` to write into FABRIC_MUX.

**Inputs:** Host PrefetchQ + issue ring buffer (same as HD). Local DRAM for DRAM-backed commands.

**Outputs:** Via FABRIC_MUX → ethernet → remote chip's PREFETCH_D cmddat queue.

**Special command:** `CQ_PREFETCH_CMD_RELAY_LINEAR_H` must be the only command in a fetchq entry. Reads from an MMIO-chip NOC address and relays directly to remote.

---

### PREFETCH_D — Remote-chip receiver

**Runs on:** Remote (non-MMIO) card. Tensix or idle ETH.

**What it does:** Receives command pages from PREFETCH_H via the fabric. The ERISC router on the local chip writes directly into PREFETCH_D's L1 cmddat buffer via NOC 1 (zero-copy). PREFETCH_D polls its upstream semaphore, reads commands, and feeds local DISPATCH_D and DISPATCH_S.

**Inputs:** L1 cmddat buffer, filled by ERISC. Remote chip's DRAM for paged reads.

**Outputs:**
- Dispatch CB → DISPATCH_D (all worker-write commands)
- `dispatch_s_buffer` → DISPATCH_S (go-signal commands, routed by `dispatcher_type` field in `CQPrefetchRelayInlineCmd`)

---

### DISPATCH_HD — Single-chip combined dispatcher

**Runs on:** MMIO card only. Tensix or idle ETH.

**What it does:** The main command interpreter. Reads command pages from PREFETCH_HD's ring buffer. For each command, issues the appropriate NOC writes: kernel binaries to worker L1, runtime args, semaphore configs, CB configs. Writes completions back to host sysmem via PCIe.

**NOC assignment:** NOC1 for upstream (receiving from prefetcher), NOC0 for downstream (worker writes, host completion writes). This split is mandatory because DISPATCH_D and DISPATCH_S can co-locate on the same core with conflicting NOC usage.

**Inputs:** Dispatch CB ring buffer from PREFETCH_HD.

**Outputs:**
- NOC writes to worker Tensix/ETH L1 (binaries, kernel configs, RTAs, semaphores)
- PCIe writes to host completion queue (events, readback data)
- GO signal multicast/unicast to workers (when not using distributed DISPATCH_S)

---

### DISPATCH_H — MMIO-side return handler

**Runs on:** MMIO card. Tensix or idle ETH.

**What it does:** Receives completion data back from the remote chip's DISPATCH_D (via RETURN_FABRIC_MUX → ethernet → local ERISC). Writes it to the host completion queue via PCIe. Also signals PREFETCH_H when the remote card is ready for more commands (exec-buf-end notification).

**Inputs:** Data pages from RETURN_FABRIC_MUX via `CQRelayClient`.

**Outputs:** PCIe writes to host completion queue. NOC semaphore increment to PREFETCH_H.

**Key point:** DISPATCH_H does NOT do any worker writes. All worker writes happen on the remote chip by DISPATCH_D.

---

### DISPATCH_D — Remote-chip dispatcher

**Runs on:** Remote card. Tensix or idle ETH.

**What it does:** Same command interpreter as DISPATCH_HD. Receives pages from PREFETCH_D. Issues all worker-targeted writes locally on the remote chip. For host-bound data (completion events, readback), relays through RETURN_FABRIC_MUX → ethernet → DISPATCH_H → host PCIe.

**NOC assignment:** NOC1 upstream, NOC0 downstream (same split as HD).

**Inputs:** Dispatch CB from PREFETCH_D.

**Outputs:**
- NOC writes to remote chip's worker L1
- GO signal multicast/unicast (when not using distributed DISPATCH_S)
- Host-return data via RETURN_FABRIC_MUX

---

### DISPATCH_S — Subordinate dispatcher (GO signal specialist)

**Runs on:** Same chip as its paired DISPATCH_D (or DISPATCH_HD). Can share the same physical Tensix core (DISPATCH_D on NCRISC, DISPATCH_S on BRISC) or run on a separate core (`distributed_dispatcher=1`).

**What it does:** One job: send GO signals to workers and wait for them to finish. This decouples go-signal latency from command processing, allowing DISPATCH_D to start queuing the next program while DISPATCH_S waits for the current one to complete. This is the key dispatch latency overlap optimization.

**Command set (only 5 commands):**

| Command | Purpose |
|---------|---------|
| `CQ_DISPATCH_CMD_SEND_GO_SIGNAL` | Multicast + unicast GO to all workers. Wait for completion count. |
| `CQ_DISPATCH_CMD_WAIT` | Wait for workers to complete and reset stream counter (distributed mode only). |
| `CQ_DISPATCH_SET_NUM_WORKER_SEMS` | Set number of worker semaphores in use. |
| `CQ_DISPATCH_SET_GO_SIGNAL_NOC_DATA` | Populate NOC XY table for unicast go signals. |
| `CQ_DISPATCH_CMD_TERMINATE` | Shutdown. |

**Worker completion mechanism:** Workers atomically increment `STREAM_REMOTE_DEST_BUF_SPACE_AVAILABLE_REG_INDEX` on DISPATCH_S (or DISPATCH_D in non-distributed mode) via NOC. DISPATCH_S polls this stream register. In distributed mode, it mirrors the count to DISPATCH_D's stream register.

**NOC allocation (when co-located with DISPATCH_D):**
- Cmd Buf 0: regular writes (DISPATCH_S)
- Cmd Buf 1: small inline writes (DISPATCH_S)
- Cmd Buf 2: atomics (DISPATCH_S)
- Cmd Buf 3: reserved for DISPATCH_D

**Inputs:** `dispatch_s_buffer` ring filled by PREFETCH_D (or PREFETCH_HD).

**Outputs:** NOC multicast to `mcast_go_signal_addr` on all worker cores. NOC unicast to active ETH cores. Stream register updates to DISPATCH_D.

---

### FABRIC_MUX — Host-to-device multiplexer

**Runs on:** MMIO card. Tensix or idle ETH.

**What it does:** Aggregates command traffic from multiple PREFETCH_H instances and forwards to the ERISC fabric router sender channels. Bridges the dispatch pipeline's "worker interface" to the persistent TT-Fabric ethernet infrastructure.

**Channel types:**
- **Full-size channels**: one per upstream PREFETCH_H. Carries complete command+data payloads.
- **Header-only channels**: one per downstream DISPATCH_H. Carries flow control signals.

**Inputs:** NOC writes from PREFETCH_H workers via `WorkerToFabricMuxSender`.

**Outputs:** Feeds the ERISC sender channel L1 buffer on the MMIO chip.

---

### RETURN_FABRIC_MUX — Device-to-host return multiplexer

**Runs on:** Remote card. Tensix or idle ETH. Same source (`tt_fabric_mux.cpp`), instantiated with `d2h_=true`.

**What it does:** Reverse-direction mux. Aggregates completion data from DISPATCH_D (full-size channels) and coordination headers from PREFETCH_D (header-only), sends over ethernet back to DISPATCH_H on the MMIO card.

**Inputs:** DISPATCH_D relay writes (full-size). PREFETCH_D exec-buf-end headers.

**Outputs:** Feeds ERISC sender channel for return-path ethernet transmission.

## Topology Graphs

Static dispatch topology tables live in `tt_metal/impl/dispatch/topology.cpp`. Node format: `{id, device_id, servicing_device_id, cq_id, kernel_type, [upstream_ids], [downstream_ids], noc_selection}`.

### Single chip, 1 CQ

```
PREFETCH_HD(0) ──dispatch_cb──→ DISPATCH_HD(1)
PREFETCH_HD(0) ──dispatch_s_buf──→ DISPATCH_S(2)
DISPATCH_S(2) ──sync_sem──→ DISPATCH_HD(1)
```

3 cores consumed.

### Two-chip, 1 CQ (N300/T3000 with fabric)

```
MMIO chip (device 0):
  PREFETCH_HD(0) → DISPATCH_HD(1) ← DISPATCH_S(2)     [local CQ]
  PREFETCH_H(3) → FABRIC_MUX(5)                         [to remote]
  DISPATCH_H(4) ← FABRIC_MUX(5)                         [from remote]

         ↕ ethernet (fabric EDM) ↕

Remote chip (device 1):
  PREFETCH_D(6) → DISPATCH_D(7) ← DISPATCH_S(8)        [remote CQ]
  PREFETCH_D(6) → RETURN_FABRIC_MUX(9)                  [to host]
  DISPATCH_D(7) → RETURN_FABRIC_MUX(9)                  [to host]
```

MMIO card: 3 (local) + 2 (PREFETCH_H + DISPATCH_H) + 1 (FABRIC_MUX) = 6 cores.
Remote card: 3 (PREFETCH_D + DISPATCH_D + DISPATCH_S) + 1 (RETURN_FABRIC_MUX) = 4 cores.

### Galaxy (9-chip, 1 CQ)

MMIO chip has up to 2 FABRIC_MUX instances (one per ethernet tunnel), each serving 4 remote chips. Each FABRIC_MUX has 4 full-size channels (one per PREFETCH_H) and 4 header-only channels (one per DISPATCH_H). Each remote chip has the standard 4-kernel quad.

MMIO card: 3 (local) + 8 (PREFETCH_H) + 8 (DISPATCH_H) + 2 (FABRIC_MUX) = ~21 cores.
Each remote card: 4 cores.

## CQ Command Protocol

### Prefetch commands (processed by PREFETCH_*)

| Opcode | ID | Description |
|--------|----|-------------|
| `RELAY_LINEAR` | 1 | Read linear data from NOC address, relay to downstream CB |
| `RELAY_LINEAR_H` | 2 | H-variant relay; must be sole command in fetchq entry |
| `RELAY_PAGED` | 3 | Read banked/paged data from DRAM or L1, relay to downstream |
| `RELAY_PAGED_PACKED` | 4 | Multiple paged reads from different banks |
| `RELAY_INLINE` | 5 | Copy data from CmdDatQ directly to downstream (+ optional dispatch_s channel) |
| `RELAY_INLINE_NOFLUSH` | 6 | Like RELAY_INLINE but don't flush the page yet |
| `EXEC_BUF` | 7 | Execute commands from a DRAM-backed exec buffer (trace replay) |
| `EXEC_BUF_END` | 8 | Finish exec_buf, signal completion |
| `STALL` | 9 | Drain the pipe through dispatcher (barrier) |
| `DEBUG` | 10 | Watcher/checksum logging |
| `TERMINATE` | 11 | Shutdown |
| `PAGED_TO_RINGBUFFER` | 12 | Copy paged DRAM data into local ringbuffer (trace) |
| `SET_RINGBUFFER_OFFSET` | 13 | Set read/write offset in ringbuffer |
| `RELAY_RINGBUFFER` | 14 | Relay data from ringbuffer to downstream (trace replay) |

`RELAY_INLINE` has a `dispatcher_type` field: `DISPATCH_MASTER=0` routes to DISPATCH_D's CB, `DISPATCH_SUBORDINATE=1` routes to DISPATCH_S's buffer.

### Dispatch commands (processed by DISPATCH_D / DISPATCH_HD)

| Opcode | ID | Description |
|--------|----|-------------|
| `WRITE_LINEAR` | 1 | NOC unicast/multicast write to worker L1 |
| `WRITE_LINEAR_H` | 2 | Linear write targeted at H-variant (passthrough) |
| `WRITE_LINEAR_H_HOST` | 3 | Write to host completion queue; D-variant relays through return fabric |
| `WRITE_PAGED` | 4 | Banked/paged write to DRAM or L1 |
| `WRITE_PACKED` | 5 | Write same data to multiple unicast/multicast NOC addresses |
| `WRITE_PACKED_LARGE` | 6 | Variable-size payloads per sub-command |
| `WAIT` | 7 | Barrier + optional wait on L1 or stream register |
| `SINK` | 8 | Data sink (testing only) |
| `DEBUG` | 9 | Watcher/checksum logging |
| `DELAY` | 10 | Spin delay (testing only) |
| `EXEC_BUF_END` | 11 | Notify PREFETCH_H of exec_buf completion |
| `SET_WRITE_OFFSET` | 12 | Set relocation offsets (up to 4) for all non-host writes |
| `TERMINATE` | 13 | Shutdown |
| `SEND_GO_SIGNAL` | 14 | Multicast + unicast GO to workers |
| `NOTIFY_SUBORDINATE_GO_SIGNAL` | 15 | D → S: "safe to send GO now" (increment sync counter) |
| `SET_NUM_WORKER_SEMS` | 16 | Set number of active worker semaphores |
| `SET_GO_SIGNAL_NOC_DATA` | 17 | Populate NOC XY table for unicast GO signals |
| `TIMESTAMP` | 18 | Write 64-bit cycle counter to DRAM |

## GO Signal and Launch Message Protocol

The launch/GO mechanism is how programs start executing on worker cores.

### Launch message

`launch_msg_t` is written to each worker core's mailbox ring buffer (8 entries at `dev_msgs.mailboxes.launch[]`) via `CQ_DISPATCH_CMD_WRITE_PACKED` with type `PACKED_WRITE_FLAG_TYPE_LAUNCH`. Contains:

- Kernel text offsets within L1 (per-RISC: BRISC, NCRISC, TRISC0/1/2)
- Semaphore offsets
- CB layout configuration
- RTA (runtime args) offsets
- Enables bitmask (which RISCs participate)
- NOC ID
- Dispatch mode flag
- Host-assigned program ID

### GO signal

A single 32-bit `go_msg_t` containing `{dispatch_message_offset, master_x, master_y, signal}`. Signal values:

| Value | Name | Meaning |
|-------|------|---------|
| `0x00` | `RUN_MSG_DONE` | Worker completed, back to idle |
| `0x80` | `RUN_MSG_GO` | Start executing the program in the launch message |
| `0xE0` | `RUN_MSG_RESET_READ_PTR_FROM_HOST` | Reset mailbox read pointer |

### GO signal flow

1. DISPATCH writes `RESET_READ_PTR_FROM_HOST` to all worker `GO_MSG` addresses.
2. DISPATCH writes `GO_MSG_INDEX` (which slot in the 8-entry ring to read).
3. DISPATCH writes `launch_msg_t` to the correct ring slot on each worker.
4. DISPATCH writes kernel binary + CB config into worker L1.
5. DISPATCH issues `CQ_DISPATCH_CMD_SEND_GO_SIGNAL` → multicasts `RUN_MSG_GO` to all workers.
6. BRISC firmware on each worker sees `RUN_MSG_GO`, reads `launch_msg_t`, deasserts NCRISC/TRISCs from reset, loads kernel text, jumps in.
7. On completion, BRISC writes `RUN_MSG_DONE` back and atomically increments DISPATCH_S's stream register.

### Distributed DISPATCH_S flow

When DISPATCH_S is on a separate core from DISPATCH_D:

1. DISPATCH_D processes `NOTIFY_SUBORDINATE_GO_SIGNAL` → increments sync semaphore on DISPATCH_S.
2. DISPATCH_D continues immediately (can start queuing next program).
3. DISPATCH_S waits for sync semaphore, then multicasts GO.
4. DISPATCH_S waits for worker completion count on stream register.
5. DISPATCH_S mirrors completion count to DISPATCH_D's stream register via `noc_inline_dw_write`.

## What blackhole-py Uses Today

blackhole-py at `~/tenstorrent/blackhole-py/` implements both dispatch modes for a single card.

### Slow dispatch (`TT_USB=1`)

Pure host-driven. No firmware intermediary. Direct L1 writes via `TLBWindow`:

```
1. TLBWindow.write(GO_MSG, RESET_READ_PTR_FROM_HOST)   # multicast
2. TLBWindow.write(GO_MSG_INDEX, 0)                      # multicast
3. TLBWindow.write(KERNEL_CONFIG_BASE, runtime_args)     # per-core or multicast
4. TLBWindow.write(LAUNCH, launch_msg)                   # multicast
5. TLBWindow.write(shared_addr, kernel_elf_blob)         # multicast
6. TLBWindow.write(GO_MSG, RUN_MSG_GO)                   # multicast
7. poll GO_MSG+3 until RUN_MSG_DONE                      # per-core read
```

`TLBWindow` is a kernel-managed NOC TLB entry: `_ioctl_alloc_tlb` → `mmap` BAR (both UC and WC) → `_ioctl_config_tlb` to point at NOC (x,y) target. CPU writes to the mmap'd region become NOC write transactions.

### Fast dispatch (default)

Two reserved cores: **prefetch** on (14,2) and **dispatch + dispatch_s** on (14,3).

Host writes CQ commands into a 64MB pinned sysmem ring buffer (`mmap(MAP_SHARED|MAP_ANONYMOUS|MAP_POPULATE)`, pinned with `_ioctl_pin_pages` for NOC DMA). The prefetch core reads via PCIe DMA.

Per-program command sequence emitted by `cq.py`:

| Step | Python class | Dispatch cmd | What it does |
|------|-------------|-------------|--------------|
| 1 | `CQWritePacked` | `WRITE_PACKED` | Write `RESET_READ_PTR` to all worker `GO_MSG` |
| 2 | `CQWritePacked` | `WRITE_PACKED` | Zero `GO_MSG_INDEX` on all workers |
| 3 | `CQWritePacked` / `CQWritePackedLarge` | `WRITE_PACKED` / `WRITE_PACKED_LARGE` | Write runtime args to `KERNEL_CONFIG_BASE` |
| 4 | `CQWritePacked` | `WRITE_PACKED` | Write `LaunchMsg` to each worker |
| 5 | `CQWritePackedLarge` | `WRITE_PACKED_LARGE` | Write shared blob (CB config + kernel XIP text) |
| 6 | `CQSetGoSignalNocData` | `SET_GO_SIGNAL_NOC_DATA` | Push worker NOC XY list into dispatch L1 |
| 7 | `CQWaitStream` | `WAIT` | Clear stream 48 (worker-done counter) |
| 8 | `CQSendGoSignal` | `SEND_GO_SIGNAL` | Multicast GO to all workers |
| 9 | `CQWaitStream` | `WAIT` | Wait for all N workers to complete |
| 10 | `CQHostEvent` | `WRITE_LINEAR_H_HOST` | Write event ID to host completion ring |

Each command is wrapped in a `CQ_PREFETCH_CMD_RELAY_INLINE` (id=5) envelope with a 16-byte prefetch header.

### Firmware loading

`Device._upload_firmware()` at construction:

1. Assert soft reset on all workers (multicast `SOFT_RESET_ALL=0x47800`).
2. Write firmware segments (brisc/ncrisc/trisc0/1/2 ELF text) into each core's L1.
3. Write bootstrap JMP at L1 address 0 → `BRISC_FIRMWARE_BASE` (0x3840).
4. Write `RUN_MSG_INIT` to `GO_MSG`.
5. Deassert BRISC reset (`SOFT_RESET_BRISC_ONLY_RUN=0x47000`).
6. Poll `GO_MSG+3` until `RUN_MSG_DONE` (firmware initialized).

For fast dispatch, additionally upload `prefetch_brisc` to (14,2) and `dispatch_brisc`+`dispatch_s_ncrisc` to (14,3), write their `LaunchMsg`, and send GO.

## Multi-Chip Dispatch Flow (End-to-End)

Complete path for launching a kernel on a remote (non-PCIe) card:

```
 1. Host CPU writes CQ commands into pinned sysmem (hugepage)
 2. Host pokes 16-bit size token into PREFETCH_H's L1 queue
 3. PREFETCH_H DMA-reads commands from sysmem via PCIe
 4. PREFETCH_H NOC-writes command pages into FABRIC_MUX's L1 buffer
 5. FABRIC_MUX NOC-writes pages into ERISC sender channel's L1 buffer
 6. ERISC transmits over ethernet PHY
 7. Remote ERISC receives, NOC-writes directly into PREFETCH_D's L1 cmddat buffer
 8. Remote ERISC increments PREFETCH_D's upstream semaphore
 9. PREFETCH_D reads from cmddat, feeds DISPATCH_D and DISPATCH_S
10. DISPATCH_D interprets commands → NOC-writes kernel binary + args to worker L1
11. DISPATCH_S multicasts GO signal to all workers
12. Workers execute kernel
13. Workers atomically increment DISPATCH_S's stream register when done
14. DISPATCH_D relays completion through RETURN_FABRIC_MUX → ethernet → DISPATCH_H
15. DISPATCH_H writes completion event to host sysmem via PCIe
```

Step 7 is zero-copy: the ERISC writes directly to PREFETCH_D's known L1 address via NOC 1. No bounce buffer or Tensix intermediary.

## Two Paths: Command Dispatch vs Data Movement

| Property | Command dispatch (host → chip) | Data movement (chip → chip) |
|----------|-------------------------------|----------------------------|
| Goes through PREFETCH/DISPATCH? | Yes, always | No |
| Tensix cores consumed on remote | 3-4 (PREFETCH_D + DISPATCH_D + DISPATCH_S + RETURN_MUX) | 0 |
| Who initiates? | Host CPU via CQ | Tensix kernel via `fabric_async_write()` |
| ERISC's role | Deliver into PREFETCH_D's L1 buffer | Deliver directly to target NOC address |
| Host involvement at runtime | Writes to sysmem, reads completions | None |

For fabric data movement (all-reduce, tensor sharding, etc.), the ERISC writes directly to the destination NOC address specified in the packet header. No dispatch pipeline involvement. See `multi-host-and-remote-card-architecture.md` for worked examples.
