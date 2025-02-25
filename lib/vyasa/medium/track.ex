defmodule Vyasa.Medium.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Medium.{Event}
  alias Vyasa.Bhaj.{Tracklist}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "tracks" do
    field :order, :integer
    #has_many :voices, Voice
    belongs_to :trackls, Tracklist, foreign_key: :trackls_id, type: :binary_id
    belongs_to :event, Event, foreign_key: :event_id, type: :binary_id

    timestamps(type: :utc_datetime)
  end


   def changeset(track, attrs) do
    track
    |> cast(attrs, [:order, :trackls_id, :event_id])
    |> validate_required([:order, :trackls_id, :event_id])
    |> foreign_key_constraint(:trackls_id)
    |> foreign_key_constraint(:event_id)
    #|> unique_constraint([:trackls_id, :order], name: "tracks_trackls_id_order_index")
  end


  @doc false
  def gen_changeset(track, attrs) do
    track
    |> cast(attrs, [:id, :order])
    |> cast_assoc(:event)
    |> validate_required([:order])
  end

  def mutate_changeset(track, attrs) do
    track
    |> cast(attrs, [:id, :title])
    |> cast_assoc(:verses)
  end
end
