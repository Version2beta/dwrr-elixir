defmodule Mix.Tasks.FairTransfer do
  use Mix.Task

  @shortdoc "Simulate byte-cost scheduling for Basic, Team and Business"
  @impl Mix.Task
  def run([]) do
    Mix.Task.run("app.start")
    Mix.shell().info("Pretend transfers (quanta: Basic=1024 Team=2048 Business=4096 bytes)")

    FairTransfer.run()
    |> Enum.each(fn entry ->
      totals = entry.totals

      Mix.shell().info(
        "#{entry.transfer.id}: #{entry.bytes} bytes | cumulative bytes: " <>
          "Basic=#{totals.basic} Team=#{totals.team} Business=#{totals.business}"
      )
    end)
  end

  def run(_args), do: Mix.raise("Usage: mix fair_transfer")
end
