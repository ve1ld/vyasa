defmodule Vyasa.SanghFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vyasa.Sangh` context.
  """

  @doc """
  Generate a session.
  """
  def session_fixture(attrs \\ %{}) do
    {:ok, session} =
      attrs
      |> Enum.into(%{
        id: "7488a646-e31f-11e4-aace-600308960662"
      })
      |> Vyasa.Sangh.create_session()

    session
  end
end
