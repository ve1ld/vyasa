defmodule Utils.Time do
  @moduledoc """
  Anything related to time-calculations shall go here
  """

  @doc """
  Inserts the current time with the given key if that key doesn't exist in the map or is nil.

  ## Parameters
    - target_map: The map to potentially update
    - target_key: The key to check and potentially insert

  ## Returns
    The updated map or the original map if no update was needed.

  ## Examples
      iex> Utils.Time.maybe_insert_current_time(%{}, :timestamp)
      %{timestamp: ~U[...]}

      iex> Utils.Time.maybe_insert_current_time(%{timestamp: nil}, :timestamp)
      %{timestamp: ~U[...]}

      iex> Utils.Time.maybe_insert_current_time(%{timestamp: "exists"}, :timestamp)
      %{timestamp: "exists"}
  """
  def maybe_insert_current_time(target_map, target_key)
      when is_map(target_map) and (is_atom(target_key) or is_binary(target_key)) do
    case Map.get(target_map, target_key) do
      nil -> Map.put(target_map, target_key, DateTime.utc_now())
      _ -> target_map
    end
  end

  def maybe_insert_current_time(target_map, target_key) do
    raise ArgumentError,
          "Invalid arguments. Expected a map and a key (atom or string), got: #{inspect(target_map)}, #{inspect(target_key)}"
  end

  @doc """
  Updates the given key in the map with the current time, regardless of its existing value.

  ## Parameters
    - target_map: The map to update
    - target_key: The key to update with the current time

  ## Returns
    The updated map with the specified key set to the current time.

  ## Examples
      iex> TimeUpdater.update_current_time(%{}, :timestamp)
      %{timestamp: ~U[...]}

      iex> TimeUpdater.update_current_time(%{timestamp: "old_value"}, :timestamp)
      %{timestamp: ~U[...]}

      iex> TimeUpdater.update_current_time(%{other_key: "value"}, :timestamp)
      %{other_key: "value", timestamp: ~U[...]}
  """
  @spec update_current_time(map(), atom() | String.t()) :: map()
  def update_current_time(target_map, target_key)
      when is_map(target_map) and (is_atom(target_key) or is_binary(target_key)) do
    Map.put(target_map, target_key, DateTime.utc_now())
  end

  def update_current_time(target_map, target_key) do
    raise ArgumentError,
          "Invalid arguments. Expected a map and a key (atom or string), got: #{inspect(target_map)}, #{inspect(target_key)}"
  end
end
