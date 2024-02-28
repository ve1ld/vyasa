defmodule VyasaWeb.AudioPlayer do
    use VyasaWeb, :live_component

    def mount(_, _, socket) do
      socket
      |> assign(player_details: nil)
    end

    @impl true
    def render(assigns) do
      IO.inspect(assigns)
      ~H"""
      <div id="audio-player" phx-hook="AudioPlayer">
        <audio></audio>
        <br/>
        <br/>
        <br/>
        <h1>audio player :: my state is:</h1>
        <%= inspect @player_details %>

        <br/>
        <%= inspect @socket.assigns%>
      </div>
      """
    end

    @impl true
    def update(%{
          event: "play_audio" = event,
          player_details: player_details,
             } = _assigns, socket) do
      IO.inspect("handle update case in audio_player.ex with event = #{event}", label: "checkpoint")

      {
        :ok, socket
        |> assign(player_details: player_details)
        |> push_event("play_media", player_details)
      }
    end

    ## TODO: consider not even having these updates and just directly push_event from media bridge and allowing the
    ##       players handle that event..
    @impl true
    def update(%{
          event: "pause_audio" = event,
          elapsed: elapsed,
             } = _assigns, socket) do
      IO.inspect("handle update case in audio_player.ex with event = #{event}", label: "checkpoint")

      {
        :ok, socket
        |> assign(elapsed: elapsed) # TODO: consider not keeping in state, or keeping playback in state instead
        |> push_event("pause_media", %{elapsed: elapsed})
      }
    end

    @impl true
    def update(assigns, socket) do
      IO.inspect(assigns, label: "what")
      {:ok, socket |> assign(player_details: nil)}
    end
  end
