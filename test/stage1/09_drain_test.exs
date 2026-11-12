# Complete; do not change.
defmodule Dwrr.Stage1.T9Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "drain FIFO and resets membership" do
    s = Dwrr.new(2) |> put(1, [{:a, 3}, {:b, 2}])
    {:ok, items, s} = Dwrr.drain_queue(s, 1)
    assert items == [item(:a, 3), item(:b, 2)]
    assert s.total == 0
    assert s.cursor == 0
    audit(s)
  end

  test "draining active closes visit" do
    s = Dwrr.new(2) |> quantum(0, 9) |> put(0, [{:a, 1}, {:b, 1}])
    {_, s} = take(s, 1)
    {:ok, _, s} = Dwrr.drain_queue(s, 0)
    refute s.active
    assert s.cursor == 1
    assert s.queues[0].credit == 0
    audit(s)
  end

  test "empty inactive leaves cursor" do
    s = Dwrr.new(2) |> put(0, [{:a, 1}])
    {_, s} = take(s, 1)
    assert s.cursor == 1
    assert {:ok, [], ^s} = Dwrr.drain_queue(s, 0)
  end
end
