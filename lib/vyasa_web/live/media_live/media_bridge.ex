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
  alias Vyasa.Medium.{Voice, Event, Playback, Meta}

  @default_player_config %{
    height: "300",
    width: "400",
    # see supported params here: https://developers.google.com/youtube/player_parameters#Parameters
    playerVars: %{
      autoplay: 1,
      mute: 1,
      start: 0,
      controls: 0,
      enablejsapi: 1,
      # hide video annotations
      iv_load_policy: 3,
      # ensures it doesn't full-screen on ios
      playsinline: 1
    }
  }

  @impl true
  def mount(_params, _sess, socket) do
    encoded_config = Jason.encode!(@default_player_config)

    socket =
      socket
      |> assign(playback: nil)
      |> assign(voice: nil)
      |> assign(video: nil)
      |> assign(video_player_config: encoded_config)
      |> assign(should_show_vid: false)
      |> assign(is_follow_mode: true)
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

  defp play_media(socket, %Playback{elapsed: elapsed} = playback) do
    IO.puts("play_media triggerred with elapsed = #{elapsed} ms")

    socket
    |> assign(playback: update_playback_on_play(playback))
    |> update_audio_player()
  end

  # fallback
  defp play_media(socket, _playback) do
    socket
  end

  defp update_playback_on_play(%Playback{elapsed: elapsed} = playback) do
    now = DateTime.utc_now()

    played_at =
      cond do
        # resume case
        elapsed > 0 ->
          DateTime.add(now, -round(elapsed), :millisecond)

        # fresh start case
        elapsed == 0 ->
          now

        true ->
          now
      end

    %{playback | playing?: true, played_at: played_at}
  end

  defp pause_media(socket, %Playback{} = playback) do
    socket
    |> assign(playback: update_playback_on_pause(playback))
    |> update_audio_player()
  end

  defp update_playback_on_pause(
         %Playback{
           played_at: played_at
         } = playback
       ) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, played_at, :millisecond)
    %{playback | playing?: false, paused_at: now, elapsed: elapsed}
  end

  # internal action: updates the playback state on seek
  defp update_playback_on_seek(socket, position_ms) do
    %{
      playback:
        %Playback{
          playing?: playing?,
          played_at: played_at
        } = playback
    } = socket.assigns

    # <=== sigil U
    now = DateTime.utc_now()

    played_at =
      cond do
        !playing? -> played_at
        playing? -> DateTime.add(now, -round(position_ms), :millisecond)
      end

    socket
    |> assign(playback: %{playback | played_at: played_at, elapsed: position_ms})
  end

  @impl true
  def handle_event(
        "toggle_should_show_vid",
        _,
        %{assigns: %{should_show_vid: flag} = _assigns} = socket
      ) do
    {:noreply, socket |> assign(should_show_vid: !flag)}
  end

  @impl true
  def handle_event(
        "toggle_is_follow_mode",
        _,
        %{assigns: %{is_follow_mode: flag} = _assigns} = socket
      ) do
    {
      :noreply,
      socket
      |> assign(is_follow_mode: !flag)
      |> push_event("toggleFollowMode", %{})
    }
  end

  @impl true
  def handle_event("play_pause", _, socket) do
    %{
      playback:
        %Playback{
          playing?: playing?
        } = playback
    } = socket.assigns

    {:noreply,
     cond do
       playing? -> socket |> pause_media(playback)
       !playing? -> socket |> play_media(playback)
     end}
  end

  @doc """
  Handles seekTime event originated from the ProgressBar
  """
  @impl true
  def handle_event(
        "seekTime",
        %{"seekToMs" => position_ms, "originator" => "ProgressBar" = originator} = _payload,
        socket
      ) do
    IO.puts("[handleEvent] seekToMs #{position_ms} ORIGINATOR = #{originator}")

    socket
    |> handle_seek(position_ms, originator)
  end

  # Fallback for seekTime, if no originator is present, shall be to treat MediaBridge as the originator
  # and call handle_seek.
  @impl true
  def handle_event("seekTime", %{"seekToMs" => position_ms} = _payload, socket) do
    IO.puts("[handleEvent] seekToMs #{position_ms}")

    socket
    |> handle_seek(position_ms, "MediaBridge")
  end

  # when originator is the ProgressBar, then shall only consume and carry out internal actions only
  # i.e. updating of the playback state kept in MediaBridge liveview.
  defp handle_seek(socket, position_ms, "ProgressBar" = _originator) do
    {
      :noreply,
      socket
      |> update_playback_on_seek(position_ms)
    }
  end

  # when the seek is originated by the MediaBridge, then it shall carry out both internal & external actions
  # internal: updating of the playback state kept in the MediaBridge liveview
  # external: pubbing via the seekTime targetEvent
  defp handle_seek(socket, position_ms, "MediaBridge" = originator) do
    seek_time_payload = %{
      seekToMs: position_ms,
      originator: originator
    }

    IO.inspect("handle_seek originator: #{originator}, playback position ms: #{position_ms}",
      label: "checkpoint"
    )

    {
      :noreply,
      socket
      |> push_event("media_bridge:seekTime", seek_time_payload)
      |> update_playback_on_seek(position_ms)
    }
  end

  @impl true
  @doc """
  On receiving a voice_ack, the written and player contexts are now synced.
  A playback struct is created that represents this synced-state and the client-side hook is triggerred
  to register the associated events timeline.
  """
  def handle_info(
        {_, :voice_ack,
         %Voice{
           video: video
         } = voice},
        socket
      ) do
    %Voice{
      events: voice_events,
      title: title,
      file_path: file_path,
      duration: duration,
      meta:
        %{
          artists: artists,
          album: album,
          artwork: artwork
        } = meta
    } = loaded_voice = voice |> Medium.load_events()

    generated_artwork = %{
      src:
        url(~p"/og/#{VyasaWeb.OgImageController.get_by_binding(%{source: loaded_voice.source})}"),
      type: "image/png",
      sizes: "480x360"
    }

    # generated_artwork = %{
    #   src:
    #    "https://i.ytimg.com/vi/AETFvQonfV8/hqdefault.jpg",
    #   type: "image/jpeg",
    #   sizes: "480x360"
    # }

    updated_artwork =
      cond do
        artwork && is_list(artwork) -> [generated_artwork | artwork]
        true -> [generated_artwork]
      end

    playback_meta = %Meta{
      title: title,
      artists: artists,
      album: album,
      artwork: updated_artwork,
      duration: duration,
      file_path: file_path
    }

    IO.inspect(meta, label: "Checkpoint: voice meta:")
    IO.inspect(playback_meta, label: "Checkpoint: playback meta:")

    {
      :noreply,
      socket
      |> assign(voice: loaded_voice)
      |> assign(video: video)
      |> assign(playback: Playback.init_playback(playback_meta))
      |> push_event("media_bridge:registerEventsTimeline", %{
        voice_events: voice_events |> create_events_payload()
      })
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
    %{voice: %{events: events} = _voice} = socket.assigns

    IO.inspect("handle_info::playback_sync", label: "checkpoint")

    %Event{
      origin: target_ms
    } =
      _target_event =
      events
      |> get_target_event(verse_id)

    socket
    |> handle_seek(target_ms, "MediaBridge")
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message received by media bridge")
    {:noreply, socket}
  end

  defp create_events_payload([%Event{} | _] = events) do
    events |> Enum.map(&(&1 |> Map.take([:origin, :duration, :phase, :fragments, :verse_id])))
  end

  defp get_target_event([%Event{} | _] = events, verse_id) do
    events
    |> Enum.find(fn e -> e.verse_id === verse_id end)
  end

  defp update_audio_player(
         %{
           assigns:
             %{
               playback:
                 %Playback{
                   playing?: playing?
                 } = playback
             } = _assigns
         } = socket
       ) do
    send_update(
      self(),
      VyasaWeb.AudioPlayer,
      id: "audio-player",
      playback: playback,
      event: "media_bridge:update_audio_player"
    )

    cmd =
      cond do
        playing? ->
          "play"

        !playing? ->
          "pause"
      end

    seek_time_payload = %{
      seekToMs: playback.elapsed,
      originator: "MediaBridge"
    }

    socket
    |> push_event("media_bridge:play_pause", %{
      cmd: cmd,
      originator: "MediaBridge",
      playback: playback
    })
    |> push_event("media_bridge:seekTime", seek_time_payload)
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
  # elapsed time (in milliseconds)
  attr :value, :integer

  def progress_bar(assigns) do
    assigns = assign_new(assigns, :value, fn -> assigns[:min] || 0 end)
    IO.inspect(assigns, label: "progress hopefully we make some progress")

    ~H"""
    <div
      id={"#{@id}-container"}
      class="bg-gray-200 flex-auto dark:bg-black rounded-full overflow-hidden justify-self-stretch"
      phx-update="ignore"
      phx-hook="ProgressBar"
      data-value={@value}
      data-max={@max}
    >
      <div
        id={@id}
        class="bg-brand dark:bg-brandAccentLight h-1.5 w-0"
        data-min={@min}
        data-max={@max}
        data-val={@value}
      >
      </div>
    </div>
    """
  end

  attr :playback, Playback, required: false
  attr :isReady, :boolean, required: false, default: false
  attr :isPlaying, :boolean, required: true

  def play_pause_button(assigns) do
    ~H"""
    <button
      type="button"
      class="mx-auto scale-75"
      phx-click={JS.push("play_pause")}
      phx-target="#media-player"
      aria-label={
        cond do
          not @isReady ->
            "Not ready to play"

          @isPlaying ->
            "Pause"

          true ->
            "Play"
        end
      }
    >
      <%= if not @isReady do %>
        <.spinner />
      <% else %>
        <%= if @isPlaying  do %>
          <svg id="player-pause" width="50" height="50" fill="none">
            <circle
              class="text-gray-300 dark:text-brandAccentLight"
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
              class="text-gray-300 dark:text-brandAccentLight"
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
      <% end %>
    </button>
    """
  end

  def next_button(assigns) do
    ~H"""
    <button type="button" class="mx-auto scale-75" phx-click={js_next()} aria-label="Next">
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

  # def volume_control(assigns) do
  #   ~H"""

  #   """

  # end

  def video_player(assigns) do
    ~H"""
    <div>
      <div
        class={
          if @should_show_vid, do: "container-YouTubePlayer", else: "container-YouTubePlayerHidden"
        }
        id="container-YouTubePlayer"
        heartbeat={@heartbeat}
        phx-hook="Floater"
        data-floater-id="container-YouTubePlayer"
        data-floater-reference-selector=".emphasized-verse"
        data-floater-fallback-reference-selector="#media-player-container"
      >
        <.live_component
          module={VyasaWeb.YouTubePlayer}
          id="YouTubePlayer"
          video_id={@video.ext_uri}
          player_config={@player_config}
        />
      </div>
    </div>
    """
  end

  def video_toggler(assigns) do
    ~H"""
    <div phx-click={JS.push("toggle_should_show_vid")}>
      <.icon :if={@should_show_vid} name="hero-video-camera-slash" />
      <.icon :if={!@should_show_vid} name="hero-video-camera" />
    </div>
    """
  end

  def follow_mode_toggler(assigns) do
    ~H"""
    <div phx-click={JS.push("toggle_is_follow_mode")}>
      <.icon :if={@is_follow_mode} name="hero-rectangle-stack" />
      <.icon :if={!@is_follow_mode} name="hero-queue-list" />
    </div>
    """
  end
end
