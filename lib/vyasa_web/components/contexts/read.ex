defmodule VyasaWeb.Context.Read do
  @moduledoc """
  The Read Context defines state handling related to the "Read" user mode.
  """
  use VyasaWeb, :live_component

  @default_lang "en"
  @default_voice_lang "sa"
  alias VyasaWeb.ModeLive.{UserMode}
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

      socket
      |> assign(
        :kv_verses,
        # creates a map of verse_id_to_verses
        Enum.into(verses, %{}, &{&1.id, &1})
      )
      |> assign(:marks, [%Mark{state: :draft, order: 0}])
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
    |> sync_draft_reflector()
  end

  defp sync_session(socket) do
    socket
  end

  @impl true
  def handle_event(
        "foo",
        _,
        socket
      ) do
    IO.puts("TRACE FOO")
    {:noreply, socket}
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

    {:noreply,
     socket
     |> mutate_verses(curr_verse_id, bound_verses)
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [%{d_mark | binding: bind, verse_id: verse_id} | marks])}
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

    {:noreply,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [%{d_mark | binding: bind, verse_id: verse_id} | marks])}
  end

  @impl true
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{order: no} | _] = marks}} = socket
      ) do
    bind = Draft.bind_node(bind)
    bound_verses = put_in(verses[verse_id].binding, bind)

    {:noreply,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [
       %Mark{state: :draft, order: no + 1, verse_id: verse_id, binding: bind} | marks
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
            kv_verses: verses,
            marks: [%Mark{state: :draft, verse_id: v_id, binding: binding} = d_mark | marks]
          }
        } = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    {
      :noreply,
      socket
      |> assign(:marks, [%{d_mark | body: body, state: :live} | marks])
      |> mutate_draft_reflector()
      |> stream_insert(
        :verses,
        %{verses[v_id] | binding: binding}
      )
    }
  end

  # when user remains on the the same binding
  def handle_event(
        "createMark",
        %{"body" => body},
        %{
          assigns: %{
            kv_verses: verses,
            marks: [%Mark{state: :live, verse_id: v_id, binding: binding} = d_mark | _] = marks
          }
        } = socket
      ) do
    send(self(), {"mutate_UiState", "update_media_bridge_visibility", [false]})

    {:noreply,
     socket
     |> assign(:marks, [%{d_mark | body: body, state: :live} | marks])
     |> mutate_draft_reflector()
     |> stream_insert(
       :verses,
       %{verses[v_id] | binding: binding}
     )}
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
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.debug_dump session={@session} user_mode={@user_mode} />
      <!-- CONTENT DISPLAY: -->
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <%= if @content_action == :show_sources do %>
          <.live_component
            module={VyasaWeb.Content.Sources}
            id="content-sources"
            sources={@streams.sources}
            user_mode={@user_mode}
          />
        <% end %>

        <%= if @content_action == :show_chapters do %>
          <.live_component
            module={VyasaWeb.Content.Chapters}
            id="content-chapters"
            source={@source}
            chapters={@streams.chapters}
            user_mode={@user_mode}
          />
        <% end %>

        <%= if @content_action == :show_verses do %>
          <.live_component
            module={VyasaWeb.Content.Verses}
            id="content-verses"
            src={@src}
            verses={@streams.verses}
            chap={@chap}
            kv_verses={@kv_verses}
            marks={@marks}
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

  # Helper function that syncs and mutates Draft Reflector
  defp mutate_draft_reflector(
         %{assigns: %{draft_reflector: %Vyasa.Sangh.Sheaf{} = dt, marks: marks}} = socket
       ) do
    {:ok, com} = Vyasa.Sangh.update_sheaf(dt, %{marks: marks})

    socket
    |> assign(:draft_reflector, com)
  end

  # when session hasnt been initialised
  defp mutate_draft_reflector(socket) do
    socket
  end

  # currently naive hd lookup can be filter based on active toggle,
  # tree like sheafs can be used to store nested collapsible topics (personal mark collection e.g.)
  # currently marks merged in and swapped out probably can be singular data structure
  # managing of lifecycle of marks
  # if sangh_id is active open
  defp sync_draft_reflector(%{assigns: %{session: %{sangh: %{id: sangh_id}}}} = socket) do
    case Vyasa.Sangh.get_sheafs_by_session(sangh_id, %{traits: ["draft"]}) do
      [%Vyasa.Sangh.Sheaf{marks: [_ | _] = marks} = dt | _] ->
        IO.inspect(marks, label: "is this triggering")

        socket
        |> assign(draft_reflector: dt)
        |> assign(marks: marks)

      [%Vyasa.Sangh.Sheaf{} = dt | _] ->
        socket
        |> assign(draft_reflector: dt)

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

  defp sync_draft_reflector(%{assigns: %{session: _}} = socket) do
    socket
  end

  def debug_dump(assigns) do
    ~H"""
    <div
      :if={unquote(Mix.env() == :dev)}
      class="fixed top-0 left-0 m-4 p-4 bg-white border border-gray-300 rounded-lg shadow-lg max-w-md max-h-80 overflow-auto z-50"
    >
      <h2 class="text-lg font-bold mb-2">Developer Dump</h2>
      <div class="mb-4">
        <strong class="text-gray-600">Session:</strong> <%= @session && @session.name %><br />
        <strong class="text-gray-600">Sangh ID:</strong> <%= @session && @session.sangh &&
          @session.sangh.id %><br />
        <strong class="text-gray-600">User Mode:</strong> <%= @user_mode.mode_context_component %> | <%= @user_mode.mode_context_component_selector %> | <%= @user_mode.mode %> mode
      </div>
      <div>
        <h3 class="text-md font-bold mb-2">Parameters:</h3>
        <pre class="bg-gray-100 p-2 rounded-md whitespace-pre-wrap"><%= inspect(Map.drop(assigns, [:session, :user_mode]), pretty: true) %></pre>
      </div>
    </div>
    """
  end
end
