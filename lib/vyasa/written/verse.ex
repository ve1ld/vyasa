defmodule Vyasa.Written.Verse do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Translation, Transliteration, Transcript, Medium}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "verses" do
    field :chapter_num, :integer, default: 0 # for sources that don't have any chapters
    field :verse_num, :integer
    field :verse_text, :string

    belongs_to :source, Source
    has_many :translations, Translation
    has_many :transliterations, Transliteration
    has_many :transcripts, Transcript
    has_many :media, Medium
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:chapter_num, :verse_num, :verse_text])
    |> validate_required([:verse_num, :verse_text])
  end
end
