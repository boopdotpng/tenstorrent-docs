#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "research-output" / "technical-report.md"
text = REPORT.read_text()
lines = text.splitlines()

headings = []
for lineno, line in enumerate(lines, 1):
  if match := re.fullmatch(r"## (\d+)\. (.+)", line):
    headings.append((int(match.group(1)), lineno, match.group(2)))

citation_pattern = re.compile(
  r"(?P<path>(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\."
  r"(?:py|md|txt|jsonl|out|diff|json)):(?P<start>\d+)"
  r"(?:-(?P<end>\d+))?"
)
references: list[tuple[str, int, int]] = []
missing: list[tuple[str, int, int]] = []
bad_ranges: list[tuple[str, int, int, int]] = []
line_counts: dict[str, int] = {}
for match in citation_pattern.finditer(text):
  path = match.group("path")
  start = int(match.group("start"))
  end = int(match.group("end") or start)
  references.append((path, start, end))
  source = ROOT / path
  if not source.is_file():
    missing.append((path, start, end))
    continue
  if path not in line_counts:
    with source.open("rb") as handle:
      line_counts[path] = sum(1 for _ in handle)
  count = line_counts[path]
  if start < 1 or end < start or end > count:
    bad_ranges.append((path, start, end, count))

expected_sections = list(range(1, 14))
actual_sections = [number for number, _, _ in headings]
absolute_leaks = [
  (lineno, line) for lineno, line in enumerate(lines, 1)
  if "/mnt/data" in line or str(ROOT) in line
]
fence_count = sum(1 for line in lines if line.startswith("```"))
errors: list[str] = []
if actual_sections != expected_sections:
  errors.append(f"section sequence is {actual_sections}, expected {expected_sections}")
if missing:
  errors.append(f"{len(missing)} citations reference missing files")
if bad_ranges:
  errors.append(f"{len(bad_ranges)} citations have invalid line ranges")
if absolute_leaks:
  errors.append(f"{len(absolute_leaks)} report lines contain absolute bundle paths")
if fence_count % 2:
  errors.append(f"unbalanced Markdown fences: {fence_count}")

print(f"report: {REPORT.relative_to(ROOT)}")
print(f"bytes: {REPORT.stat().st_size}")
print(f"lines: {len(lines)}")
print(f"words: {len(text.split())}")
print(f"numbered sections: {len(headings)} ({actual_sections})")
for number, lineno, title in headings:
  print(f"  {number:02d} line {lineno}: {title}")
print(f"source references: {len(references)}")
print(f"unique cited files: {len(set(path for path, _, _ in references))}")
print(f"missing cited files: {len(missing)}")
for item in missing:
  print(f"  MISSING {item}")
print(f"invalid citation ranges: {len(bad_ranges)}")
for item in bad_ranges:
  print(f"  BAD_RANGE {item}")
print(f"absolute path leaks: {len(absolute_leaks)}")
print(f"Markdown fences: {fence_count} ({'balanced' if fence_count % 2 == 0 else 'UNBALANCED'})")
print("status: " + ("FAIL" if errors else "PASS"))
if errors:
  for error in errors:
    print(f"ERROR: {error}")
  sys.exit(1)
