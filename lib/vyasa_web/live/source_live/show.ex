defmodule VyasaWeb.SourceLive.Show do
  use VyasaWeb, :live_view
  alias Vyasa.Written
  alias Vyasa.Written.{Source}

  @impl true
  def mount(_params, _session, socket) do
    socket = stream_configure(socket, :chapters, dom_id: &("Chapter-#{&1.no}"))
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"source_title" => source_title}, _, socket) do
    %Source{
      id: id,
      verses: verses,
      chapters: chapters,
      title: title
    } = Written.get_source_by_title(source_title)

    {
      :noreply,
      socket
      |> assign(:id, id)
      |> assign(:title, title)
      |> assign(:page_title, title)
      |> stream(:verses, verses)
      |> stream(:chapters, chapters)
      |> assign_meta()
    }

  end

  defp assign_meta(socket) do
    assign(socket, :meta, %{
      title: socket.assigns.title,
      description: "Explore the #{socket.assigns.title}",
      type: "website",
      url: url(socket, ~p"/explore/#{socket.assigns.title}")
    })
  end

  @doc """
  Renders a clickable verse list.

  ## Examples
      <.chapter_list>
        <:item title="Title" navigate={~p"/explore/:id/:chapter_id"}> [<%= @chapter.no =>]<%= @chapter.title %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string
    attr :navigate, :any, required: false
  end

  def chapter_list(assigns) do
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
