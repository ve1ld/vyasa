defmodule Vyasa.Adapters.OgAdapter do
  @moduledoc """
  Contains logic pertaining to the OpenGraph API, particularly serving as the adapter b/w
  our liveview and our filesystem that contains necessary og assets.
  """

  alias Vyasa.Corpus.Gita

  @doc """
  Retrieves the actual content from the gita that is alluded to by an opengraph file name.
  """
  def get_content(:gita, filename) do
    case Regex.scan(~r/\d+/, filename) |> List.flatten() do
      [chapter_num, verse_num] -> # TODO: this could use better guards. e.g. gita-1-000.png will break it
        %{text: text} = Gita.verse(chapter_num, verse_num)
        %{"src"=> :gita , "text"=> text}
      _ -> {:error, "Malformed / unsupported filename #{filename}"}
    end
  end


  @doc """
  Returns a complete url that can be used by any entity to find this file.
  This function aims to abstract away the actual location (i.e. local tmp dir or s3[future])
  """
  def get_og_file_url(filename) do
    System.tmp_dir() |> Path.join(filename)
  end

  @doc """
  Returns a string representing the filename for a particular verse from a particular chapter of
  the gita. Currently just supports gita.
  """
  def encode_filename(src, [chapter_num, verse_num]) when src == :gita do
    gita_uuid = "gita" # TODO: consider better unique ids based on what we want to support for our corpus.
    gita_uuid <> "-" <> Integer.to_string(chapter_num) <> "-" <> Integer.to_string(verse_num) <> ".png"
  end


  @doc """
  Returns a map of information that can be gleaned from the filename.
  """
  def decode_filename(src, filename) when src == :gita do
    [chapter_num, verse_num] = Regex.scan(~r/\d+/, filename) |> List.flatten()
    %{chapter_num => chapter_num, verse_num => verse_num}
  end

  @supported_src_ids ["gita"]
  @doc """
  Resolves src id from filename. Currently merely converts it to an existing atom.
  """
  def resolve_src_id(filename) do
    src_id = List.first(String.split(filename, "-"))
    case Enum.member?(@supported_src_ids, src_id) do
      true -> {:ok, String.to_existing_atom(src_id)}
      _ -> {:error, "Unsupported source"}
    end
  end

end
