# Complete; do not change.
defmodule Dwrr.Item do
  @moduledoc "An opaque caller value and its declared positive cost."
  @enforce_keys [:value, :cost]
  defstruct [:value, :cost]
  @type t(value) :: %__MODULE__{value: value, cost: pos_integer()}
end
