# Reduction padding strategies in tt-metal

How tt-metal handles tensors that don't evenly fill 32x32 tiles when running reduction operations (sum, max, min, mean). Two strategies exist: identity-element padding and binary masking.

## The problem

Tensors are tiled to 32x32. If the logical shape doesn't divide evenly by 32, some tile positions are "padding" — they contain data that should not affect the reduction result. The wrong padding value corrupts the output (e.g., `min([3, 5, 0_pad])` = 0, not 3).

## Identity element padding (generic reduce path)

The dominant strategy. Unfilled tile positions are filled with the reduction's **identity element** — the value that has no effect on the result.

| Reduction | Pad value | Why |
|---|---|---|
| sum | `0` | `x + 0 = x` |
| mean | `0` | zeros don't affect numerator; scaler handles denominator |
| max | `-inf` | `max(x, -inf) = x` |
| min | `+inf` | `min(x, +inf) = x` |

### Source: pad value selection

```cpp
// ttnn/cpp/ttnn/operations/reduction/generic/generic_reductions.cpp
float get_pad_value(ReduceType reduce_type) {
    return reduce_type == ReduceType::Max
               ? -std::numeric_limits<float>::infinity()
               : (reduce_type == ReduceType::Min
                      ? std::numeric_limits<float>::infinity()
                      : 0);
}
```

For the lower-level path (`reduce_op.cpp`):

```cpp
// ttnn/cpp/ttnn/operations/reduction/generic/device/reduce_op.cpp line 84
float pad_value = reduce_math == ReduceOpMath::MAX
    ? -std::numeric_limits<float>::infinity()
    : 0;
```

Note: MIN doesn't appear here because it's implemented differently (see below).

### When padding is applied

Two cases depending on tensor state:

**Case 1: Tensor is row-major (needs tilization).** The host calls `tilize_with_val_padding`, which tilizes and pads in one step:

```cpp
// reduce_op.cpp lines 99-101
auto padded_shape = pad_to_tile_shape(input_tensor.padded_shape());
auto tilized_input = ttnn::tilize_with_val_padding(
    input_tensor, padded_shape, pad_value, input_tensor.memory_config());
```

The device kernel (`reader_unary_pad_dims_split_rows.cpp`) writes the pad value into unfilled rows/columns of each tile.

**Case 2: Tensor is already tiled (on device).** Uses `fill_implicit_tile_padding` to write the pad value into the padding slots of existing tiles on-device:

```cpp
auto input_tensor = is_tiled
    ? ttnn::fill_implicit_tile_padding(input_tensor_arg, pad_value)
    : input_tensor_arg;
```

### Pad value encoding

The pad value is packed into a `uint32_t` for the device kernel. For bfloat16, two bf16 representations are packed into one uint32:

```cpp
// tilize_with_val_padding_factory_helper.cpp
if (tensor.dtype() == DataType::BFLOAT16) {
    bfloat16 bfloat_pad_value = bfloat16(pad_value);
    return pack_two_bfloat16_into_uint32({bfloat_pad_value, bfloat_pad_value});
}
```

## MIN = negate + MAX + negate

The hardware LLK only natively supports `PoolType::MAX` and `PoolType::SUM`. There is no native MIN reduce. tt-metal implements MIN as:

```
min(x) = -max(-x)
```

```cpp
// reduce_op.cpp lines 43-67
Tensor reduce_min(const Tensor& input_tensor, ReduceOpDim reduce_dim, float scaler, ...) {
    Tensor n_input = ttnn::neg(input);              // negate input
    Tensor max_result = detail::reduce(             // MAX reduce with -inf padding
        n_input, ReduceOpMath::MAX, ...);
    return ttnn::neg(max_result);                   // negate back
}
```

Why this works for padding: when `detail::reduce` is called with `ReduceOpMath::MAX`, it pads with `-inf`. On the negated input `-x`, padding is `-inf`. After negation back, this is equivalent to padding the original `x` with `+inf` — the correct identity for min.

**Concrete example:** `min([3, 5, pad])` becomes `-max([-3, -5, -inf])` = `-(-5)` = `5`. Wait, that's wrong — let me trace it correctly: `min([3, 5])` -> negate -> `[-3, -5, -inf_pad]` -> max -> `-3` -> negate -> `3`. Correct.

### Hardware reduce ops

```cpp
// tt_llk_blackhole/llk_lib/llk_defs.h
enum PoolType { SUM, AVG, MAX, MIN };
```

Despite `MIN` existing in the enum, the generic reduce path only emits:

```cpp
defines["REDUCE_OP"] = (do_max ? "PoolType::MAX" : "PoolType::SUM");
```

## Binary mask approach (moreh path)

The `moreh_sum` and `moreh_mean` ops use a completely different strategy: instead of filling padding with identity elements, they generate a **binary mask tile** and multiply the last partial tile by it before accumulation.

### Mask generation

```cpp
// moreh_sum_h_program_factory.cpp
const auto origin_H = input.logical_shape()[-2];
const bool do_mask_h = (origin_H % TILE_HEIGHT) != 0;
const auto mask_h = do_mask_h ? origin_H % TILE_HEIGHT : TILE_HEIGHT;
```

The mask tile has `1.0` in valid rows and `0.0` in padding rows:

```cpp
// moreh_common.hpp
void generate_mask_h(uint32_t cb_mask, uint32_t mask_h) {
    // 1.0 for rows [0, mask_h), 0.0 for rows [mask_h, 32)
    fill_subtile_mask_h<T>(ptr, w, subtile_offsets[0], mask_h_top, one, zero);
}
```

### Application in compute kernel

```cpp
// moreh_sum_h.cpp
if (do_mask_h) {
    copy_tile(cb_input, 0, reduce_dst_idx);
    copy_tile(cb_mask_h, 0, mask_dst_idx);
    mask_tile_init();
    mask_tile(reduce_dst_idx, mask_dst_idx);  // element-wise multiply by 0/1
}
```

Zeroed elements contribute nothing to the sum. For mean, the divisor uses the real element count, not the padded count.

### Trade-offs

| Aspect | Identity padding | Binary mask |
|---|---|---|
| Extra memory | Padding baked into tile data | Separate mask tile(s) in CB |
| Extra compute | None (padding is invisible) | One `mask_tile` multiply per partial tile |
| Generality | Works for any associative reduce with an identity | Only works for sum/mean (mask = multiply by 0) |
| Used by | `ttnn::sum`, `ttnn::max`, `ttnn::min`, `ttnn::mean` | `moreh_sum`, `moreh_mean` |

## Summary table

| Reduction op | Implementation | Padding strategy | Pad value / mask |
|---|---|---|---|
| `ttnn::sum` | SUM kernel | Identity padding | `0` |
| `ttnn::mean` | SUM kernel + scaler | Identity padding | `0`, scaler = `1/N` |
| `ttnn::max` | MAX kernel | Identity padding | `-inf` |
| `ttnn::min` | Negate + MAX + Negate | Identity padding on negated input | Effectively `+inf` on original |
| `moreh_sum` | SUM kernel + mask | Binary mask tile | `1.0` valid, `0.0` padding |
| `moreh_mean` | SUM kernel + mask + scaler | Binary mask tile | `1.0` valid, `0.0` padding |

## Key source files

| File | Content |
|---|---|
| `ttnn/.../reduction/generic/generic_reductions.cpp` | `get_pad_value()`, top-level reduce dispatch |
| `ttnn/.../reduction/generic/device/reduce_op.cpp` | `reduce_min` = negate+MAX+negate, pad_value selection |
| `ttnn/.../data_movement/tilize_with_val_padding/...` | Tilize-with-padding device kernel |
| `ttnn/.../data_movement/fill_pad/fill_pad.cpp` | `fill_implicit_tile_padding` for already-tiled tensors |
| `ttnn/.../moreh/moreh_sum/device/moreh_sum_h_program_factory.cpp` | Moreh mask dimension calculation |
| `tt_dnn/kernels/dataflow/moreh_common.hpp` | `generate_mask_h`, `generate_mask_w` |
| `tt_llk_blackhole/llk_lib/llk_defs.h` | `PoolType` enum (SUM, AVG, MAX, MIN) |
| `tt_llk_blackhole/llk_lib/llk_math_reduce.h` | Hardware reduce LLK |
