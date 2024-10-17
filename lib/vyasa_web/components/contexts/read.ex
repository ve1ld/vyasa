defmodule VyasaWeb.Context.Read do
  @moduledoc """
  The Read Context defines state handling related to the "Read" user mode.
  """
  use VyasaWeb, :live_component

  @default_lang "en"
  @default_voice_lang "sa"
  alias VyasaWeb.ModeLive.{UserMode}
  alias VyasaWeb.Context.Components.UiState.Marks, as: MarksUiState
  alias Vyasa.{Written, Draft}
  alias Vyasa.Medium
  alias Vyasa.Medium.{Voice}
  alias Vyasa.Written.{Source, Chapter}
  alias Phoenix.LiveView.Socket
  alias Vyasa.Sangh.{Mark, Sheaf}
  alias VyasaWeb.OgImageController
  import VyasaWeb.Context.Components

  @impl true
  def update(
        %{
          user_mode: %UserMode{} = user_mode,
          url_params: url_params,
          live_action: live_action,
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
      |> apply_action(live_action, url_params)
    }
  end

  @impl true
  # received updates from parent liveview when a handshake is init with sesion, does a pub for the voice to use
  def update(
        %{id: "read"} = _props,
        %{
          assigns: %{
            session: %{id: sess_id},
            chap: %Chapter{no: c_no, source_id: src_id}
          }
        } = socket
      ) do
    case Medium.get_voice(src_id, c_no, @default_voice_lang) do
      %Voice{} = v ->
        Vyasa.PubSub.publish(
          v,
          :voice_ack,
          sess_id
        )

      _ ->
        nil
    end

    {:ok, socket}
  end

  @impl true
  def update(_assigns, socket) do
    {:ok, socket}
  end

  defp apply_action(%Socket{} = socket, :show_sources, _params) do
    IO.inspect(:show_sources, label: "TRACE: apply action DM action show_sources:")

    socket
    |> stream(:sources, Written.list_sources())
    |> assign(:content_action, :show_sources)
    |> assign(:page_title, "Sources")
    |> assign(:meta, %{
      title: "Sources to Explore",
      description: "Explore the wealth of indic knowledge, distilled into words.",
      type: "website",
      image: url(~p"/images/the_vyasa_project_1.png"),
      url: url(socket, ~p"/explore/")
    })
  end

  defp apply_action(
         %Socket{} = socket,
         :show_chapters,
         %{"source_title" => source_title} =
           params
       ) do
    IO.inspect(:show_chapters, label: "TRACE: apply action DM action show_chapters:")
    IO.inspect(params, label: "TRACE: apply action DM params:")
    IO.inspect(source_title, label: "TRACE: apply action DM params source_title:")

    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         # when is more than 1 chapter
         [%Chapter{} | [%Chapter{} | _]] = chapters <-
           Written.list_chapters_by_source(sid, @default_lang) do
      socket
      |> assign(:content_action, :show_chapters)
      |> assign(:page_title, to_title_case(source.title))
      |> assign(:source, source)
      |> assign(:meta, %{
        title: to_title_case(source.title),
        description: "Explore the #{to_title_case(source.title)}",
        type: "website",
        image: url(~p"/og/#{VyasaWeb.OgImageController.get_by_binding(%{source: source})}"),
        url: url(socket, ~p"/explore/#{source.title}")
      })
      |> maybe_stream_configure(:chapters, dom_id: &"Chapter-#{&1.no}")
      |> stream(:chapters, chapters |> Enum.sort_by(fn chap -> chap.no end))
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
      fmted_title = to_title_case(source.title)

      socket
      |> assign(:content_action, :show_verses)
      |> init_draft_reflector()
      |> init_marks()
      |> sync_media_session()
      |> assign(
        :kv_verses,
        Enum.into(verses, %{}, &{&1.id, &1})
      )
      |> maybe_stream_configure(:verses, dom_id: &"verse-#{&1.id}")
      |> stream(:verses, verses)
      # DEPRECATED this src may not be needed OR RENAME src to something else??
      |> assign(:src, source)
      |> assign(:lang, @default_lang)
      |> assign(:chap, chap)
      |> assign(:selected_transl, ts)
      |> assign(:page_title, "#{fmted_title} Chapter #{chap_no} | #{chap_title}")
      |> assign(:meta, %{
        title: "#{fmted_title} Chapter #{chap_no} | #{chap_title}",
        description: chap_body,
        type: "website",
        image: url(~p"/og/#{OgImageController.get_by_binding(%{chapter: chap, source: source})}"),
        url: url(socket, ~p"/explore/#{source.title}/#{chap_no}")
      })
    else
      _ ->
        raise VyasaWeb.ErrorHTML.FourOFour, message: "Chapter not Found"
    end
  end

  defp apply_action(%Socket{} = socket, _, _) do
    socket
  end

  defp apply_action(socket, action, params) do
    IO.inspect(action, label: "TRACE: apply action DM action:")
    IO.inspect(params, label: "TRACE: apply action DM params:")

    socket
    |> assign(:page_title, "Sources")
  end

  # NOTE: This is needed because a stream can't be reconfigured.
  # Consider the case where we move from :show_chapters -> :show_verses -> :show_chapters.
  # In this case, because the state is held @ the live_view side (DM), we will end up with a situation
  # where the stream (e.g. chapters stream) would have already been configed.
  # Hence, a maybe_stream_configure/3 is necessary to avoid throwing an error.
  defp maybe_stream_configure(
         %Socket{
           assigns: assigns
         } = socket,
         stream_name,
         opts
       )
       when is_list(opts) do
    case Map.has_key?(assigns, :streams) && Map.has_key?(assigns.streams, stream_name) do
      true ->
        socket

      false ->
        socket |> stream_configure(stream_name, opts)
    end
  end

  defp maybe_stream_configure(%Socket{} = socket, _, _) do
    socket
  end

  # syncs the media sessions by subscribing and publishing to the relevant channels
  defp sync_media_session(%Socket{assigns: %{session: %{id: sess_id}}} = socket)
       when is_binary(sess_id) do
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)

    socket
  end

  defp sync_media_session(socket) do
    socket
  end

  @doc """
  Sets the initial value of the draft reflector.
  This is the reflection of the sheaf for which marks are currently being gathered for.

  Currently it takes the first draft sheaf in the session.

  This reflector is hot-swappable to other sheafs if there's a need to switch what
  sheaf to focus on and gather marks for.

  TODO: add other params-based sheaf-setting
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
      [%Sheaf{} = sheaf | _] ->
        socket
        |> assign(draft_reflector: sheaf)

      _ ->
        socket
        |> assign(draft_reflector: Sheaf.gen_first_sheaf(sangh_id))
    end
  end

  def init_draft_reflector(socket) do
    socket
  end

  @impl true
  def handle_event(
        "toggle_marks_display_collapsibility",
        %{"value" => _},
        %Socket{
          assigns:
            %{
              marks_ui: %MarksUiState{} = ui_state
            } = _assigns
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_is_expanded_view())
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "toggle_is_editable_marks?",
        %{"value" => _},
        %Socket{
          assigns:
            %{
              marks_ui: %MarksUiState{} = ui_state
            } = _assigns
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(marks_ui: ui_state |> MarksUiState.toggle_is_editable())
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "toggle_show_sheaf_modal?",
        _,
        %Socket{
          assigns:
            %{
              marks_ui: %MarksUiState{} = ui_state
            } = _assigns
        } = socket
      ) do
    {
      :noreply,
      socket
      |> assign(marks_ui: ui_state |> MarksUiState.toggle_show_sheaf_modal?())
      |> cascade_stream_change()
    }
  end

  @impl true
  def handle_event(
        "toggle_show_sheaf_modal?",
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
        "toggle_is_editing_mark_content?",
        %{"mark_id" => mark_id} = _payload,
        %Socket{
          assigns:
            %{
              marks_ui: %MarksUiState{} = ui_state
            } = _assigns
        } = socket
      ) do
    IO.puts("NICELY")

    {:noreply,
     socket
     |> assign(
       marks_ui:
         ui_state
         |> MarksUiState.toggle_is_editing_mark_content(mark_id)
     )
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "editMarkContent",
        %{"mark_id" => id, "mark_body" => body} = _payload,
        %Socket{
          assigns:
            %{
              marks: [%Mark{} | _] = marks,
              marks_ui: %MarksUiState{} = ui_state
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

    IO.inspect(old_mark, label: "oldmark for you to push down the stairs")

    {:noreply,
     socket
     |> assign(:marks, updated_marks)
     |> assign(
       :marks_ui,
       ui_state
       |> MarksUiState.toggle_is_editing_mark_content(id)
     )
     |> mutate_draft_reflector()
     |> cascade_stream_change()}
  end

  @impl true
  @doc """
  events

  "clickVersetoSeek" ->
  Handles the action of clicking to seek by emitting the verse_id to the live player
  via the pubsub system.

  "binding"
  """
  def handle_event(
        "clickVerseToSeek",
        %{"verse_id" => verse_id} = _payload,
        %{assigns: %{session: %{id: sess_id}}} = socket
      ) do
    IO.inspect("handle_event::clickVerseToSeek media:session:#{sess_id}", label: "checkpoint")
    Vyasa.PubSub.publish(%{verse_id: verse_id}, :playback_sync, "media:session:" <> sess_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{
          assigns: %{
            kv_verses: verses,
            marks: [%Mark{state: :draft, verse_id: curr_verse_id} = d_mark | marks]
          }
        } = socket
      )
      when is_binary(curr_verse_id) and verse_id != curr_verse_id do
    # binding here blocks the stream from appending to quote
    bind = Draft.bind_node(bind)

    bound_verses =
      verses
      |> then(&put_in(&1[verse_id].binding, bind))
      |> then(&put_in(&1[curr_verse_id].binding, nil))

    updated_draft_mark = d_mark |> Mark.update_mark(%{binding: bind, verse_id: verse_id})

    {:noreply,
     socket
     |> mutate_verses(curr_verse_id, bound_verses)
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [updated_draft_mark | marks])}
  end

  # already in mark in drafting state, remember to late bind binding => with a fn()
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind_target_payload = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do
    # binding here blocks the stream from appending to quote
    bind = Draft.bind_node(bind_target_payload)
    bound_verses = put_in(verses[verse_id].binding, bind)

    updated_draft_mark = d_mark |> Mark.update_mark(%{binding: bind, verse_id: verse_id})

    {:noreply,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [updated_draft_mark | marks])}
  end

  @impl true
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{} | _] = marks}} = socket
      ) do
    bind = Draft.bind_node(bind)
    bound_verses = put_in(verses[verse_id].binding, bind)

    IO.inspect(marks)

    new_draft_mark = Mark.get_draft_mark(marks, %{verse_id: verse_id, binding: bind})

    {:noreply,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [
       new_draft_mark | marks
     ])}
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
        "createMark",
        %{"body" => body},
        %{
          assigns: %{
            marks: [
              %Mark{state: :draft, id: mark_id} = draft_mark
              | rest_marks
            ]
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
      |> assign(:marks, [new_mark | rest_marks])
      |> mutate_draft_reflector()
      |> cascade_stream_change()
    }
  end

  # when user remains on the the same binding
  # TODO: prevent empty both (quote, mark body) from being submitted
  def handle_event(
        "createMark",
        %{"body" => body},
        %{
          assigns: %{
            marks:
              [%Mark{state: :live} = sibling_mark | _] =
                all_marks
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
     |> assign(:marks, [new_mark | all_marks])
     |> mutate_draft_reflector()
     |> cascade_stream_change()}
  end

  @impl true
  def handle_event(
        "createMark",
        _event,
        %Socket{} = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "tombMark",
        %{"id" => id},
        %{
          assigns: %{
            marks: [%Mark{} | _] = marks
          }
        } = socket
      ) do
    {
      :noreply,
      socket
      |> assign(:marks, marks |> Mark.edit_mark_in_marks(id, %{state: :tomb}))
      |> mutate_draft_reflector()
      |> cascade_stream_change()
    }
  end

  @impl true
  def handle_event(
        "markQuote",
        _,
        %{assigns: %{marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do
    {:noreply, socket |> assign(:marks, [%{d_mark | state: :live} | marks])}
  end

  @impl true
  def handle_event("markQuote", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("dummy_event", _params, socket) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.puts("Dummy event triggered")

    {:noreply, socket}
  end

  @impl true
  def handle_event(_event_name, _params, socket) do
    # Handle the event here (e.g., log it, update state, etc.)
    IO.puts("POKEMON READ CONTEXT EVENT HANDLING")
    # dbg()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <!-- CONTENT DISPLAY: -->
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <%= if @content_action == :show_sources do %>
          <.live_component
            module={VyasaWeb.Context.Read.Sources}
            id="content-sources"
            sources={@streams.sources}
            user_mode={@user_mode}
          />
        <% end %>

        <%= if @content_action == :show_chapters do %>
          <.live_component
            module={VyasaWeb.Context.Read.Chapters}
            id="content-chapters"
            source={@source}
            chapters={@streams.chapters}
            user_mode={@user_mode}
          />
        <% end %>

        <%= if @content_action == :show_verses do %>
          <.debug_dump label="UI State Info" marks_ui={@marks_ui} class="relative w-screen" />
          <.sheaf_creator_modal
            id="sheaf-creator"
            marks_ui={@marks_ui}
            event_target="content-display"
          />
          <.live_component
            module={VyasaWeb.Context.Read.Verses}
            id="content-verses"
            src={@src}
            verses={@streams.verses}
            chap={@chap}
            kv_verses={@kv_verses}
            marks={@marks}
            marks_ui={@marks_ui}
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

  # Helper function that syncs and mutates Draft Reflector
  defp mutate_draft_reflector(
         %{
           assigns: %{
             draft_reflector: %Vyasa.Sangh.Sheaf{} = curr_sheaf,
             marks: marks
           }
         } = socket
       ) do
    # IO.inspect(marks, label: "see the mark")
    {:ok, com} =
      Vyasa.Sangh.update_sheaf(curr_sheaf, %{
        marks: marks |> Mark.sanitise_marks()
      })

    socket
    |> assign(:draft_reflector, com)
  end

  # when session hasnt been initialised
  defp mutate_draft_reflector(socket) do
    socket
  end

  @doc """
  Initialises the following 3 state attributes that we use for managing marks:

  1. draft reflector:
     this is a reflection of the sheaf that we care about during interactions in
     the read mode.
  2. marks:
     the actual marks state, this strictly follows the invariant that the order
     of marks kept in the socket here will always be in descending order of their
     order attribute.
  3. marks_ui:
     ui state for the marks, this is currently just for the read mode.

  NOTE: during the init of marks, we will be mutating the draft reflector. This
  keeps the state of the draft marks on the db-side always sanitised.
  """
  def init_marks(
        %Socket{
          assigns: %{
            content_action: :show_verses,
            draft_reflector: draft_reflector
          }
        } = socket
      ) do
    IO.puts("INIT_MARKS")

    case draft_reflector do
      # handles head sheaf with existing marks:
      %Sheaf{marks: [_ | _] = marks} ->
        IO.puts("CHECKPOINT A")

        marks_with_draft =
          [marks |> Mark.get_draft_mark() | marks]
          |> Mark.sanitise_marks()

        socket
        |> assign(marks: marks_with_draft)
        |> assign(marks_ui: marks_with_draft |> MarksUiState.get_initial_ui_state())
        |> mutate_draft_reflector()

      # handles head sheaf without existing marks:
      %Sheaf{} ->
        IO.puts("CHECKPOINT B")
        marks = [Mark.get_draft_mark()]

        socket
        |> assign(marks: marks)
        |> assign(marks_ui: marks |> MarksUiState.get_initial_ui_state())
        |> mutate_draft_reflector()
    end
  end

  def init_marks(%Socket{} = socket) do
    IO.puts("INIT_MARKS POKEMON")
    marks = [Mark.get_draft_mark()]

    socket
    |> assign(marks: marks)
    |> assign(marks_ui: marks |> MarksUiState.get_initial_ui_state())
  end

  defp cascade_stream_change(
         %Socket{
           assigns: %{
             kv_verses: verses,
             streams: %{verses: _current_verses} = _streams,
             marks: [%Mark{verse_id: v_id, binding: binding} | _] = _marks
           }
         } = socket
       ) do
    socket
    |> stream_insert(
      :verses,
      %{verses[v_id] | binding: binding}
    )
  end

  defp cascade_stream_change(socket) do
    socket
  end
end
