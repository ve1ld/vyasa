defmodule VyasaWeb.DisplayManager.DisplayLive do
  @moduledoc """
  Testing out nested live_views
  """
  use VyasaWeb, :live_view
  alias Vyasa.Display.UserMode
  alias VyasaWeb.OgImageController
  alias Phoenix.LiveView.Socket
  alias Vyasa.Written
  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Written.{Chapter}
  alias Vyasa.Sangh.{Comment, Mark}
  alias Utils.Struct

  @supported_modes UserMode.supported_modes()
  @default_lang "en"
  # @default_voice_lang "sa"

  @impl true
  def mount(_params, sess, socket) do
    # encoded_config = Jason.encode!(@default_player_config)
    %UserMode{} = mode = UserMode.get_initial_mode()

    {
      :ok,
      socket
      # to allow passing to children live-views
      |> assign(session: sess)
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
    |> stream_configure(:chapters, dom_id: &"Chapter-#{&1.no}")
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

      socket
      |> sync_session()
      |> assign(:content_action, :show_verses)
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
      |> assign(:marks, [%Mark{state: :draft, order: 0}])
      # DEPRECATED
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
    socket
  end

  defp sync_session(socket), do: socket

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
end
