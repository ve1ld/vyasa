defmodule Vyasa.Medium.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Medium.Voice

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "tracks" do
    field :title, :string
    has_many :voices, Voice

    timestamps(type: :utc_datetime)
  end

  @doc false
  def gen_changeset(track, attrs) do
    track
    |> cast(attrs, [:id, :title])
    |> cast_assoc(:verses)
    |> validate_required([:title])
  end

  def mutate_changeset(track, attrs) do
    track
    |> cast(attrs, [:id, :title])
    |> cast_assoc(:verses)
  end
end
