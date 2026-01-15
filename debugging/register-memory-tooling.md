# Register and memory tooling for pure-py

## Most relevant: tt-exalens
- Low-level hardware debugger with CLI and Python library for register and memory access.
- CLI highlights: `brxy` (read L1 or DRAM), `wxy` (write L1/DRAM), `riscv rd/wr/rreg/wreg` (RISC-V memory and register access), `tensix-reg`, `noc register`, and GDB server support.
- Python lib highlights: `read_word_from_device`, `read_words_from_device`, `read_from_device`, `write_words_to_device`, `write_to_device`, `read_register`, `write_register`, `read_riscv_memory`, `write_riscv_memory`.
- Notes: Some address ranges are only accessible via the debug interface (example noted in the library tutorial). Coordinates can be provided as NOC or logical locations.

Refs:
- `tt-exalens/README.md`
- `tt-exalens/docs/ttexalens-app-tutorial.md`
- `tt-exalens/docs/ttexalens-app-docs.md`
- `tt-exalens/docs/ttexalens-lib-docs.md`
- `tt-exalens/docs/ttexalens-lib-tutorial.md`
- `tt-exalens/docs/gdb.md`

## Also relevant: luwen (pyluwen, Blackhole)
- Host-side abstraction layer; `pyluwen` exposes low-level access for debug tooling.
- L1 access is possible via `noc_read`/`noc_write` (you need core coords and a NOC-visible address). There is no L1 helper; you must know the address map.
- Other BH capabilities in `pyluwen`: `axi_translate` + `axi_read/axi_write` for ARC/AXI registers, `arc_msg`/`arc_msg_buf`, telemetry, TLB setup, DMA buffer allocation/transfer, SPI/bootfs tables, and power control.
- BAR/AXI (MMIO) access is only available on local mmio-capable PCIe devices. For per-core L1/DRAM and dispatch mailboxes you still need NOC reads/writes, even if you configure TLB windows.

Refs:
- `luwen/README.md`
- `luwen/bind/libluwen/README.md`
- `luwen/bind/pyluwen/src/lib.rs`
- `luwen/crates/luwen-kmd/src/tlb/blackhole.rs`

## Seeing where buffers land (addresses, L1/DRAM)
- `tt-mlir` `ttrt run --memory --save-artifacts` writes a memory report with per-op buffer placement and addresses for DRAM/L1. This is the closest tool in these repos for tracking where allocations end up at runtime.
- `ttnn-visualizer` consumes memory and performance reports, showing per-core allocations, buffer lifetimes, and layout detail in a UI.

Refs:
- `tt-mlir/docs/src/ttrt.md`
- `ttnn-visualizer/README.md`

## Less directly useful for register-level debugging
- `tt-perf-report` focuses on performance traces and does not expose register or memory read/write tooling.
- `tt-lang` is a DSL/compiler project; it discusses memory and DST registers in docs but does not provide live register or memory inspection tools.
