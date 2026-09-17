


def forward(self, L_x_ : torch.Tensor, L_w_ : torch.Tensor):
    l_x_ = L_x_
    l_w_ = L_w_
    square = l_x_.square()
    mean = square.mean(-1, keepdim = True);  square = None
    add = mean + 1e-05;  mean = None
    rsqrt = torch.rsqrt(add);  add = None
    mul = l_x_ * rsqrt;  l_x_ = rsqrt = None
    mul_1 = mul * l_w_;  mul = l_w_ = None
    return (mul_1,)
    