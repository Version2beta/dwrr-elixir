# Complete; do not change.
defmodule Dwrr.Stage1.T12Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "retrieval limit preserves active credit" do
    s = Dwrr.new(2) |> quantum(0, 3) |> put(0, [{:a, 1}, {:b, 1}, {:c, 1}]) |> put(1, [{:x, 1}])
    {[{0, :a, 1}], s} = take(s, 1)
    assert s.active
    assert s.queues[0].credit == 2
    assert {[{0, :b, 1}, {0, :c, 1}, {1, :x, 1}], _} = take(s, 3)
  end

  test "blocked paused head gets no duplicate grant" do
    s = Dwrr.new(2) |> quantum(0, 2) |> put(0, [{:a, 1}, {:b, 3}]) |> put(1, [{:x, 1}])
    {_, s} = take(s, 1)
    assert s.active
    assert {[{1, :x, 1}, {0, :b, 3}], s} = take(s, 2)
    audit(s)
  end

  test "split take matches bulk and snapshots remain valid" do
    s =
      Dwrr.new(2)
      |> quantum(0, 4)
      |> put(0, [{:a, 2}, {:b, 3}, {:c, 1}])
      |> put(1, [{:x, 2}, {:y, 1}])

    {all, final} = take(s, 5)
    {a, s1} = take(s, 1)
    {b, s2} = take(s1, 4)
    assert a ++ b == all
    assert s2 === final
    assert s.total == 5
  end
end
