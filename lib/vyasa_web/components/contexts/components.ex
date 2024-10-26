defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html
  alias Vyasa.Sangh.{Sheaf}
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState

  attr :marks, :list, default: []
  attr :marks_ui, MarksUiState, required: true
  attr :marks_target, :string
  attr :myself, :any, required: true

  attr :id, :string,
    default: "",
    doc: "An optional id suffix, to differentate intentionally duplicate components."

  def collapsible_marks_display(assigns) do
    ~H"""
    <!-- <.debug_dump label="Collapsible Marks Dump" class="relative" marks_ui={@marks_ui} /> -->
    <div :if={not is_nil(@marks_ui)} class="mb-4">
      <div
        id={"collapse-header-container-" <> @id}
        class="flex items-baseline justify-between p-2 bg-brand-extra-light rounded-lg shadow-sm transition-colors duration-200"
      >
        <button
          phx-click={JS.push("ui::toggle_marks_display_collapsibility", value: %{value: ""})}
          phx-target={@marks_target}
          class="flex items-center w-full hover:bg-brand-light hover:text-brand"
          type="button"
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
          type="button"
          class="flex space-x-2 pr-2"
          phx-click={JS.push("ui::toggle_is_editable_marks?", value: %{value: ""})}
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
        id={"collapsible-content-container-" <> @id}
        class={
          if @marks_ui.is_expanded_view?,
            do: "mt-2 transition-all duration-500 ease-in-out max-h-screen overflow-scroll",
            else: "max-h-0 overflow-scroll"
        }
      >
        <.mark_display
          :for={mark <- @marks |> Enum.reverse()}
          id={@id}
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

  attr :id,
       :string,
       default: "",
       doc: "An optional id suffix, to differentate intentionally duplicate components."

  def mark_display(assigns) do
    ~H"""
    <!-- <.debug_dump class="relative" mark_ui={@mark_ui} is_editable?={@is_editable?} />-->
    <div class="border-l border-brand-light pl-2">
      <%= if @mark.state == :live do %>
        <div
          id={"mark-container-" <>
          @mark.id <> "-" <> @id}
          class="mb-2 bg-brand-light rounded-lg shadow-sm p-1 border-l-2 border-brand flex justify-between items-start"
        >
          <div
            :if={@is_editable?}
            id={"ordering-button-group-"<> @mark.id <> "-" <> @id}
            class="flex flex-col items-center"
          >
            <button
              phx-click="dummy_event"
              phx-target={@marks_target}
              class="p-1 hover:bg-gray-200 rounded"
              aria-label="Up Arrow"
              type="button"
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
              type="button"
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
          <div
            id={"mark-content-container-" <> @mark.id <> "-" <> @id}
            class="h-full w-full flex-grow mx-2 pt-2"
          >
            <%= if !is_nil(@mark) && !is_nil(@mark.binding) && !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
              <span class="block mb-1 text-sm italic text-secondary">
                "<%= @mark.binding.window.quote %>"
              </span>
            <% end %>
            <%= if is_binary(@mark.body) do %>
              <div class="flex-grow h-full">
                <.mark_body id={@mark.id <> "-" <> @id} mark_ui={@mark_ui} body_content={@mark.body} />
              </div>
            <% end %>
          </div>
          <div
            :if={@is_editable?}
            id={"mark-edit-actions-button-group-" <> @mark.id <> "-" <> @id}
            class="h-full flex flex-col ml-2 space-y-2 justify-between"
          >
            <button
              phx-click="mark::tombMark"
              type="button"
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
                phx-click="ui::toggle_is_editing_mark_content?"
                type="button"
                phx-target={@marks_target}
                phx-value-mark_id={@mark.id}
                class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
                aria-label="Toggle edit mark body"
              >
                <.icon name="custom-icon-recent-changes-ltr" class="w-5 h-5 text-brand-dark" />
              </button>
            <% else %>
              <!-- pseudo submit button -->
              <button
                id={"pseudo-submit-" <> @mark.id <> "-" <> @id }
                type="button"
                class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
                phx-click={JS.push("shim", value: %{})}
                phx-hook="PseudoForm"
                data-event-to-capture="click"
                data-target-selector={"#mark-body-" <> @mark.id <> "-" <> @id}
                data-event-name="mark::editMarkContent"
                data-event-target={@marks_target}
                data-event-payload={
                  Jason.encode!(%{
                    "mark_id" => @mark.id,
                    "previous_mark_body" => @mark.body
                  })
                }
                aria-label="Edit mark body"
              >
                <.icon name="hero-bookmark" class="w-5 h-5 text-brand-dark" />
              </button>
            <% end %>
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

  attr :draft_sheaf, Sheaf,
    required: false,
    doc: "This is the draft sheaf, for which we are currently accumulating marks"

  attr :draft_sheaf_ui, SheafUiState,
    required: false,
    doc: "This is the draft sheaf ui, for which we are currently accumulating marks"

  attr :reply_to, Sheaf, required: false, doc: "Refers to the sheaf that we are replying to"

  attr :reply_to_ui, SheafUiState,
    default: SheafUiState.get_initial_ui_state(),
    doc: "Corresponding ui state for the reply to sheaf"

  attr :session, VyasaWeb.Session,
    default: nil,
    doc: "Refers to the currently initialised sangh session"

  # TODO: the reply_to should probably just be a binding since we can reply to any binding
  attr :event_target, :string, required: true

  def sheaf_creator_modal(assigns) do
    ~H"""
    <.generic_modal_wrapper
      id={"modal-wrapper-" <> @id}
      show={@draft_sheaf_ui.marks_ui.show_sheaf_modal?}
      on_cancel_callback={JS.push("ui::toggle_show_sheaf_modal?", target: @event_target)}
      on_click_away_callback={JS.push("ui::toggle_show_sheaf_modal?", target: @event_target)}
      window_keydown_callback={JS.push("ui::toggle_show_sheaf_modal?", target: @event_target)}
      container_class="rounded-lg shadow-lg overflow-scroll"
      background_class="bg-gray-800 bg-opacity-30 backdrop-blur-lg"
      dialog_class="rounded-lg flex flex-col max-w-lg max-h-screen mx-auto my-auto overflow-scroll"
      focus_wrap_class="flex flex-col h-full shadow-xl"
      inner_block_container_class="w-full p-6"
      close_button_icon_class="text-red-500 hover:text-red-700"
    >
      <div class="flex flex-col p-6">
        <.replyto_context sheaf={@reply_to} />
        <.sheaf_creator_form
          session={@session}
          id={@id}
          draft_sheaf={@draft_sheaf}
          draft_sheaf_ui={@draft_sheaf_ui}
          reply_to={@reply_to}
          event_target={@event_target}
          on_cancel_callback={JS.push("ui::toggle_show_sheaf_modal?", target: "#content-display")}
        />
      </div>
    </.generic_modal_wrapper>
    """
  end

  def sheaf_creator_form(assigns) do
    ~H"""
    <div id="sheaf-creator-container" class="flex flex-col">
      <.form
        for={%{}}
        phx-submit={JS.push("sheaf::publish")}
        phx-target={@event_target}
        class="flex items-center"
      >
        <div class="flex flex-col w-full">
          <textarea
            name="body"
            id={"sheaf-creator-form-body-textarea-"<> @id}
            phx-hook="TextareaAutoResize"
            class="flex-grow focus:outline-none bg-transparent text-sm text-text placeholder-gray-600 resize-vertical overflow-auto min-h-[2.5rem] max-h-[8rem] p-2 border-t-0 border-l-0 border-r-0 border-b-1 border-b-gray-300"
            placeholder="Type your Sheaf body here..."
          />

          <div class="flex justify-between mt-2 space-x-2">
            <!-- Checkbox for is_private -->
            <div class="flex items-center m-2">
              <.input
                type="checkbox"
                name="is_private"
                id="is_private"
                label="Private comment?"
                class="mx-1"
              />
            </div>
            <div>
              <label
                for={"sheaf-creator-form-signature-textarea-" <> @id}
                class="mb-2 text-sm font-medium text-gray-600"
              >
                Signed by:
              </label>
              <input
                type="text"
                name="signature"
                id={"sheaf-creator-form-signature-textarea-" <> @id}
                value={if @session, do: @session.name, else: ""}
                class="flex-grow focus:outline-none bg-transparent text-sm text-text placeholder-gray-600 p-2 border-t-0 border-l-0 border-r-0 border-b-1 border-b-gray-300"
                placeholder={if @session, do: "Session name", else: "Enter your signature..."}
                disabled={not is_nil(@session) and @session.name}
              />
            </div>
          </div>

          <.collapsible_marks_display
            id={"nested-"<> @id}
            myself={nil}
            marks_target={@event_target}
            marks={@draft_sheaf.marks}
            marks_ui={@draft_sheaf_ui.marks_ui}
          />

          <div class="flex justify-between space-x-2">
            <button
              type="button"
              phx-click={@on_cancel_callback}
              class="w-2/5 text-bold mt-4 flex items-center justify-center p-3 rounded-full border-2 border-brand text-grey-800 bg-brand-dark hover:bg-brand-light transition-colors duration-200 shadow-lg hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-brand focus:ring-opacity-50"
              phx-target={@event_target}
            >
              Cancel and go back
            </button>
            <button
              type="submit"
              class="w-2/5 text-bold mt-4 flex items-center justify-center p-3 rounded-full border-2 border-brand text-brand bg-white hover:bg-brand-light transition-colors duration-200 shadow-lg hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-brand focus:ring-opacity-50 space-x-2"
              phx-target={@event_target}
            >
              <.icon name="hero-plus-circle" class="w-5 h-5 mr-2" /> Submit
            </button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  # TODO: add nav action buttons
  def replyto_context(assigns) do
    ~H"""
    <div class="overflow-auto">
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
  A brief view of a sheaf, showing the contextually relevant information about it.
  Shows a barebones, brief summary of a sheaf, which gives just enough context for someone to
  understand it.

  Some key information:
  1. Sheaf body -- what are they saying?
  2. Sheaf Signature display -- who signed it and when did they do so?
  3. [FUTURE] Engagement Icons -- displays info about engagement (e.g. 12 replies)
  4. [FUTURE] Possible Quick Action buttons -- "reply to"
  """
  attr :label, :string,
    default: nil,
    doc: "A string to serve as some label text to the sheaf being displayed"

  attr :level, :integer,
    default: 0,
    doc: "The level in our 3-leveled tree that this sheaf corresponds to"

  attr :sheaf, Sheaf, required: true, doc: "The Sheaf struct containing details."
  attr :action_buttons, :list, default: [], doc: "List of action button configurations."

  def sheaf_summary(assigns) do
    ~H"""
    <div class="flex flex-col border-l border-brand-light p-4 rounded-lg shadow-sm bg-brand-extra-light">
      <h2
        :if={@label}
        class="italic text-lg font-normal text-brand-dark pb-1 mb-1 border-b border-gray-400"
      >
        <%= @label %>
      </h2>
      <!-- Signature Display -->
      <.sheaf_signature_display sheaf={@sheaf} />
      <!-- Body Display -->
      <div class="mb-4 mt-3">
        <!-- Added margin for vertical spacing -->
        <p class="text-brand-dark"><%= @sheaf.body || "EMPTY BODY" %></p>
      </div>
      <!-- Engagement Display -->
      <.sheaf_engagement_display sheaf={@sheaf} sheaf_ui={nil} replies_count={3} />
      <!-- Action Button Group -->
      <div class="flex justify-between items-center mt-2">
        <div class="flex space-x-2">
          <%= for {icon, action} <- @action_buttons do %>
            <button
              type="button"
              phx-click={action}
              class="flex items-center text-blue-500 hover:text-blue-700"
            >
              <.icon name={icon} class="h-5 w-5 mr-1" />
              <span>Action</span>
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
      <div class="mx-1 text-gray-800 font-semibold">
        <p><%= @sheaf.signature %></p>
      </div>
      <!-- Time Display -->
      <div class="mx-1 text-gray-500 italic">
        <%= if is_nil(@sheaf.updated_at) do %>
          <%= (@sheaf.inserted_at |> Utils.Formatters.Time.friendly()).formatted_time %>
        <% else %>
          <%= (@sheaf.updated_at |> Utils.Formatters.Time.friendly()).formatted_time %> (edited)
        <% end %>
      </div>
    </div>
    """
  end

  attr :replies_count, :integer, default: 0
  attr :sheaf, Sheaf, required: true, doc: "the sheaf that we are referring to"
  attr :sheaf_ui, :any, default: "", doc: "corresponding UI struct for the sheaf"

  attr(:on_replies_click, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the replies button is clicked."
  )

  attr(:on_set_reply_to, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the reply-to button is clicked."
  )

  def sheaf_engagement_display(assigns) do
    ~H"""
    <div class="flex space-x-4 mt-2 justify-between">
      <button
        type="button"
        phx-click={@on_replies_click}
        class="flex items-center text-gray-600 hover:text-gray-800"
      >
        <.icon name="hero-chat-bubble-oval-left" class="h-4 w-4 mr-1" />
        <span class="text-sm">Show <%= @replies_count %> Replies</span>
      </button>

      <button
        type="button"
        phx-click={@on_set_reply_to}
        class="flex items-center text-gray-600 hover:text-gray-800"
      >
        <.icon name="custom-icon-formkit-reply" class="h-4 w-4 mr-1" />
        <span class="text-sm">Reply</span>
      </button>
    </div>
    """
  end
end
