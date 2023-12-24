defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller

  def show(conn, %{"filename" => filename}) do
    target_url = System.tmp_dir() |> Path.join(filename)
    case File.exists?(target_url) do
      true ->
        conn
        |> put_resp_content_type("image/png")
        |> send_file(200, target_url)
      _ ->
        conn
        |> send_resp(404, "Not found")
    end
  end
 end
