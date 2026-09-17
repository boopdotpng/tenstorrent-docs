# From an array expression to a running program

These guides assume basic Python and arrays. They do not require prior compiler
knowledge. Start here, then follow one system's execution path. Use the large
rule catalogues when a particular transformation needs explanation.

The recurring question is: **what must the computer decide between the formula
we write and the instructions it executes?** Different frameworks make those
decisions at different times and record them in different forms.

Examples on this page explain concepts. They are not additional measured
results. The linked case studies identify their actual source versions,
execution environments, and checks.

## 1. Start with a computation, not a compiler term

Suppose one row of data is `x = [3, 4]` and a learned weight is `w = [1, 2]`.
RMSNorm rescales the row using its root mean square, then multiplies each
position by its weight:

```text
square each element:       [9, 16]
mean of those squares:     (9 + 16) / 2 = 12.5
square root:               sqrt(12.5) ≈ 3.5355
normalize each element:    [3 / 3.5355, 4 / 3.5355] ≈ [0.8485, 1.1314]
apply the weights:         [0.8485 * 1, 1.1314 * 2] ≈ [0.8485, 2.2627]
```

This hand calculation omits epsilon to keep the arithmetic visible. The real
examples use a small positive epsilon inside the square root so an all-zero
row does not require division by zero. They also specify floating-point types,
which matter because machine arithmetic rounds.

Two kinds of work appear here. Squaring and weighting operate independently
on each element: they are **elementwise** operations. Computing the mean
combines several elements into one result: it is a **reduction**. Normalizing
then uses that one result for every position in the row: this is a
**broadcast**. Broadcasting need not create an array of repeated copies.

For a matrix shaped `[B, H]`, `B` counts rows and `H` counts elements in each
row. Each row gets its own normalization statistic. Reducing the last dimension
while keeping a length-one dimension gives shape `[B, 1]`, which can broadcast
back across `[B, H]`. Dropping that dimension can change the meaning of the
later broadcast; shape is part of the computation's semantics.

## 2. The formula leaves several execution decisions open

The formula says what values to compute. It does not say where intermediate
values live or who computes them. A system still needs to decide:

1. Does it store every squared element, or feed squares directly into a sum?
2. Does one worker sum an entire row, or do several workers compute partial sums?
3. Does it retain the row's input, or read it again after the mean is ready?
4. Does it store the normalized row before a following matrix multiplication?
5. Which arithmetic instructions or external library routines should it use?
6. How does the host make the result ready for its next consumer?

A **compiler** makes and encodes execution choices before the corresponding
work runs. A **runtime** allocates memory, loads executable code, submits work,
and manages execution dependencies. The boundary varies: a compiler can run
inside the application just before execution, and a runtime may choose among
already compiled implementations.

**Eager execution** dispatches an operation when the application reaches it.
**Lazy execution** records requested computation and delays its execution.
Eager GPU code can still be asynchronous: submitting a command now is not the
same as waiting for the GPU to finish it.

In normal tinygrad use, Tensor expressions accumulate before realization.
In normal PyTorch eager use, tensor operations dispatch as Python runs.
`torch.compile` captures regions of a PyTorch program for a compiler to optimize.
The [design comparison](design-comparison.md) explains the consequences without
assuming that one strategy always produces faster code.

## 3. A compiler needs a record it can inspect and change

An **intermediate representation**, abbreviated **IR**, is that record. It is
neither necessarily Python source nor machine code. It represents computation
in a form that makes some decisions explicit while leaving others open.

For `a = x * x; b = mean(a); y = x / sqrt(b + eps)`, a graph representation can
record operations and the values passed between them:

```text
x ── multiply(x,x) ── mean ── add(eps) ── sqrt ── denominator
│                                                        │
└────────────────────── divide(x, denominator) ◄──────────┘
                                  │
                                  y
```

The intended dependency is `divide(x, sqrt(mean(x*x) + eps))`: division needs
both `x` and the completed denominator. Graph arrows describe dependencies,
not necessarily a separate kernel or stored array for every node.

A **node** records an operation or value. Its **inputs**, also called
**operands** or **sources**, refer to other nodes. A **DAG** is a directed
acyclic graph: dependencies have a direction and do not form cycles. A loop
can be represented by a special operation with a body, rather than by drawing
a cycle through ordinary value dependencies.

Tinygrad's node type is called a **UOp**. A UOp graph can describe high-level
tensor work or lower-level loops and memory operations, depending on the
compiler stage. **FX** is a graph representation used by PyTorch. **MLIR** is
infrastructure for constructing IRs; a **dialect** defines a vocabulary of
operations and their meaning within that infrastructure.

Do not read an operation name as a full specification. Ask what its inputs,
result types, attributes, side effects, and current compiler stage mean.
An **attribute** is metadata carried with an operation, such as a constant
axis number. An **invariant** is a condition a stage promises will hold, such
as “every memory read now has an explicit address and access type.”

## 4. Values, storage, and views are different things

A **value** is the result a computation promises. A **buffer** is storage in
which values can be placed. A **view** describes existing storage through a
different shape, offset, or stride, usually without copying its contents.

A **stride** says how far to move in storage when an index increases by one.
For a conventional two-by-three row-major array, the row stride is three
numbers and the column stride is one. A transpose can exchange the strides
without moving the numbers. Its visible shape changes even though its storage
is shared. This is **aliasing**: two references can reach the same memory.

For example, if `v` views `x`, a write through `x` can change what `v` later
reads. A compiler must preserve that observation. It cannot assume that a view
is an independent snapshot.

**SSA**, or static single assignment, represents each computed value with a
name assigned once. Conceptually, an update can become `x1 = update(x0)`.
Keeping `x0` and `x1` distinct makes old-versus-new observations visible in IR.
It does not itself allocate two physical arrays.

**Bufferization** decides how tensor values correspond to mutable storage.
**Materialization** means making a value exist in storage for later use.
**Liveness** asks whether some future computation can still need a value.
Storage reuse is safe only after accounting for old readers, aliases, and
unfinished asynchronous work. Equal shapes are not a proof of safe reuse.

## 5. Rewriting is a conditional change to the representation

A **pattern** describes a shape of IR to recognize. A **rewrite rule** describes
what to do when that shape and any additional conditions match. For example,
for ordinary integer arithmetic:

```text
before: ADD(x, 0)
after:  x
```

Here `x` is a pattern variable that binds to a node. It is not a request to
compute the node. A callback can inspect the binding and refuse a change.
A **guard** is a condition for accepting the change, such as a known dtype,
index bound, alignment, or absence of another consumer.

“Looks mathematically equivalent” is insufficient. Consider replacing division
by two with a right shift. For negative signed integers, a right shift's usual
arithmetic behavior matches floor division, but not truncation toward zero:
`floor(-3/2) = -2`, while truncating `-3/2` gives `-1`. The correct rule depends
on which division operation the IR represents.

Likewise, floating-point operations round, and invalid or masked values can
have special compiler meaning. A rule may therefore apply only in a particular
phase or under particular numerical assumptions.

A **matcher** finds an applicable rule. A **rewrite driver** chooses which nodes
to visit and whether to revisit replacements. A **pass** is a scheduled unit of
compiler work; it may use many rules or perform a larger analysis. Repeating
rules until none changes the graph reaches a **fixed point**, but that alone
does not prove that the output can run on the target.

**Lowering** replaces a representation with one closer to the execution model:
for example, a mean operation becomes loops, additions, and division by a count.
**Legalization** establishes that remaining operations satisfy a target's
supported forms. **Canonicalization** puts equivalent expressions into useful
standard forms. These purposes overlap in real implementations but are not
interchangeable promises.

## 6. Fusion is about boundaries and their consequences

A **kernel** is an executable unit of computation. A **dispatch** or **launch**
submits work for execution. In these guides, a CPU compiled function may also
be counted as a kernel; each experiment defines its counting unit. A
Tenstorrent dispatched program can contain cooperating compute and data-movement
functions, so “one kernel” needs particular care there.

Suppose K1 computes row statistics and stores them; K2 reads them and normalizes
rows. Their boundary can provide both storage and execution ordering. Combining
their work requires a way for every normalization to see the completed statistic.
If several GPU workgroups contribute partial sums, a barrier within one group
does not automatically wait for the others.

**Fusion** combines computations into a shared execution unit. It can avoid a
launch, intermediate storage, or repeated reads. It can also increase storage
pressure, duplicate arithmetic, or reduce available parallel work. A fused CPU
function may still contain two loops and a scratch array. One graph operation
may still require multiple device kernels.

This is why the case studies record the intermediate buffers and actual calls,
not just a number named “kernel count.” See the executed
[tinygrad RMSNorm study](tinygrad/rmsnorm-kernel-fusion.md) and
[PyTorch eager/compiled study](pytorch/rmsnorm-eager-vs-compile.md). Their versions
and shapes differ; they are explanations of execution choices, not a speed
comparison between frameworks.

## 7. The small hardware vocabulary needed later

| Term | Meaning in these guides | Why it affects compilation |
| --- | --- | --- |
| Dtype | Representation of an element, such as signed 32-bit integer or 16-bit float. | Determines available values, rounding, storage size, and legal instructions. |
| Cast / bitcast | A cast converts a value; a bitcast reinterprets the stored bits. | Converting float 1.0 to integer 1 is different from interpreting its float encoding as integer bits. |
| Register | Small, directly addressed storage used by instructions. | Limited availability can constrain fusion or require extra memory accesses. |
| Spill | Save a value from a register to memory and reload it when needed. | A larger fused computation may exceed available registers. |
| Lane / vector | One position in a group of values / operations arranged to process several positions together. | The compiler must preserve which element belongs to which lane. |
| Warp / wave / workgroup | Hardware/backend-specific groupings of GPU threads. | Cooperation and synchronization are limited by the grouping and target. These names are not universally interchangeable. |
| Tile / fragment | A tile is a block of tensor elements; a matrix-instruction fragment is the portion in a prescribed thread/register layout. | A matrix instruction expects a specific arrangement, not merely the right total number of numbers. |
| Global / local memory | Distinct address spaces; GPU “local” in these compiler discussions often means storage shared within a workgroup. | Visibility and synchronization differ. Read the target's definition rather than assuming “local” means a private CPU variable. |
| Alignment / pitch | Alignment constrains an address to a byte multiple; pitch is the storage spacing between successive rows. | Vector and image accesses may require both. |
| ABI | Application binary interface: the agreement for argument order, representation, results, and calling conventions. | Generated code and its caller must agree even if their internal representations differ. |
| DMA / NoC / CB | Direct memory access; network on chip; circular buffer. | Tenstorrent programs coordinate transfers and finite producer/consumer storage, in addition to arithmetic. |

Backend-specific chapters explain their exact meanings and constraints before
using them in individual rules.

## 8. Capturing Python adds another kind of guard

Suppose a Python function uses an array's shape to choose an operation. A
compiler may generate code specialized for the observed shape. Reusing that
code later requires a **runtime guard** that checks its assumptions. This is
different from a rewrite rule's callback guard, although both are conditions.

A failed runtime guard can trigger recompilation or another permitted execution
path. A **graph break** ends one captured region and resumes Python, potentially
capturing more regions later. A **dynamic shape** is represented symbolically
instead of being fixed to one observed size; it can still need constraints and
guards. Capturing one graph does not promise one kernel.

PyTorch's **functionalization** represents mutation using explicit functional
updates so later transformations can reason about it, then preserves the
program's observable mutations and aliases at the boundary. **Autograd**
constructs the derivative computation needed for training. If `y=x*x`, then an
incoming derivative `g` contributes `2*x*g` to the derivative for `x`. The
backward program may need forward values saved in memory or recomputed.

Those requirements explain why capture, differentiation, scheduling, and code
generation are separate topics in the [PyTorch guide](pytorch/README.md).

## How to use the rest of the collection

1. Read one system's ordinary path: [tinygrad](tinygrad/uops-and-rewrites.md#uops-and-rewrites),
   [PyTorch eager](pytorch/eager-execution.md#eager-execution), or [MLIR](mlir/README.md#mlir).
2. Follow a full RMSNorm case, locating the data and execution boundaries.
3. Read the [design comparison](design-comparison.md) to understand why the
   other systems organize the same obligations differently.
4. Use the [individual rule reference](tinygrad/rules/README.md) when a specific
   transformation is unclear. It is a lookup reference, not a prerequisite for
   understanding a complete program.
5. Attempt an exercise before reading its solution. State the value, storage,
   and ordering conditions before predicting generated code.

When an unfamiliar name appears, ask: what does it represent, who produces it,
who consumes it, and what must remain true when it changes? The source maps and
rule explanations are organized to answer those questions.
