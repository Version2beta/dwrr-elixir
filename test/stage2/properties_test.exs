# Complete; do not change. Bounded domains are part of the oracle safety contract.
Code.require_file("../support/stage2_assets_helper.exs", __DIR__)

defmodule Dwrr.Stage2.PropertiesTest do
  use ExUnit.Case, async: false
  use ExUnitProperties
  import Dwrr.Stage2Support
  import Dwrr.TestSupport, only: [item: 1, item: 2, put: 3, quantum: 3, max_cost: 0]
  @moduletag timeout: 30_000

  defp operation(costs, quanta, allow_resize \\ true) do
    i = integer(-1..4)

    value =
      one_of([
        integer(-20..20),
        binary(max_length: 10),
        constant(nil),
        constant({:opaque, :value})
      ])

    items = list_of(map({value, costs}, fn {v, c} -> item(v, c) end), max_length: 3)

    base = [
      map({i, items}, fn {i, items} -> {:enqueue, i, items} end),
      map({i, quanta}, fn {i, q} -> {:set_quantum, i, q} end),
      map(integer(-1..8), &{:take, &1}),
      map(i, &{:remove_head, &1}),
      map(i, &{:drain_queue, &1})
    ]

    one_of(
      if allow_resize, do: base ++ [constant(:add_queue), constant(:remove_queue)], else: base
    )
  end

  property "mixed operations compare every result/state, conservation, errors and deterministic replay" do
    check all(
            ops <-
              list_of(
                operation(
                  one_of([integer(0..8), constant(max_cost() + 1)]),
                  one_of([integer(0..5), constant(max_cost() + 1)])
                ),
                min_length: 1,
                max_length: 60
              ),
            max_runs: 100
          ) do
      assert trace(ops) === trace(ops)
    end
  end

  property "split take preserves service order and paused visit state" do
    check all(
            costs <- list_of(integer(1..12), min_length: 1, max_length: 24),
            q <- integer(1..8),
            a <- integer(0..24),
            b <- integer(0..24),
            max_runs: 80
          ) do
      s =
        costs
        |> Enum.with_index()
        |> Enum.reduce(Dwrr.new(3), fn {cost, n}, s ->
          put(s, rem(n, 3), [{{n, cost}, cost}])
        end)
        |> quantum(0, q)

      {:ok, all, final} = Dwrr.take(s, a + b)
      {:ok, left, next} = Dwrr.take(s, a)
      {:ok, right, split} = Dwrr.take(next, b)
      assert left ++ right === all
      assert canonical(split) === canonical(final)
      trace([{:take, a}, {:take, b}], s, canonical(s))
    end
  end

  property "arbitrary opaque values and immutable branches survive independent histories" do
    check all(
            values <- list_of(term(), min_length: 1, max_length: 12),
            max_runs: 60,
            max_size: 12
          ) do
      values = [self(), make_ref(), fn x -> x end, 1, 1.0, nil | values]
      s = Dwrr.new(1)
      {:ok, s} = Dwrr.enqueue(s, 0, Enum.map(values, &item/1))
      before = canonical(s)
      {:ok, taken, _} = Dwrr.take(s, length(values))
      {:ok, drained, empty} = Dwrr.drain_queue(s, 0)
      assert Enum.map(taken, & &1.value) === values
      assert Enum.map(drained, & &1.value) === values
      assert canonical(s) === before
      assert empty.total == 0
      trace([{:take, length(values)}], s, before)
    end
  end

  property "near-limit differential work stays bounded by large quanta, never huge cost/q1" do
    half = div(max_cost(), 2) + 1

    check all(
            ops <-
              list_of(
                operation(
                  one_of([
                    integer(1..8),
                    integer((max_cost() - 5)..max_cost()),
                    constant(0),
                    constant(max_cost() + 1)
                  ]),
                  one_of([integer(half..max_cost()), constant(0), constant(max_cost() + 1)]),
                  false
                ),
                max_length: 35
              ),
            max_runs: 60
          ) do
      initial = for i <- 0..2, do: {:set_quantum, i, half}
      trace(initial ++ ops)
    end
  end

  property "generated boundary errors preserve state, ordering and accepted exact integers" do
    check all(offset <- integer(0..100), i <- member_of([-1, 0, 1]), max_runs: 60) do
      m = max_cost()

      ops = [
        {:set_quantum, 0, m},
        {:enqueue, 0, [item(:exact, m - offset)]},
        {:enqueue, i, [item(:valid), item(:zero, 0), item(:large, m + 1)]},
        {:enqueue, i, [item(:large, m + 1), item(:zero, 0)]},
        {:set_quantum, i, m + 1},
        {:take, 1},
        {:take, -1}
      ]

      trace(ops, Dwrr.new(1), Dwrr.NaiveReference.new(1))
    end
  end

  property "peak credit reaches legal bound before debit after head exposure and reweight" do
    check all(delta <- integer(0..100), max_runs: 30) do
      m = max_cost() - delta

      s =
        Dwrr.new(2)
        |> put(0, [{:block, m}, {:cheap, 1}, {:next, m}])
        |> put(1, [{:trigger, m - 1}])

      {:ok, [%Dwrr.Scheduled{value: :trigger}], s} = Dwrr.take(s, 1)
      assert s.queues[0].credit == m - 1
      {:ok, _, s} = Dwrr.remove_head(s, 0)
      s = quantum(s, 0, max_cost())
      {:ok, [%Dwrr.Scheduled{value: :cheap, cost: 1}], next} = Dwrr.take(s, 1)
      assert next.queues[0].credit + 1 == m - 1 + max_cost()
      Dwrr.TestSupport.audit(next)
    end
  end

  property "bounded stable unit-cost backlog receives exact shares across reweight, no starvation" do
    check all(
            a <- integer(1..5),
            b <- integer(1..5),
            c <- integer(1..5),
            d <- integer(1..5),
            max_runs: 60
          ) do
      s = Dwrr.new(2) |> quantum(0, a) |> quantum(1, b)
      s = put(s, 0, Enum.map(1..100, &{{0, &1}, 1})) |> put(1, Enum.map(1..100, &{{1, &1}, 1}))
      {:ok, first, s} = Dwrr.take(s, 2 * (a + b))
      assert Enum.frequencies_by(first, & &1.queue) == %{0 => 2 * a, 1 => 2 * b}
      s = s |> quantum(0, c) |> quantum(1, d)
      {:ok, second, next} = Dwrr.take(s, 3 * (c + d))
      assert Enum.frequencies_by(second, & &1.queue) == %{0 => 3 * c, 1 => 3 * d}
      assert Enum.all?(canonical(next).queues, &(length(&1.items) > 0))
      trace([{:take, 3 * (c + d)}], s, canonical(s))
    end
  end

  property "huge cost quantum one uses analytic cyclic ties with bounded productive work" do
    check all(delta <- integer(0..100), max_runs: 30) do
      cost = max_cost() - delta
      s = Dwrr.new(3) |> put(0, [{:start, 1}])
      {:ok, _, s} = Dwrr.take(s, 1)
      s = Enum.reduce(0..2, s, fn i, s -> put(s, i, [{i, cost}]) end)
      {:reductions, before} = Process.info(self(), :reductions)
      {:ok, out, next} = Dwrr.take(s, 3)
      {:reductions, after_count} = Process.info(self(), :reductions)

      assert Enum.map(out, &{&1.queue, &1.value, &1.cost}) == [
               {1, 1, cost},
               {2, 2, cost},
               {0, 0, cost}
             ]

      assert after_count - before < 20_000
      assert next.total == 0
      Dwrr.TestSupport.audit(next)
    end
  end
end
