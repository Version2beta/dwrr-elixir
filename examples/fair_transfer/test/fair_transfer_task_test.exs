defmodule Mix.Tasks.FairTransferTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "CLI prints selected transfers and cumulative customer byte totals" do
    output = capture_io(fn -> Mix.Tasks.FairTransfer.run([]) end)
    lines = String.split(output, "\n", trim: true)

    assert hd(lines) ==
             "Pretend transfers (quanta: Basic=1024 Team=2048 Business=4096 bytes)"

    assert length(lines) == 13

    assert Enum.at(lines, 1) ==
             "draft.pdf: 1024 bytes | cumulative bytes: Basic=0 Team=1024 Business=0"

    assert List.last(lines) ==
             "report.pdf: 1024 bytes | cumulative bytes: Basic=5120 Team=6656 Business=12288"

    assert Enum.map(tl(lines), fn line -> hd(String.split(line, ":")) end) ==
             Enum.map(FairTransfer.run(), & &1.transfer.id)
  end

  test "unexpected arguments report usage" do
    assert_raise Mix.Error, "Usage: mix fair_transfer", fn ->
      Mix.Tasks.FairTransfer.run(["unexpected"])
    end
  end
end
