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
      <.debug_dump marks_target={@marks_target} class="relative" marks_ui={@marks_ui} />
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
          phx-target={@myself}
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
          editable={@marks_ui.is_editable_marks?}
        />
      </div>
    </div>
    """
  end

  attr :mark, :any, required: true
  attr :mark_ui, :any, required: true
  attr :marks_target, :any, required: true
  attr :myself, :any
  attr :editable, :boolean

  def mark_display(assigns) do
    ~H"""
    <div class="border-l border-brand-light pl-2">
      <.debug_dump
        mark_id={@mark.id}
        mark_order={@mark.order}
        mark_state={@mark.state}
        mark_last_updated={@mark.updated_at}
        class="relative"
      />
      <%= if @mark.state == :live do %>
        <div
          id={"mark-container-" <>
          @mark.id}
          class="mb-2 bg-brand-light rounded-lg shadow-sm p-1 border-l-2 border-brand flex justify-between items-start"
        >
          <div id={"ordering-button-group-"<> @mark.id} class="flex flex-col items-center">
            <button
              phx-click="dummy_event"
              phx-target={@myself}
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
              phx-target={@myself}
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
              phx-click="toggle_is_editing_content?"
              phx-target={@myself}
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

  attr :mark, :any, required: true
  attr :myself, :any
  attr :editable, :boolean

  def mark_display_(assigns) do
    ~H"""
    <div class="border-l border-brand-light pl-2 py-1">
      <%= if @mark.state == :live do %>
        <div class="flex items-start space-x-2 group">
          <div class="flex-grow">
            <%= if !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
              <p class="text-xs italic text-secondary mb-1">
                <span
                  phx-click="edit_quote"
                  phx-value-id={@mark.id}
                  class="cursor-text hover:bg-brand-light"
                >
                  <%= @mark.binding.window.quote %>
                </span>
              </p>
            <% end %>
            <p class="text-sm text-text">
              <%= if @editable do %>
                <textarea
                  rows="2"
                  class="w-full bg-transparent border-b border-brand-light focus:outline-none focus:border-brand resize-none"
                  phx-blur="update_body"
                  phx-value-id={@mark.id}
                ><%= @mark.body %></textarea>
              <% else %>
                <span
                  phx-click="edit_body"
                  phx-value-id={@mark.id}
                  class="cursor-text hover:bg-brand-light"
                >
                  <%= @mark.body %>
                </span>
              <% end %>
            </p>
          </div>
          <div class="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <button
              phx-click="edit_mark"
              phx-value-id={@mark.id}
              class="text-brand hover:text-brand-dark focus:outline-none"
              title="Edit"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
            </button>
            <button
              phx-click="tombMark"
              phx-target="#content-display"
              phx-value-id={@mark.id}
              class="text-red-500 hover:text-red-700 focus:outline-none"
              title="Delete"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                viewBox="0 0 24 24"
                fill="currentColor"
                class="size-6"
              >
                <path d="M3.53 2.47a.75.75 0 0 0-1.06 1.06l18 18a.75.75 0 1 0 1.06-1.06l-18-18ZM20.25 5.507v11.561L5.853 2.671c.15-.043.306-.075.467-.094a49.255 49.255 0 0 1 11.36 0c1.497.174 2.57 1.46 2.57 2.93ZM3.75 21V6.932l14.063 14.063L12 18.088l-7.165 3.583A.75.75 0 0 1 3.75 21Z" />
              </svg>
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
      name="editable-mark-body"
      disabled={not @mark_ui.is_editing_content?}
      id={"editable-mark-body-" <> @id}
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
