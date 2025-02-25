defmodule Vyasa.Bhaj do
  import Ecto.Query
  alias Vyasa.Repo
  alias Vyasa.Medium
  alias Vyasa.Medium.Track
  alias Vyasa.Bhaj.Tracklist


  @doc """
  Returns the list of tracks.

  ## Examples

      iex> list_tracks()
      [%Track{}, ...]

  """
  def list_tracks do
    Repo.all(Track)
  end

  @doc """
  Gets a single track.

  Raises `Ecto.NoResultsError` if the Track does not exist.

  ## Examples

      iex> get_track!(123)
      %Track{}

      iex> get_track!(456)
      ** (Ecto.NoResultsError)

  """
  def get_track!(id), do: Repo.get!(Track, id)
  def get_track(id), do: Repo.get(Track, id)

  @doc """
  Creates a track.

  ## Examples

      iex> create_track(%{field: value})
      {:ok, %Track{}}

      iex> create_track(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a track.

  ## Examples

      iex> update_track(track, %{field: new_value})
      {:ok, %Track{}}

      iex> update_track(track, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a track.

  ## Examples

      iex> delete_track(track)
      {:ok, %Track{}}

      iex> delete_track(track)
      {:error, %Ecto.Changeset{}}

  """
  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking track changes.

  ## Examples

      iex> change_track(track)
      %Ecto.Changeset{data: %Track{}}

  """
  def change_track(%Track{} = track, attrs \\ %{}) do
    Track.changeset(track, attrs)
  end

  @doc """
  Returns the list of tracklists.

  ## Examples

      iex> list_tracklists()
      [%Tracklist{}, ...]

  """
  def list_tracklists do
    Repo.all(Tracklist)
  end

  @doc """
  Gets a single tracklist.

  Raises `Ecto.NoResultsError` if the Tracklist does not exist.

  ## Examples

      iex> get_tracklist!(123)
      %Tracklist{}

      iex> get_tracklist!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tracklist!(id), do: Repo.get!(Tracklist, id) |> Repo.preload(:tracks)
  def get_tracklist(id), do: Repo.get(Tracklist, id) |> Repo.preload(:tracks)

  @doc """
  Creates a tracklist.

  ## Examples

      iex> create_tracklist(%{field: value})
      {:ok, %Tracklist{}}

      iex> create_tracklist(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tracklist(attrs \\ %{}) do
    %Tracklist{}
    |> Tracklist.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tracklist.

  ## Examples

      iex> update_tracklist(tracklist, %{field: new_value})
      {:ok, %Tracklist{}}

      iex> update_tracklist(tracklist, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tracklist(%Tracklist{} = tracklist, attrs) do
    tracklist
    |> Tracklist.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tracklist.

  ## Examples

      iex> delete_tracklist(tracklist)
      {:ok, %Tracklist{}}

      iex> delete_tracklist(tracklist)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tracklist(%Tracklist{} = tracklist) do
    Repo.delete(tracklist)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tracklist changes.

  ## Examples

      iex> change_tracklist(tracklist)
      %Ecto.Changeset{data: %Tracklist{}}

  """
  def change_tracklist(%Tracklist{} = tracklist, attrs \\ %{}) do
    Tracklist.changeset(tracklist, attrs)
  end

  @doc """
  Appends an event to a tracklist by creating a new track.
  For virtual: Add to up next
  ## Examples

      iex> append_to_tracklist(tracklist_id, event_id)
      {:ok, %Track{}}
  """
  def append_to_tracklist(tracklist_id, event_id) do
    with {:ok, tracklist} <- get_tracklist(tracklist_id),
         {:ok, _event} <- Medium.get_event(event_id),
         next_order <- get_next_order(tracklist) do

      %Track{}
      |> Track.changeset(%{
        trackls_id: tracklist_id,
        event_id: event_id,
        order: next_order
      })
      |> Repo.insert()
    end
  end

  # @doc """
  # Removes a track from a tracklist and reorders the remaining tracks.

  # Just call Repo.delete(Track for now)

  # ## Examples

  #     iex> remove_from_tracklist(tracklist_id, track_id)
  #     {:ok, %Track{}}

  # """
  # def remove_from_tracklist(tracklist_id, track_id) do
  #   with {:ok, tracklist} <- get_tracklist(tracklist_id),
  #        {:ok, track} <- get_track(track_id) do

  #     Repo.transaction(fn ->
  #       # Delete the track
  #       Repo.delete(track)

  #       # Reorder remaining tracks to maintain sequential order
  #       reorder_tracks_after_removal(tracklist, track.order)
  #     end)
  #   end
  # end
  #
  # defp reorder_tracks_after_removal(tracklist, removed_order) do
  #   # Update all tracks with order > removed_order to decrement their order
  #   query = from t in Track,
  #                where: t.trackls_id == ^tracklist.id and t.order > ^removed_order

  #   Repo.update_all(query, inc: [order: -1])
  # end

  defp get_next_order(tracklist_id) do
    # Query to find the highest order value in the tracklist
    query = from t in Track,
            where: t.trackls_id == ^tracklist_id,
            order_by: [desc: t.order],
            limit: 1,
            select: t.order

    case Repo.one(query) do
      nil -> 1  # If no tracks exist, start with order 1
      highest_order -> highest_order + 1
    end
  end


end
