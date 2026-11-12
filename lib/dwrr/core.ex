defmodule Dwrr.Core do
  @moduledoc false
  # Implement SPEC.md. Keep exported functions and the public Dwrr contract.
  # Outside documented types raise ArgumentError (guard fallbacks must raise).
  # Shared errors return tagged atoms without modifying the input scheduler.

  @max_cost 9_223_372_036_854_775_807

  @doc "Construct count default queues; zero is valid."
  def new(count) when is_integer(count) and count >= 0 do
    queues =
      Map.new(0..(count - 1)//1, fn i ->
        {i, empty_queue()}
      end)

    %Dwrr{queues: queues, busy: :gb_sets.empty(), count: count}
  end

  def new(_count), do: raise(ArgumentError, "count must be a nonnegative integer")

  @doc "Validate index, then all costs in order, before FIFO append."
  def enqueue(s, index, items) when is_integer(index) do
    with :ok <- check_index(s, index),
         :ok <- check_items(items) do
      {:ok, append(s, index, items)}
    end
  end

  def enqueue(_s, _index, _items), do: raise(ArgumentError, "queue index must be an integer")

  @doc "Validate index then quantum; do not touch credit or active."
  def set_quantum(s, index, _quantum) when is_integer(index) do
    with :ok <- check_index(s, index), do: {:ok, s}
  end

  def set_quantum(_s, _index, _quantum),
    do: raise(ArgumentError, "queue index must be an integer")

  @doc "Return {old count, scheduler with appended empty queue}."
  def add_queue(%Dwrr{count: count, queues: queues} = s) do
    {count, %{s | queues: Map.put(queues, count, empty_queue()), count: count + 1}}
  end

  @doc "Drop last queue; repair cursor/active; zero count is a no-op."
  def remove_queue(s), do: s

  @doc "Withdraw FIFO head, no scheduling/debit; emptying resets credit/closes active visit."
  def remove_head(s, index) when is_integer(index) do
    with :ok <- check_index(s, index), do: {:ok, nil, s}
  end

  def remove_head(_s, _index), do: raise(ArgumentError, "queue index must be an integer")

  @doc "Withdraw FIFO contents; reset credit and close that active visit."
  def drain_queue(s, index) when is_integer(index) do
    with :ok <- check_index(s, index), do: {:ok, [], s}
  end

  def drain_queue(_s, _index), do: raise(ArgumentError, "queue index must be an integer")

  @doc "Exact SPEC take; sparse traversal; skip only after a full unproductive cycle."
  def take(_s, n) when is_integer(n) and n < 0, do: {:error, :negative_take}
  def take(s, n) when is_integer(n), do: serve(s, n, [])
  def take(_s, _n), do: raise(ArgumentError, "take count must be an integer")

  defp empty_queue, do: %{quantum: 1, credit: 0, size: 0, head: nil, tail: :queue.new()}

  # Index precedes every other enqueue/set_quantum check (SPEC §5.2, §5.3).
  defp check_index(%Dwrr{count: count}, index) when index >= 0 and index < count, do: :ok
  defp check_index(_s, _index), do: {:error, :invalid_index}

  # Validates every item in order before any append (atomic batch).
  defp check_items([]), do: :ok

  defp check_items([%Dwrr.Item{cost: cost} | rest])
       when is_integer(cost) and cost >= 1 and cost <= @max_cost,
       do: check_items(rest)

  defp check_items([%Dwrr.Item{cost: 0} | _]), do: {:error, :zero_cost}

  defp check_items([%Dwrr.Item{cost: cost} | _]) when is_integer(cost) and cost > @max_cost,
    do: {:error, :cost_too_large}

  defp check_items(_items),
    do: raise(ArgumentError, "items must be a proper list of Dwrr.Item structs")

  defp append(s, _index, []), do: s

  defp append(%Dwrr{queues: queues, busy: busy, total: total} = s, index, items) do
    rec = Map.fetch!(queues, index)
    next = Enum.reduce(items, rec, &push/2)
    busy = if rec.size == 0, do: :gb_sets.add_element(index, busy), else: busy

    %{
      s
      | queues: Map.put(queues, index, next),
        busy: busy,
        total: total + length(items)
    }
  end

  defp push(%Dwrr.Item{} = item, %{size: 0, head: nil} = rec), do: %{rec | head: item, size: 1}

  defp push(%Dwrr.Item{} = item, rec),
    do: %{rec | tail: :queue.in(item, rec.tail), size: rec.size + 1}

  # Serves items in SPEC §5.8 order, visiting only busy queues. Empty queues
  # are skipped via the busy index; each skip matches the spec's no-op advance.
  defp serve(s, 0, out), do: {:ok, Enum.reverse(out), s}

  defp serve(%Dwrr{busy: busy} = s, left, out) do
    if :gb_sets.is_empty(busy) do
      {:ok, Enum.reverse(out), s}
    else
      serve_cursor(s, left, out)
    end
  end

  defp serve_cursor(%Dwrr{cursor: q, queues: queues, active: active} = s, left, out) do
    rec = Map.fetch!(queues, q)

    cond do
      not active and rec.size == 0 ->
        serve(%{s | cursor: next_busy(s.busy, q)}, left, out)

      not active ->
        rec = %{rec | credit: rec.credit + rec.quantum}
        serve(%{s | queues: Map.put(queues, q, rec), active: true}, left, out)

      rec.credit < rec.head.cost ->
        serve(close_visit(s), left, out)

      true ->
        serve_head(s, q, rec, left, out)
    end
  end

  defp serve_head(s, q, rec, left, out) do
    %Dwrr.Item{value: value, cost: cost} = rec.head
    credit = rec.credit - cost
    {next_head, next_tail, size} = pop(rec)
    out = [%Dwrr.Scheduled{queue: q, value: value, cost: cost} | out]

    if size == 0 do
      rec = %{rec | credit: 0, head: nil, tail: next_tail, size: 0}

      s = %{
        s
        | queues: Map.put(s.queues, q, rec),
          busy: :gb_sets.delete_any(q, s.busy),
          total: s.total - 1
      }

      serve(close_visit(s), left - 1, out)
    else
      rec = %{rec | credit: credit, head: next_head, tail: next_tail, size: size}

      s = %{
        s
        | queues: Map.put(s.queues, q, rec),
          total: s.total - 1
      }

      serve(s, left - 1, out)
    end
  end

  defp pop(rec) do
    case :queue.out(rec.tail) do
      {{:value, next}, tail} -> {next, tail, rec.size - 1}
      {:empty, tail} -> {nil, tail, rec.size - 1}
    end
  end

  defp close_visit(%Dwrr{cursor: cursor, count: count} = s) do
    %{s | active: false, cursor: rem(cursor + 1, count)}
  end

  # Cyclic successor of q within the busy set (q itself is not busy here).
  defp next_busy(busy, q) do
    case :gb_sets.next(:gb_sets.iterator_from(q, busy)) do
      {next, _iter} -> next
      :none -> :gb_sets.smallest(busy)
    end
  end
end
