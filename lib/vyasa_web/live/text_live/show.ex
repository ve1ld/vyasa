defmodule VyasaWeb.TextLive.Show do
  use VyasaWeb, :live_view

  alias Vyasa.Written

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:text, Written.get_text!(id))}
  end

  defp page_title(:show), do: "Show Text"
  defp page_title(:edit), do: "Edit Text"
end
