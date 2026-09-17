# Emulator boot state and firmware memory

The boot sequence and LDM allocations below model the recorded TT-Metal firmware. They are software contracts, not the current blackhole-py worker ABI. Use the current runtime guide for that implementation.

<a id="firmware-upload"></a>
## Firmware Upload and Core Boot Process
<a id="firmware-upload--firmware-upload-and-core-boot-process"></a>

<a id="firmware-upload--overview"></a>
### Overview

Each Tensix tile has **5 RISC-V cores**:

| Index | Name | Type | Role |
|-------|------|------|------|
| 0 | BRISC | DM0 | Master dispatcher, writer/dataflow out |
| 1 | NCRISC | DM1 | Data mover, reader/dataflow in |
| 2 | TRISC0 | MATH0 | Unpack |
| 3 | TRISC1 | MATH1 | Math/compute |
| 4 | TRISC2 | MATH2 | Pack |

The host uploads firmware to all worker cores in parallel via NOC multicast, then bootstraps them through a coordinated reset sequence. BRISC is the master — it releases the other 4 cores from reset and coordinates all kernel launches.

<a id="firmware-upload--upload-sequence"></a>
### Upload Sequence

Source: `device.py:202-276`

<a id="firmware-upload--step-1-assert-soft-reset"></a>
#### Step 1: Assert soft reset

Write `0x47800` (`SOFT_RESET_ALL`) to MMIO register `0xFFB121B0` (`SOFT_RESET_0`) on all cores via multicast. This holds all 5 RISCs in reset.

<a id="firmware-upload--step-2-upload-elf-segments-via-wc-multicast"></a>
#### Step 2: Upload ELF segments via WC multicast

Each firmware ELF's `PT_LOAD` segments are written to L1 via write-combining (WC) TLB windows. Segments whose physical address falls in `0xFFB00000–0xFFB01FFF` (LOCAL_RAM, core-private SRAM) are remapped to a scratch area in L1 so that `do_crt1()` can later copy them into actual local memory at runtime.

All other segments are written directly to their L1 address.

<a id="firmware-upload--step-3-write-boot-stub-at-l10"></a>
#### Step 3: Write boot stub at L1[0]

A single RISC-V JAL instruction encoding a jump to `0x3840` (`BRISC_FIRMWARE_BASE`) is written to L1 address 0:

```python
brisc_base = 0x3840
jal = ((brisc_base & 0xFF000)
     | ((brisc_base & 0x800) << 9)
     | ((brisc_base & 0x7FE) << 20)
     | 0x6F).to_bytes(4, "little")
```

When BRISC exits reset, its PC starts at 0 and immediately jumps to its firmware.

<a id="firmware-upload--step-4-write-initial-go_message"></a>
#### Step 4: Write initial go_message

`{0x00, 0x00, 0x00, 0x40}` is written to L1 offset `0x370`. The signal byte (byte 3, at offset `0x373`) is `RUN_MSG_INIT = 0x40`.

<a id="firmware-upload--step-5-write-bank-to-noc-mapping-table"></a>
#### Step 5: Write bank-to-NOC mapping table

The DRAM and L1 bank-to-NOC-coordinate lookup table is written at L1 offset `0x116B0`.

<a id="firmware-upload--step-6-drain-wc-buffer"></a>
#### Step 6: Drain WC buffer

A read from the WC mmap forces all pending write-combining writes to complete before any subsequent MMIO updates.

<a id="firmware-upload--step-7-program-subordinate-reset-pcs"></a>
#### Step 7: Program subordinate reset PCs

The `.text` base address of each subordinate firmware ELF is written to the corresponding MMIO debug register:

| Register | Address | Target |
|----------|---------|--------|
| `NCRISC_RESET_PC` | `0xFFB12238` | NCRISC text base (e.g. `0x5440`) |
| `TRISC0_RESET_PC` | `0xFFB12228` | TRISC0 text base (e.g. `0x5A40`) |
| `TRISC1_RESET_PC` | `0xFFB1222C` | TRISC1 text base (e.g. `0x6040`) |
| `TRISC2_RESET_PC` | `0xFFB12230` | TRISC2 text base (e.g. `0x6A40`) |

These are override registers — BRISC firmware also sets the override enable bits (`TRISC_RESET_PC_OVERRIDE = 0b111`, `NCRISC_RESET_PC_OVERRIDE = 0x1`) so the hardware uses these values instead of hardcoded defaults.

<a id="firmware-upload--step-8-release-brisc-from-reset"></a>
#### Step 8: Release BRISC from reset

Write `0x47000` (`SOFT_RESET_BRISC_ONLY_RUN`) to `0xFFB121B0`. Only BRISC is released; NCRISC and TRISCs remain in reset.

<a id="firmware-upload--step-9-poll-for-firmware-ready"></a>
#### Step 9: Poll for firmware ready

Host polls `L1[0x373]` (the signal byte of `go_messages[0]`) until it reads `0x00` (`RUN_MSG_DONE`). This indicates BRISC has completed its init, released all subordinates, waited for them to finish their init, and is ready for dispatch.

Timeout: 2 seconds, with 1 ms sleep between polls.


<a id="firmware-upload--per-core-firmware-behavior"></a>
### Per-Core Firmware Behavior

<a id="firmware-upload--brisc-dm0--firmwarebrisccc"></a>
#### BRISC (DM0) — `firmware/brisc.cc`

<a id="firmware-upload--init-phase"></a>
##### Init Phase

1. `configure_csr()` — configure RISC-V CSRs (instruction cache, etc.)
2. `do_crt1(MEM_BRISC_INIT_LOCAL_L1_BASE_SCRATCH)` — copy initialized data from L1 scratch area into LOCAL_RAM at `0xFFB00000`, zero BSS section
3. `noc_bank_table_init(MEM_BANK_TO_NOC_SCRATCH)` — load DRAM/L1 bank-to-NOC-XY lookup tables from the table the host wrote
4. `noc_worker_logical_to_virtual_map_init()` — load logical-to-virtual coordinate mapping
5. `risc_init()` — read NOC coordinates (`my_x[0]`, `my_y[0]`, `my_x[1]`, `my_y[1]`) from hardware
6. `device_setup()`:
   - Initialize instruction/PC buffers for 3 Tensix threads
   - Write `0` to `RISCV_DEBUG_REG_DEST_CG_CTRL` (`0xFFB12240`) — disable dest clock gating
   - Write `0x3F` to `RISCV_TDMA_REG_CLK_GATE_EN` (`0xFFB11024`) — enable TDMA clock gating
   - Configure NOC0 and NOC1: set bit 0 of `NIU_CFG_0` and `ROUTER_CFG_0` on each
   - Enable reset PC override for subordinates
   - Zero 512 bytes at `MEM_ZEROS_BASE` (`0x3240`)
   - Invalidate all 5 instruction caches: write `0x1F` to `cfg_regs[RISCV_IC_INVALIDATE_InvalidateAll]`
   - Execute `ex_zeroacc`, `ex_encc`, `ex_load_const` on Tensix instruction buffer (ECC/accumulator init)
   - Enable ECC scrubber with delay `0x100`
   - Initialize Tensix semaphores
7. Set `subordinate_sync.all = 0x40404040` (`RUN_SYNC_MSG_ALL_INIT`)
8. `deassert_all_reset()` — release NCRISC + TRISC0/1/2 from soft reset
9. `wait_ncrisc_trisc()` — spin on `subordinate_sync.all` until it equals `0x00000000` (all 4 subordinates have written `RUN_SYNC_MSG_DONE`)
10. Set `go_messages[0].signal = RUN_MSG_DONE` (0x00) — the host sees this and knows the tile is ready
11. Initialize NOC (`noc_init`, `noc_local_state_init`)
12. `trigger_sync_register_init()` — write `0x03` to `subordinate_sync->trisc0` to tell TRISC0 to zero all CB tile counters

<a id="firmware-upload--dispatch-loop"></a>
##### Dispatch Loop

```
while (1) {
    // 1. POLL: spin on go_messages[go_message_index].signal
    //    - Each iteration: invalidate_l1_cache() (fence instruction)
    //    - Also check launch[launch_msg_rd_ptr].preload for DISPATCH_ENABLE_FLAG_PRELOAD
    //    - Handle special signals:
    //        0xC0 (RESET_READ_PTR): reset launch_msg_rd_ptr=0, write DONE, notify dispatch
    //        0xF0 (REPLAY_TRACE): same as above + re-init profiler
    //    - Break when signal == RUN_MSG_GO (0x80) or preload flag set

    // 2. READ LAUNCH MESSAGE
    //    launch_msg = &mailboxes->launch[launch_msg_rd_ptr]
    //    enables = launch_msg->kernel_config.enables  (bitmask: bit0=BRISC, bit1=NCRISC, bit2-4=TRISC0-2)

    // 3. SIGNAL NCRISC TO PRELOAD
    //    if NCRISC enabled: subordinate_sync->dm1 = RUN_SYNC_MSG_LOAD (0x01)

    // 4. INIT CONFIG
    //    kernel_config_base = firmware_config_init(mailboxes, TENSIX, PROCESSOR_INDEX)
    //    This reads kernel_config_base from the launch message and sets up RTA/CRTA/semaphore pointers

    // 5. INVALIDATE ALL ICACHES
    //    cfg_regs[RISCV_IC_INVALIDATE] = 0x1F

    // 6. LAUNCH TRISCs
    //    Wait for trisc0 == DONE (from previous sync register init)
    //    If TRISC enabled: set trisc0=trisc1=trisc2 = RUN_SYNC_MSG_GO (0x80)

    // 7. CONFIGURE NOC + CB INTERFACES
    //    Set noc_index, noc_mode from launch_msg
    //    setup_local_cb_read_write_interfaces()
    //    setup_remote_cb_interfaces()

    // 8. LAUNCH NCRISC
    //    subordinate_sync->dm1 = RUN_SYNC_MSG_GO (0x80)

    // 9. RUN KERNEL OR WAIT
    //    if BRISC kernel enabled:
    //        kernel_lma = kernel_config_base + kernel_text_offset[0]
    //        stack_free = ((uint32_t(*)())kernel_lma)()
    //    else:
    //        wait_for_go_message()  // re-enter poll loop

    // 10. WAIT FOR SUBORDINATES
    //     wait_ncrisc_trisc()  — spin until subordinate_sync.all == 0

    // 11. RESET CB SYNC REGISTERS
    //     trigger_sync_register_init()  — subordinate_sync->trisc0 = 0x03

    // 12. SIGNAL COMPLETION
    //     go_messages[go_message_index].signal = RUN_MSG_DONE (0x00)
    //     If DISPATCH_MODE_DEV:
    //       Clear enables and preload in launch_msg
    //       notify_dispatch_core_done()  — NOC atomic increment to dispatch core
    //       Advance launch_msg_rd_ptr = (ptr + 1) & 7
}
```

<a id="firmware-upload--ncrisc-dm1--firmwarencrisccc"></a>
#### NCRISC (DM1) — `firmware/ncrisc.cc`

<a id="firmware-upload--init-phase-1"></a>
##### Init Phase

1. `configure_csr()`
2. `do_crt1(MEM_NCRISC_INIT_LOCAL_L1_BASE_SCRATCH)`
3. `noc_bank_table_init()`, `noc_worker_logical_to_virtual_map_init()`
4. `risc_init()`
5. Write `*ncrisc_run = RUN_SYNC_MSG_DONE` (0x00) — signal BRISC that init is complete

The sync byte pointer: `ncrisc_run = &mailboxes->subordinate_sync.map[0]` (L1 offset `0x068`, the `dm1` byte).

<a id="firmware-upload--main-loop"></a>
##### Main Loop

```
while (1) {
    // 1. POLL: spin on *ncrisc_run until GO (0x80) or LOAD (0x01)
    //    invalidate_l1_cache() between reads

    // 2. READ LAUNCH MESSAGE + INIT CONFIG
    //    launch_msg = &mailboxes->launch[launch_msg_rd_ptr]
    //    kernel_config_base = firmware_config_init()
    //    kernel_lma = kernel_config_base + kernel_text_offset[1]

    // 3. SET UP CB INTERFACES
    //    setup_local_cb_read_write_interfaces()
    //    setup_remote_cb_interfaces()

    // 4. WAIT FOR ACTUAL GO
    //    spin on *ncrisc_run until == RUN_SYNC_MSG_GO (0x80)
    //    (handles the LOAD → GO transition: BRISC sends LOAD first for CB preloading,
    //     then sends GO when ready to execute)

    // 5. RUN KERNEL
    //    stack_free = ((uint32_t(*)())kernel_lma)()

    // 6. SIGNAL DONE
    //    *ncrisc_run = RUN_SYNC_MSG_DONE (0x00)
}
```

<a id="firmware-upload--trisc012-unpackmathpack--firmwaretrisccc"></a>
#### TRISC0/1/2 (Unpack/Math/Pack) — `firmware/trisc.cc`

Compiled 3 times with `COMPILE_FOR_TRISC` = 0, 1, 2.

<a id="firmware-upload--init-phase-2"></a>
##### Init Phase

1. `configure_csr()`
2. `do_crt1()` — copy data from L1 scratch for the specific TRISC
3. Zero the 64-entry Tensix GPR register file at `REGFILE_BASE` (`0xFFE00000`)
4. `reset_cfg_state_id()`
5. Seed PRNG: write 0 to `cfg[PRNG_SEED_Seed_Val]`
6. `riscv_wait(600)` — wait 600 cycles for PRNG to settle
7. Write `*trisc_run = RUN_SYNC_MSG_DONE` (0x00) — signal BRISC

The sync byte pointer: `trisc_run = &mailboxes->subordinate_sync.map[COMPILE_FOR_TRISC + 1]`
- TRISC0 → `map[1]` → L1 offset `0x069`
- TRISC1 → `map[2]` → L1 offset `0x06A`
- TRISC2 → `map[3]` → L1 offset `0x06B`

<a id="firmware-upload--main-loop-1"></a>
##### Main Loop

```
while (1) {
    // 1. POLL: spin on *trisc_run until RUN_SYNC_MSG_GO (0x80)
    //    invalidate_l1_cache() between reads
    //
    //    TRISC0 ONLY: also handles RUN_SYNC_MSG_INIT_SYNC_REGISTERS (0x03)
    //      → zeroes all NUM_CIRCULAR_BUFFERS tiles_received and tiles_acked counters
    //        (hardware sync registers at 0xFFB48028 stepping by 0x20000 per CB)
    //      → writes *trisc_run = RUN_SYNC_MSG_DONE (0x00)
    //      → continues polling

    // 2. READ LAUNCH MESSAGE
    //    launch_msg = &mailboxes->launch[launch_msg_rd_ptr]
    //    kernel_config_base = launch_msg->kernel_config.kernel_config_base[TENSIX]

    // 3. SET UP CB INTERFACES (TRISC0 and TRISC2 only, not TRISC1/Math)
    //    TRISC0 (Unpack): setup_local_cb_read_write_interfaces<read=true, write=false>
    //    TRISC2 (Pack):   setup_local_cb_read_write_interfaces<read=false, write=true>

    // 4. SET UP RTA POINTERS
    //    rta_l1_base  = kernel_config_base + rta_offset[PROCESSOR_INDEX].rta_offset
    //    crta_l1_base = kernel_config_base + rta_offset[PROCESSOR_INDEX].crta_offset

    // 5. RUN KERNEL
    //    index = MATH0 + thread_id  (i.e., 2, 3, or 4)
    //    kernel_lma = kernel_config_base + kernel_text_offset[index]
    //    stack_free = ((uint32_t(*)())kernel_lma)()

    // 6. SYNC TENSIX PIPELINE
    //    tensix_sync()  — wait for Tensix hardware pipeline to drain

    // 7. SIGNAL DONE
    //    *trisc_run = RUN_SYNC_MSG_DONE (0x00)
}
```


<a id="firmware-upload--protocol-constants"></a>
### Protocol Constants

<a id="firmware-upload--go_msg_t-signal-values-host--brisc"></a>
#### go_msg_t signal values (host ↔ BRISC)

| Value | Name | Meaning |
|-------|------|---------|
| `0x00` | `RUN_MSG_DONE` | BRISC finished kernel, ready for next |
| `0x40` | `RUN_MSG_INIT` | Initial value written by host at upload time |
| `0x80` | `RUN_MSG_GO` | Launch kernel (written by host or dispatch core) |
| `0xC0` | `RUN_MSG_RESET_READ_PTR` | Reset launch_msg_rd_ptr to 0 (from dispatch) |
| `0xE0` | `RUN_MSG_RESET_READ_PTR_FROM_HOST` | Reset launch_msg_rd_ptr to 0 (from host) |
| `0xF0` | `RUN_MSG_REPLAY_TRACE` | Reset read pointer and replay trace |

<a id="firmware-upload--subordinate_sync-byte-values-brisc--subordinates"></a>
#### subordinate_sync byte values (BRISC ↔ subordinates)

| Value | Name | Meaning |
|-------|------|---------|
| `0x00` | `RUN_SYNC_MSG_DONE` | Subordinate finished (init or kernel) |
| `0x01` | `RUN_SYNC_MSG_LOAD` | BRISC→NCRISC: pre-load circular buffers |
| `0x02` | `RUN_SYNC_MSG_WAITING_FOR_RESET` | Subordinate waiting for reset |
| `0x03` | `RUN_SYNC_MSG_INIT_SYNC_REGISTERS` | BRISC→TRISC0: zero CB tile counters |
| `0x40` | `RUN_SYNC_MSG_INIT` | Initial value at reset |
| `0x80` | `RUN_SYNC_MSG_GO` | BRISC→subordinate: execute kernel now |

Aggregate constants:
- `0x40404040` = `RUN_SYNC_MSG_ALL_INIT`
- `0x80808080` = `RUN_SYNC_MSG_ALL_GO`
- `0x00000000` = `RUN_SYNC_MSG_ALL_SUBORDINATES_DONE`


<a id="firmware-upload--data-structures"></a>
### Data Structures

<a id="firmware-upload--go_msg_t-4-bytes-at-l1-offset-0x370--index4"></a>
#### `go_msg_t` (4 bytes, at L1 offset `0x370` + index*4)

```
struct go_msg_t {
    union {
        uint32_t all;
        struct {
            uint8_t dispatch_message_offset;  // byte 0
            uint8_t master_x;                 // byte 1 — dispatch core NOC X
            uint8_t master_y;                 // byte 2 — dispatch core NOC Y
            uint8_t signal;                   // byte 3 — RUN_MSG_* value
        };
    };
};
```

9 entries in the ring buffer. `go_message_index` at L1 `0x3A0` selects which entry is active.

<a id="firmware-upload--subordinate_sync-4-bytes-at-l1-offset-0x068"></a>
#### `subordinate_sync` (4 bytes, at L1 offset `0x068`)

```
union subordinate_map_t {
    volatile uint32_t all;
    struct {
        volatile uint8_t dm1;     // byte 0 — NCRISC sync
        volatile uint8_t trisc0;  // byte 1 — TRISC0 sync
        volatile uint8_t trisc1;  // byte 2 — TRISC1 sync
        volatile uint8_t trisc2;  // byte 3 — TRISC2 sync
    };
};
```

BRISC polls `all` as a single 32-bit read for fast "all done" checks.

<a id="firmware-upload--kernel_config_msg_t-embedded-in-launch_msg_t"></a>
#### `kernel_config_msg_t` (embedded in `launch_msg_t`)

```
struct kernel_config_msg_t {
    uint32_t kernel_config_base[3];       // per ProgrammableCoreType (TENSIX, ACTIVE_ETH, IDLE_ETH)
    uint16_t sem_offset[3];               // semaphore region offset within config
    uint16_t local_cb_offset;             // offset to local CB config blob
    uint16_t remote_cb_offset;            // offset to remote CB config blob
    rta_offset_t rta_offset[5];           // per-processor {rta_offset, crta_offset}
    uint8_t  mode;                        // DISPATCH_MODE_DEV(0) or DISPATCH_MODE_HOST(1)
    uint8_t  pad;
    uint32_t kernel_text_offset[5];       // per-processor kernel binary offset from kernel_config_base
    uint32_t local_cb_mask;               // bitmask of which CBs are local
    uint8_t  brisc_noc_id;                // which NOC BRISC uses (0 or 1)
    uint8_t  brisc_noc_mode;              // DM_DEDICATED_NOC(0) or DM_DYNAMIC_NOC(1)
    uint8_t  min_remote_cb_start_index;   // first remote CB index
    uint8_t  exit_erisc_kernel;
    uint32_t host_assigned_id;            // profiler program/launch ID
    uint32_t enables;                     // bitmask: bit0=BRISC, bit1=NCRISC, bit2=TRISC0, bit3=TRISC1, bit4=TRISC2
    uint16_t watcher_kernel_ids[5];
    uint16_t ncrisc_kernel_size16;        // NCRISC kernel size in 16-byte units
    uint8_t  sub_device_origin_x;
    uint8_t  sub_device_origin_y;
    uint8_t  pad3;
    uint8_t  preload;                     // DISPATCH_ENABLE_FLAG_PRELOAD = 0x80
} __attribute__((packed));
```

`launch_msg_t` is just a wrapper around `kernel_config_msg_t`. 8 entries in a ring buffer starting at L1 `0x070`, each 96 bytes.

<a id="firmware-upload--mailboxes_t-l1-offset-0x060"></a>
#### `mailboxes_t` (L1 offset `0x060`)

```
struct mailboxes_t {
    ncrisc_halt_msg_t ncrisc_halt;              // +0x00 (abs 0x060): {resume_addr, stack_save}
    subordinate_sync_msg_t subordinate_sync;    // +0x08 (abs 0x068): 4 sync bytes
    volatile uint32_t launch_msg_rd_ptr;        // +0x0C (abs 0x06C): ring buffer read index
    launch_msg_t launch[8];                     // +0x10 (abs 0x070): 8 x 96 bytes = 768 bytes
    volatile go_msg_t go_messages[9];           // +0x310 (abs 0x370): 9 x 4 bytes = 36 bytes
    uint64_t link_status_check_timestamp;       // (active erisc only)
    volatile uint32_t go_message_index;         // +0x340 (abs 0x3A0): which go_msg entry is active
    watcher_msg_t watcher;                      // debug watcher state
    dprint_buf_msg_t dprint_buf;                // debug print buffers
    core_info_msg_t core_info;                  // abs ~0x9A0: {noc addresses, logical coords, ...}
    uint32_t aerisc_run_flag;
    profiler_msg_t profiler;
};
```


<a id="firmware-upload--mmio-register-map"></a>
### MMIO Register Map

<a id="firmware-upload--reset-control"></a>
#### Reset Control

| Address | Name | Description |
|---------|------|-------------|
| `0xFFB121B0` | `SOFT_RESET_0` | Soft reset for all 5 cores. Values: `0x47800`=all held, `0x47000`=BRISC released only |
| `0xFFB12228` | `TRISC0_RESET_PC` | TRISC0 reset vector (set by host before release) |
| `0xFFB1222C` | `TRISC1_RESET_PC` | TRISC1 reset vector |
| `0xFFB12230` | `TRISC2_RESET_PC` | TRISC2 reset vector |
| `0xFFB12238` | `NCRISC_RESET_PC` | NCRISC reset vector |

BRISC always resets to PC=0 (the JAL stub in L1). Subordinate PCs are programmed via these override registers.

<a id="firmware-upload--clock-gating"></a>
#### Clock Gating

| Address | Name | Description |
|---------|------|-------------|
| `0xFFB12240` | `DEST_CG_CTRL` | Destination clock gate control (written to 0 during init) |
| `0xFFB11024` | `TDMA_CLK_GATE_EN` | TDMA clock gate enable (written to 0x3F during init) |

<a id="firmware-upload--debug-bus-pc-readback"></a>
#### Debug Bus (PC Readback)

| Address | Name | Description |
|---------|------|-------------|
| `0xFFB12054` | `DBG_BUS_CNTL` | Config register: `(1<<29) \| (rd_sel<<25) \| (daisy_sel<<16) \| sig_sel` |
| `0xFFB1205C` | `DBG_BUS_RD_DATA` | Read data, masked with `0x3FFFFFFF` for PC value |

Per-core signal configuration (all use rd_sel=1, daisy_sel=7):

| Core | sig_sel |
|------|---------|
| BRISC | 11 |
| TRISC0 | 13 |
| TRISC1 | 15 |
| TRISC2 | 17 |
| NCRISC | 25 |

<a id="firmware-upload--wall-clock"></a>
#### Wall Clock

| Address | Name |
|---------|------|
| `0xFFB121F0` | `WALL_CLOCK_L` — low 32 bits |
| `0xFFB121F8` | `WALL_CLOCK_H` — high 32 bits |

<a id="firmware-upload--instruction-cache"></a>
#### Instruction Cache

Written via Tensix config register space:

```
cfg_regs[RISCV_IC_INVALIDATE_InvalidateAll_ADDR32] = mask
```

Mask bits:
- `0x01` = BRISC
- `0x02` = TRISC0
- `0x04` = TRISC1
- `0x08` = TRISC2
- `0x10` = NCRISC
- `0x1F` = all


<a id="firmware-upload--core-private-memory-regions"></a>
### Core-Private Memory Regions

| Address Range | Name | Size | Notes |
|---------------|------|------|-------|
| `0xFFB00000–0xFFB01FFF` | LOCAL_RAM (LDM) | 8 KB (BRISC/NCRISC), 4 KB (TRISC) | Globals + stack, per-processor private |
| `0xFFE00000` | `REGFILE_BASE` | 256 bytes | 64 x 32-bit Tensix GPR register file |
| `0xFFE40000` | `INSTRN_BUF_BASE` | — | Tensix instruction buffer |
| `0xFFE80000` | `PC_BUF_BASE[0]` | — | Thread 0 PC buffer |
| `0xFFE90000` | `PC_BUF_BASE[1]` | — | Thread 1 PC buffer |
| `0xFFEA0000` | `PC_BUF_BASE[2]` | — | Thread 2 PC buffer |
| `0xFFEF0000` | `TENSIX_CFG_BASE` | — | Tensix configuration register space |


<a id="firmware-upload--l1-memory-map"></a>
### L1 Memory Map

| Offset | Name | Size | Description |
|--------|------|------|-------------|
| `0x0000` | Boot JAL | 4 B | Jump instruction to BRISC firmware |
| `0x0004` | `NOC_ATOMIC_RET_VAL` | 8 B | NOC atomic operation return value |
| `0x000C` | `L1_BARRIER` | 4 B | L1 memory barrier |
| `0x0010` | `L1_ARC_FW_SCRATCH` | 16 B | ARC firmware scratch / power throttling |
| `0x0020` | `L1_INLINE_BASE` | 64 B | Emulated inline write staging (2 NOCs x 2 DMs x 16 B) |
| `0x0060` | `MAILBOX_BASE` | ~12768 B | `mailboxes_t` (see struct above) |
| `0x3240` | `ZEROS_BASE` | 512 B | Zeroed region for DMA zero-fills |
| `0x3440` | `LLK_DEBUG_BASE` | 1024 B | LLK debug storage |
| `0x3840` | `BRISC_FIRMWARE` | 7168 B | BRISC firmware code (XIP) |
| `0x5440` | `NCRISC_FIRMWARE` | 1536 B | NCRISC firmware code (XIP) |
| `0x5A40` | `TRISC0_FIRMWARE` | 1536 B | TRISC0 firmware code (XIP) |
| `0x6040` | `TRISC1_FIRMWARE` | 2560 B | TRISC1 firmware code (XIP) |
| `0x6A40` | `TRISC2_FIRMWARE` | 1536 B | TRISC2 firmware code (XIP) |
| `0x86B0` | `KERNEL_CONFIG_BASE` | variable | Kernel text + CB config + RTAs + semaphores |
| `0x116B0` | `BANK_TO_NOC_SCRATCH` | ~2 KB | Bank-to-NOC coordinate lookup tables |
| `0x37000` | `DATA_BUFFER_SPACE_BASE` | — | Start of user data buffer space |
| `0x180000` | End of L1 | — | Total L1 = 1.5 MB |


<a id="firmware-upload--kernel-launch-flow-summary"></a>
### Kernel Launch Flow Summary

The kernel entry point is not a named symbol. It is a raw function pointer call to whatever code sits at `kernel_config_base + kernel_text_offset[processor_index]` in L1:

```c
uint32_t kernel_lma = kernel_config_base + launch_msg->kernel_config.kernel_text_offset[index];
uint32_t stack_free = ((uint32_t(*)())kernel_lma)();
```

The kernel returns a `uint32_t` representing the stack high-water mark (used for profiling/watcher stack usage tracking).

<a id="firmware-upload--processor-index-mapping"></a>
#### Processor Index Mapping

| Index | Enum | Core | Kernel Role |
|-------|------|------|-------------|
| 0 | `DM0` | BRISC | Writer / dataflow out |
| 1 | `DM1` | NCRISC | Reader / dataflow in |
| 2 | `MATH0` | TRISC0 | Unpack |
| 3 | `MATH1` | TRISC1 | Math / compute |
| 4 | `MATH2` | TRISC2 | Pack |

<a id="firmware-upload--enables-bitmask"></a>
#### Enables Bitmask

The `enables` field in `kernel_config_msg_t` controls which cores actually run a kernel:
- Bit 0 → BRISC
- Bit 1 → NCRISC
- Bit 2 → TRISC0
- Bit 3 → TRISC1
- Bit 4 → TRISC2

If a core's bit is not set, it skips the kernel call but still participates in the sync protocol.


<a id="firmware-upload--coordination-timeline"></a>
### Coordination Timeline

```
HOST                    BRISC                  NCRISC              TRISC0/1/2
─────                   ─────                  ──────              ──────────
assert reset (all)
upload FW segments
write JAL at L1[0]
write go_msg = INIT
set subordinate PCs
release BRISC          ┌─ boot from L1[0]
                       │  do_crt1, init HW
                       │  sub_sync = ALL_INIT
                       │  deassert_all_reset() ┌─ boot from PC reg  ┌─ boot from PC reg
                       │                       │  do_crt1, init     │  do_crt1, init
                       │                       │  *ncrisc_run=DONE  │  *trisc_run=DONE
                       │  wait sub_sync==0  ◄──┘                 ◄──┘
                       │  go_msg.signal=DONE
poll go_msg==DONE  ◄───┘
                       │  [ready — polling go_msg for GO]

... kernel dispatch ...

write GO to go_msg ──► │  read launch_msg
                       │  sub->dm1 = LOAD ────► wake, load CBs
                       │  invalidate icaches
                       │  sub->trisc* = GO ──────────────────────► wake, read launch_msg
                       │  sub->dm1 = GO ──────► wake (LOAD→GO)
                       │  run BRISC kernel      run NCRISC kernel   run TRISC kernel
                       │  ...                   ...                 ...
                       │                        *ncrisc_run=DONE    tensix_sync()
                       │                                            *trisc_run=DONE
                       │  wait sub_sync==0  ◄── (all done)
                       │  go_msg.signal=DONE
                       │  notify_dispatch_core_done() (NOC atomic)
                       │  advance rd_ptr
                       └─ [loop: poll for next GO]
```

<a id="ldm-layouts"></a>
## LDM (Local Data Memory) Per-Core Layouts
<a id="ldm-layouts--ldm-local-data-memory-per-core-layouts"></a>

<a id="ldm-layouts--overview"></a>
### Overview

Each Tensix tile on Blackhole contains five RISC-V cores: BRISC (data-movement manager), NCRISC (NOC/DRAM data-mover), and three Tensix co-processor cores TRISC0 (unpack), TRISC1 (math), and TRISC2 (pack). Each core has a private SRAM region called Local Data Memory (LDM) that holds per-core state: NOC counters, bank lookup tables, circular-buffer interface descriptors, coordinate variables, and the stack.

All five cores address their LDM at the same virtual base address `0xFFB00000`. The hardware memory router silently redirects each core's accesses to its own physical bank — there is no aliasing between cores. BRISC and NCRISC each have 8 KiB (`0xFFB00000`–`0xFFB01FFF`); TRISC0, TRISC1, and TRISC2 each have 4 KiB (`0xFFB00000`–`0xFFB00FFF`).

The layouts below are verified against Blackhole-compiled ELFs. Offsets are from the `0xFFB00000` base. Sizes are in bytes. Fields at non-obvious offsets are a consequence of the C/C++ struct layout rules applied by the RISC-V `rv32i` toolchain (4-byte natural alignment, no padding inserted by the linker script beyond what the compiler produces).

---

<a id="ldm-layouts--brisc-ldm-8-kib-0xffb000000xffb01fff"></a>
### BRISC LDM (8 KiB: `0xFFB00000`–`0xFFB01FFF`)

| Offset | Symbol | Size | Description |
|--------|--------|------|-------------|
| `0x0000` | `subordinate_sync` | 4 | Pointer to `mailboxes_t.subordinate_sync` in L1 |
| `0x0004` | `my_y[NUM_NOCS]` | 2 | NOC Y coordinate; index 0 = NOC0, index 1 = NOC1 |
| `0x0008` | `my_x[NUM_NOCS]` | 2 | NOC X coordinate |
| `0x000A` | `prev_noc_mode` | 1 | Previous NOC mode (private, updated by NOC mode switch helpers) |
| `0x000B` | `my_relative_y_` | 1 | Relative Y within sub-device |
| `0x000C` | `my_relative_x_` | 1 | Relative X within sub-device |
| `0x000D` | `noc_mode` | 1 | Current NOC mode (private) |
| `0x000E` | (padding) | 2 | Alignment gap |
| `0x0010` | `crta_l1_base` | 4 | Common RTA L1 base address |
| `0x0014` | `rta_l1_base` | 4 | Per-core RTA L1 base address |
| `0x0018` | `noc_posted_writes_num_issued[2]` | 8 | Posted writes issued, per NOC |
| `0x0020` | `noc_nonposted_atomics_acked[2]` | 8 | Nonposted atomics acknowledged, per NOC |
| `0x0028` | `noc_nonposted_writes_acked[2]` | 8 | Nonposted writes acknowledged, per NOC |
| `0x0030` | `noc_nonposted_writes_num_issued[2]` | 8 | Nonposted writes issued, per NOC |
| `0x0038` | `noc_reads_num_issued[2]` | 8 | Reads issued, per NOC |
| `0x0040` | `my_logical_y_` | 1 | Logical Y coordinate |
| `0x0041` | `my_logical_x_` | 1 | Logical X coordinate |
| `0x0042` | `noc_index` | 1 | Active NOC index for this core |
| `0x0043` | (padding) | 1 | Alignment gap |
| `0x0044` | `active_noc_instance` | 4 | Active NOC instance (private) |
| `0x0048` | `dram_bank_to_noc_xy[2][8]` | 32 | DRAM bank → NOC XY table (2 NOCs × 8 banks × `uint16_t`) |
| `0x0068` | `l1_bank_to_noc_xy[2][140]` | 560 | L1 bank → NOC XY table (2 NOCs × 140 banks × `uint16_t`) |
| `0x0298` | `bank_to_dram_offset[8]` | 32 | Per-DRAM-bank byte offset (`uint32_t` × 8) |
| `0x02B8` | `bank_to_l1_offset[140]` | 560 | Per-L1-bank byte offset (`uint32_t` × 140) |
| `0x04E8` | `worker_logical_col_to_virtual_col[20]` | 20 | Logical-to-virtual column translation (`uint8_t` × 20) |
| `0x04FC` | `worker_logical_row_to_virtual_row[12]` | 12 | Logical-to-virtual row translation (`uint8_t` × 12) |
| `0x0508` | `instrn_buf[3]` | 12 | Tensix instruction buffer pointers (private, `uint32_t` × 3) |
| `0x0514` | `sem_l1_base[3]` | 12 | Per-core-type semaphore L1 base (`uint32_t` × 3) |
| `0x0520` | `cb_interface[64]` | 2048 | CB interface array (64 × 32 bytes = `0x800`) |
| `0x0D20` | (BSS end) | — | End of initialized/zeroed data segment |
| `0x07F0` | `__global_pointer$` | — | RISC-V GP register value (set by CRT) |
| `0x2000` | `__stack_top` | — | SP initialized to `0xFFB01FF0` |

---

<a id="ldm-layouts--ncrisc-ldm-8-kib-0xffb000000xffb01fff"></a>
### NCRISC LDM (8 KiB: `0xFFB00000`–`0xFFB01FFF`)

| Offset | Symbol | Size | Description |
|--------|--------|------|-------------|
| `0x0000` | `ncrisc_run` | 4 | Pointer to `subordinate_sync` dm1 byte in L1 mailbox |
| `0x0004` | `noc_reads_num_issued[2]` | 8 | Reads issued, per NOC |
| `0x000C` | `noc_nonposted_writes_num_issued[2]` | 8 | Nonposted writes issued, per NOC |
| `0x0014` | `noc_nonposted_writes_acked[2]` | 8 | Nonposted writes acknowledged, per NOC |
| `0x001C` | `noc_nonposted_atomics_acked[2]` | 8 | Nonposted atomics acknowledged, per NOC |
| `0x0024` | `noc_posted_writes_num_issued[2]` | 8 | Posted writes issued, per NOC |
| `0x002C` | `my_y[2]` | 2 | NOC Y coordinate |
| `0x0030` | `my_x[2]` | 2 | NOC X coordinate |
| `0x0032` | `my_relative_y_` | 1 | Relative Y within sub-device |
| `0x0033` | `my_relative_x_` | 1 | Relative X within sub-device |
| `0x0034` | `crta_l1_base` | 4 | Common RTA L1 base address |
| `0x0038` | `rta_l1_base` | 4 | Per-core RTA L1 base address |
| `0x003C` | `my_logical_y_` | 1 | Logical Y coordinate |
| `0x003D` | `my_logical_x_` | 1 | Logical X coordinate |
| `0x003E` | (padding) | 2 | Alignment gap |
| `0x0040` | `dram_bank_to_noc_xy[2][8]` | 32 | DRAM bank → NOC XY table (2 NOCs × 8 banks × `uint16_t`) |
| `0x0060` | `l1_bank_to_noc_xy[2][140]` | 560 | L1 bank → NOC XY table (2 NOCs × 140 banks × `uint16_t`) |
| `0x0290` | `bank_to_dram_offset[8]` | 32 | Per-DRAM-bank byte offset (`uint32_t` × 8) |
| `0x02B0` | `bank_to_l1_offset[140]` | 560 | Per-L1-bank byte offset (`uint32_t` × 140) |
| `0x04E0` | `worker_logical_col_to_virtual_col[20]` | 20 | Logical-to-virtual column translation (`uint8_t` × 20) |
| `0x04F4` | `worker_logical_row_to_virtual_row[12]` | 12 | Logical-to-virtual row translation (`uint8_t` × 12) |
| `0x0500` | `sem_l1_base[3]` | 12 | Per-core-type semaphore L1 base (`uint32_t` × 3) |
| `0x050C` | `cb_interface[64]` | 2048 | CB interface array (64 × 32 bytes) |
| `0x0D0C` | (BSS end) | — | End of initialized/zeroed data segment |
| `0x07F0` | `__global_pointer$` | — | RISC-V GP register value (set by CRT) |
| `0x2000` | `__stack_top` | — | SP initialized to `0xFFB01FF0` |

---

<a id="ldm-layouts--trisc0--trisc2-ldm-unpack--pack--4-kib-0xffb000000xffb00fff"></a>
### TRISC0 / TRISC2 LDM (Unpack / Pack — 4 KiB: `0xFFB00000`–`0xFFB00FFF`)

TRISC0 (unpack) and TRISC2 (pack) share an identical LDM layout. Both interact with circular buffers, so both carry a full `cb_interface[64]` array.

| Offset | Symbol | Size | Description |
|--------|--------|------|-------------|
| `0x0000` | `ckernel::dest_offset_id` | 4 | Current Dest register half (0 or 1) |
| `0x0004` | `ckernel::op_info_offset` | 4 | Op info offset |
| `0x0008` | `cb_l1_base` | 4 | Pointer to CB config in L1 |
| `0x000C` | `my_relative_y_` | 1 | Relative Y within sub-device |
| `0x000D` | `my_relative_x_` | 1 | Relative X within sub-device |
| `0x000E` | (padding) | 2 | Alignment gap |
| `0x0010` | `crta_l1_base` | 4 | Common RTA L1 base |
| `0x0014` | `rta_l1_base` | 4 | Per-core RTA L1 base |
| `0x0018` | `my_logical_y_` | 1 | Logical Y coordinate |
| `0x0019` | `my_logical_x_` | 1 | Logical X coordinate |
| `0x001A` | (padding) | 2 | Alignment gap |
| `0x001C` | `ckernel::cfg_state_id` | 4 | Active Tensix config state bank (0 or 1) |
| `0x0020` | `cb_interface[64]` | 2048 | CB interface array (64 × 32 bytes) |
| `0x0820` | (BSS end) | — | End of initialized/zeroed data segment |
| `0x07F0` | `__global_pointer$` | — | RISC-V GP register value (set by CRT) |
| `0x1000` | `__stack_top` | — | SP initialized to `0xFFB00FF0` |

---

<a id="ldm-layouts--trisc1-ldm-math--4-kib-0xffb000000xffb00fff"></a>
### TRISC1 LDM (Math — 4 KiB: `0xFFB00000`–`0xFFB00FFF`)

TRISC1 (math) has no CB interface; the math core does not push or pop circular buffer entries directly.

| Offset | Symbol | Size | Description |
|--------|--------|------|-------------|
| `0x0000` | `ckernel::dest_offset_id` | 4 | Current Dest register half (0 or 1) |
| `0x0004` | `ckernel::op_info_offset` | 4 | Op info offset |
| `0x0008` | `my_relative_y_` | 1 | Relative Y within sub-device |
| `0x0009` | `my_relative_x_` | 1 | Relative X within sub-device |
| `0x000A` | (padding) | 2 | Alignment gap |
| `0x000C` | `crta_l1_base` | 4 | Common RTA L1 base |
| `0x0010` | `rta_l1_base` | 4 | Per-core RTA L1 base |
| `0x0014` | `my_logical_y_` | 1 | Logical Y coordinate |
| `0x0015` | `my_logical_x_` | 1 | Logical X coordinate |
| `0x0016` | (padding) | 2 | Alignment gap |
| `0x0018` | `ckernel::cfg_state_id` | 4 | Active Tensix config state bank (0 or 1) |
| `0x001C` | (BSS end) | — | End of initialized/zeroed data segment |
| `0x07F0` | `__global_pointer$` | — | RISC-V GP register value (set by CRT) |
| `0x1000` | `__stack_top` | — | SP initialized to `0xFFB00FF0` |

---

<a id="ldm-layouts--noc-counter-arrays"></a>
### NOC Counter Arrays

Each of the five per-NOC counter variables (`noc_reads_num_issued`, `noc_nonposted_writes_num_issued`, `noc_nonposted_writes_acked`, `noc_nonposted_atomics_acked`, `noc_posted_writes_num_issued`) is a `uint32_t[NUM_NOCS]` array with `NUM_NOCS = 2`. Total size is 8 bytes. Index 0 corresponds to NOC0 and index 1 to NOC1.

At boot, `noc_local_state_init()` reads the hardware NOC status-counter registers for each NOC and stores the values into these LDM arrays. Subsequent NOC operations increment the LDM copies; fence and barrier routines poll the hardware registers and compare against the stored values to determine when outstanding transactions are complete.

Emulator note: the emulator must implement these arrays as per-core LDM state, not as shared global state, because each core tracks its own outstanding NOC transactions independently.

---

<a id="ldm-layouts--cb-interface-array-cb_interface"></a>
### CB Interface Array (`cb_interface`)

The `cb_interface[64]` array stores the local (fast-path) state for up to 64 circular buffers. Each entry is a `LocalCBInterface` struct of exactly 32 bytes comprising 8 `uint32_t` fields:

| Field offset | Field | Description |
|-------------|-------|-------------|
| `+0x00` | `fifo_rd_ptr` | Read pointer (in units of 16 bytes) |
| `+0x04` | `fifo_wr_ptr` | Write pointer (in units of 16 bytes) |
| `+0x08` | `fifo_limit` | End-of-FIFO address (16-byte units) |
| `+0x0C` | `fifo_size` | FIFO size in 16-byte units |
| `+0x10` | `fifo_num_pages` | Number of pages allocated |
| `+0x14` | `fifo_page_size` | Page size in 16-byte units |
| `+0x18` | `tiles_acked` | Running count of tiles consumed by this core |
| `+0x1C` | `tiles_received` | Running count of tiles produced to this core |

Blackhole supports 64 CBs (`NUM_CIRCULAR_BUFFERS = 64`), double the 32-CB limit on Wormhole. The total array size is `64 × 32 = 2048` bytes (`0x800`). TRISC1 (math) does not carry this array because the math core reads operands from the Dest register file rather than CB L1 addresses.

---

<a id="ldm-layouts--bank-lookup-tables"></a>
### Bank Lookup Tables

`noc_bank_table_init()` runs during firmware boot on BRISC and NCRISC. It copies the bank lookup tables from a scratch region in L1 (`MEM_BANK_TO_NOC_SCRATCH = 0x0116B0`) into the corresponding LDM arrays. The L1 scratch region is pre-populated by the host before the cores are released from reset.

<a id="ldm-layouts--table-dimensions-blackhole"></a>
#### Table dimensions (Blackhole)

| Constant | Value | Description |
|----------|-------|-------------|
| `NUM_DRAM_BANKS` | 8 | Physical DRAM channels |
| `NUM_L1_BANKS` | 140 | Addressable L1 worker tiles |
| `NUM_NOCS` | 2 | NOC0 and NOC1 |

<a id="ldm-layouts--dram_bank_to_noc_xy-and-l1_bank_to_noc_xy"></a>
#### `dram_bank_to_noc_xy` and `l1_bank_to_noc_xy`

Type: `uint16_t[NUM_NOCS][NUM_BANKS]`. Each entry encodes a NOC coordinate as a packed 16-bit value:

```
entry = (noc_y << 6) | noc_x
```

Both `noc_x` and `noc_y` are 6-bit fields. The shift constant `6` matches the Blackhole NOC coordinate width. To decode: `x = entry & 0x3F`, `y = (entry >> 6) & 0x3F`.

<a id="ldm-layouts--bank_to_dram_offset-and-bank_to_l1_offset"></a>
#### `bank_to_dram_offset` and `bank_to_l1_offset`

Type: `uint32_t[NUM_BANKS]`. Each entry is the byte offset added to the NOC base address for that bank to produce the canonical address of bank slot 0. Interleaved allocation uses these offsets plus a stride computed at runtime.

---

<a id="ldm-layouts--emulator-implementation-notes"></a>
### Emulator Implementation Notes

The emulator must maintain five separate physical LDM banks, all mapped to the same virtual address `0xFFB00000` from the perspective of each core's address translation. Memory accesses by a core to `0xFFB00000`–`0xFFB01FFF` (BRISC/NCRISC) or `0xFFB00000`–`0xFFB00FFF` (TRISC0/1/2) must be dispatched to that core's private bank, never to any other core's bank.

Before releasing any core from reset, the emulator must pre-populate the L1 scratch region at `MEM_BANK_TO_NOC_SCRATCH` (`0x0116B0`) with the correct bank tables for the simulated topology. The firmware's `noc_bank_table_init()` routine will copy these into LDM; the emulator does not inject the tables directly into LDM.

The `__global_pointer$` symbol at `0x07F0` (relative to LDM base) is the value written to the `gp` register by the CRT startup code. The emulator must initialize `gp` to `0xFFB007F0` for all cores at reset so that GP-relative data accesses resolve correctly. Stack pointers initialize to `0xFFB01FF0` (BRISC/NCRISC) or `0xFFB00FF0` (TRISC0/1/2); the low 4 bytes are reserved by the RISC-V ABI red zone.

---

<a id="ldm-layouts--source-references"></a>
### Source References

| Symbol / file | Location in tt-metal / tt-llk-blackhole |
|---------------|----------------------------------------|
| `noc_local_state_init()` | `tt_metal/hw/inc/noc/noc_parameters.h`, `noc_overlay.h` |
| `noc_bank_table_init()` | `tt_metal/hw/inc/dataflow_api.h` |
| `MEM_BANK_TO_NOC_SCRATCH` | `tt_metal/hw/inc/blackhole/mem_layout.h` |
| `LocalCBInterface` struct | `tt_metal/hw/inc/circular_buffer.h` |
| `NUM_CIRCULAR_BUFFERS` | `tt_metal/hw/inc/blackhole/chlkc_params.h` |
| `NUM_DRAM_BANKS`, `NUM_L1_BANKS` | `tt_metal/hw/inc/blackhole/noc_parameters.h` |
| `ckernel::dest_offset_id`, `cfg_state_id` | `tt_llk_blackhole/llk_lib/llk_defs.h` |
| BRISC linker script | `tt_metal/hw/toolchain/brisc.ld` |
| NCRISC linker script | `tt_metal/hw/toolchain/ncrisc.ld` |
| TRISC linker scripts | `tt_metal/hw/toolchain/trisc0.ld`, `trisc1.ld`, `trisc2.ld` |

<a id="registers"></a>
## Registers: What to Emulate
<a id="registers--registers-what-to-emulate"></a>

Analysis of which CSRs and tile control/debug registers the emulator actually
needs, based on what firmware accesses in practice.

<a id="registers--must-emulate-firmware-breaks-without-these"></a>
### Must Emulate (firmware breaks without these)

<a id="registers--csr-cfg0-0x7c0"></a>
#### CSR: cfg0 (0x7C0)

Every firmware binary (BRISC, NCRISC, all TRISCs) writes this at startup via
`csrrs`/`csrrc`. Always write-only in current firmware (rd=zero), so read-back
value doesn't matter today, but store it correctly anyway.

Firmware sequence (`configure_csr()`):
```
csrrs zero, 0x7c0, 2       # set bit 1 (DisBp)
csrrs zero, 0x7c0, 1<<18   # set bit 18 (DisTrisCache)
csrrc zero, 0x7c0, 2       # clear bit 1
csrrs zero, 0x7c0, 8       # set bit 3 (DisLowCash)
```

Bit fields:

| Bit | Name | Default | Effect |
|-----|------|---------|--------|
| 0 | DisLdBufByp | 0 | Load waits for store queue empty |
| 1 | DisBp | 0 | Disable branch predictor (no effect in emulator) |
| 3 | DisLowCash | 0 | Disable L0 data cache |
| 18 | DisTriscCache | 0 | Disable .ttinsn fusion (no effect in emulator) |
| 24 | DisLowCachePeriodicFlush | 0 | Disable random L0 flush |
| 30 | EnBFloat | 0 | BF16 mode for Zfh instructions |
| 31 | EnBFloatRTNE | 0 | BF16 rounding mode (0=RTZ, 1=RTNE) |

For the emulator, only bits 30-31 have observable effects (they change FPU
behavior). The rest control caches and branch prediction that don't exist in
the emulator.

<a id="registers--soft_reset_0-0xffb121b0"></a>
#### SOFT_RESET_0 (0xFFB121B0)

Core launch sequencer. This must actually control which cores execute.

Boot sequence:
1. Host writes `0x47800` (all cores in reset)
2. Host writes `0x47000` (release BRISC only)
3. BRISC firmware writes `0x00000` (release all cores)

Bit assignments:

| Bit | Target |
|-----|--------|
| 0,1,7 | Unpackers |
| 2-5 | Packers 0-3 |
| 6 | Mover |
| 8 | TDMA-RISC |
| 9 | Scalar Unit + THCON |
| 10 | FPU + SFPU + SrcA |
| 11 | RISCV B (BRISC) |
| 12 | RISCV T0 (TRISC0) |
| 13 | RISCV T1 (TRISC1) |
| 14 | RISCV T2 (TRISC2) |
| 15-17 | SrcA/SrcB ownership, Packer-Dst |
| 18 | RISCV NC (NCRISC) |
| 19-22 | SrcA data columns |
| 23 | Auto TTSync |

Key values:
- `SOFT_RESET_ALL = 0x47800` — all 5 RISC-V cores held in reset
- `SOFT_RESET_BRISC_ONLY_RUN = 0x47000` — TRISCs + NCRISC in reset, BRISC released
- `SOFT_RESET_NONE = 0x00000` — all cores running

For the emulator, bits 11-14 and 18 (the five RISC-V cores) are the ones that
matter. Bits 0-10 and 15-23 control coprocessor blocks and can be tracked but
don't need to gate execution.

<a id="registers--reset_pc-registers"></a>
#### RESET_PC Registers

Written by host during firmware upload to set each core's boot address.

| Address | Register | Who writes |
|---------|----------|------------|
| 0xFFB12228 | TRISC0_RESET_PC | Host |
| 0xFFB1222C | TRISC1_RESET_PC | Host |
| 0xFFB12230 | TRISC2_RESET_PC | Host |
| 0xFFB12234 | TRISC_RESET_PC_OVERRIDE | BRISC (writes 0b111) |
| 0xFFB12238 | NCRISC_RESET_PC | Host |
| 0xFFB1223C | NCRISC_RESET_PC_OVERRIDE | BRISC (writes 0x1) |

The OVERRIDE registers are 1-bit (NCRISC) or 3-bit (TRISCs) enables. When set,
the core uses the programmed RESET_PC instead of the default reset vector.

Implementation: when a core is released from reset (SOFT_RESET_0 bit cleared)
and its override bit is set, start execution at the corresponding RESET_PC value.

<a id="registers--wall_clock-0xffb121f0--0xffb121f8"></a>
#### WALL_CLOCK (0xFFB121F0 / 0xFFB121F8)

TRISC firmware spins in `riscv_wait(600)` reading these at startup. If they
return 0, TRISCs hang forever. Must be monotonically increasing.

| Address | Register | Behavior |
|---------|----------|----------|
| 0xFFB121F0 | WALL_CLOCK_0 | Low 32 bits of 64-bit counter. Reading this latches WALL_CLOCK_1_AT. |
| 0xFFB121F4 | WALL_CLOCK_1 | High 32 bits (live, may change between reads) |
| 0xFFB121F8 | WALL_CLOCK_1_AT | High 32 bits latched at time of WALL_CLOCK_0 read |

There is also an alias at `0xFFB11024` (WALL_CLOCK_L in the TDMA region) which
BRISC writes with value 63 during `device_setup`. The write likely initializes
or configures the clock.

Implementation: track a global cycle counter. On read of WALL_CLOCK_0, return
low 32 bits and snapshot high 32 bits into WALL_CLOCK_1_AT. WALL_CLOCK_1
returns live high bits. The counter should increment with instruction execution
(doesn't need to be cycle-accurate, just monotonically increasing).

<a id="registers--write-sink-no-ops-firmware-writes-never-reads"></a>
### Write-Sink No-ops (firmware writes, never reads)

These registers are written during BRISC `device_setup()` but control clock
gating which is meaningless in an emulator. Accept writes, discard them.

| Address | Register | Value written |
|---------|----------|---------------|
| 0xFFB12240 | DEST_CG_CTRL | 0 |
| 0xFFB12244 | CG_CTRL_EN | 0 |
| 0xFFB11024 | RISCV_TDMA_REG_CLK_GATE_EN | 0x3F |

<a id="registers--return-zero-stubs-specified-not-used-by-current-firmware"></a>
### Return-Zero Stubs (specified, not used by current firmware)

These are defined in the spec or in `ckernel.h` but no firmware binary in the
current disassemblies reads them. Implement as simple registers that return 0
(or a sensible default). User kernels or LLK code may eventually use them.

<a id="registers--standard-risc-v-counters"></a>
#### Standard RISC-V counters

| CSR | Address | Notes |
|-----|---------|-------|
| mcycle | 0xB00 | Cycle counter low. Could return wall clock for correctness. |
| mcycleh | 0xB80 | Cycle counter high. |
| minstret | 0xB02 | Instructions retired low. Could track actual count. |
| minstreth | 0xB82 | Instructions retired high. |

Worth implementing properly since user kernels might use them for profiling.
Returning the wall clock counter for mcycle and an instruction counter for
minstret would be faithful.

<a id="registers--tensix-custom-csrs"></a>
#### Tensix custom CSRs

| CSR | Address | Notes |
|-----|---------|-------|
| tt_cfg_qstatus | 0xBC0 | Queue status. 0 = queues empty (safe for emulation). |
| tt_cfg_bstatus | 0xBC1 | Backend busy. 0 = not busy (safe for emulation). |
| tt_cfg_sstatus0-7 | 0xBC2-0xBC9 | Stream status (T0/T1/T2) or scratch (B/NC). |
| intp_restore_pc | 0xBCA | Interrupt return PC. Only matters with interrupt emulation. |

For `tt_cfg_qstatus` and `tt_cfg_bstatus`, returning 0 means "not busy" which
is correct for an emulator that executes coprocessor ops synchronously.

The `tt_cfg_sstatus` registers are scratch space for BRISC/NCRISC. For TRISCs
they reflect stream state which would need real stream emulation to be useful.

<a id="registers--defer-entirely-profilerdebug-only"></a>
### Defer Entirely (profiler/debug only)

Not needed for functional emulation. Implement only if adding profiling or
debug tool support.

| Address | Register | Used by |
|---------|----------|---------|
| 0xFFB120B4 | FPU_STICKY_BITS | LLK math layer (not startup firmware) |
| 0xFFB12054 | DBG_BUS_CTRL | Host `read_risc_pc()` debug function |
| 0xFFB1205C | DBG_BUS_RD_DATA | Host `read_risc_pc()` debug function |
| 0xFFB12000-0x124 | PERF_CNT_* | Profiler builds only |
| 0xFFB12218 | PERF_CNT_MUX_CTRL | Profiler builds only |
| 0xFFB12070 | CG_CTRL_HYST0 | Power management (dead code in rvir path) |
| 0xFFB12074 | CG_CTRL_HYST1 | Power management (dead code in rvir path) |
| 0xFFB1207C | CG_CTRL_HYST2 | Power management (dead code in rvir path) |
| 0xFFB121D0 | ECC_CTRL | Not accessed by firmware |
| 0xFFB121D4 | ECC_STATUS | Not accessed by firmware |
| 0xFFB121E0 | WATCHDOG_TIMER | Not accessed by firmware |

<a id="registers--summary"></a>
### Summary

| Priority | Count | Registers |
|----------|-------|-----------|
| Must work | 8 | cfg0, SOFT_RESET_0, 4x RESET_PC, 2x RESET_PC_OVERRIDE, WALL_CLOCK_0/1_AT |
| Write sinks | 3 | DEST_CG_CTRL, CG_CTRL_EN, CLK_GATE_EN |
| Return-zero stubs | 10 | mcycle/h, minstret/h, qstatus, bstatus, sstatus0-7, intp_restore_pc |
| Defer | ~12 | Perf counters, debug bus, FPU sticky, ECC, watchdog, etc. |
