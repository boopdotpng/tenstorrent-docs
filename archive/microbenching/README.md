# Blackhole microbenchmark reports (archived)

Reports from the old `blackhole-py/microbenching/` harness. Its scripts
imported `dsl`, `ttk.tensix`, `ttk.noc` and `ttk.mailbox`, which no longer
exist, so they were deleted (git history has them). Links to scripts in these
reports were removed. The timing cheat sheet built from this data now lives in
[`timing/`](../../timing/README.md).

- `status.md`: the pass/fail state at the time
- `docs/README.md`: index of the raw reports
- `docs/noc/`: NoC, DRAM and multicast reports; `docs/noc/reading-guide.md` introduces the NoC from scratch
- `docs/tensix/`: DRISC, pack and unpack reports

When this harness reports a hang or a missing feature, treat it as a harness
result, not a hardware fact. See [known issues](../../kernel-dev/known-issues.md).
