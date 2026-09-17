# Local docs and Tensix reference viewer

From the repository root:

```sh
./serve.sh
```

Open **http://127.0.0.1:8000**. No browser opens automatically.
`./serve.sh --port 8001` selects another port. Port is the only configuration option.
Only Python 3.10+ is needed. No npm install, CDN, build step, or device access.
The server binds to `0.0.0.0` by default, so other machines can connect at
`http://<this-machine-ip>:8000`. It never opens a browser.

The documentation page (`/`) reads Markdown directly from this repository, groups it
by topic, and searches the full text. Archives (`/archives`) have a separate page and search. Global search covers both sections
and labels historical results. The dedicated ISA page (`/isa`) has an instruction sidebar and searches names, behavior, timing, caveats, and
reviewed test claims. It offers execution-unit and evidence filters, per-opcode
links, dark mode, and a layout usable on smaller screens. Press `/` for global search. Removed document routes resolve through
`maintenance/relocations.json`; consolidated section anchors preserve deep links.

## Data provenance

`data/instructions.json` is a checked-in snapshot joining:

- `blackhole-py/tests/isa/inventory.json`: 137 encoders and operand fields.
- `blackhole-py/tests/isa/audit.json`: reviewed assertions, test selectors, and gaps.
- `blackhole-py/tests/timing/tensix_timing.json`: latency, issue spacing, evidence basis, and scheduling notes.
- `blackhole-py/tests/timing/tensix_measured.jsonl`: completed-loop slopes and raw samples.
- Applicable local ISA manual pages: attributed short summaries and caveat excerpts.
- This repository's hardware/kernel docs: exact-opcode navigation links.

The September 17 snapshot attaches 129 nonempty-body measurement records to 24
instructions; the source file also contains three empty-body controls, for 132
records total. A measured loop slope is not an isolated result latency. A
requirement's recorded pass count belongs to its entire test group, not each
opcode linked to it. Encoding coverage is not full behavioral coverage.

Source hashes, revisions, and working-tree status are embedded in the snapshot.
Several input files were untracked in blackhole-py when inspected. Test source
hashes are compared at snapshot generation; changes afterward require a refresh.
Source links open sibling checkouts when present. The instruction snapshot and
this repository's docs remain usable without them; unavailable source links
show an explicit missing-document message.

## Refresh

This command reads data and source files; it does not import blackhole-py,
run tests, boot a device, or regenerate its audit:

```sh
python3 viewer/build_reference.py
```

Optional `--blackhole-py`, `--timing`, `--manual`, and `--output` paths override
the sibling-checkout defaults. Review the diff before committing a new snapshot.
Do not replace unknowns or estimated timing with an assumed one-cycle value.
The older September 9 timing archive has been superseded for this instruction
view, notably for the corrected DMANOP probe.

## Validation

```sh
python3 -m unittest discover -s viewer/tests -v
node --check viewer/app.js  # optional development check; Node is not needed to serve
```

The server only exposes documentation, selected source file types in named
sibling repos, and viewer assets. It rejects traversal, hidden files, and
symlink escapes. Markdown is parsed with vendored marked and sanitized with
DOMPurify. [Versions and licenses](vendor/README.md) accompany the local assets.
