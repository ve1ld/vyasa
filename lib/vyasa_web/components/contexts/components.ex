defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html
  alias Vyasa.Sangh.{Sheaf}
  alias VyasaWeb.CoreComponents
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState

  attr :sheaf, Sheaf, required: true
  attr :sheaf_ui, SheafUiState, required: true
  attr :marks_target, :string
  attr :myself, :any, required: true

  attr :is_composite_member, :boolean,
    default: false,
    doc: "When true, the collapsible marks display is a member of a larger component"

  attr :id, :string,
    default: "",
    doc: "An optional id suffix, to differentate intentionally duplicate components."

  def collapsible_marks_display(assigns) do
    ~H"""
    <div
      :if={not is_nil(@sheaf_ui.marks_ui)}
      class={"transition-shadow duration-200 #{if @is_composite_member, do: "border-none", else: "border border-gray-300"}"}
    >
      <div
        id={"collapse-header-container-" <> @id}
        class="flex items-baseline justify-between p-4 bg-brand-extra-light transition-colors duration-200"
      >
        <button
          phx-click={JS.push("ui::toggle_marks_display_collapsibility", value: %{value: ""})}
          phx-target={@marks_target}
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
          class="flex items-center w-full hover:bg-brand-light hover:text-brand text-gray-600"
          type="button"
        >
          <.icon
            name={
              if @sheaf_ui.marks_ui.is_expanded_view?,
                do: "hero-chevron-up",
                else: "hero-chevron-down"
            }
            class="w-5 h-5 mr-2 text-brand-dark"
          />
          <.icon name="hero-bookmark-solid" class="w-5 h-5 mr-2 text-brand" />
          <% num_marks = Enum.count(@sheaf.marks |> Enum.filter(&(&1.state == :live))) %>
          <span class="text-sm">
            <%= "#{num_marks} #{Inflex.inflect("mark", num_marks)}" %>
          </span>
        </button>
        <button
          :if={@sheaf_ui.marks_ui.is_expanded_view?}
          type="button"
          class="flex space-x-2 pr-2"
          phx-click={JS.push("ui::toggle_is_editable_marks?", value: %{value: ""})}
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
          phx-target={@marks_target}
        >
          <.icon
            name={
              if @sheaf_ui.marks_ui.is_editable_marks?,
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
          if @sheaf_ui.marks_ui.is_expanded_view?,
            do:
              "mt-2 transition-all duration-500 ease-in-out max-h-screen overflow-hidden rounded-b-lg bg-brand-light shadow-sm border-t border-gray-300",
            else: "max-h-0 overflow-hidden"
        }
      >
        <div class="p-4">
          <.mark_display
            :for={mark <- @sheaf.marks |> Enum.reverse()}
            id={@id}
            marks_target={@marks_target}
            sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
            mark={mark}
            mark_ui={
              @sheaf_ui.marks_ui.mark_id_to_ui
              |> Map.get(mark.id, MarkUiState.get_initial_ui_state())
            }
            myself={@marks_target}
            is_editable?={@sheaf_ui.marks_ui.is_editable_marks?}
          />
        </div>
      </div>
    </div>
    """
  end

  attr :mark, :any, required: true
  attr :mark_ui, :any, required: true
  attr :marks_target, :any, required: true
  attr :myself, :any
  attr :is_editable?, :boolean
  attr :sheaf_path_labels, :string, default: nil

  attr :id,
       :string,
       default: "",
       doc: "An optional id suffix, to differentate intentionally duplicate components."

  def mark_display(assigns) do
    ~H"""
    <div class="">
      <%= if @mark.state == :live do %>
        <div
          id={"mark-container-" <> @mark.id <> "-" <> @id}
          class="mb-2 bg-brand-light rounded-l-lg border-brandDark flex justify-between items-start"
        >
          <div
            :if={@is_editable?}
            id={"ordering-button-group-" <> @mark.id <> "-" <> @id}
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
            class="h-full w-full flex-grow flex flex-col"
          >
            <div class="flex justify-between items-start">
              <!-- Flex container for content and button -->
              <.mark_content mark={@mark} mark_ui={@mark_ui} id={@id} marks_target={@marks_target} />
            </div>
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
            <!-- Toggle Edit Button -->
            <%= if not @mark_ui.is_editing_content? do %>
              <button
                phx-click="ui::toggle_is_editing_mark_content?"
                type="button"
                phx-target={@marks_target}
                phx-value-mark_id={@mark.id}
                phx-value-sheaf_path_labels={@sheaf_path_labels}
                class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
                aria-label="Toggle edit mark body"
              >
                <.icon name="custom-icon-recent-changes-ltr" class="w-5 h-5 text-brand-dark" />
              </button>
            <% else %>
              <!-- Pseudo Submit Button -->
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
                    "previous_mark_body" => @mark.body,
                    "sheaf_path_labels" => @sheaf_path_labels
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

  def mark_content(assigns) do
    ~H"""
    <div class="flex-grow">
      <%= if !is_nil(@mark) && !is_nil(@mark.binding) && !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
        <.mark_quote mark={@mark} marks_target={@marks_target} />
      <% end %>
      <%= if is_binary(@mark.body) do %>
        <.mark_body id={@mark.id <> "-" <> @id} mark_ui={@mark_ui} mark={@mark} />
      <% end %>
    </div>
    """
  end

  def mark_quote(assigns) do
    ~H"""
    <div class="relative p-4 bg-aerospaceOrange/30 border-l-4 border-brandDark rounded-tl-lg rounded-tr-lg shadow-sm flex flex-col">
      <div class="flex justify-between items-start mb-2">
        <p class="text-sm italic text-secondary">
          "<%= @mark.binding.window.quote %>"
        </p>
        <button
          type="button"
          phx-click="navigate::visit_mark"
          phx-value-mark_id={@mark.id}
          phx-target={@marks_target}
          class="flex items-center text-gray-600 hover:text-gray-800"
          aria-label="Visit"
        >
          <.icon
            name="custom-icon-park-outline-quote-start"
            class="rotate-180 text-red-600 opacity-80"
          />
        </button>
      </div>
    </div>
    """
  end

  def mark_body(assigns) do
    ~H"""
    <div class="relative p-4 border-l-4 border-brandDark rounded-bl-lg rounded-br-lg shadow-sm">
      <textarea
        name="mark_body"
        disabled={not @mark_ui.is_editing_content?}
        id={"mark-body-" <> @id}
        rows="1"
        phx-hook="TextareaAutoResize"
        class="h-full w-full flex-grow focus:outline-none bg-transparent text-sm text-text placeholder-gray-600 resize-vertical overflow-auto min-h-[2.5rem] max-h-[8rem] p-2 border-0 border-b-2 border-b-gray-300 transition-colors duration-200 focus:border-b-red-600 focus:ring-0 focus:ring-red-600"
        placeholder="Edit your mark"
      >
        <%= @mark.body %>
      </textarea>
    </div>
    """
  end

  def sheaf_display(assigns) do
    ~H"""
    <div class={"border-l-2 border-gray-250 rounded-lg transition-all duration-200
      #{if @sheaf_ui.is_focused? || @is_reply_to, do: "bg-brandExtraLight shadow-lg", else: "shadow-sm"}"}>
      <.sheaf_summary
        id={"sheaf-summary-" <> @id}
        level={@level}
        is_reply_to={@is_reply_to}
        is_composite_member={true}
        sheaf={@sheaf}
        sheaf_ui={@sheaf_ui}
        children={@children}
        on_signature_deadspace_click={@on_replies_click}
        on_replies_click={@on_replies_click}
        on_set_reply_to={@on_set_reply_to}
        on_quick_reply={@on_quick_reply}
      />

      <%= if @sheaf.active do %>
        <.collapsible_marks_display
          is_composite_member={true}
          marks_target={@events_target}
          sheaf={@sheaf}
          sheaf_ui={@sheaf_ui}
          id={"marks-" <> @sheaf.id}
          myself={@events_target}
        />
      <% end %>
    </div>
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
          on_cancel_callback={JS.push("ui::toggle_show_sheaf_modal?", target: @event_target)}
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
        phx-submit={CoreComponents.hide_modal(JS.push("sheaf::publish"), @id)}
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
            sheaf={@draft_sheaf}
            sheaf_ui={@draft_sheaf_ui}
          />

          <div class="flex justify-between space-x-2">
            <button
              type="button"
              phx-click={CoreComponents.hide_modal(@on_cancel_callback, @id)}
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
          <.sheaf_summary
            id="sheaf-summary-reply-to"
            label="Responding to"
            sheaf={@sheaf}
            action_buttons={[]}
          />
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
  attr :id, :string,
    required: true,
    doc: "The id suffix that gets injected by the parent node of this function component"

  attr :is_reply_to, :boolean,
    default: false,
    doc: "Flag representing whether the sheaf is the current target for the reply_to context"

  attr :label, :string,
    default: nil,
    doc: "A string to serve as some label text to the sheaf being displayed"

  attr :level, :integer,
    default: 0,
    doc: "The level in our 3-leveled tree that this sheaf corresponds to"

  attr :sheaf, Sheaf, required: true, doc: "The Sheaf struct containing details."

  attr :sheaf_ui, SheafUiState,
    default: SheafUiState.get_initial_ui_state(),
    doc: "The Sheaf struct containing details."

  attr :action_buttons, :list, default: [], doc: "List of action button configurations."

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

  attr(:on_signature_deadspace_click, JS,
    default: %JS{},
    doc: "Defines a callback to invoke when the user clicks on the deadspace near the signature"
  )

  attr :is_composite_member, :boolean,
    default: false,
    doc: "When true, the sheaf summary is a member of a larger component"

  attr :children, :list, default: [], doc: "The children of this sheaf"

  def sheaf_summary(assigns) do
    ~H"""
    <div class={"flex flex-col p-4 rounded-lg bg-brand-extra-light transition-shadow duration-200
    #{if @is_composite_member, do: "pb-0", else: "border-l border-brand-light shadow-sm"}"}>
      <h2
        :if={@label}
        class="italic text-lg font-normal text-brand-dark pb-1 mb-1 border-b border-gray-400"
      >
        <%= @label %>
      </h2>
      <!-- Signature Display and Clickable Deadspace -->
      <div
        id={"level-" <> to_string(@level) <> "-sheaf-top-row-" <> @id <> "-" <> @sheaf.id}
        class="flex justify-between items-center"
      >
        <div class="flex-grow max-w-[50%]">
          <!-- Allow signature display to grow but limit to 80% -->
          <.sheaf_signature_display sheaf={@sheaf} />
        </div>
        <!-- Invisible Button as Clickable Deadspace -->
        <button
          :if={Enum.count(@children) > 0}
          id={"invisible-button-level-" <> to_string(@level) <> "-sheaf-top-row-" <> @id <> "-" <> @sheaf.id}
          type="button"
          phx-click={@on_signature_deadspace_click}
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
          class="flex-grow h-full cursor-pointer opacity-0"
          aria-label="Click to interact with signature"
        >
          hello world, i'm invisible
        </button>

        <button
          type="button"
          phx-click={@on_set_reply_to}
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
          class="flex items-center text-gray-600 hover:text-gray-800"
        >
          <%= if @is_reply_to do %>
            <.icon name="custom-icon-material-symbols-pin-drop-filled" class="h-5 w-5 mr-1" />
            <span class="text-sm">Unpin</span>
          <% else %>
            <.icon name="custom-icon-material-symbols-pin-drop-empty" class="h-5 w-5 mr-1" />
            <span class="text-sm">Pin</span>
          <% end %>
        </button>
      </div>
      <!-- Body Display -->
      <div class="mb-4 mt-3">
        <p class="text-brand-dark"><%= @sheaf.body || "EMPTY BODY" %></p>
      </div>
      <!-- Engagement Display -->
      <.sheaf_engagement_display
        sheaf={@sheaf}
        sheaf_ui={@sheaf_ui}
        replies_count={@children |> Enum.count()}
        on_replies_click={@on_replies_click}
        on_set_reply_to={@on_set_reply_to}
        on_quick_reply={@on_quick_reply}
      />
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
    assigns =
      assigns
      |> assign(
        edited_suffix:
          cond do
            assigns.sheaf.inserted_at < assigns.sheaf.updated_at ->
              "(edited)"

            true ->
              ""
          end
      )

    ~H"""
    <div class="w-auto flex mt-2 text-sm text-gray-600">
      <div class="mx-1 text-gray-800 font-semibold">
        <p><%= @sheaf.signature %></p>
      </div>
      <!-- Time Display -->
      <div class="mx-1 text-gray-500 italic">
        <%= (@sheaf.inserted_at |> Utils.Formatters.Time.friendly()).formatted_time <> @edited_suffix %>
      </div>
    </div>
    """
  end

  attr :replies_count, :integer, default: 0
  attr :sheaf, Sheaf, required: true, doc: "the sheaf that we are referring to"

  attr :sheaf_ui, SheafUiState,
    default: SheafUiState.get_initial_ui_state(),
    doc: "corresponding UI struct for the sheaf"

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

  def sheaf_engagement_display(assigns) do
    ~H"""
    <div class="flex justify-between mt-2">
      <div class="flex">
        <!-- Show Replies Button -->
        <div :if={@replies_count > 0} class="flex-shrink-0 w-32">
          <button
            type="button"
            phx-click={@on_replies_click}
            phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
            class="flex items-center text-gray-600 hover:text-gray-800"
          >
            <.icon name="hero-chat-bubble-oval-left" class="h-4 w-4 mr-1" />
            <span class="text-sm">
              <%= if @sheaf_ui.is_expanded? do %>
                Hide
              <% else %>
                Show
              <% end %>
              <%= @replies_count %> <%= Inflex.inflect("reply", @replies_count) %>
            </span>
          </button>
        </div>
        <!-- Share Button -->
        <button
          type="button"
          phx-click="sheaf::share_sheaf"
          phx-target="#content-display"
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
          class="flex items-center text-gray-600 hover:text-gray-800 ml-2"
        >
          <.icon name="custom-icon-ph-share-fat-light" class="h-4 w-4 mr-1" />
          <span class="text-sm">Share</span>
        </button>
      </div>
      <!-- Reply Button -->
      <button
        type="button"
        phx-click={@on_quick_reply}
        phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
        class="flex items-center text-gray-600 hover:text-gray-800 ml-2"
      >
        <.icon name="custom-icon-formkit-reply" class="h-4 w-4 mr-1" />
        <span class="text-sm">Reply</span>
      </button>
    </div>
    """
  end
end
