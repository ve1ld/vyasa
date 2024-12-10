defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html
  alias Vyasa.Sangh.{Sheaf, Mark}
  alias VyasaWeb.CoreComponents
  alias VyasaWeb.Context.Components.UiState.Mark, as: MarkUiState
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState

  attr :sheaf, Sheaf, required: true
  attr :sheaf_ui, SheafUiState, required: true
  attr :marks_target, :string
  attr :myself, :any, required: true
  attr :container_class, :string, default: "", doc: "Injectable inline styling for the container"

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
      class={"transition-shadow duration-200 #{if @is_composite_member, do: "border-none", else: "border border-gray-100"} " <> @container_class}
    >
      <div
        id={"collapse-header-container-" <> @id}
        class={
        "flex items-center justify-between m-2 mb-3 p-2 pb-0 bg-brand-extra-light transition-colors duration-200 " <>
         if @sheaf_ui.marks_ui.is_expanded_view?, do: "border-t border-gray-200", else: ""
        }
      >
        <.action_toggle_button
          on_click={JS.push("ui::toggle_marks_display_collapsibility", value: %{value: ""})}
          flag={@sheaf_ui.marks_ui.is_expanded_view?}
          true_text=""
          false_text=""
          true_icon_name="hero-chevron-up"
          false_icon_name="hero-chevron-down"
          button_class="font-light flex items-center w-full hover:bg-brand-light hover:text-brand text-gray-600"
          icon_class="w-5 h-5 mr-2 text-brand-dark"
          phx-target={@marks_target}
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
        >
          <.icon name="hero-bookmark-solid" class="w-5 h-5 mr-2 text-brand" />
          <% num_marks = Enum.count(@sheaf.marks |> Enum.filter(&(&1.state == :live))) %>
          <span class="text-sm">
            <%= "#{num_marks} #{Inflex.inflect("mark", num_marks)}" %>
          </span>
        </.action_toggle_button>
        <.action_toggle_button
          :if={@sheaf_ui.marks_ui.is_expanded_view?}
          on_click={JS.push("ui::toggle_is_editable_marks?", value: %{value: ""})}
          flag={@sheaf_ui.marks_ui.is_editable_marks?}
          true_text="Done"
          false_text="Edit"
          button_class="font-light flex-grow space-x-2"
          icon_class="w-5 h-5 text-brand-dark cursor-pointer hover:bg-brand-accent hover:text-brand"
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
          phx-target={@marks_target}
        />
      </div>
      <div
        id={"collapsible-content-container-" <> @id}
        class={
          if @sheaf_ui.marks_ui.is_expanded_view?,
            do:
              "mt-2 transition-all duration-500 ease-in-out max-h-screen overflow-hidden rounded-b-lg bg-brand-light shadow-sm",
            else: "max-h-0 overflow-hidden"
        }
      >
        <div class="p-4 pt-0">
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
    <%= if @mark.state == :live do %>
      <div
        id={"mark-container-" <> @mark.id <> "-" <> @id}
        class="mb-2 bg-brand-light rounded-l-lg border-brandDark flex justify-between items-start"
      >
        <div
          id={"mark-content-container-" <> @mark.id <> "-" <> @id}
          class="h-full w-full flex-grow flex flex-col"
        >
          <.mark_content
            id={@id}
            mark={@mark}
            mark_ui={@mark_ui}
            is_editable?={@is_editable?}
            marks_target={@marks_target}
            sheaf_path_labels={@sheaf_path_labels}
          />
        </div>
      </div>
    <% end %>
    """
  end

  def mark_ordering_button_group(assigns) do
    ~H"""
    <div
      :if={@is_editable?}
      id={"mark-ordering-button-group-" <> @mark.id <> "-" <> @id}
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
    """
  end

  @doc """
  Toggles the edit / save mark body content changes within an editable mark display.
  The reason this is a little convoluted is because when submitting mark body changes,
  we are doing a pseudoform submit, via the client side. The use of the pseudoform allows
  us to nest an editable mark "form" within another form, thereby allowing us to do "nested forms"
  which are typically an antipattern at an HTML-level.

  WARNING::INCONVENIENT BUT data-target-selector NEEDS TO BE CORRECT, careful on refactors
  """
  def mark_body_change_action_button(assigns) do
    ~H"""
    <.action_toggle_button
      id={@id}
      flag={not @mark_ui.is_editing_content?}
      on_click={
        if not @mark_ui.is_editing_content? do
          "ui::toggle_is_editing_mark_content?"
        else
          JS.push("shim", value: %{})
        end
      }
      button_class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
      true_text="Edit"
      false_text="Save"
      true_icon_name="custom-icon-recent-changes-ltr"
      false_icon_name="hero-bookmark"
      phx-target={@marks_target}
      phx-value-mark_id={@mark.id}
      phx-value-sheaf_path_labels={@sheaf_path_labels}
      icon_class="w-3 h-3 text-brand-dark mr-1"
      text_class="text-xs"
      aria-label="Toggle edit mark body"
      phx-hook="PseudoForm"
      data-event-to-capture="click"
      data-target-selector={@mark |> get_mark_body_input_selector()}
      data-event-name="mark::editMarkContent"
      data-event-target={@marks_target}
      data-event-payload={
        Jason.encode!(%{
          "mark_id" => @mark.id,
          "previous_mark_body" => @mark.body,
          "sheaf_path_labels" => @sheaf_path_labels
        })
      }
    />
    """
  end

  @doc """
  Returns the selector that the mark body input has.
  Using this function should reduce the chances of unforced errors.
  This is an unfortunate outcome of doing the pseudoform approach.
  """
  def get_mark_body_input_selector(%Mark{id: id}) do
    get_mark_body_input_selector(id)
  end

  def get_mark_body_input_selector(mark_id) when is_binary(mark_id) do
    "#mark-body-" <> mark_id <> "-textarea"
  end

  # && !is_nil(@mark.binding.window) && @mark.binding.window.quote !== ""
  def mark_content(assigns) do
    ~H"""
    <div class="flex-grow">
      <%= if !is_nil(@mark) && !is_nil(@mark.binding)  do %>
        <.mark_quote mark={@mark} marks_target={@marks_target} />
      <% end %>
      <%= if is_binary(@mark.body) do %>
        <.mark_body
          id={"mark-body-" <> @mark.id}
          mark={@mark}
          mark_ui={@mark_ui}
          is_editable?={@is_editable?}
          marks_target={@marks_target}
          sheaf_path_labels={@sheaf_path_labels}
        />
      <% end %>
    </div>
    """
  end

  def mark_quote(assigns) do
    assigns =
      assign(assigns,
        quote_string:
          case assigns.mark do
            %{
              binding: %{
                window: %{
                  quote: quote
                }
              }
            } ->
              quote

            _ ->
              nil
          end
      )

    ~H"""
    <div class="relative p-4 py-1 px-4 sm:p-4 bg-aerospaceOrange/30 border-l-4 border-brandDark rounded-tl-lg rounded-tr-lg shadow-sm flex flex-col">
      <div class="flex justify-between items-start mb-2 w-full">
        <p :if={not is_nil(@quote_string)} class="text-sm italic text-secondary">
          "<%= @quote_string %>"
        </p>
        <button
          type="button"
          phx-click="navigate::visit_mark"
          phx-value-mark_id={@mark.id}
          phx-value-bind={@mark.binding_id}
          phx-target={@marks_target}
          class="flex items-center text-gray-600 hover:text-gray-800 flex-grow"
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
    <div class="relative xs:p-4 lg:p-2 border-l-4 border-brandDark rounded-bl-lg rounded-br-lg shadow-sm flex items-center">
      <!-- Left Button Group for Ordering a Mark -->
      <div :if={@is_editable?} class="flex-shrink-0">
        <.mark_ordering_button_group
          id={@id}
          mark={@mark}
          is_editable?={@is_editable?}
          marks_target={@marks_target}
        />
      </div>
      <!-- Textarea -->
      <textarea
        name="mark_body"
        disabled={not @mark_ui.is_editing_content?}
        id={@id <> "-textarea"}
        rows="1"
        phx-hook="TextareaAutoResize"
        class="flex-grow h-full
               focus:outline-none
               focus:ring-2 focus:ring-aerospaceOrange/30
               bg-transparent text-sm text-text
               placeholder-gray-600 resize-vertical
               overflow-auto min-h-[2.5rem] max-h-[8rem]
               p-2 border-0 border-b-2 border-b-gray-300
               transition-colors duration-200
               focus:border-b-red-600"
        placeholder="Edit your mark"
      >
        <%= @mark.body %>
      </textarea>
      <!-- Right Button Group for Editing a Mark -->
      <div :if={@is_editable?} class="flex-shrink-0 ml-2 h-full">
        <div
          id={"mark-edit-actions-button-group-" <> @mark.id <> "-" <> @id}
          class="h-full flex flex-col space-y-2 justify-between"
        >
          <.action_toggle_button
            on_click="mark::tombMark"
            true_text="Delete"
            true_icon_name="hero-x-mark"
            button_class="p-3 hover:bg-gray-200 rounded flex items-center justify-center"
            icon_class="w-3 h-3 text-brand-dark pr-1"
            text_class="text-xs"
            phx-target={@marks_target}
            phx-value-id={@mark.id}
          />
          <!-- Toggle Edit/Save Button -->
          <.mark_body_change_action_button
            id={@id}
            mark={@mark}
            mark_ui={@mark_ui}
            marks_target={@marks_target}
            sheaf_path_labels={@sheaf_path_labels}
          />
        </div>
      </div>
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
      focus_wrap_class="flex flex-col h-full shadow-xl overflow-scroll"
      inner_block_container_class="w-full p-6"
      close_button_icon_class="text-brand hover:text-red-700 w-8 h-8"
      close_button_class="p-0"
      close_button_icon="hero-x-circle-solid"
    >
      <:message_box>
        <h2 class="text-xl font-normal text-gray-800 pl-2">
          Make your post
        </h2>
      </:message_box>
      <div class="flex flex-col p-2 ">
        <.sheaf_summary
          :if={not is_nil(@reply_to)}
          id="sheaf-summary-reply-to"
          container_class="z-10 shadown-none bg-brandExtraLight"
          sheaf={@reply_to}
          action_buttons={[]}
          show_engagement_display={false}
        />
        <.replyto_context_display reply_to={@reply_to} event_target={@event_target} />
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

  # TODO: wire up the button events
  def replyto_context_display(assigns) do
    assigns =
      assigns
      |> assign(
        alternative_action:
          case is_nil(assigns.reply_to) do
            true ->
              CoreComponents.hide_modal(
                JS.push("navigate::see_discussion"),
                "sheaf-creator"
              )

            false ->
              "sheaf::clear_reply_to_context"
          end
      )
      |> assign(
        alternative_action_prompt:
          case is_nil(assigns.reply_to) do
            true -> "...post a reply?"
            false -> "...start a thread?"
          end
      )

    ~H"""
    <div class="whitespace-nowrap w-full flex flex-col sm:flex-row sm:items-center text-sm text-gray-500 font-light -ml-2 -mb-4 -mt-2 py-4 pl-4 pb-8 border-brand rounded-l-md border-2 border-r-0 z-5">
      <!-- Current Situation Indicator -->
      <div class="flex-grow">
        <%= if @reply_to do %>
          Replying <span class="italic font-semibold">@<%= @reply_to.signature %></span>
        <% else %>
          Starting a thread
        <% end %>
      </div>

      <button
        class="italic underline underline-offset-2 font-light whitespace-nowrap sm:ml-4 mt-2 sm:mt-0 self-end"
        phx-click={@alternative_action}
        phx-target={@event_target}
      >
        <%= @alternative_action_prompt %>
      </button>
    </div>
    """
  end

  def sheaf_creator_form(assigns) do
    assigns =
      assigns
      |> assign(
        textarea_placeholder:
          case is_nil(assigns.reply_to) do
            true -> "Post your thread..."
            false -> "Post your reply..."
          end
      )
      |> assign(
        action_button_text:
          case is_nil(assigns.reply_to) do
            true -> "Start thread"
            false -> "Reply"
          end
      )

    ~H"""
    <div id="sheaf-creator-container" class="flex flex-col">
      <.form
        for={%{}}
        phx-submit={CoreComponents.hide_modal(JS.push("sheaf::publish"), @id)}
        phx-target={@event_target}
        class="flex items-center"
      >
        <div class="flex flex-col w-full">
          <div class="shadow-sm border-1 border-l-2  rounded-lg border-brand">
            <textarea
              name="body"
              id={"sheaf-creator-form-body-textarea-" <> @id}
              phx-hook="TextareaFocus"
              phx-hook="TextareaAutoResize"
              class="w-full flex-grow focus:outline-none bg-brandExtraLight text-sm placeholder-gray-400 placeholder:font-light
    resize-vertical overflow-auto min-h-[2.5rem] max-h-[8rem] p-2 pt-3 border-tl-4 border-gray-300 rounded-tl-lg rounded-tr-lg transition-shadow duration-200 focus:border-brand focus:ring-0"
              placeholder={@textarea_placeholder}
            />

            <div class="flex justify-between p-2 pt-0 space-x-2 whitespace-nowrap">
              <div class="w-full text-sm">
                <label
                  for={"sheaf-creator-form-signature-textarea-" <> @id}
                  class="italic font-light text-gray-600 whitespace-nowrap"
                >
                  Signed by: @
                </label>
                <input
                  type="text"
                  name="signature"
                  id={"sheaf-creator-form-signature-textarea-" <> @id}
                  value={if @session, do: @session.name, else: ""}
                  class="font-medium underline p-0 flex-grow focus:outline-none bg-transparent text-sm text-light placeholder-gray-600 border-0 border-b-1 transition-shadow duration-200"
                  placeholder={if @session, do: "Session name", else: "Enter your signature..."}
                  disabled={not is_nil(@session) and @session.name}
                />
              </div>
            </div>
            <.collapsible_marks_display
              id={"nested-" <> @id}
              myself={nil}
              marks_target={@event_target}
              sheaf={@draft_sheaf}
              sheaf_ui={@draft_sheaf_ui}
              container_class="rounded-b-lg border-gray-100"
            />
          </div>
          <!-- start -->
          <div class="flex justify-around space-x-2 pt-4">
            <button
              type="button"
              phx-click={CoreComponents.hide_modal(@on_cancel_callback, @id)}
              class="whitespace-nowrap text-xs md:text-sm font-semibold flex items-center justify-center p-2 rounded-full border border-gray-400 text-gray-800 bg-transparent hover:bg-gray-100 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-brand focus:ring-opacity-50"
              phx-target={@event_target}
            >
              Go back
            </button>
            <button
              type="submit"
              class="whitespace-nowrap text-xs md:text-sm font-semibold flex items-center justify-center p-2 rounded-full border border-brand text-white bg-brand hover:bg-brand-light transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-brand focus:ring-opacity-50 w-auto"
              phx-target={@event_target}
              phx-value-is_new_thread={false}
            >
              <%= @action_button_text %>
            </button>
          </div>
          <!-- end -->
        </div>
      </.form>
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

  attr :show_engagement_display, :boolean,
    default: true,
    doc: "When true, displays the engagement buttons on the sheaf"

  attr :children, :list, default: [], doc: "The children of this sheaf"

  attr :container_class, :string, default: "", doc: "Inline class string that is injected"

  def sheaf_summary(assigns) do
    ~H"""
    <div class={
    "flex flex-col p-4 rounded-lg bg-brand-extra-light transition-shadow duration-200 " <>
    (if @is_composite_member, do: "pb-0", else: "border-l border-brand-light shadow-sm ") <>
    @container_class
    }>
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
        <div class="flex-grow">
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
          class="flex-grow h-full cursor-pointer opacity-0 min-w-[40%]"
          aria-label="Click to interact with signature"
        >
          hello world, i'm invisible
        </button>
        <!--<.action_toggle_button
          on_click={@on_set_reply_to}
          flag={@is_reply_to}
          true_text="Unpin"
          false_text="Pin"
          true_icon_name="custom-icon-material-symbols-pin-drop-filled"
          false_icon_name="custom-icon-material-symbols-pin-drop-empty"
          button_class="font-light flex items-center text-gray-600 hover:text-gray-800"
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
        />-->
      </div>
      <!-- Body Display -->
      <div class="mb-4 mt-3 text-md">
        <p class="text-brand-dark"><%= @sheaf.body || "EMPTY BODY" %></p>
      </div>
      <!-- Engagement Display -->
      <.sheaf_engagement_display
        :if={@show_engagement_display}
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
    <div class="w-auto flex text-sm text-gray-600 whitespace-nowrap items-baseline">
      <div class="mx-1 text-gray-800 font-medium">
        <p><%= @sheaf.signature %></p>
      </div>
      <!-- Time Display -->
      <div class="text-xs mx-1 font-light text-gray-500 italic">
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
      <!-- Show Replies Button -->
      <div :if={@replies_count > 0} class="flex-shrink-0">
        <.action_toggle_button
          on_click={@on_replies_click}
          flag={@sheaf_ui.is_expanded?}
          true_text="Hide "
          false_text="Show "
          true_icon_name="hero-chat-bubble-oval-left"
          false_icon_name="hero-chat-bubble-oval-left"
          button_class="font-light flex items-center text-gray-600 hover:text-gray-800"
          icon_class="h-4 w-4 mr-1"
          phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
        >
          <span class="text-sm">
            &nbsp<%= @replies_count %> <%= Inflex.inflect("reply", @replies_count) %>
          </span>
        </.action_toggle_button>
      </div>
      <!-- Share Button -->
      <.action_toggle_button
        on_click="bind::share"
        true_text="Share"
        icon_class="h-4 w-4 mr-1"
        true_icon_name="custom-icon-ph-share-fat-light"
        phx-value-node_id={@sheaf.id}
        phx-value-node={Vyasa.Sangh.Sheaf}
        phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
        button_class="font-light flex items-center text-gray-600 hover:text-gray-800 ml-2"
      />
      <!-- Reply Button -->
      <.action_toggle_button
        on_click={@on_quick_reply}
        true_text="Reply"
        true_icon_name="custom-icon-formkit-reply"
        button_class="font-light flex items-center text-gray-600 hover:text-gray-800 ml-2"
        icon_class="h-4 w-4 mr-1"
        phx-value-sheaf_path_labels={Jason.encode!(@sheaf |> Sheaf.get_path_labels() || [])}
      />
    </div>
    """
  end

  def floating_action_button(assigns) do
    ~H"""
    <div class="absolute bottom-20 right-4 z-50 transform">
      <button
        id="floating_action"
        class={[
          "bg-white/30 hover:bg-white/40 text-white rounded-full focus:outline-none transition-all duration-300 backdrop-blur-lg shadow-lg active:scale-95 flex items-center justify-center w-11 h-11 p-1 border border-white/20"
        ]}
        phx-click={@on_click}
        phx-target={@event_target}
      >
        <.icon
          name={@icon_name}
          class={"w-5 h-5 text-gray-500 hover:text-primaryAccent transition-colors duration-200 stroke-current stroke-2" <> @icon_class}
        />
      </button>
    </div>
    """
  end
end
