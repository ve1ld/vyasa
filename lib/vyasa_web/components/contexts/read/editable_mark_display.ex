defmodule VyasaWeb.Context.Read.EditableMarkDisplay do
  use VyasaWeb, :live_component
  alias Vyasa.Sangh.Mark

  @impl true
  def update(
        %{
          mark: %Mark{} = mark
        } =
          params,
        socket
      ) do
    IO.inspect(params, label: "TRACE: params passed to ReadContext")

    {
      :ok,
      socket
      |> assign(mark: mark)
    }
  end

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
          id="mark-container"
          class="mb-2 bg-brand-light rounded-lg shadow-sm p-1 border-l-2 border-brand flex justify-between items-start"
        >
          <div id="ordering-button-group" class="flex flex-col items-center">
            <button
              phx-click="dummy_event"
              phx-target={@myself}
              class="p-1 hover:bg-gray-200 rounded"
              aria-label="Up Arrow"
            >
              <.icon name="hero-chevron-up" class="w-4 h-4 text-brand-dark" />
            </button>
            <!-- Displaying Order -->
            <div class="mx-1 text-center text-md font-light"><%= @mark.order %></div>
            <button
              phx-click="dummy_event"
              phx-target={@myself}
              class="p-1 hover:bg-gray-200 rounded"
              aria-label="Down Arrow"
            >
              <.icon name="hero-chevron-down" class="w-4 h-4 text-brand-dark" />
            </button>
          </div>
          <div id="mark-content-container" class="flex-grow mx-2 pt-1">
            <%= if !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
              <span class="block mb-1 text-sm italic text-secondary">
                "<%= @mark.binding.window.quote %>"
              </span>
            <% end %>
            <%= if is_binary(@mark.body) do %>
              <span class="block text-sm text-text">
                <%= @mark.body %>
              </span>
            <% end %>
          </div>
          <div id="mark-edit-actions-button-group" class="flex flex-col ml-2 space-y-1">
            <button
              phx-click="dummy_event"
              phx-target={@myself}
              class="p-1 hover:bg-gray-200 rounded"
              aria-label="Delete"
            >
              <.icon name="hero-x-mark" class="w-5 h-5 text-brand-dark" />
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
