# Complete; do not change.
defmodule Dwrr.Stage1.T2Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "all queue operations reject invalid indexes" do
    s = Dwrr.new(1) |> put(0, [{:kept, 1}])

    for i <- [-1, 1, 999] do
      assert {:error, :invalid_index} == Dwrr.enqueue(s, i, [])
      assert {:error, :invalid_index} == Dwrr.set_quantum(s, i, 0)
      assert {:error, :invalid_index} == Dwrr.remove_head(s, i)
      assert {:error, :invalid_index} == Dwrr.drain_queue(s, i)
    end

    assert {[{0, :kept, 1}], _} = take(s, 1)
  end

  test "index precedes shared value errors" do
    s = Dwrr.new(0)
    assert {:error, :invalid_index} == Dwrr.enqueue(s, 0, [item(:x, 0)])
    assert {:error, :invalid_index} == Dwrr.set_quantum(s, -1, max_cost() + 1)
    {0, s} = Dwrr.add_queue(s)
    assert {:ok, _} = Dwrr.enqueue(s, 0, [item(:x)])
  end

  test "noninteger indexes raise" do
    s = Dwrr.new(1)

    for i <- [nil, "0", 0.0] do
      assert_raise ArgumentError, fn -> Dwrr.enqueue(s, i, []) end
      assert_raise ArgumentError, fn -> Dwrr.set_quantum(s, i, 1) end
      assert_raise ArgumentError, fn -> Dwrr.remove_head(s, i) end
      assert_raise ArgumentError, fn -> Dwrr.drain_queue(s, i) end
    end

    assert s.count == 1
  end
end
