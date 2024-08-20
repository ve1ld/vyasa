defmodule VyasaWeb.DisplayManager.Components.VerseMatrix do
  use VyasaWeb, :html
  alias Utils.Struct
  alias VyasaWeb.DisplayManager.Components.CommentBinding
  alias VyasaWeb.DisplayManager.Components.Drafting

  # import VyasaWeb.DisplayManager.Components.CommentBinding
  # import VyasaWeb.DisplayManager.Components.Drafting

  def render(assigns) do
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
              <CommentBinding.render comments={@verse.comments} />
              <!-- for study https://ctan.math.illinois.edu/macros/latex/contrib/tkz/pgfornament/doc/ornaments.pdf-->
              <span class="text-primaryAccent flex items-center justify-center">
                ☙ ——— ›– ❊ –‹ ——— ❧
              </span>
              <Drafting.render
                marks={@marks}
                quote={@verse.binding.window && @verse.binding.window.quote}
              />
            </div>
          </div>
        </div>
      </dl>
    </div>
    """
  end

  defp verse_class(:big),
    do: "font-dn text-lg sm:text-xl"

  defp verse_class(:mid),
    do: "font-dn text-m"
end
