defmodule VyasaWeb.Content.VerseMatrix do
  use VyasaWeb, :live_component
  alias Utils.Struct

  def mount(socket) do
    # TODO: add UI state vars here
    {:ok, assign(socket, foo: false)}
  end

  def update(%{verse: verse, marks: marks} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:verse, verse)
      |> assign(:marks, marks)

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
            <.verse_title_button verse_id={@verse.id} title={elem.title} />
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
              marks={@marks}
              quote={@verse.binding.window && @verse.binding.window.quote}
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
      phx-click={JS.push("clickVerseToSeek", value: %{verse_id: @verse_id})}
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
  attr :quote, :string, default: nil
  attr :marks, :list, default: []

  def quick_draft_container(assigns) do
    assigns = assigns |> assign(:elem_id, "comment-modal-#{Ecto.UUID.generate()}")

    ~H"""
    <div
      id="quick-draft-container"
      class="block mt-4 text-sm text-gray-700 font-serif leading-relaxed opacity-70 transition-opacity duration-300 ease-in-out hover:opacity-100"
    >
      <.bound_comments comments={@comments} />
      <.current_marks marks={@marks} />
      <.current_quote quote={@quote} />
      <.quick_draft_form />
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

  attr :marks, :list, default: []

  def current_marks(assigns) do
    ~H"""
    <div :for={mark <- @marks |> Enum.reverse()} :if={mark.state == :live}>
      <span
        :if={!is_nil(mark.binding.window) && mark.binding.window.quote !== ""}
        class="block
                 pl-1
                 ml-5
                 mb-2
                 border-l-4 border-primaryAccent
                 before:mr-5 before:text-gray-500"
      >
        <%= mark.binding.window.quote %>
      </span>
      <span
        :if={is_binary(mark.body)}
        class="block
                 before:mr-1 before:text-gray-500
                 lg:before:content-none
                 lg:border-l-0 lg:pl-2"
      >
        <%= mark.body %> - <b><%= "Self" %></b>
      </span>
    </div>
    """
  end

  attr :quote, :string, default: nil

  def current_quote(assigns) do
    ~H"""
    <span
      :if={!is_nil(@quote) && @quote !== ""}
      class="block
                 pl-1
                 ml-5
                 mb-2
                 border-l-4 border-gray-300
                 before:mr-5 before:text-gray-500"
    >
      <%= @quote %>
    </span>
    """
  end

  def quick_draft_form(assigns) do
    ~H"""
    <div id="mark-form-container" class="relative">
      <.form for={%{}} phx-submit="createMark">
        <input
          name="body"
          class="block w-full focus:outline-none rounded-lg border border-gray-300 bg-transparent p-2 pl-5 pr-12 text-sm text-gray-800"
          placeholder="Write here..."
          phx-focus={
            JS.push("verses::focus_toggle_on_quick_mark_drafting", value: %{is_focusing?: true})
          }
          phx-blur={
            JS.push("verses::focus_toggle_on_quick_mark_drafting", value: %{is_focusing?: false})
          }
          phx-window-blur={
            JS.push("verses::focus_toggle_on_quick_mark_drafting", value: %{is_focusing?: false})
          }
          phx-keyup="verses::focus_toggle_on_quick_mark_drafting"
        />
      </.form>
      <div class="absolute inset-y-0 right-2 flex items-center">
        <button class="flex items-center rounded-full bg-gray-200 p-1.5">
          <.icon name="hero-sun-mini" class="w-3 h-3 hover:text-primaryAccent hover:cursor-pointer" />
        </button>
      </div>
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
end
