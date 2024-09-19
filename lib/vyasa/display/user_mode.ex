defmodule Vyasa.Display.UserMode do
  @moduledoc """
  The UserMode struct is a way of representing user-modes and
  is intended to be used as a config.

  Typically,
  1. they shall contain component-definitions that get passed as "args" for the DM layout
  2. they may contain callback functions that get triggerred on a particular button activity
  3. they may contain some atoms that are used to define event names that happen when clicking corresponding buttons associated to these atoms.

  Current modes:
  1. read
  3. discuss
  """
  alias Vyasa.Display.{UserMode, UiState}

  @component_slots [:action_bar_component, :control_panel_component, :mode_context_component]
  @default_slot_selector ""

  @derive Jason.Encoder
  defstruct [
              :mode,
              :default_ui_state,
              :mode_icon_name,
              :quick_actions,
              :control_panel_modes,
              :mode_actions,
              :action_bar_actions,
              :action_bar_info_types
            ] ++
              Enum.flat_map(@component_slots, fn slot ->
                [{slot, nil}, {:"#{slot}_selector", @default_slot_selector}]
              end)

  # THESE ARE EXAMPLE quick actions and mode actions for now

  # we use quick_actions to define what quick actions are supported
  # by the hoverrune
  @quick_actions [:mark_quote, :bookmark]
  # we use mode_actions to define what specific actions are supported
  # under this mode.
  @mode_actions [:mark_quote, :bookmark]

  # defines static aspects of different modes:
  # TODO: define mode-specific hoverrune functions here
  # TODO: for the liveview for media bridge, just do a soft disappear
  @defs %{
    "read" => %{
      mode: "read",
      mode_icon_name: "hero-book-open",
      action_bar_component: VyasaWeb.MediaLive.MediaBridge,
      control_panel_component: VyasaWeb.ControlPanel,
      mode_context_component: VyasaWeb.Content.ReadingContent,
      quick_actions: @quick_actions,
      control_panel_modes: ["discuss"],
      mode_actions: @mode_actions,
      default_ui_state: %UiState{show_media_bridge?: true, show_action_bar?: true},
      # NOTE: so when it's used, the event name will end up being
      # "quick_mark_nav-dec"  ==> moves backwawrd in the order of the list
      action_bar_actions: [:nav_back, :nav_fwd]
    },
    "discuss" => %{
      mode: "discuss",
      mode_icon_name: "hero-chat-bubble-left-right",
      action_bar_component: VyasaWeb.MediaLive.MediaBridge,
      control_panel_component: VyasaWeb.ControlPanel,
      mode_context_component: VyasaWeb.Content.ReadingContent,
      quick_actions: @quick_actions,
      control_panel_modes: ["read"],
      mode_actions: @mode_actions,
      default_ui_state: %UiState{show_media_bridge?: true, show_action_bar?: true},
      action_bar_actions: [:nav_back, :nav_fwd]
    }
  }

  def supported_modes, do: Map.keys(@defs)

  def get_initial_mode() do
    "read"
    |> get_mode()
  end

  def get_mode(mode_name) when is_map_key(@defs, mode_name) do
    struct(UserMode, @defs[mode_name])
    |> maybe_hydrate_component_selectors()
  end

  # defaults to the intial mode
  def get_mode(_) do
    get_initial_mode()
  end

  @doc """
  Hydrates the component selectors for a given UserMode struct.

  This function iterates through the component keys in the UserMode struct,
  specifically the keys ending with `_component`. For each component:
  - If the component's value is `nil`, it is ignored.
  - If the component's value is an atom, it converts the atom to a kebab-case
    selector using `Utils.String.module_to_selector/1` and adds a new key
    for the selector in the struct.

  ## Parameters

    - mode: A `%UserMode{}` struct containing component definitions.

  ## Returns

    - A `%UserMode{}` struct with hydrated component selectors.

  ## Examples

      iex> mode = %UserMode{
      ...>   action_bar_component: MyApp.ActionBar,
      ...>   control_panel_component: nil,
      ...>   mode_context_component: MyApp.ContextComponent
      ...> }
      iex> Vyasa.Display.UserMode.maybe_hydrate_component_selectors(mode)
      %UserMode{
        action_bar_component: MyApp.ActionBar,
        action_bar_component_selector: "action-bar",
        control_panel_component: nil,
        mode_context_component: MyApp.ContextComponent,
        mode_context_component_selector: "context-component"
      }
  """
  def maybe_hydrate_component_selectors(%UserMode{} = mode) do
    Enum.reduce(@component_slots, mode, fn slot, acc ->
      slot_selector_key = String.to_atom("#{slot}_selector")
      IO.inspect(slot_selector_key, label: "CHECK slot_selector_key")

      case Map.get(acc, slot_selector_key) do
        @default_slot_selector ->
          selector = Utils.String.module_to_selector(Map.get(acc, slot))

          IO.inspect("selector: #{selector}, slot selector_key: #{slot_selector_key}",
            label: "CHECK slot_selector_key"
          )

          Map.put(acc, slot_selector_key, selector)

        _existing_value ->
          acc
      end
    end)
  end
end
