defmodule Vyasa.Adapters.Binding do
  @moduledoc """
  Bindings that unite cross referential Archetypal Data Structs, they can be both persistent and virtual
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Verse, Source, Chapter}


  embedded_schema do
    belongs_to :verse, Verse, foreign_key: :verse_id, type: :binary_id
    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    belongs_to :source, Source, foreign_key: :source_id, type: :binary_id

    embeds_one :window, Window, on_replace: :delete do
      field(:key, :string) # from target assoc hierarchy source >> chapter >> verse >> translations tie to matrix
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
end
