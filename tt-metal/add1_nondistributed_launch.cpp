#include <bit>
#include <cmath>
#include <cstdlib>
#include <random>
#include <vector>

#include <tt-metalium/bfloat16.hpp>
#include <tt-metalium/device.hpp>
#include <tt-metalium/host_api.hpp>
#include <tt-metalium/tensor_accessor_args.hpp>
#include <tt-metalium/tt_metal.hpp>

using namespace tt;
using namespace tt::tt_metal;

namespace {
constexpr const char kReaderKernel[] = R"TTK(
#include <cstdint>

void kernel_main() {
  uint32_t in0_addr = get_arg_val<uint32_t>(0);
  uint32_t n_tiles = get_arg_val<uint32_t>(1);

  constexpr uint32_t cb_in0 = tt::CBIndex::c_0;
  const uint32_t tile_size_bytes = get_tile_size(cb_in0);

  constexpr auto in0_args = TensorAccessorArgs<0>();
  const auto in0 = TensorAccessor(in0_args, in0_addr, tile_size_bytes);

  for (uint32_t i = 0; i < n_tiles; ++i) {
    cb_reserve_back(cb_in0, 1);
    uint32_t cb_in0_addr = get_write_ptr(cb_in0);

    noc_async_read_tile(i, in0, cb_in0_addr);
    noc_async_read_barrier();

    cb_push_back(cb_in0, 1);
  }
}
)TTK";

constexpr const char kWriterKernel[] = R"TTK(
#include <cstdint>

void kernel_main() {
  uint32_t out_addr = get_arg_val<uint32_t>(0);
  uint32_t n_tiles = get_arg_val<uint32_t>(1);

  constexpr uint32_t cb_out0 = tt::CBIndex::c_16;
  const uint32_t tile_size_bytes = get_tile_size(cb_out0);

  constexpr auto out0_args = TensorAccessorArgs<0>();
  const auto out0 = TensorAccessor(out0_args, out_addr, tile_size_bytes);

  for (uint32_t i = 0; i < n_tiles; ++i) {
    cb_wait_front(cb_out0, 1);
    uint32_t cb_out0_addr = get_read_ptr(cb_out0);

    noc_async_write_tile(i, out0, cb_out0_addr);
    noc_async_write_barrier();

    cb_pop_front(cb_out0, 1);
  }
}
)TTK";

constexpr const char kComputeKernel[] = R"TTK(
#include <cstdint>
#include "compute_kernel_api/common.h"
#include "compute_kernel_api/tile_move_copy.h"
#include "compute_kernel_api/eltwise_unary/eltwise_unary.h"

#ifdef TRISC_MATH
#include "sfpi.h"
#endif

namespace NAMESPACE {

void MAIN {
  uint32_t n_tiles = get_arg_val<uint32_t>(0);
  uint32_t scalar_bits = get_arg_val<uint32_t>(1);

  init_sfpu(tt::CBIndex::c_0, tt::CBIndex::c_16);

  for (uint32_t i = 0; i < n_tiles; ++i) {
    tile_regs_acquire();
    cb_wait_front(tt::CBIndex::c_0, 1);
    copy_tile(tt::CBIndex::c_0, /*cb_offset=*/0, /*reg_offset=*/0);

#ifdef TRISC_MATH
    union {
      uint32_t u;
      float f;
    } conv = {scalar_bits};
    const sfpi::vFloat scalar = conv.f;
    constexpr uint32_t vectors_per_tile = 32;
    for (uint32_t v = 0; v < vectors_per_tile; ++v) {
      sfpi::dst_reg[v] = sfpi::dst_reg[v] + scalar;
    }
#endif

    tile_regs_commit();
    tile_regs_wait();

    cb_reserve_back(tt::CBIndex::c_16, 1);
    pack_tile(/*reg_offset=*/0, tt::CBIndex::c_16);
    cb_pop_front(tt::CBIndex::c_0, 1);
    tile_regs_release();
    cb_push_back(tt::CBIndex::c_16, 1);
  }
}
}  
)TTK";
} 

int main() {
  bool pass = true;

  try {
    setenv("TT_METAL_SLOW_DISPATCH_MODE", "1", 1);
    constexpr int device_id = 0;
    IDevice* device = CreateDevice(device_id);

    Program program = CreateProgram();
    constexpr CoreCoord core = {0, 0};

    constexpr uint32_t n_tiles = 64;
    constexpr uint32_t elements_per_tile =
        tt::constants::TILE_WIDTH * tt::constants::TILE_HEIGHT;
    constexpr uint32_t tile_size_bytes = sizeof(bfloat16) * elements_per_tile;

    InterleavedBufferConfig dram_config{
        .device = device,
        .size = tile_size_bytes * n_tiles,
        .page_size = tile_size_bytes,
        .buffer_type = tt_metal::BufferType::DRAM};

    std::shared_ptr<Buffer> src_dram_buffer = CreateBuffer(dram_config);
    std::shared_ptr<Buffer> dst_dram_buffer = CreateBuffer(dram_config);

    constexpr uint32_t cb_in0 = tt::CBIndex::c_0;
    constexpr uint32_t cb_out0 = tt::CBIndex::c_16;
    constexpr uint32_t cb_tiles = 2;

    CircularBufferConfig cb_in0_config(
        cb_tiles * tile_size_bytes, {{cb_in0, tt::DataFormat::Float16_b}});
    cb_in0_config.set_page_size(cb_in0, tile_size_bytes);
    tt_metal::CreateCircularBuffer(program, core, cb_in0_config);

    CircularBufferConfig cb_out0_config(
        cb_tiles * tile_size_bytes, {{cb_out0, tt::DataFormat::Float16_b}});
    cb_out0_config.set_page_size(cb_out0, tile_size_bytes);
    tt_metal::CreateCircularBuffer(program, core, cb_out0_config);

    std::vector<uint32_t> reader_compile_time_args;
    TensorAccessorArgs(*src_dram_buffer).append_to(reader_compile_time_args);
    KernelHandle reader_kernel_id = CreateKernelFromString(
        program,
        kReaderKernel,
        core,
        DataMovementConfig{
            .processor = DataMovementProcessor::RISCV_1,
            .noc = NOC::RISCV_1_default,
            .compile_args = reader_compile_time_args});

    std::vector<uint32_t> writer_compile_time_args;
    TensorAccessorArgs(*dst_dram_buffer).append_to(writer_compile_time_args);
    KernelHandle writer_kernel_id = CreateKernelFromString(
        program,
        kWriterKernel,
        core,
        DataMovementConfig{
            .processor = DataMovementProcessor::RISCV_0,
            .noc = NOC::RISCV_0_default,
            .compile_args = writer_compile_time_args});

    KernelHandle add1_kernel_id = CreateKernelFromString(
        program,
        kComputeKernel,
        core,
        ComputeConfig{
            .math_fidelity = MathFidelity::HiFi4,
            .math_approx_mode = false,
        });

    std::mt19937 rng(std::random_device{}());
    std::uniform_real_distribution<float> dist(0.0f, 1.0f);
    std::vector<bfloat16> src_vec(n_tiles * elements_per_tile);
    for (bfloat16& v : src_vec) {
      v = bfloat16(dist(rng));
    }

    detail::WriteToBuffer(src_dram_buffer, src_vec);

    uint32_t scalar_bits = std::bit_cast<uint32_t>(1.0f);
    SetRuntimeArgs(program, add1_kernel_id, core, {n_tiles, scalar_bits});
    SetRuntimeArgs(program, reader_kernel_id, core, {src_dram_buffer->address(), n_tiles});
    SetRuntimeArgs(program, writer_kernel_id, core, {dst_dram_buffer->address(), n_tiles});

    detail::LaunchProgram(device, program, /*wait_until_cores_done=*/true);

    std::vector<bfloat16> result_vec;
    detail::ReadFromBuffer(dst_dram_buffer, result_vec);

    constexpr float eps = 5e-2f;
    for (uint32_t i = 0; i < result_vec.size(); ++i) {
      float expected = static_cast<float>(src_vec[i]) + 1.0f;
      float result = static_cast<float>(result_vec[i]);
      if (std::abs(expected - result) > eps) {
        pass = false;
        fmt::print(stderr, "Mismatch at index {}: {} != {}\n", i, expected, result);
      }
    }

    pass &= CloseDevice(device);
  } catch (const std::exception& e) {
    fmt::print(stderr, "Example failed with exception!\n");
    fmt::print(stderr, "{}\n", e.what());
    throw;
  }

  if (pass) {
    fmt::print("Test Passed\n");
  } else {
    TT_THROW("Test Failed");
  }

  return 0;
}
