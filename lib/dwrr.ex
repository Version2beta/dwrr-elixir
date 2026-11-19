# Stage-2 documentation/typespec target. Executable AST and opaque representation are frozen.
defmodule Dwrr do
  @moduledoc """
  Pure deficit weighted round robin. Thread successful returned schedulers;
  retain the input on tagged errors. Values are opaque. No process or I/O.
  Elixir >=1.18 and OTP >=27. Shared limits are 2^63-1, not BEAM limits.
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
  defdelegate new(count), to: Dwrr.Core

  @doc "Append a proper list of Item structs atomically; return {:ok, scheduler} or {:error, code}."
  defdelegate enqueue(s, queue, items), to: Dwrr.Core

  @doc "Retrieve up to n Scheduled structs, preserving paused visits; return {:ok, items, scheduler} or {:error, code}."
  defdelegate take(s, n), to: Dwrr.Core

  @doc "Set quantum for the next grant without changing credit; return {:ok, scheduler} or {:error, code}."
  defdelegate set_quantum(s, queue, quantum), to: Dwrr.Core
  @doc "Append an empty queue; return {index, scheduler}."
  defdelegate add_queue(s), to: Dwrr.Core
  @doc "Remove only the last queue, discarding items; return scheduler."
  defdelegate remove_queue(s), to: Dwrr.Core

  @doc "Withdraw one head without debiting credit; return {:ok, Item or nil, scheduler} or {:error, code}."
  defdelegate remove_head(s, queue), to: Dwrr.Core
  @doc "Withdraw all queue items FIFO; return {:ok, items, scheduler} or {:error, code}."
  defdelegate drain_queue(s, queue), to: Dwrr.Core
end
