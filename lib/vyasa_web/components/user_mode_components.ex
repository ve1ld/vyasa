defmodule VyasaWeb.Display.UserMode.Components do
  use VyasaWeb, :html
  alias Vyasa.Display.UserMode

  def render_hoverune_button(:mark_quote, assigns) do
    ~H"""
    <button phx-click="markQuote" class="text-gray-600 hover:text-blue-600 focus:outline-none">
      <.icon
        name="hero-link-mini"
        class="w-5 h-5 hover:text-black hover:cursor-pointer hover:text-primaryAccent"
      />
    </button>
    """
  end

  def render_hoverune_button(:bookmark, assigns) do
    ~H"""
    <button class="text-gray-600 hover:text-red-600 focus:outline-none">
      <.icon name="hero-bookmark-mini" class="w-5 h-5 hover:text-black hover:cursor-pointer" />
    </button>
    """
  end

  def render_hoverune_button(_fallback_id, assigns) do
    ~H"""
    <div></div>
    """
  end

  def render_current_mode_button(
        %{
          mode: %UserMode{}
        } = assigns
      ) do
    ~H"""
    <div>
      <%= @mode.mode_icon_name %>
      <.button
        id="toggleButton"
        class="bg-blue-500 text-white p-2 rounded-full focus:outline-none"
        phx-click={JS.push("toggle_show_control_panel")}
        phx-target={@myself}
      >
        <.icon name={@mode.mode_icon_name} />
      </.button>
    </div>
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
