defmodule VyasaWeb.HoveRune do
  @moduledoc """
  The HoveRune is a hovering quick-actions menu.
  For now, it's done used in the context of selected text.

  We shall define slot attributs for the various kinds of buttons we want
  and we shall render those buttons using approate rendering functions defined elsewhere.
  """
  use VyasaWeb, :live_component

  attr :quick_action_buttons, :list_of, type: :atom, default: []
  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="hoverune"
      phx-update="ignore"
      class="absolute hidden top-0 left-0 max-w-max group-hover:flex items-center space-x-2 bg-white/80 rounded-lg shadow-lg px-4 py-2 border border-gray-200 transition-all duration-300 ease-in-out"
    >
      <div :for={button_id <- @quick_action_buttons}>
        <%= VyasaWeb.Display.UserMode.Components.render_hoverune_button(button_id, %{}) %>
      </div>
    </div>
    """
  end
end
