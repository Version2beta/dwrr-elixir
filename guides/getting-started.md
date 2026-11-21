# Getting started

`dwrr` is an immutable deficit weighted round robin scheduler for Elixir.
Use it to select work from FIFO queues with different declared-cost shares.
It does not execute jobs, measure elapsed time, or start an application process.

This guide and API reference describe **dwrr 0.1.0**, published from
[`88c8dc7`](https://github.com/version2beta/dwrr-elixir/tree/88c8dc71f673c35281de00d602c5ae2a4a951f7e).
The documentation was prepared separately from the package. Source links point
to files at that release commit, not to the later documentation edits.

## Install

Requires Elixir 1.18 or later on OTP 27 or later. Add to `mix.exs`:

```elixir
{:dwrr, "~> 0.1.0"}
```

Run `mix deps.get`. There are no runtime dependencies or application children.

## Schedule work

Queue indexes start at zero. Each queue initially has quantum 1. Choose cost
units that match your workload (for example bytes, not an opaque priority score).
Quantum is the credit granted on a visit; it is not a limit on item size.

```elixir
s = Dwrr.new(2)
{:ok, s} = Dwrr.set_quantum(s, 0, 2)
{:ok, s} = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :upload, cost: 2}])
{:ok, s} = Dwrr.enqueue(s, 1, [%Dwrr.Item{value: :ping, cost: 1}])
{:ok, items, next} = Dwrr.take(s, 2)
Enum.map(items, &{&1.queue, &1.value, &1.cost})
# => [{0, :upload, 2}, {1, :ping, 1}]
```

Keep `next` for subsequent operations. `s` remains a valid independent snapshot.
`Dwrr.take/2` returns `Dwrr.Scheduled` structs; withdrawals return `Dwrr.Item`
structs instead. Values are opaque and can be any Elixir term.

## Handle errors without losing state

```elixir
s = Dwrr.new(1)
Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :bad, cost: 0}])
# => {:error, :zero_cost}
Dwrr.take(s, 1) |> elem(1)
# => []
```

Tagged errors return no replacement scheduler: retain the input. Enqueue is
atomic. Invalid argument domains raise `ArgumentError`; see `Dwrr` for validation
ordering and limits. Costs and quanta must be positive and at most 2^63-1.

## Own the process, if you need one

The pure API needs no server. For serialized shared access, supervise
`{Dwrr.Server, count}` or start it explicitly:

```elixir
{:ok, pid} = Dwrr.Server.start_link(1, name: :work_scheduler)
{:ok, _snapshot} = Dwrr.Server.enqueue(pid, 0, [%Dwrr.Item{value: :job, cost: 1}])
{:ok, items, _snapshot} = Dwrr.Server.take(pid, 1)
Enum.map(items, & &1.value)
# => [:job]
GenServer.stop(pid)
# => :ok
```

Naming is optional. Calls use the default 5-second `GenServer.call/2` timeout.
A timeout does not imply rollback. Invalid arguments terminate the server; a
restart loses queued work and starts fresh. There is no persistence, retry,
backpressure or worker pool. Returned snapshots do not mutate the server.

## Scheduling boundaries

- FIFO heads never overtake each other. `take/2` preserves paused visits.
- Enqueue joins an active visit; changing quantum affects the next grant and
  retains existing credit.
- `remove_head/2` and `drain_queue/2` withdraw without debiting credit.
- `remove_queue/1` removes only the last queue, including its backlog;
  `add_queue/1` can reuse its index.
- Fairness is by declared cost under stable backlog, not wall-clock duration
  or an unrestricted guarantee for changing backlogs.

Continue with `Dwrr` for pure operations and `Dwrr.Server` for process ownership.
