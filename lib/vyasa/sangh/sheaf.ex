defmodule Vyasa.Sangh.Sheaf do
  @moduledoc """
  The Sheaf module represents a container for marks within a session, functioning as a waypoint and organizer for these marks based on their context.
  A Sheaf is designed to facilitate the management of marks by allowing them to be categorized into collapsible bundles and creating trails tied to specific sessions. This module acts as a mediator for handling marks, enabling their movement and reference according to the current context.

  Not your traditional sheafs, waypoints and containers for marks
  so that they can be referred to and moved around according to their context

  Can create a trail of marks and tied to session
  Can seperate marks into bundle collapsible categories

  Sangh session Ids is SOT on shared and individual context
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias EctoLtree.LabelTree, as: Ltree
  alias Vyasa.Sangh.{Sheaf, Session, Mark}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "sheafs" do
    field :body, :string
    # active in draft reflector
    field :active, :boolean, default: true
    field :path, Ltree
    field :signature, :string
    field :traits, {:array, :string}, default: []
    field :child_count, :integer, default: 0, virtual: true

    belongs_to :session, Session, references: :id, type: Ecto.UUID
    belongs_to :parent, Sheaf, references: :id, type: Ecto.UUID

    has_many :marks, Mark, references: :id, foreign_key: :sheaf_id, on_replace: :delete_if_exists

    # has_many :bindings, Binding, references: :id, foreign_key: :sheaf_bind_id, on_replace: :delete_if_exists
    timestamps()
  end

  @doc false
  def changeset(%Sheaf{} = sheaf, %{marks: [%Mark{} | _] = marks} = attrs) do
    sheaf
    |> cast(attrs, [:id, :body, :active, :path, :session_id, :signature, :parent_id, :traits])
    |> put_assoc(:marks, marks, with: &Mark.changeset/2)
    |> validate_required([:id, :session_id])
    |> validate_include_subset(:traits, ["personal", "draft", "publish"])
  end

  def changeset(%Sheaf{} = sheaf, attrs) do
    sheaf
    |> cast(attrs, [:id, :body, :active, :path, :session_id, :signature, :parent_id, :traits])
    |> cast_assoc(:marks, with: &Mark.changeset/2)
    |> validate_required([:id, :session_id])
    |> validate_include_subset(:traits, ["personal", "draft", "publish"])
  end

  def mutate_changeset(%Sheaf{} = sheaf, %{marks: [%Mark{} | _] = marks} = attrs) do
    sheaf
    |> Vyasa.Repo.preload([:marks])
    |> cast(attrs, [:id, :body, :active, :signature])
    |> put_assoc(:marks, marks, with: &Mark.changeset/2)
    |> Map.put(:repo_opts, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id)
  end

  def mutate_changeset(%Sheaf{} = sheaf, attrs) do
    sheaf
    |> cast(attrs, [:id, :body, :active])
    |> Map.put(:repo_opts, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id)
  end

  defp validate_include_subset(changeset, field, data, opts \\ []) do
    validate_change(changeset, field, {:superset, data}, fn _, value ->
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
        false ->
          [
            {field,
             {Keyword.get(opts, :message, "has an invalid entry"),
              [validation: :superset, enum: data]}}
          ]

        _ ->
          []
      end
    end)
  end
end
