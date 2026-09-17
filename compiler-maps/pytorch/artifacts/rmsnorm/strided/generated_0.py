# AOT ID: ['6_inference']
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


cpp_fused_add_mean_mul_pow_rsqrt_0 = async_compile.cpp_pybinding(['const float*', 'const float*', 'float*', 'float*'], r'''
#include <torch/csrc/inductor/cpp_prefix.h>
extern "C"  void  kernel(const float* in_ptr0,
                       const float* in_ptr1,
                       float* out_ptr0,
                       float* out_ptr1)
{
    {
        for(int64_t x0=static_cast<int64_t>(0L); x0<static_cast<int64_t>(8L); x0+=static_cast<int64_t>(16L))
        {
            {
                float tmp_acc0 = 0;
                at::vec::Vectorized<float> tmp_acc0_vec = at::vec::Vectorized<float>(0);
                at::vec::Vectorized<float> tmp_acc0_vec_arr[2];
                for (int i = 0; i < 2; i++)
                {
                    tmp_acc0_vec_arr[i] = at::vec::Vectorized<float>(0);
                }
                float tmp_acc0_arr[2];
                for (int i = 0; i < 2; i++)
                {
                    tmp_acc0_arr[i] = 0;
                }
                #pragma omp parallel num_threads(2)
                {
                    int tid = omp_get_thread_num();
                    at::vec::Vectorized<float> tmp_acc0_vec_local = at::vec::Vectorized<float>(0);
                    float tmp_acc0_local = 0;
                    #pragma omp for
                    for(int64_t x1=static_cast<int64_t>(0L); x1<static_cast<int64_t>(128L); x1+=static_cast<int64_t>(1L))
                    {
                        {
                            if(C10_LIKELY(x0 >= static_cast<int64_t>(0L) && x0 < static_cast<int64_t>(8L)))
                            {
                                auto tmp0 = at::vec::Vectorized<float>::loadu(in_ptr0 + static_cast<int64_t>(x0 + 8L*x1), static_cast<int64_t>(8L));
                                auto tmp1 = tmp0 * tmp0;
                                tmp_acc0_vec_local = sum_masked_reduce(tmp_acc0_vec_local, tmp1, static_cast<int64_t>(8L));
                            }
                        }
                    }
                    tmp_acc0_vec_arr[tid] = tmp_acc0_vec_local;
                    tmp_acc0_arr[tid] = tmp_acc0_local;
                }
                for (int tid = 0; tid < 2; tid++)
                {
                    tmp_acc0_vec = tmp_acc0_vec + tmp_acc0_vec_arr[tid];
                }
                for (int tid = 0; tid < 2; tid++)
                {
                    tmp_acc0 = tmp_acc0 + tmp_acc0_arr[tid];
                }
                if(C10_UNLIKELY(x0 >= static_cast<int64_t>(0L) && x0 < static_cast<int64_t>(8L)))
                {
                    tmp_acc0_vec.store(out_ptr0 + static_cast<int64_t>(x0), static_cast<int64_t>(8L));
                }
            }
        }
    }
    #pragma omp parallel num_threads(2)
    {
        int tid = omp_get_thread_num();
        {
            #pragma omp for
            for(int64_t x0=static_cast<int64_t>(0L); x0<static_cast<int64_t>(128L); x0+=static_cast<int64_t>(1L))
            {
                for(int64_t x1=static_cast<int64_t>(0L); x1<static_cast<int64_t>(8L); x1+=static_cast<int64_t>(16L))
                {
                    {
                        if(C10_LIKELY(x1 >= static_cast<int64_t>(0L) && x1 < static_cast<int64_t>(8L)))
                        {
                            auto tmp0 = at::vec::Vectorized<float>::loadu(in_ptr0 + static_cast<int64_t>(x1 + 8L*x0), static_cast<int64_t>(8L));
                            auto tmp1 = at::vec::Vectorized<float>::loadu(out_ptr0 + static_cast<int64_t>(x1), static_cast<int64_t>(8L));
                            auto tmp10 = in_ptr1[static_cast<int64_t>(x0)];
                            auto tmp2 = static_cast<float>(128.0);
                            auto tmp3 = at::vec::Vectorized<float>(tmp2);
                            auto tmp4 = tmp1 / tmp3;
                            auto tmp5 = static_cast<float>(1e-05);
                            auto tmp6 = at::vec::Vectorized<float>(tmp5);
                            auto tmp7 = tmp4 + tmp6;
                            auto tmp8 = tmp7.rsqrt();
                            auto tmp9 = tmp0 * tmp8;
                            auto tmp11 = at::vec::Vectorized<float>(tmp10);
                            auto tmp12 = tmp9 * tmp11;
                            tmp12.store(out_ptr1 + static_cast<int64_t>(x1 + 8L*x0), static_cast<int64_t>(8L));
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
        arg0_1, arg1_1 = args
        args.clear()
        assert_size_stride(arg0_1, (8, 128), (1, 8))
        assert_size_stride(arg1_1, (128, ), (1, ))
        buf0 = empty_strided_cpu((8, 1), (1, 8), torch.float32)
        buf1 = empty_strided_cpu((8, 128), (1, 8), torch.float32)
        # [Provenance debug handles] cpp_fused_add_mean_mul_pow_rsqrt_0:1
        cpp_fused_add_mean_mul_pow_rsqrt_0(arg0_1, arg1_1, buf0, buf1)
        del arg0_1
        del arg1_1
        return (buf1, )

runner = Runner(partitions=[])
call = runner.call
recursively_apply_fns = runner.recursively_apply_fns


def get_args():
    from torch._dynamo.testing import rand_strided
    arg0_1 = rand_strided((8, 128), (1, 8), device='cpu', dtype=torch.float32)
    arg1_1 = rand_strided((128, ), (1, ), device='cpu', dtype=torch.float32)
    return [arg0_1, arg1_1]


def benchmark_compiled_module(args, times=10, repeat=10):
    from torch._inductor.utils import print_performance
    fn = lambda: call(list(args))
    return print_performance(fn, times=times, repeat=repeat)


if __name__ == "__main__":
    from torch._inductor.wrapper_benchmark import compiled_module_main
    args = get_args()
    compiled_module_main('None', lambda times, repeat: benchmark_compiled_module(args, times=times, repeat=repeat))
