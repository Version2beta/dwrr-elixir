# Stage 1 kit verification

## Outcome and boundary

**Verified stub kit, not an implemented library.** Twenty-two tasks are ready for
an owner-run loop. The private reference is outside the kit. No coder process,
subagent, model call, dependency install, staging, commit, push or tag was run in
this preparation phase. The target remains on unborn `spec-loop/framing`; the
owner must review and commit the baseline before running the loop.

Environment: installed Elixir **1.20.4 / OTP 29**, Python 3, bash, jq and timeout.
Exact ExUnit summary expectations target that installed runner, with colors off.
Library contract minimum is Elixir >=1.18 / OTP >=27; that minimum was **not**
executed here. Stage 2 and its overlay on an actual loop-written build are **not
performed** and cannot yet be verified.

## Inputs and provenance

- Shared SPEC/PROTOCOL **0.1.1** (draft), pinned commit
  `8a0e3cf9ae860ba207213590c00feeb822bdd8f2`.
- All seven corpus files copied byte-for-byte: **1,839 cases, 44,728 steps**.
- `test/fixtures/dwrr-spec/PROVENANCE.json`: commit, version, individual case/step
  counts and SHA-256 hashes, copied document hashes and upstream tool hashes.
- Original generator/Go v0.10.1 declarations remain in corpus/README.md. No corpus
  regeneration or independent historical provenance claim was made.
- Source repositories remain untouched. External tools run unchanged from the
  pinned sibling checkout, not translated or mocked inside the kit.

## Required checks

| Check | Observed evidence |
|---|---|
| Reference: every task through unchanged loop judge | `bash scripts/loop.sh --check`: **22 pass, exit 0**; format_check, each task, all earlier tasks and compile check included |
| Reference full suite | **Result: 66 passed**, warnings-as-errors, no skips/exclusions |
| External corpus replay | **PASS: 1839 cases, 44728 steps, 7 files**, exit 0 |
| External protocol checker | **PASS: 36 of 36 checks passed**, exit 0; interactive flush, EOF and strict protocol |
| Stubs: every task fails | Same unchanged `--check`: **22 FAIL, exit 1**; separately established formatted/compilable stubs, not a formatting-only failure |
| Stubs: individual tests non-vacuous | Full suite **Result: 0/66 passed; Failed: 66 tests**, exit 2. No corpus or error test passes accidentally |
| Planted affordability `<` → `<=` | Four small-file native corpus tests: **0/4 passed**, exit 2; replay: **46/1,839 failing cases**, exit 1 |
| Restore mutation and validate | Exact comparison restored to `<`; clean whole-tree command again passes all tests and both tools |
| Hand fixture | new(1), enqueue(value=7,cost=2), take(1): three exact expected responses, exit 0 |
| Loop identity/protection | Installed loop copied unchanged; protected path inventory covers tests, fixtures, parser, public contracts, build files, docs and scripts |

Whole-tree command, from the reference repository root:

```sh
mix format --check-formatted &&
MIX_ENV=test mix compile --warnings-as-errors &&
MIX_ENV=test mix test --warnings-as-errors --no-color &&
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs' &&
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

After mutation restoration this command took **11.632 seconds**, including both
external tools. The complete triangular `loop.sh --check` run took **113.928
seconds** (it deliberately reruns earlier tasks). Each individual command fits
comfortably inside **JUDGE_TIMEOUT=300**; no increase is needed on this machine.
These are observed reference timings, not future loop-performance guarantees.

## Exact expectations and fixtures

Tasks T01–T21 run one ExUnit file each. T21 also runs external replay. T22 runs
the full tree and both tools; its required full stdout lines are:

```text
Result: 66 passed
PASS: 1839 cases, 44728 steps, 7 files
PASS: 36 of 36 checks passed
```

All expectations were exercised with the installed runner by the actual loop's
`--check`, never a reimplemented judge. No pass_marker or kit model-command
settings. Tests include explicit positive paths before error assertions and
validate counts/hashes, so an empty corpus glob or skipped tests cannot pass.
Native replay calls Dwrr directly with an independent test-only result adapter;
it does not call the production conformance adapter or Python model.

Reduction-count tests bound sparse-N traversal and the cost of productive grants.
They do not independently prove every internal skip trigger: source review still
must confirm B consecutive failed busy visits, reset on service, no early scan,
exact arithmetic and cyclic cursor preservation. The reference was checked against
that argument; the eventual loop implementation must be reviewed again.

## Skill and preparation issues

Loaded `spec-loop` version **1.1** from
`/Users/rob/.pi/agent/skills/spec-loop/SKILL.md`; re-read kit-format and loop in full.
SHA-256 identities:

| File | SHA-256 |
|---|---|
| SKILL.md | `d7ac606372122ee1125cb8cea0ae43635958d349d8298aebb4e460f1d7b28335` |
| references/kit-format.md | `972367a9a45222b3070518ea3f632a2c974c2869aa0d39ba775dcf061a7de199` |
| scripts/loop.sh | `4ed33daa824bd8ed999c141cf4abd55921981f5e8de86948408552b52dbb207f` |

The first reference --check failed every task at format_check. Simplifying a
multiline System.cmd call in the test helper resolved the installed formatter's
write/check disagreement; final format and judge checks pass. Earlier scratch
test compilation errors and an improper-list exception in the private reference
were repaired before acceptance. The real stub proof is the later **66 failing
executed tests**, not the initial formatting failure.

The library adaptations remain: no runtime model pipeline, configuration,
credentials, doctor or home-directory reports. Only the test/dev driver does
stdio; tests use cleaned-up temporary subprocess input files. No custom ExUnit
formatter was needed. Generic skill text's README example of assigning model
commands conflicts with its newer owner-only rule: this kit documents defaults
without assigning them. Suggested text fix: have README show plain loop invocation
and describe overrides as owner actions only.

## Retained evidence and remaining work

Detailed stdout/stderr, command/exit/timing JSON, hand fixture and hash inventories
are under ignored **`.loop/verification/`**. Keep these locally; do not commit
transient logs or private reference source. They are not accessible through Git
history, because preparation made no commits.

Unverified: actual coder/model/provider access and effort, spending, real loop
commit/discard behavior on this kit, loop-written implementation quality, toolchain
minimum, stage-2 properties/Server/docs/CI, overlay compatibility and publication.
No claim of general correctness beyond the exercised tests/corpus/protocol.

After the owner runs stage 1, retain `.loop/loop.log`, coder logs, notes and any
STOP file. Review the baseline-to-result diff and all protected hashes, inspect
for fixture special cases and judge bypasses, rerun acceptance, and ask for real
use misfires before constructing stage 2. Exact start commands are in README.md.
