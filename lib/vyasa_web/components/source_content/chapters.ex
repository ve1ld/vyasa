defmodule VyasaWeb.Content.Chapters do
  use VyasaWeb, :live_component

  @impl true
  def update(params, socket) do
    {
      :ok,
      socket
      |> assign(params)
      # |> dbg()
    }
  end

  # TODO: navigate() -> patch() on links...
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <div class="font-dn text-4xl">
          <%= to_title_case(@source.title) %>
        </div>
      </.header>

      <.table
        id="chapters"
        rows={@chapters}
        row_click={
          fn {_id, chap} ->
            JS.push("navigate_to_chapter",
              value: %{target: ~p"/explore/#{@source.title}/#{chap.no}/"}
            )
          end
        }
      >
        <:col :let={{_id, chap}} label="Chapter">
          <div class="font-dn text-lg">
            <%= chap.no %>. <%= hd(chap.translations).target.translit_title %>
          </div>
        </:col>
        <:col :let={{_id, chap}} label="Description">
          <div class="font-dn text-md">
            <%= chap.title %>
          </div>
          <div class="font-dn text-md">
            <%= hd(chap.translations).target.title %>
          </div>
        </:col>
      </.table>

      <.back navigate={~p"/explore/"}>Back to All Sources</.back>

      <span :if={@chapters |> Enum.count() < 10} class="block h-96" />
    </div>
    """
  end

  # @impl true
  # def handle_event("reportVideoStatus", payload, socket) do
  #   IO.inspect(payload)
  #   {:noreply, socket}
  # end
end
