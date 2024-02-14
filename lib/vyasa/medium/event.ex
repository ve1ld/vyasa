defmodule Vyasa.Medium.Event do
  use Ecto.Schema

  import Ecto.Changeset

  alias Vyasa.Written.{Verse, Source}
  alias Vyasa.Medium.Voice

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "events" do
    field :origin, :integer
    field :duration, :integer
    field :phase, :string

    embeds_many :fragments, EventFrag do
      field :offset, :integer
      field :duration, :integer
      field :quote, :string
      field :status, :string
    end

    belongs_to :verse, Verse, foreign_key: :verse_id, type: :binary_id
    belongs_to :voice, Voice, foreign_key: :voice_id, type: :binary_id
    belongs_to :source, Source, foreign_key: :source_id
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:origin, :duration, :phase, :verse_id, :voice_id, :source_id])
    |> cast_embed(:fragments, with: &frag_changeset/2)
    |> validate_required([:origin, :duration, :fragments, :source_id])
    |> validate_inclusion(:phase, ["start", "end"])
  end

  def frag_changeset(frag, attrs) do
    frag
    |> cast(attrs, [:offset, :duration,:quote])
  end
end
