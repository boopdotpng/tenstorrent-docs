class <lambda>(torch.nn.Module):
    def forward(self, arg0_1: "f32[8, 128]", arg1_1: "f32[8, 128]", arg2_1: "f32[128]"):
        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:32 in residual, code: return rms(x + r, w)
        add: "f32[8, 128]" = torch.ops.aten.add.Tensor(arg0_1, arg1_1);  arg0_1 = arg1_1 = None

        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:26 in rms, code: return x * torch.rsqrt(x.square().mean(-1, keepdim=True) + 1e-5) * w
        pow_1: "f32[8, 128]" = torch.ops.aten.pow.Tensor_Scalar(add, 2)
        mean: "f32[8, 1]" = torch.ops.aten.mean.dim(pow_1, [-1], True);  pow_1 = None
        add_1: "f32[8, 1]" = torch.ops.aten.add.Tensor(mean, 1e-05);  mean = None
        rsqrt: "f32[8, 1]" = torch.ops.aten.rsqrt.default(add_1);  add_1 = None
        mul: "f32[8, 128]" = torch.ops.aten.mul.Tensor(add, rsqrt);  add = rsqrt = None
        mul_1: "f32[8, 128]" = torch.ops.aten.mul.Tensor(mul, arg2_1);  mul = arg2_1 = None
        return (mul_1,)
