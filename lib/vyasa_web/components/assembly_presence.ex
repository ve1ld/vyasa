defmodule VyasaWeb.AssemblyPresence do
  use VyasaWeb, :live_component
  @moduledoc """
   User interfacing for sangh related functions such as sharing, assemblies and what is to come for
  """

  def render(assigns) do
    ~H"""
    <div class={@class} >
      <!-- Main Toggle Button -->
      <button
        id="user-presence-toggle"
        phx-click={toggle_panel(@panel_open) |> JS.push("toggle_panel", target: @myself)}
        class="bg-white/30 hover:bg-white/40 text-white
               rounded-full focus:outline-none
               transition-all duration-300 backdrop-blur-lg
               shadow-lg active:scale-95
               flex items-center justify-center
               w-11 h-11 p-1
               border border-white/20"
      >
        <.icon name="hero-users"
               class="w-5 h-5 text-gray-500 hover:text-primaryAccent
                      transition-colors duration-200 stroke-2"
        />
      </button>
      <!-- Expanded Panel -->
      <div
        id="user-presence-panel"
        class={["space-y-2 absolute right-0 top-0 transition-all duration-500 ease-in-out",
          @panel_open && "block -translate-x-0",
          !@panel_open && "hidden translate-x-4",
          "flex items-center gap-2 mr-16"
        ]}
      >
        <!-- Overlapping Avatar Stack -->
        <div
          id="user-avatars"
          class="flex items-center"
        >
          <%= for {{ref, dis}, index} <- Enum.with_index(@sangh.disciples |> Enum.sort_by(&elem(&1, 1).online_at, :desc)) do %>
            <div
              id={"user-avatar-#{ref}"}
              class="group relative transition-all duration-300 ease-in-out"
              style={"margin-left: #{avatar_margin(index, @is_hovered)}; z-index: #{map_size(@sangh.disciples) - index + 10}"}
            >
              <!-- Disciple Avatar Button -->
              <button
                class="bg-white/30 hover:bg-white/40
                       rounded-full focus:outline-none
                       transition-all duration-300 backdrop-blur-lg
                       shadow-lg active:scale-95
                       flex items-center justify-center
                       w-11 h-11
                       border border-white/20"
              >
                <span class="text-gray-500 font-sanskrit text-lg">
                  <%= String.at(dis.name || "∅", 0) %>
                </span>
              </button>

            </div>
          <% end %>
          <!-- Share Button -->
        <button
          phx-click="sangh::share"
          class="bg-white/30 hover:bg-white/4
                 rounded-full focus:outline-none
                 transition-all duration-300 backdrop-blur-lg
                 shadow-lg active:scale-95
                 flex items-center justify-center
                 ml-4
                 px-4 h-11
                 border border-white/20"
        >
          <span class="text-gray-500">Share </span>
        </button>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign(
       panel_open: false,
       is_hovered: false
     )}
  end

  def handle_event("toggle_panel", _, socket) do
    {:noreply, update(socket, :panel_open, &(!&1))}
  end

  defp toggle_panel(false) do
    JS.toggle(
      to: "#user-presence-panel",
      in: {"ease-out duration-300", "opacity-0 translate-x-4", "opacity-100 translate-x-0"},
      out: {"ease-in duration-200", "opacity-100 translate-x-0", "opacity-0 -translate-x-4"}
    )
  end

  defp toggle_panel(true) do
    JS.hide(
      to: "#user-presence-panel",
      transition: {"ease-in duration-200", "opacity-100 translate-x-0", "opacity-0 -translate-x-4"}
    )
  end

  defp avatar_margin(_index, is_hovered) do
    if is_hovered do
      "0.5rem"
    else
      "-0.75rem"
    end
  end
end
