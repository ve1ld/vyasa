defmodule VyasaWeb.GitaLive.ShowVerse do
  use VyasaWeb, :live_view
  alias Vyasa.Corpus.Gita

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"chapter_id" => chapter_no, "verse_id" => verse_no}, _, socket) do
    {:noreply,
     socket
     |> assign(:chapter, Gita.chapters(chapter_no))
     |> stream(:verses, Gita.verses(chapter_no))
     |> assign(:verse, Gita.verse(chapter_no, verse_no))
     |> assign_meta()

    }
  end


  defp assign_meta(socket) do
    IO.inspect(socket.assigns.verse)
    %{:chapter_id => chapter, :verse_number => verse, :text => text} = socket.assigns.verse

    assign(socket, :meta, %{
      title: "Chapter #{chapter} | Verse #{verse}",
      description: text,
      type: "website",
      url: url(socket, ~p"/gita/#{chapter}/#{verse}"),
    })
  end

end
