# Firmware Upload Sequence

How blackhole-py loads firmware onto every Tensix worker core at device initialization, before any kernel can run.

## The five firmware binaries

Each Tensix core has 5 RISC-V processors. Each gets its own firmware binary, compiled from the same tt-metal firmware sources with different `-D` flags:

| Processor | Source | NOC index | Role |
|-----------|--------|-----------|------|
| BRISC | `brisc.cc` | NOC 1 | Master processor. Boots first, manages mailboxes, releases others. Runs writer dataflow kernels. |
| NCRISC | `ncrisc.cc` | NOC 0 | Runs reader dataflow kernels. Controls NOC 0 for DRAM reads. |
| TRISC0 | `trisc.cc -DCOMPILE_FOR_TRISC=0` | — | Unpack: moves tiles from CB into DST registers. |
| TRISC1 | `trisc.cc -DCOMPILE_FOR_TRISC=1` | — | Math: SFPI/FPU compute (the actual neural net math). |
| TRISC2 | `trisc.cc -DCOMPILE_FOR_TRISC=2` | — | Pack: moves results from DST registers into output CB. |

These are compiled once at `Device()` construction via `compile_firmware()` (cached in `~/.cache/tt-metal-cache/`). The ELFs are parsed for PT_LOAD segments, which tell us where each chunk of code/data goes in L1.

## Upload sequence (per core)

`CommonDevice.upload_firmware()` iterates over every worker core and performs the following TLB writes. Each core is programmed individually (no mcast for firmware upload — each core must be independently reset and configured).

### 1. Hold all RISCs in reset

```
TLB write -> register 0xFFB121B0 (RISCV_DEBUG_REG_SOFT_RESET_0)
  Value: 0x47800 (SOFT_RESET_ALL)
  Bits: BRISC(11) + TRISC0(12) + TRISC1(13) + TRISC2(14) + NCRISC(18) = all held
```

All 5 RISC-V cores are now halted. Their program counters are frozen, and they won't execute anything until selectively released.

### 2. Upload firmware segments to L1

For each of the 5 firmware binaries, the ELF's PT_LOAD segments are written to L1:

```
For each firmware target (brisc, ncrisc, trisc0, trisc1, trisc2):
  For each PT_LOAD segment:
    if segment.paddr is in LOCAL_RAM (0xFFB00000..0xFFB01FFF):
      # Local RAM (fast scratchpad) isn't directly accessible from host.
      # Redirect to a scratch area in L1 that BRISC will copy on boot.
      dest = INIT_LOCAL_L1_BASE_SCRATCH[target] + (paddr - 0xFFB00000)
    else:
      dest = segment.paddr  # directly into L1

    TLB write -> L1 dest, len(segment.data) bytes
```

The scratch areas for local-RAM relocation:

| Target | Scratch base | Purpose |
|--------|-------------|---------|
| BRISC | 0x0082B0 | Overlaps KERNEL_CONFIG_BASE (reused after init) |
| NCRISC | 0x00A2B0 | |
| TRISC0 | 0x00C2B0 | |
| TRISC1 | 0x00D2B0 | |
| TRISC2 | 0x00E2B0 | |

The firmware's startup code copies data from these scratch areas into actual local RAM once the processor starts.

The main firmware code lives at dedicated L1 addresses:

| Target | Text base |
|--------|----------|
| BRISC | 0x003840 |
| NCRISC | 0x005440 |
| TRISC0 | 0x005A40 |
| TRISC1 | 0x006040 |
| TRISC2 | 0x006640 |

### 3. Write BRISC boot trampoline at address 0

BRISC has no configurable reset PC — it always starts executing from L1 address 0x0. So we place a JAL (jump-and-link) instruction there:

```
TLB write -> L1 0x000000
  Data: JAL instruction -> 0x003840 (BRISC_FIRMWARE_BASE)
  Size: 4 bytes (one RISC-V instruction)
```

This is a `generate_jal_instruction()` call that encodes a RISC-V J-type immediate for the target offset.

### 4. Set initial GO_MSG to RUN_MSG_INIT

```
TLB write -> L1 0x000370 (GO_MSG)
  Data: [0x00, 0x00, 0x00, 0x40]
  Meaning: GoMsg { signal = 0x40 (RUN_MSG_INIT), master_x=0, master_y=0 }
```

When BRISC boots, it reads this mailbox. `RUN_MSG_INIT` (0x40) tells BRISC to:
1. Copy local-RAM data from scratch areas
2. Initialize the mailbox system
3. Set `signal = 0x00` (RUN_MSG_DONE) to indicate it's idle and ready

### 5. Set reset PCs for NCRISC and TRISCs

Unlike BRISC, the other 4 processors have configurable reset PC registers:

```
TLB write -> register 0xFFB12238 (NCRISC_RESET_PC)  = ncrisc.text_base  (0x5440)
TLB write -> register 0xFFB12228 (TRISC0_RESET_PC)  = trisc0.text_base  (0x5A40)
TLB write -> register 0xFFB1222C (TRISC1_RESET_PC)  = trisc1.text_base  (0x6040)
TLB write -> register 0xFFB12230 (TRISC2_RESET_PC)  = trisc2.text_base  (0x6640)
```

These processors will start executing from these addresses when released from reset.

### 6. Write DRAM/L1 bank translation tables

```
TLB write -> L1 0x0112B0 (MEM_BANK_TO_NOC_SCRATCH)
  Data: ~700 bytes
  Contents:
    [14 x u16]  DRAM bank NOC XY coordinates (7 banks x 2 NOCs)
    [220 x u16] L1 bank NOC XY coordinates (110 banks x 2 NOCs)
    [7 x i32]   DRAM bank address offsets
    [110 x i32] L1 bank address offsets
```

These tables are used by `InterleavedAddrGenFast` in kernel code. When a kernel calls `noc_async_read_tile(tile_id, ...)`, the firmware uses these tables to translate a logical tile ID into a physical NOC address + DRAM channel.

The P100A has one harvested DRAM bank, so the translation table accounts for the gap — logical bank IDs map to physical NOC tiles with the dead bank skipped.

### 7. Release BRISC from reset

```
TLB write -> register 0xFFB121B0 (SOFT_RESET_0)
  Value: 0x47000 (SOFT_RESET_BRISC_ONLY_RUN)
  Bits: TRISC0(12) + TRISC1(13) + TRISC2(14) + NCRISC(18) still held
        BRISC(11) released
```

Only BRISC starts running. It executes the JAL at address 0, jumps to its firmware at 0x3840, reads `GO_MSG = RUN_MSG_INIT`, performs initialization, then writes `GO_MSG = RUN_MSG_DONE`. NCRISC and TRISCs remain in reset until a kernel launch.

### 8. Wait for firmware ready

```
Host polls (via TLB read):
  L1 0x000373 (GO_MSG + 3, the signal byte)
  Until: value == 0x00 (RUN_MSG_DONE)
  Timeout: 2 seconds
```

Once BRISC writes `RUN_MSG_DONE`, the core is ready to accept kernel launches.

## CQ firmware upload (fast dispatch only)

When using fast dispatch, two cores are repurposed as the **prefetch** and **dispatch** cores. After all worker firmware is uploaded and ready, `FastDevice._start_dispatch_cores()` uploads CQ firmware to these two cores.

### Topology

| Role | NOC coord | Processor | NOC index |
|------|-----------|-----------|-----------|
| Prefetch | (14, 2) | BRISC | NOC 0 |
| Dispatch | (14, 3) | BRISC | NOC 1 |
| Dispatch subordinate | (14, 3) | NCRISC | NOC 1 |

The dispatch core runs both BRISC and NCRISC — BRISC handles the main dispatch loop (processing commands, writing to worker L1, sending GO signals), while NCRISC handles subordinate tasks (completion tracking, host event writes).

### CQ firmware upload sequence

For each CQ core, `_upload_cq_core()` performs:

```
1. TLB write -> L1 0x0082B0 (KERNEL_CONFIG_BASE)
   Data: kernel_cfg_image (runtime args + semaphore init values)
   - Prefetch sems: [DEV_DISPATCH_CB_PAGES=128, 0]
   - Dispatch sems: [0, 0]

2. TLB write -> L1 0x0082B0 + kernel_off
   Data: CQ kernel XIP binaries
   - Prefetch: prefetch_brisc.xip (polls prefetch queue, DMA-reads from sysmem)
   - Dispatch: dispatch_brisc.xip (processes dispatch commands, writes to workers)
   - Dispatch: dispatch_s_ncrisc.xip (subordinate: completion handling)

3. TLB write -> L1 0x000070 (LAUNCH)
   Data: LaunchMsg with CQ-specific config:
     mode = DISPATCH_MODE_HOST (1)
     enables = BRISC (prefetch) or BRISC+NCRISC (dispatch)
     kernel_text_offset pointing to the uploaded XIP offsets

4. TLB write -> L1 0x000370 (GO_MSG)
   Data: GoMsg { signal = 0x80 (RUN_MSG_GO) }
```

For the dispatch core specifically, `_init_dispatch_core_state()` first initializes:

```
- DEV_COMPLETION_Q_WR_PTR = initial completion queue write pointer
- DEV_COMPLETION_Q_RD_PTR = initial completion queue read pointer
- Dispatch sync semaphores = all zeroed
```

After GO, the CQ firmware starts running and enters its main polling loops:
- **Prefetch BRISC**: polls the prefetch queue at L1 0x19840 for new entries, DMA-reads records from host sysmem, writes them into the dispatch core's circular buffer via NOC
- **Dispatch BRISC**: reads commands from its CB, executes them (WRITE_PACKED, WAIT, GO_SIGNAL, etc.)
- **Dispatch NCRISC**: handles stream 48 completion counting and host event writes

## L1 memory map after firmware upload

```
0x000000  [JAL -> 0x3840]         BRISC boot trampoline
0x000060  MAILBOX_BASE            Mailbox region start
0x000070  LAUNCH                  LaunchMsg (88 bytes)
0x000370  GO_MSG                  GoMsg (4 bytes) — firmware/kernel state
0x0003A0  GO_MSG_INDEX            Go message index
0x0009C0  PROFILER_CONTROL        Profiler control vector (128 bytes)
0x003840  BRISC_FIRMWARE_BASE     BRISC firmware code
0x005440  NCRISC_FIRMWARE_BASE    NCRISC firmware code
0x005A40  TRISC0_BASE             TRISC0 firmware code
0x006040  TRISC1_BASE             TRISC1 firmware code
0x006640  TRISC2_BASE             TRISC2 firmware code
0x0082B0  KERNEL_CONFIG_BASE      Runtime args + CB config + kernel XIP images
0x0112B0  MEM_BANK_TO_NOC_SCRATCH DRAM/L1 bank translation tables
0x037000  DATA_BUFFER_SPACE_BASE  Circular buffer data region
          ...
0x180000  L1 END (1.5 MB)
```

Firmware lives in the 0x3840–0x82B0 region. Kernel code (uploaded per-launch) lives above 0x82B0. The two regions don't overlap — firmware is persistent across kernel launches, kernel images are overwritten each time.
