# NoC (Network on Chip)

The NoC is the primary data-movement fabric connecting all tiles.

## Fundamentals

**Dual independent networks:**
- **NoC0**: data flows right/down
- **NoC1**: data flows left/up
- Together they form a 2D torus with wraparound edges.

**Packet structure:**
- Transaction = 1+ packets
- Packet = 1 header flit + up to 256 data flits
- Flit = 512 bits (64 bytes)
- Max packet size = 16,384 bytes (256 × 64)

**Performance:**
- Clock: 1.35 GHz
- Throughput per NoC: 512 bits/cycle (64 bytes/cycle)
- Aggregate bandwidth: ~172 GB/s per NoC at full utilization
- Router-to-router latency: 9 cycles
- NIU-to-router latency: ~5 cycles

## Transaction Types

**Reads:**
- Read from remote tile address space; response returns to initiator.

**Writes:**
- Posted (no ACK) or non-posted
- Immediate data (32-bit inline to MMIO in Tensix/Ethernet tiles only) or DMA from initiator memory
- Broadcast to rectangle of tiles (Tensix only)
- Writes ≤ 64 bytes can use byte-enable masks; larger writes are contiguous spans
- Max 16,384 bytes for L1↔L1 transfers

**Atomics:**
- 128-bit atomics on remote L1
- Operations: accumulate, compare-and-swap, swap, increment, etc.
- 32-bit result returned to initiator
- Supported only on L1 of Tensix/Ethernet tiles (not DRAM/MMIO/PCIe)

## NIU (NoC Interface Unit) Programming

Each tile has 2 NIUs (one per NoC) with 4 request initiators each. Tensix/Ethernet/DRAM tiles expose NIU initiators;
L2CPU and PCIe tiles inject NoC traffic via different mechanisms.

**Key MMIO registers (per initiator):**
```
NIU_BASE + 0x0000: NOC_TARG_ADDR_LO/MID/HI   # Target tile coords & address
NIU_BASE + 0x000C: NOC_RET_ADDR_LO/MID/HI    # Return address for responses
NIU_BASE + 0x001C: NOC_CTRL                   # Request type & flags
NIU_BASE + 0x0020: NOC_AT_LEN_BE              # Length or atomic opcode
NIU_BASE + 0x0028: NOC_AT_DATA                # Immediate data
NIU_BASE + 0x0040: NOC_CMD_CTRL               # Write 1 to initiate
```

**NIU base addresses:**
- NoC0: `0x0000_0000_FFB2_0000`
- NoC1: `0x0000_0000_FFB3_0000`

## Coordinate System

**Translated address space:**
- X: 0–16, Y: 0–30
- Tensix tiles: X=1–16, Y=2–11 (140 tiles in a 10×14 grid with gaps)
- DRAM tiles: X=17–18, Y=12–23
- L2CPU tiles: X=8, Y=26–29

Translation handles yield variation and renumbers harvested tiles into fixed coordinates.

## Virtual Channels & Ordering

- 4-bit VC number:
  - 2 class bits: `00`/`01` = unicast, `10` = broadcast, `11` = response
  - 1 dateline bit: flips at predetermined route points
  - 1 buddy bit: can change per hop for congestion adaptation
- Ordering is weak by default.
- Ordering can be enforced with `NOC_CMD_VC_LINKED` and `NOC_CMD_VC_STATIC`.
- Atomics provide ordering at the target tile.
- Advanced features (multi-packet transactions, broadcasts without path reservation, nonzero arbitration priority) need
  software care to avoid deadlock.

## Throughput Best Practices

- Use both NoC0 and NoC1 to double bandwidth.
- Use max packet size (16 KiB) for best header:data ratio.
- Avoid small transactions (<128 bytes).
- Use broadcasts for 1-to-N where possible (Tensix only).
- Exploit weak ordering; avoid unnecessary serialization.
