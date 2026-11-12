# Complete; do not change.
defmodule Dwrr.Stage1.T5Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "opaque values round trip exactly" do
    values = [nil, 1, 1.0, %{nested: [self(), make_ref()]}, {:tuple, <<0, 255>>}]
    s = Dwrr.new(1)
    {:ok, s} = Dwrr.enqueue(s, 0, Enum.map(values, &item/1))
    {:ok, out, s2} = Dwrr.drain_queue(s, 0)
    assert Enum.map(out, & &1.value) === values
    audit(s2)
  end

  test "append after head removal is FIFO" do
    s = Dwrr.new(1) |> put(0, [{:a, 1}, {:b, 2}, {:c, 3}])
    {:ok, _, s} = Dwrr.remove_head(s, 0)
    s = put(s, 0, [{:d, 4}])
    {:ok, out, s} = Dwrr.drain_queue(s, 0)
    assert Enum.map(out, & &1.value) == [:b, :c, :d]
    audit(s)
  end

  test "empty enqueue is exact no-op" do
    s = Dwrr.new(1) |> put(0, [{:a, 1}])
    assert {:ok, ^s} = Dwrr.enqueue(s, 0, [])
    assert s.total == 1
  end
end
