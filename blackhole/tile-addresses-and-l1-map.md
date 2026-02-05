# Blackhole (P100a) tile write addresses for pure-python bring-up

This is a quick map of the NOC coordinates and per-tile address offsets you need to upload kernels, set up CBs, and poke ARC/DRAM/ETH tiles from a minimal Python driver. All values are taken from headers in this repo.

All addresses below are **offsets inside the tile's local address space**. When using a TLB window, set `TLBConfig.addr` to the offset and use the tile's NOC `(x, y)` coordinates.

## 1) Tile coordinates (NOC0)

Use these vectors to pick `(x, y)` coordinates:

- Tensix tiles: `TENSIX_CORES_NOC0` and `TENSIX_GRID_SIZE` in `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp`.
- DRAM tiles (bank/port layout): `DRAM_CORES_NOC0` in `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp`.
- ARC tile: `ARC_CORES_NOC0` (single entry, `(8, 0)`).
- Ethernet tiles: `ETH_CORES_NOC0`.
- PCIe tiles: `PCIE_CORES_NOC0`.

DRAM layout summary (NOC0):

- Bank 0 ports: `(0, 0)`, `(0, 1)`, `(0, 11)`
- Bank 1 ports: `(0, 2)`, `(0, 10)`, `(0, 3)`
- Bank 2 ports: `(0, 9)`, `(0, 4)`, `(0, 8)`
- Bank 3 ports: `(0, 5)`, `(0, 7)`, `(0, 6)`
- Bank 4 ports: `(9, 0)`, `(9, 1)`, `(9, 11)`
- Bank 5 ports: `(9, 2)`, `(9, 10)`, `(9, 3)`
- Bank 6 ports: `(9, 9)`, `(9, 4)`, `(9, 8)`
- Bank 7 ports: `(9, 5)`, `(9, 7)`, `(9, 6)`

DRAM bank grouping (Blackhole):

- There are **8 DRAM banks**, each **4 GiB**, for **32 GiB total**.
- Each bank is fronted by **3 DRAM tiles** (3 ports), and **all 3 tiles expose the same 4 GiB**.
- The bank→tile mapping is exactly the `DRAM_CORES_NOC0` list above (3 coordinates per bank).

## 2) Tensix L1 address map (kernel + CB work)

L1 size on Blackhole is `0x180000` (1536 KiB). The offsets below are **per Tensix tile**.

Key L1 offsets (hex):

```
FIRMWARE_BASE                    0x000000
ZEROS_BASE                       0x002100
NCRISC_FIRMWARE_BASE             0x005000
NCRISC_L1_CODE_BASE              0x009000
NCRISC_LOCAL_MEM_BASE            0x00c000
TRISC0_BASE                      0x00d000
TRISC0_LOCAL_MEM_BASE            0x011000
TRISC1_BASE                      0x012000
TRISC1_LOCAL_MEM_BASE            0x015000
TRISC2_BASE                      0x016000
TRISC2_LOCAL_MEM_BASE            0x01a000
EPOCH_RUNTIME_CONFIG_BASE        0x023000
OVERLAY_BLOB_BASE                0x023080
NCRISC_L1_RUNTIME_SECTION_BASE   0x033000
NCRISC_L1_SCRATCH_BASE           0x033200
NCRISC_L1_CONTEXT_BASE           0x033020
NCRISC_L1_DRAM_POLLING_CTRL_BASE 0x033040
NCRISC_PERF_QUEUE_HEADER_ADDR    0x034000
NCRISC_L1_PERF_BUF_BASE          0x034040
NCRISC_L1_EPOCH_Q_BASE           0x035000
DATA_BUFFER_SPACE_BASE           0x037000
L1_BARRIER_BASE                  0x16dfc0
```

Practical use:

- **Kernel upload**: write TRISC code to `TRISC0_BASE`, `TRISC1_BASE`, `TRISC2_BASE`. If you are using the overlay blob flow, write the compiled overlay blob at `OVERLAY_BLOB_BASE`.
- **Runtime config**: `EPOCH_RUNTIME_CONFIG_BASE` holds epoch/runtime data written by host/firmware.
- **CB backing storage**: allocate your circular buffer backing memory from `DATA_BUFFER_SPACE_BASE` upward.
- **Mailbox + launch**: the low-level launch/go mailboxes live in L1 at `MEM_MAILBOX_BASE` from `dev_mem_map.h` (used by `dev_msgs.h`).

## 3) Circular buffers (CBs) in L1

CBs have two parts:

1) **Backing storage** (tiles) in L1 data space:
   - Place these in `DATA_BUFFER_SPACE_BASE..0x180000` on the target Tensix tile.

2) **CB config entries** in L1:
   - The firmware reads the CB config array from
     `kernel_config_base + kernel_config.local_cb_offset`.
   - Each local CB config is 4 words: `fifo_addr`, `fifo_size`, `fifo_num_pages`, `fifo_page_size`.
   - These offsets and sizes are defined in `tt-metal/tt_metal/hw/inc/internal/circular_buffer_interface.h`.

