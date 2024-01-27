defmodule Vyasa.Written.Transliteration do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "transliterations" do
    field :language, :string
    field :body, :string
    field :meaning, :string

    belongs_to :verse, Verse
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:language, :body])
    |> validate_required([:language, :body])
  end
end
