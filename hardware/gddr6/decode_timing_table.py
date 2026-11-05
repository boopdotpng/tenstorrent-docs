"""Print the GDDR6 timing table embedded in Blackhole MRISC firmware.

Usage: python3 -I decode_timing_table.py tt_blackhole_gddr_init.bin

Valid for MRISC 2.16 and 2.17 (identical tables at identical offsets).
Rows: 10 vendor/speed rows of 52 one-byte indices at 0x3434; each index
selects a little-endian u32 from the value pool at 0x36a4. The firmware
expands the selected row into MRISC L1 0x10400 (52 words).
"""
import struct, sys

ROWS = ["S12", "MC12", "ME12", "S14", "MC14", "ME14", "S16", "MC16", "ME16", "S18"]
blob = open(sys.argv[1], "rb").read()
pool = [struct.unpack_from("<I", blob, 0x36a4 + 4 * i)[0] for i in range((0x37e4 - 0x36a4) // 4)]
rows = [[pool[i] for i in blob[0x3434 + 52 * r:0x3434 + 52 * (r + 1)]] for r in range(len(ROWS))]
print("word L1      " + " ".join(f"{n:>8}" for n in ROWS))
for w in range(52):
  print(f"{w:4d} {0x10400 + 4 * w:#07x} " + " ".join(f"{rows[r][w]:8d}" for r in range(len(ROWS))))
