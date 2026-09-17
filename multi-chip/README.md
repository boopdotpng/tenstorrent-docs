# Multi-chip and multi-host execution

These are TT-Metal/TT-Fabric source studies and design notes. The single-card
blackhole-py tests used in the September hardware review do not establish
Ethernet, cross-host collectives, or remote dispatch correctness. Proposed
blackhole-py APIs in these pages are sketches, not implemented interfaces.

## Documents

- [TT-Fabric and Topology Internals](fabric-and-topology-internals.md)
- [Multi-Host and Remote Card Architecture](multi-host-and-remote-card-architecture.md)
