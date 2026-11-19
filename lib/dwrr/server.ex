defmodule Dwrr.Server do
  @moduledoc """
  Caller-owned serialized scheduler. Implement SPEC Part 2; no implicit child,
  persistence, retries, custom timeouts, execution or backpressure.
  """
  use GenServer

  @doc "Start from count; forward standard GenServer options. Restart starts fresh."
  def start_link(count, options \\ []), do: GenServer.start_link(__MODULE__, count, options)

  @doc "Append items; return the exact core result, including its scheduler."
  def enqueue(server, index, items), do: GenServer.call(server, {:enqueue, index, items})

  @doc "Retrieve items; return the exact core result."
  def take(server, n), do: GenServer.call(server, {:take, n})

  @doc "Change quantum; return the exact core result."
  def set_quantum(server, index, quantum),
    do: GenServer.call(server, {:set_quantum, index, quantum})

  @doc "Append queue; return {index, scheduler}."
  def add_queue(server), do: GenServer.call(server, :add_queue)

  @doc "Remove last queue; return scheduler."
  def remove_queue(server), do: GenServer.call(server, :remove_queue)

  @doc "Withdraw head; return the exact core result."
  def remove_head(server, index), do: GenServer.call(server, {:remove_head, index})

  @doc "Withdraw FIFO contents; return the exact core result."
  def drain_queue(server, index), do: GenServer.call(server, {:drain_queue, index})

  @impl true
  def init(count), do: {:ok, Dwrr.new(count)}

  @impl true
  def handle_call({:enqueue, index, items}, _from, state) do
    reply(Dwrr.enqueue(state, index, items), state)
  end

  def handle_call({:take, n}, _from, state) do
    reply(Dwrr.take(state, n), state)
  end

  def handle_call({:set_quantum, index, quantum}, _from, state) do
    reply(Dwrr.set_quantum(state, index, quantum), state)
  end

  def handle_call(:add_queue, _from, state) do
    {_index, next} = result = Dwrr.add_queue(state)
    {:reply, result, next}
  end

  def handle_call(:remove_queue, _from, state) do
    next = Dwrr.remove_queue(state)
    {:reply, next, next}
  end

  def handle_call({:remove_head, index}, _from, state) do
    reply(Dwrr.remove_head(state, index), state)
  end

  def handle_call({:drain_queue, index}, _from, state) do
    reply(Dwrr.drain_queue(state, index), state)
  end

  defp reply({:ok, next} = result, _state), do: {:reply, result, next}
  defp reply({:ok, _value, next} = result, _state), do: {:reply, result, next}
  defp reply({:error, _code} = result, state), do: {:reply, result, state}
end
