


def forward(self, L_x_ : torch.Tensor):
    l_x_ = L_x_
    y = l_x_.sin();  l_x_ = None
    return (y,)
    