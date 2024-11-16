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
  alias Vyasa.Sangh.Sheaf

  @supported_sheaf_traits ["personal", "draft", "published"]

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

    has_many :marks, Mark,
      references: :id,
      foreign_key: :sheaf_id,
      on_replace: :delete_if_exists,
      preload_order: [desc: :order],
      on_delete: :delete_all

    # has_many :bindings, Binding, references: :id, foreign_key: :sheaf_bind_id, on_replace: :delete_if_exists
    timestamps()
  end

  @doc false
  def changeset(%Sheaf{} = sheaf, attrs) do
    sheaf
    |> cast(attrs, [
      :id,
      :body,
      :active,
      :session_id,
      :signature,
      :traits,
      :updated_at,
      :inserted_at
    ])
    |> cast_path(attrs)
    |> assoc_marks(attrs)
    |> validate_required([:id, :session_id, :path])
    |> validate_include_subset(:traits, @supported_sheaf_traits)

    # QQ: @ks0m1c in my mind, i see private vs public and draft vs published as two distinct dimensions
    # and we'd want to filter by these dimensions separately. Therefore, I wonder if it's better to NOT keep
    # them all as string identifiers within a list.
  end

  def mutate_changeset(%Sheaf{} = sheaf, attrs) do
    IO.inspect(%{sheaf: sheaf, attrs: attrs}, label: "CHECKPOINT: mutate_changeset")

    cs =
      sheaf
      |> Vyasa.Repo.preload([:marks])
      |> cast(attrs, [:id, :body, :active, :signature, :traits])
      |> cast_path(attrs)
      |> assoc_marks(attrs)
      |> Map.put(:repo_opts, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id)
      |> validate_include_subset(:traits, ["personal", "draft", "published"])

    IO.inspect(cs, label: "CHECKPOINT: mutate changeset outcome changeset:")
    cs
  end

  defp assoc_marks(sheaf, %{marks: [%Mark{} | _] = marks}) do
    sheaf
    |> put_assoc(:marks, marks, with: &Mark.changeset/2)
  end

  defp assoc_marks(sheaf, _attrs) do
    sheaf
    |> cast_assoc(:marks, with: &Mark.changeset/2)
  end

  defp cast_path(%{changes: %{id: sheaf_id}} = sheaf, %{
         parent: %Sheaf{id: p_sheaf_id, path: lpath} = parent
       }) do
    IO.inspect(parent, label: "SEE ME : cast_path, parent:")

    sheaf
    |> cast(%{parent_id: p_sheaf_id, path: encode_path(sheaf_id, lpath)}, [:parent_id, :path])
  end

  defp cast_path(%{changes: %{id: sheaf_id}} = sheaf, _) do
    IO.inspect(sheaf, label: "SEE ME : cast_path, sheaf:")

    sheaf
    |> cast(%{path: encode_path(sheaf_id)}, [:path])
  end

  defp cast_path(%{data: %{id: sheaf_id}} = sheaf, %{parent: %Sheaf{id: p_sheaf_id, path: lpath}}) do
    cast(sheaf, %{parent_id: p_sheaf_id, path: encode_path(sheaf_id, lpath)}, [:parent_id, :path])
  end

  defp cast_path(sheaf, _) do
    sheaf
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

  #   @doc """
  #   Encodes lpath with sheaf id and parent_path (in string).
  #   Parent first then child

  #   ## Examples

  #       iex> encode_lpath("789", %Ltree{})
  #       123.456.789

  #   """
  #
  def encode_path(id, %Ltree{} = parent_ltree) when is_binary(id) do
    to_string(parent_ltree) <> "." <> hd(String.split(id, "-"))
  end

  def encode_path(_, _) do
    nil
  end

  #   @doc """
  #   Encodes lpath with sheaf id.
  #   A typical UUID has sections delimited by "-" character e.g. "178bf506-e0fa-4972-b390-5781efb5de2b".
  #   For a path_encode for a particular id, we shall take the head of that ==> 178bf506.
  #
  #   FIXME @ks0m1c I think this function is more accurately named as "encode_path_slug/encode_path_label" as opposed to "encode_path" because
  #   the path would imply that it's the full lpath for that sheaf.
  #   To give an example, let's take this nested grandchild sheaf: "178bf506-e0fa-4972-b390-5781efb5de2b".
  #   This function currently  returns: "178bf506",
  #   HOWEVER, the actual path will have the labels from its ancestors:  %EctoLtree.LabelTree{labels: ["039e537b", "81fccdaf", "178bf506"]}},
  #   Hence, this current function name of "encode" path is misleading.

  #   ## Examples

  #       iex> encode_lpath("123")
  #       123

  #   """
  #
  def encode_path(id) do
    hd(String.split(id, "-"))
  end

  @doc """
  Used to create the first (draft) sheaf for a sangh session, if no sheafs exist.
  This writes the sheaf to the db.
  """
  def draft!(sangh_id) when is_binary(sangh_id) do
    {:ok, com} =
      Vyasa.Sangh.create_sheaf(%{
        id: Ecto.UUID.generate(),
        session_id: sangh_id,
        traits: ["draft"]
      })

    com
  end

  def get_supported_sheaf_traits() do
    @supported_sheaf_traits
  end

  @doc """
  Returns the list of labels for a particular sheaf's path.
  """
  def get_path_labels(
        %Sheaf{
          path:
            %Ltree{
              labels: labels
            } = _path
        } = _sheaf
      ) do
    labels
  end
end
