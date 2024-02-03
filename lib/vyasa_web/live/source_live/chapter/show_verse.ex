defmodule VyasaWeb.SourceLive.Chapter.ShowVerse do
  use VyasaWeb, :live_view
  alias Vyasa.Written

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"source_title" => source_title, "chap_no" => chap_no, "verse_no" => verse_no}, _, socket) do
    verse = get_verse_via_url_params(String.to_integer(verse_no), chap_no, source_title)

    en_translation = verse.translations |> Enum.find(fn t -> t.lang == "en" end)

    {:noreply,
     socket
     |> assign(:source_title, source_title)
     |> assign(:chap_no, chap_no)
     |> assign(:verse_no, String.to_integer(verse_no))
     |> assign(:verse, verse)
     |> assign(:en_translation, en_translation)
     # |> assign_meta()
    }
     # |> assign(:chapter, Written.get_chapter(chap_no, source_id))
     # |> stream(:verses, Gita.verses(chap_no))
     # |> assign(:verse, Gita.verse(chap_no, verse_no))
     # |> assign_meta()}
  end

  defp get_verse_via_url_params(verse_no, chap_no, src_title) do
    chapter = Written.get_chapter(chap_no, src_title)
    chapter.verses
    |> Enum.find(fn verse -> verse.no == verse_no end)
    |> Vyasa.Repo.preload([:chapter, :source, :translations])
  end

  # defp assign_meta(socket) do
  #   IO.inspect(socket.assigns.verse)
  #   %{:chapter_id => chapter, :verse_number => verse, :text => text} = socket.assigns.verse

  #   assign(socket, :meta, %{
  #     title: "Chapter #{chapter} | Verse #{verse}",
  #     description: text,
  #     type: "website",
  #     image: url(~p"/og/#{get_image_url(socket, chapter, verse)}"),
  #     url: url(socket, ~p"/gita/#{chapter}/#{verse}")
  #   })
  # end

  # defp get_image_url(socket, chapter_num, verse_num) do
  #   filename = OgAdapter.encode_filename(:gita, [chapter_num, verse_num])
  #   target_url = OgAdapter.get_og_file_url(filename)

  #   if File.exists?(target_url) do
  #     target_url
  #   else
  #     text = socket.assigns.verse.text
  #     ImageGenerator.generate_opengraph_image!(filename, text)
  #   end

  #   filename
  # end
end
