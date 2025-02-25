defmodule Vyasa.Bhaj.Tracklist do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Medium.Track

  schema "tracklists" do
    field :title, :string
    has_many :tracks, Track, references: :id, foreign_key: :trackls_id
    has_many :events, through: [:tracks, :event]
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(track_list, attrs) do
    track_list
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
