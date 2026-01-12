# Blackhole (P100a) tile write addresses for pure-python bring-up

This is a quick map of the NOC coordinates and per-tile address offsets you need to upload kernels, set up CBs, and poke ARC/DRAM/ETH tiles from a minimal Python driver. All values are taken from headers in this repo; the references are listed at the end.

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
   - These offsets and sizes are defined in `tt-metal/tt_metal/hw/inc/internal/circular_buffer_interface.h`
     and consumed in `tt-metal/tt_metal/hw/inc/internal/circular_buffer_init.h`.

If you build a minimal launch packet (see `dev_msgs.h`), you need to:

- Set `kernel_config_base[ProgrammableCoreType::TENSIX]` to the base of your per-core config region in L1.
- Set `local_cb_offset` to the CB config array offset inside that region.
- Point CB `fifo_addr` at your chosen `DATA_BUFFER_SPACE_BASE` allocations.

CB config details (local CBs):

- Each local CB config entry is 4 words: `fifo_addr`, `fifo_size`, `fifo_num_pages`, `fifo_page_size`.
- The firmware reads CB configs from `kernel_config_base + local_cb_offset`, and only for CB IDs enabled in `local_cb_mask`.

## 4) Dataflow kernels (BRISC + NCRISC) placement

Dataflow kernels run on BRISC (writer) and NCRISC (reader) for each Tensix tile. On Blackhole, their code is placed in the **firmware block** at the bottom of L1, not in a separate BRISC-only region in `l1_address_map.h`.

Relevant L1 offsets:

- `FIRMWARE_BASE = 0x000000` (start of firmware block)
- `BRISC_FIRMWARE_SIZE = 7*1024 + 512 + 768` (BRISC code lives at the start of the firmware block)
- `NCRISC_FIRMWARE_BASE = FIRMWARE_BASE + FIRMWARE_SIZE = 0x005000`

Host-side placement is defined in `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h`:

- `MEM_BRISC_FIRMWARE_BASE`
- `MEM_NCRISC_FIRMWARE_BASE`
- `MEM_TRISC0_FIRMWARE_BASE`, `MEM_TRISC1_FIRMWARE_BASE`, `MEM_TRISC2_FIRMWARE_BASE`

Launch-time selection is via `kernel_config_msg_t` in `tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h`:

- Each processor uses `kernel_lma = kernel_config_base + kernel_text_offset[index]`.
- Firmware reads those offsets in:
  - `tt-metal/tt_metal/hw/firmware/src/tt-1xx/brisc.cc`
  - `tt-metal/tt_metal/hw/firmware/src/tt-1xx/ncrisc.cc`
  - `tt-metal/tt_metal/hw/firmware/src/tt-1xx/trisc.cc`

Practical guidance for pure‑py:

- Place BRISC/NCRISC code blobs at offsets you choose inside your per‑core L1 kernel region.
- Set `kernel_text_offset[BRISC]` and `kernel_text_offset[NCRISC]` accordingly in the launch message.
- Ensure those offsets point inside the L1 firmware block (or wherever your `kernel_config_base` points) and don’t overlap the CB config/data region.

Which kernels do you need?

- **L1‑only compute** (no DRAM): upload **TRISC0** only, prefill CBs in L1, skip NCRISC/BRISC.
- **DRAM streaming**: upload **NCRISC** (reader), **TRISC0** (compute), **BRISC** (writer).
- TRISC1/2 are only needed if your compute kernel explicitly uses them.

## 5) DRAM tiles

DRAM tiles use the DRAM NOC coordinates listed in section 1. Offsets inside DRAM are linear from base:

- DRAM base offset: `0x0`
- DRAM barrier base: `0x0` (used for host->device barriers)
- DRAM peer-to-peer region start (channel 0): `0x30000000`

Firmware-visible DRAM layout for kernel blobs (if you need it):

- `TRISC0_BASE`, `TRISC1_BASE`, `TRISC2_BASE` in DRAM are 0, `MEM_TRISC0_SIZE`, `MEM_TRISC1_SIZE`, respectively.
- `OVERLAY_BLOB_BASE` follows TRISC2 in DRAM.
- See `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/dram_address_map.h`.

Host ↔ DRAM access (pure‑py):

- BARs expose **TLB windows**, not a flat DRAM aperture.
- To write/read DRAM, you must map a **TLB window** to a **DRAM tile coordinate** and a **bank offset**.
- “Global memory” is just your own mapping of (bank, offset). If you want linear global space, you must interleave across banks yourself.

## 6) Ethernet tiles (ERISC L1)

ERISC L1 offsets (per ETH tile):

```
FIRMWARE_BASE             0x009040
L1_EPOCH_Q_BASE           0x009000
L1_DRAM_POLLING_CTRL_BASE 0x009020
COMMAND_Q_BASE            0x011000
DATA_BUFFER_BASE          0x012000
TILE_HEADER_BUFFER_BASE   0x018000
EPOCH_RUNTIME_CONFIG_BASE 0x020000
OVERLAY_BLOB_BASE         0x020080
DATA_BUFFER_SPACE_BASE    0x028000
ERISC_BARRIER_BASE        0x011fe0
```

## 6) ARC tile (optional bring-up)

ARC is at NOC0 `(8, 0)`. The scratch registers used by bring-up and telemetry are offsets in the ARC reset unit:

- `SCRATCH_RAM_2`  (ARC boot status)
- `SCRATCH_RAM_11` (ARC message queue control block pointer)
- `SCRATCH_RAM_12` / `SCRATCH_RAM_13` (telemetry table/data pointers)

Offsets are defined in `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp` and used by KMD/UMD:

- ARC APB BAR0 window: `ARC_APB_BAR0_XBAR_OFFSET_START = 0x1FF00000`
- Reset unit base: `ARC_RESET_UNIT_OFFSET = 0x30000`
- `SCRATCH_RAM_2 = ARC_RESET_UNIT_OFFSET + 0x408`
- `SCRATCH_RAM_11 = ARC_RESET_UNIT_OFFSET + 0x42C`
- `SCRATCH_RAM_12 = ARC_RESET_UNIT_OFFSET + 0x430`
- `SCRATCH_RAM_13 = ARC_RESET_UNIT_OFFSET + 0x434`

For ARC messaging, KMD uses:

- `ARC_MSG_QCB_PTR = SCRATCH_RAM_11`
- `ARC_MSI_FIFO = 0x800B0000` (write 0 to trigger ARC)

## 7) Multicast behavior

- Multicast applies **only** to NOC transactions that go through a TLB configured with `mcast=1` and a rectangle `(x_start..x_end, y_start..y_end)`.
- A multicast **write** is replicated to every NOC endpoint in that rectangle. Reads are not multicast.
- Be careful not to include non‑Tensix tiles in the rectangle unless you intend to write to them.

## 8) What is the “Tensix coprocessor”?

- The “coprocessor” is the **math/SFPU/pack/unpack datapath inside each Tensix tile**.
- TRISCs run the control program (ckernel) that configures and drives that datapath; they do not execute the math themselves.

## 9) CPU tiles (L2CPU/Security)

- The “CPU tiles” in the middle are **L2CPU / Security / ARC** tiles, used for management.
- You can ignore them for Tensix kernel bring‑up.

## 10) If you scribble on L1 firmware

- Overwriting firmware/mailbox regions can hang a tile or the chip.
- Recovery is usually a **reset** (tt‑smi reset or KMD reset), worst‑case a **power‑cycle**.
- Keep experimental writes inside `DATA_BUFFER_SPACE_BASE..L1 end` on Tensix tiles.

## 11) PCIe DMA vs MMIO on Blackhole

- On Blackhole, UMD **does not support PCIe DMA** for host↔device transfers; it throws or falls back to MMIO.
- tt‑metal may still log **host buffer allocation/pinning**, but that does **not** imply DMA is used.
- Your pure‑py path (TLB‑mapped MMIO writes/reads to DRAM/L1 tiles) is the supported path on BH.
- The pinned‑pages/IOMMU path is for **device‑initiated access to host memory** (NOC DMA to pinned host buffers), not for bulk PCIe DMA transfers on BH.

## References (source of truth)

- `tt-umd/src/firmware/riscv/blackhole/l1_address_map.h`
- `tt-umd/src/firmware/riscv/blackhole/eth_l1_address_map.h`
- `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp`
- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h`
- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/dram_address_map.h`
- `tt-metal/tt_metal/hw/inc/hostdev/dev_msgs.h`
- `tt-metal/tt_metal/hw/inc/internal/circular_buffer_interface.h`
- `tt-metal/tt_metal/hw/inc/internal/circular_buffer_init.h`
- `tt-kmd/blackhole.c` (ARC queue + telemetry scratch usage)
- `tt-isa-documentation/BlackholeA0/README.md` (DRAM tile count and total VRAM)
- `tt-isa-documentation/BlackholeA0/NoC/README.md` (3 tiles per 4 GiB DRAM bank)
