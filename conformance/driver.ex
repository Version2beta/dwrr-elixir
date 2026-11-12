defmodule Dwrr.Conformance.Driver do
  @moduledoc false
  alias Dwrr.Conformance.{Adapter, Parser}

  @doc "Read JSONL from stdin, validate before dispatch; flush each response. EOF 0; protocol failure stderr + halt(2)."
  def run, do: read_request(nil)

  defp read_request(state) do
    case IO.binread(:stdio, :line) do
      :eof ->
        :ok

      {:error, _reason} ->
        protocol_error()

      line when is_binary(line) ->
        case Parser.parse(line) do
          {:ok, request} ->
            if is_nil(state) and not match?({:new, _}, request), do: protocol_error()
            {next, response} = Adapter.apply(state, request)
            # binwrite waits for the I/O reply; no response is buffered between reads.
            :ok = IO.binwrite(:stdio, [JSON.encode!(response), "\n"])
            read_request(next)

          {:error, :protocol} ->
            protocol_error()
        end
    end
  end

  defp protocol_error do
    IO.binwrite(:stderr, "protocol error\n")
    System.halt(2)
  end
end
