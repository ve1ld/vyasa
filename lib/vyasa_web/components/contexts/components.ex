defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState

  attr :marks, :list, default: []
  attr :marks_ui, MarksUiState, required: true
  attr :marks_target, :string
  attr :myself, :any, required: true

  # FIXME: the UUID generation for marks should ideally not be happening here, we should try to ensure that every mark has an id @ the point of creation, wherever that may be (fresh creation or created at point of insertion into the db)
  def collapsible_marks_display(assigns) do
    ~H"""
    <div class="mb-4">
      <div
        id="collapse-header-container"
        class="flex items-baseline justify-between p-2 bg-brand-extra-light rounded-lg shadow-sm transition-colors duration-200"
      >
        <button
          phx-click={JS.push("toggle_marks_display_collapsibility", value: %{value: ""})}
          phx-target={@marks_target}
          class="flex items-center w-full hover:bg-brand-light hover:text-brand"
        >
          <.icon
            name={if @marks_ui.is_expanded_view?, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="w-5 h-5 mr-2 text-brand-dark"
          />
          <.icon name="hero-bookmark-solid" class="w-5 h-5 mr-2 text-brand" />
          <span class="text-lg font-small text-brand-dark">
            <%= "#{Enum.count(@marks |> Enum.filter(&(&1.state == :live)))}" %>
          </span>
        </button>
        <button
          :if={@marks_ui.is_expanded_view?}
          class="flex space-x-2 pr-2"
          phx-click={JS.push("toggle_is_editable_marks?", value: %{value: ""})}
          phx-target={@marks_target}
        >
          <.icon
            name={
              if @marks_ui.is_editable_marks?,
                do: "custom-icon-mingcute-save-line",
                else: "custom-icon-mingcute-edit-4-line"
            }
            class="w-5 h-5 text-brand-dark cursor-pointer hover:bg-brand-accent hover:text-brand"
          />
        </button>
      </div>
      <div
        id="collapsible-content-container"
        class={
          if @marks_ui.is_expanded_view?,
            do: "mt-2 transition-all duration-500 ease-in-out max-h-screen overflow-scroll",
            else: "max-h-0 overflow-scroll"
        }
      >
        <.mark_display
          :for={mark <- @marks |> Enum.reverse()}
          mark={mark}
          marks_target={@marks_target}
          mark_ui={
            @marks_ui.mark_id_to_ui
            |> Map.get(mark.id, MarkUiState.get_initial_ui_state())
          }
          myself={@marks_target}
          is_editable?={@marks_ui.is_editable_marks?}
        />
      </div>
    </div>
    """
  end

  attr :mark, :any, required: true
  attr :mark_ui, :any, required: true
  attr :marks_target, :any, required: true
  attr :myself, :any
  attr :is_editable?, :boolean

  def mark_display(assigns) do
    ~H"""
    <div class="border-l border-brand-light pl-2">
      <%= if @mark.state == :live do %>
        <div
          id={"mark-container-" <>
          @mark.id}
          class="mb-2 bg-brand-light rounded-lg shadow-sm p-1 border-l-2 border-brand flex justify-between items-start"
        >
          <div
            :if={@is_editable?}
            id={"ordering-button-group-"<> @mark.id}
            class="flex flex-col items-center"
          >
            <button
              phx-click="dummy_event"
              phx-target={@marks_target}
              class="p-1 hover:bg-gray-200 rounded"
              aria-label="Up Arrow"
            >
              <.icon
                name="custom-icon-sort-up"
                class="w-5 h-5 text-brand-dark hover:bg-brand rounded-full p-1"
              />
            </button>
            <!-- Displaying Order -->
            <div class="mx-1 text-center text-md font-light"><%= @mark.order %></div>
            <button
              phx-click="dummy_event"
              phx-target={@marks_target}
              class="p-1 hover:bg-gray-200 rounded"
              aria-label="Down Arrow"
            >
              <.icon
                name="custom-icon-sort-down"
                class="w-5 h-5 text-brand-dark hover:bg-brand rounded-full p-1"
              />
            </button>
          </div>
          <div id={"mark-content-container-" <> @mark.id} class="h-full w-full flex-grow mx-2 pt-2">
            <%= if !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
              <span class="block mb-1 text-sm italic text-secondary">
                "<%= @mark.binding.window.quote %>"
              </span>
            <% end %>
            <%= if is_binary(@mark.body) do %>
              <div class="flex-grow h-full">
                <.mark_body id={@mark.id} mark_ui={@mark_ui} body_content={@mark.body} />
              </div>
            <% end %>
          </div>
          <div
            :if={@is_editable?}
            id={"mark-edit-actions-button-group-" <> @mark.id}
            class="h-full flex flex-col ml-2 space-y-2 justify-between"
          >
            <button
              phx-click="tombMark"
              phx-target={@marks_target}
              phx-value-id={@mark.id}
              title="Delete"
              class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
              aria-label="Delete"
            >
              <.icon name="hero-x-mark" class="w-5 h-5 text-brand-dark font-bold" />
            </button>
            <button
              phx-click="toggle_is_editing_mark_content?"
              phx-target={@marks_target}
              phx-value-mark_id={@mark.id}
              class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
              aria-label="Edit mark body"
            >
              <.icon name="custom-icon-recent-changes-ltr" class="w-5 h-5 text-brand-dark" />
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :mark_ui, MarkUiState, required: true
  attr :id, :string, required: true
  attr :body_content, :string, required: true

  def mark_body(assigns) do
    ~H"""
    <textarea
      name="mark-body"
      disabled={not @mark_ui.is_editing_content?}
      id={"mark-body-" <> @id}
      rows="3"
      phx-hook="TextareaAutoResize"
      class="h-full w-full flex-grow focus:outline-none bg-transparent text-sm text-text placeholder-gray-600 resize-vertical overflow-auto min-h-[2.5rem] max-h-[8rem] p-2 border-t-0 border-l-0 border-r-0 border-b-2 border-b-gray-300"
      placeholder="Edit your mark"
    >
      <%= @body_content %>
    </textarea>
    """
  end

  attr :sheaf, :any, required: true

  def sheaf_display(assigns) do
    ~H"""
    <span class="block
                   before:content-['╰'] before:mr-1 before:text-gray-500
                   lg:before:content-none
                   lg:border-l-0 lg:pl-2">
      SHEAF DISPLAY <%= @sheaf.body %> - <b><%= @sheaf.signature %></b>
    </span>
    """
  end
end
