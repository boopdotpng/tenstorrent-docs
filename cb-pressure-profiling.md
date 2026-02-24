# CB Pressure Profiling for blackhole-py

Goal: measure average CB (circular buffer) fullness to identify whether compute consumes tiles faster than readers can feed, or vice versa.

## Background

Each Tensix core has up to 64 CBs. Occupancy is trivially computable:
```
occupancy = (uint16_t)(tiles_received - tiles_acked)
```

These two counters live in **stream overlay registers** at fixed per-CB addresses:
- `tiles_received` → `0xFFB40000 + cb_id * 0x1000 + 0x28`
- `tiles_acked` → `0xFFB40000 + cb_id * 0x1000 + 0x20`

The `LocalCBInterface` struct (in each RISC's local memory) also caches `fifo_rd_ptr`, `fifo_wr_ptr`, `fifo_num_pages`, etc.

## What tt-metal Already Exposes

### Compute-side CB stall zones (already instrumented)
- `llk_wait_tiles()` → `DeviceZoneScopedSumN1("CB-COMPUTE-WAIT-FRONT")` — TRISC0 waiting for input tiles
- `llk_wait_for_free_tiles()` → `DeviceZoneScopedSumN2("CB-COMPUTE-RESERVE-BACK")` — TRISC2 waiting for output space

These accumulate total stall time per kernel run. blackhole-py's profiler should already collect these as zone markers when `TT_PROFILER=1`.

### What is NOT tracked
- Instantaneous CB occupancy / average fill level
- Per-CB breakdown (which CB is the bottleneck)
- BRISC/NCRISC side stall time (reader/writer CB waits only have watcher waypoints, not profiler zones)

## Implementation Plan

### Phase 1: Stall-time proxy (easiest)

Confirm the existing `CB-COMPUTE-WAIT-FRONT` / `CB-COMPUTE-RESERVE-BACK` sum zones are already collected by the profiler. Interpretation:
- High WAIT-FRONT → reader feeding CBs too slowly (compute starved)
- High RESERVE-BACK → writer/consumer draining CBs too slowly (compute blocked)

This is already a good directional signal.

### Phase 2: Sampled occupancy via `DeviceTimestampedData`

Add lightweight instrumentation at `cb_push_back` / `cb_pop_front` that emits current fill level with a timestamp. This gives a per-CB time-series that can be averaged.

Option A — patch the CB API headers in tt-metal (fragile, upstream dependency):
```cpp
// In dataflow_api.h, after cb_push_back updates tiles_received:
#ifdef PROFILE_KERNEL
  uint16_t occupancy = (uint16_t)(tiles_received - tiles_acked);
  DeviceTimestampedData(occupancy | (cb_id << 16));
#endif
```

Option B — thin wrappers in blackhole-py firmware (preferred):
```cpp
// In kernel source, wrap the standard CB calls
inline void cb_push_back_profiled(uint32_t cb_id, uint32_t n) {
  cb_push_back(cb_id, n);
#ifdef PROFILE_KERNEL
  uint16_t occ = cb_interface[cb_id].tiles_received - cb_interface[cb_id].tiles_acked;
  DeviceTimestampedData(occ | (cb_id << 16));
#endif
}
```

Then in `profiler.py`, decode these markers:
- Extract `cb_id` from bits [31:16], `occupancy` from bits [15:0]
- Group by CB, compute time-weighted average occupancy
- Report as percentage of `fifo_num_pages`

### Phase 3: Host-side polling (zero firmware changes)

Read stream registers via TLB from the host between dispatches:
```python
for cb_id in active_cbs:
  tiles_received = tlb_read32(core, 0xFFB40000 + cb_id * 0x1000 + 0x28)
  tiles_acked = tlb_read32(core, 0xFFB40000 + cb_id * 0x1000 + 0x20)
  occupancy = (tiles_received - tiles_acked) & 0xFFFF
```

Coarse-grained (only captures inter-kernel snapshots) but useful for validating that CBs drain fully between programs. Could also be polled in a background thread during slow dispatch.

## Key Files

| File | What to modify |
|------|---------------|
| `profiler.py` | Add CB occupancy decoding for `DeviceTimestampedData` markers |
| `profiler_ui.py` | Add CB pressure visualization (per-CB bar chart or heatmap) |
| `device.py` | Expose `LocalCBConfig` data to profiler for computing % fullness |
| `defs.py` | Add stream overlay register constants |
| `firmware/brisc.cc` | (optional) Add host-side register reads |
| `codegen.py` | (optional) Inject CB wrapper macros when profiling enabled |

## Reference: CB API Functions

| Function | Side | What it does |
|----------|------|-------------|
| `cb_reserve_back(cb_id, n)` | Producer (BRISC/NCRISC) | Block until n free pages |
| `cb_push_back(cb_id, n)` | Producer | Signal n tiles ready |
| `cb_wait_front(cb_id, n)` | Consumer | Block until n tiles available |
| `cb_pop_front(cb_id, n)` | Consumer | Free n pages |
| `cb_pages_reservable_at_back(cb_id, n)` | Producer | Non-blocking free check |
| `cb_pages_available_at_front(cb_id, n)` | Consumer | Non-blocking available check |
