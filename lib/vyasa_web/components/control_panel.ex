defmodule VyasaWeb.ControlPanel do
  @moduledoc """
  The ControlPanel is the hover-overlay of buttons that allow the user to access
  usage-modes and carry out actions related to a specific mode.
  """
  use VyasaWeb, :live_component
  use VyasaWeb, :html
  alias Phoenix.LiveView.Socket
  alias Vyasa.Display.UserMode
  import VyasaWeb.Display.UserMode.Components

  def mount(_, _, socket) do
    socket
  end

  attr :mode, UserMode, required: true
  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-15 right-5 z-10 justify-end">
      <!-- SVG Icon Button -->
      <.control_panel_mode_indicator mode={@mode} myself={@myself} />
      <div
        id="buttonGroup"
        class={
          if @show_control_panel?,
            do: "flex flex-col mt-2 space-y-2",
            else: "flex flex-col mt-2 space-y-2 hidden"
        }
      >
        <%= for other_mode <- @mode.control_panel_modes do %>
          <.control_panel_mode_button
            current_mode={@mode}
            target_mode={UserMode.get_mode(other_mode)}
          />
        <% end %>
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
