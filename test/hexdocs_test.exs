defmodule Dwrr.HexDocsTest do
  use ExUnit.Case, async: false
  doctest Dwrr
  doctest Dwrr.Server

  test "public guide scheduling example has the released service order" do
    s = Dwrr.new(2)
    {:ok, s} = Dwrr.set_quantum(s, 0, 2)
    {:ok, s} = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :upload, cost: 2}])
    {:ok, s} = Dwrr.enqueue(s, 1, [%Dwrr.Item{value: :ping, cost: 1}])
    {:ok, items, _next} = Dwrr.take(s, 2)
    assert Enum.map(items, &{&1.queue, &1.value, &1.cost}) == [{0, :upload, 2}, {1, :ping, 1}]
  end

  test "server forwards the name option" do
    {:ok, pid} = Dwrr.Server.start_link(1, name: __MODULE__)

    try do
      assert Process.whereis(__MODULE__) == pid
      assert {:ok, [], _} = Dwrr.Server.take(__MODULE__, 1)
    after
      GenServer.stop(pid)
    end
  end

  test "HexDocs exposes only the released public modules and public guide" do
    project = Dwrr.MixProject.project()
    ["compile", docs_alias] = project[:aliases][:docs]
    assert is_function(docs_alias, 1)
    config = project[:docs]
    assert config[:main] == "getting-started"
    assert config[:extras] == [{"guides/getting-started.md", [title: "Getting started"]}]

    for module <- [Dwrr, Dwrr.Item, Dwrr.Scheduled, Dwrr.Server] do
      assert config[:filter_modules].(module, %{})
    end

    refute config[:filter_modules].(Dwrr.Core, %{})
    refute config[:filter_modules].(Dwrr.PublicContract, %{})
    assert config[:source_ref] == "88c8dc71f673c35281de00d602c5ae2a4a951f7e"

    assert config[:source_url] ==
             "https://github.com/version2beta/dwrr-elixir/tree/88c8dc71f673c35281de00d602c5ae2a4a951f7e"

    assert Dwrr.MixProject.project()[:source_url] ==
             "https://github.com/version2beta/dwrr-elixir"

    # The guide is docs-only: Hex Preview cannot show it in the published package.
    assert config[:footer] == false
    assert config[:source_url_pattern].("guides/getting-started.md", 1) == nil

    assert config[:source_url_pattern].("lib/dwrr.ex", 999) ==
             "https://github.com/version2beta/dwrr-elixir/blob/88c8dc71f673c35281de00d602c5ae2a4a951f7e/lib/dwrr.ex"
  end
end
