defmodule VyasaWeb.GitaLive.Show do
  use VyasaWeb, :live_view
  alias Vyasa.Corpus.Gita

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @chapter.name_transliterated %>
        <:subtitle> <%= @chapter.chapter_summary %></:subtitle>
    </.header>

    <.list :for={{_dom_id, text} <- @streams.verses}>
        <:item title={"#{text.chapter_number}.#{text.verse_number}"}><p class="font-dn text-2xl"><%= text.text |> String.split("।।") |> List.first()  %></p></:item>
        <:item><%= text.transliteration %></:item>
        <:item><%= text.word_meanings %></:item>
    </.list>

    <.back navigate={~p"/gita"}>Back to Gita</.back>
    """
  end
  #<.link patch={~p"/gita/#{@chapter.id}"} phx-click={JS.push_focus()}> <.button>Annotate</.button> </.link>
  @impl true
  def handle_params(%{"chapter_id" => id}, _, socket) do
    {:noreply, socket
    |> assign(:chapter, Gita.chapters(id))
    |> stream(:verses, Gita.verses(id))}
  end
end
