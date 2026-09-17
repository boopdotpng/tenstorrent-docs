#!/usr/bin/env python3
"""Join reviewed ISA contracts and timing evidence without importing device code."""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASE_OPS = {'nop': 'SFPNOP', 'loadi': 'SFPLOADI', 'mov_dep': 'SFPMOV', 'iadd_dep': 'SFPIADD',
            'arecip_dep': 'SFPARECIP', 'mul24_dep': 'SFPMUL24', 'cast_dep': 'SFPCAST', 'transp': 'SFPTRANSP',
            'swap': 'SFPSWAP', 'swap_nop': 'SFPSWAP', 'shuffle': 'SFPSHFT2', 'shuffle_nop': 'SFPSHFT2',
            'shft2_bit': 'SFPSHFT2', 'setcc': 'SFPSETCC', 'encc': 'SFPENCC', 'dma_nop': 'DMANOP'}
for stem in ('add', 'mul', 'mad'):
    for kind in ('dep', 'ind4'):
        CASE_OPS[f'{stem}_{kind}'] = 'SFP' + stem.upper()
FALLBACK = {
 'ADDDMAREG': 'Add scalar operands in the Tensix GPR file.',
 'SUBDMAREG': 'Subtract scalar operands in the Tensix GPR file.',
 'MULDMAREG': 'Multiply scalar operands in the Tensix GPR file; see tested operand-width limits.',
 'BITWOPDMAREG': 'Perform a selected bitwise operation on scalar GPR operands.',
 'SHIFTDMAREG': 'Shift a scalar GPR operand using the selected shift mode.',
 'CMPDMAREG': 'Compare scalar operands and produce a GPR result.',
 'RSTDMA': 'Reset selected DMA/address state. No reviewed functional contract in this snapshot.',
 'SETPKEDGOF': 'Configure legacy pack edge offsets; encoding support is not a behavioral guarantee.',
 'UNPACR_NOP': 'Issue unpack control/synchronization behavior without the ordinary payload operation.',
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(repo, *args):
    try:
        return subprocess.check_output(['git', '-C', str(repo), *args], text=True, stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        return 'unavailable'


def sections(text):
    parts = re.split(r'^##+ (.+)\n', text, flags=re.M)
    return {parts[i]: parts[i+1].strip() for i in range(1, len(parts)-1, 2)}


def group(name, resource):
    if name.startswith('SFP'): return 'Vector / SFPU'
    return {'FPU': 'Matrix / FPU', 'FPU legacy': 'Matrix / FPU', 'unpack': 'Unpack', 'pack': 'Pack',
            'sync': 'Synchronization', 'config': 'Configuration', 'scalar': 'Scalar / DMA',
            'scalar/memory': 'Scalar / DMA', 'scalar legacy': 'Scalar / DMA'}.get(resource, 'Control / addressing')


def build(bh, timing, manual):
    invpath, auditpath = bh / 'tests/isa/inventory.json', bh / 'tests/isa/audit.json'
    inventory, audit = json.loads(invpath.read_text()), json.loads(auditpath.read_text())
    timingpath = timing / 'tensix_timing.json'
    timings = json.loads(timingpath.read_text())
    by_timing = {row['instruction']: row for row in timings['instructions']}
    by_audit = {x['instruction']: x for x in audit['instructions']}
    by_requirement = {x['id']: x for x in audit['requirements']}
    sources = [invpath, auditpath, timingpath]
    observations = {}
    source = timing / 'tensix_measured.jsonl'
    if source.exists():
        sources.append(source)
        for line in source.read_text().splitlines():
            row = json.loads(line)
            op = row.get('instruction') or CASE_OPS.get(row.get('case'))
            if not op: continue
            observations.setdefault(op, []).append({
                'case': row['case'], 'slopes': row['adjacent_slopes_cycles_per_body_op'],
                'configuration': 'cfg0 clear bits: ' + row.get('clear_cfg0_bits', 'not specified'),
                'card': row['card'], 'core': row['core'], 'role': row['role'],
                'completion': row['completion'], 'semantics': row['semantics'], 'loop': row['loop'],
                'samples_per_point': row['samples_per_point'], 'points': row['points'],
                'source': 'blackhole-py:tests/timing/tensix_measured.jsonl',
                'probe_source_sha256': row['source_sha256'],
                'note': 'Completed-loop slope per body operation, not isolated result latency. Includes loop/issue effects; swap_nop and shuffle_nop intentionally include a padding NOP.'})
    # Associate documents by exact opcode tokens, not fuzzy substring matches.
    related = {}
    for folder in ('hardware', 'kernel-dev', 'matmul'):
        for doc in (ROOT / folder).rglob('*.md'):
            text = doc.read_text()
            title = next((l[2:] for l in text.splitlines() if l.startswith('# ')), doc.stem)
            for op in set(re.findall(r'\b(?:TT_)?([A-Z][A-Z0-9_]{2,})\b', text)):
                related.setdefault(op, []).append({'path': str(doc.relative_to(ROOT)), 'title': title})
    instructions = []
    manual_manifest = []
    for entry in inventory['instructions']:
        name = entry['instruction']
        reviewed = by_audit.get(name, {})
        timing_row = by_timing.get(name, {})
        resource = timing_row.get('unit', 'unknown')
        rows = [{'status': timing_row.get('basis', 'unknown'), 'note': timing_row.get('notes', ''), 'timing': [{'latency': timing_row.get('latency_cycles', 'unknown'), 'issue_interval': timing_row.get('issue_interval_cycles', 'unknown'), 'source': timing_row.get('source_url'), 'note': timing_row.get('notes', '')}]}]
        src = entry.get('resolved_source', entry.get('source'))
        page = manual / src if src else None
        body = page.read_text() if page and page.exists() else ''
        if page and page.exists():
            manual_manifest.append({'path': src, 'sha256': digest(page)})
        parts = sections(body)
        # Short attributed synopsis; full model is opened from the sibling manual.
        summary = re.search(r'\*\*Summary:\*\*\s*(.+?)(?:\n\n|$)', body, re.S)
        overview = summary[1] if summary else FALLBACK.get(name, '')
        if not overview:
            overview = next((t.get('semantics') for row in rows for t in row.get('timing', []) if t.get('semantics')), '')
        if not overview:
            overview = next((l[2:] for l in body.splitlines() if l.startswith('# ')),
                            'No reviewed behavior synopsis is available. Use the encoding and source references below.')
        caveats = []
        for heading, content in parts.items():
            if any(word in heading.lower() for word in ('scheduling', 'divergence', 'undefined', 'restriction', 'caveat')):
                # Keep attribution and a link to the full manual, without copying a full page.
                paragraph = content.split('\n\n')[0]
                caveats.append({'title': heading, 'text': paragraph[:1600]})
        if rows:
            caveats.extend({'title': 'Timing scope', 'text': x['note']} for x in rows if x.get('note'))
        contracts = []
        for key in reviewed.get('reviewed_requirements', []):
            req = by_requirement[key]
            tests = []
            for selector in req['tests']:
                path = selector.split('::')[0]
                meta = audit['test_functions'].get(selector, {})
                local = bh / path
                expected = meta.get('source_sha256')
                state = 'matches audit' if expected and local.exists() and digest(local) == expected else 'changed or unavailable'
                tests.append({'selector': selector, 'path': path, 'line': meta.get('line'),
                              'source_status': state, 'source_sha256': expected})
            contracts.append({'id': key, 'assertion': req['assertion'], 'gaps': req['gaps'],
                              'evidence': req.get('evidence', {}), 'tests': tests,
                              'evidence_scope': 'Recorded outcomes for the whole requirement/test group, not a per-opcode pass count.'})
        instructions.append({'name': name, 'opcode': f"0x{entry['llk_encoding']['opcode']:02x}",
            'group': group(name, resource), 'resource': resource,
            'overview': overview[:1800], 'overview_source': f'tt-isa-documentation:{src}' if summary else None,
            'syntax': entry.get('syntax', ''), 'manual': src,
            'manual_revision': inventory['manual_commit'], 'blackhole_contract': entry.get('blackhole_contract', False),
            'behavior': 'partial' if contracts else 'no reviewed claim',
            'encoding': entry['llk_encoding']['arguments'], 'modifiers': entry.get('modifiers', []),
            'timing': [{**t, 'status': row['status']} for row in rows for t in row.get('timing', [])],
            'timing_status': rows[0]['status'] if rows else 'unknown',
            'observations': observations.get(name, []), 'caveats': caveats,
            'contracts': contracts, 'sightings': reviewed.get('source_sightings', []),
            'documents': related.get(name, [])[:12]})
    manifest = []
    for p in sources:
        repo = bh if p.is_relative_to(bh) else ROOT
        manifest.append({'source': ('blackhole-py:' if repo == bh else 'docs:') + str(p.relative_to(repo)),
                         'sha256': digest(p), 'git_status': git(repo, 'status', '--short', '--', str(p.relative_to(repo))) or 'clean'})
    return {'schema': 1, 'title': 'Tensix instruction reference', 'review_date': '2026-09-17',
        'blackhole_py_commit': git(bh, 'rev-parse', 'HEAD'), 'manual_commit': inventory['manual_commit'],
        'timing_date': '2026-09-17', 'sources': manifest, 'manual_sources': manual_manifest,
        'scope': 'Local working-tree snapshot. Behavioral claims are partial. Encoding presence and source sightings are not functional coverage. Recorded hardware runs are not rerun by this viewer.',
        'runs': audit.get('runs', []), 'instructions': sorted(instructions, key=lambda x: x['name'])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--blackhole-py', type=Path, default=ROOT.parent / 'blackhole-py')
    parser.add_argument('--timing', type=Path, default=ROOT.parent / 'blackhole-py/tests/timing')
    parser.add_argument('--manual', type=Path, default=ROOT.parent / 'tt-isa-documentation')
    parser.add_argument('--output', type=Path, default=ROOT / 'viewer/data/instructions.json')
    args = parser.parse_args()
    data = build(args.blackhole_py.resolve(), args.timing.resolve(), args.manual.resolve())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
    print(f"Wrote {len(data['instructions'])} instructions to {args.output}")


if __name__ == '__main__': main()
