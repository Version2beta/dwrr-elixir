# Stage 1 progress

No loop has run. Append three short lines per attempt; the loop owns judgments.
T01: implemented Dwrr.Core.new/1 with guarded nonnegative-integer clause (builds count map records quantum 1, credit 0, :queue tail; busy :gb_sets.empty()) and ArgumentError fallback.
T01 test: MIX_ENV=test mix test test/stage1/01_constructor_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0).
Remaining: other Dwrr.Core functions are still stubs (T02+); no format/compile-wide or other-stage validation run.
T02: implemented index-first guards (invalid_index before item/quantum checks; non-integer index raises ArgumentError) for enqueue/set_quantum/remove_head/drain_queue, plus the minimal enqueue (atomic cost checks, FIFO append, busy index), add_queue (append empty queue) and take (SPEC 5.8 serve loop over the busy index) that the T02 test exercises.
T02 test: MIX_ENV=test mix test test/stage1/02_indexes_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0); T01 still 3 passed; SPEC 10 example matches.
Remaining: take steps cycle by cycle with no idle-round skip (T14/T15); set_quantum, remove_head, drain_queue, remove_queue still lack their bodies (T03/T07/T08/T09); no compile-wide or other-stage validation run.
