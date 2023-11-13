defmodule Vyasa.WrittenFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vyasa.Written` context.
  """

  @doc """
  Generate a text.
  """
  def text_fixture(attrs \\ %{}) do
    {:ok, text} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> Vyasa.Written.create_text()

    text
  end
end
