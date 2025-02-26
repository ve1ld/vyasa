defmodule VyasaWeb.Context.Read.Tracks do
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
      <div>TRACKS component: shows single track list</div>
      <.table
        id="tracks"
        rows={@tracks}
        row_click={
          fn {_id, track} ->
            JS.push("navigate_from_track",
              value: %{target: ~p"/explore/tracks/#{track.id}/"},
              target: @myself
            )
          end
        }
      >
        <:col :let={{_id, track}} label="">
          <div id={ "foo_track_" <> track.id } class="font-dn text-2xl">
            TODO track foo_track_{track.id} view: <br /> {to_title_case(track.event.verse.body)}
          </div>
        </:col>
      </.table>
      <span :if={@tracks |> Enum.count() < 10} class="block h-96" />
    </div>
    """
  end

  # @rtshkmr hook to your mediabridge event from here!
  @impl true
  def handle_event("navigate_from_track", %{"target" => target} = _payload, socket) do
    IO.inspect(target, label: "TRACE: push patch to the following target by @myself:")

    {:noreply,
     socket
     # |> push_patch(to: target)
     |> push_event("scroll-to-top", %{})}
  end
end
