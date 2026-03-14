# How Tenstorrent's Fast Matmul Works (ELI5)

## GPU vs Tenstorrent: Fundamentally Different

On a **GPU**, you write one kernel that runs on thousands of tiny cores simultaneously. The hardware handles scheduling, and you think in terms of threads/warps/blocks sharing memory.

On **Tenstorrent**, each Tensix core is a complete mini-computer with its own:
- 5 RISC-V processors (2 for data movement, 3 for compute)
- 1.5MB of local SRAM (L1)
- A dedicated matrix engine
- Network-on-chip (NoC) connections to other cores and DRAM

You write **3 separate programs** that run simultaneously and communicate through circular buffers.

## The Three Musketeers: Reader, Compute, Writer

Think of it like a factory assembly line:

```
DRAM --> [Reader] --> CB --> [Compute] --> CB --> [Writer] --> DRAM
              ^                                        |
              |_______ circular buffers (L1) __________|
```

### Reader Kernel (runs on BRISC)
- Fetches tiles from DRAM into circular buffers
- Uses NoC (network-on-chip) for async DMA transfers
- Signals "data ready" by pushing to circular buffer

### Compute Kernel (runs on TRISC0/1/2)
- Waits for data in circular buffers
- Feeds tiles to the matrix engine
- Accumulates results in DST registers
- Packs results to output circular buffer

### Writer Kernel (runs on NCRISC)
- Waits for compute results
- Writes tiles back to DRAM via NoC

## The Matrix Engine: Where the Magic Happens

The matrix engine does an **8x16 @ 16x16 = 8x16** multiply in ONE cycle.

```
    A tile         B tile        Output
   (8 x 16)   @   (16 x 16)  =  (8 x 16)
   
   = 2 * 8 * 16 * 16 = 4096 multiply-adds per cycle!
```

At 1.35 GHz (Blackhole), that's **5.4 TFLOPS per core** at LoFi precision.
With 130 cores, theoretical peak is **~700 TFLOPS**.

## Why Blocking and Double Buffering Matter

### The Problem with Naive Matmul

```
for each output tile:
    for k in K_dimension:
        read A tile     <- wait for DRAM (~100 cycles)
        read B tile     <- wait for DRAM (~100 cycles)
        compute         <- matrix engine idle while waiting!
```

The matrix engine sits idle while waiting for DRAM. Bad!

### The Solution: Block and Pipeline

```
Reader:                      Compute:
  read block of 8 tiles        (waiting)
  barrier                      
  push to CB                   
                               wait for block
  read next block              process 8 tiles (overlapped!)
  barrier                      
  push to CB                   
                               wait for block
  ...                          ...
```

By reading multiple tiles before waiting, and using circular buffers with multiple slots, the reader can stay ahead of compute.

## The Fast Path: Multicast Magic

The *really* fast matmul uses **multicast** - one core reads a tile and broadcasts it to many cores simultaneously:

```
         Core (0,0) reads A row
              |
    +---------+---------+
    v         v         v
 (0,0)     (0,1)     (0,2)    <- all get same A tiles
    |         |         |
    v         v         v
 (1,0)     (1,1)     (1,2)    <- different B columns each
    
```

### 2D Decomposition
- **Row of cores** share the same A tiles (multicast horizontally)
- **Column of cores** share the same B tiles (multicast vertically)
- Each core computes a unique output block

This reduces DRAM bandwidth by `sqrt(num_cores)`.

## Key Optimizations in tt-metal's Fast Matmul

1. **Subblock Tiling**: Instead of 1 output tile, compute 4x2=8 tiles that fit in DST registers
2. **Double Buffering**: 2x CB depth so reader can work while compute processes
3. **L1 Accumulation (packer_l1_acc)**: Keep partial sums in L1 instead of spilling to DRAM
4. **Multicast**: Share input tiles across cores via NoC broadcast
5. **Fused Operations**: Bias add and activation merged into compute kernel

## Circular Buffers: The Glue

Circular buffers are the communication mechanism:

```cpp
// Reader side
cb_reserve_back(cb_a, num_tiles);  // Wait for space
noc_async_read_tile(...);          // DMA read
noc_async_read_barrier();          // Wait for DMA
cb_push_back(cb_a, num_tiles);     // Signal "data ready"

// Compute side  
cb_wait_front(cb_a, num_tiles);    // Wait for data
matmul_tiles(...);                 // Process
cb_pop_front(cb_a, num_tiles);     // Signal "done with data"
```

The CB handles synchronization - no explicit locks needed!

## Performance Numbers

From tt-metal benchmarks on Blackhole (P150):

| Data Type | Math Fidelity | Peak TFLOPS |
|-----------|---------------|-------------|
| BFLOAT8_B | HiFi2         | ~580        |
| BFLOAT16  | HiFi4         | ~250        |
| BFLOAT4_B | LoFi          | ~700+       |

## TL;DR

1. **3 kernels** (reader/compute/writer) run in parallel, not 1 kernel on many threads
2. **Circular buffers** connect them, handling synchronization
3. **Matrix engine** does 4096 ops/cycle - keep it fed!
4. **Block your reads** to overlap memory access with compute
5. **Multicast** shares data across cores for massive bandwidth savings
6. Think **dataflow**, not **thread parallelism**
