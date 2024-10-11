defmodule VyasaWeb.Context.Read.VerseMatrix do
  use VyasaWeb, :live_component
  alias Phoenix.LiveView.Socket
  alias Utils.Struct

  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState

  import VyasaWeb.Context.Components

  def mount(socket) do
    {:ok,
     socket
     |> assign(:show_current_marks?, false)
     |> assign(:form_type, :mark)}
  end

  def update(
        %{verse: verse, marks_ui: marks_ui, marks: marks, event_target: event_target} = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:verse, verse)
      |> assign(:marks, marks)
      |> assign(:marks_ui, marks_ui)
      |> assign(:event_target, event_target)

    {:ok, socket}
  end

  slot :edge, required: true do
    attr :title, :string
    attr :field, :list, required: true
    attr :verseup, :any, required: true
    attr :node, :any
  end

  def render(assigns) do
    ~H"""
    <div id={"verse-#{@verse.id}"} class="scroll-m-20 mt-8 p-4 border-b-2 border-brandDark" id={@id}>
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={elem <- @edge} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt :if={Map.has_key?(elem, :title)} class="w-1/12 flex-none text-zinc-500">
            <.verse_title_button verse_id={@verse.id} title={elem.title} event_target={@event_target} />
          </dt>
          <div class="relative">
            <.verse_content
              verse_id={@verse.id}
              node={Map.get(elem, :node, @verse).__struct__}
              node_id={Map.get(elem, :node, @verse).id}
              field={elem.field |> Enum.join("::")}
              verseup={elem.verseup}
              content={Struct.get_in(Map.get(elem, :node, @verse), elem.field)}
            />
            <.quick_draft_container
              :if={is_elem_bound_to_verse(@verse, elem)}
              sheafs={@verse.sheafs}
              marks={@marks}
              marks_ui={@marks_ui}
              quote={@verse.binding.window && @verse.binding.window.quote}
              form_type={@form_type}
              myself={@myself}
              event_target={@event_target}
            />
          </div>
        </div>
      </dl>
    </div>
    """
  end

  def verse_title_button(assigns) do
    ~H"""
    <button
      phx-click={
        JS.push("clickVerseToSeek",
          target: @event_target,
          value: %{verse_id: @verse_id}
        )
      }
      class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
    >
      <div class="font-dn text-xl sm:text-2xl mb-4">
        <%= @title %>
      </div>
    </button>
    """
  end

  def verse_content(assigns) do
    ~H"""
    <dd
      verse_id={@verse_id}
      node={@node}
      node_id={@node_id}
      field={@field}
      class={"text-zinc-700 #{verse_class(@verseup)}"}
    >
      <%= @content %>
    </dd>
    """
  end

  attr :sheafs, :list, default: []
  attr :event_target, :string, required: true
  attr :quote, :string, default: nil
  attr :marks, :list, default: []
  attr :marks_ui, MarksUiState, required: true
  attr :is_editable_marks?, :boolean, default: false
  attr :form_type, :atom, required: true
  attr :myself, :any

  # TODO: consider merging this with the sheaf container
  # TODO: instead of showing all sheafs, this should only be showing currently selected sheaf
  def quick_draft_container(assigns) do
    assigns = assigns |> assign(:elem_id, "sheaf-modal-#{Ecto.UUID.generate()}")

    ~H"""
    <div
      id="quick-draft-container"
      class="block mt-4 text-sm text-gray-700 font-serif leading-relaxed opacity-70 transition-opacity duration-300 ease-in-out hover:opacity-100"
    >
      <div class="unified-container bg-brand-extra-light rounded-lg shadow-sm">
        <.current_quote quote={@quote} form_type={@form_type} />
        <.quick_draft_form
          event_target={@event_target}
          quote={@quote}
          form_type={@form_type}
          myself={@myself}
        />
      </div>
      <.collapsible_marks_display
        myself={@myself}
        marks_target={@event_target}
        marks={@marks}
        marks_ui={@marks_ui}
      />
      <.sheaf_display :for={sheaf <- @sheafs} sheaf={sheaf} />
    </div>
    """
  end

  attr :quote, :string, required: true
  attr :form_type, :atom, required: true

  def current_quote(assigns) do
    ~H"""
    <%= if !is_nil(@quote) && @quote !== "" do %>
      <div class="p-2 border-b border-brand">
        <div class="flex items-center mb-1">
          <.icon
            name={
              if @form_type == :mark,
                do: "hero-bookmark-solid",
                else: "hero-chat-bubble-left-ellipsis-solid"
            }
            class="w-4 h-4 text-brand mr-2"
          />
          <span class="text-xs text-secondary">
            Current <%= if @form_type == :mark, do: "mark", else: "sheaf" %>'s selection
          </span>
        </div>
        <div class="text-sm italic text-secondary">
          "<%= @quote %>"
        </div>
      </div>
    <% end %>
    """
  end

  attr :form_type, :atom, required: true
  attr :event_target, :string, required: true
  attr :myself, :any, required: true
  attr :quote, :string, default: nil

  # FIXME 1: the text area will have enter button pressed for new line ==> so the onpress handlers need to change to not trigger wrongly
  # FIXME 2: I can put multiline inputs in the textarea but the stored string ends up removing the newlines -- why?
  def quick_draft_form(assigns) do
    ~H"""
    <div class="p-2">
      <.form
        for={%{}}
        phx-submit={(@form_type == :mark && "createMark") || "createSheaf"}
        phx-target={@event_target}
        class="flex items-center"
      >
        <textarea
          name="body"
          rows="1"
          id="quick-draft-form-textarea"
          phx-hook="TextareaAutoResize"
          class="flex-grow focus:outline-none bg-transparent text-sm text-text placeholder-gray-600 resize-vertical overflow-auto min-h-[2.5rem] max-h-[8rem] p-2 border-t-0 border-l-0 border-r-0 border-b-2 border-b-gray-300"
          placeholder={"Type your #{if @form_type == :mark, do: "mark", else: "sheaf"} here..."}
          phx-focus={
            JS.push("verses::focus_toggle_on_quick_mark_drafting",
              target: @event_target,
              value: %{is_focusing?: true}
            )
          }
          phx-blur={
            JS.push("verses::focus_toggle_on_quick_mark_drafting",
              target: @event_target,
              value: %{is_focusing?: false}
            )
          }
          phx-window-blur={
            JS.push("verses::focus_toggle_on_quick_mark_drafting",
              target: @event_target,
              value: %{is_focusing?: false}
            )
          }
          phx-keyup="verses::focus_toggle_on_quick_mark_drafting"
          phx-target={@event_target}
        />
        <div class="flex items-center ml-2">
          <button
            type="submit"
            class="p-1 rounded-full hover:bg-brand-dark transition-colors duration-200"
          >
            <.icon name="hero-paper-airplane" class="w-4 h-4 text-brand" />
          </button>
          <button
            type="button"
            phx-click={
              JS.push("change_form_type",
                value: %{type: if(@form_type == :mark, do: "sheaf", else: "mark")}
              )
            }
            phx-target={@myself}
            class="p-1 rounded-full text-gray-400 hover:text-brand transition-colors duration-200 ml-1"
          >
            <.icon
              name={
                if @form_type == :mark,
                  do: "hero-chat-bubble-left-ellipsis-solid",
                  else: "hero-bookmark-solid"
              }
              class="w-4 h-4"
            />
          </button>
        </div>
      </.form>
    </div>
    """
  end

  ## these are working on some formatting ui feedbackplays hmm
  def sheaf_mark_separator(assigns) do
    ~H"""
    <span class="text-primaryAccent flex items-center justify-center">
      ☙ ——— ›– ❊ –‹ ——— ❧
    </span>
    """
  end

  defp verse_class({:big, script}), do: "font-#{script} text-lg sm:text-xl"
  defp verse_class(:mid), do: "font-dn text-m"

  defp is_elem_bound_to_verse(verse, edge_elem) do
    verse.binding &&
      (verse.binding.node_id == Map.get(edge_elem, :node, verse).id &&
         verse.binding.field_key == edge_elem.field)
  end

  # def handle_event(
  #       "toggle_is_editable_marks?",
  #       %{"value" => _},
  #       %Socket{
  #         assigns:
  #           %{
  #             marks_ui: %MarksUiState{} = ui_state
  #           } = _assigns
  #       } = socket
  #     ) do
  #   {:noreply,
  #    socket
  #    |> assign(marks_ui: ui_state |> MarksUiState.toggle_is_editable())}
  # end
  def handle_event("change_form_type", %{"type" => type}, socket) do
    new_form_type = String.to_existing_atom(type)
    {:noreply, assign(socket, :form_type, new_form_type)}
  end

  def handle_event(
        _,
        _,
        %Socket{} = socket
      ) do
    IO.puts("WARNING: verse_matrix pokemon for handle_event")

    {:noreply, socket}
  end
end
