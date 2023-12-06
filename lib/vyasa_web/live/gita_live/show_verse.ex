defmodule VyasaWeb.GitaLive.ShowVerse do
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
      <:subtitle><%= @verse.chapter_number %>:<%= @verse.verse_number %></:subtitle>
      <p class="font-dn text-2xl"><%= @verse.text |> String.split("।।") |> List.first() %></p>
    </.header>
    <br />
    <p><%= @verse.transliteration %></p>
    <br />
    <p><%= @verse.word_meanings %></p>
    <br />
    <.button
    phx-hook="ShareQuoteButton"
    id="ShareQuoteButton"
    data-verse={Jason.encode!(@verse)}
    data-share-title={"Gita Chapter #{@verse.chapter_number} #{@verse.title}"}
    >
      Share
    </.button>

    <.back navigate={~p"/gita/#{@verse.chapter_number}"}>
      Back to Gita Chapter <%= @verse.chapter_number %>
    </.back>
    <.back navigate={~p"/gita"}>Back to Gita</.back>
    """
  end

  # <.link patch={~p"/gita/#{@chapter.id}"} phx-click={JS.push_focus()}> <.button>Annotate</.button> </.link>
  @impl true
  def handle_params(%{"chapter_id" => chapter_no, "verse_id" => verse_no}, _, socket) do
    {:noreply,
     socket
     |> assign(:chapter, Gita.chapters(chapter_no))
     |> stream(:verses, Gita.verses(chapter_no))
     |> assign(:verse, Gita.verse(chapter_no, verse_no))}
  end

end
