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
    [chapter_num, verse_num] = Regex.scan(~r/\d+/, filename) |> List.flatten()
    %{text: text} = Gita.verse(chapter_num, verse_num)

    %{"src"=> :gita , "text"=> text}
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

  TODO: use text-id of some sort to generify the text part.
  """
  def encode_filename(src, [chapter_num, verse_num]) when src == :gita do
    Integer.to_string(chapter_num) <> "-" <> Integer.to_string(verse_num) <> ".png"
  end


  @doc """
  Returns a map of information that can be gleaned from the filename.
  """
  def decode_filename(src, filename) when src == :gita do
    [chapter_num, verse_num] = Regex.scan(~r/\d+/, filename) |> List.flatten()
    %{chapter_num => chapter_num, verse_num => verse_num}
  end


 end
