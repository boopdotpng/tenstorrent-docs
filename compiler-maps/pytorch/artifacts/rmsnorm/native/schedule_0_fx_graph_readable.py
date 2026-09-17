class <lambda>(torch.nn.Module):
    def forward(self, arg0_1: "f32[8, 128]", arg1_1: "f32[128]"):
        # File: /home/boop/tenstorrent/.venv/lib/python3.13/site-packages/torch/nn/functional.py:2954 in rms_norm, code: return torch.rms_norm(input, normalized_shape, weight, eps)
        pow_1: "f32[8, 128]" = torch.ops.aten.pow.Tensor_Scalar(arg0_1, 2)
        mean: "f32[8, 1]" = torch.ops.aten.mean.dim(pow_1, [1], True);  pow_1 = None
        add: "f32[8, 1]" = torch.ops.aten.add.Scalar(mean, 9.999999747378752e-06);  mean = None
        rsqrt: "f32[8, 1]" = torch.ops.aten.rsqrt.default(add);  add = None
        mul: "f32[8, 128]" = torch.ops.aten.mul.Tensor(arg0_1, rsqrt);  arg0_1 = rsqrt = None
        mul_1: "f32[8, 128]" = torch.ops.aten.mul.Tensor(mul, arg1_1);  mul = arg1_1 = None
        return (mul_1,)
