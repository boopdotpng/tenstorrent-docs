# pure-py DRAM read returns zeros (InterleavedAddrGenFast / bank tables)

Baseline: `pure-py` commit `c5a6165c8bbd1e6dcdef5ba70372171dbd03e3e4`

## Symptom
- The `add1_sfpu` style pipeline runs, but the reader appears to fetch zeros from the `src` DRAM buffer.
- Compute adds `1.0` to zeros, so `dst` becomes all `1.0` (bf16 `0x3f80`), and verification fails like:
  - `mismatch at bf16[0]: src=0.84375 exp=1.84375 got=1 (src_bf16=0x3f58 exp_bf16=0x3fec got_bf16=0x3f80)`
- Host-side DRAM writes + host-side DRAM reads appear to work (TLB to DRAM tiles is fine), and host reads back `dst` correctly (all `1.0`), so the write path is plausibly correct while the read path is wrong.

## What InterleavedAddrGenFast actually depends on
In tt-metal, `InterleavedAddrGenFast<true>` (DRAM) does **not** hardcode DRAM NoC endpoints.
It computes the DRAM NoC address using per-core tables:

- `dram_bank_to_noc_xy[noc][bank_index]`
- `bank_to_dram_offset[bank_index]`

Source: `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h`:
- `interleaved_addr_gen::get_noc_xy<true>(bank_index, noc)` reads `dram_bank_to_noc_xy`.
- `interleaved_addr_gen::get_bank_offset<true>(bank_index)` reads `bank_to_dram_offset`.

Those tables live in each RISC-V core’s local memory (BSS) and are populated by firmware at boot via:
- `noc_bank_table_init(MEM_BANK_TO_NOC_SCRATCH)`

Source: `tt-metal/tt_metal/hw/inc/internal/firmware_common.h`

And `MEM_BANK_TO_NOC_SCRATCH` is a *scratch region in L1* that the host (tt-metal) fills before cores use it.

## Why this is a likely root cause in pure-py
In the pure-py flow, we upload firmware and then immediately start running kernels, but we never explicitly replicate tt-metal’s step that seeds the bank-to-NoC tables (and related scratch tables).

If `dram_bank_to_noc_xy` / `bank_to_dram_offset` are wrong (or wrong for the NoC the reader uses), `InterleavedAddrGenFast` can point NCRISC reads at the wrong DRAM endpoint/bank/offset and return zeros.

One particularly suspicious detail in `pure-py/codegen.py`:
- BRISC kernels are compiled with `-DNOC_INDEX=0`
- NCRISC kernels are compiled with `-DNOC_INDEX=1`

So even if NoC0 bank tables happen to be valid, NoC1 bank tables might not be (or might require different endpoint/translation), yielding “reads return zeros” while writes (on NoC0) still appear correct.

## Confirmed table sizes (from firmware ELF symbols)
On p100a firmware (`pure-py/riscv-firmware/p100a/brisc.elf`), `nm --print-size` shows:
- `bank_to_dram_offset` size `0x1c` => `7` entries (int32)
- `bank_to_l1_offset` size `0x1b8` => `110` entries (int32)

This matches `pure-py/codegen.py` defaults (`NUM_DRAM_BANKS=7`, `NUM_L1_BANKS=110`) and reinforces that the *ordering* and *contents* of these tables matter: “bank_index 0..6” is **not** “physical bank-id 0..7 minus harvested” unless the host generated it that way.

## Attempts so far (WIP)
WIP patches attempted to seed `MEM_BANK_TO_NOC_SCRATCH` during firmware upload (before releasing BRISC), by writing a `dram_bank_to_noc_xy` blob derived from `tt-metal/tt_metal/soc_descriptors/blackhole_140_arch.yaml` (`dram_views[*].worker_endpoint`).

Outcome: kernels started timing out / device got into a bad state, requiring resets.

Likely reasons the “write scratch tables” approach wedged things:
- `MEM_BANK_TO_NOC_SCRATCH` is a packed blob: `dram_bank_to_noc_xy` + `l1_bank_to_noc_xy` + `bank_to_dram_offset` + `bank_to_l1_offset`. Writing the wrong size/offset can corrupt the following tables.
- Blackhole has NoC coordinate translation knobs; feeding “raw” vs “virtual” coords incorrectly can break NoC routing.
- NoC1 coordinate transforms (`noc1` origin flip) can be easy to get subtly wrong.

At the moment, the safe conclusion is: **seeding these tables is necessary, but it needs to be done exactly the way tt-metal does it**.

## Next debugging steps (highest signal)
1. Quick experiment: compile NCRISC with `NOC_INDEX=0` (same as BRISC) and re-run the minimal repro.
   - If the DRAM read becomes correct, the issue is almost certainly “NoC1 bank tables / NoC1 addressing.”
2. Add a tiny NCRISC kernel that:
   - reads a single 32-bit word from `src` (tile 0, offset 0)
   - writes it to a known L1 address (or mailbox debug area) that the host reads back
   This isolates “DRAM read returned 0” from “compute path turned it into 1”.
3. Long-term fix: replicate tt-metal’s host-side initialization:
   - `MetalContext::generate_device_bank_to_noc_tables`
   - `MetalContext::initialize_device_bank_to_noc_tables`
   - (and possibly) `initialize_worker_logical_to_virtual_tables`
   Source: `tt-metal/tt_metal/impl/context/metal_context.cpp`

## Reset notes
If the device wedges during experiments, resetting via:
- `source ~/tenstorrent/.venv/bin/activate && tt-smi -r`
is the fastest recovery path.

---

## Deep dive: How tt-metal populates the bank tables (2026-01-20)

### Memory layout of MEM_BANK_TO_NOC_SCRATCH

Address: `MEM_BANK_TO_NOC_SCRATCH = MEM_MAP_END + init_scratch_sizes`

For Blackhole, tracing through `dev_mem_map.h`:
```
MEM_MAP_END                          = 0x0082b0  (same as pure-py KERNEL_CONFIG_BASE)
MEM_BRISC_INIT_LOCAL_L1_BASE_SCRATCH = MEM_MAP_END
MEM_NCRISC_INIT_LOCAL_L1_BASE_SCRATCH= +0x2000
MEM_TRISC0_INIT_LOCAL_L1_BASE_SCRATCH= +0x2000
MEM_TRISC1_INIT_LOCAL_L1_BASE_SCRATCH= +0x1000
MEM_TRISC2_INIT_LOCAL_L1_BASE_SCRATCH= +0x1000
MEM_NCRISC_INIT_IRAM_L1_BASE_SCRATCH = +0x1000
MEM_BANK_TO_NOC_SCRATCH              = +0x2000  → 0x0112b0
```

The scratch region is 2048 bytes (`MEM_BANK_TO_NOC_SIZE = MEM_BANK_TO_NOC_XY_SIZE + MEM_BANK_OFFSET_SIZE = 1024 + 1024`).

### Table layout within the scratch region

From `firmware_common.h:noc_bank_table_init()`:

```
Offset 0:    dram_bank_to_noc_xy[NUM_NOCS][NUM_DRAM_BANKS]  (uint16_t)
             Size: 2 * 7 * 2 = 28 bytes (for p100a)

Offset 28:   l1_bank_to_noc_xy[NUM_NOCS][NUM_L1_BANKS]      (uint16_t)
             Size: 2 * 110 * 2 = 440 bytes

Offset 468:  bank_to_dram_offset[NUM_DRAM_BANKS]            (int32_t)
             Size: 7 * 4 = 28 bytes

Offset 496:  bank_to_l1_offset[NUM_L1_BANKS]                (int32_t)
             Size: 110 * 4 = 440 bytes

Total: 936 bytes (well under the 2048 limit)
```

### NOC XY encoding (Blackhole)

From `noc_parameters.h`:
- `NOC_ADDR_NODE_ID_BITS = 6` (6 bits per coordinate)
- `NOC_COORD_REG_OFFSET = 0` (no shift)

The 16-bit XY encoding is:
```c
uint16_t xy = (noc_y << 6) | noc_x;
```

From `metal_context.cpp:1040`:
```cpp
uint16_t xy = ((noc_y << hal_->get_noc_addr_node_id_bits()) | noc_x)
              << hal_->get_noc_coord_reg_offset();
```

### How tt-metal computes DRAM bank coordinates

Source: `metal_context.cpp:generate_device_bank_to_noc_tables()` lines 996-1056.

**Step 1: Get the DRAM view for each bank**

The YAML `soc_descriptors/blackhole_140_arch.yaml` defines:
```yaml
dram:
  [
    [0-0, 0-1, 0-11],   # bank 0: 3 endpoints at x=0, y=0,1,11
    [0-2, 0-10, 0-3],   # bank 1
    ...
    [9-5, 9-7, 9-6],    # bank 7
  ]

dram_views:
  - channel: 0
    worker_endpoint: [2, 1]   # [noc0_subchannel, noc1_subchannel]
    address_offset: 0
  - channel: 1
    worker_endpoint: [0, 1]
  ...
```

For bank 0:
- `channel=0` → dram array index 0 = `[0-0, 0-1, 0-11]`
- `worker_endpoint[0]=2` → subchannel 2 → coordinate `(0, 11)` for NoC0
- `worker_endpoint[1]=1` → subchannel 1 → coordinate `(0, 1)` for NoC1

**Step 2: Apply NOC coordinate transformation (if DRAM not virtualized)**

```cpp
bool dram_is_virtualized = noc_translation_enabled &&
    hal_->get_virtualized_core_types().contains(DRAM);

if (dram_is_virtualized) {
    // Use coordinates as-is from YAML
    noc_x = dram_noc_coord.x;
    noc_y = dram_noc_coord.y;
} else {
    // Apply per-NoC transformation
    noc_x = hal_->noc_coordinate(noc, grid_size.x, dram_noc_coord.x);
    noc_y = hal_->noc_coordinate(noc, grid_size.y, dram_noc_coord.y);
}
```

The `noc_coordinate` transformation for Blackhole:
```cpp
// noc_index 0: identity
// noc_index 1: mirror (grid_size - 1 - coord)
return noc_index == 0 ? coord : (noc_size - 1 - coord);
```

For Blackhole grid 17x12:
- NoC0: `(0, 11)` → `(0, 11)`
- NoC1: `(0, 1)` → `(16, 10)` (mirrored: `17-1-0=16`, `12-1-1=10`)

**Step 3: Pack into 16-bit encoding**

```cpp
uint16_t xy = ((noc_y << 6) | noc_x);
```

For bank 0:
- NoC0: `xy = (11 << 6) | 0 = 0x02C0`
- NoC1: `xy = (10 << 6) | 16 = 0x0290`

### What pure-py needs to implement

**1. Compute MEM_BANK_TO_NOC_SCRATCH address**

Add to `configs.py`:
```python
class TensixL1:
    # ... existing ...
    MEM_BANK_TO_NOC_SCRATCH = 0x0112b0  # After all init scratch areas
```

**2. Build the bank table blob**

In `device.py`, add a method to generate the tables:

```python
def _build_bank_noc_tables(self) -> bytes:
    NUM_NOCS = 2
    NUM_DRAM_BANKS = 7  # p100a (1 harvested from 8)
    NUM_L1_BANKS = 110

    # DRAM coordinates from soc_descriptors/blackhole_140_arch.yaml
    # Format: dram[channel] = [(x, y), ...] for 3 subchannels
    DRAM_COORDS = {
        0: [(0, 0), (0, 1), (0, 11)],
        1: [(0, 2), (0, 10), (0, 3)],
        2: [(0, 9), (0, 4), (0, 8)],
        3: [(0, 5), (0, 7), (0, 6)],
        4: [(9, 0), (9, 1), (9, 11)],
        5: [(9, 2), (9, 10), (9, 3)],
        6: [(9, 9), (9, 4), (9, 8)],
        7: [(9, 5), (9, 7), (9, 6)],
    }
    # worker_endpoint[noc] = subchannel index for each channel
    WORKER_EP = {
        0: [2, 1], 1: [0, 1], 2: [0, 1], 3: [0, 1],
        4: [2, 1], 5: [2, 1], 6: [2, 1], 7: [2, 1],
    }
    GRID_X, GRID_Y = 17, 12

    def noc_coord(noc, grid_size, coord):
        return coord if noc == 0 else (grid_size - 1 - coord)

    def pack_xy(x, y):
        return ((y << 6) | x) & 0xFFFF

    # Build unharvested channel list
    channels = [c for c in range(8) if c != self.harvested_dram]

    # dram_bank_to_noc_xy[NUM_NOCS][NUM_DRAM_BANKS]
    dram_xy = []
    for noc in range(NUM_NOCS):
        for bank_id, ch in enumerate(channels):
            subchan = WORKER_EP[ch][noc]
            raw_x, raw_y = DRAM_COORDS[ch][subchan]
            x = noc_coord(noc, GRID_X, raw_x)
            y = noc_coord(noc, GRID_Y, raw_y)
            dram_xy.append(pack_xy(x, y))

    # l1_bank_to_noc_xy - for now, just use worker cores in order
    # (A proper impl would match tt-metal's L1BankingAllocator)
    l1_xy = []
    for noc in range(NUM_NOCS):
        for bank_id in range(NUM_L1_BANKS):
            # Simplified: map bank to tensix core
            col = bank_id % len(self.tiles.tensix_cols)
            row = bank_id // len(self.tiles.tensix_cols)
            raw_x = self.tiles.tensix_cols[col]
            raw_y = 2 + (row % 10)  # tensix rows 2-11
            x = noc_coord(noc, GRID_X, raw_x)
            y = noc_coord(noc, GRID_Y, raw_y)
            l1_xy.append(pack_xy(x, y))

    # bank_to_dram_offset - all zeros for simple interleaving
    dram_offsets = [0] * NUM_DRAM_BANKS

    # bank_to_l1_offset - all zeros for now
    l1_offsets = [0] * NUM_L1_BANKS

    # Pack into bytes
    import struct
    blob = b""
    blob += struct.pack(f"<{len(dram_xy)}H", *dram_xy)
    blob += struct.pack(f"<{len(l1_xy)}H", *l1_xy)
    blob += struct.pack(f"<{len(dram_offsets)}i", *dram_offsets)
    blob += struct.pack(f"<{len(l1_offsets)}i", *l1_offsets)
    return blob
```

**3. Write tables during firmware upload (BEFORE releasing BRISC)**

In `device.py:upload_firmware()`, add after writing firmware but before `SOFT_RESET_BRISC_ONLY_RUN`:

```python
# Write bank-to-noc tables to scratch area
bank_tables = self._build_bank_noc_tables()
win.write(TensixL1.MEM_BANK_TO_NOC_SCRATCH, bank_tables, use_uc=True, restore=False)
```

### Key gotchas

1. **Table ordering**: The tables are packed sequentially with no padding. Getting offsets wrong corrupts subsequent tables.

2. **NOC coordinate flip**: NoC1 coordinates are mirrored on Blackhole. Forgetting this makes NoC1 reads/writes go to wrong endpoints.

3. **Harvesting**: The `channels` list must skip the harvested DRAM bank. Bank index in the table != physical bank ID.

4. **Timing**: Tables MUST be written before BRISC starts, because `noc_bank_table_init()` runs during BRISC init.

5. **L1 banks**: The L1 bank mapping is more complex in tt-metal (uses `L1BankingAllocator`). For pure-py's current use case (single-core DRAM read/write), a simplified mapping may suffice.

### Verification approach

After implementing, verify with a minimal kernel that:
1. Reads `dram_bank_to_noc_xy[0][0]` and `dram_bank_to_noc_xy[1][0]` from NCRISC local memory
2. Writes them to a known L1 address
3. Host reads back and confirms expected values (`0x02C0` and `0x0290` for bank 0)

If those match, DRAM reads via `InterleavedAddrGenFast` should work correctly.

---

## Solution: Use NOC0 for NCRISC (2026-01-20)

### Root cause discovered

The bank tables were being populated correctly, but the real issue was **NOC translation is not enabled** on the device.

On Blackhole:
- BRISC uses NOC0 (`noc_index=0`)
- NCRISC uses NOC1 (`noc_index=1`)
- Host writes DRAM via NOC0 (TLB points to NOC0 address space)

Without NOC translation enabled (checked via `NIU_CFG_0 bit 14`), NOC0 and NOC1 have different coordinate systems:
- NOC0: Direct coordinates (e.g., `(0, 11)` for DRAM bank 0)
- NOC1: Mirrored coordinates (`grid_size - 1 - coord`)

This means when NCRISC reads from DRAM using NOC1, even with "correct" mirrored coordinates in the bank tables, it reads from a different physical location than where the host wrote via NOC0.

### Verification

Changed `codegen.py` line 196 from:
```python
noc_index = 0 if is_brisc else 1
```
to:
```python
noc_index = 0
```

Result: **Test Passed** - NCRISC now reads from the same physical DRAM addresses that the host wrote to.

### Final fix

In `codegen.py`, use NOC0 for both BRISC and NCRISC:

```python
# Use NOC0 for both BRISC and NCRISC. Without NOC translation enabled (NIU_CFG_0 bit 14),
# NOC1 uses a different coordinate space (mirrored), so reads would access wrong addresses.
# tt-metal requires NOC translation for Blackhole (FW >= 80.18.0.0), but pure-py uses NOC0 only.
noc_index = 0
```

### Why this works

All data movement now uses NOC0:
- Host writes via TLB → NOC0 address space
- BRISC writes via NOC0
- NCRISC reads via NOC0

The bank tables in `MEM_BANK_TO_NOC_SCRATCH` still need to be populated (for `InterleavedAddrGenFast` to work), but only the NOC0 entries matter now.

### Tradeoffs

Using NOC0 for everything may have bandwidth implications since both BRISC and NCRISC share the same NoC network. For pure-py's current single-core test workloads, this is not a concern.

tt-metal enables NOC translation during device initialization (requires FW >= 80.18.0.0 for Blackhole), allowing both NoC networks to be used with virtual coordinates. pure-py avoids this complexity by using NOC0 only.

