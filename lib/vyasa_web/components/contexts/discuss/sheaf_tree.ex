defmodule VyasaWeb.Context.Discuss.SheafTree do
  use VyasaWeb, :html

  alias Vyasa.Sangh.{SheafLattice, Sheaf}
  import VyasaWeb.Context.Components
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState

  @doc """
  Contains a root sheaf, with its own children and grandchildren sheafs.
  """
  attr :sheaf, Sheaf,
    required: true,
    doc: "The root sheaf being displayed."

  attr :sheaf_lattice, :map,
    required: true,
    doc: "The flatmap representing the entire sheaf lattice."

  attr :sheaf_ui_lattice, :map,
    required: true,
    doc: "The UI state associated with the sheafs."

  def root_sheaf(assigns) do
    ~H"""
    <div class="root-sheaf" id={"root-sheaf-container-" <> @sheaf.id}>
      <.debug_dump
        class="relative"
        label="root sheaf dump"
        sheaf={@sheaf}
        sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, @sheaf)}
        level={0}
      />
      <.sheaf_component
        id={"sheaf-" <> @sheaf.id}
        sheaf={@sheaf}
        sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, @sheaf)}
        sheaf_lattice={@sheaf_lattice}
        sheaf_ui_lattice={@sheaf_ui_lattice}
        level={0}
      />
    </div>
    """
  end

  @doc """
  Defines a container that can have collapsed and non-collapsed state.

  NOTE:
  @precondition: for parent sheafs with level > 2, an empty map is expected because of the read_lattice() functions
  which will catch this.
  """
  attr :id, :string,
    required: true,
    doc: "A suffix for id values, injected by the caller of this function component."

  attr :sheafs, :list,
    required: true,
    doc: "A list of child sheafs to be displayed in this container."

  attr :sheaf_lattice, :map,
    required: true,
    doc: "The flatmap representing the entire sheaf lattice."

  attr :sheaf_ui_lattice, :map,
    required: true,
    doc: "The UI state associated with the sheafs."

  attr :level, :integer,
    required: true,
    doc: "The current depth level of the tree structure."

  def collapsible_sheaf_container(assigns) do
    ~H"""
    <div class="collapsible-sheafs" id={"collapsible-sheaf-container-" <> @id}>
      <!-- Non-Collapsible View -->
      <%= if is_nil(@sheafs) or !@sheafs or Enum.empty?(@sheafs) do %>
        <p>No child sheafs available.</p>
      <% else %>
        <%= for child <- @sheafs do %>
          <.sheaf_component
            id={"sheaf-" <> child.id}
            sheaf={child}
            sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, child)}
            sheaf_lattice={@sheaf_lattice}
            sheaf_ui_lattice={@sheaf_ui_lattice}
            level={@level + 1}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc """
  Define a generic sheaf component.

  The is_active? flag determines whether marks shall be displayed within it,
  and is_expanded? flag determines whether to show that sheaf's children.
  """

  attr :id, :string,
    required: true,
    doc: "The id suffix that gets injected by the parent node of this function component"

  attr :sheaf, Sheaf,
    required: true,
    doc: "The individual sheaf being displayed."

  attr :sheaf_ui, SheafUiState,
    required: true,
    doc: "The corresponding ui state for the sheaf, defined here for ease of access"

  attr :sheaf_lattice, :map,
    required: true,
    doc: "The flatmap representing the entire sheaf lattice."

  attr :sheaf_ui_lattice, :map,
    required: true,
    doc: "The UI state associated with the sheafs."

  attr :level, :integer,
    required: true,
    doc: "The current depth level of the tree structure."

  def sheaf_component(assigns) do
    ~H"""
    <div class="sheaf" id={"container-" <> @id}>
      <.sheaf_summary sheaf={@sheaf} />
      <!-- display only if maarks ui says so -->
      <!-- <.collapsible_marks_display
        :if={
          not is_nil(@sheaf_ui) and
            Map.get(@sheaf_ui, :marks_ui, MarksUiState.get_initial_ui_state()).is_expanded_view?
        }
        marks_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, @sheaf).marks_ui}
        id={@sheaf.id}
        myself={@events_target}
      />
      <!-- Collapsible Sheaf Container -->
      <.collapsible_sheaf_container
        :if={
          not is_nil(@sheaf_ui) and
            @sheaf_ui
            |> Map.get(:is_expanded?, false)
        }
        id={@sheaf.id}
        sheafs={
          SheafLattice.read_sheaf_lattice(@sheaf_lattice, @level + 1, @sheaf.path.labels ++ [nil])
        }
        sheaf_lattice={@sheaf_lattice}
        sheaf_ui_lattice={@sheaf_ui_lattice}
        level={@level + 1}
      />
    </div>
    """
  end
end
