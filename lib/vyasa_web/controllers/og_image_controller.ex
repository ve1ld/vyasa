defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller
  alias Vyasa.Corpus.Gita
  alias VyasaWeb.GitaLive.ImageGenerator

  action_fallback VyasaWeb.FallbackController

  def show(conn, %{"filename" => filename}) do
    case fetch_image_jit(filename) do
      {:ok, target_url } ->
        conn
        |> put_resp_content_type("image/png")
        |> send_file(200, target_url)

      err -> err
    end
  end


  @image_file_ext ".png"
  def fetch_image_jit(filename) do
    target_url = System.tmp_dir() |> Path.join(filename)
    if File.exists?(target_url) do
      {:ok, target_url}
    else
      [chapter_num, verse_num] = Regex.scan(~r/\d+/, filename) |> List.flatten()
      # TODO file name needs to have an identifier for the title of the text for a text based lookup currently defaults just to gita
      case Gita.verse(chapter_num, verse_num) do
        %{text: text} ->
          # TODO create pathname encoder decoder adapter functions
          # TODO also needs unique title id
          filename = chapter_num <> "-" <> verse_num <> @image_file_ext
          ImageGenerator.generate_opengraph_image!(filename, text)
          # notice
          {:ok, target_url}
        _ ->
          {:error, :null_image}
      end
    end
  end
end
