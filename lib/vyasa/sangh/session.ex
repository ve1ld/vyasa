defmodule Vyasa.Sangh.Session do
  @moduledoc """
  A Sangh Session is similar to a game-room or a whiteboard session or book-club.
  The word "Sangh" here refers to assembly of people.

  Not to be confused with the web-browser / user-sessions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Sangh.{Sheaf}

  @derive {Jason.Encoder, only: [:id]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "sessions" do
    has_many :sheafs, Sheaf,
      references: :id,
      foreign_key: :session_id,
      on_replace: :delete_if_exists

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:id])
  end
end
