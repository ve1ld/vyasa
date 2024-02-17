defmodule Vyasa.Written.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Verse, Translation, Chapter}
  alias Vyasa.Medium.{Voice}

  @primary_key false
  schema "chapters" do
    field :no, :integer, primary_key: :true
    field :key, :string
    field :body, :string
    field :title, :string
    belongs_to :chapter, Chapter, references: :no, foreign_key: :parent_no

    belongs_to :source, Source, references: :id, foreign_key: :source_id, type: :binary_id, primary_key: :true
    has_many :verses, Verse, references: :no, foreign_key: :chapter_no
    has_many :translations, Translation, references: :no, foreign_key: :chapter_no
    has_many :voices, Voice, references: :no, foreign_key: :chapter_no
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:body, :no, :title])
    |> cast_assoc(:verses)
  end
end
