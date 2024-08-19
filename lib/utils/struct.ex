defmodule Utils.Struct do
  @moduledoc """
  Contains functions useful for struct operations
  """
  @doc """
  Access elements nested within structs
  """
  def get_in(struct, keys) when is_list(keys) do
    do_get_in(struct, keys)
 end

 defp do_get_in(nil, _keys), do: nil
 defp do_get_in(value, []), do: value
 defp do_get_in(map, [key | rest_keys]) when is_map(map) do
    map
    |> Map.get(key)
    |> do_get_in(rest_keys)
 end
 defp do_get_in(struct, [key | rest_keys]) do
    struct
    |> Map.get(key)
    |> do_get_in(rest_keys)
 end
end
