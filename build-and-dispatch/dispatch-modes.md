# Dispatch modes (fast vs slow) and architecture mapping

TT-Metal has two mutually exclusive dispatch modes:
- **Fast dispatch**: host enqueues commands to a device command queue; firmware dispatches on-device.
- **Slow dispatch**: host writes runtime args and launch messages directly to cores and waits for completion.

Mixing is prohibited; the dispatch state is latched on first use.

## Fast dispatch path

Primary entry points:
- `distributed::MeshDevice::create_unit_mesh()`
- `MeshCommandQueue` + `distributed::EnqueueMeshWorkload()`
- `distributed::Finish()`

Characteristics:
- Supports multi-device/mesh workflows
- Overlap of IO + compute
- Production path

## Slow dispatch path

Primary entry points:
- `CreateDevice()`
- `detail::WriteToBuffer()` / `detail::ReadFromBuffer()`
- `detail::LaunchProgram()`

Characteristics:
- Synchronous, single-device oriented
- Simpler control flow

## Architecture mapping (Blackhole)

From `blackhole/architecture.md`:
- Host orchestrates device setup and dispatch
- Brisc/Ncrisc do NoC/DMA orchestration
- Trisc threads push Tensix instruction streams

### Slow dispatch ↔ architecture
- Host directly programs per-core state and triggers execution
- Brisc/Ncrisc handle NoC DMA for reader/writer kernels
- Trisc threads push Tensix instructions

### Fast dispatch ↔ architecture
- Host enqueues CQ commands
- Device-side dispatch firmware programs the same Brisc/Trisc/Tensix pipeline
- CQ scheduling overlaps DMA and compute

## Harvesting + slow dispatch behavior

- Harvesting fuses off columns/tiles/banks
- Coordinate translation provides a stable logical view
- In slow dispatch, tt-metal writes **per core** (unicast), even when bytes are identical
- This avoids multicast rectangles that might include harvested/invalid endpoints

If you do your own multicast rectangles:
- avoid harvested columns
- avoid non-Tensix columns
- or use per-core unicast (slow-dispatch style)

## Choosing a path for a C ABI
- Minimal C wrapper: slow dispatch
- Production-like path: fast dispatch
