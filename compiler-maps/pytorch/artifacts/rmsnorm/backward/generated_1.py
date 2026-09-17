# AOT ID: ['4_backward']
from ctypes import c_void_p, c_long, c_int
import torch
import math
import random
import os
import tempfile
from math import inf, nan
from cmath import nanj
from torch._inductor.hooks import run_intermediate_hooks
from torch._inductor.utils import maybe_profile
from torch._inductor.codegen.memory_planning import _align as align
from torch import device, empty_strided
from torch._inductor.async_compile import AsyncCompile
from torch._inductor.select_algorithm import extern_kernels

aten = torch.ops.aten
inductor_ops = torch.ops.inductor
_quantized = torch.ops._quantized
assert_size_stride = torch._C._dynamo.guards.assert_size_stride
assert_alignment = torch._C._dynamo.guards.assert_alignment
empty_strided_cpu = torch._C._dynamo.guards._empty_strided_cpu
empty_strided_cpu_pinned = torch._C._dynamo.guards._empty_strided_cpu_pinned
empty_strided_cuda = torch._C._dynamo.guards._empty_strided_cuda
empty_strided_xpu = torch._C._dynamo.guards._empty_strided_xpu
empty_strided_mtia = torch._C._dynamo.guards._empty_strided_mtia
reinterpret_tensor = torch._C._dynamo.guards._reinterpret_tensor
alloc_from_pool = torch.ops.inductor._alloc_from_pool
async_compile = AsyncCompile()
empty_strided_p2p = torch._C._distributed_c10d._SymmetricMemory.empty_strided_p2p


cpp_fused_add_div_expand_mul_pow_sum_0 = async_compile.cpp_pybinding(['const float*', 'const float*', 'const float*', 'const float*', 'float*', 'float*', 'float*'], r'''
#include <torch/csrc/inductor/cpp_prefix.h>
extern "C"  void  kernel(const float* in_ptr0,
                       const float* in_ptr1,
                       const float* in_ptr2,
                       const float* in_ptr3,
                       float* out_ptr0,
                       float* out_ptr1,
                       float* out_ptr2)
{
    #pragma omp parallel num_threads(2)
    {
        int tid = omp_get_thread_num();
        {
            #pragma omp for
            for(int64_t x0=static_cast<int64_t>(0L); x0<static_cast<int64_t>(128L); x0+=static_cast<int64_t>(16L))
            {
                {
                    float tmp_acc0 = 0;
                    at::vec::Vectorized<float> tmp_acc0_vec = at::vec::Vectorized<float>(0);
                    for(int64_t x1=static_cast<int64_t>(0L); x1<static_cast<int64_t>(8L); x1+=static_cast<int64_t>(1L))
                    {
                        {
                            if(C10_LIKELY(x0 >= static_cast<int64_t>(0) && x0 < static_cast<int64_t>(128L)))
                            {
                                auto tmp0 = at::vec::Vectorized<float>::loadu(in_ptr0 + static_cast<int64_t>(x0 + 128L*x1), static_cast<int64_t>(16));
                                auto tmp1 = at::vec::Vectorized<float>::loadu(in_ptr1 + static_cast<int64_t>(x0 + 128L*x1), static_cast<int64_t>(16));
                                auto tmp2 = in_ptr2[static_cast<int64_t>(x1)];
                                auto tmp3 = at::vec::Vectorized<float>(tmp2);
                                auto tmp4 = tmp1 * tmp3;
                                auto tmp5 = tmp0 * tmp4;
                                tmp_acc0_vec = tmp_acc0_vec + tmp5;
                            }
                        }
                    }
                    if(C10_LIKELY(x0 >= static_cast<int64_t>(0) && x0 < static_cast<int64_t>(128L)))
                    {
                        tmp_acc0_vec.store(out_ptr0 + static_cast<int64_t>(x0));
                    }
                }
            }
        }
        {
            #pragma omp for
            for(int64_t x0=static_cast<int64_t>(0L); x0<static_cast<int64_t>(8L); x0+=static_cast<int64_t>(1L))
            {
                {
                    float tmp_acc0 = 0;
                    at::vec::Vectorized<float> tmp_acc0_vec = at::vec::Vectorized<float>(0);
                    for(int64_t x1=static_cast<int64_t>(0L); x1<static_cast<int64_t>(128L); x1+=static_cast<int64_t>(16L))
                    {
                        {
                            if(C10_LIKELY(x1 >= static_cast<int64_t>(0) && x1 < static_cast<int64_t>(128L)))
                            {
                                auto tmp0 = at::vec::Vectorized<float>::loadu(in_ptr0 + static_cast<int64_t>(x1 + 128L*x0), static_cast<int64_t>(16));
                                auto tmp1 = at::vec::Vectorized<float>::loadu(in_ptr3 + static_cast<int64_t>(x1), static_cast<int64_t>(16));
                                auto tmp3 = at::vec::Vectorized<float>::loadu(in_ptr1 + static_cast<int64_t>(x1 + 128L*x0), static_cast<int64_t>(16));
                                auto tmp2 = tmp0 * tmp1;
                                auto tmp4 = tmp2 * tmp3;
                                tmp_acc0_vec = tmp_acc0_vec + tmp4;
                            }
                        }
                    }
                    tmp_acc0 = tmp_acc0 + at::vec::vec_reduce_all<float, 1>([](at::vec::Vectorized<float>& x, at::vec::Vectorized<float>& y) { return x + y; }, tmp_acc0_vec);
                    out_ptr1[static_cast<int64_t>(x0)] = static_cast<float>(tmp_acc0);
                }
                for(int64_t x1=static_cast<int64_t>(0L); x1<static_cast<int64_t>(128L); x1+=static_cast<int64_t>(16L))
                {
                    {
                        if(C10_LIKELY(x1 >= static_cast<int64_t>(0) && x1 < static_cast<int64_t>(128L)))
                        {
                            auto tmp0 = at::vec::Vectorized<float>::loadu(in_ptr0 + static_cast<int64_t>(x1 + 128L*x0), static_cast<int64_t>(16));
                            auto tmp1 = at::vec::Vectorized<float>::loadu(in_ptr3 + static_cast<int64_t>(x1), static_cast<int64_t>(16));
                            auto tmp3 = in_ptr2[static_cast<int64_t>(x0)];
                            auto tmp6 = out_ptr1[static_cast<int64_t>(x0)];
                            auto tmp14 = at::vec::Vectorized<float>::loadu(in_ptr1 + static_cast<int64_t>(x1 + 128L*x0), static_cast<int64_t>(16));
                            auto tmp2 = tmp0 * tmp1;
                            auto tmp4 = at::vec::Vectorized<float>(tmp3);
                            auto tmp5 = tmp2 * tmp4;
                            auto tmp7 = static_cast<float>(-0.5);
                            auto tmp8 = float(tmp6 * tmp7);
                            auto tmp9 = float(tmp3 * tmp3);
                            auto tmp10 = float(tmp9 * tmp3);
                            auto tmp11 = float(tmp8 * tmp10);
                            auto tmp12 = static_cast<float>(128.0);
                            auto tmp13 = tmp11 / tmp12;
                            auto tmp15 = static_cast<float>(2.0);
                            auto tmp16 = at::vec::Vectorized<float>(tmp15);
                            auto tmp17 = tmp14 * tmp16;
                            auto tmp18 = at::vec::Vectorized<float>(tmp13);
                            auto tmp19 = tmp18 * tmp17;
                            auto tmp20 = tmp5 + tmp19;
                            tmp20.store(out_ptr2 + static_cast<int64_t>(x1 + 128L*x0));
                        }
                    }
                }
            }
        }
    }
}
''')


async_compile.wait(globals())
del async_compile

class Runner:
    def __init__(self, partitions):
        self.partitions = partitions

    def recursively_apply_fns(self, fns):
        new_callables = []
        for fn, c in zip(fns, self.partitions):
            new_callables.append(fn(c))
        self.partitions = new_callables

    def call(self, args):
        primals_1, primals_2, rsqrt, tangents_1 = args
        args.clear()
        assert_size_stride(primals_1, (8, 128), (128, 1))
        assert_size_stride(primals_2, (128, ), (1, ))
        assert_size_stride(rsqrt, (8, 1), (1, 1))
        assert_size_stride(tangents_1, (8, 128), (128, 1))
        buf0 = empty_strided_cpu((1, 128), (128, 1), torch.float32)
        buf1 = empty_strided_cpu((8, 1), (1, 8), torch.float32)
        buf2 = empty_strided_cpu((8, 128), (128, 1), torch.float32)
        # [Provenance debug handles] cpp_fused_add_div_expand_mul_pow_sum_0:1
        cpp_fused_add_div_expand_mul_pow_sum_0(tangents_1, primals_1, rsqrt, primals_2, buf0, buf1, buf2)
        del buf1
        del primals_1
        del primals_2
        del rsqrt
        del tangents_1
        return (buf2, reinterpret_tensor(buf0, (128, ), (1, ), 0), )

runner = Runner(partitions=[])
call = runner.call
recursively_apply_fns = runner.recursively_apply_fns


def get_args():
    from torch._dynamo.testing import rand_strided
    primals_1 = rand_strided((8, 128), (128, 1), device='cpu', dtype=torch.float32)
    primals_2 = rand_strided((128, ), (1, ), device='cpu', dtype=torch.float32)
    rsqrt = rand_strided((8, 1), (1, 1), device='cpu', dtype=torch.float32)
    tangents_1 = rand_strided((8, 128), (128, 1), device='cpu', dtype=torch.float32)
    return [primals_1, primals_2, rsqrt, tangents_1]


def benchmark_compiled_module(args, times=10, repeat=10):
    from torch._inductor.utils import print_performance
    fn = lambda: call(list(args))
    return print_performance(fn, times=times, repeat=repeat)


if __name__ == "__main__":
    from torch._inductor.wrapper_benchmark import compiled_module_main
    args = get_args()
    compiled_module_main('None', lambda times, repeat: benchmark_compiled_module(args, times=times, repeat=repeat))
