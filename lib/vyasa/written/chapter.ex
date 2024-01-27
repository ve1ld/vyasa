defmodule Vyasa.Written.Chapter do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "verses" do
    field :no, :integer
    field :body, :string
    field :title, :string

    belongs_to :source, Source
    has_many :verses, Verse
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:body, :no, :title])
  end
end
