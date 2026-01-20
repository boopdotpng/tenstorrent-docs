# Blackhole pure-py: DRAM bank tables must use translated DRAM coordinates

This notes the root cause + fix for the “NOC1 nonposted writes hang / no ACK” issue when running `pure-py/main.py` on Blackhole (p100a) with:

- NCRISC doing DRAM reads on **NOC0**
- BRISC doing DRAM writes on **NOC1**

## Symptom

The writer kernel reaches `noc_async_write_tile()` but hangs in `noc_async_write_barrier()`:

- `np_wr_sent = 1`
- `wr_ack = 0`

## Root cause

`pure-py` was building the `dram_bank_to_noc_xy` table in **physical DRAM tile coordinates** (e.g. `(0,11)`, `(9,3)`), and it also treated `dram_views[].worker_endpoint` as if it was indexed by **physical DRAM channel**.

That is incorrect for Blackhole when NOC translation / coordinate virtualization is enabled (it is on by default after `tt-smi -r`):

1) **DRAM destination coordinates are expected in a “translated DRAM coordinate space”**, not the physical grid.

In tt-umd this is `BlackholeCoordinateManager::fill_dram_noc0_translated_mapping()` and uses:

- `dram_translated_coordinate_start_x = 17`
- `dram_translated_coordinate_start_y = 12`
- `NUM_NOC_PORTS_PER_DRAM_BANK = 3`

So you’ll see DRAM endpoints like `(18,14)` or `(17,23)` in the bank table, not `(0,11)`.

2) **`dram_views[].channel` is a logical DRAM bank id** (post-harvest compaction), not a physical channel id.

With one harvested bank, bank ids shift. If you index `worker_endpoint` by physical channel you pick the wrong subchannel for some banks.

## Fix in pure-py

`pure-py/device.py` now builds `dram_bank_to_noc_xy` to match tt-metal:

- Uses the tt-umd Blackhole mapping for logical `(bank_id, port)` → translated `(x,y)` in DRAM space.
- Applies `worker_endpoint` using the *logical* bank id.
- Keeps the translation-disabled path using physical coords + NOC1 mirroring.

After this change, the repro `tt-smi -r` then `pure-py/main.py` succeeds with BRISC on NOC1.

## References

- tt-umd DRAM translated coord scheme:
  - `tt-metal/tt_metal/third_party/umd/device/coordinates/blackhole_coordinate_manager.cpp`
  - `tt-metal/tt_metal/third_party/umd/device/api/umd/device/arch/blackhole_implementation.hpp`
- tt-metal uses translated DRAM coords in bank tables:
  - `tt-metal/tt_metal/impl/context/metal_context.cpp` (`generate_device_bank_to_noc_tables`)
