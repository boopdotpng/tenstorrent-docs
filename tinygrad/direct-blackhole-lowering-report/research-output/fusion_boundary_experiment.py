#!/usr/bin/env python3
"""Host-only call-partition experiment for the bundled Llama block.

This script constructs lazy PYTHON-device graphs and never realizes a Tensor.
It monkeypatches only the two explicit CONTIGUOUS sites in FFNBlock to measure
what current Tinygrad's callify/rangeify scheduler does with those boundaries.
"""
from __future__ import annotations
import sys
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tinygrad"))
sys.path.insert(0, str(ROOT / "uop-dumps"))

from tinygrad import Tensor, UOp, function
from tinygrad.callify import transform_to_call
from tinygrad.schedule.rangeify import get_kernel_graph
from tinygrad.schedule import create_schedule
from tinygrad.uop.ops import Ops
import tinygrad.llm.model as model
import generate_uop_dumps as dumps

ORIG_FF = model.FFNBlock._feed_forward
ORIG_CALL = model.FFNBlock.__call__


def no_gate_contiguous(self, x: Tensor) -> Tensor:
  assert not hasattr(self, "ffn_gate_exps")
  return self.ffn_down(self.ffn_gate(x).silu() * self.ffn_up(x))


def make_call(outer_contiguous: bool):
  def patched_call(self, x: Tensor, start_pos: int|UOp):
    self._init_state(x)
    @function(precompile=True, allow_implicit=True)
    def _run(x: Tensor, start_pos: int|UOp):
      h = x + self._attention(self.attn_norm(x), start_pos)
      out = h + self._feed_forward(self.ffn_norm(h))
      return out.contiguous() if outer_contiguous else out
    return _run(x, start_pos)
  return patched_call


def inspect_variant(name: str, gate_contiguous: bool, outer_contiguous: bool):
  model.FFNBlock._feed_forward = ORIG_FF if gate_contiguous else no_gate_contiguous
  model.FFNBlock.__call__ = ORIG_CALL if outer_contiguous else make_call(False)
  output = dumps.llama32_1b_block_decode()
  shaped = UOp.sink(output.uop)
  callified, _ = transform_to_call(shaped)
  graph = get_kernel_graph(callified.src[0])
  # Public final schedule recursively resolves the precompiled FUNCTION/CALL.
  output_final = dumps.llama32_1b_block_decode()
  scheduled, _ = output_final.linear_with_vars()
  calls = list(scheduled.src)
  sizes = []
  summaries = []
  for call in calls:
    ast = call.src[0]
    counts = Counter(x.op.name for x in ast.toposort())
    out = next((p for p in ast.toposort() if p.op is Ops.PARAM), None)
    sizes.append(repr(out.dtype) if out is not None else "-")
    summaries.append("/".join(f"{op}:{counts[op]}" for op in ("REDUCE", "EXP2", "SQRT", "STORE") if counts[op]))
  print(f"{name}: calls={len(calls)} callified_CONTIGUOUS={sum(x.op is Ops.CONTIGUOUS for x in callified.src[0].toposort())}")
  print("  outputs=" + ", ".join(sizes))
  print("  kernels=" + ", ".join(summaries))


try:
  inspect_variant("baseline", True, True)
  inspect_variant("no_gate_contiguous", False, True)
  inspect_variant("no_outer_contiguous", True, False)
  inspect_variant("no_gate_or_outer_contiguous", False, False)
finally:
  model.FFNBlock._feed_forward = ORIG_FF
  model.FFNBlock.__call__ = ORIG_CALL
