# Measurements

Dated hardware results from blackhole-py's direct kernels. Each page records the
card, configuration and timing boundary, and its numbers hold only under that
scope. Matmul results are in [matmul/results](../matmul/README.md#measured-results).
Per-instruction cycle costs are in [timing](../timing/README.md).

| Page | Summary |
|---|---|
| [DRAM traffic patterns](dram-traffic-patterns.md) | Reaching ~512 GB/s read+write on p150a: port rotation, NoC direction, per-RISC command buffers (2026-11) |
| [DRAM bandwidth](dram-bandwidth.md) | Compute-free reader/writer bandwidth; writes plateaued at ~330–345 GB/s before the traffic-pattern work (2026-09) |
| [NoC output and DRISC DMA](noc-output-and-drisc-dma.md) | Output write paths and DRISC GDDR DMA |
| [SFPU argmax, packer L1 accumulation, load macros](sfpu-argmax-l1acc-loadmacro.md) | 10× SFPU argmax over 250k values; L1-acc pack cost; macro pipelines |
| RMSNorm: [article comparison](rmsnorm/article-comparison.md), [HiFi3 and alignment](rmsnorm/hifi3-and-alignment.md), [ELWMUL vs MOP](rmsnorm/elwmul-vs-mop.md), [Dst-half pipeline](rmsnorm/dst-half-pipeline.md) | Hybrid FPU/SFPU RMSNorm variants |
| Llama 3: [FP8 decode](llama/fp8-decode.md), [SFPU argmax](llama/argmax.md), [weight upload](llama/weight-upload.md) | End-to-end model results |

Scripts and raw JSON stay in blackhole-py beside the tests that produced them.
