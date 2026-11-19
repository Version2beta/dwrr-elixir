# Complete; do not change.
defmodule Dwrr.Stage2.CITest do
  use ExUnit.Case, async: false

  test "complete protected workflow retains its reviewed byte identity" do
    recorded = JSON.decode!(File.read!("test/fixtures/stage2-ci-sha256.json"))
    actual = :crypto.hash(:sha256, File.read!(recorded["path"])) |> Base.encode16(case: :lower)
    assert actual == recorded["sha256"]
  end
end
