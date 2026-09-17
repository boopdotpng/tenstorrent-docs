#!/usr/bin/env python3
"""CPU-only RMSNorm boundary probe for tinygrad 107adc3; run with --tinygrad /path/to/tinygrad.
Writes tensor DAGs, scheduled kernel DAGs, C source, buffer edges and checked results.
No timing claims. Input setup and output reads occur outside measured schedules.
"""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import platform
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--tinygrad', type=Path, required=True)
parser.add_argument('--out', type=Path, default=Path(__file__).with_name('rmsnorm-artifacts'))
args = parser.parse_args()
# Explicit defaults make reruns independent of an accelerator-oriented login environment.
for key in ('CPU', 'AMD', 'NV', 'CUDA', 'METAL', 'PYTHON', 'CPU_CC'): os.environ.pop(key, None)
os.environ.update(DEV='CPU', BEAM='0', NOOPT='0', SCACHE='0', VIZ='0', DEBUG='0')
sys.path.insert(0, str(args.tinygrad.resolve()))
import numpy as np
from tinygrad import Tensor
from tinygrad.engine.realize import lower_and_compile, run_linear
from tinygrad.device import Device
from tinygrad.uop.ops import Ops, UOp

args.out.mkdir(parents=True, exist_ok=True)

def dump_dag(root):
  nodes = list(root.toposort())
  ids = {u:i for i,u in enumerate(nodes)}
  return '\n'.join(f'{ids[u]:04} {u.op.name:12} {str(u.dtype):24} src={[ids[s] for s in u.src]} arg={u.arg!r}' for u in nodes)+'\n'

def ref_rms(x, w):
  # float64 accumulation/reference highlights float32 lowering error.
  v = x.astype(np.float64)
  return v / np.sqrt(np.mean(v*v, axis=-1, keepdims=True)+1e-5) * w.astype(np.float64)

class Probe:
  def __init__(self, name):
    self.path = args.out/name
    self.path.mkdir(exist_ok=True)
    self.record = {'name':name, 'phases':[], 'checks':[]}
    self.buffers = {}
  def label(self, t, name): self.buffers[t.uop.buf_uop] = name
  def buffer(self, u):
    b = u.buf_uop
    if b not in self.buffers: self.buffers[b] = f'temp{len(self.buffers)}'
    return {'id':self.buffers[b], 'elements':b.numel(), 'dtype':str(b.dtype)}
  def run(self, phase, *outputs):
    (self.path/f'{phase}.tensor.txt').write_text(dump_dag(UOp.sink(*[t.uop for t in outputs])))
    # schedule_linear mutates Tensor graphs to storage: execute THIS returned LINEAR.
    linear = outputs[0].schedule_linear(*outputs[1:])
    compiled = lower_and_compile(linear)
    assert len(linear.src) == len(compiled.src), "compilation changed call count; update artifact pairing"
    rec = {'phase':phase, 'compute_kernels':0, 'non_compute_calls':[], 'kernels':[]}
    for i,(call,progcall) in enumerate(zip(linear.src, compiled.src)):
      if progcall.body.op is not Ops.PROGRAM:
        rec['non_compute_calls'].append(progcall.body.op.name)
        continue
      rec['compute_kernels'] += 1
      prg = progcall.body
      bufs = [self.buffer(u) for u in call.src[1:]]
      info = prg.arg
      kernel = {'index':i, 'name':prg.src[0].arg.name, 'buffers':bufs,
                'outputs':[bufs[j]['id'] for j in info.outs], 'inputs':[bufs[j]['id'] for j in info.ins],
                'ast_ops':dict(sorted(Counter(u.op.name for u in call.body.toposort()).items())),
                'linear_ops':dict(sorted(Counter(u.op.name for u in prg.src[1].src).items())),
                'opts':repr(prg.src[0].arg.applied_opts)}
      rec['kernels'].append(kernel)
      (self.path/f'{phase}.k{i}.ast.txt').write_text(dump_dag(call.body))
      (self.path/f'{phase}.k{i}.c').write_text(next(u.arg for u in prg.src if u.op is Ops.SOURCE))
    run_linear(compiled, wait=True)
    self.record['phases'].append(rec)
  def check(self, t, ref, label):
    actual = t.numpy().astype(np.float64)
    np.testing.assert_allclose(actual, ref, rtol=2e-5, atol=2e-5)
    self.record['checks'].append({'output':label, 'shape':list(actual.shape), 'max_abs_error':float(np.max(np.abs(actual-ref))),
                                  'rmse':float(np.sqrt(np.mean((actual-ref)**2))), 'rtol':2e-5, 'atol':2e-5})
  def finish(self):
    self.record['compute_kernels'] = sum(p['compute_kernels'] for p in self.record['phases'])
    (self.path/'schedule.json').write_text(json.dumps(self.record, indent=2)+'\n')
    return self.record

def rms(x,w): return x*((x*x).mean(-1,keepdim=True)+1e-5).rsqrt()*w

records=[]
cases = ['rms_lazy','rms_staged','residual_lazy','residual_materialized','matmul_lazy','matmul_materialized',
         'row_sum_lazy','row_sum_materialized','fanout','odd_width','wide_row']
for name in cases:
  shape = (4,127) if name=='odd_width' else (1,4096) if name=='wide_row' else (4,128)
  rng=np.random.default_rng(20260917)
  xn=rng.normal(size=shape).astype(np.float32)
  # Include an almost-zero row, testing eps rather than only ordinary values.
  xn[0] *= np.float32(1e-4)
  wn=rng.uniform(.5,1.5,size=shape[-1]).astype(np.float32)
  rn=rng.normal(size=shape).astype(np.float32)
  an=rng.normal(size=(shape[-1],32)).astype(np.float32)
  p=Probe(name)
  x=Tensor(xn,device='CPU').realize(); w=Tensor(wn,device='CPU').realize()
  p.label(x,'x'); p.label(w,'weight')
  p.record.update(shape=list(shape), dtype='float32', eps=1e-5)
  if name=='rms_staged':
    sq=x*x; p.run('square',sq)
    mean=sq.mean(-1,keepdim=True); p.run('mean',mean)
    scale=(mean+1e-5).rsqrt(); p.run('scale',scale)
    norm=x*scale; p.run('normalize',norm)
    y=norm*w; p.run('weight',y)
    p.check(y,ref_rms(xn,wn),'y')
  elif name.startswith('residual'):
    r=Tensor(rn,device='CPU').realize(); p.label(r,'residual')
    z=x+r
    if name.endswith('materialized'): p.run('residual_add',z)
    y=rms(z,w); p.run('output',y)
    p.check(y,ref_rms((xn+rn).astype(np.float32),wn),'y')
  elif name.startswith('matmul'):
    a=Tensor(an,device='CPU').realize(); p.label(a,'matrix')
    y=rms(x,w)
    if name.endswith('materialized'): p.run('rms',y)
    z=y@a; p.run('consumer',z)
    p.check(z,ref_rms(xn,wn)@an.astype(np.float64),'matmul')
  elif name.startswith('row_sum'):
    y=rms(x,w)
    if name.endswith('materialized'): p.run('rms',y)
    z=y.sum(-1); p.run('consumer',z)
    p.check(z,ref_rms(xn,wn).sum(-1),'row_sum')
  elif name=='fanout':
    y=rms(x,w); z=y.sum(-1)
    p.run('both',y,z)
    p.check(y,ref_rms(xn,wn),'y'); p.check(z,ref_rms(xn,wn).sum(-1),'row_sum')
  else:
    y=rms(x,w); p.run('output',y); p.check(y,ref_rms(xn,wn),'y')
  records.append(p.finish())
  print(name, records[-1]['compute_kernels'], [c['max_abs_error'] for c in records[-1]['checks']])
summary={'tinygrad_commit':subprocess.check_output(['git','-C',str(args.tinygrad),'rev-parse','HEAD'],text=True).strip(),
         'python':sys.version.split()[0], 'numpy':np.__version__, 'platform':platform.platform(),
         'renderer':type(Device['CPU'].renderer).__name__, 'environment':{k:os.environ[k] for k in ('DEV','BEAM','NOOPT','SCACHE')},
         'seed':20260917, 'count_definition':'PROGRAM calls in explicitly recorded phases; excludes input creation/transfers and output numpy reads',
         'cases':records}
(args.out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
