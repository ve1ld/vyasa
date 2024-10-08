defmodule VyasaWeb.Context.Read.EditableMarkDisplay do
  use VyasaWeb, :live_component
  alias Vyasa.Sangh.Mark
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:is_editing_content?, false)}
  end

  @impl true
  def update(
        %{
          mark: %Mark{} = mark,
          parent: parent
        } =
          params,
        socket
      ) do
    IO.inspect(params, label: "TRACE: params passed to ReadContext")

    {
      :ok,
      socket
      |> assign(mark: mark)
      |> assign(parent: parent)
    }
  end

  @impl true
  def handle_event(
        "toggle_is_editing_content?",
        _params,
        %Socket{
          assigns: %{
            is_editing_content?: _is_editing_content?
          }
        } = socket
      ) do
    {:noreply, socket |> update(:is_editing_content?, &(!&1))}
  end

  # TODO: wire up editable mark event handlers
  @impl true
  def handle_event("dummy_event", _params, socket) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.puts("Dummy event triggered")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-l border-brand-light pl-2">
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
                <.editable_mark_body
                  id={@mark.id}
                  is_editing_content?={@is_editing_content?}
                  body_content={@mark.body}
                />
              </div>
            <% end %>
          </div>
          <div
            id={"mark-edit-actions-button-group-" <> @mark.id}
            class="h-full flex flex-col ml-2 space-y-2 justify-between"
          >
            <.debug_dump
              mark_id={@mark.id}
              mark_order={@mark.order}
              mark_state={@mark.state}
              mark_verse_id={@mark.verse_id}
              class="relative"
            />
            <button
              phx-click="deleteMark"
              phx-target="#content-display"
              phx-value-mark_id={@mark.id}
              phx-value-verse_id={@mark.verse_id}
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

  attr :is_editing_content?, :boolean, required: true
  attr :id, :string, required: true
  attr :body_content, :string, required: true

  def editable_mark_body(assigns) do
    ~H"""
    <textarea
      name="editable-mark-body"
      disabled={not @is_editing_content?}
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
end
