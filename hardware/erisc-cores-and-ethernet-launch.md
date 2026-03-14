# ERISC Cores: Architecture, Memory Map, and Launching from NOC

Ethernet cores on Blackhole (P150) contain **ERISC** (Ethernet RISC) processors. They share the same NOC as Tensix cores but differ in hardware capabilities, memory layout, firmware model, and dispatch conventions. This doc covers the full architecture comparison and explains exactly how to launch an ERISC program from any NOC-connected core via `noc_async_write`.

## Hardware Comparison

| Property | Tensix Core | Ethernet (ERISC) Core |
|---|---|---|
| RISCVs | 5: BRISC (DM0), NCRISC (DM1), TRISC0/1/2 | 2: ERISC0 (DM0), ERISC1 (DM1) |
| L1 Size | 1.5 MB (`0x180000`) | 512 KB (`0x80000`), top 64 KB syseng-reserved |
| NOC Multicast | Can receive multicasts | **Cannot receive multicasts** (unicast only) |
| Compute Engine | Full Tensix (Unpack/Math/Pack, SFPU, FPU) | **None** -- data movement only |
| NOC Grid Position (NOC0) | Rows y=2..11 | Row y=1 |
| Translated Coordinates | `(1+col, 2+row)` | `(20+channel, 25)` |
| Mailbox Base | `0x60` (`MEM_MAILBOX_BASE`) | `0x100` (`MEM_AERISC_MAILBOX_BASE` / `MEM_IERISC_MAILBOX_BASE`) |
| BRISC/ERISC0 FW Base | `0x38C0` | `0x3250` (active), `0x3240` (idle) |
| NOC Regs Base | `0xFFB20000` | `0xFFB20000` (same) |
| Local Mem Base | `0xFFB00000` | `0xFFB00000` (same) |
| Local Mem Size | 8 KB (BRISC/NCRISC), 4 KB (TRISCs) | 8 KB (both ERISCs) |
| I-Cache Flush | ~128 NOPs | **3072 NOPs** (BH hardware) |
| Base Firmware | None (tt-metal owns core) | Active: syseng base FW for SerDes/MAC/PCS |

## Ethernet Core NOC Coordinates (P150)

All 14 ETH channels sit at physical **NOC0 y=1**. Two are harvested on P150, leaving 12 active.

| Channel | NOC0 (x, y) | Channel | NOC0 (x, y) |
|---------|-------------|---------|-------------|
| 0 | (1, 1) | 7 | (13, 1) |
| 1 | (16, 1) | 8 | (5, 1) |
| 2 | (2, 1) | 9 | (12, 1) |
| 3 | (15, 1) | 10 | (6, 1) |
| 4 | (3, 1) | 11 | (11, 1) |
| 5 | (14, 1) | 12 | (7, 1) |
| 6 | (4, 1) | 13 | (10, 1) |

With NOC coordinate translation enabled, these map to translated coords `(20+channel, 25)`.

P150 harvesting mask = 288 = `0x120` (channels 5 and 8 harvested, i.e. physical (14,1) and (5,1)).

**Source:** `tt_metal/hw/inc/internal/tt-1xx/blackhole/eth_chan_noc_mapping.h`

## Two Modes: Active vs Idle ERISC

### Active ERISC (AERISC)

- Ethernet link **is connected**; syseng base firmware manages SerDes/MAC/PCS link training.
- tt-metal firmware runs *on top of* base firmware via cooperative mechanism:
  - On BH, ERISC0 does `setjmp/enter_reset/resume_from_reset` dance for context switching with base FW.
  - ERISC0 must periodically call `risc_context_switch()` to service the syseng mailbox and check link health.
- Has access to **ETH TX queue hardware** (`eth_send_packet`, `eth_write_remote_reg`) for cross-chip data movement.
- Top 64 KB of L1 is syseng-reserved (starts at `0x70000`). Dynamic NOC counters at `0x7D040`.
- **Fast dispatch supported** -- dispatch system sends unicast launch messages and go signals.

### Idle ERISC (IERISC)

- Ethernet link **is not connected**. Core is fully owned by tt-metal.
- Structurally similar to a Tensix DM core with different memory map constants.
- Currently used as **dispatch infrastructure** for multi-chip tunneled dispatch.
- **Fast dispatch for user kernels not yet supported** (explicitly skipped in dispatch code).

**Key firmware files:**

| File | Purpose |
|------|---------|
| `tt_metal/hw/firmware/src/tt-1xx/active_erisc.cc` | Active ERISC main firmware |
| `tt_metal/hw/firmware/src/tt-1xx/active_erisc-crt0.cc` | Active ERISC C runtime (setjmp/longjmp) |
| `tt_metal/hw/firmware/src/tt-1xx/active_erisck.cc` | Active ERISC kernel entry point |
| `tt_metal/hw/firmware/src/tt-1xx/idle_erisc.cc` | Idle ERISC main firmware |
| `tt_metal/hw/firmware/src/tt-1xx/idle_erisck.cc` | Idle ERISC kernel entry point |
| `tt_metal/hw/firmware/src/tt-1xx/subordinate_erisc.cc` | ERISC1 (DM1) subordinate firmware |
| `tt_metal/hw/firmware/src/tt-1xx/erisc.cc` | Legacy WH-compatible ERISC firmware |

## Active ERISC L1 Memory Map

```
0x00000  +-------------------------------+
         | Reserved1 (256 bytes)         |
0x00100  +-------------------------------+
         | Mailbox (12768 bytes)         |  <- mailboxes_t struct
         |   ncrisc_halt, subordinate_sync, launch_msg_rd_ptr,
         |   launch[8], go_messages[9], watcher, dprint, core_info,
         |   aerisc_run_flag, profiler
0x03200  +-------------------------------+
         | L1 Inline Write (64 bytes)    |
0x03240  +-------------------------------+
         | Void Launch Flag (16 bytes)   |  <- dummy slot (BH doesn't use WH launch mechanism)
0x03250  +-------------------------------+
         | ERISC0 Firmware (24 KB)       |  <- MEM_AERISC_FIRMWARE_BASE
0x09250  +-------------------------------+
         | ERISC1 Firmware (24 KB)       |  <- MEM_SUBORDINATE_AERISC_FIRMWARE_BASE
0x0F250  +-------------------------------+  <- MEM_AERISC_MAP_END
         | Kernel Config (25 KB)         |  <- RTAs, semaphores, CB config
         +-------------------------------+
         | ERISC_L1_UNRESERVED_BASE      |  <- user data buffers
         |          ...                  |
         +-------------------------------+
         | Fabric Router Reserved (3088) |
         | Sync Info (288 bytes)         |
         | Routing Info (48 bytes)       |
         | Barrier (64 bytes)            |
0x70000  +-------------------------------+
         | Syseng Reserved (64 KB)       |  <- base firmware, boot results, API table
0x80000  +-------------------------------+  END OF ETH L1
```

**Key syseng addresses within the reserved 64 KB:**

| Address | Contents |
|---------|----------|
| `0x7CC00` | `boot_results_t` (eth status, SerDes results, MAC/PCS, chip info) |
| `0x7CC70` | Syseng heartbeat |
| `0x7CF00` | `eth_api_table_t` (function pointers into base FW) |
| `0x7D000` | Syseng ETH mailbox (4 slots) |
| `0x7D040` | Dynamic NOC counter base |

**Source:** `tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h`

## Idle ERISC L1 Memory Map

Same structure as active but without the void launch flag:

```
0x00000  +-------------------------------+
         | Reserved1 (256 bytes)         |
0x00100  +-------------------------------+
         | Mailbox (12768 bytes)         |
0x03200  +-------------------------------+
         | L1 Inline Write (64 bytes)    |
0x03240  +-------------------------------+
         | ERISC0 Firmware (24 KB)       |  <- MEM_IERISC_FIRMWARE_BASE
0x09240  +-------------------------------+
         | ERISC1 Firmware (24 KB)       |
0x0F240  +-------------------------------+
         | Routing Table (aligned 32)    |
         | Exit Node Table               |
         +-------------------------------+  <- MEM_IERISC_MAP_END
```

## Reset PC Registers

These hardware registers control where the ERISC starts executing on reset deassert:

| Register | Address | Purpose |
|----------|---------|---------|
| `AERISC_RESET_PC` | `0xFFB14000` | ERISC0 reset PC (active) |
| `SUBORDINATE_AERISC_RESET_PC` | `0xFFB14008` | ERISC1 reset PC (active) |
| `IERISC_RESET_PC` | `0xFFB14000` | ERISC0 reset PC (idle) |
| `SUBORDINATE_IERISC_RESET_PC` | `0xFFB14008` | ERISC1 reset PC (idle) |

The HAL writes the firmware base address to these registers to launch ERISC firmware:
- Active: `fw_launch_addr = SUBORDINATE_AERISC_RESET_PC`, `fw_launch_value = MEM_AERISC_FIRMWARE_BASE`
- Idle: `fw_launch_addr = IERISC_RESET_PC` / `SUBORDINATE_IERISC_RESET_PC`

**Source:** `tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_active_eth.cpp`, `bh_hal_idle_eth.cpp`

## Launch Message and Go Signal Structures

These structures are **identical** between Tensix and ERISC -- the same `mailboxes_t` struct is used. The difference is in which fields are read and at what base address.

### `go_msg_t` (4 bytes)

```cpp
struct go_msg_t {
    union {
        uint32_t all;
        struct {
            uint8_t dispatch_message_offset;  // stream reg offset for completion ack
            uint8_t master_x;                 // NOC x of dispatch/launcher core
            uint8_t master_y;                 // NOC y of dispatch/launcher core
            uint8_t signal;                   // RUN_MSG_GO(0x80), RUN_MSG_DONE(0x00), etc.
        };
    };
};
```

### `launch_msg_t` (contains `kernel_config_msg_t`)

Key fields the ERISC firmware reads:

| Field | Type | ERISC Usage |
|-------|------|-------------|
| `kernel_config_base[ACTIVE_ETH]` | `uint32_t` | Base L1 address of kernel config data (index 1, not 0) |
| `kernel_text_offset[0]` | `uint32_t` | Offset from config base to DM0 kernel entry point |
| `kernel_text_offset[1]` | `uint32_t` | Offset from config base to DM1 kernel entry point |
| `sem_offset[ACTIVE_ETH]` | `uint16_t` | Semaphore offset within config block |
| `rta_offset[0].rta_offset` | `uint16_t` | Runtime args offset for DM0 |
| `rta_offset[0].crta_offset` | `uint16_t` | Common runtime args offset for DM0 |
| `brisc_noc_id` | `uint8_t` | Which NOC to use (0 or 1) |
| `brisc_noc_mode` | `uint8_t` | `DM_DEDICATED_NOC` (0) or `DM_DYNAMIC_NOC` (1) |
| `enables` | `uint32_t` | Bit 0 = DM0 enabled, Bit 1 = DM1 enabled |
| `mode` | `uint8_t` | `DISPATCH_MODE_DEV` (0) or `DISPATCH_MODE_HOST` (1) |
| `preload` | `uint8_t` | Data-valid flag. **Must be the last byte written.** |

**Source:** `tt_metal/hw/inc/hostdev/dev_msgs.h`

## Active ERISC Firmware Boot and Dispatch Loop

The firmware in `active_erisc.cc` boots and enters an infinite dispatch loop:

```
Boot:
  1. configure_csr() -- disable gathering, configure L1 cache
  2. initialize_local_memory() -- copy data image from L1 scratch to local mem
  3. noc_bank_table_init() -- copy bank-to-NOC-XY tables
  4. disable_interrupts() -- disable all 5 interrupt vectors
  5. risc_init() -- read NOC XY coords from hardware
  6. [2-ERISC mode]:
     a. Set SUBORDINATE_AERISC_RESET_PC = MEM_SUBORDINATE_AERISC_FIRMWARE_BASE
     b. deassert_all_reset() -- bring ERISC1 out of reset
     c. enter_reset() -- save GPR + local mem to L1, spin
     d. ERISC1 triggers soft reset of ERISC0 -> resumes at resume_from_reset()
  7. Set aerisc_run_flag = 1
  8. Set go_messages[0].signal = RUN_MSG_DONE
  9. Set launch_msg_rd_ptr = 0

Dispatch loop (forever):
  1. Poll go_messages[0].signal for RUN_MSG_GO (with invalidate_l1_cache())
  2. Check flag_disable -- if 0, return to base firmware
  3. Handle RUN_MSG_RESET_READ_PTR, RUN_MSG_REPLAY_TRACE
  4. On RUN_MSG_GO:
     a. Read launch_msg from ring buffer at launch_msg_rd_ptr
     b. Set noc_index and kg_noc_mode from launch message
     c. Reinitialize NOC state if noc_mode changed
     d. run_subordinate_eriscs() -- signal ERISC1 if DM1 enabled
     e. If DM0 enabled:
        - flush_erisc_icache() (3072 NOPs)
        - firmware_config_init(mailboxes, ProgrammableCoreType::ACTIVE_ETH, 0)
        - kernel_lma = kernel_config_base + kernel_text_offset[0]
        - reinterpret_cast<void(*)()>(kernel_lma)()
     f. wait_subordinate_eriscs()
     g. go_messages[0].signal = RUN_MSG_DONE
     h. notify_dispatch_core_done(dispatch_addr) -- NOC inline write to stream reg
     i. Advance launch_msg_rd_ptr
```

**Source:** `tt_metal/hw/firmware/src/tt-1xx/active_erisc.cc`

## ETH-Specific Hardware: TX Queue Registers

ERISC cores have ethernet TX queue hardware not present on Tensix. Three queues (BH), base `0xFFB90000`, stride `0x1000`.

| Offset | Register | Purpose |
|--------|----------|---------|
| `0x00` | `ETH_TXQ_CTRL` | Keepalive/resend, type, drop control |
| `0x04` | `ETH_TXQ_CMD` | raw/data/reg-write/flush command trigger |
| `0x08` | `ETH_TXQ_STATUS` | Bit 16 = command ongoing (BH) |
| `0x14` | `ETH_TXQ_TRANSFER_START_ADDR` | Source L1 address (16-byte aligned) |
| `0x18` | `ETH_TXQ_TRANSFER_SIZE_BYTES` | Transfer size (multiple of 16) |
| `0x1C` | `ETH_TXQ_DEST_ADDR` | Remote destination L1 address (16-byte aligned) |

Core primitive:
```cpp
void eth_send_packet(uint32_t q_num, uint32_t src_word_addr, uint32_t dest_word_addr, uint32_t num_words) {
    while (eth_txq_is_busy(q_num)) { risc_context_switch(); }
    eth_txq_reg_write(q_num, ETH_TXQ_TRANSFER_START_ADDR, src_word_addr << 4);
    eth_txq_reg_write(q_num, ETH_TXQ_DEST_ADDR, dest_word_addr << 4);
    eth_txq_reg_write(q_num, ETH_TXQ_TRANSFER_SIZE_BYTES, num_words << 4);
    eth_txq_reg_write(q_num, ETH_TXQ_CMD, ETH_TXQ_CMD_START_DATA);
}
```

All addresses are in 16-byte "eth words" (shifted left by 4). Minimum transfer granularity = 16 bytes.

**BH hardware bug (BH-55):** Polling `ETH_TXQ_CMD` for busy status is unreliable. Instead, do a dummy read of `ETH_TXQ_CMD` then check `(ETH_TXQ_STATUS >> 16) & 1`.

**Source:** `tt_metal/hw/inc/internal/ethernet/tunneling.h`, `tt_metal/hw/inc/internal/ethernet/tt_eth_ss_regs.h`

## Context Switch Mechanism (Active ERISC Only)

Active ERISC0 must cooperatively yield to the syseng base firmware:

```cpp
void risc_context_switch(bool skip_sync = false) {
    if (!skip_sync) ncrisc_noc_full_sync<1>();   // sync NOC0
    service_eth_msg();                            // service syseng mailbox at 0x7D000
    update_boot_results_eth_link_status_check();  // periodic link health check
    ncrisc_noc_counters_init<1>();
}
```

User kernels running on active ERISC **must** call `risc_context_switch()` in long polling loops to avoid breaking the ethernet link. Not needed for idle ERISC.

**Source:** `tt_metal/hw/inc/internal/ethernet/erisc.h`

## How Dispatch Currently Launches ERISC Programs

The existing dispatch system already launches ERISC programs via NOC unicast. Key differences from Tensix dispatch:

| Aspect | Tensix | ERISC |
|--------|--------|-------|
| Launch msg delivery | NOC **multicast** packed write | NOC **unicast** packed write (per core) |
| Binary delivery | Multicast packed large write | **Unicast** write linear (per core) |
| Go signal delivery | NOC **multicast** | NOC **unicast** (per core) |
| Config buffer | Ring buffer with rotation | **Fixed base address** each time |
| Completion ack | Flush one NOC, inline write to stream reg | **Flush both NOCs**, inline write to stream reg |
| `kernel_config_base` index | `[0]` (TENSIX) | `[1]` (ACTIVE_ETH) |
| Mailbox base | `0x60` | `0x100` |
| `go_message_index` | Variable (sub-device support) | Always `0` |

**Source:** `tt_metal/impl/program/dispatch.cpp`

## Launching an ERISC Program from Another Core (via `noc_async_write`)

There is **no hardware barrier** to launching an ERISC program from any NOC-connected core. The ERISC firmware just polls L1 mailbox addresses. All you do is write the right data to the right addresses via standard NOC unicast writes.

### Required Writes

All destinations are the target ETH core's L1, addressed via `NOC_XY_ADDR(eth_x, eth_y, l1_addr)`:

| Step | What to Write | Destination Address |
|------|--------------|-------------------|
| 1 | Kernel binary | `kernel_config_base[ACTIVE_ETH] + kernel_text_offset[0]` |
| 2 | Kernel config (RTAs, semaphores, CBs) | `kernel_config_base[ACTIVE_ETH]` |
| 3 | `launch_msg_t` | `0x100 + offsetof(mailboxes_t, launch[wr_ptr])` |
| 4 | `go_msg_t` with `signal=RUN_MSG_GO` | `0x100 + offsetof(mailboxes_t, go_messages[0])` |

### Pseudocode

```cpp
// Target ETH core NOC coordinates (translated or physical)
uint32_t eth_x = ...;
uint32_t eth_y = ...;

// 1. Write kernel binary
uint64_t binary_dst = NOC_XY_ADDR(eth_x, eth_y, kernel_binary_l1_addr);
noc_async_write(local_binary_addr, binary_dst, binary_size);

// 2. Write kernel config (RTAs, semaphores)
uint64_t config_dst = NOC_XY_ADDR(eth_x, eth_y, kernel_config_l1_addr);
noc_async_write(local_config_addr, config_dst, config_size);

// 3. Construct and write launch_msg_t
launch_msg_t* msg = (launch_msg_t*)local_launch_msg_addr;
msg->kernel_config.kernel_config_base[ProgrammableCoreType::ACTIVE_ETH] = kernel_config_l1_addr;
msg->kernel_config.kernel_text_offset[0] = kernel_text_offset;
msg->kernel_config.sem_offset[ProgrammableCoreType::ACTIVE_ETH] = sem_offset;
msg->kernel_config.rta_offset[0] = {.rta_offset = rta_off, .crta_offset = crta_off};
msg->kernel_config.brisc_noc_id = NOC_0;
msg->kernel_config.brisc_noc_mode = DM_DEDICATED_NOC;
msg->kernel_config.mode = DISPATCH_MODE_DEV;
msg->kernel_config.enables = 1;  // bit 0 = DM0
msg->kernel_config.preload = 1;  // MUST be last byte written

uint32_t launch_offset = offsetof(mailboxes_t, launch[0]);  // wr_ptr=0
uint64_t launch_dst = NOC_XY_ADDR(eth_x, eth_y, 0x100 + launch_offset);
noc_async_write(local_launch_msg_addr, launch_dst, sizeof(launch_msg_t));
noc_async_write_barrier();

// 4. Write go signal (must arrive after launch msg)
go_msg_t go;
go.signal = RUN_MSG_GO;
go.master_x = my_noc_x;   // for completion notification back to launcher
go.master_y = my_noc_y;
go.dispatch_message_offset = 0;

uint32_t go_offset = offsetof(mailboxes_t, go_messages[0]);
uint64_t go_dst = NOC_XY_ADDR(eth_x, eth_y, 0x100 + go_offset);
noc_async_write(local_go_addr, go_dst, sizeof(go_msg_t));
noc_async_write_barrier();
```

### Gotchas

1. **No multicast.** Every write must be unicast. You cannot batch-send to multiple ETH cores in one NOC command.

2. **Different mailbox base.** ETH = `0x100`, Tensix = `0x60`. If your launcher templates on `MEM_MAILBOX_BASE`, you need the ETH variant.

3. **Different `kernel_config_base` index.** ETH firmware reads index `[1]` (`ACTIVE_ETH`), not `[0]` (`TENSIX`). Your launch message must populate the correct slot.

4. **`enables` semantics differ.** Tensix: bit 0=BRISC, bit 1=NCRISC, bits 2-4=TRISC0/1/2. ETH: bit 0=DM0 (ERISC0), bit 1=DM1 (ERISC1). Only 2 bits meaningful.

5. **Completion notification flushes both NOCs.** The ETH `notify_dispatch_core_done` (in `tunneling.h`) calls `ncrisc_noc_full_sync` on both NOC0 and NOC1 before the ack write. If your launcher waits on this ack, the response goes to the address encoded in `go_msg_t`'s `master_x`/`master_y`/`dispatch_message_offset`.

6. **I-cache flush latency.** The firmware does 3072 NOPs before jumping to the kernel. ~3000 cycle overhead between go signal and kernel start. Firmware handles this; not your concern.

7. **Active ERISC context switching.** Kernels on active ERISC must call `risc_context_switch()` in long polling loops or risk the ethernet link dropping. Not needed for idle ERISC.

8. **`go_message_index` is always 0.** Unlike Tensix which uses multiple go_message slots for sub-devices, ETH cores only use index 0.

9. **Ring buffer management.** The firmware maintains `launch_msg_rd_ptr` wrapping over 8 entries. Wait for `RUN_MSG_DONE` before overwriting a slot. For single-shot launch, use slot 0 and ensure `launch_msg_rd_ptr` was reset.

10. **`core_info_msg_t` must be pre-populated.** The firmware reads `core_info.absolute_logical_x/y` during boot. This is set up by the host before firmware launch. If firmware is already running (which it is if you're sending a go signal), this is already done.

## Key Source Files

| Category | File |
|----------|------|
| BH Memory Map | `tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h` |
| BH ETH L1 Map | `tt_metal/hw/inc/internal/tt-1xx/blackhole/eth_l1_address_map.h` |
| BH ETH FW API | `tt_metal/hw/inc/internal/tt-1xx/blackhole/eth_fw_api.h` |
| ETH NOC Mapping | `tt_metal/hw/inc/internal/tt-1xx/blackhole/eth_chan_noc_mapping.h` |
| Core Config | `tt_metal/hw/inc/internal/tt-1xx/blackhole/core_config.h` |
| Tensix Registers | `tt_metal/hw/inc/internal/tt-1xx/blackhole/tensix.h` |
| ETH SS Registers | `tt_metal/hw/inc/internal/ethernet/tt_eth_ss_regs.h` |
| ETH Data Primitives | `tt_metal/hw/inc/internal/ethernet/tunneling.h` |
| ETH Dataflow API | `tt_metal/hw/inc/internal/ethernet/dataflow_api.h` |
| ETH Context Switch | `tt_metal/hw/inc/internal/ethernet/erisc.h` |
| Mailbox/Launch Structs | `tt_metal/hw/inc/hostdev/dev_msgs.h` |
| Firmware Common | `tt_metal/hw/inc/internal/firmware_common.h` |
| Active ERISC FW | `tt_metal/hw/firmware/src/tt-1xx/active_erisc.cc` |
| Active ERISC CRT0 | `tt_metal/hw/firmware/src/tt-1xx/active_erisc-crt0.cc` |
| Active ERISC Kernel Entry | `tt_metal/hw/firmware/src/tt-1xx/active_erisck.cc` |
| Idle ERISC FW | `tt_metal/hw/firmware/src/tt-1xx/idle_erisc.cc` |
| Idle ERISC Kernel Entry | `tt_metal/hw/firmware/src/tt-1xx/idle_erisck.cc` |
| Subordinate ERISC FW | `tt_metal/hw/firmware/src/tt-1xx/subordinate_erisc.cc` |
| HAL Active ETH | `tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_active_eth.cpp` |
| HAL Idle ETH | `tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_idle_eth.cpp` |
| Dispatch (host-side) | `tt_metal/impl/program/dispatch.cpp` |
| Dispatch Kernel | `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` |
