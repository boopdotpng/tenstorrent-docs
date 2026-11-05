# Microbench Report Archive

Raw reports are append-only historical notes. Prefer `../status.md` for the
current state; use these files when you need the underlying measurements.

## NoC / DRAM

Start with `noc/reading-guide.md` if you are new to the NoC or these report
tables.

| topic | reports |
|---|---|
| from-zero guide | `noc/reading-guide.md` |
| DRAM endpoint behavior | `noc/dram-noc-bench.md`, `noc/dram-noc-structural-matrix.md`, `noc/noc-dram-endpoint-matrix.md` |
| packet latency and dependencies | `noc/noc-packet-latency.md`, `noc/noc-packet-latency-pipelined.md`, `noc/noc-dependency-latency.md` |
| arbitration and VC flags | `noc/noc-arbitration.md`, `noc/noc-arbitration-priority.md`, `noc/noc-vc-command-flags.md`, `noc/noc-directional-vc-stress.md`, `noc/noc-crossing-vc-probe.md` |
| multicast and overlays | `noc/noc-mcast-scheduler-calibration.md`, `noc/noc-overlay-mcast-poc.md`, `noc/noc-overlay-multistream-poc.md`, `noc/noc-overlay-stream-poc.md` |
| topology and routing | `noc/noc-topology.md`, `noc/noc-route-tomography.md`, `noc/noc-stream-sweep.md`, `noc/noc-same-initiator-active.md` |
| counters, command buffers, cross-endpoint effects | `noc/noc-counter-probe.md`, `noc/noc-cmd-buffer-concurrency.md`, `noc/noc-cross-endpoint-interference.md`, `noc/noc-mixed-rw-overlap.md` |
| scheduler model | `noc/noc-scheduler-model.md` |
| hardware run output | `noc/hardware-sweep-manifest.md`, `noc/hardware-logs/*.txt` |

## Tensix / DRISC

| topic | reports |
|---|---|
| DRISC GDDR DMA | `tensix/drisc-gddr-dma.md`, `tensix/drisc-gddr-dma-aggregate.md` |
| pack/unpack units | `tensix/pack-unpack-units.md` |

## Notes

Some reports have repeated run blocks or repeated command recipes because they
were generated during iterative hardware sweeps. Keep detailed duplicates here
only when they preserve distinct measurements; summarize durable conclusions in
`../status.md`.
