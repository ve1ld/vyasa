defmodule VyasaWeb.MediaLive.Player do
  use VyasaWeb, :live_view
  alias Vyasa.Medium
  alias Vyasa.Medium.{Voice, Event, Playback}

  @impl true
  def mount(_params, _sess, socket) do
    socket = socket
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
    %{
      playback: %Playback{
      medium: %Voice{} = _voice = _medium,
      playing?: playing?,
     } = playback} = socket.assigns

    {:noreply,
     cond do
       playing? -> socket |> pause_voice(playback)
       !playing? -> socket |> play_voice(playback)
      end
    }
   end

  @impl true
  def handle_event("seekToMs", %{"position_ms" => position_ms} = _payload, socket) do
    IO.puts("[handleEvent] seekToMs #{position_ms} is_integer? #{is_integer(position_ms)} is string? #{is_binary(position_ms)}")

    %{playback: %Playback{
         medium: %Voice{} = _voice,
         playing?: playing?,
         played_at: played_at,
      } = playback} = socket.assigns


    position_s = round(position_ms / 1000)
    played_at = cond do
      !playing? -> played_at
      playing? -> DateTime.add(DateTime.utc_now, -position_s, :second)
    end

    {:noreply, socket
     |> push_event("seekTo", %{positionS: position_s})
     |> assign(playback: %{playback | played_at: played_at, elapsed: position_s})
    }
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
    } = playback = voice |> Medium.create_playback()
    # } = playback = voice |> MediaLibrary.gen_voice_playback()

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



defp play_voice(socket, %Playback{
      elapsed: elapsed,
      medium: %Voice{} = voice
                } = playback) do
    IO.puts("play_voice triggerred with elapsed = #{elapsed}")
    now = DateTime.utc_now()
    played_at = cond do
      elapsed > 0 -> # resume case
        DateTime.add(now, -elapsed, :second)
      elapsed == 0 -> # fresh start case
        now
      true ->
        now
    end

    playback = %{playback | playing?: true, played_at: played_at}

    socket
    |>push_event("play", %{
        artist: "testArtist",
        # artist: hd(voice.prop.artists),
        title: voice.title,
        isPlaying: playback.playing?,
        elapsed: playback.elapsed,
        filePath: voice.file_path,
        duration: voice.duration,
      })
    |> assign(playback: playback)
end

defp pause_voice(socket, %Playback{
      medium: %Voice{} = _voice,
      } = playback) do

    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, playback.played_at, :second)
    playback = %{playback | playing?: false, paused_at: now, elapsed: elapsed}

    IO.puts("pause_voice triggerred with elapsed = #{elapsed}")

    socket
    |> push_event("pause", %{
          elapsed: elapsed,
      })
    |> assign(playback: playback)
end

  defp js_play_pause() do
    JS.push("play_pause") # server event
    |> JS.dispatch("js:play_pause", to: "#audio-player") # client-side event, dispatches to DOM
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
      phx-hook="ProgressBar"
      data-value={@value}
      data-max={@max}
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
