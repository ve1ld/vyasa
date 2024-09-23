defmodule VyasaWeb.YouTubePlayer do
  use VyasaWeb, :live_component

  @impl true
  def update(params, socket) do
    {:ok,
     socket
     |> assign(params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        crossorigin="anonymous"
        id="player"
        phx-hook="RenderYouTubePlayer"
        data-video-id={@video_id}
        data-player-config={@player_config}
      />
    </div>
    """
  end

  @impl true
  def handle_event("reportVideoStatus", payload, socket) do
    IO.inspect(payload)
    {:noreply, socket}
  end
end
