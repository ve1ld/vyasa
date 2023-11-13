defmodule VyasaWeb.TextLive.FormComponent do
  use VyasaWeb, :live_component

  alias Vyasa.Written

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage text records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="text-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Text</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{text: text} = assigns, socket) do
    changeset = Written.change_text(text)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"text" => text_params}, socket) do
    changeset =
      socket.assigns.text
      |> Written.change_text(text_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"text" => text_params}, socket) do
    save_text(socket, socket.assigns.action, text_params)
  end

  defp save_text(socket, :edit, text_params) do
    case Written.update_text(socket.assigns.text, text_params) do
      {:ok, text} ->
        notify_parent({:saved, text})

        {:noreply,
         socket
         |> put_flash(:info, "Text updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_text(socket, :new, text_params) do
    case Written.create_text(text_params) do
      {:ok, text} ->
        notify_parent({:saved, text})

        {:noreply,
         socket
         |> put_flash(:info, "Text created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
