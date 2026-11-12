# Complete; do not change.
defmodule Dwrr.Stage1.T3Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "accepts inclusive limits" do
    s = Dwrr.new(1)

    for q <- [1, 9_007_199_254_740_993, max_cost()] do
      s2 = quantum(s, 0, q)
      assert s2.queues[0].quantum == q
      audit(s2)
    end
  end

  test "zero and too large are tagged" do
    s = Dwrr.new(1)
    assert {:error, :zero_quantum} == Dwrr.set_quantum(s, 0, 0)
    assert {:error, :quantum_too_large} == Dwrr.set_quantum(s, 0, max_cost() + 1)
    assert quantum(s, 0, 7).queues[0].quantum == 7
  end

  test "outside quantum types raise" do
    s = Dwrr.new(1)
    for q <- [-1, 1.0, nil], do: assert_raise(ArgumentError, fn -> Dwrr.set_quantum(s, 0, q) end)
    assert s.queues[0].credit == 0
  end

  test "reweight preserves active credit" do
    s = Dwrr.new(1) |> quantum(0, 5) |> put(0, [{:a, 1}, {:b, 10}])
    {_, s} = take(s, 1)
    assert s.active
    s2 = quantum(s, 0, 2)
    assert s2.queues[0].credit == 4
    assert s2.active
    assert quantum(s2, 0, 2) === s2
  end
end
