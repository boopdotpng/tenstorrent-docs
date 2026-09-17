# Matrix multiplication

Read [the matmul walkthrough](fast-matmul-eli5.md), then
[precision and spills](fp32-accumulation.md) and
[row-major input gathering](../kernel-dev/row-major-matmul.md).
The role-split pages describe TT-Metal schedules and design choices.
Older P100A benchmark tables, port plans, and the synchronization drawing are
[archived](../archive/README.md); they are not current runtime measurements.

## Documents

- [How a Blackhole matmul stays busy](fast-matmul-eli5.md)
- [Matmul accumulation precision](fp32-accumulation.md)
- [Matmul 2D mcast role split (ELI5) (2026-02-09)](matmul-2d-mcast-role-split-eli5.md)
- [When to use 4-role 2D multicast vs simpler kernel architectures](when-to-use-4-role-mcast.md)
