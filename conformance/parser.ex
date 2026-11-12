# Complete; do not change. Protocol parsing is separate from scheduler policy.
defmodule Dwrr.Conformance.Parser do
  @moduledoc false
  @u64 18_446_744_073_709_551_615

  def parse(line) do
    with true <- String.valid?(line),
         {:ok, request} <- JSON.decode(line),
         true <- is_map(request) do
      {:ok, request(request)}
    else
      _ -> {:error, :protocol}
    end
  rescue
    ArgumentError -> {:error, :protocol}
  end

  defp request(%{"op" => "new"} = r) do
    count = integer(r, "count")
    if count < 0, do: bad()
    {:new, count}
  end

  defp request(%{"op" => "enqueue"} = r) do
    index = integer(r, "queue")
    items = Map.get(r, "items")
    if not is_list(items), do: bad()

    items =
      Enum.map(items, fn
        it when is_map(it) ->
          %Dwrr.Item{value: integer(it, "value"), cost: decimal(Map.get(it, "cost"))}

        _ ->
          bad()
      end)

    {:enqueue, index, items}
  end

  defp request(%{"op" => "set_quantum"} = r),
    do: {:set_quantum, integer(r, "queue"), decimal(Map.get(r, "quantum"))}

  defp request(%{"op" => "remove_head"} = r), do: {:remove_head, integer(r, "queue")}
  defp request(%{"op" => "drain_queue"} = r), do: {:drain_queue, integer(r, "queue")}
  defp request(%{"op" => "take"} = r), do: {:take, integer(r, "n")}
  defp request(%{"op" => "add_queue"}), do: :add_queue
  defp request(%{"op" => "remove_queue"}), do: :remove_queue
  defp request(_), do: bad()

  defp integer(r, field) do
    case Map.fetch(r, field) do
      {:ok, n} when is_integer(n) -> n
      _ -> bad()
    end
  end

  defp decimal(s) when is_binary(s) do
    if not Regex.match?(~r/\A(?:0|[1-9][0-9]*)\z/, s), do: bad()
    # Range checking by length avoids constructing unbounded bignums here.
    if byte_size(s) > 20, do: bad()
    n = String.to_integer(s)
    if n > @u64, do: bad()
    n
  end

  defp decimal(_), do: bad()
  defp bad, do: raise(ArgumentError, "invalid protocol request")
end
