defmodule Vyasa.Medium do
  alias Vyasa.Medium.Voice
  alias Vyasa.Repo

  @doc """
  Creates a voice.

  ## Examples

      iex> create_voice(%{field: value})
      {:ok, %Voice{}}

      iex> create_voice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_voice(attrs \\ %{}) do
    %Voice{}
    |> Voice.gen_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a voice.

  ## Examples

      iex> update_voice(voice, %{field: new_value})
      {:ok, %Voice{}}

      iex> update_voice(voice, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_voice(%Voice{} = voice, attrs) do
    voice
    |> Voice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a voice.

  ## Examples

      iex> delete_voice(voice)
      {:ok, %Voice{}}

      iex> delete_voice(voice)
      {:error, %Ecto.Changeset{}}

  """
  def delete_voice(%Voice{} = voice) do
    Repo.delete(voice)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking voice changes.

  ## Examples
      iex> change_voice(voice)
      %Ecto.Changeset{data: %Voice{}}
  """
  def change_voice(%Voice{} = voice, attrs \\ %{}) do
    Voice.changeset(voice, attrs)
  end

end
