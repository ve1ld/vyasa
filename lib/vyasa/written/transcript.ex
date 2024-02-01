defmodule Vyasa.Written.Transcript do
  use Ecto.Schema
  # import Ecto.Changeset

  alias Vyasa.Written.{Verse}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "transcripts" do
    # TODO: create schema for transcripts...
    belongs_to :verse, Verse
  end
end
