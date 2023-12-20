defmodule VyasaWeb.GitaLive.Show do
  use VyasaWeb, :live_view
  alias Vyasa.Corpus.Gita

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"chapter_id" => id}, _, socket) do
    {:noreply, socket
    |> assign(:chapter, Gita.chapters(id))
    |> stream(:verses, Gita.verses(id))
    |> assign_meta()}
  end

  defp assign_meta(socket) do
    %{
      :chapter_number => chapter,
      :chapter_summary => summary,
      :name => chapter_name,
      :name_meaning => meaning,
    } = socket.assigns.chapter

    assign(socket, :meta, %{
      title: "Chapter #{chapter} | #{chapter_name} -- #{meaning}",
      description: summary,
      type: "website",
      url: url(socket, ~p"/gita/#{chapter}"),
    })
  end
end
