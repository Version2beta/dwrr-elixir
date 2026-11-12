# Complete; do not change.
defmodule Dwrr.Stage1.T6Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "indices append from zero" do
    s = Dwrr.new(0)
    {0, s} = Dwrr.add_queue(s)
    {1, s} = Dwrr.add_queue(s)
    assert s.count == 2
    assert s.queues[1].quantum == 1
    assert s.queues[1].credit == 0
    audit(s)
  end

  test "append preserves active visit" do
    s = Dwrr.new(1) |> quantum(0, 4) |> put(0, [{:a, 1}, {:b, 1}])
    {_, s} = take(s, 1)
    {1, s2} = Dwrr.add_queue(s)
    assert s2.active
    assert s2.cursor == s.cursor
    assert s2.queues[0] === s.queues[0]
    audit(s2)
  end
end
