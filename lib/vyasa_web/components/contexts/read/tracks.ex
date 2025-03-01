defmodule VyasaWeb.Context.Read.Tracks do
  use VyasaWeb, :live_component
  alias Vyasa.{Bhaj}

  @impl true
  def update(params, socket) do
    IO.inspect("ENTERING TRACKS")
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
        id="tracks"
        rows={@tracks}
        row_click={
          fn {_id, track} ->
            JS.push("navigate_from_track",
              value: %{track_id: track.id},
              target: @myself
            )
          end
        }
      >
        <:col :let={{_id, track}} label="">
          <.live_component
            id={"track-" <>track.id}
            module={VyasaWeb.Context.Read.VerseMatrix}
            verse={track.event.verse}
            marks={[]}
            marks_ui={%VyasaWeb.Context.Components.UiState.Marks{}}
            event_target="#content-display" 
            edge={[
              %{
                title: "#{track.order}",
                field: [:body],
                verseup: {:big, "ta"}
              },
            ]}
          />
        </:col>
      </.table>

      <span :if={@tracks |> Enum.count() <= 10} class="block h-96" />
      <span :if={@tracks |> Enum.count() > 10} class="block h-48" />
    </div>
    """
  end

  #@rtshkmr hook to your mediabridge event from here!
  @impl true
  def handle_event("navigate_from_track", %{"track_id" => track_id}, socket) do
    %{event: %{verse: %{source: source, chapter_no: chap_no}}} = Bhaj.get_track!(track_id)

    {:noreply,
     socket
     |> push_patch(to: ~p"/explore/#{source.title}/#{chap_no}/")
     |> push_event("scroll-to-top", %{})}
  end
end
