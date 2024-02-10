defmodule Vyasa.Medium do
  alias Vyasa.Medium.{Voice, Store, Writer}
  alias Vyasa.Medium
  alias Vyasa.Written
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

  @voice_stub_url "/Users/ritesh/Desktop/example.mp3"
  @doc """
  Gets a voice just for testing purposes
  """
  def get_voice_stub() do
    src = Written.get_source_by_title("Gita")
    {:ok, voice} = Medium.create_voice(%{lang: "sa", source_id: src.id})

    stored_url = %{voice | file_path: @voice_stub_url}
    |> Writer.run()
    |> then(&(elem(&1,1).key))
    |> Store.get!()


    # since it's a virtual field for now, let the stub have a non nil value:
    %Voice{voice | file_path: stored_url}

  end

  def get_voice_stub(params) do
    src = Written.get_source_by_title("Gita")
    {:ok, voice} = Medium.create_voice(%{params | lang: "sa", source_id: src.id})

    stored_url = %{voice | file_path: @voice_stub_url}
    |> Writer.run()
    |> then(&(elem(&1,1).key))
    |> Store.get!()


    # since it's a virtual field for now, let the stub have a non nil value:
    %Voice{voice | file_path: stored_url}

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
