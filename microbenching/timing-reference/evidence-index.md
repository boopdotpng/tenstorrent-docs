# Measurement evidence index

123 timing tables / 2074 rows in [measurement-tables.csv](measurement-tables.csv); 7738 structured case/interval records in [measurement-records.jsonl](measurement-records.jsonl). These include historical/adjusted/baseline/control records, not that many independent validated opcode measurements.

CSV preserves units, section and row labels. JSONL preserves raw samples and source JSON pointers; consult parent source context for firmware/job identity. Never pool cards, modes, partial intervals or controls automatically. Source hashes and repository revisions: [sources.json](sources.json).

| Report | Tables | Timing rows |
|---|---:|---:|
| [boop-docs/microbenching/timing-reference/evidence/historical/drisc-overlap-output-microbench.md](evidence/historical/drisc-overlap-output-microbench.md) | 4 | 8 |
| [boop-docs/microbenching/timing-reference/evidence/historical/math-backend-microbench.md](evidence/historical/math-backend-microbench.md) | 6 | 14 |
| [boop-docs/microbenching/timing-reference/evidence/historical/math-mvmul.md](evidence/historical/math-mvmul.md) | 2 | 12 |
| [boop-docs/microbenching/timing-reference/evidence/historical/pack-backend-microbench.md](evidence/historical/pack-backend-microbench.md) | 3 | 8 |
| [boop-docs/microbenching/timing-reference/evidence/historical/program-timing-microbench-summary.md](evidence/historical/program-timing-microbench-summary.md) | 1 | 5 |
| [boop-docs/microbenching/timing-reference/evidence/historical/riscv-contention-microbench.md](evidence/historical/riscv-contention-microbench.md) | 2 | 220 |
| [boop-docs/microbenching/timing-reference/evidence/historical/riscv-core-microbench.md](evidence/historical/riscv-core-microbench.md) | 2 | 237 |
| [boop-docs/microbenching/timing-reference/evidence/historical/riscv-memory-microbench.md](evidence/historical/riscv-memory-microbench.md) | 2 | 108 |
| [boop-docs/microbenching/timing-reference/evidence/historical/riscv-special-instr-microbench.md](evidence/historical/riscv-special-instr-microbench.md) | 2 | 115 |
| [boop-docs/microbenching/timing-reference/evidence/historical/sem-cb-microbench.md](evidence/historical/sem-cb-microbench.md) | 2 | 29 |
| [boop-docs/microbenching/timing-reference/evidence/historical/tensix-instr-microbench.md](evidence/historical/tensix-instr-microbench.md) | 1 | 10 |
| [boop-docs/microbenching/timing-reference/evidence/historical/unpack-backend-microbench.md](evidence/historical/unpack-backend-microbench.md) | 3 | 11 |
| [boop-docs/microbenching/timing-reference/evidence/historical/xmov-microbench.md](evidence/historical/xmov-microbench.md) | 8 | 60 |
| [boop-docs/microbenching/docs/noc/dram-noc-bench.md](../docs/noc/dram-noc-bench.md) | 2 | 48 |
| [boop-docs/microbenching/docs/noc/dram-noc-structural-matrix.md](../docs/noc/dram-noc-structural-matrix.md) | 1 | 6 |
| [boop-docs/microbenching/docs/noc/noc-arbitration-priority.md](../docs/noc/noc-arbitration-priority.md) | 3 | 26 |
| [boop-docs/microbenching/docs/noc/noc-arbitration.md](../docs/noc/noc-arbitration.md) | 5 | 60 |
| [boop-docs/microbenching/docs/noc/noc-atomic-calibration.md](../docs/noc/noc-atomic-calibration.md) | 7 | 120 |
| [boop-docs/microbenching/docs/noc/noc-atomic-visibility.md](../docs/noc/noc-atomic-visibility.md) | 2 | 7 |
| [boop-docs/microbenching/docs/noc/noc-counter-probe.md](../docs/noc/noc-counter-probe.md) | 2 | 12 |
| [boop-docs/microbenching/docs/noc/noc-cross-endpoint-interference.md](../docs/noc/noc-cross-endpoint-interference.md) | 1 | 3 |
| [boop-docs/microbenching/docs/noc/noc-crossing-vc-probe.md](../docs/noc/noc-crossing-vc-probe.md) | 1 | 6 |
| [boop-docs/microbenching/docs/noc/noc-dependency-latency.md](../docs/noc/noc-dependency-latency.md) | 1 | 7 |
| [boop-docs/microbenching/docs/noc/noc-directional-vc-stress.md](../docs/noc/noc-directional-vc-stress.md) | 5 | 45 |
| [boop-docs/microbenching/docs/noc/noc-dram-endpoint-matrix.md](../docs/noc/noc-dram-endpoint-matrix.md) | 1 | 4 |
| [boop-docs/microbenching/docs/noc/noc-mcast-scheduler-calibration.md](../docs/noc/noc-mcast-scheduler-calibration.md) | 3 | 56 |
| [boop-docs/microbenching/docs/noc/noc-mixed-rw-overlap.md](../docs/noc/noc-mixed-rw-overlap.md) | 2 | 4 |
| [boop-docs/microbenching/docs/noc/noc-overlay-mcast-poc.md](../docs/noc/noc-overlay-mcast-poc.md) | 3 | 3 |
| [boop-docs/microbenching/docs/noc/noc-overlay-multistream-poc.md](../docs/noc/noc-overlay-multistream-poc.md) | 1 | 1 |
| [boop-docs/microbenching/docs/noc/noc-overlay-stream-poc.md](../docs/noc/noc-overlay-stream-poc.md) | 1 | 1 |
| [boop-docs/microbenching/docs/noc/noc-packet-latency-pipelined.md](../docs/noc/noc-packet-latency-pipelined.md) | 4 | 176 |
| [boop-docs/microbenching/docs/noc/noc-packet-latency.md](../docs/noc/noc-packet-latency.md) | 2 | 168 |
| [boop-docs/microbenching/docs/noc/noc-route-tomography.md](../docs/noc/noc-route-tomography.md) | 1 | 2 |
| [boop-docs/microbenching/docs/noc/noc-same-initiator-active.md](../docs/noc/noc-same-initiator-active.md) | 2 | 12 |
| [boop-docs/microbenching/docs/noc/noc-scheduler-model.md](../docs/noc/noc-scheduler-model.md) | 9 | 41 |
| [boop-docs/microbenching/docs/noc/noc-stream-sweep.md](../docs/noc/noc-stream-sweep.md) | 2 | 26 |
| [boop-docs/microbenching/docs/noc/noc-topology.md](../docs/noc/noc-topology.md) | 1 | 8 |
| [boop-docs/microbenching/docs/noc/noc-vc-command-flags.md](../docs/noc/noc-vc-command-flags.md) | 3 | 177 |
| [boop-docs/microbenching/docs/tensix/drisc-gddr-dma-aggregate.md](../docs/tensix/drisc-gddr-dma-aggregate.md) | 1 | 7 |
| [boop-docs/microbenching/docs/tensix/drisc-gddr-dma.md](../docs/tensix/drisc-gddr-dma.md) | 12 | 80 |
| [boop-docs/microbenching/docs/tensix/pack-unpack-units.md](../docs/tensix/pack-unpack-units.md) | 1 | 5 |
| [blackhole-py/tests/operation_pocs/fpu/results.md](../../../blackhole-py/tests/operation_pocs/fpu/results.md) | 1 | 22 |
| [blackhole-py/tests/operation_pocs/runtime/results.md](../../../blackhole-py/tests/operation_pocs/runtime/results.md) | 1 | 68 |
| [blackhole-py/tests/operation_pocs/sfpu_math/results.md](../../../blackhole-py/tests/operation_pocs/sfpu_math/results.md) | 2 | 16 |
| [blackhole-py/tests/operation_pocs/sfpu_movement/results.md](../../../blackhole-py/tests/operation_pocs/sfpu_movement/results.md) | 2 | 20 |

## Structured operation evidence

- [sfpu_math/final-results.json](../../../blackhole-py/tests/operation_pocs/sfpu_math/final-results.json)
- [sfpu_movement/final-results.json](../../../blackhole-py/tests/operation_pocs/sfpu_movement/final-results.json)
- [fpu/measurements.json](../../../blackhole-py/tests/operation_pocs/fpu/measurements.json)
- [transport/final-sweep.json](../../../blackhole-py/tests/operation_pocs/transport/final-sweep.json)
- [transport/final-edges.json](../../../blackhole-py/tests/operation_pocs/transport/final-edges.json)
- [runtime/evidence/measurements.json](../../../blackhole-py/tests/operation_pocs/runtime/evidence/measurements.json)

## LLK performance CSVs

These retain whole-kernel/phase markers and format/fidelity/tile-count context. Architecture/run metadata is not always self-contained. They are indexed separately and are not imported as Blackhole opcode latencies.

- [tt-llk/perf_data/perf_eltwise_binary_fpu/perf_eltwise_binary_fpu.csv](../../../tt-llk/perf_data/perf_eltwise_binary_fpu/perf_eltwise_binary_fpu.csv)
- [tt-llk/perf_data/perf_eltwise_binary_fpu/perf_eltwise_binary_fpu.post.csv](../../../tt-llk/perf_data/perf_eltwise_binary_fpu/perf_eltwise_binary_fpu.post.csv)
- [tt-llk/perf_data/perf_pack_untilize/perf_pack_untilize.csv](../../../tt-llk/perf_data/perf_pack_untilize/perf_pack_untilize.csv)
- [tt-llk/perf_data/perf_pack_untilize/perf_pack_untilize.post.csv](../../../tt-llk/perf_data/perf_pack_untilize/perf_pack_untilize.post.csv)
- [tt-llk/perf_data/perf_unpack_tilize/perf_unpack_tilize.csv](../../../tt-llk/perf_data/perf_unpack_tilize/perf_unpack_tilize.csv)
- [tt-llk/perf_data/perf_unpack_tilize/perf_unpack_tilize.post.csv](../../../tt-llk/perf_data/perf_unpack_tilize/perf_unpack_tilize.post.csv)
