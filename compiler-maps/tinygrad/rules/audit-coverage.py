#!/usr/bin/env python3
"""Inventory production PatternMatcher rule templates and audit explanatory headings.

Static scope: direct PatternMatcher(...) calls, literal/comprehension rule lists,
and local lists assembled through assignments, +=, append, and extend. Runtime
composition reuses existing templates and is recorded separately. No imports or
device initialization are performed.
"""
import argparse
import ast
import json
import re
import subprocess
from collections import Counter
from pathlib import Path


def scan(root):
    records, constructors, unresolved = {}, [], []
    for path in sorted((root / 'tinygrad').rglob('*.py')):
        source = path.read_text()
        tree = ast.parse(source)
        parents = {child: node for node in ast.walk(tree) for child in ast.iter_child_nodes(node)}
        rel = str(path.relative_to(root / 'tinygrad'))

        def scope_of(node):
            while node in parents:
                node = parents[node]
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Module)):
                    return node
            return tree

        def collect(expr, scope, seen=None):
            seen = set() if seen is None else seen
            if isinstance(expr, ast.Tuple) and len(expr.elts) == 2:
                return [expr]
            if isinstance(expr, (ast.List, ast.Tuple)):
                return [r for item in expr.elts for r in collect(item, scope, seen)]
            if isinstance(expr, (ast.ListComp, ast.GeneratorExp)):
                return collect(expr.elt, scope, seen)
            if isinstance(expr, ast.Starred):
                return collect(expr.value, scope, seen)
            if isinstance(expr, ast.BinOp) and isinstance(expr.op, ast.Add):
                return collect(expr.left, scope, seen) + collect(expr.right, scope, seen)
            if isinstance(expr, ast.Name) and expr.id not in seen:
                seen = seen | {expr.id}
                found = []
                for n in ast.walk(scope):
                    targets = n.targets if isinstance(n, ast.Assign) else [n.target] if isinstance(n, (ast.AnnAssign, ast.AugAssign)) else []
                    if any(isinstance(t, ast.Name) and t.id == expr.id for t in targets) and n.value is not None:
                        found.extend(collect(n.value, scope, seen))
                    if (isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)
                            and isinstance(n.func.value, ast.Name) and n.func.value.id == expr.id
                            and n.func.attr in ('append', 'extend') and n.args):
                        found.extend(collect(n.args[0], scope, seen))
                return found
            return []

        for node in ast.walk(tree):
            if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                    and node.func.id == 'PatternMatcher' and node.args):
                continue
            expr = node.args[0]
            rules = collect(expr, scope_of(node))
            site = f'{rel}:L{node.lineno}'
            kind = 'templates' if rules else 'empty' if isinstance(expr, ast.List) and not expr.elts else 'composition'
            if not rules and not (kind == 'empty' or (rel == 'uop/ops.py' and isinstance(expr, ast.BinOp))):
                unresolved.append({'site': site, 'expression': ast.unparse(expr)})
            constructors.append({'site': site, 'kind': kind, 'templates': len(rules)})
            for rule in rules:
                key = (rel, rule.lineno, rule.col_offset)
                if key not in records:
                    records[key] = {'id': f'{rel}:L{rule.lineno}', 'column': rule.col_offset,
                                    'pattern': ast.unparse(rule.elts[0]), 'callback': ast.unparse(rule.elts[1]),
                                    'constructors': []}
                if site not in records[key]['constructors']:
                    records[key]['constructors'].append(site)
    return sorted(records.values(), key=lambda r: (r['id'].split(':L')[0], int(r['id'].split(':L')[1]), r['column'])), constructors, unresolved


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tinygrad', type=Path, default=Path(__file__).resolve().parents[4] / 'tinygrad')
    parser.add_argument('--output', type=Path, default=Path(__file__).with_name('coverage.json'))
    parser.add_argument('--check', action='store_true', help='fail if any template lacks a heading or a constructor cannot be resolved')
    args = parser.parse_args()
    records, constructors, unresolved = scan(args.tinygrad)
    headings = {}
    for doc in sorted(Path(__file__).parent.glob('*.md')):
        for lineno, line in enumerate(doc.read_text().splitlines(), 1):
            if not line.startswith('#'):
                continue
            for rule_id in re.findall(r'([\w/]+\.py:L\d+)', line):
                headings.setdefault(rule_id, []).append(f'{doc.name}:{lineno}')
    ordinals = Counter()
    for rule in records:
        ordinal = ordinals[rule['id']]
        ordinals[rule['id']] += 1
        rule['documented_at'] = headings.get(rule['id'], [])[ordinal:ordinal + 1]
    ids = Counter(r['id'] for r in records)
    payload = {
        'revision': subprocess.check_output(['git', '-C', str(args.tinygrad), 'rev-parse', 'HEAD'], text=True).strip(),
        'source_status': subprocess.check_output(['git', '-C', str(args.tinygrad), 'status', '--short', '--', 'tinygrad'], text=True).strip(),
        'scope': 'production tinygrad/ direct PatternMatcher constructors and statically resolved local rule-list templates',
        'counts': {'constructors': len(constructors), 'rule_templates': len(records),
                   'documented_templates': sum(bool(r['documented_at']) for r in records)},
        'same_line_templates': {k: v for k, v in ids.items() if v > 1},
        'unresolved': unresolved, 'constructors': constructors, 'rules': records,
    }
    args.output.write_text(json.dumps(payload, indent=2) + '\n')
    print(json.dumps(payload['counts']))
    print('Unresolved constructors:', len(unresolved), 'same-line template groups:', len(payload['same_line_templates']))
    for path, count in sorted(Counter(r['id'].split(':L')[0] for r in records if not r['documented_at']).items()):
        print(f'MISSING {path}: {count}')
    if args.check and (unresolved or any(not r['documented_at'] for r in records)):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
