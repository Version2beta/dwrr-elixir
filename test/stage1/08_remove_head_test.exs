# Complete; do not change.
defmodule Dwrr.Stage1.T8Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "withdraw does not debit remaining credit" do
    s = Dwrr.new(1) |> quantum(0, 8) |> put(0, [{:a, 1}, {:b, 4}, {:c, 5}])
    {_, s} = take(s, 1)
    {:ok, b, s2} = Dwrr.remove_head(s, 0)
    assert b == item(:b, 4)
    assert s2.active
    assert s2.queues[0].credit == 7
    assert {[{0, :c, 5}], _} = take(s2, 1)
  end

  test "emptying active closes and resets" do
    s = Dwrr.new(2) |> quantum(0, 5) |> put(0, [{:a, 1}, {:b, 1}])
    {_, s} = take(s, 1)
    {:ok, _, s} = Dwrr.remove_head(s, 0)
    refute s.active
    assert s.cursor == 1
    assert s.queues[0].credit == 0
    audit(s)
  end

  test "empty removal is no-op" do
    s = Dwrr.new(1)
    assert {:ok, nil, ^s} = Dwrr.remove_head(s, 0)
    s = put(s, 0, [{nil, 1}])
    assert {:ok, %Dwrr.Item{value: nil}, _} = Dwrr.remove_head(s, 0)
  end
end
