


def forward(self, L_y_ : torch.Tensor):
    l_y_ = L_y_
    cos = l_y_.cos();  l_y_ = None
    return (cos,)
    