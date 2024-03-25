defmodule VyasaWeb.AudioPlayer do
    use VyasaWeb, :live_component

    def mount(_, _, socket) do
      socket
      |> assign(playback: nil)
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
          playback: playback,
             } = _assigns, socket) do
      IO.inspect("handle update case in audio_player.ex with event = #{event}", label: "checkpoint")

      {
        :ok, socket
        |> assign(playback: playback)
      }
    end

    @impl true
    def update(assigns, socket) do
      IO.inspect(assigns, label: "what")
      {:ok, socket
      |> assign(playback: nil)
      }
    end
  end
