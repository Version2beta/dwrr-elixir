# Complete; do not change.
defmodule Dwrr.Stage1.T19Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "translates constructor add remove" do
    alias Dwrr.Conformance.Adapter, as: A
    {s, %{"ok" => nil}} = A.apply(nil, {:new, 1})
    {s, %{"ok" => 1}} = A.apply(s, :add_queue)
    {s, %{"ok" => nil}} = A.apply(s, :remove_queue)
    assert s.count == 1
    audit(s)
  end

  test "translates core item and scheduled results" do
    alias Dwrr.Conformance.Adapter, as: A
    {s, _} = A.apply(nil, {:new, 1})
    {s, %{"ok" => nil}} = A.apply(s, {:enqueue, 0, [item(10, 2), item(11, 3)]})
    {s, %{"ok" => [%{"queue" => 0, "value" => 10, "cost" => "2"}]}} = A.apply(s, {:take, 1})
    {s, %{"ok" => %{"value" => 11, "cost" => "3"}}} = A.apply(s, {:remove_head, 0})
    {s, %{"ok" => []}} = A.apply(s, {:drain_queue, 0})
    audit(s)
  end

  test "scheduler errors retain state and require new" do
    alias Dwrr.Conformance.Adapter, as: A
    assert_raise ArgumentError, fn -> A.apply(nil, {:take, 1}) end
    s = Dwrr.new(1)
    assert {^s, %{"error" => "zero_cost"}} = A.apply(s, {:enqueue, 0, [item(1, 0)]})
    {s, %{"ok" => nil}} = A.apply(s, {:set_quantum, 0, max_cost()})
    assert s.queues[0].quantum == max_cost()
  end
end
