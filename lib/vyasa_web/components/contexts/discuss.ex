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
    IO.inspect(params, label: "TRACE: params passed to Discuss")

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

  @doc """
  For a particular sheaf, re-registers it by deleting its old entry in the lattice and inserting the new entry.
  This is useful for manipulating the lattices in events such as promoting a sheaf from draft to published.
  """
  def reregister_sheaf(
        %Socket{} = socket,
        %Sheaf{id: old_id} = old_sheaf,
        %Sheaf{id: new_id} = new_sheaf
      )
      when old_id == new_id do
    socket
    |> deregister_sheaf(old_sheaf)
    |> register_sheaf(new_sheaf)
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
      marks: current_marks
    } = reflected_sheaf = sheaf_lattice |> Map.get(lattice_key)

    case current_marks do
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

  @impl true
  def handle_event(
        "ui::toggle_is_editing_mark_content?",
        %{
          "sheaf_path_labels" => sheaf_labels,
          "mark_id" => mark_id
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            sheaf_lattice: %{} = _sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(sheaf_labels) do
    lattice_key = Jason.decode!(sheaf_labels)

    {:noreply,
     socket
     |> assign(
       sheaf_ui_lattice:
         sheaf_ui_lattice |> SheafLattice.toggle_is_editing_mark_content?(lattice_key, mark_id)
     )}
  end

  @impl true
  def handle_event(
        "ui::toggle_is_editable_marks?",
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
      )
      when is_binary(sheaf_labels) do
    lattice_key = Jason.decode!(sheaf_labels)

    {:noreply,
     socket
     |> assign(
       sheaf_ui_lattice: sheaf_ui_lattice |> SheafLattice.toggle_is_editable_marks(lattice_key)
     )}
  end

  @impl true
  def handle_event(
        "ui::toggle_show_sheaf_modal?",
        _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector_path: %Ltree{
              labels: draft_sheaf_lattice_key
            },
            sheaf_lattice: %{} = _sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      ) do
    new_lattice =
      sheaf_ui_lattice |> SheafLattice.toggle_show_sheaf_modal?(draft_sheaf_lattice_key)

    {
      :noreply,
      socket
      |> assign(sheaf_ui_lattice: new_lattice)
    }
  end

  @impl true
  def handle_event(
        "ui::toggle_marks_display_collapsibility",
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
      )
      when is_binary(sheaf_labels) do
    lattice_key = Jason.decode!(sheaf_labels)
    # Handle the event here (e.g., log it, update state, etc.)
    IO.inspect(sheaf_labels,
      label: "ui::toggle_marks_display_collapsibility"
    )

    {:noreply,
     socket
     |> assign(
       sheaf_ui_lattice:
         sheaf_ui_lattice |> SheafLattice.toggle_marks_display_collapsibility(lattice_key)
     )}
  end

  @impl true
  def handle_event(
        "ui::toggle_sheaf_is_expanded?",
        %{
          "sheaf_path_labels" => sheaf_labels
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector_path: draft_reflector_path,
            sheaf_lattice: %{} = _sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(sheaf_labels) do
    lattice_key = Jason.decode!(sheaf_labels)

    IO.inspect(sheaf_labels,
      label: "HANDLE -- ui::toggle_sheaf_is_expanded?"
    )

    {:noreply,
     socket
     |> assign(
       sheaf_ui_lattice: sheaf_ui_lattice |> SheafLattice.toggle_sheaf_is_expanded?(lattice_key)
     )
     # effects the dom diff:
     |> assign(draft_reflector_path: draft_reflector_path)}
  end

  @impl true
  @doc """
  A quick reply to a sheaf is done when a user wants to reply to a particular comment(sheaf) that
  they see in the discuss mode.


  1 Note on sheaf::publish
  ════════════════════════

  Curently, at the point of init, to determine the reply_to context, we
  shall read what the parent id of the current active draft sheaf is.

  However, after init, within a browser session, we expect the user to
  choose reply_to_focuses multiple times. This choice may be “transient”
  (e.g. quick reply to this) or “permanent/intentional” – so 2 cases for
  the user’s intent. This would mean that the final `sheaf::publish'
  should respect the user’s final choice.

  We have 2 ways to do it:
  1. if “transient”:
     • we don’t want to persist the reply_to in the db (by updating the
       current active draft sheaf).
     • we won’t do an update query on the draft_sheaf form the
       sheaf::toggle_quick_reply
     • we will only change the reply_to_path that is kept in state
       within the discuss context
     • the user should expect that since this is a quick reply, this
       sheaf they’re replying to will not have a pin-focus
     • NOTE HOWEVER, the user will be getting hinted by the UI to go and
       gather marks (e.g. the marks collapse display could display some
       text) ==> if a user decides that their quick reply needs more
       depth, and desires to go and gather marks (e.g. by clicking some
       kind of “nav to read mode”), then this transient case will change
       to case 2, permanent.
       ^ this event is will be different from the sheaf::toggle_quick_reply event though

  2. if “permanent/intentional”
     • we update both the reply_to_path in the local socket state as
       well as update the parent of the current draft sheaf in the db


  1.1 Conclusions:
  ────────────────

  1. `sheaf::toggle_quick_reply' will not do any db write to the current draft
     sheaf’s parent field. Will only update the local state (for
     `reply_to_path')
  2. `sheaf::publish' will be updated so that regardless of the upstream
     context, it will always use the drafting and reply to contexts to
     determine parent and child and will ALWAYS update the parent to the
     current draft sheaf no matter what.
  """
  def handle_event(
        "sheaf::toggle_quick_reply",
        %{
          "sheaf_path_labels" => immediate_reply_to_sheaf_labels
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector_path: %Ltree{
              labels: draft_sheaf_lattice_key
            },
            reply_to_path: current_reply_to_path,
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(immediate_reply_to_sheaf_labels) do
    reply_to_lattice_key = Jason.decode!(immediate_reply_to_sheaf_labels)
    reply_to_sheaf = sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(reply_to_lattice_key)

    new_reply_to_path =
      case reply_to_sheaf do
        %Sheaf{
          path: %Ltree{} = path
        } ->
          path

        _ ->
          current_reply_to_path
      end

    {
      :noreply,
      socket
      |> assign(reply_to_path: new_reply_to_path)
      |> assign(
        sheaf_ui_lattice:
          sheaf_ui_lattice |> SheafLattice.toggle_show_sheaf_modal?(draft_sheaf_lattice_key)
      )
    }
  end

  @impl true
  def handle_event(
        "sheaf::set_reply_to_context",
        %{
          "sheaf_path_labels" => new_reply_to_target
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector_path: %Ltree{
              labels: draft_sheaf_lattice_key
            },
            reply_to_path: current_reply_to_path,
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(new_reply_to_target) do
    reply_to_lattice_key = Jason.decode!(new_reply_to_target)
    reply_to_sheaf = sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(reply_to_lattice_key)
    draft_sheaf = sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(draft_sheaf_lattice_key)
    # why not  sheaf_lattice["reply_to_path"] -> quite explicit

    new_reply_to_path =
      case reply_to_sheaf do
        %Sheaf{
          path: %Ltree{} = path
        } ->
          path

        _ ->
          current_reply_to_path
      end

    # FIXME: @ks0m1c this update function should be updating the parent for the current draft sheaf, but it doesn't seem to be
    # doing so right now
    # what it needs to do:
    # 1. remove assoc b/w old parent and this sheaf
    # 2. create new assoc b/w new parent and this sheaf:
    #     - updates path of child
    IO.puts("CHECKPOINT: before updating sheaf")

    updated_draft_sheaf =
      draft_sheaf
      |> Sangh.update_sheaf!(%{
        parent: reply_to_sheaf
      })

    # updated_sheaf_ui_lattice = sheaf_ui_lattice |> SheafLattice.toggle_sheaf_is_focused?(reply_to_lattice_key)
    updated_sheaf_ui_lattice =
      cond do
        not is_nil(current_reply_to_path) and current_reply_to_path != new_reply_to_path ->
          sheaf_ui_lattice
          |> SheafLattice.toggle_sheaf_is_focused?(reply_to_lattice_key)
          |> SheafLattice.toggle_sheaf_is_focused?(current_reply_to_path.labels)

        not is_nil(current_reply_to_path) and current_reply_to_path == new_reply_to_path ->
          sheaf_ui_lattice
          |> SheafLattice.toggle_sheaf_is_focused?(current_reply_to_path.labels)

        true ->
          sheaf_ui_lattice |> SheafLattice.toggle_sheaf_is_focused?(reply_to_lattice_key)
      end

    IO.inspect(
      %{
        new_reply_to_path: new_reply_to_path,
        current_reply_to_path: current_reply_to_path,
        reply_to_lattice_key: reply_to_lattice_key,
        draft: draft_sheaf_lattice_key,
        target_sheaf_ui_before: sheaf_ui_lattice[new_reply_to_path.labels],
        target_sheaf_ui_after: updated_sheaf_ui_lattice[new_reply_to_path.labels]
      },
      label: "sheaf::set_reply_to_context"
    )

    {
      :noreply,
      socket
      |> assign(reply_to_path: new_reply_to_path)
      |> assign(sheaf_ui_lattice: updated_sheaf_ui_lattice)
      |> assign(
        sheaf_lattice:
          sheaf_lattice
          |> SheafLattice.update_sheaf_in_lattice(draft_sheaf_lattice_key, updated_draft_sheaf)
      )
    }
  end

  @impl true
  # TODO @ks0m1c another place that would require binding / permalinking apis
  # equivalent handler for the read mode as well...
  def handle_event(
        "sheaf::share_sheaf",
        %{
          "sheaf_path_labels" => sheaf_labels
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = _sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(sheaf_labels) do
    lattice_key = Jason.decode!(sheaf_labels)
    shareable_sheaf = sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(lattice_key)

    IO.inspect(shareable_sheaf, label: "TODO: sheaf::share_sheaf")

    {
      :noreply,
      socket
    }
  end

  # FIXME: with the new desire to start new thread, the event handling has to be updated, I shall commit the UI changes in first so that it can be branched off.
  def handle_event(
        "sheaf::publish",
        %{
          "body" => body,
          "is_new_thread" => is_new_thread
          # "is_private" => _is_private
          # "is_new_thread" => is_new_thread
        } = params,
        %Socket{
          assigns: %{
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            },
            draft_reflector_path: %Ltree{
              labels: draft_sheaf_lattice_key
            },
            reply_to_path: %Ltree{
              labels: reply_to_lattice_key
            },
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(body) do
    # TODO: the reply_to_lattice_key might be nil, that case of "create new thread" is not handled right now by discuss
    reply_to_sheaf = sheaf_lattice[reply_to_lattice_key]
    draft_sheaf = sheaf_lattice[draft_sheaf_lattice_key]
    dbg()

    payload_precursor = %{
      body: body,
      traits: ["published"],
      signature: username,
      inserted_at: Utils.Time.get_utc_now()
    }

    update_payload =
      case(is_nil(reply_to_sheaf)) do
        true ->
          payload_precursor

        false ->
          Map.put(payload_precursor, :parent, reply_to_sheaf)
      end

    {:ok, updated_sheaf} = draft_sheaf |> Vyasa.Sangh.make_reply(update_payload)

    %Sheaf{
      path: %Ltree{} = new_draft_reflector_path
    } = new_draft_reflector = Sheaf.draft!(sangh_id)

    {
      :noreply,
      socket
      |> assign(
        sheaf_ui_lattice:
          sheaf_ui_lattice |> SheafLattice.toggle_show_sheaf_modal?(draft_sheaf_lattice_key)
      )
      |> reregister_sheaf(draft_sheaf, updated_sheaf)
      |> assign(draft_reflector_path: new_draft_reflector_path)
      |> assign(reply_to_path: nil)
      |> register_sheaf(new_draft_reflector)
      |> maybe_prepend_draft_mark_in_reflector()
    }
  end

  @impl true
  # TODO @ks0m1c this is an example of what binding/permalinking should handle
  # we need to do a push-patch direction from this function
  def handle_event(
        "navigate::visit_mark",
        %{
          "mark_id" => mark_id
        } = _params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            sheaf_lattice: %{} = _sheaf_lattice,
            sheaf_ui_lattice: %{} = _sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(mark_id) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.inspect(mark_id,
      label: "navigate::visit_mark -- TODO"
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "mark::editMarkContent",
        %{
          "sheaf_path_labels" => sheaf_labels,
          "mark_id" => mark_id,
          "input" => input,
          "previous_mark_body" => _previous_input
        } = params,
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            sheaf_lattice: %{} = sheaf_lattice,
            sheaf_ui_lattice: %{} = sheaf_ui_lattice
          }
        } = socket
      )
      when is_binary(sheaf_labels) do
    lattice_key = Jason.decode!(sheaf_labels)
    IO.inspect(params, label: "Handling mark::editMarkContent")

    # %Sheaf{
    #   marks: old_marks
    # } = old_sheaf = sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(lattice_key)

    # {[old_mark | _] = _old_versions_of_changed, updated_marks} =
    #   get_and_update_in(
    #     old_marks,
    #     [Access.filter(&match?(%Mark{id: ^mark_id}, &1))],
    #     &{&1, Map.put(&1, :body, input)}
    #   )

    # old_mark |> Vyasa.Draft.update_mark(%{body: input})

    # updated_sheaf = %Sheaf{old_sheaf | marks: updated_marks}

    # TODO: this needs to be updated if the sheaf that is being modded is the draft sheaf.
    # this is beause in the case of the draft sheafs, there's a need to do sanitising, and maybe prepending draft mark in the reflector
    # prior to updating the sheaf,
    # this can likey rely on a separate helepr function and shall be done after bindings are handled on the discuss mode.

    # TODOe_path after user model is handled, this is likely to be the best place to check if current user is authorised
    # to make this mark edit
    {
      :noreply,
      socket
      |> assign(
        sheaf_lattice:
          sheaf_lattice
          |> SheafLattice.edit_mark_content_within_sheaf(lattice_key, mark_id, input)
      )
      |> assign(
        sheaf_ui_lattice:
          sheaf_ui_lattice |> SheafLattice.toggle_is_editing_mark_content?(lattice_key, mark_id)
      )
    }
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
    reply_to_sheaf =
      case Map.has_key?(assigns, :reply_to_path) && not is_nil(assigns.reply_to_path) do
        true ->
          assigns.sheaf_lattice
          |> SheafLattice.get_sheaf_from_lattice(assigns.reply_to_path.labels)

        _ ->
          nil
      end

    root_sheaves =
      case assigns.sheaf_lattice do
        l when not is_nil(l) ->
          SheafLattice.read_published_from_sheaf_lattice(assigns.sheaf_lattice, 0)

        _ ->
          []
      end

    assigns =
      assigns
      |> assign(:reply_to, reply_to_sheaf)
      |> assign(:root_sheaves, root_sheaves)

    ~H"""
    <div id={@id}>
      <!-- <.debug_dump
        :if={Map.has_key?(assigns, :draft_reflector_path)}
        label="Context Dump on Discussions"
        draft_reflector_path={@draft_reflector_path}
        reply_to={@reply_to}
        reflected={@sheaf_lattice |> Map.get(@draft_reflector_path.labels)}
        reflected_ui={@sheaf_ui_lattice |> Map.get(@draft_reflector_path.labels)}
      /> -->
      <div id="content-display" class="mx-auto max-w-4xl pb-16 w-full">
        <.header class="m-8 ml-0">
          <div class="font-dn text-4xl">
            Discussions
          </div>
          <br />
          <div class="font-dn text-xl">
            <% num_active_root_sheaves = Enum.count(@root_sheaves || []) %>
            <% num_comments = Enum.count(Map.keys(@sheaf_lattice || %{})) %>
            <%= num_active_root_sheaves %> <%= Inflex.inflect("thread", num_active_root_sheaves) %> with a total of <%= num_comments %> <%= Inflex.inflect(
              "comment",
              num_comments
            ) %>
          </div>
        </.header>
        <.sheaf_creator_modal
          :if={
            Map.has_key?(assigns, :draft_reflector_path) &&
              not is_nil(@draft_reflector_path)
          }
          id="sheaf-creator"
          session={@session}
          reply_to={@reply_to}
          draft_sheaf={
            @sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(@draft_reflector_path.labels)
          }
          draft_sheaf_ui={
            @sheaf_ui_lattice |> SheafLattice.get_sheaf_from_lattice(@draft_reflector_path.labels)
          }
          event_target="#content-display"
        />

        <%= if not is_nil(@sheaf_lattice) do %>
          <div id="dump-check">
            <!--  <.debug_dump
              :if={
                Map.has_key?(assigns, :draft_reflector_path) &&
                  not is_nil(@draft_reflector_path)
              }
              label="CHECK SHEAF CREATOR MODAL INPUTS"
              draft_sheaf_ui={
                @sheaf_ui_lattice |> SheafLattice.get_sheaf_from_lattice(@draft_reflector_path.labels)
              }
              draft_sheaf={
                @sheaf_lattice |> SheafLattice.get_sheaf_from_lattice(@draft_reflector_path.labels)
              }
              event_target="#content-display"
            /> -->
          </div>

          <div :for={
            root_sheaf <-
              @root_sheaves
          }>
            <.root_sheaf
              events_target="#content-display"
              reply_to={@reply_to}
              sheaf={root_sheaf}
              sheaf_lattice={@sheaf_lattice}
              sheaf_ui_lattice={@sheaf_ui_lattice}
              on_replies_click={JS.push("ui::toggle_sheaf_is_expanded?", target: "#content-display")}
              on_quick_reply={JS.push("sheaf::toggle_quick_reply", target: "#content-display")}
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
