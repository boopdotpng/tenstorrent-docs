


def forward(self, L_x_ : torch.Tensor, L_w_ : torch.Tensor):
    l_x_ = L_x_
    l_w_ = L_w_
    v = l_x_.view(8, 128);  l_x_ = None
    add_ = v.add_(0.25);  add_ = None
    square = v.square()
    mean = square.mean(-1, keepdim = True);  square = None
    add = mean + 1e-05;  mean = None
    rsqrt = torch.rsqrt(add);  add = None
    mul = v * rsqrt;  v = rsqrt = None
    mul_1 = mul * l_w_;  mul = l_w_ = None
    return (mul_1,)
    