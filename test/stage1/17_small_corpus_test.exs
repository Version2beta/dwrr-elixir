# Complete; do not change.
defmodule Dwrr.Stage1.T17Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "examples" do
    replay("examples.jsonl", 2, 15)
  end

  test "edge cases" do
    replay("edge-cases.jsonl", 20, 225)
  end

  test "errors" do
    replay("errors.jsonl", 10, 70)
  end

  test "boundaries" do
    replay("boundaries.jsonl", 7, 53)
  end
end
