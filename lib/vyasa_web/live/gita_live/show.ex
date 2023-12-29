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
      :name_meaning => meaning
    } = socket.assigns.chapter

    assign(socket, :meta, %{
      title: "Chapter #{chapter} | #{chapter_name} -- #{meaning}",
      description: summary,
      type: "website",
      url: url(socket, ~p"/gita/#{chapter}")
    })
  end

  @doc """
  Renders a clickable verse list.

  ## Examples
      <.verse_list>
        <:item title="Title" navigate={~p"/myPath"}><%= @post.title %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string
    attr :navigate, :any, required: false
  end

  def verse_list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt
            :if={Map.has_key?(item, :title) && Map.has_key?(item, :navigate)}
            class="w-1/6 flex-none text-zinc-500"
          >
            <.link
              navigate={item[:navigate]}
              class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
            >
              <%= item.title %>
            </.link>
          </dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end
end
