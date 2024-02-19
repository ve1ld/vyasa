defmodule VyasaWeb.MediaLive.Player do
  use VyasaWeb, :live_view
  alias Vyasa.MediaLibrary.{Playback}
  alias Vyasa.MediaLibrary
  alias Vyasa.Medium.{Voice, Event}

  @impl true
  def mount(_params, _sess, socket) do
    socket = socket
    |> assign(voice: nil)
    |> assign(playback: nil)
    |> sync_session()

    {:ok, socket, layout: false}
  end

  defp sync_session(%{assigns: %{session: %{"id" => id} = sess}} = socket) when is_binary(id) do
    Vyasa.PubSub.subscribe("media:session:" <> id)
    Vyasa.PubSub.publish(:init, :media_handshake, "written:session:" <> id)

    socket
    |> push_event("initSession", sess |> Map.take(["id"]))
  end

  defp sync_session(socket) do
    socket
  end

  @impl true
  def handle_event("play_pause", _, socket) do
    %{voice: voice, playback: playback} = socket.assigns

    cond do
     playback.playing? ->
        playback = pause_playback(playback)
        {:noreply, pause_voice(socket, voice, playback)}
     !playback.playing? ->
        playback = play_playback(playback)
        {:noreply, play_voice(socket, voice, playback)}
     true ->
        {:noreply, socket}
    end
  end

  defp pause_playback(%Playback{} = playback) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, playback.played_at, :second)

    %{playback | playing?: false, paused_at: now, elapsed: elapsed}
  end



  defp play_playback(%Playback{elapsed: elapsed} = playback) do
    now = DateTime.utc_now()
    played_at = cond do
      elapsed > 0 -> # resume case
        DateTime.add(now, -elapsed, :second)
      elapsed == 0 -> # fresh start case
        now
      true ->
        now
    end

    %{playback | playing?: true, played_at: played_at}
  end

  @impl true
  @doc"""
  On receiving a voice_ack, the written and player contexts are now synced.
  A playback struct is created that represents this synced-state and the client-side hook is triggerred
  to register the associated events timeline.
  """
  def handle_info({_, :voice_ack, voice}, socket) do
    %Playback{
      medium: %Voice{events: events},
    } = playback = voice |> MediaLibrary.gen_voice_playback()

    socket = socket
    |> assign(playback: playback)
    # Registers Events Timeline on Client-Side:
    |> push_event("registerEventsTimeline", %{voice_events: events |> create_events_payload()})

    {:noreply, socket}
  end

  def handle_info({_, :written_handshake, :init}, %{assigns: %{session: %{"id" => id}}} = socket) do
    Vyasa.PubSub.publish(:init, :media_handshake, "written:session:" <> id)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message in @player_live")
    {:noreply, socket}
  end


defp create_events_payload([%Event{} | _] = events) do
  events|> Enum.map(&(&1 |> Map.take([:origin, :duration, :phase, :fragments, :verse_id])))
end



defp play_voice(socket, voice, %Playback{
      elapsed: elapsed,
                } = playback) do
    IO.puts("play_voice triggerred with elapsed = #{elapsed}")

    socket
    |> push_play(voice, playback)
end

defp pause_voice(socket, voice, %Playback{
      elapsed: elapsed
                 } = playback) do
  IO.puts("pause_voice triggerred with elapsed = #{elapsed}")
  # IO.inspect(voice)

  # paused_at = DateTime.truncate(DateTime.utc_now(), :second)
  paused_at = DateTime.utc_now()

  playback = %{playback | paused_at: paused_at}

  socket
  |> push_pause(voice, playback)

end

defp push_play(socket, %Voice{} = voice, %Playback{
    elapsed: elapsed,
    playing?: playing?,
    } = playback) do

    socket
    |>push_event("play", %{
            artist: "testArtist",
            # artist: hd(voice.prop.artists),
            title: voice.title,
            paused: playing?,
            elapsed: elapsed,
            filePath: voice.file_path,
            duration: voice.duration,
      })
    |> assign(voice: voice, playback: playback)
  end

  defp push_pause(socket, %Voice{} = voice, %Playback{
    elapsed: elapsed,
  } = playback) do
    socket
    |> push_event("pause", %{
          elapsed: elapsed,
                  })

    |> assign(voice: voice, playback: playback)
  end

  defp js_play_pause() do
    JS.push("play_pause") # server event
    |> JS.dispatch("js:play_pause", to: "#audio-player") # client-side event
  end


  defp js_prev() do
  end

  defp js_next() do
  end


  attr :id, :string, required: true
  attr :min, :integer, default: 0
  attr :max, :integer, default: 100
  attr :value, :integer

  def progress_bar(assigns) do
    assigns = assign_new(assigns, :value, fn -> assigns[:min] || 0 end)

    ~H"""
    <div
      id={"#{@id}-container"}
      class="bg-gray-200 flex-auto dark:bg-black rounded-full overflow-hidden"
      phx-update="ignore"
    >
      <div
        id={@id}
        class="bg-lime-500 dark:bg-lime-400 h-1.5 w-0"
        data-min={@min}
        data-max={@max}
        data-val={@value}
      >
      </div>
    </div>
    """
         end

 end
