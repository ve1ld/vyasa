defmodule Vyasa.Sangh.Comment do
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
    field :child_count, :integer, default: 0, virtual: true

    belongs_to :session, Session, references: :id, type: Ecto.UUID
    belongs_to :parent, Comment, references: :id, type: Ecto.UUID

    #has_many :marks, Mark, references: :id, foreign_key: :comment_bind_id, on_replace: :delete_if_exists
    #has_many :bindings, Binding, references: :id, foreign_key: :comment_bind_id, on_replace: :delete_if_exists

    timestamps()
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
      |> cast(attrs, [:id, :body, :path, :chapter_number, :p_type, :session_id, :parent_id, :text_id])
      |> cast_assoc(:bindings, with: &Mark.changeset/2)
      |> validate_required([:id, :session_id])
  end

  def mutate_changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:id, :body, :active])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end
end
