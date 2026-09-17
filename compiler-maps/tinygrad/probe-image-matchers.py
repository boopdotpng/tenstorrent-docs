#!/usr/bin/env python3
"""CPU-only UOp probes; no Device/renderer backend initialization or GPU compilation."""
import argparse
import json
import os
from pathlib import Path
import struct
import sys

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--tinygrad', type=Path, required=True)
p.add_argument('--out', type=Path, default=Path(__file__).with_name('image-matcher-probes.json'))
a = p.parse_args()
os.environ.update(DEV='NULL', BEAM='0', VIZ='0', DEBUG='0')
sys.path.insert(0, str(a.tinygrad.resolve()))
from tinygrad.codegen.late.coalesce import indexing_simplify, memory_coalescing, pm_simplify_add_image, image_valid_dims
from tinygrad.codegen.late.gater import pm_move_gates_from_index
from tinygrad.dtype import dtypes
from tinygrad.helpers import Context, Target
from tinygrad.renderer import Renderer
from tinygrad.uop.ops import UOp, Ops, graph_rewrite
from tinygrad.uop.symbolic import sym

results = {}
ren = Renderer(Target('CL', arch='IMAGE_PITCH_ALIGNMENT=64'))
with Context(IMAGE=1):
  # A complete four-lane load must exist BEFORE the image promotion matcher runs.
  b = UOp.param(0, dtypes.float, 1024)
  r = UOp.variable('pixel', 0, 255, param=True)
  original = UOp.sink(*[b.index(r*4+i).load() for i in range(4)])
  coalesced = memory_coalescing(original, ren)
  promoted = graph_rewrite(coalesced, pm_simplify_add_image, ctx=({}, ren), bottom_up=True)
  images = [u for u in promoted.toposort() if u.op is Ops.PARAM and u.arg.image]
  assert len(images) == 1 and images[0].arg.image == (1, 256)
  assert sum(u.op is Ops.LOAD for u in promoted.toposort()) == 1
  results['coalesce_then_image'] = {'scalar_loads_before': 4, 'vector_loads_after': 1, 'image_hw': images[0].arg.image,
                                    'coordinates': 'x = pixel; y = 0; lane is pixel component'}
  # Different per-lane valid masks prohibit four-lane coalescing.
  lane_gated = UOp.sink(*[b.index((r*4+i).valid(r*4+i < 1023)).load() for i in range(4)])
  remain = graph_rewrite(memory_coalescing(lane_gated, ren), pm_simplify_add_image, ctx=({}, ren), bottom_up=True)
  assert not any(u.op is Ops.PARAM and u.arg.image for u in remain.toposort())
  results['lane_dependent_masks'] = {'image_promoted': False}
  # Identical syntactic predicate; different physical image heights change legality.
  x, y = UOp.special(32, 'gidx0'), UOp.special(32, 'gidx1')
  for height, expected in [(10, True), (20, False)]:
    img = UOp.param(0, dtypes.float, (height, 10, 4))
    load = img.index(y.valid(y < 10), x.valid(y < 10)).load()
    after = graph_rewrite(load, sym+indexing_simplify)
    dropped = after.src[0].src[1].get_valid() is UOp.const(True)
    assert dropped == expected
    gated = graph_rewrite(after, pm_move_gates_from_index)
    assert len(gated.src) == (1 if expected else 3)
    # Exhaust every coordinate in the constructed domain, including image OOB.
    for xx in range(32):
      for yy in range(32):
        read = 1 + xx + yy*10 if xx < 10 and yy < height else 0
        assert (read if yy < 10 else 0) == (read if dropped or yy < 10 else 0)
    results[f'mask_height_{height}'] = {'gate_dropped': dropped, 'load_source_count_after_gater': len(gated.src),
                                    'coordinate_cases_checked': 1024}
  # Pin a sharp edge: the current matcher erases half-rounding even with IMAGE=0.
  v = UOp.param(9, dtypes.float)
  cast_chain = v.cast(dtypes.half).cast(dtypes.float)
  with Context(IMAGE=0): assert graph_rewrite(cast_chain, pm_simplify_add_image) is v
  f32 = 1.0001
  f16_roundtrip = struct.unpack('e', struct.pack('e', f32))[0]
  assert f16_roundtrip != f32
  results['half_roundtrip_fold'] = {'active_even_with_IMAGE_0': True, 'input': f32, 'binary16_rounded_value': f16_roundtrip,
                                    'note': 'struct demonstrates rounding distinction; matcher probe checks structural rewrite only'}
  dims = image_valid_dims(dtypes.float, 16, 'IMAGE_PITCH_ALIGNMENT=64')
  assert dims == [(1, 4)]
  assert image_valid_dims(dtypes.float, 1024, '') == []
  assert image_valid_dims(dtypes.int, 1024, 'IMAGE_PITCH_ALIGNMENT=64') == []
  results['eligibility'] = {'float16_elements_hw': dims, 'without_pitch_alignment': [], 'integer_storage': []}
a.out.write_text(json.dumps(results, indent=2)+'\n')
print(f'{len(results)} probe groups passed; wrote {a.out}')
