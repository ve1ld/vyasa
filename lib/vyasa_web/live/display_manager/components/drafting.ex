defmodule VyasaWeb.DisplayManager.Components.Drafting do
  use VyasaWeb, :html

  attr :quote, :string, default: nil
  attr :marks, :list, default: []

  def render(assigns) do
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
