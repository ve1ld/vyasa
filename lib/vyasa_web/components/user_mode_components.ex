# TODO: rename
defmodule VyasaWeb.UserMode.Components do
  use VyasaWeb, :html
  alias VyasaWeb.ModeLive.UserMode

  attr :action_event, :string, required: true
  attr :action_icon_name, :string, required: true

  def control_panel_mode_action(assigns) do
    ~H"""
    <button
      phx-click={@action_event}
      class="bg-white/20 hover:bg-white/30 text-white rounded-full focus:outline-none transition-all duration-300 shadow-md active:scale-95 flex items-center justify-center w-10 h-10 p-1 backdrop-blur-md border border-white/10"
    >
      <%= if @action_icon_name do %>
        <.icon
          name={@action_icon_name}
          class="w-5 h-5 text-gray-500 hover:text-primaryAccent transition-colors duration-200 stroke-current stroke-2"
        />
      <% end %>
    </button>
    """
  end

  def hover_rune_quick_action(assigns) do
    ~H"""
    <button
      phx-click={@action_event}
      phx-target={@action_target}
      class="text-gray-600 hover:text-blue-600 focus:outline-none"
    >
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
    <button
      phx-click={
        JS.push("change_mode",
          value: %{
            current_mode: @current_mode.mode,
            target_mode: @target_mode.mode
          }
        )
      }
      class="bg-white/20 hover:bg-white/30 text-white rounded-full focus:outline-none transition-all duration-300 shadow-md active:scale-95 flex items-center justify-center w-10 h-10 p-1 backdrop-blur-md border border-white/10"
    >
      <.icon
        name={@target_mode.mode_icon_name}
        class="w-5 h-5 text-gray-500 hover:text-primaryAccent transition-colors duration-200 stroke-current stroke-2"
      />
    </button>
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
    <button
      id="control-panel-indicator"
      class="bg-white/30 hover:bg-white/40 text-white rounded-full focus:outline-none transition-all duration-300 backdrop-blur-lg shadow-lg active:scale-95 flex items-center justify-center w-11 h-11 p-1 border border-white/20"
      phx-click={JS.push("toggle_show_control_panel")}
      phx-target={@myself}
    >
      <.icon
        name={@mode.mode_icon_name}
        class="w-5 h-5 text-gray-500 hover:text-primaryAccent transition-colors duration-200 stroke-current stroke-2"
      />
    </button>
    """
  end
end
