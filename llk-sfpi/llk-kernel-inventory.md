# TT-LLK kernel inventory (repo scan)

This is a quick scan of the TT-LLK repo to summarize what kernel families and SFPU ops are implemented here, with a focus on traditional ML ops vs custom SFPI work.

## Where kernels live

- `tt_llk_blackhole/llk_lib` contains the LLK kernel families.
- SFPU op implementations live under `tt_llk_blackhole/common/inc/sfpu`.

## Core LLK kernel families (Blackhole)

These are the "traditional" compute/data-movement primitives that higher-level ops are built from:

- Matmul: `llk_math_matmul.h`
- Reductions: `llk_math_reduce.h`, `llk_math_reduce_custom.h`
- Elementwise: `llk_math_eltwise_unary_*`, `llk_math_eltwise_binary*`, `llk_math_eltwise_ternary*`
- Welford stats: `llk_math_welfords_sfpu.h`
- Transpose in dest: `llk_math_transpose_dest.h`
- Pack/unpack + layout transforms: `llk_pack*`, `llk_unpack*`, `llk_unpack_tilize.h`, `llk_unpack_untilize.h`, `llk_pack_untilize.h`, `llk_pack_rows.h`

## SFPU op catalog (Blackhole)

There are 54 SFPU op headers under `tt_llk_blackhole/common/inc/sfpu`:

abs, activations, add_int, add_top_row, binary, binary_bitwise, cast_fp32_to_fp16a, cdf, clamp, comp,
converter, cumsum, dropout, elu, ema, exp, exp2, fill, gelu, hardtanh, is_fp16_zero, isinf_isnan,
load_config, log, max, max_int32, max_pool_indices, mul_int, negative, polyval, quant, recip,
reduce, reduce_custom, relu, reshuffle_rows, rounding_ops, rsqrt, rsqrt_compat, shift, sigmoid, sign,
silu, sqrt, square, sub_int, tanh, tanh_derivative, threshold, topk, trigonometry, typecast, welfords, where

These cover most common ML unary/activation functions, compares, typecasts, and a few higher-level ops (topk, where, dropout).

## ML op buckets (Blackhole SFPU)

- Activations: relu, gelu, silu, sigmoid, tanh, tanh_derivative, hardtanh, threshold, activations
- Elementwise math: abs, negative, sign, square, sqrt, rsqrt, rsqrt_compat, recip, exp, exp2, log, trigonometry, cdf, polyval
- Comparisons/select: comp, where
- Reductions and stats: reduce, reduce_custom, max, max_int32, max_pool_indices, topk, welfords, cumsum, ema
- Quantization and type conversion: typecast, cast_fp32_to_fp16a, converter, quant, rounding_ops, shift
- Integer and bitwise ops: add_int, sub_int, mul_int, binary_bitwise
- Utility/data movement: fill, reshuffle_rows, add_top_row, load_config, isinf_isnan, is_fp16_zero, dropout

Common NN ops that map directly or compose from these:

- Softmax: exp + reduce + recip (plus binary ops for scale and normalization)
- LayerNorm/RMSNorm: welfords or reduce + rsqrt + mul/add
- GELU/SILU/Tanh families: native ops in SFPU
- Top-k / argmax-style flows: topk, max, max_pool_indices
- Dropout: dropout
- Type/quant flows: typecast + quant + rounding_ops

## How many “traditional ML ops” are supported?

- Core kernels: matmul, reduce, elementwise (unary/binary/ternary), Welford stats, transpose, plus pack/unpack/tilize/untilize.
- SFPU ops: 54 named SFPU operations on Blackhole.

If your ML op maps to these kernels or can be composed from unary/binary/ternary SFPU ops, you can stay in LLK. If it is not in the SFPU list or needs a new instruction sequence, you will need custom SFPI.
