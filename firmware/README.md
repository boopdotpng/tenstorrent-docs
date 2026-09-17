# Three meanings of firmware

Current blackhole-py builds small resident worker and service programs from
[C sources](../../blackhole-py/firmware/); see its
[runtime map](../build-and-dispatch/blackhole-py-runtime.md).

The upload/source architecture pages below describe TT-Metal worker firmware.
The fwbundle guide describes **board-management firmware** (ARC/SMC, DMC, boot
images). Building a worker kernel does not require building or flashing an
SMC/DMC bundle. The fwbundle guide retains its recorded environment and versions.

## Documents

- [Building firmware and creating custom fwbundles](firmware-build-system.md)
- [Firmware architecture (source-confirmed)](firmware-source-architecture.md)
- [Firmware Upload Sequence](firmware-upload-sequence.md)
