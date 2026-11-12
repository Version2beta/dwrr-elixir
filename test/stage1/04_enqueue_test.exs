# Complete; do not change.
defmodule Dwrr.Stage1.T4Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "ordered validation rejects whole batch" do
    s = Dwrr.new(1) |> put(0, [{:old, 1}])

    assert {:error, :zero_cost} ==
             Dwrr.enqueue(s, 0, [item(:valid), item(:bad, 0), item(:large, max_cost() + 1)])

    assert {[{0, :old, 1}], _} = take(s, 100)
  end

  test "first too large wins" do
    s = Dwrr.new(1)

    assert {:error, :cost_too_large} ==
             Dwrr.enqueue(s, 0, [item(:big, max_cost() + 1), item(:zero, 0)])

    assert {:ok, s} = Dwrr.enqueue(s, 0, [item(:max, max_cost())])
    assert s.total == 1
    audit(s)
  end

  test "invalid shapes and negative costs raise" do
    s = Dwrr.new(1)

    for items <- [
          [item(:bad, -1)],
          [item(:bad, 1.0)],
          [%{value: 1, cost: 1}],
          nil,
          [item(:x) | :bad]
        ],
        do: assert_raise(ArgumentError, fn -> Dwrr.enqueue(s, 0, items) end)

    assert {:ok, _} = Dwrr.enqueue(s, 0, [item(:good)])
  end
end
