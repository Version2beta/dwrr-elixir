# Complete; do not change.
defmodule Dwrr.Stage1.T1Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "creates default queues" do
    s = Dwrr.new(3)
    assert s.count == 3
    assert s.cursor == 0
    refute s.active
    assert s.total == 0
    audit(s)
    assert Enum.all?(s.queues, fn {_, q} -> q.quantum == 1 end)
  end

  test "zero queues is valid" do
    s = Dwrr.new(0)
    assert s.busy == :gb_sets.empty()
    assert {[], ^s} = take(s, 100)
    audit(s)
  end

  test "outside counts raise ArgumentError" do
    for count <- [-1, 1.0, nil, "2"], do: assert_raise(ArgumentError, fn -> Dwrr.new(count) end)
  end
end
