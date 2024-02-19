defmodule Vyasa.Written.Source do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Written.{Chapter, Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "sources" do
    field :title, :string
    has_many :verses, Verse
    has_many :chapters, Chapter

    timestamps(type: :utc_datetime)
  end

  @doc false
  def gen_changeset(source, attrs) do
    source
    |> cast(attrs, [:id, :title])
    |> cast_assoc(:chapters)
    |> cast_assoc(:verses)
    |> validate_required([:title])
  end

  def mutate_changeset(source, attrs) do
    source
    |> cast(attrs, [:id, :title])
    |> cast_assoc(:chapters)
    |> cast_assoc(:verses)
    |> validate_required([:id, :title])
  end
end