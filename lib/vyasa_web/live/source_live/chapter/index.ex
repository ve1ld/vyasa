defmodule VyasaWeb.SourceLive.Chapter.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Written
  alias Vyasa.Medium

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
    |> sync_session()
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

  defp sync_session(%{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # written channel for reading and media channel for writing to media bridge and to player
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)
    socket
  end

  defp sync_session(socket), do: socket

  defp apply_action(socket, :index, %{"source_title" => source_title, "chap_no" => chap_no} = _params) do


    # ==> replace this:
    chap  = %{verses: verses, translations: [ts | _]} = Written.get_chapter(chap_no, source_title, @default_lang)



    socket
    |> stream(:verses, verses)
    |> assign(:source_title, source_title)
    |> assign(:chap, chap)
    |> assign(:selected_transl, ts)
    |> assign_meta()
  end

  @impl true
  @doc """
  Handles the action of clicking to seek by emitting the verse_id to the live player
  via the pubsub system.
  """
  def handle_event("clickVerseToSeek",
                %{"verse_id" => verse_id} = _payload,
                %{assigns: %{session: %{"id" => sess_id}}}  = socket) do
    Vyasa.PubSub.publish(%{verse_id: verse_id}, :playback_sync, "media:session:" <> sess_id)
    {:noreply, socket}
  end

  @doc """
  Upon rcv of :media_handshake, which indicates an intention to sync by the player,
  returns a message containing %Voice{} info that can be used to generate a playback.
  """
  @impl true
  def handle_info({_, :media_handshake, :init},
    %{assigns: %{
         session: %{"id" => sess_id},
         chap: %Written.Chapter{no: c_no, source_id: src_id}
      }} = socket) do

    chosen_voice = Medium.get_voice(src_id, c_no, @default_voice_lang)
    Vyasa.PubSub.publish(
      chosen_voice,
      :voice_ack,
      sess_id
    )

    {:noreply, socket}
  end

  def handle_info(msg, socket) do IO.inspect(msg, label: "unexpected message in @chapter")
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
  Renders a clickable verse display.

  ## Examples
      <.verse_display>
        <:item title="Title" navigate={~p"/myPath"}><%= @post.title %></:item>
      </.verse_display>
  """
  attr :id, :string, required: false
  slot :item, required: true do
    attr :title, :string
    attr :verse_id, :string, required: false
    attr :navigate, :any, required: false
  end
  def verse_display(assigns) do
    ~H"""
    <div class="scroll-m-20 mt-8 p-4 border-b-2 border-brandDark" id={@id}>
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt
            :if={Map.has_key?(item, :title) && Map.has_key?(item, :verse_id)}
            class="w-1/12 flex-none text-zinc-500"
          >
           <button
              phx-click={JS.push("clickVerseToSeek", value: %{verse_id: item.verse_id})}
              class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
            >
              <div class="font-dn text-xl sm:text-2xl mb-4">
                <%= item.title %>
              </div>
           </button>
          </dt>
          <dd class="text-zinc-700">
            <%= render_slot(item) %>
          </dd>
        </div>
      </dl>
    </div>
    """
  end

 end
