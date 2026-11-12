# Complete; do not change.
defmodule Dwrr.Stage1.T7Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "drop only last including contents" do
    s = Dwrr.new(3) |> put(0, [{:a, 1}]) |> put(2, [{:lost, 1}])
    s = Dwrr.remove_queue(s)
    assert s.count == 2
    assert s.total == 1
    assert {[{0, :a, 1}], s} = take(s, 10)
    audit(s)
  end

  test "remove active last cancels and wraps" do
    s = Dwrr.new(2) |> put(1, [{:a, 1}, {:b, 1}]) |> quantum(1, 3)
    {_, s} = take(s, 1)
    assert s.active and s.cursor == 1
    s = Dwrr.remove_queue(s)
    assert s.cursor == 0
    refute s.active
    audit(s)
  end

  test "zero and inactive cursor wrap" do
    s = Dwrr.new(0)
    assert Dwrr.remove_queue(s) === s
    s = Dwrr.new(2) |> put(0, [{:x, 1}])
    {_, s} = take(s, 1)
    assert s.cursor == 1
    s = Dwrr.remove_queue(s)
    assert s.cursor == 0
    s = Dwrr.remove_queue(s)
    assert s.count == 0
    audit(s)
  end

  test "removing other queue preserves active" do
    s = Dwrr.new(2) |> put(0, [{:a, 1}, {:b, 1}]) |> quantum(0, 4)
    {_, s} = take(s, 1)
    s2 = Dwrr.remove_queue(s)
    assert s2.active
    assert s2.queues[0] === s.queues[0]
    audit(s2)
  end
end
