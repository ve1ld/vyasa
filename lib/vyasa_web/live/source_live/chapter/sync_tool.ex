defmodule VyasaWeb.SourceLive.Chapter.SyncTool do
  use VyasaWeb, :live_view
  alias Vyasa.Written
  alias Vyasa.Written.{Chapter}

  @default_lang "en"
  @default_verse_offset_in_window 0

  @impl true
  def mount(_params, _session, socket) do
    socket = socket
    |> assign(:focused_verse_no, @default_verse_offset_in_window)

    {:ok, socket}
  end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end


  @stub_time_map %{
    start_time: 0,
    offset: 1000,
    duration: 2000,
    state: "unset"
  }
  defp apply_action(socket, :sync, %{
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

    verses_with_timemap_data = verses
    |> Enum.map(fn v -> Map.put(v, :caption_info, @stub_time_map) end)

    focused_verse = verses_with_timemap_data
    |> Enum.filter(fn v -> !is_nil(v.global_order) end) # weird issue with my seeded verses for chap 5 verse 1
    |> Enum.find(fn v -> v.global_order == (hd(verses_with_timemap_data).global_order + socket.assigns.focused_verse_no) end) |> dbg()

    socket
    |> stream(:verses, verses_with_timemap_data)
    |> assign(:focused_verse, focused_verse)
    |> assign(:source_title, source_title)
    |> assign(:chap_no, chap_no)
    |> assign(:chap_body, body)
    |> assign(:chap_title, title)
    |> assign(:selected_transl, selected_transl)
    |> assign(:page_title, "#{source_title} Chapter #{chap_no} | #{title}")
    |> assign(:text, nil)
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

  slot :item, required: true do
    attr :title, :string
    attr :navigate, :any, required: false
  end

  slot :time_map, required: true do
    attr :caption_info, :map
  end

  def leaf(assigns) do
    ~H"""
      <div class="flex w-full items-center">
        <div class="w-5/10">
          <dl class="my-2  border-t-2 border-zinc-500 divide-y divide-zinc-100">
            <div :for={item <- @item} class="flex gap-1 py-4 text-sm leading-6 sm:gap-1">
              <!-- text display -->
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
        <.time_marker :for={caption <- @time_map} caption_info={caption.caption_info}/>
    </div>
    """
  end

  @doc"""
  Represents a node within a timeline (whereby a timeline is a flattened tree of depth 1).
  NOTE: mental model is that of a tree-leaf
  """
  def focused_leaf(assigns) do
    ~H"""
      <div class="flex w-full items-center">
        <div class="w-5/10">
          <dl class="my-2  border-t-2 border-zinc-500 divide-y divide-zinc-100">
            <div :for={item <- @item} class="flex gap-1 py-4 text-sm leading-6 sm:gap-1">
              <!-- text display -->
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
        <.time_marker :for={caption <- @time_map} caption_info={caption.caption_info}/>
    </div>
    """
  end

  def time_marker(assigns) do
    ~H"""
    <div class="border-2 border-red-500 w-3/10">
        <%= inspect @caption_info %>
    </div>
    """
  end

end
