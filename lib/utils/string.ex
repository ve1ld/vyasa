defmodule Utils.String do
  @moduledoc """
  Contains functions useful for string operations, that need not be
  web or server-specific.
  """
  @doc """
  Inflexor logic that humanises snake_case string then converts to title case.
  """
  def to_title_case(value) when is_binary(value),
    do: Recase.to_title(value)
end
