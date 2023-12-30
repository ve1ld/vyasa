defmodule VyasaWeb.GitaLive.ShowVerse do
  use VyasaWeb, :live_view
  alias Vyasa.Corpus.Gita
  alias VyasaWeb.GitaLive.ImageGenerator

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
     |> assign_meta()}
  end

  defp assign_meta(socket) do
    IO.inspect(socket.assigns.verse)
    %{:chapter_id => chapter, :verse_number => verse, :text => text} = socket.assigns.verse

    assign(socket, :meta, %{
      title: "Chapter #{chapter} | Verse #{verse}",
      description: text,
      type: "website",
      image: url(~p"/og/#{get_image_url(socket, chapter, verse)}"),
      url: url(socket, ~p"/gita/#{chapter}/#{verse}")
    })
  end

  # TODO Encoder decoder pair need to by synced with independent adapter module
  @image_file_ext ".png"
  defp get_image_url(socket, chapter_num, verse_num) do
    filename = Integer.to_string(chapter_num) <> "-" <> Integer.to_string(verse_num) <> @image_file_ext
    target_url = System.tmp_dir() |> Path.join(filename)

    if File.exists?(target_url) do
      target_url
    else
      text = socket.assigns.verse.text
      ImageGenerator.generate_opengraph_image!(filename, text)
    end

    filename
  end
end
