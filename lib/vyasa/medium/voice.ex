defmodule Vyasa.Medium.Voice do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Medium.{Event, Video, Track}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "voices" do
    field :lang, :string
    field :title, :string
    field :duration, :integer
    field :file_path, :string, virtual: true

    ## FIXME: change field name to artists since it's an array..
    embeds_one :meta, VoiceMetadata do
      field(:artist, {:array, :string})
    end

    has_one :video, Video, references: :id, foreign_key: :voice_id
    has_many :events, Event, references: :id, foreign_key: :voice_id, preload_order: [asc: :origin]

    belongs_to :track, Track, references: :id, foreign_key: :track_id
    belongs_to :chapter, Chapter, type: :integer, references: :no, foreign_key: :chapter_no
    belongs_to :source, Source, references: :id, foreign_key: :source_id, type: :binary_id

    timestamps(type: :utc_datetime)
   end

  @doc false

  def gen_changeset(voice, attrs) do
    %{voice | id: Ecto.UUID.generate()}
    |> cast(attrs, [:id, :title, :duration, :lang, :file_path, :chapter_no, :source_id])
    |> cast_embed(:meta, with: &meta_changeset/2)
    |> file_upload()
  end

  def changeset(voice, attrs) do
    voice
    |> cast(attrs, [:id, :title, :duration, :lang, :file_path, :chapter_no, :source_id])
    |> cast_embed(:meta, with: &meta_changeset/2)
    |> cast_assoc(:video)
    |> cast_assoc(:events)
  end

  def meta_changeset(voice, attrs) do
    voice
    |> cast(attrs, [:artist])
  end

  def file_upload(%Ecto.Changeset{changes: %{file_path: _} = changes} = ec) do
    ext_path = apply_changes(ec)
    |> Vyasa.Medium.Writer.run()
    |> then(&elem(&1, 1).key)
    |> Vyasa.Medium.Store.get!()

    %{ec | changes: %{changes | file_path: ext_path}}
  end

  def file_upload(ec), do: ec
end
