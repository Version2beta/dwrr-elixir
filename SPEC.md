# dwrr-elixir: binding stage-1 specification

Complete; do not change. Approved owner decisions plus dwrr-spec 0.1.1 at
`8a0e3cf9ae860ba207213590c00feeb822bdd8f2` govern. Read protected
`test/fixtures/dwrr-spec/SPEC.md` §§2–8 for exact scheduler state transitions,
precedence and limits, and `PROTOCOL.md` in that directory for the complete wire
contract. They are part of this binding spec, not optional reference behavior.
The Go source is informative only. docs/SPEC-DRAFT.md records architecture and
stage-2 plans; only stage 1 is implemented now.

## Public contract

Elixir >=1.18, OTP >=27. No runtime dependencies. Built-in JSON for test/dev driver;
no Jason. Core is pure and immutable, no I/O or process or hidden application state.
`%Dwrr.Item{value: term, cost: integer}` and
`%Dwrr.Scheduled{queue: index, value: term, cost: positive_integer}` preserve values
exactly. Successful accepted item costs and quanta are 1..9_223_372_036_854_775_807.
Zero and larger nonnegative integers return shared errors, not exceptions.
Credit arithmetic is exact through 18_446_744_073_709_551_613. No floats/saturation.

| Function | Return |
|---|---|
| new(count) | scheduler struct |
| add_queue(s) | {old_count, s2} |
| remove_queue(s) | s2 |
| enqueue(s, index, items) | {:ok, s2} or {:error, code} |
| set_quantum(s, index, quantum) | {:ok, s2} or {:error, code} |
| take(s, n) | {:ok, scheduled_list, s2} or {:error, code} |
| remove_head(s, index) | {:ok, item_or_nil, s2} or {:error, code} |
| drain_queue(s, index) | {:ok, item_list, s2} or {:error, code} |

Index and n are integers; invalid index/negative n return :invalid_index/:negative_take.
Count is a nonnegative integer. Enqueue items is a proper list of Item structs.
Cost/quantum validation inputs are nonnegative integers. Other types/shapes and
negative count/cost/quantum raise ArgumentError, via guarded clauses plus explicit
fallbacks (not FunctionClauseError). No new shared codes. Existing input state
remains usable after all failures. Multiple outside-type-fault precedence is
unspecified; documented-type shared errors follow upstream ordering. Opaque states
must come from this API; callers may not forge/edit struct fields.

Enqueue is whole-batch atomic, checks index even for an empty batch, then costs in
order (zero_cost or cost_too_large). Set quantum checks index, zero_quantum,
quantum_too_large; preserves credit and active. add appends quantum-1 empty queue.
Remove queue drops only last, discards items, cancels that active visit and repairs
cursor exactly as shared §5.5. Withdraw/drain do not debit or schedule; emptying
resets credit and closes/advances only that active visit. Empty head is nil, drain
empty is []. All-empty take and take(0) do not move cursor. On each inactive busy
visit grant once; blocked head closes visit (never overtake FIFO). Serve when credit
>= cost; debit exactly; reaching n preserves an active nonempty visit even if its
next head blocks. Enqueue joins active visit; reweight affects only next grant.

## Complete representation seam

Protected Dwrr struct holds queues (map indexed by contiguous integer), count,
total queued items, cursor, active, and busy (ordered :gb_sets nonempty indexes).
Each internal queue record is a map with quantum, credit, size, head and tail.
head is Item or nil; tail is :queue of remaining Items. Empty head implies size 0,
empty tail and zero credit. Default quantum 1. Cached head avoids repeated O(L)
FIFO peeks. Maintain counts and busy membership on every transition. Do not
publish representation as API; the protected test helper audits this internal seam.

## Direct idle cycles: trigger and exactness

Use local failed-closed-busy-visit count, initially zero per take. Reset on every
item served (even if that empties a queue). A blocked active resume counts once,
without another grant. Empty bypasses do not count. No skip scan before B failed
busy visits, where B is current busy-set size. During no service, heads, membership,
quanta and B cannot change. Cyclic selection therefore observes every head once;
after B failures, all credit < head cost, cursor is next cyclic position, inactive.
No external mutation interleaves in a pure call. This also handles nonzero cursor,
a resumed active visit, and changing B after service: service resets the count.

Only now compute r = min_i div(head_cost_i - credit_i - 1, quantum_i) over busy
queues. Add r*quantum_i credit to each when r>0; reset failed count even if r=0.
For 1<=j<=r every head remains strictly unaffordable, so each skipped cycle grants
once, serves nothing, closes visits and returns to the same inactive cursor. The
next cycle has at least one affordable head; run it normally in cyclic order.
This is exact even at MAX_COST/quantum=1. No stepping through numeric idle rounds,
no selecting winners out of cyclic order, no pre-grant all-busy scan.

## Performance

Use map records, FIFO :queue (amortized O(1) push/pop along linear state histories;
worst reversal O(L)), ordered busy indexes with logarithmic successor/wrap. Never
scan N empty queues per take or repeatedly convert FIFO to lists. Persistent map
cost is conservatively O(log N), representation dependent. new O(N log N), add
O(log N), remove O(log N+log B) excluding GC, enqueue K items O(K+log N+log B)
amortized, reweight O(log N), withdraw O(log N+log B) amortized, drain O(L+log N+
log B). Each visit/item adds O(log N+log B), each full-failure scan O(B log N),
not per grant. take is magnitude-independent; coarse bound O((R+1) Bmax (log N+
log Bmax)+R) for R>0. Treat log sizes as log(2+size). Retained storage O(N+items),
plus outputs and old snapshots. Persistence branching may repeat reversal costs.
No allocation proportional to requested n. No claimed secure erase or Go parity.

## Driver

Complete parser is protected; implement Adapter and Driver stubs. Parse a whole
request before invoking scheduler logic. Built-in JSON decode preserves integer
vs float/exponent distinctions. Costs/quanta are canonical decimal strings (0 or
nonzero digit then digits), unsigned <=2^64-1. Values/index/count/n are JSON integers;
negative count is protocol error. Ignore extra fields; duplicate keys unspecified.
Blank/malformed lines, wrong/missing fields, unknown op or operation before new:
stderr category-only diagnostic, exit 2, no response for that line or later lines.
Successful prior responses stand. Scheduler errors respond and continue. No atom
creation from wire keys/values. No sensitive payload echo. Extra integer magnitude
and input line resource caps are not newly imposed. EOF exit 0. Each response one
compact JSON object plus newline, synchronously written/flushed before next read.

Adapter.apply(s, parsed_request) returns {s2, wire_response}; nil state requires new
(ArgumentError if not). Extract state from each operation-specific core result;
wire response shapes are exactly PROTOCOL.md. Driver.run() owns only stdin/stdout
and one threaded scheduler; no reports/files/model calls/config/credentials/doctor.

From repository root, compile first (no compile text on wire):

```sh
MIX_ENV=test mix compile --warnings-as-errors
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

The unchanged external tools must be at the pinned sibling checkout. Both exact
PASS lines are required by T22, as is the exact 66-test no-failure summary on the
installed Elixir 1.20.4 runner. Colors disabled. Tests must genuinely execute;
printing summaries, exiting test VM or fixture-specific behavior is forbidden.

## Kit boundary

22 ordered tasks; T17 small and T18 random corpus files cover all 1839 cases/44728
steps natively, separate from driver and Python checks. T22 last is formatted,
compile warnings-as-errors, every test, both external tools. No stage-2 Server,
property reference, StreamData, release CI or publishing now. Owner runs loop;
strong-model preparation never runs a coder or model call. Model commands are
pinned in unchanged loop.sh, never kit overrides. Protected files cannot drift.

# Part 2 — stage-2 binding contracts

This numbered part supersedes the stage-1-only kit boundary above, not the
scheduler/protocol semantics or provenance. Apply to audited loop-written HEAD
7205252eb23a27a817fbc8795776ef58013de090 (original kit e3d229e). Preserve T01–T21
commands and counts exactly. Replace old T22 final gate with seven cohesive tasks
T22–T27 and T29 (owner-approved exception to the skill's 15-task stage minimum).
T28 is deliberately absent: complete protected CI is not a coding task. Properties
and the naive reference are complete protected preparation assets, not coding tasks.

## 2.1 Frozen source and writable targets

Do not change core, driver, parser, Item/Scheduled structs, stage-1 tests/support,
vendored corpus/spec/provenance, or the unchanged installed loop. Hash assertions
in test/fixtures/stage1-preserved-sha256.json freeze 41 original files unchanged.
The sole authorized exception is test/test_helper.exs: assert_receive_timeout
1000ms, with original SHA provenance and protected overlay SHA in
test/fixtures/stage2-helper-overlay-sha256.json. Historical 66 tests still run. lib/dwrr.ex is
editable ONLY for @doc, @moduledoc and @spec attributes: its entire remaining AST,
including opaque type/struct/delegates, is frozen against the original source in
protected test/fixtures/stage1_dwrr.ex.txt. No production behavior changes here.
Writable targets: lib/dwrr/server.ex, lib/dwrr.ex documentation/specs, README.md,
TESTING.md, CHANGELOG.md, RELEASING.md, mix.exs metadata,
and PROGRESS.md attempt notes. CI is complete/protected, not writable. New helper files only if required by these targets.
All tests/fixtures/helpers/spec/tasks/prompt/loop/scripts/docs/lock and complete
files are protected. Writable task files must not be added to protected patterns.

## 2.2 Dwrr.Server (T22)

start_link(count, options \\ []) forwards standard GenServer options unchanged.
Use `use GenServer` with normal child_spec count argument, and initialize via
Dwrr.new(count). Caller owns links/supervision. No implicit application children,
registered name, persistence or hidden global state. Named options are optional.
Restart reconstructs a fresh scheduler from the original count, losing queued
items/reweights/added queues. No restore/snapshot parameter or reset API.

Provide enqueue(server,index,items), set_quantum(server,index,quantum),
take(server,n), add_queue(server), remove_queue(server), remove_head(server,index),
drain_queue(server,index). Each makes exactly one default-timeout GenServer.call;
perform the corresponding pure operation once. Reply with the EXACT core return,
INCLUDING scheduler snapshots. Store according to result shape: add pair's second
value; remove's scheduler; {:ok,s2}'s s2; {:ok,value,s2}'s s2. Tagged errors reply
unchanged and retain prior state. No second error scheme, catches, retries,
idempotence, task execution, casts, blocking queue, wakeups or backpressure.

Calls serialize complete operations in mailbox arrival order; cross-sender order
is not guaranteed. Default 5000ms call timeout; timeout does not prove rollback.
Outside-domain core ArgumentError terminates Server and caller observes call exit,
not a translated tagged error; invalid initialization fails standard start_link.
Returned snapshots support separate pure branching, not authoritative shared writes.

## 2.3 Public documentation and types (T23)

All eight Dwrr operations have exact operation-specific polymorphic signatures
in protected test/fixtures/stage2-spec-signatures.json; Server public signatures
(including standard start_link options/result) are in stage2-server-spec-signatures.json.
Server snapshots may contain values from arbitrary callers, so results use term()
parameters, not an unsafe claim that enqueue infers the whole stored value type.
Enqueue validation inputs include zero cost via a nonnegative-cost Item struct
type; accepted returned Items remain positive-cost. Preserve the opaque/value
and error types. Do not use `any()`/`term()` to erase returned state/shape (the
constructor's opaque value parameter is term). Document every operation plus
immutable threading, retained input on tagged errors, outside-domain ArgumentError,
shared 2^63-1 limits/2^64-3 credit and declared-cost not time fairness.
The module docs contain exactly three fenced `elixir` executable examples in order:
(1) enqueue/take :job at cost2, `result == [:job]`; (2) independently take and drain
an old snapshot holding :original, `result == {[:original],[:original]}`;
(3) rejected zero-cost enqueue, `result == {:error,:zero_cost}`, state unchanged.
Each example must derive result from actual calls, not a literal expected answer.
Examples are independent histories and are evaluated by protected tests.

## 2.4 README and executable examples (T24)

Begin `# dwrr-elixir`. Include The need; At a glance; Quick start; Examples;
Behavior worth knowing; How we know it's correct; Check it yourself; How it
compares; Colophon. State intended release0.1.0, Hex dwrr/app dwrr, MIT2026
M. Robert Martin, Elixir>=1.18/OTP>=27, no runtime deps, intended install
`{:dwrr, "~> 0.1.0"}` and canonical https://github.com/version2beta/dwrr-elixir.
Intended Hex/docs URLs are not evidence of publication. Avoid time-sensitive,
unmeasured allocation/benchmark/CI claims; differentiate Go semantics from BEAM
storage and pure coordination from a worker pool.

Exactly four fenced elixir examples, with result computed from operations:
1. Byte sharing: q0=2/q1=3; queue0 packet_a:2,packet_b:2; queue1 packet_x:4,
   packet_y:1; take10 => result list of {queue,value,cost} in that order.
2. Caller-owned worker orchestration: start Server(1), enqueue job_a/job_b cost1,
   take2, map actual values into result [:job_a,:job_b]; always stop owned Server.
   Explain caller executes jobs; Server does not.
3. Pure withdrawal: cancelled:5,kept:1; remove_head then drain =>
   result {[:cancelled],[:kept]} from actual returns.
4. Atomic error: valid item followed by zero-cost invalid item => zero_cost;
   subsequent take proves empty original input.

Document all result shapes, six shared errors/input retention, ArgumentError,
FIFO/no overtaking, retrieval limit/paused visits, enqueue joining/reweight next
grant, last deletion/index reuse, immutable storage/old snapshot retention,
default Server timeout/no retries/restart losses/no backpressure. Cost fairness
is not an unrestricted dynamic-backlog promise. Preserve the exact owner-run
section from protected test/fixtures/stage2-owner-instructions.md, including
review/commit as OWNER steps, unchanged defaults, logs, STOP and spending authority.

## 2.5 TESTING (T25)

Describe 66 historical tests, 1,839 cases/44,728 steps/seven files, 36 protocol
checks, eight properties and three naive anchor tests. StreamData1.3.0 locked,
test-only/runtime:false. Include exact executable reproduction fenced sh block:
`MIX_ENV=test mix test test/stage2/properties_test.exs --seed 4242 --warnings-as-errors --no-color`.
Explain printed seed, shrinking, step/op/shrunk_trace for generated data only,
preserve lock/version and trace when reproducing. Document 20,000 naive-step cap,
small operation/batch domains, near-limit large quanta/no resizing, analytic
huge cost/quantum1, conservation/FIFO/errors/state/branches/split takes, bounded
stable-backlog fairness only. Give full local and both pinned external commands;
never say minimum/CI executed when not. Mutation instructions ONLY in disposable
owned copy: actual core `<` to `<=`, native corpus AND replay must fail, restore
bytes and rerun full gate; never alter upstream/expected responses.

## 2.6 Release docs (T26)

CHANGELOG has exactly one release heading `## 0.1.0` marked unreleased; initial
Elixir immutable scheduler/Server, shared draft0.1.1, no transplanted Go history
or invented publication date. RELEASING is an owner procedure, not authorization:
verify protected assets/clean tree/version/license/deps, min/current runtimes,
format/compile/test and BOTH pinned tools; then `mix hex.build` and inspect actual
archive; then owner credentials/approval/package ownership and only explicitly
authorized `mix hex.publish`; tags (`git tag -a v0.1.0`) and pushes require separate
owner permission. Canonical repo above, intended https://hex.pm/packages/dwrr and
https://hexdocs.pm/dwrr/. No credentials in files/logs, no claim published here.

## 2.7 Mix metadata/package (T27)

Keep app dwrr/version0.1.0/elixir >=1.18.0 and application [] (no implicit child).
Preserve elixirc_paths: [lib,conformance] only dev/test, [lib] prod. Dependency
exactly {:stream_data,"~> 1.3.0",only: :test,runtime: false}; protected lock pins
1.3.0/checksums. No runtime or documentation dependency silently added.
Description 30..250 characters; source_url canonical repo; package name dwrr,
licenses [MIT], links exactly %{"GitHub" => canonical repo}. Expanded package
file manifest is exactly all lib/**/*.ex, mix.exs, README.md, TESTING.md,
CHANGELOG.md, RELEASING.md, LICENSE. No tests/corpus/conformance/loop/private source.
MIT copyright 2026 M. Robert Martin is frozen. Inspect actual archive locally
on the private reference; publishing is not this task.

## 2.8 CI (complete protected assurance asset; no T28)

.github/workflows/ci.yml is complete ordinary YAML, protected by the anchored
tasks.json pattern and one SHA256 identity test against readable provenance in
test/fixtures/stage2-ci-sha256.json. No YAML parser dependency. Triggers
push and pull_request, exactly one job test on ubuntu-latest, timeout15min,
MIX_ENV=test, default run working-directory dwrr-elixir. Matrix include exactly
Elixir1.18.4/OTP27.3 and Elixir1.20.4/OTP29.1.2. setup-beam build listings
confirm both pairings; exact URLs/status/evidence in docs/STAGE2-VERIFICATION.md.
Ordered steps:
1 actions/checkout@v4 with path dwrr-elixir;
2 erlef/setup-beam@v1 with matrix.elixir and matrix.otp;
3 actions/checkout@v4 repository version2beta/dwrr-spec, ref
8a0e3cf9ae860ba207213590c00feeb822bdd8f2, path dwrr-spec (sibling);
4 `mix local.hex --force && mix deps.get --check-locked`;
5 `mix format --check-formatted`;
6 `mix compile --warnings-as-errors`;
7 `mix test --warnings-as-errors --no-color`;
8 external replay command from Part1;
9 external check_driver command from Part1.
No if/continue-on-error/extra run step or bypass. Configuration checks are NOT
hosted CI execution nor proof the minimum toolchain is compatible.

## 2.9 Final gate (T29)

Formatting, warnings-as-errors compilation, full tests including all preparation
assets, external replay and protocol checker. Installed Elixir1.20.4 exact summary
`Result: 97 passed (8 properties, 89 tests)` plus both exact historical external
PASS lines. Earlier counts remain unchanged. Unchanged loop --check must reject
every NEW task on delivered stubs for missing behavior and pass EVERY task on the
private reference including final gate. Preparation runs no coder/model loop,
commits/staging/push/publication/installed-skill changes. Runtime minimum unavailable
is an explicit gap, not a fabricated success. Parent review remains required.
