defmodule Vyasa.Written.Verse do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Chapter, Translation, Transliteration, Transcript, Medium}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "verses" do
    field :no, :integer
    field :body, :string
    # QQ: compiler was looking for this but not sure what made it look for this field since the migration file doesn't use this name

    belongs_to :source, Source, type: Ecto.UUID
    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    has_many :translations, Translation
    has_many :transliterations, Transliteration
    has_many :transcripts, Transcript
    has_many :media, Medium
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:body, :no, :source_id])
    |> cast_assoc(:translations)
    |> cast_assoc(:transliterations)
    |> cast_assoc(:transcripts)
    |> cast_assoc(:media)
    |> validate_required([:no, :body])
  end
end
