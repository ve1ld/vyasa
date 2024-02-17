defmodule VyasaWeb.MediaLive.Player do
  use VyasaWeb, :live_view
  # use VyasaWeb, {:live_view, container: {:div, []}}

  @pubsub Vyasa.PubSub
  # alias Vyasa.Medium
  alias Vyasa.MediaLibrary.Playback
  alias Vyasa.Medium.{Voice}

  # alias LiveBeats.{Accounts, MediaLibrary}
  #
  # alias LiveBeats.MediaLibrary.Song
  # alias LiveBeatsWeb.Presence

  # on_mount {LiveBeatsWeb.UserAuth, :current_user}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe_now_playing()
    end

    # initial_voice = Medium.get_voice_stub()
    socket = socket
    # |> assign(voice: initial_voice)
    |> assign(voice: nil)
    |> assign(playback: nil)
    # |> assign(playback: Playback.new(%{
    #           medium: nil,
    #           playing?: false
    #                                  }))

    {:ok, socket, layout: false}
  end

  defp subscribe_now_playing do
    Phoenix.PubSub.subscribe(@pubsub, "nowplaying")
  end

  # defp switch_profile(socket, nil) do
  #   current_user = Accounts.update_active_profile(socket.assigns.current_user, nil)

  #   if profile = connected?(socket) and socket.assigns.profile do
  #     Presence.untrack_profile_user(profile, current_user.id)
  #   end

  #   socket
  #   |> assign(current_user: current_user)
  #   |> assign_profile(nil)
  # end

  # defp switch_profile(socket, profile_user_id) do
  #   %{current_user: current_user} = socket.assigns
  #   profile = get_profile(profile_user_id)

  #   if profile && connected?(socket) do
  #     current_user = Accounts.update_active_profile(current_user, profile.user_id)
  #     # untrack last profile the user was listening
  #     if socket.assigns.profile do
  #       Presence.untrack_profile_user(socket.assigns.profile, current_user.id)
  #     end

  #     Presence.track_profile_user(profile, current_user.id)
  #     send(self(), :play_current)

  #     socket
  #     |> assign(current_user: current_user)
  #     |> assign_profile(profile)
  #   else
  #     assign_profile(socket, nil)
  #   end
  # end

  # defp assign_profile(socket, profile)
  #      when is_struct(profile, MediaLibrary.Profile) or is_nil(profile) do
  #   %{profile: prev_profile, current_user: current_user} = socket.assigns

  #   profile_changed? = profile_changed?(prev_profile, profile)

  #   if connected?(socket) and profile_changed? do
  #     prev_profile && MediaLibrary.unsubscribe_to_profile(prev_profile)
  #     profile && MediaLibrary.subscribe_to_profile(profile)
  #   end

  #   assign(socket,
  #     profile: profile,
  #     own_profile?: !!profile && MediaLibrary.owns_profile?(current_user, profile)
  #   )
  # end


  @impl true
  def handle_event("play_pause", _, socket) do
    %{voice: voice, playback: playback} = socket.assigns

    IO.puts("handle_event: play_pause:, checkout socket:")
    dbg(socket)

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

    playback = %{playback | playing?: false, paused_at: now, elapsed: elapsed}
    IO.puts("pause_playback")
    dbg(playback)

    playback

  end


  defp play_playback(%Playback{
        elapsed: elapsed
                     } = playback) do
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
    IO.puts("play_playback")
    dbg(playback)

    playback
  end

  # def handle_event("play_pause", _, socket) do
  #   %{song: song, playing: playing, current_user: current_user} = socket.assigns
  #   song = MediaLibrary.get_song!(song.id)

  #   cond do
  #     song && playing and MediaLibrary.can_control_playback?(current_user, song) ->
  #       MediaLibrary.pause_song(song)
  #       {:noreply, assign(socket, playing: false)}

  #     song && MediaLibrary.can_control_playback?(current_user, song) ->
  #       MediaLibrary.play_song(song)
  #       {:noreply, assign(socket, playing: true)}

  #     true ->
  #       {:noreply, socket}
  #   end
  # end

  # def handle_event("switch_profile", %{"user_id" => user_id}, socket) do
  #   {:noreply, switch_profile(socket, user_id)}
  # end

  # def handle_event("next_song", _, socket) do
  #   %{song: song, current_user: current_user} = socket.assigns

  #   if song && MediaLibrary.can_control_playback?(current_user, song) do
  #     MediaLibrary.play_next_song(socket.assigns.profile)
  #   end

  #   {:noreply, socket}
  # end

  # def handle_event("prev_song", _, socket) do
  #   %{song: song, current_user: current_user} = socket.assigns

  #   if song && MediaLibrary.can_control_playback?(current_user, song) do
  #     MediaLibrary.play_prev_song(socket.assigns.profile)
  #   end

  #   {:noreply, socket}
  # end

  # def handle_event("next_song_auto", _, socket) do
  #   if socket.assigns.song do
  #     MediaLibrary.play_next_song_auto(socket.assigns.profile)
  #   end

  #   {:noreply, socket}
  # end

  @impl true
  def handle_info({:set_voice, voice} = msg, socket) do
    IO.puts(">> [handle_info] set voice! by player_live.ex")
    dbg(msg, limit: :infinity)

    # voice = %Voice{voice | file_path: "http://localhost:9000/vyasa/voices/d040c39a-a25d-45b2-b73d-a7d3db70cbee.mp3?ContentType=application%2Foctet-stream&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secrettunnel%2F20240217%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Date=20240217T033529Z&X-Amz-Expires=88888&X-Amz-SignedHeaders=host&X-Amz-Signature=d5aed6e6c22a7f29409663901033d1e15c83572f48358c6d84f78609e089ac8e"}
    socket = socket
    |> assign(voice: voice)
    |> assign(playback: Playback.new(%{
              medium: voice,
              playing?: false,
                                     }))

    {:noreply, socket
    }

  end

  # def handle_info(:play_current, socket) do
  #   {:noreply, play_current_song(socket)}
  # end

  # def handle_info(
  #       {Accounts, %Accounts.Events.ActiveProfileChanged{new_profile_user_id: user_id}},
  #       socket
  #     ) do
  #   if user_id do
  #     {:noreply, assign(socket, profile: get_profile(user_id))}
  #   else
  #     {:noreply, socket |> assign_profile(nil) |> stop_song()}
  #   end
  # end

  # def handle_info({MediaLibrary, %MediaLibrary.Events.PublicProfileUpdated{} = update}, socket) do
  #   %{current_user: current_user} = socket.assigns

  #   if update.profile.user_id == socket.assigns.current_user.id do
  #     Presence.untrack_profile_user(socket.assigns.profile, current_user.id)
  #     Presence.track_profile_user(update.profile, current_user.id)
  #   end

  #   {:noreply, assign_profile(socket, update.profile)}
  # end

  # def handle_info({MediaLibrary, %MediaLibrary.Events.Pause{}}, socket) do
  #   {:noreply, push_pause(socket)}
  # end

  # def handle_info({MediaLibrary, %MediaLibrary.Events.Play{} = play}, socket) do
  #   {:noreply, play_song(socket, play.song, play.elapsed)}
  # end

  # def handle_info({MediaLibrary, _}, socket), do: {:noreply, socket}


defp play_voice(socket, voice, %Playback{
      elapsed: elapsed,
                } = playback) do
    IO.puts("play_voice triggerred with elapsed = #{elapsed}")
    IO.inspect(voice)

    socket
    |> push_play(voice, playback)
end

defp pause_voice(socket, voice, %Playback{
      elapsed: elapsed
                 } = playback) do
  IO.puts("pause_voice triggerred with elapsed = #{elapsed}")
  IO.inspect(voice)

  # paused_at = DateTime.truncate(DateTime.utc_now(), :second)
  paused_at = DateTime.utc_now()

  playback = %{playback | paused_at: paused_at}

  socket
  |> push_pause(voice, playback)

end

  # defp play_song(socket, %Song{} = song, elapsed) do
  #   socket
  #   |> push_play(song, elapsed)
  #   |> assign(song: song, playing: true, page_title: song_title(song))
  # end

  # defp stop_song(socket) do
  #   socket
  #   |> push_event("stop", %{})
  #   |> assign(song: nil, playing: false, page_title: "Listing Songs")
  # end

  # defp song_title(%{artist: artist, title: title}) do
  #   "#{title} - #{artist} (Now Playing)"
  # end

  # defp play_current_song(socket) do
  #   song = MediaLibrary.get_current_active_song(socket.assigns.profile)

  #   cond do
  #     song && MediaLibrary.playing?(song) ->
  #       play_song(socket, song, MediaLibrary.elapsed_playback(song))

  #     song && MediaLibrary.paused?(song) ->
  #       assign(socket, song: song, playing: false)

  #     true ->
  #       socket
  #   end
  # end

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

  # defp push_play(socket, %Song{} = song, elapsed) do
  #   token =
  #     Phoenix.Token.encrypt(socket.endpoint, "file", %{
  #       vsn: 1,
  #       ip: to_string(song.server_ip),
  #       size: song.mp3_filesize,
  #       uuid: song.mp3_filename
  #     })

  #   push_event(socket, "play", %{
  #     artist: song.artist,
  #     title: song.title,
  #     paused: Song.paused?(song),
  #     elapsed: elapsed,
  #     duration: song.duration,
  #     token: token,
  #     url: song.mp3_url
  #   })
  # end

  # defp push_pause(socket) do
  #   socket
  #   |> push_event("pause", %{})
  #   |> assign(playing: false)
  # end

  # defp js_play_pause() do
  # end
  defp js_play_pause() do
    JS.push("play_pause") # server event
    |> JS.dispatch("js:play_pause", to: "#audio-player") # client-side event



    # if own_profile? do
    #   JS.push("play_pause")
    #   |> JS.dispatch("js:play_pause", to: "#audio-player")
    # else
    #   show_modal("not-authorized")
    # end
  end


  defp js_prev() do
  end
  # defp js_prev(own_profile?) do
  #   if own_profile? do
  #     JS.push("prev_song")
  #   else
  #     show_modal("not-authorized")
  #   end
  # end

  defp js_next() do
  end

  # defp js_next(own_profile?) do
  #   if own_profile? do
  #     JS.push("next_song")
  #   else
  #     show_modal("not-authorized")
  #   end
  # end

  # defp js_listen_now(js \\ %JS{}) do
  #   JS.dispatch(js, "js:listen_now", to: "#audio-player")
  # end

  # defp get_profile(user_id) do
  #   user_id && Accounts.get_user!(user_id) |> MediaLibrary.get_profile!()
  # end

  # defp profile_changed?(nil = _prev_profile, nil = _new_profile), do: false
  # defp profile_changed?(nil = _prev_profile, %MediaLibrary.Profile{}), do: true
  # defp profile_changed?(%MediaLibrary.Profile{}, nil = _new_profile), do: true

  # defp profile_changed?(%MediaLibrary.Profile{} = prev, %MediaLibrary.Profile{} = new),
  #   do: prev.user_id != new.user_id


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
