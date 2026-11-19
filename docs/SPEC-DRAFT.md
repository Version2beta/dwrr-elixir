# dwrr-elixir — approved specification draft; implemented checkout

**Current source status:** core, driver, Server, public docs and metadata are
implemented; intended 0.1.0 remains unpublished. Preparation/stub statements below
are historical evidence boundaries, not descriptions of the delivered source.
Pinned fixtures/CI retain shared `8a0e3cf` provenance; working-tree shared
consistency corrections are described in the root README/SPEC without repinning.

**Historical preparation status:** owner stage-1 loop completed at audited HEAD `7205252`;
local stage-2 preparation is authorized, not a stage-2 coder/model loop. Binding
stage-2 contracts are numbered Part 2 of `../SPEC.md`. See
[STAGE2-VERIFICATION.md](STAGE2-VERIFICATION.md) for current executed evidence
and [SPEC-LOOP-SHAKEDOWN.md](SPEC-LOOP-SHAKEDOWN.md) §12–13 for the original
owner loop versus this delegated preparation. Historical stage-1 framing and
preparation claims below describe their original phase, not current status.
No commits, staging, remote actions, publication or installed-skill edits are
authorized in this preparation. Repository/package names and Server details are
now settled (§16); no design decision remains open for this kit.

## 1. Approved framing

**Target/outcome:** Elixir application authors sharing one consumer among producers get a pure, cost-aware FIFO scheduler that allocates service by queue weight and conforms exactly to dwrr specification 0.1.1.

Name/repository: `dwrr-elixir`; Mix application `:dwrr`, module `Dwrr`, initial release `0.1.0`. Approved repository https://github.com/version2beta/dwrr-elixir and Hex name dwrr; publication still requires owner control/authority verification. This is a library with a small deterministic conformance-driver executable, not the skill's usual standalone CLI product.

### Goals

- Exact shared behavior for all SPEC §5 operations, §6 errors, §2 limits, and service order, including mutations during paused visits.
- Immutable, opaque scheduler values; no hidden process, ETS, Agent, mutable global state, or runtime dependency.
- `:queue` FIFO storage, sparse nonempty-queue selection, and exact direct idle-round calculation: maximum legal cost with quantum 1 must be practical.
- Stage 1 usable core, all seven corpus files natively and by external replay, focused §5 units.
- Stage 2 independently checked properties, minimal explicitly supervised `Dwrr.Server`, and publication-quality docs/metadata/CI. Cut Server first if stage 2 exceeds budget.

### Non-goals

Executing work, blocking dequeue, producer wakeups, bounded mailboxes/queues, priority or keyed queues, admission control, persistence, distributed fairness, wall-clock fairness, runtime model calls, configuration/credential machinery, or a general CLI. Caller declares costs and manages execution. Queue indices are positions, not permanent IDs; only the last queue can be removed, and its index can be reused.

## 2. Architecture

```text
application caller ──operation──> Dwrr (pure) ──> operation-specific result (§3)
                                   │
                                   ├── map indexed queue records
                                   │     quantum, credit, :queue of items
                                   └── cursor + active + count + item total
                                         + ordered nonempty-index set

stdin JSONL -> test/dev driver -> Dwrr -> exact JSONL stdout
                  │                         diagnostics -> stderr
                  └── built-in JSON (Elixir >=1.18, OTP >=27; no Jason)

Stage 2 (first cut if over budget):
caller -> GenServer.call -> Dwrr.Server -> Dwrr pure operation
                                owns one scheduler; explicit supervision

Tests: shared corpus + §5 units -> core
Stage 2: independent naive reference + StreamData -> core
External: unchanged dwrr-spec/tools/replay.py -> driver -> core
```

Pure calls coordinate nothing: callers must thread the successful returned scheduler into the next call; on `{:error, code}`, retain the input scheduler. Branching old immutable states is supported. BEAM terms are opaque values returned unchanged (`===`); a PID/reference inside a value still refers to external state, which the scheduler neither owns nor protects. No scheduler I/O or logging. The driver owns stdin/stdout and its one scheduler. Server owns its current scheduler and serializes complete operations while replying with the unchanged core return, including scheduler values on success (§9).

## 3. Approved public data and result contract

Opaque `%Dwrr{}` with `@opaque t(value)` and documented types. Items are `%Dwrr.Item{value: term, cost: pos_integer}`; results are `%Dwrr.Scheduled{queue: non_neg_integer, value: term, cost: pos_integer}`. Validation also accepts integer zero and above-limit costs/quanta to return the specified shared domain errors.

| Call | Successful return (`s2` is updated scheduler) | Error return |
|---|---|---|
| `Dwrr.new(count)` | `s2` with count empty queues | outside-domain `ArgumentError` |
| `Dwrr.enqueue(s, queue, items)` | `{:ok, s2}` | `{:error, :invalid_index}`, then first invalid item's `:zero_cost` or `:cost_too_large` |
| `Dwrr.take(s, n)` | `{:ok, scheduled_items, s2}` in service order | `{:error, :negative_take}` |
| `Dwrr.set_quantum(s, queue, quantum)` | `{:ok, s2}` | `{:error, :invalid_index}`, then `:zero_quantum` or `:quantum_too_large` |
| `Dwrr.add_queue(s)` | `{new_index, s2}`; index is old count | none |
| `Dwrr.remove_queue(s)` | `s2`; removed items discarded | none |
| `Dwrr.remove_head(s, queue)` | `{:ok, item_or_nil, s2}` | `{:error, :invalid_index}` |
| `Dwrr.drain_queue(s, queue)` | `{:ok, items, s2}` in FIFO order, possibly `[]` | `{:error, :invalid_index}` |

All scheduler failures are `{:error, code}` without a scheduler; input state remains unchanged and usable. All six shared codes (`invalid_index`, `negative_take`, `zero_cost`, `cost_too_large`, `zero_quantum`, `quantum_too_large`) are atoms in core and exact strings on the wire. No new shared codes. Empty-head `nil` is unambiguous even for a stored `nil` value because a present item is a struct. Validate an entire enqueue batch before append; no partial scheduler escapes on error.

Example threading:

```elixir
s = Dwrr.new(1)
{:ok, s} = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :work, cost: 1}])
{:ok, [%Dwrr.Scheduled{queue: 0, value: :work, cost: 1}], s} = Dwrr.take(s, 1)
{1, s} = Dwrr.add_queue(s)
s = Dwrr.remove_queue(s)
```

### Documented Elixir domain

Count is a nonnegative integer; index and take limit are integers (negative/out-of-range index yields `invalid_index`; negative limit yields `negative_take`). Cost and quantum validation inputs are nonnegative integers; above-limit integers yield the shared errors. Enqueue accepts a proper list of Item structs with arbitrary values. Scheduler inputs must be valid opaque states produced by the API; malformed/forged states are outside the contract.

Inputs outside documented types/shapes raise `ArgumentError`, including negative/noninteger costs/quanta, noninteger index/n, malformed items and negative/noninteger count. Use guards where possible **with explicit fallback clauses raising `ArgumentError`**: guards alone would leak `FunctionClauseError`. Type/shape validation is distinct from shared scheduler domain-error precedence; no new local/shared error codes. Valid zero/oversized costs/quanta still undergo index-first scheduler validation. Existing valid state remains usable after an error or exception. No arbitrary allocation cap on valid counts; resource exhaustion is a resource failure, not a fabricated shared error. Precedence among multiple simultaneous outside-domain Elixir faults is not otherwise specified.

## 4. Binding shared semantics to preserve

The following preserves shared scheduling semantics under the approved Elixir representation and error contract:

- Count zero: cursor 0, inactive; otherwise cursor is in range. Empty queues have credit 0. Active implies cursor queue nonempty.
- New queues: quantum 1, credit 0. `new` replaces the driver's scheduler. Add appends without changing cursor/active. Remove drops only the last queue. If active on that last queue, cancel visit and set cursor 0; after removal, zero count means cursor 0, otherwise an out-of-range cursor becomes cursor modulo new count. Empty removal is a no-op.
- Enqueue checks index even for an empty batch, then checks costs in order. Any error rejects the whole batch. Items join an active visit without another grant.
- Set quantum checks index, then zero, then too large. It never changes credit or active state; a new quantum applies at the next grant. Setting the same value is a no-op.
- Remove head does not schedule or debit it. Empty return is a no-op. If items remain, keep credit and active. If it empties the queue, reset credit; close and advance a visit only if this queue was active.
- Drain returns every item FIFO, resets credit, and closes/advances an active visit on that queue. Draining an empty inactive queue keeps cursor.
- Take validates negative `n` first. `take(0)` preserves all state and returns `[]`. Zero queues/all empty returns `[]` without moving an already empty scheduler's cursor.
- On a nonempty inactive cursor queue, add exactly one quantum and activate the visit. Serve the FIFO head if and only if `credit >= cost`; debit exactly. An unaffordable head closes the visit and advances, even if later items are cheap. Emptying resets credit and closes/advances. Reaching retrieval limit while items remain preserves the active visit, even if its next head will be unaffordable. Resume without a fresh grant.
- Take returns fewer than requested only when every queue is empty; results contain source index, unchanged value, unchanged cost. Fairness is in declared cost, not item count or execution time.

### Numeric contract (mandatory even with BEAM big integers)

`MAX_COST = MAX_QUANTUM = 9_223_372_036_854_775_807` (2^63−1). Accept every integer 1 through the limit, reject zero and every integer above the limit with the shared errors in precedence order. Use only exact integer addition, subtraction, multiplication, `div`, and comparisons; never float division/ceil, saturation, wrapping, or rounding. Credit must remain in 0 through `18_446_744_073_709_551_613` (2^64−3). Costs are fixed on acceptance. No reduced safe-integer limit at 2^53. Wire inputs through 2^64−1 include values above the scheduler limit and must receive scheduler errors, not a JSON overflow error.

Proof of bound: closing an unaffordable visit leaves credit < head cost ≤ MAX_COST; emptiness resets credit; removals/reweights do not increase it. A new visit grants ≤ MAX_QUANTUM, so peak credit is MAX_COST−1+MAX_QUANTUM. This peak is reachable after reweighting and exposing a cheaper head; test it rather than inferring safety from arbitrary-precision arithmetic.

## 5. Exact idle rounds and sparse traversal

Idle-round calculation occurs **only after a complete unproductive cycle**, as in the Go Take strategy, not before every grant. Use local per-take progress accounting; no persistent round synchronization or round counter. No external enqueue, removal, reweight or other mutation can interleave within a pure take.

### Trigger and accounting proof

Initialize a local consecutive failed-closed-visit count to zero on each take. Resume an active entry visit with its existing credit, without a new grant or skip. Whenever an unaffordable head closes a visit with no service, increment the count. This includes a resumed active visit that blocks without receiving a grant. Reset the count on **every item served**, including when service empties a queue. If service leaves a visit active, later failure of that visit starts the next failed-visit sequence. Never count an empty-queue bypass as a failed busy visit.

Let B be the current number of busy (nonempty) queues. During consecutive failed visits there is no service and no interleaving external mutation: membership, heads, quanta and B are stable. Cyclic successor selection visits each of these B queues exactly once before repetition. Thus only when B > 0, the count reaches B and the last failed visit has closed (`active = false`) have **all B heads been observed strictly above their current credit**. No later visit in that sequence changes an earlier queue's credit. A resumed blocked queue is a valid observation even without a grant: the trigger proves unaffordability, not that every observed visit had a grant. Do not skip early on B−1 failures, a cursor wrap, or merely becoming inactive. Reset the local count after the calculation as well as after service. B can change only on service inside take, which resets the accounting. This handles arbitrary active-entry and nonzero-cursor states without inventing persistent round boundaries.

### Exact calculation after the actual failed cycle

For every busy queue i let `h_i` be its head cost, `d_i` its credit **after that actual failed cycle**, and `q_i > 0` its quantum. The trigger establishes `h_i > d_i`. Compute:

```text
skip = min_i div(h_i - d_i - 1, q_i)
```

Add `skip * q_i` to each busy queue's credit when skip > 0. Preserve all heads/items, quanta, the next cyclic cursor and `active = false`. If a defensive check finds any affordable head, do not skip; it signals that the trigger proof must be rechecked. There is no pre-grant scan on ordinary visits.

For every `1 <= j <= skip` and every busy i, `d_i + j*q_i < h_i`. Consequently each skipped cycle would grant once per busy queue, fail affordability, close every visit, and return to the same next cyclic cursor inactive. Empty queues have zero credit and are bypassed without N-slot scans. No skipped cycle serves an item or changes membership. Conversely, in cycle `skip + 1` at least one head becomes affordable: this is the exact maximum number of complete **strictly unaffordable** cycles, not an estimate of when to serve. Run that potentially productive cycle normally, preserving cyclic order and ties; never pick the minimum-cost or minimum-index head. Each skipped addition is ≤ `h_i - 1 - d_i`, so it neither makes a head eligible nor violates the credit bound.

A prior `remove_head` may expose an already-affordable head. The next take must execute/resume visits normally; service resets accounting, and only a later full failed cycle permits a scan. Arithmetic uses the actual post-failure credits, not pre-cycle credits. Local trigger details need not duplicate Go's grant counter; the observed failed-visit proof above explicitly covers resumed visits without grants.

**`newRound` terminology:** shared SPEC has `active`, not a `newRound` state field. Use the single persistent `active` flag. Any local “needs grant” name means `not active`, never “cursor crossed zero”; skipping preserves inactivity. No duplicate persistent synchronization state.

### Data structures and honest per-operation costs

Use a persistent **map indexed by queue integer** for queue records, not `:gb_trees`. Let N be queue count, B busy count, K enqueue batch length, L the addressed queue length, R returned item count, V ordinary busy visits and C full-unproductive-cycle calculations during a take. Write logarithms below as `log(2 + size)` to cover empty/singleton cases. BEAM maps use representation-dependent small-map/HAMT behavior; use conservative O(log N) lookup/update/insert/delete bounds, not a portable O(1) guarantee or a balanced-tree claim.

- Each map record stores quantum, credit, maintained item count, Erlang `:queue` and cached head cost/item. FIFO enqueue/dequeue and cache refresh are amortized O(1) along a linearly threaded evolving history; a rear-list reversal/refresh can cost O(L). Repeated peeks without dequeue must use the cache, not repeatedly pay O(L). Persistent branches can repeat those costs. Never claim no BEAM allocations or Go slice reuse. Do not call `:queue.len/1` per item.
- Retain ordered nonempty-index `:gb_sets`, with successor-at-or-after-cursor and wrap in O(log B), verifying minimum-OTP iterator support. Maintain membership on empty/nonempty transitions; use counts/set emptiness, not a scan of all N queues. Empty queues earn no credit.
- `new/1`: conservative O(N log N) construction by map insertion, O(N) retained records (a verified bulk-build may improve construction, but is not assumed).
- `add_queue/1`: O(log N), empty record insertion; no busy-set change.
- `remove_queue/1`: O(log N + log B) bookkeeping, independent of discarded L; no item list is materialized. Reclamation/GC and retained snapshots are separate costs.
- `enqueue/3`: O(K + log N + log B) amortized including full validation, FIFO append and possible busy insertion. Empty batch still checks index.
- `set_quantum/3`: O(log N), unchanged FIFO/credit/membership.
- `remove_head/2`: O(log N + log B) amortized, worst-case extra O(L) reversal/cache refresh. Empty lookup O(log N).
- `drain_queue/2`: O(L + log N + log B), including FIFO result materialization; no scheduling.
- `take/2`: O((V + R)(log N + log B) + C B_max log N + R) amortized, where B_max is the largest busy count during the call; each actual scan/update is O(B_current log N) and O(B_current) temporary storage at most. These scans occur once per **full unproductive cycle**, never once per grant. Post-skip ordinary execution serves within at most B_current busy visits; repeated service resets accounting. A coarse magnitude-independent bound for R > 0 is O((R + 1) B_max (log N + log B_max) + R); zero/negative/all-empty takes require no queue scan. Direct arithmetic removes dependence on the numeric number of idle cycles, not on busy queues/items.

Integer arithmetic is exact; bit complexity is not literally constant, though scheduler credit/cost/quantum operands are bounded by §2. Outside-domain arbitrary-size inputs also have validation costs. Take accumulates reversed results and reverses once; never allocate proportional to untrusted n. Retained storage is O(N + queued items), plus results/temporary traversal and structurally shared old versions. Old snapshots retain data until released; no secure erasure. Performance claims remain obligations to measure, especially sparse N and huge skips, not benchmark evidence.

## 6. Driver and approved JSON/protocol contract

Driver is dev/test tooling only, not a runtime library API. Planned path `scripts/conformance_driver.exs`. Use **Elixir >=1.18, OTP >=27 and built-in JSON; no Jason**. From the **dwrr-elixir repository root**, after separately authorized setup, planned exact build/replay commands are:

```sh
MIX_ENV=test mix compile --warnings-as-errors
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

`../dwrr-spec` denotes the sibling pinned checkout at `8a0e3cf9ae860ba207213590c00feeb822bdd8f2`. CI must fetch/locate that exact revision explicitly, not silently use main or a mutable tag. The replay command starts one driver process and uses upstream corpus by default. Both tool commands have passed on the private reference, not on the delivered stubs. Build first so compilation messages cannot contaminate stdout. The complete protected CI places pinned dwrr-spec at the same sibling path.

### Required protocol behavior

- Read UTF-8, one JSON object per input line; output exactly one compact JSON object and newline per valid request, nothing else on stdout. Flush after **every** response. A pipelined bulk replay alone does not prove flushing: add a handshake test that waits for response before sending the next request.
- EOF exits 0. Malformed JSON/shape, unknown op, or a request before first `new` prints a non-sensitive diagnostic to stderr and exits **2**. No scheduler-error response for protocol failures; no extra stdout line. Blank lines are protocol failures (exit 2), not skipped.
- Scheduler errors emit `{"error":"code"}` and continue; state remains unchanged. A second `new` replaces the held scheduler.
- `cost` and `quantum` are decimal **strings**, including returned costs. Require the full-string canonical decimal grammar `0|[1-9][0-9]*`: no signs, whitespace or leading zeros. Parse exact integers in wire range 0..2^64−1; outside that range is protocol failure. Zero/above-scheduler-limit but in-wire-range integers reach scheduler validation. Index/count/n and item values are JSON integer numbers, not floats/strings; required corpus range −2^31..2^31−1. No coercions; the corpus range is not a protocol magnitude cap (see the clarification below).
- Validate **all required protocol types, shapes, syntax and wire ranges before any scheduler validation**, including every item in a batch. Missing required fields fail; extra fields are ignored. Duplicate JSON keys are unspecified. Only after parsing succeeds apply shared scheduler precedence: an invalid index beats a parsed zero/oversized cost or quantum. Example: invalid index plus cost `"0"` yields `invalid_index`; invalid index plus cost `"01"`, a numeric cost, malformed item shape or out-of-wire-range cost exits 2 without a scheduler response. This is protocol-first parsing, not cost-before-index scheduler validation.
- `new`, `enqueue`, `set_quantum`, `remove_queue`: `{"ok":null}`; add: `{"ok":new_index}`; remove-head: `{"ok":null}` or `{"ok":{"value":v,"cost":"c"}}`; drain: `{"ok":[{"value":v,"cost":"c"},...]}`; take: `{"ok":[{"queue":q,"value":v,"cost":"c"},...]}`. Empty collections are `[]`, not null. Values are unchanged integer JSON numbers on the wire, even though core accepts any term.
- Compare parsed JSON exactly; whitespace/key ordering irrelevant; strings versus numbers distinct. Reject invalid UTF-8 and nonobjects without a crash stack trace containing payloads. No dynamic atom creation from untrusted op/error/keys; use fixed dispatch strings and fixed atoms.

Test built-in JSON exact encode/decode behavior at the stated minimum toolchain, not only a newer local runtime. No runtime JSON dependency or hand-written parser. StreamData is permitted test-only in stage 2; dependency constraint/lock remains future authorized work. The recorded local Elixir 1.20.4/OTP 29 is not evidence of minimum compatibility; no dependency setup was performed here.

PROTOCOL 0.1.1 §3.1 settles negative constructor count as a protocol error. The driver accepts arbitrary JSON integer magnitudes without adding a new wire limit on indexes/n/values/count, and imposes no new line-size cap; resource exhaustion is not a shared scheduler error. Duplicate-key behavior remains unspecified. Built-in JSON and protocol-first validation were exercised against both upstream tools on the reference; minimum-version compatibility is still unverified.

## 7. Conformance and testing plan

Stage 1 vendors byte-for-byte corpus records into protected `test/fixtures/dwrr-spec/corpus/` with upstream LICENSE, SPEC/PROTOCOL version, git SHA, original file hashes, seeds and generator provenance recorded. No regeneration or expected-response rewriting. All 1,839 cases / 44,728 steps / seven files must run as **native ExUnit core calls**, not only through the driver; each file gets positive expected-case/step counts so a missing glob cannot pass. State-preservation errors are followed by valid operations; error-only tests cannot stand in for must-succeed coverage. Native executor does not call the Python model or Go.

Focused units cover all §5 branches, arbitrary Elixir values, exact affordability equality, paused visits and joining enqueue, batch precedence/atomicity, set-quantum preservation, remove/drain emptying and nonempty branches, queue deletion cursor wrap, take zero/negative/zero queues, FIFO, sparse traversal, direct-skip ties and nonzero cursor, huge skip after active entry, peak credit and every §2 boundary. Behavior tests cover resumed blocked visits, reset-on-service and cyclic ties; reduction-count tests bound sparse traversal and productive grants without an all-busy scan per grant. The exact B-failure trigger is additionally a source-review obligation, not proven solely by output equality. Assert shared invariants after operations through an agreed protected test seam, without publishing representation as API. External unchanged replay must independently report `PASS: 1839 cases, 44728 steps, 7 files`.

Stage 2 writes an **independent naive Elixir reference** in test support, not using production helpers, `:queue`, skip arithmetic or nonempty index. StreamData generates small mixed valid/invalid sequences and checks every result/error/state invariant, FIFO conservation, splitting take equivalence, deterministic replay, and nonstarvation under reweights. Shrink failing operations and print reproducible seeds/traces without logging arbitrary real payloads.

Near-limit properties use large quanta (e.g. >=2^62), bounded queue/items/operations, to let a truly naive reference finish. Huge-cost/quantum-1 cases must NOT be fed into an unbounded naive loop: keep analytic boundary fixtures/shared corpus, bounded-step reference domains, and explicit time/work caps. Never share optimized skip code with the reference to hide the explosion. Include cases just below/at/above MAX limits and full 2^64−3 credit. StreamData test-only is allowed; no runtime deps.

After any formatting write, rerun the exact judge on the resulting code; a pre-format pass is insufficient. Final task of each stage is whole-tree: `mix format --check-formatted`, `MIX_ENV=test mix compile --warnings-as-errors`, `mix test --warnings-as-errors` (verify supported flags at chosen floor), and both external tools' exact PASS lines. Each nonfinal task runs one file with its exact installed ExUnit `Result: N passed` expectation, colors disabled; the final task requires `Result: 66 passed`. The unchanged loop's own --check verified every expectation on the reference.

## 8. Approved two-stage build order

Stage 1 was realized as 22 tasks. Current tasks.json retains T01–T21 and replaces the old final T22 with seven NEW stage-2 tasks T22–T27 and T29 (deliberate T28 gap: CI is complete/protected); the owner explicitly approved this exception to the 15-task minimum. All 22 stage-1 tasks passed on the private reference under loop --check and failed on delivered stubs. Every task has nonempty exact stdout expectations; no legacy pass_marker is used. Whole-tree must remain last. Tests, fixtures, contracts, driver seams, and judge glue may be protected complete files; don't create fake coding tasks for already-complete artifacts.

### Stage 1 — usable pure scheduler and exact conformance (22 tasks)

1. Constructor `new/1` returning scheduler struct, typed-domain exceptions, zero/count cases and initial invariants.
2. Queue lookup/index-error precedence across existing APIs.
3. `set_quantum/3`, numeric bounds, unchanged state and next-grant behavior.
4. `enqueue/3` batch validation, ordered errors and atomic append.
5. FIFO opaque-value acceptance and empty-batch behavior.
6. `add_queue/1`, stable existing indices and count-zero recovery.
7. `remove_queue/1`, inactive/active-last removal and cursor repair.
8. `remove_head/2`, empty/nonempty remainder and active emptying.
9. `drain_queue/2`, FIFO result, reset and active closure.
10. Basic `take/2` grant/debit/affordability equality and blocked FIFO heads.
11. Take zero/negative/empty behavior and unchanged-state contracts.
12. Paused visit continuation; retrieval limit is not a fairness cap.
13. Mid-visit enqueue and reweight semantics.
14. Full-unproductive-cycle trigger and exact idle-round skipping, resumed blocked visit, reset-on-service, nonzero cursor, ties and already-affordable heads.
15. Huge skips and peak credit with all shared numeric limits enforced.
16. Nonempty index maintenance and sparse traversal without N-empty scans.
17. Native small corpus files: examples (2 cases, 15 steps), edge cases (20, 225), errors (10, 70) with continuation/state preservation, and boundaries (7, 53); per-file count guards.
18. Native random corpus files: random-small (1,000 cases, 23,659 steps), random-large (500, 13,933), random-skip (300, 6,773); per-file/all-file provenance and count guards. Tasks 17–23 of the original plan are consolidated into these two units, preserving all seven upstream files byte-for-byte.
19. Driver operation/result translation with built-in JSON, exact canonical decimal strings.
20. Driver framing, protocol-first validation, subprocess handshake/flush, protocol exit 2 versus continuing scheduler errors.
21. Driver independent external corpus replay, root command and minimal usable core docs/examples/types.
22. FINAL whole-tree: formatted, compile warnings-as-errors, all 66 tests, unchanged replay `PASS: 1839 cases, 44728 steps, 7 files` and check_driver `PASS: 36 of 36 checks passed`.

Stage 1's deliverable is a usable pure library with the approved API and reproducible conformance driver, not only a test scaffold.

### Stage 2 — seven current cohesive tasks, not 25 artificial slices

Protected complete preparation assets: independent list-based bounded naive
reference, eight StreamData properties, three oracle anchor tests, provenance and
public executable-AST guards, authorized helper-overlay hash and complete CI
with one byte-identity test. These are not implementation tasks.

1. T22 minimal Server initialization, all operations, serialization and failures.
2. T23 public documentation/typespecs/executable examples, frozen executable AST.
3. T24 README structure, meaningful executable examples and exact owner commands.
4. T25 TESTING inventory, bounded domains, diagnostics and reproduction.
5. T26 CHANGELOG initial0.1.0 plus owner-controlled RELEASING procedure.
6. T27 Mix identity/metadata, exact package manifest and no runtime dependency.
7. T29 final whole tree, 97 checks including eight properties, both external tools.

T28 is deliberately absent. Complete protected ordinary YAML CI targets
1.18.4/27.3 and 1.20.4/29.1.2, pinned sibling replay AND protocol checker.
setup-beam listings are verified; minimum runtime and hosted CI remain unexecuted.

Every new task fails delivered stubs and passes private reference under unchanged
loop --check; earlier task commands/counts remain unchanged. See current evidence.

## 9. Minimal Server (stage 2; first budget cut)

Pure core is the default with no running application children. The minimal wrapper offers `start_link` plus one `GenServer.call` per operation; no cast/batch/retry layer or custom timeout machinery. Use default GenServer call timeouts. Each operation performs one pure transition. Reply with the **exact core return unchanged**, including scheduler values on success. Reply snapshots do not replace process ownership: callers must use Server operations for authoritative shared state; branching a returned immutable scheduler is a separate pure history.

The driver and Server must store state according to the differing core shapes, not assume a uniform scheduler-first pair:

| Core result | State to store | Server reply |
|---|---|---|
| `new/1` → `s2` (initialization) | `s2` | initialization uses normal `start_link` result |
| `add_queue/1` → `{index, s2}` | `s2` | `{index, s2}` |
| `remove_queue/1` → `s2` | `s2` | `s2` |
| `enqueue/3`, `set_quantum/3` → `{:ok, s2}` | `s2` | `{:ok, s2}` |
| `take/2`, `remove_head/2`, `drain_queue/2` → `{:ok, value, s2}` | `s2` | `{:ok, value, s2}` |
| Any `{:error, code}` | prior scheduler unchanged | `{:error, code}` |

The driver's separate wire translation uses the same state-extraction rules, including replacing its state on `new`; it does not expose core scheduler structs on the wire. Server replies are deliberately **not** stripped of scheduler state. No snapshot API is needed just to access an already-returned immutable value.

Concurrent calls serialize in mailbox arrival order, not promised order across senders. A timeout does not prove the operation was not applied: no retries or idempotence guarantee. No task execution, wakeups, backpressure or persistence. Supervision is caller-owned; no implicit global scheduler. `start_link(count, options \\ [])` forwards standard GenServer options. Caller-owned restart starts fresh from original count; core outside-domain exceptions terminate Server and caller sees call exit. Default GenServer timeouts/no retry; no new validation/error scheme. These details are approved, not open.

## 10. README/documentation and release requirements

README first line must be **`# dwrr-elixir`**. Adapt Go README's structure: introduction; The need; At a glance (0.1.0, chosen language floor, license, install, repository, API docs); Quick start; Examples (bandwidth by bytes, worker loop, withdrawing work); Behavior worth knowing (queues/items, scheduling, take, limits/errors, mutations, storage/immutability, concurrency); How we know it's correct and Check it yourself; How it compares; Colophon. Show operation-specific successful state threading from §3 and retention of the input scheduler on tagged errors, not uniform scheduler-first pairs or mutable Go-style calls. Worker examples must not imply the pure core coordinates callers. Comparisons must be verified or clearly limited; do not transplant time-sensitive Go claims.

TESTING, CHANGELOG 0.1.0, RELEASING, complete public docs/types, Mix metadata (name/version/description/license/links/files), MIT copyright 2026 M. Robert Martin, and CI tests plus external replay are stage-2 requirements. No fake package/repository URLs; confirm owner-controlled names. Publishing, tagging, commits, remote mutation and credentials are future owner actions, not authorized preparation work.

## 11. Configuration, privacy, failures and skill adaptations

No library configuration files, environment precedence, credentials, `doctor`, model prompt/pipeline, telemetry, home-directory reports, or model calls apply. Do not build any. The skill's “writes only under its own home directory” rule is a runtime tool constraint; this library performs no writes, and its explicit test/dev tooling works in the test checkout/stdio. It must not create reports in caller projects or at home. Stage-1 preparation now adds the kit's contracts, tests, fixtures and stubs; original framing/draft history is retained in the shakedown ledger. Private reference source is outside the kit.

Core errors preserve state and are returned once, without logging. Driver diagnostics go only to stderr, identify category/field without echoing item values or a whole JSON line. Wire inputs are untrusted: bounded tests must cover malformed messages, no dynamic atoms, and exact numeric conversion. Oversized input/resource-limit behavior needs a documented owner-approved policy; no arbitrary valid-input rejection can masquerade as conformance. A GenServer mailbox is not backpressure. Immutable snapshots retain values, and arbitrary caller values may contain sensitive data; do not log them by default.

## 12. Viability experiments and current evidence

1. Installed 1.20.4 ExUnit success/failure summary checked; all actual task expectations passed under the unchanged judge. Every delivered stub test failed; colors disabled. No custom formatter or marker strategy was needed.
2. Tiny JSON adapter round-trip at chosen minimum toolchain: costs 0, 2^53+1, MAX, MAX+1 and 2^64−1 as strings; integer values exact; interactive pipe handshake proves flush and protocol error exit 2. No network needed after approved dependency resolution.
3. Private reference exercises §5 units, active entry, exposed cheaper head, nonzero cursor/ties and maximum-cost/quantum-1; all native corpus records and external replay pass. Source trigger proof is in §5.
4. Small sparse queue prototype to measure N=10,000 with B=1 versus B dense; check ordered successor support on minimum OTP. Do not promise Go allocation/performance parity.
5. Hand fixture returned all three exact responses with exit 0. Full verification is recorded separately; no actual coder/harness/provider validation is inferred.

## 13. Kit verification gate

Owner cleared the preparation hold after skill fixes. Stage-1 results are recorded in STAGE1-VERIFICATION.md: every task passes under unchanged loop --check on the private reference; every task fails on stubs; all 66 stub tests fail individually, including corpus/error tests; both external tools pass on the reference. The planted <= affordability bug fails all four small-file native corpus tests and external replay, and was restored before a clean whole-tree rerun. Every expected test must be present, not merely a green aggregate. Stage 2 overlay must be tested on the owner's **actual stage-1 loop-written build**, preserving all earlier tests/tasks (replace old whole-tree task rather than leaving it mid-list). Plant affordability `<` → `<=` in a disposable authorized target copy; both native tests and unchanged external replay must catch it. Run a fixture by hand with the real driver. Review protected-path patterns against tests, fixtures/provenance, contracts, complete files, judge glue, spec, tasks and loop; check tracked and new files and review resulting diffs for special casing. Do not mutate either source repository for any test.

Only after verified kit and owner's separate clean-branch/commit/spending authorization does the **owner** run loops on branches, then return for strong-model review. No loop now; no implicit commits now. Copy installed loop unchanged unless owner approves a skill-level correction; any workaround in kit settings needs its own exactness proof.

## 14. Approved Elixir mapping (now also in sibling working-tree §11)

The historical preparation made no upstream edit. The consistency correction now adds this approved Elixir column to the sibling working-tree SPEC §11, retaining Go; the vendored historical source pin remains unchanged:

| Operation | Elixir (`Dwrr`, dwrr-elixir) |
|---|---|
| `new(count)` | `new/1` → scheduler struct |
| `enqueue` | `enqueue/3` → `{:ok, scheduler}` or `{:error, code}`; invalid_index / zero_cost / cost_too_large |
| `set_quantum` | `set_quantum/3` → `{:ok, scheduler}` or `{:error, code}`; invalid_index / zero_quantum / quantum_too_large |
| `add_queue` | `add_queue/1` → `{index, scheduler}` |
| `remove_queue` | `remove_queue/1` → scheduler |
| `remove_head` | `remove_head/2` → `{:ok, item_or_nil, scheduler}` or `{:error, :invalid_index}` |
| `drain_queue` | `drain_queue/2` → `{:ok, items, scheduler}` or `{:error, :invalid_index}` |
| `take` | `take/2` → `{:ok, scheduled_items, scheduler}` or `{:error, :negative_take}` |
| `invalid_index`, `negative_take` | tagged atom errors; caller retains unchanged input scheduler |

Item and Scheduled are structs. Outside documented Elixir types/shapes raise `ArgumentError` via guards plus explicit raising fallbacks; no added shared error codes.

## 15. Decision record

Stage-1 approvals are preserved above. Stage-1 loop and post-loop audits are now
complete. Historical 25-task stage-2 slicing is superseded by the owner-approved
seven-task plan in §8 and binding SPEC Part 2 (historical eight-task preparation
was superseded when complete protected CI ceased to be a coder task). No protected test becomes a fake
coding task merely to meet a count. Core and driver implementation remain unchanged.

## 16. Stage-2 approval and evidence boundary

Approved: Server start_link(count, options \\ []) with forwarded standard options,
caller-owned supervision/fresh restart from count, exact core replies including
state, operation-shaped state extraction, default calls/timeouts/no retry,
terminate-on-outside-domain exception. No implicit child, persistence, execution
or backpressure. Release0.1.0, Hex dwrr/app dwrr, canonical repository
https://github.com/version2beta/dwrr-elixir; MIT2026 M. Robert Martin.

Approved dependency resolved: StreamData ~>1.3.0, locked1.3.0 only:test,
runtime:false; no runtime/documentation dependencies. No dependency updates by
coder. Writable lib/dwrr.ex is docs/@spec only, frozen rest-of-AST; source structs,
core/driver/parser and 41 original files remain unchanged/hash-guarded. The sole
authorized helper-only change sets assert_receive_timeout 1000ms; its original
SHA provenance and new protected overlay SHA are recorded separately. README,
release docs and Mix metadata are writable targets; CI is complete/protected.

Historically, preparation was sole-writer delegated implementation work under
explicit owner authority, not the original stage-1 owner's model loop. At that
preparation checkpoint private Server/docs implementation was outside the kit and
delivered Server/docs/metadata were stubs. They are now implemented in this
checkout; the following records historical preparation evidence only.
CI is identical, complete and protected in both trees. Only
installed Elixir1.20.4/OTP29 executed. Minimum1.18/27 and hosted CI remain unrun;
no runtime-install/Docker/model/provider inference or publication was done.
See STAGE2-VERIFICATION.md for exact stub/reference/mutation/package evidence.
Owner reviews and commits baseline before separately authorizing the stage-2 loop.
