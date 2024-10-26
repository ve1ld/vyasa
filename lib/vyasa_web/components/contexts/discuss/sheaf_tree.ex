defmodule VyasaWeb.Context.Discuss.SheafTree do
  @moduledoc """
  This module provides functions components that can be wired up
  to render a 3-level deep tree for discussions.
  """
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

  attr :events_target, :string,
    required: true,
    doc:
      "the target value to be used as argument for the phx-target field wherever emits shall get emitted."

  attr :sheaf_lattice, :map,
    required: true,
    doc: "The flatmap representing the entire sheaf lattice."

  attr :sheaf_ui_lattice, :map,
    required: true,
    doc: "The UI state associated with the sheafs."

  def root_sheaf(assigns) do
    ~H"""
    <div class="flex flex-col" id={"root-sheaf-container-" <> @sheaf.id}>
      <!-- <.debug_dump
        class="relative"
        label="root sheaf dump"
        sheaf={@sheaf}
        sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, @sheaf)}
        level={0}
      /> -->
      <.sheaf_component
        id={"sheaf-" <> @sheaf.id}
        events_target={@events_target}
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

  attr :events_target, :string,
    required: true,
    doc:
      "the target value to be used as argument for the phx-target field wherever emits shall get emitted."

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

  attr :container_class, :string,
    default: "",
    doc: "Overridable class definition to be applied to the container."

  def collapsible_sheaf_container(assigns) do
    ~H"""
    <div
      class={["border-l-2 border-gray-200", @container_class]}
      id={"collapsible-sheaf-container-" <> @id}
    >
      <!-- Non-Collapsible View -->
      <%= if is_nil(@sheafs) or !@sheafs or Enum.empty?(@sheafs) do %>
        <p class="text-gray-500">No child sheafs available.</p>
      <% else %>
        <%= for child <- @sheafs do %>
          <.sheaf_component
            id={"sheaf-" <> child.id}
            events_target={@events_target}
            sheaf={child}
            sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, child)}
            sheaf_lattice={@sheaf_lattice}
            sheaf_ui_lattice={@sheaf_ui_lattice}
            level={@level}
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

  attr :events_target, :string,
    required: true,
    doc:
      "the target value to be used as argument for the phx-target field wherever emits shall get emitted."

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
    <div id={"sheaf-component_container-" <> @id} class="flex flex-col">
      <!-- <.debug_dump
        label={"LEVEL "<> to_string(@level) <>  " sheaf component id=" <> @id}
        sheaf_ui={@sheaf_ui}
        level={@level}
        sheaf_path={@sheaf.path}
      /> -->
      <.sheaf_summary sheaf={@sheaf} />
      <!-- Display Marks if Active -->
      <%= if @sheaf_ui.is_active? do %>
        <.collapsible_marks_display
          marks_ui={@sheaf_ui.marks_ui}
          marks_target={@events_target}
          marks={@sheaf.marks}
          id={"marks-" <> @sheaf.id}
          myself={@events_target}
        />
      <% end %>
      <!-- Collapsible Sheaf Container -->
      <%= if @sheaf_ui.is_expanded? do %>
        <.collapsible_sheaf_container
          id={"collapsible_sheaf_container-" <> @id}
          container_class={"flex flex-col overflow-scroll pl-#{to_string((@level + 1) * 4)}  ml-#{to_string((@level + 1) * 4)}"}
          events_target={@events_target}
          sheafs={
            SheafLattice.read_sheaf_lattice(@sheaf_lattice, @level + 1, @sheaf.path.labels ++ [nil])
          }
          sheaf_lattice={@sheaf_lattice}
          sheaf_ui_lattice={@sheaf_ui_lattice}
          level={@level + 1}
        />
      <% end %>
    </div>
    """
  end
end
