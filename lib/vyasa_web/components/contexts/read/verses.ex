defmodule VyasaWeb.Context.Read.Verses do
  use VyasaWeb, :live_component

  alias Vyasa.Written.{Verse}

  @impl true
  def update(params, socket) do
    {
      :ok,
      socket
      |> assign(params)
    }
  end

  @impl true
  # FIXME: there's a duplication of ids so we get this error on the client side:
  # Multiple IDs detected: quick-draft-container. Ensure unique element ids.
  def render(assigns) do
    ~H"""
    <div>
      <div id="chapter-index-container">
        <.header class="p-4 pb-0">
          <div class={["text-4xl mb-4", "font-" <> @src.script]}>
            <%= @selected_transl.target.title_translit %> | <%= @chap.title %>
          </div>
          <div class="font-dn text-2xl mb-4">
            Chapter <%= @chap.no %> - <%= @selected_transl.target.title %>
          </div>

          <:subtitle>
            <div id="chapter-preamble" class="font-dn text-sm sm:text-lg">
              <%= @selected_transl.target.body %>
            </div>
          </:subtitle>
        </.header>
        <.back patch={~p"/explore/#{@src.title}"}>
          Back to <%= to_title_case(@src.title) %> Chapters
        </.back>
        <div
          id="verses"
          phx-update="stream"
          phx-hook="HoveRune"
          data-event-target={@user_mode.mode_context_component_selector}
        >
          <.live_component
            :for={{dom_id, %Verse{} = verse} <- @verses}
            id={dom_id}
            module={VyasaWeb.Context.Read.VerseMatrix}
            verse={verse}
            marks={@marks}
            marks_ui={@marks_ui}
            event_target="#content-display"
            edge={[
              %{
                title: "#{verse.chapter_no}.#{verse.no}",
                field: [:body],
                verseup: {:big, @src.script}
              },
              %{node: hd(verse.translations), field: [:target, :body_translit], verseup: :mid},
              %{node: hd(verse.translations), field: [:target, :body_translit_meant], verseup: :mid},
              %{node: hd(verse.translations), field: [:target, :body], verseup: :mid}
            ]}
          />
        </div>
        <.back patch={~p"/explore/#{@src.title}"}>
          Back to <%= to_title_case(@src.title) %> Chapters
        </.back>
      </div>
    </div>
    """
  end

  # @impl true
  # def handle_event("reportVideoStatus", payload, socket) do
  #   IO.inspect(payload)
  #   {:noreply, socket}
  # end
  @impl true
  def handle_event("navigate_to_chapter", %{"target" => target} = _payload, socket) do
    IO.inspect(target, label: "TRACE: push patch to the following target by @myself:")

    {:noreply,
     socket
     |> push_patch(to: target)
     |> push_event("scroll-to-top", %{})}
  end
end
