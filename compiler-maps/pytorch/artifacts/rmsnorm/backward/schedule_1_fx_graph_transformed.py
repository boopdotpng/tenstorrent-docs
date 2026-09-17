class GraphModule(torch.nn.Module):
    def forward(self, primals_1: "f32[8, 128]", primals_2: "f32[128]"):
        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:26 in rms, code: return x * torch.rsqrt(x.square().mean(-1, keepdim=True) + 1e-5) * w
        pow_1: "f32[8, 128]" = torch.ops.aten.pow.Tensor_Scalar(primals_1, 2)
        mean: "f32[8, 1]" = torch.ops.aten.mean.dim(pow_1, [-1], True);  pow_1 = None
        add: "f32[8, 1]" = torch.ops.aten.add.Tensor(mean, 1e-05);  mean = None
        rsqrt: "f32[8, 1]" = torch.ops.aten.rsqrt.default(add);  add = None
        mul: "f32[8, 128]" = torch.ops.aten.mul.Tensor(primals_1, rsqrt)
        mul_1: "f32[8, 128]" = torch.ops.aten.mul.Tensor(mul, primals_2);  mul = None
        return (mul_1, primals_1, primals_2, rsqrt)
