defmodule Vyasa.Draft do
  @moduledoc """
  The Drafting Context for all your marking and binding needs
  User-generated artefacts like marks and sheafs that are around the written context are interacted with via this Draft context.
  """

  import Ecto.Query, warn: false
  alias Vyasa.Adapters.Binding
  alias Vyasa.Sangh.Mark
  alias Vyasa.Repo

  # Inits the binding for an empty selection
  def bind_node(%{"selection" => ""} = node = _bind_target_payload) do
    bind_node(Map.delete(node, "selection"), %Binding{})
  end

  # Shifts the selection within the bind target payload to the %Binding{} struct, and continues with the binding.
  def bind_node(%{"selection" => selection, "text" => text} = node = _bind_target_payload) do
    case :binary.match(text, selection) do
      {start_quote, len} ->
        bind_node(Map.delete(node, "selection"), %Binding{:window => %{:quote => selection, :start_quote => start_quote, :end_quote => start_quote + len}})
      _ ->
        bind_node(Map.delete(node, "selection"), %Binding{})
    end

  end

  # Uses the "field" attribute in the bind_target
  # When the binding target is defined by a "field" attribute, it sets the field_key for the %Binding{} struct struct.
  def bind_node(%{"field" => field} = node = _bind_target_payload, bind) do
    bind_node(Map.delete(node, "field"), %{
      bind
      | field_key: String.split(field, "::") |> Enum.map(&String.to_existing_atom(&1))
    })
  end

  @doc """
  Finally, updates the %Binding{} struct's node_id and returns a map with the binding, the node_id and the  with the id and the
  id as keyed by the node_field_name.
  """
  def bind_node(
        %{"node" => node, "node_id" => node_id} = element,
        %Binding{} = bind
      ) do
    node_field_name =
      node
      |> String.to_existing_atom()
      |> struct()
      |> Binding.field_lookup()

    %{bind | node_field_name => node_id, :node_id => node_id}
    |> Binding.apply(element)
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
