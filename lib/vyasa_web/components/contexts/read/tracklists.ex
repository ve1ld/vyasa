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
      <div>TRACK LISTs display component</div>
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
            {to_title_case(tracklists.title)}
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

    # TODO This is what allows the media bridge to be updated with a tracklist, we sync the entire tracklist
    # this should be @ mount of the tracklist page actually
    # send(self(), %{
    #   process: MediaBridge,
    #   event: :load_tracklist,
    #   loader: fn -> Vyasa.Bhaj.get_tracklist("fc4bb25c-41c0-447a-90c7-894d4f52b183") end,
    #   origin: __MODULE__
    # })

    {:noreply,
     socket
     |> push_patch(to: target)
     |> push_event("scroll-to-top", %{})}
  end
end
