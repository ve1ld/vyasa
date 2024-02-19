defmodule Vyasa.Medium do

  import Ecto.Query, warn: false
  alias Vyasa.Medium.{Voice, Event}
  alias Vyasa.Medium
  alias Vyasa.Written
  # alias Vyasa.Written.{Chapter}
  alias Vyasa.Repo


  @doc """
  Gets a single voice.

  Raises `Ecto.NoResultsError` if the Voice does not exist.

  ## Examples

      iex> get_voice!(123)
      %Voice{}

      iex> get_voice!(456)
      ** (Ecto.NoResultsError)

  """
  def get_voice!(id) do
    Repo.get!(Voice, id)
    |> Repo.preload([:events])
  end


  def get_voices!(%Voice{source_id: src_id, chapter_no: c_no, lang: l}) do
    from(v in Voice,
      where: v.source_id == ^src_id and v.chapter_no == ^c_no and v.lang == ^l,
      preload: [:events])
    |> Repo.all()
  end


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

  @voice_stub_url Path.expand("./media/gita/1.mp3")
  @doc """
  Gets a voice just for testing purposes
  """
  def get_voice_stub() do
    src = Written.get_source_by_title("Gita")
    {:ok, %Voice{ id: voice_id } = voice} = Medium.create_voice(%{lang: "sa", source_id: src.id, file_path: @voice_stub_url})
    # since it's a virtual field for now, let the stub have a non nil value:
    %Voice{voice | title: "Gita"}

    get_voice!(voice_id) |> dbg()

  end

  #should be using \\ %{} and be ! as its not accounting for :error tuple
  def get_voice_stub(params) do
    src = Written.get_source_by_title("Gita")
    {:ok, voice} = Medium.create_voice(%{params | lang: "sa", source_id: src.id}
      |> Map.put(:file_path, @voice_stub_url))

    # since it's a virtual field for now, let the stub have a non nil value:
    voice

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

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)


    @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_event(attrs \\ %{})
  def create_event(%Event{} = event) do
    event
    |> Repo.insert()
  end
  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples
      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}
  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end



 end
