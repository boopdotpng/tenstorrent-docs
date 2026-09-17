


def forward(self, L_x_ : torch.Tensor, L_w_ : torch.Tensor):
    l_x_ = L_x_
    l_w_ = L_w_
    rms_norm = torch.rms_norm(l_x_, (128,), l_w_, 1e-05);  l_x_ = l_w_ = None
    return (rms_norm,)
    