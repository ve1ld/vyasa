defmodule VyasaWeb.YouTubePlayer do
    use Phoenix.LiveComponent

    def render(assigns) do
      ~H"""
      <div>
        <div> ------- YOUTUBE PLAYER: ----- </div>
        <div
          crossorigin="anonymous"
          id="player"
          phx-hook="YouTubePlayer"
        />
      </div>
      """
    end
 end
