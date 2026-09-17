# Tinygrad matcher construction and driver census

## How to read this index

A **matcher** is a collection of conditional rewrite rules. A **construction site** is a place in Python source that creates such a collection. A **driver** walks a graph or instruction list and asks a matcher to rewrite its elements. This page answers where those collections are created and used; the linked guides explain their behavior.

For example, `pm = PatternMatcher([(pattern, callback)])` contributes one construction site and one literal rule entry. Calling `graph_rewrite(root, pm)` elsewhere contributes one driver site. Neither count says how many nodes will match when a program runs.

In the construction table, follow the source link to inspect the rule list. The assignment/function column locates its surrounding Python code. In the driver table, the matcher expression identifies the rules supplied, and traversal options describe how the caller asks the driver to visit nodes. Read the matcher and its driver together: rule order and graph traversal can both affect the result.

For explanations and examples of individual rules, use the [rule-by-rule reference](rules/README.md). For focused backend reading, see [AMD](amd-pattern-matchers.md) and [IMAGE](image-pattern-matchers.md).

Source checkout HEAD `107adc31701df0247dfa45e175984df906a68b53` (2026-09-17). The scanned source directory is clean. Relative links refer to the scanned checkout; this generator does not fetch upstream.

This is a mechanically generated **static AST census of every Python file under `tinygrad/tinygrad/`**, including production runtime and renderer support. It excludes tests, `extra/`, docs, and other checkouts. Only direct calls whose callee is the bare identifier `PatternMatcher`, `graph_rewrite`, or `line_rewrite` are counted. Aliases, attribute calls, `.rewrite(...)`, matcher factories without those literal names, and runtime-expanded compositions are outside the count. This is a reproducible search index, not a complete execution trace.

An assignment label is the nearest enclosing assignment in the syntax tree, not proof that the entire assignment is one matcher. For composed matchers it names the composition containing this construction site. A literal rule count counts outer list/tuple entries only; comprehensions and other expressions are marked dynamic. Driver rows show the actual matcher expression and explicit traversal flags. `defaults` means normal driver defaults apply. See [UOps and rewrites](uops-and-rewrites.md#4-why-these-concrete-matchers-exist) for semantic purposes, phase dependencies, and sharp edges.

Found **180 direct matcher construction sites in 43 files**, and **103 direct graph/list driver calls**. These are source sites, not distinct runtime matchers or rules executed.

## Construction sites

| Source | Assignment / enclosing function | Literal entries |
|---|---|---:|
| [tinygrad/codegen/__init__.py:38](../../../tinygrad/tinygrad/codegen/__init__.py#L38) | `pm_number_params` / `<module/class>` | 1 |
| [tinygrad/codegen/__init__.py:78](../../../tinygrad/tinygrad/codegen/__init__.py#L78) | `expander` / `<module/class>` | 3 |
| [tinygrad/codegen/__init__.py:102](../../../tinygrad/tinygrad/codegen/__init__.py#L102) | `pm_wmma_add` / `<module/class>` | 3 |
| [tinygrad/codegen/__init__.py:112](../../../tinygrad/tinygrad/codegen/__init__.py#L112) | `pm_expand_broadcast` / `<module/class>` | 2 |
| [tinygrad/codegen/__init__.py:137](../../../tinygrad/tinygrad/codegen/__init__.py#L137) | `ew_devectorizer` / `<module/class>` | 1 |
| [tinygrad/codegen/__init__.py:142](../../../tinygrad/tinygrad/codegen/__init__.py#L142) | `devectorizer2` / `<module/class>` | 8 |
| [tinygrad/codegen/__init__.py:223](../../../tinygrad/tinygrad/codegen/__init__.py#L223) | `pm_reduce_identity` / `<module/class>` | 1 |
| [tinygrad/codegen/__init__.py:228](../../../tinygrad/tinygrad/codegen/__init__.py#L228) | `pm_reduce_local` / `<module/class>` | 4 |
| [tinygrad/codegen/__init__.py:239](../../../tinygrad/tinygrad/codegen/__init__.py#L239) | `pm_add_loads` / `<module/class>` | 2 |
| [tinygrad/codegen/__init__.py:249](../../../tinygrad/tinygrad/codegen/__init__.py#L249) | `pm_add_local_buffers` / `<module/class>` | 1 |
| [tinygrad/codegen/__init__.py:255](../../../tinygrad/tinygrad/codegen/__init__.py#L255) | `pm_cast_float_alu` / `<module/class>` | 1 |
| [tinygrad/codegen/__init__.py:281](../../../tinygrad/tinygrad/codegen/__init__.py#L281) | `pm_implicit_barriers` / `<module/class>` | 2 |
| [tinygrad/codegen/__init__.py:287](../../../tinygrad/tinygrad/codegen/__init__.py#L287) | `(inline / return)` / `full_rewrite_to_sink` | 0 |
| [tinygrad/codegen/__init__.py:376](../../../tinygrad/tinygrad/codegen/__init__.py#L376) | `extra_matcher` / `full_rewrite_to_sink` | 0 |
| [tinygrad/codegen/__init__.py:393](../../../tinygrad/tinygrad/codegen/__init__.py#L393) | `(inline / return)` / `full_rewrite_to_sink` | 0 |
| [tinygrad/codegen/__init__.py:408](../../../tinygrad/tinygrad/codegen/__init__.py#L408) | `pm_linearize_cleanups` / `<module/class>` | 2 |
| [tinygrad/codegen/__init__.py:462](../../../tinygrad/tinygrad/codegen/__init__.py#L462) | `pm_to_program` / `<module/class>` | 5 |
| [tinygrad/codegen/__init__.py:496](../../../tinygrad/tinygrad/codegen/__init__.py#L496) | `(inline / return)` / `do_to_program` | 0 |
| [tinygrad/codegen/decomp/dtype.py:145](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L145) | `pm_long_decomp` / `<module/class>` | 13 |
| [tinygrad/codegen/decomp/dtype.py:178](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L178) | `pm_float_decomp` / `<module/class>` | 10 |
| [tinygrad/codegen/decomp/dtype.py:215](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L215) | `pm_dtype_decomps` / `<module/class>` | 2 |
| [tinygrad/codegen/decomp/op.py:80](../../../tinygrad/tinygrad/codegen/decomp/op.py#L80) | `(inline / return)` / `get_simplifying_rewrite_patterns` | dynamic |
| [tinygrad/codegen/decomp/op.py:126](../../../tinygrad/tinygrad/codegen/decomp/op.py#L126) | `(inline / return)` / `get_late_rewrite_patterns` | dynamic |
| [tinygrad/codegen/decomp/transcendental.py:277](../../../tinygrad/tinygrad/codegen/decomp/transcendental.py#L277) | `(inline / return)` / `get_transcendental_patterns` | dynamic |
| [tinygrad/codegen/gpudims.py:86](../../../tinygrad/tinygrad/codegen/gpudims.py#L86) | `pm_device_to_var` / `<module/class>` | 2 |
| [tinygrad/codegen/gpudims.py:94](../../../tinygrad/tinygrad/codegen/gpudims.py#L94) | `pm_add_gpudims` / `<module/class>` | 1 |
| [tinygrad/codegen/late/coalesce.py:58](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L58) | `indexing_simplify` / `<module/class>` | 2 |
| [tinygrad/codegen/late/coalesce.py:97](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L97) | `pm_simplify_add_image` / `<module/class>` | 3 |
| [tinygrad/codegen/late/gater.py:9](../../../tinygrad/tinygrad/codegen/late/gater.py#L9) | `pm_move_gates_from_index` / `<module/class>` | 6 |
| [tinygrad/codegen/late/linearizer.py:83](../../../tinygrad/tinygrad/codegen/late/linearizer.py#L83) | `pm_add_control_flow` / `<module/class>` | 1 |
| [tinygrad/codegen/late/linearizer.py:92](../../../tinygrad/tinygrad/codegen/late/linearizer.py#L92) | `pm_split_ends` / `<module/class>` | 1 |
| [tinygrad/codegen/late/regalloc.py:114](../../../tinygrad/tinygrad/codegen/late/regalloc.py#L114) | `pm_regalloc_rewrite` / `<module/class>` | 1 |
| [tinygrad/codegen/simplify.py:16](../../../tinygrad/tinygrad/codegen/simplify.py#L16) | `pm_flatten_range` / `<module/class>` | 1 |
| [tinygrad/codegen/simplify.py:54](../../../tinygrad/tinygrad/codegen/simplify.py#L54) | `pm_simplify_ranges` / `<module/class>` | 4 |
| [tinygrad/codegen/simplify.py:72](../../../tinygrad/tinygrad/codegen/simplify.py#L72) | `pm_split_ranges` / `<module/class>` | 2 |
| [tinygrad/codegen/simplify.py:94](../../../tinygrad/tinygrad/codegen/simplify.py#L94) | `pm_reduce_unparented` / `<module/class>` | 1 |
| [tinygrad/codegen/simplify.py:99](../../../tinygrad/tinygrad/codegen/simplify.py#L99) | `pm_reduce_collapse` / `<module/class>` | 6 |
| [tinygrad/codegen/simplify.py:122](../../../tinygrad/tinygrad/codegen/simplify.py#L122) | `pm_reduce_load_collapse` / `<module/class>` | 2 |
| [tinygrad/codegen/simplify.py:148](../../../tinygrad/tinygrad/codegen/simplify.py#L148) | `pm_reduce_simplify` / `<module/class>` | 1 |
| [tinygrad/codegen/simplify.py:153](../../../tinygrad/tinygrad/codegen/simplify.py#L153) | `pm_load_collapse` / `<module/class>` | 2 |
| [tinygrad/device.py:432](../../../tinygrad/tinygrad/device.py#L432) | `self.pm_bufferize` / `__init__` | 3 |
| [tinygrad/engine/jit.py:67](../../../tinygrad/tinygrad/engine/jit.py#L67) | `(inline / return)` / `jit_lower` | 0 |
| [tinygrad/engine/jit.py:74](../../../tinygrad/tinygrad/engine/jit.py#L74) | `(inline / return)` / `jit_lower` | 0 |
| [tinygrad/engine/realize.py:221](../../../tinygrad/tinygrad/engine/realize.py#L221) | `pm_flatten_linear` / `<module/class>` | 1 |
| [tinygrad/engine/realize.py:231](../../../tinygrad/tinygrad/engine/realize.py#L231) | `pm_validate` / `<module/class>` | 1 |
| [tinygrad/engine/realize.py:234](../../../tinygrad/tinygrad/engine/realize.py#L234) | `pm_beam` / `<module/class>` | 1 |
| [tinygrad/engine/realize.py:278](../../../tinygrad/tinygrad/engine/realize.py#L278) | `pm_exec` / `<module/class>` | 5 |
| [tinygrad/function.py:15](../../../tinygrad/tinygrad/function.py#L15) | `pm_ctx` / `<module/class>` | 2 |
| [tinygrad/mixin/gradient.py:84](../../../tinygrad/tinygrad/mixin/gradient.py#L84) | `pm_gradient` / `<module/class>` | 31 |
| [tinygrad/renderer/cstyle.py:11](../../../tinygrad/tinygrad/renderer/cstyle.py#L11) | `base_rewrite` / `<module/class>` | 32 |
| [tinygrad/renderer/cstyle.py:78](../../../tinygrad/tinygrad/renderer/cstyle.py#L78) | `patterns` / `create_non_native_float_pats` | 3 |
| [tinygrad/renderer/cstyle.py:87](../../../tinygrad/tinygrad/renderer/cstyle.py#L87) | `(inline / return)` / `create_non_native_float_pats` | 2 |
| [tinygrad/renderer/cstyle.py:100](../../../tinygrad/tinygrad/renderer/cstyle.py#L100) | `pm_manual_bf16_cast` / `<module/class>` | 2 |
| [tinygrad/renderer/cstyle.py:106](../../../tinygrad/tinygrad/renderer/cstyle.py#L106) | `pm_bf16_ushort_const` / `<module/class>` | 1 |
| [tinygrad/renderer/cstyle.py:282](../../../tinygrad/tinygrad/renderer/cstyle.py#L282) | `extra_matcher` / `<module/class>` | 3 |
| [tinygrad/renderer/cstyle.py:325](../../../tinygrad/tinygrad/renderer/cstyle.py#L325) | `string_rewrite` / `<module/class>` | 5 |
| [tinygrad/renderer/cstyle.py:369](../../../tinygrad/tinygrad/renderer/cstyle.py#L369) | `extra_matcher` / `<module/class>` | 1 |
| [tinygrad/renderer/cstyle.py:375](../../../tinygrad/tinygrad/renderer/cstyle.py#L375) | `string_rewrite` / `<module/class>` | 1 |
| [tinygrad/renderer/cstyle.py:427](../../../tinygrad/tinygrad/renderer/cstyle.py#L427) | `extra_matcher` / `<module/class>` | 1 |
| [tinygrad/renderer/cstyle.py:430](../../../tinygrad/tinygrad/renderer/cstyle.py#L430) | `string_rewrite` / `<module/class>` | 1 |
| [tinygrad/renderer/cstyle.py:497](../../../tinygrad/tinygrad/renderer/cstyle.py#L497) | `self.string_rewrite` / `__init__` | 5 |
| [tinygrad/renderer/cstyle.py:510](../../../tinygrad/tinygrad/renderer/cstyle.py#L510) | `self.string_rewrite` / `__init__` | 1 |
| [tinygrad/renderer/cstyle.py:526](../../../tinygrad/tinygrad/renderer/cstyle.py#L526) | `extra_matcher` / `<module/class>` | 1 |
| [tinygrad/renderer/isa/x86.py:90](../../../tinygrad/tinygrad/renderer/isa/x86.py#L90) | `extra_matcher` / `<module/class>` | 16 |
| [tinygrad/renderer/isa/x86.py:148](../../../tinygrad/tinygrad/renderer/isa/x86.py#L148) | `pre_isel_matcher` / `<module/class>` | 5 |
| [tinygrad/renderer/isa/x86.py:319](../../../tinygrad/tinygrad/renderer/isa/x86.py#L319) | `isel_matcher` / `<module/class>` | 84 |
| [tinygrad/renderer/isa/x86.py:475](../../../tinygrad/tinygrad/renderer/isa/x86.py#L475) | `pre_regalloc_matcher` / `<module/class>` | 2 |
| [tinygrad/renderer/isa/x86.py:506](../../../tinygrad/tinygrad/renderer/isa/x86.py#L506) | `post_regalloc_matcher` / `<module/class>` | 7 |
| [tinygrad/renderer/llvmir.py:77](../../../tinygrad/tinygrad/renderer/llvmir.py#L77) | `base_rewrite` / `<module/class>` | 18 |
| [tinygrad/renderer/llvmir.py:230](../../../tinygrad/tinygrad/renderer/llvmir.py#L230) | `string_rewrite` / `<module/class>` | 5 |
| [tinygrad/renderer/llvmir.py:241](../../../tinygrad/tinygrad/renderer/llvmir.py#L241) | `extra_matcher` / `<module/class>` | 2 |
| [tinygrad/renderer/llvmir.py:275](../../../tinygrad/tinygrad/renderer/llvmir.py#L275) | `(inline / return)` / `__init__` | 1 |
| [tinygrad/renderer/nir.py:121](../../../tinygrad/tinygrad/renderer/nir.py#L121) | `extra_matcher` / `<module/class>` | 7 |
| [tinygrad/renderer/nir.py:145](../../../tinygrad/tinygrad/renderer/nir.py#L145) | `def_rewrite` / `<module/class>` | 14 |
| [tinygrad/renderer/nir.py:292](../../../tinygrad/tinygrad/renderer/nir.py#L292) | `def_rewrite` / `<module/class>` | 3 |
| [tinygrad/renderer/ptx.py:40](../../../tinygrad/tinygrad/renderer/ptx.py#L40) | `ptx_matcher` / `<module/class>` | 8 |
| [tinygrad/renderer/ptx.py:81](../../../tinygrad/tinygrad/renderer/ptx.py#L81) | `string_rewrite` / `<module/class>` | 23 |
| [tinygrad/renderer/ptx.py:148](../../../tinygrad/tinygrad/renderer/ptx.py#L148) | `(inline / return)` / `__init__` | 1 |
| [tinygrad/renderer/tc.py:114](../../../tinygrad/tinygrad/renderer/tc.py#L114) | `pm_validate_wmma_rdna3` / `<module/class>` | 3 |
| [tinygrad/renderer/tc.py:129](../../../tinygrad/tinygrad/renderer/tc.py#L129) | `pm_validate_wmma_rdna4` / `<module/class>` | 2 |
| [tinygrad/renderer/tc.py:138](../../../tinygrad/tinygrad/renderer/tc.py#L138) | `pm_validate_wmma_cdna` / `<module/class>` | 3 |
| [tinygrad/renderer/wgsl.py:43](../../../tinygrad/tinygrad/renderer/wgsl.py#L43) | `wgsl_matcher` / `<module/class>` | 7 |
| [tinygrad/renderer/wgsl.py:67](../../../tinygrad/tinygrad/renderer/wgsl.py#L67) | `string_rewrite` / `<module/class>` | 17 |
| [tinygrad/runtime/ops_amd.py:840](../../../tinygrad/tinygrad/runtime/ops_amd.py#L840) | `pm_encode` / `<module/class>` | 2 |
| [tinygrad/runtime/ops_amd.py:887](../../../tinygrad/tinygrad/runtime/ops_amd.py#L887) | `self.pm_bufferize` / `__init__` | 3 |
| [tinygrad/runtime/ops_amd.py:904](../../../tinygrad/tinygrad/runtime/ops_amd.py#L904) | `self.pm_bufferize` / `__init__` | dynamic |
| [tinygrad/runtime/ops_nv.py:99](../../../tinygrad/tinygrad/runtime/ops_nv.py#L99) | `q_rewrite` / `<module/class>` | 1 |
| [tinygrad/runtime/ops_nv.py:560](../../../tinygrad/tinygrad/runtime/ops_nv.py#L560) | `pm_encode` / `<module/class>` | 3 |
| [tinygrad/runtime/ops_nv.py:657](../../../tinygrad/tinygrad/runtime/ops_nv.py#L657) | `self.pm_bufferize` / `_new_gpu_fifo` | dynamic |
| [tinygrad/runtime/ops_qcom.py:306](../../../tinygrad/tinygrad/runtime/ops_qcom.py#L306) | `pm_encode` / `<module/class>` | 1 |
| [tinygrad/runtime/ops_qcom.py:340](../../../tinygrad/tinygrad/runtime/ops_qcom.py#L340) | `self.pm_bufferize` / `__init__` | 3 |
| [tinygrad/runtime/ops_rdma.py:79](../../../tinygrad/tinygrad/runtime/ops_rdma.py#L79) | `nic.pm_bufferize` / `rdma_qp` | dynamic |
| [tinygrad/runtime/ops_rdma.py:162](../../../tinygrad/tinygrad/runtime/ops_rdma.py#L162) | `pm_rdma_encode` / `<module/class>` | 1 |
| [tinygrad/runtime/support/hcq2.py:119](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L119) | `pm_replace_buffers` / `<module/class>` | 1 |
| [tinygrad/runtime/support/hcq2.py:129](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L129) | `pm_unwrap_multi` / `<module/class>` | 1 |
| [tinygrad/runtime/support/hcq2.py:171](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L171) | `pm_insert_copy_staging` / `<module/class>` | 2 |
| [tinygrad/runtime/support/hcq2.py:320](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L320) | `q_rewrite` / `<module/class>` | 8 |
| [tinygrad/runtime/support/hcq2.py:376](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L376) | `pm_hcq_encode` / `<module/class>` | 2 |
| [tinygrad/runtime/support/hcq2.py:408](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L408) | `pm_patches` / `<module/class>` | 2 |
| [tinygrad/runtime/support/hcq2.py:448](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L448) | `pm_views` / `<module/class>` | 2 |
| [tinygrad/runtime/support/hcq2.py:456](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L456) | `pm_renumber` / `<module/class>` | 2 |
| [tinygrad/runtime/support/hcq2.py:468](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L468) | `body` / `lower_call` | 0 |
| [tinygrad/runtime/support/hcq2.py:470](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L470) | `body` / `lower_call` | 0 |
| [tinygrad/runtime/support/hcq2.py:496](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L496) | `(inline / return)` / `lower_call` | 0 |
| [tinygrad/runtime/support/hcq2.py:497](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L497) | `(inline / return)` / `lower_call` | 0 |
| [tinygrad/runtime/support/hcq2.py:502](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L502) | `pm_encode` / `<module/class>` | 1 |
| [tinygrad/runtime/support/hcq2.py:564](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L564) | `pm_link` / `<module/class>` | 8 |
| [tinygrad/runtime/support/usb.py:325](../../../tinygrad/tinygrad/runtime/support/usb.py#L325) | `pm_usb_copy_slicer` / `<module/class>` | 1 |
| [tinygrad/runtime/support/usb.py:349](../../../tinygrad/tinygrad/runtime/support/usb.py#L349) | `pm_usb_batch` / `<module/class>` | 1 |
| [tinygrad/runtime/support/usb.py:471](../../../tinygrad/tinygrad/runtime/support/usb.py#L471) | `pm_usb_lower` / `<module/class>` | 3 |
| [tinygrad/runtime/support/usb.py:495](../../../tinygrad/tinygrad/runtime/support/usb.py#L495) | `pm_usb_bufferize` / `<module/class>` | 5 |
| [tinygrad/schedule/__init__.py:93](../../../tinygrad/tinygrad/schedule/__init__.py#L93) | `pm_post_sched_cache` / `<module/class>` | 2 |
| [tinygrad/schedule/__init__.py:113](../../../tinygrad/tinygrad/schedule/__init__.py#L113) | `pm_resolve_linear_call` / `<module/class>` | 1 |
| [tinygrad/schedule/__init__.py:147](../../../tinygrad/tinygrad/schedule/__init__.py#L147) | `pm_schedule` / `<module/class>` | 1 |
| [tinygrad/schedule/__init__.py:168](../../../tinygrad/tinygrad/schedule/__init__.py#L168) | `pm_copy_from_store` / `<module/class>` | 4 |
| [tinygrad/schedule/indexing.py:45](../../../tinygrad/tinygrad/schedule/indexing.py#L45) | `pm_generate_realize_map` / `<module/class>` | 4 |
| [tinygrad/schedule/indexing.py:134](../../../tinygrad/tinygrad/schedule/indexing.py#L134) | `pm_apply_rangeify` / `<module/class>` | 5 |
| [tinygrad/schedule/indexing.py:147](../../../tinygrad/tinygrad/schedule/indexing.py#L147) | `pm_fix_deviceless` / `<module/class>` | 1 |
| [tinygrad/schedule/multi.py:29](../../../tinygrad/tinygrad/schedule/multi.py#L29) | `replace_allreduce` / `<module/class>` | 6 |
| [tinygrad/schedule/multi.py:47](../../../tinygrad/tinygrad/schedule/multi.py#L47) | `_early_allreduce` / `<module/class>` | 1 |
| [tinygrad/schedule/multi.py:281](../../../tinygrad/tinygrad/schedule/multi.py#L281) | `multi_pm` / `<module/class>` | 19 |
| [tinygrad/schedule/prepare.py:26](../../../tinygrad/tinygrad/schedule/prepare.py#L26) | `pm_fold_moved_after` / `<module/class>` | 3 |
| [tinygrad/schedule/prepare.py:47](../../../tinygrad/tinygrad/schedule/prepare.py#L47) | `pm_mops` / `<module/class>` | 3 |
| [tinygrad/schedule/prepare.py:98](../../../tinygrad/tinygrad/schedule/prepare.py#L98) | `pm_gather_params` / `<module/class>` | 1 |
| [tinygrad/schedule/prepare.py:151](../../../tinygrad/tinygrad/schedule/prepare.py#L151) | `earliest_rewrites` / `<module/class>` | 19 |
| [tinygrad/schedule/rangeify.py:47](../../../tinygrad/tinygrad/schedule/rangeify.py#L47) | `pm_gate_substitute` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:115](../../../tinygrad/tinygrad/schedule/rangeify.py#L115) | `pm_const_buffer_folding` / `<module/class>` | 6 |
| [tinygrad/schedule/rangeify.py:131](../../../tinygrad/tinygrad/schedule/rangeify.py#L131) | `pm_remove_bufferize` / `<module/class>` | 3 |
| [tinygrad/schedule/rangeify.py:160](../../../tinygrad/tinygrad/schedule/rangeify.py#L160) | `pm_no_indexing_calls` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:165](../../../tinygrad/tinygrad/schedule/rangeify.py#L165) | `pm_no_views` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:198](../../../tinygrad/tinygrad/schedule/rangeify.py#L198) | `pm_limit_bufs` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:251](../../../tinygrad/tinygrad/schedule/rangeify.py#L251) | `pm_flatten_bufferize` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:261](../../../tinygrad/tinygrad/schedule/rangeify.py#L261) | `pm_add_buffers` / `<module/class>` | 6 |
| [tinygrad/schedule/rangeify.py:320](../../../tinygrad/tinygrad/schedule/rangeify.py#L320) | `to_define_global` / `<module/class>` | 9 |
| [tinygrad/schedule/rangeify.py:344](../../../tinygrad/tinygrad/schedule/rangeify.py#L344) | `pm_add_param_range_tags` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:362](../../../tinygrad/tinygrad/schedule/rangeify.py#L362) | `split_kernels` / `<module/class>` | 1 |
| [tinygrad/schedule/rangeify.py:377](../../../tinygrad/tinygrad/schedule/rangeify.py#L377) | `(inline / return)` / `get_kernel_graph` | 0 |
| [tinygrad/schedule/rangeify.py:387](../../../tinygrad/tinygrad/schedule/rangeify.py#L387) | `(inline / return)` / `get_kernel_graph` | 0 |
| [tinygrad/tensor.py:44](../../../tinygrad/tinygrad/tensor.py#L44) | `add_tags` / `<module/class>` | 4 |
| [tinygrad/tensor.py:137](../../../tinygrad/tinygrad/tensor.py#L137) | `pm_early_transform_tensor_graph` / `<module/class>` | 9 |
| [tinygrad/tensor.py:166](../../../tinygrad/tinygrad/tensor.py#L166) | `pm_drop_after` / `<module/class>` | 1 |
| [tinygrad/tensor.py:182](../../../tinygrad/tinygrad/tensor.py#L182) | `pm_canonicalize_unbound` / `<module/class>` | 2 |
| [tinygrad/tensor.py:187](../../../tinygrad/tinygrad/tensor.py#L187) | `pm_replace_buf` / `<module/class>` | 3 |
| [tinygrad/tensor.py:199](../../../tinygrad/tinygrad/tensor.py#L199) | `(inline / return)` / `transform_to_call` | 0 |
| [tinygrad/tensor.py:233](../../../tinygrad/tinygrad/tensor.py#L233) | `(inline / return)` / `transform_to_call` | 0 |
| [tinygrad/uop/divandmod.py:98](../../../tinygrad/tinygrad/uop/divandmod.py#L98) | `div_and_mod_symbolic` / `<module/class>` | 3 |
| [tinygrad/uop/movement.py:5](../../../tinygrad/tinygrad/uop/movement.py#L5) | `mop_cleanup` / `<module/class>` | 8 |
| [tinygrad/uop/ops.py:1538](../../../tinygrad/tinygrad/uop/ops.py#L1538) | `(inline / return)` / `__add__` | dynamic |
| [tinygrad/uop/ops.py:1816](../../../tinygrad/tinygrad/uop/ops.py#L1816) | `_substitute` / `<module/class>` | 1 |
| [tinygrad/uop/ops.py:1817](../../../tinygrad/tinygrad/uop/ops.py#L1817) | `_pm_resolve_params` / `<module/class>` | 1 |
| [tinygrad/uop/ops.py:1825](../../../tinygrad/tinygrad/uop/ops.py#L1825) | `remove_all_tags` / `<module/class>` | 1 |
| [tinygrad/uop/ops.py:1836](../../../tinygrad/tinygrad/uop/ops.py#L1836) | `pm_unbind` / `<module/class>` | 1 |
| [tinygrad/uop/ops.py:1839](../../../tinygrad/tinygrad/uop/ops.py#L1839) | `pm_contiguous_view_offset` / `<module/class>` | 6 |
| [tinygrad/uop/render.py:34](../../../tinygrad/tinygrad/uop/render.py#L34) | `renderer` / `<module/class>` | 21 |
| [tinygrad/uop/render.py:59](../../../tinygrad/tinygrad/uop/render.py#L59) | `renderer_infer` / `<module/class>` | 4 |
| [tinygrad/uop/render.py:83](../../../tinygrad/tinygrad/uop/render.py#L83) | `pm_pyrender_extra` / `<module/class>` | 14 |
| [tinygrad/uop/render.py:115](../../../tinygrad/tinygrad/uop/render.py#L115) | `pm_pyrender` / `<module/class>` | 1 |
| [tinygrad/uop/spec.py:42](../../../tinygrad/tinygrad/uop/spec.py#L42) | `spec_shared` / `<module/class>` | 32 |
| [tinygrad/uop/spec.py:132](../../../tinygrad/tinygrad/uop/spec.py#L132) | `spec_tensor` / `<module/class>` | 23 |
| [tinygrad/uop/spec.py:189](../../../tinygrad/tinygrad/uop/spec.py#L189) | `spec_program` / `<module/class>` | 9 |
| [tinygrad/uop/spec.py:214](../../../tinygrad/tinygrad/uop/spec.py#L214) | `spec_hcq` / `<module/class>` | 2 |
| [tinygrad/uop/spec.py:222](../../../tinygrad/tinygrad/uop/spec.py#L222) | `spec_full` / `<module/class>` | 4 |
| [tinygrad/uop/spec.py:237](../../../tinygrad/tinygrad/uop/spec.py#L237) | `spec_kernel_graph` / `<module/class>` | 12 |
| [tinygrad/uop/symbolic.py:79](../../../tinygrad/tinygrad/uop/symbolic.py#L79) | `pm_data_invalid` / `<module/class>` | 14 |
| [tinygrad/uop/symbolic.py:104](../../../tinygrad/tinygrad/uop/symbolic.py#L104) | `pm_remove_invalid` / `<module/class>` | 2 |
| [tinygrad/uop/symbolic.py:115](../../../tinygrad/tinygrad/uop/symbolic.py#L115) | `symbolic_simple` / `<module/class>` | 51 |
| [tinygrad/uop/symbolic.py:227](../../../tinygrad/tinygrad/uop/symbolic.py#L227) | `commutative` / `<module/class>` | 1 |
| [tinygrad/uop/symbolic.py:240](../../../tinygrad/tinygrad/uop/symbolic.py#L240) | `symbolic` / `<module/class>` | 40 |
| [tinygrad/uop/symbolic.py:409](../../../tinygrad/tinygrad/uop/symbolic.py#L409) | `pm_drop_and_clauses` / `<module/class>` | 1 |
| [tinygrad/uop/symbolic.py:426](../../../tinygrad/tinygrad/uop/symbolic.py#L426) | `pm_move_where_on_load` / `<module/class>` | 2 |
| [tinygrad/uop/symbolic.py:439](../../../tinygrad/tinygrad/uop/symbolic.py#L439) | `pm_simplify_valid` / `<module/class>` | 2 |
| [tinygrad/uop/symbolic.py:447](../../../tinygrad/tinygrad/uop/symbolic.py#L447) | `pm_clean_up_group_sink` / `<module/class>` | 2 |
| [tinygrad/uop/symbolic.py:455](../../../tinygrad/tinygrad/uop/symbolic.py#L455) | `sym` / `<module/class>` | 14 |
| [tinygrad/uop/upat.py:109](../../../tinygrad/tinygrad/uop/upat.py#L109) | `pm_proc` / `<module/class>` | 1 |
| [tinygrad/uop/upat.py:116](../../../tinygrad/tinygrad/uop/upat.py#L116) | `pm_renderer` / `<module/class>` | 4 |
| [tinygrad/uop/validate.py:44](../../../tinygrad/tinygrad/uop/validate.py#L44) | `z3_renderer` / `<module/class>` | 9 |
| [tinygrad/uop/weak.py:35](../../../tinygrad/tinygrad/uop/weak.py#L35) | `pm_commit_weak` / `<module/class>` | 3 |
| [tinygrad/uop/weak.py:67](../../../tinygrad/tinygrad/uop/weak.py#L67) | `pm_lower_weak` / `<module/class>` | 4 |
| [tinygrad/uop/weak.py:89](../../../tinygrad/tinygrad/uop/weak.py#L89) | `pm_uncast_const` / `<module/class>` | 1 |
| [tinygrad/uop/weak.py:98](../../../tinygrad/tinygrad/uop/weak.py#L98) | `pm_cast_const` / `<module/class>` | 1 |

## Driver call sites

| Source | Driver / matcher expression | Pass label | Explicit traversal options |
|---|---|---|---|
| [tinygrad/codegen/__init__.py:287](../../../tinygrad/tinygrad/codegen/__init__.py#L287) | `graph_rewrite`: `PatternMatcher([])` | `'View Base AST'` | `defaults` |
| [tinygrad/codegen/__init__.py:292](../../../tinygrad/tinygrad/codegen/__init__.py#L292) | `graph_rewrite`: `multi_pm` | `'multi_pm'` | `defaults` |
| [tinygrad/codegen/__init__.py:295](../../../tinygrad/tinygrad/codegen/__init__.py#L295) | `graph_rewrite`: `pm_mops` | `'early movement ops'` | `bottom_up=True` |
| [tinygrad/codegen/__init__.py:300](../../../tinygrad/tinygrad/codegen/__init__.py#L300) | `graph_rewrite`: `pm_load_collapse` | `'load collapse'` | `defaults` |
| [tinygrad/codegen/__init__.py:303](../../../tinygrad/tinygrad/codegen/__init__.py#L303) | `graph_rewrite`: `pm_split_ranges + pm_flatten_range` | `'split ranges'` | `defaults` |
| [tinygrad/codegen/__init__.py:306](../../../tinygrad/tinygrad/codegen/__init__.py#L306) | `graph_rewrite`: `sym + pm_flatten_range` | `'initial symbolic'` | `defaults` |
| [tinygrad/codegen/__init__.py:309](../../../tinygrad/tinygrad/codegen/__init__.py#L309) | `graph_rewrite`: `pm_flatten_range + pm_simplify_ranges` | `'simplify ranges'` | `defaults` |
| [tinygrad/codegen/__init__.py:316](../../../tinygrad/tinygrad/codegen/__init__.py#L316) | `graph_rewrite`: `sym + pm_move_where_on_load + pm_flatten_range + pm_reduce_unparented + pm_reduce_identity` | `'postopt symbolic'` | `defaults` |
| [tinygrad/codegen/__init__.py:319](../../../tinygrad/tinygrad/codegen/__init__.py#L319) | `graph_rewrite`: `expander` | `'expander'` | `defaults` |
| [tinygrad/codegen/__init__.py:322](../../../tinygrad/tinygrad/codegen/__init__.py#L322) | `graph_rewrite`: `mop_cleanup + pm_reduce_local` | `'remove reduces'` | `defaults` |
| [tinygrad/codegen/__init__.py:325](../../../tinygrad/tinygrad/codegen/__init__.py#L325) | `graph_rewrite`: `pm_add_local_buffers` | `'add local buffers'` | `defaults` |
| [tinygrad/codegen/__init__.py:328](../../../tinygrad/tinygrad/codegen/__init__.py#L328) | `graph_rewrite`: `pm_add_gpudims` | `'add gpudims'` | `defaults` |
| [tinygrad/codegen/__init__.py:332](../../../tinygrad/tinygrad/codegen/__init__.py#L332) | `graph_rewrite`: `symbolic_simple + pm_expand_broadcast + pm_add_loads` | `'*** expand broadcast / add loads'` | `defaults` |
| [tinygrad/codegen/__init__.py:335](../../../tinygrad/tinygrad/codegen/__init__.py#L335) | `graph_rewrite`: `symbolic_simple + devectorizer2 + indexing_simplify` | `'devectorize2'` | `defaults` |
| [tinygrad/codegen/__init__.py:338](../../../tinygrad/tinygrad/codegen/__init__.py#L338) | `graph_rewrite`: `sym` | `'early symbolic'` | `defaults` |
| [tinygrad/codegen/__init__.py:342](../../../tinygrad/tinygrad/codegen/__init__.py#L342) | `graph_rewrite`: `symbolic_simple + ew_devectorizer + pm_simplify_add_image` | `'add images'` | `bottom_up=True` |
| [tinygrad/codegen/__init__.py:348](../../../tinygrad/tinygrad/codegen/__init__.py#L348) | `graph_rewrite`: `sym + indexing_simplify + pm_commit_weak` | `'extra symbolic'` | `defaults` |
| [tinygrad/codegen/__init__.py:353](../../../tinygrad/tinygrad/codegen/__init__.py#L353) | `graph_rewrite`: `pm_lower_weak + indexing_simplify` | `'lower all index dtypes'` | `enter_calls=True` |
| [tinygrad/codegen/__init__.py:356](../../../tinygrad/tinygrad/codegen/__init__.py#L356) | `graph_rewrite`: `symbolic` | `'final symbolic'` | `defaults` |
| [tinygrad/codegen/__init__.py:358](../../../tinygrad/tinygrad/codegen/__init__.py#L358) | `graph_rewrite`: `pm_cast_float_alu` | `'cast float alu operands'` | `defaults` |
| [tinygrad/codegen/__init__.py:365](../../../tinygrad/tinygrad/codegen/__init__.py#L365) | `graph_rewrite`: `pm_decomp` | `'early decompositions'` | `defaults` |
| [tinygrad/codegen/__init__.py:368](../../../tinygrad/tinygrad/codegen/__init__.py#L368) | `graph_rewrite`: `pm_dtype_decomps + pm_commit_weak` | `'decomp dtypes'` | `defaults` |
| [tinygrad/codegen/__init__.py:372](../../../tinygrad/tinygrad/codegen/__init__.py#L372) | `graph_rewrite`: `pm_decomp` | `'late decompositions'` | `defaults` |
| [tinygrad/codegen/__init__.py:373](../../../tinygrad/tinygrad/codegen/__init__.py#L373) | `graph_rewrite`: `pm_move_gates_from_index` | `'move gates from index'` | `defaults` |
| [tinygrad/codegen/__init__.py:378](../../../tinygrad/tinygrad/codegen/__init__.py#L378) | `graph_rewrite`: `pm_final_rewrite + pm_remove_invalid` | `'final rewrite'` | `defaults` |
| [tinygrad/codegen/__init__.py:381](../../../tinygrad/tinygrad/codegen/__init__.py#L381) | `graph_rewrite`: `pm_cast_const` | `'cast consts'` | `defaults` |
| [tinygrad/codegen/__init__.py:384](../../../tinygrad/tinygrad/codegen/__init__.py#L384) | `graph_rewrite`: `pm_implicit_barriers` | `'add implicit barriers'` | `defaults` |
| [tinygrad/codegen/__init__.py:387](../../../tinygrad/tinygrad/codegen/__init__.py#L387) | `graph_rewrite`: `pm_add_control_flow` | `'add control flow'` | `bottom_up=True` |
| [tinygrad/codegen/__init__.py:391](../../../tinygrad/tinygrad/codegen/__init__.py#L391) | `graph_rewrite`: `pm_number_params` | `'number params with -1'` | `walk=True` |
| [tinygrad/codegen/__init__.py:393](../../../tinygrad/tinygrad/codegen/__init__.py#L393) | `graph_rewrite`: `PatternMatcher([])` | `'View Output AST'` | `defaults` |
| [tinygrad/codegen/__init__.py:429](../../../tinygrad/tinygrad/codegen/__init__.py#L429) | `line_rewrite`: `pm_linearize_cleanups` | `—` | `defaults` |
| [tinygrad/codegen/__init__.py:433](../../../tinygrad/tinygrad/codegen/__init__.py#L433) | `line_rewrite`: `ctx.pre_regalloc_matcher` | `—` | `defaults` |
| [tinygrad/codegen/__init__.py:437](../../../tinygrad/tinygrad/codegen/__init__.py#L437) | `line_rewrite`: `pm_regalloc_rewrite` | `—` | `defaults` |
| [tinygrad/codegen/__init__.py:438](../../../tinygrad/tinygrad/codegen/__init__.py#L438) | `line_rewrite`: `ctx.post_regalloc_matcher` | `—` | `defaults` |
| [tinygrad/codegen/__init__.py:490](../../../tinygrad/tinygrad/codegen/__init__.py#L490) | `graph_rewrite`: `renderer.pre_isel_matcher` | `'pre instruction selection'` | `bottom_up=True` |
| [tinygrad/codegen/__init__.py:491](../../../tinygrad/tinygrad/codegen/__init__.py#L491) | `graph_rewrite`: `renderer.isel_matcher` | `'instruction selection'` | `bottom_up=True` |
| [tinygrad/codegen/__init__.py:495](../../../tinygrad/tinygrad/codegen/__init__.py#L495) | `graph_rewrite`: `pm_to_program` | `'linearize/render'` | `defaults` |
| [tinygrad/codegen/__init__.py:496](../../../tinygrad/tinygrad/codegen/__init__.py#L496) | `graph_rewrite`: `PatternMatcher([])` | `'View Program'` | `defaults` |
| [tinygrad/codegen/decomp/dtype.py:91](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L91) | `graph_rewrite`: `pm_long_decomp` | `—` | `bottom_up=True` |
| [tinygrad/codegen/decomp/dtype.py:136](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L136) | `graph_rewrite`: `pm_float_decomp` | `—` | `bottom_up=True` |
| [tinygrad/codegen/decomp/dtype.py:174](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L174) | `graph_rewrite`: `pm_long_decomp` | `—` | `bottom_up=True` |
| [tinygrad/codegen/decomp/dtype.py:183](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L183) | `graph_rewrite`: `pm_float_decomp` | `—` | `bottom_up=True` |
| [tinygrad/codegen/decomp/dtype.py:188](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L188) | `graph_rewrite`: `pm_float_decomp` | `—` | `bottom_up=True` |
| [tinygrad/codegen/decomp/dtype.py:211](../../../tinygrad/tinygrad/codegen/decomp/dtype.py#L211) | `graph_rewrite`: `pm` | `f'decomp {fr} -> {to}'` | `bottom_up=True` |
| [tinygrad/codegen/late/coalesce.py:36](../../../tinygrad/tinygrad/codegen/late/coalesce.py#L36) | `graph_rewrite`: `sym` | `—` | `defaults` |
| [tinygrad/codegen/opt/postrange.py:49](../../../tinygrad/tinygrad/codegen/opt/postrange.py#L49) | `graph_rewrite`: `pm_flatten_range` | `'flatten range'` | `defaults` |
| [tinygrad/codegen/simplify.py:35](../../../tinygrad/tinygrad/codegen/simplify.py#L35) | `graph_rewrite`: `_substitute + symbolic + pm_flatten_range` | `f'check_merge_{r0.arg[0]}_{r1.arg[0]}'` | `defaults` |
| [tinygrad/codegen/simplify.py:140](../../../tinygrad/tinygrad/codegen/simplify.py#L140) | `graph_rewrite`: `pm` | `'reduce_collapse'` | `defaults` |
| [tinygrad/engine/jit.py:67](../../../tinygrad/tinygrad/engine/jit.py#L67) | `graph_rewrite`: `PatternMatcher([])` | `'View captured linear'` | `defaults` |
| [tinygrad/engine/jit.py:74](../../../tinygrad/tinygrad/engine/jit.py#L74) | `graph_rewrite`: `PatternMatcher([])` | `'View graphed linear'` | `defaults` |
| [tinygrad/engine/realize.py:290](../../../tinygrad/tinygrad/engine/realize.py#L290) | `graph_rewrite`: `pm_validate` | `'validate'` | `walk=True` |
| [tinygrad/engine/realize.py:291](../../../tinygrad/tinygrad/engine/realize.py#L291) | `graph_rewrite`: `pm_beam` | `—` | `walk=True` |
| [tinygrad/function.py:74](../../../tinygrad/tinygrad/function.py#L74) | `graph_rewrite`: `pm_ctx` | `'get_implicit_inputs'` | `bottom_up=True` |
| [tinygrad/runtime/support/hcq2.py:468](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L468) | `graph_rewrite`: `pm_rdma_encode + sum([d.pm_encode for d in devs if d.pm_encode is not None], PatternMatcher([])) + pm_hcq_encode` | `'encode'` | `bpm=pm_patches` |
| [tinygrad/runtime/support/hcq2.py:470](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L470) | `graph_rewrite`: `sum([d.pm_lower for d in devs if d.pm_lower is not None], PatternMatcher([]))` | `'lower'` | `bpm=pm_patches` |
| [tinygrad/runtime/support/hcq2.py:494](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L494) | `graph_rewrite`: `pm_renumber` | `—` | `walk=True, enter_calls=True` |
| [tinygrad/runtime/support/hcq2.py:496](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L496) | `graph_rewrite`: `PatternMatcher([])` | `'View Link-Time Patches'` | `defaults` |
| [tinygrad/runtime/support/hcq2.py:497](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L497) | `graph_rewrite`: `PatternMatcher([])` | `'View Body'` | `defaults` |
| [tinygrad/runtime/support/hcq2.py:513](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L513) | `graph_rewrite`: `pm_replace_buffers` | `'replace buffers'` | `walk=True` |
| [tinygrad/runtime/support/hcq2.py:514](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L514) | `graph_rewrite`: `pm_unwrap_multi + pm_insert_copy_staging + pm_flatten_linear` | `'prep calls'` | `defaults` |
| [tinygrad/runtime/support/hcq2.py:516](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L516) | `graph_rewrite`: `pm_encode` | `'encode'` | `walk=True` |
| [tinygrad/runtime/support/hcq2.py:589](../../../tinygrad/tinygrad/runtime/support/hcq2.py#L589) | `graph_rewrite`: `pm_link` | `'link'` | `walk=True` |
| [tinygrad/runtime/support/usb.py:341](../../../tinygrad/tinygrad/runtime/support/usb.py#L341) | `graph_rewrite`: `pm_usb_copy_slicer` | `'usb copy slicer'` | `defaults` |
| [tinygrad/schedule/__init__.py:102](../../../tinygrad/tinygrad/schedule/__init__.py#L102) | `graph_rewrite`: `pm_post_sched_cache` | `'params to buffers'` | `walk=True` |
| [tinygrad/schedule/__init__.py:165](../../../tinygrad/tinygrad/schedule/__init__.py#L165) | `graph_rewrite`: `sym + pm_mops + pm_flatten_range + pm_simplify_ranges` | `'simplify ranges in copy'` | `defaults` |
| [tinygrad/schedule/__init__.py:187](../../../tinygrad/tinygrad/schedule/__init__.py#L187) | `graph_rewrite`: `pm_schedule` | `'schedule to linear'` | `enter_calls=True` |
| [tinygrad/schedule/__init__.py:190](../../../tinygrad/tinygrad/schedule/__init__.py#L190) | `graph_rewrite`: `pm_resolve_linear_call` | `'resolve linear call'` | `defaults` |
| [tinygrad/schedule/__init__.py:193](../../../tinygrad/tinygrad/schedule/__init__.py#L193) | `graph_rewrite`: `pm_copy_from_store` | `'create COPY kernels for SDMA'` | `defaults` |
| [tinygrad/schedule/indexing.py:165](../../../tinygrad/tinygrad/schedule/indexing.py#L165) | `graph_rewrite`: `symbolic + pm_simplify_valid + pm_drop_and_clauses` | `'reshape'` | `defaults` |
| [tinygrad/schedule/indexing.py:178](../../../tinygrad/tinygrad/schedule/indexing.py#L178) | `graph_rewrite`: `symbolic + pm_simplify_valid` | `'pad'` | `defaults` |
| [tinygrad/schedule/indexing.py:193](../../../tinygrad/tinygrad/schedule/indexing.py#L193) | `graph_rewrite`: `pm_generate_realize_map` | `'get realize'` | `defaults` |
| [tinygrad/schedule/indexing.py:259](../../../tinygrad/tinygrad/schedule/indexing.py#L259) | `graph_rewrite`: `symbolic` | `'minimum_valid'` | `defaults` |
| [tinygrad/schedule/indexing.py:315](../../../tinygrad/tinygrad/schedule/indexing.py#L315) | `graph_rewrite`: `pm_apply_rangeify` | `'apply rangeify'` | `bottom_up=True` |
| [tinygrad/schedule/indexing.py:317](../../../tinygrad/tinygrad/schedule/indexing.py#L317) | `graph_rewrite`: `pm_fix_deviceless` | `'add device to deviceless'` | `defaults` |
| [tinygrad/schedule/multi.py:276](../../../tinygrad/tinygrad/schedule/multi.py#L276) | `graph_rewrite`: `multi_pm` | `'subcall'` | `defaults` |
| [tinygrad/schedule/prepare.py:102](../../../tinygrad/tinygrad/schedule/prepare.py#L102) | `graph_rewrite`: `pm_gather_params` | `'gather params'` | `bottom_up=True` |
| [tinygrad/schedule/prepare.py:220](../../../tinygrad/tinygrad/schedule/prepare.py#L220) | `graph_rewrite`: `multi_pm` | `'multi_pm'` | `defaults` |
| [tinygrad/schedule/prepare.py:221](../../../tinygrad/tinygrad/schedule/prepare.py#L221) | `graph_rewrite`: `pm_fold_moved_after` | `'fold moved afters'` | `defaults` |
| [tinygrad/schedule/prepare.py:222](../../../tinygrad/tinygrad/schedule/prepare.py#L222) | `graph_rewrite`: `pm_mops + earliest_rewrites` | `'earliest rewrites'` | `bottom_up=True` |
| [tinygrad/schedule/rangeify.py:357](../../../tinygrad/tinygrad/schedule/rangeify.py#L357) | `graph_rewrite`: `to_define_global + pm_flatten_range` | `'kernel split'` | `bottom_up=True` |
| [tinygrad/schedule/rangeify.py:372](../../../tinygrad/tinygrad/schedule/rangeify.py#L372) | `graph_rewrite`: `symbolic + pm_reduce_simplify + pm_const_buffer_folding + pm_remove_bufferize` | `'symbolic+reduce_collapse+debuf'` | `defaults` |
| [tinygrad/schedule/rangeify.py:376](../../../tinygrad/tinygrad/schedule/rangeify.py#L376) | `graph_rewrite`: `pm_limit_bufs` | `'limit buffers'` | `defaults` |
| [tinygrad/schedule/rangeify.py:377](../../../tinygrad/tinygrad/schedule/rangeify.py#L377) | `graph_rewrite`: `PatternMatcher([])` | `'View Rangeify'` | `defaults` |
| [tinygrad/schedule/rangeify.py:382](../../../tinygrad/tinygrad/schedule/rangeify.py#L382) | `graph_rewrite`: `pm_add_buffers + pm_add_param_range_tags` | `'stage to store'` | `bottom_up=True` |
| [tinygrad/schedule/rangeify.py:383](../../../tinygrad/tinygrad/schedule/rangeify.py#L383) | `graph_rewrite`: `split_kernels` | `'split kernels'` | `bottom_up=True` |
| [tinygrad/schedule/rangeify.py:384](../../../tinygrad/tinygrad/schedule/rangeify.py#L384) | `graph_rewrite`: `pm_no_indexing_calls` | `'remove indexing from call args'` | `defaults` |
| [tinygrad/schedule/rangeify.py:385](../../../tinygrad/tinygrad/schedule/rangeify.py#L385) | `graph_rewrite`: `pm_no_views` | `'remove views from the kernel graph'` | `defaults` |
| [tinygrad/schedule/rangeify.py:387](../../../tinygrad/tinygrad/schedule/rangeify.py#L387) | `graph_rewrite`: `PatternMatcher([])` | `'View Kernel Graph'` | `defaults` |
| [tinygrad/tensor.py:80](../../../tinygrad/tinygrad/tensor.py#L80) | `graph_rewrite`: `multi_pm` | `'multi_buffer_view'` | `defaults` |
| [tinygrad/tensor.py:179](../../../tinygrad/tinygrad/tensor.py#L179) | `graph_rewrite`: `pm_canonicalize_unbound` | `—` | `bottom_up=True` |
| [tinygrad/tensor.py:199](../../../tinygrad/tinygrad/tensor.py#L199) | `graph_rewrite`: `PatternMatcher([])` | `'View Tensor Graph'` | `defaults` |
| [tinygrad/tensor.py:206](../../../tinygrad/tinygrad/tensor.py#L206) | `graph_rewrite`: `add_tags` | `'add tags'` | `bottom_up=True` |
| [tinygrad/tensor.py:221](../../../tinygrad/tinygrad/tensor.py#L221) | `graph_rewrite`: `pm_early_transform_tensor_graph` | `'early transform tensor graph'` | `defaults` |
| [tinygrad/tensor.py:230](../../../tinygrad/tinygrad/tensor.py#L230) | `graph_rewrite`: `pm_drop_after` | `—` | `defaults` |
| [tinygrad/tensor.py:231](../../../tinygrad/tinygrad/tensor.py#L231) | `graph_rewrite`: `pm_replace_buf + remove_all_tags` | `'replace bufs'` | `bottom_up=True` |
| [tinygrad/tensor.py:233](../../../tinygrad/tinygrad/tensor.py#L233) | `graph_rewrite`: `PatternMatcher([])` | `'View Call'` | `defaults` |
| [tinygrad/uop/ops.py:497](../../../tinygrad/tinygrad/uop/ops.py#L497) | `graph_rewrite`: `symbolic` | `'simplify'` | `defaults` |
| [tinygrad/uop/ops.py:514](../../../tinygrad/tinygrad/uop/ops.py#L514) | `graph_rewrite`: `extra_pm + _substitute if extra_pm is not None else _substitute` | `name` | `bottom_up=True, walk=walk, enter_calls=enter_calls` |
| [tinygrad/uop/ops.py:910](../../../tinygrad/tinygrad/uop/ops.py#L910) | `graph_rewrite`: `pm_mops + symbolic + pm_contiguous_view_offset` | `'contiguous_view_offset'` | `defaults` |
| [tinygrad/uop/ops.py:1005](../../../tinygrad/tinygrad/uop/ops.py#L1005) | `graph_rewrite`: `pm_unbind` | `—` | `defaults` |
| [tinygrad/uop/ops.py:1240](../../../tinygrad/tinygrad/uop/ops.py#L1240) | `graph_rewrite`: `_pm_resolve_params` | `—` | `walk=True` |
| [tinygrad/uop/upat.py:156](../../../tinygrad/tinygrad/uop/upat.py#L156) | `graph_rewrite`: `pm_proc` | `'process UPat'` | `defaults` |
| [tinygrad/uop/upat.py:158](../../../tinygrad/tinygrad/uop/upat.py#L158) | `graph_rewrite`: `pm_renderer` | `'compile UPat'` | `defaults` |

## Reproduce the scope

Use Python `ast.parse` over `Path("tinygrad/tinygrad").rglob("*.py")`; count `ast.Call` nodes with `isinstance(call.func, ast.Name)` and `call.func.id == "PatternMatcher"`. The same condition with `graph_rewrite` / `line_rewrite` selects driver sites. Include nested functions/classes and do not follow imports. Static inspection performs no imports or device initialization. The inventory was generated with this algorithm against the revision above.

## Regenerate

Generator: [generate-matcher-inventory.py](generate-matcher-inventory.py). Run from the workspace root:

```bash
python3 boop-docs/compiler-maps/tinygrad/generate-matcher-inventory.py
# Optional alternate checkout/output:
python3 boop-docs/compiler-maps/tinygrad/generate-matcher-inventory.py \
  --tinygrad-path /path/to/tinygrad --output /path/to/matcher-inventory.md
```

Defaults resolve relative to the script, so the first command can also be invoked by absolute path from another working directory. Only Python's standard library and git are needed. Counts describe the selected worktree; HEAD and source-directory cleanliness are recorded above. Regeneration does not update the manually maintained semantic guide or validate its explanations against a new revision.
