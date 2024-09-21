defmodule Vyasa.Sangh.Session do
  use Ecto.Schema
  import Ecto.Changeset

 alias Vyasa.Sangh.{Comment}

  @derive {Jason.Encoder, only: [:id]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "sessions" do

    has_many :comments, Comment, references: :id, foreign_key: :session_id, on_replace: :delete_if_exists

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:id])
  end
end
