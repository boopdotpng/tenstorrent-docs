#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
CORPUS = ROOT/'uop-dumps'/'current'
PROBES = ['matmul_epilogue','rmsnorm','sdpa_gqa_decode','kv_cache_update_symbolic','llama32_1b_block_decode']

for probe in PROBES:
  d = CORPUS/probe
  abi = json.loads((d/'call_abi.json').read_text())
  print(f'=== {probe}: {len(abi)} final calls ===')
  for i, call in enumerate(abi):
    f = d/f'50_kernel_{i:02d}_base_ast.jsonl'
    nodes = [json.loads(x) for x in f.read_text().splitlines()]
    counts = Counter(n['op'] for n in nodes)
    params = [(n['id'], n['arg'], n['dtype'], n['shape']) for n in nodes if n['op']=='PARAM']
    stores = [(n['id'], n['src']) for n in nodes if n['op']=='STORE']
    shapeops = [(n['id'],n['op'],n['shape']) for n in nodes if n['op'] in {'REDUCE','EXP2','SQRT','RECIPROCAL','WHERE','MULACC','ADD','MUL','STORE'}]
    outarg = call['bound_args'][0] if call.get('bound_args') else {}
    print(f'call {i:02d}: ast_nodes={len(nodes)} output={outarg.get("shape")} dtype={outarg.get("dtype")} counts=' + ','.join(f'{k}:{counts[k]}' for k in sorted(counts) if k in {'REDUCE','EXP2','SQRT','RECIPROCAL','WHERE','STORE','MUL','ADD','PARAM'}))
    print('  ast params: ' + '; '.join(f'id={pid} {arg} {dtype} shape={shape}' for pid,arg,dtype,shape in params))
    print('  bound: ' + '; '.join(f"pos={a['position']} op={a['op']} shape={a['shape']} dtype={a['dtype']} arg={a['arg']}" for a in call['bound_args']))
    print('  key ops: ' + '; '.join(f'id={nid} {op} shape={shape}' for nid,op,shape in shapeops))
  print()
