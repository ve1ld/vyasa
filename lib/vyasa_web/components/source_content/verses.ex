defmodule VyasaWeb.Content.Verses do
  use VyasaWeb, :live_component

  alias Vyasa.Written.{Verse}
  alias Utils.Struct

  @impl true
  def update(params, socket) do
    {
      :ok,
      socket
      |> assign(params)
    }
  end

  # TODO: navigate() -> patch() on links...
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div id="chapter-index-container">
        <.header class="p-4 pb-0" >

        <div class={["text-4xl mb-4", "font-" <> @src.script]} >
            <%= @selected_transl.target.translit_title %> | <%= @chap.title %>
          </div>
          <div class="font-dn text-2xl mb-4">
            Chapter <%= @chap.no %> - <%= @selected_transl.target.title %>
          </div>
          
          <:subtitle>
            <div id="chapter-preamble" class="font-dn text-sm sm:text-lg">
              <%= @selected_transl.target.body %>
            </div>
          </:subtitle>
        </.header>
        <.back patch={~p"/explore/#{@src.title}"}>
          Back to <%= to_title_case(@src.title) %> Chapters
        </.back>
        <div id="verses" phx-update="stream" phx-hook="HoveRune">
          <.verse_matrix
            :for={{dom_id, %Verse{} = verse} <- @verses}
            id={dom_id}
            verse={verse}
            marks={@marks}
          >
            <:edge title={"#{verse.chapter_no}.#{verse.no}"} field={[:body]} verseup={{:big, @src.script}} />
            <:edge node={hd(verse.translations)} field={[:target, :body_translit]} verseup={:mid} />

            <:edge
              node={hd(verse.translations)}
              field={[:target, :body_translit_meant]}
              verseup={:mid}
            />

            <:edge node={hd(verse.translations)} field={[:target, :body]} verseup={:mid} />
          </.verse_matrix>
        </div>
        <.back patch={~p"/explore/#{@src.title}"}>
          Back to <%= to_title_case(@src.title) %> Chapters
        </.back>
      </div>

      <div
        id="hoverune"
        phx-update="ignore"
        class="absolute hidden top-0 left-0 max-w-max group-hover:flex items-center space-x-2 bg-white/80 rounded-lg shadow-lg px-4 py-2 border border-gray-200 transition-all duration-300 ease-in-out"
      >
        <button phx-click="markQuote" class="text-gray-600 hover:text-blue-600 focus:outline-none">
          <.icon
            name="hero-link-mini"
            class="w-5 h-5 hover:text-black hover:cursor-pointer hover:text-primaryAccent"
          />
        </button>

        <button class="text-gray-600 hover:text-red-600 focus:outline-none">
          <.icon name="hero-bookmark-mini" class="w-5 h-5 hover:text-black hover:cursor-pointer" />
        </button>
      </div>
    </div>
    """
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
  defp verse_class({:big, script}),
    do: "font-#{script} text-lg sm:text-xl"

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

  # @impl true
  # def handle_event("reportVideoStatus", payload, socket) do
  #   IO.inspect(payload)
  #   {:noreply, socket}
  # end
  @impl true
  def handle_event("navigate_to_chapter", %{"target" => target} = _payload, socket) do
    IO.inspect(target, label: "TRACE: push patch to the following target by @myself:")

    {:noreply,
     socket
     |> push_patch(to: target)
     |> push_event("scroll-to-top", %{})}
  end
end
