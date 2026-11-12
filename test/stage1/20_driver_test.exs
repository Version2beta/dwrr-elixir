# Complete; do not change.
defmodule Dwrr.Stage1.T20Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "real process responds and EOF exits zero" do
    {out, 0} =
      driver(
        "{\"op\":\"new\",\"count\":1}\n{\"op\":\"enqueue\",\"queue\":0,\"items\":[{\"value\":7,\"cost\":\"1\"}]}\n{\"op\":\"take\",\"n\":1}\n"
      )

    assert Enum.map(String.split(out, "\n", trim: true), &JSON.decode!/1) == [
             %{"ok" => nil},
             %{"ok" => nil},
             %{"ok" => [%{"queue" => 0, "value" => 7, "cost" => "1"}]}
           ]
  end

  test "bad line exits two without later response" do
    {out, 2} = driver("{\"op\":\"new\",\"count\":1}\n\n{\"op\":\"take\",\"n\":1}\n")
    assert String.starts_with?(out, "{\"ok\":null}\n")
    assert String.contains?(out, "protocol error")
    assert length(String.split(out, "{\"ok\"")) == 2
  end

  test "protocol first canonical and ignored extras" do
    alias Dwrr.Conformance.Parser, as: P
    assert {:ok, {:new, 1}} = P.parse(~s({"op":"new","count":1,"extra":false}))

    for cost <- ["01", "+1", " 1", "1.0", "1\n", "18446744073709551616"] do
      line =
        JSON.encode!(%{
          "op" => "enqueue",
          "queue" => 99,
          "items" => [%{"value" => 1, "cost" => cost}]
        })

      assert {:error, :protocol} = P.parse(line)
    end

    {out, 2} =
      driver(
        "{\"op\":\"new\",\"count\":1}\n{\"op\":\"enqueue\",\"queue\":99,\"items\":[{\"value\":1,\"cost\":\"01\"}]}\n"
      )

    refute String.contains?(out, "invalid_index")
  end

  test "wire numeric types and required fields" do
    assert Dwrr.new(1).count == 1
    alias Dwrr.Conformance.Parser, as: P

    for line <- [
          ~s({"op":"new","count":1e0}),
          ~s({"op":"take","n":true}),
          ~s({"op":"new","count":-1}),
          ~s({"op":"remove_head"}),
          "[]",
          ""
        ] do
      assert {:error, :protocol} = P.parse(line)
    end

    assert {:ok, {:take, -1}} = P.parse(~s({"op":"take","n":-1}))
  end
end
