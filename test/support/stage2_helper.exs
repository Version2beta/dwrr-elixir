# Complete; do not change.
defmodule Dwrr.Stage2Support do
  import ExUnit.Assertions
  alias Dwrr.NaiveReference, as: Ref

  def core(s, :add_queue) do
    {i, next} = Dwrr.add_queue(s)
    {{:index, i}, next}
  end

  def core(s, :remove_queue), do: {:state, Dwrr.remove_queue(s)}

  def core(s, op) do
    [name | args] = Tuple.to_list(op)

    case apply(Dwrr, name, [s | args]) do
      {:ok, next} -> {:ok, next}
      {:ok, value, next} -> {{:ok, value}, next}
      {:error, _} = error -> {error, s}
    end
  end

  def canonical(s) do
    Dwrr.TestSupport.audit(s)

    queues =
      for i <- 0..(s.count - 1)//1 do
        q = s.queues[i]

        %{
          items: if(q.head == nil, do: [], else: [q.head | :queue.to_list(q.tail)]),
          quantum: q.quantum,
          credit: q.credit
        }
      end

    %{queues: queues, cursor: s.cursor, active: s.active}
  end

  def trace(ops, s \\ Dwrr.new(3), r \\ Ref.new(3)) do
    Enum.reduce(Enum.with_index(ops), {s, r}, fn {op, index}, {s, r} ->
      {expected, r2} = Ref.step(r, op)
      {actual, s2} = core(s, op)
      # Generated data only: never use this diagnostic helper for real caller payloads.
      context = "step=#{index} op=#{inspect(op)} shrunk_trace=#{inspect(ops, limit: :infinity)}"
      assert actual === expected, context
      assert canonical(s2) === r2, context
      conserve(s, s2, op, actual)
      if match?({:error, _}, actual), do: assert(s2 === s, context)
      {s2, r2}
    end)
  end

  defp inventory(s), do: canonical(s).queues |> Enum.flat_map(& &1.items) |> Enum.frequencies()

  defp conserve(s, next, op, result) do
    {added, removed} =
      case {op, result} do
        {{:enqueue, _, items}, :ok} ->
          {items, []}

        {{:take, _}, {:ok, items}} ->
          {[], Enum.map(items, &%Dwrr.Item{value: &1.value, cost: &1.cost})}

        {{:remove_head, _}, {:ok, nil}} ->
          {[], []}

        {{:remove_head, _}, {:ok, item}} ->
          {[], [item]}

        {{:drain_queue, _}, {:ok, items}} ->
          {[], items}

        {:remove_queue, :state} ->
          {[], if(s.count == 0, do: [], else: List.last(canonical(s).queues).items)}

        _ ->
          {[], []}
      end

    combine = fn a, b -> Map.merge(a, Enum.frequencies(b), fn _, x, y -> x + y end) end
    assert combine.(inventory(s), added) === combine.(inventory(next), removed)
  end

  def fences(path) do
    Regex.scan(~r/```elixir\n(.*?)```/s, File.read!(path), capture: :all_but_first)
    |> Enum.map(&hd/1)
  end

  def eval_examples(path, expected) do
    blocks = fences(path)
    assert length(blocks) == length(expected), "#{path}: executable example count"

    Enum.zip(blocks, expected)
    |> Enum.each(fn {code, wanted} ->
      {_value, bindings} = Code.eval_string(code, [], file: path)
      assert Keyword.fetch!(bindings, :result) === wanted, "#{path}: incorrect example result"
    end)
  end

  def prose(path, patterns) do
    text = File.read!(path)

    for pattern <- patterns,
        do:
          assert(
            Regex.match?(pattern, text),
            "#{path}: missing factual contract #{inspect(pattern)}"
          )
  end
end
