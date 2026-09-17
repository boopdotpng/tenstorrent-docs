# NoC interfaces, atomics, and streams

Source-derived NIU and overlay models. Preserve address space, destination type, transaction identity, and completion semantics; a source-read completion is not remote visibility.

<a id="niu"></a>
## NIU Emulator Specification (Blackhole)
<a id="niu--niu-emulator-specification-blackhole"></a>

<a id="niu--1-address-space-overview"></a>
### 1. Address Space Overview

Each Tensix tile has **2 NIU instances** (NoC0 and NoC1), memory-mapped into the tile's private address space:

| NIU | Base Address | Size |
|-----|-------------|------|
| NoC0 | `0xFFB20000` | `0x10000` |
| NoC1 | `0xFFB30000` | `0x10000` |

The formula firmware uses to compute a register's absolute address:

```
addr = (buf << 11) + (noc << 16) + register_offset
```

Where `register_offset` already includes the `0xFFB20000` base (the defines in `noc_parameters.h` are absolute addresses). For the emulator, offsets from the NIU base are:

| Region | Offset Range | Description |
|--------|-------------|-------------|
| **Command Buffers** | `0x0000`-`0x1FFF` | 4 buffers x 0x800 stride |
| **Misc Control** | `0x0040`-`0x0068` | CMD_CTRL, NODE_ID, ECC, CMD_BUF_AVAIL |
| **Configuration** | `0x0100`-`0x017F` | NIU_CFG_0, ROUTER_CFG, translate tables |
| **Status Counters** | `0x0200`-`0x02FF` | 128 x 4-byte counters |
| **Security Fence** | `0x0400`-`0x04A8` | Not needed for emulation |
| **Flit Counters** | `0x0500`-`0x05FF` | Not needed for emulation |

<a id="niu--2-command-buffer-registers"></a>
### 2. Command Buffer Registers

4 command buffers at offsets `0x000`, `0x800`, `0x1000`, `0x1800`. Each has this layout:

| Offset | Name | R/W | Description |
|--------|------|-----|-------------|
| `+0x00` | `NOC_TARG_ADDR_LO` | RW | Target address bits [31:0] |
| `+0x04` | `NOC_TARG_ADDR_MID` | RW | Target address bits [63:32] (PCIe: bit 60 set) |
| `+0x08` | `NOC_TARG_ADDR_HI` | RW | Target XY coordinate (see encoding below) |
| `+0x0C` | `NOC_RET_ADDR_LO` | RW | Return/dest address bits [31:0] |
| `+0x10` | `NOC_RET_ADDR_MID` | RW | Return/dest address bits [63:32] |
| `+0x14` | `NOC_RET_ADDR_HI` | RW | Return/dest XY coordinate |
| `+0x18` | `NOC_PACKET_TAG` | RW | `[13:10]` = transaction_id, `[9]` = header_store |
| `+0x1C` | `NOC_CTRL` | RW | Command type/flags (see bitfield below) |
| `+0x20` | `NOC_AT_LEN_BE` | RW | Transfer length in bytes (or byte-enable low word) |
| `+0x24` | `NOC_AT_LEN_BE_1` | RW | Byte-enable high word (for BE writes) |
| `+0x28` | `NOC_AT_DATA` | RW | Inline write data / atomic operand |
| `+0x2C` | `NOC_BRCST_EXCLUDE` | RW | Broadcast exclusion mask |
| `+0x30` | `NOC_L1_ACC_AT_INSTRN` | RW | L1 accumulate atomic instruction encoding |
| `+0x34` | `NOC_SEC_CTRL` | RW | Security control (ignore for emu) |
| `+0x40` | **`NOC_CMD_CTRL`** | RW | **Trigger**: write `0x1` to fire. Reads `0x0` when ready. |
| `+0x44` | `NOC_NODE_ID` | RO | Physical node XY: `{y[5:0], x[5:0]}` |
| `+0x48` | `NOC_ENDPOINT_ID` | RO | Endpoint ID |

**Registers at offsets `+0x44` and `+0x48` read the same value in all 4 command buffers** -- they are shared (the hardware aliases them).

<a id="niu--conventional-buffer-assignments-dedicated-mode-the-common-case"></a>
#### Conventional buffer assignments (dedicated mode, the common case)

| Buffer | Index | Used for |
|--------|-------|----------|
| WR_CMD_BUF | 0 | Large DMA writes |
| RD_CMD_BUF | 1 | All DMA reads |
| WR_REG_CMD_BUF | 2 | Small register/semaphore writes |
| AT_CMD_BUF | 3 | Atomics (incr_get, CAS, swap, accumulate) |

<a id="niu--3-noc_ctrl-bitfield"></a>
### 3. NOC_CTRL Bitfield

```
Bit  0: AT       (1 = atomic, 0 = copy)
Bit  1: WR       (1 = write, 0 = read)
Bit  2: WR_BE    (byte-enable write: AT_LEN_BE is a bitmask, not a length)
Bit  3: WR_INLINE (data comes from NOC_AT_DATA register, not from L1)
Bit  4: RESP_MARKED (non-posted: expect ACK; used for barrier tracking)
Bit  5: BRCST_PACKET (multicast)
Bit  6: VC_LINKED (linked VC allocation with previous transaction)
Bit  7: VC_STATIC (use static VC from bits [15:13])
Bit  8: PATH_RESERVE (reserve path for multicast)
Bit  9: MEM_RD_DROP_ACK (drop read ack -- fire-and-forget)
[12:10]: reserved
[15:13]: STATIC_VC (virtual channel number when VC_STATIC=1)
[16]: BRCST_XY (multicast direction flag)
[17]: BRCST_SRC_INCLUDE (include source in multicast)
[26:18]: reserved
[29:27]: ARB_PRIORITY
[30]: reserved
[31]: L1_ACC_AT_EN (enable L1 accumulate atomic)
```

<a id="niu--transaction-type-decoding-for-the-emulator"></a>
#### Transaction type decoding for the emulator

| AT | WR | WR_BE | WR_INLINE | Transaction |
|----|-----|-------|-----------|-------------|
| 0 | 0 | 0 | 0 | **Read**: copy from `TARG` to `RET` |
| 0 | 1 | 0 | 0 | **Write**: copy from `TARG` (local src) to `RET` (remote dest) |
| 0 | 1 | 1 | 0 | **Write with byte-enables**: AT_LEN_BE/BE_1 = 64-bit bitmask |
| 0 | 1 | 0 | 1 | **Inline write**: 4 bytes from NOC_AT_DATA to `TARG` addr |
| 1 | x | x | x | **Atomic**: operation encoded in NOC_L1_ACC_AT_INSTRN or NOC_AT_LEN_BE |

<a id="niu--4-xy-coordinate-encoding"></a>
### 4. XY Coordinate Encoding

Coordinates are packed as 6-bit fields:

**Unicast** (in `NOC_TARG_ADDR_HI` / `NOC_RET_ADDR_HI`):
```
[5:0]  = x
[11:6] = y
```

**Multicast** (when `BRCST_PACKET=1`):
```
[5:0]   = end_x
[11:6]  = end_y
[17:12] = start_x
[23:18] = start_y
```

**64-bit address encoding** (as used by the API to build `src_noc_addr` / `dst_noc_addr`):
```
[35:0]  = local address (36-bit)
[41:36] = x
[47:42] = y
```

The API splits these: bits [31:0] go to `ADDR_LO`, bits [35:32] (plus PCIe bit 60 -> bit 28 of MID) go to `ADDR_MID`, and bits [47:36] (the XY coordinate) go to `ADDR_HI`/`ADDR_COORDINATE`.

<a id="niu--5-configuration-registers-0x100--index4"></a>
### 5. Configuration Registers (`0x100 + index*4`)

These are the registers the emulator needs to support (firmware reads/writes them):

| Index | Name | Key bits |
|-------|------|----------|
| `0x00` | `NIU_CFG_0` | `[14]` = NOC_ID_TRANSLATE_EN, `[16]` = CMD_BUFFER_FIFO_EN |
| `0x01` | `ROUTER_CFG_0` | Router config (not needed for functional emu) |
| `0x06`-`0x0B` | `NOC_X_ID_TRANSLATE_TABLE_0..5` | X coordinate translation (6 regs, 6 entries each, 5 bits/entry) |
| `0x0C`-`0x11` | `NOC_Y_ID_TRANSLATE_TABLE_0..5` | Y coordinate translation |
| **`0x12`** | **`NOC_ID_LOGICAL`** | **Logical coordinates: `{y[5:0], x[5:0]}`** |
| `0x14` | `NOC_ID_TRANSLATE_COL_MASK` | Column mask for ID translation |
| `0x15` | `NOC_ID_TRANSLATE_ROW_MASK` | Row mask for ID translation |

**Critical for emulation**: `NOC_ID_LOGICAL` (at absolute address `NIU_base + 0x148`) is what firmware reads during `noc_init()` to discover "who am I." The ARC firmware pre-programs this before tensix cores boot. Your emulator must pre-populate this for each tile.

<a id="niu--6-status-counters-0x200--index4"></a>
### 6. Status Counters (`0x200 + index*4`)

These are hardware-maintained monotonically increasing counters. Firmware polls them for barriers ("have all my writes been acked?"). The emulator must **increment them when transactions complete**.

Key counters firmware actually reads:

| Index | Name | When to increment |
|-------|------|-------------------|
| `0x0` | `NIU_MST_ATOMIC_RESP_RECEIVED` | After atomic completes |
| `0x1` | `NIU_MST_WR_ACK_RECEIVED` | After non-posted write ACK received |
| `0x2` | `NIU_MST_RD_RESP_RECEIVED` | After read response received |
| `0x4` | `NIU_MST_CMD_ACCEPTED` | After any command accepted (optional) |
| `0x5` | `NIU_MST_RD_REQ_SENT` | After read request sent |
| `0xA` | `NIU_MST_NONPOSTED_WR_REQ_SENT` | After non-posted write sent |
| `0xB` | `NIU_MST_POSTED_WR_REQ_SENT` | After posted write sent |
| `0x10+id` | `NIU_MST_REQS_OUTSTANDING_ID(id)` | Outstanding count per transaction_id |

**Barrier pattern** (this is what firmware spins on):
```c
// Read barrier: spin until RD_RESP_RECEIVED == local counter
while (NOC_STATUS_READ_REG(noc, NIU_MST_RD_RESP_RECEIVED) != noc_reads_num_issued[noc]);

// Write barrier: spin until WR_ACK_RECEIVED == local counter
while (NOC_STATUS_READ_REG(noc, NIU_MST_WR_ACK_RECEIVED) != noc_nonposted_writes_acked[noc]);
```

For a synchronous emulator: increment counters immediately when `NOC_CMD_CTRL` fires. This makes all barriers resolve on the next load.

<a id="niu--7-misc-control-registers-at-niu-base"></a>
### 7. Misc Control Registers (at NIU base)

| Offset | Name | Notes |
|--------|------|-------|
| `0x50` | `NUM_MEM_PARITY_ERR` | Always 0 in emu |
| `0x54` | `NUM_HEADER_1B_ERR` | Always 0 |
| `0x58` | `NUM_HEADER_2B_ERR` | Always 0 |
| `0x5C` | `ECC_CTRL` | Ignore |
| `0x60` | `NOC_CLEAR_OUTSTANDING_REQ_CNT` | Write to clear outstanding request counts by ID mask |
| `0x64` | `CMD_BUF_AVAIL` | `[4:0]`=buf0 slots, `[12:8]`=buf1, `[20:16]`=buf2, `[28:24]`=buf3. Return all-available. |
| `0x68` | `CMD_BUF_OVFL` | Overflow flag, always 0 in emu |

<a id="niu--8-transaction-execution-on-cmd_ctrl-write"></a>
### 8. Transaction Execution (on CMD_CTRL write)

When firmware writes `0x1` to `NOC_CMD_CTRL` at offset `+0x40` of a command buffer:

```python
def fire_cmd(self, buf_idx):
    regs = self.cmd_bufs[buf_idx]
    ctrl = regs[0x1C]  # NOC_CTRL

    is_atomic = ctrl & 1
    is_write  = (ctrl >> 1) & 1
    is_wr_be  = (ctrl >> 2) & 1
    is_inline = (ctrl >> 3) & 1
    is_resp_marked = (ctrl >> 4) & 1  # non-posted
    is_mcast  = (ctrl >> 5) & 1

    targ_lo  = regs[0x00]
    targ_mid = regs[0x04]
    targ_xy  = regs[0x08]
    ret_lo   = regs[0x0C]
    ret_mid  = regs[0x10]
    ret_xy   = regs[0x14]
    length   = regs[0x20]

    if is_atomic:
        # Atomic operation on target, return result to ret addr
        execute_atomic(...)
        self.inc_counter(NIU_MST_ATOMIC_RESP_RECEIVED)
    elif is_write:
        if is_inline:
            # Write NOC_AT_DATA (4 bytes) to targ address
            execute_inline_write(...)
        else:
            # DMA from local TARG addr to remote RET addr
            execute_dma_write(...)
        if is_resp_marked:
            self.inc_counter(NIU_MST_WR_ACK_RECEIVED)
            self.inc_counter(NIU_MST_NONPOSTED_WR_REQ_SENT)
        else:
            self.inc_counter(NIU_MST_POSTED_WR_REQ_SENT)
    else:
        # Read: DMA from remote TARG addr to local RET addr
        execute_dma_read(...)
        self.inc_counter(NIU_MST_RD_RESP_RECEIVED)
```

<a id="niu--9-firmware-boot-sequence-what-the-emulator-must-handle"></a>
### 9. Firmware Boot Sequence (what the emulator must handle)

The BRISC firmware `noc_init()` does this for each NoC:

1. **Read `NOC_CFG(NOC_ID_LOGICAL)`** (offset `0x148` from NIU base) to get `my_x`, `my_y`
2. **Pre-program command buffers** with local coordinates:
   - WR_CMD_BUF (0): set `TARG_ADDR_MID=0`, `TARG_ADDR_COORDINATE=my_xy` (local source for writes)
   - WR_REG_CMD_BUF (2): same as above
   - AT_CMD_BUF (3): set `RET_ADDR_LO`, `RET_ADDR_MID=0`, `RET_ADDR_COORDINATE=my_xy` (atomic return addr)
   - RD_CMD_BUF (1): set `NOC_CTRL` to read command flags, `RET_ADDR_MID=0`, `RET_ADDR_COORDINATE=my_xy`
3. **Read status counters** (`noc_local_state_init`): read `RD_RESP_RECEIVED`, `NONPOSTED_WR_REQ_SENT`, `WR_ACK_RECEIVED`, `ATOMIC_RESP_RECEIVED`, `POSTED_WR_REQ_SENT` and store in L1 variables

This means your emulator **must pre-populate** before firmware starts:
- `NOC_CFG(NOC_ID_LOGICAL)` = `(y << 6) | x` for the tile's logical coordinates
- `NOC_NODE_ID` (offset `0x44`) = `(y << 6) | x` for the tile's physical coordinates
- All status counters = `0`

<a id="niu--10-disassembly-verification"></a>
### 10. Disassembly Verification

From the real `add1` kernel disassembly, here's `noc_async_write` (NCRISC, using NoC0, cmd_buf 0):

```asm
; a4 = 0xFFB20000 (NoC0 base, cmd buf 0)
; Wait for CMD_CTRL ready
.L4:
    lw   a5, 64(a4)     ; read NOC_CMD_CTRL (+0x40)
    bnez a5, .L4         ; spin until 0

    ; Write NOC_CTRL = 0x2092 (CPY|WR|RESP_MARKED|VC_STATIC|STATIC_VC(1))
    li   a5, 0x2092
    sw   a5, 28(a4)      ; +0x1C = NOC_CTRL

    ; Write source address
    sw   a0, 0(a4)       ; +0x00 = NOC_TARG_ADDR_LO  (local L1 source)

    ; Write dest address
    sw   a1, 12(a4)      ; +0x0C = NOC_RET_ADDR_LO
    sw   zero, 16(a4)    ; +0x10 = NOC_RET_ADDR_MID = 0

    ; Write dest coordinate (pre-shifted)
    srli a2, a2, 4
    sw   a2, 20(a4)      ; +0x14 = NOC_RET_ADDR_COORDINATE

    ; Write length
    li   a5, 0x800       ; 2048 bytes
    sw   a5, 32(a4)      ; +0x20 = NOC_AT_LEN_BE

    ; FIRE
    li   a5, 1
    sw   a5, 64(a4)      ; +0x40 = NOC_CMD_CTRL = 1
```

And from `noc_async_read` (BRISC, using NoC1, cmd_buf 1):

```asm
; a4 = 0xFFB31000 (NoC1 base + buf1*0x800 = 0xFFB30000 + 0x800)
; Wait for CMD_CTRL ready
.L7:
    lw   a5, -1984(a4)   ; 0xFFB31000 + (-1984) = 0xFFB30840 = NOC_CMD_CTRL of buf 1
    bnez a5, .L7

    ; Write dest coordinate (local return)
    sw   a2, -2036(a4)   ; 0xFFB30814 = NOC_RET_ADDR_HI of buf 1

    ; Write source address
    sw   a0, -2048(a4)   ; 0xFFB30800 = NOC_TARG_ADDR_LO of buf 1
    sw   zero, -2044(a4) ; 0xFFB30804 = NOC_TARG_ADDR_MID of buf 1 = 0

    ; Write source coordinate
    sw   a1, -2040(a4)   ; 0xFFB30808 = NOC_TARG_ADDR_HI of buf 1

    ; Write length
    li   a2, 0x800
    sw   a2, -2016(a4)   ; 0xFFB30820 = NOC_AT_LEN_BE of buf 1

    ; FIRE
    li   a2, 1
    sw   a2, -1984(a4)   ; 0xFFB30840 = NOC_CMD_CTRL of buf 1
```

<a id="niu--11-overlay--stream-path"></a>
### 11. Overlay / Stream Path

The stream/overlay engine lives at a separate base:

- `NOC_OVERLAY_START_ADDR = 0xFFB40000`
- 64 streams, each with `0x1000` bytes of register space
- `STREAM_REG_ADDR(stream_id, reg_id) = 0xFFB40000 + stream_id*0x1000 + reg_id*4`

The stream engine can issue NoC transactions on behalf of firmware (used for data movement pipelines). This is a separate subsystem from the raw NIU command path. For the matmul_peak and add1 kernels, the **raw NIU path above is what's used** -- the stream/overlay path is for pipelined data movement (not needed for basic emulation of compute kernels).

<a id="niu--12-cmd_buffer_fifo_en-niu_cfg_0-bit-16"></a>
### 12. CMD_BUFFER_FIFO_EN (NIU_CFG_0 bit 16)

When bit 16 of `NIU_CFG_0` is set, the 4 command buffers operate as a FIFO rather than independently addressable slots. Commands are written to buffer 0's registers and the hardware auto-advances. **Not used in add1 or matmul_peak kernels.** Can be stubbed as a no-op for initial emulation.

<a id="niu--13-atomic-operations"></a>
### 13. Atomic Operations

When `NOC_CMD_AT` (bit 0 of NOC_CTRL) is set, the transaction is an atomic. The operation type is encoded in `NOC_AT_LEN_BE` (bits [15:12]) or `NOC_L1_ACC_AT_INSTRN` (when `L1_ACC_AT_EN` is set):

| Code | Name | Description |
|------|------|-------------|
| `0x0` | `NOP` | No operation |
| `0x1` | `INCR_GET` | Increment target, return old value |
| `0x2` | `INCR_GET_PTR` | Increment-get with pointer wrap |
| `0x3` | `SWAP` | Swap target with NOC_AT_DATA |
| `0x4` | `CAS` | Compare-and-swap |
| `0x5` | `GET_TILE_MAP` | Tile map lookup |
| `0x6` | `STORE_IND` | Indirect store |
| `0x7` | `SWAP_4B` | 4-byte swap |
| `0x9` | `ACC` | Accumulate (FP32/FP16/INT32/INT8) |

The atomic instruction field in `NOC_AT_LEN_BE`:
```
[1:0]  = IND_32 (index)
[5:2]  = WRAP (wrap count)
[9:6]  = (reserved / INCR)
[11:10] = IND_32_SRC (source index)
[15:12] = INS (instruction opcode from table above)
```

For `L1_ACC_AT_INSTRN` (when `L1_ACC_AT_EN=1`):
```
[2:0]  = ACC_FORMAT (0=FP32, 1=FP16_A, 2=FP16_B, 3=INT32, 4=INT32_COMPL, 5=INT32_UNS, 6=INT8)
[3]    = ACC_SAT_DIS (disable saturation)
[15:12] = INS (must be 0x9 for ACC)
```

<a id="niu--14-multicast-delivery-model"></a>
### 14. Multicast Delivery Model

When `NOC_CMD_BRCST_PACKET` (bit 5 of `NOC_CTRL`) is set, the transaction is delivered to a rectangle of tiles rather than a single target.

<a id="niu--coordinate-encoding-in-noc_ret_addr_hi-for-dma-writes-noc_targ_addr_hi-for-inline-writes"></a>
#### Coordinate encoding (in `NOC_RET_ADDR_HI` for DMA writes, `NOC_TARG_ADDR_HI` for inline writes)

```
[5:0]   = EndX      (6 bits)
[11:6]  = EndY      (6 bits)
[17:12] = StartX    (6 bits)
[23:18] = StartY    (6 bits)
```

The 64-bit multicast address is constructed by the firmware API:

```c
#define NOC_MULTICAST_ADDR(x_start, y_start, x_end, y_end, addr)  \
    ((uint64_t)(x_start) << 48) | ((uint64_t)(y_start) << 54) |   \
    ((uint64_t)(x_end) << 36) | ((uint64_t)(y_end) << 42) |       \
    ((uint64_t)(addr))
```

This splits across the three address registers: bits [31:0] to `ADDR_LO`, bits [35:32] to `ADDR_MID`, and the XY fields to `ADDR_HI`.

<a id="niu--delivery-algorithm"></a>
#### Delivery algorithm

The hardware delivers to all tiles whose coordinates lie within the rectangle:

```python
def multicast_targets(start_x, start_y, end_x, end_y, src_x, src_y, src_include):
    """Return set of (x, y) coordinates that receive the multicast."""
    targets = set()
    for y in range(start_y, end_y + 1):
        for x in range(start_x, end_x + 1):
            if not src_include and x == src_x and y == src_y:
                continue  # skip sender unless BRCST_SRC_INCLUDE is set
            targets.add((x, y))
    return targets
```

The rectangle is always `{(x,y) | StartX <= x <= EndX AND StartY <= y <= EndY}`. Only tiles that have been registered in the NOC routing table actually receive data (unregistered grid positions are ignored).

<a id="niu--noc_cmd_brcst_xy-bit-16--routing-axis-not-delivery-set"></a>
#### `NOC_CMD_BRCST_XY` (bit 16) — routing axis, not delivery set

This bit controls which axis the multicast packet traverses first through the routers:
- `BRCST_XY=0`: X is the major axis (traverse columns first, then branch along rows)
- `BRCST_XY=1`: Y is the major axis (traverse rows first, then branch along columns)

This affects only routing topology and congestion behavior — **it does not change which tiles receive the write**. The emulator should ignore this bit entirely.

<a id="niu--noc_cmd_brcst_src_include-bit-17--source-tile-inclusion"></a>
#### `NOC_CMD_BRCST_SRC_INCLUDE` (bit 17) — source tile inclusion

Controls whether the sending tile receives its own multicast:
- `BRCST_SRC_INCLUDE=0` (default): if the sender's `(x, y)` falls inside the rectangle, it is excluded from receiving
- `BRCST_SRC_INCLUDE=1`: the sender also receives the write (loopback)

The firmware API exposes two variants for each multicast operation:
- `noc_async_write_multicast(...)` — excludes self (default)
- `noc_async_write_multicast_loopback_src(...)` — includes self

<a id="niu--noc_brcst_exclude-register-offset-0x2c--non-rectangular-exclusion"></a>
#### `NOC_BRCST_EXCLUDE` (register offset `+0x2C`) — non-rectangular exclusion

When bit 22 is set in this register, a single row or column can be carved out of the rectangle:

```
Bits [7:0]   = start_x of excluded region
Bits [13:8]  = start_y of excluded region
Bit  [20]    = exclude direction X
Bit  [21]    = exclude direction Y
Bit  [22]    = exclude enabled
```

Used by `noc_multicast_copy_exclude()` for non-rectangular broadcast patterns. Standard firmware APIs (including `noc_semaphore_set_multicast`) always write `0x0` to this register (no exclusion). The emulator can leave this unimplemented for basic kernel emulation.

<a id="niu--multicast-is-write-only"></a>
#### Multicast is write-only

Multicast applies only to write and atomic transactions. Read requests must always be unicast (`BRCST_PACKET=0`).

<a id="niu--counter-accounting-for-multicast"></a>
#### Counter accounting for multicast

For non-posted multicast writes (`RESP_MARKED=1`):
- `NIU_MST_NONPOSTED_WR_REQ_SENT` increments by 1 (one command issued)
- `NIU_MST_WR_ACK_RECEIVED` increments by 1 per destination tile that ACKs

The firmware pre-charges its local LDM counter: `noc_nonposted_writes_acked[noc] += num_dests`. The synchronous emulator should increment `WR_ACK_RECEIVED` by the number of actual targets delivered to when `fire_cmd()` runs, so that barrier polling resolves immediately.

<a id="niu--emulator-fire_cmd-multicast-path"></a>
#### Emulator `fire_cmd()` multicast path

```python
def fire_cmd(self, buf_idx):
    regs = self.cmd_bufs[buf_idx]
    ctrl = regs[0x1C]
    is_mcast = (ctrl >> 5) & 1
    mcast_src_include = (ctrl >> 17) & 1

    if is_mcast and is_write:
        sx, sy, ex, ey = self._mcast_rect(ret_xy)
        targets_hit = 0
        for y in range(sy, ey + 1):
            for x in range(sx, ex + 1):
                if not mcast_src_include and x == self.x and y == self.y:
                    continue
                if (x, y) in self.fabric:
                    self.fabric[(x, y)].write(dst_addr, data)
                    targets_hit += 1
        if is_resp_marked:
            self.inc_counter(NIU_MST_WR_ACK_RECEIVED, targets_hit)
            self.inc_counter(NIU_MST_NONPOSTED_WR_REQ_SENT)
    # ... (existing unicast path unchanged)
```

<a id="niu--firmware-api-summary"></a>
#### Firmware API summary

| Function | Src included? | Notes |
|---|---|---|
| `noc_async_write_multicast(src, dst_mcast, size, num_dests, linked, noc)` | No | Standard multicast DMA |
| `noc_async_write_multicast_loopback_src(...)` | Yes | `num_dests` includes self |
| `noc_semaphore_set_multicast(src, dst_mcast, num_dests, linked, noc)` | No | 4-byte non-posted write |
| `noc_semaphore_set_multicast_loopback_src(...)` | Yes | 4-byte with loopback |
| `noc_semaphore_inc_multicast(addr, incr, num_dests, noc)` | No | Atomic increment multicast |
| `get_noc_multicast_addr(x_start, y_start, x_end, y_end, addr, noc)` | — | Constructs the 64-bit multicast address |


<a id="niu--15-source-files-reference"></a>
### 15. Source Files Reference

| Purpose | File |
|---------|------|
| Primary BH register defines | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h` |
| NoC nonblocking API (C++) | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc_nonblocking_api.h` |
| Overlay/stream params | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_overlay_parameters.h` |
| Firmware C noc_transfer | `tt-metal/tt_metal/hw/firmware/src/tt-1xx/blackhole/noc.c` |
| Firmware multicast helpers | `tt-metal/tt_metal/hw/inc/api/dataflow/dataflow_api.h` |
| Multicast addr construction | `tt-metal/tt_metal/hw/inc/internal/dataflow/dataflow_api_addrgen.h` |
| NOC architecture overview | `tt-isa-documentation/BlackholeA0/NoC/README.md` |
| NOC register field spec | `tt-isa-documentation/BlackholeA0/NoC/MemoryMap.md` |
| NOC routing paths | `tt-isa-documentation/BlackholeA0/NoC/RoutingPaths.md` |
| NIU register Python map | `tt-exalens/ttexalens/hardware/blackhole/niu_registers.py` |
| ARC firmware coordinate map | `tt-zephyr-platforms/lib/tenstorrent/bh_arc/noc.c` |
| ARC NIU init/config | `tt-zephyr-platforms/lib/tenstorrent/bh_arc/noc_init.c` |
| Existing emulator NIU model | `blackhole-py/emu/noc.py` |

<a id="noc-atomics"></a>
## NOC Atomic Operations
<a id="noc-atomics--noc-atomic-operations"></a>

The NIU (Network Interface Unit) supports atomic read-modify-write operations against L1 memory of Tensix and Ethernet tiles. Atomic operations cannot target MMIO addresses, DRAM addresses, or PCIe endpoints. They can be unicast or multicast (broadcast to a rectangle of tiles, performed independently on each).

The existing niu.md documents the basic INCR_GET atomic used for software semaphore signaling. This document covers the remaining atomic operations: INCR_GET_PTR, CAS, SWAP, and ACC.


<a id="noc-atomics--atomic-opcode-table"></a>
### Atomic Opcode Table

The atomic operation is encoded in `NOC_AT_LEN_BE[15:12]`:

| Code | Symbol | Description |
|------|--------|-------------|
| 0x0 | `AT_NOP` | No operation |
| 0x1 | `AT_INCR_GET` | Increment + return old value (documented in niu.md) |
| 0x2 | `AT_INCR_GET_PTR` | Increment with modular wrap |
| 0x3 | `AT_SWAP` | Masked 16-bit-granule swap |
| 0x4 | `AT_CAS` | Compare-and-swap |
| 0x5 | `AT_GET_TILE_MAP` | Tile map lookup |
| 0x6 | `AT_STORE_IND` | Indirect store |
| 0x7 | `AT_SWAP_4B` | Full 32-bit swap |
| 0x8 | Zaamo | RISC-V Zaamo atomic operations via NOC |
| 0x9 | `AT_ACC` | Parallel accumulate (FP32/FP16/BF16/INT) |

The constants are defined in `noc_parameters.h`:
```c
// From tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h
#define NOC_AT_INS_NOP          0x0
#define NOC_AT_INS_INCR_GET     0x1
#define NOC_AT_INS_INCR_GET_PTR 0x2
#define NOC_AT_INS_SWAP         0x3
#define NOC_AT_INS_CAS          0x4
#define NOC_AT_INS_SWAP_4B      0x7
#define NOC_AT_INS_ACC          0x9
```


<a id="noc-atomics--noc_at_len_be-field-layout"></a>
### NOC_AT_LEN_BE Field Layout

The `NOC_AT_LEN_BE` register encodes the atomic operation and its parameters. The exact field layout depends on the operation:

<a id="noc-atomics--for-incr_get--incr_get_ptr"></a>
#### For INCR_GET / INCR_GET_PTR:
```
[15:12] = INS     (opcode: 0x1 or 0x2)
[11:10] = IND_32_SRC
[9:6]   = INCR    (increment amount; 0 means 1)
[5:2]   = WRAP    (wrap boundary for INCR_GET_PTR; 0=no wrap)
[1:0]   = IND_32  (destination word offset within 16-byte aligned region)
```

<a id="noc-atomics--for-cas"></a>
#### For CAS:
```
[15:12] = INS     (0x4)
[11:8]  = SetVal  (value to write if comparison succeeds)
[7:4]   = CmpVal  (value to compare against)
[3:2]   = Ofs     (word offset)
[1:0]   = IND_32
```

<a id="noc-atomics--for-swap-mask-variant"></a>
#### For SWAP (mask variant):
```
[15:12] = INS     (0x3)
[11:4]  = Mask    (8 bits — selects which 16-bit granules to write)
[3:2]   = (unused)
[1:0]   = IND_32
```

<a id="noc-atomics--for-acc-parallel-addition"></a>
#### For ACC (parallel addition):
```
[15:12] = INS     (0x9)
[2:0]   = Fmt     (data format selector)
```


<a id="noc-atomics--incr_get_ptr--atomic-increment-with-wrap-opcode-0x2"></a>
### INCR_GET_PTR — Atomic Increment with Wrap (opcode 0x2)

Increments a 32-bit value at the target L1 address, returning the old value. If the new value reaches or exceeds the wrap boundary, it resets to 0. This is the building block for circular buffer pointer management.

<a id="noc-atomics--functional-model"></a>
#### Functional Model

```python
def atomic_incr_get_ptr(target_mem, targ_addr, at_len_be, noc_at_data):
    """
    at_len_be fields:
      INS       = (at_len_be >> 12) & 0xF  = 0x2
      INCR      = (at_len_be >> 6) & 0xF   (0 means increment by 1)
      WRAP      = (at_len_be >> 2) & 0xF   (0 means no wrap)
      IND_32    = at_len_be & 0x3
    """
    incr = (at_len_be >> 6) & 0xF
    if incr == 0:
        incr = 1
    wrap = (at_len_be >> 2) & 0xF

    # Read old value
    old_val = target_mem.read32(targ_addr)

    # Compute new value
    new_val = old_val + incr
    if wrap > 0 and new_val >= wrap:
        new_val = 0

    # Write new value
    target_mem.write32(targ_addr, new_val & 0xFFFFFFFF)

    # Return old value to NOC_RET_ADDR_LO (if NOC_CMD_RESP_MARKED)
    return old_val
```

<a id="noc-atomics--tensix-coprocessor-analog-atincgetptr-opcode-0x62"></a>
#### Tensix Coprocessor Analog: ATINCGETPTR (opcode 0x62)

ATINCGETPTR is a Scalar Unit instruction that implements FIFO push/pop atomics. It checks empty/full conditions before incrementing:
- `Ofs=0` (pop): increments read pointer if FIFO is not empty
- `Ofs=1` (push): increments write pointer if FIFO is not full

Retries in hardware if the FIFO condition is not met; takes at least 15 cycles per attempt.

<a id="noc-atomics--difference-from-incr_get"></a>
#### Difference from INCR_GET

| Feature | INCR_GET (0x1) | INCR_GET_PTR (0x2) |
|---------|----------------|---------------------|
| Wrap | No wrap | Wraps to 0 when `new_val >= wrap` |
| WRAP field | Ignored | Controls wrap boundary |
| Use case | Simple counters, semaphores | Circular buffer pointers |


<a id="noc-atomics--cas--compare-and-swap-opcode-0x4"></a>
### CAS — Compare-And-Swap (opcode 0x4)

Atomically reads the target word, compares it against a value, and if equal, replaces it with a new value. Returns the original value so software can determine whether the swap succeeded.

<a id="noc-atomics--functional-model-1"></a>
#### Functional Model

```python
def atomic_cas(target_mem, targ_addr, at_len_be, noc_at_data):
    """
    at_len_be fields:
      INS     = (at_len_be >> 12) & 0xF  = 0x4
      SetVal  = (at_len_be >> 8) & 0xF   (value to write on match — 4-bit NOC CAS)
      CmpVal  = (at_len_be >> 4) & 0xF   (value to compare against — 4-bit NOC CAS)
      Ofs     = (at_len_be >> 2) & 0x3   (word offset)
    """
    # Wider CAS uses NOC_AT_DATA for compare/set values:
    compare = noc_at_data & 0xFFFF
    swap_val = (noc_at_data >> 16) & 0xFFFF

    # Read original value at target address
    result = target_mem.read32(targ_addr)

    # Compare against low 16 bits
    l1_addr = (targ_addr & ~0xF) + ((at_len_be >> 2) & 0x3) * 4
    original = target_mem.read32(l1_addr)

    if (original & 0xFFFF) == compare:
        target_mem.write32(l1_addr, (original & 0xFFFF0000) | swap_val)

    # Return original value at targ_addr (for success/failure detection)
    return result
```

The ISA documentation specifies the full functional model as:
```c
atomic {
    Result = *(uint32_t*)NOC_TARG_ADDR_LO;
    uint32_t* L1Address = (uint32_t*)((NOC_TARG_ADDR_LO & ~0xf) + (NOC_AT_LEN_BE.Ofs * 4));
    uint32_t OriginalValue = *L1Address;
    if (OriginalValue == NOC_AT_LEN_BE.CmpVal) {
        *L1Address = NOC_AT_LEN_BE.SetVal;
    }
}
```

<a id="noc-atomics--tensix-coprocessor-analog-atcas-opcode-0x64"></a>
#### Tensix Coprocessor Analog: ATCAS (opcode 0x64)

ATCAS is a Scalar Unit instruction that spins on an L1 address until a 4-bit field equals `CmpVal`, then writes `SetVal`. Takes at least 15 cycles per attempt. Documented in the Wormhole ISA; may not exist on Blackhole.


<a id="noc-atomics--swap--atomic-swap-opcodes-0x3-and-0x7"></a>
### SWAP — Atomic Swap (opcodes 0x3 and 0x7)

Two variants: mask-based (0x3) and full 32-bit (0x7).

<a id="noc-atomics--mask-variant-opcode-0x3"></a>
#### Mask Variant (opcode 0x3)

Writes `NOC_AT_DATA` to selected 16-bit granules within a 16-byte aligned region of L1. An 8-bit mask selects which of the 8 possible 16-bit slots to overwrite. Returns the original 32-bit value at the target address.

```python
def atomic_swap_mask(target_mem, targ_addr, at_len_be, noc_at_data):
    """
    at_len_be fields:
      INS   = 0x3
      Mask  = (at_len_be >> 4) & 0xFF   (8 bits, one per 16-bit granule)
    """
    mask = (at_len_be >> 4) & 0xFF

    # Read original value
    result = target_mem.read32(targ_addr)

    # Write selected 16-bit granules
    l1_base = targ_addr & ~0xF
    to_write = [noc_at_data & 0xFFFF, (noc_at_data >> 16) & 0xFFFF]
    for i in range(8):
        if mask & (1 << i):
            addr = l1_base + i * 2
            target_mem.write16(addr, to_write[i & 1])

    return result
```

<a id="noc-atomics--index-variant--swap_4b-opcode-0x7"></a>
#### Index Variant / SWAP_4B (opcode 0x7)

Writes the full 32 bits of `NOC_AT_DATA` to the word at `L1Address = (NOC_TARG_ADDR_LO & ~0xF) + (Ofs * 4)`. Returns the original 32-bit value at `NOC_TARG_ADDR_LO`.

```python
def atomic_swap_4b(target_mem, targ_addr, at_len_be, noc_at_data):
    result = target_mem.read32(targ_addr)
    ofs = (at_len_be >> 2) & 0x3
    l1_addr = (targ_addr & ~0xF) + ofs * 4
    target_mem.write32(l1_addr, noc_at_data & 0xFFFFFFFF)
    return result
```

<a id="noc-atomics--tensix-coprocessor-analog-atswap-opcode-0x63"></a>
#### Tensix Coprocessor Analog: ATSWAP (opcode 0x63)

ATSWAP is a Scalar Unit instruction that writes up to 128 bits from GPRs to L1 using a mask (8 bits × 16-bit granules). Despite the name, it does **not** return the old value to a GPR. Takes ~3 cycles to occupy ThCon; sustained throughput ≤ 1 per 12 cycles.


<a id="noc-atomics--acc--parallel-accumulate-opcode-0x9"></a>
### ACC — Parallel Accumulate (opcode 0x9)

The most complex atomic operation. Performs SIMD addition of `NOC_AT_DATA` (broadcast) onto 16 bytes of L1, with format-dependent interpretation. Always operates on a full 16-byte aligned region — no lane mask is available.

<a id="noc-atomics--format-table"></a>
#### Format Table

| Fmt | L1 interpretation | NOC_AT_DATA interpretation | Arithmetic |
|-----|-------------------|---------------------------|------------|
| 0 | 4× fp32 | 1× fp32, broadcast to 4 | Flush denormals |
| 1 | 8× fp16 | 2× fp16, broadcast to 8 | Flush denormals |
| 2 | 8× bf16 | 2× bf16, broadcast to 8 | Flush denormals |
| 4 | 4× u32 | 1× u32, broadcast to 4 | Wrapping two's complement |
| 7 | 16× u8 | 4× u8, broadcast to 16 | Saturating |

Formats 8–15 mirror 0–7 with minor behavioral differences (e.g., format 12 = INT32 wrapping, format 13 = INT32 wrapping, format 15 = INT8 wrapping instead of saturating).

<a id="noc-atomics--functional-model-2"></a>
#### Functional Model

```python
import struct

def atomic_acc(target_mem, targ_addr, at_len_be, noc_at_data):
    fmt = at_len_be & 0x7
    l1_addr = targ_addr & ~0xF
    l1_bytes = target_mem.read_bytes(l1_addr, 16)
    at_bytes = struct.pack('<I', noc_at_data)

    if fmt == 0:       # FP32: 4 lanes
        for i in range(4):
            old = struct.unpack_from('<f', l1_bytes, i*4)[0]
            add = struct.unpack_from('<f', at_bytes, 0)[0]   # broadcast
            result = flush_denormal(old + add)
            struct.pack_into('<f', l1_bytes, i*4, result)

    elif fmt == 1:     # FP16: 8 lanes
        for i in range(8):
            old = fp16_to_float(struct.unpack_from('<H', l1_bytes, i*2)[0])
            add = fp16_to_float(struct.unpack_from('<H', at_bytes, (i & 1)*2)[0])  # 2-way broadcast
            result = float_to_fp16(flush_denormal(old + add))
            struct.pack_into('<H', l1_bytes, i*2, result)

    elif fmt == 2:     # BF16: 8 lanes
        for i in range(8):
            old = bf16_to_float(struct.unpack_from('<H', l1_bytes, i*2)[0])
            add = bf16_to_float(struct.unpack_from('<H', at_bytes, (i & 1)*2)[0])
            result = float_to_bf16(flush_denormal(old + add))
            struct.pack_into('<H', l1_bytes, i*2, result)

    elif fmt == 4:     # INT32: 4 lanes, wrapping
        for i in range(4):
            old = struct.unpack_from('<i', l1_bytes, i*4)[0]
            add = struct.unpack_from('<i', at_bytes, 0)[0]
            result = (old + add) & 0xFFFFFFFF
            struct.pack_into('<I', l1_bytes, i*4, result)

    elif fmt == 7:     # INT8: 16 lanes, saturating
        for i in range(16):
            old = l1_bytes[i]
            add = at_bytes[i & 3]  # 4-way broadcast
            result = min(255, max(0, old + add))  # unsigned saturating
            l1_bytes[i] = result

    target_mem.write_bytes(l1_addr, l1_bytes)

    # ACC does not return a meaningful value to NOC_RET_ADDR_LO
    return None  # UndefinedValue
```

<a id="noc-atomics--usage"></a>
#### Usage

ACC is used for distributed accumulation in multi-core operations — each core atomically adds its partial result to a shared L1 buffer without needing locks:

```c
// From tt-metal firmware (noc.c)
NOC_AT_INS(NOC_AT_INS_ACC) | NOC_AT_ACC_FORMAT(data_format) | NOC_AT_ACC_SAT_DIS(disable_saturation)
```

<a id="noc-atomics--acc-format-constants"></a>
#### ACC Format Constants

```c
#define NOC_AT_ACC_FP32       0x0
#define NOC_AT_ACC_FP16_A     0x1
#define NOC_AT_ACC_FP16_B     0x2
#define NOC_AT_ACC_INT32      0x3
#define NOC_AT_ACC_INT32_COMPL 0x4
#define NOC_AT_ACC_INT32_UNS  0x5
#define NOC_AT_ACC_INT8       0x6
```


<a id="noc-atomics--response-handling"></a>
### Response Handling

All atomic operations (except ACC) return a result to `NOC_RET_ADDR_LO` if `NOC_CMD_RESP_MARKED` is set:

```c
// At the target tile, after the atomic completes:
*(uint32_t*)NOC_RET_ADDR_LO = Result;    // original value at target address
memory_barrier;
atomic {
    NIUCounters.NIU_MST_ATOMIC_RESP_RECEIVED += 1;
    NIUCounters.NIU_MST_REQS_OUTSTANDING_ID(NOC_PACKET_TRANSACTION_ID) -= 1;
}
```

Software polls `NIU_MST_ATOMIC_RESP_RECEIVED` or the outstanding-requests counter to determine when the response has arrived and the result is available.

For ACC, the response contains an undefined value — the operation is fire-and-forget from the initiator's perspective.


<a id="noc-atomics--emulator-implementation-notes"></a>
### Emulator Implementation Notes

1. **Atomicity**: In a single-threaded synchronous emulator, all operations are inherently atomic. No special locking is needed.
2. **Address alignment**: All atomic operations operate on 16-byte aligned addresses (`targ_addr & ~0xF`). The `Ofs` / `IND_32` fields select a word within that 16-byte region.
3. **Response counters**: The emulator must increment `NIU_MST_ATOMIC_RESP_RECEIVED` and decrement the per-transaction outstanding counter when the response is generated.
4. **Multicast**: Atomic operations can be multicast. Each target tile performs the operation independently. The response comes from the first tile in the multicast range.


<a id="noc-atomics--source-references"></a>
### Source References

| Source | Path |
|--------|------|
| NOC Atomics ISA (BH) | `tt-isa-documentation/BlackholeA0/NoC/Atomics.md` |
| ATINCGET ISA (WH) | `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/ATINCGET.md` |
| ATINCGETPTR ISA (WH) | `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/ATINCGETPTR.md` |
| ATCAS ISA (WH) | `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/ATCAS.md` |
| ATSWAP ISA (WH) | `tt-isa-documentation/WormholeB0/TensixTile/TensixCoprocessor/ATSWAP.md` |
| Python emulator (atomics) | `blackhole-py/emu/noc.py` |
| NOC parameter constants | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/noc/noc_parameters.h` |
| Firmware NOC API | `tt-metal/tt_metal/hw/firmware/src/tt-1xx/blackhole/noc.c` |
| NIU emulator spec | `./niu.md` |
| Existing INCR_GET docs | `./niu.md` §13 (Atomic Operations) |

<a id="stream-registers"></a>
## Stream / NOC Overlay Registers — Blackhole Tensix Emulation
<a id="stream-registers--stream--noc-overlay-registers--blackhole-tensix-emulation"></a>

<a id="stream-registers--1-address-space"></a>
### 1. Address Space

64 streams per tile at base `0xFFB40000`, stride `0x1000` per stream, total 256 KiB.

```
STREAM_REG_ADDR(stream_id, reg_id) = 0xFFB40000 + stream_id * 0x1000 + reg_id * 4
```

<a id="stream-registers--2-cb-to-stream-mapping-blackhole-specific"></a>
### 2. CB-to-Stream Mapping (Blackhole-specific)

On Blackhole, `OPERAND_START_STREAM = 0`, so CB N maps directly to stream N (streams 0–63).

Sources:
- `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/stream_io_map.h`: `OPERAND_START_STREAM = 0`; `get_operand_stream_id(operand)` returns `OPERAND_START_STREAM + operand`.
- `tt-metal/tt_metal/hw/firmware/src/tt-1xx/trisc.cc`: `init_sync_registers()` iterates via `get_operand_stream_id(operand)`, confirming streams 0..NUM_CIRCULAR_BUFFERS-1.

Note: Wormhole used `OPERAND_START_STREAM = 8`. Blackhole reset this to 0. Do not apply a +8 offset in the emulator.

<a id="stream-registers--3-critical-registers-for-cb-synchronization"></a>
### 3. Critical Registers for CB Synchronization

Only two register indices within each stream matter for CB operation:

| Reg Index | Byte Offset | Name | Access | Purpose |
|-----------|-------------|------|--------|---------|
| 8 | `+0x020` | `STREAM_REMOTE_DEST_BUF_START_REG_INDEX` | R/W | `tiles_acked` counter |
| 10 | `+0x028` | `STREAM_REMOTE_DEST_BUF_SIZE_REG_INDEX` | R/W | `tiles_received` counter |

CB API mapping:
- `cb_push_back(cb, n)` — atomically adds n to `tiles_received` at stream cb, reg 10
- `cb_wait_front(cb, n)` — polls `tiles_received` at stream cb, reg 10 until (received - acked) >= n
- `cb_pop_front(cb, n)` — atomically adds n to `tiles_acked` at stream cb, reg 8
- `cb_reserve_back(cb, n)` — polls `tiles_acked` at stream cb, reg 8 until (acked + n - received) <= num_pages

TRISC0 zeroes both registers for all CBs during `init_sync_registers()` (triggered by `RUN_SYNC_MSG_INIT_SYNC_REGISTERS = 0x03` from BRISC). The zeroing loop steps through streams 0–63 (or however many CBs are active based on `NUM_CIRCULAR_BUFFERS`).

<a id="stream-registers--4-sync-register-general-purpose"></a>
### 4. Sync Register (General Purpose)

| Reg Index | Byte Offset | Name | Access | Purpose |
|-----------|-------------|------|--------|---------|
| 31 | `+0x07C` | `STREAM_PHASE_AUTO_CFG_PTR_REG_INDEX` | R/W | General-purpose sync register, used by BRISC/NCRISC for kernel-to-dispatch signaling |

Used by `get_sync_register_ptr()` in firmware.

<a id="stream-registers--5-dispatch-signaling-stream-48"></a>
### 5. Dispatch Signaling (Stream 48)

The dispatch message address is:
```
DISPATCH_MESSAGE_ADDR = 0xFFB40000 + (48 * 0x1000) + (270 * 4) = 0xFFB70438
```

Register 270 (`STREAM_REMOTE_DEST_BUF_SPACE_AVAILABLE_UPDATE_REG_INDEX`) at stream 48 is the dispatch signaling register. The `dispatch_message_offset` field in `go_msg_t` selects which stream offset from base 48 to use. Firmware computes this via `firmware_common.h:calculate_dispatch_addr()`.

For basic emulation (slow dispatch, no fast dispatch pipeline), this register only needs to be a write sink. For fast dispatch, it needs to trigger the dispatch completion protocol.

<a id="stream-registers--6-emulator-implementation"></a>
### 6. Emulator Implementation

Model the stream register space as a sparse array. Only implement:

1. **Streams 0–63, regs 8 and 10**: These are the CB tile counters. Initialize to 0. Support read and write.
2. **Stream 0, reg 31**: Sync register pointer. Simple read/write.
3. **Stream 48, reg 270**: Dispatch signaling. Write sink for slow dispatch; completion trigger for fast dispatch.

All other stream registers can return 0 on read and accept writes silently.

```python
class StreamRegisters:
    def __init__(self):
        # Only need reg 8 (tiles_acked) and reg 10 (tiles_received) per stream
        self.tiles_acked = [0] * 64     # stream N -> tiles_acked
        self.tiles_received = [0] * 64  # stream N -> tiles_received
        self.sync_reg = 0               # stream 0 reg 31
        self.dispatch_msg = 0           # stream 48 reg 270

    def read(self, stream_id, reg_id):
        if reg_id == 8 and stream_id < 64:
            return self.tiles_acked[stream_id]
        elif reg_id == 10 and stream_id < 64:
            return self.tiles_received[stream_id]
        elif stream_id == 0 and reg_id == 31:
            return self.sync_reg
        return 0

    def write(self, stream_id, reg_id, value):
        if reg_id == 8 and stream_id < 64:
            self.tiles_acked[stream_id] = value
        elif reg_id == 10 and stream_id < 64:
            self.tiles_received[stream_id] = value
        elif stream_id == 0 and reg_id == 31:
            self.sync_reg = value
        elif stream_id == 48 and reg_id == 270:
            self.dispatch_msg = value
```

<a id="stream-registers--7-init_sync_registers-zeroing-pattern"></a>
### 7. init_sync_registers() Zeroing Pattern

When TRISC0 receives `RUN_SYNC_MSG_INIT_SYNC_REGISTERS` (0x03), it zeroes the CB tile counters:

```python
for cb in range(NUM_CIRCULAR_BUFFERS):  # 64 on Blackhole
    stream_regs.write(cb, 8, 0)   # tiles_acked = 0
    stream_regs.write(cb, 10, 0)  # tiles_received = 0
```

<a id="stream-registers--8-source-references"></a>
### 8. Source References

| Symbol / Function | Source File |
|-------------------|-------------|
| `OPERAND_START_STREAM`, CB-to-stream mapping | `tt-metal/tt_metal/hw/inc/internal/tt-1xx/blackhole/stream_io_map.h` |
| `STREAM_REMOTE_DEST_BUF_START_REG_INDEX` (reg 8) | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/blackhole/noc/stream_io_map.h` |
| `STREAM_REMOTE_DEST_BUF_SIZE_REG_INDEX` (reg 10) | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/blackhole/noc/stream_io_map.h` |
| `STREAM_PHASE_AUTO_CFG_PTR_REG_INDEX` (reg 31) | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/blackhole/noc/stream_io_map.h` |
| `STREAM_REMOTE_DEST_BUF_SPACE_AVAILABLE_UPDATE_REG_INDEX` (reg 270) | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/blackhole/noc/stream_io_map.h` |
| `get_sync_register_ptr()` | `tt-metal/tt_metal/hw/firmware/src/common/firmware_common.h` |
| `calculate_dispatch_addr()` | `tt-metal/tt_metal/hw/firmware/src/common/firmware_common.h` |
| `RUN_SYNC_MSG_INIT_SYNC_REGISTERS` (0x03) | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/dev_msgs.h` |
| `init_sync_registers()` | `tt-metal/tt_metal/hw/firmware/src/trisc.cc` |
| `cb_push_back`, `cb_wait_front`, `cb_pop_front`, `cb_reserve_back` | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/circular_buffer_init.h` |
| `go_msg_t`, `dispatch_message_offset` | `tt-metal/tt_metal/hw/inc/tt_metal/hw/inc/dev_msgs.h` |
