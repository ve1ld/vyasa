defmodule VyasaWeb.ActionBar do
  @moduledoc """
  ActionBar is our slottable panel of buttons that are user-mode-specific.
  It shall recieve a list of actions and shall effect changes specific to the user mode.

  For example, consider the action of navigation, which is a generic slot

  say the following info is passeed via %UserMode:
  %UserMode{
  ...
    mode: "read",
    action_bar_actions: [:nav_back, :nav_fwd]
  ...
  } = u_mode

  then the action is used for the phx-click for that button, and the event name ends up being a concat:
  <mode> <> "::" <> <action_name>
  """
  use VyasaWeb, :live_component
  alias Vyasa.Display.UserMode
  import VyasaWeb.Display.UserMode.Components

  attr :mode, UserMode, required: true
  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="action-bar"
      class="bg-gray-50 text-black dark:bg-brandExtraDark dark:text-brandAccentLight
           px-4 sm:px-6 lg:px-8 py-3 flex items-center justify-center"
    >
      <%= for action <- @mode.action_bar_actions do %>
        <.action_bar_action
          action_name={Atom.to_string(action)}
          action_event={define_action_event_name(action, @mode)}
          action_icon_name={get_action_icon_name(action)}
        />
      <% end %>
    </div>
    """
  end

  def define_action_event_name(action, %UserMode{mode: mode_name} = _mode) when is_atom(action) do
    mode_name <> "::" <> Atom.to_string(action)
  end

  @doc """
  Resolves icons to use for the actions
  """
  def get_action_icon_name(action) when is_atom(action) do
    case action do
      :nav_back -> "hero-arrow-left-circle"
      :nav_fwd -> "hero-arrow-right-circle"
      _ -> nil
    end
  end
end
