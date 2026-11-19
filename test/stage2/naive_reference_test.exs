# Complete; do not change. Anchor oracle behavior independently of production comparisons.
Code.require_file("../support/stage2_assets_helper.exs", __DIR__)

defmodule Dwrr.Stage2.NaiveReferenceTest do
  use ExUnit.Case, async: false
  alias Dwrr.NaiveReference, as: R
  alias Dwrr.Item

  test "literal SPEC example and paused active credit" do
    s = R.new(2)
    {:ok, s} = R.step(s, {:set_quantum, 0, 2})
    {:ok, s} = R.step(s, {:set_quantum, 1, 3})
    {:ok, s} = R.step(s, {:enqueue, 0, [%Item{value: :a, cost: 2}, %Item{value: :b, cost: 2}]})
    {:ok, s} = R.step(s, {:enqueue, 1, [%Item{value: :x, cost: 4}, %Item{value: :y, cost: 1}]})
    {{:ok, [a]}, paused} = R.step(s, {:take, 1})
    assert {a.queue, a.value, a.cost} == {0, :a, 2}
    assert paused.active and paused.cursor == 0
    assert hd(paused.queues).credit == 0
    {{:ok, rest}, _} = R.step(paused, {:take, 10})
    assert Enum.map(rest, &{&1.queue, &1.value, &1.cost}) == [{0, :b, 2}, {1, :x, 4}, {1, :y, 1}]
  end

  test "ordered atomic errors, withdrawal closes active visit and last deletion repairs cursor" do
    s = R.new(2)

    {:ok, s} =
      R.step(s, {:enqueue, 1, [%Item{value: nil, cost: 1}, %Item{value: :last, cost: 1}]})

    {:ok, s} = R.step(s, {:set_quantum, 1, 5})
    {{:ok, [_]}, s} = R.step(s, {:take, 1})
    assert s.active and s.cursor == 1

    assert {{:error, :invalid_index}, ^s} =
             R.step(s, {:enqueue, 2, [%Item{value: :bad, cost: 0}]})

    assert {{:error, :zero_cost}, ^s} =
             R.step(s, {:enqueue, 1, [%Item{value: :good, cost: 1}, %Item{value: :bad, cost: 0}]})

    {{:ok, %Item{value: :last}}, empty} = R.step(s, {:remove_head, 1})
    assert empty.cursor == 0 and not empty.active
    assert Enum.at(empty.queues, 1).credit == 0
    {:state, removed} = R.step(s, :remove_queue)
    assert removed.cursor == 0 and not removed.active
    assert length(removed.queues) == 1
  end

  test "oracle has explicit work cap, not optimized numeric skipping" do
    {:ok, s} =
      R.step(R.new(1), {:enqueue, 0, [%Item{value: :huge, cost: 9_223_372_036_854_775_807}]})

    assert_raise RuntimeError, ~r/work budget exceeded/, fn -> R.step(s, {:take, 1}) end
    source = File.read!("test/support/naive_reference_helper.exs")
    refute Regex.match?(~r/Dwrr\.(Core|TestSupport)|:queue\.|:gb_sets\.|div\(/, source)
  end
end
