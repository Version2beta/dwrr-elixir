# Complete; do not change.
defmodule Dwrr.Stage1.T10Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "exact affordability serves immediately" do
    s =
      Dwrr.new(2)
      |> quantum(0, 2)
      |> quantum(1, 3)
      |> put(0, [{:a, 2}, {:b, 2}])
      |> put(1, [{:x, 4}, {:y, 1}])

    assert {[{0, :a, 2}, {0, :b, 2}, {1, :x, 4}, {1, :y, 1}], s} = take(s, 10)
    audit(s)
  end

  test "blocked head prevents cheaper overtaking" do
    s = Dwrr.new(2) |> put(0, [{:expensive, 3}, {:cheap, 1}]) |> put(1, [{:other, 2}])
    assert {[{1, :other, 2}, {0, :expensive, 3}, {0, :cheap, 1}], s} = take(s, 10)
    audit(s)
  end

  test "emptying resets excess credit" do
    s = Dwrr.new(2) |> quantum(0, 100) |> put(0, [{:a, 1}])
    {_, s} = take(s, 1)
    assert s.queues[0].credit == 0
    assert s.cursor == 1
    refute s.active
    audit(s)
  end
end
