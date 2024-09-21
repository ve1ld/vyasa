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
    field :active, :boolean, default: true #active in drafting table
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
  def changeset(%Comment{} = comment, %{marks: [%Mark{} | _ ] = marks} = attrs) do
    comment
      |> cast(attrs, [:id, :body, :active, :path, :session_id, :signature, :parent_id, :traits])
      |> put_assoc(:marks, marks, with: &Mark.changeset/2)
      |> validate_required([:id, :session_id])
      |> validate_include_subset(:traits, ["personal", "draft", "publish"])
  end

  def changeset(%Comment{} = comment, attrs) do
    comment
      |> cast(attrs, [:id, :body, :active, :path, :session_id, :signature, :parent_id, :traits])
      |> cast_assoc(:marks, with: &Mark.changeset/2)
      |> validate_required([:id, :session_id])
      |> validate_include_subset(:traits, ["personal", "draft", "publish"])
  end

  def mutate_changeset(%Comment{} = comment, %{marks: [%Mark{} | _ ] = marks} = attrs) do
    comment
    |> Vyasa.Repo.preload([:marks])
    |> cast(attrs, [:id, :body, :active, :signature])
    |> put_assoc(:marks, marks, with: &Mark.changeset/2)
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def mutate_changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:id, :body, :active])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  defp validate_include_subset(changeset, field, data, opts \\ []) do
    validate_change changeset, field, {:superset, data}, fn _, value ->
      element_type =
        case Map.fetch!(changeset.types, field) do
          {:array, element_type} ->
            element_type
          type ->
            {:array, element_type} = Ecto.Type.type(type)
            element_type
        end

      Enum.map(data, &Ecto.Type.include?(element_type, &1, value))
      |> Enum.member?(true)
      |> case do
        false -> [{field, {Keyword.get(opts, :message, "has an invalid entry"), [validation: :superset, enum: data]}}]
        _ -> []
      end
    end
  end
end
