defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller
  alias VyasaWeb.SourceLive.ImageGenerator
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
      case get_og_content(filename) do
        %{"src" => :gita, "text" => text} ->
          ImageGenerator.generate_opengraph_image!(filename, text)
          {:ok, target_url}
        _ ->
          {:error, :null_image}
      end
    end
  end

  @doc """
  Fetches the actual content, by parsing the filename.

  For now, this shall only fetch gita-related content. Subsequently, this function may be
  updated to support other texts and media formats.
  """
  def get_og_content(filename) do
    case OgAdapter.resolve_src_id(filename) do
      {:ok, :gita} -> OgAdapter.get_content(:gita, filename)
      _ -> {:error}
    end
  end
end
