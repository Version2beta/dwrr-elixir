# Complete; do not change.
defmodule Dwrr.Stage1.T21Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "fixture driven integration serves weighted example" do
    requests = [
      %{"op" => "new", "count" => 2},
      %{"op" => "set_quantum", "queue" => 0, "quantum" => "2"},
      %{"op" => "enqueue", "queue" => 0, "items" => [%{"value" => 42, "cost" => "2"}]},
      %{"op" => "take", "n" => 2}
    ]

    input = Enum.map_join(requests, "\n", &JSON.encode!/1) <> "\n"
    {out, 0} = driver(input)
    lines = Enum.map(String.split(out, "\n", trim: true), &JSON.decode!/1)
    assert List.last(lines) == %{"ok" => [%{"queue" => 0, "value" => 42, "cost" => "2"}]}
  end

  test "documented snapshot branching" do
    s = Dwrr.new(1) |> put(0, [{:x, 1}])
    {a, empty} = take(s, 1)
    {b, _} = take(s, 1)
    assert a == b
    assert empty.total == 0
    assert s.total == 1
    audit(s)
  end
end
