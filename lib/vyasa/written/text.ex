defmodule Vyasa.Written.Text do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "texts" do
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
