defmodule Dwrr.Stage2.FairnessTest do
  use ExUnit.Case, async: true
  import Dwrr.TestSupport, only: [put: 3, quantum: 3, audit: 1]

  test "closed visits keep heterogeneous served cost within one maximum item cost of grants" do
    patterns = %{0 => [2, 7, 3, 5], 1 => [9, 4, 6, 3], 2 => [5, 13, 2, 7]}
    quanta = %{0 => 7, 1 => 11, 2 => 17}
    maximums = Map.new(patterns, fn {i, costs} -> {i, Enum.max(costs)} end)

    initial =
      Enum.reduce(0..2, Dwrr.new(3), fn i, s ->
        costs = patterns[i] |> Stream.cycle() |> Enum.take(2_000)
        items = Enum.with_index(costs, fn cost, n -> {{i, n}, cost} end)
        s |> quantum(i, quanta[i]) |> put(i, items)
      end)

    zeros = %{0 => 0, 1 => 0, 2 => 0}

    {final, _served, _visits, closed, _last} =
      Enum.reduce(1..600, {initial, zeros, zeros, zeros, nil}, fn _,
                                                                  {s, served, visits, closed,
                                                                   last} ->
        assert {:ok, [%Dwrr.Scheduled{queue: i, cost: cost}], next} = Dwrr.take(s, 1)
        assert next.active
        assert Enum.all?(next.queues, fn {_, q} -> q.size > 0 end)

        # Every quantum covers any head in its queue, so every visit serves.
        # Queue changes therefore independently count grants (no hidden idle
        # visits/skips). take(1) pauses an active visit; only the NEXT queue's
        # first output proves that the previous visit has actually closed.
        {visits, closed} =
          if i != last do
            assert i == if(last == nil, do: 0, else: rem(last + 1, 3))

            closed =
              if last == nil do
                closed
              else
                k = visits[last]
                shortfall = k * quanta[last] - served[last]
                q = next.queues[last]
                assert shortfall == q.credit
                assert shortfall >= 0
                assert shortfall < q.head.cost
                assert shortfall < maximums[last]
                Map.update!(closed, last, &(&1 + 1))
              end

            {Map.update!(visits, i, &(&1 + 1)), closed}
          else
            {visits, closed}
          end

        {next, Map.update!(served, i, &(&1 + cost)), visits, closed, i}
      end)

    assert Enum.all?(closed, fn {_, k} -> k >= 30 end)
    audit(final)
  end
end
