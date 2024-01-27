defmodule Vyasa.Written.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "translations" do
    field :language, :string # to consider changing to language enum
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
