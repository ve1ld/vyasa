defmodule VyasaWeb.MediaLive.MediaBridge do
  @moduledoc """
  Media Bridge intends to decouple the media players (audio/video...) from the context of what is being played.

  It will have the following responsibilities:
  1. stores a general playback state. This shall be agnostic to the players that rely on this playback state for synchronising their own playback states.
  2. It shall contain the common playback buttons because these buttons will be controlling all the supported players simultaneously. In so doing, playback state and actions are kept only in the media_bridge
  3. TODO: handle the sync between A/V players
  """
  use VyasaWeb, :live_view
  alias Vyasa.Medium
  alias Vyasa.Medium.{Voice, Event, Playback}

  @impl true
  def mount(_params, _sess, socket) do
    socket = socket
    |> assign(playback: nil)
    |> assign(voice: nil)
    |> assign(video: nil)
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

  # TODO: handle vid next
  defp play_media(socket, %Playback{elapsed: elapsed} = playback) do
    IO.puts("play_media triggerred with elapsed = #{elapsed}")
    socket
    |> assign(playback: update_playback_on_play(playback))
    |> play_audio()
  end

  # fallback
  defp play_media(socket, _playback) do
    socket
  end

  defp update_playback_on_play(%Playback{elapsed: elapsed} = playback) do
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

  defp pause_media(socket, %Playback{} = playback)  do
    socket
    |> assign(playback: update_playback_on_pause(playback))
    |> pause_audio()
  end

  defp update_playback_on_pause( %Playback{
        played_at: played_at
    } = playback) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, played_at, :second)
    %{playback | playing?: false, paused_at: now, elapsed: elapsed}
  end

  @impl true
  def handle_event("play_pause", _, socket) do
    %{
      playback: %Playback {
        playing?: playing?,
     } = playback,
    } = socket.assigns

    {:noreply,
     cond do
       playing? -> socket |> pause_media(playback)
       !playing? -> socket |> play_media(playback)
      end
    }
   end

  @impl true
  def handle_event("seekToMs", %{"position_ms" => position_ms} = _payload, socket) do
    IO.puts("[handleEvent] seekToMs #{position_ms}")
    socket
    |> handle_seek(position_ms)
    end

  defp handle_seek(socket, position_ms) do
    %{playback: %Playback{
         playing?: playing?,
         played_at: played_at,
      } = playback,
    } = socket.assigns


    position_s = round(position_ms / 1000)
    played_at = cond do
      !playing? -> played_at
      playing? -> DateTime.add(DateTime.utc_now, -position_s, :second)
    end

    {:noreply, socket
     |> push_event("seekTo", %{positionS: position_s}) # dispatches to player -- QQ: will mutliple players be able to receive this simultaneously?
     |> assign(playback: %{playback | played_at: played_at, elapsed: position_s}) #modifies the socket after emitting client-side event
    }
  end

  @impl true
  @doc """
  On receiving a voice_ack, the written and player contexts are now synced.
  A playback struct is created that represents this synced-state and the client-side hook is triggerred
  to register the associated events timeline.
  """
  def handle_info({_, :voice_ack, %Voice{video: video} = voice}, socket) do
     %Voice{
       events: voice_events,
     } = loaded_voice = voice |> Medium.load_events()

     {
      :noreply,
      socket
      |> assign(voice: loaded_voice)
      |> assign(video: video)
      |> assign(playback: Playback.init_playback())
      |> push_event("registerEventsTimeline", %{voice_events: voice_events |> create_events_payload()})
     }
  end

  def handle_info({_, :written_handshake, :init}, %{assigns: %{session: %{"id" => id}}} = socket) do
    Vyasa.PubSub.publish(:init, :media_handshake, "written:session:" <> id)
    {:noreply, socket}
  end

  # Handles playback sync relative to a particular verse id. In this case, the playback state is expected
  # to get updated to the start of the event corresponding to that particular verse.
  @impl true
  def handle_info({_, :playback_sync, %{verse_id: verse_id} = _inner_msg} = _msg, socket) do
    %{voice: %{ events: events } = _voice} = socket.assigns

    %Event{
      origin: target_ms
    } = _target_event = events
    |> get_target_event(verse_id)


    socket
    |> handle_seek(target_ms)
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message received by media bridge")
    {:noreply, socket}
  end


defp create_events_payload([%Event{} | _] = events) do
  events|> Enum.map(&(&1 |> Map.take([:origin, :duration, :phase, :fragments, :verse_id])))
end

defp get_target_event([%Event{} | _] = events, verse_id) do
  events
  |> Enum.find(fn e -> e.verse_id === verse_id  end)
end

defp play_audio(%{
      assigns: %{
        voice: %Voice{
          title: title,
          file_path: file_path,
          duration: duration,
        } = _voice,
        playback: %Playback{
            elapsed: elapsed,
            playing?: playing?,
        } = _playback
      } = _assigns,
   } = socket) do

  player_details = %{
      artist: "testArtist",
      title: title,
      isPlaying: playing?,
      elapsed: elapsed,
      filePath: file_path,
      duration: duration,
  }

  send_update(
    self(),
    VyasaWeb.AudioPlayer,
    id: "audio-player",
    player_details: player_details,
    event: "play_audio"
  )

  socket
end

defp pause_audio(%{assigns: %{playback: %Playback{
                                 elapsed: elapsed
                              }= _playback} = _assigns} = socket) do

    send_update(self(), VyasaWeb.AudioPlayer,
      id: "audio-player",
      event: "pause_audio",
      elapsed: elapsed
    )

    socket
end

  defp js_play_pause() do
    JS.push("play_pause") # server event
    |> JS.dispatch("js:play_pause", to: "#audio-player") # client-side event, dispatches to DOM TODO: shift to the new audio player hook instead
  end


  # TODO: add this when implementing tracks & playlists
  defp js_prev() do
  end

  # TODO: add this when implementing tracks & playlists
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

  attr :playback, Playback, required: false
  def play_pause_button(assigns) do
   ~H"""
    <button
      type="button"
      class="mx-auto scale-75"
      phx-click={js_play_pause()}
      phx-target="#media-player"
      aria-label={
        if @playback && @playback.playing? do
          "Pause"
        else
          "Play"
        end
      }
    >
      <%= if @playback && @playback.playing? do %>
      <!-- play/pause -->
        <svg id="player-pause" width="50" height="50" fill="none">
          <circle
            class="text-gray-300 dark:text-gray-500"
            cx="25"
            cy="25"
            r="24"
            stroke="currentColor"
            stroke-width="1.5"
          />
          <path d="M18 16h4v18h-4V16zM28 16h4v18h-4z" fill="currentColor" />
        </svg>
      <% else %>
        <svg
          id="player-play"
          width="50"
          height="50"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <circle
            id="svg_1"
            stroke-width="0.8"
            stroke="currentColor"
            r="11.4"
            cy="12"
            cx="12"
            class="text-gray-300 dark:text-gray-500"
          />
          <path
            stroke="null"
            fill="currentColor"
            transform="rotate(90 12.8947 12.3097)"
            id="svg_6"
            d="m9.40275,15.10014l3.49194,-5.58088l3.49197,5.58088l-6.98391,0z"
            stroke-width="1.5"
            fill="none"
          />
        </svg>
      <% end %>
    </button>
   """
  end

   def next_button(assigns) do
   ~H"""
    <button
        type="button"
        class="mx-auto scale-75"
        phx-click={js_next()}
        aria-label="Next"
      >
        <svg width="17" height="18" viewBox="0 0 17 18" fill="none">
          <path d="M17 0H15V18H17V0Z" fill="currentColor" />
          <path d="M13 9L0 0V18L13 9Z" fill="currentColor" />
        </svg>
      </button>
    """
   end

  def prev_button(assigns) do
    ~H"""
      <button
        type="button"
        class="sm:block xl:block mx-auto scale-75"
        phx-click={js_prev()}
        aria-label="Previous"
      >
        <svg width="17" height="18">
          <path d="M0 0h2v18H0V0zM4 9l13-9v18L4 9z" fill="currentColor" />
        </svg>
      </button>
    """
  end

  def video_player(assigns) do
    ~H"""
    <div>
      <%= inspect @video%>
      <.button id="button-YouTubePlayer">
          Toggle Player
      </.button>
      <div
        class="container-YouTubePlayer container-YouTubePlayerHidden"
        phx-hook={"MiniPlayer"}
        id={"container-YouTubePlayer"}>
        <.live_component
          module={VyasaWeb.YouTubePlayer}
          id={"YouTubePlayer"}
          video_id={@video.ext_uri}
        />
      </div>

    </div>
    """

  end

 end
