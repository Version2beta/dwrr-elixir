defmodule Dwrr.Conformance.Adapter do
  @moduledoc false
  @doc "Apply a fully parsed request; return {new_scheduler, wire_response}. Errors retain state; nil requires new."
  def apply(s, _request), do: {s, %{"ok" => nil}}
end
