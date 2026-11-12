# Spec-loop shakedown — preparation evidence ledger

**Current status: stage-1 stub kit verified; owner loop not run.** See §11 and [STAGE1-VERIFICATION.md](STAGE1-VERIFICATION.md) for current evidence. Sections 1–10 preserve the historical framing/draft phase (including its then-open decisions and then-unfixed skill findings); they are not current status. No coder/model calls or commits in stage-1 preparation. See [SPEC-DRAFT.md](SPEC-DRAFT.md) for approved decisions.

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
