


def forward(self, L_x_ : torch.Tensor, L_r_ : torch.Tensor, L_w_ : torch.Tensor):
    l_x_ = L_x_
    l_r_ = L_r_
    l_w_ = L_w_
    add = l_x_ + l_r_;  l_x_ = l_r_ = None
    square = add.square()
    mean = square.mean(-1, keepdim = True);  square = None
    add_1 = mean + 1e-05;  mean = None
    rsqrt = torch.rsqrt(add_1);  add_1 = None
    mul = add * rsqrt;  add = rsqrt = None
    mul_1 = mul * l_w_;  mul = l_w_ = None
    return (mul_1,)
    