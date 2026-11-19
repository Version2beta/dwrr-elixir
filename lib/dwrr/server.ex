defmodule Dwrr.Server do
  @moduledoc """
  Caller-owned serialized scheduler. Implement SPEC Part 2; no implicit child,
  persistence, retries, custom timeouts, execution or backpressure.
  """
  @doc "Start from count; forward standard GenServer options. Restart starts fresh."
  def start_link(_count, _options \\ []), do: {:error, :not_implemented}
  @doc "Append items; return the exact core result, including its scheduler."
  def enqueue(_server, _index, _items), do: nil
  @doc "Retrieve items; return the exact core result."
  def take(_server, _n), do: nil
  @doc "Change quantum; return the exact core result."
  def set_quantum(_server, _index, _quantum), do: nil
  @doc "Append queue; return {index, scheduler}."
  def add_queue(_server), do: nil
  @doc "Remove last queue; return scheduler."
  def remove_queue(_server), do: nil
  @doc "Withdraw head; return the exact core result."
  def remove_head(_server, _index), do: nil
  @doc "Withdraw FIFO contents; return the exact core result."
  def drain_queue(_server, _index), do: nil
end
