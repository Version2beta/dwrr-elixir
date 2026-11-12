# Complete; do not change.
defmodule Dwrr.Stage1.T18Test do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport
  @moduletag timeout: 30_000
  test "random small" do
    replay("random-small.jsonl", 1000, 23659)
  end

  test "random large" do
    replay("random-large.jsonl", 500, 13933)
  end

  test "random skip" do
    replay("random-skip.jsonl", 300, 6773)
  end
end
