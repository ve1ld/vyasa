defmodule VyasaWeb.AudioPlayer do
    use VyasaWeb, :live_component

    def mount(_, _, socket) do
      socket
      |> assign(player_deetz: nil)
    end

    @impl true
    def render(assigns) do
      IO.inspect(assigns)
      ~H"""
      <div id="audio-player">
        <audio></audio>
        <br/>
        <br/>
        <br/>
        <h1>audio player :: my state is:</h1>
        <%= inspect @player_deetz %>

        <br/>
        <%= inspect @socket.assigns%>
      </div>
      """
    end

    @impl true
    def update(%{
          player_details: player_details,
             } = _assigns, socket) do
      IO.inspect("handle update case in audio_player.ex", label: "checkpoint")

      {:ok, socket |> assign(player_deetz: player_details)}
    end

    @impl true
    def update(assigns, socket) do
      IO.inspect(assigns, label: "what")
      {:ok, socket |> assign(player_deetz: nil)}
    end
  end
