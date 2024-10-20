defmodule VyasaWeb.Context.Discuss do
  @moduledoc """
  The Discuss Context defines state handling related to the "Discuss" user mode.
  """
  use VyasaWeb, :live_component

  alias VyasaWeb.ModeLive.{UserMode}
  alias VyasaWeb.Session
  alias Phoenix.LiveView.Socket
  alias Vyasa.Sangh
  alias Vyasa.Sangh.Session, as: SanghSession
  # alias VyasaWeb.Context.Discuss.SheafContainer
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
  end

  defp init_sheaf_lattice(
         %Socket{
           assigns: %{
             session:
               %{
                 sangh: %{id: sangh_session_id}
               } = _session
           }
         } = socket
       ) do
    root_sheafs =
      sangh_session_id
      # TODO: use paginated version for this eventually
      |> Sangh.get_root_sheafs_by_session()
      |> Enum.filter(fn s -> s.traits == ["published"] end)

    sheaf_lattice =
      [0, 1, 2]
      |> Enum.flat_map(fn level ->
        root_sheafs
        |> Enum.map(fn sheaf -> to_string(sheaf.path) end)
        |> Enum.flat_map(fn sheaf_id ->
          Sangh.get_child_sheafs_by_session(sangh_session_id, sheaf_id, level)
        end)
        |> Enum.map(fn s -> {s.path.labels, s} end)
      end)
      |> Enum.into(%{})

    socket
    |> assign(sheaf_lattice: sheaf_lattice)
  end

  # fallback when no session loaded:
  defp init_sheaf_lattice(%Socket{} = socket) do
    socket
    |> assign(sheaf_lattice: nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <%= if not is_nil(@sheaf_lattice) do %>
          <div :for={
            sheaf <-
              @sheaf_lattice
              |> Enum.filter(fn
                {[_], _sheaf} -> true
                _ -> false
              end)
              |> Enum.map(fn {_, s} -> s end)
          }>
            <.sheaf_summary sheaf={sheaf} />
            <!-- <.debug_dump
            label={Enum.join(sheaf.traits, ",") <> " sheaf dump, id =" <> sheaf.id}
            sheaf={sheaf}
            class="relative bg-green"
          /> -->
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
