# dwrr-elixir

Deficit weighted round robin (DWRR) scheduler for Elixir. The core is a set of
pure functions over immutable values. `Dwrr.Server` is an optional, caller-owned
wrapper that keeps one scheduler in one process.

Intended release: **0.1.0**, unpublished according to local release records.
The Hex package and application are `dwrr`.

## Other languages

- [DWRR for Go](https://github.com/version2beta/dwrr)
- [DWRR for Python](https://github.com/version2beta/dwrr-python)

These libraries share fixed-quantum scheduling semantics, with language-specific
APIs and additional features. See each library's README for its supported contract.

## Shared specification

[dwrr-spec](https://github.com/version2beta/dwrr-spec) defines the shared
[fixed-quantum contract](https://github.com/version2beta/dwrr-spec/blob/main/SPEC.md),
[conformance corpus](https://github.com/version2beta/dwrr-spec/tree/main/corpus)
and [driver protocol](https://github.com/version2beta/dwrr-spec/blob/main/PROTOCOL.md) /
[conformance tools](https://github.com/version2beta/dwrr-spec/tree/main/tools).
They let implementations with different APIs check the same service order,
errors and numeric limits rather than rely on similar-looking algorithms.
This is a development/conformance resource, **not a runtime dependency**.
Pinned revisions and vendored snapshots make checks reproducible; they do not
automatically track current spec source or establish all-sequences conformance.

This implementation targets the fixed-quantum core through immutable values;
`Dwrr.Server` and Elixir-domain validation are local API choices, not shared
requirements. Fixtures and the main CI retain historical revision
`8a0e3cf9ae860ba207213590c00feeb822bdd8f2`, rather than automatically following
upstream. Separate current-source checks must identify their revision and
results; see [TESTING.md](TESTING.md). The standalone example CI does not change
that historical conformance-tool pin.

## The need

When several queues share one resource, such as a link, a packet path or a job
pool, each queue should get a share in proportion to its quantum. DWRR does this
with small integer bookkeeping, and it measures work by the cost callers declare,
not by elapsed time. This library gives you that scheduler as plain values you can
store, branch and test.

## At a glance

- `Dwrr` is pure: no process, no I/O, no hidden state. Each successful operation
  returns a new scheduler value.
- `Dwrr.Server` is a serialized GenServer around one scheduler. You start and
  supervise it; the library starts nothing for you.
- Requires Elixir >= 1.18 and OTP >= 27. No runtime dependencies. StreamData is
  a test-only dependency.
- MIT licensed.

## Quick start

The intended dependency for release 0.1.0 is:

```text
{:dwrr, "~> 0.1.0"}
```

Local release records mark the package as not yet on Hex; this is an intended
install, not a verified public fetch. Until release, use a local checkout, for example:

```text
{:dwrr, path: "../dwrr-elixir"}
```

Adjust the path for your application. The core has no dependencies to fetch;
this repository's own tests additionally require StreamData.

## Examples

Each example is an independent history. Each one binds `result` to what the
operations actually returned.

### Byte sharing

Queue 0 has quantum 2 and queue 1 has quantum 3. Queue 0 serves `packet_a`, then blocks on
`packet_b`. Queue 1 cannot yet afford `packet_x` (cost 4), so it keeps its 3 credit.
Queue 0 then serves `packet_b`, and queue 1 serves `packet_x` and `packet_y`.

```elixir
s = Dwrr.new(2)
{:ok, s} = Dwrr.set_quantum(s, 0, 2)
{:ok, s} = Dwrr.set_quantum(s, 1, 3)

{:ok, s} =
  Dwrr.enqueue(s, 0, [
    %Dwrr.Item{value: :packet_a, cost: 2},
    %Dwrr.Item{value: :packet_b, cost: 2}
  ])

{:ok, s} =
  Dwrr.enqueue(s, 1, [
    %Dwrr.Item{value: :packet_x, cost: 4},
    %Dwrr.Item{value: :packet_y, cost: 1}
  ])

{:ok, served, _s} = Dwrr.take(s, 10)
result = Enum.map(served, &{&1.queue, &1.value, &1.cost})
```

Expected `result`:

```text
[{0, :packet_a, 2}, {0, :packet_b, 2}, {1, :packet_x, 4}, {1, :packet_y, 1}]
```

### Fair file-transfer simulation

The [standalone example](examples/fair_transfer/README.md) uses Basic/Team/Business
byte quanta of 1024/2048/4096 and repeated `take(s, 1)` calls. Its twelve pretend
records, selection order and cumulative totals match the Python example; the Go
README uses a different backlogged dataset. Final totals are Basic=5120,
Team=6656 and Business=12288 bytes: finite offered demand, not a promised 1:2:4
split. There is no real transfer I/O, timing, bandwidth pacing or preemption.
Use bounded chunks as items in a real sender for finer interleaving.

### Caller-owned worker orchestration

The `Server` only decides the order of jobs. It does not run them. The caller
receives the jobs and runs them itself. This example stops the server it started,
even if an operation fails.

```elixir
{:ok, server} = Dwrr.Server.start_link(1)

result =
  try do
    {:ok, _scheduler} =
      Dwrr.Server.enqueue(server, 0, [
        %Dwrr.Item{value: :job_a, cost: 1},
        %Dwrr.Item{value: :job_b, cost: 1}
      ])

    {:ok, served, _scheduler} = Dwrr.Server.take(server, 2)
    Enum.map(served, & &1.value)
  after
    GenServer.stop(server)
  end
```

### Pure withdrawal

`remove_head/2` withdraws the first item without spending credit. `drain_queue/2`
then withdraws the rest in FIFO order.

```elixir
s = Dwrr.new(1)

{:ok, s} =
  Dwrr.enqueue(s, 0, [
    %Dwrr.Item{value: :cancelled, cost: 5},
    %Dwrr.Item{value: :kept, cost: 1}
  ])

{:ok, cancelled, s} = Dwrr.remove_head(s, 0)
{:ok, kept, _s} = Dwrr.drain_queue(s, 0)
result = {[cancelled.value], Enum.map(kept, & &1.value)}
```

### Atomic error

Enqueue checks every item before it adds any. The valid item is not kept when the
zero-cost item fails. A later `take` on the original scheduler returns nothing.

```elixir
s = Dwrr.new(1)

result =
  Dwrr.enqueue(s, 0, [
    %Dwrr.Item{value: :valid, cost: 1},
    %Dwrr.Item{value: :invalid, cost: 0}
  ])

{:ok, [], _s} = Dwrr.take(s, 10)
```

## Public API

`Dwrr.new(count)` creates `count` empty queues (zero is valid), each with quantum
1 and credit 0. `%Dwrr.Item{value: value, cost: cost}` is the enqueue record;
`take/2` returns `%Dwrr.Scheduled{queue: index, value: value, cost: cost}` records.

| Operation | Successful result |
| --- | --- |
| `enqueue(s, index, items)` | `{:ok, scheduler}` |
| `set_quantum(s, index, quantum)` | `{:ok, scheduler}` |
| `add_queue(s)` | `{index, scheduler}` |
| `remove_queue(s)` | `scheduler` (unchanged when no queues exist) |
| `remove_head(s, index)` | `{:ok, item_or_nil, scheduler}` |
| `drain_queue(s, index)` | `{:ok, items, scheduler}` in FIFO order |
| `take(s, n)` | `{:ok, scheduled_items, scheduler}` |

`Dwrr.Server` exposes the same operations against a caller-started server and
returns the same results, including immutable scheduler snapshots.

## Behavior worth knowing

- **Results.** Most operations return `{:ok, scheduler}`, `{:ok, value, scheduler}`
  or `{:error, code}`. `add_queue/1` returns `{index, scheduler}`. `remove_queue/1`
  returns the scheduler alone.
- **Six tagged errors.** `:invalid_index`, `:negative_take`, `:zero_cost`,
  `:cost_too_large`, `:zero_quantum` and `:quantum_too_large`. A tagged error returns
  no new scheduler; it retains the input unchanged, so keep using the scheduler you passed in.
- **ArgumentError.** A non-integer index or count, a negative count, or a negative
  or noninteger cost or quantum, or a batch that is not a proper list of `Dwrr.Item`
  structs raises `ArgumentError`. Domain validation precedes shared error ordering:
  enqueue validates the integer index and entire batch first; set_quantum validates
  the integer index and nonnegative integer quantum first. Only for domain-valid
  arguments does `:invalid_index` win, followed by the first zero/oversized cost or
  the zero/oversized quantum. No items are appended on either kind of failure.
- **Immutable storage.** Old snapshots stay valid. One snapshot can be branched into
  separate histories, and branches do not share writes. Values are stored and
  returned without being inspected.
- **Visits.** Nonempty queues earn their quantum at the start of a visit in
  cyclic index order. Credit carries across visits while backlogged; empty
  queues hold no credit. Whole unproductive rounds are skipped exactly, so a
  huge cost with quantum 1 does not require one iteration per grant.
- **FIFO, no overtaking.** Items leave a queue in order. A queue whose head costs
  more than its credit waits, and later items in that queue do not jump ahead.
- **Take is a retrieval limit, not a fairness cap.** `take/2` returns up to `n` items in service order. If it
  stops at `n` in the middle of a visit, that visit stays paused with its remaining
  credit, and the next `take` continues it without another quantum grant. It returns
  fewer than `n` only when every queue is empty.
- **Enqueue joins the visit.** Items added to the queue being visited join that
  visit; they do not start a new grant.
- **Reweight affects the next grant.** `set_quantum/3` changes only the quantum used
  for the next grant. Credit is kept.
- **Withdrawal.** `remove_head/2` and `drain_queue/2` do not spend credit. Emptying a
  queue resets its credit to 0.
- **Last-queue deletion and index reuse.** `remove_queue/1` deletes only the last
  queue, with its items. `add_queue/1` may then reuse that index.
- **Limits.** Costs and quanta are limited to 2^63-1. Each queue's credit stays within
  2^64-3. These are shared scheduler limits, not BEAM integer limits.
- **Fairness is by declared cost.** While queues stay backlogged, each queue's served
  cost at closed visit boundaries stays within one maximum item cost of its
  fixed quantum times the number of its visits. A paused active visit is not a
  closed visit. This is not an unrestricted fairness promise for dynamic backlogs.
  The scheduler does not measure time.
- **Server.** Each call is one `GenServer.call/2` with the default 5000 ms timeout.
  A timeout does not prove that the operation was rolled back. There are no retries
  and no backpressure. An argument outside the `Dwrr` domain raises `ArgumentError`
  inside the server, which then terminates. The caller sees an exit, not a tagged
  error. A restarted server starts fresh from its original count, so queued items,
  quantum changes and added queues are lost. Nothing is persisted.

There are no built-in queue capacity limits, admission control or resource-exhaustion
recovery guarantees. Large counts, batches and retained immutable snapshots still
consume memory. Pure histories need no shared lock; callers coordinate which
snapshot to retain. The Server serializes its own history, not caller-owned
branches. Neither interface waits for producers when empty; `take(s, 0)` or an
empty scheduler returns `{:ok, [], s}`. Selection still costs CPU and memory.

## How we know it's correct

- The behavior follows a written spec, pinned in the sibling `dwrr-spec` repository,
  with a shared conformance corpus. The corpus responses were recorded from the Go
  implementation `github.com/version2beta/dwrr` v0.10.1.
- Property tests (StreamData 1.3.0, test-only) run generated operation sequences
  against a naive reference model. They compare every result and state, and check
  item conservation, FIFO order, state after errors, branching and deterministic
  replay.
- The conformance driver replays that corpus through the Elixir implementation.
- Focused tests cover each operation and the `Dwrr.Server` behavior.

Historical local verification ran on Elixir 1.20.4 / OTP 29. The minimum
Elixir 1.18 / OTP 27 and the full CI matrix (Elixir 1.18.4 / OTP 27.3 and Elixir 1.20.4 / OTP 29.1.2) are
configured but not verified by this README. See [TESTING.md](TESTING.md).

## Check it yourself

Run these from the repository root:

```sh
MIX_ENV=test mix deps.get --check-locked
mix format --check-formatted
mix compile --warnings-as-errors
MIX_ENV=test mix test --warnings-as-errors --no-color
```

The conformance replay needs a sibling `dwrr-spec` checkout at the pinned commit.
[TESTING.md](TESTING.md) lists the exact commands.

## How it compares

- **Go `dwrr`.** The spec maps each operation to the Go library (SPEC section 11).
  Go panics on `invalid_index` and `negative_take`. Here they are tagged errors,
  `{:error, :invalid_index}` and `{:error, :negative_take}`.
- **BEAM storage.** Scheduler values are ordinary immutable Erlang terms. There is no
  shared memory and no mutable state. Old snapshots stay valid, and the cost and
  credit limits are the same in every language, not the BEAM's integer limits.
- **Pure coordination, not a worker pool.** `Dwrr` decides which item is served next.
  It does not start processes, run jobs or manage a pool of workers. The caller does
  the work. `Dwrr.Server` is a serialized mailbox around one scheduler, not a pool.

## Current implementation and shared-source status

The pure core, driver, optional Server, public docs and package metadata are
implemented in this checkout; intended 0.1.0 remains unpublished. The owner-run
kit instructions below are historical preparation instructions, not a statement
that these files are still stubs or authorization to rerun a loop.

Vendored SPEC/PROTOCOL/corpus and their hash guards deliberately retain the
historical `8a0e3cf9ae860ba207213590c00feeb822bdd8f2` snapshot. Sibling working-tree
corrections clarify that negative costs/quanta are language-local and wire
integers have no signed-32-bit protocol cap, add language mappings, and repair
the Go adapter/checker; no scheduler semantics or corpus bytes changed. They do
not silently repin these historical fixtures or CI. Historical verification records
report that Elixir was also checked against the expanded sibling checker:
**41/41**, plus all **1,839 cases / 44,728 steps**. Python now has a working
mutable, internally locked implementation; its public API and language-domain
validation differ from Elixir's immutable core. Go's unreleased callbacks/result
API and generation-exhaustion restriction are not shared fixed-core requirements.
The sibling protocol now permits native count-representation exhaustion as a
resource failure, not malformed input: Go detects counts above native `int` before
allocation, emits stderr and exits 1 with no response or later processing; prior
responses stand. This adds no shared count cap or Elixir rejection requirement,
and guarantees no controlled recovery from actual allocation limits/OOM. Frozen
vendored documents and identities above remain unchanged.

## Apply and run the stage-2 kit (owner only)

Already applied over audited stage-1 HEAD `7205252` on
`spec-loop/stage2-preparation`. Review SPEC Part 2, tasks.json and
[verification](docs/STAGE2-VERIFICATION.md) first. T01–T21 remain unchanged;
the old T22 whole-tree gate was replaced by seven new tasks T22–T27 and T29.
T28 is deliberately absent: CI is complete and protected, not a coding task.
Properties, the naive oracle and CI identity check are protected preparation assets.

Exact judge expectations require installed Elixir 1.20.4 / OTP29. Library minimum
1.18/27 is not proven by that runtime. CI minimum/current jobs are not executed
by preparation. Requires Python3, bash, git, jq, timeout (or gtimeout), Pi with
owner-authorized access/spending, and approved StreamData test dependency.
Do not start with unrelated edits. Only the owner may commit this baseline and
then authorize model calls, loop commits and discards of attempt-owned edits.

```sh
cd ~/Development/dwrr-elixir
test "$(git -C ../dwrr-spec rev-parse HEAD)" = 8a0e3cf9ae860ba207213590c00feeb822bdd8f2
test "$(git branch --show-current)" = spec-loop/stage2-preparation
MIX_ENV=test mix deps.get --check-locked
git status --short
# Review all tracked AND new files; do not include .loop/ or private source.
git add .
git diff --cached --stat
git commit -m "Add verified stage-2 spec-loop kit"
test -z "$(git status --porcelain)"
mkdir -p .loop
set -o pipefail
JUDGE_TIMEOUT=300 bash scripts/loop.sh 2>&1 | tee .loop/stage2-console.log
```

Unchanged pinned defaults (inspection only; no kit overrides):

```text
cheap: pi --provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session
strong: pi --provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session
strongest: pi --provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session
```

Inspect any owner environment overrides yourself. Defaults: 60 iterations, four
attempts per task, 1200s coder timeout, 300s per judge command. The loop commits
on this branch. `.loop/loop.log` records exact coder commands, `.loop/coder.*.log`
holds output and `.loop/notes.*` discarded notes; `STOP` names an exhausted task.
Keep ignored logs for review; do not blindly rerun STOP. Preparation invokes no
coder, stages/commits nothing, publishes nothing and changes no installed skill.

## Colophon

- Release: 0.1.0 (intended; not yet published). Hex package and application: `dwrr`.
- Elixir >= 1.18 and OTP >= 27. No runtime dependencies.
- License: MIT. Copyright 2026 M. Robert Martin.
- Source: https://github.com/version2beta/dwrr-elixir
- Intended Hex and HexDocs pages for `dwrr` are not published yet.
