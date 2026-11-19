# Stage-2 documentation/typespec target. Executable AST and opaque representation are frozen.
defmodule Dwrr do
  @moduledoc """
  Pure deficit weighted round robin scheduler: no process, no I/O, no hidden state.

  Scheduler values are immutable. Successful operations return the new scheduler,
  possibly with a result (`{:ok, result, scheduler}`). On a tagged error no new
  scheduler is returned: keep using the input you passed, which is unchanged.
  Old snapshots remain valid, so one snapshot can be branched into separate pure
  histories. Branches do not share writes.

  Tagged errors are `:invalid_index`, `:negative_take`, `:zero_cost`,
  `:cost_too_large`, `:zero_quantum` and `:quantum_too_large`. Arguments outside the
  documented domain, such as a non-integer index or count, a negative count, or a
  negative cost or quantum, raise `ArgumentError` instead of returning a tagged error.

  Values are opaque: the scheduler stores and returns them without inspecting them.
  Costs and quanta are limited to 2^63-1, and each queue's credit stays within
  2^64-3. These are shared scheduler limits, not BEAM limits. Fairness is by declared
  cost, not time: the scheduler does not measure work, and it makes no unrestricted
  fairness promise for dynamic backlogs.

  Queues are FIFO and never overtake a blocked head. `take/2` returns up to `n` items
  in service order. Enqueue joins the active visit; `set_quantum/3` changes only the
  next grant and keeps credit. `remove_queue/1` deletes only the last queue and its
  items, and `add_queue/1` may reuse that index. `remove_head/2` and `drain_queue/2`
  withdraw items without debiting credit.

  Requires Elixir >=1.18 and OTP >=27.

  ## Examples

  Each example is an independent history.

  ```elixir
  s = Dwrr.new(1)
  {:ok, s} = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :job, cost: 2}])
  {:ok, served, _s} = Dwrr.take(s, 1)
  result = Enum.map(served, & &1.value)
  ```

  ```elixir
  s = Dwrr.new(1)
  {:ok, old} = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :original, cost: 1}])
  {:ok, served, _after_take} = Dwrr.take(old, 1)
  {:ok, drained, _after_drain} = Dwrr.drain_queue(old, 0)
  result = {Enum.map(served, & &1.value), Enum.map(drained, & &1.value)}
  ```

  ```elixir
  s = Dwrr.new(1)
  result = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :job, cost: 0}])
  ```
  """
  defstruct queues: %{}, busy: nil, count: 0, total: 0, cursor: 0, active: false

  @opaque t(value) :: %__MODULE__{
            queues: %{
              optional(non_neg_integer()) => %{
                head: Dwrr.Item.t(value) | nil,
                tail: term(),
                size: non_neg_integer(),
                quantum: pos_integer(),
                credit: non_neg_integer()
              }
            },
            busy: term(),
            count: non_neg_integer(),
            total: non_neg_integer(),
            cursor: non_neg_integer(),
            active: boolean()
          }
  @type error ::
          :invalid_index
          | :negative_take
          | :zero_cost
          | :cost_too_large
          | :zero_quantum
          | :quantum_too_large
  @doc "Create count empty queues (nonnegative integer); return the scheduler."
  @spec new(non_neg_integer()) :: t(term())
  defdelegate new(count), to: Dwrr.Core

  @doc "Append a proper list of Item structs atomically; return {:ok, scheduler} or {:error, code}."
  @spec enqueue(t(value), integer(), [%Dwrr.Item{cost: non_neg_integer(), value: value}]) ::
          {:ok, t(value)} | {:error, error()}
        when value: term()
  defdelegate enqueue(s, queue, items), to: Dwrr.Core

  @doc "Retrieve up to n Scheduled structs, preserving paused visits; return {:ok, items, scheduler} or {:error, code}."
  @spec take(t(value), integer()) ::
          {:ok, [Dwrr.Scheduled.t(value)], t(value)} | {:error, error()}
        when value: term()
  defdelegate take(s, n), to: Dwrr.Core

  @doc "Set quantum for the next grant without changing credit; return {:ok, scheduler} or {:error, code}."
  @spec set_quantum(t(value), integer(), non_neg_integer()) ::
          {:ok, t(value)} | {:error, error()}
        when value: term()
  defdelegate set_quantum(s, queue, quantum), to: Dwrr.Core
  @doc "Append an empty queue; return {index, scheduler}."
  @spec add_queue(t(value)) :: {non_neg_integer(), t(value)} when value: term()
  defdelegate add_queue(s), to: Dwrr.Core
  @doc "Remove only the last queue, discarding items; return scheduler."
  @spec remove_queue(t(value)) :: t(value) when value: term()
  defdelegate remove_queue(s), to: Dwrr.Core

  @doc "Withdraw one head without debiting credit; return {:ok, Item or nil, scheduler} or {:error, code}."
  @spec remove_head(t(value), integer()) ::
          {:ok, Dwrr.Item.t(value) | nil, t(value)} | {:error, error()}
        when value: term()
  defdelegate remove_head(s, queue), to: Dwrr.Core
  @doc "Withdraw all queue items FIFO; return {:ok, items, scheduler} or {:error, code}."
  @spec drain_queue(t(value), integer()) ::
          {:ok, [Dwrr.Item.t(value)], t(value)} | {:error, error()}
        when value: term()
  defdelegate drain_queue(s, queue), to: Dwrr.Core
end
