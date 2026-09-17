


def forward(self, L_a_ : torch.Tensor):
    l_a_ = L_a_
    add = l_a_ + 1e-05;  l_a_ = None
    rsqrt = torch.rsqrt(add);  add = None
    return (rsqrt,)
    