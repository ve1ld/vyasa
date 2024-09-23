defmodule Vyasa.Medium.Video do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Medium.Voice

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "videos" do
    field :type, :string
    field :ext_uri, :string

    belongs_to :voice, Voice, references: :id, foreign_key: :voice_id, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:type, :ext_uri])
  end

  def gen_changeset(video, attrs, %Voice{id: voice_id}) do
    %{video | voice_id: voice_id}
    |> cast(attrs, [:type, :ext_uri])
    |> validate_required([:type, :ext_uri])
  end
end
