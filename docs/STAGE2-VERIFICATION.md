# Stage-2 kit verification

## Current authorized bounded precommit revision

This section supersedes the **historical initial eight-task preparation record**
below for current paths, task counts, CI protection and helper governance.
The delivered Server/docs/metadata are still STUBS. CI is now a complete protected
ordinary YAML assurance asset, identical to the private reference; it is not a
coding task. Seven new tasks remain: **T22–T27 and T29**, deliberately no T28;
28 total tasks. T01–T21 commands/tiers/counts are unchanged. One CI SHA256 test
replaces two structural JSON tests, making the full suite **97 checks (8
properties, 89 tests)**. This is counted by the final executions, not by task titles.

### Durable relocation and provenance

Before any edits to the relocated reference, complete recursive byte inventories
were captured and compared after moving the whole owned trees (no overwrite):

- `/private/var/folders/vw/fh_b6s2s4l154vl9dl21lx480000gn/T/dwrr-stage2-reference-zlzdi55o`
  → `/Users/rob/Development/dwrr-elixir-private/reference/`: **243 files,
  9,387,251 bytes**, every SHA256 identical. The reference checkout is
  `/Users/rob/Development/dwrr-elixir-private/reference/dwrr-elixir`, with its
  required sibling `dwrr-spec` preserved in the same parent tree.
- `/private/tmp/dwrr-stage2-isolation-audit-77zIgw`
  → `/Users/rob/Development/dwrr-elixir-private/isolation-audit/`: **272 files,
  9,895,083 bytes**, every SHA256 identical, including the **23 quarantined
  artifacts / 616,790 bytes** and original map/report/evidence. Original artifacts
  were not rewritten to replace historical locators; older scripts can still
  reference removed temporary paths and must not be blindly rerun.

All new scripts, inventories, logs and source-bearing evidence are external:
`/Users/rob/Development/dwrr-elixir-private/evidence/`. Exact relocation maps and
per-file hashes: `reference-{pre,post}-relocation.json`,
`isolation-audit-{pre,post}-relocation.json` and each `*-relocation-result.json`.
Later authorized edits have separate initial/final source inventories and deltas.
Outside-tree isolation is **not an OS sandbox** against same-user file access.
These external paths are intentionally documented at the owner's explicit request.
No private reference source, generators or leaked snapshots belong in the real
repository, including ignored builds, logs or archives. The protected naive
oracle is intentionally delivered test support, not the private implementation.

### Timeout race and frozen-helper governance

The inert fake accepts one `$gen_call`, then self-sends its `{:seen, request}`
marker. After the default 5000ms call timeout, the caller sends a fresh-reference
barrier and waits for the matching acknowledgement **before** inspecting the
fake mailbox. The fake executes its self-send before receiving/acknowledging that
barrier. Per-sender signal ordering places this caller's preceding call/retry
messages before its barrier; selective receive takes only the barrier, leaving
the marker and any queued retries untouched. The ack is sent to the caller, not
the fake. Thus the final mailbox must be exactly one `{:seen, request}`: no extra
handshake message is counted, and queued retries still fail. No arbitrary sleep
or retry-after-failure. Elapsed time retains only **>=4900ms**, no upper bound;
the 15s module timeout still catches hangs.

`test/test_helper.exs` now sets `assert_receive_timeout: 1_000`. This is the sole
owner-authorized stage-1 helper change, not an unchanged-file claim:
**41 original frozen files untouched + 1 authorized helper overlay**. The
unchanged manifest excludes that helper. The separate protected
`test/fixtures/stage2-helper-overlay-sha256.json` preserves original SHA256
`3a799aed7ff92bb3d65f4e39b41270cfc5f9a2c569d026ab810460ad98ac8c28`
and checks new SHA256
`a343d30019609abef5a18d0a792319c1e43d6601165a847b76e5b3e63c674379`.
The original historical 66 tests/helper still execute; original provenance was
not silently rewritten. Public executable AST/core/driver remain unchanged.

### Complete protected CI and authoritative build catalog evidence

`tasks.json` anchors `^\.github/workflows/ci\.yml$` under protected paths.
`test/stage2/07_ci_test.exs` is one independent byte-identity check against readable
`test/fixtures/stage2-ci-sha256.json`, not T28. Workflow SHA256:
`e9db7e9196fd83ce6a8484c68a7d68ec632e5d10312efb693198592464f82a3a`.
It has push/pull_request triggers, one ubuntu-latest job, 15-minute timeout,
MIX_ENV=test and sibling working directory, the exact two-entry matrix
**1.18.4/27.3 + 1.20.4/29.1.2**, dependency-lock setup, format, warnings-as-errors
compile, full tests, replay.py and check_driver.py, pinned sibling spec checkout
`8a0e3cf9ae860ba207213590c00feeb822bdd8f2`. No parser dependency or bypass.

Read-only authoritative network retrieval returned **HTTP 200** for each:

- https://raw.githubusercontent.com/erlef/setup-beam/v1/src/setup-beam.js
  — source selects Linux OTP listing by architecture/ImageOS and Elixir build by
  runtime OTP major; it finds a matching major before considering fallback.
- https://builds.hex.pm/builds/elixir/builds.txt
  — exact `v1.18.4-otp-27` and `v1.20.4-otp-29` entries exist.
- https://builds.hex.pm/builds/otp/amd64/ubuntu-24.04/builds.txt
  — exact `OTP-27.3` and `OTP-29.1.2` entries exist.
- https://builds.hex.pm/builds/otp/amd64/ubuntu-26.04/builds.txt
  — the same exact OTP entries exist, also covering the newer ubuntu-latest image.

Full response bodies, exact matching lines (upstream commit/timestamp/build
SHA256), HTTP statuses and response SHA256 are in external
`setup-beam-listings.json` and companion `*-builds.txt`/`setup-beam-v1-source.txt`.
Both pairs are catalog-supported for runtime OTP27/29 respectively, not inferred
from Homebrew. These are listing checks, **not installation/runtime validation**.
Installed Elixir1.20.4/OTP29 executes locally; minimum runtime and hosted CI remain
**unexecuted**. Mutable action tags/ubuntu-latest/catalogs may change later.

### Dependencies and revalidation evidence

Both actual and private Mix declarations are exactly:
`{:stream_data, "~> 1.3.0", only: :test, runtime: false}`.
`mix.lock` has only StreamData **1.3.0**, Hex dependency list `[]`; resolved Mix
children are also `[]`. No transitive or runtime dependency, no additions.
StreamData's own development tools are not transitive project dependencies: it
is loaded in dependency environment `:prod`. Exact declarations/resolved options
are in external `actual-dependencies.txt` and `reference-dependencies.txt`.
Lock SHA256 remains
`6c53fd0150dc8ac45b454c996fc36904c1c55f34bb0152b486f8defeafd940d7`.

Final bounded verification uses the actual unchanged loop, JUDGE_TIMEOUT=300,
outer 900s per check, immediate durable result JSON/stdout/stderr. The exact
server repetition command is
`MIX_ENV=test mix test --repeat-until-failure 50 test/stage2/01_server_test.exs`:
51 suites (initial + 50 repeats), not 50 total. Final execution results are in the
postjudge completion note and external `*-result.json`. Final snapshots include
protected test/CI/task equality, core identity, original frozen manifest plus
helper overlay, index/status and repository-wide isolation scans. Known mutation
proof below is historical and unchanged; it was not redundantly rerun.
No coder-model loop, staging/commit/push, remote mutation or installed-skill edits.
Independent reviewer acceptance remains required.

---

# Historical initial eight-task stage-2 preparation record

The record below retains original run counts, paths and claims as history, not
current instructions. Current seven-task kit, helper exception, complete CI,
durable external locators and new exact final-snapshot evidence are above.

## Precommit isolation correction

The precommit audit FAILED the earlier repository-isolation claim: although the
private reference checkout was external, ignored preparation evidence still held
a complete solution generator (`reference.py`) and a private README source
snapshot (`final-audit-readme-correction-before.json`). Gitignore is not isolation.
These two files, two private package-metadata snapshots, and nineteen
preparation-owned artifacts exposing the private reference location were moved
intact to an owned external audit quarantine, with
SHA256 hashes and an original-path map retained externally. Historical evidence
paths below describe the original runs; quarantined artifacts are no longer at
those repository paths. No unrelated owner files, tests, stubs or builds were
removed or changed by this remediation.

The isolation audit includes ignored files, stdout/stderr and JSON snapshots,
BEAM debug/docs chunks, build manifests, Git blobs and archive/cache candidates,
not just Git status. The protected naive test oracle and ordinary expected data
are intentional kit assets, not private stage-2 implementations. No repository
symlinks or hardlinks were found. Externalization is not an OS sandbox against a
same-user process deliberately accessing files elsewhere. Private source and
quarantine locations are intentionally not recorded in this delivered document.

## Final review closure

The supervising session reviewed the oracle, properties, task boundaries and
protected-file controls. Independent review confirmed the private Server's
operation-specific state extraction, default calls and error behavior. It found
one README acceptance gap: six shared error names and last-queue index reuse
were required by the spec but absent from the reference and unchecked by tests.
The existing README test now asserts both; it rejects the old reference, accepts
the corrected reference, and still rejects the delivered stub. Counts stay fixed.

On the corrected snapshot, unchanged `bash scripts/loop.sh --check` completed
with **exit 0, 29/29 tasks passing, 251.878921 seconds**. Final T29 includes
**98 passed (8 properties, 90 tests)** and both external PASS lines. The judge
changed no source or Git status/index. This fresh recorded exit closes the earlier
session-timeout evidence gap; it does not invent an exit for the interrupted run.
Evidence: `.loop/verification-stage2/final-audit-verification-report.md` and
`final-audit-corrected-20261112T142902-{result,summary,initial,final}.json` there.
The supervising session inspected the corrected test and recorded result and
confirmed `git diff --check`, no staged changes, and unchanged core/driver/tests.

This completion addendum was added after validation; no task implementation or
test changed afterward. Minimum runtime and hosted CI remain unexecuted. The
private package archive predates the README prose correction and is not a
final-source package artifact. The delivered tree remains a verified STUB KIT,
not the completed stage-2 library. No commit or coder loop has been performed.

## Outcome, authority and preserved state

Prepared eight NEW cohesive stub tasks T22–T29 over the owner's actual completed
stage-1 tree `7205252eb23a27a817fbc8795776ef58013de090` (original kit
`e3d229e547663d93498aaf7466962e75b986919b`). Local branch:
`spec-loop/stage2-preparation`; HEAD unchanged; no staged files or commits.
Core, driver, parser, structs, historical tests/support and all shared provenance
remain byte-identical. Public lib/dwrr.ex is now docs/spec-editable, with its
remaining AST frozen by protected test fixtures. Previously protected docs/specs,
tasks/README/Mix contracts legitimately change; the old 52 protected hash claim
applies to the ORIGINAL stage-1 loop, not this overlay.

The user authorized sole-writer delegated kit preparation, local verification,
test-only StreamData download and shakedown updates. No stage-2 coder/model loop,
model-command override, subdelegation, staging, commit, push/tag, remote mutation,
publishing, Docker/toolchain download or installed-skill change was performed.
The private implementation is outside the delivered kit in an owned temporary
reference directory (location retained locally). Delivered Server/docs/metadata/CI
remain stubs, not an accidentally completed stage-2 implementation.

## Exact task gates

T01–T21 retain their original commands, stdout counts and tiers unchanged. The
old T22 whole-tree gate is removed from the middle; new T29 is the only final
gate. Eight-task exception was explicitly owner-approved. Properties and oracle
are complete protected assurance assets, NOT coding tasks.

| New task | Delivered stub result | Private reference result |
|---|---|---|
| T22 Server | FAIL: 0/7 passed, seven actual behavior failures; exit3 (also inferred unreachable-pattern warnings from stubs) | 7 passed |
| T23 public docs/types | FAIL: 1/3 passed; absent specs/docs/examples, exit2 | 3 passed |
| T24 README/examples | FAIL: 0/2 passed; absent executable histories/release structure, exit2 | 2 passed |
| T25 TESTING | FAIL: 0/2 passed; absent executable reproduction/domain guide, exit2 | 2 passed |
| T26 CHANGELOG/RELEASING | FAIL: 0/2 passed; absent initial release/ordered owner procedure, exit2 | 2 passed |
| T27 metadata/package | FAIL: 1/3 passed; missing identity metadata/manifest, exit2 | 3 passed |
| T28 CI | FAIL: 0/2 passed; empty workflow, no matrix/pin/required steps, exit2 | 2 passed |
| T29 final whole tree | FAIL: 79/98 passed, 19 actual failures, exit3 | 98 passed (8 properties, 90 tests), replay1839/44728/7 and protocol36/36 |

Actual delivered overlay, unchanged `bash scripts/loop.sh --check`: T01–T21
**pass**, every T22–T29 **FAIL**, aggregate exit1, 101.145s. It uses the loop's
format_check, exact stdout matching, predecessor tests and compile check, not a
reimplemented judge. Formatting and warnings-as-errors compile pass independently;
the missing behavior is substantive, not merely formatting/compiler diagnostics.
Full stub suite genuinely executes98: `Result: 79/98 passed (8/8 properties,
71/90 tests)`,19 failures. The expected newer compiler warnings do not stand in
for those actual assertions. There are exactly **eleven** preparation assurance checks: eight properties and three oracle anchor tests;
they pass on both actual stage1 and reference, and are not tasks.

A completed earlier private unchanged-loop `--check` recorded exit0/all29
(253.607s). After strengthening exact public/Server typespec assertions, the latest
`reference-check-final.stdout` contains all29 passing verdicts, including every
predecessor and final external gates, with empty stderr. **Its outer session timed
out before the wrapper wrote an exit/timing row; that invocation's exit status is
UNKNOWN, not reported as a captured exit0.** Recovery found no remaining matching
processes. The latest separate `reference-final-full` has recorded exit0/98 checks
and both external tools (18.329s). No unchanged full judge was rerun for recovery. Exact final output has no skipped/excluded
suffix. Private source/kit differences are limited to the eight implementation
areas named in SPEC Part2; tests, fixtures, task list, loop and judge expectations
are identical. Parent independent source/test review remains required.

## Fresh build and independent runtime probes

Installed versions: **Elixir1.20.4 / OTP29**, Python3.15.0, Hex2.7.0.
Only that runtime was available cheaply (Homebrew Elixir directory1.20.4;
no mise/asdf found). Minimum Elixir1.18/OTP27 was **not executed**. CI targets
1.18.4/27.3 and1.20.4/29.1 are structurally checked, not run on hosted CI.
Do not confuse a checked workflow with either minimum compatibility or CI success.

Approved dependency: `{:stream_data, "~> 1.3.0", only: :test, runtime: false}`,
resolved/locked **1.3.0**, no transitive/runtime deps. Normal authorized Hex
download also installed the Hex2.7.0 archive. Lock SHA256:
`6c53fd0150dc8ac45b454c996fc36904c1c55f34bb0152b486f8defeafd940d7`.
`MIX_ENV=test mix deps.get --check-locked` exits0. No documentation dependency added.

- Actual overlay fresh isolated build (`MIX_BUILD_PATH` under ignored evidence):
  warnings-as-errors compile plus historical suite: **66 passed**, exit0,2.295s.
  Existing user's `_build` was not deleted.
- Private fresh `_build` from absence: full final command passes98 checks, both
  pinned external tools; recorded run18.676s. Later final reruns and source hashes
  are retained in commands.jsonl.
- Hand-run actual driver: new1/enqueue(value7,cost2)/take1 yields exactly three
  expected responses, exit0,0.252s. `hand-comparison.json` independently compares
  parsed values. Protocol checker additionally verifies interactive flushing.
- Disposable copy of the ACTUAL unchanged core, with only
  `rec.credit < rec.head.cost` changed to `<=`: native small+random corpus
  **1/7 passed,6 failures**, exit2; all four small tests fail. External replay
  **46/1839 failing cases**, exit1. Restore exact original bytes, then full final
  gate **98 passed + both tools**, exit0,18.407s. Owned mutation directory deleted;
  see `mutation-cleanup.json`. Real working core and upstream were never mutated.
- Actual local production `mix hex.build` of private reference: exactly11 approved
  source/release files, no tests/corpus/driver/kit/private files, empty runtime
  requirements. Archive metadata/manifest/SHA are retained. This archive was built
  before the last public/Server typespec refinement; it proves package composition,
  not a final-source release artifact. No publication request.

Full final command (exact tasks.json command):

```sh
mix format --check-formatted &&
MIX_ENV=test mix compile --warnings-as-errors &&
MIX_ENV=test mix test --warnings-as-errors --no-color &&
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs' &&
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

External tools/corpus are unchanged at pinned dwrr-spec0.1.1 commit
`8a0e3cf9ae860ba207213590c00feeb822bdd8f2`. No upstream edits/regeneration.
Both expected stdout lines remain exact:

```text
PASS: 1839 cases, 44728 steps, 7 files
PASS: 36 of 36 checks passed
```

## Assurance design and manual source review

The protected naive reference uses ordered lists for queues/items, literal slot
scanning, no production helpers/:queue/busy index/skip arithmetic, and loud
20,000-step budget exhaustion. Reviewed directly against shared §5: index-first
ordered atomic enqueue; quantum preserving credit/active; last-only deletion and
cursor repair; withdrawals retaining credit unless empty then closing the active
visit; inactive grant once, blocked head close, exact debit, paused take unchanged.
Its normalized results intentionally omit scheduler representation; canonical
state comparison separately checks every item/quantum/credit/cursor/active.
Three literal anchor tests cover the shared example, errors/withdrawal/deletion,
and deliberate work-cap exhaustion, independently of production equality.
This preparer's direct source review is not substituted for the parent's required
independent review. No claim of an independent external oracle certification.

Eight StreamData properties cover mixed valid/shared-error sequences and every
state/result, count/credit/busy invariants, conservation/FIFO/cost/value, split
takes, arbitrary opaque terms (including pid/ref/function, nil, integer/float),
immutable branches, near-limit large-quanta bounded work, peak-credit generated
boundaries, reweights with precisely bounded stable unit-cost backlog, and
analytic huge-cost/q1 nonzero-cursor cyclic ties with reduction bound. No naive
astronomical loop, unrestricted fairness claim, payload logging or fixture-specific
implementation. Seed0 and reproduced seed4242 execute; failure traces identify
step/op/shrunk_trace for generated data only.

Docs examples evaluate real histories and compare concrete results, not output
markers. Public exact signatures and whole executable AST are checked. Mix tests
inspect actual config and expanded manifest; private archive is inspected too.
CI JSON-compatible YAML is parsed structurally to check matrix, sibling pin,
working directory, setup and every mandatory command/order, with no conditional
or continue-on-error bypass. These checks still require human prose/source review;
they are not an adversarial sandbox or semantic proof of all documentation.

## Durable local evidence and reproducibility

Historical preparation evidence was recorded under the ignored directory
**`.loop/verification-stage2/`**. The isolation correction above externalized the
solution-bearing and private-location-bearing subset; the following is the
original evidence inventory, not a claim that every artifact remains there:

- `commands.jsonl`: bounded commands, cwd, start, exit, timing, HEAD/diff/lock hashes;
  companion `<label>.stdout` / `.stderr` retain failures as well as successes.
- `stubs-check-final.*`, `stub-judge/`: exact final stub outcomes and per-task output.
- `reference-check-final.*`, `reference-judge/`: final all29 observed verdicts (outer exit unknown) and
  exact per-task stdout (including final full-test/both-external expectations).
- `actual-final-stage1.*`, `actual-final-suite.*`, `actual-properties.*`;
  `environment.*`, `dependency-locked.*`.
- `actual-hand.*`, `hand-input.jsonl`, `hand-comparison.json`.
- `mutation-native.*`, `mutation-replay.*`, `mutation-restored-final.*`,
  `mutation-cleanup.json`.
- `package-build.*`, `package-manifest.json`, `inventory.json`, `recovery-checkpoint.json` and
  `private-location.txt` (now quarantined along with the leaked generator and snapshot).

The run helper bounds each retained command at300s and keeps stdout/stderr
separate. Installed loop retains default JUDGE_TIMEOUT300 per judge command;
no script modification/model-command settings. Its SHA256 is unchanged:
`4ed33daa824bd8ed999c141cf4abd55921981f5e8de86948408552b52dbb207f`.
Initial preparation wiring failures (formatter/typespec expectations and Mix
support discovery) remain in evidence; final support uses documented
`*_helper.exs` convention without disabling warnings or changing stage1 helpers.
Transient root `.loop/test.*` and loop.log diagnostics are reused by --check;
original owner coder logs, attempts, console and commit history are preserved.
Use the stage-specific retained evidence, not cumulative loop.log for duration.

Limits: minimum runtime/hosted CI unexecuted, no stage2 coder/model/provider/cost
or real-loop commit/discard validation, no publication, finite properties/corpus
not full proof. Parent review required before owner baseline commit and separate
loop/spending authorization. Exact owner commands are already in delivered
README.md and protected owner-instructions fixture; commit remains OWNER action.

## Recovery checkpoint after session timeout

The first preparation session timed out during final reference --check evidence
collection. Recovery performed bounded inspection only: no orphan verification
processes remained, all29 final pass lines were present, but the wrapper had not
persisted exit/duration. No exit status was fabricated. Preserved both that partial
record and earlier completed judge/full-gate records. Refreshed per-task output
copies, source/protection/changed-file inventory, no-stage/HEAD checks and private
asset identities. No full judge rerun or implementation expansion. See
`.loop/verification-stage2/recovery-checkpoint.json` for exact disposition.

## Postjudge completion note — final authorized snapshot

The final unchanged `bash scripts/loop.sh --check` results are now durably recorded:

- Actual stub: **exit 1 (expected), 107.916636s**;
  T01–T21 all pass, every new T22–T27/T29 fails substantively. Individual new
  counts: 0/7, 1/3, 0/2, 0/2, 0/2, 1/3; full stub suite **80/97 passed**
  (8/8 properties, 72/89 tests), **17 actual test failures**.
- Private reference: **exit 0, 28/28 tasks pass,
  247.197920s**; final T29 is **97 passed
  (8 properties, 89 tests)**, replay **1839 cases / 44728 steps / 7 files**,
  protocol **36/36**. All historical 66 tests execute in this suite.
- Exact `MIX_ENV=test mix test --repeat-until-failure 50 test/stage2/01_server_test.exs`
  on that reference: **exit 0, 256.183455s,
  51 suites × 7 = 357 test executions**, all pass, no retry-after-failure.
- Independent actual format / warnings-as-errors compile / CI identity test:
  **exit 0, 0.932699s**, CI **1 passed**.

Installed runtime file confirms **Elixir1.20.4 / OTP29.1.2**. setup-beam catalog
verification does not mean minimum-runtime or hosted CI execution; both remain
unexecuted. The private sibling spec is a byte-exact source snapshot, not a Git
checkout: all **22 upstream tracked files** match pinned `8a0e3cf` Git blobs.

Evidence root: `/Users/rob/Development/dwrr-elixir-private/evidence/`.
`stub-judge-result.json`, `reference-judge-result.json`,
`reference-server-repeat-result.json`, `repeat-summary.json` and companion
stdout/stderr retain immediate status, timing and every output. Current per-task
outputs are indices0–27 in `actual-judge-outputs/` and `reference-judge-outputs/`;
any pre-existing stale index28 copy is explicitly historical, not a current task.
`contract-audit.json`, `pinned-sibling-identity.json`, initial/final source
inventories, authorized edit deltas and `*-judge-identity.json` prove protection
and source equality: actual/reference differ only in the **seven** intended
implementation files, while tests/fixtures/CI/tasks/core are identical. Neither
judge nor repetition changed source, HEAD, status or index; the private preparation
Git repository remains unborn (no commit was created). No staged files.

The historical audit tree remains **272 files byte-identical** after relocation;
its 23 quarantine hashes remain intact. Full relocation-manifest SHA256:
reference `ba67d496524cc68a88445998eb6186aaa634fef954141c35ee10897b73e7ba15`;
audit `9844894031f5dd6431db8d2439f193260b5f02d63b04becac89a619b35f6c180`.
Final isolation scan covers ignored files, decoded BEAM/debug/docs and ETF build
caches, JSON leaves, archive candidates and Git blobs; no private implementation
leaks, duplicates, symlinks or hardlinks. The naive oracle and explicitly requested
documentation locators are allowed assets, not private source. Source-bearing
scripts/evidence are external only. See `final-isolation-scan.json` and
`final-acceptance-audit.json` for exact counts and final preservation checks.

Only this completion note and the corresponding shakedown result note were added
after the judge/repetition; no test, implementation, CI, task or contract changed.
Final inventories separately record those documentation-only additions.
`git diff --check` passes, index remains empty, existing preparation is preserved.
One initial evidence-wrapper startup stopped before executing checks because the
private repository has no HEAD; handling unborn state fixed that wrapper-only
issue. The original error is retained; no test failure was retried or hidden.
Independent reviewer gate remains required; no coder loop/commit/push was run.
