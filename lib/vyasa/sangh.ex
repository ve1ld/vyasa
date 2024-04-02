defmodule Vyasa.Sangh do
  @moduledoc """
  The Sangh context.
  """

  import Ecto.Query, warn: false
  import EctoLtree.Functions, only: [nlevel: 1]
  alias Vyasa.Repo
  alias Vyasa.Sangh.Comment


  @doc """
  Returns the list of comments within a specific session.

  ## Examples

  iex> list_comments_by_session()
  [%Comment{}, ...]

  """
  def list_comments_by_session(id) do
    (from c in Comment,
      where: c.session_id == ^id,
      select: c)
    |> Repo.all()
  end

  @doc """
    Creates a comment.

    ## Examples

        iex> create_comment(comment, %{field: new_value})
        {:ok, %Comment{}}

        iex> create_comment(comment, %{field: bad_value})
        {:error, %Ecto.Changeset{}}

  """

  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Returns a single comment.

    Raises `Ecto.NoResultsError` if the Comment does not exist.

    ## Examples

        iex> get_comment!(123)
        %Comment{}

        iex> get_comment!(456)
        ** (Ecto.NoResultsError)

  """

  def get_comment!(id), do: Repo.get!(Comment, id)

  def get_comment(id) do
    (from c in Comment,
      where: c.id == ^id,
      limit: 1)
    |> Repo.one()
  end


  def get_descendents_comment(id) do
    query =
      from c in Comment,
      as: :c,
      where: c.parent_id == ^id,
      order_by: [desc: c.inserted_at],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}
    Repo.all(query)
  end


  def get_root_comments_by_comment(id) do
    query =
      from c in Comment,
      as: :c,
      where: c.comment_id == ^id,
      where: nlevel(c.path) == 1,
      preload: [:initiator],
      order_by: [desc: c.inserted_at],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)

  end

  def get_descendents_comment(id, page) do
    query =
      from c in Comment,
      as: :c,
      where: c.parent_id == ^id,
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, [page: page, asc: true])
  end

  def get_root_comments_by_session(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    query =
      from c in Comment,
      as: :c,
      where: c.session_id == ^id,
      where: nlevel(c.path) == 1,
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end



  def get_comments_by_session(id) do
    query = Comment
    |> where([c], c.session_id == ^id)
    |> order_by(desc: :inserted_at)

    Repo.all(query)
  end

  def get_comment_count_by_session(id) do
    query =
      Comment
      |> where([e], e.session_id == ^id)
    |> select([e], count(e))
    Repo.one(query)
  end


  # Gets child comments 1 level down only
  def get_child_comments_by_session(id, path) do
    path = path <> ".*{1}"

    query =
      from c in Comment,
      as: :c,
      where: c.session_id == ^id,
      where: fragment("? ~ ?", c.path, ^path),
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end

  # Gets ancestors down up all levels only
  # TODO: Get root comments together
  def get_ancestor_comments_by_comment(comment_id, path) do
    query =
      from c in Comment,
      as: :c,
      where: c.comment_id == ^comment_id,
      where: fragment("? @> ?", c.path, ^path),
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ), on: true,
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end

  #   @doc """
  #   Updates a comment.

  #   ## Examples

  #       iex> update_comment(comment, %{field: new_value})
  #       {:ok, %Comment{}}

  #       iex> update_comment(comment, %{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.mutate_changeset(attrs)
    |> Repo.update()
  end

  #   @doc """
  #   Updates a comment.

  #   ## Examples

  #       iex> update_comment!(%{field: value})
  #       %Comment{}

  #       iex> Need to Catch error state

  #   """

  def update_comment!(%Comment{} = comment, attrs) do
    comment
    |> Comment.mutate_changeset(attrs)
    |> Repo.update!()
  end

  #   @doc """
  #   Deletes a comment.

  #   ## Examples

  #       iex> delete_comment(comment)
  #       {:ok, %Comment{}}

  #       iex> delete_comment(comment)
  #       {:error, %Ecto.Changeset{}}

  #   """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  #   @doc """
  #   Returns an `%Ecto.Changeset{}` for tracking comment changes.

  #   ## Examples

  #       iex> change_comment(comment)
  #       %Ecto.Changeset{data: %Comment{}}

  #   """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def filter_root_comments_chrono(comments) do
    comments
    |> Enum.filter(&match?({{_}, _}, &1))
    |> sort_comments_chrono()
  end

  def filter_child_comments_chrono(comments, comment) do
    comments
    |> Enum.filter(fn i -> elem(i, 1).parent_id == elem(comment, 1).id end)
    |> sort_comments_chrono()
  end

  defp sort_comments_chrono(comments) do
    Enum.sort_by(comments, &elem(&1, 1).inserted_at, :desc)
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
