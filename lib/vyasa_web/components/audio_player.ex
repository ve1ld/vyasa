defmodule VyasaWeb.AudioPlayer do
  @moduledoc """
  This is the concrete AudioPlayer module that interfaces with the html5 audio player.
  User-generated events will get piped directly to the MediaBridge which will notify the AudioPlayer when there are updates to make.
  Any interfacing with the html5 player shall happen from this module (e.g. dispatching an evnent for the client-side AudioPlayer Hook).
  """
  use VyasaWeb, :live_component

  alias Vyasa.Medium.{Playback}

  def mount(_, _, socket) do
    socket
    |> assign(playback: nil)
  end

  @impl true
  def render(assigns) do
    # TODO: remove the reliance on the playback prop passed here, it forces a remounting of the node, which is undesirable
    ~H"""
    <div id="audio-player" phx-hook="AudioPlayer">
      <audio data-playback={Jason.encode!(@playback)}></audio>
    </div>
    """
  end

  @impl true
  def update(
        %{
          event: "media_bridge:notify_audio_player" = event,
          playback: %Playback{} = playback
        } = _assigns,
        socket
      ) do
    IO.inspect(
      "TRACE: audio player notified by media bridge -- audio_player.ex with event = #{event}",
      label: "checkpoint"
    )

    {:ok,
     socket
     |> assign(playback: playback)}
  end

  @impl true
  def update(_assigns, socket) do
    {:ok,
     socket
     |> assign(playback: nil)}
  end
end
