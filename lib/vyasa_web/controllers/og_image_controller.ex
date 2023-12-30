defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller
  alias Vyasa.Corpus.Gita
  alias VyasaWeb.GitaLive.ImageGenerator

  def show(conn, %{"filename" => filename}) do
    target_url = System.tmp_dir() |> Path.join(filename)

    case File.exists?(target_url) do
      true ->
        conn
        |> put_resp_content_type("image/png")
        |> send_file(200, target_url)
      _ ->
        create_image_just_in_time(filename)
        conn
        |> put_resp_content_type("image/png")
        |> send_file(200, target_url)
    end

  end

  @opengraph_filename_prefix "opengraph_file"
  @image_file_ext ".png"
  def create_image_just_in_time(filename) do
    [chapter_num, verse_num] = Regex.scan(~r/\d+/, filename) |> List.flatten()
    verse = Gita.verse(chapter_num, verse_num)
    filename =
      @opengraph_filename_prefix <>
        "-" <> chapter_num <> "-" <> verse_num <> @image_file_ext
    ImageGenerator.generate_opengraph_image(filename, verse.text)
  end
 end
