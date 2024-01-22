defmodule Vyasa.Written.Source do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "sources" do
    field :title, :string
    has_many :verses, Verse
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
