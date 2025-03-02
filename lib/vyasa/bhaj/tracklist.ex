defmodule Vyasa.Bhaj.Tracklist do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Medium.Track

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "tracklists" do
    field :title, :string
    field :cursor, :integer, default: 0,  virtual: true #keeps track of stateful order
    has_many :tracks, Track, references: :id, foreign_key: :trackls_id
    has_many :events, through: [:tracks, :event]
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(track_list, attrs) do
    track_list
    |> cast(attrs, [:id, :title])
    |> cast_assoc(:tracks)
  end
end
