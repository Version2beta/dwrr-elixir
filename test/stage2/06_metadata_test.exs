# Historical metadata gate with explicitly authorized docs-only tooling extension.
defmodule Dwrr.Stage2.MetadataTest do
  use ExUnit.Case, async: false

  test "package identity, minimum, description and canonical links" do
    p = Dwrr.MixProject.project()
    assert p[:app] == :dwrr
    assert p[:version] == "0.1.0"
    assert p[:elixir] == ">= 1.18.0"
    assert is_binary(p[:description]) and String.length(p[:description]) in 30..250
    assert p[:source_url] == "https://github.com/version2beta/dwrr-elixir"
    assert p[:package][:name] == "dwrr"
    assert p[:package][:licenses] == ["MIT"]
    assert p[:package][:links] == %{"GitHub" => p[:source_url]}
  end

  test "actual expanded package manifest includes library/release docs but excludes tooling and private assets" do
    package = Dwrr.MixProject.project()[:package]
    assert is_list(package)

    files =
      package[:files]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.regular?/1)
      |> Enum.sort()

    expected =
      ["mix.exs", "README.md", "TESTING.md", "CHANGELOG.md", "RELEASING.md", "LICENSE"] ++
        Path.wildcard("lib/**/*.ex")

    assert files == Enum.sort(expected)

    assert Enum.all?(
             files,
             &(not String.starts_with?(&1, ["test/", "conformance/", ".loop/", "scripts/"]))
           )

    assert File.read!("LICENSE") =~ "Copyright (c) 2026 M. Robert Martin"
  end

  test "dependencies are locked test/dev-only, production builds contain no driver or application child" do
    assert Dwrr.MixProject.project()[:deps] == [
             {:stream_data, "~> 1.3.0", [only: :test, runtime: false]},
             {:ex_doc, "~> 0.40.0", [only: :dev, runtime: false]}
           ]

    assert Dwrr.MixProject.application() == []
    lock = Mix.Dep.Lock.read()

    assert Enum.sort(Map.keys(lock)) ==
             [
               :earmark_parser,
               :ex_doc,
               :makeup,
               :makeup_elixir,
               :makeup_erlang,
               :nimble_parsec,
               :stream_data
             ]

    assert elem(lock.ex_doc, 2) == "0.40.5"

    assert :crypto.hash(:sha256, File.read!("mix.lock")) |> Base.encode16(case: :lower) ==
             File.read!("docs/hexdocs-lock.sha256") |> String.trim()

    assert elem(lock.stream_data, 2) == "1.3.0"
    # Evaluate project paths for prod without recompiling or mutating caller's Mix environment.
    old = Mix.env()

    try do
      Mix.env(:prod)
      assert Dwrr.MixProject.project()[:elixirc_paths] == ["lib"]
    after
      Mix.env(old)
    end
  end
end
