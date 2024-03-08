defmodule VyasaWeb.SourceLive.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Written

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :sources, Written.list_sources())}
  end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Sources")
    |> assign_meta()

  end

  defp assign_meta(socket) do
    assign(socket, :meta, %{
      title: "Sources to Explore",
      description: "Explore the wealth of indic knowledge, distilled into words.",
      type: "website",
      image: url(~p"/images/the_vyasa_project_1.png"),
      url: url(socket, ~p"/explore/"),
    })
  end
end
