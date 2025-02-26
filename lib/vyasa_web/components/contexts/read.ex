defmodule VyasaWeb.Context.Read do
  @moduledoc """
  The Read Context defines state handling related to the "Read" user mode.
  """
  use VyasaWeb, :live_component

  @default_lang "en"
  @default_voice_lang "sa"
  alias VyasaWeb.ModeLive.{UserMode}
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState
  alias Vyasa.Written
  alias VyasaWeb.Utils.Stream
  alias Vyasa.Medium
  alias Vyasa.Written.{Source, Chapter, Verse}
  alias Phoenix.LiveView.Socket
  alias Vyasa.{Sangh, Bhaj}
  alias Vyasa.Sangh.{Mark, Sheaf}
  alias VyasaWeb.OgImageController
  alias VyasaWeb.MediaLive.MediaBridge
  import VyasaWeb.Context.Components

  @impl true
  def update(
        %{
          user_mode: %UserMode{} = user_mode,
          url_params: url_params,
          live_action: live_action,
          session: session,
          id: id
        } = _params,
        socket
      ) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(session: session)
      |> assign(user_mode: user_mode)
      |> apply_action(live_action, url_params)
    }
  end

  @impl true
  # received updates from parent liveview when a handshake is init with sesion, does a pub for the voice to use
  def update(
        %{id: "read", event: :media_handshake},
        %{
          assigns: %{
            chap: %Chapter{no: c_no, source_id: src_id}
          }
        } = socket
      ) do
    send(self(), %{
      process: MediaBridge,
      event: :ack_handshake,
      voice: fn -> Medium.get_voice(src_id, c_no, @default_voice_lang) end,
      origin: __MODULE__
    })

    {:ok, socket}
  end

  # @bala @ritesh this msg recipient is for the flat version
  @impl true
  # received updates from parent liveview when a handshake is init with sesion, does a pub for the voice to use
  def update(
        %{
          id: "read",
          event: :set_cursor_in_tracklist,
          tracklist_cursor: tracklist_cursor,
          track_id: track_id,
          tracklist_id: tracklist_id,
          verse_id: verse_id,
          chapter_no: chapter_no,
          source_id: source_id,
          source: source
        },
        %{
          assigns: %{
            content_action: :show_tracks,
            tracklist_cursor: curr_cursor,
            tracklist_id: curr_tracklist
            # chap: %Chapter{no: _c_no, source_id: _src_id}
          }
        } = socket
      ) do
    # send(self(), %{
    #   process: MediaBridge,
    #   event: :ack_handshake,
    #   voice: fn -> Medium.get_voice(src_id, c_no, @default_voice_lang) end,
    #   origin: __MODULE__
    # })

    IO.puts("WALDO is IN READ MODE")
    dbg()

    {:ok, socket}
  end

  # @bala @ritesh this msg recipient is for the flat version
  @impl true
  # received updates from parent liveview when a handshake is init with sesion, does a pub for the voice to use
  def update(
        %{
          id: "read",
          event: :set_cursor_in_tracklist,
          tracklist_cursor: tracklist_cursor,
          track_id: track_id,
          tracklist_id: tracklist_id,
          verse_id: verse_id,
          chapter_no: chapter_no,
          source_id: source_id,
          source: source
        },
        %{
          assigns: %{
            content_action: :show_verses,
            tracklist_cursor: curr_cursor,
            tracklist_id: curr_tracklist
            # chap: %Chapter{no: _c_no, source_id: _src_id}
          }
        } = socket
      ) do
    # send(self(), %{
    #   process: MediaBridge,
    #   event: :ack_handshake,
    #   voice: fn -> Medium.get_voice(src_id, c_no, @default_voice_lang) end,
    #   origin: __MODULE__
    # })

    IO.puts("WALDO is IN READ MODE")
    dbg()

    {:ok, socket}
  end

  # @bala use this to do the check if correct url and push patch prior to calling the  emphasis event
  @impl true
  # received updates from parent liveview when a handshake is init with sesion, does a pub for the voice to use
  def update(
        %{id: "read", event: :media_handshake},
        %{
          assigns: %{
            content_action: :show_tracks,
            tracklist_loader: tracklist_loader,
            tracklist_id: tracklist_id,
            tracklist_cursor: tracklist_cursor
          }
        } = socket
      ) do
    IO.inspect(tracklist_id,
      label: "WALDO Received media handshake for :show_tracks where tracklist = #{tracklist_id}"
    )

    send(self(), %{
      process: MediaBridge,
      event: :load_tracklist,
      tracklist_loader: tracklist_loader,
      tracklist_cursor: tracklist_cursor,
      origin: __MODULE__
    })

    {:ok, socket}
  end

  # received changes to binding

  def update(
        %{id: "read", binding: bind = %{verse_id: verse_id}},
        %{
          assigns: %{
            kv_verses: verses,
            draft_reflector:
              %Sheaf{
                marks: [%Mark{state: :draft, verse_id: curr_verse_id} = d_mark | marks]
              } = draft_reflector
          }
        } = socket
      )
      when is_binary(curr_verse_id) and verse_id != curr_verse_id do
    # binding here blocks the stream from appending to quote
    #
    bound_verses =
      verses
      |> then(&put_in(&1[verse_id].binding, bind))
      |> then(&put_in(&1[curr_verse_id].binding, nil))

    updated_draft_mark = d_mark |> Mark.update_mark(%{binding: bind, verse_id: verse_id})

    {:ok,
     socket
     |> mutate_verses(curr_verse_id, bound_verses)
     |> mutate_verses(verse_id, bound_verses)
     |> assign(draft_reflector: %Sheaf{draft_reflector | marks: [updated_draft_mark | marks]})}
  end

  # already in mark in drafting state, remember to late bind binding => with a fn()
  def update(
        %{id: "read", binding: bind = %{verse_id: verse_id}},
        %{
          assigns: %{
            kv_verses: verses,
            draft_reflector:
              %Sheaf{
                marks: [%Mark{state: :draft} = d_mark | marks]
              } = draft_reflector
          }
        } = socket
      ) do
    # binding here blocks the stream from appending to quote
    bound_verses = put_in(verses[verse_id].binding, bind)
    updated_draft_mark = d_mark |> Mark.update_mark(%{binding: bind, verse_id: verse_id})

    {:ok,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(draft_reflector: %Sheaf{draft_reflector | marks: [updated_draft_mark | marks]})
     |> push_event("bind::jump", bind)}
  end

  ## this is a dead clause to catch error states with draft_reflector to ensure the initial draft mark
  def update(
        %{id: "read", binding: bind = %{verse_id: verse_id}},
        %{
          assigns: %{
            kv_verses: verses,
            draft_reflector:
              %Sheaf{
                marks: [%Mark{} | _] = marks
              } = draft_reflector
          }
        } = socket
      ) do
    bound_verses = put_in(verses[verse_id].binding, bind)

    new_marks = [
      Mark.get_draft_mark(marks, %{verse_id: verse_id, binding: bind})
      | marks
    ]

    {:ok,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(draft_reflector: %Sheaf{draft_reflector | marks: new_marks})}
  end

  @impl true
  def update(assigns, socket) do
    IO.inspect(assigns, label: ">> POKEMON update within read")
    {:ok, socket}
  end

  defp apply_action(%Socket{} = socket, :show_sources, _params) do
    socket
    |> stream(:sources, Written.list_sources())
    |> assign(%{
      content_action: :show_sources,
      page_title: "Sources",
      meta: %{
        title: "Sources to Explore",
        description: "Explore the wealth of indic knowledge, distilled into words.",
        type: "website",
        image: url(~p"/images/the_vyasa_project_1.png"),
        url: url(socket, ~p"/explore/")
      }
    })
  end

  defp apply_action(
         %Socket{} = socket,
         :show_chapters,
         %{"source_title" => source_title} = params
       ) do
    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         [%Chapter{} | [%Chapter{} | _]] = chapters <-
           Written.list_chapters_by_source(sid, @default_lang) do
      # case 1: when there is more than 1 chapter
      socket
      |> assign(%{
        content_action: :show_chapters,
        page_title: to_title_case(source.title),
        source: source,
        meta: %{
          title: to_title_case(source.title),
          description: "Explore the #{to_title_case(source.title)}",
          type: "website",
          image: url(~p"/og/#{VyasaWeb.OgImageController.get_by_binding(%{source: source})}"),
          url: url(socket, ~p"/explore/#{source.title}")
        }
      })
      |> Stream.maybe_stream_configure(:chapters, dom_id: &"Chapter-#{&1.no}")
      |> stream(:chapters, chapters |> Enum.sort_by(& &1.no))

      # case 2: when there's a single chapter for the source, short circuit to show verses for that chapter
    else
      [%Chapter{} = chapter | _] ->
        socket
        |> apply_action(:show_verses, params |> Map.put("chap_no", chapter.no))

      _ ->
        raise VyasaWeb.ErrorHTML.FourOFour, message: "No Chapters here yet"
    end
  end

  defp apply_action(
         %Socket{} = socket,
         :show_verses,
         %{"source_title" => source_title, "chap_no" => chap_no}
       ) do
    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         %{verses: verses, translations: [ts | _], title: chap_title, body: chap_body} = chap <-
           Written.get_chapter(chap_no, sid, @default_lang) do
      desc_title = "#{to_title_case(source.title)} Chapter #{chap_no} | #{chap_title}"

      socket
      |> Stream.maybe_stream_configure(:verses, dom_id: &"verse-#{&1.id}")
      |> stream(:verses, verses)
      |> assign(%{
        kv_verses: Enum.into(verses, %{}, &{&1.id, &1}),
        content_action: :show_verses,
        src: source,
        lang: @default_lang,
        chap: chap,
        selected_transl: ts,
        page_title: desc_title,
        meta: %{
          title: desc_title,
          description: chap_body,
          type: "website",
          image:
            url(~p"/og/#{OgImageController.get_by_binding(%{chapter: chap, source: source})}"),
          url: url(socket, ~p"/explore/#{source.title}/#{chap_no}")
        }
      })
      |> init_drafting_context()
      |> init_reply_to_context()
      |> sync_media_bridge()
    else
      _ ->
        raise VyasaWeb.ErrorHTML.FourOFour, message: "Chapter not Found"
    end
  end

  # trackls and tracks
  defp apply_action(%Socket{} = socket, :show_tracklists, _params) do
    socket
    |> stream(:trackls, Bhaj.list_tracklists())
    |> assign(%{
      content_action: :show_tracklists,
      page_title: "Tracklists",
      meta: %{
        title: "Tracklists to follow and listen",
        description: "The hymns and bhajans of what is past, or passing, or to come",
        type: "website",
        image: url(~p"/images/the_vyasa_project_1.png"),
        url: url(socket, ~p"/explore/")
      }
    })
  end

  ### @bala here's how the injection is being done, we can hardcode inject the tracklist id and cursor and things will work as intended
  ## FIXME this should be tracks within a particular tracklist, needs tracklist id to be injected in via url params
  defp apply_action(%Socket{} = socket, :show_tracks, _params) do
    # FIXME: this is a static stub, for now, these can be injected via url params / slug
    tracklist_id = "fc4bb25c-41c0-447a-90c7-894d4f52b183"
    tracklist_cursor = 1

    tracklist =
      Vyasa.Bhaj.get_tracklist(tracklist_id)
      |> Vyasa.Repo.preload(tracks: [event: [:verse]])

    IO.inspect(tracklist.title, label: "showing tracks in tracklist")

    tracklist_loader = fn ->
      Vyasa.Bhaj.get_tracklist(tracklist_id)
      |> Vyasa.Repo.preload(tracks: [event: [verse: [:source, :chapter]]])
    end

    # send(self(), %{
    #   process: MediaBridge,
    #   event: :load_tracklist,
    #   tracklist_loader: tracklist_loader,
    #   origin: __MODULE__
    # })

    IO.puts("WALDO BEING SEARCHED")

    socket
    |> stream(:tracks, tracklist.tracks)
    # |> stream(:tracks, Bhaj.list_tracks())
    |> assign(%{
      tracklist_id: tracklist.id,
      content_action: :show_tracks,
      tracklist_cursor: tracklist_cursor,
      tracklist_loader: tracklist_loader,
      page_title: "Tracks in {tracklist.title}",
      meta: %{
        title: "Following the ",
        description: "Listen and follow along to {tracklist.title}",
        type: "website",
        image: url(~p"/images/the_vyasa_project_1.png"),
        url: url(socket, ~p"/explore/tracks/{tracklist.id}")
      }
    })
  end

  # fallthrough
  defp apply_action(%Socket{} = socket, _, _) do
    socket
  end

  # # syncs the media sessions by subscribing and publishing to the relevant channels
  defp sync_media_bridge(
         %Socket{assigns: %{chap: %Chapter{no: c_no, source_id: src_id}}} = socket
       ) do
    send(self(), %{
      process: MediaBridge,
      event: :ack_handshake,
      voice: fn -> Medium.get_voice(src_id, c_no, @default_voice_lang) end,
      origin: __MODULE__
    })

    socket
  end

  # fallthrough
  defp sync_media_bridge(socket) do
    socket
  end

  @doc """
  TODO: this functionis still a WIP, will be looked at when we are merging w the permalinking piece
  @ks0m1c this is to be shifted out, into the mediator so that the pattern would be that the mediator injects
  context into the MODE_CONTEXT (read context, discuss context)

  When we gather marks, we may have 2 cases for WHY we gather them:

  a) we intend to reply to a particular sheaf
    => if we create a new sheaf, the reply_to sheaf shall be the parent sheaf of the newly created sheaf

  b) we don't intend to reply to a particular sheaf
    => the reply_to sheaf is nil
    => if we create a new sheaf, it's a root sheaf for that session

   When we actually create the sheaf that contains the marks, they may be published as public or private,
   regardless of whether the intent is a) or b) above.

  [TBD: @ks0m1c]

  There are two main ways this reply to context can be set (implicitly):
  1) because it has been set in another mode (discuss mode) ==> the db is used to mediate this.
      => init_reply_to_context() reads from DB.
      By looking at the currently active draft sheaf, check it's parent id:
      1A: the parent is nil: so no reply_to sheaf
      1B: non-nil then load that parent sheaf as reply_to
  2) TODO  @ks0m1c via url params, as permalinked ==> this will take precendence over the db-based determining of reply_to_context
     --- /http://localhost:4000/<mode>/<binding_type>/id=xxx
     --- /http://localhost:4000/explore/<slug for chapter>/id=xxx
     --- /http://localhost:4000/discuss/sheaf/id=xxx
         ==> discuss mode shows the threads
     --- /http://localhost:4000/read/sheaf/id=xxx
         ==> reading mode
     ==> prioritise urls_params

  """
  def init_reply_to_context(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: _sangh_id}},
            draft_reflector: %Sheaf{
              parent_id: parent_id
            }
          }
        } = socket
      )
      when is_binary(parent_id) do
    socket
    |> assign(reply_to: Sangh.get_sheaf(parent_id))
  end

  def init_reply_to_context(%Socket{} = socket) do
    socket
    |> assign(reply_to: nil)
  end

  @doc """
  Handles the init for all things drafting, assuming that a valid
  sangh_id exists.

  This means that:
  1. there's a draft_reflector in the socket that we use to track the
     state of marks (not necessarily committed to the db yet).
     This is actually a %Sheaf{}

  2. there's a draft_reflector_ui that we use to track the state of all the marks
     that are currently tracked by the draft_reflector.
     This is actually a %SheafUiState{}

  3. Additionally, we also ensure that the first mark in the draft_reflector.marks list
     is a draft mark because the hoverrune binding context relies on this.

     TODO: possible refactor step would be to move this maybe_prepend_draft_mark_in_reflector()
     to the bind_hoverrune functions, but that would be a bigger refactor lift so have place that
     logic within the init subroutine for now.
  """
  def init_drafting_context(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: sangh_id}}
          }
        } = socket
      )
      when not is_nil(sangh_id) do
    socket
    |> init_draft_reflector()
    |> init_draft_reflector_ui()
    |> maybe_prepend_draft_mark_in_reflector()
  end

  # fallthrough
  def init_drafting_context(%Socket{} = socket) do
    socket
    |> assign(draft_reflector: %Sheaf{marks: [Mark.get_draft_mark()]})
    |> assign(draft_reflector_ui: nil)
  end

  @doc """
  Only initialises a draft reflector in the socket state. If there's no existing
  draft reflector(s) in the db, then we shall create a new draft sheaf.
  """
  def init_draft_reflector(
        %Socket{
          assigns: %{
            session: %{sangh: %{id: sangh_id}}
          }
        } = socket
      ) do
    draft_sheafs = sangh_id |> Vyasa.Sangh.get_sheafs_by_session(%{traits: ["draft"]})

    case draft_sheafs do
      [%Sheaf{} = draft_sheaf | _] ->
        socket
        |> assign(draft_reflector: draft_sheaf)

      _ ->
        socket
        |> assign(draft_reflector: Sheaf.draft!(sangh_id))
    end
  end

  @doc """
  The ui states for marks within the draft reflector will be tracked using the
  draft_reflector_ui.
  This will just rely on the exposed init functions within SheafUiState module
  for this init routine.
  """
  def init_draft_reflector_ui(
        %Socket{
          assigns: %{
            draft_reflector: %Sheaf{} = draft_reflector,
            session: %{sangh: %{id: _sangh_id}}
          }
        } = socket
      ) do
    socket
    |> assign(draft_reflector_ui: draft_reflector |> SheafUiState.get_initial_ui_state())
  end

  @doc """
  Helps ensure that the head of the mark in the reflector will be a draft mark.

  If such a draft mark actually is inserted, then we will need to register it in the draft_reflector_ui as well.

  Precondition:
  1. the draft_reflector_ui must already exist
  """
  def maybe_prepend_draft_mark_in_reflector(
        %Socket{
          assigns: %{
            draft_reflector: %Sheaf{marks: marks} = draft_reflector,
            # requires the reflector ui to already exist
            draft_reflector_ui: %SheafUiState{},
            session: %{sangh: %{id: _sangh_id}}
          }
        } = socket
      ) do
    possible_new_draft = Mark.get_draft_mark()

    case marks do
      # case 1: has existing draft marks, no change needed
      [%Mark{state: :draft} | _] = _existing_marks ->
        socket

      # case 2: has existing marks that are non-draft, but 0 draft marks:
      [%Mark{} | _] = existing_marks ->
        socket
        |> assign(
          draft_reflector: %Sheaf{
            draft_reflector
            | marks: [possible_new_draft | existing_marks]
          }
        )
        |> ui_register_mark(possible_new_draft.id)

      # case 3 no existing marks:
      _ ->
        socket
        |> assign(
          draft_reflector: %Sheaf{
            draft_reflector
            | marks: [possible_new_draft]
          }
        )
        |> ui_register_mark(possible_new_draft.id)
    end
  end

  @impl true
  def handle_event(
        "ui::toggle_marks_display_collapsibility",
        %{"value" => _},
        %Socket{
          assigns:
            %{
              draft_reflector_ui:
                %SheafUiState{
                  marks_ui: %MarksUiState{}
                } = draft_reflector_ui
            } = _assigns
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(
       draft_reflector_ui:
         draft_reflector_ui
         |> SheafUiState.toggle_marks_is_expanded_view()
     )
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "ui::toggle_is_editable_marks?",
        %{"value" => _},
        %Socket{
          assigns:
            %{
              draft_reflector_ui:
                %SheafUiState{
                  marks_ui: %MarksUiState{}
                } = _sheaf_ui_state
            } = _assigns
        } = socket
      ) do
    {:noreply,
     socket
     |> ui_toggle_is_editable_marks?()
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "ui::toggle_show_sheaf_modal?",
        _,
        %Socket{
          assigns:
            %{
              draft_reflector_ui:
                %SheafUiState{
                  marks_ui: %MarksUiState{} = _ui_state
                } = draft_reflector_ui
            } = _assigns
        } = socket
      ) do
    {
      :noreply,
      socket
      |> assign(draft_reflector_ui: draft_reflector_ui |> SheafUiState.toggle_show_sheaf_modal?())
      |> cascade_stream_change()
    }
  end

  @impl true
  def handle_event(
        "ui::toggle_show_sheaf_modal?",
        _,
        %Socket{} = socket
      ) do
    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "ui::toggle_is_editing_mark_content?",
        %{"mark_id" => mark_id} = _payload,
        %Socket{
          assigns:
            %{
              draft_reflector_ui:
                %SheafUiState{
                  marks_ui: %MarksUiState{}
                } = sheaf_ui_state
            } = _assigns
        } = socket
      ) do
    IO.puts("NICELY")

    {:noreply,
     socket
     |> assign(
       draft_reflector_ui:
         sheaf_ui_state
         |> SheafUiState.toggle_is_editing_mark_content?(mark_id)
     )
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "mark::editMarkContent",
        %{"mark_id" => id, "previous_mark_body" => _prev_body, "input" => body} =
          _payload,
        %Socket{
          assigns:
            %{
              draft_reflector:
                %Sheaf{
                  marks: [%Mark{} | _] = marks
                } = _draft_reflector,
              draft_reflector_ui:
                %SheafUiState{
                  marks_ui: %MarksUiState{} = _ui_state
                } = _draft_reflector_ui
            } = _assigns
        } = socket
      )
      when is_binary(body) do
    {[old_mark | _] = _old_versions_of_changed, updated_marks} =
      get_and_update_in(
        marks,
        [Access.filter(&match?(%Mark{id: ^id}, &1))],
        &{&1, Map.put(&1, :body, body)}
      )

    old_mark |> Vyasa.Draft.update_mark(%{body: body})

    {:noreply,
     socket
     |> commit_marks_in_reflector(updated_marks)
     |> ui_toggle_is_editing_mark_content(id)
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "dom_navigation::clickVerseToSeek",
        %{"verse_id" => verse_id} = _payload,
        %{assigns: %{session: %{id: sess_id}}} = socket
      ) do
    IO.inspect("handle_event::clickVerseToSeek media:session:#{sess_id}", label: "checkpoint")
    send(self(), %{payload: %{verse_id: verse_id}, event: :playback_sync, process: MediaBridge})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "read::nav_fwd",
        _,
        %{assigns: %{session: %{id: sess_id}}} = socket
      ) do
    IO.inspect("navigation forward media:session:#{sess_id}", label: "checkpoint")
    # Vyasa.PubSub.publish(%{verse_id: verse_id}, :playback_sync, "media:session:" <> sess_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "verses::focus_toggle_on_quick_mark_drafting",
        %{"key" => "Enter"} = _payload,
        %Socket{} = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "verses::focus_toggle_on_quick_mark_drafting",
        %{"is_focusing?" => is_focusing?} = _payload,
        %Socket{} = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [is_focusing?]})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "verses::focus_toggle_on_quick_mark_drafting",
        _payload,
        %Socket{} = socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "mark::createMark",
        %{"body" => body},
        %{
          assigns: %{
            draft_reflector:
              %Sheaf{
                marks: [
                  %Mark{state: :draft, id: mark_id} = draft_mark
                  | rest_marks
                ]
              } = _draft_reflector
          }
        } = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    new_mark = %Mark{
      draft_mark
      | id: if(not is_nil(mark_id), do: Ecto.UUID.generate(), else: mark_id),
        order: Mark.get_next_order(rest_marks),
        body: body,
        state: :live
    }

    {
      :noreply,
      socket
      |> commit_marks_in_reflector([new_mark | rest_marks])
      |> ui_register_mark(new_mark.id)
      |> cascade_stream_change()
    }
  end

  # when user remains on the the same binding
  # TODO: prevent empty both (quote, mark body) from being submitted
  def handle_event(
        "mark::createMark",
        %{"body" => body},
        %{
          assigns: %{
            draft_reflector:
              %Sheaf{
                marks:
                  [%Mark{state: :live} = sibling_mark | _] =
                    all_marks
              } = _draft_reflector
          }
        } = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    new_mark =
      sibling_mark
      |> Mark.update_mark(%{
        id: Ecto.UUID.generate(),
        order: Mark.get_next_order(all_marks),
        body: body,
        state: :live
      })

    {:noreply,
     socket
     |> commit_marks_in_reflector([new_mark | all_marks])
     |> ui_register_mark(new_mark.id)
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "mark::createMark",
        _event,
        %Socket{} = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "mark::tombMark",
        %{"id" => id},
        %{
          assigns: %{
            draft_reflector:
              %Sheaf{
                marks: [%Mark{} | _] = marks
              } = _draft_reflector
          }
        } = socket
      ) do
    {
      :noreply,
      socket
      |> commit_marks_in_reflector(marks |> Mark.edit_mark_in_marks(id, %{state: :tomb}))
      |> ui_deregister_mark(id)
      |> cascade_stream_change()
    }
  end

  @impl true
  def handle_event(
        "quote::markQuote",
        _,
        %{
          assigns: %{
            draft_reflector:
              %Sheaf{
                marks: [%Mark{state: :draft} = d_mark | marks]
              } = draft_reflector
          }
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(
       draft_reflector: %Sheaf{
         draft_reflector
         | marks: [%Mark{d_mark | state: :live} | marks]
       }
     )}
  end

  @impl true
  def handle_event("quote::markQuote", _, socket) do
    {:noreply, socket}
  end

  @impl true
  # TODO: @ks0m1c sheaf crud -- event handler [TODO testing needed by @rtshkmr if this works as required]
  # This function handles the case where there's a parent sheaf in the reply_to context.
  # What should happen:
  # 1. since this is NOT a ROOT sheaf, the existing draft sheaf should be updated and promoted to a pulished sheaf AND it needs to be associated to the parent sheaf (in the reply to context).
  #    => also, that should also be the new, active sheaf since it just got created (NOT SURE ABOUT THIS)
  # 2. no need to add in a new draft sheaf because the init_reply_to_context() will handle it for us.
  #
  # Consider the current implementation of init_draft_reflector when writing this out. The draft sheaf used for the draft_reflector may
  # be fetched from the DB (or may have been generated without being pushed in).
  # If it was fetched from the DB, then this creation step needs to ensure that entry needs to be updated/delete.
  #
  # TODO: @ks0m1c [this can be done another time, or now]
  # There's some more cases to handle:
  # 1. if it's a private sheaf ==> needs to be associated with the user's private sangh session id
  # 2. if it's a public sheaf ==> (no change) keep usingthe current sangh session id
  #
  def handle_event(
        "sheaf::publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            marks_ui: %MarksUiState{} = ui_state,
            reply_to: %Sheaf{} = parent_sheaf,
            draft_reflector: %Sheaf{} = draft_sheaf,
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      )
      when not is_nil(parent_sheaf) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION"
    )

    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        parent: parent_sheaf,
        signature: username
      }
    )

    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> cascade_stream_change()}
  end

  # TODO: @ks0m1c since this is a root sheaf, no parent to associate.
  # This function shall:
  # 1. update (promote) this current draft sheaf in the reflector to a published sheaf
  #
  # TODO @ks0m1c same 2 cases as before: A) it's a private sheaf ==> use private sangh session B) it's a public sheaf
  # creates a root sheaf, no parent associated
  def handle_event(
        "sheaf::publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            draft_reflector: %Sheaf{} = draft_sheaf,
            draft_reflector_ui: %SheafUiState{
              marks_ui: %MarksUiState{} = _ui_state
            },
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      ) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION without parent"
    )

    # current_sheaf_id context is always inherited from the in-context window
    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        signature: username
      }
    )

    {:noreply,
     socket
     |> ui_toggle_show_sheaf_modal?()
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> maybe_prepend_draft_mark_in_reflector()
     |> cascade_stream_change()}
  end

  # fallback:
  def handle_event(
        "sheaf:create_sheaf",
        _params,
        %Socket{} = socket
      ) do
    IO.puts("sheaf:create_sheaf:pokemon")
    {:noreply, socket}
  end

  @impl true
  # TODO: @ks0m1c sheaf crud -- event handler [TODO testing needed by @rtshkmr if this works as required]
  # This function handles the case where there's a parent sheaf in the reply_to context.
  # What should happen:
  # 1. since this is NOT a ROOT sheaf, the existing draft sheaf should be updated and promoted to a pulished sheaf AND it needs to be associated to the parent sheaf (in the reply to context).
  #    => also, that should also be the new, active sheaf since it just got created (NOT SURE ABOUT THIS)
  # 2. no need to add in a new draft sheaf because the init_reply_to_context() will handle it for us.
  #
  # Consider the current implementation of init_draft_reflector when writing this out. The draft sheaf used for the draft_reflector may
  # be fetched from the DB (or may have been generated without being pushed in).
  # If it was fetched from the DB, then this creation step needs to ensure that entry needs to be updated/delete.
  #
  # TODO: @ks0m1c [this can be done another time, or now]
  # There's some more cases to handle:
  # 1. if it's a private sheaf ==> needs to be associated with the user's private sangh session id
  # 2. if it's a public sheaf ==> (no change) keep usingthe current sangh session id
  #
  def handle_event(
        "sheaf::publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            marks_ui: %MarksUiState{} = ui_state,
            reply_to: %Sheaf{} = parent_sheaf,
            draft_reflector: %Sheaf{} = draft_sheaf,
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      )
      when not is_nil(parent_sheaf) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION"
    )

    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        parent: parent_sheaf,
        signature: username
      }
    )

    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> cascade_stream_change()}
  end

  # TODO: @ks0m1c since this is a root sheaf, no parent to associate.
  # This function shall:
  # 1. update (promote) this current draft sheaf in the reflector to a published sheaf
  #
  # TODO @ks0m1c same 2 cases as before: A) it's a private sheaf ==> use private sangh session B) it's a public sheaf
  # creates a root sheaf, no parent associated
  def handle_event(
        "sheaf::publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            draft_reflector: %Sheaf{} = draft_sheaf,
            draft_reflector_ui: %SheafUiState{
              marks_ui: %MarksUiState{} = _ui_state
            },
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      ) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION without parent"
    )

    # current_sheaf_id context is always inherited from the in-context window
    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        signature: username
      }
    )

    {:noreply,
     socket
     |> ui_toggle_show_sheaf_modal?()
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> maybe_prepend_draft_mark_in_reflector()
     |> cascade_stream_change()}
  end

  @impl true
  # TODO: @ks0m1c sheaf crud -- event handler
  # This function handles the case where there's a parent sheaf in the reply_to context.
  # What should happen:
  # 1. since this is NOT a ROOT sheaf, the existing draft sheaf should be updated and promoted to a pulished sheaf AND it needs to be associated to the parent sheaf (in the reply to context).
  #    => also, that should also be the new, active sheaf since it just got created (NOT SURE ABOUT THIS)
  # 2. no need to add in a new draft sheaf because the init_reply_to_context() will handle it for us.
  #
  # Consider the current implementation of init_draft_reflector when writing this out. The draft sheaf used for the draft_reflector may
  # be fetched from the DB (or may have been generated without being pushed in).
  # If it was fetched from the DB, then this creation step needs to ensure that entry needs to be updated/delete.
  #
  # TODO: @ks0m1c [this can be done another time, or now]
  # There's some more cases to handle:
  # 1. if it's a private sheaf ==> needs to be associated with the user's private sangh session id
  # 2. if it's a public sheaf ==> (no change) keep usingthe current sangh session id
  #
  def handle_event(
        "sheaf:publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            marks_ui: %MarksUiState{} = ui_state,
            reply_to: %Sheaf{} = parent_sheaf,
            draft_reflector: %Sheaf{} = draft_sheaf,
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      )
      when not is_nil(parent_sheaf) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION"
    )

    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        parent: parent_sheaf,
        signature: username
      }
    )

    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> cascade_stream_change()}
  end

  # TODO: @ks0m1c since this is a root sheaf, no parent to associate.
  # This function shall:
  # 1. update (promote) this current draft sheaf in the reflector to a published sheaf
  #
  # TODO @ks0m1c same 2 cases as before: A) it's a private sheaf ==> use private sangh session B) it's a public sheaf
  # creates a root sheaf, no parent associated
  def handle_event(
        "sheaf:publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            marks_ui: %MarksUiState{} = ui_state,
            draft_reflector: %Sheaf{} = draft_sheaf,
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      ) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION without parent"
    )

    # current_sheaf_id context is always inherited from the in-context window
    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        signature: username
      }
    )

    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> cascade_stream_change()}
  end

  @impl true
  # TODO: @ks0m1c sheaf crud -- event handler
  # This function handles the case where there's a parent sheaf in the reply_to context.
  # What should happen:
  # 1. since this is NOT a ROOT sheaf, the existing draft sheaf should be updated and promoted to a pulished sheaf AND it needs to be associated to the parent sheaf (in the reply to context).
  #    => also, that should also be the new, active sheaf since it just got created (NOT SURE ABOUT THIS)
  # 2. no need to add in a new draft sheaf because the init_reply_to_context() will handle it for us.
  #
  # Consider the current implementation of init_draft_reflector when writing this out. The draft sheaf used for the draft_reflector may
  # be fetched from the DB (or may have been generated without being pushed in).
  # If it was fetched from the DB, then this creation step needs to ensure that entry needs to be updated/delete.
  #
  # TODO: @ks0m1c [this can be done another time, or now]
  # There's some more cases to handle:
  # 1. if it's a private sheaf ==> needs to be associated with the user's private sangh session id
  # 2. if it's a public sheaf ==> (no change) keep usingthe current sangh session id
  #
  def handle_event(
        "sheaf:publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            marks_ui: %MarksUiState{} = ui_state,
            reply_to: %Sheaf{} = parent_sheaf,
            draft_reflector: %Sheaf{} = draft_sheaf,
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      )
      when not is_nil(parent_sheaf) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION"
    )

    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        parent: parent_sheaf,
        signature: username
      }
    )

    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> cascade_stream_change()}
  end

  # TODO: @ks0m1c since this is a root sheaf, no parent to associate.
  # This function shall:
  # 1. update (promote) this current draft sheaf in the reflector to a published sheaf
  #
  # TODO @ks0m1c same 2 cases as before: A) it's a private sheaf ==> use private sangh session B) it's a public sheaf
  # creates a root sheaf, no parent associated
  def handle_event(
        "sheaf:publish",
        %{
          "body" => body,
          "is_private" => is_private
        } = _params,
        %Socket{
          assigns: %{
            marks_ui: %MarksUiState{} = ui_state,
            draft_reflector: %Sheaf{} = draft_sheaf,
            session: %VyasaWeb.Session{
              name: username,
              sangh: %Vyasa.Sangh.Session{
                id: sangh_id
              }
            }
          }
        } = socket
      ) do
    IO.inspect(%{body: body, is_private: is_private},
      label: "SHEAF CREATION without parent"
    )

    # current_sheaf_id context is always inherited from the in-context window
    Vyasa.Sangh.update_sheaf(
      draft_sheaf,
      %{
        body: body,
        traits: ["published"],
        signature: username
      }
    )

    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
     |> assign(draft_reflector: Sheaf.draft!(sangh_id))
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event("dummy_event", _params, socket) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.puts("Dummy event triggered")

    {:noreply, socket}
  end

  @impl true
  def handle_event(event_name, params, socket) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.inspect(%{event_name: event_name, params: params, socket_assigns: socket.assigns},
      label: "POKEMON READ CONTEXT EVENT HANDLING"
    )

    {:noreply, socket}
  end

  @impl true
  # TODO: UI-polish: prevent the button click for creating sheaf if there's no active sheaf (no reflected sheaf)
  # TODO: sheaf-crud: reply_to is currently set to the same as the active_sheaf
  def render(assigns) do
    ~H"""
    <div id={@id} class="flex-grow">
      <!-- CONTENT DISPLAY: -->
      <div id="content-display" class="mx-auto max-w-2xl">
        <.debug_dump
          label="Read Mode State Checks"
          content_action={@content_action}
          tracklist_cursor={@tracklist_cursor}
          tracklist_id={@tracklist_id}
        />
        <.live_component
          :if={@content_action == :show_sources}
          module={VyasaWeb.Context.Read.Sources}
          id="content-sources"
          sources={@streams.sources}
          user_mode={@user_mode}
        />

        <.live_component
          :if={@content_action == :show_chapters}
          module={VyasaWeb.Context.Read.Chapters}
          id="content-chapters"
          source={@source}
          chapters={@streams.chapters}
          user_mode={@user_mode}
        />

        <.live_component
          :if={@content_action == :show_tracklists}
          module={VyasaWeb.Context.Read.Tracklists}
          id="content-tracklists"
          #
          tracklists={@streams.trackls}
          user_mode={@user_mode}
        />

        <.live_component
          :if={@content_action == :show_tracks}
          module={VyasaWeb.Context.Read.Tracks}
          id="content-tracks"
          tracks={@streams.tracks}
          user_mode={@user_mode}
        />

        <%= if @content_action == :show_verses && not is_nil(@draft_reflector_ui) && not is_nil(@draft_reflector) do %>
          <!-- <.debug_dump
            label="Sheaf Creator"
            class="relative"
            session={@session}
            marks={@draft_reflector.marks}
            marks_ui={@draft_reflector_ui.marks_ui}
            reply_to={@reply_to}
            active_sheaf={@draft_reflector}
            event_target="#content-display"
          /> -->
          <.sheaf_creator_modal
            id="sheaf-creator"
            session={@session}
            marks={@draft_reflector.marks}
            marks_ui={@draft_reflector_ui.marks_ui}
            reply_to={@reply_to}
            active_sheaf={@draft_reflector}
            event_target="#content-display"
          />
          <.live_component
            module={VyasaWeb.Context.Read.Verses}
            id="content-verses"
            src={@src}
            verses={@streams.verses}
            chap={@chap}
            marks={@draft_reflector.marks}
            marks_ui={@draft_reflector_ui.marks_ui}
            lang={@lang}
            selected_transl={@selected_transl}
            page_title={@page_title}
            user_mode={@user_mode}
          />
        <% end %>
      </div>
    </div>
    """
  end

  # Helper function for updating verse state across both stream and the k_v map
  defp mutate_verses(%Socket{} = socket, target_verse_id, mutated_verses) do
    socket
    |> stream_insert(
      :verses,
      mutated_verses[target_verse_id]
    )
    |> assign(:kv_verses, mutated_verses)
  end

  @doc """
  Commits the marks by persisting them in the db, and updates the draft reflector.
  We are using a reflector so that we can choose when to commit the marks being
  accumulated.

  When committing, marks shall be sanitised.

  NOTE that the responsiblity of updating the aux ui struct shall not be owned by this function.
  """
  def commit_marks_in_reflector(
        %Socket{
          assigns: %{
            draft_reflector: %Vyasa.Sangh.Sheaf{} = curr_sheaf
          }
        } = socket,
        [%Mark{} | _] = new_marks
      ) do
    sanitised_marks = new_marks |> Mark.sanitise_marks()

    {:ok, written_sheaf} = Vyasa.Sangh.update_sheaf(curr_sheaf, %{marks: sanitised_marks})

    socket
    |> assign(draft_reflector: written_sheaf)
    |> maybe_prepend_draft_mark_in_reflector()
  end

  # inserts an existing verse back into its stream to
  # trigger dom updates:
  defp cascade_stream_change(
         %Socket{
           assigns: %{
             kv_verses: verses,
             streams: %{verses: _current_verses} = _streams,
             draft_reflector:
               %Sheaf{
                 marks: [%Mark{} | _] = _marks
               } = _draft_reflector
           }
         } = socket
       ) do
    %Verse{
      id: v_id,
      binding: binding
    } =
      Map.values(verses)
      |> Enum.find(fn v -> not is_nil(v.binding) end)

    socket
    |> stream_insert(
      :verses,
      %{verses[v_id] | binding: binding}
    )
  end

  # fallthrough
  defp cascade_stream_change(socket) do
    socket
  end

  defp ui_toggle_is_editable_marks?(
         %Socket{
           assigns: %{
             draft_reflector_ui:
               %SheafUiState{
                 marks_ui: %MarksUiState{} = _marks_ui
               } = ui
           }
         } = socket
       ) do
    socket
    |> assign(draft_reflector_ui: ui |> SheafUiState.toggle_is_editable_marks?())
  end

  defp ui_toggle_is_editing_mark_content(
         %Socket{
           assigns: %{
             draft_reflector_ui:
               %SheafUiState{
                 marks_ui: %MarksUiState{} = marks_ui
               } = ui
           }
         } = socket,
         id
       ) do
    socket
    |> assign(
      draft_reflector_ui: %SheafUiState{
        ui
        | marks_ui: marks_ui |> MarksUiState.toggle_is_editing_mark_content(id)
      }
    )
  end

  defp ui_toggle_show_sheaf_modal?(
         %Socket{
           assigns: %{
             draft_reflector_ui:
               %SheafUiState{
                 marks_ui: %MarksUiState{} = marks_ui
               } = ui
           }
         } = socket
       ) do
    socket
    |> assign(
      draft_reflector_ui: %SheafUiState{
        ui
        | marks_ui: marks_ui |> MarksUiState.toggle_show_sheaf_modal?()
      }
    )
  end

  defp ui_register_mark(
         %Socket{
           assigns: %{
             draft_reflector_ui: %SheafUiState{} = ui
           }
         } = socket,
         id
       ) do
    socket
    |> assign(draft_reflector_ui: ui |> SheafUiState.register_mark(id))
  end

  defp ui_deregister_mark(
         %Socket{
           assigns: %{
             draft_reflector_ui: %SheafUiState{} = ui
           }
         } = socket,
         id
       ) do
    socket
    |> assign(draft_reflector_ui: ui |> SheafUiState.deregister_mark(id))
  end
end
