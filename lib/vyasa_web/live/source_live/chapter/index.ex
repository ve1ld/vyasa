defmodule VyasaWeb.SourceLive.Chapter.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Written

  @default_lang "en"
  @default_voice_lang "sa"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
     |> stream_configure(:verses, dom_id: &("verse-#{&1.id}"))}
  end


  @impl true
  def handle_params(params, _url, socket) do
    IO.puts("chapter/index handle params")

    {:noreply, socket
    |> bind_session()
    |> apply_action(socket.assigns.live_action, params)

    #|> register_client_state()
    }
  end

  # defp register_client_state(%{assigns: %{voice_events: voice_events}} = socket) do
  #   desired_keys = [:origin, :duration, :phase, :fragments, :verse_id]
  #   events = Enum.map(voice_events, fn e -> Map.take(Map.from_struct(e), desired_keys) end)

  #   socket
  #   |> push_event("registerEventsTimeline",
  #   %{voice_events:  events})
  # end

  defp bind_session(%{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # written channel for reading and media channel for writing to media bridge and to player
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    socket
  end

  defp bind_session(socket), do: socket

  defp apply_action(socket, :index, %{"source_title" => source_title, "chap_no" => chap_no} = _params) do
    chap  = %{verses: verses, translations: [ts | _]} = Written.get_chapter(chap_no, source_title, @default_lang)

    socket
    |> stream(:verses, verses)
    |> assign(:source_title, source_title)
    |> assign(:chap, chap)
    |> assign(:selected_transl, ts)
    |> assign(:playback, nil)
    |> assign_meta()
  end

  @impl true
  def handle_info({_, :media_handshake, :init}, %{assigns: %{session: %{"id" => sess_id}, chap: %Written.Chapter{no: c_no, source_id: src_id}}} = socket) do
    Vyasa.PubSub.publish(%Vyasa.Medium.Voice{
          source_id: src_id,
          chapter_no: c_no,
          lang: @default_voice_lang},
      :voice_ack, sess_id)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message in @chapter")
    {:noreply, socket}
  end

  defp assign_meta(socket) do
    socket
    |> assign(:page_title, "#{socket.assigns.source_title} Chapter #{socket.assigns.chap.no} | #{socket.assigns.chap.title}")
    |> assign(:meta, %{
          title: "#{socket.assigns.source_title} Chapter #{socket.assigns.chap.no} | #{socket.assigns.chap.title}",
          description: socket.assigns.chap.body,
          type: "website",
          url: url(socket, ~p"/explore/#{socket.assigns.source_title}/#{socket.assigns.chap.no}"),
              })
  end

  @doc """
  Renders a clickable verse list.

  ## Examples
      <.verse_list>
        <:item title="Title" navigate={~p"/myPath"}><%= @post.title %></:item>
      </.list>
  """
  attr :id, :string, required: false
  slot :item, required: true do
    attr :title, :string
    attr :navigate, :any, required: false
  end
  def verse_list(assigns) do
    ~H"""
    <div class="mt-14" id={@id}>
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
