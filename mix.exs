# Stage-2 metadata target; preserve build paths and the approved test-only dependency.
defmodule Dwrr.MixProject do
  use Mix.Project

  def project do
    [
      app: :dwrr,
      version: "0.1.0",
      elixir: ">= 1.18.0",
      deps: [{:stream_data, "~> 1.3.0", only: :test, runtime: false}],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod
    ]
  end

  def application, do: []
  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "conformance"]
  defp elixirc_paths(_), do: ["lib"]
end
