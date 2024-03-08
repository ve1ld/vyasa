defmodule VyasaWeb.AudioPlayer do
    use VyasaWeb, :live_component

    def mount(_, _, socket) do
      socket
      |> assign(player_details: nil)
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="audio-player" phx-hook="AudioPlayer">
        <audio></audio>
      </div>
      """
    end

    @impl true
    def update(%{
          event: "media_bridge:update_audio_player" = event,
          player_details: player_details,
          elapsed: elapsed,
             } = _assigns, socket) do
      IO.inspect("handle update case in audio_player.ex with event = #{event}", label: "checkpoint")

      {
        :ok, socket
        |> assign(player_details: player_details)
        |> assign(elapsed: elapsed) # TODO: refactor candidate for removal
      }
    end

    @impl true
    def update(assigns, socket) do
      IO.inspect(assigns, label: "what")
      {:ok, socket |> assign(player_details: nil)}
    end
  end
