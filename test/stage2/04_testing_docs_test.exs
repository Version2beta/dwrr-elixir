# Complete; do not change.
Code.require_file("../support/stage2_assets_helper.exs", __DIR__)

defmodule Dwrr.Stage2.TestingDocsTest do
  use ExUnit.Case, async: false
  import Dwrr.Stage2Support

  test "documented property replay is executable and uses a real property file and seed" do
    [command] =
      Regex.run(
        ~r/```sh\n(MIX_ENV=test mix test test\/stage2\/properties_test.exs --seed 4242 --warnings-as-errors --no-color)\n```/,
        File.read!("TESTING.md"),
        capture: :all_but_first
      )

    assert command =~ "--seed 4242"
    # Execute the documented command without recursing into this documentation test.
    {out, status} = System.cmd("sh", ["-c", command], stderr_to_stdout: true)
    assert status == 0, out
    assert out =~ "Result: 8 passed"
  end

  test "testing guide records real inventory, bounded oracle and disposable mutation procedure" do
    prose("TESTING.md", [
      ~r/66/,
      ~r/1,839/,
      ~r/44,728/,
      ~r/36/,
      ~r/StreamData 1\.3\.0/,
      ~r/20,000/,
      ~r/shrink/i,
      ~r/--seed/,
      ~r/shrunk_trace/,
      ~r/large quanta/,
      ~r/quantum.?1.*analytic/is,
      ~r/stable backlog/i,
      ~r/Elixir 1\.18.*OTP 27.*not.*executed/is,
      ~r/check_driver.py/,
      ~r/replay.py/,
      ~r/disposable/,
      ~r/<=/,
      ~r/restore/i,
      ~r/no.*publication/is
    ])
  end
end
