# Spec-loop shakedown — preparation evidence ledger

**Current status: stage 1 owner loop completed and reviewed; stage-2 stub overlay
prepared and verified locally.** See §12 for the original owner loop, §13 and
[STAGE2-VERIFICATION.md](STAGE2-VERIFICATION.md) for this authorized delegated
preparation. Sections 1–11 preserve historical phases and their then-current
status/decisions; they are not claims about today's checkout. No stage-2 coder or
model loop, staging, commit, publication or installed-skill edits in preparation.
See [SPEC-DRAFT.md](SPEC-DRAFT.md) and binding SPEC Part 2 for current approvals.

## 1. Authority, target and preserved files

Target: `/Users/rob/Development/dwrr-elixir`.

Initial read-only inspection found no git repository and no application source. The target was **not literally empty**: `.wtha/last.md` and `.wtha/last.json` already existed (harness artifacts). Their contents were not needed or examined; they were preserved, not overwritten/removed or staged. They are ignored by existing git ignore configuration; no new ignore file was created.

Authorized local operations actually performed successfully:

```sh
git init
git config --local user.name 'M. Robert Martin'
git switch --orphan spec-loop/framing
```

Result: unborn branch `spec-loop/framing`, no commits, local `user.name` reads `M. Robert Martin`. No user.email/config outside this repository was changed; no remote added or mutated. No destructive recovery used. Only requested draft paths were written:

- `docs/SPEC-DRAFT.md`
- `docs/SPEC-LOOP-SHAKEDOWN.md`

No files staged. The git configuration and repository metadata were created only as authorized. Future loop requires a committed clean baseline and separate authorization; this preparation deliberately does not supply one.

## 2. Applicable instructions and skill coverage

Read in full `/Users/rob/.pi/agent/AGENTS.md` (global safeguards). Checked ancestor instruction paths through `/Users/rob/Development/dwrr-elixir`, plus skill ancestors, and searched both source trees and target for AGENTS.md: no other applicable instruction files were found. No source repository edits permitted or made.

Installed skill read in full:

| Artifact | Coverage | SHA-256 |
|---|---|---|
| `/Users/rob/.pi/agent/skills/spec-loop/SKILL.md` | all 189 lines; skill name `spec-loop`, metadata version **1.0**, MIT, author M. Robert Martin | `ac29320fb5ddea28c6f987d57e0d8b680335aaee4ccff89767d7150384111455` |
| `/Users/rob/.pi/agent/skills/spec-loop/references/kit-format.md` | all 91 lines | `553447b28bfd82519494a3c047fe9b88a9e3db6378f143814492222031d601a8` |
| `/Users/rob/.pi/agent/skills/spec-loop/scripts/loop.sh` | all 157 lines; header and actual judge examined | `01785cb7833d854c5df97000f3007ef6f4596d80d5e5971aae076c6bc025db71` |

The skill directly links kit-format and loop.sh; both were read. No additional direct reference was necessary for the preparation. No harness extension/SDK/theme changes are proposed or implemented. Skill steps completed only to the extent of **input reading, proposed framing, draft specification and proposed stage slicing**. Owner has not confirmed framing or scope. Skill steps 4–7 have NOT been performed.

Library adaptations are explicit in the draft: deterministic pure library plus test/dev conformance driver, no model calls, configuration, credentials, doctor or home-directory outputs. Do not build inapplicable CLI infrastructure. Standard library runtime only; StreamData test-only allowed; JSON dependency/version choice remains OPEN.

## 3. Source revisions and input coverage

### dwrr-spec — ALL tracked inputs inspected before framing

Repository: `/Users/rob/Development/dwrr-spec`

Revision: **`a4f5e406cecc5dc7fe81c30478448a24e7378353`**. Git porcelain status empty at initial inspection and again after input/draft work. Twenty tracked files:

- Text read in full with `read`: `SPEC.md`, `PROTOCOL.md`, `README.md`, `.gitignore`, `LICENSE`, `corpus/README.md`, `drivers/go/README.md`, `drivers/go/go.mod`, `drivers/go/go.sum`, `drivers/go/main.go`, `tools/gen_corpus.py`, `tools/replay.py`, `tools/spec_model.py` (13 files).
- All seven tracked `corpus/*.jsonl` files loaded line by line using bounded Python parsing (7 files). Every record and every step was visited, request operations counted, error responses counted, input costs/quanta parsed exactly, response structures recursively inspected and all returned costs validated as strings in range. Every case begins with `new`; case names unique; each step has request/response; each response has one ok/error branch. No giant corpus dump. This is structural inspection, **not** scheduler execution or fresh Go-versus-model cross-validation.

Thus all 20 tracked files were covered; `.git` internals were not product inputs. There were no nested AGENTS files or extra tracked files left unread. No source changes, regeneration, `go mod tidy`, builds or test runs were done.

### Go reference — documentation structure and relevant implementation only

Repository: `/Users/rob/Development/dwrr`

Revision: **`225f59971e09c76df0949bbcc164e9cfaef82d4b`**. Git porcelain status empty at initial inspection and after input/draft work. Seventeen tracked files inventoried.

Read in full with `read`: `README.md`, `TESTING.md`, `CHANGELOG.md`, `RELEASING.md`, `LICENSE`, `go.mod`, `.github/workflows/ci.yml`, and relevant implementation `dwrr.go`. README/test docs explain remaining test/benchmark files, which were inventoried but **not all read** (not requested for Go reference). No claim of complete Go test-source reading or execution. Observed Go uses exact uint64 credit, a busy bitmap, a mutex, visit-preserving take and bounded idle skipping. Its storage reuse and concurrency guarantees must not be transplanted as claims about immutable Elixir.

README structure was carried into proposed Elixir docs: need, glance/install, quick start, examples, behavior, correctness/check-it-yourself, comparisons, colophon. Elixir README must begin `# dwrr-elixir`. Stage 2 explicitly requires TESTING, CHANGELOG 0.1.0, RELEASING, metadata, MIT copyright 2026 M. Robert Martin and CI tests+replay.

## 4. Corpus provenance, counts and fingerprints

Upstream corpus README states: generated **2026-11-12**, responses recorded from `github.com/version2beta/dwrr` **v0.10.1** through `drivers/go`; every response cross-checked against executable spec fast mode, all but four huge-skip cases also against naive mode. Seeds: random-small **20261112**, random-large **20261113**, random-skip **20261114**. This preparation verified those provenance declarations in the generator, module files and README, but did not reexecute them. It must not claim freshly regenerated/cross-validated responses.

Observed counts match README exactly; 4,175,587 corpus bytes total:

| File | Cases | Steps | Bytes | SHA-256 |
|---|---:|---:|---:|---|
| boundaries.jsonl | 7 | 53 | 6,970 | `aa99606f7441eca2689f11d8d9d793e740ce12da797823403412e63f54980b71` |
| edge-cases.jsonl | 20 | 225 | 29,692 | `6fc3028a57ecdae4c54386b6de78c6f46daa6a56d4e41699ab671dbae05364f7` |
| errors.jsonl | 10 | 70 | 8,151 | `ca86bbe58446ad82f899ebe3ec002689a4b4a12cb10ba64748ce5ec00ebd29fb` |
| examples.jsonl | 2 | 15 | 8,993 | `f481f277aed5cc78e06c4ba5de4717c2bb6311df60551c6320fdcc17e3be807a` |
| random-large.jsonl | 500 | 13,933 | 1,389,012 | `4fba307282dadcb348f283d973679cda7630f42cba3c7bdf145c5bd9b0c332e5` |
| random-skip.jsonl | 300 | 6,773 | 608,208 | `394f81d136a7a482efe2a8ab5d6946f703919123d99641e9e27f4f44f5a255d0` |
| random-small.jsonl | 1,000 | 23,659 | 2,124,561 | `d53f9b7226a9ee7a8751c1b9131a5e8b8022b5e6a094a942e0cd84d7b57d17db` |
| **Total** | **1,839** | **44,728** | **4,175,587** | seven files |

Operation coverage observed over every step:

| Operation | Count |
|---|---:|
| new | 1,839 |
| enqueue | 12,113 |
| take | 10,282 |
| set_quantum | 7,208 |
| add_queue | 3,633 |
| remove_queue | 3,221 |
| remove_head | 4,078 |
| drain_queue | 2,354 |

Error responses observed: invalid_index 4,422; zero_cost 728; cost_too_large 714; zero_quantum 213; quantum_too_large 194; negative_take 307. These demonstrate record coverage, not implementation correctness. Input costs/quanta include **18,446,744,073,709,551,615** (2^64−1) in errors.jsonl. Accepted upper bound remains SPEC §2 **9,223,372,036,854,775,807**, regardless of BEAM arbitrary precision.

## 5. Installation and loop/judge findings — blockers for future kit

Only read-only/help/catalog checks were run, never coder/model inference. Commands: `command -v pi elixir mix jq timeout gtimeout` (individually), `pi --help`, `pi --list-models`, `elixir --version`. Found pi `/Users/rob/.pi/agent/bin/pi`, Elixir/Mix `/opt/homebrew/bin`, jq `/usr/bin/jq`, timeout `/usr/bin/timeout`; no gtimeout needed. Elixir reports **1.20.4**, compiled with Erlang/OTP 29; running OTP **29**. This does not validate the proposed 1.17 or 1.18 minimums. No package/dependency manager operations were run.

### Model defaults and availability: distinguish observed from unknown

- SKILL.md lines **150–152** chooses Claude Haiku 5.5 high first, GPT-6.1 Sol high retry and maximum fourth attempt; 60 iterations, 20 minutes. User chose these **skill defaults**; no alternative selected here.
- loop.sh lines **24–26** have **empty CHEAP_CMD and STRONG_CMD**, and STRONGEST_CMD falls back to STRONG_CMD. Thus installed script alone does NOT enact the documented model/effort defaults. Line 38 refuses a run with empty commands. Future owner commands must pin exact provider/model and high/max separately; do not let the fallback turn the last attempt into high accidentally.
- `pi --list-models` currently lists `anthropic/claude-haiku-5-5`, and `gpt-6.1-sol` under **openai**, **openai-codex** and **openrouter**. There is **no observed missing-ID catalog mismatch on this installation**; do not fabricate one merely because it was a requested inspection concern. A catalog is not proof of authenticated provider access, entitlement, uptime, supported effort mapping or cost. **Operational availability remains untested**; a future failure is a blocker requiring owner decision, not permission to substitute.
- Human labels (`Claude Haiku 5.5`, `GPT-6.1 Sol`, “maximum”) are not exact shell commands/provider pins. Installed `pi --help` exposes `--provider`, `--model`, `--thinking ... high, xhigh, max`, `--print`, `--no-session`, `--offline`. The documented maximum label needs an explicit `max` command and provider support confirmation, not arbitrary xhigh substitution. No command strings or credential values were installed/changed; no auth file or broad environment dump was read. No inference request was sent.

### ExUnit recognition is not supplied

- kit-format.md lines **62–65** give Go/pytest examples only, not ExUnit.
- loop.sh **47, 58–65** has only a kit-configurable text marker, no Elixir parser. Omit `pass_marker` and line **61** accepts exit code alone, violating the desired robust acceptance. An empty/missing expect list also vacuously passes the marker loop.
- `mix test` aggregate output is not enough. Future viability probe must identify a reliable verbose ExUnit format on the chosen minimum version or a **protected test-only formatter** that emits stable, unambiguous markers only on genuine passing test events. Expected names should include module and full test name/identity; verify filters, skipped/excluded tests, failures, asynchronous output, ANSI/Unicode and no-test cases. No formatter was implemented or tested now.

### Exactness and safety gaps to address before approval to run

1. **Substring rather than exact recognition:** loop.sh **64** uses `grep -qF` on merged stdout/stderr. A short expected marker can match a longer test name, arbitrary printed text or diagnostics. It does not parse test events. Choose boundary-bearing unique marker grammar and protected formatter; prove it against negative/spoofing cases. This still cannot make a test-only shell judge secure against intentionally malicious production code printing exact markers; include code review and unrelated-input coverage, not blind trust in green output.
2. **Check-only scope:** **74–80** runs task_passes only, not top-level `.check` or `.format`. Every task command/whole-tree verification must include necessary checks; `--check` passing alone is not evidence that formatting/check settings passed.
3. **Post-judgment mutation:** **130–137** judges task+earlier tasks and `.check`, then runs `.format` and commits **without rejudging**. Formatting is not generally guaranteed semantics-preserving. Future kit commands can check formatting before accept, but that alone doesn't prove post-format tree; use explicit whole-tree verification on the final tree and seek owner-approved skill fix if necessary. Do not silently edit the installed/copied loop.
4. **Unborn/dirty target:** **39–41**, **96–101**, **142–145** depend on clean committed HEAD and branch state for restore/discard; current uncommitted preparation cannot be used as a loop-ready baseline. Committing remains owner-authorized future work.
5. **Protected patterns:** **48–49**, **93–101** combine regexes and restore protected tracked/new paths. Future kit needs anchored reviewed patterns covering tests, fixture manifests, formatter, complete files and all corpus records. Source specs must not be writable loop targets. Line **136** stages all files: preserve and audit unrelated artifacts, including ignored/untracked harness outputs, before owner runs.
6. **Time limits:** **87–89** optionally time-limit coder process only. `task_passes` at **60** has no built-in timeout; neither does upstream replay. A naive near-limit test can hang a judge even if a coder timeout exists. Add bounded test commands and property generation/work budgets. `/usr/bin/timeout` is present, but cross-platform CI setup still needs documentation.

These are identified risks and required viability work, not proven corrected defects. No loop `--check`, synthetic kit, fake tasks.json, model invocation, skill edit or model substitution was done.

## 6. Upstream protocol/tool observations relevant to the draft

- PROTOCOL requires exact per-line responses, flushing, EOF 0, protocol failure stderr + exit 2, scheduler errors continue, costs/quanta as strings. Core values may be any Elixir term; wire values are integers.
- `tools/replay.py` runs one subprocess, sends all requests at once, compares parsed JSON and exact line count, and waits without a timeout. Therefore replay alone proves neither per-response flushing nor interactive correctness. It reports all first-per-case mismatches, and successful full output should be `PASS: 1839 cases, 44728 steps, 7 files`.
- Python executable model skips blank lines; written PROTOCOL does not grant that exception. It also does not define all malformed/negative host-language-domain cases. Go driver handles some malformed cases differently. Draft exposes these as owner decisions rather than copying incidental behavior.
- `tools/gen_corpus.py` marks four boundary cases naive=False to avoid roughly 2^63 rounds. Stage-2 naive properties must use bounded small values or near-limit **large quanta**; huge skip correctness needs analytic/shared fixtures, not an unbounded naive run.
- Go implementation uses active, not a public newRound concept. Draft gives precise correspondence if that term appears later, and a cursor-independent full-cycle skip proof. Empty-queue skipping must preserve inactive cursor order and zero credits, not grant empty queues.

## 7. Proposed decisions/recommendations sent for parent/owner review

The draft proposes a pure scheduler-first `{scheduler, {:ok, value} | {:error, code}}` convention including `new/1` success, and preserved original state on all scheduler errors. Recommends tagged invalid_index/negative_take. Constructor invalid-domain result and all malformed Elixir inputs remain OPEN, not new shared codes.

Proposes `:queue` FIFO and persistent ordered queue/index structures, with explicit nonconstant/amortized immutable complexity and old-snapshot retention. Direct skip formula/proof covers credit, cursor, paused active visit and `newRound = not active` if used; no implementation/benchmark claim.

**Most important owner questions:**

1. Confirm proposed target users/outcome, API/data/result convention, errors, module/Mix/package names.
2. **JSON choice OPEN:** Jason dev/test-only and Elixir >=1.17, or raise minimum to Elixir >=1.18 + OTP >=27 for standard JSON? Ask owner, do not choose silently.
3. Resolve malformed-input and protocol-gap policy before binding fixtures.
4. Include optional Dwrr.Server in stage 2? Confirm wrapper API/ownership/timeout/restart semantics separately from pure core.
5. Approve 27-task stage 1 and 25-task stage 2 scope; exact tasks must be resliced to avoid tasks that pass stubs or cover protected complete files.
6. Resolve ExUnit judge exactness, actual provider/effort readiness and clean committed loop baseline. User will run verified kits on branches and return for review; no loop now.
7. **Explicit approval to build a kit only after annotated draft review.** Proposed upstream §11 Elixir mapping exists only inside the draft; dwrr-spec was not edited.

## 8. Checks actually performed versus not performed

### Performed

- Instruction discovery and full applicable AGENTS reading.
- Full required skill, kit reference and loop reading; line-level judge inspection and SHA-256 fingerprints.
- Git revisions/status/inventory for both immutable source repositories.
- All 20 tracked dwrr-spec files inspected, including every corpus case/step through bounded parsing; counts, type/range sanity, unique names, operation/error totals and file fingerprints recorded above.
- Go documentation structure and relevant implementation read, with limited coverage stated.
- Read-only installed executable/help/model-catalog/runtime-version checks; no model inference or credential inspection.
- Authorized target git init/local name/unborn branch setup; existing harness artifacts preserved.
- Both requested draft documents created and reviewed as text; no binding approval claimed.
- Final target/source git status, no-stage/no-commit and artifact-presence checks (recorded at completion below).

### NOT performed — must not be called success

- Owner framing/spec/API/dependency approval; binding SPEC or upstream §11 change.
- Kit/test/stub/tasks/PROMPT/loop creation, dependency install or lockfile, code/reference implementation, or synthetic ExUnit experiment.
- Any mix compile/test/format, Go build/test, scheduler-model execution, corpus regeneration, external replay or hand fixture driver run.
- Native corpus implementation pass, invariant/property/benchmark pass, true JSON round-trip/flush/exit tests, minimum-toolchain compatibility.
- Stub-failure proof, every-reference-task judge pass, whole-tree/reference/replay pass, stage-2 overlay on actual stage 1, affordability mutation checks, or protected-path runtime proof.
- Actual model access/credentials/effort/cost verification, real coder harness operation, any loop or model call.
- Commits, staging, tags, remotes, CI execution, release/publication.

## 9. Future verification matrix — all pending

| Required before handing owner a kit | Current status |
|---|---|
| Every actual task fails on stubs; must-succeed positive path, no empty filters/globs, no accidental corpus/error pass | NOT RUN |
| Private reference passes every task through installed loop's own judge; every expected test observed | NOT RUN |
| Whole tree formatted, warnings-as-errors compile, complete tests and unchanged external replay PASS | NOT RUN |
| Stage-2 overlay against owner's actual stage-1 loop-written tree preserves all previous task/test behavior | NOT RUN |
| Planted affordability `<` to `<=` mutation caught by native tests **and** external replay, then restored in authorized disposable target | NOT RUN |
| Hand fixture request/response run with real driver, including interactive flush | NOT RUN |
| Protected-path regex/complete-files/fixture provenance review; source repos untouched; final diff reviewed for special casing | NOT RUN |
| Pinned exact model commands/high versus max and availability approved; no substitution | NOT RUN |

## 10. Residual risks and stop condition

Draft completeness is not scheduler correctness. Open API/domain/JSON/Server decisions change design and must block kit work. The simple skip formula has a written proof but no implemented test evidence. Persistent BEAM structures have different allocation/amortization costs from Go. Property domains can explode into astronomical rounds if generated carelessly. Existing judge accepts textual substrings and checks pre-format code; test inventory, negative probes and final-tree review are mandatory. Default model IDs appear in the catalog but operational access is unknown. Shared upstream spec/protocol remain drafts; record pinned provenance rather than claiming a released normative standard.

Preparation stops with these two **unapproved** drafts. Next action belongs to parent review and owner annotation/approval, not automatic infrastructure work.

### Final local inspection

Final inspection confirms target branch `spec-loop/framing`, no commits, no staged files, only the two requested untracked docs outside pre-existing ignored `.wtha`. Both source repositories still have the pinned HEADs and empty porcelain status. No implementation/kit paths were created. This statement records artifact/git inspection only, not software validation.

## 11. Stage-1 preparation after owner approval and skill fixes

Owner approved the operation-specific API, map records, ordered busy set,
full-unproductive-cycle-only skip trigger, structs, built-in JSON on Elixir
>=1.18/OTP >=27, strict protocol, and 22 + 25 tasks. The later resume request
explicitly cleared the kit hold, pinned dwrr-spec **0.1.1** at
`8a0e3cf9ae860ba207213590c00feeb822bdd8f2`, and required both upstream tools.
No commits or model calls were authorized; preparation used deterministic tools
directly, without subagents, to respect that boundary.

Re-read installed **spec-loop 1.1**, kit-format and loop completely. Copied the
loop unchanged and verified byte identity. Pinned model commands stay in the
loop; the kit sets none. Exact stdout full-line expectations use installed
Elixir 1.20.4 summaries; colors off, one test file per nonfinal task. No custom
formatter/pass_marker. All judge commands use the skill's default 300s cap.
Prior skill-1.0 defects above are historical, not claims about the current loop.

Produced SPEC.md, tasks.json (22 tasks), PROMPT.md, PROGRESS.md, README.md,
.gitignore, .formatter.exs, mix.exs, public delegate/struct contracts, complete
protocol parser, three implementation stubs, 21 test files/support, scripts,
MIT LICENSE and protected vendored corpus/spec/protocol/provenance. Runtime has
no dependencies. No library-inapplicable configuration, credentials, doctor,
model pipeline or report directories were built.

Reference kept outside the kit. Current acceptance:

- Unchanged `bash scripts/loop.sh --check`: **22 pass**, exit 0, 113.928 seconds.
- Stub `--check`: **22 FAIL**, exit 1. Full stub suite: **0/66 passed**, exit 2;
  every individual corpus/error test fails, not merely the aggregate task.
- Restored reference whole-tree: **66 passed**; replay **1839 cases / 44728 steps /
  7 files PASS**; protocol checker **36/36 PASS**. Command took 11.632 seconds;
  default **JUDGE_TIMEOUT=300** needs no increase on this host.
- Planted `<` to `<=`: native small corpus **0/4 passed** (exit 2), external
  replay **46 failing cases** (exit 1). Restored and reran whole-tree cleanly.
- Hand fixture new/enqueue/take returned three exact responses, exit 0;
  check_driver independently exercised interactive flushing and exit behavior.
- Source/fixture hashes and protected path inventory inspected; source repos
  untouched. Private reference differs from delivered code only in the three
  implementation stub paths, not tests, contracts, loop or fixtures.

An initial reference --check failed at formatting; helper-call layout was
simplified before the successful verification. This was not used as stub proof.
The final stub suite actually executed all 66 failing tests. Retained local
stdout/stderr, command/exit/timing JSON and inventory are ignored under
`.loop/verification/`. Full details, skill identities and limitations are in
STAGE1-VERIFICATION.md. No logs/private reference source go into Git.

Step accounting: framing/spec/stages approved; stage-1 kit and verification done;
owner loop and strong-model post-loop review still pending; stage-2 overlay,
properties, process wrapper and release work not started. Minimum toolchain not
executed (only installed 1.20.4/OTP29). No provider-access/effort inference,
model spending, real-loop commits/discards, remote actions or publication tested.
Actual iteration/retry/model/time report must come from future loop logs.

Suggested skill wording improvement: kit-format's final README model-command
assignment example conflicts with the owner-only/no-kit-overrides rule; prefer
plain loop invocation plus a documented, owner-controlled override explanation.
Exact skip-trigger proof still needs review against the eventual loop code;
behavior and reduction bounds alone do not prove internal trigger placement.

## 12. Original stage-1 owner loop and post-loop review

This section records the parent-provided independent read-only audit, not a new
execution of historical snapshots by this preparer. Audit artifact:
`/Users/rob/.pi/agent/sessions/--Users-rob-Development-dwrr-elixir--/subagent-artifacts/aeaa3bca-b0dd-485a-bb52-8a8d50fe2310_worker_output.md`.
The parent separately inspected source: no fixture special cases, dynamic atoms
or hidden shared state; the exact failed-busy-visit skip proof was checked at
core.ex lines186–281 (at audited HEAD). This is source-inspection evidence, not
an inference from task titles or a universal correctness proof.

The owner ran kit `e3d229e547663d93498aaf7466962e75b986919b` to
`7205252eb23a27a817fbc8795776ef58013de090`: **eight iterations, eight successful
first attempts, zero observed retries**. Targets T01,T02,T03,T05,T07,T15,T19,T20.
Six exact commands in loop logs and commit trailers:
`pi --provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session`;
T15/T20 used
`pi --provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session`.
No strongest/max attempt. These record commands requested, not backend telemetry,
token counts, billing or independent model/effort verification.

The stage-specific console file birth-to-mtime span was 626.108640 seconds,
**approximately 10m26.1s**, 2026-11-12 12:47:32–12:57:58 −07:00. Filesystem span,
not instrumented subprocess/run timing; cumulative loop.log contained earlier
stub-check failures and must not supply the run's start time. Eight coder-log
spans total481.297s, also not measured process durations.

All **52 protected hashes held through all eight original loop commits**. Four
implementation/progress files changed, not tests/contracts. The independent fresh
build passed 66 tests, native all-seven corpus, external1839 cases/44728 steps/7
files and36/36 protocol checks. Its disposable affordability `<`→`<=` mutation
failed6/7 native corpus tests (all four small) and replay46/1839 cases; restoring
bytes passed whole tree. Those are the parent's audit results; current overlay
mutation and checks are separately recorded in §13. Stage2 legitimately changes
some former protected docs/specs/tasks/metadata, so the original52 cannot be
claimed intact across this overlay. Stage1 implementation/test/provenance hashes
are newly pinned and preserved by the overlay.

### All fourteen incidental completions (execution-backed historical matrix)

“Own command” includes exit0 and all stdout expectations. “Full judge” additionally
requires all predecessors, format and compile checks at the same snapshot.
The audit executed all22 exact commands across nine snapshots (198 commands,
104passes/94failures), plus18 format/compile checks; it did not run a coder or
loop to reconstruct history.

| Untargeted task | First own command pass | First full judge pass |
|---|---|---|
| T04 atomic enqueue | c345478 (T02) | 6ac75ed |
| T06 append queues | c345478 (T02) | 329792f |
| T08 remove head | 329792f (T05) | 2f59cad |
| T09 drain | 329792f (T05) | 2f59cad |
| T10 basic take | c345478 (T02) | 2f59cad |
| T11 take edges | c345478 (T02) | 2f59cad |
| T12 paused visits | 6ac75ed (T03) | 2f59cad |
| T13 mid-visit mutations | 329792f (T05) | 2f59cad |
| T14 idle-cycle/work bound tests | 6ac75ed (T03) | 2f59cad |
| T16 sparse/FIFO | 2f59cad (T07) | 4410c38 |
| T17 small corpus | 4410c38 (T15) | 4410c38 |
| T18 random corpus | 2f59cad (T07) | 4410c38 |
| T21 integration/replay | 7205252 (T20) | 7205252 |
| T22 original whole tree | 7205252 (T20) | 7205252 |

**Slicing lesson:** T14 and T18 own commands pass before idle skipping exists;
task-title success does not establish that optimization. T15 remained the failing
predecessor. Small implementation tasks often complete related later contracts;
record this empirically instead of padding a task minimum or crediting22 coder
iterations. The initial stage2 preparation used eight cohesive tasks; current stage2 uses
seven, T22–T27 and T29, with CI complete/protected and T28 absent. Finished
properties/reference are protected preparation work, not artificial coder tasks.

## 13. Historical initial eight-task stage-2 preparation and skill feedback

This section records the initial preparation, superseded for current task counts,
CI protection and helper governance by §14 and STAGE2-VERIFICATION.md.

The user expressly authorized a sole repository writer (delegated worker), local
checks, a test-only StreamData download and this ledger update. That differs from
§11's original no-subagent preparation and from §12's owner-run model loop. This
phase invokes no coder/model loop, provider inference, staging, commits, pushes,
remote collaboration mutations, publication or installed-skill changes. A local
`spec-loop/stage2-preparation` branch was created from7205252; audited core and
driver code remain byte-identical. All new tasks remain stubs in the delivered
kit; private completed Server/docs/CI prove reachability outside it.

Current results/commands/hashes/timings are in STAGE2-VERIFICATION.md and ignored
`.loop/verification-stage2/`. The actual overlay passes all earlier21 tasks;
every new T22–T29 fails its own unchanged loop judge for missing implementation.
A completed private reference run passed all29 via unchanged loop --check.
After exact typespec-test strengthening, final stdout again shows all29 pass;
that final wrapper's exit record was lost to session timeout and is explicitly
unknown (no orphan remained). A separately recorded latest whole-tree command
exits0. Full recovery disposition is in STAGE2-VERIFICATION.md. The fresh
whole tree passes98 checks (8properties/90tests), replay and protocol checker.
The disposable actual-core-copy mutation fails6/7 corpus tests and replay46cases;
restore passes full final gate and owned mutation directory is deleted.
StreamData1.3.0 is approved, locked, test-only/runtime:false; no runtime dependency.

Preparation initially caught a real installed-runner issue: new support filenames
were not matched by Mix1.20's loader/ignore filters, so98 executed passes still
exited nonzero under warnings-as-errors. Renaming NEW support files to documented
`*_helper.exs` convention fixed it without disabling warnings, adding minimum-
specific config or modifying historical support/tests. Earlier fixture/test wiring
mistakes were fixed before final evidence, not used to weaken contracts. Delivered
Server stubs also generate newer compiler unreachable-pattern warnings, but seven
actual behavior tests fail; this is not formatting/warning-only stub proof.

Minimum Elixir1.18/OTP27 not available/executed; no toolchain installation or
Docker downloads. CI structure/commands are checked locally, **hosted CI is not
run**. No new claim of authentication, model availability, cost, publication or
full correctness beyond exercised evidence. Parent independent review remains a
gate, especially the naive reference and test strength.

Suggested skill improvements (feedback only; installed files unchanged):

- Timestamp run start/end and record actual attempt/process durations.
- Distinguish logs per run; cumulative logs may include earlier stub checks.
- Record incidental task completion separately from targeted attempts and full
  predecessor judgments; titles are not algorithm-proof coverage.
- Permit honest smaller cohesive stages by explicit exception, not padded tasks
  for complete preparation assets.
- Replace README's model-command override assignment example with plain loop
  invocation plus owner-controlled override explanation.

## 14. Current authorized bounded precommit corrections

The initial eight-task preparation in §13 is historical. Current stage 2 has
seven new tasks T22–T27 and T29, deliberately no T28: ordinary YAML CI is complete
and protected, identical in actual/reference, with one independent SHA256 test.
T01–T21 commands/tiers/counts are unchanged; final suite is 97 checks (8 properties,
89 tests), 28 total tasks. Delivered Server/docs/metadata remain stubs.

The fake-process timeout test now waits on a fresh-reference barrier ack before
mailbox inspection; selective receive preserves the single seen marker and any
retry calls. There is no sleep or elapsed upper bound; module timeout catches
hangs. Owner authorized assert_receive_timeout 1000ms in the stage-1 helper:
41 original frozen files untouched plus one explicitly hashed helper overlay,
retaining original hash provenance. Historical 66 tests still run.

Private reference and entire isolation audit/quarantine were moved, with full
pre/post byte identities, to /Users/rob/Development/dwrr-elixir-private/reference/
and /Users/rob/Development/dwrr-elixir-private/isolation-audit/. New scripts/logs
are external under /Users/rob/Development/dwrr-elixir-private/evidence/. These
requested locators are deliberate; outside-tree is not an OS sandbox. Historical
artifacts are preserved intact and older scripts can name removed temp paths.

setup-beam v1 source and authoritative Hex build listings were fetched read-only
(HTTP200); exact 1.18.4-otp-27 / OTP27.3 and 1.20.4-otp-29 / OTP29.1.2 exist
for amd64 Ubuntu24.04 and26.04. CI uses those pairs and pinned spec8a0e3cf.
This is catalog support, not runtime/hosted CI execution: both minimum runtime
and hosted CI remain unexecuted. Exact URLs and final judge/repeat/isolation
evidence are in STAGE2-VERIFICATION.md. Only StreamData1.3.0 test-only/runtime:false
is declared/resolved in both trees, no transitive/runtime deps or additions.
No model loop/staging/commit/push/skill edit. Independent review remains a gate.

### Current final-snapshot completion results

Stub unchanged judge exits1 as expected (107.916636s):
all21 earlier tasks pass, all7 new T22–T27/T29 fail substantively; full stub suite
80/97, 17 failures. Private unchanged judge exits0/all28
(247.197920s), T29 97 checks (8 properties,89tests),
replay1839/44728/7 and protocol36/36. Exact server repeat-until-failure50 exits0
(256.183455s): 51 suites,357 executions,allpass.
Independent format/compile/CI identity gate exits0 (CI1passed). No code changes
by verification; only this result note and verification completion note follow
the judge. Detailed evidence/inventories are external as cited in
STAGE2-VERIFICATION.md. Minimum runtime/hosted CI still unexecuted; review required.
