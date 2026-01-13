# Fast Dispatch Architecture

This document covers how tt-metal's fast dispatch system works, for replicating in pure Python.

## Overview: Slow vs Fast Dispatch

**Slow Dispatch** (what pure-py currently does):
- Host writes directly to worker L1 via TLB windows
- Each write is a separate PCIe transaction
- Works with any PCIe connection including USB4/UT3G

**Fast Dispatch**:
- Host writes commands to system memory (hugepage or IOMMU-mapped)
- Device reads commands via PCIe DMA
- On-device prefetch/dispatch cores process commands and write to workers via NOC
- Much faster for bulk operations

## Two Write Destinations

### 1. System Memory (Issue Queue) - Command Data

This is where serialized command sequences go. The device's prefetch core reads from here.

```
Host Memory (Hugepage or IOMMU mmap)
├── Issue Queue (commands)
├── Completion Queue (device writes completion events here)
└── Control pointers (read/write pointers)
```

**No hugepages needed with IOMMU!** tt-metal uses regular mmap:
```python
# IOMMU path - sysmem_manager.cpp:init_iommu()
sysmem = mmap.mmap(-1, size,
                   flags=mmap.MAP_PRIVATE | mmap.MAP_ANONYMOUS | mmap.MAP_POPULATE)
```

### 2. Prefetch Core L1 (TLB) - Control Writes

Small writes to notify the device that new commands are ready:
- `PREFETCH_Q` entries (fetch queue - sizes of commands to fetch)
- `ISSUE_Q_WR` pointer update

These use TLB windows to the dispatch/prefetch cores.

## IOMMU vs Hugepage Path

### PIN_PAGES IOCTL (IOCTL 7)

```python
# ioctl.h structure
TENSTORRENT_IOCTL_PIN_PAGES = 7

# Input structure
class tenstorrent_pin_pages_in:
  output_size_bytes: u32
  flags: u32              # See flags below
  virtual_address: u64
  size: u64

# Output structure
class tenstorrent_pin_pages_out:
  physical_address: u64   # Physical or IOVA address

# Extended output (KMD >= 2.0.0)
class tenstorrent_pin_pages_out_extended:
  physical_address: u64
  noc_address: u64        # NOC address for device to read from

# Flags
TENSTORRENT_PIN_PAGES_CONTIGUOUS = 1 << 0  # Require physically contiguous (hugepages)
TENSTORRENT_PIN_PAGES_NOC_DMA = 1 << 1     # Map to NOC address space
```

### With IOMMU (no hugepages needed):
```python
# pci_device.cpp:map_buffer_to_noc()
pin.in.flags = TENSTORRENT_PIN_PAGES_NOC_DMA  # No CONTIGUOUS flag!
# IOMMU handles scatter-gather mapping
# Returns NOC address the device can read from
```

### Without IOMMU (needs hugepages):
```python
# pci_device.cpp:map_hugepage_to_noc()
pin.in.flags = TENSTORRENT_PIN_PAGES_CONTIGUOUS | TENSTORRENT_PIN_PAGES_NOC_DMA
# Requires physically contiguous memory
```

### NOC Address Base

For Blackhole, the PCIe/sysmem NOC address base is:
```
PCIE_NOC_BASE = 4ULL << 58 = 0x0400_0000_0000_0000
```

Each channel adds 1GB offset.

## Dispatch Core Coordinates

### From Core Descriptor YAML

Dispatch cores come from `blackhole_140_arch.yaml`:
```yaml
dispatch_cores:
  [[-1, 0], [-1, 1], [-1, 2], [-1, 3], [-1, 4], [-1, 5], [-1, 6], [-1, 7], [-1, 8], [-1, 9]]
dispatch_core_type: "tensix"
```

- `[-1, y]` means last column, row y
- For unharvested 13x10 grid: logical (12, 0) through (12, 9)
- Physical coords: (16, 2) through (16, 11) based on soc_descriptor

### Core Allocation Order

1. First allocated: **Prefetcher** (reads from Issue Queue)
2. Second allocated: **Dispatcher** (processes commands, writes to workers)
3. Optional: **Dispatcher S** (subordinate, handles go signals)

From `dispatch_core_manager.cpp`:
```cpp
// Prefetcher core on MMIO device
tt_cxy_pair prefetcher = get_next_available_dispatch_core(mmio_device_id);
// Dispatcher core (same device for MMIO)
tt_cxy_pair dispatcher = get_next_available_dispatch_core(mmio_device_id);
```

### Verified Logical → Physical (NOC0) Mapping (Blackhole)

Dispatch cores are declared as logical relative coords in `tt-metal/tt_metal/core_descriptors/blackhole_140_arch.yaml`:
```yaml
dispatch_cores:
  [[-1, 0], [-1, 1], [-1, 2], [-1, 3], [-1, 4], [-1, 5], [-1, 6], [-1, 7], [-1, 8], [-1, 9]]
```

Logical relative → logical absolute uses `get_core_coord_from_relative()` (so `-1` resolves to last column of the logical grid):
```
CoreCoord get_core_coord_from_relative(const RelativeCoreCoord& in, const CoreCoord& grid_size) {
  coord.x = in.x + ((in.x < 0) ? grid_size.x : 0);
  coord.y = in.y + ((in.y < 0) ? grid_size.y : 0);
}
```

For Blackhole, the Tensix logical grid size is 14x10. That means:
```
[-1, y] → logical (13, y) for y in 0..9
```

Logical → physical (NOC0) translation uses `metal_SocDescriptor::get_physical_tensix_core_from_logical()`, which maps through the Blackhole coordinate manager and `blackhole::TENSIX_CORES_NOC0` in `tt-umd/device/api/umd/device/arch/blackhole_implementation.hpp`. For the last logical column:
```
logical (13, 0..9) → physical NOC0 (16, 2..11)
```

This matches the earlier “(16, 2) through (16, 11)” statement.

### NOC Address Width (Kernel Driver API)

The kernel driver NoC mapping config uses 64-bit addresses:
```c
typedef struct tt_noc_addr_config_t {
  uint64_t addr;
  uint16_t x_end;
  uint16_t y_end;
  uint16_t x_start;
  uint16_t y_start;
  uint8_t noc;
  uint8_t mcast;
  uint8_t ordering;
  uint8_t static_vc;
} tt_noc_addr_config_t;
```

So the NoC address base for PCIe/sysmem (`4ULL << 58`) is compatible with the driver interface; it is not truncated to 32 bits.

## L1 Memory Layout in Prefetch Core

From `dispatch_mem_map.cpp` and `command_queue_common.hpp`:

```
Prefetch Core L1 Layout:
┌─────────────────────────────────────────┐ L1_BASE (DEFAULT_UNRESERVED)
│ PREFETCH_Q_RD          (4 bytes)        │ Device updates when done fetching
│ PREFETCH_Q_PCIE_RD     (4 bytes)        │
│ COMPLETION_Q_WR        (4 bytes)        │
│ COMPLETION_Q_RD        (4 bytes)        │ Host writes via TLB
│ COMPLETION_Q0_LAST_EVENT (4 bytes)      │
│ COMPLETION_Q1_LAST_EVENT (4 bytes)      │
│ DISPATCH_S_SYNC_SEM    (4 bytes)        │
│ FABRIC_HEADER_RB       (128 bytes)      │
│ FABRIC_SYNC_STATUS     (4 bytes)        │
├─────────────────────────────────────────┤ UNRESERVED (aligned to 16B)
│ PREFETCH_Q (Fetch Queue)                │ Ring buffer of uint16_t entries
│   Entry 0: cmd_size_16B                 │ Each entry = size in 16-byte units
│   Entry 1: cmd_size_16B                 │
│   ...                                   │
│   (prefetch_q_entries entries)          │
├─────────────────────────────────────────┤
│ CMDDAT_Q (Command Data Queue)           │
│ SCRATCH_DB                              │
│ ...                                     │
└─────────────────────────────────────────┘
```

### Address Calculation

From `dispatch_mem_map.cpp`:
```cpp
// L1 base for Tensix dispatch cores
l1_base = hal.get_dev_addr(TENSIX, DEFAULT_UNRESERVED);
// For Blackhole: ~0x8700 (MEM_MAP_END + 69KB, aligned)

// Device CQ addresses are sequential from l1_base:
device_cq_addrs[PREFETCH_Q_RD] = l1_base;
device_cq_addrs[PREFETCH_Q_PCIE_RD] = l1_base + prefetch_q_rd_ptr_size;
// ... etc

// UNRESERVED (where PREFETCH_Q ring buffer starts):
device_cq_addrs[UNRESERVED] = align(prev_addr, pcie_alignment);  // 16-byte aligned
```

### Key Addresses (Blackhole Tensix - CONCRETE VALUES)

```python
# Calculated from dev_mem_map.h
MEM_MAP_END = 0x82b0          # 33456 - End of reserved memory
DEFAULT_UNRESERVED = 0x196b0  # 104112 - L1 base for dispatch CQ structures

# This is where you point your TLB for prefetch core writes!
DISPATCH_L1_BASE = 0x196b0

# Offsets from DISPATCH_L1_BASE (each 16 bytes for L1 alignment):
PREFETCH_Q_RD_OFFSET      = 0x00   # Device writes when done fetching
PREFETCH_Q_PCIE_RD_OFFSET = 0x10   # 16
COMPLETION_Q_WR_OFFSET    = 0x20   # 32
COMPLETION_Q_RD_OFFSET    = 0x30   # 48 - Host writes via TLB
COMPLETION_Q0_LAST_OFFSET = 0x40   # 64
COMPLETION_Q1_LAST_OFFSET = 0x50   # 80
DISPATCH_S_SYNC_OFFSET    = 0x60   # 96
FABRIC_HEADER_RB_OFFSET   = 0x70   # 112 (128 bytes)
FABRIC_SYNC_STATUS_OFFSET = 0xF0   # 240

# PREFETCH_Q ring buffer starts here (aligned to 16):
PREFETCH_Q_RING_OFFSET    = 0x100  # 256 - Write fetch entries here!

# Absolute addresses for TLB:
PREFETCH_Q_RING_ADDR = 0x196b0 + 0x100  # = 0x197b0
```

## Host CQ Address Layout (in Sysmem)

From `command_queue_common.hpp`:
```cpp
enum class CommandQueueHostAddrType : uint8_t {
  ISSUE_Q_RD = 0,     // offset 0
  ISSUE_Q_WR = 1,     // offset 16
  COMPLETION_Q_WR = 2, // offset 32
  COMPLETION_Q_RD = 3, // offset 48
  UNRESERVED = 4      // offset 64 - actual command data starts here
};
```

Each is spaced by PCIe alignment (16 bytes).

## The Write Flow

### Step 1: Write Command to Issue Queue (Sysmem)

```python
# Host writes to sysmem via regular memcpy
issue_queue_data_start = 64  # After control pointers
self.sysmem[issue_queue_data_start + self.wr_offset:...] = cmd_bytes
```

### Step 2: Update Issue Queue Write Pointer

Two places need updating:
1. **Sysmem** (for debug/recovery)
2. **Not needed for prefetch** - prefetch reads from PREFETCH_Q

Actually looking more carefully at `system_memory_manager.cpp:issue_queue_push_back()`:
```cpp
// Update local tracking
cq_interface.issue_fifo_wr_ptr += push_size_16B;

// Write to sysmem for debug (not strictly needed for operation)
cluster.write_sysmem(&cq_interface.issue_fifo_wr_ptr, sizeof(uint32_t),
                     issue_q_wr_ptr_offset, mmio_device_id, channel);
```

### Step 3: Write Fetch Queue Entry (TLB to Prefetch Core L1)

This is the critical notification:
```python
# system_memory_manager.cpp:fetch_queue_write()
cmd_size_16B = len(cmd_bytes) >> 4  # Size in 16-byte units (uint16_t)

# Write to prefetch core L1 via TLB
prefetch_q_writers[cq_id].write(prefetch_q_dev_ptr, cmd_size_16B)
prefetch_q_dev_ptr += 2  # sizeof(uint16_t)
```

The prefetch core polls `PREFETCH_Q` and when it sees a new entry:
1. Reads the size from PREFETCH_Q
2. Issues PCIe read from Issue Queue for that many bytes
3. Processes the prefetch commands
4. Writes pages to dispatch buffer

## Prefetch Command Format

From `cq_commands.hpp`:

```cpp
// Prefetch command IDs
enum CQPrefetchCmdId : uint8_t {
  CQ_PREFETCH_CMD_RELAY_LINEAR = 1,    // Relay data from NOC address
  CQ_PREFETCH_CMD_RELAY_PAGED = 3,     // Relay paged/banked data
  CQ_PREFETCH_CMD_RELAY_INLINE = 5,    // Relay inline data (in command)
  CQ_PREFETCH_CMD_EXEC_BUF = 7,        // Execute from buffer
  CQ_PREFETCH_CMD_EXEC_BUF_END = 8,    // End buffer execution
  CQ_PREFETCH_CMD_STALL = 9,           // Drain pipe
  CQ_PREFETCH_CMD_TERMINATE = 11,      // Exit prefetch kernel
};

// Base command (16 bytes)
struct CQPrefetchCmd {
  uint8_t cmd_id;
  // ... command-specific fields
} __attribute__((packed));
```

## Dispatch Command Format

```cpp
enum CQDispatchCmdId : uint8_t {
  CQ_DISPATCH_CMD_WRITE_LINEAR = 1,       // Write to NOC address
  CQ_DISPATCH_CMD_WRITE_PAGED = 4,        // Write to banked DRAM
  CQ_DISPATCH_CMD_WRITE_PACKED = 5,       // Multicast write
  CQ_DISPATCH_CMD_WAIT = 7,               // Wait for workers
  CQ_DISPATCH_CMD_SEND_GO_SIGNAL = 14,    // Trigger worker execution
  CQ_DISPATCH_CMD_TERMINATE = 13,         // Exit dispatcher
  // ... more
};

// Write command (32 bytes for linear)
struct CQDispatchWriteCmd {
  uint8_t cmd_id;          // = 1
  uint8_t num_mcast_dests; // 0 = unicast
  uint8_t write_offset_index;
  uint8_t pad;
  uint32_t noc_xy_addr;    // Packed NOC X/Y
  uint64_t addr;           // L1 destination address
  uint64_t length;         // Data length
  // Followed by inline data
};
```

## Minimum Size Requirements

From `dispatch_settings.hpp`:
```cpp
MAX_DEV_CHANNEL_SIZE = 256 MB   // Per device per channel
TRANSFER_PAGE_SIZE = 4096       // 4KB pages
prefetch_q_entry_type = uint16_t // 2 bytes per fetch entry
```

The CQ size is derived from available sysmem:
```cpp
cq_size = host_channel_size / num_hw_cqs;
// For Galaxy: cq_size /= 4 (DEVICES_PER_UMD_CHANNEL)
```

**Minimum practical size**: The prefetch queue needs enough entries, and issue queue needs to hold at least `prefetch_q_entries * max_prefetch_command_size`.

For a minimal implementation: **~16MB should be sufficient** for basic operation.

## Python Implementation Sketch

```python
# Constants for Blackhole
DISPATCH_L1_BASE = 0x196b0
PREFETCH_Q_RING_OFFSET = 0x100
PREFETCH_Q_RING_ADDR = DISPATCH_L1_BASE + PREFETCH_Q_RING_OFFSET  # 0x197b0

# Prefetch core physical coords (first dispatch core)
PREFETCH_CORE_X = 16
PREFETCH_CORE_Y = 2

# IOCTL
TENSTORRENT_IOCTL_PIN_PAGES = 7
TENSTORRENT_PIN_PAGES_NOC_DMA = 1 << 1

class FastDispatch:
  def __init__(self, fd, sysmem_size=16*1024*1024):
    # 1. Allocate sysmem (IOMMU path - NO HUGEPAGES)
    self.sysmem = mmap.mmap(-1, sysmem_size,
                            prot=mmap.PROT_READ | mmap.PROT_WRITE,
                            flags=mmap.MAP_PRIVATE | mmap.MAP_ANONYMOUS | mmap.MAP_POPULATE)

    # 2. Pin for NOC DMA access (IOMMU will handle scatter-gather)
    self.noc_addr = self._pin_pages_noc_dma(fd, self.sysmem, sysmem_size)

    # 3. TLB to prefetch core L1 for writing fetch queue entries
    self.prefetch_tlb, self.prefetch_mm = get_tlbs(
      fd, BH_TLB_2M_WINDOW_SIZE,
      TLBConfig(
        noc_addr=PREFETCH_Q_RING_ADDR,
        x_start=PREFETCH_CORE_X, y_start=PREFETCH_CORE_Y,
        x_end=PREFETCH_CORE_X, y_end=PREFETCH_CORE_Y,
        noc=NOC_0
      )
    )

    # Track pointers
    self.issue_q_wr_ptr = 64  # After host CQ control pointers (4 * 16B)
    self.prefetch_q_offset = 0  # Offset within TLB window

  def _pin_pages_noc_dma(self, fd, buf, size):
    """Pin pages and get NOC address via IOMMU (no hugepages needed)"""
    # Get virtual address of mmap buffer
    buf_addr = ctypes.addressof(ctypes.c_char.from_buffer(buf))

    # Pack input struct
    pin_in = struct.pack("<IIqq",
                         24,  # output_size (extended output has noc_address)
                         TENSTORRENT_PIN_PAGES_NOC_DMA,  # flags - NO CONTIGUOUS!
                         buf_addr,
                         size)

    # Allocate output buffer
    pin_out = bytearray(24)

    # Call ioctl
    fcntl.ioctl(fd, TENSTORRENT_IOCTL_PIN_PAGES, pin_in + pin_out)

    # Parse extended output
    phys_addr, noc_addr = struct.unpack("<QQ", pin_out[:16])
    return noc_addr

  def enqueue_command(self, cmd_bytes):
    """Enqueue a command sequence to fast dispatch"""
    cmd_len = len(cmd_bytes)
    aligned_len = (cmd_len + 15) & ~15  # Align to 16 bytes

    # 1. Write command to issue queue (sysmem - host memory)
    self.sysmem[self.issue_q_wr_ptr:self.issue_q_wr_ptr + cmd_len] = cmd_bytes

    # 2. Write fetch queue entry (TLB write to prefetch core L1)
    # This tells prefetch core: "fetch <size> bytes from issue queue"
    fetch_entry = aligned_len >> 4  # Size in 16-byte units (uint16_t)
    struct.pack_into("<H", self.prefetch_mm, self.prefetch_q_offset, fetch_entry)

    # Update pointers
    self.issue_q_wr_ptr += aligned_len
    self.prefetch_q_offset += 2  # sizeof(uint16_t)

  def close(self):
    """Cleanup"""
    # Unpin pages, free TLB, close mmap
    pass
```

## Dispatch Core Physical Coordinates (Blackhole)

For an **unharvested** Blackhole (13 logical columns):
- Dispatch cores are logical column 12 (last column), rows 0-9
- Physical X = 16 (rightmost worker column)
- Physical Y = 2-11

```python
# First dispatch core (becomes prefetcher):
PREFETCH_CORE_PHYS = (16, 2)   # Physical NOC coordinates

# Second dispatch core (becomes dispatcher):
DISPATCH_CORE_PHYS = (16, 3)

# For TLB setup to prefetch core:
prefetch_tlb_config = TLBConfig(
  noc_addr=PREFETCH_Q_RING_ADDR,  # 0x197b0
  x_start=16, y_start=2,
  x_end=16, y_end=2,
  noc=NOC_0
)
```

**Important**: These are for CQ 0. If you have multiple CQs, each gets its own prefetch/dispatch cores allocated sequentially from the dispatch_cores list.

## UT3G / USB4 Considerations

The UT3G fails with large sysmem because:
1. Limited iATU (inbound Address Translation Unit) window size
2. Thunderbolt PCIe aperture constraints

**Solution**: Use smaller sysmem buffers. The KMD allocates NOC address space, and UT3G has limited range. Try:
- 16MB instead of 256MB
- Or even smaller (4MB) for testing

The slow dispatch path (direct TLB writes) always works on UT3G because it doesn't need sysmem mapping.

## Key Files Reference

| Component | File |
|-----------|------|
| System Memory Manager | `tt_metal/impl/dispatch/system_memory_manager.cpp` |
| Dispatch Memory Map | `tt_metal/impl/dispatch/dispatch_mem_map.cpp` |
| Dispatch Settings | `tt_metal/impl/dispatch/dispatch_settings.hpp` |
| Command Queue Common | `tt_metal/impl/dispatch/command_queue_common.hpp` |
| Dispatch Core Manager | `tt_metal/impl/dispatch/dispatch_core_manager.cpp` |
| Prefetch Kernel | `tt_metal/impl/dispatch/kernels/cq_prefetch.cpp` |
| Dispatch Kernel | `tt_metal/impl/dispatch/kernels/cq_dispatch.cpp` |
| Command Definitions | `tt_metal/impl/dispatch/kernels/cq_commands.hpp` |
| PIN_PAGES IOCTL | `tt_metal/third_party/umd/device/pcie/ioctl.h` |
| PCI Device (map_buffer_to_noc) | `tt_metal/third_party/umd/device/pcie/pci_device.cpp` |
| Blackhole Dev Mem Map | `tt_metal/hw/inc/internal/tt-1xx/blackhole/dev_mem_map.h` |
| Core Descriptor YAML | `tt_metal/core_descriptors/blackhole_140_arch.yaml` |
| SOC Descriptor YAML | `tt_metal/soc_descriptors/blackhole_140_arch.yaml` |
