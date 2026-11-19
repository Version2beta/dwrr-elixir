# Complete; do not change.
Code.require_file("../support/stage2_assets_helper.exs", __DIR__)

defmodule Dwrr.Stage2.ReadmeTest do
  use ExUnit.Case, async: false
  import Dwrr.Stage2Support

  test "README examples execute the declared byte sharing, owned worker and withdrawal histories" do
    eval_examples("README.md", [
      [{0, :packet_a, 2}, {0, :packet_b, 2}, {1, :packet_x, 4}, {1, :packet_y, 1}],
      [:job_a, :job_b],
      {[:cancelled], [:kept]},
      {:error, :zero_cost}
    ])
  end

  test "README has release structure, correct authority and honest scope" do
    assert String.starts_with?(File.read!("README.md"), "# dwrr-elixir\n")

    prose("README.md", [
      ~r/## The need/,
      ~r/## At a glance/,
      ~r/## Quick start/,
      ~r/## Examples/,
      ~r/## Behavior worth knowing/,
      ~r/## How we know/,
      ~r/## Check it yourself/,
      ~r/## How it compares/,
      ~r/## Colophon/,
      ~r/\{:dwrr, "~> 0\.1\.0"\}/,
      ~r/https:\/\/github.com\/version2beta\/dwrr-elixir/,
      ~r/immutable/,
      ~r/retrieval limit/,
      ~r/2\^63-1/,
      ~r/ArgumentError/,
      ~r/no retries/i,
      ~r/backpressure/,
      ~r/declared cost/,
      ~r/retai[n].*input/i,
      ~r/bash scripts\/loop.sh/,
      ~r/git commit/
    ])

    [_, behavior] =
      Regex.run(~r/## Behavior worth knowing\n(.*?)(?:\n## |\z)/s, File.read!("README.md"))

    for error <-
          ~w(invalid_index negative_take zero_cost cost_too_large zero_quantum quantum_too_large) do
      assert Regex.match?(~r/:#{error}\b/, behavior), "missing shared error :#{error}"
    end

    assert behavior =~ ~r/index.*reus|reus.*index/is

    refute File.read!("README.md") =~ "No loop has run"
    assert File.read!("README.md") =~ File.read!("test/fixtures/stage2-owner-instructions.md")
  end
end
