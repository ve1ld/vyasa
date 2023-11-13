defmodule VyasaWeb.GitaLive.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Corpus.Gita

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :chapters, Gita.chapters())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
    <%= @page_title %>
    </.header>

    <.table
    id="texts"
    rows={@streams.chapters}
    row_click={fn {_id, text} -> JS.navigate(~p"/gita/#{text}") end}
    >
    <:col :let={{_id, text}} label="Title"><%= text.name_transliterated %></:col>
    <:col :let={{_id, text}} label="Description"><%= text.name_meaning %></:col>
    </.table>
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Chapters in Gita")
    |> assign(:text, nil)
  end
end
