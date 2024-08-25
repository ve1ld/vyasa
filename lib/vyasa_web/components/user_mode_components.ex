defmodule VyasaWeb.Display.UserMode.Components do
  use VyasaWeb, :html

  def render_hoverune_button(:mark_quote, assigns) do
    ~H"""
    <button phx-click="markQuote" class="text-gray-600 hover:text-blue-600 focus:outline-none">
      <.icon
        name="hero-link-mini"
        class="w-5 h-5 hover:text-black hover:cursor-pointer hover:text-primaryAccent"
      />
    </button>
    """
  end

  def render_hoverune_button(:bookmark, assigns) do
    ~H"""
    <button class="text-gray-600 hover:text-red-600 focus:outline-none">
      <.icon name="hero-bookmark-mini" class="w-5 h-5 hover:text-black hover:cursor-pointer" />
    </button>
    """
  end

  def render_hoverune_button(_fallback_id, assigns) do
    ~H"""
    <div></div>
    """
  end
end
