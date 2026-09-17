#!/usr/bin/env python3
"""Rebuild source-indexed timing catalogs using local files only; no device access."""
import csv
import hashlib
import html
import json
import os
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ISA = ROOT/'tt-isa-documentation'
BH = ISA/'BlackholeA0/TensixTile/TensixCoprocessor'
WH = ISA/'WormholeB0/TensixTile/TensixCoprocessor'

def rel(p): return os.path.relpath(p, HERE)
def source(p): return os.path.relpath(p, ROOT)
def clean(s): return html.unescape(re.sub('<[^>]*>', '', s)).replace('\xa0',' ').strip()
def write_json(name, value): (HERE/name).write_text(json.dumps(value, indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

# Read every explicit mode row, preserving separate descriptions for modifiers.
modes=[]
for line, text in enumerate((BH/'VectorUnit.md').read_text().splitlines(), 1):
    cells=re.findall(r'<td[^>]*>(.*?)</td>',text)
    if len(cells)!=4: continue
    match=re.search(r'<code>(SFP\w+)</code>',cells[0])
    if match:
        modes.append(dict(instruction=match[1], ipc=clean(cells[1]), latency=clean(cells[2]),
                          semantics=clean(cells[3]), source=source(BH/'VectorUnit.md'), line=line))
write_json('sfpu-modes.json',modes)

# Compiler encoding coverage, not an assertion that every historical opcode is useful.
yaml=ROOT/'tt-llk/tt_llk_blackhole/instructions/assembly.yaml'
parts=re.split(r'^([A-Z][A-Z0-9_]*):\s*$',yaml.read_text(),flags=re.M)
fixed={}
def group(names,latency,ipc,filename,note='',blackhole=False):
    for name in names.split():
        fixed[name]=dict(latency=latency,ipc=ipc,source=source((BH if blackhole else WH)/filename),note=note)
group('MVMUL DOTPV GAPOOL ELWMUL GMPOOL ELWADD ELWSUB','5','1','MatrixUnit.md','Per architectural instruction; fidelity phases and destination hazards are additional.')
group('SETRWC INCRWC CLEARDVALID CLREXPHIST GATESRCRST SHIFTXA ZEROACC ZEROSRC TRNSPSRCB','1','1','MatrixUnit.md')
group('SHIFTXB','2','0.5','MatrixUnit.md')
group('MOVD2A','2','1','MOVD2A.md','Only MOVD2A/MOVB2A can follow on next cycle.')
group('MOVD2B','4','1','MOVD2B.md','Next three cycles accept only MOVD2B; 4 derived from scheduling restriction.')
group('MOVA2D MOVDBGA2D MOVB2D MOVB2A','4','1','MatrixUnit.md','Consumer-specific interlocks; see individual scheduling pages.')
group('DMANOP SETDMAREG','1','1','ScalarUnit.md','Shared nonpipelined unit; thread continuation and result visibility are separate.')
group('REG2FLOP FLUSHDMA','>=2','<=0.5','ScalarUnit.md','May block for completion conditions.')
group('ADDDMAREG SUBDMAREG MULDMAREG CMPDMAREG BITWOPDMAREG SHIFTDMAREG','3 or 4','1/(3 or 4)','ScalarUnit.md','Operand mode/GPR grouping matters; issuing thread blocked.')
group('STOREIND STOREREG ATSWAP LOADIND LOADREG ATINCGET','>=3','<=1/3','ScalarUnit.md','Memory result/visibility can occur later than unit occupancy.')
group('ATCAS ATINCGETPTR','>=15','<=1/15','ScalarUnit.md','Conditional waits can be unbounded.')
group('SETADC SETADCXY SETADCXX SETADCZW INCADCXY INCADCZW ADDRCRXY ADDRCRZW SETDVALID NOP','1','1/thread','MiscellaneousUnit.md')
group('ATGETM ATRELM','1','up to 3 distinct mutexes','SyncUnit.md','ATGETM waits for ownership before admission.',True)
group('SEMINIT SEMPOST SEMGET STALLWAIT SEMWAIT STREAMWAIT','1','1 shared','SyncUnit.md','Wait condition can take arbitrary time; wait gate release lag is additional.',True)
group('SETC16','1','3 (one/thread)','ConfigurationUnit.md','Separate ThreadConfig IPC group.',True)
group('WRCFG','2','1','ConfigurationUnit.md','Config IPC group shared with MMIO.',True)
group('RDCFG','>=2','1','ConfigurationUnit.md','GPR contention can extend completion.',True)
group('RMWCIB0 RMWCIB1 RMWCIB2 RMWCIB3','1','1','ConfigurationUnit.md','RMWCIB opcode aliases; Config IPC group.',True)
group('STREAMWRCFG','>=5','1','ConfigurationUnit.md','Config pipeline ordering/starvation matters.',True)
group('CFGSHIFTMASK','2','0.5','ConfigurationUnit.md','Config IPC group.',True)
variable={
 'UNPACR':'At least 2 address-generation cycles; data/format/throttle/ownership dependent. UNPACR_NOP is a mode of this opcode; nop occupancy 1.',
 'PACR':'Variable data/format/packer/Dst/L1 service; at most one command starts per cycle, admission is not completion.',
 'PACR_SETREG':'Sequenced packer-side register write; visibility after earlier pack late conversion; no universal completion constant.',
 'XMOV':'Variable length and L1 contention; do not use historical failed readback as measurement.',
 'MOP':'Expand configured microprogram, one downstream instruction/cycle subject to backpressure; no single opcode latency.',
 'MOP_CFG':'Frontend configuration; timing not separately calibrated.',
 'REPLAY':'Execute N entries at one/cycle before downstream stalls; record-only consumes command plus N entries; no transition penalty.',
 'SFPLOADMACRO':'Load latency 1; subsequent subunit events follow configured delays and have no automatic dependency interlocks.',
 'RESOURCEDECL':'Resource tracking declaration; no isolated cycle calibration.'}
records=[]
for name,body in zip(parts[1::2],parts[2::2]):
    op=re.search(r'^\s+op_binary:\s*(\S+)',body,re.M)
    unit=re.search(r'^\s+ex_resource:\s*(\S+)',body,re.M)
    canonical='SFPSTOCHRND' if name=='SFP_STOCH_RND' else name
    variants=[x for x in modes if x['instruction']==canonical]
    rec=dict(instruction=name,canonical=canonical,opcode=op[1] if op else None,
             encoder_resource=unit[1] if unit else None,encoding_source=source(yaml))
    if variants:
        rec.update(status='documented modes', timing=variants,
                   note='Read individual instruction scheduling rules; result latency is not general consumer visibility.')
    elif name in fixed: rec.update(status='documented unit/scheduling rule',timing=[fixed[name]])
    elif name in variable: rec.update(status='variable or not calibrated',timing=[],note=variable[name])
    else: rec.update(status='unknown/uncharacterized',timing=[],note='Do not assign 1 cycle by default. Decode semantics/architecture support before timing.')
    records.append(rec)
write_json('instruction-timing.json',dict(architecture='Blackhole',date='2026-09-09',instructions=records))
lines=['# Complete compiler opcode timing coverage','',
       'All 134 top-level entries in the local Blackhole assembly YAML. Encoding presence does not prove useful semantics or valid architecture support. `unknown` is intentional. IPC belongs to the unit, not the RISC issue path. Full mode data: [instruction-timing.json](instruction-timing.json).','',
       '| Instruction | Opcode | Encoder resource | Documented latency / IPC | Evidence or gap |','|---|---|---|---|---|']
for r in records:
    timing=r['timing']; pairs=list(dict.fromkeys(f"{v['latency']} / {v['ipc']}" for v in timing))
    p=ROOT/timing[0]['source'] if timing else yaml
    note=r.get('note',timing[0].get('note','') if timing else '')
    lines.append(f"| `{r['instruction']}` | `{r['opcode']}` | {r['encoder_resource']} | {'; '.join(pairs) if pairs else '**unknown / variable**'} | [{r['status']}]({rel(p)}). {note} |")
(HERE/'instruction-catalog.md').write_text('\n'.join(lines)+'\n')

# Preserve tables with their original headers and labels, never convert their
# adjusted-cycle columns into opcode latencies. Include NoC/DRAM scenario tables.
reports=sorted((HERE/'evidence/historical').glob('*.md'))
reports+=sorted((ROOT/'boop-docs/microbenching/docs').rglob('*.md'))
reports+=sorted((ROOT/'blackhole-py/tests/operation_pocs').glob('*/results.md'))
reports += [ROOT/'boop-docs/microbenching/status.md']
tables=[]
for path in reports:
    lines=path.read_text().splitlines(); heading='';i=0
    while i<len(lines):
        line=lines[i]
        if line.startswith('#'): heading=line.lstrip('# ')
        if line.startswith('|') and i+1<len(lines) and re.match(r'^\|[ :|\-]+\|\s*$',lines[i+1]):
            header=[s.strip() for s in line.strip('|').split('|')]
            start=i;i+=2;rows=[]
            while i<len(lines) and lines[i].startswith('|'):
                rows.append((i+1,[s.strip() for s in lines[i].strip('|').split('|')]));i+=1
            if re.search(r'cyc|latency|throughput|bandwidth|B/c|cost|\bus\b|\bns\b',line,re.I):
                tables.append(dict(source=source(path),line=start+1,heading=heading,header=header,rows=rows))
        else:i+=1
with (HERE/'measurement-tables.csv').open('w',newline='') as f:
    w=csv.writer(f);w.writerow(['source','source_line','section','headers_json','values_json'])
    for table in tables:
        for line,cells in table['rows']:
            w.writerow([table['source'],line,table['heading'],json.dumps(table['header']),json.dumps(cells)])

# Structured case records retain raw samples, controls and modifiers. Parent
# context stays in source JSON and is referenced, not repeated thousands of times.
case_files=[
 'sfpu_math/final-results.json','sfpu_movement/final-results.json','fpu/measurements.json',
 'transport/final-sweep.json','transport/final-edges.json','runtime/evidence/measurements.json']
count=0
with (HERE/'measurement-records.jsonl').open('w') as out:
    for name in case_files:
        path=ROOT/'blackhole-py/tests/operation_pocs'/name
        obj=json.loads(path.read_text())
        key='records' if isinstance(obj,dict) and 'records' in obj else 'cases' if isinstance(obj,dict) else None
        rows=obj[key] if key else obj
        if isinstance(rows,dict): iterator=rows.items()
        else: iterator=enumerate(rows)
        for i,row in iterator:
            out.write(json.dumps(dict(source=source(path),json_pointer=f'/{key}/{i}' if key else f'/{i}',record=row))+'\n');count+=1

# A source manifest catches drift between this document and later kernel edits.
paths=set(reports+[yaml,BH/'VectorUnit.md'])
paths.update(ROOT/'blackhole-py/tests/operation_pocs'/n for n in case_files)
paths.update((BH).glob('*.md'))
paths.update((WH).glob('*.md'))
paths.update((ISA/'BlackholeA0/TensixTile/BabyRISCV').glob('*.md'))
paths.add(ROOT/'blackhole-py/tests/timing/test_instruction_timing.py')
manifest=[]
for p in sorted(paths):manifest.append(dict(path=source(p),sha256=sha(p),bytes=p.stat().st_size))
revisions={}
for repo in ('boop-docs','blackhole-py','tt-isa-documentation','tt-llk','tt-metal','tt-ins-docs','ttsim','sfpi'):
    result=subprocess.run(['git','-C',str(ROOT/repo),'rev-parse','HEAD'],capture_output=True,text=True)
    revisions[repo]=result.stdout.strip() if result.returncode==0 else None
write_json('sources.json',dict(date='2026-09-09',heads=revisions,files=manifest,
    historical_recovery=dict(repository='blackhole-py',commit=subprocess.check_output(['git','-C',str(ROOT/'blackhole-py'),'rev-parse','aa8a402'],text=True).strip(),original_prefix='microbenching/docs/'),
    note='HEAD plus file hash identifies dirty source. Recovered markdown is verbatim and its old relative links are not rewritten.'))

index=['# Measurement evidence index','',f'{len(tables)} timing tables / {sum(len(t["rows"]) for t in tables)} rows in [measurement-tables.csv](measurement-tables.csv); {count} structured case/interval records in [measurement-records.jsonl](measurement-records.jsonl). These include historical/adjusted/baseline/control records, not that many independent validated opcode measurements.','',
       'CSV preserves units, section and row labels. JSONL preserves raw samples and source JSON pointers; consult parent source context for firmware/job identity. Never pool cards, modes, partial intervals or controls automatically. Source hashes and repository revisions: [sources.json](sources.json).','',
       '| Report | Tables | Timing rows |','|---|---:|---:|']
for p in reports:
    ts=[t for t in tables if t['source']==source(p)]
    if ts:index.append(f'| [{source(p)}]({rel(p)}) | {len(ts)} | {sum(len(t["rows"]) for t in ts)} |')
index+=['','## Structured operation evidence','']
for n in case_files:
    p=ROOT/'blackhole-py/tests/operation_pocs'/n
    index.append(f'- [{n}]({rel(p)})')
index+=['','## LLK performance CSVs','',
 'These retain whole-kernel/phase markers and format/fidelity/tile-count context. Architecture/run metadata is not always self-contained. They are indexed separately and are not imported as Blackhole opcode latencies.','']
for p in sorted((ROOT/'tt-llk/perf_data').rglob('*.csv')):
    index.append(f'- [{source(p)}]({rel(p)})')
(HERE/'evidence-index.md').write_text('\n'.join(index)+'\n')
print(f'{len(records)} opcodes, {len(modes)} SFPU mode rows, {len(tables)} tables, {count} structured records')
