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
    output =
      case {level, match} do
        # fetch all sheafs in a particular level:
        {0, m} when is_nil(m) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[_], _sheaf} -> true
            _ -> false
          end)

        {1, m} when is_nil(m) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[_, a], _sheaf} when not is_list(a) -> true
            _ -> false
          end)

        {2, m} when is_nil(m) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[a | [b | [c]]], _sheaf} when is_binary(a) and is_binary(b) and is_binary(c) -> true
            _ -> false
          end)

        # specific matches based on a particular layer's label:
        {0, m} when is_binary(m) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[^m], _sheaf} -> true
            _ -> false
          end)

        {1, m} when is_binary(m) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[_, ^m], _sheaf} -> true
            _ -> false
          end)

        {2, m} when is_binary(m) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[_ | [_ | [^m]]], _sheaf} -> true
            _ -> false
          end)

        # exact matches:
        {1, [a, b]} when is_binary(a) and is_binary(b) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[^a, ^b], _sheaf} -> true
            _ -> false
          end)

        {2, [a, b, c]} when is_binary(a) and is_binary(b) and is_binary(c) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[^a, ^b, ^c], _sheaf} -> true
            _ -> false
          end)

        # children of a specific level 0 node:
        {1, [a, b]} when is_binary(a) and is_nil(b) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[^a, _], _sheaf} when is_binary(a) -> true
            _ -> false
          end)

        # children of a specific level 1 node:
        {2, [a, b, nil]} when is_binary(a) and is_binary(b) ->
          sheaf_lattice
          |> Enum.filter(fn
            {[^a, ^b, _], _sheaf} -> true
            _ -> false
          end)
      end

    output |> Enum.map(fn {_, s} -> s end)
  end

  defp init_sheaf_lattice(
         %Socket{
           assigns: %{
             content_action: :index,
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
            root_sheaf <-
              read_sheaf_lattice(@sheaf_lattice, 0)
          }>
            <.sheaf_summary sheaf={root_sheaf} />
            <!-- <.debug_dump
            label={Enum.join(root_sheaf.traits, ",") <> " root_sheaf dump, id =" <> root_sheaf.id}
            sheaf={root_sheaf}
            class="relative bg-green"
          /> -->
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
