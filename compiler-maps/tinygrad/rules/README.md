# Tinygrad: individual pattern-matching rules

This reference explains the production rule templates in tinygrad master
`107adc31701df0247dfa45e175984df906a68b53`. The upstream master ref was checked
again when this extension began and still pointed to that revision.

Start with the [matcher mechanics](../uops-and-rewrites.md) if `UPat`, callback
bindings, matcher composition, or traversal order is unfamiliar. For the GPU
questions, read the [AMD guide](../amd-pattern-matchers.md) and
[IMAGE guide](../image-pattern-matchers.md), then follow their individual rules
below. The [RMSNorm study](../rmsnorm-kernel-fusion.md) shows how the passes fit
into actual kernels rather than isolated expression transformations.

## How to read one rule

A compiler represents a calculation as connected operation nodes, called **UOps** in tinygrad. A **pattern** recognizes a particular arrangement of nodes; a Python **callback** decides what to return. For example, a schematic integer rule recognizes `ADD(x, 0)` and returns the existing node `x`. This changes the program description; it does not add zero to each array element while matching. The optional [first-principles guide](../../first-principles.md) introduces these ideas across compilers.

Use each entry in this order:

1. Read the example to identify the before/after change. An arrow usually describes one rule, not the complete compiled result.
2. Read the pattern and its named inputs. Repeated names require the same graph node, not merely two values that happen to compare equal.
3. Read the **guards**, the additional conditions checked before accepting the match. A dtype, index bound, execution phase, or hardware generation can be essential to correctness.
4. Read the rationale and sharp edge together. The rationale explains the useful problem the rule solves; the sharp edge explains why that reasoning cannot be applied everywhere.
5. Follow the source link if you need the exact implementation, then use the surrounding matcher/pass to establish when the rule runs. A **pass** visits a graph and applies rules; earlier rules can take priority, and later rules can transform the result again.

For `ADD(x,0) -> x`, recognizing ADD is a structural test, checking the numeric domain is a semantic restriction, and returning `x` is the replacement. Those are separate parts of the explanation. The same pattern machinery also recognizes valid graphs or emits target code: a boolean result checks a condition, and a string result emits text. Neither is an arithmetic optimization.

For a first reading, take one expression through symbolic arithmetic → scheduling → core codegen → the renderer for your target. **Scheduling** chooses stored intermediates and kernel boundaries; **codegen** implements each chosen kernel; **rendering** expresses it in the target language. Use the remaining chapters when that path reaches their responsibilities. Reading all 926 entries in filename order is unnecessary to follow one compilation.

## Chapters

| Rules | What the individual examples explain |
| --- | --- |
| [Symbolic arithmetic, div/mod, movement](symbolic.md) | Why seemingly strange forms help range proofs, masking, indexing, and normalization; where algebraic assumptions stop being safe. |
| [Specs, validation, and weak typing](spec-and-types.md) | Accepted/rejected IR, Z3 translation, width commitment, and the difference between validating and rewriting. |
| [Scheduling and sharding](scheduling.md) | Movement, staging, kernel boundaries, range propagation, distributed reductions, and call construction. |
| [Core codegen](codegen.md) | Reduction accumulators, vector expansion, launch coordinates, gate movement, barriers, control flow, and program assembly. |
| [Dtype and operation decompositions](decompositions.md) | Unsupported arithmetic/dtypes, integer division, generated transcendental rules, numerical conditions, and target selection. |
| [C-style renderers](render-cstyle.md) | Shared C-family emission, OpenCL/IMAGE, Metal, CUDA, HIP, and dtype conversion helpers. |
| [LLVM and AMD matrix fragments](render-llvm-tc.md) | LLVM emission, AMD intrinsics, RDNA/CDNA fragment adaptation, and architecture guards. |
| [PTX and WGSL](render-ptx-wgsl.md) | Predicate versus byte storage, architecture-specific half operations, packed storage, atomics, and target syntax. |
| [NIR and image/coalescing rules](render-nir-image.md) | NIR builders, Adreno image operations, memory grouping, and image promotion. |
| [x86 instruction selection](render-x86.md) | Instruction forms, register constraints, flags, ABI, spills, and pre/post-allocation repairs. |
| [Runtime and execution](runtime-and-execution.md) | Dispatch, queue packets, address patching, RDMA, USB, linking, and execution-side callbacks. |
| [Tensor/autograd and UOp tools](frontend-and-uop-tools.md) | Tensor graph updates, derivatives, substitutions, debug/source rendering, and compiled matcher predicates. |

## What “every rule” means here

The [coverage ledger](coverage.json) records **926 source rule templates**
across **180 direct `PatternMatcher` construction sites**. These include every
direct constructor under the production `tinygrad/` package, local rule lists
built by factories, comprehensions, and starred generator templates. Empty
instrumentation matchers contain no rules. Matcher addition composes existing
templates rather than defining new ones.

A **rule template** is a source definition that can generate several concrete rules. For example, a loop can create the same conversion pattern for several numeric types; the source template is counted once, with its variants explained together.

A template instantiated for several operations, dtypes, buffer names, or
architectures gets an explanation of the template and its parameter cases.
There is no finite, universal count of all matcher objects and bindings created
at runtime. Test-only patterns, example programs under `extra/`, and generated
external/compiler rules are outside this production-package reference.

Each entry is keyed by its actual source path and line. It explains the
pattern, callback conditions, result, a concrete example, and the reason or
constraint behind it. Some entries produce strings, booleans, queue commands,
or host-side results rather than replacement UOps. A callback returning `None`
can mean a correct rejection, not a missed optimization.

Examples are schematic and source-derived unless explicitly marked executed.
They describe one rule's effect, which can differ from a complete fixed-point
rewrite's final output. Earlier rules, traversal order, and subsequent cleanup
can prevent an example's intermediate form from appearing in a full trace. A **fixed point** is the result after repeated rewriting makes no further change; a **trace** records the transformations actually taken in one run.

“Why” also has an evidence boundary. A source comment can state a workaround
or intended invariant; the implementation can establish behavior; a commit can
establish a historical change. Where the original author's reason is not
recorded, the guide labels the design explanation as inference. It does not
invent a bug report, hardware erratum, or measured speed benefit to make a rule
sound more justified.

## Updating and checking coverage

From the workspace root:

```sh
python3 boop-docs/compiler-maps/tinygrad/rules/audit-coverage.py --check
```

The script parses source without importing tinygrad or opening devices. It
resolves direct literal rule lists and local list construction through
assignment, `+=`, `append`, `extend`, and comprehensions. `coverage.json` records
the exact pattern/callback expressions, constructor sites, and matching
explanation headings. Missing headings and unresolved constructors are reported.
With `--check`, either condition makes the command fail. The committed ledger
records **926/926 templates with corresponding explanation headings**, with no
unresolved constructors. Headings are checked for existence, not semantic
correctness; examples and explanations still require review.
The two rules on `runtime/support/hcq2.py:408` are distinct templates despite
sharing a source line.

This is a coverage check, not a proof that every example or transformation is
correct. After changing tinygrad, re-audit the prose and guards rather than
merely updating line numbers or regenerating the ledger. Hardware behavior
requires execution on the relevant target; these explanations do not replace
that validation.

The checked examples include five CPU-only AMD fragment probes, six IMAGE
probe groups, the image-validity suite (**40 passed, 1 xfailed**), and
[20 CPU/Z3 assertions](probes/spec_and_types.py). Independent source review
sampled chip guards, packed memory, numerical decomposition, WMMA, barriers,
and gates. Other individual examples are explicitly schematic; full coverage
of source templates is not exhaustive execution coverage.
