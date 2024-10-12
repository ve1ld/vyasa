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
  alias Vyasa.Sangh.{Mark}
  alias VyasaWeb.OgImageController

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
        send(self(), {"helm", ~p"/explore/#{source_title}/#{chapter.no}/"})

        socket

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
      initial_marks = [Mark.get_draft_mark()]

      socket
      |> assign(
        :kv_verses,
        # creates a map of verse_id_to_verses
        Enum.into(verses, %{}, &{&1.id, &1})
      )
      |> assign(:marks, initial_marks)
      |> assign(:marks_ui, MarksUiState.get_initial_ui_state(initial_marks))
      |> sync_session()
      |> assign(:content_action, :show_verses)
      |> maybe_stream_configure(:verses, dom_id: &"verse-#{&1.id}")
      |> stream(:verses, verses)
      # DEPRECATED
      # RENAME?
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

  defp sync_session(%Socket{assigns: %{session: %{id: sess_id}}} = socket)
       when is_binary(sess_id) do
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)

    socket
    |> init_draft_reflector()
  end

  defp sync_session(socket) do
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
     |> trigger_dom_refresh()}
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
     |> trigger_dom_refresh()}
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
     |> trigger_dom_refresh()}
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
    {:noreply,
     socket
     |> assign(:marks, marks |> Mark.edit_mark_in_marks(id, %{body: body}))
     |> assign(
       :marks_ui,
       ui_state
       |> MarksUiState.toggle_is_editing_mark_content(id)
     )
     |> trigger_dom_refresh()}
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
      |> trigger_dom_refresh()
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
     |> trigger_dom_refresh()}
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
      |> trigger_dom_refresh()
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
         %{assigns: %{draft_reflector: %Vyasa.Sangh.Sheaf{} = curr_sheaf, marks: marks}} = socket
       ) do
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

  # Allows us to get a reflection of the internal sangh session state and store it within
  # this component's state.
  # Currently, we shall do a naive hd lookup on the sheafs within the session.
  # We could filter the sheaf based on the active flag,
  # NOTE:
  # Tree like sheafs can be used to store nested collapsible topics (personal mark collection e.g.)
  # TODO: @ks0m1c combine the state handling for marks and sheaf by using the marks within the sheaf.
  # This will work well with the other TODO defined about the CRUD functions needed
  defp init_draft_reflector(%{assigns: %{session: %{sangh: %{id: sangh_id}}}} = socket) do
    case Vyasa.Sangh.get_sheafs_by_session(sangh_id, %{traits: ["draft"]}) do
      [%Vyasa.Sangh.Sheaf{marks: [_ | _] = marks} = sheaf | _] ->
        sanitised_marks = marks |> Mark.sanitise_marks()
        {:ok, com} = Vyasa.Sangh.update_sheaf(sheaf, %{marks: sanitised_marks})

        socket
        |> assign(draft_reflector: com)
        |> assign(marks: sanitised_marks |> Enum.reverse())
        |> assign(marks_ui: MarksUiState.get_initial_ui_state(sanitised_marks))

      [%Vyasa.Sangh.Sheaf{} = sheaf | _] ->
        socket
        |> assign(draft_reflector: sheaf)

      _ ->
        {:ok, com} =
          Vyasa.Sangh.create_sheaf(%{
            id: Ecto.UUID.generate(),
            session_id: sangh_id,
            traits: ["draft"]
          })

        socket
        |> assign(draft_reflector: com)
    end
  end

  defp init_draft_reflector(%{assigns: %{session: _}} = socket) do
    socket
  end

  defp trigger_dom_refresh(
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

  defp trigger_dom_refresh(socket) do
    socket
  end
end
