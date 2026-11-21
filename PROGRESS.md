# Stage 2 preparation / historical stage-1 progress

Stage 1 owner loop completed at 7205252 in eight first-pass iterations. Historical
notes below are preserved verbatim; their task-local "remaining" statements are
not current status. Stage-2 preparation now adds protected assurance assets and seven
new failing stub tasks T22–T27 and T29. T28 was removed: CI is complete/protected. No stage-2 coder/model loop has run. See
docs/STAGE2-VERIFICATION.md for actual preparation checks. Append three short
lines per future attempt; the loop owns judgments.
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
T07: implemented Dwrr.Core.remove_queue/1 per SPEC 5.5: no-op at count 0; otherwise cancels the active visit only when it sits on the last queue, deletes that queue with its items (total reduced by its size, busy membership removed), sets count to last, and repairs cursor (0 when last is 0, else cursor mod last when cursor >= last).
T07 test: MIX_ENV=test mix test test/stage1/07_remove_queue_test.exs --warnings-as-errors --no-color -> Result: 4 passed (exit 0); regression run of T01-T06, T08, T09 files -> 24 passed (exit 0).
Remaining: take still lacks the idle-cycle skip arithmetic (T14/T15); T10-T13, T16 and the adapter/driver stubs (T19/T20) were not separately validated here; no compile-wide or other-stage validation run.
T15: huge skips and exact numeric boundaries.
Work done: added exact idle-cycle arithmetic after B consecutive failed busy visits, counting blocked resumes once and resetting after service; MIX_ENV=test mix test test/stage1/15_boundaries_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0).
Remaining: no issue observed in the selected tests; other tasks and full-suite validation were not run in this attempt.
T19: implemented Dwrr.Conformance.Adapter.apply/2 for every parsed request shape: nil state requires {:new, n} (ArgumentError otherwise), core results map to PROTOCOL.md wire maps (Scheduled/Item to queue/value/cost with cost as a decimal string, nil and lists preserved), and scheduler errors return {original_state, %{"error" => code}}.
T19 test: MIX_ENV=test mix test test/stage1/19_adapter_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0); mix format --check-formatted conformance/adapter.ex passes.
Remaining: Driver.run/0 is still the T20 stub (returns :ok without reading stdin); the other stage-1 tests and the full suite were not run in this attempt.
T20: JSONL driver and strict protocol.
Work done: implemented fully parsed request dispatch with threaded state, synchronous JSONL writes, EOF return, and category-only stderr plus exit 2 for protocol errors; MIX_ENV=test mix test test/stage1/20_driver_test.exs --warnings-as-errors --no-color -> Result: 4 passed (exit 0).
Remaining: no issue observed in selected tests; full-suite and external conformance validation were not run in this attempt.
T22: minimal caller-owned Dwrr.Server.
Work: implemented GenServer initialization, serialized core operations with exact replies/state extraction, standard supervision and default calls; selected test command -> Result: 7 passed (exit 0); server formatted and git diff --check passed.
Remaining: no issue observed in selected tests; full-suite validation was not run in this attempt.
T23: public docs, operation typespecs and executable examples.
Work: Dwrr moduledoc (immutability, six tagged errors, ArgumentError domain, 2^63-1 and 2^64-3 limits, declared-cost fairness, FIFO/no overtaking) with three ordered elixir examples; @spec for the eight Dwrr operations and Server functions from the protected signature fixtures; Server moduledoc on caller ownership, timeouts and restart; stage-1 AST unchanged. MIX_ENV=test mix test test/stage2/02_public_docs_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0); T22 test/stage2/01_server_test.exs -> 7 passed; mix format --check-formatted on lib/dwrr.ex and lib/dwrr/server.ex passes.
Remaining: no issue observed in the selected test; README, CI, property and full-suite validation were not run in this attempt.
T24: README: usable examples, contracts and owner instructions.
Work: rewrote README.md with the required sections, four elixir examples whose result values come from actual Dwrr/Dwrr.Server calls (byte sharing, owned worker, withdrawal, atomic error), behavior/contract notes, verification and comparison text, the owner section copied byte-for-byte from test/fixtures/stage2-owner-instructions.md, and a colophon; MIX_ENV=test mix test test/stage2/03_readme_test.exs --warnings-as-errors --no-color -> Result: 2 passed (exit 0); test/stage2/02_public_docs_test.exs and 06_metadata_test.exs were run as a regression check and are unaffected by README text.
Remaining: README wording beyond the protected checks (Go comparison, fairness and Server claims) was checked by reading against SPEC and lib sources, not by a separate review; the full suite, format/compile gate and pinned conformance replay were not run in this attempt; 06_metadata_test.exs still fails 2 tests in mix.exs metadata (T27, out of scope).
T25: TESTING.md rewritten with the real inventory (66 stage-1 tests, 1,839 cases/44,728 steps, 36 protocol checks, eight properties, three naive anchors), bounded domains, step/op/shrunk_trace diagnostics, the sh-fenced --seed 4242 replay, full local gate, both pinned external commands and a disposable-copy <= mutation procedure; no publication recorded.
T25 test: MIX_ENV=test mix test test/stage2/04_testing_docs_test.exs --warnings-as-errors --no-color -> Result: 2 passed (exit 0), including the nested documented replay (Result: 8 passed).
Remaining: the external replay/check_driver, full gate and mutation procedure are documented but were not rerun in this attempt; the minimum Elixir 1.18/OTP 27 and CI pairings were not executed.
T26: CHANGELOG.md now has exactly one "## 0.1.0 (unreleased)" heading (initial Elixir release, Server, immutable scheduler, shared draft 0.1.1, not yet published, no invented date); RELEASING.md is an owner-only ordered procedure (clean tree and protected assets, min/current runtimes, format/compile/test and both pinned tools, then mix hex.build with archive inspection, then separately authorized mix hex.publish, then separately authorized git tag -a v0.1.0 and push).
T26 test: MIX_ENV=test mix test test/stage2/05_release_docs_test.exs --warnings-as-errors --no-color -> Result: 2 passed (exit 0).
Remaining: the RELEASING gate and pinned tools were documented, not run here; mix hex.build would not yet produce the required manifest because mix.exs has no package config (T27, out of scope); no publication, tag or push was performed.
T27: Mix metadata and exact package manifest.
Work: added description (97 chars), source_url, package name dwrr, licenses ["MIT"], links %{"GitHub" => canonical repo}, and the exact files list (lib/**/*.ex, mix.exs, README.md, TESTING.md, CHANGELOG.md, RELEASING.md, LICENSE) to mix.exs, leaving app, version, elixir, deps, elixirc_paths and application unchanged; MIX_ENV=test mix test test/stage2/06_metadata_test.exs --warnings-as-errors --no-color -> Result: 3 passed (exit 0); mix format --check-formatted mix.exs passes.
Remaining: mix hex.build and the archive inspection, the whole-tree gate and pinned conformance tools were not run in this attempt; the manifest is verified only through the test's Path.wildcard expansion, not an actual built archive.

Owner-authorized domain-validation fix at base 4ef9d16360b1ac936b33ddf23c6f1ac5e091e220: validate enqueue's entire argument domain and set_quantum's domain before any shared errors; preserve domain-valid ordering and atomicity. Added six regressions, public/SPEC clarification and an exact core overlay gate with original hash provenance (historical manifest unchanged).
Validation: focused six tests passed; mix format --check-formatted and MIX_ENV=test mix compile --warnings-as-errors passed; full --seed 4242 --warnings-as-errors --no-color run passed 107 checks (8 properties, 99 tests). Clean sibling 243dd125470365df2c52a6ce72de3ee8ecfce3fe replay passed 1839 cases/44728 steps and checker passed 41/41.
Parent validation: inspected the diff and reran formatting, compilation with warnings as errors, all 107 checks with seed 4242, and git diff --check successfully. Independent read-only review found no issues.
Remaining: minimum-runtime/hosted CI and historical pinned external tools were not run; no dependency fetch, staging, commit, push or release work performed.
