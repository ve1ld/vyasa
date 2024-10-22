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

  @doc """
  Reads sheaf layers from a lattice based on the specified level and match criteria.

  ## Examples

  # Fetch all sheafs in a particular level
      iex> Discuss.read_sheaf_lattice(sheaf_lattice)
      # equivalent to:
      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 0, nil)

      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 1, nil)

      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 2, nil)

  # Fetch based on specific matches of a single label
      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 0, "cf27deab")

      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 1, "65c1ac0c")

      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 2, "56c369e4")

  # Fetch based on complete matches
      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 1, ["c9cbcb0c", "65c1ac0c"])

      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 2, ["c9cbcb0c", "f91bac0d", "56c369e4"])

  # Fetch immediate children based on particular parent
  # Fetch immediate children of a specific level 0 node:
      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 1, ["cf27deab", nil])

  # Fetch immediate children of a specific level 1 node:
      iex> Discuss.read_sheaf_lattice(sheaf_lattice, 2, ["c9cbcb0c", "65c1ac0c", nil])
  """

  def read_sheaf_lattice(%{} = sheaf_lattice, level \\ 0, match \\ nil) do
    sheaf_lattice
    |> Enum.filter(create_sheaf_lattice_filter(level, match))
    |> Enum.map(fn {_, s} -> s end)
  end

  # fetches all sheafs in level 0:
  defp create_sheaf_lattice_filter(0, nil) do
    fn
      {[_], _sheaf} -> true
      _ -> false
    end
  end

  # fetches all sheafs in level 1:
  defp create_sheaf_lattice_filter(1, nil) do
    fn
      {[_, a], _sheaf} when is_binary(a) -> true
      _ -> false
    end
  end

  # fetches all sheafs in level 2:
  defp create_sheaf_lattice_filter(2, nil) do
    fn
      {[a | [b | [c]]], _sheaf} when is_binary(a) and is_binary(b) and is_binary(c) -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 0
  defp create_sheaf_lattice_filter(0, m) when is_binary(m) do
    fn
      {[^m], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 1
  defp create_sheaf_lattice_filter(1, m) when is_binary(m) do
    fn
      {[_, ^m], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 2
  defp create_sheaf_lattice_filter(2, m) when is_binary(m) do
    fn
      {[_ | [_ | [^m]]], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 1, by matching labels completely
  defp create_sheaf_lattice_filter(1, [a, b]) when is_binary(a) and is_binary(b) do
    fn
      {[^a, ^b], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 2, by matching labels completely
  defp create_sheaf_lattice_filter(2, [a, b, c])
       when is_binary(a) and is_binary(b) and is_binary(c) do
    fn
      {[^a, ^b, ^c], _sheaf} -> true
      _ -> false
    end
  end

  # fetches all the immeidate children (level 1) of a root sheaf (level 2)
  defp create_sheaf_lattice_filter(1, [a, b]) when is_binary(a) and is_nil(b) do
    fn
      {[^a, _], _sheaf} when is_binary(a) -> true
      _ -> false
    end
  end

  # fetches all the immediate children (level 2) of a level 1 sheaf
  defp create_sheaf_lattice_filter(2, [a, b, nil]) when is_binary(a) and is_binary(b) do
    fn
      {[^a, ^b, _], _sheaf} -> true
      _ -> false
    end
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
              read_sheaf_lattice(@sheaf_lattice, 0)
          }>
            <.root_sheaf
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
