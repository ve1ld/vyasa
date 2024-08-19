defmodule VyasaWeb.Content.Sources do
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
        id="sources"
        rows={@sources}
        row_click={
          fn {_id, source} ->
            JS.push("navigate_to_source",
              value: %{target: ~p"/explore/#{source.title}/"},
              target: @myself
            )
          end
        }
      >
        <:col :let={{_id, source}} label="">
          <div class="font-dn text-2xl">
            <%= to_title_case(source.title) %>
          </div>
        </:col>
      </.table>

      <span :if={@sources |> Enum.count() < 10} class="block h-96" />
    </div>
    """
  end

  @impl true
  def handle_event("navigate_to_source", %{"target" => target} = _payload, socket) do
    IO.inspect(target, label: "TRACE: push patch to the following target by @myself:")

    {:noreply,
     socket
     |> push_patch(to: target)
     |> push_event("scroll-to-top", %{})}
  end
end
