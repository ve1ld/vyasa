defmodule Vyasa.Medium.Voice do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Medium.{Video}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "voices" do
    field :lang, :string
    embeds_one :prop, VoiceProperties do
      field(:artist, {:array, :string})
    end

    field :file_path, :string, virtual: true

    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    has_one :video, Video, references: :id, foreign_key: :voice_id
    belongs_to :source, Source, references: :id, foreign_key: :source_id, type: :binary_id

    timestamps(type: :utc_datetime)
   end

  @doc false

  def gen_changeset(text, attrs) do
    text
    |> cast(attrs, [:lang])
    |> cast_embed(:prop, with: &prop_changeset/2)
    |> cast_assoc(:videos)
  end

  def changeset(text, attrs) do
    text
    |> cast(attrs, [:lang])
    |> cast_embed(:prop, with: &prop_changeset/2)
    |> cast_assoc(:videos)
  end

  def prop_changeset(text, attrs) do
    text
    |> cast(attrs, [:artist])
  end
end
