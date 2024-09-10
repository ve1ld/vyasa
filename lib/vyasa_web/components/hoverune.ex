defmodule VyasaWeb.HoveRune do
  @moduledoc """
  The HoveRune is a hovering quick-actions menu.
  For now, it's done used in the context of selected text.

  We shall define slot attributes for the various kinds of buttons we want
  and we shall render those buttons using approate rendering functions defined elsewhere.
  """
  use VyasaWeb, :live_component
  alias Vyasa.Display.UserMode
  import VyasaWeb.Display.UserMode.Components

  attr :user_mode, UserMode, required: true
  @impl true
  # TODO: use param for #reading-content below
  def render(assigns) do
    ~H"""
    <div
      id="hoverune"
      class="z-10 absolute hidden top-0 left-0 max-w-max group-hover:flex items-center bg-white/90 rounded-lg shadow-lg border border-gray-200 transition-all duration-300 ease-in-out p-1"
    >
      <%= for action <- @user_mode.quick_actions do %>
        <.hover_rune_quick_action
          action_event={get_quick_action_click_event(action)}
          action_icon_name={get_quick_action_icon_name(action)}
          action_target="#reading-content"
        />
      <% end %>
    </div>
    """
  end

  def get_quick_action_click_event(action) when is_atom(action) do
    case action do
      :mark_quote -> "markQuote"
      _ -> ""
    end
  end

  def get_quick_action_icon_name(action) when is_atom(action) do
    case action do
      :bookmark -> "hero-bookmark-mini"
      :mark_quote -> "hero-link-mini"
      _ -> nil
    end
  end
end
