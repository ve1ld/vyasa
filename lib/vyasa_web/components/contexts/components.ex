defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html
  alias Vyasa.Sangh.{Sheaf}
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState

  attr :marks, :list, default: []
  attr :marks_ui, MarksUiState, required: true
  attr :marks_target, :string
  attr :myself, :any, required: true

  # FIXME: the UUID generation for marks should ideally not be happening here, we should try to ensure that every mark has an id @ the point of creation, wherever that may be (fresh creation or created at point of insertion into the db)
  def collapsible_marks_display(assigns) do
    ~H"""
    <!-- <.debug_dump label="Collapsible Marks Dump" class="relative" marks_ui={@marks_ui} /> -->
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
    <!-- <.debug_dump class="relative" mark_ui={@mark_ui} is_editable?={@is_editable?} />-->
    <div class="border-l border-brand-light pl-2">
      <!-- <.debug_dump
        mark_state={@mark.state}
        mark_id={@mark.id}
        class="relative"
        mark_order={@mark.order}
      />
      -->
      <%= if @mark.state == :live do %>
        <.form
          for={%{}}
          phx-submit="editMarkContent"
          phx-value-mark_id={@mark.id}
          phx-target={@marks_target}
        >
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
              <%= if not @mark_ui.is_editing_content? do %>
                <button
                  phx-click="toggle_is_editing_mark_content?"
                  phx-target={@marks_target}
                  phx-value-mark_id={@mark.id}
                  class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
                  aria-label="Toggle edit mark body"
                >
                  <.icon name="custom-icon-recent-changes-ltr" class="w-5 h-5 text-brand-dark" />
                </button>
              <% else %>
                <!-- Alternative content when not editing -->
                <button
                  type="submit"
                  class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
                  aria-label="Edit mark body"
                >
                  <.icon name="hero-bookmark" class="w-5 h-5 text-brand-dark" />
                </button>
              <% end %>
            </div>
          </div>
        </.form>
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
      name="mark_body"
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

  attr :id, :string, required: true
  attr :marks_ui, MarksUiState, required: true
  attr :marks, :list, required: true

  attr :active_sheaf, Sheaf,
    required: false,
    doc: "Refers to the sheaf that we are currently accumulating marks for.
      It's named active in line with the original intent of creating that active
      flag, where we define what the current sheaf is for which we are
      accumulating marks for."

  attr :reply_to, Sheaf, required: false, doc: "Refers to the sheaf that we are replying to"
  # TODO: the reply_to should probably just be a binding since we can reply to any binding
  attr :event_target, :string, required: true

  def sheaf_creator_modal(assigns) do
    ~H"""
    <.generic_modal_wrapper
      id="sheaf-creator-modal"
      show={@marks_ui.show_sheaf_modal?}
      on_cancel_callback={JS.push("toggle_show_sheaf_modal?", target: "#content-display")}
      on_click_away_callback={JS.push("toggle_show_sheaf_modal?", target: "#content-display")}
      window_keydown_callback={JS.push("toggle_show_sheaf_modal?", target: "#content-display")}
      container_class="rounded-lg shadow-lg overflow-hidden"
      background_class="bg-gray-800 bg-opacity-75 backdrop-blur-md"
      dialog_class="rounded-lg shadow-xl flex flex-col w-3/4 h-3/4 max-w-lg max-h-screen mx-auto my-auto overflow-scroll"
      focus_container_class="border border-red-500"
      focus_wrap_class="flex flex-col items-center justify-center h-full"
      inner_block_container_class="w-full p-6"
      close_button_icon_class="text-red-500 hover:text-red-700"
    >
      <div class="flex flex-col">
        <.replyto_context sheaf={@reply_to} />
        <.sheaf_creator
          id={@id}
          marks={@marks}
          marks_ui={@marks_ui}
          active_sheaf={@active_sheaf}
          reply_to={@reply_to}
          action_buttons={[]}
        />
      </div>
    </.generic_modal_wrapper>
    """
  end

  def sheaf_creator(assigns) do
    ~H"""
    <div id="sheaf-creator-container" class="p-6 m-6">
      <.current_draft_sheaf
        sheaf={@active_sheaf}
        event_target="#content-display"
        marks={@marks}
        marks_ui={@marks_ui}
      />
      <!-- TODO: button group for actions -->
      <div>STUB FOR BUTTON GROUPS</div>
    </div>
    """
  end

  def replyto_context(assigns) do
    ~H"""
    <div class="m-2 p-2 overflow-auto">
      <%= if not is_nil(@sheaf) do %>
        <div class="flex flex-col">
          <.sheaf_summary label="Responding to" sheaf={@sheaf} action_buttons={[]} />
        </div>
      <% else %>
        <h2 class="text-2xl font-normal text-gray-800">
          Creating a new thread
        </h2>
      <% end %>
    </div>
    """
  end

  @doc """
  TODO: implement a reddit-top-comment-like UI for this
  A brief view of a sheaf, showing the contextually relevant information about it.
  """
  attr :label, :string,
    default: nil,
    doc: "A string to serve as some label text to the sheaf being displayed"

  attr :sheaf, Sheaf, required: true, doc: "The Sheaf struct containing details."
  attr :action_buttons, :list, default: [], doc: "List of action button configurations."

  def sheaf_summary(assigns) do
    ~H"""
    <div class="border p-4 rounded-lg shadow-md bg-white">
      <h2
        :if={@label}
        class="italic text-lg font-normal text-gray-800 pb-1 mb-1 border-b border-gray-400"
      >
        <%= @label %>
      </h2>
      <!-- Body Display -->
      <div class="mb-2">
        <p class="text-gray-800"><%= @sheaf.body || "EMPTY BODY" %></p>
      </div>
      <!-- Signature and Action Button Group -->
      <div class="flex justify-between items-center mt-2">
        <.sheaf_signature_display sheaf={@sheaf} />
        <!-- Action Button Group -->
        <div class="flex space-x-2">
          <%= for {icon, action} <- @action_buttons do %>
            <button phx-click={action} class="flex items-center text-blue-500 hover:text-blue-700">
              <.icon name={icon} class="h-5 w-5 mr-1" />
              <span>Action</span>
              <!-- Replace with meaningful labels -->
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Gives information about who, when (created / last updated).
  """
  attr :sheaf, Sheaf, required: true
  attr :text_container_class, :string, default: ""
  attr :signature_class, :string, default: ""
  attr :time_class, :string, default: "text-sm italic"

  def sheaf_signature_display(assigns) do
    ~H"""
    <div class="flex mt-2 text-sm text-gray-600">
      <div class="mx-1 text-gray-800">
        <p>- <%= @sheaf.signature %></p>
      </div>
      <!-- Time Display -->
      <div class="mx-1 text-gray-800 text-sm italic">
        <%= if is_nil(@sheaf.updated_at) do %>
          <%= (@sheaf.inserted_at |> Utils.Formatters.Time.human_friendly_time()).formatted_time %>
        <% else %>
          <%= (@sheaf.updated_at |> Utils.Formatters.Time.human_friendly_time()).formatted_time %> (edited)
        <% end %>
      </div>
    </div>
    """
  end

  # TODO [SHEAF CRUD] this will contain the form!
  def current_draft_sheaf(assigns) do
    ~H"""
    <div>
      <.debug_dump label="ACCUMULATING MARKS FOR" sheaf={@sheaf} class="relative" />
      <.collapsible_marks_display
        myself={nil}
        marks_target={@event_target}
        marks={@marks}
        marks_ui={@marks_ui}
      />
    </div>
    """
  end
end
