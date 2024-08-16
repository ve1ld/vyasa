defmodule VyasaWeb.SourceLive.Chapter.Index do
  # use VyasaWeb, {:live_view, layout: {VyasaWeb.Layouts, :content_layout}}
  use VyasaWeb, :live_view
  alias Vyasa.{Written, Medium, Draft}
  alias Vyasa.Medium.{Voice}
  alias Vyasa.Written.{Source, Chapter}
  alias VyasaWeb.OgImageController
  alias Utils.Struct
  alias Vyasa.Sangh.{Comment, Mark}

  @default_lang "en"
  @default_voice_lang "sa"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> sync_session()
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp sync_session(%{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # written channel for reading and media channel for writing to media bridge and to player
    IO.inspect(sess_id, label: "Written Handshake Init")
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)
    socket
  end

  defp sync_session(socket), do: socket

  defp apply_action(
         socket,
         :index,
         %{"source_title" => source_title, "chap_no" => chap_no} = _params
       ) do
    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         %{verses: verses, translations: [ts | _]} = chap <-
           Written.get_chapter(chap_no, sid, @default_lang) do
      socket
      |> stream_configure(:verses, dom_id: &"verse-#{&1.id}")
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
      |> assign(:src, source)
      |> assign(:marks, [%Mark{state: :draft, order: 0}])
      |> assign(:lang, @default_lang)
      |> assign(:chap, chap)
      |> assign(:selected_transl, ts)
      |> assign_meta()
    else
      _ -> raise VyasaWeb.ErrorHTML.FourOFour, message: "Chapter not Found"
    end
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
            chap: %Written.Chapter{no: c_no, source_id: src_id}
          }
        } = socket
      ) do
    %Voice{} = chosen_voice = Medium.get_voice(src_id, c_no, @default_voice_lang)

    IO.inspect("VOICE CHOSEN", label: "be alive")
    Vyasa.PubSub.publish(
      chosen_voice,
      :voice_ack,
      sess_id
    )

    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message in @chapter")
    {:noreply, socket}
  end

  defp assign_meta(
         %{
           assigns: %{
             chap:
               %Chapter{
                 no: chap_no,
                 title: chap_title,
                 body: chap_body
               } = chap,
             src: src
           }
         } = socket
       ) do
    fmted_title = to_title_case(src.title)

    socket
    |> assign(:page_title, "#{fmted_title} Chapter #{chap_no} | #{chap_title}")
    |> assign(:meta, %{
      title: "#{fmted_title} Chapter #{chap_no} | #{chap_title}",
      description: chap_body,
      type: "website",
      image: url(~p"/og/#{OgImageController.get_by_binding(%{chapter: chap, source: src})}"),
      url: url(socket, ~p"/explore/#{src.title}/#{chap_no}")
    })
  end

  defp assign_meta(socket), do: socket

  # TODO verse matrix id structure build hashed node ref from node and node_id, field pairs
  # all comments where bindings -> where source and chapter
  # construct flat map access head via verse_id => %{node_assocs => %{node_id => }} for existing bindings based comments (r)a
  # create bindings based on node and node_id with the comment (w)

  @doc """
  Renders Abstract Verse Matrix

  ## Examples
      <.verse_display>
        <:item title="Title" navigate={~p"/myPath"}><%= @post.title %></:item>
      </.verse_display>
  """
  attr :id, :string, required: false
  attr :verse, :any, required: true
  attr :marks, :any

  slot :edge, required: true do
    attr :title, :string

    attr(:node, :any,
      required: false,
      doc: "Written Nodes linked to Verse"
    )

    attr :field, :list

    attr(:verseup, :atom,
      values: ~w(big mid smol)a,
      doc: "Markup Style"
    )

    attr :navigate, :any, required: false
  end

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

  attr :class, :string, default: nil
  attr :comments, :any, default: nil

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
end
