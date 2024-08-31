defmodule Vyasa.Display.UiState do
  @moduledoc """
  UiState defines booleans and other UI-related aspects that need to be tracked.
  This shall only be a struct definition. If mediating state transitions becomes complex enough, then we shall
  add split DM to a UiStateManager and DataManager or something of that nature.

  This is expected to be used in 2 ways:
  1. allow DM to manage this UiState via this struct
  2. allow UserModes to be defined with an initial UI state in mind
  """
  defstruct [
    :show_media_bridge?,
    :show_action_bar?
  ]
end
