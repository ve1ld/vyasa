defmodule Vyasa.Draft do
  @moduledoc """
  The Drafting Context for all your marking and binding needs
  """

  import Ecto.Query, warn: false
  alias Vyasa.Adapters.Binding
  alias Vyasa.Sangh.Mark
  alias Vyasa.Sangh
  alias Vyasa.Repo



  def bind_node(%{"selection" => ""} = node) do
    bind_node(node, %Binding{})
  end

  def bind_node(%{"selection" => selection} = node) do
    bind_node(Map.delete(node, "selection"), %Binding{:window => %{:quote => selection}})
  end

  def bind_node(%{"field" => field} = node, bind) do
    bind_node(Map.delete(node, "field"), %{bind | field_key: String.split(field, "::") |> Enum.map(&(String.to_existing_atom(&1)))})
  end

  def bind_node(%{"node" => node, "node_id" => node_id}, %Binding{} = bind) do
    n = node
    |> String.to_existing_atom()
    |> struct()
    |> Binding.field_lookup()

    %{bind | n  => node_id, :node_id => node_id}
  end

  def create_comment([%Mark{} | _]= marks) do
    Sangh.create_comment(%{marks: marks})
  end
  @doc """
  Returns the list of marks.

  ## Examples

      iex> list_marks()
      [%Mark{}, ...]

  """
  def list_marks do
    Repo.all(Mark)
  end

  @doc """
  Gets a single mark.

  Raises `Ecto.NoResultsError` if the Mark does not exist.

  ## Examples

      iex> get_mark!(123)
      %Mark{}

      iex> get_mark!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mark!(id), do: Repo.get!(Mark, id)

  @doc """
  Creates a mark.

  ## Examples

      iex> create_mark(%{field: value})
      {:ok, %Mark{}}

      iex> create_mark(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mark(attrs \\ %{}) do
    %Mark{}
    |> Mark.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mark.

  ## Examples

      iex> update_mark(mark, %{field: new_value})
      {:ok, %Mark{}}

      iex> update_mark(mark, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mark(%Mark{} = mark, attrs) do
    mark
    |> Mark.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mark.

  ## Examples

      iex> delete_mark(mark)
      {:ok, %Mark{}}

      iex> delete_mark(mark)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mark(%Mark{} = mark) do
    Repo.delete(mark)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mark changes.

  ## Examples

      iex> change_mark(mark)
      %Ecto.Changeset{data: %Mark{}}

  """
  def change_mark(%Mark{} = mark, attrs \\ %{}) do
    Mark.changeset(mark, attrs)
  end
end
