defmodule VyasaWeb.Context.Discuss do
  @moduledoc """
  The Discuss Context defines state handling related to the "Discuss" user mode.
  """
  use VyasaWeb, :live_component

  alias VyasaWeb.ModeLive.{UserMode}
  alias VyasaWeb.Session
  alias Phoenix.LiveView.Socket
  alias Vyasa.Sangh.Session, as: SanghSession
  alias Vyasa.Sangh.{SheafLattice, Sheaf}
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState
  import VyasaWeb.Context.Discuss.SheafTree
  import VyasaWeb.Context.Components

  @impl true
  def update(
        %{
          user_mode: %UserMode{} = user_mode,
          url_params: url_params,
          live_action: _live_action,
          session: session,
          id: id
        } =
          params,
        socket
      ) do
    IO.inspect(params, label: "TRACE: params passed to ReadContext")

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(session: session)
      |> assign(user_mode: user_mode)
      # TODO remove TEMP once doing the url_params:
      |> apply_action(:index, url_params)
      # |> apply_action(live_action, url_params)
    }
  end

  defp apply_action(
         %Socket{
           assigns: %{
             session:
               %Session{
                 sangh: %SanghSession{id: sangh_id} = _sangh_session
               } = _session
           }
         } = socket,
         :index,
         _
       )
       when not is_nil(sangh_id) do
    socket
    |> assign(content_action: :index)
    |> init_sheaf_lattice()
    |> init_sheaf_ui_lattice()
  end

  # when there is no sangh session in state:
  defp apply_action(
         %Socket{
           assigns: %{session: %Session{sangh: nil} = _session}
         } = socket,
         :index,
         _
       ) do
    socket
    |> assign(content_action: :index)
    |> init_sheaf_lattice()
    |> init_sheaf_ui_lattice()
  end

  defp init_sheaf_lattice(
         %Socket{
           assigns: %{
             content_action: :index,
             session:
               %{
                 sangh: %{id: sangh_id}
               } = _session
           }
         } = socket
       ) do
    socket
    |> assign(sheaf_lattice: SheafLattice.create_complete_sheaf_lattice(sangh_id))
  end

  # fallback when no session loaded:
  defp init_sheaf_lattice(%Socket{} = socket) do
    socket
    |> assign(sheaf_lattice: nil)
  end

  # creates a ui lattice in a similar shape to the actual lattice. This lattice
  # may be read in the same way using the same functions as the data lattice.
  defp init_sheaf_ui_lattice(
         %Socket{
           assigns: %{
             sheaf_lattice: sheaf_lattice
           }
         } = socket
       )
       when is_map(sheaf_lattice) do
    sheaf_ui_lattice =
      sheaf_lattice
      |> Enum.map(fn {k,
                      %Sheaf{
                        marks: _marks
                      } = sheaf} ->
        {k, sheaf |> SheafUiState.get_initial_ui_state()}
      end)
      |> Enum.into(%{})

    socket
    |> assign(sheaf_ui_lattice: sheaf_ui_lattice)
  end

  defp init_sheaf_ui_lattice(%Socket{} = socket) do
    socket
    |> assign(sheaf_ui_lattice: nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <%= if not is_nil(@sheaf_lattice) do %>
          <div :for={
            root_sheaf <-
              SheafLattice.read_sheaf_lattice(@sheaf_lattice, 0)
          }>
            <.root_sheaf
              events_target="#content-display"
              sheaf={root_sheaf}
              sheaf_lattice={@sheaf_lattice}
              sheaf_ui_lattice={@sheaf_ui_lattice}
            />
            <.sheaf_summary sheaf={root_sheaf} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
