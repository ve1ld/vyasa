defmodule Vyasa.Adapters.Binding do
  @moduledoc """
  Bindings that unite cross referential Archetypal Data Structs, they can be both persistent and virtual
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Chapter, Verse, Translation}
  alias Vyasa.Sangh.{Sheaf}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "bindings" do
    field :w_type, Ecto.Enum, values: [:quote, :timestamp, :null]

    field :field_key, {:array, :any}

    field :node_id, :string, virtual: true

    belongs_to :verse, Verse, foreign_key: :verse_id, type: :binary_id
    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    belongs_to :source, Source, foreign_key: :source_id, type: :binary_id
    belongs_to :translation, Translation, foreign_key: :translation_id, type: :binary_id
    belongs_to :sheaf, Sheaf, foreign_key: :sheaf_id, type: :binary_id

    # window is essentially because bindings might only refer to a subset of a node
    # either by timestamping of events or through line no and character range
    embeds_one :window, Window, on_replace: :delete do
      field(:line_number, :integer)
      field(:start, :integer)
      field(:end, :integer)
      field(:quote, :string)

      field(:start_time, :integer)
      field(:end_time, :integer)
    end
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:verse_id, :voice_id, :source_id])
  end

  def windowing_changeset(%__MODULE__{} = binding, attrs) do
    binding
    |> cast(attrs, [:w_type, :verse_id, :chapter_no, :source_id])
    |> typed_window_switch(attrs)
    |> Map.put(:repo_opts, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id)
  end

  # when type changes
  def typed_window_switch(changeset, %{w_type: type}),
    do: typed_window_switch(changeset, %{"w_type" => type})

  def typed_window_switch(changeset, %{"w_type" => type}) do
    window_changeset =
      case type do
        "quote" ->
          &quote_changeset(&1, &2)

        "timestamp" ->
          &timestamp_changeset(&1, &2)

        _ ->
          &null_changeset(&1, &2)
      end

    cast_embed(changeset, :window, with: window_changeset)
  end

  def typed_window_switch(changeset, _attrs), do: validate_required(changeset, [:w_type])

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

  def cast(attrs) do
    %__MODULE__{}
    |> Vyasa.Repo.preload(__schema__(:associations))
    |> cast(attrs, [])
    |> put_all_assoc(attrs)
    |> apply_action(:binded)
  end

  def put_all_assoc(changeset, attrs) do
    assocs = __schema__(:associations)

    Enum.reduce(assocs, changeset, fn assoc, acc ->
      case Map.fetch(attrs, assoc) do
        {:ok, value} -> Ecto.Changeset.put_assoc(acc, assoc, value)
        :error -> acc
      end
    end)
  end

  def field_lookup(%Verse{}), do: :verse_id
  def field_lookup(%Chapter{}), do: :chapter_no
  def field_lookup(%Source{}), do: :source_id
  def field_lookup(%Translation{}), do: :translation_id
  def field_lookup(%Sheaf{}), do: :sheaf_id

  def field_lookup(_), do: nil
end
