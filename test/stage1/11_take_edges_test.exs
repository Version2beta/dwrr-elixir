# Complete; do not change.
defmodule Dwrr.Stage1.T11Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "zero and empty preserve state" do
    s = Dwrr.new(2) |> put(0, [{:a, 1}])
    assert {:ok, [], ^s} = Dwrr.take(s, 0)
    {_, s} = take(s, 1)
    assert s.cursor == 1
    assert {:ok, [], ^s} = Dwrr.take(s, 100)
    audit(s)
  end

  test "negative is tagged before emptiness" do
    for count <- [0, 1] do
      s = Dwrr.new(count)
      assert {:error, :negative_take} == Dwrr.take(s, -1)
      audit(s)
    end

    s = Dwrr.new(1) |> put(0, [{:valid, 1}])
    assert {[{0, :valid, 1}], _} = take(s, 1)
  end

  test "outside take type raises" do
    s = Dwrr.new(1)
    for n <- [1.0, nil, "1"], do: assert_raise(ArgumentError, fn -> Dwrr.take(s, n) end)
  end
end
