defmodule Dwrr.Server do
  @moduledoc """
  Caller-owned, serialized wrapper around `Dwrr` for one process.

  Start it under your own supervisor or with `start_link/2`. It registers no name
  and starts no children. Each function makes one `GenServer.call/2` with the default
  5000 ms timeout and returns the exact `Dwrr` result, including the new scheduler.
  Tagged errors are returned unchanged and leave the stored state unchanged. Calls
  are applied in mailbox arrival order; the order of calls from different senders is
  not guaranteed.

  A timeout does not prove that the operation was rolled back. An argument outside
  the `Dwrr` domain raises `ArgumentError` inside the server, which then terminates;
  the caller sees an exit, not a tagged error. Invalid initialization fails
  `start_link/2`. A restarted server starts fresh from its original count, so queued
  items, quantum changes and added queues are lost. There are no retries, no
  backpressure and no persistence. Returned snapshots are immutable values for pure
  branching, not shared writes.
  """
  use GenServer

  @doc "Start from count; forward standard GenServer options. Restart starts fresh."
  @spec start_link(non_neg_integer(), GenServer.options()) :: GenServer.on_start()
  def start_link(count, options \\ []), do: GenServer.start_link(__MODULE__, count, options)

  @doc "Append items; return the exact core result, including its scheduler."
  @spec enqueue(GenServer.server(), integer(), [
          %Dwrr.Item{cost: non_neg_integer(), value: term()}
        ]) ::
          {:ok, Dwrr.t(term())} | {:error, Dwrr.error()}
  def enqueue(server, index, items), do: GenServer.call(server, {:enqueue, index, items})

  @doc "Retrieve items; return the exact core result."
  @spec take(GenServer.server(), integer()) ::
          {:ok, [Dwrr.Scheduled.t(term())], Dwrr.t(term())} | {:error, Dwrr.error()}
  def take(server, n), do: GenServer.call(server, {:take, n})

  @doc "Change quantum; return the exact core result."
  @spec set_quantum(GenServer.server(), integer(), non_neg_integer()) ::
          {:ok, Dwrr.t(term())} | {:error, Dwrr.error()}
  def set_quantum(server, index, quantum),
    do: GenServer.call(server, {:set_quantum, index, quantum})

  @doc "Append queue; return {index, scheduler}."
  @spec add_queue(GenServer.server()) :: {non_neg_integer(), Dwrr.t(term())}
  def add_queue(server), do: GenServer.call(server, :add_queue)

  @doc "Remove last queue; return scheduler."
  @spec remove_queue(GenServer.server()) :: Dwrr.t(term())
  def remove_queue(server), do: GenServer.call(server, :remove_queue)

  @doc "Withdraw head; return the exact core result."
  @spec remove_head(GenServer.server(), integer()) ::
          {:ok, Dwrr.Item.t(term()) | nil, Dwrr.t(term())} | {:error, Dwrr.error()}
  def remove_head(server, index), do: GenServer.call(server, {:remove_head, index})

  @doc "Withdraw FIFO contents; return the exact core result."
  @spec drain_queue(GenServer.server(), integer()) ::
          {:ok, [Dwrr.Item.t(term())], Dwrr.t(term())} | {:error, Dwrr.error()}
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
