defmodule VyasaWeb.CommandGroup do
  @moduledoc """
  """
  use VyasaWeb, :live_component
  alias Phoenix.LiveView.Socket

  # alias Vyasa.Medium.{Playback}

  def mount(_, _, socket) do
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-15 right-5">
      <!-- SVG Icon Button -->
      <h1>show_command_group?: <%= @show_command_group? %></h1>
      <.button
        id="toggleButton"
        class="bg-blue-500 text-white p-2 rounded-full focus:outline-none"
        phx-click={JS.push("toggle_show_command_group")}
        phx-target={@myself}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="w-6 h-6"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 14.25l4.5-4.5m0 0L12 5.25m4.5 4.5H3"
          />
        </svg>
      </.button>
      <div
        id="buttonGroup"
        class={
          if @show_command_group?,
            do: "flex flex-col mt-2 space-y-2",
            else: "flex flex-col mt-2 space-y-2 hidden"
        }
      >
        <button class="bg-green-500 text-white px-4 py-2 rounded-md focus:outline-none">
          Button 1
        </button>
        <button class="bg-red-500 text-white px-4 py-2 rounded-md focus:outline-none">
          Button 2
        </button>
        <button class="bg-yellow-500 text-white px-4 py-2 rounded-md focus:outline-none">
          Button 3
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "toggle_show_command_group",
        _params,
        %Socket{
          assigns:
            %{
              show_command_group?: show_command_group?
            } = _assigns
        } = socket
      ) do
    IO.inspect(show_command_group?, label: "TRACE handle event for toggle_show_command_group")

    {
      :noreply,
      socket
      |> assign(show_command_group?: !show_command_group?)
    }
  end

  @impl true
  def update(_assigns, socket) do
    {:ok,
     socket
     |> assign(show_command_group?: false)}
  end

  # @impl true
  # def update(
  #       %{
  #         event: "media_bridge:notify_audio_player" = _event,
  #         playback: %Playback{} = playback
  #       } = _assigns,
  #       socket
  #     ) do
  #   {:ok,
  #    socket
  #    |> assign(playback: playback)}
  # end

  # @impl true
  # def update(_assigns, socket) do
  #   {:ok,
  #    socket
  #    |> assign(playback: nil)}
  # end
end
