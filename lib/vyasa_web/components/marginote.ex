defmodule VyasaWeb.Marginote do
  use VyasaWeb, :live_component

  @impl true
  def update(assigns, socket) do
    assigns = Enum.reject(assigns, fn {_k, v} -> is_nil(v) or v == [] end)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> assign_new(:comments, fn -> [] end)
      |> assign_new(:custom_style, fn -> [] end)
      |> assign_new(:display, fn -> "hidden" end)
      |> assign_new(:class, fn -> "" end)}
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
      <header class={["absolute z-50 shadow-sm", @actions != [] && "marginote", @class, @display]} id={@id}
        style={["max-width: calc(-24px + 100vw)", @custom_style] |> List.flatten() |> Enum.join(";")}
        data-marginote-id={Map.get(@last_created_comment, :id)}
        data-marginote="parent">
        <div
          class="origin-top w-full flex overflow-hidden relative text-black bg-white rounded-md shadow-md flex flex-col w-64 h-full"
          style="max-width: calc(-12px + 100vw)">
          <div class="grow flex pt-3 py-4 relative">
            <div class="m-0">
              <div :for={c <- @comments} id={c.id} class="first:mt-0 mt-2 border-b border-gray-600 last:border-0 px-4 py-1">
                <div class="flex items-center">
                  <img
                    src="https://picsum.photos/50/50"
                    class="p-0 m-0 mr-2 flex h-6 w-6 rounded-full object-cover border-none border-red-900"
                    onerror="this.src='/images/default_hand.jpg';"
                  />
                  <span class="ml-2 font-bold text-md">@<%= c.initiator.username %></span>
                  <span class="ml-2 font-italic text-xs text-gray-500"><%= Timex.from_now(c.inserted_at) %></span>
                </div>
                <div class="mt-3 pl-8">
                  <div class="flex">
                    <div class="w-1 bg-yellow-400 mr-2 rounded-sm" />
                    <p class="align-left m-0 py-0.5 break-words font-light text-sm font-base font text-gray-400">
                      <%= c.pointer.quote %>
                    </p>
                  </div>
                  <p class="m-0 mt-2 font-light"><%= c.body %></p>
                </div>

                <div class="mt-2" :for={s <- c.children} id={s.id}>
                  <div class="flex items-center">
                    <img
                      class="p-0 m-0 flex h-6 w-6 rounded-full object-cover border-none border-red-900"
                      
                    />
                    <span class="ml-2 font-bold text-md">@<%= s.initiator.username %></span>
                    <span class="ml-2 font-italic text-xs text-gray-500"><%= Timex.from_now(s.inserted_at) %></span>
                  </div>
                  <div class="mt-0 pl-8">
                    <p class="m-0 font-light"><%= s.body %></p>
                  </div>
                </div>

                <.form
                  for={%{}}
                  class="flex items-center mt-4 mb-2" phx-submit="submit-quoted-comment">
                  <img
                    src="https://picsum.photos/50/50"
                    class="p-0 m-0 mr-2 flex h-6 w-6 rounded-full object-cover border-none border-red-900"
                    onerror="this.src='/images/default_hand.jpg';"
                  />
                  <input name="parent_id" type="hidden" value={c.id} />
                  <input
                    name="body"
                    placeholder="Add a comment"
                    id={"commentable-#{Ecto.UUID.generate()}"}
                    class="block focus:outline-none rounded-sm w-full text-zinc-900 border-0"
                    />
                </.form>
              </div>
            </div>
          </div>
        </div>
      </header>
      """
  end
end
