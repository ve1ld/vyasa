defmodule VyasaWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use VyasaWeb, :controller

  def call(conn, {:error, :unprocessable_entity}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(VyasaWeb.ErrorHTML)
    |> render(:"422")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(VyasaWeb.ErrorHTML)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(VyasaWeb.ErrorHTML)
    |> render(:"403")
  end

  def call(conn, {:error, :null_image}) do
    conn
    |> put_status(:not_found)
    |> put_resp_content_type("image/svg+xml")
    # path to default logo svg
    |> send_file(200, :code.priv_dir(:vyasa) |> Path.join("/static/images/logo.svg"))
  end
end
