defmodule Utils.StringUtils do
  @moduledoc """
  Contains functions useful for string operations, that need not be
  web or server-specific.
  """
  @doc """
  Inflexor logic that humanises snake_case string then converts to title case.
  """
  def fmt_to_title_case(s) do
    s
    |> Recase.to_title()
  end

end
