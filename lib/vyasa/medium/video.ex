defmodule Vyasa.Medium.Video do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Medium.Voice

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "videos" do
    field :type, :string
    field :ext_uri, :string

    belongs_to :voice, Voice, type: Ecto.UUID

    timestamps(type: :utc_datetime)
   end

  @doc false
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
