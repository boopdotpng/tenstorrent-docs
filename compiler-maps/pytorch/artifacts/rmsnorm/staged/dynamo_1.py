


def forward(self, L_a_ : torch.Tensor):
    l_a_ = L_a_
    square = l_a_.square();  l_a_ = None
    mean = square.mean(-1, keepdim = True);  square = None
    return (mean,)
    