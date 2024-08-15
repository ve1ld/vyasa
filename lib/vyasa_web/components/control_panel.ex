defmodule VyasaWeb.ControlPanel do
  @moduledoc """
  The ControlPanel is the hover-overlay of buttons that allow the user to access
  usage-modes and carry out actions related to a specific mode.
  """
  use VyasaWeb, :live_component
  alias Phoenix.LiveView.Socket

  def mount(_, _, socket) do
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-15 right-5 z-10 justify-end">
      <!-- SVG Icon Button -->
      <%= @mode.mode %>
      <.button
        id="toggleButton"
        class="bg-blue-500 text-white p-2 rounded-full focus:outline-none"
        phx-click={JS.push("toggle_show_control_panel")}
        phx-target={@myself}
      >
        <.icon name={@mode.mode_icon_name} />
      </.button>
      <div
        id="buttonGroup"
        class={
          if @show_control_panel?,
            do: "flex flex-col mt-2 space-y-2",
            else: "flex flex-col mt-2 space-y-2 hidden"
        }
      >
        <.button
          phx-click={JS.push("change_mode", value: %{current_mode: @mode.mode, target_mode: "read"})}
          class="bg-green-500 text-white px-4 py-2 rounded-md focus:outline-none"
        >
          Change to Read
        </.button>
        <.button
          phx-click={JS.push("change_mode", value: %{current_mode: @mode.mode, target_mode: "draft"})}
          class="bg-red-500 text-white px-4 py-2 rounded-md focus:outline-none"
        >
          Change to Draft
        </.button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "toggle_show_control_panel",
        _params,
        %Socket{
          assigns:
            %{
              show_control_panel?: show_control_panel?
            } = _assigns
        } = socket
      ) do
    IO.inspect(show_control_panel?, label: "TRACE handle event for toggle_show_control_panel")

    {
      :noreply,
      socket
      |> assign(show_control_panel?: !show_control_panel?)
    }
  end

  @impl true
  def update(%{id: _id, mode: mode} = _assigns, socket) do
    {:ok,
     socket
     |> assign(show_control_panel?: false)
     |> assign(mode: mode)}
  end
end
