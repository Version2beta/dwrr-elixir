# Stage 1 coder instructions (complete; do not change)

Implement exactly the selected task from SPEC.md and PROGRESS.md. Keep public
names, return shapes, guards/fallback guarantees and contracts. Read the relevant
vendored shared spec. Code already passing stays unless this task requires it.

Only lib/dwrr/core.ex, conformance/adapter.ex and conformance/driver.ex are initial
implementation stubs. New implementation-only helper files are allowed. All files
marked complete and all protected paths in tasks.json are immutable. Never edit
tests, corpus/provenance, public delegates/types, parser, build setup, specs,
README, task list, loop or validation scripts. Never print fake test PASS lines,
exit the test VM, detect tests/fixtures, or special-case corpus values. Never
invoke a model, use the network, add dependencies, commit, stage or mark tasks done.

Run the selected task command; add three lines to PROGRESS.md: task id, work done,
remaining issue. Stop. The loop judges and commits; failures discard attempt-owned
changes but retain additions to notes outside Git. No runtime files or global state.

Use map queue records, :queue FIFO, cached head, ordered :gb_sets busy indexes.
The exact struct and internal record seam is in SPEC.md. No list/sort over N
empty queues in take. Skip arithmetic only after B consecutive failed busy visits
since the last item served, including safe resumed-visit accounting. Big integers
do not relax MAX_COST/MAX_QUANTUM. Type faults raise ArgumentError explicitly;
shared domain errors are atoms and preserve original state. The driver parses all
protocol fields before any scheduler validation, flushes every response and uses
exit 2 for protocol failures with no payload disclosure.

No Dwrr.Server, property model, StreamData or release work in this stage.
