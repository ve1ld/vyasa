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
  # attr :reply_to_path, Ltree, default: nil, doc: "The current reply_to context's path"
  attr :reply_to, Sheaf, default: nil, doc: "The sheaf that is being replied to. "

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

  attr :level, :integer,
    default: 0,
    doc:
      "Defines what level the root is, it's expected to be an integer value in the range [0, 2]"

  attr(:on_replies_click, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the replies button is clicked."
  )

  attr(:on_set_reply_to, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the reply-to button is clicked."
  )

  attr(:on_quick_reply, JS,
    default: %JS{},
    doc:
      "Defines a callback to invoke when the user wishes to quick reply, this potentially override the reply to context."
  )

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
        reply_to={@reply_to}
        sheaf={@sheaf}
        on_replies_click={@on_replies_click}
        on_set_reply_to={@on_set_reply_to}
        on_quick_reply={@on_quick_reply}
        children={
          SheafLattice.read_published_from_sheaf_lattice(
            @sheaf_lattice,
            @level + 1,
            @sheaf.path.labels ++ [nil]
          )
        }
        sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, @sheaf)}
        sheaf_lattice={@sheaf_lattice}
        sheaf_ui_lattice={@sheaf_ui_lattice}
        level={@level}
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

  attr :sheaf, Sheaf, required: true, doc: "What the parent sheaf is"
  attr :reply_to, Sheaf, default: nil, doc: "The sheaf that is being replied to. "

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

  attr(:on_replies_click, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the replies button is clicked."
  )

  attr(:on_set_reply_to, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the reply-to button is clicked."
  )

  attr(:on_quick_reply, JS,
    default: %JS{},
    doc:
      "Defines a callback to invoke when the user wishes to quick reply, this potentially override the reply to context."
  )

  def collapsible_sheaf_container(assigns) do
    ~H"""
    <div
      class={["border-l-2 border-gray-200", @container_class]}
      id={"collapsible-sheaf-container-" <> @id}
    >
      <!-- <.debug_dump label="collapsible sheaf container" reply_to={@reply_to} /> -->
      <!-- Non-Collapsible View -->
      <%= if is_nil(@sheafs) or !@sheafs or Enum.empty?(@sheafs) do %>
        <p class="text-gray-500">No child sheafs available.</p>
      <% else %>
        <%= for child <- @sheafs do %>
          <.sheaf_component
            id={"sheaf-" <> child.id}
            events_target={@events_target}
            reply_to={@reply_to}
            sheaf={child}
            sheaf_ui={SheafLattice.get_ui_from_lattice(@sheaf_ui_lattice, child)}
            sheaf_lattice={@sheaf_lattice}
            sheaf_ui_lattice={@sheaf_ui_lattice}
            level={@level + 1}
            on_replies_click={@on_replies_click}
            on_set_reply_to={@on_set_reply_to}
            on_quick_reply={@on_quick_reply}
            children={
              SheafLattice.read_published_from_sheaf_lattice(
                @sheaf_lattice,
                @level,
                @sheaf.path.labels ++ [nil]
              )
            }
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

  attr :reply_to, Sheaf, default: nil, doc: "The sheaf that is being replied to. "

  attr :children, :list, default: [], doc: "The children of this sheaf"

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

  attr(:on_replies_click, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the replies button is clicked."
  )

  attr(:on_set_reply_to, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the reply-to button is clicked."
  )

  attr(:on_quick_reply, JS,
    default: %JS{},
    doc:
      "Defines a callback to invoke when the user wishes to quick reply, this potentially override the reply to context."
  )

  def sheaf_component(assigns) do
    assigns =
      assigns
      |> assign(
        is_reply_to:
          not is_nil(assigns.reply_to) &&
            assigns.sheaf.path.labels == assigns.reply_to.path.labels &&
            assigns.sheaf_ui.is_focused?
      )

    ~H"""
    <div
      id={"level" <> to_string(@level) <> "-sheaf-component_container-" <> @id}
      class="flex flex-col"
    >
      <!-- <.debug_dump
        label={"LEVEL "<> to_string(@level) <>  " sheaf component id=" <> @id}
        reply_to={@reply_to}
        is_reply_to={@is_reply_to}
        level={@level}
        sheaf_path={@sheaf.path}
      /> -->
      <.sheaf_summary
        id={"sheaf-tree-node-sheaf-summary-"<> @id}
        level={@level}
        is_reply_to={@is_reply_to}
        sheaf={@sheaf}
        sheaf_ui={@sheaf_ui}
        children={@children}
        on_signature_deadspace_click={@on_replies_click}
        on_replies_click={@on_replies_click}
        on_set_reply_to={@on_set_reply_to}
        on_quick_reply={@on_quick_reply}
      />
      <!-- Display Marks if Active -->
      <%= if @sheaf.active do %>
        <.collapsible_marks_display
          marks_target={@events_target}
          sheaf={@sheaf}
          sheaf_ui={@sheaf_ui}
          id={"marks-" <> @sheaf.id}
          myself={@events_target}
        />
      <% end %>
      <!-- Collapsible Sheaf Container -->
      <%= if @level <= 2 && @sheaf_ui.is_expanded? do %>
        <.collapsible_sheaf_container
          id={"collapsible_sheaf_container-" <> @id}
          sheaf={@sheaf}
          reply_to={@reply_to}
          container_class={"flex flex-col overflow-scroll pl-#{to_string((@level + 1) * 5)}  ml-#{to_string((@level + 1) * 4)}"}
          events_target={@events_target}
          sheafs={@children}
          sheaf_lattice={@sheaf_lattice}
          sheaf_ui_lattice={@sheaf_ui_lattice}
          level={@level + 1}
          on_replies_click={@on_replies_click}
          on_set_reply_to={@on_set_reply_to}
          on_quick_reply={@on_quick_reply}
        />
      <% end %>
    </div>
    """
  end
end
