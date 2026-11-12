# Complete; do not change.
defmodule Dwrr.Stage1.T15Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "maximum cost quantum one skips directly" do
    s = Dwrr.new(1) |> put(0, [{:max, max_cost()}])
    m = max_cost()
    assert {[{0, :max, ^m}], s} = take(s, 1)
    audit(s)
  end

  test "peak credit is exact" do
    m = max_cost()

    s =
      Dwrr.new(2) |> put(0, [{:block, m}, {:cheap, 1}, {:next, m}]) |> put(1, [{:trigger, m - 1}])

    {_, s} = take(s, 1)
    assert s.queues[0].credit == m - 1
    {:ok, _, s} = Dwrr.remove_head(s, 0)
    s = quantum(s, 0, m)
    {[{0, :cheap, 1}], s} = take(s, 1)
    assert s.queues[0].credit == 2 * m - 2
    assert s.active
    audit(s)
  end

  test "no safe integer truncation" do
    c = 9_007_199_254_740_993
    s = Dwrr.new(1) |> quantum(0, c) |> put(0, [{:exact, c}])
    assert {[{0, :exact, ^c}], s} = take(s, 1)
    audit(s)
  end
end
