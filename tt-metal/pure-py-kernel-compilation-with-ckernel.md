# Pure-py kernel compilation with `ckernel` / `compute_kernel_api` (Blackhole)

Use this when your TRISC kernel source includes things like:

- `#include "compute_kernel_api/common.h"`
- `#include "compute_kernel_api/tile_move_copy.h"`
- `#include "sfpi.h"` (via `TRISC_MATH`)
- `namespace NAMESPACE { void MAIN { ... } }`

That stack pulls in `ckernel.h` and the LLK helpers under `tt_metal/third_party/tt_llk`, so a “no-tt_llk” build won’t work.

## What `pure-py` generates

To mimic the TT-metal JIT enough for compilation, `pure-py/codegen.py` generates into the build dir:

- `chlkc_unpack.cpp`, `chlkc_math.cpp`, `chlkc_pack.cpp` (each includes your kernel source with `TRISC_UNPACK/MATH/PACK`)
- `defines_generated.h` (empty for now)
- The descriptor headers that TT-metal normally JIT-generates:
  - `chlkc_unpack_data_format.h`, `chlkc_pack_data_format.h`
  - `chlkc_unpack_tile_dims.h`, `chlkc_pack_tile_dims.h`
  - `chlkc_dst_accum_mode.h`, `chlkc_dst_sync_mode.h`
  - `chlkc_math_fidelity.h`, `chlkc_math_approx_mode.h`

Then it compiles `TT_HOME/tt_metal/hw/firmware/src/tt-1xx/trisck.cc` (this is a *kernel wrapper*, not firmware) with:

- `-DUCK_CHLKC_UNPACK` + `-DNAMESPACE=chlkc_unpack` (TRISC0)
- `-DUCK_CHLKC_MATH` + `-DNAMESPACE=chlkc_math` (TRISC1)
- `-DUCK_CHLKC_PACK` + `-DNAMESPACE=chlkc_pack` (TRISC2)

## Required include paths (Blackhole)

In addition to the usual `tt_metal/hw/inc` includes, TRISC+ckernel builds need:

- `tt_metal/hw/ckernels/blackhole/metal/common` (for `chlkc_list.h`)
- `tt_metal/hw/ckernels/blackhole/metal/llk_api` (+ `llk_sfpu/`)
- `tt_metal/hw/ckernels/blackhole/metal/llk_io` (for `llk_io.h`)
- `tt_metal/third_party/tt_llk/tt_llk_blackhole/common/inc` (for `ckernel.h`, `ckernel_include.h`, etc.)

## Important constraints

- Tile dims / formats / math fidelity are compile-time in this model. `pure-py` currently emits a single fixed set (defaults to `Float16_b` 32x32 tiles).
- If your runtime CB config doesn’t match what was compiled into those descriptor headers, the kernel may run wrong.

## Tweaking compile-time descriptors

`pure-py/codegen.py` exposes this as a small dataclass:

- `codegen.CkernelConfig` (format, tile dims, math fidelity, etc.)
