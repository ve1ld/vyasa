defmodule Vyasa.Sangh.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias EctoLtree.LabelTree, as: Ltree
  alias Vyasa.Sangh.{Comment, Session}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "comments" do
    field :body, :string
    field :chapter_number, :integer
    field :active, :boolean, default: true
    field :p_type, Ecto.Enum, values: [:null, :quote, :timestamp]
    field :path,  Ltree
    field :child_count, :integer, default: 0, virtual: true
    belongs_to :session, Session, references: :id, type: Ecto.UUID
    belongs_to :text, Vyasa.Written.Text , references: :title, type: :string
    belongs_to :parent, Comment, references: :id, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
      |> cast(attrs, [:id, :body, :path, :chapter_number, :p_type, :session_id, :parent_id, :text_id])
      |> typed_pointer_switch(attrs)
      |> validate_required([:id, :session_id])
  end

  def mutate_changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:id, :body, :active])
    |> typed_pointer_switch(attrs)
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  #when type changes
  def typed_pointer_switch(changeset, %{type: type}), do: typed_pointer_switch(changeset, %{"type" => type})
  def typed_pointer_switch(changeset, %{"type" => type}) do
    pointer_changeset = case type do
                            "quote" ->
                              &quote_changeset(&1, &2)
                            "timestamp" ->
                              &timestamp_changeset(&1, &2)
                            _ ->
                              &null_changeset(&1, &2)
                          end

    cast_embed(changeset, :pointer, with: pointer_changeset)
  end

  def typed_pointer_switch(changeset, _attrs), do: validate_required(changeset, [:type])

  def quote_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:line_number, :start, :end, :quote])
    |> validate_required([:line_number, :quote])
  end

  def timestamp_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:start_time, :end_time])
    |> validate_required([:start_time, :end_time])
  end

  def null_changeset(structure, attrs) do
    structure
    |> cast(attrs, [])
  end
end
