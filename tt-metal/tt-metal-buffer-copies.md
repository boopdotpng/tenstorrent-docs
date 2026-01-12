# TT-metal buffer copies (blocking, single device)

## Quick answer
- Use `tt::tt_metal::detail::WriteToBuffer` / `ReadFromBuffer` for blocking host-to-device and device-to-host copies.
- These functions do not return a device pointer; they just move bytes into or out of an existing `Buffer`.
- The `Buffer` owns the device allocation and its address. Kernels reference that address via runtime args or buffer handles.

## What maps to CUDA concepts
- `Buffer` ~= CUDA allocation + device pointer (lifetime owned by the buffer)
- `WriteToBuffer` / `ReadFromBuffer` ~= `cudaMemcpy` (blocking)
- Runtime args that point at `Buffer` addresses ~= kernel argument packing

## Minimal C API surface (conceptual)
- device create/destroy
- buffer create/destroy (DRAM or L1)
- buffer_write(handle, host_ptr, size) -> WriteToBuffer
- buffer_read(handle, host_ptr, size) -> ReadFromBuffer
- program build + set runtime args + enqueue + finish

## Relevant headers and signatures
- `tt_metal/api/tt-metalium/tt_metal.hpp`
  - `void tt::tt_metal::detail::WriteToBuffer(Buffer& buffer, tt::stl::Span<const uint8_t> host_buffer)`
  - `void tt::tt_metal::detail::ReadFromBuffer(Buffer& buffer, uint8_t* host_buffer)`
  - Template helpers: `WriteToBuffer(Buffer&, const std::vector<DType>&)` and `ReadFromBuffer(Buffer&, std::vector<DType>&)`
  - Raw address copies (optional):
    - `bool WriteToDeviceDRAMChannel(IDevice* device, int dram_channel, uint32_t address, std::span<const uint8_t> host_buffer)`
    - `bool ReadFromDeviceDRAMChannel(IDevice* device, int dram_channel, uint32_t address, std::span<uint8_t> host_buffer)`
    - `bool WriteToDeviceL1(IDevice* device, const CoreCoord& logical_core, uint32_t address, std::span<const uint8_t> host_buffer, CoreType core_type = CoreType::WORKER)`
    - `bool ReadFromDeviceL1(IDevice* device, const CoreCoord& logical_core, uint32_t address, std::span<uint8_t> host_buffer, CoreType core_type = CoreType::WORKER)`
- `tt_metal/api/tt-metalium/buffer.hpp`
  - `uint64_t Buffer::address() const` (device address base)
  - `uint32_t Buffer::page_size() const` / `size_t Buffer::size() const`

## Notes
- You do not need distributed APIs for single-device, blocking copies.
- Device addresses come from `Buffer` metadata (`Buffer::address()` and layout), not from copy calls.
