defmodule VyasaWeb.SourceLive.Chapter.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Written
  alias Vyasa.Written.{Chapter}

  @default_lang "en"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, %{
      "source_title" => source_title,
      "chap_no" => chap_no,
    } = _params) do


    %Chapter{
      verses: verses,
      title: title,
      body: body,
      translations: translations,
    } = Written.get_chapter(chap_no, source_title)

    selected_transl = translations |> Enum.find(fn t -> t.lang == @default_lang end)

    socket
    |> stream(:verses, verses)
    |> assign(:source_title, source_title)
    |> assign(:chap_no, chap_no)
    |> assign(:chap_body, body)
    |> assign(:chap_title, title)
    |> assign(:selected_transl, selected_transl)
    |> assign(:page_title, "#{source_title} Chapter #{chap_no} | #{title}")
    |> assign(:text, nil)
    |> assign(:song, nil)
    |> assign_meta()
  end

  defp assign_meta(socket) do
    assign(socket, :meta, %{
      title: "#{socket.assigns.source_title} Chapter #{socket.assigns.chap_no} | #{socket.assigns.chap_title}",
      description: socket.assigns.chap_body,
      type: "website",
      url: url(socket, ~p"/explore/#{socket.assigns.source_title}/#{socket.assigns.chap_no}"),
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
              <div class="font-dn text-2xl mb-4">
                <%= item.title %>
              </div>
            </.link>
          </dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

end
