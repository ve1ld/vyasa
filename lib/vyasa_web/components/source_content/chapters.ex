defmodule VyasaWeb.Content.Chapters do
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
      <.header>
        <div class="font-dn text-4xl">
          <%= to_title_case(@source.title) %>
        </div>
      </.header>

      <.back patch={~p"/explore/"}>Back to All Sources</.back>

      <.table
        id="chapters"
        rows={@chapters}
        row_click={
          fn {_id, chap} ->
            JS.push("navigate_to_chapter",
              value: %{target: ~p"/explore/#{@source.title}/#{chap.no}/"},
              target: @myself
            )
          end
        }
      >
        <:col :let={{_id, chap}} label="Chapter">
          <div class="font-dn text-lg">
            <%= chap.no %>. <%= hd(chap.translations).target.title_translit %>
          </div>
        </:col>
        <:col :let={{_id, chap}} label="Description">
          <div class={"font-#{@source.script} text-md"}>
            <%= chap.title %>
          </div>
          <div class="font-dn text-md">
            <%= hd(chap.translations).target.title %>
          </div>
        </:col>
      </.table>

      <.back patch={~p"/explore/"}>Back to All Sources</.back>

      <span :if={@chapters |> Enum.count() < 10} class="block h-96" />
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
