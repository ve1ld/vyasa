defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html

  attr :marks, :list, default: []
  attr :is_expanded_view?, :boolean, default: true
  attr :myself, :any

  def collapsible_marks_display(assigns) do
    ~H"""
    <div class="mb-4">
      <div class="flex items-center justify-between p-2 bg-brand-extra-light rounded-lg shadow-sm transition-colors duration-200">
        <button
          phx-click={JS.push("toggle_marks_display_collapsibility", value: %{value: ""})}
          phx-target={@myself}
          class="flex items-center w-full hover:bg-brand-light hover:text-white"
        >
          <.icon
            name={if @is_expanded_view?, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="w-5 h-5 mr-2 text-brand-dark"
          />
          <.icon name="hero-bookmark" class="w-5 h-5 mr-2 text-brand" />
          <span class="text-sm font-medium text-brand-dark">
            <%= "#{Enum.count(@marks |> Enum.filter(&(&1.state == :live)))} personal #{ngettext("mark", "marks", Enum.count(@marks))}" %>
          </span>
        </button>
        <div class="flex space-x-2">
          <.icon name="hero-pencil" class="w-5 h-5 text-brand-dark cursor-pointer" />
          <.icon name="hero-heart" class="w-5 h-5 text-brand-dark cursor-pointer" />
          <.icon name="hero-share" class="w-5 h-5 text-brand-dark cursor-pointer" />
        </div>
      </div>
      <div class={
        if @is_expanded_view?,
          do: "mt-2 transition-all duration-500 ease-in-out max-h-screen overflow-hidden",
          else: "max-h-0 overflow-hidden"
      }>
        <.mark_display :for={mark <- @marks |> Enum.reverse()} mark={mark} />
      </div>
    </div>
    """
  end

  attr :mark, :any, required: true

  def mark_display(assigns) do
    ~H"""
    <div class="border-l border-brand-light pl-2">
      <%= if @mark.state == :live do %>
        <div class="mb-2 bg-brand-light rounded-lg shadow-sm p-2 border-l-2 border-brand">
          <%= if !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
            <span class="block mb-1 text-sm italic text-secondary">
              "<%= @mark.binding.window.quote %>"
            </span>
          <% end %>
          <%= if is_binary(@mark.body) do %>
            <span class="block text-sm text-text">
              <%= @mark.body %>
            </span>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :sheaf, :any, required: true

  def sheaf_display(assigns) do
    ~H"""
    <span class="block
                   before:content-['╰'] before:mr-1 before:text-gray-500
                   lg:before:content-none
                   lg:border-l-0 lg:pl-2">
      SHEAF DISPLAY <%= @sheaf.body %> - <b><%= @sheaf.signature %></b>
    </span>
    """
  end
end
