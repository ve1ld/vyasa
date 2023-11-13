defmodule VyasaWeb.TextLive.Index do
  use VyasaWeb, :live_view

  alias Vyasa.Written
  alias Vyasa.Written.Text

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :texts, Written.list_texts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Text")
    |> assign(:text, Written.get_text!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Text")
    |> assign(:text, %Text{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Texts")
    |> assign(:text, nil)
  end

  @impl true
  def handle_info({VyasaWeb.TextLive.FormComponent, {:saved, text}}, socket) do
    {:noreply, stream_insert(socket, :texts, text)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    text = Written.get_text!(id)
    {:ok, _} = Written.delete_text(text)

    {:noreply, stream_delete(socket, :texts, text)}
  end
end
