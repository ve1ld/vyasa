defmodule Vyasa.Medium.Voice do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Medium.{Video, Track}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "voices" do
    field :lang, :string
    field :title, :string
    field :duration, :integer
    field :file_path, :string, virtual: true

    embeds_one :prop, VoiceProperties do
      field(:artist, {:array, :string})
    end

    belongs_to :track, Track, references: :id, foreign_key: :track_id
    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    has_one :video, Video, references: :id, foreign_key: :voice_id
    belongs_to :source, Source, references: :id, foreign_key: :source_id, type: :binary_id

    timestamps(type: :utc_datetime)
   end

  @doc false

  def gen_changeset(voice, attrs) do
    voice
    |> cast(attrs, [:title, :duration, :lang])
    |> cast_embed(:prop, with: &prop_changeset/2)
  end

  def changeset(voice, attrs) do
    voice
    |> cast(attrs, [:title, :duration, :lang, :file_path])
    |> cast_embed(:prop, with: &prop_changeset/2)
    # |> cast_assoc(:videos)
  end

  def prop_changeset(voice, attrs) do
    voice
    |> cast(attrs, [:artist])
  end
end
