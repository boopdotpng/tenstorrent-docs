#!/usr/bin/env python3
"""CPU-only installed-wheel probe; never imports/builds the source checkout."""
import json
import os
from pathlib import Path
import re
import shutil
import tempfile

OUT = Path(__file__).resolve().parents[1] / 'artifacts' / 'rmsnorm'
OUT.mkdir(parents=True, exist_ok=True)
os.environ['CUDA_VISIBLE_DEVICES'] = ''
os.environ['TORCHINDUCTOR_CACHE_DIR'] = tempfile.mkdtemp(prefix='boop-torch-probe-')
os.environ['TORCHINDUCTOR_FORCE_DISABLE_CACHES'] = '1'
os.environ['TORCH_COMPILE_DEBUG'] = '1'
os.environ['TORCH_COMPILE_DEBUG_DIR'] = str(OUT / 'debug')
import torch
from torch._inductor import metrics
from torch._inductor.compile_fx import compile_fx
from torch._inductor.utils import run_and_get_code

torch.manual_seed(20260917)
torch.set_num_threads(2)

def rms(x, w):
    return x * torch.rsqrt(x.square().mean(-1, keepdim=True) + 1e-5) * w

def native(x, w):
    return torch.nn.functional.rms_norm(x, (x.shape[-1],), w, eps=1e-5)

def residual(x, w, r):
    return rms(x + r, w)

def matmul(x, w, m):
    return rms(x, w) @ m

def mutate(x, w):
    v = x.view(8, 128)
    v.add_(0.25)
    return rms(v, w)

x, w = torch.randn(8, 128), torch.randn(128)
r, m = torch.randn_like(x), torch.randn(128, 64)
cases = [('decomposed', rms, (x, w), False), ('native', native, (x, w), False),
         ('residual', residual, (x, w, r), False), ('matmul', matmul, (x, w, m), False),
         ('backward', rms, (x, w), True), ('view_mutation', mutate, (x, w), False),
         ('strided', rms, (torch.randn(128, 8).t(), w), False),
         ('staged', rms, (x, w), False)]
report = {'torch_version': torch.__version__, 'torch_git': torch.version.git_version,
          'torch_file': torch.__file__, 'device': 'cpu', 'dtype': 'float32',
          'shape': [8, 128], 'threads': 2, 'cases': {}}
for name, fn, inputs, backward in cases:
    torch._dynamo.reset()
    metrics.reset()
    case = OUT / name
    case.mkdir(exist_ok=True)
    def copies():
        return tuple(t.detach().clone(memory_format=torch.preserve_format).requires_grad_(backward) for t in inputs)
    eager_inputs, compiled_inputs = copies(), copies()
    with torch.profiler.profile(activities=[torch.profiler.ProfilerActivity.CPU]) as prof:
        expected = fn(*eager_inputs)
        if backward:
            expected.sum().backward()
    eager_ops = {e.key: e.count for e in prof.key_averages() if e.key.startswith('aten::')}
    graphs = []
    def backend(gm, example_inputs):
        graphs.append(gm.code)
        (case / f'dynamo_{len(graphs)}.py').write_text(gm.code)
        return compile_fx(gm, example_inputs)
    if name == 'staged':
        mean_part = torch.compile(lambda a: a.square().mean(-1, keepdim=True), backend=backend, fullgraph=True)
        scale_part = torch.compile(lambda a: torch.rsqrt(a + 1e-5), backend=backend, fullgraph=True)
        out_part = torch.compile(lambda a, b, c: a * b * c, backend=backend, fullgraph=True)
        def compiled(a, b):
            return out_part(a, scale_part(mean_part(a)), b)
    else:
        compiled = torch.compile(fn, backend=backend, fullgraph=True)
    def execute():
        result = compiled(*compiled_inputs)
        if backward:
            result.sum().backward()
        return result
    previous_schedules = set((OUT / "debug").rglob("ir_pre_fusion.txt"))
    actual, codes = run_and_get_code(execute)
    new_schedules = sorted(set((OUT / "debug").rglob("ir_pre_fusion.txt")) - previous_schedules)
    for index, schedule in enumerate(new_schedules):
        for filename in ("ir_pre_fusion.txt", "ir_post_fusion.txt", "fx_graph_readable.py", "fx_graph_transformed.py"):
            shutil.copy2(schedule.parent / filename, case / f"schedule_{index}_{filename}")
    for index, code in enumerate(codes):
        (case / f'generated_{index}.py').write_text(code)
    torch.testing.assert_close(actual, expected, atol=2e-5, rtol=2e-5)
    for got, want in zip(compiled_inputs, eager_inputs):
        torch.testing.assert_close(got, want)
        if backward:
            torch.testing.assert_close(got.grad, want.grad, atol=3e-5, rtol=3e-5)
    # Independent float64 formula (native and decomposed use the same epsilon).
    if name in ('decomposed', 'native', 'strided'):
        xx, ww = (t.double() for t in inputs)
        reference = xx / ((xx * xx).sum(-1, keepdim=True) / xx.shape[-1] + 1e-5).sqrt() * ww
        torch.testing.assert_close(actual.double(), reference, atol=2e-5, rtol=2e-5)
    invocation_lines = [line.strip() for code in codes for line in code.splitlines()
                        if re.match(r'\s*(cpp_fused_\w+\(|extern_kernels\.\w+\()', line)]
    report['cases'][name] = {'passed': True, 'dynamo_graphs': len(graphs),
        'generated_kernel_count': metrics.generated_kernel_count,
        'generated_cpp_vec_kernel_count': metrics.generated_cpp_vec_kernel_count,
        'ir_nodes_pre_fusion': metrics.ir_nodes_pre_fusion,
        'wrapper_invocations': invocation_lines, 'eager_aten_events': eager_ops,
        'max_abs_error': (actual - expected).abs().max().item(),
        'backward_checked': backward, 'input_mutations_checked': True}
    print(name, report['cases'][name], flush=True)

# Counting backend measures Dynamo graph submissions, NOT generated kernels.
def count_experiment(dynamic):
    torch._dynamo.reset()
    submitted = []
    def counting(gm, inputs):
        submitted.append(gm.code)
        return gm.forward
    def scaled(x, scale):
        return x.sin() * scale
    opt = torch.compile(scaled, backend=counting, dynamic=dynamic, fullgraph=True)
    history = []
    for size, scale in [(8, 2), (8, 2), (12, 2), (12, 3), (8, 2)]:
        arg = torch.randn(size, 16)
        torch.testing.assert_close(opt(arg, scale), scaled(arg, scale))
        history.append({'shape': [size, 16], 'scale': scale, 'submissions': len(submitted)})
    return history
report['guards_static'] = count_experiment(False)
report['guards_dynamic'] = count_experiment(True)

torch._dynamo.reset()
submissions = []
def counting(gm, inputs):
    submissions.append(gm.code)
    return gm.forward

def broken(x):
    y = x.sin()
    torch._dynamo.graph_break()
    return y.cos()
opt = torch.compile(broken, backend=counting)
arg = torch.randn(8)
torch.testing.assert_close(opt(arg), broken(arg))
report['graph_break'] = {'submissions': len(submissions)}
for index, graph in enumerate(submissions):
    (OUT / f'graph_break_{index}.py').write_text(graph)
torch._dynamo.reset()
try:
    torch.compile(broken, backend=counting, fullgraph=True)(arg)
except torch._dynamo.exc.Unsupported as exc:
    report['graph_break']['fullgraph_exception'] = type(exc).__name__
    (OUT / 'fullgraph_error.txt').write_text(str(exc))
else:
    raise AssertionError('fullgraph accepted an explicit graph break')
(OUT / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
shutil.rmtree(OUT / 'debug')
print(json.dumps(report, indent=2))
