defmodule Vyasa.Display.UserMode do
  @moduledoc """
  The UserMode struct is a way of representing user-modes and
  is intended to be used as a container.

  Typically,
  1. they shall contain component-definitions that get passed as "args" for the DM layout
  2. they may contain callback functions that get triggerred on a particular button activity

  Modes:
  1. Reading
  2. Drafting
  3. Discussion(?)
  """
  alias Vyasa.Display.UserMode

  @derive Jason.Encoder
  defstruct [
    :mode,
    :mode_icon_name,
    :action_bar_component,
    :control_panel_component,
    :quick_actions,
    :control_panel_modes,
    :mode_actions
  ]

  # THESE ARE EXAMPLE quick actions and mode actions for now

  # we use quick_actions to define what quick actions are supported
  # by the hoverrune
  @quick_actions [:mark_quote, :bookmark]
  # we use mode_actions to define what specific actions are supported
  # under this mode.
  @mode_actions [:mark_quote, :bookmark]

  # defines static aspects of different modes:
  # TODO: define mode-specific hoverrune functions here
  @defs %{
    "read" => %{
      mode: "read",
      mode_icon_name: "hero-book-open",
      action_bar_component: VyasaWeb.MediaLive.MediaBridge,
      control_panel_component: VyasaWeb.ControlPanel,
      quick_actions: @quick_actions,
      control_panel_modes: ["draft"],
      mode_actions: @mode_actions
    },
    "draft" => %{
      mode: "draft",
      mode_icon_name: "hero-pencil-square",
      # TODO: add drafting form for this
      # TODO: to test swaps of action bar component
      action_bar_component: VyasaWeb.MediaLive.MediaBridge,
      control_panel_component: VyasaWeb.ControlPanel,
      quick_actions: @quick_actions,
      control_panel_modes: ["read"],
      mode_actions: @mode_actions
    }
  }

  def supported_modes, do: Map.keys(@defs)

  def get_initial_mode() do
    mode = "read"
    struct(UserMode, @defs[mode])
  end

  def get_mode(mode_name) when is_map_key(@defs, mode_name) do
    struct(UserMode, @defs[mode_name])
  end

  # defaults to the intial mode
  def get_mode(_) do
    get_initial_mode()
  end
end
