# Instruction usage in historical TT-Metal workloads

These reports count instructions found in particular compiled workloads.
**Absence from a disassembly sample is not evidence that an instruction is
unsupported, unnecessary, or safe to delete.** Static occurrences also do not
count dynamic executions inside loops or replay.

- [747-ELF frequency report](instruction-frequency-report.md): April 14, 2026
  corpus, including inline instructions and recognized stores to the FIFO.
- [Earlier instruction survey](blackhole-instruction-set-analysis.md): separate
  workload sample and its historical classifications.

For functional behavior, use [the test evidence map](../hardware/behavior-from-tests.md)
and the Blackhole ISA manual. Current raw-emitter tests exercise operations
such as scalar arithmetic and source/Dst moves outside the old LLK sample.
The reports' old deletion recommendations have been withdrawn; the counts are
retained as historical observations.
