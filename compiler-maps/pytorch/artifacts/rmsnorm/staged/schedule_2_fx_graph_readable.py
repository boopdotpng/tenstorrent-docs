class <lambda>(torch.nn.Module):
    def forward(self, arg0_1: "f32[8, 128]", arg1_1: "f32[8, 1]", arg2_1: "f32[128]"):
        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:73 in <lambda>, code: out_part = torch.compile(lambda a, b, c: a * b * c, backend=backend, fullgraph=True)
        mul: "f32[8, 128]" = torch.ops.aten.mul.Tensor(arg0_1, arg1_1);  arg0_1 = arg1_1 = None
        mul_1: "f32[8, 128]" = torch.ops.aten.mul.Tensor(mul, arg2_1);  mul = arg2_1 = None
        return (mul_1,)
