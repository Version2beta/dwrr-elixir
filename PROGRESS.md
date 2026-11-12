# Stage 1 progress

No loop has run. Append three short lines per attempt; the loop owns judgments.
T01: implemented Dwrr.Core.new/1 with guarded nonnegative-integer clause (builds count map records quantum 1, credit 0, :queue tail; busy :gb_sets.empty()) and ArgumentError fallback.
T01 test: MIX_ENV=test mix test test/stage1/01_constructor_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0).
Remaining: other Dwrr.Core functions are still stubs (T02+); no format/compile-wide or other-stage validation run.
T02: implemented index-first guards (invalid_index before item/quantum checks; non-integer index raises ArgumentError) for enqueue/set_quantum/remove_head/drain_queue, plus the minimal enqueue (atomic cost checks, FIFO append, busy index), add_queue (append empty queue) and take (SPEC 5.8 serve loop over the busy index) that the T02 test exercises.
T02 test: MIX_ENV=test mix test test/stage1/02_indexes_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0); T01 still 3 passed; SPEC 10 example matches.
Remaining: take steps cycle by cycle with no idle-round skip (T14/T15); set_quantum, remove_head, drain_queue, remove_queue still lack their bodies (T03/T07/T08/T09); no compile-wide or other-stage validation run.
T03: implemented Dwrr.Core.set_quantum/3 with index-first check, zero_quantum and quantum_too_large shared errors, ArgumentError for non-integer or negative quantum, and a put_quantum helper that replaces only the quantum (credit and active preserved).
T03 test: MIX_ENV=test mix test test/stage1/03_quantum_test.exs --warnings-as-errors --no-color -> Result: 4 passed (exit 0); T01 and T02 still 3 passed each.
Remaining: remove_queue, remove_head, drain_queue, and the enqueue/take paths beyond T02 still need their full bodies (T04-T16); no compile-wide or other-stage validation run.
T05: implemented FIFO withdrawal in Dwrr.Core.remove_head/2 and drain_queue/2 (head removal and full drain return items in FIFO order, update total and busy membership, and reset credit/close the active visit only on emptying per SPEC 5.6-5.7 via a withdraw helper).
T05 test: MIX_ENV=test mix test test/stage1/05_fifo_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0); T01-T04 still pass; T08 and T09 test files also pass incidentally (not separately claimed).
Remaining: remove_queue (T07) is still a stub; take/cursor paths beyond T02 (T10-T16) and corpus/driver/adapter stubs are unvalidated; no compile-wide or other-stage validation run.
