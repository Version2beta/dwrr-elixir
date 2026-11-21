defmodule FairTransferTest do
  use ExUnit.Case, async: true

  test "all transfer records and byte costs survive, with FIFO per customer" do
    transfers = Enum.sort_by(FairTransfer.demo(), & &1.id)
    trace = FairTransfer.run(transfers)

    assert length(trace) == length(transfers)
    assert Enum.sort(Enum.map(trace, & &1.transfer)) == Enum.sort(transfers)
    assert Enum.all?(trace, &(&1.bytes == &1.transfer.bytes))

    for {customer, _quantum} <- FairTransfer.customers() do
      expected = Enum.filter(transfers, &(&1.customer == customer))
      actual = trace |> Enum.map(& &1.transfer) |> Enum.filter(&(&1.customer == customer))
      assert actual == expected
    end

    totals =
      Enum.reduce(trace, %{basic: 0, team: 0, business: 0}, fn entry, totals ->
        totals = Map.update!(totals, entry.transfer.customer, &(&1 + entry.bytes))
        assert entry.totals == totals
        totals
      end)

    assert totals == %{basic: 5120, team: 6656, business: 8704}
  end

  test "default single-item takes produce a deterministic service trace" do
    trace = FairTransfer.run()

    assert Enum.map(trace, & &1.transfer.id) == [
             "basic-1",
             "team-1",
             "business-1",
             "business-2",
             "basic-2",
             "team-2",
             "business-3",
             "basic-3",
             "team-3",
             "business-4",
             "team-4",
             "basic-4"
           ]

    assert FairTransfer.run() == trace
    assert FairTransfer.customers() == [basic: 1024, team: 2048, business: 4096]
  end

  test "a large head waits for credit without letting a smaller transfer overtake it" do
    transfers = [
      %{id: "large", customer: :basic, bytes: 3072},
      %{id: "small", customer: :basic, bytes: 1},
      %{id: "other", customer: :team, bytes: 1024}
    ]

    assert Enum.map(FairTransfer.run(transfers), & &1.transfer.id) == ["other", "large", "small"]
  end

  test "empty input has an empty trace" do
    assert FairTransfer.run([]) == []
  end
end
