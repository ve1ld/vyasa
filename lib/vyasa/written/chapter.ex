defmodule Vyasa.Written.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Verse, Translation}

  @primary_key false
  schema "chapters" do
    field :no, :integer, primary_key: :true
    field :body, :string
    field :title, :string
    # field :indic_name, :string
    # field :indic_name_meaning, :string
    # field :indic_summary, :string
    # field :indic_name_translation, :string
    # field :indic_name_transliteration, :string

    belongs_to :source, Source, references: :id, foreign_key: :source_id, type: :binary_id, primary_key: :true
    has_many :verses, Verse, references: :no, foreign_key: :chapter_no
    has_many :translations, Translation, references: :no, foreign_key: :chapter_no
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:body, :no, :title])
    |> cast_assoc(:verses)
  end
end
