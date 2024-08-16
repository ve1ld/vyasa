defmodule VyasaWeb.DisplayManager.DisplayLive do
  @moduledoc """
  Testing out nested live_views
  """
  use VyasaWeb, :live_view
  alias Vyasa.Display.UserMode
  alias VyasaWeb.OgImageController
  alias Phoenix.LiveView.Socket
  alias Vyasa.{Medium, Written, Draft}
  alias Vyasa.Medium.{Voice}
  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Sangh.{Comment, Mark}
  alias Utils.Struct

  @supported_modes UserMode.supported_modes()
  @default_lang "en"
  @default_voice_lang "sa"

  @impl true
  def mount(_params, sess, socket) do
    # encoded_config = Jason.encode!(@default_player_config)
    %UserMode{} = mode = UserMode.get_initial_mode()

    {
      :ok,
      socket
      # to allow passing to children live-views
      # TODO: figure out if this is important
      |> assign(stored_session: sess)
      |> assign(mode: mode),
      layout: {VyasaWeb.Layouts, :display_manager}
    }
  end

  @impl true
  def handle_params(
        params,
        url,
        %Socket{
          assigns: %{
            live_action: live_action
          }
        } = socket
      ) do
    IO.inspect(url, label: "TRACE: handle param url")
    IO.inspect(live_action, label: "TRACE: handle param live_action")

    {
      :noreply,
      socket |> apply_action(live_action, params)
    }
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp apply_action(%Socket{} = socket, :show_sources, _params) do
    IO.inspect(:show_sources, label: "TRACE: apply action DM action show_sources:")
    # IO.inspect(params, label: "TRACE: apply action DM params:")

    # TODO: make this into a live component
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

  # TODO: change navigate -> patch on the html side
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

      socket
      |> sync_session()
      |> assign(:content_action, :show_verses)
      |> maybe_stream_configure(:verses, dom_id: &"verse-#{&1.id}")
      |> stream(:verses, verses)
      |> assign(
        :kv_verses,
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

  defp change_mode(socket, curr, target)
       when is_binary(curr) and is_binary(target) and target in @supported_modes do
    socket
    |> assign(mode: UserMode.get_mode(target))
  end

  defp change_mode(socket, _, _) do
    socket
  end

  defp sync_session(%{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # written channel for reading and media channel for writing to media bridge and to player
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)

    IO.inspect(sess_id, label: "TRACE: synced the sess with session id: ")
    socket
  end

  defp sync_session(socket) do
    IO.inspect(socket, label: "TRACE: NO SYNC OF SESSION!")
    socket
  end

  # ---- CHECKPOINT: all the sangha stuff goes here ----

  # enum.split() from @verse binding to mark
  def verse_matrix(assigns) do
    assigns = assigns

    ~H"""
    <div class="scroll-m-20 mt-8 p-4 border-b-2 border-brandDark" id={@id}>
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={elem <- @edge} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt :if={Map.has_key?(elem, :title)} class="w-1/12 flex-none text-zinc-500">
            <button
              phx-click={JS.push("clickVerseToSeek", value: %{verse_id: @verse.id})}
              class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
            >
              <div class="font-dn text-xl sm:text-2xl mb-4">
                <%= elem.title %>
              </div>
            </button>
          </dt>
          <div class="relative">
            <dd
              verse_id={@verse.id}
              node={Map.get(elem, :node, @verse).__struct__}
              node_id={Map.get(elem, :node, @verse).id}
              field={elem.field |> Enum.join("::")}
              class={"text-zinc-700 #{verse_class(elem.verseup)}"}
            >
              <%= Struct.get_in(Map.get(elem, :node, @verse), elem.field) %>
            </dd>
            <div
              :if={@verse.binding}
              class={[
                "block mt-4 text-sm text-gray-700 font-serif leading-relaxed
              lg:absolute lg:top-0 lg:right-0 md:mt-0
              lg:float-right lg:clear-right lg:-mr-[60%] lg:w-[50%] lg:text-[0.9rem]
              opacity-70 transition-opacity duration-300 ease-in-out
              hover:opacity-100",
                (@verse.binding.node_id == Map.get(elem, :node, @verse).id &&
                   @verse.binding.field_key == elem.field && "") || "hidden"
              ]}
            >
              <.comment_binding comments={@verse.comments} />
              <!-- for study https://ctan.math.illinois.edu/macros/latex/contrib/tkz/pgfornament/doc/ornaments.pdf-->
              <span class="text-primaryAccent flex items-center justify-center">
                ☙ ——— ›– ❊ –‹ ——— ❧
              </span>
              <.drafting marks={@marks} quote={@verse.binding.window && @verse.binding.window.quote} />
            </div>
          </div>
        </div>
      </dl>
    </div>
    """
  end

  # font by lang here
  defp verse_class(:big),
    do: "font-dn text-lg sm:text-xl"

  defp verse_class(:mid),
    do: "font-dn text-m"

  def comment_binding(assigns) do
    assigns = assigns |> assign(:elem_id, "comment-modal-#{Ecto.UUID.generate()}")

    ~H"""
    <span
      :for={comment <- @comments}
      class="block
                 before:content-['╰'] before:mr-1 before:text-gray-500
                 lg:before:content-none
                 lg:border-l-0 lg:pl-2"
    >
      <%= comment.body %> - <b><%= comment.signature %></b>
    </span>
    """
  end

  attr :quote, :string, default: nil
  attr :marks, :list, default: []

  def drafting(assigns) do
    assigns = assigns |> assign(:elem_id, "comment-modal-#{Ecto.UUID.generate()}")

    ~H"""
    <div :for={mark <- @marks} :if={mark.state == :live}>
      <span
        :if={!is_nil(mark.binding.window) && mark.binding.window.quote !== ""}
        class="block
                 pl-1
                 ml-5
                 mb-2
                 border-l-4 border-primaryAccent
                 before:mr-5 before:text-gray-500"
      >
        <%= mark.binding.window.quote %>
      </span>
      <span
        :if={is_binary(mark.body)}
        class="block
                 before:mr-1 before:text-gray-500
                 lg:before:content-none
                 lg:border-l-0 lg:pl-2"
      >
        <%= mark.body %> - <b><%= "Self" %></b>
      </span>
    </div>

    <span
      :if={!is_nil(@quote) && @quote !== ""}
      class="block
                 pl-1
                 ml-5
                 mb-2
                 border-l-4 border-gray-300
                 before:mr-5 before:text-gray-500"
    >
      <%= @quote %>
    </span>

    <div class="relative">
      <.form for={%{}} phx-submit="createMark">
        <input
          name="body"
          class="block w-full focus:outline-none rounded-lg border border-gray-300 bg-transparent p-2 pl-5 pr-12 text-sm text-gray-800"
          placeholder="Write here..."
        />
      </.form>
      <div class="absolute inset-y-0 right-2 flex items-center">
        <button class="flex items-center rounded-full bg-gray-200 p-1.5">
          <.icon name="hero-sun-mini" class="w-3 h-3 hover:text-primaryAccent hover:cursor-pointer" />
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "change_mode",
        %{
          "current_mode" => current_mode,
          "target_mode" => target_mode
        } = _params,
        socket
      ) do
    {:noreply,
     socket
     |> change_mode(current_mode, target_mode)}
  end

  # CHECKPOINT: event handlers related to hoverrune and stuff
  #
  #

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
    IO.inspect("handle_event::clickVerseToSeek", label: "checkpoint")
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

    {:noreply,
     socket
     |> stream_insert(
       :verses,
       %{verses[curr_verse_id] | binding: nil}
     )
     |> stream_insert(
       :verses,
       %{verses[verse_id] | binding: bind}
     )
     |> assign(:marks, [%{d_mark | binding: bind, verse_id: verse_id} | marks])}
  end

  # already in mark in drafting state, remember to late bind binding => with a fn()
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do
    # binding here blocks the stream from appending to quote
    bind = Draft.bind_node(bind)

    {:noreply,
     socket
     |> stream_insert(
       :verses,
       %{verses[verse_id] | binding: bind}
     )
     |> assign(:marks, [%{d_mark | binding: bind, verse_id: verse_id} | marks])}
  end

  @impl true
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{order: no} | _] = marks}} = socket
      ) do
    bind = Draft.bind_node(bind)

    {:noreply,
     socket
     |> stream_insert(
       :verses,
       %{verses[verse_id] | binding: bind}
     )
     |> assign(:marks, [
       %Mark{state: :draft, order: no + 1, verse_id: verse_id, binding: bind} | marks
     ])}
  end

  @impl true
  def handle_event(
        "markQuote",
        _,
        %{assigns: %{marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do
    IO.inspect(marks)
    {:noreply, socket |> assign(:marks, [%{d_mark | state: :live} | marks])}
  end

  def handle_event("markQuote", _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "createMark",
        %{"body" => body},
        %{assigns: %{marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do
    {:noreply, socket |> assign(:marks, [%{d_mark | body: body, state: :live} | marks])}
  end

  def handle_event("createMark", _event, socket) do
    {:noreply, socket}
  end

  def handle_event(event, message, socket) do
    IO.inspect(%{event: event, message: message}, label: "pokemon")
    {:noreply, socket}
  end

  # CHECKPOINT: handle_info functions in DM
  @doc """
  Handles the custom message that corresponds to the :media_handshake event with the :init
  message, regardless of the module that dispatched the message.

  This indicates an intention to sync the media library with the chapter, hence it
  returns a message containing %Voice{} info that can be used to generate a playback struct.
  """
  @impl true
  def handle_info(
        {_, :media_handshake, :init} = _msg,
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

        _ -> nil
    end



    {:noreply, socket}
  end

  @impl true
  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message in @chapter")
    {:noreply, socket}
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

  def maybe_config_stream(%Socket{} = socket, _, _) do
    socket
  end
end
