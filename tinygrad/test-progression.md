# TT Backend: Test Progression (Low to High Complexity)

Reference for bringing up the Blackhole TT backend incrementally. Each level builds on the previous — don't move forward until all tests at the current level pass.

Run tests with: `TT=1 python -m pytest <test_file> -k <test_name> -x`

---

## Level 1: Tensor Construction (0 inputs, no compute)

**File:** `test/backend/test_ops.py`

```
test_zeros, test_ones, test_full, test_full_like
test_zeros_like, test_ones_like, test_empty_0
test_eye
```

**What's needed:** `TTRenderer.render()` must handle constant fills (no input buffers, just STORE a constant). `TTProgram.__call__()` must dispatch. Allocator copyin/copyout already works.

---

## Level 2: Elementwise Unary (1 input)

**File:** `test/backend/test_ops.py`

```
test_neg, test_abs, test_relu, test_relu_exact
test_sqrt, test_rsqrt, test_exp, test_exp2
test_log, test_log2, test_sin, test_cos
test_sign, test_floor, test_ceil, test_trunc
test_logical_not, test_cast
```

**What's needed:** Renderer emits SFPI for unary ops. Dataflow: 1 reader, 1 writer. Compute: `copy_tile(cb_in0, 0, 0)` → SFPI unary → `pack_tile(0, cb_out)`.

---

## Level 3: Elementwise Binary (2 inputs)

**File:** `test/backend/test_ops.py`

```
test_add, test_sub, test_mul, test_div
test_tiny_add, test_tiny_mul
test_add3, test_broadcasted_add, test_broadcasted_add_2
test_scalar_sub, test_scalar_mul, test_scalar_div
test_pow, test_maximum, test_minimum
test_where
test_cmp_eq, test_cmp_gt, test_cmp_lt, test_cmp_le, test_cmp_ge
test_mod
```

**What's needed:** 2-input dataflow, 2 `copy_tile` calls loading DST[0] and DST[1], SFPI binary op, broadcast handling.

---

## Level 4: Elementwise Activations & Transcendentals

**File:** `test/backend/test_ops.py`

These are combinations of the above — validates fused kernels:

```
test_sigmoid, test_tanh, test_gelu, test_silu, test_softplus
test_leaky_relu, test_celu, test_selu, test_elu, test_relu6
test_hardsigmoid, test_hardswish, test_mish
test_erf, test_asin, test_acos, test_atan
test_sinh, test_cosh, test_asinh, test_acosh, test_atanh
test_lerp
```

---

## Level 5: Movement / Shape Ops

**File:** `test/backend/test_ops.py`

```
test_reshape, test_view, test_flatten, test_unflatten
test_transpose, test_permute
test_squeeze, test_unsqueeze
test_expand
test_flip
test_cat, test_stack, test_repeat
test_slice_in_bounds_1dim, test_slice_in_bounds_multidim
test_pad, test_pad_reshape
```

**What's needed:** These may not generate TT compute kernels at all (handled by view/copy logic). But they test that the scheduler correctly handles TT buffer layouts.

---

## Level 6: Reductions

**File:** `test/backend/test_ops.py`

```
test_sum_simple, test_sum, test_sum_full
test_min, test_max
test_mean, test_mean_axis
test_prod
test_argmax, test_argmin
test_any, test_all
test_var, test_std
```

**What's needed:** Reduction compute kernels (accumulate across tiles). Padding values must be identity elements (see `reduction-padding-strategy.md`). Phase 2 territory — requires either pad-fill kernel or graph rewrite for non-zero identity values.

---

## Level 7: Softmax & Log-domain

**File:** `test/backend/test_ops.py`

```
test_softmax, test_log_softmax
test_softmax_other_axis, test_log_softmax_other_axis
test_logsumexp
```

**What's needed:** Fused reduction + elementwise. max-subtract-exp-sum-div pattern. Multi-kernel pipeline.

---

## Level 8: Matmul / GEMM

**File:** `test/backend/test_ops.py`

```
test_matmul_simple, test_matmul
test_dot, test_dot_1d
test_small_gemm, test_gemm
test_matmul_batched
test_einsum
```

**What's needed:** FPU matmul (not SFPI). `mm_block_init`, srcA/srcB loading, DEST accumulation. This is Phase 2+ — completely different compute kernel structure.

---

## Level 9: NN Layers

**File:** `test/backend/test_nn.py`

```
test_linear
test_batchnorm2d, test_batchnorm2d_training
test_layernorm, test_groupnorm, test_rmsnorm
test_conv2d, test_conv1d
test_embedding
test_lstm_cell
```

**What's needed:** All of the above working together. Conv requires im2col or direct conv kernel. BN/LN require reduction + elementwise fusion.

---

## Level 10: Optimizers (training works)

**File:** `test/backend/test_optim.py`

```
test_sgd, test_adam, test_adamw
test_sgd_wd, test_sgd_high_lr
test_multistep_sgd, test_multistep_adam
```

**What's needed:** Backward pass (autograd) generates correct gradients on TT. In-place buffer updates work.

---

## Level 11: MNIST Training (first real model)

**File:** `test/models/test_mnist.py`

```
test_sgd_onestep, test_sgd_threestep, test_sgd_sixstep
test_conv_onestep, test_conv
```

**File:** `test/models/test_end2end.py`

```
test_linear_mnist, test_conv_mnist
test_bn_mnist
```

**Milestone:** Loss decreases over training steps. Model learns something.

---

## Level 12: CIFAR Training

**File:** `test/null/test_real_world.py` (schedule check, no compute)

```
test_forward_cifar, test_train_cifar
```

Then actually train CIFAR with a ResNet — no existing accuracy test for this, write one:

```python
# Manual test: train ResNet on CIFAR-10, expect >70% accuracy after N epochs
```

**Milestone:** Conv + BN + residual connections + multi-class cross-entropy all work in a training loop.

---

## Level 13: JIT & Scheduling

**File:** `test/backend/test_jit.py`

```
test_simple_jit, test_simple_jit_reset
test_jit_multioutput_realize
test_free_intermediates
```

**File:** `test/backend/test_schedule.py`

```
test_softmax_fusion, test_layernorm_onelayer_fusion
test_multireduce_fusion_*
```

**What's needed:** Kernel fusion and JIT capture/replay work on TT. May require graph support.

---

## Level 14: GPT-2 Inference

**File:** `test/null/test_real_world.py` (schedule only)

```
test_gpt2
```

Then run actual GPT-2 inference:

```python
# Manual test: load GPT-2 weights, generate text, verify coherent output
from extra.models.gpt2 import GPT2
```

**Milestone:** Transformer attention + matmul + layernorm + softmax + embedding all work together. Text generation produces coherent output.

---

## Summary Table

| Level | Category | Key Tests | Phase |
|-------|----------|-----------|-------|
| 1 | Construction | `test_zeros`, `test_ones`, `test_full` | 1 |
| 2 | Unary elementwise | `test_neg`, `test_exp`, `test_sqrt` | 1 |
| 3 | Binary elementwise | `test_add`, `test_mul`, `test_where` | 1 |
| 4 | Activations | `test_sigmoid`, `test_gelu`, `test_tanh` | 1 |
| 5 | Movement/shape | `test_reshape`, `test_transpose`, `test_cat` | 1 |
| 6 | Reductions | `test_sum`, `test_max`, `test_mean` | 2 |
| 7 | Softmax | `test_softmax`, `test_log_softmax` | 2 |
| 8 | Matmul/GEMM | `test_matmul`, `test_gemm` | 2 |
| 9 | NN layers | `test_linear`, `test_conv2d`, `test_layernorm` | 2 |
| 10 | Optimizers | `test_sgd`, `test_adam` | 2 |
| 11 | MNIST training | `test_sgd_onestep`, `test_conv_mnist` | 2 |
| 12 | CIFAR training | ResNet on CIFAR-10 | 3 |
| 13 | JIT/scheduling | `test_simple_jit`, fusion tests | 3 |
| 14 | GPT-2 inference | Transformer end-to-end | 3 |
