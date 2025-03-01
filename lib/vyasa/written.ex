defmodule Vyasa.Written do
  @moduledoc """
  The Written context.
  """

  import Ecto.Query, warn: false
  alias Vyasa.Repo

  alias Vyasa.Written.{Text, Source, Verse, Chapter, Translation}

  @doc """
  Guards for any uuidV4

  ## Examples

  iex> is_uuid?("hanuman")
  false

  """
  defguard is_uuid?(value)
           when is_bitstring(value) and
                  byte_size(value) == 36 and
                  binary_part(value, 8, 1) == "-" and
                  binary_part(value, 13, 1) == "-" and
                  binary_part(value, 18, 1) == "-" and
                  binary_part(value, 23, 1) == "-"

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
  Returns the list of sources.

  ## Examples

      iex> list_sources()
      [%Source{}, ...]

  """
  def list_sources do
    Repo.all(Source)
    |> Repo.preload([:chapters, :verses])
  end

  @doc """
  Returns the list of verses.

  ## Examples

      iex> list_verses()
      [%Verse{}, ...]

  """
  def list_verses do
    Repo.all(Verse)
    |> Repo.preload([:chapter])
  end

  @doc """
  Returns the list of chapters.

  ## Examples

      iex> list_chapters()
      [%Chapter{}, ...]

  """
  def list_chapters do
    Repo.all(Chapter)
    |> Repo.preload([:verses])
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

  def get_text_by_title!(title), do: Repo.get_by!(Text, title: title)

  @doc """
  Gets a single source by id.

  Raises `Ecto.NoResultsError` if the Text does not exist.

  ## Examples

      iex> get_source!(<uuid>)
      %Source{}

      iex> get_text!(<uuid>)
      ** (Ecto.NoResultsError)

  """
  def get_source!(id),
    do:
      Repo.get!(Source, id)
      |> Repo.preload([:chapters, :verses])

  def get_source_by_title(title) do
    query =
      from src in Source,
        where: src.title == ^title,
        preload: [verses: [:translations], chapters: [:translations]]

    Repo.one(query)
    |> lang2script()
  end

  def get_chapters_by_src(src_title) do
    from(c in Chapter,
      inner_join: src in assoc(c, :source),
      where: src.title == ^src_title,
      inner_join: t in assoc(c, :translations),
      on: t.source_id == src.id
    )
    |> select_merge([c, src, t], %{
      c
      | translations: [t],
        source: src
    })
    |> Repo.all()
  end

  def list_chapters_by_source(sid, lang) when is_uuid?(sid) do
    from(c in Chapter,
      where: c.source_id == ^sid,
      join: ts in assoc(c, :translations),
      on: ts.source_id == ^sid and ts.lang == ^lang
    )
    |> select_merge([c, t], %{
      c
      | translations: [t]
    })
    |> Repo.all()
  end

  def list_chapters_by_source(source_title, lang) when is_binary(source_title) do
    %Source{id: id} = _src = get_source_by_title(source_title)
    list_chapters_by_source(id, lang)
  end

  def get_chapter(no, source_title) do
    from(c in Chapter,
      where: c.no == ^no,
      inner_join: src in assoc(c, :source),
      where: src.title == ^source_title
    )
    |> Repo.one()
  end

  def get_chapter(no, sid, lang) when is_uuid?(sid) do
    target_lang =
      from ts in Translation,
        where: ts.lang == ^lang and ts.source_id == ^sid

    from(c in Chapter,
      where: c.no == ^no and c.source_id == ^sid,
      preload: [
        verses:
          ^from(v in Verse,
            where: v.source_id == ^sid,
            order_by: v.no,
            preload: [translations: ^target_lang]
          ),
        translations: ^target_lang
      ]
    )
    |> Repo.one()
  end

  def get_chapter(no, source_title, lang) do
    %Source{id: id} = _src = get_source_by_title(source_title)

    target_lang =
      from ts in Translation,
        where: ts.lang == ^lang and ts.source_id == ^id

    from(c in Chapter,
      where: c.no == ^no and c.source_id == ^id,
      preload: [
        verses:
          ^from(v in Verse,
            where: v.source_id == ^id,
            order_by: v.no,
            preload: [translations: ^target_lang]
          ),
        translations: ^target_lang
      ]
    )
    |> Repo.one()
  end

  def get_verses_in_chapter(no, source_id) when is_uuid?(source_id) do
    query_verse =
      from v in Verse,
        where: v.chapter_no == ^no and v.source_id == ^source_id
    Repo.all(query_verse)
  end

  def get_verses_in_chapter(no, source_title) when is_binary(source_title) do
    %Source{id: id} = _src = get_source_by_title(source_title)

    query_verse =
      from v in Verse,
        where: v.chapter_no == ^no and v.source_id == ^id

    Repo.all(query_verse)
  end


  def create_translation(attrs \\ %{}) do
    %Translation{}
    |> Translation.changeset(attrs)
    |> Repo.insert()
  end

  def delete_translation(%Translation{} = translation) do
    Repo.delete(translation)
  end


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

  @doc """
  Creates a source.

  ## Examples

      iex> create_source(%{field: value})
      {:ok, %Source{}}

      iex> create_source(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_source(attrs \\ %{}) do
    %Source{}
    |> Source.gen_changeset(attrs)
    |> Repo.insert()
  end

  def fetch_source(%{"title" => title} = attrs) do
    case get_source_by_title(title) do
      %Source{} = source -> {:ok, source}
        _ -> create_source(attrs)
    end
  end

  @doc """
  Updates a source.

  ## Examples

      iex> update_source(source, %{field: new_value})
      {:ok, %Source{}}

      iex> update_source(source, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_source(%Source{} = source, attrs) do
    source
    |> Source.mutate_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a source.

  ## Examples

      iex> delete_source(source)
      {:ok, %Source{}}

      iex> delete_source(source)
      {:error, %Ecto.Changeset{}}

  """
  def delete_source(%Source{} = source) do
    Repo.delete(source)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking source changes.

  ## Examples
      iex> change_source(source)
      %Ecto.Changeset{data: %Source{}}
  """
  def change_source(%Source{} = source, attrs \\ %{}) do
    Source.mutate_changeset(source, attrs)
  end

  # Sanskrit
  defp lang2script(%Source{lang: "sa"} = s), do: %{s | script: "dn"}
  # Awadhi
  defp lang2script(%Source{lang: "awa"} = s), do: %{s | script: "dn"}
  # Tamil
  defp lang2script(%Source{lang: "ta"} = s), do: %{s | script: "ta"}

  # fallthrough to devanagari
  defp lang2script(%Source{} = s), do: %{s | script: "dn"}
  defp lang2script(_), do: nil
end
