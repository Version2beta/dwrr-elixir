# Historical release gate; docs-only review instructions are a separate procedure.
Code.require_file("../support/stage2_assets_helper.exs", __DIR__)

defmodule Dwrr.Stage2.ReleaseDocsTest do
  use ExUnit.Case, async: false
  import Dwrr.Stage2Support

  test "changelog is initial Elixir release, not invented Go history or publication" do
    text = File.read!("CHANGELOG.md")
    assert Regex.scan(~r/^## /m, text) |> length() == 1

    prose("CHANGELOG.md", [
      ~r/## 0\.1\.0/,
      ~r/unreleased/i,
      ~r/immutable/,
      ~r/Server/,
      ~r/0\.1\.1/,
      ~r/not.*published/i
    ])

    refute text =~ "0.10.1"
  end

  test "release guide orders verification, package inspection and explicit owner-only publication" do
    prose("RELEASING.md", [
      ~r/owner/i,
      ~r/hex.pm\/packages\/dwrr/,
      ~r/hexdocs.pm\/dwrr/,
      ~r/https:\/\/github.com\/version2beta\/dwrr-elixir/,
      ~r/credentials/i,
      ~r/mix hex.build/,
      ~r/mix hex.publish/,
      ~r/git tag.*v0\.1\.0/,
      ~r/MIT/,
      ~r/minimum/i,
      ~r/check_driver.py/,
      ~r/no.*publication.*preparation/is
    ])

    [_, historical] = String.split(File.read!("RELEASING.md"), "## Step 1:", parts: 2)
    text = historical
    [_, verify] = :binary.match(text, "mix test") |> Tuple.to_list()
    assert verify > 0
    {check, _} = :binary.match(text, "mix test")
    {build, _} = :binary.match(text, "mix hex.build")
    {publish, _} = :binary.match(text, "mix hex.publish")
    assert check < build and build < publish
  end
end
