// Authored probe for the source map; not compiled during documentation.
// f32 residual RMSNorm over rows, H=128, epsilon=1e-5.
// Intentionally separate structured ops expose candidate dispatch boundaries.
#full = affine_map<(b, h) -> (b, h)>
#row = affine_map<(b, h) -> (b)>
#weight = affine_map<(b, h) -> (h)>
#id = affine_map<(b) -> (b)>
func.func @residual_rmsnorm(%x: tensor<2x128xf32>,
    %residual: tensor<2x128xf32>, %gamma: tensor<128xf32>)
    -> tensor<2x128xf32> {
  %zero = arith.constant 0.0 : f32
  %inv_h = arith.constant 0.0078125 : f32
  %epsilon = arith.constant 1.0e-5 : f32
  %empty = tensor.empty() : tensor<2x128xf32>
  %row_empty = tensor.empty() : tensor<2xf32>
  %z = linalg.generic {
      indexing_maps = [#full, #full, #full],
      iterator_types = ["parallel", "parallel"]}
      ins(%x, %residual : tensor<2x128xf32>, tensor<2x128xf32>)
      outs(%empty : tensor<2x128xf32>) {
    ^bb0(%a: f32, %r: f32, %unused: f32):
      %v = arith.addf %a, %r : f32
      linalg.yield %v : f32
  } -> tensor<2x128xf32>
  %sq = linalg.generic {
      indexing_maps = [#full, #full],
      iterator_types = ["parallel", "parallel"]}
      ins(%z : tensor<2x128xf32>) outs(%empty : tensor<2x128xf32>) {
    ^bb0(%a: f32, %unused: f32):
      %v = arith.mulf %a, %a : f32
      linalg.yield %v : f32
  } -> tensor<2x128xf32>
  %init = linalg.fill ins(%zero : f32) outs(%row_empty : tensor<2xf32>) -> tensor<2xf32>
  %sum = linalg.generic {
      indexing_maps = [#full, #row],
      iterator_types = ["parallel", "reduction"]}
      ins(%sq : tensor<2x128xf32>) outs(%init : tensor<2xf32>) {
    ^bb0(%a: f32, %acc: f32):
      %v = arith.addf %a, %acc : f32
      linalg.yield %v : f32
  } -> tensor<2xf32>
  %scale = linalg.generic {
      indexing_maps = [#id, #id], iterator_types = ["parallel"]}
      ins(%sum : tensor<2xf32>) outs(%row_empty : tensor<2xf32>) {
    ^bb0(%a: f32, %unused: f32):
      %mean = arith.mulf %a, %inv_h : f32
      %shifted = arith.addf %mean, %epsilon : f32
      %v = math.rsqrt %shifted : f32
      linalg.yield %v : f32
  } -> tensor<2xf32>
  %y = linalg.generic {
      indexing_maps = [#full, #row, #weight, #full],
      iterator_types = ["parallel", "parallel"]}
      ins(%z, %scale, %gamma : tensor<2x128xf32>, tensor<2xf32>, tensor<128xf32>)
      outs(%empty : tensor<2x128xf32>) {
    ^bb0(%a: f32, %s: f32, %g: f32, %unused: f32):
      %normalized = arith.mulf %a, %s : f32
      %v = arith.mulf %normalized, %g : f32
      linalg.yield %v : f32
  } -> tensor<2x128xf32>
  return %y : tensor<2x128xf32>
}
