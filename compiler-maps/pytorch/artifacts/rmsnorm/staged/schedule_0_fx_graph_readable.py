class <lambda>(torch.nn.Module):
    def forward(self, arg0_1: "f32[8, 128]"):
        # File: /home/boop/tenstorrent/boop-docs/compiler-maps/pytorch/probes/rmsnorm_cpu.py:71 in <lambda>, code: mean_part = torch.compile(lambda a: a.square().mean(-1, keepdim=True), backend=backend, fullgraph=True)
        pow_1: "f32[8, 128]" = torch.ops.aten.pow.Tensor_Scalar(arg0_1, 2);  arg0_1 = None
        mean: "f32[8, 1]" = torch.ops.aten.mean.dim(pow_1, [-1], True);  pow_1 = None
        return (mean,)
