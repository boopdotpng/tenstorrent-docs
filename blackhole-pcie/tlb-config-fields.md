# TLB Config Fields (Blackhole)

Quick reference for `TLBConfig` fields when configuring host-to-device TLB windows.

## Field summary

| Field | Purpose |
|-------|---------|
| `addr` | 64-bit offset into the target tile's local address space (L1 offset for Tensix, bank offset for DRAM) |
| `start` / `end` | NOC (x, y) coordinates. For unicast, `start == end`. For multicast, defines a rectangle of tiles |
| `noc` | Which NoC to use: `0` (right/down) or `1` (left/up) |
| `mcast` | `True` = multicast writes to all tiles in the rectangle. Reads can't multicast |
| `ordering` | PCIe tile ordering mode (see below) |
| `linked` | **Always 0.** Never safe to use (KMD can interleave its own TLB accesses) |
| `static_vc` | Static virtual channel — forces deterministic VC routing through NoC |

## `ordering` — PCIe tile behavior

Controls how aggressively the PCIe tile sends transactions into the NoC:

| Value | Mode | Behavior |
|-------|------|----------|
| `0` | Default | Many transactions in-flight, doesn't wait for completion. Max parallelism. |
| `1` | Strict AXI | Won't start new read until previous read completes, same for writes. |
| `2` | Posted Writes | Returns write ACK immediately when data enters NoC (doesn't wait for destination ACK). |
| `3` | Counted Writes | For tracking completion. |

## `static_vc` — NoC routing behavior

Controls whether packets can change virtual channels mid-route:

| Value | Behavior |
|-------|----------|
| `0` | Routers dynamically pick VCs per hop — more parallelism, but packets can reorder |
| `1` | Software dictates VC for all hops — packets from same source to dest stay in order |

## How `ordering` and `static_vc` interact

```
Host write → [PCIe Tile] → [NoC routers] → [Destination NIU]
              ordering      static_vc
```

| `ordering` | `static_vc` | Result |
|------------|-------------|--------|
| `0` | `0` | Max parallelism. Packets can reorder at PCIe tile AND in NoC. Fast but chaotic. |
| `0` | `1` | PCIe tile sends many at once, but they stay ordered through NoC routers. |
| `1` | `0` | PCIe tile serializes, but packets could still reorder in NoC (unlikely in practice). |
| `1` | `1` | Full ordering. Slowest but safest. |

## `linked` — Don't use it

From the ISA docs:

> It is never safe to set this to `true`, as the kernel driver reserves the right to use its TLB window at any time, and *it* always has `linked` set to `false`.

`linked` chains multiple NoC requests into a transaction where they share a VC. Problems:
- All requests must go to the same destination tile
- VC is locked until you complete the transaction with `linked=0`
- KMD can interleave its own accesses, breaking your transaction

**Always use `linked=0`.**

## Recommended configs

```python
# Register access (strict ordering)
TLBConfig(
  addr=reg_offset,
  start=(x, y), end=(x, y),
  noc=0, mcast=False,
  ordering=1,   # Strict AXI
  linked=0,     # Always
  static_vc=1,  # Deterministic VC
)

# Bulk L1/DRAM writes (throughput)
TLBConfig(
  addr=l1_offset,
  start=(x, y), end=(x, y),
  noc=0, mcast=False,
  ordering=0,   # Default (or 2 for posted)
  linked=0,
  static_vc=0,  # Dynamic VC
)

# Multicast to Tensix grid
TLBConfig(
  addr=l1_offset,
  start=(1, 2), end=(16, 11),  # Tensix grid
  noc=0, mcast=True,
  ordering=0,
  linked=0,
  static_vc=0,
)
```

## References

- `tt-isa-documentation/BlackholeA0/PCIExpressTile/HostToDeviceTLBs.md`
- `tt-isa-documentation/BlackholeA0/NoC/MemoryMap.md` (NOC_CTRL register)
- `tt-isa-documentation/WormholeB0/NoC/Ordering.md` (ordering semantics)
