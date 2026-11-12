# Complete; do not change.
defmodule Dwrr.Stage1.T13Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "enqueue joins active visit" do
    s = Dwrr.new(2) |> quantum(0, 3) |> put(0, [{:a, 1}, {:b, 1}]) |> put(1, [{:x, 1}])
    {_, s} = take(s, 1)
    s = put(s, 0, [{:c, 1}])
    assert {[{0, :b, 1}, {0, :c, 1}, {1, :x, 1}], _} = take(s, 3)
  end

  test "new quantum waits until next grant" do
    s = Dwrr.new(2) |> quantum(0, 2) |> put(0, [{:a, 1}, {:b, 2}]) |> put(1, [{:x, 1}])
    {_, s} = take(s, 1)
    s = quantum(s, 0, 100)
    assert s.queues[0].credit == 1
    assert {[{1, :x, 1}, {0, :b, 2}], _} = take(s, 2)
  end

  test "head exposure preserves credit" do
    s = Dwrr.new(2) |> put(0, [{:large, 100}, {:cheap, 1}]) |> put(1, [{:x, 2}])
    {_, s} = take(s, 1)
    assert s.queues[0].credit == 2
    {:ok, _, s} = Dwrr.remove_head(s, 0)
    assert {[{0, :cheap, 1}], _} = take(s, 1)
  end
end
