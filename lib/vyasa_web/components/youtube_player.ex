defmodule VyasaWeb.YouTubePlayer do
    use VyasaWeb, :live_component

    # @impl true
    # def update(%{event: "play_audio" = _event} = _params, socket) do
    #   {:ok, socket}
    # end

    @impl true
    def update(params, socket) do
      IO.inspect(socket, label: "BREAKS HERE")
      IO.inspect(params, label: "BREAKS HERE params")
      {:ok, socket
       |> assign(params)
      }
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

    # @impl true
    # def render(assigns) do
    #   ~H"""
    #   <div>
    #     <div
    #       crossorigin="anonymous"
    #       id="player"
    #       phx-hook="RenderYouTubePlayer"
    #       data-video-id={@video_id}
    #       data-player-config={@player_config}
    #     />
    #     <br/>
    #     <br/>
    #     <.button id="seek100" phx-hook="TriggerYouTubeFunction" data-event-name="click" data-function-name={"seekTo"} data-target-time-stamp={100}> Button 1: 100s </.button>
    #     <.button id="seek1000" phx-hook="TriggerYouTubeFunction" data-event-name="click" data-function-name={"seekTo"}  data-target-time-stamp={1000}> Button 2: 1000s </.button>
    #     <.button
    #       id="switchVideo"
    #       phx-hook="TriggerYouTubeFunction"
    #       data-function-name={"loadVideoById"}
    #       data-event-name={"click"}
    #       data-video-id={@video_id}
    #       data-target-time-stamp={0}
    #     >
    #       Load New Video @ Start
    #     </.button>
    #     <br/>
    #     <.button id="statsHover" phx-hook={"TriggerYouTubeFunction"} data-event-name={"mouseover"} data-function-name={"getAllStats"}> Hover to get stats </.button>
    #     <br/>

    #   </div>
    #   """
    # end

  @impl true
  def handle_event("reportVideoStatus", payload, socket) do
    IO.inspect(payload)
    {:noreply, socket}
  end

 end
