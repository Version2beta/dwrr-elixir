defmodule Dwrr.Conformance.Adapter do
  @moduledoc false
  alias Dwrr.{Item, Scheduled}

  @doc "Apply a fully parsed request; return {new_scheduler, wire_response}. Errors retain state; nil requires new."
  def apply(nil, {:new, count}), do: {Dwrr.new(count), %{"ok" => nil}}

  def apply(nil, _request),
    do: raise(ArgumentError, "a new request must come before other operations")

  def apply(_s, {:new, count}), do: {Dwrr.new(count), %{"ok" => nil}}

  def apply(s, :add_queue) do
    {index, next} = Dwrr.add_queue(s)
    {next, %{"ok" => index}}
  end

  def apply(s, :remove_queue), do: {Dwrr.remove_queue(s), %{"ok" => nil}}

  def apply(s, {:enqueue, index, items}),
    do: state_result(s, Dwrr.enqueue(s, index, items))

  def apply(s, {:set_quantum, index, quantum}),
    do: state_result(s, Dwrr.set_quantum(s, index, quantum))

  def apply(s, {:remove_head, index}), do: value_result(s, Dwrr.remove_head(s, index))
  def apply(s, {:drain_queue, index}), do: value_result(s, Dwrr.drain_queue(s, index))
  def apply(s, {:take, n}), do: value_result(s, Dwrr.take(s, n))

  def apply(_s, _request), do: raise(ArgumentError, "unknown protocol request")

  defp state_result(_s, {:ok, next}), do: {next, %{"ok" => nil}}
  defp state_result(s, {:error, code}), do: {s, error(code)}

  defp value_result(_s, {:ok, value, next}), do: {next, %{"ok" => wire(value)}}
  defp value_result(s, {:error, code}), do: {s, error(code)}

  defp error(code), do: %{"error" => Atom.to_string(code)}

  defp wire(nil), do: nil

  defp wire(%Scheduled{queue: q, value: v, cost: c}),
    do: %{"queue" => q, "value" => v, "cost" => Integer.to_string(c)}

  defp wire(%Item{value: v, cost: c}), do: %{"value" => v, "cost" => Integer.to_string(c)}
  defp wire(list) when is_list(list), do: Enum.map(list, &wire/1)
end
