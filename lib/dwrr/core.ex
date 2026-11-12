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
  def set_quantum(s, index, quantum) when is_integer(index) do
    with :ok <- check_index(s, index),
         :ok <- check_quantum(quantum) do
      {:ok, put_quantum(s, index, quantum)}
    end
  end

  def set_quantum(_s, _index, _quantum),
    do: raise(ArgumentError, "queue index must be an integer")

  @doc "Return {old count, scheduler with appended empty queue}."
  def add_queue(%Dwrr{count: count, queues: queues} = s) do
    {count, %{s | queues: Map.put(queues, count, empty_queue()), count: count + 1}}
  end

  @doc "Drop last queue and its items; cancel its active visit; repair cursor (SPEC §5.5)."
  def remove_queue(%Dwrr{count: 0} = s), do: s

  def remove_queue(%Dwrr{count: count, queues: queues, busy: busy, total: total} = s) do
    last = count - 1
    %{size: size} = Map.fetch!(queues, last)

    # Step 1: cancel the visit only when it sits on the queue being removed.
    {active, cursor} =
      if s.active and s.cursor == last, do: {false, 0}, else: {s.active, s.cursor}

    # Step 3: repair the cursor into 0..last-1.
    cursor =
      cond do
        last == 0 -> 0
        cursor >= last -> rem(cursor, last)
        true -> cursor
      end

    %{
      s
      | queues: Map.delete(queues, last),
        busy: :gb_sets.delete_any(last, busy),
        total: total - size,
        count: last,
        cursor: cursor,
        active: active
    }
  end

  @doc "Withdraw FIFO head, no scheduling/debit; emptying resets credit/closes active visit."
  def remove_head(s, index) when is_integer(index) do
    with :ok <- check_index(s, index) do
      case Map.fetch!(s.queues, index) do
        %{size: 0} ->
          {:ok, nil, s}

        %{head: removed} = rec ->
          {next_head, next_tail, size} = pop(rec)
          rec = %{rec | head: next_head, tail: next_tail, size: size}
          {:ok, removed, withdraw(s, index, rec, 1)}
      end
    end
  end

  def remove_head(_s, _index), do: raise(ArgumentError, "queue index must be an integer")

  @doc "Withdraw FIFO contents; reset credit and close that active visit."
  def drain_queue(s, index) when is_integer(index) do
    with :ok <- check_index(s, index) do
      case Map.fetch!(s.queues, index) do
        %{size: 0} ->
          {:ok, [], s}

        %{head: head, tail: tail, size: size} = rec ->
          items = [head | :queue.to_list(tail)]
          rec = %{rec | head: nil, tail: :queue.new(), size: 0}
          {:ok, items, withdraw(s, index, rec, size)}
      end
    end
  end

  def drain_queue(_s, _index), do: raise(ArgumentError, "queue index must be an integer")

  @doc "Exact SPEC take; sparse traversal; skip only after a full unproductive cycle."
  def take(_s, n) when is_integer(n) and n < 0, do: {:error, :negative_take}
  def take(s, n) when is_integer(n), do: serve(s, n, [], 0)
  def take(_s, _n), do: raise(ArgumentError, "take count must be an integer")

  defp empty_queue, do: %{quantum: 1, credit: 0, size: 0, head: nil, tail: :queue.new()}

  # Index precedes every other enqueue/set_quantum check (SPEC §5.2, §5.3).
  defp check_index(%Dwrr{count: count}, index) when index >= 0 and index < count, do: :ok
  defp check_index(_s, _index), do: {:error, :invalid_index}

  # Quantum must be 1..MAX_QUANTUM; 0 and too-large are shared errors, other inputs raise.
  defp check_quantum(0), do: {:error, :zero_quantum}

  defp check_quantum(quantum) when is_integer(quantum) and quantum > @max_cost,
    do: {:error, :quantum_too_large}

  defp check_quantum(quantum) when is_integer(quantum) and quantum > 0, do: :ok

  defp check_quantum(_quantum),
    do: raise(ArgumentError, "quantum must be a nonnegative integer")

  # Replaces only the quantum; credit and active are preserved (SPEC §5.3).
  defp put_quantum(%Dwrr{queues: queues} = s, index, quantum) do
    rec = Map.fetch!(queues, index)
    %{s | queues: Map.put(queues, index, %{rec | quantum: quantum})}
  end

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
  defp serve(s, 0, out, _failed), do: {:ok, Enum.reverse(out), s}

  defp serve(%Dwrr{busy: busy} = s, left, out, failed) do
    if :gb_sets.is_empty(busy) do
      {:ok, Enum.reverse(out), s}
    else
      serve_cursor(s, left, out, failed)
    end
  end

  defp serve_cursor(%Dwrr{cursor: q, queues: queues, active: active} = s, left, out, failed) do
    rec = Map.fetch!(queues, q)

    cond do
      not active and rec.size == 0 ->
        serve(%{s | cursor: next_busy(s.busy, q)}, left, out, failed)

      not active ->
        rec = %{rec | credit: rec.credit + rec.quantum}
        serve(%{s | queues: Map.put(queues, q, rec), active: true}, left, out, failed)

      rec.credit < rec.head.cost ->
        s = close_visit(s)
        failed = failed + 1

        # A blocked resume counts without a new grant. Only a complete run of
        # failed busy visits proves every head is still unaffordable.
        if failed == :gb_sets.size(s.busy) do
          serve(skip_idle_cycles(s), left, out, 0)
        else
          serve(s, left, out, failed)
        end

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

      serve(close_visit(s), left - 1, out, 0)
    else
      rec = %{rec | credit: credit, head: next_head, tail: next_tail, size: size}

      s = %{
        s
        | queues: Map.put(s.queues, q, rec),
          total: s.total - 1
      }

      serve(s, left - 1, out, 0)
    end
  end

  # Called only after every busy head failed since the last service. Each
  # skipped cycle leaves all heads blocked and returns to this inactive cursor.
  defp skip_idle_cycles(s) do
    rounds = idle_rounds(:gb_sets.iterator(s.busy), s.queues, nil)

    if rounds > 0 do
      queues = grant_idle_rounds(:gb_sets.iterator(s.busy), s.queues, rounds)
      %{s | queues: queues}
    else
      s
    end
  end

  defp idle_rounds(iterator, queues, minimum) do
    case :gb_sets.next(iterator) do
      {index, rest} ->
        rec = Map.fetch!(queues, index)
        rounds = div(rec.head.cost - rec.credit - 1, rec.quantum)
        minimum = if minimum == nil, do: rounds, else: min(minimum, rounds)
        idle_rounds(rest, queues, minimum)

      :none ->
        minimum
    end
  end

  defp grant_idle_rounds(iterator, queues, rounds) do
    case :gb_sets.next(iterator) do
      {index, rest} ->
        rec = Map.fetch!(queues, index)
        rec = %{rec | credit: rec.credit + rounds * rec.quantum}
        grant_idle_rounds(rest, Map.put(queues, index, rec), rounds)

      :none ->
        queues
    end
  end

  # Stores a queue after FIFO withdrawal (no scheduling). Emptying resets credit
  # and closes the visit only when that queue is the active cursor (SPEC §5.6-5.7).
  defp withdraw(%Dwrr{queues: queues, busy: busy, total: total} = s, index, rec, removed) do
    if rec.size == 0 do
      rec = %{rec | credit: 0}

      s = %{
        s
        | queues: Map.put(queues, index, rec),
          busy: :gb_sets.delete_any(index, busy),
          total: total - removed
      }

      if s.active and s.cursor == index, do: close_visit(s), else: s
    else
      %{s | queues: Map.put(queues, index, rec), total: total - removed}
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
