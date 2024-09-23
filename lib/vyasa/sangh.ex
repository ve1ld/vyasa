defmodule Vyasa.Sangh do
  @moduledoc """
  The Sangh context.
  """

  import Ecto.Query, warn: false
  import EctoLtree.Functions, only: [nlevel: 1]
  alias Vyasa.Repo
  alias Vyasa.Sangh.Sheaf


  @doc """
  Returns the list of sheafs within a specific session.

  ## Examples

  iex> list_sheafs_by_session()
  [%Sheaf{}, ...]

  """
  def list_sheafs_by_session(id) do
    (from c in Sheaf,
      where: c.session_id == ^id,
      select: c)
    |> Repo.all()
  end

  @doc """
    Creates a sheaf.

    ## Examples

        iex> create_sheaf(%{field: new_value})
        {:ok, %Sheaf{}}

        iex> create_sheaf(%{field: bad_value})
        {:error, %Ecto.Changeset{}}

  """

  def create_sheaf(attrs \\ %{}) do
    %Sheaf{}
    |> Sheaf.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Returns a single sheaf.

    Raises `Ecto.NoResultsError` if the Sheaf does not exist.

    ## Examples

        iex> get_sheaf!(123)
        %Sheaf{}

        iex> get_sheaf!(456)
        ** (Ecto.NoResultsError)

  """

  def get_sheaf!(id), do: Repo.get!(Sheaf, id)

  def get_sheaf(id) do
    (from c in Sheaf,
      where: c.id == ^id,
      limit: 1)
    |> Repo.one()
  end


  def get_descendents_sheaf(id) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.parent_id == ^id,
      order_by: [desc: c.inserted_at],
      inner_lateral_join: sc in subquery(
        from sc in Sheaf,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}
    Repo.all(query)
  end


  def get_root_sheafs_by_sheaf(id) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.sheaf_id == ^id,
      where: nlevel(c.path) == 1,
      preload: [:initiator],
      order_by: [desc: c.inserted_at],
      inner_lateral_join: sc in subquery(
        from sc in Sheaf,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)

  end

  def get_descendents_sheaf(id, page) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.parent_id == ^id,
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Sheaf,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, [page: page, asc: true])
  end

  def get_root_sheafs_by_session(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.session_id == ^id,
      where: nlevel(c.path) == 1,
      inner_lateral_join: sc in subquery(
        from sc in Sheaf,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end

  def get_sheafs_by_session(id, %{traits: traits}) do
    from(c in Sheaf,
      where: c.session_id == ^id and fragment("? @> ?", c.traits, ^traits),
      preload: [marks: [:binding]]
    )
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def get_sheafs_by_session(id) do
    query = Sheaf
    |> where([c], c.session_id == ^id)
    |> order_by(desc: :inserted_at)

    Repo.all(query)
  end

  def get_sheaf_count_by_session(id) do
    query =
      Sheaf
      |> where([e], e.session_id == ^id)
    |> select([e], count(e))
    Repo.one(query)
  end


  # Gets child sheafs 1 level down only
  def get_child_sheafs_by_session(id, path) do
    path = path <> ".*{1}"

    query =
      from c in Sheaf,
      as: :c,
      where: c.session_id == ^id,
      where: fragment("? ~ ?", c.path, ^path),
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Sheaf,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end

  # Gets ancestors down up all levels only
  # TODO: Get root sheafs together
  def get_ancestor_sheafs_by_sheaf(sheaf_id, path) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.sheaf_id == ^sheaf_id,
      where: fragment("? @> ?", c.path, ^path),
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Sheaf,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end

  #   @doc """
  #   Updates a sheaf.

  #   ## Examples

  #       iex> update_sheaf(sheaf, %{field: new_value})
  #       {:ok, %Sheaf{}}

  #       iex> update_sheaf(sheaf, %{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """
  def update_sheaf(%Sheaf{} = sheaf, attrs) do
    sheaf
    |> Sheaf.mutate_changeset(attrs)
    |> Repo.update()
  end

  #   @doc """
  #   Updates a sheaf.

  #   ## Examples

  #       iex> update_sheaf!(%{field: value})
  #       %Sheaf{}

  #       iex> Need to Catch error state

  #   """

  def update_sheaf!(%Sheaf{} = sheaf, attrs) do
    sheaf
    |> Sheaf.mutate_changeset(attrs)
    |> Repo.update!()
  end

  #   @doc """
  #   Deletes a sheaf.

  #   ## Examples

  #       iex> delete_sheaf(sheaf)
  #       {:ok, %Sheaf{}}

  #       iex> delete_sheaf(sheaf)
  #       {:error, %Ecto.Changeset{}}

  #   """
  def delete_sheaf(%Sheaf{} = sheaf) do
    Repo.delete(sheaf)
  end

  #   @doc """
  #   Returns an `%Ecto.Changeset{}` for tracking sheaf changes.

  #   ## Examples

  #       iex> change_sheaf(sheaf)
  #       %Ecto.Changeset{data: %Sheaf{}}

  #   """
  def change_sheaf(%Sheaf{} = sheaf, attrs \\ %{}) do
    Sheaf.changeset(sheaf, attrs)
  end

  def filter_root_sheafs_chrono(sheafs) do
    sheafs
    |> Enum.filter(&match?({{_}, _}, &1))
    |> sort_sheafs_chrono()
  end

  def filter_child_sheafs_chrono(sheafs, sheaf) do
    sheafs
    |> Enum.filter(fn i -> elem(i, 1).parent_id == elem(sheaf, 1).id end)
    |> sort_sheafs_chrono()
  end

  defp sort_sheafs_chrono(sheafs) do
    Enum.sort_by(sheafs, &elem(&1, 1).inserted_at, :desc)
  end


  alias Vyasa.Sangh.Session

  @doc """
  Returns the list of sessions.

  ## Examples

      iex> list_sessions()
      [%Session{}, ...]

  """
  def list_sessions do
    Repo.all(Session)
  end

  @doc """
  Gets a single session.

  Raises `Ecto.NoResultsError` if the Session does not exist.

  ## Examples

      iex> get_session!(123)
      %Session{}

      iex> get_session!(456)
      ** (Ecto.NoResultsError)

  """
  def get_session!(id), do: Repo.get!(Session, id)
  def get_session(id), do: Repo.get(Session, id)

  @doc """
  Creates a session.

  ## Examples

      iex> create_session(%{field: value})
      {:ok, %Session{}}

      iex> create_session(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a session.

  ## Examples

      iex> update_session(session, %{field: new_value})
      {:ok, %Session{}}

      iex> update_session(session, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a session.

  ## Examples

      iex> delete_session(session)
      {:ok, %Session{}}

      iex> delete_session(session)
      {:error, %Ecto.Changeset{}}

  """
  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking session changes.

  ## Examples

      iex> change_session(session)
      %Ecto.Changeset{data: %Session{}}

  """
  def change_session(%Session{} = session, attrs \\ %{}) do
    Session.changeset(session, attrs)
  end
end
