# GDDR6 on the p150a: part, configuration and timing table

What the memory on our two p150a cards is, how it is configured, and the exact
timing parameters the memory controller runs. Established 2026-11-03 from the
MRISC (memory-controller) firmware and from the cards themselves; rechecked
2026-11-05 against the firmware actually installed. Bandwidth consequences are
in [DRAM traffic patterns](../measurements/dram-traffic-patterns.md).

## Summary

* **Part:** Samsung GDDR6 C-die, 16 Gb per device, running at **16 Gbps**.
* **Configuration:** clamshell. Each of the 8 controllers drives two devices at
  x8, which together form two x16 channels. 8 controllers × 2 devices × 2 GB =
  32 GB.
* **Clock:** command clock **2.01 GHz** (tCK ≈ 0.4975 ns), not 2.0. Pin rate is
  64.3 GB/s per controller, **514.6 GB/s per chip**.
* **Key timings at 16 Gbps:** CL 33, WL 8, tRCD 36 (read) / 20 (write), tRFCab
  245, tRFCpb 125, tREFI 3700, all in tCK. Full table below.
* **Health at the time of reading:** training passed, zero corrected or
  uncorrected EDC errors, DRAM 44–48 °C.

## Where the information came from

Every number on this page comes from one of these sources. **None comes from a
datasheet or web search.** Samsung's 16 Gb GDDR6 datasheet isn't public, and
no P150 teardown showing the package marking was found.

| Source | What it gave |
|---|---|
| MRISC firmware **2.16**, `tt-system-firmware/zephyr/blobs/tt_blackhole_gddr_init.bin` (copy in `gddr-decompile/binaries/`, SHA-256 `b5be3c09…`) | The timing table for every supported vendor and speed, and the rule for choosing the row |
| MRISC firmware **2.17**, extracted from the official signed bundle `p150a-19.17.1` (`tenstorrent/build/fw/19.17.1/`). This is what the cards run. | The same table, byte for byte, at the same offsets. The rest of the code changed. |
| Live MRISC L1 on both cards, read over the NoC with tt-exalens | The timing struct the controller is actually using, the raw DRAM vendor ID, and the vendor code the firmware chose |
| GDDR telemetry table (MRISC L1 `0x8000`), layout from `bh_arc/gddr_telemetry_table.h` | Vendor = 1 (Samsung C-die), speed 16000, training complete, firmware 2.17, EDC counters, temperatures |
| `memfwcfg` board parameter blob (P150A) | `dram_speed = 16000`, `clamshell_mode = 1` |
| `tt-smi` | Both cards: P150A, bundle 19.17.1, GDDR firmware 2.17 |
| `tt-system-firmware` source (`bh_arc/gddr.c`, `gddr.h`) | Memory PLL = speed ÷ 16, allowed speed range, how training failure is handled at boot |

`hardware/gddr6/decode_timing_table.py` prints the full table from either
firmware binary.

## What is confirmed and what is inferred

| Claim | Status |
|---|---|
| The **numbers** in the table | **Confirmed.** Decoded from the firmware. The live struct on both cards equals the Samsung 16 Gbps row exactly, and 2.17 contains the identical table. |
| DRAM vendor: Samsung C-die | **Confirmed** by the firmware's own detection. Every controller read returns raw vendor ID `0xAB91` per channel, and the firmware maps `0x91` to Samsung C-die. |
| 16 Gbps, 2.01 GHz clock | **Confirmed** by the config blob, telemetry, and table word 37 (2,010,000), which matches speed ÷ 16 from the ARC source |
| Clamshell, 2 × x8 devices per controller | **Confirmed** by the config blob. Device density follows from 32 GB total. |
| Exact part number (`K4ZAF325BC-…`) | **Inferred** from Samsung's naming for 16 Gb GDDR6 C-die. Not readable from software, since GDDR6 has no SPD and the vendor ID doesn't encode the speed bin. Check the package marking. |
| The **names** of the fields (CL, tRCD, …) | **Inferred**, with the confidence marked per row. The controller's register names aren't public. Labels come from field width, how fields are paired or packed (CL and WL go into one mode-register value), and whether a value stays at a constant ns across speeds and vendors. |
| Only 3 of 8 controllers read directly (instances 0, 1, 3) | The others didn't respond at the NoC coordinates tried. That's a script limitation, not a fault. The P150A config sets all 8 identically, and one firmware image serves all of them. |

## Samsung timing table

Values in tCK, with ns in parentheses (tCK = 1 / clock: 1.50, 1.76, 2.01,
2.26 GHz). Our cards use the **16 Gbps** column. The firmware also uses the
18 Gbps row when configured for 17 Gbps.

| Word | Field | Label confidence | 12 Gbps | 14 Gbps | **16 Gbps** | 18 Gbps |
|---:|---|---|---:|---:|---:|---:|
| 2 | CL / RL (read latency) | High | 22 (14.7) | 26 (14.8) | **33 (16.4)** | 33 (14.6) |
| 1 | WL (write latency) | High | 8 (5.3) | 8 (4.5) | **8 (4.0)** | 8 (3.5) |
| 17 | tRCD, read | High | 36 (24.0) | 36 (20.5) | **36 (17.9)** | 36 (15.9) |
| 16 | tRCD, write | High | 20 (13.3) | 20 (11.4) | **20 (10.0)** | 21 (9.3) |
| 19 | tRAS | Medium | 46 (30.7) | 54 (30.7) | **64 (31.8)** | 70 (31.0) |
| 23 | tRC | Medium | 70 (46.7) | 94 (53.4) | **94 (46.8)** | 104 (46.0) |
| 22 | tWR | Medium | 30 (20.0) | 30 (17.0) | **32 (15.9)** | 36 (15.9) |
| 25 | tRFCab (all-bank refresh) | High | 185 (123) | 220 (125) | **245 (122)** | 275 (122) |
| 26 | tRFCpb (per-bank refresh) | High | 95 (63) | 110 (63) | **125 (62)** | 140 (62) |
| 36 | tREFI (refresh interval) | High | 2840 (1.89 µs) | 3200 (1.82 µs) | **3700 (1.84 µs)** | 4100 (1.81 µs) |
| 37 | Memory clock, kHz | High | 1,500,000 | 1,760,000 | **2,010,000** | 2,260,000 |
| 9, 12 or 13 | tCCD_S | Medium | 2 | 2 | **2** | 2 |
| 14 / 15 | tWTR_L / tWTR_S | **Low** | 20 / 20 | 20 / 20 | **20 / 20 (10.0)** | 22 / 22 |
| 20 / 21 | tRRD (two variants) | **Low** | 8 / 8 | 8 / 8 | **9 / 9 (4.5)** | 9 / 9 |

Notes on the labels:

* **Constant-ns check.** tRFCab/pb, tREFI, tRAS and tWR hold nearly constant
  ns across all four speeds, which supports those labels. Samsung's tRCD read
  and tWTR are the *same tCK* at 12–16 Gbps, so their ns shrink as speed rises.
  These look like values set once for the fastest bin and reused. The labels
  for them rest on Micron's rows (Micron's tRCD read stays at 18 ns at every
  speed) and on field pairing.
* **tWTR is the weakest label.** In the same slots Micron has 12/11 at 16 Gbps.
  20 tCK for Samsung is plausible but unconfirmed, and it is the value that
  matters most for read/write turnaround (below).
* Word 37 as the memory clock is read off the values (it equals speed ÷ 16 in
  MHz × 1000).

### All 52 words, Samsung rows

The controller expands the chosen row into MRISC L1 `0x10400`; word *n* lives
at `0x10400 + 4n`. Words not named above are unidentified.

| Word | 12 | 14 | **16** | 18 | | Word | 12 | 14 | **16** | 18 |
|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | **0** | 0 | | 26 | 95 | 110 | **125** | 140 |
| 1 | 8 | 8 | **8** | 8 | | 27 | 6 | 6 | **6** | 6 |
| 2 | 22 | 26 | **33** | 33 | | 28 | 25 | 36 | **36** | 36 |
| 3 | 3 | 3 | **3** | 3 | | 29 | 12 | 12 | **14** | 16 |
| 4 | 3 | 3 | **3** | 3 | | 30 | 239 | 240 | **250** | 280 |
| 5 | 14 | 14 | **14** | 14 | | 31 | 16 | 20 | **22** | 25 |
| 6 | 7 | 7 | **7** | 7 | | 32 | 16 | 20 | **22** | 25 |
| 7 | 396826 | 396826 | **411000** | 451000 | | 33 | 18 | 20 | **22** | 25 |
| 8 | 15 | 15 | **15** | 17 | | 34 | 11 | 12 | **12** | 14 |
| 9 | 2 | 2 | **2** | 2 | | 35 | 11 | 12 | **12** | 14 |
| 10 | 25 | 25 | **26** | 31 | | 36 | 2840 | 3200 | **3700** | 4100 |
| 11 | 10 | 10 | **10** | 10 | | 37 | 1500000 | 1760000 | **2010000** | 2260000 |
| 12 | 2 | 2 | **2** | 2 | | 38 | 6 | 7 | **21** | 25 |
| 13 | 2 | 2 | **2** | 2 | | 39 | 6 | 7 | **4** | 9 |
| 14 | 20 | 20 | **20** | 22 | | 40 | 750 | 875 | **1000** | 1120 |
| 15 | 20 | 20 | **20** | 22 | | 41 | 20 | 22 | **25** | 28 |
| 16 | 20 | 20 | **20** | 21 | | 42 | 12 | 12 | **12** | 14 |
| 17 | 36 | 36 | **36** | 36 | | 43 | 16 | 18 | **22** | 25 |
| 18 | 24 | 29 | **32** | 36 | | 44 | 25 | 25 | **27** | 31 |
| 19 | 46 | 54 | **64** | 70 | | 45 | 12 | 13 | **13** | 13 |
| 20 | 8 | 8 | **9** | 9 | | 46 | 8 | 8 | **8** | 9 |
| 21 | 8 | 8 | **9** | 9 | | 47 | 5 | 6 | **6** | 7 |
| 22 | 30 | 30 | **32** | 36 | | 48 | 5 | 6 | **6** | 7 |
| 23 | 70 | 94 | **94** | 104 | | 49 | 0 | 0 | **0** | 0 |
| 24 | 28 | 28 | **28** | 28 | | 50 | 2 | 3 | **3** | 3 |
| 25 | 185 | 220 | **245** | 275 | | 51 | 8 | 10 | **11** | 13 |

Live values read from both cards (identical on every controller read):
`0, 8, 33, 3, 3, 14, 7, 411000, 15, 2, 26, 10, 2, 2, 20, 20, 20, 36, 32, 64, 9,
9, 32, 94, 28, 245, 125, 6, 36, 14, 250, 22, 22, 22, 12, 12, 3700, 2010000, 21,
4, 1000, 25, 12, 22, 27, 13, 8, 6, 6, 0, 3, 11`.

## Other information from the firmware

* **Supported parts:** Samsung C-die, Micron C-die and Micron E-die at 12, 14
  and 16 Gbps. **17 and 18 Gbps are Samsung-only**; any other vendor at those
  speeds is a firmware error.
* **Vendor is detected at boot**, not configured. The same firmware and board
  config work with either vendor.
* **Speed is configured, not detected.** It is word 1 of the 256-byte `memfwcfg`
  blob in SPI flash, read once at boot. The ARC accepts 12000–20000 and sets the
  memory PLL to speed ÷ 16. Every board config in the bundle uses 16000, except
  Galaxy, which was lowered to 14000.
* **The installed `memfwcfg` is parameter-table version 8**: speed 16000,
  clamshell 1, features 0, board 1, firmware 2.17. The public header describes
  version 6.

## What it means for bandwidth

Per channel, at 16 Gbps:

* **Write → read turnaround:** the bus idles for about tWTR + RL = 20 + 33 =
  53 tCK ≈ **26 ns**. If the low-confidence tWTR is really nearer 9 tCK, it's
  about 21 ns.
* **Read → write:** about 2–4 tCK. Cheap.
* **Batching:** a burst is 32 B in 2 tCK, so one round trip costs about 22–28
  burst slots. Reaching about 90% efficiency needs roughly **4 KB per direction
  per channel** (8 KB per controller) between switches.

| Bursts per direction | Bytes per channel per direction | Efficiency | Per-controller GB/s |
|---:|---:|---:|---:|
| 8 | 256 B | ~36% | ~23 |
| 32 | 1 KB | ~70% | ~45 |
| 80 | 2.5 KB | ~85% | ~54 |
| 128 | 4 KB | ~90% | ~58 |

This is a model from the timings, not a measurement. The
[traffic-pattern experiments](../measurements/dram-traffic-patterns.md) switched
direction every few µs at the finest, far above this scale, so they neither
confirm nor contradict it. They do show a single controller sustaining ~99% of
pin rate, which suggests refresh is mostly hidden (tRFCpb = 62 ns every 1.84 µs
per bank, if per-bank refresh is used; not confirmed from registers).

## 18 Gbps

* The firmware has a distinct Samsung 18 Gbps row. Its values aren't copies of
  the 16 Gbps row, so someone characterized it, but no shipping board config
  uses it.
* Changing speed means reflashing `memfwcfg` with a new `dram_speed`. No host
  message sets it, and resetting the controller doesn't reload the config or
  the PLL.
* Reading the boot source: a failed training is logged and boot continues;
  tt-flash doesn't need working GDDR. Recovery by reflashing should therefore
  work. **Not tested on a card.** The official 19.17.1 bundle is kept in
  `tenstorrent/build/fw/19.17.1/` as a restore point. Nothing has been flashed.
* Gain: at most +12.5% peak bandwidth (576 GB/s). The 18 Gbps timings are about
  the same in ns, so latency and turnaround barely change.
* Whether our chips are rated for 18 Gbps (Samsung's `-HC18` bin) can only be
  read from the package marking.

## Open questions

* Exact part number and speed bin (package marking).
* Field names for the ~35 unlabeled words, and confirmation of tWTR and tRRD.
* The address mapping from bytes to channel, bank group and bank. It is needed
  to avoid same-bank-group (tCCD_L) and row conflicts deliberately from
  software.
* Whether refresh is per-bank.
