defmodule Vyasa.Written.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Verse}

  @primary_key false
  schema "chapters" do
    field :no, :integer, primary_key: :true
    field :body, :string
    field :title, :string

    belongs_to :source, Source, references: :id, foreign_key: :source_id, type: :binary_id, primary_key: :true

    has_many :verses, Verse,  foreign_key: :chapter_no
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:body, :no, :title])
  end
end
