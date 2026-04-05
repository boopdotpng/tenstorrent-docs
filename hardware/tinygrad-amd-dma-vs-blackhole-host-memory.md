# tinygrad AMD DMA vs Blackhole host memory

## Summary

`tinygrad`'s macOS eGPU path for AMD works because the runtime only needs a **generic PCI DMA substrate**:

| Runtime | What userspace asks the platform for | What the runtime does itself | Consequence |
|---|---|---|---|
| tinygrad AMD | BAR mapping, config space access, reset, DMA-prepared host pages | Programs GPU page tables, queue rings, doorbells, SDMA, kernargs | A generic `DriverKit` + userspace bridge is enough |
| `blackhole-py` | Tenstorrent TLB windows, page pinning, power ioctls, TT-visible host `noc_address` | Builds firmware/dispatch on top of that TT-specific substrate | A generic BAR/DMA bridge is not enough |

The key difference is that AMD consumes **generic DMA physical segments**, while `blackhole-py` consumes a **Tenstorrent-specific host-memory mapping** returned by `tt-kmd`.

## tinygrad AMD DMA model

### Platform contract

The platform layer exposes a PCI device with these primitives:

| Primitive | tinygrad source | Purpose |
|---|---|---|
| `map_bar` | `tinygrad/runtime/support/system.py` | MMIO access to GPU registers / apertures |
| `read_config` / `write_config` | `tinygrad/runtime/support/system.py` | PCI config space setup |
| `reset` | `tinygrad/runtime/support/system.py` | Function reset |
| `alloc_sysmem` | `tinygrad/runtime/support/system.py:186-191, 415-420` | Return host-visible memory plus DMA-visible physical pages |

On macOS, `APLRemotePCIDevice.alloc_sysmem` gets a shared-memory FD from `TinyGPU.app`, then reads DMA segments that the `DriverKit` extension wrote into the mapping.

### DriverKit side

`TinyGPUDriver` and `TinyGPUDriverUserClient` do two DMA-relevant things:

| File | Function | Role |
|---|---|---|
| `TinyGPUDriver.cpp` | `CreateDMA`, `SetupDMA` | Allocate shared buffer and call `PrepareForDMA` |
| `TinyGPUDriverUserClient.cpp` | `PrepareDMA`, `CopyClientMemoryForType` | Return DMA segments or a shared memory object to userspace |
| `Shared/server.c` | `CMD_MAP_SYSMEM_FD` | Send the shared-memory FD to tinygrad over the Unix socket |

The output is a list of `(physical_address, length)` pairs. That is enough for AMD.

### How tinygrad uses those DMA pages

tinygrad maps those pages into the GPU's own address space:

| Step | tinygrad source | Effect |
|---|---|---|
| Host pages allocated | `system.py:186-191 / 415-420` | Userspace gets a CPU mapping and physical page list |
| GPU mapping created | `system.py:247-253` | `dev_impl.mm.map_range(..., aspace=AddrSpace.SYS, snooped=True, uncached=True)` |
| Page tables programmed | `support/memory.py:199-216` | GPU can access that system memory via GPU virtual addresses |

After that, the rest of the AMD runtime just uses normal GPU-visible addresses for:

| Use | Source |
|---|---|
| Compute ring / AQL ring | `ops_amd.py:1012-1029` |
| SDMA ring | `ops_amd.py:1031-1036, 461-552` |
| Doorbells | `ops_amd.py:647-665` |
| Kernargs / dispatch packets | `ops_amd.py:331-340, 418-459` |

The important point: tinygrad does **not** need the OS to give it an AMD-specific "GPU host aperture address". It only needs DMA-visible physical pages. tinygrad's AMD runtime owns the GPU-side mapping logic.

## `blackhole-py` host-memory model

### `tt-kmd` contract

`blackhole-py` does not use a generic PCI abstraction. It directly uses Tenstorrent ioctls:

| Primitive | `blackhole-py` source | Role |
|---|---|---|
| `_ioctl_alloc_tlb` / `_ioctl_config_tlb` / `_ioctl_free_tlb` | `blackhole-py/hw.py:135-137` | Allocate and retarget TT NoC TLB windows |
| `_ioctl_pin_pages` / `_ioctl_unpin_pages` | `blackhole-py/hw.py:138-139` | Pin host memory for TT access |
| `_ioctl_set_power_state` | `blackhole-py/hw.py:140` | TT-specific power management |

Those ioctls back the two critical abstractions:

| Abstraction | `blackhole-py` source | What it expects |
|---|---|---|
| `TLBWindow` | `blackhole-py/hw.py:148-187` | Kernel allocates a TT TLB slot and exposes UC/WC mmap offsets |
| `Sysmem` | `blackhole-py/hw.py:189-204` | Kernel pins host memory and returns a TT-visible `noc_address` |

### Why `noc_address` matters

The pinned-memory path is not just generic DMA prep. `Sysmem` expects:

```python
out = _ioctl_pin_pages(self.fd, flags=_PIN_NOC_DMA, virtual_address=self._va, size=self.size)
self.noc_addr = out.noc_address
```

That `noc_addr` is then consumed directly by runtime code and device kernels:

| Consumer | Source | Use |
|---|---|---|
| Fast dispatch sysmem | `blackhole-py/cq.py:234-245` | Command queue sysmem is pinned and addressed through TT-visible NOC state |
| DRAM fill/drain kernels | `blackhole-py/dram.py:118-143` | Forms `pcie_base` from `sysmem_noc_addr` |
| Device DRAM transfers | `blackhole-py/device.py:354-381` | Uses `_dram_sysmem.noc_addr` for host/device staging |

The crucial expression is in `blackhole-py/dram.py`:

```python
pcie_base = (Sysmem.PCIE_NOC_XY << 36) | (1 << 60) | (sysmem_noc_addr & ((1 << 36) - 1))
```

The firmware/dataflow side is expecting a **TT-specific NOC-routed host address**, not a list of physical pages and not a GPU virtual address.

## Core difference

### AMD

AMD's contract is:

1. give me host pages that are DMA-visible
2. I will map them into GPU VM
3. the GPU will access them through its own MMU

The platform only has to expose **generic PCI DMA memory**.

### Blackhole

`blackhole-py`'s contract is:

1. give me TT TLB windows for NoC/MMIO access
2. give me pinned host memory expressed as a TT-visible `noc_address`
3. I will hand that NOC address to dispatch code / firmware / kernels

The platform has to expose **Tenstorrent-specific access semantics**.

## Why TinyGPU-style BAR plus DMA is not enough for Blackhole

If a macOS bridge only provides:

- BAR mapping
- config read/write
- reset
- DMA segments from `PrepareForDMA`

then that matches tinygrad AMD, but it does **not** match `blackhole-py`'s current assumptions.

Missing pieces for `blackhole-py` are:

| Missing primitive | Why it matters |
|---|---|
| TT TLB window allocation / retargeting | `TLBWindow` is used everywhere for firmware upload, slow dispatch, DRAM access, debug reads |
| TT-visible host `noc_address` | Fast dispatch and DRAM transfer kernels consume it directly |
| Optional TT power-state control | `Device.run()` toggles it around dispatch |

The largest gap is the host-memory mapping path. Generic DMA segments are probably insufficient unless some lower layer can turn them into the exact `noc_address` semantics that `tt-kmd` currently provides.

## Porting implications for `blackhole-py`

### What can likely be reused

| Layer | Status |
|---|---|
| Compiler / firmware image construction | Reusable |
| IR / dispatch building | Reusable |
| Program model | Reusable |
| Most DRAM/dataflow logic above `TLBWindow` / `Sysmem` | Reusable if the low-level API is preserved |

### What has to change

| File | Required change |
|---|---|
| `blackhole-py/hw.py` | Split Linux `tt-kmd` code behind a backend/transport interface |
| `blackhole-py/device.py` | Stop assuming `/dev/tenstorrent/*` and `/sys/class/tenstorrent/*` |
| `blackhole-py/cq.py` | Make pinned host sysmem come from a backend, not `_ioctl_pin_pages` |

### Recommended bring-up order

| Phase | Goal | Why first |
|---|---|---|
| 1 | Slow dispatch over remote TLB/MMIO | Avoids the harder host-sysmem problem |
| 2 | Firmware upload / kernel launch | Same reason |
| 3 | DRAM read/write helpers | Requires host-memory story, but simpler than fast CQ |
| 4 | Fast dispatch | Depends on TT-visible pinned sysmem and CQ plumbing |

## Bottom line

`tinygrad` on macOS AMD succeeds because the runtime is built on top of **generic PCI DMA pages** and owns the GPU-side VM mapping logic.

`blackhole-py` is built on top of **`tt-kmd`-provided Tenstorrent primitives**, especially:

- TT TLB windows
- TT-visible pinned host `noc_address`

That is why a TinyGPU-style macOS bridge is a good model for structure, but not a drop-in solution for Blackhole. For Tenstorrent, the macOS bridge needs to look more like a **remote `tt-kmd`** than a generic remote PCI helper.
