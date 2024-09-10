defmodule VyasaWeb.Content.ReadingContent do
  @moduledoc """
  Reading content shall be a slottable component that
  handles what content to display when in reading mode.
  """
  use VyasaWeb, :live_component

  @default_lang "en"
  @default_voice_lang "sa"
  alias Vyasa.Display.{UserMode}
  alias Vyasa.{Written, Draft}
  alias Vyasa.Medium
  alias Vyasa.Medium.{Voice}
  alias Vyasa.Written.{Source, Chapter}
  alias Phoenix.LiveView.Socket
  alias Vyasa.Sangh.{Comment, Mark}
  alias VyasaWeb.OgImageController

  @impl true
  def update(
        %{
          user_mode: %UserMode{} = user_mode,
          url_params: url_params,
          live_action: live_action,
          session: session
        } =
          params,
        socket
      ) do
    IO.inspect(params, label: "TRACE: params passed to ReadingContent")

    {
      :ok,
      socket
      |> assign(session: session)
      |> assign(user_mode: user_mode)
      |> apply_action(live_action, url_params)
    }
  end

  @impl true
  # received updates from parent liveview when a handshake is init, does a pub for the voice to use
  def update(
        %{id: "reading-content", sess_id: sess_id} = _props,
        %{
          assigns: %{
            session: %{"id" => sess_id},
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
    # IO.inspect(params, label: "TRACE: apply action DM params:")

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

    [%Chapter{source: src} | _] = chapters = Written.get_chapters_by_src(source_title)

    socket
    |> assign(:content_action, :show_chapters)
    |> assign(:page_title, to_title_case(src.title))
    |> assign(:source, src)
    |> assign(:meta, %{
      title: to_title_case(src.title),
      description: "Explore the #{to_title_case(src.title)}",
      type: "website",
      image: url(~p"/og/#{VyasaWeb.OgImageController.get_by_binding(%{source: src})}"),
      url: url(socket, ~p"/explore/#{src.title}")
    })
    |> maybe_stream_configure(:chapters, dom_id: &"Chapter-#{&1.no}")
    |> stream(:chapters, chapters |> Enum.sort_by(fn chap -> chap.no end))
  end

  defp apply_action(
         %Socket{} = socket,
         :show_verses,
         %{"source_title" => source_title, "chap_no" => chap_no} = params
       ) do
    IO.inspect(:show_verses, label: "TRACE: apply action DM action show_verses:")
    IO.inspect(params, label: "TRACE: apply action DM params:")
    IO.inspect(source_title, label: "TRACE: apply action DM params source_title:")
    IO.inspect(chap_no, label: "TRACE: apply action DM params chap_no:")

    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         %{verses: verses, translations: [ts | _], title: chap_title, body: chap_body} = chap <-
           Written.get_chapter(chap_no, sid, @default_lang) do
      fmted_title = to_title_case(source.title)

      IO.inspect(fmted_title, label: "TRACE: am i WITH it?")

      IO.inspect("sid: #{sid} title: #{source_title}", label: "SEE ME:")

      socket
      |> sync_session()
      |> assign(:content_action, :show_verses)
      |> maybe_stream_configure(:verses, dom_id: &"verse-#{&1.id}")
      |> stream(:verses, verses)
      |> assign(
        :kv_verses,
        # creates a map of verse_id_to_verses
        Enum.into(
          verses,
          %{},
          &{&1.id,
           %{
             &1
             | comments: [
                 %Comment{signature: "Pope", body: "Achilles’ wrath, to Greece the direful spring
              Of woes unnumber’d, heavenly goddess, sing"}
               ]
           }}
        )
      )
      |> assign(:marks, [%Mark{state: :draft, order: 0}])
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

  defp sync_session(%Socket{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # dbg()
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)
    # send(self(), :sync_session)
    send(self(), %{"cmd" => :sub_to_topic, "topic" => "written:session:" <> sess_id})
    socket
  end

  defp sync_session(socket) do
    IO.inspect(socket, label: "not ready to init sync of session from within ReadingContent")
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
        %{assigns: %{session: %{"id" => sess_id}}} = socket
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
    dbg()
    send(self(), {:change_ui, "update_media_bridge_visibility", [false]})

    {
      :noreply,
      socket
      # |> UiState.update_media_bridge_visibility(false)
    }
  end

  @impl true
  def handle_event(
        "verses::focus_toggle_on_quick_mark_drafting",
        %{"is_focusing?" => is_focusing?} = _payload,
        %Socket{} = socket
      ) do
    send(self(), {:change_ui, "update_media_bridge_visibility", [is_focusing?]})

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="reading-content">
      Hello world, i'm the ReadingContent <br />
      <.button phx-click="foo" phx-target={@myself}>
        FOO
      </.button>
      <br />
      <%= @user_mode.mode %> mode <br />
      <br />
      <br />
      <br />
      <br />
      <br />
      <!-- CONTENT DISPLAY: -->
      <div id="content-display" class="mx-auto max-w-2xl pb-16">
        <%= if @content_action == :show_sources do %>
          <.live_component
            module={VyasaWeb.Content.Sources}
            id="content-sources"
            sources={@streams.sources}
          />
        <% end %>

        <%= if @content_action == :show_chapters do %>
          <.live_component
            module={VyasaWeb.Content.Chapters}
            id="content-chapters"
            source={@source}
            chapters={@streams.chapters}
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
end
