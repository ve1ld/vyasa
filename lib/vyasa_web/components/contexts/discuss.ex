defmodule VyasaWeb.Context.Discuss do
  @moduledoc """
  The Discuss Context defines state handling related to the "Discuss" user mode.
  """
  use VyasaWeb, :live_component

  alias VyasaWeb.ModeLive.{UserMode}
  alias VyasaWeb.Session
  alias Phoenix.LiveView.Socket
  # alias Vyasa.Sangh
  alias Vyasa.Sangh.Session, as: SanghSession
  # alias VyasaWeb.Context.Discuss.SheafContainer

  @impl true
  def update(
        %{
          user_mode: %UserMode{} = user_mode,
          live_action: live_action,
          session:
            %Session{
              sangh: %SanghSession{id: _sangh_id} = _sangh_session
            } = session,
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
      |> assign(content_action: live_action)
      |> apply_action(live_action, nil)
    }
  end

  # TODO: this is only a stub:
  defp apply_action(%Socket{} = socket, _, _) do
    socket
    |> init_reply_to_context()

    # |>assign()
    # |> assign(sheafs: Sangh.get_sheafs_by_session(sangh_id))
  end

  defp init_reply_to_context(%Socket{} = socket) do
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <.icon name="custom-spinner-bars-scale-middle" />
        <h1>DISCUSS MODE -- sheafs in this session:</h1>
        <div :for={sheaf <- @sheafs}>
          <.debug_dump label={"sheaf dump, id =" <> sheaf.id} sheaf={sheaf} class="relative bg-green" />
        </div>
      </div>
    </div>
    """
  end
end
