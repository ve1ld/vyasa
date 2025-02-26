defmodule VyasaWeb.MediaLive.MediaBridge do
  @moduledoc """
  Media Bridge intends to decouple the media players (audio/video...) from the context of what is being played.

  It will have the following responsibilities:
  1. stores a general playback state. This shall be agnostic to the players that rely on this playback state for synchronising their own playback states.
  2. It shall contain the common playback buttons because these buttons will be controlling all the supported players simultaneously. In so doing, playback state and actions are kept only in the media_bridge
  3. TODO: handle the sync between A/V players

  1) remove handshake protocol (just simple assign to socket)
  2) a client side component
  3) event fragment navigation a push event from client side that calls navigation stream
  4) remove heartbeat from server side
  """
  use VyasaWeb, :live_view
  alias Phoenix.LiveView.Socket
  alias Vyasa.Medium
  alias Vyasa.Medium.{Voice, Event, Playback}
  alias Vyasa.Bhaj.{Tracklist}

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

  @play_state %{
    playback: nil,
    tracklist_id: nil,
    tracklist_cursor: 0,
    voice: nil,
    video: nil,
    tracks: nil,
    should_show_vid: false,
    is_action_bar_visible: true,
    is_queue_visible: false,
    is_follow_mode: true,
    video_player_config: Jason.encode!(@default_player_config)
  }

  @impl true
  def mount(_params, _sess, socket) do
    if connected?(socket) do
      send(socket.parent_pid, %{event: :init_handshake, pid: self(), origin: __MODULE__})
    end

    {:ok, Enum.reduce(@play_state, socket, fn {key, state}, sock -> assign(sock, key, state) end),
     layout: false}
  end

  defp update_playback(
         %Socket{
           assigns:
             %{
               playback:
                 %Playback{
                   played_at: _played_at,
                   elapsed: _elapsed,
                   playing?: _playing?,
                   paused_at: _paused_at
                 } = playback_bef
             } = _assigns
         } =
           socket
       ) do
    # TODO: [refactor] add case for updating playback on seek
    socket
    |> assign(
      playback:
        case playback_bef do
          %Playback{playing?: false} ->
            create_playback_on_play(playback_bef)

          %Playback{playing?: true} ->
            create_playback_on_pause(playback_bef)

          _ ->
            playback_bef
        end
    )
  end

  defp update_playback(%Socket{} = socket) do
    socket
  end

  defp create_playback_on_play(%Playback{elapsed: elapsed} = playback) do
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

  defp create_playback_on_pause(
         %Playback{
           played_at: played_at
         } = playback
       ) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, played_at, :millisecond)
    %{playback | playing?: false, paused_at: now, elapsed: elapsed}
  end

  # TODO: [refactor] merge with the other update playback functions
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
        "toggle_is_queue_visible",
        _,
        %{assigns: %{is_queue_visible: flag} = _assigns} = socket
      ) do
    {:noreply, socket |> assign(is_queue_visible: !flag)}
  end

  @impl true
  def handle_event(
        "hide_playback_queue",
        _,
        %{assigns: %{is_queue_visible: flag} = _assigns} = socket
      ) do
    IO.puts("HIDE PLAYBACK QUEUE")

    case flag do
      true -> {:noreply, socket |> assign(is_queue_visible: false)}
      false -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "show_playback_queue",
        _,
        %{assigns: %{is_queue_visible: flag} = _assigns} = socket
      ) do
    case flag do
      true -> {:noreply, socket}
      false -> {:noreply, socket |> assign(is_queue_visible: true)}
    end
  end

  @impl true
  def handle_event(
        "toggle_is_action_bar_visible",
        _,
        %{assigns: %{is_action_bar_visible: flag} = _assigns} = socket
      ) do
    {:noreply, socket |> assign(is_action_bar_visible: !flag)}
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
  @doc """
  Handle the user-generated action of playing or pausing.
  First updates the playback struct then uses it to notify others that depend on that playback struct.

  TODO: use event structs in the same fashion as livebeats to standardise the user-generated events
  """
  def handle_event("play_pause", _, socket) do
    %{
      assigns: %{
        playback: %Playback{} = playback
      }
    } = socket

    IO.inspect(playback, label: "TRACE :handling play_pause event")

    {:noreply,
     socket
     |> update_playback()
     |> notify_audio_player()
     |> push_hook_events()}
  end

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

  @impl true
  def handle_event(poke_event, poke_message, socket) do
    IO.puts(~c"[handleEvent] fallthrough #{poke_event} handle event")
    IO.inspect(poke_message)
    {:noreply, socket}
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

  # assigns necessary states if voice is legit and events can be loaded.
  defp apply_voice_action(
         %Socket{} = socket,
         %Voice{
           video: video
         } = voice
       ) do
    loaded_voice = voice |> Medium.load_events()

    generated_artwork = %{
      src:
        url(~p"/og/#{VyasaWeb.OgImageController.get_by_binding(%{source: loaded_voice.source})}"),
      type: "image/png",
      sizes: "480x360"
    }

    playback = Playback.create_playback(loaded_voice, generated_artwork)

    socket
    |> assign(voice: loaded_voice)
    |> assign(video: video)
    |> assign(playback: playback)
  end

  defp dispatch_voice_registering_events(
         %Socket{
           assigns: %{
             voice:
               %Voice{
                 events: voice_events
               } = _voice,
             playback: playback
           }
         } = socket
       ) do
    socket
    |> push_event("media_bridge:registerEventsTimeline", %{
      voice_events: voice_events |> create_events_payload()
    })
    |> push_event("media_bridge:registerPlayback", %{playback: playback})
  end

  # TODO: consolidate other hook events that need to be sent to the media bridge hook
  defp push_hook_events(
         %Socket{
           assigns: %{
             playback:
               %Playback{
                 playing?: playing?,
                 elapsed: elapsed
               } = playback
           }
         } = socket
       ) do
    # TODO: merge into a single push_event, let the hook use the Playback::elapsed to determine where to start playing from.
    socket
    |> push_event("media_bridge:play_pause", %{
      cmd:
        cond do
          playing? ->
            "play"

          !playing? ->
            "pause"
        end,
      originator: "MediaBridge",
      playback: playback
    })
    |> push_event("media_bridge:seekTime", %{
      seekToMs: elapsed,
      originator: "MediaBridge"
    })
  end

  def handle_info(
        %{event: :load_tracklist, tracklist_loader: loader, tracklist_cursor: tracklist_cursor},
        %Socket{
          assigns:
            %{
              # voice: curr_voice
            }
        } = socket
      )
      when is_integer(tracklist_cursor) do
    with %Tracklist{title: title} = tracklist <- loader.() do
      IO.inspect(title, label: "WALDO: loaded the tracklist with title")

      {:noreply,
       socket
       # |> stream(:tracks, tracklist.tracks)
       |> assign(%{
         tracklist_id: tracklist.id,
         tracklist_cursor: tracklist_cursor,
         tracks: tracklist.tracks
       })}
    else
      _ -> {:noreply, socket}
    end

    # with %Voice{id: updated_voice_id} = voice <-  get_voice.(),
    #      false <- is_struct(curr_voice) && updated_voice_id == curr_voice.id do
    #   {:noreply,
    #      socket
    #      |> apply_voice_action(voice)
    #      |> dispatch_voice_registering_events()}
    # else
    #   _ -> {:noreply, socket}
    # end
  end

  @impl true
  # On receiving a voice_ack, the written and player contexts are now synced.
  # The voice's id shall be used as a sort of implicit ack number to check if the voice received
  # has already been received and in the case of a duplicate message, we shall ignore the msg.
  #
  # If the voice is new, then we shall pipe it to the respective apply_action where in
  # a playback struct is created that represents this synced-state and the client-side hook is triggerred
  # to register the associated events timeline.
  def handle_info(
        %{event: :ack_handshake, voice: get_voice},
        %Socket{
          assigns: %{
            voice: curr_voice
          }
        } = socket
      ) do
    with %Voice{id: updated_voice_id} = voice <- get_voice.(),
         false <- is_struct(curr_voice) && updated_voice_id == curr_voice.id do
      {:noreply,
       socket
       |> apply_voice_action(voice)
       |> dispatch_voice_registering_events()}
    else
      _ -> {:noreply, socket}
    end
  end

  # Handles playback sync relative to a particular verse id. In this case, the playback state is expected
  # to get updated to the start of the event corresponding to that particular verse.
  @impl true
  def handle_info(%{event: :playback_sync, payload: %{verse_id: verse_id}}, socket) do
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

  defp create_events_payload([]) do
    []
  end

  defp get_target_event([%Event{} | _] = events, verse_id) do
    events
    |> Enum.find(fn e -> e.verse_id === verse_id end)
  end

  # dispatches events to the audio player
  defp notify_audio_player(
         %{
           assigns:
             %{
               playback:
                 %Playback{
                   playing?: _playing?
                 } = playback
             } = _assigns
         } = socket
       ) do
    send_update(
      self(),
      VyasaWeb.AudioPlayer,
      id: "audio-player",
      playback: playback,
      event: "media_bridge:notify_audio_player"
    )

    socket
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
  attr :class, :string, default: ""

  def progress_bar(assigns) do
    assigns = assign_new(assigns, :value, fn -> assigns[:min] || 0 end)

    ~H"""
    <div
      id={"#{@id}-container"}
      class={[
        "relative bg-gray-200 dark:bg-black h-2 rounded-full overflow-visible cursor-pointer group",
        @class
      ]}
      phx-update="ignore"
      phx-hook="ProgressBar"
      data-value={@value}
      data-max={@max}
    >
      <div
        id={@id}
        class="absolute top-0 left-0 h-full bg-brand dark:bg-brandAccentLight rounded-full transition-all duration-100 ease-out"
        style="width: 0%;"
        data-min={@min}
        data-max={@max}
        data-val={@value}
      >
      </div>
      <div
        id={"#{@id}-scrubber"}
        class="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 w-4 h-4 bg-white border-2 border-brand dark:border-brandAccentLight rounded-full shadow-md transition-all duration-100 ease-out opacity-0 group-hover:opacity-100"
        style="left: 0%;"
      >
      </div>
    </div>
    """
  end

  attr :playback, Playback, required: false
  attr :isReady, :boolean, required: false, default: false
  attr :isPlaying, :boolean, required: true
  attr :class, :string, default: ""

  def play_pause_button(assigns) do
    ~H"""
    <button
      type="button"
      disabled={not @isReady}
      class={["mx-auto scale-75", @class]}
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
        <.icon name="custom-spinner-bars-scale-middle" class="w-10 h-10" />
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
    <button>
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
    </button>
    """
  end

  def video_toggler(assigns) do
    ~H"""
    <button phx-click={JS.push("toggle_should_show_vid")}>
      <.icon :if={@should_show_vid} name="hero-video-camera-slash" />
      <.icon :if={!@should_show_vid} name="hero-video-camera" />
    </button>
    """
  end

  def follow_mode_toggler(assigns) do
    ~H"""
    <button phx-click={JS.push("toggle_is_follow_mode")}>
      <.icon :if={@is_follow_mode} name="hero-rectangle-stack" />
      <.icon :if={!@is_follow_mode} name="hero-rectangle-group" />
    </button>
    """
  end

  def playback_queue_toggler(assigns) do
    ~H"""
    <button
      phx-click={JS.push("toggle_is_queue_visible")}
      class={if @is_queue_visible, do: "text-primaryAccent", else: ""}
    >
      <.icon name="hero-queue-list" />
    </button>
    """
  end

  def action_bar_toggler(assigns) do
    ~H"""
    <button
      id="media-bridge-player-visibility-toggle"
      phx-click={JS.push("toggle_is_action_bar_visible")}
      class="text-xl sm:text-2xl focus:outline-none hover:text-brand dark:hover:text-brandAccentLight transition-all duration-300 ease-in-out transform hover:scale-110"
    >
      <.icon name={if @is_action_bar_visible, do: "hero-eye-slash", else: "hero-eye"} />
    </button>
    """
  end

  def playback_queue(assigns) do
    ~H"""
    <.generic_modal_wrapper
      show={@is_queue_visible}
      id="playback-queue-sheet"
      side_position_class="right-0"
      container_class="fixed inset-0 z-50 flex justify-end"
      dialog_class="fixed inset-0 w-full max-w-md h-full justify-end"
      background_class="fixed inset-0 bg-transparent"
      focus_container_class="bg-transparent rounded-lg shadow-sm  overflow-y-auto max-h-[90vh]"
    >
      <div :for={track <- @tracks} :if={@tracks != nil}>
        <.track_summary track={track} is_now_playing={track.order === @tracklist_cursor} />
      </div>
    </.generic_modal_wrapper>
    """
  end

  def track_summary(assigns) do
    ~H"""
    TODO track view: <br />
    {to_title_case(@track.event.verse.body)} <br /> now playing? {@is_now_playing}
    """
  end
end
