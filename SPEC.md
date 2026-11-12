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
