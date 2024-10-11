defmodule VyasaWeb.Context.Discuss.SheafContainer do
  @moduledoc """
  A container to hold local state for a sheaf in the discussion mode.
  """
  use VyasaWeb, :live_component

  alias VyasaWeb.ModeLive.{UserMode}
  alias Phoenix.LiveView.Socket
  alias Vyasa.Sangh.Sheaf
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState
  import VyasaWeb.Context.Components

  @impl true
  def update(
        %{
          user_mode: %UserMode{} = user_mode,
          id: id,
          sheaf: %Sheaf{} = sheaf
        } =
          params,
        socket
      ) do
    IO.inspect(params, label: "TRACE: params passed to ReadContext")

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(sheaf: sheaf)
      |> assign(user_mode: user_mode)
      |> assign(is_expanded_view?: true)
    }
  end

  @impl true
  def handle_event(
        "toggle_marks_display_collapsibility",
        %{"value" => _},
        %Socket{
          assigns:
            %{
              is_expanded_view?: _is_expanded_view?
            } = _assigns
        } = socket
      ) do
    {:noreply, update(socket, :is_expanded_view?, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="border border-red-500">
      <div class="mx-auto max-w-2xl pb-16">
        <h1>SHEAF CONTAINER</h1>
        <.sheaf_display sheaf={@sheaf} />
        <.collapsible_marks_display
          myself={@myself}
          marks={@sheaf.marks |> Enum.reverse()}
          marks_ui={MarksUiState.get_initial_ui_state(@marks)}
        />
        Sheaf: <pre>
        <%= inspect(@sheaf, pretty: true) %>
      </pre>
      </div>
    </div>
    """
  end
end
