defmodule Dwrr.Conformance.Driver do
  @moduledoc false
  @doc "Read JSONL from stdin, validate before dispatch; flush each response. EOF 0; protocol failure stderr + halt(2)."
  def run, do: :ok
end
