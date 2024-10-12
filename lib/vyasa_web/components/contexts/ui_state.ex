#################################################################################
# These structs is expected to be useful across all the user-modes that we shall#
# have. Hence it applies to generic components that are defined in the          #
# VyasaWeb.Context.Components module.                                           #
#################################################################################

defmodule VyasaWeb.Context.Components.UiState.Marks do
  @moduledoc """
  Definition of ui state corresponding to a a set of marks in a sheaf.
  """
  alias Vyasa.Sangh.Mark
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState
  defstruct [:is_expanded_view?, :is_editable_marks?, :mark_id_to_ui]

  @initial %{
    is_expanded_view?: false,
    is_editable_marks?: false,
    mark_id_to_ui: %{}
  }

  def get_initial_ui_state([%Mark{} | _] = marks) do
    struct(MarksUiState, @initial)
    |> register_marks(marks)
  end

  def get_initial_ui_state() do
    struct(MarksUiState, @initial)
  end

  def register_marks(
        %MarksUiState{mark_id_to_ui: mark_id_to_ui} = ui_state,
        [%Mark{} | _] = marks
      ) do
    ui_entries =
      marks
      |> Enum.map(fn mark -> {mark.id, MarkUiState.get_initial_ui_state()} end)

    %MarksUiState{
      ui_state
      | mark_id_to_ui:
          ui_entries
          |> Enum.into(mark_id_to_ui)
    }
  end

  def toggle_is_editable(
        %MarksUiState{
          is_editable_marks?: curr
        } = ui_state
      ) do
    %MarksUiState{ui_state | is_editable_marks?: !curr}
  end

  @doc """
  Toggles the edit flag for a particular mark.
  """
  def toggle_is_editing_mark_content(
        %MarksUiState{
          mark_id_to_ui: mark_id_to_ui
        } = ui_state,
        mark_id
      )
      when is_binary(mark_id) do
    updated =
      mark_id_to_ui
      |> Map.put(
        mark_id,
        mark_id_to_ui
        |> Map.get(mark_id, nil)
        |> MarkUiState.toggle_is_editing_content()
      )

    %MarksUiState{ui_state | mark_id_to_ui: updated}
  end

  def toggle_is_expanded_view(
        %MarksUiState{
          is_expanded_view?: curr
        } = ui_state
      ) do
    %MarksUiState{ui_state | is_expanded_view?: !curr}
  end
end

defmodule VyasaWeb.Context.Components.UiState.Mark do
  @moduledoc """
  Definition of ui state corresponding to a single mark.
  """

  # alias Phoenix.LiveView.Socket
  alias VyasaWeb.Context.Components.UiState.Mark, as: UiState

  # import Phoenix.Component, only: [assign: 2]

  defstruct [
    :is_editing_content?
  ]

  def get_initial_ui_state() do
    struct(UiState, %{is_editing_content?: false})
  end

  def toggle_is_editing_content(%UiState{is_editing_content?: current} = state) do
    %UiState{state | is_editing_content?: !current}
  end
end