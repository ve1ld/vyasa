defmodule VyasaWeb.YouTubePlayer do
    use VyasaWeb, :live_component

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <div> ------- YOUTUBE PLAYER: ----- </div>
        <.button id="seek100" phx-hook="TriggerYouTubeFunction" data-event-name="click" data-function-name={"seekTo"} data-target-time-stamp={100}> Button 1: 100s </.button>
        <.button id="seek1000" phx-hook="TriggerYouTubeFunction" data-event-name="click" data-function-name={"seekTo"}  data-target-time-stamp={1000}> Button 2: 1000s </.button>
        <.button
          id="switchVideo"
          phx-hook="TriggerYouTubeFunction"
          data-function-name={"loadVideoById"}
          data-event-name={"click"}
          data-video-id={"3jWRrafhO7M"}
          data-target-time-stamp={0}
        >
          Load New Video @ Start
        </.button>
        <br/>
        <.button id="statsHover" phx-hook={"TriggerYouTubeFunction"} data-event-name={"mouseover"} data-function-name={"getAllStats"}> Hover to get stats </.button>
        <br/>
        <div
          crossorigin="anonymous"
          id="player"
          phx-hook="RenderYouTubePlayer"
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
