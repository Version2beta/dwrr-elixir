# Complete; do not change.
defmodule Dwrr.Stage1.T14Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "productive grants do not scan all busy queues" do
    s = Enum.reduce(0..1999, Dwrr.new(2000), fn i, s -> put(s, i, [{i, 1}]) end)
    {:reductions, before_count} = Process.info(self(), :reductions)
    {out, next} = take(s, 2000)
    {:reductions, after_count} = Process.info(self(), :reductions)
    assert length(out) == 2000
    assert after_count - before_count < 1_000_000
    audit(next)
  end

  test "ties preserve nonzero cursor order" do
    s = Dwrr.new(3) |> put(0, [{:start, 1}])
    {_, s} = take(s, 1)
    assert s.cursor == 1
    s = s |> put(0, [{:a, 101}]) |> put(1, [{:b, 101}]) |> put(2, [{:c, 101}])
    assert {[{1, :b, 101}, {2, :c, 101}, {0, :a, 101}], s} = take(s, 3)
    audit(s)
  end

  test "resumed blocked visit does not break cycle accounting" do
    s =
      Dwrr.new(2)
      |> quantum(0, 2)
      |> put(0, [{:a, 1}, {:huge, 10001}])
      |> put(1, [{:other, 5001}])

    {_, s} = take(s, 1)
    assert s.active
    assert {[{0, :huge, 10001}, {1, :other, 5001}], s} = take(s, 2)
    audit(s)
  end

  test "service resets failed cycle accounting" do
    s =
      Dwrr.new(3)
      |> put(0, [{:a, 10}, {:b, 2}])
      |> put(1, [{:x, 1}, {:y, 20}])
      |> put(2, [{:z, 10}])

    assert {[{1, :x, 1}, {0, :a, 10}, {2, :z, 10}, {0, :b, 2}, {1, :y, 20}], s} = take(s, 9)
    audit(s)
  end
end
