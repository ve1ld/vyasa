defmodule Vyasa.Sangh do
  @moduledoc """
  The Sangh context.
  """

  import Ecto.Query, warn: false
  import EctoLtree.Functions, only: [nlevel: 1]
  alias Vyasa.Repo
  alias Vyasa.Sangh.Sheaf

  # TODO: @ks0m1c if a single sheaf has many associated marks and each mark has order with respect to another mark, then
  # we should float the ability to adjust mark orders in this context module.
  # "As a user I want to rearrange marks in my sheaf"
  # Some CRUD Functions needed here:
  # 1) promote_mark_in_sheaf(sheaf_id, mark_id) ==> swaps rank with previous mark that came along with it
  # 2) demote_mark_in_sheaf(sheaf_id, mark_id) ==> mirror of number 1
  # 3) delete_mark_in_sheaf(sheaf_id, mark_id) ==> calls the mark::delete() and adjusts rank order for the remaining marks

  @doc """
  Promotes a particular mark's rank within a particular sheaf.
  """
  # TODO @ks0m1c
  def promote_mark_in_sheaf(sheaf_id, _mark_id) do
    {:ok, sheaf_id}
  end

  @doc """
  Demotes a particular mark's rank within a particular sheaf.
  """
  # TODO @ks0m1c
  def demote_mark_in_sheaf(sheaf_id, _mark_id) do
    {:ok, sheaf_id}
  end

  @doc """
  Deletes a particular mark within a particular sheaf and adjusts the ranks of the remaining marks to ensure they are in order.
  NOTE: @ks0m1c QQ: needs some version of authorisation here, in a multi-user sangh, one user shouldn't be able to delete others' marks and sheafs willy-nilly (unless they are admins).
  """
  # TODO @ks0m1c
  def delete_mark_in_sheaf(sheaf_id, _mark_id) do
    {:ok, sheaf_id}
  end

  @doc """
  Returns a list of sheafs associated with a specific session.

  ## Parameters

  - `id`: The ID of the session for which to retrieve sheafs.

  ## Examples

  iex> list_sheafs_by_session("f7f1af05-109d-4adc-8987-9b6c4e2bbe5c")
  [%Sheaf{}, ...]

  """
  def list_sheafs_by_session(id) do
    from(c in Sheaf,
      where: c.session_id == ^id,
      select: c
    )
    |> Repo.all()
  end


  @doc """
  Creates a new sheaf with the given attributes.

  ## Parameters

  - `attrs`: A map of attributes used to create the sheaf.

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
  Retrieves a single sheaf by its ID.

  Raises `Ecto.NoResultsError` if the sheaf does not exist.

  ## Parameters

  - `id`: The ID of the sheaf to retrieve.

  ## Examples

  iex> get_sheaf!(123)
  %Sheaf{}

  iex> get_sheaf!(456)
  ** (Ecto.NoResultsError)

  """
  def get_sheaf!(id), do: Repo.get!(Sheaf, id)


  @doc """
  Fetches a single sheaf by its ID, returning nil if not found.

  ## Parameters

  - `id`: The ID of the sheaf to retrieve.

  ## Examples

  iex> get_sheaf(123)
  %Sheaf{}

  iex> get_sheaf(456)
  nil

  """
  def get_sheaf(id) do
    from(c in Sheaf,
      where: c.id == ^id,
      limit: 1
    )
    |> Repo.one()
  end


  @doc """
  Retrieves all direct descendants of a specific sheaf.

  ## Parameters

  - `id`: The ID of the parent sheaf whose descendants are to be retrieved.

  ## Examples

  iex> get_descendents_sheaf("f7f1af05-109d-4adc-8987-9b6c4e2bbe5c")
  [%Sheaf{}, ...]

  """
  def get_descendents_sheaf(id) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.parent_id == ^id,
      order_by: [desc: c.inserted_at],
      inner_lateral_join:
    sc in subquery(
      from sc in Sheaf,
      where: sc.parent_id == parent_as(:c).id,
      select: %{count: count()}
    ),
      on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end


  @doc """
  Retrieves root sheafs that are children of a specified sheaf.

  ## Parameters

  - `id`: The ID of the parent sheaf for which to find root children.

  ## Examples

  iex> get_root_sheafs_by_sheaf("f7f1af05-109d-4adc-8987-9b6c4e2bbe5c")
  [%Sheaf{}, ...]

  """
  def get_root_sheafs_by_sheaf(id) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.sheaf_id == ^id,
      where: nlevel(c.path) == 1,
      order_by: [desc: c.inserted_at],
      inner_lateral_join:
    sc in subquery(
      from sc in Sheaf,
      where: sc.parent_id == parent_as(:c).id,
      select: %{count: count()}
    ),
      on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end


  @doc """
  Retrieves paginated descendants of a specific sheaf.

  ## Parameters

  - `id`: The ID of the parent sheaf.
  - `page`: The page number for pagination.

  ## Examples

  iex> get_descendents_sheaf(1, 2)
  [%Sheaf{}, ...]

  """
  def get_descendents_sheaf(id, page) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.parent_id == ^id,
      inner_lateral_join:
    sc in subquery(
      from sc in Sheaf,
      select: %{count: count()}
    ),
      on: true,
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, page: page, asc: true)
  end


  @doc """
  Retrieves root sheafs associated with a specific session, with pagination options.

  ## Parameters

  - `id`: The ID of the session.
  - `page`: The page number for pagination.
  - `sort_attribute`: The attribute to sort by (default is `inserted_at`).
  - `limit`: The maximum number of results per page (default is 12).

  ## Examples

  iex> get_root_sheafs_by_session(1, 1)
  [%Sheaf{}, ...]

  """
  def get_root_sheafs_by_session(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.session_id == ^id,
      where: nlevel(c.path) == 1,
      inner_lateral_join:
    sc in subquery(
      from sc in Sheaf,
      where: sc.parent_id == parent_as(:c).id,
      select: %{count: count()}
    ),
      on: true,
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end


  @doc """
  Retrieves sheafs associated with a specific session filtered by traits.

  ## Parameters

  - `id`: The ID of the session.
  - `traits`: A map containing traits for filtering results.

  ## Examples

  iex> get_sheafs_by_session(1, %{traits: ["trait_value"]})
  [%Sheaf{}, ...]

  """
  def get_sheafs_by_session(id, %{traits: traits}) do
    from(c in Sheaf,
      where: c.session_id == ^id and fragment("? @> ?", c.traits, ^traits),
      preload: [marks: [:binding]]
    )
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end


  @doc """
  Retrieves all sheafs associated with a specific session sorted by insertion date.

  ## Parameters

  - `id`: The ID of the session.

  ## Examples

  iex> get_sheafs_by_session("f7f1af05-109d-4adc-8987-9b6c4e2bbe5c")
  [%Sheaf{}, ...]

  """
  def get_sheafs_by_session(id) do
    query =
      Sheaf
      |> where([c], c.session_id == ^id)
    |> preload(marks: [:binding])
    |> order_by(desc: :inserted_at)

    Repo.all(query)
  end


  @doc """
  Counts the number of sheafs associated with a specific session.

  ## Parameters

  - `id`: The uuid of the session for which to count sheafs.
  -  can pipe where filters for more granular counts
  ## Examples

  iex> get_sheaf_count_by_session("f7f1af05-109d-4adc-8987-9b6c4e2bbe5c")
  10

  """
  def get_sheaf_count_by_session(id) do
    query =
      Sheaf
      |> where([e], e.session_id == ^id)
    |> select([e], count(e))

    Repo.one(query)
  end


  @doc """
  Retrieves child sheafs that are one level down from a specified path within a session.

  ## Parameters

  - `id`: The ID of the session.
  - `path`: A string representing the path pattern to match against child sheafs.

  ## Examples

  iex> get_child_sheafs_by_session("f7f1af05-109d-4adc-8987-9b6c4e2bbe5c", "803a126e.539fb291")
  [%Sheaf{}, ...]

  """
  def get_child_sheafs_by_session(id, path) do
    path = path <> ".*{1}"

    query =
      from c in Sheaf,
      as: :c,
      where: c.session_id == ^id,
      where: fragment("? ~ ?", c.path, ^path),
      preload: [marks: [:binding]],
      inner_lateral_join:
    sc in subquery(
      from sc in Sheaf,
      where: sc.parent_id == parent_as(:c).id,
      select: %{count: count()}
    ),
      on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end


  @doc """
  Retrieves all ancestor sheafs for a specified sheaf based on its path.

  ## Parameters

  - `sheaf_id`: The ID of the target sheaf.
  - `path`: A string representing the path pattern to match against ancestor sheafs.

  ## Examples

  iex> get_ancestor_sheafs_by_sheaf(1, "ancestor_path")
  [%Sheaf{}, ...]

  """
  def get_ancestor_sheafs_by_sheaf(sheaf_id, path) do
    query =
      from c in Sheaf,
      as: :c,
      where: c.sheaf_id == ^sheaf_id,
      where: fragment("? @> ?", c.path, ^path),
      preload: [marks: [:binding]],
      inner_lateral_join:
    sc in subquery(
      from sc in Sheaf,
      where: sc.parent_id == parent_as(:c).id,
      select: %{count: count()}
    ),
      on: true,
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
    IO.inspect(sheaf, label: ">>> UPDATE SHEAF -- SHOULD BE WRITING TO DB NOW")

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
