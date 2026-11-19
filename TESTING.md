# TESTING

This guide describes what the test suites cover, how to reproduce a property
failure, and which checks were actually run.

## Inventory

- **66 historical tests** in `test/stage1/` (21 files). They cover the core
  operations, the adapter, the JSONL driver and the integration path.
- **Conformance corpus:** 1,839 cases and 44,728 steps across seven files, run
  natively by `test/stage1/17_small_corpus_test.exs` and
  `test/stage1/18_random_corpus_test.exs`, and again through the external replay
  tool below.
- **36 protocol checks** from the external `check_driver.py` tool. It checks
  flushing, exit status 0 at end of input, and exit status 2 for each protocol
  error.
- **Eight properties** in `test/stage2/properties_test.exs`.
- **Three naive anchor tests** in `test/stage2/naive_reference_test.exs`. They
  check the literal naive reference model, which is independent of the production
  code.

Property testing uses StreamData 1.3.0, pinned in `mix.lock`. It is declared as
`{:stream_data, "~> 1.3.0", only: :test, runtime: false}`, so it is a test-only
dependency and is not part of the runtime.

## Reproduce a property run

```sh
MIX_ENV=test mix test test/stage2/properties_test.exs --seed 4242 --warnings-as-errors --no-color
```

The expected result is `Result: 8 passed`. ExUnit prints the seed it used
(`Running ExUnit with seed: ...`), so a fixed `--seed` makes the run repeatable.

## Bounded domains

The properties are bounded on purpose, so that the naive oracle can finish.

- Queue indices are drawn from `-1..4`. Batches hold at most three items.
  Takes request `-1..8` items. Costs are mostly `0..8`, plus the limit-plus-one
  value. Quanta are mostly `0..5`, plus the limit-plus-one value.
- The naive reference is a literal list model with a 20,000-step work cap per
  take. When the cap is exceeded it raises `work budget exceeded`. It does not
  skip numerically, so a too-large domain shows up as an oracle failure rather
  than a silent pass. Shrink the domain, not the semantics.
- **Near-limit large quanta:** quanta are drawn from half the limit up to the
  limit, and queues are not added or removed in that property (no resizing).
- **Huge cost with quantum 1 (analytic):** the property checks cyclic tie order
  for costs near the limit and asserts that the take uses fewer than 20,000
  reductions.
- **Conservation, FIFO, errors, state, branches and split takes:** each is
  checked by at least one property. Split takes check that `take a` followed by
  `take b` gives the same items and final state as `take (a + b)`.
- **Stable backlog fairness** is checked only for a bounded case: two queues with
  unit costs, small quanta, and a backlog that stays non-empty across one
  reweight. It is not a general promise for changing backlogs.

## Failures and diagnostics

When a comparison fails, the assertion message includes:

- `step=N`, the index of the failing operation;
- `op=...`, the operation that failed;
- `shrunk_trace=...`, the full operation list after StreamData shrinking.

The `shrunk_trace` comes from generated test data only. Never reuse this
diagnostic helper with real caller data.

To reproduce a failure, rerun the reproduction command with the seed that ExUnit
printed. Keep `mix.lock` and the StreamData 1.3.0 version unchanged, because
generated values depend on them. If you need to replay the exact failing case,
copy the `shrunk_trace` from the failure message into a focused test.

## Full local gate

Run from the repository root. Each command is part of the same gate.

```sh
MIX_ENV=test mix deps.get --check-locked
mix format --check-formatted
MIX_ENV=test mix compile --warnings-as-errors
MIX_ENV=test mix test --warnings-as-errors --no-color
```

## External conformance commands

These need a sibling `dwrr-spec` checkout at the pinned commit
`8a0e3cf9ae860ba207213590c00feeb822bdd8f2`. Neither tool modifies upstream files.

```sh
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

Expected output lines:

```text
PASS: 1839 cases, 44728 steps, 7 files
PASS: 36 of 36 checks passed
```

## Verification status

The local runs used Elixir 1.20.4 on OTP 29. The minimum pairing (Elixir 1.18.4
on OTP 27.3) and the other CI pairing (Elixir 1.20.4 on OTP 29.1.2) are configured
in `.github/workflows/ci.yml`, but they have not been executed in this
documentation. Do not treat the configuration as a passing run. See
`docs/STAGE2-VERIFICATION.md` for what was run and what was recorded.

This guide records no publication. Nothing here publishes a package, creates a
tag, or pushes to a remote.

## Mutation check (disposable copy only)

This procedure checks that the corpus tests catch a real bug. Do it only in a
disposable copy, never in the working tree or the upstream checkout.

1. Copy the repository to a sibling directory, for example
   `../dwrr-elixir-mutation`, so that `../dwrr-spec` still resolves.
2. In the copy only, change the affordability comparison in `lib/dwrr/core.ex`
   from `rec.credit < rec.head.cost` to `rec.credit <= rec.head.cost`.
3. Run the native corpus tests (`test/stage1/17_small_corpus_test.exs` and
   `test/stage1/18_random_corpus_test.exs`). They must fail.
4. Run the external replay command. It must report failing cases.
5. Restore the exact original bytes in the copy, rerun the full local gate and
   both external commands, then delete the copy.

Never edit the upstream corpus, the expected responses, or the real core to make
a check pass.
