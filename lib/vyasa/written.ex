defmodule Vyasa.Written do
  @moduledoc """
  The Written context.
  """

  import Ecto.Query, warn: false
  alias Vyasa.Repo

  alias Vyasa.Written.Text

  @doc """
  Returns the list of texts.

  ## Examples

      iex> list_texts()
      [%Text{}, ...]

  """
  def list_texts do
    Repo.all(Text)
  end

  @doc """
  Gets a single text.

  Raises `Ecto.NoResultsError` if the Text does not exist.

  ## Examples

      iex> get_text!(123)
      %Text{}

      iex> get_text!(456)
      ** (Ecto.NoResultsError)

  """
  def get_text!(id), do: Repo.get!(Text, id)

  @doc """
  Creates a text.

  ## Examples

      iex> create_text(%{field: value})
      {:ok, %Text{}}

      iex> create_text(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_text(attrs \\ %{}) do
    %Text{}
    |> Text.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a text.

  ## Examples

      iex> update_text(text, %{field: new_value})
      {:ok, %Text{}}

      iex> update_text(text, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_text(%Text{} = text, attrs) do
    text
    |> Text.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a text.

  ## Examples

      iex> delete_text(text)
      {:ok, %Text{}}

      iex> delete_text(text)
      {:error, %Ecto.Changeset{}}

  """
  def delete_text(%Text{} = text) do
    Repo.delete(text)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking text changes.

  ## Examples

      iex> change_text(text)
      %Ecto.Changeset{data: %Text{}}

  """
  def change_text(%Text{} = text, attrs \\ %{}) do
    Text.changeset(text, attrs)
  end
end
