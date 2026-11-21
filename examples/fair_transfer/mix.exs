defmodule FairTransfer.MixProject do
  use Mix.Project

  def project do
    [
      app: :fair_transfer,
      version: "0.1.0",
      elixir: ">= 1.18.0",
      deps: [{:dwrr, path: "../.."}]
    ]
  end

  def application, do: []
end
