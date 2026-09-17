class <lambda>(torch.nn.Module):
    def forward(self, arg0_1: "f32[8, 1]"):
        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:72 in <lambda>, code: scale_part = torch.compile(lambda a: torch.rsqrt(a + 1e-5), backend=backend, fullgraph=True)
        add: "f32[8, 1]" = torch.ops.aten.add.Tensor(arg0_1, 1e-05);  arg0_1 = None
        rsqrt: "f32[8, 1]" = torch.ops.aten.rsqrt.default(add);  add = None
        return (rsqrt,)
