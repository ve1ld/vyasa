defmodule Vyasa.Medium do
  alias Vyasa.Medium.{Voice, Store}
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
  Gets a voice just for testing purposes
  """
  def get_voice_stub() do
    example_url = "/Users/ritesh/Desktop/example.mp3"

    {:ok, inserted_v} = %Voice{
      lang: "sa",
      file_path: example_url,
    }
    |> Repo.insert()

    {:ok, stored_url} = Store.put(inserted_v)

    inserted_v
    |> update_voice(%{file_path: stored_url})

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
