defmodule VyasaWeb.Display.UserMode.Components do
  use VyasaWeb, :html
  alias Vyasa.Display.UserMode

  attr :action_event, :string, required: true
  attr :action_icon_name, :string, required: true

  def hover_rune_quick_action(assigns) do
    ~H"""
    <button phx-click={@action_event} class="text-gray-600 hover:text-blue-600 focus:outline-none">
      <%= if @action_icon_name do %>
        <.icon
          name={@action_icon_name}
          class="w-5 h-5 hover:text-black hover:cursor-pointer hover:text-primaryAccent"
        />
      <% end %>
    </button>
    """
  end

  def action_bar_action(assigns) do
    ~H"""
    <button
      id={"action-bar-action-button-" <> @action_name}
      phx-click={@action_event}
      class="relative text-3xl sm:text-4xl focus:outline-none transition-all duration-300 ease-in-out hover:text-brand dark:hover:text-brandAccentLight transform hover:scale-110 active:bg-gray-200 dark:active:bg-gray-700 rounded-full p-2"
    >
      <%= if @action_icon_name do %>
        <.icon
          name={@action_icon_name}
          class="w-8 h-8 sm:w-10 sm:h-10 hover:text-black hover:cursor-pointer hover:text-primaryAccent"
        />
        <span class="absolute inset-0 bg-current opacity-0 group-active:animate-ripple rounded-full" />
      <% end %>
    </button>
    """
  end

  attr :current_mode, UserMode, required: true
  attr :target_mode, UserMode, required: true

  @doc """
  The mode button displays modes that can be switched into.
  Clicking it allows the user to switch from the current mode to the target mode.
  """
  def control_panel_mode_button(assigns) do
    ~H"""
    <.button
      phx-click={
        JS.push("change_mode",
          value: %{
            current_mode: @current_mode.mode,
            target_mode: @target_mode.mode
          }
        )
      }
      class="bg-green-500 text-white px-4 py-2 rounded-md focus:outline-none"
    >
      <.icon name={@target_mode.mode_icon_name} />
    </.button>
    """
  end

  attr :mode, UserMode, required: true
  attr :myself, :any, required: true

  @doc """
  The current user mode is indicated by this button that shall always be present and hovering, regardless whether
  the Control Panel is collapsed or not.
  """
  def control_panel_mode_indicator(assigns) do
    ~H"""
    <.button
      id="control-panel-indicator"
      class="bg-blue-500 text-white p-2 rounded-full focus:outline-none"
      phx-click={JS.push("toggle_show_control_panel")}
      phx-target={@myself}
    >
      <.icon name={@mode.mode_icon_name} />
    </.button>
    """
  end
end
