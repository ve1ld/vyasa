defmodule Vyasa.Written.Medium do
  use Ecto.Schema
  # import Ecto.Changeset

  alias Vyasa.Written.{Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "media" do
    # TODO: create schema for transcripts...
    belongs_to :verse, Verse
  end

  # @doc false
  # def changeset(text, _attrs) do
  #   text
  #   # |> cast(attrs, [:title])
  #   # |> validate_required([:title])
  # end
end
