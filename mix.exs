# Release metadata; documentation tooling is development-only.
defmodule Dwrr.MixProject do
  use Mix.Project

  def project do
    [
      app: :dwrr,
      version: "0.1.0",
      elixir: ">= 1.18.0",
      description:
        "Immutable deficit weighted round robin scheduler with an optional caller-owned GenServer wrapper.",
      source_url: "https://github.com/version2beta/dwrr-elixir",
      package: [
        name: "dwrr",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/version2beta/dwrr-elixir"},
        files: [
          "lib/**/*.ex",
          "mix.exs",
          "README.md",
          "TESTING.md",
          "CHANGELOG.md",
          "RELEASING.md",
          "LICENSE"
        ]
      ],
      deps: [
        {:stream_data, "~> 1.3.0", only: :test, runtime: false},
        {:ex_doc, "~> 0.40.0", only: :dev, runtime: false}
      ],
      aliases: [docs: ["compile", &docs/1]],
      docs: [
        main: "getting-started",
        extras: [{"guides/getting-started.md", title: "Getting started"}],
        source_ref: "88c8dc71f673c35281de00d602c5ae2a4a951f7e",
        # File-level links avoid mapping expanded docs onto historical line numbers.
        source_url_pattern: fn
          "lib/" <> _ = path, _line ->
            "https://github.com/version2beta/dwrr-elixir/blob/88c8dc71f673c35281de00d602c5ae2a4a951f7e/#{path}"

          _path, _line ->
            nil
        end,
        source_url:
          "https://github.com/version2beta/dwrr-elixir/tree/88c8dc71f673c35281de00d602c5ae2a4a951f7e",
        footer: false,
        filter_modules: fn module, _metadata ->
          module in [Dwrr, Dwrr.Item, Dwrr.Scheduled, Dwrr.Server]
        end
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod
    ]
  end

  # Locked ExDoc 0.40.5 prefers root source_url over docs options. Its @doc false
  # task entrypoint accepts a local config override; canonical metadata stays intact.
  defp docs(args) do
    config = Mix.Project.config()
    Mix.Tasks.Docs.run(args, Keyword.put(config, :source_url, config[:docs][:source_url]))
  end

  def application, do: []
  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "conformance"]
  defp elixirc_paths(_), do: ["lib"]
end
