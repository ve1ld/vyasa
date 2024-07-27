defmodule VyasaWeb.DraftMatrix do
  use VyasaWeb, :live_component

  @impl true
  def update(assigns, socket) do
    assigns = Enum.reject(assigns, fn {_k, v} -> is_nil(v) or v == [] end)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> assign_new(:marks, fn -> [] end)
      |> assign_new(:custom_style, fn -> [] end)}
  end

  @impl true
  def handle_event("adjust", adjusted, socket) do
    style = Enum.map(adjusted, fn {key, val} ->
      "#{key}: #{val}"
    end)

    {:noreply, assign(socket, custom_style: style)}
  end

  @doc """
  Renders a marginote w action slots for interaction with marginote
  """
  @impl true
  def render(assigns) do
    ~H"""
      <header class={["absolute z-50 shadow-sm", @actions != [] && "marginote"]} id={@id}
        style={["max-width: calc(-24px + 100vw)", @custom_style] |> List.flatten() |> Enum.join(";")}>
       <.form for={%{}} phx-submit="create_mark">
          <input
            name="body"
            class="block lg:w-[80%] md:w-96 rounded-lg border border-gray-200 bg-gray-50 p-2 pl-5 text-sm text-gray-800"
            placeholder="Write here..."
          />
       </.form>
      </header>
      """
  end
end
