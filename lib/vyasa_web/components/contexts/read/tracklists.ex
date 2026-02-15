defmodule VyasaWeb.Context.Read.Tracklists do
  use VyasaWeb, :live_component

  @impl true
  def update(params, socket) do
    {
      :ok,
      socket
      |> assign(params)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.table
        id="tracklists"
        rows={@tracklists}
        row_click={
          fn {_id, tracklist} ->
            JS.push("navigate_to_tracklist",
              value: %{target: ~p"/explore/tracks/#{tracklist.id}/"},
              target: @myself
            )
          end
        }
      >
        <:col :let={{_id, tracklists}} label="">
          <div class="font-dn text-2xl">
            <%= to_title_case(tracklists.title) %>
          </div>
        </:col>
      </.table>

      <span :if={@tracklists |> Enum.count() < 10} class="block h-96" />
    </div>
    """
  end

  @impl true
  def handle_event("navigate_to_tracklist", %{"target" => target} = _payload, socket) do
    IO.inspect(target, label: "TRACE: push patch to the following target by @myself:")

    {:noreply,
     socket
     |> push_patch(to: target)
     |> push_event("scroll-to-top", %{})}
  end
end
