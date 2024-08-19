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
    :control_panel_component
  ]

  # defines static aspects of different modes:
  @defs %{
    "read" => %{
      mode: "read",
      mode_icon_name: "hero-book-open",
      action_bar_component: VyasaWeb.MediaLive.MediaBridge,
      control_panel_component: VyasaWeb.ControlPanel
    },
    "draft" => %{
      mode: "draft",
      mode_icon_name: "hero-pencil-square",
      # TODO: add drafting form for this
      # TODO: to test swaps of action bar component
      action_bar_component: VyasaWeb.MediaLive.MediaBridge,
      # action_bar_component: nil,
      control_panel_component: VyasaWeb.ControlPanel
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
