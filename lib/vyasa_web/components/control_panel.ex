defmodule VyasaWeb.ControlPanel do
  @moduledoc """
  The ControlPanel is the hover-overlay of buttons that allow the user to access
  usage-modes and carry out actions related to a specific mode.
  """
  use VyasaWeb, :live_component
  use VyasaWeb, :html
  alias Phoenix.LiveView.Socket
  alias Vyasa.Display.UserMode
  # alias VyasaWeb.Display.UserMode.Components

  import VyasaWeb.Display.UserMode.Components
  alias VyasaWeb.HoveRune

  def mount(_, _, socket) do
    socket
  end

  attr :mode, UserMode, required: true
  @impl true
  # TODO: as a stop-gap we're using functions from Hoverune, this needs to be changed and
  # we need a component specific to control panel for the rendering of mode-specific action buttons
  def render(assigns) do
    ~H"""
    <div class="fixed top-15 right-4 z-30 flex flex-col items-end">
      <!-- SVG Icon Button -->
      <.control_panel_mode_indicator mode={@mode} myself={@myself} />
      <div
        id="buttonGroup"
        class={[
          "mt-2 p-3 rounded-2xl backdrop-blur-lg bg-white/10 shadow-lg transition-all duration-300 border border-white/20",
          @show_control_panel? && "opacity-100 translate-y-0",
          !@show_control_panel? && "opacity-0 translate-y-2 pointer-events-none"
        ]}
      >
        <div id="control-panel-mode-button-group" class="grid">
          <%= for other_mode <- @mode.control_panel_modes do %>
            <.control_panel_mode_button
              current_mode={@mode}
              target_mode={UserMode.get_mode(other_mode)}
            />
          <% end %>
        </div>
        <div
          id="action-button-group"
          class="flex flex-col space-y-2 mt-3 pt-3 border-t border-white/20"
        >
          <%= for action <- @mode.mode_actions do %>
            <.control_panel_mode_action
              action_event={HoveRune.get_quick_action_click_event(action)}
              action_icon_name={HoveRune.get_quick_action_icon_name(action)}
            />
          <% end %>
        </div>
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
