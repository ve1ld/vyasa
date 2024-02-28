defmodule VyasaWeb.AudioPlayer do
    use VyasaWeb, :live_component

    def mount(_, _, socket) do
      socket
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="audio-player" phx-update="ignore">
        <audio></audio>
        <br/>
        <br/>
        <br/>
        <h1>audio player :: my state is:</h1>
        <%= inspect @socket %>

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
      IO.inspect(player_details, label: "checkpoint: player details")

      {:ok, socket
      |> assign(player_details: player_details)
      |> dbg()
      }
    end

    @impl true
    def update(_assigns, socket) do
      {:ok, socket}
    end
  end
