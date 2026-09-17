# Tenstorrent Blackhole documentation

Unofficial notes on Blackhole hardware, kernel programming, runtime design,
and compiler lowering. The goal is to make a direct compiler backend possible
by explaining the hardware and the software contracts separately. Most prose
was written with coding assistants; `human/` is human-authored and read-only.

## Open the reference

```sh
./serve.sh
```

Listens on **0.0.0.0:8000**. Open **http://127.0.0.1:8000** in your browser.
Other machines can use `http://<this-machine-ip>:8000`. Python 3
is the only runtime dependency. The site works offline, with categorized
Markdown documents, full-text search, and a dedicated **[Tensix ISA page](http://127.0.0.1:8000/isa)** for all 137 encoders: behavior, cycle counts, caveats, and test scope.
It never opens a browser. Use `./serve.sh --port 8001` to change ports.
See [viewer maintenance](viewer/README.md) to refresh the ISA snapshot.

Start with [the introduction](intro.md), then
[behavior demonstrated by blackhole-py tests](hardware/behavior-from-tests.md).
The latter identifies the September 17 local source snapshot and distinguishes
test assertions, recorded measurements, and remaining coverage gaps.

Documentation opens at `/`; `/isa` has its own instruction navigation;
`/archives` contains historical studies and measurement reports. Global search
covers all three, with historical results labeled.

## Choose a path

| Task | Start here |
|---|---|
| Understand the chip | [Hardware](hardware/README.md) → [architecture](hardware/architecture.md) |
| Write or fuse a kernel | [Kernel development](kernel-dev/README.md) |
| Understand current blackhole-py | [Runtime map](build-and-dispatch/blackhole-py-runtime.md) |
| Study TT-Metal build/dispatch | [Build and dispatch](build-and-dispatch/README.md) |
| Distinguish board firmware from worker firmware | [Firmware](firmware/README.md) |
| Optimize matrix multiplication | [Matmul](matmul/README.md) |
| Find measurements and timing limits | [Microbenchmarks](microbenching/README.md) |
| Learn compilers or plan a backend | [Compiler maps](compiler-maps/README.md) |
| Study TT-Fabric and multi-host execution | [Multi-chip](multi-chip/README.md) |
| Inspect old instruction usage or assembly | [ISA workload samples](llk-sfpi/README.md), [disassemblies](disasms/README.md) |
| Find a retired document or historical result | [Archive](archive/README.md) |

## How to read the evidence

- **Hardware behavior:** a manual description or an explicitly scoped hardware
  assertion. A passing encoder test only checks instruction bits.
- **Runtime convention:** CB IDs, reserved tiles, L1 partitions, launch records,
  and controller assignments chosen by software. These vary by implementation.
- **Source snapshot:** compiler, TT-Metal, LLK, and firmware maps describe the
  recorded checkout. They are not promises about future upstream versions.
- **Measurement:** keep the shape, format, fidelity, placement, and timing
  boundary with the result. Old reports remain useful under their original scope.

The current blackhole-py path uses tt-kmd, Python instruction emitters, and C
worker/service firmware. Older SFPI/LLK-based blackhole-py APIs live in the
archive. TT-Metal and SFPI remain useful separate programming interfaces.

## Cycle timing reference

[Blackhole cycle cheat sheet and five-stream predictor reference](microbenching/timing-reference/README.md): RISC-V, SFPU result availability, FPU, unpack/pack, synchronization, complete opcode coverage, and source-indexed hardware measurements.

## Sources and maintenance

Source links beginning with `../blackhole-py`, `../tinygrad`, or other sibling
repository names require those checkouts beside this one. Source fingerprints
and uncommitted-file status for the hardware review are in
[the evidence manifest](maintenance/blackhole-py-sources.json).

Primary upstream projects: [Blackhole ISA manual](https://github.com/tenstorrent/tt-isa-documentation/tree/main/BlackholeA0),
[blackhole-py](https://github.com/boopdotpng/blackhole-py),
[TT-Metal](https://github.com/tenstorrent/tt-metal),
[TT-LLK](https://github.com/tenstorrent/tt-llk),
[SFPI](https://github.com/tenstorrent/sfpi), and
[tt-kmd](https://github.com/tenstorrent/tt-kmd).

The [maintenance record](maintenance/README.md) explains what was rewritten,
relocated, removed, and checked. It also records what has not been revalidated.
