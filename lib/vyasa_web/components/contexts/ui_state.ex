#################################################################################
# These structs is expected to be useful across all the user-modes that we shall#
# have. Hence it applies to generic components that are defined in the          #
# VyasaWeb.Context.Components module.                                           #
#################################################################################
defmodule VyasaWeb.Context.Components.UiState.Mark do
  @moduledoc """
  Definition of ui state corresponding to a single mark.
  """
  alias VyasaWeb.Context.Components.UiState.Mark, as: UiState

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

defmodule VyasaWeb.Context.Components.UiState.Marks do
  @moduledoc """
  Definition of ui state corresponding to a a set of marks in a sheaf.
  """
  alias Vyasa.Sangh.Mark
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState

  defstruct [
    :is_expanded_view?,
    :show_sheaf_modal?,
    :is_editable_marks?,
    :mark_id_to_ui
  ]

  @initial %{
    is_expanded_view?: false,
    show_sheaf_modal?: false,
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

  @doc """
  Registers a single mark, its state gets tracked thereafter.
  """
  def register_mark(
        %MarksUiState{mark_id_to_ui: mark_id_to_ui} = ui_state,
        mark_id
      )
      when is_binary(mark_id) do
    %MarksUiState{
      ui_state
      | mark_id_to_ui:
          mark_id_to_ui
          |> Map.put(mark_id, MarkUiState.get_initial_ui_state())
    }
  end

  @doc """
  Deregisters a single mark, removing its state from tracking.
  """
  def deregister_mark(
        %MarksUiState{mark_id_to_ui: mark_id_to_ui} = ui_state,
        mark_id
      )
      when is_binary(mark_id) do
    %MarksUiState{
      ui_state
      | mark_id_to_ui: mark_id_to_ui |> Map.delete(mark_id)
    }
  end

  def toggle_show_sheaf_modal?(
        %MarksUiState{
          show_sheaf_modal?: curr
        } = ui_state
      ) do
    %MarksUiState{ui_state | show_sheaf_modal?: !curr}
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

defmodule VyasaWeb.Context.Components.UiState.Sheaf do
  alias Vyasa.Sangh.{Sheaf, Mark}
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState

  # QQ: @ks0m1c i haven't thought of whether the is_active should be duplicated from
  # the actual ui state and kept within the SheafUiState or not.
  # @rtshkmr to decide later, and remove this flag  if unnecessary
  defstruct [
    # this defines whether the sheaf is currently in focus
    :is_focused?,
    :is_expanded?,
    :marks_ui
  ]

  @initial %{
    is_focused?: false,
    is_expanded?: false,
    marks_ui: MarksUiState.get_initial_ui_state()
  }

  def get_initial_ui_state(
        %Sheaf{
          marks: marks,
          active: _active
        } = _sheaf
      ) do
    marks_ui =
      case marks do
        [%Mark{} | _] -> MarksUiState.get_initial_ui_state(marks)
        _ -> MarksUiState.get_initial_ui_state()
      end

    %SheafUiState{
      struct(SheafUiState, @initial)
      | marks_ui: marks_ui,
        is_focused?: false
    }
  end

  def get_initial_ui_state() do
    IO.puts("CHECKPOINT get initial ui state POKEMON")
    struct(SheafUiState, @initial)
  end

  def toggle_sheaf_is_focused?(%SheafUiState{is_focused?: curr} = ui_state) do
    %SheafUiState{ui_state | is_focused?: !curr}
  end

  def toggle_sheaf_is_expanded?(%SheafUiState{is_expanded?: curr} = ui_state) do
    %SheafUiState{ui_state | is_expanded?: !curr}
  end

  @doc """
  Wraps the toggle function for the marks ui state.
  """
  def toggle_marks_is_expanded_view(
        %SheafUiState{
          marks_ui: marks_ui_state
        } = sheaf_ui_state
      ) do
    %SheafUiState{
      sheaf_ui_state
      | marks_ui:
          marks_ui_state
          |> MarksUiState.toggle_is_expanded_view()
    }
  end

  @doc """
  Wraps the toggle function for the sheaf ui modal
  """
  def toggle_show_sheaf_modal?(
        %SheafUiState{
          marks_ui: ui_state
        } = sheaf_ui_state
      ) do
    %SheafUiState{
      sheaf_ui_state
      | marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?()
    }
  end

  @doc """
  Wraps the toggle function for the sheaf ui modal
  """
  def toggle_is_editable_marks?(
        %SheafUiState{
          marks_ui: ui_state
        } = sheaf_ui_state
      ) do
    %SheafUiState{
      sheaf_ui_state
      | marks_ui: ui_state |> MarksUiState.toggle_is_editable()
    }
  end

  @doc """
  Wraps the toggle function for the is editing mark content for a particular mark
  """
  def toggle_is_editing_mark_content?(
        %SheafUiState{
          marks_ui: ui_state
        } = sheaf_ui_state,
        mark_id
      )
      when is_binary(mark_id) do
    # dbg()

    %SheafUiState{
      sheaf_ui_state
      | marks_ui: ui_state |> MarksUiState.toggle_is_editing_mark_content(mark_id)
    }
  end

  @doc """
  Registers a mark, starts tracking its state
  """
  def register_mark(
        %SheafUiState{
          marks_ui: ui_state
        } = sheaf_ui_state,
        mark_id
      )
      when is_binary(mark_id) do
    IO.inspect(%{mark_id: mark_id, sheaf_ui_state: sheaf_ui_state},
      label: "UI_STATE::SHEAF::register_mark"
    )

    %SheafUiState{
      sheaf_ui_state
      | marks_ui: ui_state |> MarksUiState.register_mark(mark_id)
    }
  end

  @doc """
  Deregisters a mark, stops tracking its state.
  """
  def deregister_mark(
        %SheafUiState{
          marks_ui: ui_state
        } = sheaf_ui_state,
        mark_id
      )
      when is_binary(mark_id) do
    IO.inspect(%{mark_id: mark_id, sheaf_ui_state: sheaf_ui_state},
      label: "UI_STATE::SHEAF::deregister_mark"
    )

    %SheafUiState{
      sheaf_ui_state
      | marks_ui: ui_state |> MarksUiState.deregister_mark(mark_id)
    }
  end
end
