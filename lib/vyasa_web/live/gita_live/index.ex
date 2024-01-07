defmodule VyasaWeb.GitaLive.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Corpus.Gita

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :chapters, Gita.chapters())}
  end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Chapters in Gita")
    |> assign(:text, nil)
    |> assign_meta()

  end

  defp assign_meta(socket) do
    assign(socket, :meta, %{
      title: "Gita",
      description: "The Song Celestial",
      type: "website",
      url: url(socket, ~p"/gita/"),
    })
  end
end
