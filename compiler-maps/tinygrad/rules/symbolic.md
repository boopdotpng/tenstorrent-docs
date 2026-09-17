# Every symbolic, div/mod, and movement rewrite rule

Pinned source: tinygrad `107adc31701df0247dfa45e175984df906a68b53`. This guide covers every outer production rule tuple/template in `uop/symbolic.py`, `uop/divandmod.py`, and `uop/movement.py`; it is one part of the complete rule catalog. The disabled MAX-distribution comment at symbolic.py:277 is **not an active rule**; the source asks why it breaks `beautiful_mnist` and does not supply an answer.

Examples below are **source-reviewed illustrative transformations, not executed traces**. An arrow may show constant folding after the displayed callback; a larger composed matcher can select an earlier rule. The exact source excerpt under each entry is the match, guards, and replacement, including dtype constraints. The prose then explains what the callback actually means. “Why” is a mathematical/implementation rationale inferred from the current code unless explicitly labeled as a source comment; it is not a claim about the commit that originally introduced a rule.

Notation: `c ? x : y` means WHERE; `//` and `%` mean floor division/modulo, not truncating C division. `Invalid` is an absent-value sentinel, **not NaN or zero**. `weakint` is mathematical index arithmetic before commitment to a physical integer width. Bare `CONST` and `CAST(CONST)` are different constant spellings. `UPat.var` means a named matching subgraph, not necessarily an input variable; repeated names require identical graph nodes. A tuple of sources is ordered; a list permits permutation. Pattern arithmetic also follows operation commutativity. Rules return None when a match is not safe/useful under their proof or policy. A guard missing from the source must not be invented to make a tempting algebraic identity look universally sound.

`symbolic_simple = pm_data_invalid + simple rules + mop_cleanup`; `symbolic` adds commutative/deeper rules, div/mod, and `pm_uncast_const`; `sym` adds validity simplification, final rules, and root cleanup. The separately defined matchers `pm_remove_invalid`, `pm_drop_and_clauses`, and `pm_move_where_on_load` are context-specific passes. In particular, dropping unrelated validity clauses is used by reshape index analysis in `schedule/indexing.py`, not as a universal algebraic law. The weak-constant matcher imported here is cataloged with `uop/weak.py` elsewhere.

For IMAGE, start with **symbolic.py:L442**: it deliberately declines a range-based simplification that would otherwise appear mathematically reasonable. Its comment identifies IMAGE/openpilot but does not give a detailed hardware failure history. For floating data, many algebraic rules are explicitly or implicitly less strict than IEEE bitwise equivalence; the counterexamples below are important when debugging a surprising result.

Coverage: **140 individually explained outer rule entries**, including the five-variant associative template; the general div/mod callback also has an internal-branch walkthrough.

## Before reading the rules: what problem is this algebra solving?

A tensor program repeatedly turns coordinates into addresses. For an array with eight columns, `(row, col)` becomes `8*row+col`. Reshaping and splitting loops can turn that back into divisions and remainders. These matchers remove the round trips, simplify conditions that protect memory, and reduce ordinary arithmetic. They rewrite **expressions in a graph**; they do not run a Python calculation on the tensor's current contents. See [the compiler first-principles guide](../../first-principles.md) for the surrounding pipeline.

A **node** is one operation; its `src` entries are the values it reads. A **pattern** recognizes a particular arrangement of nodes. The **callback** constructs a replacement, or returns `None` to decline. A **guard** is a restriction: sometimes a mathematical safety proof, sometimes a choice to avoid extra work, and sometimes a workaround. Those are different reasons for refusing a rewrite. Repeated `x` in a pattern means the same graph node; it does not compare two arrays at runtime.

Read the notation as follows:

- `i∈[0,7]` means an integer i from 0 through 7, inclusive. `[0,8)` excludes 8. `RANGE(8)` supplies the coordinates 0 through 7. `vmin` and `vmax` are conservative bounds computed by the compiler; they need not describe every reachable value between the endpoints.
- `x//d` is the quotient rounded down. `x%d` is defined by `x = (x//d)*d + x%d`. Thus `-7//3=-3` and `-7%3=2`. Truncating division instead gives -2 and remainder -1. With positive d, a remainder is a digit in `[0,d)`; multiplying the quotient by d restores the whole groups.
- `p ? a : b`, `WHERE(p,a,b)` and `p.where(a,b)` all select a when p is true and b otherwise. `!p` means logical NOT; for booleans, `&` means AND and `|` means OR. These are graph expressions, not a promise that an unselected memory read will never execute.
- For integers, `&`, `|` and `^` act bit by bit (AND, OR, XOR); `<<k` moves bits left and `>>k` moves them right. In the **POW examples only**, `x^n` is mathematical exponentiation, written `x**n` in Python. The rule's operation name distinguishes those examples from XOR.
- A **validity mask** says which coordinates have a value. `Invalid`, also called *poison* here, marks absence rather than the number zero. `valid(i,p)` abbreviates attaching condition p to address i; memory lowering must suppress access when p is false. Replacing absence with zero too early could turn a suppressed access into a real one.
- **Affine** means a sum of coordinates multiplied by constants, plus an offset: `8*row+col+3`. A **coefficient** is one of those multipliers. A **congruence** says two numbers have the same remainder for a divisor: 7 and -1 are congruent modulo 8 because they differ by 8. **gcd** is the greatest positive integer dividing every stated coefficient.
- **Canonicalization** chooses one preferred spelling so later patterns need fewer variants. It does not always make the expression smaller immediately. **Folding** computes something at compile time; **hoisting** moves a calculation outside repeated work. A **reduction**, such as `sum_r(x[r])`, combines the values for every r into one result.

`weakint` keeps index calculations as mathematical integers. A physical dtype such as int32 instead has a finite range; float32 has finite precision. Algebra that is exact for mathematical numbers can overflow or round differently on a device. The entry's sharp edge is part of its explanation, not an optional afterthought.

## pm_data_invalid: propagate absence before arithmetic

### uop/symbolic.py:L80 — Broadcasting poison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L80). Exact pattern and callback:

```python
(invalid_pat.broadcast(), lambda i: i)
```

**Example:** broadcast(Invalid, 4) → Invalid

**Why / helper behavior:** Invalid denotes an absent value, not a scalar that needs four physical lanes. Source explicitly requires poison propagation before arithmetic folding.

**Walkthrough:** Broadcasting normally copies a scalar into several vector positions. Copying absence still provides no usable value in any position, so there is no vector of numbers to construct.

**Guard / sharp edge:** This is not broadcasting a numeric zero; eliminating the gate early could make an invalid memory access valid.

### uop/symbolic.py:L81 — Unary operations preserve poison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L81). Exact pattern and callback:

```python
(UPat(GroupOp.Unary|{Ops.CAST, Ops.BITCAST}, src=(invalid_pat,)), lambda i: i)
```

**Example:** sqrt(Invalid) → Invalid; cast<float>(Invalid) → Invalid

**Why / helper behavior:** No computation can recover a value from an invalid input; retain the sentinel until memory rules consume it.

**Walkthrough:** The rule retains the same marker through a conversion or a one-input arithmetic operation. It does not ask what square root or a bitcast of the marker would numerically mean.

**Guard / sharp edge:** The op set is Unary plus CAST and BITCAST, not every UOp with one source.

### uop/symbolic.py:L82 — Push unary computation inside validity

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L82). Exact pattern and callback:

```python
(UPat(GroupOp.Unary|{Ops.CAST, Ops.BITCAST}, src=(invalid_gate,), name="op"),
   lambda cond,x,op,i: cond.where(op.replace(src=(x,)), i))
```

**Example:** sqrt(c ? x : Invalid) → c ? sqrt(x) : Invalid

**Why / helper behavior:** The outer sentinel makes validity visible to later LOAD/STORE rewriting.

**Walkthrough:** When c is true, both expressions compute sqrt(x). When c is false, both must describe absence. Putting that absence on the outside lets a later memory rule see it without looking through sqrt.

**Guard / sharp edge:** The gate is in the false branch; the normalization rule handles the opposite orientation.

### uop/symbolic.py:L85 — Left operand carries validity

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L85). Exact pattern and callback:

```python
(UPat(GroupOp.Binary, src=(invalid_gate, UPat.var("y")), name="alu"), lambda cond,x,y,alu,i: cond.where(x.alu(alu.op,y), i))
```

**Example:** (c ? x : Invalid) + y → c ? (x+y) : Invalid

**Why / helper behavior:** Hoist the validity information without losing the operation on the valid branch.

**Walkthrough:** Check the false case before applying arithmetic identities: `(False ? x : Invalid)*0` is still absent. If multiplication by zero ran first, the compiler would lose the reason that this coordinate must not be accessed.

**Guard / sharp edge:** Even multiplying by zero must retain this gate: the source explicitly says poison must beat zero folding.

### uop/symbolic.py:L86 — Right operand carries validity

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L86). Exact pattern and callback:

```python
(UPat(GroupOp.Binary, src=(UPat.var("y"), invalid_gate), name="alu"), lambda cond,x,y,alu,i: cond.where(y.alu(alu.op,x), i))
```

**Example:** y - (c ? x : Invalid) → c ? (y-x) : Invalid

**Why / helper behavior:** Same propagation is needed for noncommutative binary operations in the other operand position.

**Walkthrough:** For the example, c=true gives y-x on both sides. Keeping y first is essential: copying the previous rule mechanically would produce x-y instead.

**Guard / sharp edge:** Operand order is preserved; this is not equivalent to the preceding rule for subtraction/division.

### uop/symbolic.py:L87 — Bare poison absorbs binary arithmetic

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L87). Exact pattern and callback:

```python
(UPat(GroupOp.Binary-GroupOp.Comparison, src=[invalid_pat, UPat()]), lambda i: i)
```

**Example:** Invalid * x → Invalid

**Why / helper behavior:** An ungated invalid value poisons arithmetic directly.

**Guard / sharp edge:** Comparisons are excluded; treating all comparisons as ordinary poisoned arithmetic would violate their separate boolean handling.

### uop/symbolic.py:L88 — Lift reduction-independent invalidity

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L88). Exact pattern and callback:

```python
(invalid_gate.reduce(allow_any_len=True, name="red"), lift_reduce_gate)
```

**Example:** sum_r((row_ok & r_ok(r)) ? x[r] : Invalid) → row_ok ? sum_r(r_ok(r) ? x[r] : Invalid) : Invalid

**Why / helper behavior:** Source rationale: a condition independent of reduction ranges invalidates every lane together. The helper partitions AND clauses by overlap with every reduced range, retaining dependent clauses inside.

**Walkthrough:** Think of a padded row reduction. If the entire row is outside the tensor, row_ok is false for every r; testing it inside every element repeats the same condition. The condition r_ok(r), however, may accept one column and reject another, so it stays inside the sum.

**Guard / sharp edge:** Only red.arg[1] == 0 is accepted. A condition depending on r cannot be lifted, and no independent clauses means no rewrite.

### uop/symbolic.py:L90 — An invalid selector invalidates selection

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L90). Exact pattern and callback:

```python
(invalid_pat.where(UPat(), UPat()), lambda i: i)
```

**Example:** Invalid ? a : b → Invalid

**Why / helper behavior:** There is no meaningful branch choice if the condition itself has no value.

**Guard / sharp edge:** This is sentinel semantics, not a numeric condition of zero.

### uop/symbolic.py:L91 — Lift validity from the selector

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L91). Exact pattern and callback:

```python
(invalid_gate.where(UPat.var("a"), UPat.var("b")), lambda cond,x,i,a,b: cond.where(x.where(a,b), i))
```

**Example:** (c ? p : Invalid) ? a : b → c ? (p ? a : b) : Invalid

**Why / helper behavior:** Makes the condition’s validity available at the outermost value.

**Guard / sharp edge:** The inner boolean p still chooses a/b; c is not a replacement for p.

### uop/symbolic.py:L93 — Put invalidity in the false branch

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L93). Exact pattern and callback:

```python
(UPat.var("cond").where(invalid_pat, UPat.var("val")), lambda cond, i, val: cond.logical_not().where(val, i) if not val.is_invalid else i)
```

**Example:** c ? Invalid : x → !c ? x : Invalid

**Why / helper behavior:** Source explicitly normalizes the orientation so the other invalid-gate patterns can be small.

**Guard / sharp edge:** If x is also Invalid, the result is Invalid, not a two-branch WHERE.

### uop/symbolic.py:L95 — Lift invalidity from the true value

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L95). Exact pattern and callback:

```python
(UPat.var("a").where(invalid_gate, UPat.var("c")), lambda cond,i,x,a,c:
   (a.logical_not()|cond).where(a.where(x,c), i) if not c.is_invalid else None)
```

**Example:** a ? (c ? x : Invalid) : z → (!a | c) ? (a ? x : z) : Invalid

**Why / helper behavior:** The inner c matters only when a selects that branch; !a makes z valid regardless of c.

**Walkthrough:** Split the cases: a=false selects z, so c is irrelevant and `!a|c` is true. For a=true, selecting x is legal exactly when c is true. That two-case truth table produces OR, not AND.

**Guard / sharp edge:** Requires z not invalid. Replacing the outer guard with a & c would incorrectly discard z.

### uop/symbolic.py:L97 — Lift invalidity from the false value

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L97). Exact pattern and callback:

```python
(UPat.var("a").where(UPat.var("b"), invalid_gate), lambda cond,i,x,a,b: (a|cond).where(a.where(b, x), i) if not b.is_invalid else None)
```

**Example:** a ? z : (c ? x : Invalid) → (a | c) ? (a ? z : x) : Invalid

**Why / helper behavior:** Symmetric conditional validity: selecting z bypasses c.

**Walkthrough:** When a=true the result z exists without consulting c. Only a=false needs c to make x available; `a|c` captures precisely those two routes to a valid result.

**Guard / sharp edge:** Requires z not invalid. Both gates cannot simply be ANDed.

### uop/symbolic.py:L99 — Erase a store to an invalid address

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L99). Exact pattern and callback:

```python
(UPat(Ops.STORE, src=(UPat(Ops.INDEX, src=(UPat(), invalid_pat), allow_any_len=True).or_casted(), UPat())), lambda i: UOp(Ops.NOOP))
```

**Example:** STORE(INDEX(buf, Invalid), x) → NOOP

**Why / helper behavior:** A masked-off write must have no memory effect; poison reaches its intended consumer here.

**Walkthrough:** For a padded launch, threads beyond the array end may still participate in arithmetic. This rule turns their absent destination into no write at all, rather than writing to a dummy address.

**Guard / sharp edge:** Only an INDEX with Invalid in its index position, optionally casted, matches; an arbitrary bad numeric address is not recognized.

### uop/symbolic.py:L100 — Replace a load from an invalid address

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L100). Exact pattern and callback:

```python
(UPat(Ops.LOAD, src=(UPat(Ops.INDEX, src=(UPat(), invalid_pat), allow_any_len=True).or_casted(),), allow_any_len=True, name="x"),
    lambda x,i: x.src[1] if len(x.src) > 1 else x.const_like(0))
```

**Example:** LOAD(INDEX(buf, Invalid), 7) → 7; without alternate → 0

**Why / helper behavior:** The masked load returns its alternate without touching memory.

**Walkthrough:** The alternate is the value requested when a read is masked off. For example, a caller asking for 7 on missing coordinates must keep 7; avoiding a read does not determine the replacement number by itself.

**Guard / sharp edge:** Keep an explicit alternate; replacing every masked load with zero loses caller semantics.

## pm_remove_invalid: materialize residual absent lanes

### uop/symbolic.py:L105 — Materialize remaining invalid lanes as zero

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L105). Exact pattern and callback:

```python
(invalid_gate.named("w"), lambda cond,x,i,w: w.replace(src=(cond,x,w.const_like(0))))
```

**Example:** c ? x : Invalid → c ? x : 0

**Why / helper behavior:** After validity has served its purpose, code emission needs ordinary representable values.

**Walkthrough:** This is a phase boundary: earlier, absence prevents memory effects; later, each emitted expression needs an ordinary dtype value. The same-looking replacement would be wrong if performed before the memory rules.

**Guard / sharp edge:** This separate matcher must not run before poison has suppressed invalid memory effects.

### uop/symbolic.py:L106 — Materialize invalid vector components

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L106). Exact pattern and callback:

```python
(UPat(Ops.STACK, name="s"), lambda s: s.replace(src=tuple(UOp.const(0, s.dtype) if x.is_invalid else x for x in s.src))
   if any(x.is_invalid for x in s.src) else None)
```

**Example:** STACK(3, Invalid, 5) → STACK(3, 0, 5)

**Why / helper behavior:** A final vector cannot contain the nonnumeric Invalid sentinel.

**Guard / sharp edge:** Only invalid components change, and the helper uses the stack dtype for zeros; valid lanes remain intact.

## symbolic_simple: local identities and constants

### uop/symbolic.py:L117 — Remove additive and bitwise zero identities

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L117). Exact pattern and callback:

```python
(UPat({Ops.ADD, Ops.XOR, Ops.OR}, src=[UPat.var("x"), UPat.const(0)]), lambda x: x)
```

**Example:** x+0 → x; x^0 → x; x|0 → x

**Why / helper behavior:** Cuts identity work and exposes the same x node to common-subexpression matching.

**Walkthrough:** If two later expressions both use x, returning the original node lets the compiler recognize that shared input directly. Leaving ADD(x,0) in one branch hides that identity behind an extra operation.

**Guard / sharp edge:** These are ADD/XOR/OR identities, not AND; floating signed-zero details are not guarded here.

### uop/symbolic.py:L118 — Remove zero-distance shifts

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L118). Exact pattern and callback:

```python
(UPat({Ops.SHL, Ops.SHR}, src=(UPat.var("x"), UPat.const(0))), lambda x: x)
```

**Example:** x<<0 → x; x>>0 → x

**Why / helper behavior:** No bits move, so the shift contributes no computation.

**Guard / sharp edge:** Only constant zero shift distance matches; a variable that happens to be zero requires separate bound folding.

### uop/symbolic.py:L119 — Remove multiplication by one

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L119). Exact pattern and callback:

```python
(UPat.var("x") * 1, lambda x: x)
```

**Example:** x*1 → x

**Why / helper behavior:** An identity introduced by shapes, coefficients, or lowering should not survive into kernels.

**Guard / sharp edge:** Poison handling runs earlier; this does not authorize replacing x*0 with x.

### uop/symbolic.py:L120 — Self floor-division

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L120). Exact pattern and callback:

```python
(UPat.var("x") // UPat.var("x"), lambda x: x.const_like(1))
```

**Example:** x//x → 1 (e.g. 7//7)

**Why / helper behavior:** Eliminates a structurally identical quotient.

**Guard / sharp edge:** There is no nonzero guard: x=0 is a counterexample to interpreting this as a universal arithmetic identity.

### uop/symbolic.py:L121 — Floor division by one

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L121). Exact pattern and callback:

```python
(UPat.var("x") // 1, lambda x: x)
```

**Example:** x//1 → x

**Why / helper behavior:** The quotient is unchanged for positive and negative integers.

**Guard / sharp edge:** This is floor integer division, not arbitrary division by a runtime value.

### uop/symbolic.py:L122 — Floor division by negative one

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L122). Exact pattern and callback:

```python
(UPat.var("x") // -1, lambda x: -x)
```

**Example:** x//(-1) → -x

**Why / helper behavior:** Converts a division into a cheaper negation.

**Guard / sharp edge:** Weak integer math is mathematical; fixed-width minimum-integer overflow still belongs to the dtype/emission semantics.

### uop/symbolic.py:L123 — Cancel repeated XOR

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L123). Exact pattern and callback:

```python
((UPat.var("x") ^ UPat.var("y")) ^ UPat.var("y"), lambda x,y: x)
```

**Example:** (x^37)^37 → x

**Why / helper behavior:** XOR is its own inverse; useful when reversible bit mixing introduces redundant masks.

**Walkthrough:** At each bit, XOR with 0 leaves it alone and XOR with 1 flips it. Applying the same y twice therefore flips each selected bit twice, returning the starting bits.

**Guard / sharp edge:** Both y references must be the same UOp, not merely equal-looking runtime inputs.

### uop/symbolic.py:L124 — Remove repeated identical modulus

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L124). Exact pattern and callback:

```python
((UPat.var() % UPat.var("y")).named("base") % UPat.var("y"), lambda base,y: base)
```

**Example:** (x%8)%8 → x%8

**Why / helper behavior:** The first remainder already lies in the remainder range for that divisor. Source captures the base node for speed.

**Walkthrough:** For divisor 8 the first result is already one of 0 through 7. Dividing any of those by 8 has quotient zero, so another remainder operation cannot change it.

**Guard / sharp edge:** The repeated divisor must be identical; (x%8)%3 cannot drop the outer modulus.

### uop/symbolic.py:L126 — Reassemble quotient and remainder digits

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L126). Exact pattern and callback:

```python
(UPat(Ops.ADD, dtype=dtypes.weakint, name="x"), fold_add_divmod_recombine)
```

**Example:** (x%8)+(x//8)*8 → x; (x%8)+((x//8)%4)*8 → x%32

**Why / helper behavior:** The helper scans flattened ADD terms for remainder×scale and quotient×(divisor×scale). _quotient_base also recognizes constant-shifted or merged quotient spellings with congruent numerators, allowing address arithmetic to recover a flat index.

**Walkthrough:** Take x=43: its base-8 quotient is 5 and low digit is 3, so `3+5*8=43`. Retaining only quotient digit `5%4=1` instead gives `3+1*8=11=43%32`. This is why flattening an index and then recovering its coordinates can cancel.

**Guard / sharp edge:** Weakint ADD only. Partial recombination requires the outer modulus positive; unmatched terms are preserved. Similar-looking quotients with noncongruent numerators must not combine.

### uop/symbolic.py:L127 — Boolean AND with a constant

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L127). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool) & UPat.cvar("c"), lambda x,c: x if c.val else c)
```

**Example:** p & True → p; p & False → False

**Why / helper behavior:** Apply the boolean truth table before generic arithmetic transformations.

**Guard / sharp edge:** x must have bool dtype; integer bitwise AND with 1 does not return arbitrary x.

### uop/symbolic.py:L128 — Boolean OR with a constant

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L128). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool) | UPat.cvar("c"), lambda x,c: c if c.val else x)
```

**Example:** p | True → True; p | False → p

**Why / helper behavior:** Constant predicates disappear from validity expressions.

**Guard / sharp edge:** The bool dtype guard is essential: integer x|1 is generally neither 1 nor x.

### uop/symbolic.py:L129 — Boolean inequality to false

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L129). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool) != UPat.const(False, dtypes.bool), lambda x: x)
```

**Example:** p != False → p

**Why / helper behavior:** Avoids wrapping an already boolean value in another comparison.

**Guard / sharp edge:** p is bool; integer 2 != 0 yields True, not integer 2.

### uop/symbolic.py:L130 — Idempotent operations

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L130). Exact pattern and callback:

```python
(UPat(GroupOp.Idempotent, src=(UPat.var("x"), UPat.var("x"))), lambda x: x)
```

**Example:** x|x → x; x&x → x; max(x,x) → x

**Why / helper behavior:** Repeated identical operands add no information. These are the exact current Idempotent members.

**Guard / sharp edge:** ADD is deliberately absent: x+x is 2*x, not x.

### uop/symbolic.py:L131 — Double boolean negation

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L131). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool).logical_not().logical_not(), lambda x: x)
```

**Example:** !!p → p

**Why / helper behavior:** Removes two comparison/negation nodes from predicate logic.

**Guard / sharp edge:** Bool dtype is required; this is not arbitrary bitwise complement syntax.

### uop/symbolic.py:L132 — Selection reproduces its predicate

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L132). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool).where(UPat.const(True, dtypes.bool), UPat.const(False, dtypes.bool)), lambda x: x)
```

**Example:** p ? True : False → p

**Why / helper behavior:** A truth-table encoding should become its original condition.

**Guard / sharp edge:** Branches must be exactly boolean True and False in that order.

### uop/symbolic.py:L133 — Selection negates its predicate

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L133). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool).where(UPat.const(False, dtypes.bool), UPat.const(True, dtypes.bool)), lambda x: x.logical_not())
```

**Example:** p ? False : True → !p

**Why / helper behavior:** Use one boolean negation instead of an explicit two-value select.

**Guard / sharp edge:** Reversing branch order changes the result; it is not the preceding identity.

### uop/symbolic.py:L135 — Compare an integer-cast boolean

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L135). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool).cast(dtypes.ints+(dtypes.weakint,)) != UPat.cvar("c"),
   lambda x,c: x if c.val == 0 else x.logical_not() if c.val == 1 else x.const_like(True))
```

**Example:** int(p)!=0 → p; int(p)!=1 → !p; int(p)!=7 → True

**Why / helper behavior:** Source rationale: converting bool produces only 0 or 1, so the comparison has only three cases.

**Guard / sharp edge:** The matched destination is an integer dtype or weakint. A general float/integer value is not constrained to {0,1}.

### uop/symbolic.py:L137 — Truncation of an integer is redundant

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L137). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.ints+(dtypes.bool, dtypes.weakint)).trunc(), lambda x: x)
```

**Example:** TRUNC(int32(x)) → int32(x)

**Why / helper behavior:** Integer and boolean inputs have no fractional part to remove.

**Guard / sharp edge:** Floating inputs must retain TRUNC; -1.7 is a counterexample.

### uop/symbolic.py:L139 — Strict self-comparison is false

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L139). Exact pattern and callback:

```python
(UPat.var("x") < UPat.var("x"), lambda x: x.const_like(False, dtypes.bool))
```

**Example:** x<x → False

**Why / helper behavior:** A value is never strictly less than itself, including unordered NaN comparisons.

**Guard / sharp edge:** This is CMPLT, not <=; x<=x has different NaN behavior.

### uop/symbolic.py:L140 — Self remainder is zero

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L140). Exact pattern and callback:

```python
(UPat.var("x") % UPat.var("x"), lambda x: x.const_like(0))
```

**Example:** x%x → 0 (e.g. 9%9)

**Why / helper behavior:** Cancels identical numerator and denominator.

**Guard / sharp edge:** No nonzero guard exists; zero divisor is an invalid arithmetic case.

### uop/symbolic.py:L141 — Self XOR is zero

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L141). Exact pattern and callback:

```python
(UPat.var("x") ^ UPat.var("x"), lambda x: x.const_like(0))
```

**Example:** x^x → 0

**Why / helper behavior:** Every set bit cancels against itself.

**Guard / sharp edge:** Do not generalize to OR or AND; those return x.

### uop/symbolic.py:L142 — AND with zero clears all bits

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L142). Exact pattern and callback:

```python
(UPat.var("x") & 0, lambda x: x.const_like(0))
```

**Example:** x&0 → 0

**Why / helper behavior:** No output bit can remain set.

**Guard / sharp edge:** Invalid is propagated earlier so poison is not accidentally converted into a usable address.

### uop/symbolic.py:L144 — Drop a mask that only clears discarded low bits

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L144). Exact pattern and callback:

```python
((UPat.var("x") & UPat.cvar("mask")) >> UPat.cvar("k"),
   lambda x,mask,k: x >> k.val if mask.val | ((1 << k.val) - 1) == -1 else None)
```

**Example:** (x & -8)>>3 → x>>3

**Why / helper behavior:** The guard mask | ((1<<k)-1) == -1 proves all retained high bits are untouched.

**Walkthrough:** In two's-complement notation, -8 has bits `...11111000`. AND with -8 clears only the three low bits, and shifting right by three throws those bits away anyway. The OR guard fills in those discarded positions and checks that every remaining mask bit was already 1.

**Guard / sharp edge:** (x & 7)>>3 cannot drop its mask: that mask clears high bits. There is no explicit negative-shift guard in this rule.

### uop/symbolic.py:L146 — Drop the same low-bit mask before power-of-two floor division

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L146). Exact pattern and callback:

```python
((UPat.var("x") & UPat.cvar("mask")) // UPat.cvar("c"),
   lambda x,mask,c: x // c.val if c.val > 0 and c.val & (c.val-1) == 0 and mask.val | (c.val-1) == -1 else None)
```

**Example:** (x & -8)//8 → x//8

**Why / helper behavior:** A positive power-of-two divisor discards exactly those low bits, just like an arithmetic shift.

**Walkthrough:** Write x as `8*q+r` with `0<=r<8`. Clearing the bottom three bits removes r; dividing either x or the cleared value by 8 therefore yields q. A divisor such as 3 does not correspond to a fixed number of low bits.

**Guard / sharp edge:** Requires c>0, c a power of two, and mask|(c-1)==-1. Division by 3 does not satisfy the proof.

### uop/symbolic.py:L148 — Integer self-inequality is false

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L148). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.ints+(dtypes.bool, dtypes.weakint)) != UPat.var("x"),
   lambda x: x.const_like(False, dtypes.bool))
```

**Example:** int32(x)!=x → False when both references are the same int32 UOp

**Why / helper behavior:** An integer or boolean is equal to itself, so this inequality is always false.

**Walkthrough:** Integers always compare equal to themselves. The dtype restriction encodes the exception for floating NaN (the special “not a number” value), which deliberately compares unequal even to itself.

**Guard / sharp edge:** Float is excluded because NaN != NaN is True; note the contrast with the self-division rules.

### uop/symbolic.py:L152 — Canonicalize a committed constant cast

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L152). Exact pattern and callback:

```python
(UPat(Ops.CAST, dtypes.all, name="root", src=(UPat.cvar("c"),)), lambda root, c: root.const_like(c.val))
```

**Example:** CAST<float32>(CONST(2)) → float32 constant spelling for 2

**Why / helper behavior:** Use the constant constructor’s standard representation so equal constants share nodes.

**Walkthrough:** A committed constant has a chosen physical dtype, unlike a weak literal awaiting context. The constant constructor (called the “mint” in source comments) chooses the standard representation for that value and dtype.

**Guard / sharp edge:** The result can still be represented as CAST(CONST) in the weak/strong constant system; this does not promise all CAST nodes vanish.

### uop/symbolic.py:L154 — Collapse nested committed constant conversions

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L154). Exact pattern and callback:

```python
(UPat(Ops.CAST, dtypes.all, name="root", src=(UPat(Ops.CAST, dtypes.all, src=(UPat(Ops.CONST, name="c"),)),)),
   lambda root,c: root.const_like(c.val))
```

**Example:** CAST<float64>(CAST<float32>(CONST(2))) → float64 constant 2

**Why / helper behavior:** Repeated committed-constant wrappers need one canonical outer value, allowing subsequent folding.

**Walkthrough:** The purpose is to normalize constant construction, not to claim all intermediate numeric conversions are harmless. The exact nested-CONST spelling in the pattern is the boundary of this rule.

**Guard / sharp edge:** This rule specifically recognizes nested CONST conversions; it is not permission to erase lossy casts around runtime inputs.

### uop/symbolic.py:L158 — Evaluate bare constant ALU

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L158). Exact pattern and callback:

```python
(UPat(GroupOp.ALU-{Ops.THREEFRY}, src=bare_const, name="a"), fold_const_alu)
```

**Example:** CONST(2)+CONST(3) → CONST(5); STACK constants fold lane-wise

**Why / helper behavior:** fold_const_alu reads scalar or stacked constants and calls exec_alu with truncation disabled: source says integers stay mathematical and floats re-round in the mint.

**Walkthrough:** The compiler knows every operand already, so it can calculate the answer while building the kernel. “Truncation disabled” here means it does not force each intermediate mathematical integer into a machine word; the constant constructor handles the final typed representation.

**Guard / sharp edge:** THREEFRY is excluded and folds through decomposition. Invalid propagation has priority; fixed-width overflow is not modeled by blindly truncating every weak intermediate.

### uop/symbolic.py:L159 — Evaluate committed constant ALU

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L159). Exact pattern and callback:

```python
(UPat(GroupOp.ALU-{Ops.THREEFRY}, src=casted_const, name="a"), fold_const_alu)
```

**Example:** float32(2)+float32(3) → float32(5)

**Why / helper behavior:** This separate spelling handles casted constants and stacks of casted constants. Source distinguishes stated-width operands from bare mathematical values.

**Walkthrough:** A typed constant can appear as CAST(CONST) rather than as a bare CONST. Having a second pattern allows the same compile-time evaluator to handle that representation without treating arbitrary runtime casts as constant.

**Guard / sharp edge:** The allowed stack spelling can include bare Invalid; earlier poison rules matter. Do not interpret this as arbitrary CAST inputs being constants.

### uop/symbolic.py:L160 — Commit mixed constant operands to their promotion

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L160). Exact pattern and callback:

```python
(UPat(GroupOp.Binary-{Ops.THREEFRY}, src=[casted_const, bare_const], name="a"), lambda a:
   a.replace(src=tuple(s.ccast(dt) if s.dtype in dtypes.weaks else s for s in a.src))
   if (dt:=promo_dtype(a.src)) not in dtypes.weaks else None)
```

**Example:** int32(2)+weakint(3) → int32(2)+int32(3), then fold

**Why / helper behavior:** Mixed weak/strong constants must agree on promoted dtype before the committed-constant evaluator can run.

**Walkthrough:** The first operand fixes the example's numeric context as int32. Converting the weak 3 to that context makes both operands fit the preceding constant-evaluation pattern; the following rewrite then computes 5.

**Guard / sharp edge:** Only binary operations except THREEFRY; if promotion remains weak there is no rewrite.

### uop/symbolic.py:L164 — Boolean multiplication means conjunction

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L164). Exact pattern and callback:

```python
(UPat.var('x', dtype=dtypes.bool) * UPat.var('y', dtype=dtypes.bool), lambda x,y: x&y)
```

**Example:** bool(p)*bool(q) → p&q

**Why / helper behavior:** Source explicitly prevents later numeric algebra from treating bool multiplication as ordinary integer multiplication.

**Guard / sharp edge:** The output is boolean logic, not an integer count.

### uop/symbolic.py:L165 — Boolean addition means disjunction

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L165). Exact pattern and callback:

```python
(UPat.var('x', dtype=dtypes.bool) + UPat.var('y', dtype=dtypes.bool), lambda x,y: x|y)
```

**Example:** bool(p)+bool(q) → p|q

**Why / helper behavior:** Source explicitly protects bool ADD semantics against coefficient-combination rules such as x+x→2*x.

**Guard / sharp edge:** True+True stays True in this dtype, not integer 2.

### uop/symbolic.py:L166 — Boolean maximum means disjunction

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L166). Exact pattern and callback:

```python
(UPat.var('x', dtype=dtypes.bool).maximum(UPat.var('y', dtype=dtypes.bool)), lambda x,y: x|y)
```

**Example:** max(bool(p),bool(q)) → p|q

**Why / helper behavior:** The maximum of two truth values is their OR; common predicate form exposes other boolean rules.

**Guard / sharp edge:** This simplification depends on both operands being bool.

### uop/symbolic.py:L168 — Explicit zero over zero becomes NaN

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L168). Exact pattern and callback:

```python
(UPat.cvar('x', arg=0) / 0, lambda x: x.const_like(float('nan')))
```

**Example:** 0.0/0 → NaN

**Why / helper behavior:** Handle a known invalid floating division before broader self-division cancellation.

**Guard / sharp edge:** This catches literal-zero pattern structure; it does not make later x/x cancellation safe for runtime zero.

### uop/symbolic.py:L170 — Cancel floating self-division

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L170). Exact pattern and callback:

```python
(UPat.var("x") / UPat.var("x"), lambda x: x.const_like(1))
```

**Example:** x/x → 1 (e.g. 4.0/4.0)

**Why / helper behavior:** Avoids redundant division when identical operands occur.

**Guard / sharp edge:** The source itself warns it can be wrong when x is zero; NaN and infinities also prevent strict IEEE equivalence.

### uop/symbolic.py:L171 — Cancel a product factor through division

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L171). Exact pattern and callback:

```python
((UPat.var("x") * UPat.var("x2")) / UPat.var("x2"), lambda x,x2: x)
```

**Example:** (x*y)/y → x (e.g. (3*4)/4)

**Why / helper behavior:** Removes a multiply/divide pair in algebraic normalization.

**Guard / sharp edge:** The source warns about zero divisor. Floating rounding, overflow, infinities, and NaNs are additional reasons this is not bitwise IEEE algebra.

### uop/symbolic.py:L175 — Multiply by zero, preserving known nonfinite constants

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L175). Exact pattern and callback:

```python
(UPat.var("x") * 0, lambda x: x.const_like(float("nan") if x.op is Ops.CONST
                                             and isinstance(x.val, float) and (math.isnan(x.val) or math.isinf(x.val)) else 0))
```

**Example:** x*0 → 0; CONST(inf)*0 → NaN

**Why / helper behavior:** Most zero products can disappear; explicitly known NaN/Inf constants preserve a NaN result.

**Guard / sharp edge:** Source explicitly notes this can be wrong for loaded NaN. Runtime infinity is likewise not covered by the CONST check.

### uop/symbolic.py:L178 — Remove casts that do not change dtype

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L178). Exact pattern and callback:

```python
(UPat((Ops.CAST, Ops.BITCAST), name="root"), lambda root: root.src[0] if root.dtype == root.src[0].dtype else None)
```

**Example:** CAST<float32>(float32 x) → x; same for BITCAST

**Why / helper behavior:** A conversion/reinterpretation to the identical dtype does no work.

**Guard / sharp edge:** Equal byte size alone is insufficient: float32→uint32 is a real bitcast.

### uop/symbolic.py:L180 — Bitcast a constant at its declared width

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L180). Exact pattern and callback:

```python
(UPat(Ops.BITCAST, name="root", src=(UPat.any(UPat(Ops.CONST, dtypes.bool, name="c"), UPat(Ops.CAST, src=(UPat(Ops.CONST),), name="c")),)),
   fold_bitcast)
```

**Example:** BITCAST<uint32>(float32(1.0)) → uint32(1065353216)

**Why / helper behavior:** fold_bitcast first truncates to the source width, then reinterprets bytes; source says the bit read pins a mathematical value to a physical width.

**Walkthrough:** Float32 1.0 has bits `0x3F800000`. Reading that identical 32-bit pattern as an unsigned integer gives 1065353216; an ordinary numeric cast would give integer 1 instead. A weak literal has no unique bit pattern until a width is chosen.

**Guard / sharp edge:** Requires equal itemsize. Bare weak constants cannot supply meaningful bits; the bare pattern arm is bool only.

### uop/symbolic.py:L183 — Undo a lossless cast round trip

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L183). Exact pattern and callback:

```python
(UPat.var('x').cast(name="a").cast(name="b"), lambda x,a,b: x if x.dtype == b.dtype and can_lossless_cast(b.dtype, a.dtype) else None)
```

**Example:** int16 x → int32 → int16 becomes x

**Why / helper behavior:** If the intermediate type can represent every original value, returning to the original type restores x.

**Guard / sharp edge:** float32→float16→float32 cannot fold: information was lost. The rule checks full dtype representability, not observed bounds.

### uop/symbolic.py:L185 — Compose two bitcasts

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L185). Exact pattern and callback:

```python
(UPat(Ops.BITCAST, name="b", src=(UPat.var('x').bitcast(),)), lambda x,b: x.bitcast(b.dtype))
```

**Example:** BITCAST<int32>(BITCAST<float32>(uint32 x)) → BITCAST<int32>(x)

**Why / helper behavior:** Intermediate reinterpretation changes no bits and can be bypassed.

**Guard / sharp edge:** This concerns bitcasts, not numeric casts; legal bitcast size/shape constraints still apply.

### uop/symbolic.py:L186 — Define numeric-to-bool cast by nonzero

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L186). Exact pattern and callback:

```python
(UPat.var("x").cast(dtypes.bool), lambda x: x != 0)
```

**Example:** CAST<bool>(x) → x!=0

**Why / helper behavior:** Expresses a conversion with the comparison primitives understood by backends.

**Guard / sharp edge:** For NaN the result is True because NaN!=0; it is not x>0, which also mishandles negative inputs.

### uop/symbolic.py:L188 — Expand selected constant powers

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L188). Exact pattern and callback:

```python
(UPat.var("x").alu(Ops.POW, UPat.cvar("c")), simplify_pow)
```

**Example:** x^0 → 1; x^(-2) → reciprocal(x)^2; x^2.5 → x^2*sqrt(x); x^6 → (x^3)*(x^3)

**Why / helper behavior:** simplify_pow handles negative exponents first, then zero, half-integers, then integer exponentiation by squaring; other exponents return None. This exposes products and avoids a general power implementation.

**Walkthrough:** For the square example, form t=x*x once and use t*t for x⁴; larger powers reuse the same idea. For `x**2.5`, the integer part supplies x*x and the remaining half supplies sqrt(x). Avoiding the general power routine makes those smaller operations visible to later rules.

**Guard / sharp edge:** Half-integer handling has a precision guard h<c. Negative bases, signed zero, and floating rounding deserve care; these are algebraic decompositions, not a bitwise equivalence guarantee.

### uop/symbolic.py:L190 — Use exp2 for a positive constant base

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L190). Exact pattern and callback:

```python
(UPat.cvar("c").alu(Ops.POW, UPat.var("x")), lambda c,x: c if c.val == 1 else (x*math.log2(c.val)).exp2() if c.val > 0 else None)
```

**Example:** 2^x → exp2(x); 4^x → exp2(2*x); 1^x → 1

**Why / helper behavior:** Computing log2(base) at compile time removes a logarithm from the runtime power calculation.

**Walkthrough:** Because `c = 2**log2(c)`, raising c to x gives `2**(x*log2(c))`. The logarithm is computed once by the compiler when c is a constant; only multiplication and exp2 remain in the kernel.

**Guard / sharp edge:** Base must be positive unless it is 1; zero and negative bases retain POW for other handling.

### uop/symbolic.py:L192 — Unpack the low word of a packed pair

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L192). Exact pattern and callback:

```python
(((UPat.var(None, dtypes.uint64)<<32) | UPat.var('y', dtypes.uint32).cast(dtypes.uint64)).cast(dtypes.uint32), lambda y: y)
```

**Example:** uint32((uint64(hi)<<32)|uint64(lo)) → lo

**Why / helper behavior:** Source explicitly names the uint32 pairs used by THREEFRY; narrowing discards the high half.

**Walkthrough:** In hexadecimal, `(hi=2,lo=3)` packs to `0x0000000200000003`. Keeping only 32 bits leaves `0x00000003`, so the pack and narrow operations can both disappear.

**Guard / sharp edge:** lo must originate as uint32, so it cannot already contain high-half bits.

### uop/symbolic.py:L193 — Unpack the high word of a packed pair

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L193). Exact pattern and callback:

```python
(((UPat.var('x', dtypes.uint32).cast(dtypes.uint64)<<32) | UPat.var(None, dtypes.uint32).cast(dtypes.uint64))>>32,
   lambda x: x.cast(dtypes.uint64))
```

**Example:** ((uint64(hi)<<32)|uint64(lo))>>32 → uint64(hi)

**Why / helper behavior:** Removes pack/unpack work around the high half of THREEFRY’s uint64 representation.

**Walkthrough:** For the same pair, shifting `0x0000000200000003` right by 32 leaves 2. The low-half dtype guard proves there were no extra bits in lo that could have overlapped the stored high half.

**Guard / sharp edge:** Both packed inputs are uint32 cast to uint64; arbitrary uint64 low operands could contaminate the high word.

### uop/symbolic.py:L197 — Equal WHERE branches

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L197). Exact pattern and callback:

```python
(UPat.var().where(UPat.var("val"), UPat.var("val")), lambda val: val)
```

**Example:** p ? x : x → x

**Why / helper behavior:** The condition cannot affect the returned value.

**Guard / sharp edge:** Branch identity is structural UOp identity; semantic equivalence of unrelated graphs is not proved here.

### uop/symbolic.py:L198 — Constant WHERE condition

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L198). Exact pattern and callback:

```python
(UPat.cvar("gate").where(UPat.var("c0"), UPat.var("c1")).named("w"), fold_const_where)
```

**Example:** True ? x : y → x; False ? x : y → y

**Why / helper behavior:** fold_const_where selects the branch and commits a weak constant to the original strong WHERE dtype if needed.

**Walkthrough:** Selecting a branch does not remove the selected expression's type obligation. If the original WHERE was float32 and the selected branch is weak literal 2, the result still needs to represent float32 2.

**Guard / sharp edge:** Returning a weak literal directly could silently lose the original dtype; the helper deliberately preserves it.

### uop/symbolic.py:L199 — Nonzero test of zero-masked data

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L199). Exact pattern and callback:

```python
(UPat.var("gate").where(UPat.var("x"), 0) != 0, lambda gate,x: gate & (x != 0))
```

**Example:** (p ? x : 0)!=0 → p & (x!=0)

**Why / helper behavior:** A nonzero result requires both selection of x and x being nonzero.

**Guard / sharp edge:** The alternate must be zero; replacing an alternate 7 would give different behavior when p is false.

### uop/symbolic.py:L201 — Merge nested true-branch selects

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L201). Exact pattern and callback:

```python
(UPat.var("a").where(UPat.var("b").where(UPat.var("c"), UPat.var("d")), UPat.var("d")), lambda a,b,c,d: (a&b).where(c,d))
```

**Example:** a ? (b ? 7 : 3) : 3 → (a&b) ? 7 : 3

**Why / helper behavior:** The exceptional value requires both conditions; one WHERE is enough.

**Guard / sharp edge:** The two d branches must be the same UOp.

### uop/symbolic.py:L203 — Merge nested false-branch selects

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L203). Exact pattern and callback:

```python
(UPat.var("a").where(UPat.var("c"), UPat.var("b").where(UPat.var("c"), UPat.var("d"))), lambda a,b,c,d: (a|b).where(c,d))
```

**Example:** a ? 7 : (b ? 7 : 3) → (a|b) ? 7 : 3

**Why / helper behavior:** Either condition selects the shared true value.

**Guard / sharp edge:** This uses OR rather than AND because either branch can select c.

## commutative: weak-integer canonicalization

### uop/symbolic.py:L230 — Canonical operand ordering for index math

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L230). Exact pattern and callback:

```python
(UPat(GroupOp.Commutative, dtype=dtypes.weakint, name='x'), lambda x: x.replace(src=x.src[::-1]) if x.src[1].tuplize < x.src[0].tuplize else None)
```

**Example:** weakint ADD(b,a) → ADD(a,b) when a.tuplize < b.tuplize

**Why / helper behavior:** A stable structural ordering lets equivalent commutative index expressions become the same graph.

**Walkthrough:** Commutative means operand order does not change the mathematical result, as in a+b=b+a. Sorting by a structural description (`tuplize`) ensures that two construction paths choose the same graph spelling; this is not sorting by runtime numerical value.

**Guard / sharp edge:** Only weakint. Source warns that flipping only some vector math lanes can break merging, so this is not applied indiscriminately to strong numerical data.

## symbolic: deeper algebra and bounds

### uop/symbolic.py:L243 — Predicate or its negation

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L243). Exact pattern and callback:

```python
(UPat.var("x", dtype=dtypes.bool) | UPat.var("x", dtype=dtypes.bool).logical_not(), lambda x: x.const_like(True))
```

**Example:** p|!p → True

**Why / helper behavior:** The exhaustive alternatives make the mask unconditional.

**Guard / sharp edge:** Requires bool p; bitwise complements of other types follow different representation rules.

### uop/symbolic.py:L245 — Collect two explicit coefficients

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L245). Exact pattern and callback:

```python
(UPat.var("x") * UPat.cvar("c0") + UPat.var("x") * UPat.cvar("c1"), lambda x,c0,c1: x*(c0+c1))
```

**Example:** x*3+x*5 → x*8

**Why / helper behavior:** Repeated terms need one multiplication, and coefficients become foldable constants.

**Guard / sharp edge:** Floating reassociation can change rounding; no strict IEEE guard exists.

### uop/symbolic.py:L246 — Collect explicit coefficients inside an addition chain

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L246). Exact pattern and callback:

```python
((UPat.var("y") + UPat.var("x") * UPat.cvar("c0")) + UPat.var("x") * UPat.cvar("c1"), lambda x,y,c0,c1: y+x*(c0+c1))
```

**Example:** (y+x*3)+x*5 → y+x*8

**Why / helper behavior:** The nested tree hides the pair from the direct binary pattern, so a separate shape handles it.

**Walkthrough:** The outer ADD sees `(y+x*3)` and `(x*5)`, not two direct multiplications by x. This deeper pattern reaches one level into the left operand to expose the 3+5 coefficient sum.

**Guard / sharp edge:** This does not search an arbitrary unordered polynomial; it recognizes the displayed depth and shared x.

### uop/symbolic.py:L247 — Treat a bare term as coefficient one

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L247). Exact pattern and callback:

```python
(UPat.var("x") + UPat.var("x") * UPat.cvar("c"), lambda x,c: x*(c+1))
```

**Example:** x+x*3 → x*4

**Why / helper behavior:** An implicit coefficient should combine with an explicit coefficient.

**Walkthrough:** Spell the bare x as x*1: `x*1+x*3 = x*(1+3)`. That is the missing step behind the callback's `c+1`.

**Guard / sharp edge:** This is additive combination, not x*(x*3); boolean arithmetic has already been converted to logic.

### uop/symbolic.py:L248 — Collect a bare term inside an addition chain

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L248). Exact pattern and callback:

```python
((UPat.var("y") + UPat.var("x")) + UPat.var("x") * UPat.cvar("c"), lambda x,y,c: y+x*(c+1))
```

**Example:** (y+x)+x*3 → y+x*4

**Why / helper behavior:** Captures the nested shape without first flattening every addition tree.

**Walkthrough:** The leading y need not be related to x. The rule changes only `x+x*3` into x*4 while carrying y through unchanged, so it needs no assumption about y's value.

**Guard / sharp edge:** Only the shared x is merged; unrelated y remains.

### uop/symbolic.py:L249 — Collect the trailing bare term

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L249). Exact pattern and callback:

```python
((UPat.var("y") + UPat.var("x") * UPat.cvar("c")) + UPat.var("x"), lambda x,y,c: y+x*(c+1))
```

**Example:** (y+x*3)+x → y+x*4

**Why / helper behavior:** The explicit coefficient may occur in the inner rather than outer add.

**Walkthrough:** Compared with the previous entry, the bare x is the final operand. The algebra is the same, but graph matching sees different parent/child positions and needs this additional template.

**Guard / sharp edge:** Pattern ordering/commutative matching matters; do not assume one printed algebraic rule matches every tree association.

### uop/symbolic.py:L250 — Combine two bare terms

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L250). Exact pattern and callback:

```python
(UPat.var("x") + UPat.var("x"), lambda x: x*2)
```

**Example:** x+x → x*2

**Why / helper behavior:** An explicit coefficient reduces duplicated addition structure and joins the coefficient normal form.

**Walkthrough:** Writing repeated x as a coefficient makes later `x*2+x*3` recognizable as x*5. The benefit includes enabling the next simplification, even if a multiply by two later becomes an addition or shift.

**Guard / sharp edge:** Bool ADD is rewritten earlier to OR, avoiding an invalid numeric interpretation.

### uop/symbolic.py:L251 — Combine repeated terms in a nested add

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L251). Exact pattern and callback:

```python
((UPat.var("y") + UPat.var("x")) + UPat.var("x"), lambda y,x: y+x*2)
```

**Example:** (y+x)+x → y+x*2

**Why / helper behavior:** Handles the common associated form with an unrelated leading term.

**Walkthrough:** Here the root ADD's left child is another ADD. Matching that extra level reveals the repeated x without requiring a general search through every possible sum arrangement.

**Guard / sharp edge:** The pattern is not a full global common-term collector.

### uop/symbolic.py:L252 — Merge successive true divisions

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L252). Exact pattern and callback:

```python
((UPat.var("x") / UPat.var("x2")) / UPat.var("x3"), lambda x,x2,x3: x/(x2*x3) if x2 is not x3 else None)
```

**Example:** (x/2)/3 → x/(2*3)

**Why / helper behavior:** The denominator product may fold and removes one division.

**Guard / sharp edge:** Requires x2 is not x3; the source gives no historical reason for that identity guard. Floating overflow/rounding can differ after denominator multiplication.

### uop/symbolic.py:L253 — Distribute a minus over a constant offset

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L253). Exact pattern and callback:

```python
(-1 * (UPat.var("x") + UPat.cvar("c")), lambda x,c: (-x)+(-c))
```

**Example:** -1*(x+5) → -x-5

**Why / helper behavior:** Makes the trailing constant available to constant folding and comparison normalization.

**Guard / sharp edge:** This includes floating expressions, so signed-zero/rounding details are not separately guarded.

### uop/symbolic.py:L254 — Distribute a constant through a weak-integer offset

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L254). Exact pattern and callback:

```python
(UPat.cvar("y") * (UPat.var("x", dtype=dtypes.weakint) + UPat.cvar("c")), lambda x,y,c: (y*x)+(y*c))
```

**Example:** 3*(x+5) → 3*x+15

**Why / helper behavior:** Stride-times-offset expressions become a coordinate multiplied by a constant, plus a fixed offset (an affine expression).

**Walkthrough:** For a row stride of 3 and logical offset x+5, the address is `3*x+3*5`. Computing the fixed 15 at compile time leaves only the changing coordinate work in the kernel.

**Guard / sharp edge:** x must be weakint; unrestricted float distribution can introduce overflow or NaN differences.

### uop/symbolic.py:L256 — Remove negation from a selector

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L256). Exact pattern and callback:

```python
(UPat.var("cond", dtype=dtypes.bool).logical_not().where(UPat.var("t"), UPat.var("f")),
   lambda cond, t, f: cond.where(f,t) if not f.is_invalid else None)
```

**Example:** !p ? a : b → p ? b : a

**Why / helper behavior:** Swapping branches eliminates a boolean negation.

**Guard / sharp edge:** Will not fire if b is Invalid: that swap would fight the canonical false-branch poison orientation.

### uop/symbolic.py:L259 — Use the selected branch’s known condition

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L259). Exact pattern and callback:

```python
(UPat.var("cond", dtype=dtypes.bool).where(UPat.var("t"), UPat.var("f")), fold_where_closure)
```

**Example:** p ? (p ? x : y) : z → p ? x : z

**Why / helper behavior:** fold_where_closure substitutes p=True in the true branch and p=False in the false branch, then later folding cleans up.

**Walkthrough:** Entering the true branch already tells us p=true, so its inner `p ? x : y` can only select x. The helper applies that known condition to boolean expressions inside the branch; it avoids address nodes because their masks also control memory access.

**Guard / sharp edge:** Requires a use of p in a branch’s bool_slice and refuses any INDEX anywhere in condition/branches: source says INDEX gates belong to validity/store-coalescing machinery.

### uop/symbolic.py:L261 — Combine two selections with the same predicate

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L261). Exact pattern and callback:

```python
(UPat(GroupOp.Binary, name="alu", src=(UPat.var("c").where(UPat.var("t"), UPat.var("f")), UPat.var("c").where(UPat.var("tt"), UPat.var("ff")))), \
   lambda alu,c,t,tt,f,ff: c.where(t.alu(alu.op, tt), f.alu(alu.op, ff)) if t.op == tt.op == Ops.CONST or f.op == ff.op == Ops.CONST else None)
```

**Example:** (p ? x : 2)+(p ? y : 3) → p ? (x+y) : 5

**Why / helper behavior:** One select can carry branchwise arithmetic, and the constant side immediately folds.

**Walkthrough:** Evaluate the predicate once conceptually: if true, add x and y; if false, add 2 and 3 at compile time. Requiring a constant pair ensures there is concrete simplification to gain, not merely a different spelling.

**Guard / sharp edge:** Fires only if both true branches or both false branches are CONST. Two entirely variable pairs do not meet its profitability guard.

### uop/symbolic.py:L264 — Combine selections nested in an add

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L264). Exact pattern and callback:

```python
((UPat.var("y")+UPat.var("c").where(UPat.var("t"), UPat.var("f"))) + UPat.var("c").where(UPat.var("tt"), UPat.var("ff")), \
   lambda y,c,t,tt,f,ff: y+c.where(t+tt, f+ff) if t.op == tt.op == Ops.CONST or f.op == ff.op == Ops.CONST else None)
```

**Example:** (z+(p ? x : 2))+(p ? y : 3) → z+(p ? (x+y) : 5)

**Why / helper behavior:** Same optimization needs its own associated-add pattern to see past z.

**Walkthrough:** The extra z is outside both selections and is kept there. The pattern reaches through that outer addition to combine only the two expressions controlled by p.

**Guard / sharp edge:** The same constant-pair guard applies; z remains outside the select.

### uop/symbolic.py:L267 — Join complementary zero-masked values

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L267). Exact pattern and callback:

```python
(UPat.var("c").where(UPat.var("t"), 0) + UPat.var("c").where(0, UPat.var("f")), lambda c,t,f: c.where(t, f))
```

**Example:** (p ? x : 0)+(p ? 0 : y) → p ? x : y

**Why / helper behavior:** Exactly one contribution can be nonzero, eliminating an addition and one select.

**Guard / sharp edge:** Both selections must share the identical predicate; unrelated masks may overlap or leave holes.

### uop/symbolic.py:L269 — A singleton value interval is a constant

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L269). Exact pattern and callback:

```python
(UPat({Ops.CMPLT, Ops.CMPNE, Ops.FLOORDIV, Ops.FLOORMOD, Ops.PARAM, Ops.AFTER, Ops.SPECIAL}, name="x"),
   lambda x: x.const_like(x.vmin) if x.vmin == x.vmax else None)
```

**Example:** PARAM(n, min=4,max=4) → 4; (i<8) → True when i∈[0,7]

**Why / helper behavior:** Bounds already prove the result; runtime work would be redundant. Covers CMPLT, CMPNE, FLOORDIV, FLOORMOD, PARAM, AFTER, SPECIAL.

**Walkthrough:** “Conservative” means the true answer must lie inside the reported bounds. If both bounds are 4 there is no room for any other answer; if the interval is [4,6], even when only 4 and 6 are possible, it is not a constant.

**Guard / sharp edge:** Only this enumerated op set and vmin==vmax. Bounds are conservative; a non-singleton interval gives no rewrite.

### uop/symbolic.py:L271 — A one-iteration range is zero

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L271). Exact pattern and callback:

```python
(UPat(Ops.RANGE, src=(UPat(Ops.CONST,)), name="x"), lambda x: x.const_like(x.vmin) if x.vmin == x.vmax else None)
```

**Example:** RANGE(1) → 0

**Why / helper behavior:** An iteration coordinate whose only possible value is zero need not remain a loop/index variable.

**Guard / sharp edge:** The range end must be a CONST and bounds singleton; RANGE(n) with variable n does not match this rule.

### uop/symbolic.py:L273 — Recognize maximum from constant-left comparison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L273). Exact pattern and callback:

```python
((UPat.cvar("a") < UPat.var("b")).where(UPat.var("b"), UPat.cvar("c")), lambda a,b,c: UOp.maximum(a,b) if a.val == c.val else None)
```

**Example:** (3<x) ? x : 3 → max(3,x)

**Why / helper behavior:** Expose the MAX primitive rather than comparison plus selection.

**Guard / sharp edge:** a.val must equal c.val. NaN selection semantics and backend MAX semantics should not be inferred to be universally identical from this algebraic pattern.

### uop/symbolic.py:L274 — Recognize maximum from constant-right comparison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L274). Exact pattern and callback:

```python
((UPat.var("a") < UPat.cvar("b")).where(UPat.cvar("c"), UPat.var("a")), lambda a,b,c: UOp.maximum(a,b) if b.val == c.val else None)
```

**Example:** (x<3) ? 3 : x → max(x,3)

**Why / helper behavior:** The opposite spelling expresses the same maximum operation.

**Guard / sharp edge:** The compared constant and selected constant must have equal values; (x<3)?4:x is not max(x,3).

### uop/symbolic.py:L275 — Choose a provably dominant maximum operand

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L275). Exact pattern and callback:

```python
(UPat.maximum(UPat.var("x"), UPat.var("y")), lambda x,y: x if x.vmin >= y.vmax else y if x.vmax <= y.vmin else None)
```

**Example:** max(x,y) → x for x∈[8,12], y∈[0,7]

**Why / helper behavior:** Disjoint ordered bounds prove which operand wins without a comparison.

**Walkthrough:** Even the smallest x (8) exceeds the largest y (7), so examining actual runtime values cannot change the winner. This is stronger than knowing that their average or typical values are ordered.

**Guard / sharp edge:** Overlapping ranges such as x∈[0,9], y∈[4,8] are insufficient; the matcher returns None.

### uop/symbolic.py:L279 — Associative constant-tail folding template

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L279). Exact pattern and callback:

```python
*((UPat.var("x").alu(op, UPat.cvar("c1")).alu(op, UPat.cvar("c2")).named("f"),
     lambda f,x,c1,c2: x.alu(f.op,c1.alu(f.op,c2))) for op in GroupOp.Associative)
```

**Example:** (x+3)+5 → x+8; (x*3)*5 → x*15; (x&7)&3 → x&3; (x|1)|2 → x|3; max(max(x,3),5) → max(x,5)

**Why / helper behavior:** One generated rule for each current Associative member: ADD, MUL, AND, OR, MAX. Moving adjacent constant tails together exposes constant ALU folding.

**Walkthrough:** Associative means parentheses may move for the mathematical operation: `(x+3)+5 = x+(3+5)`. The second sum is now all constants. The five generated patterns do the corresponding regrouping for each listed operation, subject to the floating caveat below.

**Guard / sharp edge:** XOR is not in this template’s current set. Floating ADD/MUL association is not bitwise invariant; do not read GroupOp.Associative as an IEEE proof.

### uop/symbolic.py:L282 — Merge nested floor divisions

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L282). Exact pattern and callback:

```python
((UPat.var("x") // UPat.cvar("c1")) // UPat.cvar("c2"), lambda x,c1,c2: x//(c1*c2) if c2.vmin>0 else None)
```

**Example:** (x//3)//4 → x//12

**Why / helper behavior:** Counting groups of groups can count the corresponding larger groups directly, removing a division.

**Walkthrough:** For x=35, first counting groups of 3 gives 11, then groups of 4 gives 2. Directly counting groups of 12 also gives 2. A positive outer divisor lets discarded fractional groups stay irrelevant to the final rounded-down quotient.

**Guard / sharp edge:** Requires outer divisor c2>0; with a negative outer divisor the identity can fail (e.g. x=1,c1=2,c2=-1).

### uop/symbolic.py:L285 — Move a constant across an integer comparison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L285). Exact pattern and callback:

```python
((UPat.cvar("c0") + UPat.var("x", dtype=dtypes.ints+(dtypes.weakint,))) < UPat.cvar("c1"), lambda x,c0,c1: x<(c1-c0))
```

**Example:** (x+3)<10 → x<7

**Why / helper behavior:** Turns affine bounds into direct variable bounds understood by later validity reasoning.

**Walkthrough:** Subtract 3 from both sides of `x+3<10`. The result x<7 mentions the coordinate directly, so another rule can use it as a range bound without solving an additional expression.

**Guard / sharp edge:** x must be integer/weakint. Fixed-width overflow is not separately guarded in this pattern, so mathematical-int reasoning and emitted overflow behavior must be distinguished.

### uop/symbolic.py:L287 — Divide out a comparison coefficient with ceiling

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L287). Exact pattern and callback:

```python
((UPat.cvar("c0")*UPat.var("x", dtype=dtypes.weakint))<UPat.cvar("c1"),
   lambda x,c0,c1: (x if c0.val > 0 else -x)<-(-c1.val//abs(c0.val)) if abs(c0.val) > 1 else None)
```

**Example:** 3*x<10 → x<4; -3*x<10 → -x<4

**Why / helper behavior:** Integer strict inequalities need ceil(c1/abs(c0)), not truncating division.

**Walkthrough:** The real-number threshold is 10/3≈3.333. An integer x below it may be 3, so the equivalent strict integer threshold is 4. Ceiling means rounding up; `-(-10//3)` computes that ceiling using floor division.

**Guard / sharp edge:** Only weakint and abs(c0)>1. Using 10//3=3 would incorrectly reject x=3.

### uop/symbolic.py:L290 — Remove a floor quotient from a bound

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L290). Exact pattern and callback:

```python
((UPat.var("x", dtype=dtypes.weakint)//UPat.cvar("d"))<UPat.cvar("c"),
   lambda x,d,c: (x<c.val*d.val) if d.val > 0 else (x>c.val*d.val) if d.val < 0 else None)
```

**Example:** x//3<4 → x<12; x//(-3)<4 → x> -12

**Why / helper behavior:** Monotonicity of floor division transforms the comparison into a direct numerator threshold.

**Walkthrough:** For positive d=3, quotient buckets below 4 end just before 12. For negative d=-3, division reverses ordering: `floor(x/-3)<4` requires x/-3<4, hence x>-12.

**Guard / sharp edge:** A zero divisor returns None. The negative-divisor arm reverses the inequality, with UOp > represented through comparison primitives.

### uop/symbolic.py:L293 — Move an additive constant to the final position

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L293). Exact pattern and callback:

```python
((UPat.var("x") + UPat.cvar("c1")) + UPat.var("y"), lambda x,c1,y: (x+y)+c1 if y.op is not Ops.CONST else None)
```

**Example:** (x+3)+y → (x+y)+3

**Why / helper behavior:** Keeps constants together for later folding and stable affine-form matching.

**Walkthrough:** Putting the constant last makes expressions produced by different paths look alike. For example, a later `+5` can combine directly with this trailing +3 once the variable sum x+y is grouped together.

**Guard / sharp edge:** Skips y when it is already CONST; the associative constant-tail rule handles that case. Floating reassociation may change rounding.

### uop/symbolic.py:L294 — Move a multiplicative constant to the final position

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L294). Exact pattern and callback:

```python
((UPat.var("x") * UPat.cvar("c1")) * UPat.var("y"), lambda x,c1,y: (x*y)*c1 if y.op is not Ops.CONST else None)
```

**Example:** (x*3)*y → (x*y)*3

**Why / helper behavior:** Normalizes coefficient placement for const_factor and coefficient-based rules.

**Walkthrough:** The compiler's coefficient helper looks for a constant multiplier. Moving 3 to the outside presents one coefficient for the whole changing product x*y.

**Guard / sharp edge:** Skips a constant y; floating overflow and rounding may differ after reassociation.

### uop/symbolic.py:L297 — Discard bounded low digits from a comparison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L297). Exact pattern and callback:

```python
(UPat.var("x", dtypes.weakint)<UPat.cvar("c"), lambda x,c: lt_folding(x, c.val) if 0 < c.val else None)
```

**Example:** 4*i+j<12 → i<3 when j∈[0,3]

**Why / helper behavior:** lt_folding partitions unit-coefficient terms from scaled ones, takes gcd of the scaled coefficients and threshold, and drops a nonnegative remainder smaller than that gcd.

**Walkthrough:** Values 4*i+j occupy blocks of four: i=2 gives 8 through 11, all below 12; i=3 gives 12 through 15, all outside. The j bound is what prevents a low digit from crossing the block boundary.

**Guard / sharp edge:** Threshold must be positive and gcd>1. If j can equal 4, dropping j is unsound because it can carry into the next digit.

### uop/symbolic.py:L298 — Reverse two negated integer operands

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L298). Exact pattern and callback:

```python
(UPat.var("x", dtypes.weakint)*-1 < UPat.var("y")*-1, lambda x,y: y<x)
```

**Example:** -x < -y → y < x

**Why / helper behavior:** Removes redundant minus operations from index predicates.

**Guard / sharp edge:** x must be weakint; this does not broadly rewrite floating comparisons.

### uop/symbolic.py:L300 — Remove positive weights from a nonzero simplex

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L300). Exact pattern and callback:

```python
((UPat.var("x", dtypes.weakint)<1).ne(True), lambda x: (newx<1).ne(True) if (newx:=canonicalize_simplex(x)) is not None else None)
```

**Example:** !(2*i+7*j<1) → !(i+j<1) for nonnegative irreducible i,j

**Why / helper behavior:** canonicalize_simplex strips positive constant coefficients because a nonnegative integer sum is positive exactly when at least one term is positive.

**Walkthrough:** With nonnegative integer coordinates, the weighted sum is zero exactly when every coordinate is zero. Its particular positive weights do not matter for a test asking whether it is at least 1. Here “irreducible” means a term the helper keeps as a basic coordinate-like input, rather than recursively expanding it further.

**Guard / sharp edge:** Every term after stripping must be irreducible and nonnegative; negative terms can cancel and invalidate the proof. No changed coefficient means no rewrite.

### uop/symbolic.py:L302 — Remainder of a range by its own extent

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L302). Exact pattern and callback:

```python
(UPat(Ops.RANGE, src=UPat.var("end"), name="r")%UPat.var("end"), lambda r,end: r)
```

**Example:** r=RANGE(8); r%8 → r

**Why / helper behavior:** A range coordinate is already in [0,end), so it is a valid digit.

**Guard / sharp edge:** The divisor must be the identical range-end UOp, not merely a related dimension.

### uop/symbolic.py:L303 — Quotient of a range by its own extent

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L303). Exact pattern and callback:

```python
(UPat(Ops.RANGE, src=UPat.var("end"), name="r")//UPat.var("end"), lambda r,end: r.const_like(0))
```

**Example:** r=RANGE(8); r//8 → 0

**Why / helper behavior:** The coordinate never reaches one whole extent.

**Guard / sharp edge:** This assumes a valid range extent; it is not a rewrite for arbitrary x//end.

### uop/symbolic.py:L306 — Bypass a globally lossless intermediate cast

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L306). Exact pattern and callback:

```python
(UPat.var('x').cast(name="a").cast(name="b"), lambda x,a,b: x.cast(b.dtype) if can_lossless_cast(x.dtype, a.dtype) else None)
```

**Example:** int16 x → int32 → float32 becomes int16 x → float32

**Why / helper behavior:** The intermediate conversion cannot lose any original value and can be skipped.

**Guard / sharp edge:** This guard concerns x→a representability; a narrowing intermediate cast cannot be erased just because the final dtype is wide.

### uop/symbolic.py:L307 — Bypass a bound-proven safe integer intermediate cast

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L307). Exact pattern and callback:

```python
(UPat.var('x', dtypes.ints+(dtypes.weakint,)).cast(dtypes.ints+(dtypes.weakint,), name="a").cast(name="b"),
    lambda x,a,b: x.ccast(b.dtype) if not x.overflows(a.dtype) else None)
```

**Example:** int64 x∈[0,100] → int8 → int64 becomes x committed to int64

**Why / helper behavior:** Bounds can prove a narrowing integer cast safe even when the entire source dtype would not fit.

**Walkthrough:** Int8 holds -128 through 127. Although int64 as a type is too large to fit, this particular x is proven to lie from 0 to 100, so the intermediate conversion cannot discard information.

**Guard / sharp edge:** Both source and intermediate must be integer/weakint, and x.overflows(a.dtype) must be false; x=200 does not fit int8.

### uop/symbolic.py:L310 — Perform bounded long arithmetic at int width

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L310). Exact pattern and callback:

```python
(UPat(GroupOp.Binary, src=(UPat.var("x", (dtypes.long, dtypes.weakint)), UPat.var("y", (dtypes.long, dtypes.weakint))), name="u"), lambda u,x,y:
    (UOp.const(x.val) if x.op is Ops.CONST else x.cast(dtypes.int)).alu(u.op,
     UOp.const(y.val) if y.op is Ops.CONST else y.cast(dtypes.int)).cast(u.dtype)
    if dtypes.long in (x.dtype, y.dtype) and not any(v.overflows(dtypes.int) for v in (u,x,y)) else None)
```

**Example:** int64 x∈[0,100] + int64 y∈[0,100] → int64(int32(x)+int32(y))

**Why / helper behavior:** Source explicitly aims to use int rather than long. Proving both operands and result fit permits a cheaper-width ALU; constants remain weak literals.

**Walkthrough:** The proof checks the operation's output as well as its inputs. For example, two individually valid int32 values near the maximum can have a sum that needs int64; narrowing that addition would be incorrect.

**Guard / sharp edge:** At least one operand must be long. An int32-fitting pair whose sum can overflow int32 is rejected; checking operands alone is insufficient.

### uop/symbolic.py:L314 — Move a weak integer offset outside a signed cast

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L314). Exact pattern and callback:

```python
((UPat.var("x", dtypes.weakint) + UPat.cvar("c")).cast(dtypes.sints, name="cast"), lambda x,c,cast:x.cast(cast.dtype)+cast.const_like(c.val))
```

**Example:** CAST<int32>(weakint(i)+3) → CAST<int32>(i)+int32(3)

**Why / helper behavior:** Exposes a typed affine expression and a typed constant for backend simplification.

**Walkthrough:** Separating the runtime coordinate from the fixed offset gives the backend an ordinary typed addition. This is a representation choice, not a new proof that every weak integer fits the destination dtype.

**Guard / sharp edge:** Destination is a signed integer dtype. Source has no explicit range guard here; overflow follows the integer representation conventions rather than real-number algebra.

### uop/symbolic.py:L316 — Flatten dependencies in AFTER

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L316). Exact pattern and callback:

```python
(UPat(Ops.AFTER, name="x"), lambda x: x.replace(src=(x.src[0],)+
    tuple(dedup(flatten([(y,) if y.op in {Ops.RANGE, Ops.STORE, Ops.CALL, Ops.BARRIER, Ops.END, Ops.LINEAR, Ops.STAGE}
                        else y.src for y in x.src[1:]])))))
```

**Example:** AFTER(v, pure_add(a,b), STORE(...), STORE(...)) → AFTER(v,a,b,STORE(...)) with duplicate dependencies removed

**Why / helper behavior:** The helper preserves RANGE, STORE, CALL, BARRIER, END, LINEAR, STAGE dependencies, otherwise substitutes the dependency’s own sources, and deduplicates. Inferred intent: retain effects while shedding irrelevant expression wrappers.

**Walkthrough:** AFTER(v,...) returns v while recording work that must precede its use. A pure addition has no write to preserve, but the operations feeding it may carry dependencies. Flattening removes the wrapper while retaining the listed ordering-sensitive operations.

**Guard / sharp edge:** The nearby comment is less precise than the actual preservation set. The first source v is always kept; removing all dependencies would lose ordering.

### uop/symbolic.py:L320 — Remove an empty dependency/loop wrapper

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L320). Exact pattern and callback:

```python
(UPat((Ops.AFTER, Ops.END), src=(UPat.var("s"),)), lambda s: s)
```

**Example:** AFTER(x) → x; END(x) → x

**Why / helper behavior:** Without extra sources there is no ordering or range closure to represent.

**Guard / sharp edge:** END(x,r) still carries a range and cannot be erased by this rule.

### uop/symbolic.py:L322 — Remove constant ranges from END

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L322). Exact pattern and callback:

```python
(UPat(Ops.END, name="x"), lambda x: x.replace(src=(x.src[0],)+tuple(r for r in x.src[1:] if r.op is not Ops.CONST or r.dtype is dtypes.bool)))
```

**Example:** END(x, CONST(0), r, CONST(True,bool)) → END(x,r,CONST(True,bool))

**Why / helper behavior:** When a RANGE becomes constant, its closure is unnecessary; source explicitly preserves constant boolean backedges.

**Walkthrough:** END describes completion of repeated work. If a one-iteration coordinate has already become constant 0, there is no loop for that coordinate left to close. Boolean control conditions have a different job and are kept.

**Guard / sharp edge:** Do not remove all CONST operands: a bool constant can describe control flow and is retained.

## pm_drop_and_clauses: reshape-analysis validity ownership

### uop/symbolic.py:L409 — Drop invalidity clauses unrelated to the value’s ranges

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L409). Exact pattern and callback:

```python
(invalid_gate, drop_and_clauses)
```

**Example:** ((r<4)&(s<3)) ? x[r] : Invalid → (r<4) ? x[r] : Invalid when x ranges only over r

**Why / helper behavior:** drop_and_clauses partitions conjunctions by whether their ranges intersect x.ranges. Inferred purpose: keep only the validity constraints owned by this range-dependent value in the caller’s specialized analysis.

**Walkthrough:** This caller is analyzing how the value depends on r, not evaluating the whole original two-coordinate expression. That restricted question permits setting aside the s clause; executing the changed expression in isolation would not preserve its original validity.

**Guard / sharp edge:** This is not a general semantic identity for an arbitrary WHERE: changing s<3 can change validity. It is deliberately a separate PM, not automatically composed into sym; only use in its intended context.

## pm_move_where_on_load: transfer zero masks into index validity

### uop/symbolic.py:L427 — Move a true-branch zero mask onto an indexed read

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L427). Exact pattern and callback:

```python
(UPat.var("cond").where(UPat.var("buf").index(UPat.var("idx")).or_casted("or_cast"), 0), where_on_load)
```

**Example:** (r<8) ? buf.index(r) : 0 → buf.index(valid(r,r<8)) with a trivially true outer select

**Why / helper behavior:** where_on_load removes clauses already in the index validity and moves clauses whose ranges are a subset of the index’s ranges. It rebuilds the index, preserves an optional cast, and leaves immovable clauses in the outer WHERE.

**Walkthrough:** A zero selected after a read is not automatically a safe read: the address could already be out of bounds. Moving the eligible condition onto the address lets later memory lowering implement “do not read here; use zero.” The dependency checks limit which conditions this helper can transfer.

**Guard / sharp edge:** Despite the historical helper name, this pattern matches INDEX, optionally CAST, rather than an explicit LOAD. A condition containing a data-dependent INDEX absent from the address graph cannot move.

### uop/symbolic.py:L428 — Move a false-branch zero mask onto an indexed read

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L428). Exact pattern and callback:

```python
(UPat.var("cond").where(0, UPat.var("buf").index(UPat.var("idx")).or_casted("or_cast")),
   lambda cond,buf,idx,or_cast: where_on_load(cond.logical_not(),buf,idx,or_cast))
```

**Example:** (r>=8) ? 0 : buf.index(r) → buf.index(valid(r,r<8))

**Why / helper behavior:** Negates the condition then calls the same helper, giving both common zero-mask orientations the same address validity form.

**Walkthrough:** Rewrite the selector first: `(r>=8) ? 0 : read(r)` means “read when r<8.” That complementary condition is then processed by the same address-mask helper as the previous entry.

**Guard / sharp edge:** The zero branch must be literal zero, and the helper’s range/data-dependency checks still apply after negation.

## pm_simplify_valid: predicates and conditioned index math

### uop/symbolic.py:L441 — Simplify conjunctions using earlier bounds

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L441). Exact pattern and callback:

```python
(UPat(Ops.AND, dtypes.bool, name="valid"), simplify_valid)
```

**Example:** (i<8)&(i<16) → i<8 for nonnegative integer i

**Why / helper behavior:** simplify_valid flattens/deduplicates AND clauses, prioritizes constraints whose expression feeds other clauses, then simplifies each under previous constraints. uop_given_valid replaces bounded expressions with temporary parameters, simplifies, and substitutes originals back.

**Walkthrough:** Once i<8 is known, testing i<16 adds nothing. More complex clauses require the helper to temporarily assign tighter bounds, simplify using them, and restore the original graph names afterward. The “simplex” case here concerns nonnegative sums and their coordinates, not a guarantee of solving arbitrary inequalities.

**Guard / sharp edge:** Returns None for any INDEX in the predicate graph. Its simplex mode also tries each positive coordinate of a nonnegative sum separately, accepting only identical outcomes (or identical lanes of a two-lane STACK); it is not an unrestricted theorem prover.

### uop/symbolic.py:L442 — Simplify pure address math under its validity, except IMAGE div/mod

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L442). Exact pattern and callback:

```python
(invalid_gate, gated_given_valid)
```

**Example:** (i<8) ? (i//8) : Invalid → (i<8) ? 0 : Invalid for i∈[0,15], IMAGE=0

**Why / helper behavior:** gated_given_valid uses uop_given_valid with simplex disabled: the selected arm may exploit the condition’s bounds. Source explicitly skips DIV/MOD-containing expressions under IMAGE>0, citing image indexing such as openpilot.

**Walkthrough:** Before conditioning, i may be 0 through 15 and i//8 may be 0 or 1. Inside the valid arm i is at most 7, so its quotient is always 0. The IMAGE exception deliberately keeps some such address expressions unchanged despite this local arithmetic argument.

**Guard / sharp edge:** Must be weakint and contain no INDEX: source says a load executes even where the condition is false, so its address validity must survive. IMAGE skips CDIV, CMOD, FLOORDIV, FLOORMOD. The source does not document the exact hardware failure behind that workaround; treating it as proven image coordinate equivalence would overclaim.

## pm_clean_up_group_sink: effect-root cleanup

### uop/symbolic.py:L449 — Unwrap a singleton group

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L449). Exact pattern and callback:

```python
(UPat(Ops.GROUP, src=(UPat.var("x"),)), lambda x: x)
```

**Example:** GROUP(STORE(...)) → STORE(...)

**Why / helper behavior:** One effect needs no grouping node.

**Guard / sharp edge:** This is GROUP only; a singleton SINK can still serve as the graph root.

### uop/symbolic.py:L450 — Flatten root/group containers and discard no-ops

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L450). Exact pattern and callback:

```python
(UPat((Ops.SINK, Ops.GROUP), name="root"),
    lambda root: UOp(root.op, src=tuple(flatten(x.src if x.op in REMOVE_FROM_SINK_LIKE else (x,) for x in root.src)), arg=root.arg)
      if any(x.op in REMOVE_FROM_SINK_LIKE for x in root.src) else None)
```

**Example:** SINK(GROUP(a,b), NOOP, STACK(c,d)) → SINK(a,b,c,d)

**Why / helper behavior:** Source flattens children in {NOOP,STACK,SINK,GROUP}; a source-free NOOP contributes nothing, exposing the actual work/effects.

**Guard / sharp edge:** This interpretation of STACK belongs specifically under SINK/GROUP, not in numerical vector expressions. The root op and arg are retained.

## sym: final algebra, memory, and reduction rules

### uop/symbolic.py:L457 — Lower a remaining general power

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L457). Exact pattern and callback:

```python
(UPat(Ops.POW, name="p"), lambda p: xpow(*p.src))
```

**Example:** POW(x,y) → xpow(x,y), whose central magnitude calculation is exp2(y*log2(abs(x))) with exceptional/sign handling

**Why / helper behavior:** The earlier small-exponent rules remove cheap cases; remaining POW must be expressed in supported primitives. xpow checks whether the exponent equals its int32 round trip, computes oddness from abs(exponent).cast(int32)%2, returns NaN for negative finite bases with noninteger exponents, negates odd-integer results, and forces exponent zero to 1 (including 0^0 and inf^0). Negative infinity has a specific exception to the noninteger-NaN branch.

**Walkthrough:** For positive x, take logarithms: `x**y = 2**(y*log2(x))`. For x=-2 and y=3, the magnitude calculation produces 8 but the answer needs a minus sign; for y=0.5 the ordinary real-valued result is invalid. Those cases explain the extra sign and integer-exponent tests.

**Guard / sharp edge:** The replacement is not simply exp2(y*log2(x)): negative bases and integer exponents require sign/parity handling, and exceptional cases are explicit in the helper.

### uop/symbolic.py:L459 — Remove a load/store round trip to the identical address

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L459). Exact pattern and callback:

```python
(UPat.store(UPat(Ops.INDEX, name="index"), UPat.load(UPat(Ops.INDEX, name="index"))), lambda index: UOp(Ops.NOOP))
```

**Example:** STORE(index,LOAD(index)) → NOOP

**Why / helper behavior:** Writing back the exact value just read contributes no change.

**Guard / sharp edge:** Both index nodes must be identical. This algebra assumes the compiler’s memory-effect model; it is not a general transformation for volatile or externally changing memory.

### uop/symbolic.py:L460 — Convert a conditional update into a masked store

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L460). Exact pattern and callback:

```python
(UPat.store(UPat(Ops.INDEX, name="index"), UPat.var("gate").where(UPat.var("alt"),
                                                                    UPat.load(UPat(Ops.INDEX, name="index")))),
   lambda index, gate, alt: UOp.store(index.src[0].index(index.src[1].valid(gate)), alt))
```

**Example:** STORE(i, p ? new : LOAD(i)) → STORE(valid(i,p),new)

**Why / helper behavior:** On the false branch memory already has the requested value; skip the write and remove the old-value read from this expression.

**Guard / sharp edge:** The false-branch load must use the identical INDEX. Aliasing to a different index is not proved here.

### uop/symbolic.py:L464 — Erase a store of poison

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L464). Exact pattern and callback:

```python
(UPat(Ops.STORE, src=(UPat(), invalid_pat)), lambda i: UOp(Ops.NOOP))
```

**Example:** STORE(addr,Invalid) → NOOP

**Why / helper behavior:** Invalid denotes absence of a value to write, so the effect disappears.

**Guard / sharp edge:** Do not confuse this with writing numeric zero or uninitialized arbitrary bits.

### uop/symbolic.py:L466 — Transfer value validity to store-address validity

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L466). Exact pattern and callback:

```python
(UPat(Ops.STORE, src=(UPat(Ops.INDEX, name="index"), UPat.var("cond").where(UPat.var("val"), invalid_pat))),
   lambda index, cond, val, i: UOp.store(index.src[0].index(index.src[1].valid(cond)), val))
```

**Example:** STORE(i,p ? x : Invalid) → STORE(valid(i,p),x)

**Why / helper behavior:** A condition controlling whether a value exists becomes the store predicate; the backend can emit an ordinary gated store.

**Walkthrough:** When p=false, the value is absent, so this write should not happen. Encoding p as destination validity turns that statement into the form the memory backend consumes; when p=true, it writes x normally.

**Guard / sharp edge:** Only INDEX destinations are matched. Existing address validity must be represented through the INDEX/valid machinery.

### uop/symbolic.py:L468 — Move reciprocal through a square

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L468). Exact pattern and callback:

```python
((UPat.var("x") * UPat.var("x")).reciprocal(), lambda x: x.reciprocal()*x.reciprocal())
```

**Example:** reciprocal(x*x) → reciprocal(x)*reciprocal(x)

**Why / helper behavior:** Exposes a reusable reciprocal and multiplication rather than reciprocal of a product.

**Walkthrough:** Since reciprocal means 1/x, the real-number identity is `1/(x*x)=(1/x)*(1/x)`. Both uses of 1/x can share one graph node, potentially also shared with other consumers.

**Guard / sharp edge:** This is an algebraic optimization with different floating overflow/underflow/rounding; x near the representable extremes is a counterexample to bitwise equivalence.

### uop/symbolic.py:L469 — Move reciprocal through a cube

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L469). Exact pattern and callback:

```python
((UPat.var("x") * UPat.var("x") * UPat.var("x")).reciprocal(), lambda x: x.reciprocal()*x.reciprocal()*x.reciprocal())
```

**Example:** reciprocal((x*x)*x) → reciprocal(x)*reciprocal(x)*reciprocal(x)

**Why / helper behavior:** The explicit depth-three pattern catches the cube tree separately from the square.

**Walkthrough:** The product tree has three x leaves. Replacing it gives three references to the same reciprocal expression, rather than three independently computed reciprocal values by necessity.

**Guard / sharp edge:** Association must match; the same floating exceptional/rounding caveats apply as for the square.

### uop/symbolic.py:L470 — Separate a constant factor from a reciprocal

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L470). Exact pattern and callback:

```python
((UPat.var("x") * UPat.cvar("c")).reciprocal(), lambda x,c: x.reciprocal()*c.reciprocal())
```

**Example:** reciprocal(x*4) → reciprocal(x)*0.25

**Why / helper behavior:** The constant reciprocal folds, making the runtime reciprocal independent of the scale.

**Guard / sharp edge:** c=0 or nonfinite values and floating underflow/overflow need care; there is no explicit nonzero guard in the rule.

### uop/symbolic.py:L471 — Rewrite a ratio around one plus its numerator

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L471). Exact pattern and callback:

```python
(UPat.var("x") * ((1+UPat.var("x")).reciprocal().named("d")), lambda x,d: 1-d)
```

**Example:** x*reciprocal(1+x) → 1-reciprocal(1+x)

**Why / helper behavior:** Shares the denominator reciprocal while eliminating the multiply by x. Inferred use: algebraic cleanup of normalized ratios.

**Walkthrough:** Write x as `(1+x)-1`, then divide: `x/(1+x)=((1+x)-1)/(1+x)=1-1/(1+x)`. At x=3 both sides are 0.75. This derivation explains the subtraction but does not remove the stated floating and singularity caveats.

**Guard / sharp edge:** x=-1 is singular, and cancellation near zero changes numerical error; no stability/domain guard is supplied.

### uop/symbolic.py:L472 — Rewrite a scaled ratio

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L472). Exact pattern and callback:

```python
(UPat.var("x") * ((1+UPat.var("x")).reciprocal().named("d")*UPat.var("y")), lambda x,y,d: y*(1-d))
```

**Example:** x*(reciprocal(1+x)*y) → y*(1-reciprocal(1+x))

**Why / helper behavior:** The nested multiplication needs its own pattern to expose the same ratio simplification with an outside scale.

**Walkthrough:** Apply the previous identity to just x/(1+x), then multiply by y. With x=3 and y=8, both expressions give 6; the separate template is needed because y is nested inside the multiplication tree.

**Guard / sharp edge:** This is tree-sensitive floating algebra, not kernel fusion; singularity and rounding caveats remain.

### uop/symbolic.py:L473 — Rewrite a ratio plus an extra summand

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L473). Exact pattern and callback:

```python
(UPat.var("x") * ((1+UPat.var("x")).reciprocal().named("d")+UPat.var("y")), lambda x,y,d: (1-d)+x*y)
```

**Example:** x*(reciprocal(1+x)+y) → (1-reciprocal(1+x))+x*y

**Why / helper behavior:** Distributes only enough to isolate the recognizable x/(1+x) contribution.

**Walkthrough:** Distribute x over the sum first: `x*(1/(1+x)+y)=x/(1+x)+x*y`. Replace only the first term using the preceding ratio identity. At x=3,y=2 this gives 0.75+6=6.75.

**Guard / sharp edge:** Unlike a universal distribution pass this is a specific pattern; cancellation and exceptional values can differ.

### uop/symbolic.py:L475 — Hoist invariant factors out of a reduction

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L475). Exact pattern and callback:

```python
(UPat(Ops.MUL).reduce(name="r", allow_any_len=True), reduce_mul_chain)
```

**Example:** sum_r(a*x[r]*b) → sum_r(x[r])*a*b; max_r(a*x[r]) → max_r(x[r])*a when a>=0

**Why / helper behavior:** reduce_mul_chain splits the product, retaining factors equal to or dependent on reduced ranges. ADD reductions allow all independent factors; MAX additionally requires nonnegative factors. If everything is independent, the inner expression becomes 1.

**Walkthrough:** For x=[2,5] and constant a=3, the sum is `3*2+3*5=3*(2+5)`. Moving a outside avoids multiplying every element. For maximum, a=-3 changes which element wins (`max(-6,-15)=-6`, whereas `-3*max(2,5)=-15`), explaining the nonnegative guard.

**Guard / sharp edge:** Only ADD and MAX reductions. A negative factor reverses max to min, so cannot move through MAX. Floating reassociation changes rounding; moving work out of a loop is not proof that two kernels fuse.

### uop/symbolic.py:L477 — Distribute a minus over a general sum

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L477). Exact pattern and callback:

```python
(-1 * (UPat.var("x") + UPat.var("y")), lambda x,y: (-x)+(-y))
```

**Example:** -1*(x+y) → -x + -y

**Why / helper behavior:** The opinionated final stage expands expressions further than symbolic_simple, exposing cancellation of terms.

**Walkthrough:** For example, `-(x+y)+x` becomes `-x-y+x`, exposing x and -x for cancellation. This final matcher deliberately accepts some expansion of the graph to reveal later simplifications.

**Guard / sharp edge:** No integer restriction here; floating signed zeros and exceptional arithmetic need care.

### uop/symbolic.py:L479 — Distribute an integer constant over a general sum

[Source](../../../../tinygrad/tinygrad/uop/symbolic.py#L479). Exact pattern and callback:

```python
((UPat.var("x", dtypes.weakint) + UPat.var("y")) * UPat.cvar("c"), lambda x,y,c: x*c+y*c)
```

**Example:** (weakint(i)+j)*4 → i*4+j*4

**Why / helper behavior:** Makes affine address terms explicit so stride/division rules can simplify them. Source restricts this because float inf*0 can be NaN.

**Walkthrough:** If i and j are coordinates, `(i+j)*4` becomes `4*i+4*j`: each coordinate's stride is now explicit. Division/remainder rules can inspect those coefficients directly.

**Guard / sharp edge:** The weakint guard is essential; distributing a floating scale across canceling infinities is not generally valid.

## div_and_mod_symbolic: exact index digit arithmetic

### uop/divandmod.py:L101 — Merge shifted nested quotients

[Source](../../../../tinygrad/tinygrad/uop/divandmod.py#L101). Exact pattern and callback:

```python
((UPat.var("x")//UPat.cvar("c") + UPat.cvar("a"))//UPat.cvar("d"), lambda x,c,a,d: (x+a*c)//(c*d) if d.vmin>0 else None)
```

**Example:** (x//4+3)//2 → (x+12)//8

**Why / helper behavior:** Adding 3 after dividing by 4 adds three groups of four, so it can instead add 12 to the numerator. Dividing the resulting group count by 2 then counts groups of eight directly. This keeps coordinate-and-offset expressions compact.

**Guard / sharp edge:** The executable guard checks d>0; the nearby source comment also says c>0, but the pattern does not explicitly enforce that. Do not report the comment as an implemented c guard; zero divisors are invalid.

### uop/divandmod.py:L103 — Extract whole periods from a constant offset

[Source](../../../../tinygrad/tinygrad/uop/divandmod.py#L103). Exact pattern and callback:

```python
(UPat((Ops.FLOORDIV, Ops.FLOORMOD), src=(UPat.var("x", dtypes.weakint)+UPat.cvar("c"), UPat.cvar("d")), name="n"),
    lambda n,x,c,d: None if d.val==0 or c.val%d.val==c.val else
      (x+c.val%d.val)//d + c.val//d.val if n.op is Ops.FLOORDIV else (x+c.val%d.val)%d)
```

**Example:** (x+19)//8 → (x+3)//8+2; (x+19)%8 → (x+3)%8

**Why / helper behavior:** Split 19 into `2*8+3`. The 16 adds two whole quotient groups and no remainder; only the +3 can affect where x lands within a group. Reducing the offset this way gives the general solver a smaller expression.

**Guard / sharp edge:** x is weakint, d must be nonzero, and no rewrite occurs if c%d==c. Python floor/remainder signs matter for negative d; truncating-C formulas are not substitutes.

### uop/divandmod.py:L108 — General weak-integer division/remainder solver

[Source](../../../../tinygrad/tinygrad/uop/divandmod.py#L108). Exact pattern and callback:

```python
(UPat((Ops.FLOORDIV, Ops.FLOORMOD), dtypes.weakint, name="d"), lambda d: fold_divmod_general(d))
```

**Example:** (8*i+j)//8 → i and (8*i+j)%8 → j for i>=0 and j∈[0,7]

**Why / helper behavior:** fold_divmod_general is a cached, ordered sequence of range, congruence, gcd, and exact-factor proofs. The individual internal branches are explained below rather than treating this helper name as an explanation.

**Guard / sharp edge:** Only weakint; it must not be interpreted as a fixed-width overflowing integer optimizer. A branch may return None and allow later rules to try; zero divisor is explicitly rejected.


#### Reading the division solver without number-theory background

All its branches try to separate complete groups from a small leftover. For divisor 8, `8*i+j` contains i complete groups and remainder j only if `0<=j<8`. If j=9, there is another complete group, so dropping j from the quotient is wrong. Bounds supply that missing proof.

A coefficient need not be divisible by 8 to make progress. Split `13*i` into `8*i+5*i`: the first part contributes i to the quotient, while the second still needs division. A gcd simplifies a different way: when all variable coefficients and the divisor share 2, factor 2 out before doing the harder work. The constant offset must be split too so its leftover is not lost.

“Bucket” below means an interval with a single floor quotient: for divisor 8, [16,23] is bucket 2 and [-8,-1] is bucket -1. “Backward-slice size” counts the operations needed to compute a candidate result by following its inputs; the helper uses fewer operations as a rough preference between valid answers.

#### Inside the L108 helper: each ordered branch

These are branches of **one matcher callback**, not extra PM entries. All examples are mathematical weak-integer examples; the indicated branch can be preempted by an earlier successful branch.

1. **Zero denominator (line 12).** If `y.vmin==y.vmax==0`, raise `ZeroDivisionError`. Example: `i//0` does not become an arbitrary constant. This diagnoses impossible index math rather than emitting a faulty division. A merely possibly-zero divisor does not meet this exact check.
2. **Constant quotient interval (line 14).** Compute quotient bounds. If they agree on `q`, `x//y → q` and `x%y → x-q*y`. Example: `x∈[16,23], y=8` gives quotient 2 and remainder `x-16`. This avoids division whenever the interval occupies one bucket, including variable denominators if bounds prove it. A range crossing 24 cannot use q=2 throughout.
3. **PARAM divisibility metadata (line 16).** For `PARAM % CONST(c)`, if `PARAM.arg.multiple_of % c == 0`, return zero; its quotient is treated as irreducible and returns None. Example: a parameter declared a multiple of 16 has `p%8 → 0`. The same metadata does not tell the runtime value of `p//8`.
4. **Peel affine terms (lines 19–20).** Separate the additive constant, split ADDs, and later obtain each term’s constant factor. Example: `12*i+6*j+5` becomes terms `12*i,6*j` and constant 5. This is analysis setup, not an independent semantic rewrite; it relies on canonical coefficient extraction.
5. **Nested modulus then quotient (line 25).** For positive constant denominator c, `(x%(k*c))//c → (x//c)%k` if the modulus divides exactly by c and k is provably positive. Example: `(x%32)//8 → (x//8)%4`. This expresses a digit directly. An unknown-sign k is rejected.
6. **Remove inner moduli in a sum (lines 28–35).** Under `%c`, replace a term `a%m` by `a` when m is exactly divisible by c. Example: `(a%12+b)%4 → (a+b)%4`. Inner wrapping changes the numerator only by whole outer periods. Without the divisibility relation, `(a%10)%4` is not `a%4` (a=10 is a counterexample).
7. **Congruence using bounded remainders (lines 37–49).** Write coefficients as `f=q*c+r`. Try small signed representatives r, including both signs for a lone term or an exact half-period tie. If the residual sum plus `const%c` stays in one quotient bucket, replace modulo with that residual minus its bucket base, or replace division with the extracted q-weighted sum plus the bucket. Example: `(8*i+j+2)%8 → j+2` for j∈[0,3]; quotient becomes i. Example explaining the signed representative: `(7*i+8)%8 → 8-i` for i∈[1,2], because 7≡−1 mod 8 and −i lies in one negative bucket. Without tight residual bounds this proof does not fire; modular congruence alone does not identify a concrete remainder.
8. **GCD with a constant remainder (lines 52–56).** Compute `g=gcd(term coefficients,c)>1`; divide variable terms by g and retain the constant’s two residues. With `new_x=(x_without_const/g)+(const//g)%(c//g)` and nonnegative new_x, modulo becomes `(new_x%(c//g))*g+const%g`; division becomes `new_x//(c//g)+const//c`. Example: `(6*i+5)%4 → ((3*i)%2)*2+1`; `(6*i+5)//4 → (3*i)//2+1`, for nonnegative i. The low constant residue cannot be dropped: +1 matters in the remainder. The nonnegative new_x guard is explicit.
9. **Nest by a useful numerator factor (lines 61–73).** Try each absolute coefficient f with `1<f<c` and `c%f==0`, recursively simplify `x//f`, then divide that smaller quotient by c/f. Example: `(4*i+j)//12 → i//3` if j∈[0,3]. For modulo reconstruct `(new_quotient%(c/f))*f+b`, but only with nonnegative numerator/quotient and a residual b proven in `[0,f)`. Example: `(4*i+j)%12 → (i%3)*4+j` for nonnegative i and j∈[0,3]. Choose the result with smallest backward-slice size among successes. j=4 breaks the residual proof; the helper will not silently treat it as a low digit.
10. **Exact common divisor, including symbolic denominators (lines 80–83).** Compute a UOp gcd across every numerator term and the denominator. Divide both sides exactly; for remainder multiply the reduced remainder back by gcd. Example: `(6*i+9*j)//3 → 2*i+3*j`, and `(6*i)%(9*j) → 3*((2*i)%(3*j))` for suitable nonzero denominator. Symbolic shared factors can participate because this is `UOp.gcd`, not just `math.gcd` of constants. No rewrite is made for gcd=1; ordinary rounding division is not used to cancel a purported factor.
11. **Extract exact quotient terms (lines 86–96).** If numerator or denominator has a negative lower bound, give up. Otherwise partition additive terms into exact multiples of y and remainder terms. With constant y, split coefficients into quotient/remainder parts too. Example: `(d*i+j)//d → i+j//d` for positive d and nonnegative i,j; modulo drops d*i. A term `13*i` at y=8 contributes `i` to the quotient and `5*i` to the residual. Require at least one extracted quotient and a nonnegative rebuilt remainder. This conservative final fallback avoids sign interactions; failure is not evidence the identity is mathematically false.

#### Why this helper matters for a real row-reduction address

For an RMSNorm row stored contiguously with width H=8, a scheduler may temporarily represent the address as `(flat//8)*8 + flat%8`. L126 recombines that to `flat`; the inverse transform `(8*row+col)//8` and `%8` simplify to `row` and `col` when `col=RANGE(8)`. These are address identities under explicit range proofs, not evidence of kernel fusion. Kernel fusion additionally depends on schedule boundaries, reduction dependencies, storage, and resource constraints. For example, `col=RANGE(16)` invalidates the one-digit proof: column 9 must carry into the next row.

## mop_cleanup: shape and indexing identities

### uop/movement.py:L7 — Collapse adjacent reshapes

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L7). Exact pattern and callback:

```python
(UPat(Ops.RESHAPE, src=(UPat(Ops.RESHAPE, name="x2"), UPat()), name="x"), lambda x,x2: x.replace(src=(x2.src[0], x.src[1])))
```

**Example:** reshape(reshape(x,(2,6)),(3,4)) → reshape(x,(3,4))

**Why / helper behavior:** Only the final logical shape matters when reshaping the same linear element order.

**Guard / sharp edge:** The final shape source is retained; this is not a permutation or a physical transpose.

### uop/movement.py:L9 — Remove an unchanged reshape

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L9). Exact pattern and callback:

```python
(UPat(Ops.RESHAPE, src=(UPat(name="x2"), UPat()), name="x"), lambda x,x2: x2 if x2._shape is not None and x2.shape == x.shape else None)
```

**Example:** reshape(x,(3,4)) → x when x.shape==(3,4)

**Why / helper behavior:** Avoid a metadata-only wrapper when input and output shapes already agree.

**Guard / sharp edge:** Requires x._shape is not None; an unknown shape cannot be assumed equal.

### uop/movement.py:L11 — Compose two permutations

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L11). Exact pattern and callback:

```python
(UPat(Ops.PERMUTE, src=(UPat(Ops.PERMUTE, name="x2"),), name="x"), lambda x,x2: x2.replace(arg=tuple(x2.arg[i] for i in x.arg)))
```

**Example:** permute(permute(x,(1,0,2)),(2,0,1)) → permute(x,(2,1,0))

**Why / helper behavior:** Name the original axes A,B,C. The first permutation gives B,A,C; choosing positions 2,0,1 from that gives C,B,A, or original positions 2,1,0. In code, resulting axis i is x2.arg[x.arg[i]].

**Guard / sharp edge:** Order matters; composing tuples in the opposite order gives a different permutation.

### uop/movement.py:L13 — Erase an identity permutation

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L13). Exact pattern and callback:

```python
(UPat(Ops.PERMUTE, name="x"), lambda x: x.src[0] if list(x.arg) == list(range(len(x.arg))) else None)
```

**Example:** permute(x,(0,1,2)) → x

**Why / helper behavior:** The axes already appear in their original order.

**Guard / sharp edge:** Equal dimension sizes do not make (1,0) an identity; values can still transpose.

### uop/movement.py:L15 — Undo a stack of all components in order

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L15). Exact pattern and callback:

```python
(UPat(Ops.STACK, src=UPat(Ops.INDEX, src=(UPat.var("src"), UPat(Ops.CONST))), name="stk"),
   lambda src,stk: src if stk.shape == src.shape and list(range(len(stk.src))) == [x.src[1].val for x in stk.src] else None)
```

**Example:** STACK(x[0],x[1],x[2]) → x when the stack shape equals x.shape

**Why / helper behavior:** Reassembling each constant-index component of the same source is the original tensor/vector.

**Guard / sharp edge:** Requires exact index list 0..len(stack)-1 and equal shapes. Reordered, repeated, or partial components cannot fold.

### uop/movement.py:L18 — Select a constant component from a stack

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L18). Exact pattern and callback:

```python
(UPat(Ops.INDEX, src=(UPat(Ops.STACK, name="a"), UPat.cvar("i")), name="idx", allow_any_len=True),
   lambda a,i,idx: a.src[i.val] if len(idx.src) <= 2 else a.src[i.val].index(*idx.src[2:]))
```

**Example:** INDEX(STACK(a,b,c),1) → b; INDEX(STACK(a,b),1,j) → INDEX(b,j)

**Why / helper behavior:** The stack’s source tuple directly contains the selected value; remaining indices apply to that value.

**Guard / sharp edge:** The index must be constant. This is source selection, not an arbitrary dynamic gather; valid index bounds are assumed upstream.

### uop/movement.py:L21 — Concatenate successive scalar indexing steps

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L21). Exact pattern and callback:

```python
(UPat(Ops.INDEX, src=(UPat(Ops.INDEX, name="idx1", allow_any_len=True),), allow_any_len=True, name="idx2"),
   lambda idx1,idx2: idx1.src[0].index(*idx1.src[1:], *idx2.src[1:]) if all(x.shape == () for x in idx1.src[1:]+idx2.src[1:]) else None)
```

**Example:** INDEX(INDEX(x,i),j) → INDEX(x,i,j) when i,j have shape ()

**Why / helper behavior:** Sequential scalar dimension selection can use one INDEX with the combined index tuple.

**Guard / sharp edge:** All indices from both INDEX nodes must be scalar; vector/advanced indexing can change shape and is not interchangeable with concatenation.

### uop/movement.py:L24 — Push selection through a shaped index

[Source](../../../../tinygrad/tinygrad/uop/movement.py#L24). Exact pattern and callback:

```python
(UPat(Ops.INDEX, src=(UPat(Ops.INDEX, src=(UPat.var("buf"), UPat.var("idx1_arg"))),), allow_any_len=True, name="idx2"),
   lambda buf,idx1_arg,idx2: buf.index(idx1_arg.index(*idx2.src[1:])) if len(idx1_arg.shape) == len(idx2.src[1:]) else None)
```

**Example:** INDEX(INDEX(buf,idx_vector),j) → INDEX(buf,INDEX(idx_vector,j))

**Why / helper behavior:** With idx_vector=[5,2,9], the intermediate gather is [buf[5],buf[2],buf[9]]. Selecting position 1 needs only buf[2]: first select address idx_vector[1], then read buf at that address. This avoids describing unneeded gathered elements.

**Guard / sharp edge:** Requires rank(idx1_arg)==number of outer indices. Source marks this TODO for more generic handling; the preceding scalar-index rule is a different case.

