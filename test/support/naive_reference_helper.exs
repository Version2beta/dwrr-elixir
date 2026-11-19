# Complete; do not change. Literal list/slot model of shared SPEC §5.
# No production helpers, FIFO library, busy index, skip arithmetic or round synchronization.
defmodule Dwrr.NaiveReference do
  alias Dwrr.{Item, Scheduled}
  @max 9_223_372_036_854_775_807
  @work_limit 20_000
  def new(count), do: %{queues: List.duplicate(empty(), count), cursor: 0, active: false}
  defp empty, do: %{items: [], quantum: 1, credit: 0}

  def step(s, :add_queue),
    do: {{:index, length(s.queues)}, %{s | queues: s.queues ++ [empty()]}}

  def step(%{queues: []} = s, :remove_queue), do: {:state, s}

  def step(s, :remove_queue) do
    last = length(s.queues) - 1
    s = if s.active and s.cursor == last, do: %{s | active: false, cursor: 0}, else: s
    cursor = if last == 0, do: 0, else: rem(s.cursor, last)
    {:state, %{s | queues: Enum.take(s.queues, last), cursor: cursor}}
  end

  def step(s, {:take, n}) when n < 0, do: {{:error, :negative_take}, s}

  def step(s, {:take, n}) do
    {out, next} = run(s, n, [], @work_limit)
    {{:ok, out}, next}
  end

  def step(s, op) do
    index = elem(op, 1)

    if index < 0 or index >= length(s.queues) do
      {{:error, :invalid_index}, s}
    else
      queue_step(s, Enum.at(s.queues, index), op)
    end
  end

  defp queue_step(s, q, {:enqueue, i, items}) do
    error =
      Enum.find_value(items, fn
        %Item{cost: 0} -> :zero_cost
        %Item{cost: c} when c > @max -> :cost_too_large
        _ -> nil
      end)

    if error, do: {{:error, error}, s}, else: {:ok, put(s, i, %{q | items: q.items ++ items})}
  end

  defp queue_step(s, _q, {:set_quantum, _i, 0}), do: {{:error, :zero_quantum}, s}

  defp queue_step(s, _q, {:set_quantum, _i, n}) when n > @max,
    do: {{:error, :quantum_too_large}, s}

  defp queue_step(s, q, {:set_quantum, i, n}), do: {:ok, put(s, i, %{q | quantum: n})}
  defp queue_step(s, %{items: []}, {:remove_head, _i}), do: {{:ok, nil}, s}

  defp queue_step(s, q, {:remove_head, i}) do
    [head | rest] = q.items
    {{:ok, head}, withdraw(s, i, %{q | items: rest})}
  end

  defp queue_step(s, q, {:drain_queue, i}),
    do: {{:ok, q.items}, withdraw(s, i, %{q | items: []})}

  defp withdraw(s, i, %{items: []} = q) do
    s = put(s, i, %{q | credit: 0})
    if s.active and s.cursor == i, do: close(s), else: s
  end

  defp withdraw(s, i, q), do: put(s, i, q)
  defp put(s, i, q), do: %{s | queues: List.replace_at(s.queues, i, q)}
  defp advance(s), do: %{s | cursor: rem(s.cursor + 1, length(s.queues))}
  defp close(s), do: advance(%{s | active: false})

  defp run(s, 0, out, _fuel), do: {Enum.reverse(out), s}

  defp run(_s, _n, _out, 0),
    do: raise("naive reference work budget exceeded; shrink domain, not semantics")

  defp run(s, n, out, fuel) do
    if Enum.all?(s.queues, &(&1.items == [])) do
      {Enum.reverse(out), s}
    else
      i = s.cursor
      q = Enum.at(s.queues, i)

      cond do
        not s.active and q.items == [] ->
          run(advance(s), n, out, fuel - 1)

        not s.active ->
          run(%{put(s, i, %{q | credit: q.credit + q.quantum}) | active: true}, n, out, fuel - 1)

        true ->
          [head | rest] = q.items

          if q.credit < head.cost do
            run(close(s), n, out, fuel - 1)
          else
            served = %Scheduled{queue: i, value: head.value, cost: head.cost}
            s = put(s, i, %{q | items: rest, credit: q.credit - head.cost})
            s = if rest == [], do: close(put(s, i, %{q | items: [], credit: 0})), else: s
            run(s, n - 1, [served | out], fuel - 1)
          end
      end
    end
  end
end
