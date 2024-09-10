defmodule VyasaWeb.Content.VerseMatrix do
  use VyasaWeb, :live_component
  alias Phoenix.LiveView.Socket

  alias Utils.Struct

  def mount(socket) do
    {:ok,
     socket
     |> assign(:show_current_marks?, false)
     |> assign(:form_type, :mark)}
  end

  def update(%{verse: verse, marks: marks, event_target: event_target} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:verse, verse)
      |> assign(:marks, marks)
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
              comments={@verse.comments}
              show_current_marks?={@show_current_marks?}
              marks={@marks}
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
          target: "#" <> @event_target,
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

  attr :comments, :list, default: []
  attr :event_target, :string, required: true
  attr :quote, :string, default: nil
  attr :marks, :list, default: []
  attr :show_current_marks?, :boolean, default: false
  attr :form_type, :atom, required: true
  attr :myself, :any

  def quick_draft_container(assigns) do
    assigns = assigns |> assign(:elem_id, "comment-modal-#{Ecto.UUID.generate()}")
    # TODO: i want a "current_comment"

    ~H"""
    <div
      id="quick-draft-container"
      class="block mt-4 text-sm text-gray-700 font-serif leading-relaxed opacity-70 transition-opacity duration-300 ease-in-out hover:opacity-100"
    >
      <.unified_quote_and_form
        event_target={@event_target}
        quote={@quote}
        form_type={@form_type}
        myself={@myself}
      />
      <.current_marks myself={@myself} marks={@marks} show_current_marks?={@show_current_marks?} />
      <.bound_comments comments={@comments} />
    </div>
    """
  end

  def bound_comments(assigns) do
    assigns = assigns |> assign(:elem_id, "comment-modal-#{Ecto.UUID.generate()}")

    ~H"""
    <span
      :for={comment <- @comments}
      class="block
                 before:content-['╰'] before:mr-1 before:text-gray-500
                 lg:before:content-none
                 lg:border-l-0 lg:pl-2"
    >
      <%= comment.body %> - <b><%= comment.signature %></b>
    </span>
    """
  end

  attr :quote, :string, required: true
  attr :event_target, :string, required: true
  attr :form_type, :atom, required: true
  attr :myself, :any, required: true

  def unified_quote_and_form(assigns) do
    ~H"""
    <div class="unified-container bg-brand-extra-light rounded-lg shadow-sm">
      <.current_quote quote={@quote} form_type={@form_type} />
      <.quick_draft_form
        event_target={@event_target}
        quote={@quote}
        form_type={@form_type}
        myself={@myself}
      />
    </div>
    """
  end

  # FIXME @ks0m1c qq: for current_marks below: when marks are in draft state, you'll help have a default container for it right
  # i need the invariant to be true: every mark has an associated container it is in, regardless of the state of the mark (draft or live or not)
  # yeah all marks are stored in this stack
  # if the stack becomes a list of lists
  # it is possible to have a single elemented list mark
  # so should be g

  attr :marks, :list, default: []
  attr :show_current_marks?, :boolean, default: true
  attr :myself, :any

  def current_marks(assigns) do
    ~H"""
    <div class="mb-4">
      <button
        phx-click={JS.push("toggle_show_current_marks", value: %{value: ""})}
        phx-target={@myself}
        class="w-full flex items-center justify-between p-2 bg-brand-extra-light rounded-lg shadow-sm hover:bg-brand-light hover:text-white transition-colors duration-200"
      >
        <div class="flex items-center">
          <.icon name="hero-bookmark" class="w-5 h-5 mr-2 text-brand" />
          <span class="text-sm font-medium text-brand-dark">
            <%= "#{Enum.count(@marks)} personal #{ngettext("mark", "marks", Enum.count(@marks))}" %>
          </span>
        </div>
        <.icon
          name={if @show_current_marks?, do: "hero-chevron-up", else: "hero-chevron-down"}
          class="w-5 h-5 text-brand-dark"
        />
      </button>

      <div class={if @show_current_marks?, do: "mt-2", else: "hidden"}>
        <div class="border-l border-brand-light pl-2">
          <%= for mark <- @marks |> Enum.reverse() do %>
            <%= if mark.state == :live do %>
              <div class="mb-2 bg-brand-light rounded-lg shadow-sm p-2 border-l-2 border-brand">
                <%= if !is_nil(mark.binding.window) && mark.binding.window.quote !== "" do %>
                  <span class="block mb-1 text-sm italic text-secondary">
                    "<%= mark.binding.window.quote %>"
                  </span>
                <% end %>
                <%= if is_binary(mark.body) do %>
                  <span class="block text-sm text-text">
                    <%= mark.body %> - <b class="text-brand-accent"><%= "Self" %></b>
                  </span>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
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
            Current <%= if @form_type == :mark, do: "mark", else: "comment" %>'s selection
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

  def quick_draft_form(assigns) do
    ~H"""
    <div class="p-2">
      <.form
        for={%{}}
        phx-submit={(@form_type == :mark && "createMark") || "createComment"}
        phx-target={"#" <> @event_target}
        class="flex items-center"
      >
        <input
          name="body"
          class="flex-grow focus:outline-none bg-transparent text-sm text-text placeholder-gray-600 mr-2"
          placeholder={"Type your #{if @form_type == :mark, do: "mark", else: "comment"} here..."}
          phx-focus={
            JS.push("verses::focus_toggle_on_quick_mark_drafting",
              target: "#" <> @event_target,
              value: %{is_focusing?: true}
            )
          }
          phx-blur={
            JS.push("verses::focus_toggle_on_quick_mark_drafting",
              target: "#" <> @event_target,
              value: %{is_focusing?: false}
            )
          }
          phx-window-blur={
            JS.push("verses::focus_toggle_on_quick_mark_drafting",
              target: "#" <> @event_target,
              value: %{is_focusing?: false}
            )
          }
          phx-keyup="verses::focus_toggle_on_quick_mark_drafting"
          phx-target={"#" <> @event_target}
        />
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
              value: %{type: if(@form_type == :mark, do: "comment", else: "mark")}
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
      </.form>
    </div>
    """
  end

  def comment_mark_separator(assigns) do
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

  def handle_event(
        "toggle_show_current_marks",
        %{"value" => _},
        %Socket{
          assigns:
            %{
              show_current_marks?: _show_current_marks?
            } = _assigns
        } = socket
      ) do
    {:noreply, update(socket, :show_current_marks?, &(!&1))}
  end

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
