# Complete; do not change.
defmodule Dwrr.Scheduled do
  @moduledoc "A served item with its source queue index."
  @enforce_keys [:queue, :value, :cost]
  defstruct [:queue, :value, :cost]
  @type t(value) :: %__MODULE__{queue: non_neg_integer(), value: value, cost: pos_integer()}
end
