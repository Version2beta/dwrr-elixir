defmodule FairTransfer do
  @moduledoc """
  Pure, finite simulation of three customer queues. No transfers are performed.

  Inputs are transfer maps with an `:id`, a known `:customer`, and positive
  `:bytes` within Dwrr's cost limit. Input order determines each customer's FIFO.
  Each trace entry records one whole transfer and cumulative declared bytes.
  """

  @customers [{:basic, 1024}, {:team, 2048}, {:business, 4096}]
  @type transfer :: %{id: String.t(), customer: :basic | :team | :business, bytes: pos_integer()}
  @type entry :: %{transfer: transfer(), bytes: pos_integer(), totals: map()}

  def customers, do: @customers

  @spec demo() :: [transfer()]
  def demo do
    for {customer, sizes} <- [
          basic: [512, 1536, 768, 2304],
          team: [1024, 3072, 512, 2048],
          business: [2048, 1024, 4096, 1536]
        ],
        {bytes, index} <- Enum.with_index(sizes, 1) do
      %{id: "#{customer}-#{index}", customer: customer, bytes: bytes}
    end
  end

  @spec run([transfer()]) :: [entry()]
  def run(transfers \\ demo()) do
    queues = @customers |> Enum.with_index() |> Map.new(fn {{name, _}, i} -> {name, i} end)

    scheduler =
      @customers
      |> Enum.with_index()
      |> Enum.reduce(Dwrr.new(3), fn {{_, quantum}, queue}, scheduler ->
        {:ok, scheduler} = Dwrr.set_quantum(scheduler, queue, quantum)
        scheduler
      end)

    scheduler =
      Enum.reduce(transfers, scheduler, fn transfer, scheduler ->
        queue = Map.fetch!(queues, transfer.customer)
        item = %Dwrr.Item{cost: transfer.bytes, value: transfer}
        {:ok, scheduler} = Dwrr.enqueue(scheduler, queue, [item])
        scheduler
      end)

    totals = Map.new(@customers, fn {customer, _} -> {customer, 0} end)
    serve(scheduler, totals, [])
  end

  defp serve(scheduler, totals, trace) do
    case Dwrr.take(scheduler, 1) do
      {:ok, [], _scheduler} ->
        Enum.reverse(trace)

      {:ok, [selected], scheduler} ->
        totals = Map.update!(totals, selected.value.customer, &(&1 + selected.cost))
        entry = %{transfer: selected.value, bytes: selected.cost, totals: totals}
        serve(scheduler, totals, [entry | trace])
    end
  end
end
