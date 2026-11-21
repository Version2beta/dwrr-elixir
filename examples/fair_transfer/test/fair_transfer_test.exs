defmodule FairTransferTest do
  use ExUnit.Case, async: true

  test "demo matches the Python fair_transfer customer FIFOs, file names and costs" do
    assert Enum.map(FairTransfer.demo(), &{&1.customer, &1.id, &1.bytes}) == [
             {:basic, "archive.zip", 3072},
             {:basic, "note.txt", 256},
             {:basic, "photo.jpg", 768},
             {:basic, "report.pdf", 1024},
             {:team, "draft.pdf", 1024},
             {:team, "chart.png", 1024},
             {:team, "bundle.zip", 4096},
             {:team, "index.txt", 512},
             {:business, "slides.pdf", 2048},
             {:business, "logo.png", 1024},
             {:business, "summary.pdf", 1024},
             {:business, "backup.zip", 8192}
           ]
  end

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

    assert totals == %{basic: 5120, team: 6656, business: 12288}
  end

  test "default single-item takes match Python service order and every cumulative total" do
    trace = FairTransfer.run()

    assert Enum.map(trace, fn entry ->
             {entry.transfer.id, entry.bytes,
              {entry.totals.basic, entry.totals.team, entry.totals.business}}
           end) == [
             {"draft.pdf", 1024, {0, 1024, 0}},
             {"chart.png", 1024, {0, 2048, 0}},
             {"slides.pdf", 2048, {0, 2048, 2048}},
             {"logo.png", 1024, {0, 2048, 3072}},
             {"summary.pdf", 1024, {0, 2048, 4096}},
             {"archive.zip", 3072, {3072, 2048, 4096}},
             {"bundle.zip", 4096, {3072, 6144, 4096}},
             {"backup.zip", 8192, {3072, 6144, 12288}},
             {"note.txt", 256, {3328, 6144, 12288}},
             {"photo.jpg", 768, {4096, 6144, 12288}},
             {"index.txt", 512, {4096, 6656, 12288}},
             {"report.pdf", 1024, {5120, 6656, 12288}}
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
