# Complete; do not change. Native replay deliberately does not call the driver adapter.
defmodule Dwrr.TestSupport do
  import ExUnit.Assertions
  alias Dwrr.{Item, Scheduled}
  @root Path.expand("../fixtures/dwrr-spec", __DIR__)
  @max 9_223_372_036_854_775_807
  def max_cost, do: @max
  def item(value, cost \\ 1), do: %Item{value: value, cost: cost}

  def put(s, index, pairs) do
    {:ok, next} = Dwrr.enqueue(s, index, Enum.map(pairs, fn {v, c} -> item(v, c) end))
    next
  end

  def quantum(s, index, q) do
    {:ok, next} = Dwrr.set_quantum(s, index, q)
    next
  end

  def take(s, n) do
    {:ok, out, next} = Dwrr.take(s, n)
    {Enum.map(out, fn %Scheduled{queue: q, value: v, cost: c} -> {q, v, c} end), next}
  end

  def audit(s) do
    assert %Dwrr{} = s
    assert map_size(s.queues) == s.count

    assert Enum.sort(Map.keys(s.queues)) ==
             if(s.count == 0, do: [], else: Enum.to_list(0..(s.count - 1)))

    busy = for {i, q} <- s.queues, q.size > 0, do: i
    assert :gb_sets.to_list(s.busy) == Enum.sort(busy)
    assert s.total == Enum.reduce(s.queues, 0, fn {_, q}, acc -> acc + q.size end)
    assert if(s.count == 0, do: s.cursor == 0, else: s.cursor >= 0 and s.cursor < s.count)
    if s.active, do: assert(s.queues[s.cursor].size > 0)

    for {_, q} <- s.queues do
      tail = :queue.to_list(q.tail)
      assert q.size == length(tail) + if(q.head == nil, do: 0, else: 1)
      assert q.quantum >= 1 and q.quantum <= @max
      assert q.credit >= 0 and q.credit <= 2 * @max - 1

      if q.size == 0 do
        assert q.credit == 0
        assert q.head == nil
      else
        assert %Item{} = q.head
        for it <- [q.head | tail], do: assert(it.cost >= 1 and it.cost <= @max)
      end
    end

    s
  end

  def native(s, %{"op" => op} = r) do
    result =
      case op do
        "new" ->
          {:state, Dwrr.new(r["count"])}

        "enqueue" ->
          Dwrr.enqueue(
            s,
            r["queue"],
            Enum.map(r["items"], fn it -> item(it["value"], String.to_integer(it["cost"])) end)
          )

        "set_quantum" ->
          Dwrr.set_quantum(s, r["queue"], String.to_integer(r["quantum"]))

        "add_queue" ->
          {i, next} = Dwrr.add_queue(s)
          {:value, i, next}

        "remove_queue" ->
          {:state, Dwrr.remove_queue(s)}

        "remove_head" ->
          Dwrr.remove_head(s, r["queue"])

        "drain_queue" ->
          Dwrr.drain_queue(s, r["queue"])

        "take" ->
          Dwrr.take(s, r["n"])
      end

    case result do
      {:state, next} -> {audit(next), %{"ok" => nil}}
      {:value, v, next} -> {audit(next), %{"ok" => v}}
      {:ok, next} -> {audit(next), %{"ok" => nil}}
      {:ok, v, next} -> {audit(next), %{"ok" => wire(v)}}
      {:error, code} -> {audit(s), %{"error" => Atom.to_string(code)}}
    end
  end

  def wire(nil), do: nil

  def wire(%Scheduled{queue: q, value: v, cost: c}),
    do: %{"queue" => q, "value" => v, "cost" => Integer.to_string(c)}

  def wire(%Item{value: v, cost: c}), do: %{"value" => v, "cost" => Integer.to_string(c)}
  def wire(list) when is_list(list), do: Enum.map(list, &wire/1)

  def replay(file, cases, steps) do
    path = Path.join([@root, "corpus", file])
    manifest = JSON.decode!(File.read!(Path.join(@root, "PROVENANCE.json")))
    assert manifest["commit"] == "8a0e3cf9ae860ba207213590c00feeb822bdd8f2"
    bytes = File.read!(path)
    hash = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
    assert hash == manifest["files"][file]["sha256"]
    rows = bytes |> String.split("\n", trim: true) |> Enum.map(&JSON.decode!/1)
    assert length(rows) == cases
    assert Enum.sum(Enum.map(rows, &length(&1["steps"]))) == steps

    for row <- rows do
      Enum.reduce(Enum.with_index(row["steps"], 1), nil, fn {step, n}, s ->
        {next, actual} = native(s, step["request"])

        assert actual == step["response"],
               "#{file}: #{row["name"]} step #{n}: #{inspect(step["request"])} expected #{inspect(step["response"])} got #{inspect(actual)}"

        next
      end)
    end
  end

  def driver(input) do
    # Fixed executable/arguments, payload is an ignored temporary file, never shell interpolation.
    path = Path.join(System.tmp_dir!(), "dwrr-driver-#{System.unique_integer([:positive])}.jsonl")
    File.write!(path, input)

    try do
      args = [
        "-c",
        "exec mix run --no-compile --no-start scripts/conformance_driver.exs < \"$1\"",
        "dwrr-driver",
        path
      ]

      System.cmd("sh", args, env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)
    after
      File.rm!(path)
    end
  end
end
