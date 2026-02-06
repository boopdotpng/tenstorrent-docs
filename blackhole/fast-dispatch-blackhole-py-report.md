# Fast Dispatch: Architecture, Implementation, and Mismatches

Research report comparing tt-metal's fast dispatch implementation with blackhole-py's.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [The Dispatch Pipeline](#the-dispatch-pipeline)
3. [Which Cores Are Used](#which-cores-are-used)
4. [The JAL Trampoline](#the-jal-trampoline)
5. [Firmware Upload Sequence](#firmware-upload-sequence)
6. [Dispatch Firmware ELFs](#dispatch-firmware-elfs)
7. [Command Queue Memory Layout](#command-queue-memory-layout)
8. [Command Flow](#command-flow)
9. [Mismatches and Bugs](#mismatches-and-bugs)
10. [Key File Reference](#key-file-reference)

---

## Architecture Overview

Fast dispatch avoids the slow host-PCIe-per-core path by dedicating **on-chip Tensix cores** to run command relay firmware. The host writes commands into pinned system memory; a **prefetcher** core DMA-reads those commands via PCIe/NoC and forwards them to a **dispatcher** core, which interprets them and writes to worker cores at wire speed over the NoC.

Three logical roles, **two physical Tensix cores**:

| Role | Processor | Physical Core | Source (tt-metal) |
|------|-----------|---------------|-------------------|
| **Prefetch** | BRISC (RISCV_0) | Core A | `cq_prefetch.cpp` |
| **Dispatch** | BRISC (RISCV_0) | Core B | `cq_dispatch.cpp` |
| **Dispatch Subordinate** | NCRISC (RISCV_1) | Core B (shared) | `cq_dispatch_subordinate.cpp` |

Dispatch and dispatch_s share one Tensix core: dispatch runs on BRISC using NOC_0, subordinate runs on NCRISC using NOC_1. This is enforced by a static_assert in tt-metal.

### Kernel Variants (tt-metal multi-chip)

For multi-chip setups, tt-metal splits these into more specialized variants:

- **PREFETCH_HD** -- host+DRAM on single chip (reads from host, reads from DRAM)
- **PREFETCH_H** -- host-only on MMIO chip (forwards to remote via fabric)
- **PREFETCH_D** -- DRAM-only on remote chip (receives from fabric)
- **DISPATCH_HD** -- single chip (interprets commands + writes completions)
- **DISPATCH_H** -- host-side for remote (writes completions from remote)
- **DISPATCH_D** -- device-side for remote (dispatches to local workers)
- **DISPATCH_S** -- subordinate (go-signal sender, overlaps with next dispatch)

blackhole-py only implements the single-chip HD variants.

---

## The Dispatch Pipeline

### Single-chip, 1 Command Queue

```
Host Memory (pinned sysmem, 16 MiB default)
  ┌─────────────────────────────────────┐
  │ [ptr area 256B] [issue 8MiB] [completion 4MiB] │
  └──────────────┬──────────────────────┘
                 │ PCIe DMA read (NOC_0)
                 v
  ┌──────────────────────────┐
  │ PREFETCH_HD (BRISC)      │  Core A
  │ - polls prefetch_q for   │
  │   new command sizes       │
  │ - DMA-reads cmd+data     │
  │   from host issue queue  │
  │ - relays pages to        │
  │   dispatcher ring buffer │
  └──────────────┬───────────┘
                 │ NoC write to L1 ring buffer
                 v
  ┌──────────────────────────┐
  │ DISPATCH_HD (BRISC)      │  Core B (BRISC)
  │ - processes commands:    │
  │   WRITE_LINEAR, WAIT,   │
  │   SEND_GO_SIGNAL, etc.  │
  │ - writes kernel bins,   │
  │   RT args, CBs, launch  │
  │   msgs to worker L1     │
  │ - writes completions    │
  │   back to host sysmem   │
  └──────────────┬───────────┘
                 │ notification via semaphore
                 v
  ┌──────────────────────────┐
  │ DISPATCH_S (NCRISC)      │  Core B (NCRISC)
  │ - sends go signals to   │
  │   worker cores (NOC_1)  │
  │ - overlaps go-signal    │
  │   send with next        │
  │   program dispatch      │
  └──────────────┬───────────┘
                 │ NoC multicast
                 v
  ┌──────────────────────────┐
  │ Worker Cores (all other  │
  │ Tensix)                  │
  └──────────────────────────┘
```

### Multi-chip (N300/T3000/Galaxy) -- tt-metal only

```
Host ─> PREFETCH_HD (local) ─> workers
     ─> PREFETCH_H  (MMIO) ─> FABRIC_MUX ─> ethernet ─> PREFETCH_D (remote) ─> DISPATCH_D ─> workers
                                                                                    │
     <─ DISPATCH_H (MMIO) <── RETURN_MUX <── ethernet <─────────────────────────────┘
```

---

## Which Cores Are Used

**Dispatch cores are regular Tensix cores** -- there is no special-purpose hardware. They are strategically chosen from the **edge** of the compute grid to preserve contiguous rectangular compute area.

### tt-metal core selection

Defined in YAML descriptors at `tt_metal/core_descriptors/`:

| Architecture | Axis | Dispatch Location | Config File |
|---|---|---|---|
| Blackhole (no fabric) | **COL** | Rightmost column (col 13), rows 0-9 = **10 cores** | `blackhole_140_arch.yaml` |
| Blackhole (fabric) | ROW | Last row | `blackhole_140_arch_fabric_mux.yaml` |
| Blackhole (ETH) | -- | All 14 ETH cores | `blackhole_140_arch_eth_dispatch.yaml` |
| Wormhole B0 | **ROW** | Bottom row (row 9), cols 0-7 = **8 cores** | `wormhole_b0_80_arch.yaml` |

The YAML uses **relative coordinates** (`[-1, 0]` = last column, row 0). The `dispatch_core_manager` allocates from this pool FIFO at runtime. For a single-chip 1-CQ setup, only 2 cores are consumed.

Axis selection logic (`dispatch_core_common.cpp:15-20`):
- Blackhole (no fabric): COL -- losing 1 of 14 columns (7%) is better than 1 of 10 rows (10%)
- Everything else: ROW

### blackhole-py core selection

`device_dispatch.py:428-439`:
```python
def _select_dispatch_cores(self):
    y0, _ = self.tiles.TENSIX_Y
    y1 = y0 + 1
    # pick rightmost column where both rows exist
    candidates = [x for x in sorted(worker_x, reverse=True)
                  if self._core_exists((x, y0)) and self._core_exists((x, y1))]
    x = candidates[0]
    return (x, y0), (x, y1)  # (prefetch_core, dispatch_core)
```

Takes the **rightmost valid column**, picks two adjacent rows. The two cores are in the **same column, different rows**. This is slightly different from tt-metal which takes cores from a pre-defined pool spanning the entire edge column.

### Answer: Are they "two arbitrary Tensix cores"?

No. They are **any functional Tensix cores**, but chosen from the grid edge by convention. The hardware has no requirement for specific cores -- the strategy is purely about maximizing contiguous compute area.

---

## The JAL Trampoline

**BRISC has a hardcoded reset PC of 0x0 on Blackhole** -- there is no reset PC register for BRISC (unlike NCRISC/TRISC which have programmable reset PC registers at `RISCV_DEBUG_REG_*_RESET_PC`).

Both codebases solve this by writing a RISC-V `JAL x0, <firmware_base>` instruction at L1 address 0x0. When BRISC comes out of reset, it executes this single-instruction bootloader trampoline and jumps to the real firmware.

### tt-metal implementation

`hal.cpp:111-134`:
```cpp
uint32_t generate_risc_startup_addr(uint32_t firmware_base) {
    // BRISC always starts executing at address 0x0.
    // Write a JAL instruction there that jumps to firmware_base.
    constexpr uint32_t jal_opcode = 0x6f;
    uint32_t jal_offset_bits_10_to_1 = (firmware_base & 0x7fe) << 20;
    uint32_t jal_offset_bit_11 = (firmware_base & 0x800) << 9;
    uint32_t jal_offset_bits_19_to_12 = (firmware_base & 0xff000) << 0;
    // bit 20 is sign bit, always 0 for small positive offsets
    return jal_offset | jal_opcode;
}
```

Written for **ALL Tensix cores** (worker AND dispatch) at `metal_context.cpp:1263-1267`.

### blackhole-py implementation

`helpers.py:73-79`:
```python
def generate_jal_instruction(target_addr: int) -> int:
    opcode = 0x6F
    imm_10_1 = (target_addr & 0x7FE) << 20
    imm_11 = (target_addr & 0x800) << 9
    imm_19_12 = target_addr & 0xFF000
    return imm_19_12 | imm_11 | imm_10_1 | opcode
```

Written for worker cores at `device_runtime.py:133`:
```python
win.write(0x0, jal_insn.to_bytes(4, "little"), use_uc=True, restore=False)
```

**Not written for dispatch cores** -- see [Mismatches](#mismatches-and-bugs).

---

## Firmware Upload Sequence

### Worker cores (both codebases -- identical flow)

1. Assert full soft reset (`SOFT_RESET_ALL = 0x47800`) on all 5 RISC-V cores
2. Write all firmware ELF segments to L1 (brisc, ncrisc, trisc0/1/2)
   - Segments with `paddr` in `0xFFB00000-0xFFB01FFF` (local RAM) are relocated to L1 scratch areas
3. **Write JAL at address 0x0** (jumps to `BRISC_FIRMWARE_BASE = 0x3840`)
4. Write go message with `RUN_MSG_INIT` (0x40)
5. Set NCRISC/TRISC reset PC registers via MMIO debug registers
6. Write bank-to-NOC mapping tables
7. Release BRISC only (`SOFT_RESET_BRISC_ONLY_RUN = 0x47000`)
8. BRISC starts at PC=0 -> hits JAL -> jumps to 0x3840 -> runs init
9. BRISC releases NCRISC and TRISCs from firmware
10. All cores complete init, BRISC writes `RUN_MSG_DONE`
11. Host polls for `RUN_MSG_DONE`

### Dispatch cores -- tt-metal approach

tt-metal loads **standard base firmware** on dispatch cores during device init (same as workers). The dispatch kernels are then loaded **later** as a "program" via the standard kernel compilation + program launch pipeline:

1. `initialize_firmware()` -- loads brisc.elf/ncrisc.elf/etc. on ALL cores including dispatch
2. `compile_cq_programs()` -- compiles cq_prefetch.cpp etc. from C++ source using RISC-V toolchain
3. `configure_dispatch_cores()` -- writes initial L1 state (completion queue ptrs, semaphores)
4. Launches dispatch program onto reserved cores via slow dispatch (direct L1 writes)
5. Base firmware receives the program, sets up kernel config, runs it

### Dispatch cores -- blackhole-py approach

blackhole-py takes a shortcut: it **skips base firmware entirely** on dispatch cores and loads the pre-compiled dispatch ELFs directly:

1. `_firmware_skip_cores()` returns `{prefetch_core, dispatch_core}` -- excluded from `upload_firmware()`
2. `_start_dispatch_cores()` (device_dispatch.py:519-574):
   a. Load dispatch ELFs (cq_prefetch_brisc.elf, cq_dispatch_brisc.elf, cq_dispatch_subordinate_ncrisc.elf)
   b. Assert `SOFT_RESET_ALL` on both cores
   c. Write ELF segments to L1 (with local RAM relocation)
   d. Write bank-to-NOC tables
   e. Build launch message with kernel config, RT args, semaphore values
   f. Write GO messages: `RESET_READ_PTR_FROM_HOST` (0xE0) then `RUN_MSG_GO` (0x80)
   g. Set NCRISC reset PC to subordinate entry point (dispatch core only)
   h. Release prefetch: BRISC only (`0x47000`)
   i. Release dispatch: BRISC + NCRISC (`0x7000`)
   j. Sleep 10ms

This works because the dispatch ELFs are self-contained -- they include their own `_start`/crt0 code (BSS clearing, data copy, NOC init, GO message polling).

---

## Dispatch Firmware ELFs

### Origin

The dispatch ELFs in `riscv-firmware/p100a/` are **byte-identical copies from tt-metal's build cache** at `~/.cache/tt-metal-cache/`. They were compiled by tt-metal's kernel compilation pipeline from:

| ELF | Source | Processor |
|-----|--------|-----------|
| `cq_prefetch_brisc.elf` (2.5 MiB) | `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` | BRISC |
| `cq_dispatch_brisc.elf` (1.2 MiB) | `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` | BRISC |
| `cq_dispatch_subordinate_ncrisc.elf` (247 KiB) | `tt_metal/impl/dispatch/kernels/cq_dispatch_subordinate.cpp` | NCRISC |

Confirmed via DWARF debug info (`DW_AT_comp_dir`) and MD5 hash matching.

There is no build script in blackhole-py for these -- they are manually copied.

### ELF Structure

Each dispatch ELF is self-contained with its own `_start` function:
- `cq_prefetch_brisc.elf`: `_start` at `0x49F0`, calls `kernel_main_hd()` at `0xAA0C`
- `cq_dispatch_brisc.elf`: `_start` at `0x49F0`, calls `kernel_main()` at `0x4F30`
- `cq_dispatch_subordinate_ncrisc.elf`: `_start` at `0x5880`

The `_start` functions handle: BSS zeroing, `.data` copy from LMA, NOC counter init, GO message polling, then call into the dispatch kernel main function.

### Base firmware ELFs (for reference)

| ELF | L1 Load Address | Init Scratch Base |
|-----|-----------------|-------------------|
| `brisc.elf` | `0x003840` | `0x0082B0` |
| `ncrisc.elf` | `0x005440` | `0x00A2B0` |
| `trisc0.elf` | `0x005A40` | `0x00C2B0` |
| `trisc1.elf` | `0x006040` | `0x00D2B0` |
| `trisc2.elf` | `0x006640` | `0x00E2B0` |

---

## Command Queue Memory Layout

### Host Side (`_HostCQ`)

16 MiB pinned anonymous mmap, pinned with `IOCTL_PIN_PAGES` for NOC DMA.

```
Offset   Size      Content
0x000    256 B     Reserved pointers (issue rd/wr, completion wr/rd, each 64B-aligned)
0x100    8 MiB     Issue queue (host -> device commands)
0x800100 4 MiB     Completion queue (device -> host completions)
```

### Device Side (`_DeviceCQ`)

L1 base: `0x196C0` (BH_TENSIX_DEFAULT_UNRESERVED)

```
Offset   Size      Content
+0x00    4 B       Prefetch queue read pointer
+0x04    4 B       Prefetch queue PCIe read pointer
+0x10    4 B       Completion queue write pointer
+0x20    4 B       Completion queue read pointer
+0x30    4 B       Completion queue 0 last event pointer
+0x40    4 B       Completion queue 1 last event pointer
+0x50    128 B     Dispatch_S sync semaphore (8 x 16B)
+0x180   3068 B    Prefetch queue (1534 x 2B entries)
~+0xD80  256 KiB   Command data queue (cmddat_q)
~+4D80   128 KiB   Scratch double-buffer
         512 KiB   Dispatch circular buffer (128 x 4096B pages)
```

### Synchronization

- **Prefetch <-> Dispatch**: Two semaphores (`page_ready`, `page_done`) for ring buffer flow control
- **Dispatch <-> Workers**: Stream registers (`STREAM_REMOTE_DEST_BUF_SPACE_AVAILABLE`) as lightweight semaphores
- **Dispatch <-> Dispatch_S**: Sync semaphore + NOC inline writes

---

## Command Flow

### Command Protocol

Commands are 16 bytes (or 32 bytes for "large" variants), defined in `cq_commands.hpp`.

**Prefetcher commands** (`CQPrefetchCmdId`):
- `RELAY_INLINE (5)` -- relay inline data to dispatcher
- `RELAY_LINEAR` -- relay data from a linear DRAM address
- `RELAY_PAGED` -- relay paged DRAM data
- `EXEC_BUF` -- execute a command buffer
- `STALL` -- stall until dispatcher catches up
- `TERMINATE` -- shutdown

**Dispatcher commands** (`CQDispatchCmdId`):
- `WRITE_LINEAR (1)` -- write data to NOC address (unicast/multicast)
- `WRITE_PAGED` -- write banked/paged data
- `WRITE_PACKED` -- write to multiple cores
- `WRITE_PACKED_LARGE` -- write large payloads to multiple cores
- `WAIT` -- wait for worker completion semaphores
- `SEND_GO_SIGNAL` -- multicast go signals
- `WRITE_LINEAR_H_HOST` -- write data back to host
- `TERMINATE` -- shutdown

### Host -> Device Write Flow (blackhole-py)

`_FastCQ.enqueue_write_linear()` at `device_dispatch.py:175-195`:

```
1. Build inner CQDispatchCmd (WRITE_LINEAR):
   [cmd_id=1, noc_xy, addr, length, num_mcast_dests]  (32 bytes)

2. Wrap in outer CQPrefetchCmd (RELAY_INLINE):
   [cmd_id=5, length=inner+payload]  (16 bytes)

3. Full record = [CQPrefetchCmd 16B] [CQDispatchCmd 32B] [payload] [pad to 64B]

4. Write record into host sysmem issue ring buffer

5. Write 2-byte prefetch_q entry (size in 16B units) to prefetch core's L1

6. Prefetch firmware polls prefetch_q, DMA-reads the record from host sysmem,
   relays to dispatcher's ring buffer

7. Dispatch firmware processes the command, NoC-writes payload to target core
```

---

## Mismatches and Bugs

### 1. CRITICAL: Missing JAL at 0x0 for dispatch cores

**tt-metal** writes the JAL trampoline at L1 address 0x0 for **ALL** Tensix cores, including dispatch cores (`metal_context.cpp:1263-1267`).

**blackhole-py** writes the JAL only for worker cores (`device_runtime.py:133`). The `_start_dispatch_cores()` method (`device_dispatch.py:519-574`) never writes a JAL at address 0x0.

BRISC's reset PC is **hardcoded to 0**. Without a JAL at 0x0, BRISC will execute whatever is at L1[0x0] (likely zeros = illegal instruction, or stale data). The dispatch ELFs' `_start` is at `0x49F0`, well beyond address 0.

**If fast dispatch currently works**, it may be because:
- The dispatch ELF happens to have a loadable segment covering address 0x0
- L1 has stale firmware from a previous upload that left a valid JAL there
- Address 0x0 happens to contain something that doesn't immediately fault

**Fix:** Add `win.write(0x0, generate_jal_instruction(entry).to_bytes(4, "little"), ...)` in `_start_dispatch_cores()` for each dispatch core, where `entry` is the ELF entry point.

### 2. Different firmware loading strategy (by design, but with implications)

| Aspect | tt-metal | blackhole-py |
|--------|----------|--------------|
| Base FW on dispatch cores | Yes -- standard brisc/ncrisc/trisc | No -- skipped via `_firmware_skip_cores()` |
| Dispatch kernel loading | Compiled from source, loaded as "program" on top of base FW | Pre-compiled ELFs loaded directly, replacing base FW |
| Go signal for dispatch | Base FW uses `RUN_MSG_INIT` (0x40) during init; dispatch program launched later | Goes straight to `RESET_READ_PTR` (0xE0) then `GO` (0x80) |

This is an intentional simplification in blackhole-py. The dispatch ELFs are self-contained (include their own crt0), so they don't need the base firmware. However, any tt-metal firmware update that changes the init handshake or crt0 behavior will silently break the copied ELFs.

### 3. NCRISC release timing

| | tt-metal | blackhole-py |
|---|----------|--------------|
| **Worker cores** | BRISC released first; BRISC firmware releases NCRISC/TRISC | Same |
| **Dispatch core** | Same as workers (base FW handles it) | BRISC + NCRISC released **simultaneously** (`SOFT_RESET_BRISC_NCRISC_RUN = 0x7000`) |

For dispatch cores, blackhole-py releases both BRISC and NCRISC at the same time because there's no base firmware to orchestrate the staged release. This should be fine since the dispatch ELFs handle their own init independently, but it means NCRISC starts executing before BRISC has finished its init. If there's any shared state dependency, this could be a race.

### 4. Dispatch core selection differences

- **tt-metal**: Pre-defined pool from YAML, rightmost column (all 10 rows), FIFO allocation
- **blackhole-py**: Rightmost column where **two adjacent rows** exist, always picks the first two rows

Functionally equivalent for single-chip 1-CQ, but blackhole-py's approach wouldn't scale to multi-CQ or fabric without changes.

### 5. No dispatch core wait/readiness check

tt-metal waits for `RUN_MSG_DONE` after firmware init. blackhole-py just `time.sleep(0.01)` after releasing dispatch cores. If the cores take longer than 10ms to initialize, the host could start issuing commands before dispatch firmware is ready.

### 6. Pre-compiled ELF staleness risk

The dispatch ELFs are manually copied from tt-metal's build cache. If tt-metal updates `cq_prefetch.cpp`, `cq_dispatch.cpp`, or `cq_dispatch_subordinate.cpp` (or the firmware support library, memory map, command structures, etc.), the blackhole-py ELFs become silently stale. There is no version check or build script.

---

## Key File Reference

### blackhole-py

| File | Purpose |
|------|---------|
| `device_dispatch.py:428-439` | `_select_dispatch_cores()` -- core selection |
| `device_dispatch.py:441-443` | `_firmware_skip_cores()` -- exclude dispatch cores from base FW |
| `device_dispatch.py:470-504` | `_load_dispatch_elf()`, `_write_dispatch_segs()`, `_build_dispatch_launch()` |
| `device_dispatch.py:519-574` | `_start_dispatch_cores()` -- dispatch firmware upload and launch |
| `device_dispatch.py:576-639` | `FastDevice.run()` -- enqueue kernel launch via command queue |
| `device_dispatch.py:89-211` | `_FastCQ` -- host-side command queue manager |
| `device_dispatch.py:42-70` | `_device_cq_layout()` -- device-side CQ memory layout |
| `device_runtime.py:75-170` | `upload_firmware()` -- worker firmware upload with JAL |
| `helpers.py:73-79` | `generate_jal_instruction()` -- RISC-V JAL encoder |
| `defs.py:233-263` | `FastDispatch` constants |
| `defs.py:265-301` | CQ command structures |
| `riscv-firmware/p100a/` | Pre-compiled firmware ELFs |

### tt-metal

| File | Purpose |
|------|---------|
| `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` | Prefetcher firmware source |
| `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` | Dispatcher firmware source |
| `tt_metal/impl/dispatch/kernels/cq_dispatch_subordinate.cpp` | Subordinate firmware source |
| `tt_metal/impl/dispatch/kernels/cq_commands.hpp` | Command structures (host + device) |
| `tt_metal/impl/dispatch/dispatch_core_manager.cpp` | Runtime dispatch core allocation |
| `tt_metal/impl/dispatch/topology.cpp` | Dispatch kernel graph per board config |
| `tt_metal/impl/dispatch/kernel_config/prefetch.cpp` | Prefetch kernel compile config |
| `tt_metal/impl/dispatch/kernel_config/dispatch.cpp` | Dispatch kernel compile config |
| `tt_metal/impl/dispatch/kernel_config/dispatch_s.cpp` | Dispatch_S kernel config + core sharing |
| `tt_metal/impl/dispatch/dispatch_settings.hpp` | Buffer sizes, page sizes |
| `tt_metal/impl/dispatch/hardware_command_queue.cpp` | Host-side HW command queue |
| `tt_metal/impl/context/metal_context.cpp:1214-1357` | Firmware upload to all cores |
| `tt_metal/llrt/hal.cpp:111-134` | `generate_risc_startup_addr()` -- JAL encoder |
| `tt_metal/llrt/hal/tt-1xx/blackhole/bh_hal_tensix.cpp` | BH HAL config (reset PCs, FW bases) |
| `tt_metal/core_descriptors/blackhole_140_arch.yaml` | BH dispatch core positions |
| `tt_metal/hw/firmware/src/tt-1xx/brisc.cc` | BRISC base firmware (init + main loop) |
| `tt_metal/hw/firmware/src/tt-1xx/ncrisc.cc` | NCRISC base firmware |
| `tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h` | Memory map constants |
| `tt_metal/hw/inc/hostdev/dev_msgs.h` | Go/launch message structures |
