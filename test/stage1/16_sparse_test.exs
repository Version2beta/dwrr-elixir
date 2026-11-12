# Complete; do not change.
defmodule Dwrr.Stage1.T16Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "far busy queue selected without empty scans" do
    s = Dwrr.new(20_000) |> put(19_999, [{:a, 1}, {:b, 1}])
    {before, _} = Process.info(self(), :reductions) |> then(fn {_, n} -> {n, nil} end)
    assert {[{19_999, :a, 1}, {19_999, :b, 1}], s} = take(s, 2)
    {:reductions, afterwards} = Process.info(self(), :reductions)
    assert afterwards - before < 20_000
    audit(s)
  end

  test "busy transitions across mutations" do
    s = Dwrr.new(4) |> put(1, [{:a, 1}]) |> put(3, [{:b, 1}])
    {:ok, _, s} = Dwrr.drain_queue(s, 1)
    s = Dwrr.remove_queue(s)
    s = put(s, 2, [{:c, 1}])
    assert {[{2, :c, 1}], s} = take(s, 9)
    assert :gb_sets.is_empty(s.busy)
    audit(s)
  end

  test "long FIFO pushes and pops preserve order" do
    items = Enum.map(1..2000, &{&1, 1})
    s = Dwrr.new(1) |> put(0, items)
    {out, s} = take(s, 2000)
    assert Enum.map(out, fn {_, v, _} -> v end) == Enum.to_list(1..2000)
    audit(s)
  end
end
