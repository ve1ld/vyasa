defmodule Utils.Formatters.TimeDisplay do
  @moduledoc """
  A struct for keeping human-friendly time formats.
  """

  defstruct [:formatted_time, :original_datetime]

  @type t :: %__MODULE__{
          formatted_time: String.t(),
          original_datetime: DateTime.t()
        }
end
