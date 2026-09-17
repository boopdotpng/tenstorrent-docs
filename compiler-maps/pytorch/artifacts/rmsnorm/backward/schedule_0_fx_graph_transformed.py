class GraphModule(torch.nn.Module):
    def forward(self, primals_1: "f32[8, 128]", primals_2: "f32[128]", rsqrt: "f32[8, 1]", tangents_1: "f32[8, 128]"):
        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:26 in rms, code: return x * torch.rsqrt(x.square().mean(-1, keepdim=True) + 1e-5) * w
        mul: "f32[8, 128]" = torch.ops.aten.mul.Tensor(primals_1, rsqrt)
        mul_2: "f32[8, 128]" = torch.ops.aten.mul.Tensor(tangents_1, mul);  mul = None
        mul_3: "f32[8, 128]" = torch.ops.aten.mul.Tensor(tangents_1, primals_2);  tangents_1 = primals_2 = None
        sum_1: "f32[1, 128]" = torch.ops.aten.sum.dim_IntList(mul_2, [0], True);  mul_2 = None
        view: "f32[128]" = torch.ops.aten.reshape.default(sum_1, [128]);  sum_1 = None
        mul_4: "f32[8, 128]" = torch.ops.aten.mul.Tensor(mul_3, primals_1)
        mul_5: "f32[8, 128]" = torch.ops.aten.mul.Tensor(mul_3, rsqrt);  mul_3 = None
        sum_2: "f32[8, 1]" = torch.ops.aten.sum.dim_IntList(mul_4, [1], True);  mul_4 = None
        pow_2: "f32[8, 1]" = torch.ops.aten.pow.Tensor_Scalar(rsqrt, 3);  rsqrt = None
        mul_6: "f32[8, 1]" = torch.ops.aten.mul.Scalar(sum_2, -0.5);  sum_2 = None
        mul_7: "f32[8, 1]" = torch.ops.aten.mul.Tensor(mul_6, pow_2);  mul_6 = pow_2 = None
        expand: "f32[8, 128]" = torch.ops.aten.expand.default(mul_7, [8, 128]);  mul_7 = None
        div: "f32[8, 128]" = torch.ops.aten.div.Scalar(expand, 128);  expand = None
        pow_3: "f32[8, 128]" = torch.ops.aten.pow.Tensor_Scalar(primals_1, 1.0);  primals_1 = None
        mul_8: "f32[8, 128]" = torch.ops.aten.mul.Scalar(pow_3, 2.0);  pow_3 = None
        mul_9: "f32[8, 128]" = torch.ops.aten.mul.Tensor(div, mul_8);  div = mul_8 = None
        add_1: "f32[8, 128]" = torch.ops.aten.add.Tensor(mul_5, mul_9);  mul_5 = mul_9 = None
        return (add_1, view)
