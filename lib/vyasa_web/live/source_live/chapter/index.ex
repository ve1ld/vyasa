defmodule VyasaWeb.SourceLive.Chapter.Index do
  use VyasaWeb, :live_view
  alias Vyasa.Written
  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Medium
  alias VyasaWeb.OgImageController
  alias Utils.Struct
  
  @default_lang "en"
  @default_voice_lang "sa"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
     |> stream_configure(:verses, dom_id: &("verse-#{&1.id}"))}
  end


  @impl true
  def handle_params(params, _url, socket) do
    IO.puts("chapter/index handle params")

    {:noreply, socket
    |> sync_session()
    |> apply_action(socket.assigns.live_action, params)}
  end


  defp sync_session(%{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # written channel for reading and media channel for writing to media bridge and to player
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)
    socket
  end

  defp sync_session(socket), do: socket

  defp apply_action(socket, :index, %{"source_title" => source_title, "chap_no" => chap_no} = _params) do
    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         %{verses: verses, translations: [ts | _]} = chap  <- Written.get_chapter(chap_no, sid, @default_lang) do

      socket
      |> stream(:verses, verses)
      |> assign(:src, source)
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
  Handles the action of clicking to seek by emitting the verse_id to the live player
  via the pubsub system.
  """
  def handle_event("clickVerseToSeek",
    %{"verse_id" => verse_id} = _payload,
    %{assigns: %{session: %{"id" => sess_id}}}  = socket) do

    IO.inspect("handle_event::clickVerseToSeek", label: "checkpoint")
    Vyasa.PubSub.publish(%{verse_id: verse_id}, :playback_sync, "media:session:" <> sess_id)
    {:noreply, socket}
  end

  @doc """
  Upon rcv of :media_handshake, which indicates an intention to sync by the player,
  returns a message containing %Voice{} info that can be used to generate a playback.
  """
  @impl true
  def handle_info({_, :media_handshake, :init},
    %{assigns: %{
         session: %{"id" => sess_id},
         chap: %Written.Chapter{no: c_no, source_id: src_id}
      }} = socket) do

    chosen_voice = Medium.get_voice(src_id, c_no, @default_voice_lang)
    Vyasa.PubSub.publish(
      chosen_voice,
      :voice_ack,
      sess_id
    )

    {:noreply, socket}
  end

  def handle_info(msg, socket) do IO.inspect(msg, label: "unexpected message in @chapter")
    {:noreply, socket}
  end

  defp assign_meta(%{assigns: %{
      chap: %Chapter{
        no: chap_no,
        title: chap_title,
        body: chap_body,
      } = chap,
      src: src,
    }} = socket) do
    fmted_title = to_title_case(src.title)

    socket
    |> assign(:page_title, "#{fmted_title} Chapter #{chap_no} | #{chap_title}")
    |> assign(:meta, %{
          title: "#{fmted_title} Chapter #{chap_no} | #{chap_title}",
          description: chap_body,
          type: "website",
          image: url(~p"/og/#{OgImageController.get_by_binding(%{chapter: chap, source: src})}"),
          url: url(socket, ~p"/explore/#{src.title}/#{chap_no}"),
      })
  end

  defp assign_meta(socket), do: socket

  @doc """
  Renders Abstract Verse Matrix

  ## Examples
      <.verse_display>
        <:item title="Title" navigate={~p"/myPath"}><%= @post.title %></:item>
      </.verse_display>
  """
  attr :id, :string, required: false
  attr :verse, :any, required: true
  slot :edge, required: true do
    attr :title, :string
    attr(:node, :any,
      required: false,
      doc: "Written Nodes linked to Verse")
    attr :field, :list
    attr(:verseup, :atom,
      values: ~w(big mid smol)a,
      doc: "Markup Style"
    )
    attr :navigate, :any, required: false
  end

  def verse_matrix(assigns) do
    assigns = assigns
      |> assign(:marginote_id, "marginote-#{Map.get(assigns, :id)}-#{Ecto.UUID.generate()}")
    ~H"""
    <div class="scroll-m-20 mt-8 p-4 border-b-2 border-brandDark" id={@id}>
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={elem <- @edge} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt
            :if={Map.has_key?(elem, :title)}
            class="w-1/12 flex-none text-zinc-500"
          >
           <button
              phx-click={JS.push("clickVerseToSeek", value: %{verse_id: @verse.id})}
              class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
            >
              <div class="font-dn text-xl sm:text-2xl mb-4">
                <%= elem.title %>
              </div>
           </button>
          </dt>
          <dd node={Map.get(elem, :node, @verse).__struct__} node_id={Map.get(elem, :node, @verse).id} field={elem.field |> Enum.join("::")} class={"text-zinc-700 #{verse_class(elem.verseup)}"}>
            <%=  Struct.get_in(Map.get(elem, :node, @verse), elem.field)%>
          </dd>
        </div>
      </dl>
    </div>
    """
  end
  # font by lang here
  defp verse_class(:big),
    do:
      "font-dn text-lg sm:text-xl"
  defp verse_class(:mid),
    do:
      "font-dn text-m"

  attr :current_user, :map, required: true

  def comment_information(assigns) do
    assigns = assigns |> assign(:elem_id, "comment-modal-#{Ecto.UUID.generate()}")

    ~H"""
    <div class="max-w-28 flex items-center hidden rounded-md bg-gray-200 px-2 py-1 shadow-2xl" id={Ecto.UUID.generate()}
      phx-hook="PopoverComment"
      style="max-width:7rem"
      >
      <button
        id={"comment-button-#{Ecto.UUID.generate()}"}
        phx-click={show_modal(@elem_id)}
        class="inline-flex items-center gap-1 border-none w-full font-serif text-sm"
      >
      <.icon name="hero-chat-bubble-left-ellipsis" class="h-4 w-4" /> Comment
      </button>
      <.modal_comments id={@elem_id} show={true} current_user={@current_user} />
    </div>
    """
  end


  attr(:id, :string, required: true)
  attr(:current_user, :map, required: true)
  attr(:show, :boolean,
    default: true,
    doc: "Default value is not to show the message"
  )
  attr(:path, :string, default: "/")

  def modal_comments(assigns) do
    assigns = assigns

    ~H"""
    <.modal_wrapper id={@id} background="bg-black/50" close_button={true} main_width="lg:max-w-lg">
      <div
        id={"#{@id}-comments-content"}
        data-selector="vyasa_modal_message"
        class="relative w-full shadow-2xl"
      >
        <div class="pointer-events-none absolute inset-y-0 px-2 flex items-center">
          <img src="https://picsum.photos/50/50" class="h-6 w-6 rounded-full bg-black" />
        </div>
        <.form for={%{}} phx-submit="submit-quoted-comment">
          <input
            name="body"
            class="block w-full rounded-lg border border-gray-200 bg-gray-50 p-2 pl-10 text-sm text-gray-900"
            placeholder="Add to comment..."
          />
        </.form>
        <div class="absolute inset-y-0 right-0 flex items-center gap-2 px-3">
          <button type="button" class="flex items-center">
          <.icon name="hero-paper-clip" class="h-4 w-4" />
          </button>
          <button class="flex items-center rounded-full bg-gray-200 p-1.5">
          <.icon name="hero-arrow-up" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </.modal_wrapper>
    """
  end

end
