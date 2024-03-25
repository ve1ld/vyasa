defmodule Vyasa.Written.Verse do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Chapter, Translation}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "verses" do
    field :no, :integer
    field :body, :string

    belongs_to :source, Source, type: Ecto.UUID
    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    has_many :translations, Translation
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:id, :body, :no, :source_id, :chapter_no])
    |> cast_assoc(:translations)
    |> validate_required([:no, :body])
  end
end
