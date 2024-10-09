defmodule VyasaWeb.Context.Components do
  @moduledoc """
  Provides core components that shall be used in multiple contexts (e.g. read, discuss).
  """
  use VyasaWeb, :html


  attr :marks, :list, default: []
  attr :marks_target, :string
  attr :is_expanded_view?, :boolean, default: true
  attr :is_editable_marks?, :boolean, default: true
  attr :myself, :any, required: true

  # FIXME: the UUID generation for marks should ideally not be happening here, we should try to ensure that every mark has an id @ the point of creation, wherever that may be (fresh creation or created at point of insertion into the db)
  def collapsible_marks_display(assigns) do
    ~H"""
    <div class="mb-4">
      <div class="flex items-center justify-between p-2 bg-brand-extra-light rounded-lg shadow-sm transition-colors duration-200">
        <button
          phx-click={JS.push("toggle_marks_display_collapsibility", value: %{value: ""})}
          phx-target={@myself}
          class="flex items-center w-full hover:bg-brand-light hover:text-brand"
        >
          <.icon
            name={if @is_expanded_view?, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="w-5 h-5 mr-2 text-brand-dark"
          />
          <.icon name="hero-bookmark" class="w-5 h-5 mr-2 text-brand" />
          <span class="text-sm font-medium text-brand-dark">
            <%= "#{Enum.count(@marks |> Enum.filter(&(&1.state == :live)))}" %>
          </span>
        </button>
        <button
          :if={@is_expanded_view?}
          class="flex space-x-2"
          phx-click={JS.push("toggle_is_editable_marks?", value: %{value: ""})}
          phx-target={@myself}
        >
          <.icon
            name="hero-pencil-square"
            class="w-5 h-5 text-brand-dark cursor-pointer hover:bg-brand-accent hover:text-brand"
          />
        </button>
      </div>
      <div class={
        if @is_expanded_view?,
          do: "mt-2 transition-all duration-500 ease-in-out max-h-screen overflow-hidden",
          else: "max-h-0 overflow-hidden"
      }>
          <.mark_display :for={mark <- @marks |> Enum.reverse()} mark={mark} myself={@marks_target} editable={@is_editable_marks?}/>
      </div>
    </div>
    """
  end

  attr :mark, :any, required: true
  attr :myself, :any
  attr :editable, :boolean


  def mark_display(assigns) do
    ~H"""
    <div class="border-l border-brand-light pl-2 py-1">
      <%= if @mark.state == :live do %>
        <div class="flex items-start space-x-2 group">
          <div class="flex-grow">
            <%= if !is_nil(@mark.binding.window) && @mark.binding.window.quote !== "" do %>
              <p class="text-xs italic text-secondary mb-1">
                  <span phx-click="edit_quote" phx-value-id={@mark.id} class="cursor-text hover:bg-brand-light"><%= @mark.binding.window.quote %></span>
              </p>
            <% end %>
            <p class="text-sm text-text">
              <%= if @editable do %>
                <textarea rows="2" class="w-full bg-transparent border-b border-brand-light focus:outline-none focus:border-brand resize-none" phx-blur="update_body" phx-value-id={@mark.id}><%= @mark.body %></textarea>
              <% else %>
                <span phx-click="edit_body" phx-value-id={@mark.id} class="cursor-text hover:bg-brand-light"><%= @mark.body %></span>
              <% end %>
            </p>
          </div>
          <div class="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <button phx-click="edit_mark" phx-value-id={@mark.id} class="text-brand hover:text-brand-dark focus:outline-none" title="Edit">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button  phx-click="tombMark" phx-target={"#" <>@myself} phx-value-id={@mark.id}  class="text-red-500 hover:text-red-700 focus:outline-none" title="Delete">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor" class="size-6">
              <path d="M3.53 2.47a.75.75 0 0 0-1.06 1.06l18 18a.75.75 0 1 0 1.06-1.06l-18-18ZM20.25 5.507v11.561L5.853 2.671c.15-.043.306-.075.467-.094a49.255 49.255 0 0 1 11.36 0c1.497.174 2.57 1.46 2.57 2.93ZM3.75 21V6.932l14.063 14.063L12 18.088l-7.165 3.583A.75.75 0 0 1 3.75 21Z" />
              </svg>
            </button>
          </div>
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
