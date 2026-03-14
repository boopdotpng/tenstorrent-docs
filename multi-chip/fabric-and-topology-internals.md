# TT-Fabric and Topology Internals

How tt-metal discovers multi-chip topologies, builds routing tables, and moves data between chips over the ethernet fabric. Covers the EDM kernel, 1D/2D mesh modes, cross-host routing, and the current state of non-rectangular mesh support.

See also: `distributed-training-in-tt-metal.md` for the higher-level MeshDevice/MeshWorkload API layer.

## Architecture Overview

The topology system has three layers:

1. **Physical discovery** (`PhysicalSystemDescriptor`) — probes ethernet PHY on every chip to find which links are live and where they go.
2. **Logical mesh graph** (`MeshGraph` / `MeshGraphDescriptor`) — defines the desired mesh topology via a textproto config file (MGD).
3. **Topology mapping** (`TopologyMapper`) — maps logical mesh node IDs to physical ASIC IDs using a constraint-satisfaction solver (CSP with backtracking).

The glue is `ControlPlane`, which owns all three layers and drives initialization.

### Key source files

| File | Purpose |
|------|---------|
| `tt_metal/fabric/physical_system_descriptor.hpp/.cpp` | Raw ethernet topology discovery (local + global) |
| `tt_metal/api/tt-metalium/experimental/fabric/control_plane.hpp` | ControlPlane class — owns topology mapper, mesh graph, routing tables |
| `tt_metal/fabric/control_plane.cpp` | Routing table generation, ethernet channel direction assignment |
| `tt_metal/api/tt-metalium/experimental/fabric/mesh_graph.hpp` | MeshGraph — intra/inter mesh connectivity graphs |
| `tt_metal/api/tt-metalium/experimental/fabric/mesh_graph_descriptor.hpp` | MeshGraphDescriptor — parses MGD textproto, validates topology |
| `tt_metal/fabric/mesh_graph_descriptor.cpp` | Express connections, all-to-all, ring inter-mesh topology generation |
| `tt_metal/fabric/protobuf/mesh_graph_descriptor.proto` | MGD schema: `MeshDescriptor`, `TorusTopology`, `ExpressConnection` |
| `tt_metal/api/tt-metalium/experimental/fabric/topology_mapper.hpp` | TopologyMapper — CSP solver mapping logical to physical |
| `tt_metal/fabric/topology_mapper_utils.cpp` | `map_mesh_to_physical()` — the actual CSP/DFS algorithm |
| `tt_metal/fabric/routing_table_generator.cpp` | BFS for inter-mesh shortest paths, dimension-ordered intra-mesh |
| `tt_metal/api/tt-metalium/experimental/fabric/fabric_types.hpp` | `FabricConfig`, `RoutingDirection` enums |

## Topology Discovery

### Local discovery (per-host)

Each host independently iterates its local chips via UMD's `Cluster`:

```
for each chip on this host:
    for each ethernet core:
        read PHY link state
        if connected to a chip on the SAME host → EthConnection(is_local=true)
        if connected to a chip on a DIFFERENT host → ExitNodeConnection(is_local=false)
```

Intra-host connections (both ASICs accessible by the same PCIe tree) are stored in `PhysicalConnectivityGraph`. Cross-host connections are stored in `ExitNodeConnectionTable`, keyed by hostname.

### Global discovery (multi-host, via MPI)

Only runs in multi-host setups:

1. Every non-controller MPI rank serializes its local `PhysicalSystemDescriptor` to protobuf and sends to rank 0.
2. Rank 0 merges all descriptors, calls `remove_unresolved_nodes()` (prunes exit nodes whose remote isn't participating), then `generate_cross_host_connections()`.
3. Cross-referencing: if host A has exit node `src→X` and host B has exit node `X→dst`, the pair is registered as a bidirectional edge in `host_connectivity_graph`.
4. Rank 0 broadcasts the merged global descriptor back to all ranks.

After this, every host holds a complete topology including all ASICs across all servers.

## MeshDevice and MeshShape

`MeshDevice` is the central multi-chip abstraction. It owns a `ScopedDevices` (RAII lifetimes), a `MeshDeviceView` (logical 2D grid), and `MeshCommandQueue` per CQ.

`MeshShape` is N-dimensional (built on `ShapeBase`). Key method:

```cpp
bool MeshShape::is_line_topology() const {
    return std::count_if(cbegin(), cend(), [](size_t dim) { return dim != 1; }) <= 1;
}
```

Examples: `MeshShape(1, 8)`, `MeshShape(8, 1)`, `MeshShape(8)` are all line topologies. `MeshShape(4, 8)` is a 2D grid.

`MeshDevice::create(MeshDeviceConfig(shape, offset))` → `SystemMesh::get_mapped_devices()` → `ControlPlane` → `TopologyMapper` CSP solver.

## Fabric Modes

The **Fabric EDM (Ethernet Data Mover)** kernel runs on every active ERISC core and forms the inter-chip communication fabric. Configured via `FabricConfig`:

| Enum value | Mode | Description |
|------------|------|-------------|
| `DISABLED` (0) | Off | No fabric |
| `FABRIC_1D_NEIGHBOR_EXCHANGE` (1) | Lite fabric | 1 sender channel, no multi-hop forwarding. Only talks to immediate neighbors. |
| `FABRIC_1D` (2) | 1D line | Multi-hop forwarding along a line. 2 sender + 1 receiver channels. |
| `FABRIC_1D_RING` (3) | 1D ring | Ring with dateline deadlock avoidance. |
| `FABRIC_2D` (4) | 2D mesh | Full N/S/E/W routing. 8 sender + 2 receiver channels. |
| `FABRIC_2D_TORUS_X` (5) | 2D + X torus | Torus wrap along X axis. |
| `FABRIC_2D_TORUS_Y` (6) | 2D + Y torus | Torus wrap along Y axis. |
| `FABRIC_2D_TORUS_XY` (7) | Full torus | Both axes wrapped. |
| `CUSTOM` (8) | Custom | Bypasses validation only. No custom routing logic exists. |

The EDM kernel source is `tt_metal/fabric/impl/kernels/edm_fabric/fabric_erisc_router.cpp`.

### Routing directions

Routing uses a 4-direction compass (N/S/E/W) plus "local" (C) and "Z" (for inter-mesh). The routing table is a fixed `direction_table_t<MAX_MESH_SIZE>` with 3-bit entries per destination.

Intra-mesh routing is **dimension-ordered** (X-first): move N/S to align rows, then E/W to align columns. This is static, deterministic, single-path (no ECMP).

## Routing Tables

Two-level structure:

| Table | Key | Value | Purpose |
|-------|-----|-------|---------|
| `intra_mesh_table_` | `[mesh_id][src_chip][dst_chip]` | `RoutingDirection` | Routes within one mesh |
| `inter_mesh_table_` | `[mesh_id][src_chip][dst_mesh_id]` | `RoutingDirection` | Routes to exit node facing another mesh |
| `exit_node_lut_` | `[src_mesh][src_chip][dst_mesh]` | `exit_chip_id` | Which chip is the exit point for a given destination mesh |

### How packets are routed

Each packet header carries `dst_start_mesh_id` and `dst_start_chip_id`. At each ERISC hop:

1. Router checks if destination is local → deliver via NOC write.
2. If not local, consult `intra_mesh_table_` for next direction within the mesh.
3. At a mesh boundary (`is_intermesh_router_on_edge`), call `recompute_path()` using the new mesh's routing table.

This means the path is **NOT** fully pre-computed end-to-end. Each inter-mesh boundary ASIC re-derives the next hop from its local L1 routing table. The `write_routing_info_to_devices()` function writes per-chip tables to every Tensix and ETH core's L1 at `HalL1MemAddrType::ROUTING_TABLE`.

### Inter-mesh routing table generation

Uses BFS over the mesh graph (`routing_table_generator.cpp:180`) to find shortest paths between meshes. Exit node selection prefers:

1. The src chip itself if it's directly connected to the next mesh (zero intra-mesh overhead).
2. The geographically closest exit chip (Manhattan distance).
3. The least-loaded exit chip when distances tie.

## Blackhole Galaxy Mesh Graph Descriptors

Defined in `tt_metal/fabric/mesh_graph_descriptors/`:

| File | Shape | Topology | Channels | Hosts |
|------|-------|----------|----------|-------|
| `single_bh_galaxy_mesh_graph_descriptor.textproto` | 8x4 | MESH | 2, RELAXED | 1 |
| `single_bh_galaxy_torus_xy_graph_descriptor.textproto` | 8x4 | TORUS_XY (RING,RING) | 2, STRICT | 1 |
| `single_bh_galaxy_torus_x_graph_descriptor.textproto` | 8x4 | TORUS_X (LINE,RING) | 2, STRICT | 1 |
| `single_bh_galaxy_torus_y_graph_descriptor.textproto` | 8x4 | TORUS_Y (RING,LINE) | 2, STRICT | 1 |
| `dual_bh_galaxy_torus_xy_graph_descriptor.textproto` | 8x8 | TORUS_XY (RING,RING) | 2, RELAXED | 2 |
| `bh_qb_4x4_mesh_graph_descriptor.textproto` | 4x4 | TORUS_XY (RING,RING) | 2, STRICT | 2x2 |
| `p150_mesh_graph_descriptor.textproto` | 1x1 | MESH | 1 | 1 |
| `p150_x2_mesh_graph_descriptor.textproto` | 1x2 | MESH | 4 | 1 |
| `p150_x4_mesh_graph_descriptor.textproto` | 2x2 | MESH | 4 | 1 |
| `p150_x8_mesh_graph_descriptor.textproto` | 2x4 | MESH | 2 | 1 |
| `p300_mesh_graph_descriptor.textproto` | 1x2 | MESH | 2 | 1 |

Note: `dual_bh_galaxy` and `bh_qb_4x4` exist on disk but have **no entry** in `cluster_type_to_mesh_graph_descriptor`. They require `CUSTOM` cluster type with an explicit path.

### Blackhole vs Wormhole ethernet differences

| Property | Wormhole B0 | Blackhole |
|----------|-------------|-----------|
| Ethernet cores per chip | 16 (8 top + 8 bottom) | 14 (single row y=1) |
| ERISC processors per core | 1 | 2 (ERISC0 + ERISC1) |
| Max mesh dimensions | 2 | 3 (Z-direction for BH Galaxy UBB internal links) |
| Z-links | N/A | Channels 8,9 on BH Galaxy (skipped today, fragile hardcode) |
| NOC inline writes | Normal | Must be non-posted (BH hardware bug, forced flush) |

BH Galaxy Z-links (channels 8,9) connect cards within a UBB module. Currently skipped in `topology_mapper.cpp:1376` with a TODO acknowledging the port-number hardcode is not sustainable.

## Non-Rectangular Mesh Support: Current State

**Does not exist in any functional form.** Here is the status of each relevant feature:

| Feature | In schema? | Parsed? | Routed? | Usable? |
|---------|-----------|---------|---------|---------|
| Express connections (skip links) | Yes (proto) | Yes (MGD parser) | No | No — rejected by `validate_legacy_requirements()` when `backwards_compatible=true` |
| 3D mesh dims | Partial (BH allows 3) | Partial | No — `TT_FATAL(dims == 2)` in `populate_intra_mesh_connections()` | No |
| `FabricConfig::CUSTOM` | Yes (enum=8) | N/A | Bypasses validation only | No custom routing logic |
| Switch descriptors | Yes (proto) | Yes | Partial (treated as regular mesh) | No — `is_switch_mesh()` is a stub |

### Why it's structurally hard

1. **Routing is dimension-ordered**: N/S then E/W. Only 4 directions + "local". No "jump to chip 5" direction encoding.
2. **Routing table is fixed-size**: 3-bit direction per destination in `direction_table_t<MAX_MESH_SIZE>`.
3. **Topology mapper rejects non-rectangular layouts**: tries all `(rows, cols)` factor pairs and fails if none match physical connectivity.
4. **Express connections in MGD are dead code**: `populate_intra_mesh_express_connections()` stores them with direction `C` (Centre), but `MeshGraph::initialize_from_mgd()` never transfers them into `IntraMeshConnectivity`.

### What "relaxing strict mesh conditions" would require

Changes needed at every layer:

1. **MGD**: Remove `backwards_compatible` restriction so express connections aren't rejected.
2. **MeshGraph**: Transfer express connections from MGD storage into `IntraMeshConnectivity`.
3. **Routing table generator**: Switch from dimension-ordered to BFS/Dijkstra within the mesh (the inter-mesh routing already does BFS).
4. **EDM kernel**: The packet header route buffer uses 4-bit compass values per hop. Express links need either new direction encoding or a next-hop lookup table.
5. **Topology mapper**: Handle non-rectangular physical layouts in the CSP solver.

### The "virtual NxM mesh" idea

Map physical chips to logical NxM coordinates even if some ethernet links skip grid positions. Use express connections for shortcuts. Route as if it's NxM but with some hops being "free" (direct link instead of multi-hop). Conceptually sound but requires all 5 changes above.

## Fabric Data Delivery Mechanics

When a packet arrives at its destination chip, the ERISC router writes directly to the target NOC address via NOC 1:

```cpp
// fabric_edm_packet_transmission.hpp → execute_chip_unicast_to_local_chip()
static constexpr uint8_t edm_to_local_chip_noc = 1;

noc_async_write_one_packet_with_trid<...>(
    payload_start_address, dest_address, payload_size_bytes, ...
    edm_to_local_chip_noc, ...);
```

The `dest_address` is a full 64-bit NOC address embedded in the packet header by the sender. The ERISC fires a NOC write and the data lands at the specified address — any L1, any core, or DRAM. No Tensix intermediary for raw fabric data movement.

For dispatch command delivery, the ERISC writes into PREFETCH_D's L1 cmddat buffer (the address is pre-set in the packet header by PREFETCH_H). See `dispatch-kernel-pipeline-internals.md` for the full dispatch chain.

## Device-Side Fabric API

Tensix kernels use `tt_fabric_api.h` to send data through the fabric:

```cpp
fabric_unicast_send(dst_mesh_id, dst_chip_id, dst_noc_addr, payload, size);
fabric_async_write(noc_addr, payload, size);  // using pre-set route
fabric_atomic_inc(dst_addr, increment, wrap);
```

These write into an ERISC sender channel buffer on the local chip. The ERISC router picks up the packet and forwards it hop-by-hop using the L1 routing tables. No host involvement.

## UBB (Universal Base Board) Topology

UBB modules are identified by `BoardType::UBB_WORMHOLE` or `BoardType::UBB_BLACKHOLE`. Each chassis has up to 4 trays, identified by PCIe bus ID high nibble:

```cpp
// Blackhole UBB bus IDs per tray
{0x00, 0x40, 0xC0, 0x80}
// Wormhole UBB bus IDs per tray
{0xC0, 0x80, 0x00, 0x40}
```

Within a chassis: all trays share one host. Ethernet links between trays are `is_local=true`.

Across chassis: each chassis has its own host. QSFP links between chassis are `is_local=false` (cross-host). The MGD `host_topology` dimension controls the partitioning.

Single-host Galaxy optimization: corner chips are pinned to known fabric node IDs so QSFP links (physically on corner chips) align with logical mesh corners.
