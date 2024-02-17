defmodule VyasaWeb.SourceLive.Chapter.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Written
  alias Vyasa.Written.{Chapter}
  alias Vyasa.Medium.{Voice}

  @pubsub Vyasa.PubSub
  @default_lang "en"
  @default_voice_lang "sa"

  @impl true
  def mount(_params, _session, socket) do
    # Process.sleep(2000)
    socket = stream_configure(socket, :verses, dom_id: &("verse-#{&1.id}"))

    if connected?(socket) do
      subscribe_now_playing()
    end

    {:ok, socket}
  end


  @impl true
  def handle_params(params, _url, socket) do
    IO.puts("chapter/index handle params")

    {:noreply, socket
    |> apply_action(socket.assigns.live_action, params)
    |> register_client_state()}
  end

  defp register_client_state(%{assigns: assigns} = socket) do
    %{voice_events: voice_events} = assigns

    desired_keys = [:origin, :duration, :phase, :fragments, :verse_id]

    events = Enum.map(voice_events, fn e -> Map.take(Map.from_struct(e), desired_keys) end)
    _encoded_events = Jason.encode!(events)


    socket
    |> push_event("registerEventsTimeline", %{
          voice_events:  events
                  })

  end

  defp apply_action(socket, :index, %{
      "source_title" => source_title,
      "chap_no" => chap_no,
    } = _params) do

    %Chapter{} = chap = Written.get_chapter(chap_no, source_title)
    selected_transl = chap.translations |> Enum.find(fn t -> t.lang == @default_lang end)
    selected_voice = chap.voices |> Enum.find(fn v -> v.lang == @default_voice_lang  end)
    # TODO: shift closer to query, add a hydration helper so that the virtual fields get hydrated there itself.
    selected_voice = %Voice{selected_voice | file_path: "http://localhost:9000/vyasa/voices/d040c39a-a25d-45b2-b73d-a7d3db70cbee.mp3?ContentType=application%2Foctet-stream&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secrettunnel%2F20240217%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Date=20240217T033529Z&X-Amz-Expires=88888&X-Amz-SignedHeaders=host&X-Amz-Signature=d5aed6e6c22a7f29409663901033d1e15c83572f48358c6d84f78609e089ac8e"}
    broadcast_now_playing({:set_voice, selected_voice})

    # broadcast_task = Task.async(fn -> broadcast_now_playing({:set_voice, selected_voice}) end)
    # Task.await(broadcast_task, 15000)
    # broadcast_now_playing({:set_voice, selected_voice})
    voice_events = selected_voice.events

    socket
    |> stream(:verses, chap.verses)
    |> assign(:source_title, source_title)
    |> assign(:chap, chap)
    |> assign(:selected_transl, selected_transl)
    |> assign(:selected_voice, selected_voice)
    |> assign(:voice_events, voice_events)
    |> assign(:playback, nil)
    |> assign_meta()
  end

  # @impl true
  # def handle_event("update_playback_progress", %{"currentTimeVal" => current_time_val}, socket) do
  #   IO.puts("[handle_event::update_playback_progress] from within chapter/index.ex")
  #   IO.puts(current_time_val)


  #   {:noreply, socket
  #   |> assign(:playback, current_time_val)}
  # end



  @impl true
  def handle_info({:set_voice, _} , socket) do
    IO.puts(">> [handle_info] set voice by index.ex")

    # voice = %Voice{voice | file_path: "http://localhost:9000/vyasa/voices/d040c39a-a25d-45b2-b73d-a7d3db70cbee.mp3?ContentType=application%2Foctet-stream&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secrettunnel%2F20240217%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Date=20240217T033529Z&X-Amz-Expires=88888&X-Amz-SignedHeaders=host&X-Amz-Signature=d5aed6e6c22a7f29409663901033d1e15c83572f48358c6d84f78609e089ac8e"}
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

  defp subscribe_now_playing do
    Phoenix.PubSub.subscribe(@pubsub, "nowplaying")
  end

  defp broadcast_now_playing(msg) do
    IO.puts("Broadcasting now playing...")
    dbg(msg, limit: :infinity)
    # Phoenix.PubSub.broadcast_from(@pubsub, self(), "nowplaying", msg)
    Phoenix.PubSub.broadcast(@pubsub, "nowplaying", msg)
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
