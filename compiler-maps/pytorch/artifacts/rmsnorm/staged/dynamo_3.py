


def forward(self, L_a_ : torch.Tensor, L_b_ : torch.Tensor, L_c_ : torch.Tensor):
    l_a_ = L_a_
    l_b_ = L_b_
    l_c_ = L_c_
    mul = l_a_ * l_b_;  l_a_ = l_b_ = None
    mul_1 = mul * l_c_;  mul = l_c_ = None
    return (mul_1,)
    