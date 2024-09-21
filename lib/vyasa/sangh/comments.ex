defmodule Vyasa.Sangh.Comment do
  @moduledoc """
  Not your traditional comments, waypoints and containers for marks
  so that they can be referred to and moved around

  Can create a trail of marks and tied to session
  Can seperate marks into collapsible categories

  Sangh session Ids is SOT on shared and individual context
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias EctoLtree.LabelTree, as: Ltree
  alias Vyasa.Sangh.{Comment, Session, Mark}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "comments" do
    field :body, :string
    field :active, :boolean, default: true
    field :path,  Ltree
    field :signature, :string
    field :traits, {:array, :string}, default: []
    field :child_count, :integer, default: 0, virtual: true

    belongs_to :session, Session, references: :id, type: Ecto.UUID
    belongs_to :parent, Comment, references: :id, type: Ecto.UUID

    has_many :marks, Mark, references: :id, foreign_key: :comment_id, on_replace: :delete_if_exists
    #has_many :bindings, Binding, references: :id, foreign_key: :comment_bind_id, on_replace: :delete_if_exists
    timestamps()
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
      |> cast(attrs, [:id, :body, :path, :session_id, :signature, :parent_id])
      |> cast_assoc(:marks, with: &Mark.changeset/2)
      |> validate_required([:id, :session_id])
  end

  def mutate_changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:id, :body, :active])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end
end
