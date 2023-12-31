defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller
  alias VyasaWeb.GitaLive.ImageGenerator
  alias Vyasa.Adapters.OgAdapter

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


  def fetch_image_jit(filename) do
    target_url = System.tmp_dir() |> Path.join(filename)
    if File.exists?(target_url) do
      {:ok, target_url}
    else
      case get_content_for_file(filename) do
        %{"src" => :gita, "text" => text} ->
          ImageGenerator.generate_opengraph_image!(filename, text)
          {:ok, target_url}
        _ ->
          {:error, :null_image}
      end
    end
  end

  # TODO file name needs to have an identifier for the title of the text for a text based lookup currently defaults just to gita
  # TODO also needs unique title id -- perhaps we can just use url params for this for now.
  @doc """
  Fetches the actual content, by parsing the filename.

  For now, this shall only fetch gita-related content. Subsequently, this function may be
  updated to support other texts and media formats.
  """
  def get_content_for_file(filename) do
    OgAdapter.get_content(:gita, filename)
  end
end
