# Stage-2 coder instructions (complete; do not change)

Implement only the selected task from SPEC Part 2 and PROGRESS.md. All stage-1
behavior and provenance remain frozen, except the owner-authorized helper-only
assert_receive_timeout overlay recorded in test/fixtures/stage2-helper-overlay-sha256.json. Keep already passing code unchanged.

Writable targets: lib/dwrr/server.ex; lib/dwrr.ex @doc/@moduledoc/@spec ONLY (its
remaining AST is frozen); README.md; TESTING.md; CHANGELOG.md; RELEASING.md;
mix.exs metadata (preserve paths/approved dependency);
PROGRESS.md attempt notes. Never edit core, conformance, structs, tests/support,
fixtures, docs/, scripts, lock, formatter, ignore, license, spec/tasks/prompt/loop
or other complete/protected files, including complete .github/workflows/ci.yml. New helpers only if the selected target needs
one. Tests and the naive reference are finished preparation assets, not tasks.

No fixture special cases, output-marker tricks, VM exits, test detection or
expected-answer literals in examples. No model/network calls, new dependencies,
publication, credentials, staging, commits, tags, remote actions or skill edits.
Server is minimal: exact core replies including state, correct shape extraction,
caller-owned supervision, fresh restart, default calls/timeouts, no catches/retries
or execution/backpressure. Pure docs/types must not alter implementation.

Run the selected task command, append three lines to PROGRESS.md (task id, work,
remaining issue) and stop. The owner-authorized loop judges and commits or discards
attempt-owned edits; you do not mark tasks done or commit yourself.
