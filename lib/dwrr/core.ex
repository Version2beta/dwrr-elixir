defmodule Dwrr.Core do
  @moduledoc false
  # Implement SPEC.md. Keep exported functions and the public Dwrr contract.
  # Outside documented types raise ArgumentError (guard fallbacks must raise).
  # Shared errors return tagged atoms without modifying the input scheduler.
  @doc "Construct count default queues; zero is valid."
  def new(_count), do: %Dwrr{}
  @doc "Validate index, then all costs in order, before FIFO append."
  def enqueue(s, _index, _items), do: {:ok, s}
  @doc "Validate index then quantum; do not touch credit or active."
  def set_quantum(s, _index, _quantum), do: {:ok, s}
  @doc "Return {old count, scheduler with appended empty queue}."
  def add_queue(s), do: {0, s}
  @doc "Drop last queue; repair cursor/active; zero count is a no-op."
  def remove_queue(s), do: s
  @doc "Withdraw FIFO head, no scheduling/debit; emptying resets credit/closes active visit."
  def remove_head(s, _index), do: {:ok, nil, s}
  @doc "Withdraw FIFO contents; reset credit and close that active visit."
  def drain_queue(s, _index), do: {:ok, [], s}
  @doc "Exact SPEC take; sparse traversal; skip only after a full unproductive cycle."
  def take(s, _n), do: {:ok, [], s}
end
