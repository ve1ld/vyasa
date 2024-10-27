defmodule VyasaWeb.Context.Discuss do
  @moduledoc """
  The Discuss Context defines state handling related to the "Discuss" user mode.
  """
  use VyasaWeb, :live_component

  alias EctoLtree.LabelTree, as: Ltree
  alias VyasaWeb.ModeLive.{UserMode}
  alias VyasaWeb.Session
  alias Phoenix.LiveView.Socket
  alias Vyasa.Sangh.Session, as: SanghSession
  alias Vyasa.Sangh
  alias Vyasa.Sangh.{SheafLattice, Sheaf, Mark}
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
    |> init_drafting_context()
    |> init_reply_to_context()
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
  Adds a new sheaf to both the sheaf_lattice and sheaf_ui_lattice.
  This is destructive, and will do overwrites if an existing sheaf exists.
  Note that this and anything downstream of this function will not do any db writes,
  will only update the lattices kept in socket state.
  """
  def register_sheaf(
        %Socket{
          assigns: %{
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket,
        %Sheaf{} = new_sheaf
      ) do
    socket
    |> assign(
      sheaf_lattice:
        sheaf_lattice
        |> SheafLattice.insert_sheaf_into_lattice(new_sheaf)
    )
    |> assign(
      sheaf_ui_lattice:
        sheaf_ui_lattice
        |> SheafLattice.insert_sheaf_into_ui_lattice(new_sheaf)
    )
  end

  def deregister_sheaf(
        %Socket{
          assigns: %{
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket,
        %Sheaf{} = old_sheaf
      ) do
    socket
    |> assign(
      sheaf_lattice:
        sheaf_lattice
        |> SheafLattice.remove_sheaf_from_lattice(old_sheaf)
    )
    |> assign(
      sheaf_ui_lattice:
        sheaf_ui_lattice
        |> SheafLattice.remove_sheaf_from_ui_lattice(old_sheaf)
    )
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

  @doc """
  Defines the drafting context by setting the draft_reflector_path and updating
  the respective state and ui_state lattices.

  Additionally, ensures that there's at least one draft mark in the marks that draft reflector
  keeps in state.

  There are no db writes that will be done in this function and anything downstream of it.
  """
  def init_drafting_context(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}}
          }
        } = socket
      ) do
    socket
    |> init_draft_reflector()
    |> maybe_prepend_draft_mark_in_reflector()
  end

  # fallthrough
  def init_drafting_context(%Socket{} = socket) do
    socket
    |> assign(draft_reflector_path: nil)
  end

  @doc """
  Similar to the read mode, this function defines what the currently in-draft sheaf is for:
  case 1: when there's a parent sheaf to it, it means that this draft sheaf, if published, will respond to that parent.
  case 2: when there's no parent sheaf to it, then it means that the draft sheaf, if published, will be a root sheaf.

  TODO: similar to the read::init_reply_to_context, url overrides may happen.
  """
  def init_reply_to_context(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector_path: %Ltree{labels: lattice_key} = _reflector_path,
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{}
          }
        } = socket
      ) do
    %Sheaf{
      parent_id: parent_id
    } = _reflected_sheaf = sheaf_lattice |> Map.get(lattice_key)

    reply_to_path =
      case parent_id do
        p_id when is_binary(p_id) ->
          # case 1: there's a parent sheaf that is being responded to
          %Sheaf{
            id: ^p_id,
            path: %Ltree{} = parent_path
          } = _parent = Sangh.get_sheaf(p_id)

          parent_path

        _ ->
          # case 2: publishing this draft sheaf will end up creating a root sheaf
          nil
      end

    socket
    |> assign(reply_to_path: reply_to_path)
  end

  # fallthrough
  def init_reply_to_context(%Socket{} = socket) do
    socket
    |> assign(reply_to_path: nil)
  end

  @doc """
  Only initialises a draft reflector in the socket state. If there's no existing
  draft reflector(s) in the db, then we shall create a new draft sheaf.

  Since we are keeping state within the lattices, we shall only add reflector's path to socket state,
  since it can be used to get access the sheaf latttices and and update lattices accordingly by using register_sheaf()
  """
  def init_draft_reflector(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: sangh_id}},
            sheaf_lattice: %{},
            sheaf_ui_lattice: %{}
          }
        } = socket
      ) do
    draft_sheafs = sangh_id |> Vyasa.Sangh.get_sheafs_by_session(%{traits: ["draft"]})

    case draft_sheafs do
      [%Sheaf{path: %Ltree{} = path} = draft_sheaf | _] ->
        socket
        |> assign(draft_reflector_path: path)
        # possibly redundant, registering here for extra measure:
        |> register_sheaf(draft_sheaf)

      _ ->
        %Sheaf{path: %Ltree{} = path} = new_draft_sheaf = Sheaf.draft!(sangh_id)

        socket
        |> assign(draft_reflector_path: path)
        |> register_sheaf(new_draft_sheaf)
    end
  end

  @doc """
  Ensures that the current draft reflector will always have a draft mark at the head of
  its list of marks.

  If there's a need to, a new draft mark will be prepended and we will register the sheaf
  again, which will just overwrite existing state in the various lattices.
  """
  def maybe_prepend_draft_mark_in_reflector(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector_path:
              %Ltree{
                labels: lattice_key
              } = _path,
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{}
          }
        } = socket
      ) do
    possible_new_draft = Mark.get_draft_mark()

    %Sheaf{
      marks: marks
    } = reflected_sheaf = sheaf_lattice |> Map.get(lattice_key)

    case marks do
      # case 1: has existing draft marks, no change needed
      [%Mark{state: :draft} | _] = _existing_marks ->
        socket

      # case 2: has existing marks that are non-draft, but 0 draft marks:
      [%Mark{} | _] = existing_marks ->
        updated_reflector = %Sheaf{reflected_sheaf | marks: [possible_new_draft | existing_marks]}

        socket
        |> register_sheaf(updated_reflector)

      # case 3 no existing marks:
      _ ->
        updated_reflector = %Sheaf{reflected_sheaf | marks: [possible_new_draft]}

        socket
        |> register_sheaf(updated_reflector)
    end
  end

  # @doc """
  # Inserts a particular mark into a particular sheaf in the lattice.

  # Intent is that it gets used when creating a mark in the discuss mode.
  # TODO: figure out what is the best place to put this? likely when creating mark
  # """
  # def insert_mark_into_sheaf_in_lattice(
  #       %{} = lattice,
  #       %Ltree{labels: lattice_key} = _sheaf_path,
  #       %Mark{id: mark_id, body: body} = mark
  #     ) do
  #   %Sheaf{
  #     marks: rest_marks
  #   } = target_sheaf = lattice |> Map.get(lattice_key)

  #   updated_new_mark = %Mark{
  #     mark
  #     | id: if(not is_nil(mark_id), do: Ecto.UUID.generate(), else: mark_id),
  #       order: Mark.get_next_order(rest_marks),
  #       body: body,
  #       state: :live
  #   }

  #   updated_sheaf = %Sheaf{target_sheaf | marks: [updated_new_mark | rest_marks]}

  #   socket
  #   |> register_sheaf(updated_sheaf)
  # end
  @impl true
  def handle_event(
        "ui::toggle_sheaf_is_expanded?",
        %{
          "sheaf_path_labels" => sheaf_labels
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            sheaf_lattice: %{} = _sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      ) do
    lattice_key = Jason.decode!(sheaf_labels)
    # Handle the event here (e.g., log it, update state, etc.)
    IO.inspect(sheaf_labels,
      label: "HANDLE -- ui::toggle_sheaf_is_expanded?"
    )

    {:noreply,
     socket
     |> assign(
       sheaf_ui_lattice: sheaf_ui_lattice |> SheafLattice.toggle_sheaf_is_expanded?(lattice_key)
     )}
  end

  @impl true
  def handle_event(event_name, params, socket) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.inspect(%{event_name: event_name, params: params},
      label: "POKEMON DISCUSS CONTEXT EVENT HANDLING"
    )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <!-- <.debug_dump
        :if={Map.has_key?(assigns, :draft_reflector_path)}
        label="Context Dump on Discussions"
        draft_reflector_path={@draft_reflector_path}
        reply_to_path={@reply_to_path}
        reflected={@sheaf_lattice |> Map.get(@draft_reflector_path.labels)}
        reflected_ui={@sheaf_ui_lattice |> Map.get(@draft_reflector_path.labels)}
      /> -->
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <.sheaf_creator_modal
          :if={
            Map.has_key?(assigns, :reply_to_path) &&
              not is_nil(@reply_to_path)
          }
          id="sheaf-creator"
          session={@session}
          reply_to={@sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(@reply_to_path.labels)}
          draft_sheaf={
            @sheaf_latice |> SheafLattice.get_sheaf_from_lattice(@draft_reflector_path.labels)
          }
          draft_sheaf_ui={
            @sheaf_ui_latice |> SheafLattice.get_sheaf_from_lattice(@draft_reflector_path.labels)
          }
          event_target="#content-display"
        />

        <%= if not is_nil(@sheaf_lattice) do %>
          <div :for={
            root_sheaf <-
              SheafLattice.read_published_from_sheaf_lattice(@sheaf_lattice, 0)
          }>
            <.root_sheaf
              events_target="#content-display"
              sheaf={root_sheaf}
              sheaf_lattice={@sheaf_lattice}
              sheaf_ui_lattice={@sheaf_ui_lattice}
              on_replies_click={JS.push("ui::toggle_sheaf_is_expanded?", target: "#content-display")}
              on_set_reply_to={JS.push("sheaf::set_reply_to_context", target: "#content-display")}
            />
            <!-- <.sheaf_summary sheaf={root_sheaf} /> -->
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
