# PCIe Bandwidth Benchmarking

## Overview

This document covers PCIe bandwidth testing for Tenstorrent devices, explaining the architecture, transfer mechanisms, and benchmark results from tt-umd.

## TLB (Translation Lookaside Buffer) Architecture

### What is TLB in this context?

TLB here refers to PCIe BAR (Base Address Register) windows that map device memory into the host's address space. Think of it as a "viewport" through which the host can access device memory.

**Architecture:**
- Device has GBs of DRAM (GDDR6) and small on-chip L1 SRAM in each core
- Host cannot directly address all device memory
- Instead: allocate fixed-size TLB windows and map them to specific device locations

**TLB Window Sizes (architecture-dependent):**
- **Wormhole**: 1MB, 2MB, 16MB
- **Blackhole**: 2MB, 4GB only

### TLB Usage Patterns

**Dynamic TLB:**
```cpp
// Allocate and configure TLB on-demand for each transfer
cluster->write_to_device(data, size, chip, core, address);
// TLB allocated, mapped, used, then freed
```
- Flexible but has allocation overhead
- Good for diverse access patterns
- Slower for small transfers due to setup cost

**Static TLB:**
```cpp
// Pre-allocate and configure once
cluster->configure_tlb(chip, core, 2 * MB, address, tlb_data::Relaxed);
// Reuse for all transfers
cluster->write_to_device(data, size, chip, core, address);
```
- No allocation overhead per transfer
- Much faster for small transfers (2-3x improvement)
- Large transfers see similar performance

## Transfer Mechanisms

### MMIO (Memory-Mapped I/O) via TLB

**How it works:**
```
Host CPU → PCIe Posted Writes → TLB Window → NoC → Device Memory (L1/DRAM)
```

**Characteristics:**
- CPU writes to mapped TLB region
- Write-combining buffers improve write performance
- Reads are synchronous and very slow (~44 MB/s)
- No DMA engine involvement
- Limited by PCIe transaction overhead

**This is what most tt-umd tests actually measure!**

### PCIe DMA (Direct Memory Access)

**How it works:**
```
Host Memory → DMA Engine → PCIe → Device MMIO Region → NoC → Device Memory
```

**Characteristics:**
- Hardware DMA engine copies data
- CPU only initiates transfer, doesn't touch data
- Requires IOMMU for buffer mapping
- Much higher bandwidth potential (30-50 GB/s on Gen5 x16)
- Works for both L1 and DRAM destinations

**Requires explicit setup:**
```cpp
Cluster cluster(ClusterOptions{.num_host_mem_ch_per_mmio_device = 1});
SysmemManager* sysmem = cluster->get_chip(0)->get_sysmem_manager();
auto buffer = sysmem->allocate_sysmem_buffer(size);
buffer->dma_write_to_device(offset, size, core, address);
```

## Can DMA Write Directly to L1?

**Yes, but with caveats:**

DMA can write to L1 SRAM, but it follows the same path as MMIO:
```
PCIe → Device Entry Point → NoC (Network-on-Chip) → Target Core L1
```

**Performance implications:**
- L1 is on-chip SRAM inside compute cores
- All PCIe traffic (MMIO or DMA) must traverse the NoC to reach L1
- NoC bandwidth limits L1 writes (~5-6 GB/s observed)
- DRAM writes are faster (~7-8 GB/s) as GDDR6 controllers have better NoC connectivity

**Bottom line:** DMA can target L1, but you're still limited by on-chip interconnect bandwidth, not PCIe speed.

## Benchmark Results (Blackhole, PCIe Gen5 x16)

### Test Configuration
- **Device:** Tenstorrent Blackhole (Harvesting: tensix=0x1020, dram=0x8, eth=0x3fff)
- **Host:** PCIe Gen5 x16 link
- **IOMMU:** Enabled
- **Hugepages:** Not configured (warning in logs)
- **Transfer Method:** MMIO via TLB (DMA buffers not allocated)

### Dynamic TLB Performance

**Host → Device DRAM:**
| Size | Write (MB/s) | Read (MB/s) |
|------|--------------|-------------|
| 1 KB | 965 | 47 |
| 2 KB | 1,894 | 83 |
| 4 KB | 3,613 | 45 |
| 8 KB | 6,478 | 86 |
| 1 MB | 7,633 | 44 |
| 8 MB | 7,609 | 44 |

**Host → Device Tensix L1:**
| Size | Write (MB/s) | Read (MB/s) |
|------|--------------|-------------|
| 1 KB | 1,002 | 42 |
| 2 KB | 1,962 | 79 |
| 4 KB | 3,738 | 43 |
| 8 KB | 6,660 | 43 |
| 1 MB | 5,247 | 85 |

### Static TLB Performance

**Host → Device DRAM (2MB TLB):**
| Size | Write (MB/s) | Read (MB/s) |
|------|--------------|-------------|
| 2 KB | 8,918 | 46 |
| 4 KB | 17,361 | 46 |
| 8 KB | 11,712 | 45 |
| 1 MB | 7,653 | 44 |
| 8 MB | 7,613 | 45 |

**Host → Device Tensix L1 (2MB TLB):**
| Size | Write (MB/s) | Read (MB/s) |
|------|--------------|-------------|
| 2 KB | 12,440 | 44 |
| 4 KB | 13,286 | 43 |
| 8 KB | 13,778 | 83 |
| 1 MB | 5,261 | 42 |

### Key Observations

1. **Static TLB dramatically improves small transfers:**
   - 4KB write: 17.3 GB/s (static) vs 3.6 GB/s (dynamic)
   - Saves TLB allocation overhead

2. **Large transfers plateau:**
   - DRAM: ~7.6 GB/s
   - L1: ~5.2 GB/s
   - Limited by NoC bandwidth, not PCIe

3. **Reads are extremely slow:**
   - ~44 MB/s regardless of size or destination
   - Synchronous MMIO reads from CPU
   - PCIe read latency dominates

4. **DRAM faster than L1 for large transfers:**
   - DRAM has better NoC connectivity
   - L1 limited by core-level interconnect

5. **These are NOT real DMA speeds:**
   - Tests use MMIO, not hardware DMA
   - Real PCIe Gen5 x16 DMA should hit 30-50 GB/s
   - See warnings: "DMA buffer was not allocated"

## Bugs Fixed and Issues Found

### Bug #1: 16MB TLB on Blackhole (FIXED)

**Issue:** Test tried to allocate 16MB TLB on Blackhole architecture.

**Error:**
```
TT_THROW: tt_tlb_alloc failed with error code -22 for TLB size 16777216
```

**Root cause:**
- Blackhole only supports 2MB and 4GB TLB windows
- 16MB is Wormhole-only
- Kernel driver correctly rejected with EINVAL (-22)

**Fix:**
```cpp
// tests/microbenchmark/benchmarks/tlb/test_tlb.cpp:168
// OLD: cluster->configure_tlb(0, dram_core, 16 * (1 << 20), 0, tlb_data::Relaxed);
// NEW: cluster->configure_tlb(0, dram_core, 1 << 21, 0, tlb_data::Relaxed);  // 2MB
```

**Proper fix would be:** Detect architecture and use appropriate TLB sizes.

### Bug #2: Ethernet Core Access (UNFIXED)

**Issue:** Test tries to access Ethernet cores when all are harvested.

**Error:**
```
Segmentation fault at MicrobenchmarkTLB.TLBDynamicEth
```

**Root cause:**
```cpp
// Harvesting mask: eth: 0x3fff (all 14 Ethernet cores disabled)
const CoreCoord eth_core = cluster->get_cores(CoreType::ETH)[0];  // Empty vector!
```

**Fix needed:** Check if Ethernet cores exist before testing:
```cpp
auto eth_cores = cluster->get_cores(CoreType::ETH);
if (eth_cores.empty()) {
    GTEST_SKIP() << "No Ethernet cores available";
}
```

### Issue #3: Misleading Test Names

**Problem:** Tests named "MicrobenchmarkPCIeDMA.*" don't actually use PCIe DMA.

**Reality:**
```cpp
std::unique_ptr<Cluster> cluster = std::make_unique<Cluster>();
// This creates cluster with num_host_mem_ch_per_mmio_device = 0
// No DMA buffers allocated → falls back to MMIO
```

**Warning in logs:**
```
DMA buffer was not allocated for PCI device 0, falling back to non-DMA (regular MMIO TLB)
```

**Tests that SHOULD use real DMA:**
- `MicrobenchmarkPCIeDMA.TensixZeroCopy`
- `MicrobenchmarkPCIeDMA.TensixMapBufferZeroCopy`
- `MicrobenchmarkPCIeDMA.DRAMZeroCopy`

These use `SysmemManager` and should measure actual DMA performance, but require proper setup.

## Why Aren't We Seeing PCIe Gen5 Speeds?

**Theoretical:** PCIe Gen5 x16 = ~64 GB/s

**Observed:** ~7.6 GB/s write, ~44 MB/s read

**Reasons:**

1. **Not using DMA engine** (main issue)
   - Tests use MMIO through TLB windows
   - CPU-initiated PCIe writes, not hardware DMA
   - See "DMA buffer was not allocated" warnings

2. **NoC bottleneck for L1**
   - Even with DMA, L1 writes limited to ~5-6 GB/s
   - On-chip interconnect bandwidth constraint

3. **Small TLB windows**
   - 2MB TLB size causes chunking overhead for large transfers
   - Could use 4GB TLB on Blackhole (untested)

4. **Missing optimizations**
   - No hugepage mapping configured
   - IOMMU translation overhead
   - Non-optimal DMA channel configuration

## Why Are Reads So Slow? (~44 MB/s vs ~7.6 GB/s Writes)

The massive read/write asymmetry is fundamental to how PCIe works at the protocol level.

### PCIe Writes are "Posted" (Fast)

**Posted writes = fire and forget:**

```
CPU: "Write this data to address X"
     [sends packet, doesn't wait for response]
     [continues immediately]
     [write-combining buffers batch multiple writes]
```

**Characteristics:**
- CPU doesn't wait for confirmation
- Multiple writes pipeline together
- Write-combining buffers coalesce small writes into larger PCIe transactions
- Achieves high throughput through parallelism

### PCIe Reads are Synchronous (Slow)

**Non-posted reads = request/response:**

```
CPU: "Read from address X"
     [sends read request]
     [WAITS for response]
     PCIe travels to device (~500-1000ns)...
     Device fetches data...
     Response travels back...
     [CPU finally gets data]
     CPU: "Read from address X+4"
     [whole cycle repeats]
```

**Each read incurs full round-trip latency:**
- PCIe latency: ~500-1000ns per transaction
- Sequential reads cannot pipeline effectively
- Even with prefetching, fundamentally limited by latency

### The Math

**Example: Reading 1MB in 4-byte chunks via MMIO**

```
Reads needed: 1MB / 4B = 262,144 reads
Round-trip time: ~1000ns each
Total time: 262ms
Bandwidth: 1MB / 262ms = 3.8 MB/s
```

Even with larger read transactions and some pipelining, MMIO reads are stuck around 40-80 MB/s.

### Why This Happens

1. **Writes don't wait** - Posted transactions, batched, pipelined
2. **Reads must wait** - Every read stalls for round-trip
3. **Write-combining helps writes** - No equivalent optimization for reads
4. **PCIe protocol favors writes** - Designed this way intentionally

### Universal PCIe Behavior

This asymmetry is **not specific to Tenstorrent** - it's fundamental to PCIe:

- GPUs have the same asymmetry (GPU→Host slow, Host→GPU fast)
- Network cards, storage controllers, all PCIe devices
- Why DMA helps: hardware can issue reads without CPU stalling
- Even with DMA reads: 200-500 MB/s typical (still way slower than writes)

### Best Practices

1. **Minimize reads from device** - Every read is expensive
2. **Batch data on device** - Process/accumulate results on-chip
3. **Bulk transfer when done** - One large DMA read > many small reads
4. **Use writes for control** - Write commands to device, not read status
5. **Device-initiated transfers** - Let device DMA results to host memory

## Recommendations for Real DMA Testing

### Use tt-metal benchmarks instead

The tt-metal framework likely:
- Properly initializes DMA engines
- Allocates DMA-capable host buffers
- Configures hardware correctly
- Should show real PCIe Gen5 bandwidth

### Or fix tt-umd tests

```cpp
// Allocate DMA buffers
Cluster cluster(ClusterOptions{.num_host_mem_ch_per_mmio_device = 4});

// Get sysmem manager
SysmemManager* sysmem = cluster.get_chip(0)->get_sysmem_manager();

// Allocate DMA-capable buffer
auto buffer = sysmem->allocate_sysmem_buffer(size);

// Use real DMA
buffer->dma_write_to_device(0, size, core, address);
```

### Enable hugepages

```bash
# Reduce TLB misses and IOMMU overhead
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
```

### Use 4GB TLB windows on Blackhole

Should eliminate chunking overhead for large transfers.

## Conclusion

Current tt-umd benchmarks primarily measure **MMIO bandwidth through TLB windows**, not true PCIe DMA performance. Results show:

- **Static TLB:** Best for small transfers (up to 17 GB/s for 4KB)
- **Large DRAM writes:** ~7.6 GB/s via MMIO
- **Large L1 writes:** ~5.2 GB/s (NoC limited)
- **Reads:** ~44 MB/s (very slow)

Real PCIe DMA testing requires proper setup with `SysmemManager` and DMA buffer allocation. For production bandwidth testing, use tt-metal benchmarks which likely implement the full DMA path correctly.
