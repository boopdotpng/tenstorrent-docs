import sys
sys.path.insert(0,'tinygrad')
import z3
from tinygrad.uop.ops import UOp, Ops, ParamArg
from tinygrad.dtype import dtypes
from tinygrad.uop.weak import pm_commit_weak,pm_uncast_const,pm_cast_const,pm_lower_weak
from tinygrad.uop.validate import validate_index_with_z3,z3_cdiv,z3_floordiv,z3_and,z3_xor
from tinygrad.uop.spec import spec_shared,spec_program,spec_tensor
x=UOp.variable('x',0,100,dtypes.float32,param=True)
y=UOp.variable('y',0,100,dtypes.int32,param=True)
a=x+UOp.const(2.0,dtypes.float32)
b=pm_uncast_const.rewrite(a)
assert b is not None and b.src[1].op is Ops.CONST
assert pm_cast_const.rewrite(b) is a
assert spec_program.rewrite(a) is True
assert spec_program.rewrite(b) is False
assert spec_shared.rewrite(UOp(Ops.AND,src=(x,x))) is False
assert spec_tensor.rewrite(UOp(Ops.EXP2,src=(y,))) is True
assert pm_cast_const.rewrite(UOp.const(True).where(x,x)).src[0].op is Ops.CAST
store=UOp(Ops.STORE,src=(UOp(Ops.PARAM,arg=ParamArg(0,dtypes.float16)),UOp.const(1.25)))
assert pm_commit_weak.rewrite(store).src[1].dtype is dtypes.float16
wide=(UOp.variable('n',0,100000)+1).cast(dtypes.int16)
assert pm_commit_weak.rewrite(wide).src[0].dtype is dtypes.int32
nested=x.cast(dtypes.weakint).cast(dtypes.weakfloat)
r=pm_lower_weak.rewrite(nested)
assert r.dtype is dtypes.weakfloat and r.src[0].dtype is dtypes.float32 and r.src[0].src[0].dtype is dtypes.int32
variable=UOp.variable('v',0,1024)
assert pm_lower_weak.rewrite(variable).src[0].dtype is dtypes.int32
consume=y.cast(dtypes.weakint)+y.cast(dtypes.weakint)
assert pm_lower_weak.rewrite(consume).src[0].dtype is dtypes.int32
i=UOp.variable('i',0,31,dtypes.int32,param=True)
assert validate_index_with_z3(16,i,i<16)
for aa,bb,div,want in [(-7,3,z3_cdiv,-2),(-7,-3,z3_cdiv,2),(-7,3,z3_floordiv,-3),(7,-3,z3_floordiv,-3)]:
 assert z3.simplify(div(z3.IntVal(aa),z3.IntVal(bb))).as_long()==want
s=z3.Int('s')
for expr,value,want in [(z3_and(s,z3.IntVal(7)),-3,5),(z3_and(s,z3.IntVal(-8)),13,8),(z3_xor(s,z3.IntVal(-1)),13,-14)]:
 assert z3.simplify(z3.substitute(expr,(s,z3.IntVal(value)))).as_long()==want
print('20 assertions passed')
