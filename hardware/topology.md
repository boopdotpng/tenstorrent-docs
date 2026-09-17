# Coordinates and worker placement

Scope: Blackhole hardware coordinate concepts and the September 17 local
blackhole-py topology. Use [pcie.py](../../blackhole-py/pcie.py) `board_config`
and the resulting `Device.cores` as the source of launchable workers.

## Three coordinate meanings

| Kind | Meaning |
|---|---|
| Physical NoC | Position in the selected NoC's hardware grid |
| Translated / virtual | Endpoint address interpreted through hardware translation |
| Logical worker index | Software's index into its selected worker set |

The physical NoC0 grid is 17 by 12. A translated endpoint can have coordinates
outside that range: blackhole-py's DRAM tables use virtual coordinates such as
`(18,14)`. Neither an out-of-range physical-grid check nor swapping axes converts
between these spaces. NoC1 also has its own endpoint mapping.

`ConfigureTlb` passes the coordinates supplied by the caller; it does not derive
a worker placement or apply an application harvesting map. Match the coordinates
to the active hardware translation state and the runtime's endpoint tables.
The old instruction to always substitute physical coordinates was too broad.

## Current supported layout

The inspected runtime requires 120 firmware-enabled Tensix tiles on P100A and
supported P150A/B/C cards. It checks the ARC-enabled masks; this is an
implementation restriction, not a claim that every Blackhole board has that
usable layout.

| Item | Current runtime selection |
|---|---|
| Worker-capable columns | 1–7 and 10–14 |
| Worker-capable rows | 2–11 |
| Prefetch service | `(14,2)` |
| Dispatch service | `(14,3)` |
| DRAM transfer service | `(14,4)` |
| Compute workers after reservations | 117 |
| DRAM banks | P100A: 7; supported P150: 8 |

The three services belong to the software runtime. Their placement is not a
hardware reservation. Use the board-specific pairs of NoC0/NoC1 DRAM endpoints
from `pcie.py`, rather than deriving DRAM coordinates from worker coordinates.

## Planning a grid

A regular 10-row by 11-column plan can exclude column 14 and use 110 workers.
A 7-row by 12-column plan on rows 5–11 uses 84. These are logical rectangles;
physical multicast may require multiple rectangles around the column gap.
The remaining workers are available to other valid schedules.

For a proposed placement:

1. Check every coordinate against `Device.cores`.
2. Assign each output block exactly once, including tails.
3. Keep multicast destinations out of service tiles and invalid endpoints.
4. Match sender expectations to actual receiver counts.
5. Check L1 storage, Dst capacity, and buffering before optimizing occupancy.

For an equal-block mapping of `Mt × Nt` output tiles onto `R × C` workers, the
simple utilization estimate is
`Mt*Nt / (R*C*ceil(Mt/R)*ceil(Nt/C))`. This ignores K blocking, communication,
padding, and nonuniform work; it is not a throughput prediction.

## Diagnosing address failures

Distinguish a bad address-space assumption from an uninitialized endpoint.
Check the selected NoC, translation state, endpoint table, and service/worker
reservation before interpreting a timeout as absent hardware. Test a single
known word and read it back before testing multicast or a complete program.

TT-Metal's `InterleavedAddrGenFast` reads firmware-populated bank tables. Those
tables and their LDM/scratch placement are TT-Metal ABI details, not a universal
Blackhole DRAM layout. The [emulator topology model](blackhole-emulator-specs/topology.md)
retains the detailed translation study under that scope.
